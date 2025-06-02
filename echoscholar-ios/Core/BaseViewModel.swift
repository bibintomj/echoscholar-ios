//
//  BaseViewModel.swift
//  Lixor
//
//  Created by Inhyuck Kim on 2025-03-25.
//

import SwiftUI

@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false

    func setLoading(_ loading: Bool) {
        withAnimation {
            isLoading = loading
        }
    }

    func handleError(_ error: Error) {
        LToastManager.shared.show(.init(title: error.localizedDescription, tint: .red))
    }
    
    func show(message: String) {
        LToastManager.shared.show(.init(title: message))
    }
}

// Helper AlertItem model for SwiftUI Alerts
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

