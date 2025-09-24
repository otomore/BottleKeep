import Foundation
import CoreData

@objc(Bottle)
public class Bottle: NSManagedObject {

    // MARK: - Computed Properties

    /// 残量パーセンテージ（0-100）
    var remainingPercentage: Double {
        guard volume > 0 else { return 0.0 }
        let percentage = Double(remainingVolume) / Double(volume) * 100.0
        return min(max(percentage, 0.0), 100.0)
    }

    /// 開栓済みかどうか
    var isOpened: Bool {
        return openedDate != nil
    }

    /// 評価の星マーク（1-5）
    var ratingStars: String {
        guard rating > 0 else { return "未評価" }
        return String(repeating: "⭐", count: Int(rating))
    }

    /// 短い説明文
    var shortDescription: String {
        var parts: [String] = []

        if let type = type, !type.isEmpty {
            parts.append(type)
        }

        if abv > 0 {
            parts.append("\(Int(abv))%")
        }

        if volume > 0 {
            parts.append("\(volume)ml")
        }

        return parts.joined(separator: " • ")
    }

    // MARK: - Validation

    /// データ検証
    func validate() throws {
        // 必須フィールドの検証
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            throw ValidationError.emptyName
        }

        guard let distillery = distillery?.trimmingCharacters(in: .whitespacesAndNewlines),
              !distillery.isEmpty else {
            throw ValidationError.emptyDistillery
        }

        // 数値範囲の検証
        if abv < 0 || abv > 100 {
            throw ValidationError.invalidABV
        }

        if volume < 0 {
            throw ValidationError.invalidVolume
        }

        if remainingVolume < 0 || remainingVolume > volume {
            throw ValidationError.remainingVolumeExceedsTotal
        }

        if rating < 0 || rating > 5 {
            throw ValidationError.invalidRating
        }

        // 日付の検証
        if let purchaseDate = purchaseDate,
           let openedDate = openedDate,
           openedDate < purchaseDate {
            throw ValidationError.openedDateBeforePurchaseDate
        }
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()

        // デフォルト値の設定
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.remainingVolume = self.volume // 初期値は満量
    }

    public override func willSave() {
        super.willSave()

        // 更新日時を自動更新
        if !isDeleted && isUpdated {
            self.updatedAt = Date()
        }
    }
}

// MARK: - Validation Error

enum ValidationError: LocalizedError {
    case emptyName
    case emptyDistillery
    case invalidABV
    case invalidVolume
    case remainingVolumeExceedsTotal
    case invalidRating
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
        case .remainingVolumeExceedsTotal:
            return "残量が総容量を超えています"
        case .invalidRating:
            return "評価は1-5の範囲で入力してください"
        case .openedDateBeforePurchaseDate:
            return "開栓日は購入日以降に設定してください"
        }
    }
}