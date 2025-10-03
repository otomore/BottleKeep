import Foundation
import CoreData

@objc(WishlistItem)
public class WishlistItem: NSManagedObject {
    /// バリデーションエラーの種類
    enum ValidationError: LocalizedError {
        case invalidName
        case invalidPriority
        case invalidBudget

        var errorDescription: String? {
            switch self {
            case .invalidName:
                return "ウィッシュリスト名は必須です"
            case .invalidPriority:
                return "優先度は1から5の範囲である必要があります"
            case .invalidBudget:
                return "予算は0円以上である必要があります"
            }
        }
    }

    /// ウィッシュリストアイテムのデータを検証
    func validate() throws {
        // 名前のバリデーション
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidName
        }

        // 優先度のバリデーション
        guard priority >= 1 && priority <= 5 else {
            throw ValidationError.invalidPriority
        }

        // 予算のバリデーション（設定されている場合のみ）
        if let budget = budget {
            guard budget.doubleValue >= 0 else {
                throw ValidationError.invalidBudget
            }
        }

        // 目標価格のバリデーション（設定されている場合のみ）
        if let targetPrice = targetPrice {
            guard targetPrice.doubleValue >= 0 else {
                throw ValidationError.invalidBudget
            }
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

        // 優先度が範囲外の場合は補正
        if priority < 1 {
            priority = 1
        } else if priority > 5 {
            priority = 5
        }
    }
}