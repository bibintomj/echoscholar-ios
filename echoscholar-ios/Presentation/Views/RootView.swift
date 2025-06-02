//
//  RootView.swift
//  Lixor
//
//  Created by Bibin Joseph on 2025-04-25.
//

import SwiftUI

let overlayWindowTag = Int.random(in: 1000...10000) // some random number

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var overlayWindow: UIWindow?

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            LoginView()
                .navigationDestination(for: Route.self) { route in
                    viewForRoute(route)
                        .onAppear { createOverlayWindow() }
                        .overlay {
                            appState.fadeOverlayColor
                                .ignoresSafeArea()
                                .opacity(appState.isFadingOut ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5), value: appState.isFadingOut)
                        }
                }
        }
        .tint(.accent)
        
    }

    @ViewBuilder
    private func viewForRoute(_ route: Route) -> some View {
        switch route {
        case .login: LoginView()
        case .sessionList: EmptyView()
        case .sessionDetail: EmptyView()
        case .newSession: EmptyView()
        case .account: EmptyView()
//        case .splash: SplashView()
//        case .onboarding: OnboardView()
//        case .login: LoginView(viewModel: appState.makeAuthViewModel())
//        case .register: RegisterView(viewModel: appState.makeAuthViewModel())
//        case .main: MainTabView()
//        case .home: HomeView(viewModel: appState.makeHomeViewModel())
//        case .liveSession: SessionView(viewModel: appState.makeSessionsViewModel())
//        case .downloads: SplashView()
//        case .sessionDetail: SessionDetailView(viewModel: appState.makeDownloadsViewModel())
//        case .settings: SettingsView(viewModel: appState.makeSettingsViewModel())
        }
    }
    
    func createOverlayWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                overlayWindow.isNil else {
            return
        }
        
        let window = PassthroughWindow(windowScene: windowScene)
        window.backgroundColor = .clear
        let rootConroller = UIHostingController(rootView: LToastGroup())
        rootConroller.view.frame = windowScene.keyWindow?.frame ?? .zero
        rootConroller.view.backgroundColor = .clear
        window.rootViewController = rootConroller
        window.isHidden = false
        window.isUserInteractionEnabled = true
        window.tag = overlayWindowTag
        
        overlayWindow = window
    }
}

fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        return rootViewController?.view == view ? nil : view
    }
}


#Preview {
    RootView()
}
