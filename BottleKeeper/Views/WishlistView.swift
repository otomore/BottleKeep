import SwiftUI
import CoreData

struct WishlistView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \WishlistItem.priority, ascending: false),
            NSSortDescriptor(keyPath: \WishlistItem.createdAt, ascending: false)
        ],
        animation: .default)
    private var wishlistItems: FetchedResults<WishlistItem>

    @State private var showingAddItem = false
    @State private var searchText = ""
    @State private var itemToMoveToCollection: WishlistItem?
    @State private var showingMoveConfirmation = false

    var filteredItems: [WishlistItem] {
        if searchText.isEmpty {
            return Array(wishlistItems)
        } else {
            return wishlistItems.filter { item in
                item.wrappedName.localizedCaseInsensitiveContains(searchText) ||
                item.wrappedDistillery.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if wishlistItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("ウィッシュリストが空です")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("欲しいウイスキーを追加して管理しましょう")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            showingAddItem = true
                        } label: {
                            Label("追加する", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                } else {
                    List {
                        ForEach(filteredItems, id: \.id) { item in
                            WishlistRowView(item: item, onMoveToCollection: {
                                itemToMoveToCollection = item
                                showingMoveConfirmation = true
                            })
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .searchable(text: $searchText, prompt: "銘柄名や蒸留所で検索")
                }
            }
            .navigationTitle("ウィッシュリスト")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                if !wishlistItems.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                WishlistFormView(wishlistItem: nil)
            }
            .alert("コレクションに追加", isPresented: $showingMoveConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("追加") {
                    if let item = itemToMoveToCollection {
                        moveToCollection(item)
                    }
                }
            } message: {
                if let item = itemToMoveToCollection {
                    Text("\(item.wrappedName)をコレクションに追加しますか？")
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredItems[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("⚠️ Failed to delete wishlist items: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func moveToCollection(_ item: WishlistItem) {
        withAnimation {
            // 新しいボトルを作成
            let bottle = Bottle(context: viewContext)
            bottle.id = UUID()
            bottle.name = item.name
            bottle.distillery = item.distillery
            bottle.createdAt = Date()
            bottle.updatedAt = Date()
            bottle.volume = 700 // デフォルト値
            bottle.remainingVolume = 700 // 新品として登録
            bottle.abv = 40.0 // デフォルト値

            // ウィッシュリストから削除
            viewContext.delete(item)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("⚠️ Failed to move item to collection: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct WishlistRowView: View {
    let item: WishlistItem
    let onMoveToCollection: () -> Void

    @State private var showingEditForm = false

    var body: some View {
        HStack(spacing: 12) {
            // 優先度インジケーター
            RoundedRectangle(cornerRadius: 4)
                .fill(priorityColor(for: item.priority))
                .frame(width: 4, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.wrappedName)
                    .font(.headline)

                Text(item.wrappedDistillery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    // 優先度
                    Label(item.priorityLevel, systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundColor(priorityColor(for: item.priority))

                    // 価格情報
                    if let targetPrice = item.targetPrice {
                        Label("¥\(targetPrice)", systemImage: "yensign.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            // アクションボタン
            Menu {
                Button {
                    showingEditForm = true
                } label: {
                    Label("編集", systemImage: "pencil")
                }

                Button {
                    onMoveToCollection()
                } label: {
                    Label("コレクションに追加", systemImage: "plus.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
        }
        .padding()
        .primaryGlassEffect()
        .sheet(isPresented: $showingEditForm) {
            WishlistFormView(wishlistItem: item)
        }
    }

    private func priorityColor(for priority: Int16) -> Color {
        switch priority {
        case 5:
            return .red
        case 4:
            return .orange
        case 3:
            return .yellow
        case 2:
            return .green
        case 1:
            return .blue
        default:
            return .gray
        }
    }
}

#Preview {
    WishlistView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}