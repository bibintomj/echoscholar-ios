//
//  ProfileView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-08-07.
//

import SwiftUI
import NetSwift

struct ProfileView: View {
    @State private var user: User?
    @State private var isProUser = false

    var body: some View {
        ZStack {
            Color("background.primary")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text(user?.userMetadata.fullName.first?.uppercased() ?? "")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundStyle(.gray)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user?.userMetadata.fullName ?? "")
                            .font(.title2.bold())
                        Text(isProUser ? "Pro Plan" : "Free Plan")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(isProUser ? Color.accent : Color.gray.opacity(0.2))
                            .foregroundColor(isProUser ? .black : .gray)
                            .clipShape(Capsule())
                    }
                }

                VStack(spacing: 16) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            TextField("", text: .constant(user?.email ?? ""))
                                .disabled(true)

                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.backgroundTertiary)
                        .cornerRadius(10)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            Task {
                await loadUserData()
                isProUser = await loadSubscriptionStatus()
            }
        }
    }
    
    func loadUserData() async {
        guard let userId = supabase.auth.currentSession?.user.id.uuidString else {
            return 
        }
        let request = UserEndpoints.user(userId: userId)
        let networkClient = NetworkClient(requestBuilder: ProtectedRequestBuilder())
        do {
            let response: UserResponse = try await networkClient.request(request)
            user = response.user
//            return response
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func loadSubscriptionStatus() async -> Bool {
        guard let userId = supabase.auth.currentSession?.user.id.uuidString else {
            return false
        }
        let request = UserEndpoints.subscription(userId: userId)
        let networkClient = NetworkClient(requestBuilder: ProtectedRequestBuilder())
        do {
            let response: SubscriptionStatus.Response = try await networkClient.request(request)
            return response.isActive
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

#Preview {
    ProfileView()
}
