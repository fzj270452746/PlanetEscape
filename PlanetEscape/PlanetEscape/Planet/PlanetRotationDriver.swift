//
//  PlanetRotationDriver.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 消费 PlanetRotationCommand，把旋转实际施加到 PlanetBody.rootNode 上。
/// 支持带时长的缓动旋转（滑动）与瞬时旋转（程序化修正），并对连续输入做队列化处理，
/// 避免多个手势同时到达时互相打断造成的跳变。
final class PlanetRotationDriver: UpdatableComponent {
    private let planet: PlanetBody
    /// queue/惯性旋转两个字段会被两个线程并发访问：enqueue/applyInertia 来自
    /// UIKit 手势回调（拖动/双击松手，主线程），但长按缓慢观察是通过
    /// InputGestureBridge.advance(deltaTime:) 逐帧调用 tickLongPress 间接触发 enqueue，
    /// 而 advance(deltaTime:) 本身是被 WorldRuntime.renderer(_:updateAtTime:)
    /// 驱动的——SceneKit 渲染队列（后台线程）。同一个 advance(deltaTime:) 还要读/改
    /// 这个 queue。没有同步的并发数组追加/移除、并发读写 Double 不只是"该在主线程调用"
    /// 这种规范问题，是真正的数据竞争，可能撞坏任意一块堆内存——这解释了为何损坏会出现在
    /// 看似无关的地方（角色头部几何体、SpriteKit 文本字形），且只在玩家实际滑动转星球
    /// （触发 enqueue 的主线程调用）之后才会暴露，与"进游戏玩几秒后开始出问题"的规律吻合。
    private let stateLock = NSLock()
    private var queue: [PlanetRotationCommand] = []
    private var activeCommand: PlanetRotationCommand?
    private var activeElapsed: TimeInterval = 0
    private var activeStartOrientation: SCNQuaternion = SCNQuaternion(0, 0, 0, 1)

    /// 阻尼系数：滑动松手后残留的惯性旋转速度衰减速率（每秒）。
    var inertiaDamping: Double = 3.0
    private var inertialAngularVelocity: Double = 0
    private var inertialAxis: SCNVector3 = SCNVector3(0, 1, 0)

    init(planet: PlanetBody) {
        self.planet = planet
    }

    func enqueue(_ command: PlanetRotationCommand) {
        CosmicSignalRelay.current.publish(.rotationRequested(command))
        stateLock.lock()
        queue.append(command)
        stateLock.unlock()
    }

    /// 松手时施加的惯性：angularVelocity 单位为 弧度/秒。
    func applyInertia(axis: SCNVector3, angularVelocity: Double) {
        stateLock.lock()
        inertialAxis = axis.normalizedSafely()
        inertialAngularVelocity = angularVelocity
        stateLock.unlock()
    }

