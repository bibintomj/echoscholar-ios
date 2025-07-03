//
//  LButton.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-2.
//

import SwiftUI

enum ButtonType {
    case primary
    case secondary
    case link
    case danger
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .accent
        case .secondary: return .clear
        case .link: return .clear
        case .danger: return .red
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return .brandDarkPrimary
        case .secondary: return .foregroundPrimary
        case .link: return .accent
        case .danger: return .white
        }
    }
    
    var borderColor: Color {
        switch self {
        case .secondary: return .foregroundPrimary
        default: return .clear
        }
    }
}

struct ESButton: View {
    let title: String?
    let icon: String?
    let type: ButtonType
    let isWide: Bool
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    // Customization options
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 12
    var cornerRadius: CGFloat = 20
    var borderWidth: CGFloat = 0.5
    var minWidth: CGFloat? = 44
    var minHeight: CGFloat? = 32
    
    var iconSize: CGFloat = 18
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: type.foregroundColor))
                } else {
                    if let icon = icon {
                        // Try to use the icon as an SF Symbol
                        if UIImage(systemName: icon) != nil {
                            // It's an SF Symbol
                            Image(systemName: icon)
                                .font(.system(size: iconSize, weight: .semibold))
                        } else {
                            // It's a custom asset image
                            Image(icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: iconSize, height: iconSize)
                        }
                    }

                    if let title {
                        Text(title)
                            .bold()
//                            .customFont(.primary, .headline)
                    }
                }
            }
            .frame(minWidth: minWidth, maxWidth: isWide ? .infinity : nil, minHeight: minHeight)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .foregroundColor(type.foregroundColor)
            .background(type.backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(type.borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isDisabled ? 0.4 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isPressed)
        }
        .disabled(isDisabled || isLoading)
        .pressAction {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

struct PressAction: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in onPress() })
                    .onEnded({ _ in onRelease() })
            )
    }
}

extension View {
    func pressAction(
        onPress: @escaping (() -> Void),
        onRelease: @escaping (() -> Void)
    ) -> some View {
        modifier(PressAction(onPress: onPress, onRelease: onRelease))
    }
}
