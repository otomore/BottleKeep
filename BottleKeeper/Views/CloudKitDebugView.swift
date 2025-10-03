import SwiftUI

struct CloudKitDebugView: View {
    @ObservedObject private var logger = CloudKitLogger.shared
    @State private var showingCopyConfirmation = false

    var body: some View {
        List {
            // ログエントリ
            Section {
                if logger.logs.isEmpty {
                    Text("ログがありません")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding()
                } else {
                    ForEach(logger.logs) { log in
                        LogEntryRow(entry: log)
                    }
                }
            } header: {
                HStack {
                    Text("CloudKit同期ログ")
                    Spacer()
                    Text("\(logger.logs.count)件")
                        .foregroundColor(.secondary)
                }
            }

            // アクションボタン
            Section {
                Button {
                    UIPasteboard.general.string = logger.exportLogsAsText()
                    showingCopyConfirmation = true
                } label: {
                    Label("ログをコピー", systemImage: "doc.on.clipboard")
                }
                .disabled(logger.logs.isEmpty)

                Button(role: .destructive) {
                    logger.clearLogs()
                } label: {
                    Label("ログをクリア", systemImage: "trash")
                }
                .disabled(logger.logs.isEmpty)
            }

            // ヘルプ情報
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ログの見方")
                        .font(.headline)

                    LogLegendItem(icon: "ℹ️", label: "情報", description: "一般的な情報")
                    LogLegendItem(icon: "✅", label: "成功", description: "処理が成功")
                    LogLegendItem(icon: "⚠️", label: "警告", description: "注意が必要")
                    LogLegendItem(icon: "❌", label: "エラー", description: "エラーが発生")
                    LogLegendItem(icon: "🔧", label: "デバッグ", description: "デバッグ情報")
                    LogLegendItem(icon: "☁️", label: "CloudKit", description: "CloudKit同期イベント")
                }
                .padding(.vertical, 8)
            } footer: {
                Text("CloudKitの同期状態を確認できます。問題が発生した場合は、このログをコピーして開発者に共有してください。")
            }
        }
        .navigationTitle("CloudKit デバッグ")
        .navigationBarTitleDisplayMode(.inline)
        .alert("コピー完了", isPresented: $showingCopyConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("ログをクリップボードにコピーしました")
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: CloudKitLogger.LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(entry.icon)
                    .font(.caption)

                Text(entry.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Text(entry.message)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Log Legend Item

struct LogLegendItem: View {
    let icon: String
    let label: String
    let description: String

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.caption)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CloudKitDebugView()
    }
}
