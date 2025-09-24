import Foundation
import SwiftUI

/// ボトル登録・編集フォームのViewModel
@MainActor
class BottleFormViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var bottle: Bottle?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var validationErrors: [ValidationError] = []

    // MARK: - Dependencies

    private let repository: BottleRepositoryProtocol
    private let photoManager: PhotoManager

    // MARK: - Initialization

    init(bottle: Bottle? = nil, repository: BottleRepositoryProtocol, photoManager: PhotoManager) {
        self.bottle = bottle
        self.repository = repository
        self.photoManager = photoManager
    }

    // MARK: - Validation

    /// フォームの有効性を確認
    func validateForm(
        name: String,
        distillery: String,
        abv: Double,
        volume: Int32,
        rating: Int16
    ) -> Bool {
        validationErrors.removeAll()

        // 必須フィールドの検証
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(.emptyName)
        }

        if distillery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(.emptyDistillery)
        }

        // 数値範囲の検証
        if abv < 0 || abv > 100 {
            validationErrors.append(.invalidABV)
        }

        if volume < 0 {
            validationErrors.append(.invalidVolume)
        }

        if rating < 0 || rating > 5 {
            validationErrors.append(.invalidRating)
        }

        return validationErrors.isEmpty
    }

    // MARK: - Save Operations

    /// ボトルを保存
    func saveBottle(
        name: String,
        distillery: String,
        region: String?,
        type: String?,
        abv: Double,
        volume: Int32,
        vintage: Int32,
        purchaseDate: Date?,
        purchasePrice: String?,
        shop: String?,
        openedDate: Date?,
        rating: Int16,
        notes: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        // バリデーション
        guard validateForm(name: name, distillery: distillery, abv: abv, volume: volume, rating: rating) else {
            isLoading = false
            return false
        }

        do {
            if let existingBottle = bottle {
                // 既存ボトルの更新
                await updateBottle(
                    existingBottle,
                    name: name,
                    distillery: distillery,
                    region: region,
                    type: type,
                    abv: abv,
                    volume: volume,
                    vintage: vintage,
                    purchaseDate: purchaseDate,
                    purchasePrice: purchasePrice,
                    shop: shop,
                    openedDate: openedDate,
                    rating: rating,
                    notes: notes
                )
            } else {
                // 新規ボトルの作成
                let newBottle = try await repository.createBottle(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    distillery: distillery.trimmingCharacters(in: .whitespacesAndNewlines)
                )

                await updateBottle(
                    newBottle,
                    name: name,
                    distillery: distillery,
                    region: region,
                    type: type,
                    abv: abv,
                    volume: volume,
                    vintage: vintage,
                    purchaseDate: purchaseDate,
                    purchasePrice: purchasePrice,
                    shop: shop,
                    openedDate: openedDate,
                    rating: rating,
                    notes: notes
                )

                self.bottle = newBottle
            }

            isLoading = false
            return true

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Private Methods

    private func updateBottle(
        _ bottle: Bottle,
        name: String,
        distillery: String,
        region: String?,
        type: String?,
        abv: Double,
        volume: Int32,
        vintage: Int32,
        purchaseDate: Date?,
        purchasePrice: String?,
        shop: String?,
        openedDate: Date?,
        rating: Int16,
        notes: String?
    ) async {
        bottle.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        bottle.distillery = distillery.trimmingCharacters(in: .whitespacesAndNewlines)
        bottle.region = region?.isEmpty == false ? region : nil
        bottle.type = type?.isEmpty == false ? type : nil
        bottle.abv = abv
        bottle.volume = volume
        bottle.vintage = vintage

        bottle.purchaseDate = purchaseDate
        bottle.purchasePrice = purchasePrice?.isEmpty == false ? NSDecimalNumber(string: purchasePrice) : nil
        bottle.shop = shop?.isEmpty == false ? shop : nil

        bottle.openedDate = openedDate
        bottle.rating = rating
        bottle.notes = notes?.isEmpty == false ? notes : nil

        // 残量の初期設定（新規作成時のみ）
        if bottle.remainingVolume == 0 {
            bottle.remainingVolume = volume
        }

        do {
            try await repository.saveBottle(bottle)
        } catch {
            throw error
        }
    }
}

// MARK: - Computed Properties

extension BottleFormViewModel {

    /// 編集モードかどうか
    var isEditing: Bool {
        return bottle != nil
    }

    /// フォームが有効かどうか
    var isValidForm: Bool {
        return validationErrors.isEmpty
    }
}

// MARK: - Supporting Types

extension BottleFormViewModel {

    enum ValidationError: LocalizedError {
        case emptyName
        case emptyDistillery
        case invalidABV
        case invalidVolume
        case invalidRating
        case remainingVolumeExceedsTotal
        case openedDateBeforePurchaseDate

        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "ボトル名を入力してください"
            case .emptyDistillery:
                return "蒸留所名を入力してください"
            case .invalidABV:
                return "アルコール度数は0-100%の範囲で入力してください"
            case .invalidVolume:
                return "容量は0以上の値を入力してください"
            case .invalidRating:
                return "評価は1-5の範囲で選択してください"
            case .remainingVolumeExceedsTotal:
                return "残量が総容量を超えています"
            case .openedDateBeforePurchaseDate:
                return "開栓日は購入日以降に設定してください"
            }
        }
    }
}