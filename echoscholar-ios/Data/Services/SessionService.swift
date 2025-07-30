//
//  SessionService.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-03.
//

import Foundation
import NetSwift

class SessionService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient = NetworkClient(requestBuilder: ProtectedRequestBuilder())) {
        self.networkClient = networkClient
    }
    
    func getSessions() async throws -> [Session] {
        let request = SessionEndpoint.getSessions
        do {
            let response: GetSession.Response = try await networkClient.request(request)
            return response.sessions
        } catch let error as NetworkError {
            throw error
        }
    }
    
    func getMoMOfSession(sessionId: String) async throws -> String {
        let request = SessionEndpoint.getMoMOfSession(sessionId: sessionId)
        do {
            let response: GetMoM.Response = try await networkClient.request(request)
            return response.mom
        } catch let error as NetworkError {
            throw error
        }
    }
    
    func saveSession(sessionToUpload: SaveSession.RequestModel) async throws -> SaveSession.Response {
        let request = UploadEndpoint.saveSession(uploadItem: sessionToUpload)
        do {
            let response: SaveSession.Response = try await networkClient.uploadMultipart(request)
            return response
        } catch let error as NetworkError {
            throw error
        }
    }
    
    func deleteSession(sessionId: String) async throws {
        let request = SessionEndpoint.deleteSession(sessionId: sessionId)
        do {
            let response: Generic.Response = try await networkClient.request(request)
            return
        } catch let error as NetworkError {
            throw error
        }
    }
}
