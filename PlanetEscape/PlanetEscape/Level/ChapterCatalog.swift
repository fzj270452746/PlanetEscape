//
//  ChapterCatalog.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 文档第 7 节六章节命名（Green Planet / Volcano Planet / Dark Planet / Ice Planet /
/// Space Core / Galaxy Escape）。ChapterDifficultyCurve 只关心数值参数，
/// 不适合承载展示用的章节标题，所以单独建一个只读目录供 UI 使用。
struct ChapterCatalog {
    struct ChapterInfo {
        let number: Int
        let title: String
        let levelRange: ClosedRange<Int>
    }

    static let all: [ChapterInfo] = [
        ChapterInfo(number: 1, title: "Green Planet", levelRange: 1...20),
        ChapterInfo(number: 2, title: "Volcano Planet", levelRange: 21...40),
        ChapterInfo(number: 3, title: "Dark Planet", levelRange: 41...60),
        ChapterInfo(number: 4, title: "Ice Planet", levelRange: 61...80),
        ChapterInfo(number: 5, title: "Space Core", levelRange: 81...100),
        ChapterInfo(number: 6, title: "Galaxy Escape", levelRange: 101...120),
    ]

    static func chapter(forLevel level: Int) -> ChapterInfo? {
        all.first { $0.levelRange.contains(level) }
    }
}
