//
//  FontRegistry.swift
//  Lixor
//
//  Created by Bibin Joseph on 2025-04-24.
//

import SwiftUI

final class FontRegistry {
    static let shared = FontRegistry()
    private var registeredFonts = Set<String>()
    
    public func registerAllFonts() {
        DispatchQueue.global(qos: .userInitiated).async {
            let extensions = ["ttf", "otf"]
            extensions.forEach { self.registerFonts(withExtension: $0) }
        }
    }
    
    private func registerFonts(withExtension ext: String) {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) else { return }
        
        urls.forEach { url in
            guard let provider = CGDataProvider(url: url as CFURL),
                  let font = CGFont(provider),
                  CTFontManagerRegisterGraphicsFont(font, nil) else {
                print("Failed to register font: \(url.lastPathComponent)")
                return
            }
            registeredFonts.insert(font.postScriptName as String? ?? "")
        }
    }
    
    func isFontRegistered(_ name: String) -> Bool {
        registeredFonts.contains(name)
    }
    
    private func logRegisteredFonts() {
        print("Available Fonts:\n\(registeredFonts.sorted().joined(separator: "\n"))")
    }
}
