//
//  SessionListView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18.
//

import SwiftUI
import Helpers

import SwiftUI
import Helpers
import Supabase

struct SessionListView: View {
    @EnvironmentObject var appState: AppState
    @State private var sessions: [Session] = []
    @State private var isLoading = true
    @State private var showError = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color("background.primary")
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading sessions...")
                    .foregroundColor(.white)
            } else {
                List {
                    ForEach(sessions) { session in
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.title)
                                    .font(.headline)
                                
                                Text(session.timestampText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.backgroundTertiary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            
            ESButton(
                title: "New Session",
                icon: "mic.fill",
                type: .primary,
                isWide: true,
                action: {
                    appState.navigateTo(.newSession)
                }
            )
            .padding()
        }
        .navigationTitle("Your Sessions")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Logout", role: .destructive) {
                        logout()
                    }
                } label: {
                    if let urlString = (supabase.auth.currentUser?.userMetadata["avatar_url"] as? AnyJSON)?.stringValue,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 25, height: 25)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.accent, lineWidth: 2))
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            loadSessions()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to load sessions.")
        }
    }

    private func loadSessions() {
        isLoading = true
        Task {
            do {
                guard let accessToken = supabase.auth.currentSession?.accessToken else {
                    throw NSError(domain: "No token", code: 401)
                }

                var request = URLRequest(url: URL(string: "http://localhost:3000/api/session")!)
                request.httpMethod = "GET"
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NSError(domain: "Invalid response", code: 500)
                }

                // Debug: print raw JSON string
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Raw JSON Response:\n\(jsonString)")
                }

                let decoded = try JSONDecoder().decode(SessionResponse.self, from: data)

                // Debug: print full decoded object
                print("✅ Decoded Sessions:\n\(decoded)")

                // Map to display model
                sessions = decoded.sessions.map {
                    let title: String

                    if let firstTranscription = $0.transcriptions?.first?.content {
                        title = firstTranscription
                            .split(separator: "\n")
                            .first
                            .map(String.init) ?? "Untitled"
                    } else {
                        title = "Untitled"
                    }

                    return Session(title: title, timestampText: formatTimestamp($0.created_on))
                }


            } catch {
                print("❌ Failed to load sessions: \(error)")
                showError = true
            }

            isLoading = false
        }
    }

    private func logout() {
        Task {
            do {
                try await supabase.auth.signOut()
                appState.popToRoot()
            } catch {
                print("❌ Logout failed: \(error)")
            }
        }
    }

    private func formatTimestamp(_ timestamp: String) -> String {
        // Example: Convert ISO to friendly string
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: timestamp) {
            let formatter = RelativeDateTimeFormatter()
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return timestamp
    }
}

// MARK: - Session Models

struct SessionResponse: Codable {
    let sessions: [SessionAPIModel]
}

struct SessionAPIModel: Codable, Identifiable {
    let id: String
    let created_on: String
    let user_id: String
    let target_language: String
    let audio_file_path: String
    let audio_signed_url: String?
    let translations: [ContentBlock]?
    let transcriptions: [ContentBlock]?
    let summaries: [ContentBlock]?
}

struct ContentBlock: Codable, Identifiable {
    let id: String
    let content: String
    let created_on: String
}



#Preview {
    SessionListView()
}
