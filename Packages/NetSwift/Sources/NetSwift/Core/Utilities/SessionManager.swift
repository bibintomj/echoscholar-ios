//
//  SessionManager.swift
//  NetSwift
//
//  Created by Bibin Joseph on 2025-04-04.
//

import Foundation
import Security

@MainActor
public final class SessionManager: Sendable {
    // MARK: - Shared Instance
    public static let shared = SessionManager()
    
    // MARK: - Notifications
    public static let didUpdateTokens = Notification.Name("SessionManager.didUpdateTokens")
    public static let didClearTokens = Notification.Name("SessionManager.didClearTokens")
    
    // MARK: - Private Properties
    private struct KeychainKeys {
        static let accessToken = "network.accessToken"
        static let refreshToken = "network.refreshToken"
    }
    
    private actor TokenStorage {
        private var _accessToken: String?
        private var _refreshToken: String?
        
        func getAccessToken() -> String? { _accessToken }
        func getRefreshToken() -> String? { _refreshToken }
        
        func setTokens(access: String?, refresh: String?) {
            _accessToken = access
            _refreshToken = refresh
        }
        
        func clear() {
            _accessToken = nil
            _refreshToken = nil
        }
    }
    
    private let storage = TokenStorage()
    
    // MARK: - Public Interface
    public var accessToken: String? {
        get async { await storage.getAccessToken() }
    }
    
    public var refreshToken: String? {
        get async { await storage.getRefreshToken() }
    }
    
    public var isAuthenticated: Bool {
        get async { await storage.getAccessToken() != nil }
    }
    
    private init() {
        Task {
            await loadInitialTokens()
        }
    }
    
    public func restore() {
        Task {
            await loadInitialTokens()
        }
    }
    
    public func invalidate() {
        Task {
            await clearTokens()
        }
    }
    
    // MARK: - Token Management
    public func setTokens(accessToken: String, refreshToken: String) async {
        await storage.setTokens(access: accessToken, refresh: refreshToken)
        await saveToKeychain(token: accessToken, key: KeychainKeys.accessToken)
        await saveToKeychain(token: refreshToken, key: KeychainKeys.refreshToken)
        await notifyTokenUpdate()
    }
    
    public func clearTokens() async {
        await storage.clear()
        await deleteFromKeychain(key: KeychainKeys.accessToken)
        await deleteFromKeychain(key: KeychainKeys.refreshToken)
        await notifyTokenUpdate()
        NotificationCenter.default.post(name: Self.didClearTokens, object: nil)
    }
    
    // MARK: - Private Methods
    private func loadInitialTokens() async {
        let accessToken = await loadFromKeychain(key: KeychainKeys.accessToken)
        let refreshToken = await loadFromKeychain(key: KeychainKeys.refreshToken)
        await storage.setTokens(access: accessToken, refresh: refreshToken)
    }
    
    private func saveToKeychain(token: String, key: String) async {
        guard let data = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save failed: \(status)")
        }
    }
    
    private func loadFromKeychain(key: String) async -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    private func deleteFromKeychain(key: String) async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    private func notifyTokenUpdate() async {
        let currentAccessToken = await accessToken
        let currentRefreshToken = await refreshToken
        
        NotificationCenter.default.post(
            name: Self.didUpdateTokens,
            object: nil,
            userInfo: [
                "accessToken": currentAccessToken as Any,
                "refreshToken": currentRefreshToken as Any
            ]
        )
    }
}
