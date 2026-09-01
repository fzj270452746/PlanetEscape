//
//  ToneBufferFactory.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import AVFoundation

/// 纯数学生成 PCM 波形缓冲区的工具类型，供风声/旋转/黑洞/收集等
/// 程序化音效生成器共用，避免每个 Synth 都重复实现"写采样点到 AVAudioPCMBuffer"的样板代码。
struct ToneBufferFactory {
    static let sampleRate: Double = 44100

    /// 生成一段正弦波（可带频率随时间的线性滑变，用于收集音的音高上扬效果）。
    static func sineWave(
        duration: TimeInterval,
        startFrequency: Double,
        endFrequency: Double? = nil,
        amplitude: Double = 0.4
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let endFreq = endFrequency ?? startFrequency
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        var phase: Double = 0
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / Double(frameCount)
            let instantaneousFrequency = startFrequency + (endFreq - startFrequency) * t
            phase += 2 * Double.pi * instantaneousFrequency / sampleRate
            let envelope = envelopeValue(progress: t)
            channelData[frame] = Float(sin(phase) * amplitude * envelope)
        }
        return buffer
    }

    /// 生成白噪声（用于风声基底），加一个简单的低通感（相邻采样点平滑）模拟风声的柔和质感。
    static func filteredNoise(duration: TimeInterval, amplitude: Double = 0.15) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        var previous: Float = 0
        for frame in 0..<Int(frameCount) {
            let raw = Float.random(in: -1...1)
            let smoothed = previous * 0.85 + raw * 0.15
            previous = smoothed
            channelData[frame] = smoothed * Float(amplitude)
        }
        return buffer
    }

    /// 简单的淡入淡出包络，避免播放瞬间产生咔哒声。
    private static func envelopeValue(progress: Double) -> Double {
        let fadeFraction = 0.08
        if progress < fadeFraction { return progress / fadeFraction }
        if progress > 1 - fadeFraction { return (1 - progress) / fadeFraction }
        return 1
    }
}
