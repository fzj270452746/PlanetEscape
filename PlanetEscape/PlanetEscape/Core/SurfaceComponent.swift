//
//  SurfaceComponent.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 标记协议：任何依附在星球表面（用经纬度定位）的组件都实现它，
/// 使 OrbitalPathCalculator、HazardRegistry 等可以统一按“表面对象”处理，
/// 而不必关心具体是角色、障碍物还是收集品。
protocol SurfaceComponent: AnyObject {
    var surfaceCoordinate: SphereSurfaceCoordinate { get set }
    /// 表面对象的包围半径（弧度制，用于粗略碰撞/接近检测）。
    var surfaceFootprint: Double { get }
}

/// 一个组件容器，实现最小化的 Component Architecture：
/// 节点通过挂载若干实现 UpdatableComponent 的对象获得行为，
/// 而不是让某个巨型类同时负责移动、动画、碰撞判定等所有事情。
final class ComponentHost {
    private var components: [ObjectIdentifier: AnyObject] = [:]
    private var updatables: [UpdatableComponent] = []

    func install<T: AnyObject>(_ component: T) {
        components[ObjectIdentifier(T.self)] = component
        if let updatable = component as? UpdatableComponent {
            updatables.append(updatable)
        }
        if let lifecycleAware = component as? LifecycleAwareComponent {
            lifecycleAware.onAttach(to: self)
        }
    }

    func component<T: AnyObject>(ofType type: T.Type) -> T? {
        components[ObjectIdentifier(type)] as? T
    }

    func advanceAll(deltaTime: TimeInterval) {
        for updatable in updatables {
            updatable.advance(deltaTime: deltaTime)
        }
    }
}
