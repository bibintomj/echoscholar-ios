//
//  ViewModelFactory.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-2.
//

@MainActor
protocol ViewModelFactory {
    func makeSessionViewModel() -> SessionViewModel
}


extension AppState: ViewModelFactory {
    func makeSessionViewModel() -> SessionViewModel {
        getViewModel(SessionViewModel.self) {
            SessionViewModel(sessionService: sessionService)
        }
    }
}
