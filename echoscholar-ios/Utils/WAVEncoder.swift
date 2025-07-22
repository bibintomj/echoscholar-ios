//
//  WAVEncoder.swift
//  echoscholar-ios
//
//  Created by Bibin Joseph on 2025-07-03.
//

import Foundation
import AVFoundation

enum WAVEncoder {
    static func encode(buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> Data {
        guard let channelData = buffer.floatChannelData?[0] else {
            print("⚠️ Failed to get channel data")
            return Data()
        }
        
        let frameCount = Int(buffer.frameLength)
        let bytesPerSample = MemoryLayout<Float>.size
        let sampleRate = Int(format.sampleRate)
        let numChannels = Int(format.channelCount)
        
        var wavData = Data()
        
        // WAV header
        let byteRate = sampleRate * numChannels * bytesPerSample
        let blockAlign = numChannels * bytesPerSample
        let dataSize = frameCount * numChannels * bytesPerSample
        let riffChunkSize = 36 + dataSize
        
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(UInt32(riffChunkSize).littleEndianData)
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(UInt32(16).littleEndianData)                     // Subchunk1Size
        wavData.append(UInt16(3).littleEndianData)                      // AudioFormat = 3 (IEEE Float)
        wavData.append(UInt16(numChannels).littleEndianData)
        wavData.append(UInt32(sampleRate).littleEndianData)
        wavData.append(UInt32(byteRate).littleEndianData)
        wavData.append(UInt16(blockAlign).littleEndianData)
        wavData.append(UInt16(8 * bytesPerSample).littleEndianData)    // BitsPerSample
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(UInt32(dataSize).littleEndianData)
        
        // PCM float samples
        let samples = UnsafeBufferPointer(start: channelData, count: frameCount)
        wavData.append(Data(buffer: samples))
        
        return wavData
    }
    
    //    static func encode(rawPCM: Data, format: AVAudioFormat) -> Data {
    //        let sampleRate = Int(format.sampleRate)
    //        let numChannels = Int(format.channelCount)
    //        let bytesPerSample = MemoryLayout<Float>.size
    //        let dataSize = rawPCM.count
    //        let byteRate = sampleRate * numChannels * bytesPerSample
    //        let blockAlign = numChannels * bytesPerSample
    //        let riffChunkSize = 36 + dataSize
    //
    //        var wavData = Data()
    //        wavData.append("RIFF".data(using: .ascii)!)
    //        wavData.append(UInt32(riffChunkSize).littleEndianData)
    //        wavData.append("WAVE".data(using: .ascii)!)
    //        wavData.append("fmt ".data(using: .ascii)!)
    //        wavData.append(UInt32(16).littleEndianData) // PCM chunk size
    //        wavData.append(UInt16(3).littleEndianData)  // format = 3 (IEEE Float)
    //        wavData.append(UInt16(numChannels).littleEndianData)
    //        wavData.append(UInt32(sampleRate).littleEndianData)
    //        wavData.append(UInt32(byteRate).littleEndianData)
    //        wavData.append(UInt16(blockAlign).littleEndianData)
    //        wavData.append(UInt16(8 * bytesPerSample).littleEndianData)
    //        wavData.append("data".data(using: .ascii)!)
    //        wavData.append(UInt32(dataSize).littleEndianData)
    //        wavData.append(rawPCM)
    //
    //        return wavData
    //    }
    
    static func encode(rawPCM: Data, format: AVAudioFormat) -> Data {
        // Convert Float32 PCM buffer to Int16
        let floatArray = rawPCM.withUnsafeBytes {
            Array(UnsafeBufferPointer<Float>(start: $0.baseAddress!.assumingMemoryBound(to: Float.self), count: rawPCM.count / MemoryLayout<Float>.size))
        }
        
        // Print min/max for debugging
        print("PCM Min: \(floatArray.min() ?? 0), Max: \(floatArray.max() ?? 0)")
        
        var int16Array = [Int16]()
        for sample in floatArray {
            let clipped = max(-1.0, min(1.0, sample))
            int16Array.append(Int16(clipped * 32767))
        }
        let int16PCMData = Data(buffer: UnsafeBufferPointer(start: &int16Array, count: int16Array.count))
        
        let sampleRate = Int(format.sampleRate)
        let numChannels = Int(format.channelCount)
        let bytesPerSample = MemoryLayout<Int16>.size
        let dataSize = int16PCMData.count
        let byteRate = sampleRate * numChannels * bytesPerSample
        let blockAlign = numChannels * bytesPerSample
        let riffChunkSize = 36 + dataSize
        
        var wavData = Data()
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(UInt32(riffChunkSize).littleEndianData)
        wavData.append("WAVE".data(using: .ascii)!)
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(UInt32(16).littleEndianData) // PCM chunk size
        wavData.append(UInt16(1).littleEndianData)  // format = 1 (PCM)
        wavData.append(UInt16(numChannels).littleEndianData)
        wavData.append(UInt32(sampleRate).littleEndianData)
        wavData.append(UInt32(byteRate).littleEndianData)
        wavData.append(UInt16(blockAlign).littleEndianData)
        wavData.append(UInt16(8 * bytesPerSample).littleEndianData)
        wavData.append("data".data(using: .ascii)!)
        wavData.append(UInt32(dataSize).littleEndianData)
        wavData.append(int16PCMData)
        
        return wavData
    }
    
    
}

private extension FixedWidthInteger {
    var littleEndianData: Data {
        withUnsafeBytes(of: self.littleEndian) { Data($0) }
    }
}
