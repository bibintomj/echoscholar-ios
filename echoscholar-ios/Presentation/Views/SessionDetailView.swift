//
//  SessionDetailsView.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-03.
//

import SwiftUI
import AVFoundation

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SessionViewModel
    @State var player: AVPlayer?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(viewModel: SessionViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Transcription
            Text("Transcription")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView {
                Text(viewModel.selectedSession?.transcriptions?.first?.content ?? "No transcription available")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color("background.tertiary"))
                    .cornerRadius(16)
            }
            .frame(maxHeight: 200)
            
            // Translation
            Text("Translation")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView {
                Text(viewModel.selectedSession?.translations?.first?.content ?? "No translation available")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color("background.tertiary"))
                    .cornerRadius(16)
            }
            .frame(maxHeight: 200)
            
            // Audio Player
            if let audioUrlStr = viewModel.selectedSession?.audioSignedUrl, let url = URL(string: audioUrlStr) {
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
                    player = AVPlayer(url: url)

                    // Observe time to update slider
                    player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
                        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
                        let currentTime = player?.currentTime().seconds ?? 0
                        viewModel.progress = currentTime / duration
                    }
                }
            }


            Spacer()
        }
        .padding()
        .background(Color("background.primary").ignoresSafeArea())
        .navigationTitle(viewModel.selectedSession?.transcriptions?.first?.content.prefix(10) ?? "Untitled")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            // Download & Favorite Buttons
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    // Handle download
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }

                Button {
                    // Handle favorite
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
            }
        }
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        viewModel.isPlaying.toggle()
        viewModel.isPlaying ? player.play() : player.pause()
    }
    
    private func updateProgress() {
        guard let player = player, let duration = player.currentItem?.duration.seconds, duration > 0 else { return }
        viewModel.progress = player.currentTime().seconds / duration
    }
    
    private func currentTime() -> Double {
        player?.currentTime().seconds ?? 0
    }

    private func timeFormatted(_ seconds: Double) -> String {
        guard !seconds.isNaN else { return "" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}


#Preview {
    SessionDetailView(viewModel: .init())
}
