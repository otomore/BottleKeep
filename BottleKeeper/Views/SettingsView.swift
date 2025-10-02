import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bottle.createdAt, ascending: false)],
        animation: .default)
    private var bottles: FetchedResults<Bottle>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WishlistItem.createdAt, ascending: false)],
        animation: .default)
    private var wishlistItems: FetchedResults<WishlistItem>

    @State private var showingDeleteAlert = false

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "不明"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "不明"
    }

    // MARK: - Premium Features Section

    private var premiumFeaturesSection: some View {
        Section {
            // 1. 無制限コレクション
            PremiumFeatureRow(
                icon: "infinity",
                iconColor: .purple,
                title: "無制限コレクション",
                description: "10本の制限を解除して無制限にボトルを登録",
                price: "¥600",
                isPurchased: false
            )

            // 2. プレミアムガラスエフェクト
            PremiumFeatureRow(
                icon: "sparkles",
                iconColor: .blue,
                title: "プレミアムガラスエフェクト",
                description: "高級感あふれる特別なガラスデザインとテーマ",
                price: "¥480",
                isPurchased: false
            )

            // 3. 詳細統計＆分析
            PremiumFeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .green,
                title: "詳細統計＆分析",
                description: "コスト分析、熟成予測、地域別比較など高度な統計",
                price: "¥480",
                isPurchased: false
            )

            // 4. AIテイスティングアシスタント
            PremiumFeatureRow(
                icon: "brain",
                iconColor: .orange,
                title: "AIテイスティングアシスタント",
                description: "AIによるテイスティングノート提案とペアリング推奨",
                price: "¥720",
                isPurchased: false
            )

            // 5. コレクター認証バッジ
            PremiumFeatureRow(
                icon: "checkmark.seal.fill",
                iconColor: .yellow,
                title: "コレクター認証バッジ",
                description: "認証コレクターバッジと限定機能へのアクセス",
                price: "¥360",
                isPurchased: false
            )
        } header: {
            Text("プレミアム機能")
        } footer: {
            Text("※ 購入機能は現在準備中です")
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // アプリ情報セクション
                Section {
                    HStack {
                        Text("🥃")
                            .font(.largeTitle)
                            .frame(width: 60, height: 60)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("BottleKeeper")
                                .font(.headline)
                            Text("ウイスキーコレクション管理")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 機能設定
                Section("機能設定") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("通知設定", systemImage: "bell")
                            .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }
                }

                // プレミアム機能
                premiumFeaturesSection

                // バージョン情報
                Section("アプリ情報") {
                    HStack {
                        Label("バージョン", systemImage: "info.circle")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                }

                // データ管理
                Section("データ管理") {
                    HStack {
                        HStack {
                            Text("🥃")
                                .font(.body)
                            Text("総ボトル数")
                        }
                        Spacer()
                        Text("\(bottles.count)本")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("ウィッシュリスト", systemImage: "star.fill")
                        Spacer()
                        Text("\(wishlistItems.count)件")
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("すべてのデータを削除", systemImage: "trash.fill")
                    }
                }

                // アプリについて
                Section("アプリについて") {
                    HStack {
                        Label("開発者", systemImage: "person.fill")
                        Spacer()
                        Text("otomore")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://x.com/otomore01")!) {
                        HStack {
                            Label("X (Twitter)", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // フッター情報
                Section {
                    VStack(spacing: 8) {
                        Text("🥃")
                            .font(.largeTitle)

                        Text("ウイスキーコレクションを\n楽しく管理しましょう")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("設定")
            .alert("データ削除の確認", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("すべてのボトルとウィッシュリストのデータが削除されます。この操作は取り消せません。")
            }
        }
    }

    private func deleteAllData() {
        withAnimation {
            // すべてのボトルを削除
            bottles.forEach { bottle in
                viewContext.delete(bottle)
            }

            // すべてのウィッシュリストアイテムを削除
            wishlistItems.forEach { item in
                viewContext.delete(item)
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("⚠️ Failed to delete all data: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Premium Feature Row Component

struct PremiumFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let price: String
    let isPurchased: Bool

    var body: some View {
        Button {
            // TODO: 実際の購入処理を実装
            print("購入ボタンタップ: \(title)")
        } label: {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(10)

                // 説明
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // 価格または購入済みバッジ
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else {
                    VStack(spacing: 2) {
                        Text(price)
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("購入")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3), lineWidth: 1)
                }
        }
        .padding(.vertical, 6)
        .disabled(isPurchased)
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}