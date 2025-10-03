import SwiftUI
import CoreData

// MARK: - Settings View Model

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var showingDeleteAlert = false
    @Published var iCloudSyncAvailable = false
    @Published var showingSchemaInitAlert = false
    @Published var schemaInitError: String?
    @Published var isInitializingSchema = false

    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
        self.iCloudSyncAvailable = coreDataManager.isCloudSyncAvailable
    }

    var isCloudKitSchemaInitialized: Bool {
        coreDataManager.isCloudKitSchemaInitialized
    }

    var cloudKitLogs: [String] {
        coreDataManager.logs
    }

    /// すべてのデータを削除
    func deleteAllData(bottles: FetchedResults<Bottle>, wishlistItems: FetchedResults<WishlistItem>, context: NSManagedObjectContext) {
        guard !bottles.isEmpty || !wishlistItems.isEmpty else {
            print("ℹ️ No data to delete")
            return
        }

        let bottleCount = bottles.count
        let wishlistCount = wishlistItems.count

        // すべてのボトルを削除
        bottles.forEach { bottle in
            context.delete(bottle)
        }

        // すべてのウィッシュリストアイテムを削除
        wishlistItems.forEach { item in
            context.delete(item)
        }

        do {
            try context.save()
            print("✅ Deleted \(bottleCount) bottles and \(wishlistCount) wishlist items")
        } catch {
            let nsError = error as NSError
            print("❌ Failed to delete all data: \(nsError), \(nsError.userInfo)")

            // コンテキストをロールバックして変更を元に戻す
            context.rollback()
        }
    }

    /// CloudKitスキーマを初期化
    func initializeCloudKitSchema() {
        isInitializingSchema = true
        schemaInitError = nil

        Task {
            do {
                try coreDataManager.initializeCloudKitSchema()
                await MainActor.run {
                    isInitializingSchema = false
                    showingSchemaInitAlert = true
                }
            } catch {
                await MainActor.run {
                    isInitializingSchema = false
                    schemaInitError = error.localizedDescription
                    showingSchemaInitAlert = true
                }
            }
        }
    }

    /// iCloud同期状態を更新
    func refreshCloudSyncStatus() {
        iCloudSyncAvailable = coreDataManager.isCloudSyncAvailable
    }
}

// MARK: - Settings View

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

    @StateObject private var viewModel = SettingsViewModel()
    private var coreDataManager = CoreDataManager.shared

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
                    }
                    .padding()
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }
                }

                // プレミアム機能
                premiumFeaturesSection

                // iCloud同期状態
                Section {
                    // 同期状態
                    HStack {
                        Label("同期状態", systemImage: "icloud")
                        Spacer()
                        if viewModel.iCloudSyncAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("利用可能")
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("利用不可")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    // スキーマ初期化状態
                    HStack {
                        Label("スキーマ初期化", systemImage: "cloud.fill")
                        Spacer()
                        if viewModel.isCloudKitSchemaInitialized {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("初期化済み")
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text("未初期化")
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    // スキーマ初期化ボタン
                    Button {
                        viewModel.initializeCloudKitSchema()
                    } label: {
                        HStack {
                            Label("CloudKitスキーマを初期化", systemImage: "arrow.clockwise.icloud")
                            Spacer()
                            if viewModel.isInitializingSchema {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isInitializingSchema || !viewModel.iCloudSyncAvailable)

                    // デバッグログへのリンク
                    NavigationLink(destination: CloudKitDebugLogView()) {
                        Label("デバッグログを表示", systemImage: "list.bullet.rectangle")
                    }
                } header: {
                    Text("iCloud同期")
                } footer: {
                    if !viewModel.iCloudSyncAvailable {
                        Text("iCloud同期を使用するには、デバイスでiCloudにサインインしてください。")
                    } else if !viewModel.isCloudKitSchemaInitialized {
                        Text("初めてiCloud同期を使用する場合、またはデータが同期されない場合は、CloudKitスキーマの初期化を実行してください。")
                    } else {
                        Text("iCloudを使用してデバイス間でデータを自動同期します。問題が発生した場合は、デバッグログを確認してください。")
                    }
                }

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
                        viewModel.showingDeleteAlert = true
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
            .onAppear {
                viewModel.refreshCloudSyncStatus()
            }
            .alert("データ削除の確認", isPresented: $viewModel.showingDeleteAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    withAnimation {
                        viewModel.deleteAllData(bottles: bottles, wishlistItems: wishlistItems, context: viewContext)
                    }
                }
            } message: {
                Text("すべてのボトルとウィッシュリストのデータが削除されます。この操作は取り消せません。")
            }
            .alert(viewModel.schemaInitError == nil ? "初期化完了" : "初期化エラー", isPresented: $viewModel.showingSchemaInitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.schemaInitError {
                    Text("CloudKitスキーマの初期化に失敗しました：\(error)")
                } else {
                    Text("CloudKitスキーマの初期化が完了しました。データの同期が開始されます。")
                }
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
            .padding()
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3), lineWidth: 1)
                }
        }
        .disabled(isPurchased)
    }
}

// MARK: - CloudKit Debug Log View

struct CloudKitDebugLogView: View {
    @ObservedObject private var coreDataManager = CoreDataManager.shared
    @State private var showingCopyConfirmation = false
    @State private var showingClearConfirmation = false

    var body: some View {
        List {
            Section {
                if coreDataManager.logs.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "text.alignleft")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("ログがありません")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(coreDataManager.logs, id: \.self) { log in
                        Text(log)
                            .font(.caption)
                            .textSelection(.enabled)
                            .padding(.vertical, 4)
                    }
                }
            } header: {
                HStack {
                    Text("CloudKit同期ログ")
                    Spacer()
                    Text("\(coreDataManager.logs.count)件")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } footer: {
                Text("ログは最新100件まで保存されます。CloudKit同期に関するイベントとエラーが記録されます。")
                    .font(.caption2)
            }

            Section {
                Button {
                    UIPasteboard.general.string = coreDataManager.logs.joined(separator: "\n")
                    showingCopyConfirmation = true
                } label: {
                    Label("ログをコピー", systemImage: "doc.on.clipboard")
                }
                .disabled(coreDataManager.logs.isEmpty)

                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    Label("ログをクリア", systemImage: "trash")
                }
                .disabled(coreDataManager.logs.isEmpty)
            }
        }
        .navigationTitle("CloudKit デバッグ")
        .navigationBarTitleDisplayMode(.inline)
        .alert("コピー完了", isPresented: $showingCopyConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("ログをクリップボードにコピーしました")
        }
        .alert("ログをクリア", isPresented: $showingClearConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("クリア", role: .destructive) {
                coreDataManager.clearLogs()
            }
        } message: {
            Text("すべてのログを削除します。この操作は取り消せません。")
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}