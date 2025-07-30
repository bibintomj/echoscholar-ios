//
//  Chat.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-30.
//

import Foundation
struct Chat {
    struct Request: Codable {
        let userId: String
        let messages: [Message]
    }
    
    struct Message: Codable, Identifiable {
        let id = UUID()
        let role: String  // "user" or "assistant"
        var content: String
    }
    
    struct SingleResponse: Codable {
        let message: Message
    }
    
    struct ChunkResponse: Codable {
        let delta: String
        
        enum CodingKeys: String, CodingKey {
            case delta = "0"
        }
    }
}
