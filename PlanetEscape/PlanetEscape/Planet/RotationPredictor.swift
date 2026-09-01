//
//  RotationPredictor.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 实现文档第 19 节 "Rotation Prediction"：
/// 给定一次即将施加的 PlanetRotationCommand，预测角色（沿世界固定路径前进）
/// 在旋转完成后会落在星球本地坐标系的哪个位置，而不需要真的先转一遍再算。
/// 与 PlanetBody.projectWorldToLocal 使用完全一致的数学模型（假设的未来朝向
/// = command 对应的增量四元数 * 星球当前朝向），保证预测结果与旋转真正生效后
/// ExplorerMotionUnit 实际算出的坐标一致，可用于"提前预警前方危险"等教学/辅助功能。
struct RotationPredictor {
    /// 世界坐标下角色当前位置（星球中心为世界原点时，等于局部坐标；
    /// 若星球在世界中有偏移，调用方需先转换到星球局部空间再传入）。
    func predictWorldPosition(
        currentLocalPosition: SCNVector3,
        command: PlanetRotationCommand
    ) -> SCNVector3 {
        let axis = command.axis.normalizedSafely()
        let angle = Float(command.angleRadians)
        return rotate(point: currentLocalPosition, aroundAxis: axis, angle: angle)
    }

    /// 预测角色沿世界固定路径前进时，在这次旋转指令完成后会落在星球本地坐标系的哪个位置。
    /// currentOrientation 是星球当前的朝向四元数（PlanetBody.rootNode.orientation）。
    func predictSurfaceCoordinate(
        worldPathCoordinate: SphereSurfaceCoordinate,
        planetRadius: Double,
        currentOrientation: SCNQuaternion,
        command: PlanetRotationCommand
    ) -> SphereSurfaceCoordinate {
        let deltaQuat = axisAngleQuaternion(axis: command.axis, angleRadians: command.angleRadians)
        let predictedOrientation = QuaternionRotationMath.multiply(deltaQuat, currentOrientation)
        let inverseOrientation = QuaternionRotationMath.conjugate(predictedOrientation)

        let worldCartesian = worldPathCoordinate.cartesian(radius: planetRadius)
        let localCartesian = QuaternionRotationMath.rotate(worldCartesian, by: inverseOrientation)
        return SphereSurfaceCoordinate.from(cartesian: localCartesian)
    }

    private func axisAngleQuaternion(axis: SCNVector3, angleRadians: Double) -> SCNQuaternion {
        let half = angleRadians / 2
        let s = Float(sin(half))
        let normalizedAxis = axis.normalizedSafely()
        return SCNQuaternion(normalizedAxis.x * s, normalizedAxis.y * s, normalizedAxis.z * s, Float(cos(half)))
    }

    /// 罗德里格斯旋转公式：绕单位轴 axis 旋转 angle 弧度。
    private func rotate(point: SCNVector3, aroundAxis axis: SCNVector3, angle: Float) -> SCNVector3 {
        let cosA = cos(angle)
        let sinA = sin(angle)

        let dot = axis.x * point.x + axis.y * point.y + axis.z * point.z
        let crossX = axis.y * point.z - axis.z * point.y
        let crossY = axis.z * point.x - axis.x * point.z
        let crossZ = axis.x * point.y - axis.y * point.x

        let termAx = point.x * cosA
        let termAy = point.y * cosA
        let termAz = point.z * cosA

        let termBx = crossX * sinA
        let termBy = crossY * sinA
        let termBz = crossZ * sinA

        let scale = dot * (1 - cosA)
        let termCx = axis.x * scale
        let termCy = axis.y * scale
        let termCz = axis.z * scale

        return SCNVector3(termAx + termBx + termCx, termAy + termBy + termCy, termAz + termBz + termCz)
    }
}
