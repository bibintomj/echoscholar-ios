//
//  WebView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-08-04.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    let onDismiss: () -> Void
    let onSuccessRedirect: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss, onSuccessRedirect: onSuccessRedirect)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Load the initial URL
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update delegate if needed
        uiView.navigationDelegate = context.coordinator
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let onDismiss: () -> Void
        let onSuccessRedirect: () -> Void
        
        init(onDismiss: @escaping () -> Void, onSuccessRedirect: @escaping () -> Void) {
            self.onDismiss = onDismiss
            self.onSuccessRedirect = onSuccessRedirect
        }
        
        // Called when navigation starts
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if let url = webView.url {
                checkForSuccessRedirect(url: url)
            }
        }
        
        // Called when navigation finishes
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url {
                checkForSuccessRedirect(url: url)
            }
        }
        
        // Called for redirects
        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
            if let url = webView.url {
                checkForSuccessRedirect(url: url)
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if let url = navigationAction.request.url {
                checkForSuccessRedirect(url: url)
            }
            return .allow
        }
        
        private func checkForSuccessRedirect(url: URL) {
            if url.absoluteString.contains("/payment-success") {
                DispatchQueue.main.async { [weak self] in
                    self?.onSuccessRedirect()
                }
            }
        }
        
        // Handle navigation errors
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Usage Example
struct WebViewModal: View {
    let url: URL
    @Binding var isPresented: Bool
    let onSuccessRedirect: () -> Void
    
    var body: some View {
        NavigationView {
            WebView(
                url: url,
                onDismiss: {
                    isPresented = false
                },
                onSuccessRedirect: {
                    onSuccessRedirect()
                    isPresented = false
                }
            )
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
