//
//  NewSessionView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18.
//

import SwiftUI
import NetSwift

struct NewSessionView: View {
    @State private var transcript = ""
    @State private var translation = ""
    @State private var isRecording = false
    @State private var selectedLang = "es"

    private let languages = [
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("hi", "Hindi"),
        ("zh", "Chinese"),
        ("ar", "Arabic")
    ]
    
    @State private var transcriber: WebSocketTranscriber?

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Transcription")
                    .foregroundColor(.gray)
                ScrollView {
                    Text(transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: 180)
                .background(Color.black.opacity(0.1))
                .cornerRadius(20)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Translation")
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $selectedLang) {
                        ForEach(languages, id: \.0) { lang in
                            Text(lang.1).tag(lang.0)
                        }
                    }
                    .pickerStyle(.menu)
                }

                ScrollView {
                    Text(translation)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: 180)
                .background(Color.black.opacity(0.1))
                .cornerRadius(20)
            }

            Spacer()
            
            ESButton(
                title: isRecording ? "Stop" : "Record",
                icon: isRecording ? "stop.circle.fill" : "mic.fill",
                type: isRecording ? .danger : .primary,
                isWide: true,
                action: {
                    isRecording ? stopRecording() : startRecording()
                }
            )
            .padding()
        }
        .padding()
        .navigationTitle("Recording")
    }

    func startRecording() {
        guard let userId = supabase.auth.currentUser?.id else { return }
        isRecording = true
        transcript = ""
        translation = ""

        let socket = WebSocketClient(url: URL(string: "ws://localhost:8080")!)
        let newTranscriber = WebSocketTranscriber(
            socket: socket,
            languageCode: selectedLang,
            userId: userId.uuidString
        )

        newTranscriber.onTranscript = { newLine in
            DispatchQueue.main.async {
                transcript += "\n" + newLine
            }
        }

        newTranscriber.onTranslation = { newLine in
            DispatchQueue.main.async {
                translation += "\n" + newLine
            }
        }

        transcriber = newTranscriber
        newTranscriber.connect()
    }

    func stopRecording() {
        isRecording = false
        transcriber?.disconnect()
        transcriber = nil
    }
}

#Preview {
    NewSessionView()
}
