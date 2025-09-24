import Foundation
import SwiftUI

/// ボトル詳細画面のViewModel
@MainActor
class BottleDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var bottle: Bottle
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let repository: BottleRepositoryProtocol
    private let photoManager: PhotoManager

    // MARK: - Initialization

    init(bottle: Bottle, repository: BottleRepositoryProtocol, photoManager: PhotoManager) {
        self.bottle = bottle
        self.repository = repository
        self.photoManager = photoManager
    }

    // MARK: - Public Methods

    /// ボトルを削除
    func deleteBottle() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.deleteBottle(bottle)
            isLoading = false
            return true
        } catch {
            errorMessage = "ボトルの削除に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// ボトル情報を更新
    func updateBottle() async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.saveBottle(bottle)
            isLoading = false
        } catch {
            errorMessage = "ボトルの更新に失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - Computed Properties

extension BottleDetailViewModel {

    /// 残量パーセンテージの表示用文字列
    var remainingPercentageText: String {
        return String(format: "%.0f%%", bottle.remainingPercentage)
    }

    /// 評価の表示用文字列
    var ratingText: String {
        guard bottle.rating > 0 else { return "未評価" }
        return "\(bottle.rating)/5"
    }

    /// 購入価格の表示用文字列
    var purchasePriceText: String {
        guard let price = bottle.purchasePrice else { return "未設定" }
        return "¥\(price.intValue)"
    }
}