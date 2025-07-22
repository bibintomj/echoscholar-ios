//
//  WebSocketTranscriber.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18

import Foundation
import NetSwift

class WebSocketTranscriber {
    private let socket: WebSocketClient
    private let languageCode: String
    private let userId: String
    private var audioProcessor: AudioProcessor?
    private var isConnected = false
    private var isRecording = false
    private var configSent = false

    // Callbacks
    var onTranscript: ((String, Bool) -> Void)? // text, isFinal
    var onTranslation: ((String) -> Void)?
    var onStatusChange: ((String) -> Void)?
    var onError: ((String) -> Void)?

    init(socket: WebSocketClient, languageCode: String, userId: String) {
        self.socket = socket
        self.languageCode = languageCode
        self.userId = userId
        setupSocketHandlers()
    }

    private func setupSocketHandlers() {
        socket.onOpen = { [weak self] in
            self?.handleConnect()
        }

        socket.onClose = { [weak self] error in
            self?.handleDisconnect(error: error)
        }

        socket.onReceive = { [weak self] result in
            switch result {
            case .success(let data):
                if let text = String(data: data, encoding: .utf8) {
                    self?.handleMessage(text)
                }
            case .failure(let error):
                self?.onError?("WebSocket error: \(error.localizedDescription)")
            }
        }
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        stopRecording()
        socket.disconnect()
    }

    private func handleConnect() {
        isConnected = true
        onStatusChange?("Connected")

        // Send initial configuration that matches your backend expectations
        let config: [String: Any] = [
            "lang": languageCode,
            "userId": userId
        ]

        if let configData = try? JSONSerialization.data(withJSONObject: config),
           let configString = String(data: configData, encoding: .utf8) {
            print("Sending config: \(configString)")
            socket.send(text: configString)
            configSent = true
        }
    }

    private func handleDisconnect(error: Error?) {
        isConnected = false
        configSent = false
        stopRecording()

        if let error = error {
            onError?("Connection lost: \(error.localizedDescription)")
        }
        onStatusChange?("Disconnected")
    }

    private func handleMessage(_ message: String) {
        print("Received message: \(message)")
        
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Failed to parse message as JSON")
            return
        }

        // Handle READY message from backend
        if let type = json["type"] as? String, type == "READY" {
            print("Backend is ready, starting recording")
            startRecording()
            return
        }
        
        // Handle transcription and translation from your backend format
        if let transcription = json["transcription"] as? String {
            onTranscript?(transcription, true) // Assuming final transcripts
        }
        
        if let translation = json["translation"] as? String {
            onTranslation?(translation)
        }
        
        // Handle error messages
        if let error = json["error"] as? String {
            onError?(error)
        }
    }

    func startRecording() {
        guard isConnected && configSent && !isRecording else {
            print("Cannot start recording: connected=\(isConnected), configSent=\(configSent), recording=\(isRecording)")
            return
        }
        
        print("Starting audio recording...")
        audioProcessor = AudioProcessor()
        audioProcessor?.startRecording(
            onBuffer: { [weak self] pcmData in
                self?.sendAudioData(pcmData)
            },
            completion: { [weak self] result in
                switch result {
                case .success():
                    self?.isRecording = true
                    self?.onStatusChange?("Recording")
                    print("✅ Audio recording started successfully")
                case .failure(let error):
                    self?.onError?("Failed to start recording: \(error.localizedDescription)")
                    print("❌ Audio recording failed: \(error)")
                }
            }
        )
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        print("Stopping audio recording...")
        audioProcessor?.stopRecording()
        audioProcessor = nil
        isRecording = false
        
        // Send END message to backend (matches your backend's handleTextMessage)
        if isConnected {
            print("Sending END message to backend")
            socket.send(text: "END")
        }
        
        onStatusChange?("Stopped")
    }

    private func sendAudioData(_ data: Data) {
        guard isConnected && isRecording else {
            print("Cannot send audio: connected=\(isConnected), recording=\(isRecording)")
            return
        }
        
        guard data.count > 0 else {
            print("⚠️ Skipping empty audio data")
            return
        }
        
        print("Sending audio data: \(data.count) bytes")
        // Send raw PCM data as binary message
        socket.send(data: data)
    }
}
