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
    
    /// This is the name of the file including extenstion. Eg. bibintomj-profile-picture.jpg
    var fileName: String { get }
    var mimeType: String { get }
    
    var formFields: [String: String]? { get }
    
    /// This is the Key where the file data (value) will be paired with. You must use the key server is looking to read the file data.
    var fileFieldName: String { get }
}
