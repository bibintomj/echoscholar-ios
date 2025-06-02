//
//  echoscholar_iosApp.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-05-19.
//

import SwiftUI
import NetSwift

@main
struct echoscholar_iosApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        guard !isSwiftUIPreview else { return }
        SessionManager.shared.restore()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
