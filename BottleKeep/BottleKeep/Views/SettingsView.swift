import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("iCloud") {
                    HStack {
                        Image(systemName: "icloud")
                        Text("iCloud同期")
                        Spacer()
                        Text("オン")
                            .foregroundColor(.secondary)
                    }
                }

                Section("データ") {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("データをエクスポート")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                Section("アプリについて") {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "heart")
                        Text("開発者")
                        Spacer()
                        Text("BottleKeep Team")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
}