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
        // 削除中のオブジェクトには何もしない
        guard !isDeleted else {
            super.willSave()
            return
        }

        super.willSave()

        // IDが未設定の場合は自動生成（新規作成時のみ）
        if primitiveValue(forKey: "id") == nil {
            setPrimitiveValue(UUID(), forKey: "id")
        }

        // 作成日時が未設定の場合は自動設定（新規作成時のみ）
        if primitiveValue(forKey: "createdAt") == nil {
            setPrimitiveValue(Date(), forKey: "createdAt")
        }

        // 更新日時は明示的に設定されている場合のみ更新
        // willSave()内での自動更新は無限ループを引き起こす可能性があるため削除

        // 優先度が範囲外の場合は補正（primitiveValueを使用して変更追跡を回避）
        let currentPriority = primitiveValue(forKey: "priority") as? Int16 ?? 1

        if currentPriority < 1 {
            setPrimitiveValue(Int16(1), forKey: "priority")
        } else if currentPriority > 5 {
            setPrimitiveValue(Int16(5), forKey: "priority")
        }
    }
}