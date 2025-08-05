//
//  PaymentsEndpoint.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-08-04.
//

import NetSwift
import Foundation

enum PaymentsEndpoint: NetworkRequest {
    case checkout(request: Checkout.Request)
    
    var baseURL: URL { URL(string: AppState.hostURLString)! }
    
    var path: String {
        switch self {
        case .checkout: "/stripe/checkout"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .checkout: .post
        }
    }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    
    var queryParameters: [String: String]? { nil }
    
    var body: Encodable? {
        switch self {
        case .checkout(let request): return request
        }
    }
}
