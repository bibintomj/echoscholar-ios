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
            
            if viewModel.isLoading && viewModel.sessions.isEmpty {
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
                                Text(session.transcriptions?.content.prefix(20) ?? "Untitled")
                                    .font(.headline)
                                
                                Text(formatTimestamp(session.transcriptions?.createdOn))
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.sessionToDelete = session
                                viewModel.showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .foregroundStyle(.black)
//                                    .backgroundStyle(.fill(Color.red))
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await refreshSessions()
                }
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
        .sheet(isPresented: $viewModel.showPricingPage) {
            PricingView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if appState.isPro {
                        appState.navigateTo(.chat)
                    } else {
                        viewModel.showPricingPage = true
                    }
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Profile") {
                        appState.navigateTo(.account)
                    }
                    
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
                            .foregroundColor(Color.foregroundPrimary)
                    }
                }
            }
        }
        .onAppear {
            if viewModel.sessions.isEmpty {
                viewModel.loadSessions()
                Task {
                    let status = await viewModel.loadSubscriptionStatus()
                    appState.isPro = status
                }
            }
            viewModel.generatedMoM = nil
        }
        .onChange(of: viewModel.shouldLogout) { oldValue, newValue in
            if newValue { logout() }
        }
        .confirmationDialog("Are you sure you want to delete this session?",
                            isPresented: $viewModel.showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let session = viewModel.sessionToDelete {
                    Task {
                        await viewModel.deleteSession(session.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.sessionToDelete = nil
            }
        }
    }
    
    private func refreshSessions() async {
        viewModel.loadSessions()
        
        // Small delay to ensure the refresh animation completes smoothly
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
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
