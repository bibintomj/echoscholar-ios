//
//  UserEndpoints.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-08-04.
//

import NetSwift
import Foundation

enum UserEndpoints: NetworkRequest {
    case user(userId: String)
    case me
    case subscription(userId: String)
    
    var baseURL: URL { URL(string: AppState.hostURLString)! }
    
    var path: String {
        switch self {
        case .user(let userId): "/user/\(userId)"
        case .me: "/user/me"
        case .subscription(let userId): "/user/\(userId)/subscription"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .user: .get
        case .me: .get
        case .subscription: .get
        }
    }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    
    var queryParameters: [String: String]? { nil }
    
    var body: Encodable? {
        switch self {
        default: nil
        }
    }
}
