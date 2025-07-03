//
//  SessionListView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18.
//

import SwiftUI
import Helpers
import Supabase

struct SessionListView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject var viewModel: SessionViewModel
    
    init(viewModel: SessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color("background.primary")
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading sessions...")
                    .foregroundColor(.white)
            } else {
                List {
                    ForEach(viewModel.sessions) { session in
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.transcriptions?.first?.content.prefix(20) ?? "Untitled")
                                    .font(.headline)
                                
                                Text(formatTimestamp(session.transcriptions?.first?.createdOn))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.backgroundTertiary)
                        .onTapGesture {
                            viewModel.selectedSession = session
                            appState.navigateTo(.sessionDetail)
                        }
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
            viewModel.loadSessions()
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
    
    private func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}




#Preview {
    SessionListView(viewModel: .init())
}
