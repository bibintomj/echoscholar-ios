//
//  GenericModel.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-30.
//

struct Generic {
    struct Response: Codable {
        let success: Bool
        let message: String?
    }
    
    struct ErrorResponse: Codable {
        let error: String?
    }
}


