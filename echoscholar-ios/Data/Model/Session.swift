//
//  Session.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-03.
//

import Foundation

// MARK: - Session Models

struct GetSession {
    struct Response: Codable {
        let sessions: [Session]
    }
}

struct Session: Codable, Identifiable {
    let id: String
    let createdOn: String
    let userId: String
    let targetLanguage: String
    let audioFilePath: String
    let audioSignedUrl: String?
    let translations: [ContentBlock]?
    let transcriptions: [ContentBlock]?
    let summaries: [ContentBlock]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdOn = "created_on"
        case userId = "user_id"
        case targetLanguage = "target_language"
        case audioFilePath = "audio_file_path"
        case audioSignedUrl = "audio_signed_url"
        case translations
        case transcriptions
        case summaries
    }
}

struct ContentBlock: Codable, Identifiable {
    let id: String
    let content: String
    let createdOn: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdOn = "created_on"
    }
}
