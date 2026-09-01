//
//  AppFlowCoordinator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import SpriteKit
import UIKit

/// 文档第 16 节结构：UIViewController -> SCNView -> SCNScene + SKScene Overlay。
/// 这个协调器负责在 Home / PlanetSelect / Collection / Settings / Gameplay(HUD+Result)
/// 之间切换 SCNView.overlaySKScene，并在切换到 Gameplay 时驱动 WorldRuntime 加载关卡。
/// 不叫 "NavigationManager"，避免文档禁止的万能 Manager 命名雷同。
final class AppFlowCoordinator {
    private weak var renderSurface: RenderSurfaceView?
    private let runtime: WorldRuntime
    private let progressStore: UserProgressStore
    private let settingsStore: GameSettingsStore
    private let unlockRegistry: UnlockRegistry
    private let audio: AudioSceneAssembly

    private var hudScene: GameplayHUDScene?
    private var resultOverlay: LevelResultOverlay?
    private var subscription: SignalSubscription?
    private var activeLevelNumber = 1
    private var activeTrail: TrailRibbonEffect?
    private var challengeMonitor: ChallengeModeMonitor?
    private var isInChallenge = false
    private lazy var endlessSession = EndlessRunSession(
        director: EndlessModeDirector(planet: runtime.planet, hazards: runtime.hazards, collectibles: runtime.adventure.collectibles, dispatcher: runtime.hazards.dispatcher),
        progressStore: progressStore
    )

    init(renderSurface: RenderSurfaceView, runtime: WorldRuntime, progressStore: UserProgressStore, settingsStore: GameSettingsStore, audio: AudioSceneAssembly) {
        self.renderSurface = renderSurface
        self.runtime = runtime
        self.progressStore = progressStore
        self.settingsStore = settingsStore
        self.audio = audio
        self.unlockRegistry = UnlockRegistry(progressStore: progressStore)

        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
        runtime.gestureBridge.applySensitivity(settingsStore.snapshot.rotationSensitivity)
    }

    /// 非游玩界面统一在这里暂停 WorldRuntime——角色/摄像机每帧仍在推进，
    /// 首页等菜单场景背后能透视看到 3D 星球（SKScene overlay 默认不挡住 SCNView），
    /// 若不暂停，角色会在没人操作的情况下绕着球体持续奔跑，配合近距离追逐摄像机
    /// 在首页背景里就是持续的抖动/晃动。只有 startLevel/startEndlessRun/startChallenge
    /// 真正进入一局玩法时才恢复运行。
    func showHome() {
        guard let surface = renderSurface else { return }
        runtime.isPaused = true
        let scene = HomeMenuScene(size: surface.bounds.size, topInset: surface.safeAreaInsets.top)
        scene.onPlayTapped = { [weak self] in self?.startLevel(self?.progressStore.snapshot.highestUnlockedLevel ?? 1) }
        scene.onEndlessTapped = { [weak self] in self?.startEndlessRun() }
        scene.onChallengeTapped = { [weak self] in self?.showChallengeSelect() }
        scene.onPlanetsTapped = { [weak self] in self?.showPlanetSelect() }
        scene.onCollectionTapped = { [weak self] in self?.showCollection() }
        scene.onSettingsTapped = { [weak self] in self?.showSettings() }
        scene.onProfileTapped = { [weak self] in self?.showProfile() }
        surface.overlaySKScene = scene
    }

    private func showProfile() {
        guard let surface = renderSurface else { return }
        runtime.isPaused = true
        let scene = PlayerStatsScene(size: surface.bounds.size, progressStore: progressStore, topInset: surface.safeAreaInsets.top)
        scene.onBackTapped = { [weak self] in self?.showHome() }
        surface.overlaySKScene = scene
    }

    private func showPlanetSelect() {
        guard let surface = renderSurface else { return }
        runtime.isPaused = true
        let scene = PlanetSelectGrid(size: surface.bounds.size, progressStore: progressStore, topInset: surface.safeAreaInsets.top)
        scene.onLevelSelected = { [weak self] level in self?.startLevel(level) }
        scene.onBackTapped = { [weak self] in self?.showHome() }
        surface.overlaySKScene = scene
    }

