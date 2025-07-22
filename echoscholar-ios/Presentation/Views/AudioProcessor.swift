import Foundation
import AVFoundation
import ffmpegkit

class AudioProcessor {
    private let tempDirectory: URL
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var currentWavURL: URL?
    private var pendingWavURLs: [URL] = []

    init() {
        tempDirectory = FileManager.default.temporaryDirectory
    }
    
    func startRecording(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioEngine = AVAudioEngine()
            inputNode = audioEngine?.inputNode
            guard let audioEngine = audioEngine,
                  let inputNode = inputNode else {
                completion(.failure(AudioProcessorError.setupFailed))
                return
            }
            
            // Start first chunk
            startNewRecordingChunk()
            audioEngine.prepare()
            try audioEngine.start()
            
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func startNewRecordingChunk() {
        guard let audioEngine = audioEngine, let inputNode = inputNode else { return }
        // Remove previous tap if any
        inputNode.removeTap(onBus: 0)
        let wavURL = tempDirectory.appendingPathComponent("recording_\(UUID().uuidString).wav")
        currentWavURL = wavURL
        let format = inputNode.outputFormat(forBus: 0)
        do {
            audioFile = try AVAudioFile(forWriting: wavURL, settings: format.settings)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                do {
                    try self?.audioFile?.write(from: buffer)
                } catch {
                    print("Error writing audio buffer: \(error)")
                }
            }
        } catch {
            print("Failed to start new chunk: \(error)")
        }
    }
    
    func finishCurrentChunkAndStartNext() {
        // 1. Stop current recording
        inputNode?.removeTap(onBus: 0)
        audioFile = nil

        // 2. Add last .wav to pending list
        if let lastURL = currentWavURL {
            pendingWavURLs.append(lastURL)
            currentWavURL = nil
        }

        // 3. Start a new .wav file and install new tap
        startNewRecordingChunk()
    }

    func processPendingChunks(onOpusChunk: @escaping (Data) -> Void) {
        guard !pendingWavURLs.isEmpty else { return }
        let wavURL = pendingWavURLs.removeFirst()
        convertToOpusChunk(wavURL: wavURL) { result in
            switch result {
            case .success(let opusData):
                onOpusChunk(opusData) // <--- Send to websocket here
            case .failure(let error):
                print("Failed to convert chunk: \(error.localizedDescription)")
            }
        }
    }

    func convertToOpusChunk(wavURL: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let webmURL = tempDirectory.appendingPathComponent("converted_\(UUID().uuidString).webm")
        DispatchQueue.global(qos: .userInitiated).async {
            guard FileManager.default.fileExists(atPath: wavURL.path) else {
                DispatchQueue.main.async {
                    completion(.failure(AudioProcessorError.noRecordingFound))
                }
                return
            }
            let command = "-y -i \"\(wavURL.path)\" -c:a libopus -b:a 128k -f webm \"\(webmURL.path)\""
            let session = FFmpegKit.execute(command)
            let returnCode = session?.getReturnCode()
            if let code = returnCode, code.isValueSuccess() {
                do {
                    let opusData = try Data(contentsOf: webmURL)
                    try? FileManager.default.removeItem(at: wavURL)
                    try? FileManager.default.removeItem(at: webmURL)
                    DispatchQueue.main.async {
                        completion(.success(opusData))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            } else {
                let failCode = returnCode?.getValue() ?? -1
                DispatchQueue.main.async {
                    completion(.failure(AudioProcessorError.conversionFailed(code: Int32(failCode))))
                }
            }
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioFile = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
    
    func cleanup() {
        stopRecording()
        if let wavURL = currentWavURL {
            try? FileManager.default.removeItem(at: wavURL)
        }
        // Clean up pending chunks
        for url in pendingWavURLs {
            try? FileManager.default.removeItem(at: url)
        }
        pendingWavURLs.removeAll()
    }
}

enum AudioProcessorError: Error, LocalizedError {
    case setupFailed
    case noRecordingFound
    case conversionFailed(code: Int32)
    
    var errorDescription: String? {
        switch self {
        case .setupFailed:
            return "Failed to setup audio recording"
        case .noRecordingFound:
            return "No recording found to convert"
        case .conversionFailed(let code):
            return "Audio conversion failed with code: \(code)"
        }
    }
}
