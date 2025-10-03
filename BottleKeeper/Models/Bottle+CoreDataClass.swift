import Foundation
import CoreData

@objc(Bottle)
public class Bottle: NSManagedObject {
    /// バリデーションエラーの種類
    enum ValidationError: LocalizedError {
        case invalidName
        case invalidVolume
        case invalidRemainingVolume
        case invalidABV
        case invalidRating

        var errorDescription: String? {
            switch self {
            case .invalidName:
                return "ボトル名は必須です"
            case .invalidVolume:
                return "容量は1ml以上である必要があります"
            case .invalidRemainingVolume:
                return "残量は0ml以上、容量以下である必要があります"
            case .invalidABV:
                return "アルコール度数は0%から100%の範囲である必要があります"
            case .invalidRating:
                return "評価は0から5の範囲である必要があります"
            }
        }
    }

    /// ボトルのデータを検証
    func validate() throws {
        // 名前のバリデーション
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidName
        }

        // 容量のバリデーション
        guard volume > 0 else {
            throw ValidationError.invalidVolume
        }

        // 残量のバリデーション
        guard remainingVolume >= 0 && remainingVolume <= volume else {
            throw ValidationError.invalidRemainingVolume
        }

        // ABVのバリデーション
        guard abv >= 0 && abv <= 100 else {
            throw ValidationError.invalidABV
        }

        // 評価のバリデーション
        guard rating >= 0 && rating <= 5 else {
            throw ValidationError.invalidRating
        }
    }

    /// データの整合性を確保（保存前に呼び出す）
    public override func willSave() {
        super.willSave()

        // IDが未設定の場合は自動生成
        if id == nil {
            id = UUID()
        }

        // 作成日時が未設定の場合は自動設定
        if createdAt == nil {
            createdAt = Date()
        }

        // 更新日時を自動設定
        updatedAt = Date()

        // 残量が容量を超えないように補正
        if remainingVolume > volume {
            remainingVolume = volume
        }

        // 残量が負の値にならないように補正
        if remainingVolume < 0 {
            remainingVolume = 0
        }
    }
}