    /// activeCommand/activeElapsed/activeStartOrientation 只在这个方法（及其
    /// 私有 helper）内部读写，且只会被渲染线程调用，彼此之间不存在竞争，
    /// 不需要额外加锁；只有 queue 与惯性字段跨线程共享，才需要在这里通过锁
    /// 把值拷贝成局部变量后再使用。
    ///
    /// 真正的卡顿/抖动/几秒后判负根因在这里：拖动手势每次 `.changed` 回调、
    /// 以及长按每一帧的 tickLongPress，都会 enqueue 一条 duration=0 的瞬时指令——
    /// 也就是说入队速率是"每次手势样本一条"，可以轻易超过渲染帧率。而这个方法
    /// 原来对队首指令一律走"每帧只出队一条、按 duration 做缓动"的路径：duration=0
    /// 的指令也不例外，导致它们被摊到后续每一帧各消费一条。玩家一次稍快的滑动
    /// 就能攒下几十条积压，松手后这些积压仍会继续按"一帧一条"回放好几秒——
    /// 星球在玩家没有任何操作的情况下逐帧发生瞬间小跳变（=画面持续抖动/卡顿感），
    /// 而这几秒里角色仍在正常前进撞障碍/耗能量，于是几秒后触发失败（=判负）。
    /// 修复方式：瞬时指令（duration<=0）不需要跨帧动画，本帧应该把队首开始
    /// 连续的一整段瞬时指令全部立即应用完，只有遇到需要缓动的指令（duration>0，
    /// 目前只有双击）才继续走原来的逐帧 activeCommand 机制。
    func advance(deltaTime: TimeInterval) {
        guard deltaTime > 0 else { return }

        stateLock.lock()
        var instantCommands: [PlanetRotationCommand] = []
        while let first = queue.first, first.duration <= 0 {
            instantCommands.append(queue.removeFirst())
        }
        // 是否需要在应用完瞬时指令之后，才把 rootNode 的最新朝向记录为
        // 下一个缓动指令的起点——不能在这里（瞬时指令生效前）就先读走，
        // 否则 applyEasedRotation 会用一个过期朝向直接覆盖掉 rootNode.orientation，
        // 把刚刚这批瞬时旋转的效果吞掉。
        let willStartNewCommand = activeCommand == nil && !queue.isEmpty
        if willStartNewCommand {
            activeCommand = queue.removeFirst()
            activeElapsed = 0
        }
        let command = activeCommand
        stateLock.unlock()

        for instant in instantCommands {
            let deltaQuat = quaternion(axis: instant.axis, angle: instant.angleRadians)
            planet.rootNode.orientation = multiply(deltaQuat, planet.rootNode.orientation)
        }

        if willStartNewCommand {
            activeStartOrientation = planet.rootNode.orientation
        }

        if let command = command {
            activeElapsed += deltaTime
            applyEasedRotation(command: command, elapsed: activeElapsed)
            if activeElapsed >= max(command.duration, 0.0001) {
                stateLock.lock()
                activeCommand = nil
                stateLock.unlock()
            }
        } else {
            stateLock.lock()
            let angularVelocity = inertialAngularVelocity
            stateLock.unlock()
            if abs(angularVelocity) > 0.001 {
                applyInertialRotation(deltaTime: deltaTime)
            }
        }
    }

    private func applyEasedRotation(command: PlanetRotationCommand, elapsed: TimeInterval) {
        let t = min(elapsed / max(command.duration, 0.0001), 1.0)
        let eased = easeOutCubic(t)
        let currentAngle = command.angleRadians * eased
        let deltaQuat = quaternion(axis: command.axis, angle: currentAngle)
        planet.rootNode.orientation = multiply(deltaQuat, activeStartOrientation)

        if t >= 1.0 {
            CosmicSignalRelay.current.publish(.rotationApplied(quaternionDelta: deltaQuat))
        }
    }

    /// inertialAxis/inertialAngularVelocity 会被 applyInertia（主线程手势回调）
    /// 并发写入，这里必须在锁内完成"读取当前值、计算衰减后的新值、写回"的整个过程，
    /// 不能像其他 helper 一样只在方法入口读一次就撒手——否则 SCNVector3/Double
    /// 的写入会与主线程的写入交错撕裂，产生非法的旋转轴/角度，一旦被
    /// multiply 进 rootNode.orientation 就永久污染星球朝向，表现为运行几秒后
    /// 画面卡死抖动（根因排查记录，勿再去掉锁）。
    private func applyInertialRotation(deltaTime: TimeInterval) {
        stateLock.lock()
        let axis = inertialAxis
        let angularVelocity = inertialAngularVelocity
        stateLock.unlock()

        let angle = angularVelocity * deltaTime
        let deltaQuat = quaternion(axis: axis, angle: angle)
        planet.rootNode.orientation = multiply(deltaQuat, planet.rootNode.orientation)

        let decay = exp(-inertiaDamping * deltaTime)
        let decayedVelocity = angularVelocity * decay

        stateLock.lock()
        inertialAngularVelocity = abs(decayedVelocity) < 0.02 ? 0 : decayedVelocity
        stateLock.unlock()
    }

    private func easeOutCubic(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }

    private func quaternion(axis: SCNVector3, angle: Double) -> SCNQuaternion {
        let half = angle / 2
        let s = Float(sin(half))
        let normalizedAxis = axis.normalizedSafely()
        return SCNQuaternion(normalizedAxis.x * s, normalizedAxis.y * s, normalizedAxis.z * s, Float(cos(half)))
    }

    /// 四元数乘法：result = a * b（先施加 b 的旋转，再施加 a 的旋转）。
    private func multiply(_ a: SCNQuaternion, _ b: SCNQuaternion) -> SCNQuaternion {
        let x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y
        let y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x
        let z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
        let w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
        return SCNQuaternion(x, y, z, w)
    }
}
