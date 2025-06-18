//
//  Extensions.swift
//  Lixor
//
//  Created by Bibin Joseph on 2025-04-24.
//

import SwiftUI

func runOnMain(_ timeinterval: TimeInterval = 0, completion: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + timeinterval, execute: completion)
}

extension Color {
    static var seperator: Color {
        Color(uiColor: .separator)
    }
    
    static var background: Color {
        Color(uiColor: .systemGroupedBackground)
    }
    
    static var elevatedCardBackground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
}

var isSwiftUIPreview: Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
        return false
#endif
}

extension Optional {
    var isNil: Bool { self == nil }

    var isNotNil: Bool { !isNil }
}

extension Color {
    init(hex: String) {
        var string: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.hasPrefix("#") {
            _ = string.removeFirst()
        }

        // Double the last value if incomplete hex
        if !string.count.isMultiple(of: 2), let last = string.last {
            string.append(last)
        }

        // Fix invalid values
        if string.count > 8 {
            string = String(string.prefix(8))
        }

        // Scanner creation
        let scanner = Scanner(string: string)

        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        if string.count == 2 {
            let mask = 0xFF

            let g = Int(color) & mask

            let gray = Double(g) / 255.0

            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)

        } else if string.count == 4 {
            let mask = 0x00FF

            let g = Int(color >> 8) & mask
            let a = Int(color) & mask

            let gray = Double(g) / 255.0
            let alpha = Double(a) / 255.0

            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)

        } else if string.count == 6 {
            let mask = 0x0000FF
            let r = Int(color >> 16) & mask
            let g = Int(color >> 8) & mask
            let b = Int(color) & mask

            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0

            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)

        } else if string.count == 8 {
            let mask = 0x000000FF
            let r = Int(color >> 24) & mask
            let g = Int(color >> 16) & mask
            let b = Int(color >> 8) & mask
            let a = Int(color) & mask

            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0
            let alpha = Double(a) / 255.0

            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)

        } else {
            self.init(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        }
    }

    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
#if canImport(UIKit)
        typealias NativeColor = UIColor
#elseif canImport(AppKit)
        typealias NativeColor = NSColor
#endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o)
        return (r, g, b, o)
    }

    var hex: String {
        String(
            format: "#%02x%02x%02x%02x",
            Int(components.red * 255),
            Int(components.green * 255),
            Int(components.blue * 255),
            Int(components.opacity * 255)
        )
    }
}

extension View {
#if canImport(UIKit)
    @available(iOS 14, *)
    func navigationBarTitle(_ color: Color?) -> some View {
        var titleAttributes: [NSAttributedString.Key: Any] = [:]
        var largeTitleAttributes: [NSAttributedString.Key: Any] = [:]
        if let color {
            titleAttributes[.foregroundColor] = UIColor(color)
            largeTitleAttributes[.foregroundColor] = UIColor(color)
        }
//        titleAttributes[.font] = AppFont.custom(.primary, weight: .bold, textStyle: .title).uiFont()
//        largeTitleAttributes[.font] = AppFont.custom(.primary, weight: .bold, textStyle: .largeTitle).uiFont()

        UINavigationBar.appearance().titleTextAttributes = titleAttributes
        UINavigationBar.appearance().largeTitleTextAttributes = largeTitleAttributes

        return self
    }

    func navigationBarCustomFont() -> some View {
        var titleAttributes: [NSAttributedString.Key: Any] = [:]
        var largeTitleAttributes: [NSAttributedString.Key: Any] = [:]
//        titleAttributes[.font] = AppFont.custom(.primary, weight: .bold, textStyle: .title3).uiFont()
//        largeTitleAttributes[.font] = AppFont.custom(.primary, weight: .bold, textStyle: .largeTitle).uiFont()
        UINavigationBar.appearance().titleTextAttributes = titleAttributes
        UINavigationBar.appearance().largeTitleTextAttributes = largeTitleAttributes
        UINavigationBar.appearance().setTitleVerticalPositionAdjustment(5, for: .default)
        return self
    }
    
   
#endif

    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}

func clearBackButtonTitle() {
#if canImport(UIKit)
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
    appearance.backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
    appearance.backButtonAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.clear]

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
#endif
}

extension UIApplication {
    func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow }?.rootViewController

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
}
