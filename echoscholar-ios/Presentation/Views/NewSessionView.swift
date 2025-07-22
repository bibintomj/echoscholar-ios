//
//  NewSessionView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18.
//

import SwiftUI
import NetSwift
import AVFoundation

struct NewSessionView: View {
    @State private var transcript = ""
    @State private var translation = ""
    @State private var isRecording = false
    @State private var selectedLang = "es"
    @State private var status = "Ready"
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showPermissionAlert = false

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
            // Transcription section
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(transcript.isEmpty ? "Start recording to see transcription..." : transcript)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .foregroundColor(transcript.isEmpty ? .secondary : .primary)
                            .id("transcriptBottom")
                    }
                    .frame(height: 180)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(16)
                    .onChange(of: transcript) { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("transcriptBottom", anchor: .bottom)
                        }
                    }
                }
            }

            // Translation section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Translation")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                    
                    // Language picker
                    Picker("Translate to", selection: $selectedLang) {
                        ForEach(languages, id: \.0) { lang in
                            Text(lang.1).tag(lang.0)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(isRecording) // Disable while recording
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        Text(translation.isEmpty ? "Translation will appear here..." : translation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .foregroundColor(translation.isEmpty ? .secondary : .primary)
                            .id("translationBottom")
                    }
                    .frame(height: 180)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(16)
                    .onChange(of: translation) { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("translationBottom", anchor: .bottom)
                        }
                    }
                }
            }

            Spacer()
            
            // Record button
            ESButton(
                title: isRecording ? "Stop Recording" : "Start Recording",
                icon: isRecording ? "stop.circle.fill" : "mic.fill",
                type: isRecording ? .danger : .primary,
                isWide: true,
                action: {
                    isRecording ? stopRecording() : startRecording()
                }
            )
            .padding()
            .disabled(status == "Connecting..." || status == "Setting up audio...")
        }
        .padding()
        .background(Color("background.primary").ignoresSafeArea())
        .navigationTitle("New Session")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Recording Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Microphone Permission", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to record audio.")
        }
        .onDisappear {
            // Clean up when view disappears
            if isRecording {
                stopRecording()
            }
        }
        .onAppear {
            checkMicrophonePermission()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    // Handle favorite
                } label: {
                    // Status indicator
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        // Audio format indicator
                        if isRecording {
                            Text("WebM Opus")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case "Recording":
            return .red
        case "Connected", "Ready":
            return .green
        case "Connecting...", "Setting up audio...":
            return .orange
        default:
            return .gray
        }
    }
    
    private func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            break
        case .denied:
            showPermissionAlert = true
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if !granted {
                        showPermissionAlert = true
                    }
                }
            }
        @unknown default:
            break
        }
    }

    func startRecording() {
        // Check microphone permission first
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            showPermissionAlert = true
            return
        }
        
        guard let userId = supabase.auth.currentUser?.id else {
            showError(message: "User not authenticated")
            return
        }
        
        // Reset state
        transcript = ""
        translation = ""
        status = "Connecting..."
        
        // Create WebSocket connection
        let socket = WebSocketClient(url: URL(string: "ws://" + hostURL + ":8080")!)
        let newTranscriber = WebSocketTranscriber(
            socket: socket,
            languageCode: selectedLang,
            userId: userId.uuidString
        )

        // Set up callbacks
        newTranscriber.onTranscript = { newLine in
            DispatchQueue.main.async {
                if !transcript.isEmpty {
                    transcript += "\n"
                }
                transcript += newLine
            }
        }

        newTranscriber.onTranslation = { newLine in
            DispatchQueue.main.async {
                if !translation.isEmpty {
                    translation += "\n"
                }
                translation += newLine
            }
        }
        
        newTranscriber.onStatusChange = { newStatus in
            DispatchQueue.main.async {
                status = newStatus
                if newStatus == "Recording" {
                    isRecording = true
                }
            }
        }
        
        newTranscriber.onError = { error in
            DispatchQueue.main.async {
                showError(message: error)
                stopRecording()
            }
        }

        transcriber = newTranscriber
        newTranscriber.connect()
    }

    func stopRecording() {
        isRecording = false
        status = "Stopping..."
        
        transcriber?.disconnect()
        transcriber = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            status = "Ready"
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    NewSessionView()
}
