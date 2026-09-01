//
//  UserProgressStore.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 玩家进度的持久化数据结构：已解锁到第几关、每关最佳用时、总能量收集数。
/// 用 Codable + FileManager 存到 Documents 目录，不做成 SaveManager.shared 单例——
/// WorldRuntime 或 UI 层持有一个实例并按需读写，符合文档反雷同要求。
struct UserProgressSnapshot: Codable {
    var highestUnlockedLevel: Int
    var bestElapsedSecondsByLevel: [Int: TimeInterval]
    var totalEnergyCollected: Int
    var bestEndlessDistance: Double
    var equippedSkinID: String
    var equippedTrailID: String
    var equippedColorwayID: String

    static let initial = UserProgressSnapshot(
        highestUnlockedLevel: 1,
        bestElapsedSecondsByLevel: [:],
        totalEnergyCollected: 0,
        bestEndlessDistance: 0,
        equippedSkinID: "skin_default",
        equippedTrailID: "trail_none",
        equippedColorwayID: "planet_default"
    )
}

final class UserProgressStore {
    private let fileURL: URL
    private(set) var snapshot: UserProgressSnapshot

    init(fileName: String = "user_progress.json") {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        fileURL = (directory ?? FileManager.default.temporaryDirectory).appendingPathComponent(fileName)
        snapshot = UserProgressStore.load(from: fileURL) ?? .initial
    }

    private static func load(from url: URL) -> UserProgressSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(UserProgressSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func recordLevelCompletion(level: Int, elapsedSeconds: TimeInterval, energyGained: Int) {
        if level + 1 > snapshot.highestUnlockedLevel {
            snapshot.highestUnlockedLevel = min(level + 1, 121)
        }
        if let existingBest = snapshot.bestElapsedSecondsByLevel[level] {
            snapshot.bestElapsedSecondsByLevel[level] = min(existingBest, elapsedSeconds)
        } else {
            snapshot.bestElapsedSecondsByLevel[level] = elapsedSeconds
        }
        snapshot.totalEnergyCollected += energyGained
        save()
    }

    func recordEndlessRun(distance: Double) {
        snapshot.bestEndlessDistance = max(snapshot.bestEndlessDistance, distance)
        save()
    }

    func isLevelUnlocked(_ level: Int) -> Bool {
        level <= snapshot.highestUnlockedLevel
    }

    func equipSkin(_ skinID: String) {
        snapshot.equippedSkinID = skinID
        save()
    }

    func equipTrail(_ trailID: String) {
        snapshot.equippedTrailID = trailID
        save()
    }

    func equipColorway(_ colorwayID: String) {
        snapshot.equippedColorwayID = colorwayID
        save()
    }
}
