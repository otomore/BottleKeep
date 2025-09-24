import Foundation
import CoreData

@objc(WishlistItem)
public class WishlistItem: NSManagedObject {

    // MARK: - Convenience Initializers

    convenience init(context: NSManagedObjectContext, name: String, distillery: String) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.distillery = distillery
        self.createdAt = Date()
        self.updatedAt = Date()
        self.priority = 1
    }

    // MARK: - Computed Properties

    /// 優先度の文字列表現
    var priorityText: String {
        switch priority {
        case 1:
            return "低"
        case 2:
            return "中"
        case 3:
            return "高"
        default:
            return "未設定"
        }
    }

    /// 優先度の色
    var priorityColor: String {
        switch priority {
        case 1:
            return "blue"
        case 2:
            return "orange"
        case 3:
            return "red"
        default:
            return "gray"
        }
    }

    /// 推定価格の表示用文字列
    var estimatedPriceText: String {
        guard let estimatedPrice = estimatedPrice, estimatedPrice.doubleValue > 0 else {
            return "未設定"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: NSNumber(value: estimatedPrice.doubleValue)) ?? "¥0"
    }

    /// アイテムの表示用サマリー
    var displaySummary: String {
        var components: [String] = []

        if let region = region, !region.isEmpty {
            components.append(region)
        }

        if let type = type, !type.isEmpty {
            components.append(type)
        }

        if vintage > 0 {
            components.append("\(vintage)年")
        }

        return components.joined(separator: " • ")
    }

    // MARK: - Validation

    /// アイテムのバリデーション
    func validate() throws {
        // 名前のバリデーション
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }

        // 蒸留所名のバリデーション
        guard !distillery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyDistillery
        }

        // 優先度のバリデーション
        guard priority >= 1 && priority <= 3 else {
            throw ValidationError.invalidPriority
        }

        // ヴィンテージのバリデーション
        let currentYear = Calendar.current.component(.year, from: Date())
        if vintage > 0 && (vintage < 1800 || vintage > Int32(currentYear + 10)) {
            throw ValidationError.invalidVintage
        }
    }

    // MARK: - Core Data Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()

        if id == nil {
            id = UUID()
        }

        let now = Date()
        if createdAt == nil {
            createdAt = now
        }
        updatedAt = now

        if priority == 0 {
            priority = 1
        }
    }

    public override func willSave() {
        super.willSave()

        if !isDeleted {
            updatedAt = Date()
        }
    }
}

// MARK: - ValidationError Extension

extension ValidationError {
    static let invalidPriority = ValidationError.custom("優先度は1〜3の範囲で設定してください")
    static let invalidVintage = ValidationError.custom("ヴィンテージが無効です")
}