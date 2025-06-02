//
//  AppState.swift
//  Lixor
//
//  Created by Bibin Joseph on 2025-04-24.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var navigationPath = NavigationPath()

    // Used for fade transitions
    @Published var isFadingOut: Bool = false
    @Published var fadeOverlayColor: Color = .backgroundPrimary
    
    // ViewModel storage
    private var viewModels: [ObjectIdentifier: Any] = [:]

    @Published var isOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded")
        }
    }

    init() {
        self.isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
        self.setUpInitialView()
    }

    // Get or create ViewModel
    func getViewModel<T: ObservableObject>(_ type: T.Type, creator: () -> T)
        -> T
    {
        let key = ObjectIdentifier(type)
        if let vm = viewModels[key] as? T {
            return vm
        }
        let newVM = creator()
        viewModels[key] = newVM
        return newVM
    }

    // Clean up specific ViewModel
    func removeViewModel<T: ObservableObject>(_ type: T.Type) {
        let key = ObjectIdentifier(type)
        viewModels.removeValue(forKey: key)
    }

    private func setUpInitialView() {
        navigationPath.append(Route.login)
    }

    // Pops all routes
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
        viewModels.removeAll()
    }
    
    func pop() {
        navigationPath.removeLast()
    }
    
    func replaceRoot(with newRoutes: Route...,
                     animated: Bool = true,
                     fadeDuration: Double = 0.5) {
        
        guard animated else {
            performRootReplacement(newRoutes)
            return
        }

        isFadingOut = true

        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
            [weak self] in
            self?.performRootReplacement(newRoutes)
            self?.isFadingOut = false
        }
    }

    private func performRootReplacement(_ newRoute: [Route]) {
        navigationPath.removeLast(navigationPath.count)
        viewModels.removeAll()
        newRoute.forEach {
            navigationPath.append($0)
        }
    }

    func navigateTo(_ route: Route, animated: Bool = true) {
        self.navigationPath.append(route)
    }
}

// App Navigation Routes
enum Route: Hashable {
    case login
    case sessionList
    case sessionDetail
    case newSession
    case account
}
