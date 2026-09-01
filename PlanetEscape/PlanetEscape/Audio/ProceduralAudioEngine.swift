//
//  ProceduralAudioEngine.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import AVFoundation

/// 对 AVAudioEngine 的薄封装：持有引擎与一组可复用的 AVAudioPlayerNode，
/// 具体音色生成（风声/旋转/黑洞/收集音）由各个 XxxGenerator/Synth 类型实现，
/// 它们都通过这个引擎播放，而不是各自创建独立的 AVAudioEngine 实例。
final class ProceduralAudioEngine {
    let engine = AVAudioEngine()
    let mixer: AVAudioMixerNode

    private(set) var isRunning = false

    init() {
        mixer = engine.mainMixerNode
    }

    func start() {
        guard !isRunning else { return }
        do {
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.stop()
        isRunning = false
    }

    /// 创建一个已挂接到主混音器的播放节点，供各音效生成器复用。
    /// 必须显式指定单声道格式并与 ToneBufferFactory 生成的 buffer 保持一致——
    /// 若传 format: nil，播放节点会采用默认立体声格式，
    /// 之后 scheduleBuffer 一个单声道 buffer 时通道数不匹配会直接崩溃。
    func makePlayerNode() -> AVAudioPlayerNode {
        let node = AVAudioPlayerNode()
        engine.attach(node)
        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: ToneBufferFactory.sampleRate, channels: 1)
        engine.connect(node, to: mixer, format: monoFormat)
        return node
    }
}
