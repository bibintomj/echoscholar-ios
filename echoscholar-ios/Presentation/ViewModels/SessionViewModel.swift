//
//  SessionViewModel.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-03.
//

import SwiftUI
import AVFoundation
import Starscream
import Translation
import NetSwift

@MainActor
final class SessionViewModel: BaseViewModel {
    @Published var sessions: [Session] = []
    @Published var selectedSession: Session?
    @Published var isPlaying = false
    @Published var progress: Double = 0.0
    @Published var shouldLogout: Bool = false
    @Published var generatedMoM: String?
    @Published var selectedLang = "es" {
        didSet {
            // Only setup translation if the language actually changed
            if oldValue != selectedLang {
                setupTranslationSession(targetLanguage: selectedLang)
            }
        }
    }
    
    @Published var transcript: String = ""
    @Published var translation: String = ""
    @Published var status: String = "Ready"
    @Published var errorMessage: String?
    
    private let sessionService: SessionService
    private let apiKey = "8bdc8e692b2131dc51fff5f6e764e89f7e624ad1"
    private var socket: WebSocket?
    private var audioEngine: AVAudioEngine?
    @Published var translationConfiguration: TranslationSession.Configuration?
    @Published var textToTranslate: [String] = []
    @Published var translatedTexts: [String] = []
    
    private var isTranslating = false
    private var hasSetupInitialTranslation = false // Add this flag
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    init(sessionService: SessionService = SessionService()) {
        self.sessionService = sessionService
        super.init()
    }
    
    func loadSessions() {
        setLoading(true)
        Task {
            do {
                sessions = try await sessionService.getSessions()
            } catch {
                if case NetworkError.httpError(let statusCode, _) = error, statusCode == 401 {
                    shouldLogout = true
                }
                if case NetworkError.httpErrorData(let statusCode, _) = error, statusCode == 401 {
                    shouldLogout = true
                }
                handleError(error)
            }
            setLoading(false)
        }
    }
    
    func getMoM() {
        guard let selectedSession else { return }
        setLoading(true)
        Task {
            do {
                generatedMoM = try await sessionService.getMoMOfSession(sessionId: selectedSession.id)
            } catch {
                handleError(error)
            }
            setLoading(false)
        }
    }
    
    func setupTranslationSession(targetLanguage: String) {
        guard #available(iOS 18.0, *) else {
            errorMessage = "Translation is only available on iOS 18 or later."
            return
        }
        
//        // Don't recreate if we already have a configuration for this language
//        if let currentConfig = translationConfiguration,
//           currentConfig.target?.languageCode?.identifier == targetLanguage {
//            return
//        }
        
        // Create translation configuration that will be used by the view
        translationConfiguration = nil
        translationConfiguration = TranslationSession.Configuration(
            source: Locale(identifier: "en").language,
            target: Locale(identifier: targetLanguage).language
        )
        
