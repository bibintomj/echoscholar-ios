//
//  WebSocketTranscriber.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18.
//

import Foundation
import AVFoundation
import NetSwift

final class WebSocketTranscriber {
    private let client: WebSocketClient
    private let audioEngine = AVAudioEngine()
    private let languageCode: String
    private let userId: String

    var onTranscript: ((String) -> Void)?
    var onTranslation: ((String) -> Void)?

    init(socket: WebSocketClient, languageCode: String, userId: String) {
        self.client = socket
        self.languageCode = languageCode
        self.userId = userId

        client.onReceive = handleIncoming
        client.onOpen = { [weak self] in
            self?.sendInitial()
        }
    }

    func connect() {
        client.connect()
    }

    func disconnect() {
        client.send(text: "END")
        client.disconnect()
        stopAudio()
    }

    private func sendInitial() {
        let payload: [String: Any] = ["userId": userId, "lang": languageCode]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            client.send(data: data)
        }
    }

    private func handleIncoming(result: Result<Data, Error>) {
        guard case .success(let data) = result else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if json["type"] as? String == "READY" {
            startAudio()
        } else {
            if let t = json["transcription"] as? String {
                onTranscript?(t)
            }
            if let tr = json["translation"] as? String {
                onTranslation?(tr)
            }
        }
    }

    private func startAudio() {
        let input = audioEngine.inputNode
//        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
//                                   sampleRate: 16000,
//                                   channels: 1,
//                                   interleaved: false)!
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            guard let self else { return }
            let data = self.convertBuffer(buffer)
            self.client.send(data: data)
        }



        try? AVAudioSession.sharedInstance().setCategory(.record)
        try? AVAudioSession.sharedInstance().setActive(true)
        try? audioEngine.start()
    }

    private func stopAudio() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func convertBuffer(_ buffer: AVAudioPCMBuffer) -> Data {
        guard let floatChannel = buffer.floatChannelData?[0] else { return Data() }
        let samples = UnsafeBufferPointer(start: floatChannel, count: Int(buffer.frameLength))
        let int16Samples = samples.map { Int16(max(-1.0, min(1.0, $0)) * Float(Int16.max)) }
        return int16Samples.withUnsafeBufferPointer { Data(buffer: $0) }
    }
}
