//
//  Request.swift
//  NetSwift
//
//  Created by Bibin Joseph on 2025-04-04.
//

import Foundation

/// Defines a network request.
public protocol NetworkRequest {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get }
    var body: Encodable? { get }
}

/// HTTP methods.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Builds `URLRequest` from various request types.
public protocol RequestBuilder {
    func build(from request: NetworkRequest) async throws -> URLRequest
    func build(from request: RawFileUploadRequest) async throws -> URLRequest
    func build(from request: MultipartUploadRequest) async throws -> URLRequest
}

/// Default implementation of `RequestBuilder`.
public struct DefaultRequestBuilder: RequestBuilder {
    public init() {}
    
    // Standard request builder
    public func build(from request: NetworkRequest) async throws -> URLRequest {
        let url = request.baseURL.appendingPathComponent(request.path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if let queryParams = request.queryParameters {
            components?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = request.method.rawValue
        
        if let headers = request.headers {
            headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        }
        
        if let body = request.body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }
        
        return urlRequest
    }
    
    // Raw file upload builder
    public func build(from request: RawFileUploadRequest) async throws -> URLRequest {
        var urlRequest = try buildStandardRequest(from: request)
        urlRequest.httpBody = request.fileData
        return urlRequest
    }
    
    // Multipart upload builder
    public func build(from request: MultipartUploadRequest) async throws -> URLRequest {
        var urlRequest = try buildStandardRequest(from: request)
        
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let builder = MultipartFormDataBuilder(boundary: boundary)
        urlRequest.httpBody = builder.build(
            with: request.fileData,
            fileName: request.fileName,
            mimeType: request.mimeType,
            formFields: request.formFields
        )
        
        return urlRequest
    }
    
    // Private helper for common request building
    private func buildStandardRequest(from request: NetworkRequest) throws -> URLRequest {
        let url = request.baseURL.appendingPathComponent(request.path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if let queryParams = request.queryParameters {
            components?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = request.method.rawValue
        
        if let headers = request.headers {
            headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        }
        
        return urlRequest
    }
}

public struct ProtectedRequestBuilder: RequestBuilder {
    private let defaultBuilder: RequestBuilder
    
    public init(defaultBuilder: RequestBuilder = DefaultRequestBuilder()) {
        self.defaultBuilder = defaultBuilder
    }
    
    public func build(from request: NetworkRequest) async throws -> URLRequest {
        var urlRequest = try await defaultBuilder.build(from: request)
        
        // Async token access
        if let token = await SessionManager.shared.accessToken {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return urlRequest
    }
    
    public func build(from request: RawFileUploadRequest) async throws -> URLRequest {
        var urlRequest = try await defaultBuilder.build(from: request)
        if let token = await SessionManager.shared.accessToken {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }
    
    public func build(from request: MultipartUploadRequest) async throws -> URLRequest {
        var urlRequest = try await defaultBuilder.build(from: request)
        if let token = await SessionManager.shared.accessToken {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }
}
