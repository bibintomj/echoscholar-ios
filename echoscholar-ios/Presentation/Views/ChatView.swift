//
//  ChatView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-30.
//

import SwiftUI

struct ChatView: View {
    @StateObject var viewModel = ChatViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen scroll view with blurred message background
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages.indices, id: \.self) { index in
                            let msg = viewModel.messages[index]
                            HStack {
                                if msg.role == "user" {
                                    Spacer()
                                    Text(msg.content)
                                        .padding()
                                        .background(Color.accent)
                                        .foregroundColor(.black)
                                        .cornerRadius(20)
                                } else {
                                    Text(msg.content)
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(20)
                                    Spacer()
                                }
                            }
                            .id(index)
                        }

                        // ✅ Spacer to prevent overlap with input bar
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 80) // Adjust based on input bar height
                    }
                    .padding()

                }
                .background(Color.backgroundPrimary)
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.count - 1, anchor: .bottom)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Input bar overlayed at the bottom
            HStack(spacing: 12) {
                TextField("Talk to EchoScholar...", text: $viewModel.input)
                        .padding(12)
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onSubmit {
                            viewModel.send()
                        }
                
                if viewModel.isStreaming {
                    ProgressView()
                } else {
                    Button(action: {
                        viewModel.send()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding([.horizontal, .bottom])
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle("EchoScholar Chat")
    }

}


#Preview {
    ChatView()
}
