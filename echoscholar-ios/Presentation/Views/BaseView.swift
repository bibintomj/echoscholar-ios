//
//  BaseView.swift
//  echoscholar-ios
//
//  Created by Bibin on 2025-06-02.
//

import SwiftUI

protocol BaseView: View {
    associatedtype VM: BaseViewModel
    var viewModel: VM { get }
}