    private func showCollection() {
        guard let surface = renderSurface else { return }
        runtime.isPaused = true
        let scene = CollectionGalleryScene(size: surface.bounds.size, unlockRegistry: unlockRegistry, progressStore: progressStore, topInset: surface.safeAreaInsets.top)
        scene.onBackTapped = { [weak self] in self?.showHome() }
        scene.onSkinEquipped = { [weak self] skinID in self?.applyEquippedSkin(skinID) }
        scene.onTrailEquipped = { [weak self] trailID in self?.applyEquippedTrail(trailID) }
        scene.onColorwayEquipped = { [weak self] colorwayID in
            guard let self = self else { return }
            PlanetColorwayCatalog.apply(colorwayID, to: self.runtime.planet)
        }
        scene.onAchievementsTapped = { [weak self] in self?.showAchievements() }
        surface.overlaySKScene = scene
    }

    private func showChallengeSelect() {
        guard let surface = renderSurface else { return }
        runtime.isPaused = true
        let scene = ChallengeSelectScene(size: surface.bounds.size, topInset: surface.safeAreaInsets.top)
        scene.onBackTapped = { [weak self] in self?.showHome() }
        scene.onChallengeSelected = { [weak self] ruleSet in self?.startChallenge(ruleSet) }
        surface.overlaySKScene = scene
    }

    private func startChallenge(_ ruleSet: ChallengeRuleSet) {
        guard let surface = renderSurface else { return }
        // isPaused 必须留到 loadLevel（在主线程重建 hazards/collectibles/lod 的
        // 内部数组：unregisterAll/clearAll/populate 一整套 append）完全结束之后才能
        // 松开。SceneKit 渲染线程一旦看到 isPaused == false 就会在下一帧开始并发
        // 调用 hazards.advance/adventure.advance 遍历这些同一批数组——如果 loadLevel
        // 还没跑完，就是主线程写、渲染线程同时遍历同一个 Array，直接撞坏堆内存，
        // 表现为进关卡几秒后 HUD 文字变乱码、画面卡死抖动（对应真实复现的 bug）。
        isInChallenge = true
        activeLevelNumber = progressStore.snapshot.highestUnlockedLevel
        runtime.explorer?.energyReserve.reset()
        runtime.explorer?.motionUnit.reset()
        runtime.adventure.loadLevel(activeLevelNumber)
        applyEquippedSkin(progressStore.snapshot.equippedSkinID)
        applyEquippedTrail(progressStore.snapshot.equippedTrailID)
        runtime.isPaused = false

        challengeMonitor = ChallengeModeMonitor(ruleSet: ruleSet)
        runtime.setExternalFrameObserver(key: "challengeMonitor") { [weak self] deltaTime in
            self?.challengeMonitor?.advance(deltaTime: deltaTime)
        }

        let hud = GameplayHUDScene(size: surface.bounds.size)
        hud.applyTopInset(surface.safeAreaInsets.top)
        hud.onPauseTapped = { [weak self] in self?.showPauseMenu() }
        hudScene = hud
        surface.overlaySKScene = hud
        runtime.setExternalFrameObserver(key: "hudEnergySync") { [weak self, weak hud] _ in
            guard let self = self, let hud = hud, let reserve = self.runtime.explorer?.energyReserve else { return }
            hud.syncEnergy(current: reserve.currentEnergy, max: reserve.maxEnergy)
        }
    }

    private func showAchievements() {
        guard let surface = renderSurface else { return }
        let scene = AchievementListScene(size: surface.bounds.size, progressStore: progressStore, topInset: surface.safeAreaInsets.top)
        scene.onBackTapped = { [weak self] in self?.showCollection() }
        surface.overlaySKScene = scene
    }

    private func applyEquippedSkin(_ skinID: String) {
        guard let rootNode = runtime.explorer?.rootNode else { return }
        TinyBotSkinCatalog.apply(TinyBotSkinCatalog.definition(for: skinID), to: rootNode)
    }

    private func applyEquippedTrail(_ trailID: String) {
        guard let rootNode = runtime.explorer?.rootNode else { return }
        activeTrail?.detach()
        activeTrail = nil
        switch trailID {
        case "trail_spark":
            let trail = TrailRibbonEffect(style: .spark)
            trail.attach(to: rootNode)
            activeTrail = trail
        case "trail_comet":
            let trail = TrailRibbonEffect(style: .comet)
            trail.attach(to: rootNode)
            activeTrail = trail
        default:
            break
        }
    }

    private func showSettings() {
        guard let surface = renderSurface else { return }
        runtime.isPaused = true
        let scene = SettingsPanel(size: surface.bounds.size, settingsStore: settingsStore, topInset: surface.safeAreaInsets.top)
        scene.onBackTapped = { [weak self] in self?.showHome() }
        scene.onSensitivityChanged = { [weak self] sensitivity in
            self?.runtime.gestureBridge.applySensitivity(sensitivity)
        }
        surface.overlaySKScene = scene
    }

