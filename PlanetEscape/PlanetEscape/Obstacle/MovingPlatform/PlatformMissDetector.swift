//
//  PlatformMissDetector.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 文档 8.5："平台绕星球旋转，需要时间判断"。角色沿纬线自动前进，
/// 会周期性穿越移动平台所在的纬线带；这个检测器判断穿越瞬间角色是否与
/// 平台经度对齐（isAligned）。对齐 = 踩中平台，安全通过；不对齐 = 错过平台，
/// 触发一次失衡反馈。每次穿越只判定一次，用"是否已进入纬线带"的迟滞状态
/// 避免同一次穿越内重复触发。
final class PlatformMissDetector: UpdatableComponent {
    private let anchor: CharacterSurfaceAnchor
    private weak var hazards: HazardWorldAssembly?

    /// 判定"正在穿越纬线带"的角度容差（弧度）。
    var latitudeBandTolerance: Double = 0.08
    private var withinBandFlags: [String: Bool] = [:]

    init(anchor: CharacterSurfaceAnchor, hazards: HazardWorldAssembly) {
        self.anchor = anchor
        self.hazards = hazards
    }

    func advance(deltaTime: TimeInterval) {
        guard let hazards = hazards else { return }
        let platforms = hazards.registry.activeHazards.compactMap { $0 as? OrbitingPlatformDriver }
        guard !platforms.isEmpty else { return }

        let characterLatitude = anchor.surfaceCoordinate.latitude

        for platform in platforms {
            let platformLatitude = platform.surfaceCoordinate.latitude
            let isWithinBand = abs(characterLatitude - platformLatitude) < latitudeBandTolerance
            let wasWithinBand = withinBandFlags[platform.hazardID] ?? false

            if isWithinBand && !wasWithinBand {
                // 刚进入纬线带：这是一次穿越事件，判定是否踩中平台。
                if !platform.isAligned(with: anchor.surfaceCoordinate) {
                    CosmicSignalRelay.current.publish(.hazardContact(hazardID: platform.hazardID, kind: .movingPlatformMiss))
                }
            }
            withinBandFlags[platform.hazardID] = isWithinBand
        }
    }
}
