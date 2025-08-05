//
//  SubscriptionStatus.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-08-05.
//

struct SubscriptionStatus: Codable {
    struct Response: Codable {
        var isActive: Bool
         enum CodingKeys: String, CodingKey {
            case isActive = "is_active"
        }
    }
    
}
