//
//  FontManager.swift
//  Lixor
//
//  Created by Bibin Joseph on 2025-04-24.
//

import SwiftUI

enum FontWeight: String {
    case regular, bold, semibold, medium, light, extralight, black, extrabold
    case italic, boldItalic, semiboldItalic, mediumItalic, lightItalic, extralightItalic, blackItalic, extraboldItalic
}

enum FontFamily {
    case standard
    case dyslexic
    
    func name(for weight: FontWeight) -> String {
        switch self {
        case .standard:
            return "Lexend-\(weight.rawValue.capitalized)"
        case .dyslexic:
            return "Lexend-\(weight.rawValue.capitalized)"
        }
    }
}

struct AppFont {
    let family: FontFamily
    let weight: FontWeight
    let size: CGFloat
    let textStyle: Font.TextStyle?
    
    // MARK: - Core Font Generator
    func font() -> Font {
        let fontName = family.name(for: weight)
        
        guard FontRegistry.shared.isFontRegistered(fontName) else {
            return textStyle.map { Font.system($0) } ?? Font.system(size: size)
        }
        
        return textStyle.map { Font.custom(fontName, size: size, relativeTo: $0) }
                     ?? Font.custom(fontName, fixedSize: size)
    }
    
    // MARK: - Convenience Initializers
    /// Style 1: Specify family and text style (uses predefined weights/sizes)
    static func style(_ family: FontFamily, _ textStyle: Font.TextStyle) -> AppFont {
        switch textStyle {
        case .largeTitle:
            return AppFont(family: family, weight: .bold, size: 34, textStyle: textStyle)
        case .title:
            return AppFont(family: family, weight: .bold, size: 28, textStyle: textStyle)
        case .title2:
            return AppFont(family: family, weight: .semibold, size: 22, textStyle: textStyle)
        case .title3:
            return AppFont(family: family, weight: .semibold, size: 20, textStyle: textStyle)
        case .headline:
            return AppFont(family: family, weight: .semibold, size: 17, textStyle: textStyle)
        case .subheadline:
            return AppFont(family: family, weight: .medium, size: 15, textStyle: textStyle)
        case .body:
            return AppFont(family: family, weight: .regular, size: 17, textStyle: textStyle)
        case .callout:
            return AppFont(family: family, weight: .regular, size: 16, textStyle: textStyle)
        case .footnote:
            return AppFont(family: family, weight: .light, size: 13, textStyle: textStyle)
        case .caption:
            return AppFont(family: family, weight: .light, size: 12, textStyle: textStyle)
        case .caption2:
            return AppFont(family: family, weight: .light, size: 11, textStyle: textStyle)
        @unknown default:
            return AppFont(family: family, weight: .regular, size: 17, textStyle: .body)
        }
    }
    
    /// Style 2: Specify family, weight, and fixed size
    static func custom(_ family: FontFamily, weight: FontWeight, size: CGFloat) -> AppFont {
        AppFont(family: family, weight: weight, size: size, textStyle: nil)
    }
    
    /// Style 3: Specify family, weight, and text style
    static func custom(_ family: FontFamily, weight: FontWeight, textStyle: Font.TextStyle) -> AppFont {
        let baseSize: CGFloat
        switch textStyle {
        case .largeTitle: baseSize = 34
        case .title: baseSize = 28
        case .title2: baseSize = 22
        case .title3: baseSize = 20
        case .headline: baseSize = 17
        case .subheadline: baseSize = 15
        case .body: baseSize = 17
        case .callout: baseSize = 16
        case .footnote: baseSize = 13
        case .caption: baseSize = 12
        case .caption2: baseSize = 11
        @unknown default: baseSize = 17
        }
        return AppFont(family: family, weight: weight, size: baseSize, textStyle: textStyle)
    }
}

// MARK: - Semantic Typography (Bonus)
extension AppFont {
    // Primary font presets
    static let title = style(.standard, .title)
    static let headline = style(.standard, .headline)
    static let body = style(.standard, .body)
    static let caption = style(.standard, .caption)
    
    // Secondary font presets
//    static let accentTitle = custom(.secondary, weight: .bold, textStyle: .title)
}

extension AppFont {
    func uiFont() -> UIFont {
        let fontName = family.name(for: weight)
        
        guard FontRegistry.shared.isFontRegistered(fontName),
              let customUIFont = UIFont(name: fontName, size: size) else {
            return UIFont.systemFont(ofSize: size)
        }
        
        return customUIFont
    }
}

// MARK: - View Extension
extension View {
    /// Main font modifier
    func customFont(_ font: AppFont) -> some View {
        self.font(font.font())
    }
    
    /// Convenience for Style 1
    func customFont(_ family: FontFamily, _ textStyle: Font.TextStyle) -> some View {
        self.font(AppFont.style(family, textStyle).font())
    }
    
    /// Convenience for Style 2
    func customFont(_ family: FontFamily, weight: FontWeight, size: CGFloat) -> some View {
        self.font(AppFont.custom(family, weight: weight, size: size).font())
    }
    
    /// Convenience for Style 3
    func customFont(_ family: FontFamily, weight: FontWeight, textStyle: Font.TextStyle) -> some View {
        self.font(AppFont.custom(family, weight: weight, textStyle: textStyle).font())
    }
}
