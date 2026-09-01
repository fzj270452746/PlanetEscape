//
//  UpdatableComponent.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 每帧更新协议。挂载到 ComponentHost 上的组件如果需要逐帧逻辑，实现此协议即可，
/// WorldRuntime 只认识这个协议，不知道具体是旋转组件、动画组件还是别的什么。
protocol UpdatableComponent: AnyObject {
    /// deltaTime 单位为秒。
    func advance(deltaTime: TimeInterval)
}

/// 组件的生命周期钩子，挂载/卸载时触发，用于资源分配与释放。
protocol LifecycleAwareComponent: AnyObject {
    func onAttach(to host: ComponentHost)
    func onDetach(from host: ComponentHost)
}
