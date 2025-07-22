//
//  SessionViewModel.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-03.
//

import SwiftUI
import NetSwift

@MainActor
final class SessionViewModel: BaseViewModel {
    @Published var sessions: [Session] = []
    private let sessionService: SessionService
    
    @Published var selectedSession: Session?
    @Published var isPlaying = false
    @Published var progress: Double = 0.0
    @Published var shouldLogout: Bool = false
    @Published var generatedMoM: String?
    
    init(sessionService: SessionService = SessionService()) {
        self.sessionService = sessionService
        
    }
    
    func loadSessions() {
        setLoading(true)
        Task {
            do {
                sessions = try await sessionService.getSessions()
            } catch {
                if case NetworkError.httpError(let statusCode, _) = error, statusCode == 401 {
                    shouldLogout = true
                }
                if case NetworkError.httpErrorData(let statusCode, _) = error, statusCode == 401 {
                    shouldLogout = true
                }
                handleError(error)
            }
            setLoading(false)
        }
    }
    
    func getMoM() {
        guard let selectedSession else { return }
        setLoading(true)
        Task {
            do {
                generatedMoM = try await sessionService.getMoMOfSession(sessionId: selectedSession.id)
            } catch {
                handleError(error)
            }
            setLoading(false)
        }
    }
}
