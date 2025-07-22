//
//  NewSessionView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-06-18.
//

import SwiftUI
import AVFoundation
import Translation

struct NewSessionView: View {
    @StateObject private var viewModel = SessionViewModel()
    @State private var transcript = ""
    @State private var translation = ""
    @State private var isRecording = false
    @State private var status = "Ready"
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPermissionAlert = false

    private let languages = [
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("hi", "Hindi"),
        ("zh-Hans", "Chinese"),
        ("ar", "Arabic")
    ]

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
                    Picker("Translate to", selection: $viewModel.selectedLang) {
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
            // Setup translation when view appears, but don't force it
            viewModel.setupInitialTranslation()
        }
        // Remove the onChange for selectedLang - let the viewModel handle it
        .onReceive(viewModel.$transcript) { newTranscript in
            transcript = newTranscript
        }
        .onReceive(viewModel.$translation) { newTranslation in
            translation = newTranslation
        }
        .onReceive(viewModel.$status) { newStatus in
            status = newStatus
            if newStatus == "Recording" {
                isRecording = true
            } else if newStatus == "Ready" {
                isRecording = false
            }
        }
        .onReceive(viewModel.$errorMessage) { error in
            if let error = error {
                errorMessage = error
                showError = true
            }
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
                            Text("PCM")
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
        .translationTask(viewModel.translationConfiguration) { session in
            await viewModel.translateSequence(session)
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
        
        // Reset state
        transcript = ""
        translation = ""
        viewModel.startRecording()
    }

    func stopRecording() {
        viewModel.stopRecording()
    }
}

#Preview {
    NewSessionView()
}
