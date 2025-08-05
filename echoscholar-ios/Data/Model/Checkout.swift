//
//  CheckoutModel.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-08-04.
//

struct Checkout {
    struct Request: Codable {
        let userId: String
        let email: String
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case email
        }
    }
    
    
    struct Response: Decodable {
        let url: String
    }
}