    private func startLevel(_ levelNumber: Int) {
        guard let surface = renderSurface else { return }
        let isFirstEverAttempt = progressStore.snapshot.highestUnlockedLevel <= 1 && levelNumber == 1

        // 同 startChallenge：isPaused 必须等 loadLevel 把关卡内容重建完再松开，
        // 否则渲染线程会在主线程仍在增删 hazards/collectibles/lod 数组时并发遍历它们。
        activeLevelNumber = levelNumber
        runtime.explorer?.energyReserve.reset()
        runtime.explorer?.motionUnit.reset()
        audio.windIntensityDriver.reset()
        runtime.adventure.loadLevel(levelNumber)
        applyEquippedSkin(progressStore.snapshot.equippedSkinID)
        applyEquippedTrail(progressStore.snapshot.equippedTrailID)
        PlanetColorwayCatalog.apply(progressStore.snapshot.equippedColorwayID, to: runtime.planet)
        runtime.isPaused = false

        let hud = GameplayHUDScene(size: surface.bounds.size)
        hud.applyTopInset(surface.safeAreaInsets.top)
        hud.onPauseTapped = { [weak self] in self?.showPauseMenu() }
        hud.showLevelInfo(levelNumber: levelNumber, chapterTitle: ChapterCatalog.chapter(forLevel: levelNumber)?.title)
        hudScene = hud

        runtime.setExternalFrameObserver(key: "hudEnergySync") { [weak self, weak hud] _ in
            guard let self = self, let hud = hud, let reserve = self.runtime.explorer?.energyReserve else { return }
            hud.syncEnergy(current: reserve.currentEnergy, max: reserve.maxEnergy)
        }

        if isFirstEverAttempt {
            runtime.isPaused = true
            let tutorial = TutorialHintOverlay(size: surface.bounds.size)
            tutorial.onDismissTapped = { [weak self] in
                self?.runtime.isPaused = false
                surface.overlaySKScene = hud
            }
            surface.overlaySKScene = tutorial
        } else {
            surface.overlaySKScene = hud
        }
    }

    private func startEndlessRun() {
        guard let surface = renderSurface, let explorer = runtime.explorer else { return }
        // 同 startChallenge：endlessSession.start 内部会走 director.reset()，
        // 同样会在主线程增删 hazards/collectibles 数组，isPaused 必须等它跑完再松开。
        // exitToFreeMode()/motionUnit.reset() 必须在这里调用：startEndlessRun 不像
        // startLevel/startChallenge 那样走 loadLevel，如果不清空上一局 Adventure/Challenge
        // 残留的 currentBlueprint.targetDistance 和 totalDistanceTravelled，
        // AdventureLevelDirector.advance() 每帧无条件的距离判断会在 Endless 里被误触发，
        // 导致角色被永久 pause 并卡进 celebrating 转圈动画（原地 360 度旋转的根因）。
        runtime.adventure.exitToFreeMode()
        runtime.explorer?.energyReserve.reset()
        runtime.explorer?.motionUnit.reset()
        runtime.explorer?.motionUnit.resume()
        runtime.explorer?.animationDriver.transition(to: .running)
        audio.windIntensityDriver.reset()
        runtime.adventure.progressionTracker.beginLevel(-1)
        applyEquippedSkin(progressStore.snapshot.equippedSkinID)
        applyEquippedTrail(progressStore.snapshot.equippedTrailID)

        endlessSession.onRunEnded = { [weak self] distance in
            guard let self = self, let resultSurface = self.renderSurface else { return }
            // presentResult 同样的原因：结算展示期间必须暂停 runtime，否则渲染线程
            // 会在玩家点 Retry 触发的下一次 startEndlessRun/loadLevel 重建数组时
            // 仍在并发遍历同一批数组。
            self.runtime.isPaused = true
            let overlay = LevelResultOverlay(size: resultSurface.bounds.size)
            overlay.onRetryTapped = { [weak self] in self?.startEndlessRun() }
            overlay.onNextTapped = { [weak self] in self?.startEndlessRun() }
            overlay.onHomeTapped = { [weak self] in self?.showHome() }
            overlay.showSuccess(levelNumber: 0, elapsedSeconds: 0, energyGained: Int(distance))
            self.resultOverlay = overlay
            resultSurface.overlaySKScene = overlay
        }
        endlessSession.start(motionUnit: explorer.motionUnit)
        runtime.isPaused = false

        let hud = GameplayHUDScene(size: surface.bounds.size)
        hud.applyTopInset(surface.safeAreaInsets.top)
        hud.onPauseTapped = { [weak self] in self?.showPauseMenu() }
        hudScene = hud
        surface.overlaySKScene = hud
        runtime.setExternalFrameObserver(key: "hudEnergySync") { [weak self, weak hud] _ in
            guard let self = self, let hud = hud, let reserve = self.runtime.explorer?.energyReserve else { return }
            hud.syncEnergy(current: reserve.currentEnergy, max: reserve.maxEnergy)
        }
    }

