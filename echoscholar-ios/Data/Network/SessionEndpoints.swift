//
//  SessionEndpoints.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-03.
//

import NetSwift
import Foundation

enum SessionEndpoint: NetworkRequest {
    case getSessions
    case getMoMOfSession(sessionId: String)
    case deleteSession(sessionId: String)
    
    var baseURL: URL { URL(string: AppState.hostURLString)! }
    var path: String {
        switch self {
        case .getSessions: "/session"
        case .getMoMOfSession: "/mom"
        case .deleteSession(let sessionId): "/session/\(sessionId)"
        }
    }
    var method: HTTPMethod {
        switch self {
        case .getSessions: .get
        case .getMoMOfSession: .post
        case .deleteSession: .delete
        }
    }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    var queryParameters: [String: String]? { nil }
    var body: Encodable? {
        switch self {
        case .getMoMOfSession(let sessionId): return ["session_id": sessionId]
        default: return nil
        }
    }
}
