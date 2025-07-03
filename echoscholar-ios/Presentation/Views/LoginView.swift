//
//  LoginView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-05-19.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import Supabase
import NetSwift

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = "abc@mail.com"
    @State private var password = "Pass@123"
    @State private var isLoadingEmail = false
    @State private var isLoadingGoogle = false
    @State private var loginError: String?

    var body: some View {
        ZStack {
            Color("background.primary")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                Text("Welcome to")
                    .foregroundColor(Color("foregroundPrimary"))
                
                Image(.brandLettertype)
                    .resizable()
                    .frame(width: 250, height: 40)
                
                Text("Transcribe  •  Translate  •  Summarize")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                
                Picker(selection: .constant(0), label: Text("")) {
                    Text("Login").tag(0)
                    Text("Register").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                
                Group {
                    VStack(alignment: .leading) {
                        Text("Email")
                            .foregroundColor(.secondary)
                        TextField("abc@mail.com", text: $email)
                            .padding(12)
                            .background(.backgroundTertiary)
                            .cornerRadius(12)
                            .autocapitalization(.none)
                        
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Password")
                            .foregroundColor(.secondary)
                        SecureField("••••••••", text: $password)
                            .padding(12)
                            .background(.backgroundTertiary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                ESButton(
                    title: "Login",
                    icon: nil,
                    type: .primary,
                    isWide: true,
                    action: loginWithEmail,
                    isLoading: isLoadingEmail
                )
                .padding(.horizontal)
                
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray)
                    Text("OR CONTINUE WITH").foregroundColor(.gray).font(.caption)
                        .multilineTextAlignment(.center)
                        .layoutPriority(1)
                    Rectangle().frame(height: 1).foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                ESButton(
                    title: "Login with Google",
                    icon: "google.logo",
                    type: .secondary,
                    isWide: true,
                    action: loginWithGoogle,
                    isLoading: isLoadingGoogle
                )
                .padding(.horizontal)
                
                if let error = loginError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            if supabase.auth.currentUser != nil {
                navigateToHome()
            }
        }
    }
    
    func loginWithEmail() {
        isLoadingEmail = true
        loginError = nil
        Task {
            do {
                let session = try await supabase.auth.signIn(email: email, password: password)
                print("✅ Logged in with session: \(session)")
                let accessToken = session.accessToken
                let refreshToken = session.refreshToken
                await SessionManager.shared.setTokens(accessToken: accessToken, refreshToken: refreshToken)
                navigateToHome()
            } catch {
                loginError = "Login failed: \(error.localizedDescription)"
                print("❌ Email login error: \(error)")
            }
            isLoadingEmail = false
        }
    }
    
    func loginWithGoogle() {
        isLoadingGoogle = true
        loginError = nil
        Task {
            guard let topVC = UIApplication.shared.topViewController() else {
                print("❌ Failed to get top UIViewController")
                return
            }
                        
            do {
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
                guard let idToken = result.user.idToken?.tokenString else {
                    print("❌ No idToken found")
                    return
                }
                print("idToken>>>", idToken)
                let accessToken = result.user.accessToken.tokenString
                let refreshToken = result.user.refreshToken.tokenString
                print("accessToken>>>", accessToken)
                try await supabase.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .google,
                        idToken: idToken,
                        accessToken: accessToken
                    )
                )
                
                print("Supabase access token", supabase.auth.currentSession?.accessToken)
                
                await SessionManager.shared.setTokens(accessToken: supabase.auth.currentSession?.accessToken ?? accessToken,
                                                      refreshToken: supabase.auth.currentSession?.refreshToken ?? refreshToken)
                print("✅ Signed in with Google & Supabase")
                navigateToHome()
            } catch {
                print("❌ Sign in failed: \(error)")
            }
            isLoadingGoogle = false
        }
    }
    
    func navigateToHome() {
        isLoadingEmail = false
        isLoadingEmail = false
        appState.navigateTo(.sessionList)
    }
}

#Preview {
    LoginView()
}
