import Foundation
import AVFoundation

class AudioProcessor {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var format: AVAudioFormat?
    
    init() {}
    
    func startRecording(onBuffer: @escaping (Data) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else {
                completion(.failure(AudioProcessorError.setupFailed))
                return
            }
            
            inputNode = audioEngine.inputNode
            guard let inputNode = inputNode else {
                completion(.failure(AudioProcessorError.setupFailed))
                return
            }
            
            // Use the hardware's native format for the tap
            let inputFormat = inputNode.inputFormat(forBus: 0)
            print("Input format: \(inputFormat)")
            
            // Create our desired output format (16kHz, mono, 16-bit PCM) - THIS IS THE FIX
            guard let outputFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,  // Use 16-bit integer format
                sampleRate: inputFormat.sampleRate,
                channels: inputFormat.channelCount,
                interleaved: true
            ) else {
                completion(.failure(AudioProcessorError.setupFailed))
                return
            }
            print("Output format: \(outputFormat)")
            
            // Create format converter
            guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
                completion(.failure(AudioProcessorError.setupFailed))
                return
            }
            
            // Install tap with hardware's native format
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (buffer, _) in
                // Debug: Check if we're getting input data
                print("Received buffer with \(buffer.frameLength) frames")
                
                // Convert to desired format
                guard let convertedBuffer = self.convertBuffer(buffer, using: converter, to: outputFormat) else {
                    print("❌ Buffer conversion failed")
                    return
                }
                
                print("Converted buffer has \(convertedBuffer.frameLength) frames")
                
                // Convert to PCM data and send immediately
                let pcmData = convertedBuffer.toPCMData()
                print("PCM data size: \(pcmData.count) bytes")
                
                if pcmData.count > 0 {
                    DispatchQueue.main.async {
                        onBuffer(pcmData)
                    }
                } else {
                    print("⚠️ Empty PCM data generated")
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            completion(.success(()))
        } catch {
            print("❌ Audio setup error: \(error)")
            completion(.failure(error))
        }
    }
    
    private func convertBuffer(_ inputBuffer: AVAudioPCMBuffer, using converter: AVAudioConverter, to outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        let inputFrameCount = inputBuffer.frameLength
        
        // Calculate output frame count more carefully
        let sampleRateRatio = outputFormat.sampleRate / inputBuffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(inputFrameCount) * sampleRateRatio)
        
        guard outputFrameCount > 0 else {
            print("❌ Invalid output frame count: \(outputFrameCount)")
            return nil
        }
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount) else {
            print("❌ Failed to create output buffer")
            return nil
        }
        
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        if let error = error {
            print("❌ Conversion error: \(error)")
            return nil
        }
        
        if status == .error {
            print("❌ Conversion failed with error status")
            return nil
        }
        
        return outputBuffer
    }
    
    func stopRecording() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
}

extension AVAudioPCMBuffer {
    /// Convert PCM buffer to raw PCM data (16-bit signed little-endian)
    func toPCMData() -> Data {
        // Check if buffer has valid data
        guard self.frameLength > 0 else {
            print("⚠️ Empty frame length")
            return Data()
        }
        
        guard let channelData = self.int16ChannelData else {
            print("⚠️ No int16 channel data available")
            return Data()
        }
        
        let channelCount = Int(self.format.channelCount)
        guard channelCount > 0 else {
            print("⚠️ Invalid channel count: \(channelCount)")
            return Data()
        }
        
        let frameLength = Int(self.frameLength)
        let bytesPerFrame = channelCount * MemoryLayout<Int16>.size
        let totalBytes = frameLength * bytesPerFrame
        
        guard totalBytes > 0 else {
            print("⚠️ Invalid total bytes: \(totalBytes)")
            return Data()
        }
        
        // For mono audio, use the first channel
        let channelPtr = channelData[0]
        return Data(bytes: channelPtr, count: frameLength * MemoryLayout<Int16>.size)
    }
}

enum AudioProcessorError: Error, LocalizedError {
    case setupFailed
    case noRecordingFound
    case conversionFailed(code: Int32)
    
    var errorDescription: String? {
        switch self {
        case .setupFailed:
            return "Failed to setup audio recording"
        case .noRecordingFound:
            return "No recording found to convert"
        case .conversionFailed(let code):
            return "Audio conversion failed with code: \(code)"
        }
    }
}
