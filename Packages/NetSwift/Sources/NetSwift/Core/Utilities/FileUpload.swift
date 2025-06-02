//
//  FileUpload.swift
//  NetSwift
//
//  Created by Bibin Joseph on 2025-04-04.
//

import Foundation

/// For simple binary data uploads
public protocol RawFileUploadRequest: NetworkRequest {
    var fileData: Data { get }
}

/// For multipart form uploads
public protocol MultipartUploadRequest: NetworkRequest {
    var fileData: Data { get }
    var fileName: String { get }
    var mimeType: String { get }
    var formFields: [String: String]? { get }
}
