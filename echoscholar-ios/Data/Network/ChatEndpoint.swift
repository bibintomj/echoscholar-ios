//
//  ChatEndpoint.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-30.
//

import NetSwift
import Foundation

enum ChatEndpoint: NetworkRequest {
    case sendChatMessage(request: Chat.Request)
    
    var baseURL: URL { URL(string: AppState.hostURLString)! }
    
    var path: String {
        switch self {
        case .sendChatMessage: "/chat"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .sendChatMessage: .post
        }
    }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    
    var queryParameters: [String: String]? { nil }
    
    var body: Encodable? {
        switch self {
        case .sendChatMessage(let request): return request
        }
    }
}
