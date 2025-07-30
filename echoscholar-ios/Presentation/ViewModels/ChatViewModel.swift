//
//  ChatViewModel.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-30.
//

import Foundation

@MainActor
final class ChatViewModel: BaseViewModel {
    @Published var messages: [Chat.Message] = []
    @Published var input: String = ""
    @Published var isStreaming: Bool = false
    
    private let chatService: ChatService
    
    init(chatService: ChatService = ChatService()) {
        self.chatService = chatService
        super.init()
    }
    
    func send() {
        let userMessage = Chat.Message(role: "user", content: input)
        messages.append(userMessage)
        input = ""
        
        isStreaming = true
        Task {
            await streamChat(message: userMessage)
            isStreaming = false
        }
    }
    
    private func streamChat(message: Chat.Message) async {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            return
        }

        let request = Chat.Request(userId: userId, messages: messages)

        let empty = Chat.Message(role: "assistant", content: "")
        messages.append(empty)
        let index = messages.count - 1

        do {
            try await chatService.streamChatMessages(request: request) { [weak self] delta in
                guard let self = self else { return }
                print("DELTA: ", delta)
                DispatchQueue.main.async {
                    self.messages[index].content += delta
                }
            }
        } catch {
            messages.append(Chat.Message(role: "assistant", content: "❌ Error: \(error.localizedDescription)"))
        }
    }

}
