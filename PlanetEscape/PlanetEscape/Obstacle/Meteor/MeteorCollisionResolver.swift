//
//  MeteorCollisionResolver.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 订阅物理接触事件，专门处理"陨石落地"（撞到星球表面而非角色）的情况——
/// 落地后陨石应该标记为可回收，而不是无限存在。
/// 与 hazardContact(kind: .meteor) 事件（陨石撞角色，走 TinyBotBalanceComponent 逃脱流程）分开处理，
/// 这里只关心陨石自身的生命周期终结条件。
final class MeteorCollisionResolver {
    private weak var planet: PlanetBody?

    /// 每帧检查陨石与星球表面的实际距离，比订阅碰撞事件更可靠
    /// （因为陨石落到地表是 dynamic-vs-static 碰撞，不总是产生我们关心的 contact 回调时机）。
    private var monitoredMeteors: [MeteorObject] = []

    init(planet: PlanetBody) {
        self.planet = planet
    }

    func monitor(_ meteor: MeteorObject) {
        monitoredMeteors.append(meteor)
    }

    func advance(deltaTime: TimeInterval) {
        guard let planet = planet else { return }
        for meteor in monitoredMeteors where !meteor.hasLanded {
            let distanceFromCenter = length(meteor.rootNode.position)
            if distanceFromCenter <= planet.radius + 0.05 {
                meteor.markLanded()
            }
        }
        monitoredMeteors.removeAll { $0.hasLanded }
    }

    private func length(_ v: SCNVector3) -> Double {
        sqrt(Double(v.x * v.x + v.y * v.y + v.z * v.z))
    }
}
