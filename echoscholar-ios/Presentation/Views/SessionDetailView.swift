//
//  SessionDetailView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-03.
//

import SwiftUI
import AVFoundation
import UIKit
import WebKit

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SessionViewModel
    @State private var player: AVPlayer?
    @State private var isSharePresented = false
    @State private var shareContent: String = ""
    @State private var webView: WKWebView?
    @State private var useWebViewPlayer = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(viewModel: SessionViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Transcription
                SectionBox(title: "Transcription",
                           text: viewModel.selectedSession?.transcriptions?.content ?? "No transcription available",
                           onCopy: {
                               if let content = viewModel.selectedSession?.transcriptions?.content {
                                   UIPasteboard.general.string = content
                               }
                           },
                           onDownload: {
                               if let content = viewModel.selectedSession?.transcriptions?.content {
                                   shareContent = content
                                   isSharePresented = true
                               }
                           }
                )

                // Translation
                SectionBox(title: "Translation",
                           text: viewModel.selectedSession?.translations?.content ?? "No translation available",
                           onCopy: {
                               if let content = viewModel.selectedSession?.translations?.content {
                                   UIPasteboard.general.string = content
                               }
                           },
                           onDownload: {
                               if let content = viewModel.selectedSession?.translations?.content {
                                   shareContent = content
                                   isSharePresented = true
                               }
                           }
                )

                // Summary
                SectionBox(title: "Summary",
                           text: viewModel.selectedSession?.summaries?.content ?? "No summary available",
                           onCopy: {
                               if let content = viewModel.selectedSession?.summaries?.content {
                                   UIPasteboard.general.string = content
                               }
                           },
                           onDownload: {
                               if let content = viewModel.selectedSession?.summaries?.content {
                                   shareContent = content
                                   isSharePresented = true
                               }
                           }
                )

                // Audio Player
                if let audioUrlStr = viewModel.selectedSession?.audioSignedUrl, let url = URL(string: audioUrlStr) {
                    VStack {
                        // Check if it's a WebM file
                        if audioUrlStr.contains(".webm") {
                            // Use WebView for WebM files
                            WebViewAudioPlayer(url: url, viewModel: viewModel)
                                .frame(height: 64)
                        } else {
                            // Use AVPlayer for supported formats
                            VStack {
                                Slider(value: $viewModel.progress, in: 0...1)
                                    .accentColor(.green)
                                
                                HStack {
                                    Button(action: togglePlayPause) {
                                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.title)
                                            .foregroundColor(.green)
                                    }
                                    Text(timeFormatted(currentTime()))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(timeFormatted(player?.currentItem?.duration.seconds ?? 0))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.top, 8)
                            .onAppear {
                                setupAVPlayer(url: url)
                            }
                        }
                    }
                }

                if let mom = viewModel.generatedMoM {
                    SectionBox(title: "Minutes of Meeting",
                               text: mom,
                               onCopy: { UIPasteboard.general.string = mom },
                               onDownload: {
                                    shareContent = mom
                                    isSharePresented = true
                               }
                    )
                } else {
                    ESButton(
                        title: "Get Minute of Meeting",
                        icon: "doc.append",
                        type: .secondary,
                        isWide: true,
                        action: {
                            viewModel.getMoM()
                        }
                    )
                    .padding()
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.5 : 1)
                }
                
                
                Spacer()
            }
            .padding()
        }
        .background(Color("background.primary").ignoresSafeArea())
        .navigationTitle(viewModel.selectedSession?.transcriptions?.content.prefix(10) ?? "Untitled")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    // Handle favorite
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(activityItems: [shareContent])
        }
    }
    
    private func setupAVPlayer(url: URL) {
        // Only set the player if not already set or url changed
        if player == nil || player?.currentItem?.asset as? AVURLAsset != AVURLAsset(url: url) {
            player = AVPlayer(url: url)
            
            // Configure audio session for playback
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set audio session category: \(error)")
            }
            
            // Add time observer
            player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
                guard let duration = player?.currentItem?.duration.seconds, duration > 0, !duration.isNaN else { return }
                let currentTime = player?.currentTime().seconds ?? 0
                if !currentTime.isNaN && currentTime >= 0 {
                    viewModel.progress = currentTime / duration
                }
            }
            
            // Add notification for when playback ends
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
                viewModel.isPlaying = false
                player?.seek(to: .zero)
                viewModel.progress = 0
            }
        }
    }

    private func togglePlayPause() {
        guard let player = player else { return }
        viewModel.isPlaying.toggle()
        viewModel.isPlaying ? player.play() : player.pause()
    }

    private func currentTime() -> Double {
        player?.currentTime().seconds ?? 0
    }

    private func timeFormatted(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// WebView-based audio player for WebM files
struct WebViewAudioPlayer: UIViewRepresentable {
    let url: URL
    @ObservedObject var viewModel: SessionViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 10px;
                    background-color: transparent;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                audio {
                    width: 100%;
                    height: 30px;
                    background-color: transparent;
                    border-radius: 8px;
                }
                audio::-webkit-media-controls-panel {
                    background-color: #2c2c2c;
                }
            </style>
        </head>
        <body>
            <audio controls preload="auto">
                <source src="\(url.absoluteString)" type="audio/webm">
                <source src="\(url.absoluteString)" type="audio/ogg">
                Your browser does not support the audio element.
            </audio>
        </body>
        </html>
        """
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Web view finished loading
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView failed to load: \(error.localizedDescription)")
        }
    }
}

struct SectionBox: View {
    let title: String
    let text: String
    let onCopy: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Scrollable text box
            ScrollView(.vertical, showsIndicators: false) {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 60) // Height of header
                    .padding([.horizontal, .bottom])
            }
            .frame(minHeight: 180, maxHeight: 200)
            .background(Color("background.tertiary"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Overlay header with blur
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                        .frame(width: 34, height: 24)
                }
                Button(action: onDownload) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.secondary)
                        .frame(width: 34, height: 24)
                }
            }
            .padding(.leading)
            .padding(.trailing, 8)
            .frame(height: 44)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
            )
        }
        .padding(.vertical, 4)
    }
}

/// UIKit wrapper for ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SessionDetailView(viewModel: .init())
}
