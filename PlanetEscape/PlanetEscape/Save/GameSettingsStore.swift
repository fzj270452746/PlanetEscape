//
//  GameSettingsStore.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 玩家可调设置：音效/音乐开关、灵敏度、震动反馈。
/// 用 UserDefaults 存储（数据量小、访问频繁，比 FileManager JSON 更合适）。
struct GameSettingsSnapshot: Codable {
    var soundEffectsEnabled: Bool
    var musicEnabled: Bool
    var hapticFeedbackEnabled: Bool
    var rotationSensitivity: Double

    static let initial = GameSettingsSnapshot(
        soundEffectsEnabled: false,
        musicEnabled: false,
        hapticFeedbackEnabled: true,
        rotationSensitivity: 1.0
    )
}

final class GameSettingsStore {
    private let defaults: UserDefaults
    private let storageKey = "com.pes.gameSettings"

    private(set) var snapshot: GameSettingsSnapshot

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(GameSettingsSnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = .initial
        }
    }

    func update(_ mutate: (inout GameSettingsSnapshot) -> Void) {
        mutate(&snapshot)
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
