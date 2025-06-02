//
//  NetSwiftSetup.swift
//  NetSwift
//
//  Created by Bibin Joseph on 2025-04-05.
//

import Testing
import Foundation
@testable import NetSwift

// MARK: - Test Models
struct Post: Codable, Equatable {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}

struct UploadResponse: Codable {
    let data: String?
    let files: [String: String]?
    let form: [String: String]?
}

// MARK: - Test Request Types
struct GetPostsRequest: NetworkRequest {
    let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    let path = "/posts/1"
    let method: HTTPMethod = .get
    let headers: [String: String]? = nil
    let queryParameters: [String: String]? = nil
    let body: Encodable? = nil
}

struct BinaryUploadRequest: RawFileUploadRequest {
    let baseURL = URL(string: "https://httpbin.org")!
    let path = "/post"
    let method: HTTPMethod = .post
    let headers: [String: String]? = nil
    let queryParameters: [String: String]? = nil
    let body: Encodable? = nil
    let fileData: Data
    
    init(text: String) {
        self.fileData = Data(text.utf8)
    }
}

struct MultipartUploadRequest: NetSwift.MultipartUploadRequest {
    let baseURL = URL(string: "https://httpbin.org")!
    let path = "/post"
    let method: HTTPMethod = .post
    let headers: [String: String]? = nil
    let queryParameters: [String: String]? = nil
    let body: Encodable? = nil
    let fileData: Data
    let fileName: String
    let mimeType: String
    let formFields: [String: String]?
    
    init(text: String, fileName: String = "test.txt", mimeType: String = "text/plain") {
        self.fileData = Data(text.utf8)
        self.fileName = fileName
        self.mimeType = mimeType
        self.formFields = ["description": "test file upload"]
    }
}
