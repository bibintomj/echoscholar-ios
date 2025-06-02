//
//  File.swift
//  NetSwift
//
//  Created by Bibin Joseph on 2025-04-04.
//

import Foundation

/// Network-related errors.
public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, error: NError?)
    case httpErrorData(statusCode: Int, data: Data?)
    case decodingError(Error)
    case encodingError(Error)
    case unknownError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .invalidResponse: return "Invalid server response."
        case .httpError(let statusCode, let error): return error?.message ?? "HTTP Error: \(statusCode)"
        case .httpErrorData(let statusCode, _): return "HTTP Error: \(statusCode)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error): return "Encoding error: \(error.localizedDescription)"
        case .unknownError(let error): return "Unknown error: \(error.localizedDescription)"
        }
    }
}

public struct NError: Codable, Sendable {
    let error, message: String
}
