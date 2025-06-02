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

struct HttpBinResponse: Codable {
    let data: String?
    let files: [String: String]?
    let form: [String: String]?
    let json: [String: String]?
    let headers: [String: String]?
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
    let path = "/anything"
    let method: HTTPMethod = .post
    let headers: [String: String]? = ["Content-Type": "text/plain"]
    let queryParameters: [String: String]? = nil
    let body: Encodable? = nil
    let fileData: Data
    
    init(text: String) {
        self.fileData = Data(text.utf8)
    }
}

struct MultipartUploadRequest: MultipartUploadRequest {
    let baseURL = URL(string: "https://httpbin.org")!
    let path = "/anything"
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

struct NetworkClientTests {
    private let client = NetworkClient()
    
    // MARK: - Standard Request Tests
    
    @Test func testGetRequest() async throws {
        let request = GetPostsRequest()
        let post: Post = try await client.request(request)
        
        #expect(post.id == 1)
        #expect(!post.title.isEmpty)
        #expect(!post.body.isEmpty)
        #expect(post.userId == 1)
    }
    
    // MARK: - Binary Upload Tests
    
    @Test func testBinaryUpload() async throws {
        let testString = "This is a test upload"
        let request = BinaryUploadRequest(text: testString)
        let response: HttpBinResponse = try await client.uploadBinary(request)
        
        // httpbin returns the raw data in the 'data' field
        let returnedString = response.data
        
        #expect(returnedString == testString)
    }
    
    // MARK: - Multipart Upload Tests
    
    @Test func testMultipartUpload() async throws {
        let testString = "Multipart test content"
        let fileName = "testfile.txt"
        let request = MultipartUploadRequest(text: testString, fileName: fileName)
        let response: HttpBinResponse = try await client.uploadMultipart(request)
        
        // Verify file was received correctly
        #expect(response.files?[fileName] == testString)
        
        // Verify form fields
        #expect(response.form?["description"] == "test file upload")
    }
    
    @Test func testMultipartUploadWithDifferentMimeType() async throws {
        let testString = "PNG image data would be here"
        let fileName = "test.png"
        let mimeType = "image/png"
        let request = MultipartUploadRequest(
            text: testString,
            fileName: fileName,
            mimeType: mimeType
        )
        
        let response: HttpBinResponse = try await client.uploadMultipart(request)
        
        #expect(response.files?[fileName] == testString)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testInvalidURL() async throws {
        struct InvalidRequest: NetworkRequest {
            let baseURL = URL(string: "https://invalid.url")!
            let path = "/invalid"
            let method: HTTPMethod = .get
            let headers: [String: String]? = nil
            let queryParameters: [String: String]? = nil
            let body: Encodable? = nil
        }
        
        let request = InvalidRequest()
        
        await #expect(throws: NetworkError.self) {
            let _: Post = try await client.request(request)
        }
    }
    
    @Test func testNotFoundError() async throws {
        struct NotFoundRequest: NetworkRequest {
            let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
            let path = "/nonexistent"
            let method: HTTPMethod = .get
            let headers: [String: String]? = nil
            let queryParameters: [String: String]? = nil
            let body: Encodable? = nil
        }
        
        let request = NotFoundRequest()
        
        await #expect(throws: NetworkError.self) {
            let _: Post = try await client.request(request)
        }
    }
}
