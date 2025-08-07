//
//  User.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-08-07.
//

import Foundation

struct UserResponse: Codable {
    let user: User
}

struct User: Codable {
//    let createdAt: String
    let email: String
    let id: String
    let userMetadata: UserMetadata

    enum CodingKeys: String, CodingKey {
//        case createdAt = "created_at"
        case email
        case id
        case userMetadata = "user_metadata"
    }
}

struct UserMetadata: Codable {
    let email: String
    let emailVerified: Bool
    let fullName: String
    let phoneVerified: Bool
    let sub: String

    enum CodingKeys: String, CodingKey {
        case email
        case emailVerified = "email_verified"
        case fullName = "full_name"
        case phoneVerified = "phone_verified"
        case sub
    }
}
