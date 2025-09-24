import Foundation
import SwiftUI

/// 統計画面のViewModel
@MainActor
class StatisticsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var totalCount: Int = 0
    @Published var totalValue: Decimal = 0
    @Published var averageRating: Double = 0
    @Published var regionDistribution: [String: Int] = [:]
    @Published var openedCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let repository: BottleRepositoryProtocol

    // MARK: - Initialization

    init(repository: BottleRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// 統計データを読み込み
    func loadStatistics() async {
        isLoading = true
        errorMessage = nil

        do {
            // 並列で統計データを取得
            async let totalCountTask = repository.getBottleCount()
            async let totalValueTask = repository.getTotalValue()
            async let averageRatingTask = repository.getAverageRating()
            async let regionDistributionTask = repository.getBottlesByRegion()

            let (count, value, rating, regions) = await (
                try totalCountTask,
                try totalValueTask,
                try averageRatingTask,
                try regionDistributionTask
            )

            totalCount = count
            totalValue = value
            averageRating = rating
            regionDistribution = regions

            // 開栓数を計算
            let openedBottles = try await repository.fetchOpenedBottles()
            openedCount = openedBottles.count

            isLoading = false

        } catch {
            errorMessage = "統計データの読み込みに失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// データを更新
    func refreshData() async {
        await loadStatistics()
    }
}

// MARK: - Computed Properties

extension StatisticsViewModel {

    /// 未開栓数
    var unopenedCount: Int {
        return totalCount - openedCount
    }

    /// 開栓率
    var openedPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(openedCount) / Double(totalCount) * 100
    }

    /// 平均価格
    var averagePrice: Double {
        guard totalCount > 0 else { return 0 }
        return totalValue.doubleValue / Double(totalCount)
    }

    /// 総価値の表示用文字列
    var totalValueText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: NSNumber(value: totalValue.doubleValue)) ?? "¥0"
    }

    /// 平均評価の表示用文字列
    var averageRatingText: String {
        guard averageRating > 0 else { return "未評価" }
        return String(format: "%.1f/5", averageRating)
    }

    /// 地域分布のソート済み配列
    var sortedRegions: [(String, Int)] {
        return regionDistribution.sorted { $0.value > $1.value }
    }

    /// 統計サマリー
    var summary: StatisticsSummary {
        return StatisticsSummary(
            totalCount: totalCount,
            openedCount: openedCount,
            unopenedCount: unopenedCount,
            totalValue: totalValue,
            averagePrice: averagePrice,
            averageRating: averageRating
        )
    }
}

// MARK: - Supporting Types

struct StatisticsSummary {
    let totalCount: Int
    let openedCount: Int
    let unopenedCount: Int
    let totalValue: Decimal
    let averagePrice: Double
    let averageRating: Double
}