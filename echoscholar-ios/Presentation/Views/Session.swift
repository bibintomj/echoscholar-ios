//
//  Session.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18.
//

import Foundation

struct Session: Identifiable {
    let id = UUID()
    let title: String
    let timestampText: String
}
