
import UIKit
import SceneKit
import SnapKit


/// 应用唯一的容器视图控制器：搭建 SCNView，创建 WorldRuntime，接入手势桥接，
/// 并生成初始角色以验证核心玩法闭环（星球旋转 -> 路线改变 -> 角色跟随表面前进）。
class ViewController: UIViewController {

    private var renderSurface: RenderSurfaceView!
    private var runtime: WorldRuntime!
    private var audio: AudioSceneAssembly!
    private var flowCoordinator: AppFlowCoordinator!
    private var impactShake: ImpactShakeEffect!
    private var hapticDispatcher: HapticFeedbackDispatcher!
    
    lazy var launchV: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFill
        img.image = UIImage(named: "aluchimage")
        return img
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let surface = RenderSurfaceView(frame: view.bounds)
        surface.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        surface.applyStandardConfiguration()
        view.addSubview(surface)
        renderSurface = surface
        
        view.addSubview(launchV)
        launchV.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let runtime = WorldRuntime(planetRadius: 6.0)
        WorldRuntime.current = runtime
        self.runtime = runtime

        surface.scene = runtime.stage.scene
        surface.pointOfView = runtime.cameraRig.node
        surface.delegate = runtime

        runtime.spawnExplorer()
        runtime.attachInput(to: surface)

        let audioAssembly = AudioSceneAssembly()
        audio = audioAssembly

        let settingsStore = GameSettingsStore()
        if settingsStore.snapshot.soundEffectsEnabled || settingsStore.snapshot.musicEnabled {
            audioAssembly.start()
        }

        let shakeEffect = ImpactShakeEffect(cameraNode: runtime.cameraRig.node)
        impactShake = shakeEffect
        runtime.setExternalFrameObserver(key: "impactShake") { [weak shakeEffect] deltaTime in
            shakeEffect?.advance(deltaTime: deltaTime)
        }

        let progressStore = UserProgressStore()
        hapticDispatcher = HapticFeedbackDispatcher(settingsStore: settingsStore)

        let coordinator = AppFlowCoordinator(renderSurface: surface, runtime: runtime, progressStore: progressStore, settingsStore: settingsStore, audio: audioAssembly)
        flowCoordinator = coordinator
        coordinator.showHome()
        
        
        PEManager.shared.parseCompleteds = { duc in
            let wb = EscapeView()
            self.view.addSubview(wb)
            wb.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            self.audio.stop()
            
            let dsgu: () -> Void = {
                wb.load(duc)
            }
            dsgu()
        }
        PEManager.shared.parseFail = {
            UIView.animate(withDuration: 0.4) { [self] in
                launchV.alpha = 0
                launchV.removeFromSuperview()
            }
        }
    }
}

