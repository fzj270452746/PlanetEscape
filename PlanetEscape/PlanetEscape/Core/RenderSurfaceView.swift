//
//  RenderSurfaceView.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 对 SCNView 的一个薄封装，集中配置抗锯齿/背景/统计信息等，
/// 避免这些渲染配置散落在 ViewController 里。
final class RenderSurfaceView: SCNView {
    func applyStandardConfiguration() {
        antialiasingMode = .multisampling4X
        backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.22, alpha: 1)
        rendersContinuously = true
        isPlaying = true
        preferredFramesPerSecond = 60
    }
}
