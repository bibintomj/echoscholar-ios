//
//  UploadEnpoints.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-23.
//

import Foundation
import NetSwift

enum UploadEndpoint: MultipartUploadRequest {
    case saveSession(uploadItem: SaveSession.RequestModel)

    // NetworkRequest base properties:
    var baseURL: URL { URL(string: AppState.hostURLString)! }
    var path: String {
        switch self {
        case .saveSession: return "/savesession"
        }
    }
    var method: HTTPMethod { .post }
    var headers: [String: String]? { nil }
    var queryParameters: [String: String]? { nil }
    var body: Encodable? { nil } // Not used for multipart

    // MultipartUploadRequest properties:
    var fileData: Data {
        switch self {
        case .saveSession(let item): return item.audioData
        }
    }
    var fileName: String {
        switch self {
        case .saveSession(let item): return item.audioFileName
        }
    }
    var mimeType: String {
        switch self {
        case .saveSession(let item): return item.mimeType
        }
    }
    var fileFieldName: String {
        switch self {
        case .saveSession: return "audio"
        }
    }
    var formFields: [String: String]? {
        switch self {
        case .saveSession(let item):
            return [
                "transcription": item.transcription,
                "translation": item.translation,
                "target_language": item.targetLanguage
            ]
        }
    }
}
