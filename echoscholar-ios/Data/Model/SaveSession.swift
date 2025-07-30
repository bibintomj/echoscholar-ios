//
//  SaveSession.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-23.
//

import Foundation

struct SaveSession {
    struct RequestModel: Codable {
        let transcription: String
        let translation: String
        let targetLanguage: String
        let audioData: Data
        let audioFileName: String
        let mimeType: String
        
        enum CodingKeys: String, CodingKey {
            case transcription
            case translation
            case targetLanguage = "target_language"
            case audioData
            case audioFileName
            case mimeType
        }
    }
    
    struct Response: Codable {
        let sessionId: String
        let audioFileUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case audioFileUrl = "audio_file_url"
        }
    }
}


