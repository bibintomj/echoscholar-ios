//
//  WebSocketClient.swift
//  NetSwift
//
//  Created by Bibin Joseph on 2025-06-18.
//

import Foundation

public final class WebSocketClient: @unchecked Sendable {
    private let url: URL
    private var socket: URLSessionWebSocketTask?
    private let session: URLSession
    public var onReceive: ((Result<Data, Error>) -> Void)?
    public var onOpen: (() -> Void)?
    public var onClose: ((Error?) -> Void)?

    public init(url: URL) {
        self.url = url
        self.session = URLSession(configuration: .default)
    }

    public func connect() {
        disconnect()
        socket = session.webSocketTask(with: url)
        socket?.resume()
        onOpen?()
        listen()
    }

    public func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        onClose?(nil)
        socket = nil
    }

    public func send(data: Data) {
        socket?.send(.data(data)) { error in
            if let error = error {
                self.onReceive?(.failure(error))
            }
        }
    }

    public func send(text: String) {
        socket?.send(.string(text)) { error in
            if let error = error {
                self.onReceive?(.failure(error))
            }
        }
    }

    private func listen() {
        socket?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.onReceive?(.success(data))
                case .string(let string):
                    self.onReceive?(.success(Data(string.utf8)))
                @unknown default:
                    break
                }
                self.listen()
            case .failure(let error):
                self.onClose?(error)
            }
        }
    }
}
