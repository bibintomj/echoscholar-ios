//
//  LToastManager.swift
//  Cue
//
//  Created by Bibin Tom Joseph on 18/12/23.
//

import SwiftUI

class LToastManager: ObservableObject {
    static let shared = LToastManager()
    @Published var toasts: [LToastItem] = []

    func show(_ toast: LToastItem) {
        withAnimation(.snappy) {
            toasts.append(toast)
        }
    }
}

struct LToastItem: Identifiable {
    let id: UUID = .init()
    var image: Image? = nil
    var title: String
    var tint: Color = .accent
    var timing: RelativeDuration = .long

    var primaryAction: ToastAction? = nil
    var secondaryAction: ToastAction? = nil
    var didFinishDisplaying: ((_ actionExecuted: Bool) -> Void)? = nil

    var actionExecuted = false

    init(image: Image? = nil, title: String,
         tint: Color = .accent,
         timing: LToastItem.RelativeDuration = .long,
         primaryAction: LToastItem.ToastAction? = nil,
         secondaryAction: LToastItem.ToastAction? = nil,
         didFinishDisplaying: ((Bool) -> Void)? = nil) {
        self.image = image
        self.title = title
        self.tint = tint
        self.timing = timing
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.didFinishDisplaying = didFinishDisplaying
    }
}

extension LToastItem {
    enum RelativeDuration: CGFloat {
        case short = 1, medium = 3, long = 5
    }

    struct ToastAction {
        init(title: String? = nil, image: Image? = nil, tint: Color = .accent, action: (() -> Void)? = nil) {
            self.title = title
            self.image = image
            self.action = action
            self.tint = tint
        }

        let title: String?
        let image: Image?
        var tint: Color = .accent
        let action: (() -> Void)?
    }
}
