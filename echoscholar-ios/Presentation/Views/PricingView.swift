//
//  PricingView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-08-04.
//

import SwiftUI
import SafariServices
import NetSwift

struct PricingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSafari = false
    @State private var checkoutURL: URL?
    @State private var isLoading = false
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss

    
    private var userEmail: String = supabase.auth.currentUser?.email ?? ""
    private var userId: String = supabase.auth.currentUser?.id.uuidString ?? ""
    private var isPro: Bool = false
    
    var body: some View {
        ZStack {
            Color("background.primary").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        if isPro {
                            VStack(spacing: 12) {
                                Text("Your Plan")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    Text("Pro")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.yellow)
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Text("Free Tier")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                                
                                Text("You are currently on the Free plan. Upgrade to Pro to unlock AI-powered features!")
                                    .font(.body)
                                    .foregroundColor(.yellow.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text("Choose Your Plan")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Start for free. Upgrade to Pro anytime to unlock AI-powered learning features!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Plans Section
                    VStack(spacing: 20) {
                        // Free Plan
                        planCard(
                            title: "Free",
                            price: "Free",
                            subtitle: "Perfect to try out EchoScholar",
                            features: [
                                PlanFeature(text: "Real-time transcription", isIncluded: true),
                                PlanFeature(text: "Live translation", isIncluded: true),
                                PlanFeature(text: "AI Ask feature", isIncluded: false)
                            ],
                            buttonText: "Sign up",
                            buttonAction: nil,
                            isPro: false,
                            isCurrentPlan: !isPro
                        )
                        
                        // Pro Plan
                        planCard(
                            title: "Pro",
                            price: "$15.99",
                            priceSubtitle: "CAD / one-time",
                            subtitle: "Unlock all features. One-time purchase.",
                            features: [
                                PlanFeature(text: "Real-time transcription", isIncluded: true),
                                PlanFeature(text: "Live translation", isIncluded: true),
                                PlanFeature(text: "AI Ask feature", isIncluded: true, isHighlight: true)
                            ],
                            buttonText: isPro ? "You're already Pro" : "Get Pro",
                            buttonAction: isPro ? nil : {
                                Task {
                                    await startCheckout()
                                }
                            },
                            isPro: true,
                            isCurrentPlan: isPro
                        )
                    }
                    .padding(.horizontal)
                    
                    // Footer
                    Text("* All prices in CAD. Pro plan is a one-time payment and unlocks AI Ask forever for your account.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            
            if isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Text("Redirecting to Stripe...")
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
            }
        }
        .navigationTitle("Pricing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSafari) {
            if let url = checkoutURL {
                WebViewModal(
                    url: url,
                    isPresented: $showSafari,
                    onSuccessRedirect: {
                        appState.isPro = true
                        dismiss()
                    }
                )
            }
        }
        .alert("Checkout failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
    }
    
    @ViewBuilder
    private func planCard(
        title: String,
        price: String,
        priceSubtitle: String? = nil,
        subtitle: String,
        features: [PlanFeature],
        buttonText: String,
        buttonAction: (() -> Void)?,
        isPro: Bool,
        isCurrentPlan: Bool
    ) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isPro && isCurrentPlan {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(price)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let priceSubtitle = priceSubtitle {
                        Text(priceSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Features
            VStack(spacing: 12) {
                ForEach(features, id: \.text) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: feature.isIncluded ? "checkmark" : "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(feature.isIncluded ? .green : .gray.opacity(0.3))
                        
                        HStack {
                            Text(feature.text)
                                .font(.subheadline)
                                .foregroundColor(feature.isIncluded ? .white : .gray)
                                .strikethrough(!feature.isIncluded)
                            
                            if feature.isHighlight && feature.isIncluded {
                                Text("Pro Only")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color("accent"))
                                    .foregroundColor(.black)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Button
            if let buttonAction = buttonAction {
                ESButton(
                    title: buttonText,
                    icon: isPro ? "lock.fill" : nil,
                    type: .primary,
                    isWide: true,
                    action: buttonAction
                )
                .disabled(isLoading)
            } else {
                Button(action: {}) {
                    HStack {
                        if isPro && isCurrentPlan {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(buttonText)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .background(Color.gray.opacity(0.3))
                .foregroundColor(.secondary)
                .cornerRadius(12)
                .disabled(true)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPro && !isCurrentPlan ? Color("accent").opacity(0.1) : Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isPro && !isCurrentPlan ? Color("accent").opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .shadow(color: isPro && !isCurrentPlan ? Color("accent").opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
    }
    
    private func startCheckout() async {
        isLoading = true
        defer { isLoading = false }
        
        let client = NetworkClient(requestBuilder: ProtectedRequestBuilder())
        let request = PaymentsEndpoint.checkout(request: .init(userId: userId, email: userEmail))
        do {
            let response: Checkout.Response = try await client.request(request)
            if let url = URL(string: response.url) {
                self.checkoutURL = url
                self.showSafari = true
            }
        } catch {
            print(error.localizedDescription)
            self.showError = true
        }
    }
}

struct PlanFeature {
    let text: String
    let isIncluded: Bool
    let isHighlight: Bool
    
    init(text: String, isIncluded: Bool, isHighlight: Bool = false) {
        self.text = text
        self.isIncluded = isIncluded
        self.isHighlight = isHighlight
    }
}

#Preview {
    PricingView()
}
