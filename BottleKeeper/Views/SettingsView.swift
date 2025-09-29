import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDataExport = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                Section("アプリ情報") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("このアプリについて")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section("データ管理") {
                    Button {
                        showingDataExport = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                            Text("データエクスポート")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        // バックアップ機能
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("iCloudバックアップ")
                            Spacer()
                            Text("自動")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section("表示設定") {
                    HStack {
                        Image(systemName: "textformat.size")
                            .foregroundColor(.purple)
                        Text("フォントサイズ")
                        Spacer()
                        Text("システム設定に従う")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "circle.lefthalf.filled")
                            .foregroundColor(.orange)
                        Text("外観")
                        Spacer()
                        Text("システム設定に従う")
                            .foregroundColor(.secondary)
                    }
                }

                Section("サポート") {
                    Button {
                        // フィードバック送信
                        if let url = URL(string: "mailto:support@bottlekeeper.app?subject=BottleKeeper フィードバック") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                            Text("フィードバック送信")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        // レビュー依頼
                        if let url = URL(string: "https://apps.apple.com/app/id1234567890") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(.yellow)
                            Text("App Storeでレビュー")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section("開発者情報") {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BottleKeeper")
                                .font(.subheadline)
                            Text("個人開発プロジェクト")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                Text("データエクスポート")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("コレクションデータをCSV形式でエクスポートできます。バックアップや他のアプリでの利用に便利です。")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("CSVファイルとしてエクスポート")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isExporting)

                    if isExporting {
                        ProgressView("エクスポート中...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("データエクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportData() {
        isExporting = true
        // エクスポート処理の実装
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            // エクスポート完了の処理
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 16) {
                        Image(systemName: "wineglass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("BottleKeeper")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("バージョン 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("概要")
                            .font(.headline)

                        Text("BottleKeeperは、ウイスキー愛好家のためのコレクション管理アプリです。あなたの貴重なウイスキーコレクションを整理し、テイスティング体験を記録できます。")

                        Text("主な機能")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "list.bullet", text: "ボトル管理 - 詳細情報と写真の記録")
                            FeatureRow(icon: "drop.fill", text: "残量管理 - 飲酒記録と残量の視覚化")
                            FeatureRow(icon: "magnifyingglass", text: "検索・フィルタ - 素早いボトル検索")
                            FeatureRow(icon: "chart.bar", text: "統計情報 - コレクションの分析")
                            FeatureRow(icon: "star", text: "ウィッシュリスト - 欲しいボトルの管理")
                        }

                        Text("技術情報")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(title: "開発言語", value: "Swift")
                            DetailRow(title: "UIフレームワーク", value: "SwiftUI")
                            DetailRow(title: "データ管理", value: "Core Data")
                            DetailRow(title: "対応OS", value: "iOS 26.0+, iPadOS 26.0+")
                        }

                        Text("開発者")
                            .font(.headline)

                        Text("個人開発プロジェクトとして、ウイスキー愛好家による、ウイスキー愛好家のためのアプリを目指して開発されています。")
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
            Spacer()
        }
        .font(.subheadline)
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}