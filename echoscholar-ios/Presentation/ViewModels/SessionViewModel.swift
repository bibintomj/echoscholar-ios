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
    
    init(sessionService: SessionService = SessionService()) {
        self.sessionService = sessionService
        
    }
    
    func loadSessions() {
        setLoading(true)
        Task {
            do {
                sessions = try await sessionService.getSessions()
            } catch {
                handleError(error)
            }
            setLoading(false)
        }
    }
}
