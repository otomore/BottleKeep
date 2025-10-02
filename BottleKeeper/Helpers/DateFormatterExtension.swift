import Foundation

/// DateFormatterの共有インスタンスを提供
/// パフォーマンス最適化: DateFormatterの生成は重い処理のため、静的インスタンスを再利用
extension DateFormatter {
    /// ボトル関連の日付フォーマッター（中形式、時刻なし、日本語）
    static let bottleDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    /// 短い日付フォーマッター（年/月/日）
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    /// 日時フォーマッター（日付＋時刻）
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}
