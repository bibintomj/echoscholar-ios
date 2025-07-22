//
//  WebSocketTranscriber.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18.
//

import Foundation
import NetSwift

class WebSocketTranscriber {
    private let socket: WebSocketClient
    private let languageCode: String
    private let userId: String
    private var audioProcessor: AudioProcessor?
    private var isConnected = false
    private var chunkTimer: Timer?
    
    // Callbacks
    var onTranscript: ((String) -> Void)?
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
        chunkTimer?.invalidate()
        chunkTimer = nil
        audioProcessor?.cleanup()
        audioProcessor = nil
        socket.disconnect()
    }
    
    private func handleConnect() {
        isConnected = true
        onStatusChange?("Connected")
        
        // Send initial configuration
        let config = [
            "type": "config",
            "language": languageCode,
            "userId": userId,
            "format": "webm_opus"
        ]
        
        if let configData = try? JSONSerialization.data(withJSONObject: config),
           let configString = String(data: configData, encoding: .utf8) {
            socket.send(text: configString)
        }
        
        startAudioProcessing()
    }
    
    private func handleDisconnect(error: Error?) {
        isConnected = false
        chunkTimer?.invalidate()
        chunkTimer = nil
        audioProcessor?.cleanup()
        audioProcessor = nil
        
        if let error = error {
            onError?("Connection lost: \(error.localizedDescription)")
        }
        onStatusChange?("Disconnected")
    }
    
    private func handleMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }
        
        switch type {
        case "transcript":
            if let text = json["text"] as? String {
                onTranscript?(text)
            }
        case "translation":
            if let text = json["text"] as? String {
                onTranslation?(text)
            }
        case "error":
            if let message = json["message"] as? String {
                onError?(message)
            }
        default:
            break
        }
    }
    
    func startAudioProcessing() {
        audioProcessor = AudioProcessor()
        audioProcessor?.startRecording { [weak self] result in
            switch result {
            case .success():
                self?.onStatusChange?("Recording")
                // Start chunk timer here!
                self?.chunkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                    self?.audioProcessor?.finishCurrentChunkAndStartNext()
                    self?.audioProcessor?.processPendingChunks { opusData in
                        // Send opusData to websocket
                        self?.sendOpusData(opusData)
                    }
                }
            case .failure(let error):
                self?.onError?("Failed to start recording: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendAudioChunk() {
        guard isConnected else { return }
        
        audioProcessor?.processPendingChunks { [weak self] opusData in
            self?.sendOpusData(opusData)
        }
    }
    
    private func sendOpusData(_ data: Data) {
        // Send binary data directly to WebSocket
        socket.send(data: data)
    }
}
