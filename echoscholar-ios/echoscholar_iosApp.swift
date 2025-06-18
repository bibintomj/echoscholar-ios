//
//  echoscholar_iosApp.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-05-19.
//

import SwiftUI
import NetSwift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://ktuwbavdnqfkyhhdzpvp.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0dXdiYXZkbnFma3loaGR6cHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc2NzYyMTgsImV4cCI6MjA2MzI1MjIxOH0.ifnO2cTnTEqCJAmNAaX0UdTmpp5y1DOIlh4HiDBXAY4"
)


@main
struct echoscholar_iosApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        guard !isSwiftUIPreview else { return }
        SessionManager.shared.restore()
        print("Session", supabase.auth.currentUser)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onOpenURL { url in
                    Task {
                        
                        print(">>> OPEN URL: \(url)")
                        supabase.auth.handle(url)
                        print("✅ Google login completed successfully")
                        
                        let user = supabase.auth.currentUser
                        if let user {
                            print(">>> user: \(user)")
                        } else {
                            print("❌ Failed OAuth Login. NO USER FOUND")
                        }
//                      appState.currentUser = user
                    }
                }
        }
    }
}
