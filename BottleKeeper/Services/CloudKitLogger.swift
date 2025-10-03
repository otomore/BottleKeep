import Foundation

/// CloudKitの同期ログを記録・管理するクラス
class CloudKitLogger: ObservableObject {
    static let shared = CloudKitLogger()

    @Published private(set) var logs: [LogEntry] = []
    private let maxLogs = 200  // 最大保存ログ数

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: LogLevel
        let message: String

        var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }

        var icon: String {
            switch level {
            case .info: return "ℹ️"
            case .success: return "✅"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .debug: return "🔧"
            case .cloudKit: return "☁️"
            }
        }
    }

    enum LogLevel {
        case info
        case success
        case warning
        case error
        case debug
        case cloudKit
    }

    private init() {}

    /// ログを追加
    func log(_ message: String, level: LogLevel = .info) {
        DispatchQueue.main.async {
            let entry = LogEntry(timestamp: Date(), level: level, message: message)
            self.logs.insert(entry, at: 0)  // 新しいログを先頭に追加

            // 最大数を超えたら古いログを削除
            if self.logs.count > self.maxLogs {
                self.logs.removeLast()
            }

            // コンソールにも出力
            print("\(entry.icon) \(message)")
        }
    }

    /// すべてのログをクリア
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }

    /// ログをテキストとしてエクスポート
    func exportLogsAsText() -> String {
        return logs.reversed().map { entry in
            "[\(entry.formattedTimestamp)] \(entry.icon) \(entry.message)"
        }.joined(separator: "\n")
    }
}
