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
    
    var baseURL: URL { URL(string: AppState.hostURLString)! }
    var path: String {
        switch self {
        case .getSessions: "/session"
        }
    }
    var method: HTTPMethod {
        switch self {
        case .getSessions: .get
        }
    }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    var queryParameters: [String: String]? { nil }
    var body: Encodable? {
        switch self {
        default: return nil
        }
    }
}
