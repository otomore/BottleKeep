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

    var body: some View {
        NavigationStack {
            List {
                // アプリ情報セクション
                Section {
                    HStack {
                        Image(systemName: "wineglass.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
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
                        Label("総ボトル数", systemImage: "wineglass.fill")
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
                        Image(systemName: "wineglass")
                            .font(.title)
                            .foregroundColor(.gray)

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
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}