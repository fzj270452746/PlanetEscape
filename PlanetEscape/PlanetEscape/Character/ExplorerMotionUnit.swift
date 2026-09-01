//
//  ExplorerMotionUnit.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 角色自动前进的驱动器（文档反雷同要求：不叫 PlayerController，
/// 因为玩家并不直接控制这个单位——它自己一直往前走，玩家控制的是星球）。
/// 每帧沿 OrbitalPathCalculator 计算出的前进方向推进 surfaceCoordinate，
/// 并通过 CosmicSignalRelay 广播位移事件供 HUD/难度系统订阅。
final class ExplorerMotionUnit: UpdatableComponent {
    private let anchor: CharacterSurfaceAnchor
    private let planet: PlanetBody

    /// 前进速度，单位：世界单位/秒（与星球半径同量纲）。
    var forwardSpeed: Double = 1.4
    private(set) var totalDistanceTravelled: Double = 0
    private(set) var isRunning = true

    /// 角色实际前进的轨迹坐标，定义在"世界固定参考系"下——它只随时间单调推进
    /// （纬度递增），完全不受星球当前朝向影响。这是修复核心玩法的关键：
    /// 如果角色前进方向绑定在星球本地坐标系里，那么"整体刚体旋转星球"不会改变
    /// 子节点间的相对位置，玩家转不转星球，角色撞不撞上某个障碍物都不受影响。
    /// 现在角色始终沿着世界固定的大圆前进，每帧再把这条世界路径投影成
    /// 星球当前朝向下的本地坐标（anchor.surfaceCoordinate），玩家旋转星球
    /// 就是在改变"同一条世界路径"对应到哪一段本地危险区域——这才是"转星球=改路线"。
    private(set) var worldPathCoordinate: SphereSurfaceCoordinate

    /// 角色沿世界固定路径前进的方向（笛卡尔切向量），作为持久化状态每帧用
    /// "平行移动"更新，而不是每帧从 worldPathCoordinate 用 forwardTangent() 重新反推——
    /// 后者在南北极附近必然出现方向不连续（拓扑上的毛球定理推论），会导致角色卡在
    /// 极点反复横跳，见 OrbitalPathCalculator.advance 的详细说明。
    private(set) var worldForwardDirection: SCNVector3

    /// 由 HazardWorldAssembly 注入：查询角色当前坐标是否处于重力异常区内，
    /// 返回应叠加的速度倍率（默认 1.0，即无影响）。用闭包而非直接持有
    /// HazardRegistry 引用，避免 Character 模块反向依赖 Obstacle 模块。
    var speedMultiplierProvider: ((SphereSurfaceCoordinate) -> Double)?

    init(anchor: CharacterSurfaceAnchor, planet: PlanetBody) {
        self.anchor = anchor
        self.planet = planet
        self.worldPathCoordinate = anchor.surfaceCoordinate
        self.worldForwardDirection = anchor.surfaceCoordinate.forwardTangent()
    }

    func pause() { isRunning = false }
    func resume() { isRunning = true }

    /// 开启一局全新的游玩（无论是 Adventure loadLevel 还是 Endless startRun）都必须调用：
    /// totalDistanceTravelled 之前从没有任何地方重置过，如果上一局（哪怕是另一种模式）
    /// 已经跑出很大的距离，残留值会让新一局里 AdventureLevelDirector.advance() 的
    /// "distance >= targetDistance" 判断在还没真正开始跑的时候就被错误触发，
    /// 导致角色被永久 pause + 切到 celebrating 动画（无限旋转，见 TinyBotAnimationDriver
    /// .driveCelebrationSpin）。同时把世界路径基准点重新对齐到角色当前位置，
    /// 语义等价于 init 时的初始化，保证新一局从"这里"开始重新计算路径。
    func reset() {
        totalDistanceTravelled = 0
        worldPathCoordinate = anchor.surfaceCoordinate
        worldForwardDirection = anchor.surfaceCoordinate.forwardTangent()
    }

    func advance(deltaTime: TimeInterval) {
        guard isRunning, deltaTime > 0 else { return }
        let multiplier = speedMultiplierProvider?(anchor.surfaceCoordinate) ?? 1.0
        let arcLength = forwardSpeed * multiplier * deltaTime

        let result = planet.pathCalculator.advance(from: worldPathCoordinate, direction: worldForwardDirection, arcLength: arcLength)
        worldPathCoordinate = result.coordinate
        worldForwardDirection = result.direction
        // forwardDirection 必须和 surfaceCoordinate 一起、在同一帧内更新到最新值——
        // 顺序无所谓（两者的 didSet 都会重新 syncTransform，多算一次没有正确性问题），
        // 但绝不能只更新坐标不更新方向，否则角色朝向仍会用上一帧的本地方向，
        // 在星球旋转较快时出现朝向与实际前进方向脱节的瞬间抖动。
        anchor.forwardDirection = planet.projectWorldDirectionToLocal(worldForwardDirection)
        anchor.surfaceCoordinate = planet.projectWorldToLocal(worldPathCoordinate)
        totalDistanceTravelled += arcLength

        CosmicSignalRelay.current.publish(
            .explorerAdvanced(
                longitude: anchor.surfaceCoordinate.longitude,
                latitude: anchor.surfaceCoordinate.latitude,
                distanceTravelled: totalDistanceTravelled
            )
        )
    }
}
