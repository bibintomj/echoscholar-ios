//
//  MultipartFormDataBuilder.swift
//  NetSwift
//
//  Created by Bibin Joseph on 2025-04-04.
//

import Foundation

/// Builds `multipart/form-data` body for file uploads.
struct MultipartFormDataBuilder {
    private let boundary: String
    
    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }
    
    /// Creates the body for a multipart request.
    func build(
        with fileData: Data,
        fileName: String,
        mimeType: String,
        formFields: [String: String]?
    ) -> Data {
        var body = Data()
        
        // Add form fields (if any)
        formFields?.forEach { key, value in
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        // Add file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        
        // Close boundary
        body.append("--\(boundary)--\r\n")
        
        return body
    }
}

// Helper to append strings to `Data`
fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