        hasSetupInitialTranslation = true
    }
    
    func setupInitialTranslation() {
        // Only setup once and only when first needed
        guard !hasSetupInitialTranslation else { return }
        setupTranslationSession(targetLanguage: selectedLang)
    }
    
    func startRecording() {
        // Setup translation if not already done
        setupInitialTranslation()
        
        // Reset state
        transcript = ""
        translation = ""
        textToTranslate.removeAll()
        translatedTexts.removeAll()
        status = "Connecting..."
        
        // Initialize WebSocket
        let url = URL(string: "wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=48000&channels=1&model=nova&smart_format=true&filler_words=true")!
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        let newSocket = WebSocket(request: urlRequest)
        newSocket.delegate = self
        socket = newSocket
        newSocket.connect()
        
        // Configure AVAudioSession
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }
        
        // Set up audio engine
        let engine = AVAudioEngine()
        audioEngine = engine
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 48000, channels: 1, interleaved: true)
        let converterNode = AVAudioMixerNode()
        let sinkNode = AVAudioMixerNode()
        
        engine.attach(converterNode)
        engine.attach(sinkNode)
        
        converterNode.installTap(onBus: 0, bufferSize: 1024, format: converterNode.outputFormat(forBus: 0)) { (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            if let data = self.toData(buffer: buffer) {
                self.socket?.write(data: data)
            }
        }
        
        engine.connect(inputNode, to: converterNode, format: inputFormat)
        engine.connect(converterNode, to: sinkNode, format: outputFormat)
        engine.prepare()
        
        do {
            try engine.start()
            status = "Recording"
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            stopRecording()
        }
    }
    
    func stopRecording() {
        status = "Stopping..."
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        // Disconnect WebSocket
        socket?.disconnect()
        socket = nil
        
        // Deactivate AVAudioSession
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            errorMessage = "Failed to deactivate audio session: \(error.localizedDescription)"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.status = "Ready"
        }
    }
    
    func translateText(_ text: String) {
        guard #available(iOS 18.0, *) else {
            errorMessage = "Translation is only available on iOS 18 or later."
            return
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Ensure translation is setup
        setupInitialTranslation()
        
        // Set the text to translate, which will trigger the translationTask
        textToTranslate.append(text)
        
//        setupTranslationSession(targetLanguage: selectedLang)
        Task {
            await translate()
        }
        
    }
    
    func handleTranslationResult(_ result: String) {
        if !translation.isEmpty {
            translation += "\n"
        }
        translation += result
    }
    
    private func toData(buffer: AVAudioPCMBuffer) -> Data? {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        return Data(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
    }
    
    var session: TranslationSession?
    
    func translateSequence(_ session: TranslationSession) async {
        self.session = session
        await translate()
    }
    
    func translate() async {
        guard !isTranslating else { return }
        
        // Create an array of requests. Use the index of the review array
        // as the client identifier.
        let startIndex = translatedTexts.count
        let slice = textToTranslate[startIndex...]
        
        guard !slice.isEmpty else { return }

        let requests: [TranslationSession.Request] = slice.enumerated().map { (offset, text) in
            // Use (startIndex + offset) as the original index in the full array
            .init(sourceText: text, clientIdentifier: "\(startIndex + offset)")
        }
        
        do {
            // Translate the batch of requests.
            // For each response received, update the corresponding review in the array.
            isTranslating = true
            for try await response in self.session!.translate(batch: requests) {
                guard let index = Int(response.clientIdentifier ?? "") else { continue }
                await MainActor.run {
                    withAnimation {
                        // The client identifier is used to match the response to the original reviews
                        translatedTexts.append(response.targetText)
                        
                        // Update the translation display
                        if !translation.isEmpty {
                            translation += "\n"
                        }
                        translation += response.targetText
                    }
                }
            }
            isTranslating = false
        } catch {
            isTranslating = false
            await MainActor.run {
                errorMessage = "Translation failed: \(error.localizedDescription)"
            }
        }
    }
}

extension SessionViewModel: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .text(let text):
            do {
                let jsonData = Data(text.utf8)
                let response = try jsonDecoder.decode(DeepgramResponse.self, from: jsonData)
                let transcriptText = response.channel.alternatives.first?.transcript ?? ""
                
                if response.isFinal && !transcriptText.isEmpty {
                    if !transcript.isEmpty {
                        transcript += "\n"
                    }
                    transcript += transcriptText
                    translateText(transcriptText)
                    print("transcript: \(transcriptText)")
                }
            } catch {
                errorMessage = "Failed to parse Deepgram response: \(error.localizedDescription)"
            }
        case .connected(_):
            status = "Connected"
        case .error(let error):
            errorMessage = "WebSocket error: \(error?.localizedDescription ?? "Unknown error") \(error as? NSError) \((error as? NSError)?.description)"
            stopRecording()
        case .disconnected(_, _):
            status = "Ready"
        default:
            break
        }
    }
}

struct DeepgramResponse: Codable {
    let isFinal: Bool
    let channel: Channel
    
    struct Channel: Codable {
        let alternatives: [Alternatives]
    }
    
    struct Alternatives: Codable {
        let transcript: String
    }
}
