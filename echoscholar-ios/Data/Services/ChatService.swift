//
//  ChatService.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-30.
//

import Foundation
import NetSwift

class ChatService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient = NetworkClient(requestBuilder: ProtectedRequestBuilder())) {
        self.networkClient = networkClient
    }
    
    func streamChatMessages(request: Chat.Request, onDelta: @escaping (String) -> Void) async throws {
        let endpoint = ChatEndpoint.sendChatMessage(request: request)
        try await networkClient.stream(endpoint, onElement: { (chunk: Chat.ChunkResponse) in
            onDelta(chunk.delta)
        })
    }
}
