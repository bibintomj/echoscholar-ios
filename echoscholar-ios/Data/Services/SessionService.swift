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
}
