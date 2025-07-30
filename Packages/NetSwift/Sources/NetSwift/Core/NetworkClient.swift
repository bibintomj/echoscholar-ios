//
//  NetworkClient.swift
//  NetSwift
//
//  Created by Bibin Joseph on 2025-04-04.
//

import Foundation

public protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    func upload(for request: URLRequest, from bodyData: Data) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}

/// A thread-safe, configurable networking client for HTTP requests.
public final class NetworkClient {
    private let session: NetworkSession
    private let requestBuilder: RequestBuilder
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let debugLoggingEnabled: Bool
    
    /// Initialize the `NetworkClient` with custom configurations.
    /// - Parameters:
    ///   - session: `NetworkSession` to customize caching, timeouts, etc.
    ///   - requestBuilder: Custom `RequestBuilder` for request modifications (default: `DefaultRequestBuilder`).
    ///   - decoder: Custom `JSONDecoder` for response parsing (default: `JSONDecoder()`).
    ///   - encoder: Custom `JSONEncoder` for request body encoding (default: `JSONEncoder()`).
    ///   - debugLoggingEnabled: Whether to enable debug logging (default: `false` in production, `true` in debug).
    public init(
        session: NetworkSession = URLSession.shared,
        requestBuilder: RequestBuilder = DefaultRequestBuilder(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        debugLoggingEnabled: Bool = false
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.decoder = decoder
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",   // With timezone
                "yyyy-MM-dd'T'HH:mm:ss.SSS",    // Without timezone
                "yyyy-MM-dd'T'HH:mm:ssZ",       // No milliseconds
                "yyyy-MM-dd'T'HH:mm:ss"         // No milliseconds, no timezone
            ]
            
            for format in formats {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = format
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateStr)"
            )
        }
        self.encoder = encoder
        #if DEBUG
        self.debugLoggingEnabled = true
        #else
        self.debugLoggingEnabled = debugLoggingEnabled
        #endif
    }
    
    /// Performs a network request and decodes the response.
    public func request<T: Decodable>(_ request: NetworkRequest) async throws -> T {
        let urlRequest = try await requestBuilder.build(from: request)
        logRequest(urlRequest)
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            logResponse(response, data: data)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                logError(statusCode: httpResponse.statusCode, data: data)
                if let decodedError = try? decoder.decode(NError.self, from: data) {
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode, error: decodedError)
                } else {
                    throw NetworkError.httpErrorData(statusCode: httpResponse.statusCode, data: data)
                }
            }
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                logSuccess(decoded)
                return decoded
            } catch {
                throw NetworkError.decodingError(error)
            }
        } catch {
            logNetworkError(error)
            throw error
        }
    }
    
    public func stream<T: Decodable>(
        _ request: NetworkRequest,
        linePrefix: String = "0:",
        until terminator: String = "d:",
        onElement: @escaping (T) -> Void
    ) async throws {
        let urlRequest = try await requestBuilder.build(from: request)
        logRequest(urlRequest)

        let (stream, response) = try await URLSession.shared.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        for try await line in stream.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // ✅ Handle terminator (optional)
            if trimmed.hasPrefix(terminator) {
                // optional: decode done metadata here
                break
            }

            // ✅ Handle streaming tokens like: 0:" today"
            if trimmed.hasPrefix(linePrefix) {
                let value = trimmed.replacingOccurrences(of: linePrefix, with: "")

                if T.self == String.self {
                    let unquoted = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    if let result = unquoted as? T {
                        onElement(result)
                    }
                    continue
                }

                // If using a model like ChunkResponse
                let json = #"{"0":\#(value)}"#
                guard let data = json.data(using: .utf8) else { continue }

                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    onElement(decoded)
                } catch {
                    logStreamDecodeError(raw: json, error: error)
                }

                continue
            }

            // 🟡 Unmatched line
            logStreamDecodeError(raw: line, error: NetworkError.decodingError(NSError(domain: "stream", code: 0)))
        }
    }



    // MARK: - Upload Methods
    public func uploadBinary<T: Decodable>(_ request: RawFileUploadRequest) async throws -> T {
        let urlRequest = try await requestBuilder.build(from: request)
        logRequest(urlRequest, fileData: request.fileData)
        
        do {
            let (data, response) = try await session.upload(for: urlRequest, from: request.fileData)
            return try handleResponse(data: data, response: response)
        } catch {
            logNetworkError(error)
            throw error
        }
    }
    
    public func uploadMultipart<T: Decodable>(_ request: MultipartUploadRequest) async throws -> T {
        let urlRequest = try await requestBuilder.build(from: request)
        logRequest(urlRequest, multipartData: request.fileData)
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            return try handleResponse(data: data, response: response)
        } catch {
            logNetworkError(error)
            throw error
        }
    }
    
    // MARK: - Private Helpers
    private func handleResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        logResponse(response, data: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            logError(statusCode: httpResponse.statusCode, data: data)
            if let decodedError = try? decoder.decode(NError.self, from: data) {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, error: decodedError)
            } else {
                throw NetworkError.httpErrorData(statusCode: httpResponse.statusCode, data: data)
            }
        }
        
        let decoded = try decoder.decode(T.self, from: data)
        logSuccess(decoded)
        return decoded
    }
    
    // MARK: - Debug Logging
    private func logRequest(_ request: URLRequest, fileData: Data? = nil, multipartData: Data? = nil) {
        guard debugLoggingEnabled else { return }
        
        print("\n🌐⬆️ [NETWORK REQUEST]")
        print("🔗 \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "No URL")")
        
        if let headers = request.allHTTPHeaderFields {
            print("\n📋 HEADERS:")
            prettyPrint(headers)
        }
        
        if let body = request.httpBody {
            print("\n📦 BODY:")
            if let json = try? JSONSerialization.jsonObject(with: body) {
                prettyPrint(json)
            } else {
                print(String(data: body, encoding: .utf8) ?? "Binary data")
            }
        } else if let fileData = fileData {
            print("\n📦 FILE DATA: \(fileData.count) bytes")
        } else if let multipartData = multipartData {
            print("\n📦 MULTIPART DATA: \(multipartData.count) bytes")
        }
        
        print("----------------------------------------")
    }
    
    private func logResponse(_ response: URLResponse, data: Data) {
        guard debugLoggingEnabled else { return }
        
        print("\n🌐⬇️ [NETWORK RESPONSE]")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🟢 STATUS: \(httpResponse.statusCode)")
            print("🔗 URL: \(httpResponse.url?.absoluteString ?? "No URL")")
            
            if !data.isEmpty {
                print("\n📦 RESPONSE DATA:")
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    prettyPrint(json)
                } else {
                    print(String(data: data, encoding: .utf8) ?? "Binary data")
                }
            }
        } else {
            print("🟡 Non-HTTP response")
        }
        
        print("----------------------------------------")
    }
    
    private func logError(statusCode: Int, data: Data) {
        guard debugLoggingEnabled else { return }
        
        print("\n🌐❌ [NETWORK ERROR]")
        print("🔴 STATUS: \(statusCode)")
        
        if !data.isEmpty {
            print("\n📦 ERROR BODY:")
            if let json = try? JSONSerialization.jsonObject(with: data) {
                prettyPrint(json)
            } else {
                print(String(data: data, encoding: .utf8) ?? "Binary data")
            }
        }
        
        print("----------------------------------------")
    }
    
    private func logSuccess<T>(_ decoded: T) {
        guard debugLoggingEnabled else { return }
        
        print("\n🌐✅ [DECODED RESPONSE]")
        prettyPrint(decoded)
        print("----------------------------------------")
    }
    
    private func logNetworkError(_ error: Error) {
        guard debugLoggingEnabled else { return }
        
//        print("\n🌐❗️ [NETWORK FAILURE]")
        
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                print("❌ Invalid URL")
            case .invalidResponse:
                print("❌ Invalid server response")
            case .httpError(let statusCode, let error):
                print("❌ HTTP Error: \(statusCode)")
                if let error = error {
                    print("Error details: \(error)")
                }
            case .httpErrorData(let statusCode, let data):
                print("❌ HTTP Error: \(statusCode)")
                if let data = data {
                    print("Error details: \(String(data: data, encoding: .utf8) ?? "Binary data")")
                }
            case .decodingError(let error):
                print("❌ Decoding error: \(error)")
            case .encodingError(let error):
                print("❌ Encoding error: \(error.localizedDescription)")
            case .unknownError(let error):
                print("❌ Unknown error: \(error.localizedDescription)")
            }
        } else {
            print("❌ \(error.localizedDescription)")
        }
        
        print("----------------------------------------")
    }
    
    private func logStreamDecodeError(raw: String, error: Error) {
        guard debugLoggingEnabled else { return }
        print("\n🌐⚠️ [STREAMING DECODE ERROR]")
        print("Raw: \(raw)")
        print("Error: \(error.localizedDescription)")
        print("----------------------------------------")
    }

    
    private func prettyPrint(_ value: Any) {
        // If the object is Encodable, encode it to JSON and print it nicely
        if let encodableValue = value as? Encodable {
            do {
                let jsonData = try JSONEncoder().encode(AnyEncodable(encodableValue))
                if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    print(prettyString)
                    return
                }
            } catch {
                print("❌ Failed to encode JSON: \(error)")
            }
        } else {
            print("\(value)")
        }
    }
}

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

