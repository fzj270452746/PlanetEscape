//
//  EscapeRouteAnalyzer.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 分析一个 LevelBlueprint 生成的障碍布局，沿角色默认前进路径（经度固定，
/// 纬度从起点到终点单调递增）采样，检查是否存在"整条纬线附近都被
/// 危险物覆盖"的不可通过区域。这是文档第 19 节自定义算法要求的一部分：
/// LevelGenerator 生成关卡后可用它自检，避免程序化生成出无解关卡。
struct EscapeRouteAnalyzer {
    /// 沿前进方向采样的步数。
    var sampleCount: Int = 60
    /// 判定"完全被封锁"的角度阈值（弧度）：若某个采样纬度上，
    /// 危险物覆盖的经度范围达到 2π 的这个比例以上，认为该纬度不可通行。
    var blockedCoverageRatio: Double = 0.92

    struct Report {
        var isTraversable: Bool
        var blockedLatitudes: [Double]
    }

    func analyze(
        hazardCoordinates: [(kind: HazardKind, coordinate: SphereSurfaceCoordinate)],
        startLatitude: Double,
        travelSpanRadians: Double,
        hazardAngularFootprint: Double = 0.35
    ) -> Report {
        var blockedLatitudes: [Double] = []
        let latitudeStep = travelSpanRadians / Double(sampleCount)

        for step in 0...sampleCount {
            let latitude = startLatitude + latitudeStep * Double(step)
            let nearbyLongitudeCoverage = hazardCoordinates
                .filter { abs($0.coordinate.latitude - latitude) < hazardAngularFootprint }
                .count

            // 简化模型：把每个危险物视为覆盖 hazardAngularFootprint 弧度的经度区间，
            // 若同一纬度附近的危险物数量足够多，认为该纬线被完全封锁。
            let estimatedCoverage = Double(nearbyLongitudeCoverage) * hazardAngularFootprint
            if estimatedCoverage >= (2 * Double.pi) * blockedCoverageRatio {
                blockedLatitudes.append(latitude)
            }
        }

        return Report(isTraversable: blockedLatitudes.isEmpty, blockedLatitudes: blockedLatitudes)
    }
}
