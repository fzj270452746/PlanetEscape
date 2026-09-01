//
//  SurfacePhysicsCoordinator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 统一管理本游戏用到的物理分类掩码与碰撞判定辅助方法，
/// 让障碍/角色/收集品的物理体设置有一处权威来源，
/// 不必在每个 Obstacle 文件里各自重复定义位掩码常量。
struct SurfacePhysicsCoordinator {
    struct Category {
        static let explorer: Int = 1 << 0
        static let hazard: Int = 1 << 1
        static let collectible: Int = 1 << 2
        static let meteor: Int = 1 << 3
        static let platform: Int = 1 << 4
    }

    /// 给角色节点安装一个仅用于接触检测的物理体（kinematic，不受重力/碰撞位移影响，
    /// 因为角色的位置完全由 SphereSurfaceCoordinate 驱动，物理体只负责"感知"）。
    static func installExplorerContactBody(on node: SCNNode, radius: CGFloat) {
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: radius), options: nil)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = Category.explorer
        body.contactTestBitMask = Category.hazard | Category.collectible | Category.meteor
        body.collisionBitMask = 0
        node.physicsBody = body
    }

    /// 给静态障碍（火山口、激光发射器等不参与自由落体的对象）安装接触体。
    static func installStaticHazardBody(on node: SCNNode, shape: SCNPhysicsShape) {
        let body = SCNPhysicsBody(type: .static, shape: shape)
        body.categoryBitMask = Category.hazard
        body.contactTestBitMask = Category.explorer
        body.collisionBitMask = 0
        node.physicsBody = body
    }

    /// 给陨石等需要真实物理下落/反弹的对象安装动力学体。
    static func installDynamicMeteorBody(on node: SCNNode, radius: CGFloat, mass: CGFloat) {
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: radius), options: nil)
        let body = SCNPhysicsBody(type: .dynamic, shape: shape)
        body.mass = mass
        body.categoryBitMask = Category.meteor
        body.contactTestBitMask = Category.explorer
        body.collisionBitMask = 0
        node.physicsBody = body
    }

    static func installCollectibleBody(on node: SCNNode, radius: CGFloat) {
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: radius), options: nil)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = Category.collectible
        body.contactTestBitMask = Category.explorer
        body.collisionBitMask = 0
        node.physicsBody = body
    }
}