    private func showPauseMenu() {
        guard let surface = renderSurface else { return }
        runtime.isPaused = true
        let overlay = PauseMenuOverlay(size: surface.bounds.size)
        overlay.onResumeTapped = { [weak self] in
            self?.runtime.isPaused = false
            if let hud = self?.hudScene { surface.overlaySKScene = hud }
        }
        overlay.onRestartTapped = { [weak self] in
            self?.runtime.isPaused = false
            self?.startLevel(self?.activeLevelNumber ?? 1)
        }
        overlay.onHomeTapped = { [weak self] in
            self?.runtime.isPaused = false
            self?.showHome()
        }
        surface.overlaySKScene = overlay
    }

    /// CosmicSignalRelay.publish 是同步分发，而 .levelCompleted/.levelFailed
    /// 最初触发于 WorldRuntime.renderer(_:updateAtTime:)——SceneKit 在自己的
    /// 渲染队列（后台线程）上调用这个 delegate 方法，不是主线程。这里一旦要
    /// 触碰 UIView/SKScene（读 bounds、赋值 overlaySKScene）就必须先跳回主线程，
    /// 否则是未定义行为：轻则数据竞争造成画面几何错乱/持续抖动，重则直接崩溃。
    private func handle(_ event: GameEvent) {
        switch event {
        case .levelCompleted(let levelID, let elapsedSeconds, _):
            let energyGained = runtime.adventure.collectibles.totalEnergyCollected
            if !isInChallenge {
                progressStore.recordLevelCompletion(level: levelID, elapsedSeconds: elapsedSeconds, energyGained: energyGained)
            }
            endChallengeIfNeeded()
            DispatchQueue.main.async { [weak self] in
                self?.presentResult { overlay in overlay.showSuccess(levelNumber: levelID, elapsedSeconds: elapsedSeconds, energyGained: energyGained) }
            }
        case .levelFailed(let levelID, let reason):
            endChallengeIfNeeded()
            DispatchQueue.main.async { [weak self] in
                self?.presentResult { overlay in overlay.showFailure(levelNumber: levelID, reason: reason) }
            }
        default:
            break
        }
    }

    private func endChallengeIfNeeded() {
        guard isInChallenge else { return }
        isInChallenge = false
        challengeMonitor = nil
        runtime.removeExternalFrameObserver(key: "challengeMonitor")
    }

    /// 之前只把 startLevel/startChallenge/startEndlessRun 内部“先 loadLevel 再放开
    /// isPaused”这一步修好了，但漏了这里：结算画面展示期间从来没人把 isPaused
    /// 设为 true。从关卡失败/成功到玩家点 Retry/Next 的这段时间里，runtime 其实
    /// 一直在跑（isPaused 一直是 false），渲染线程持续遍历 hazards/collectibles 数组；
    /// 玩家点 Retry 后 startLevel 调 loadLevel 在主线程改这些数组时，isPaused 早就
    /// 是 false 了（不是从 true 变 false），loadLevel 期间渲染线程照样并发遍历它们——
    /// 这才是"玩一会儿失败/重试后又出现 HUD 文字乱码、摄像机钻进地表、画面抖动"
    /// 反复出现的真正原因：结算界面完全没有暂停保护。
    private func presentResult(configure: (LevelResultOverlay) -> Void) {
        guard let surface = renderSurface else { return }
        runtime.isPaused = true
        let overlay = LevelResultOverlay(size: surface.bounds.size)
        overlay.onRetryTapped = { [weak self] in
            guard let self = self else { return }
            self.startLevel(self.activeLevelNumber)
        }
        overlay.onNextTapped = { [weak self] in
            guard let self = self else { return }
            self.startLevel(self.activeLevelNumber + 1)
        }
        overlay.onHomeTapped = { [weak self] in self?.showHome() }
        configure(overlay)
        resultOverlay = overlay
        surface.overlaySKScene = overlay
    }
}
