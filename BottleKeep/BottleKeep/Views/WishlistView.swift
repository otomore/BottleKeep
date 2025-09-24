import SwiftUI

struct WishlistView: View {
    @StateObject private var viewModel: WishlistViewModel

    init(diContainer: DIContainer = DIContainer()) {
        _viewModel = StateObject(wrappedValue: diContainer.makeWishlistViewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("ウィッシュリストを読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredItems.isEmpty {
                    emptyStateView
                } else {
                    wishlistContent
                }
            }
            .navigationTitle("ウィッシュリスト")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        viewModel.showingAddSheet = true
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "アイテムを検索")
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadWishlistItems()
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                WishlistItemFormView(viewModel: viewModel)
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "heart.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("ウィッシュリストが空です")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.hasActiveFilters ?
                 "条件に一致するアイテムが見つかりません" :
                 "欲しいボトルを追加してみましょう")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.hasActiveFilters {
                Button("フィルタをクリア") {
                    viewModel.clearSearch()
                    viewModel.clearPriorityFilter()
                }
                .buttonStyle(.bordered)
            } else {
                Button("最初のアイテムを追加") {
                    viewModel.showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private var wishlistContent: some View {
        VStack(spacing: 0) {
            // 統計サマリー
            wishlistSummary
                .padding()

            // フィルタセクション
            filterSection
                .padding(.horizontal)
                .padding(.bottom)

            // ウィッシュリスト
            List {
                ForEach(viewModel.filteredItems) { item in
                    WishlistItemRow(item: item, viewModel: viewModel)
                        .swipeActions(edge: .trailing) {
                            Button("削除", role: .destructive) {
                                Task {
                                    await viewModel.deleteItem(item)
                                }
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var wishlistSummary: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("総アイテム数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.totalItemsCount)件")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("総推定価値")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.totalEstimatedValueText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }

            Divider()

            HStack(spacing: 16) {
                PriorityBadge(count: viewModel.highPriorityCount, priority: 3, color: .red)
                PriorityBadge(count: viewModel.mediumPriorityCount, priority: 2, color: .orange)
                PriorityBadge(count: viewModel.lowPriorityCount, priority: 1, color: .blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var filterSection: some View {
        if viewModel.hasActiveFilters {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if !viewModel.searchText.isEmpty {
                        FilterChip(text: "検索: \(viewModel.searchText)") {
                            viewModel.clearSearch()
                        }
                    }

                    if let selectedPriority = viewModel.selectedPriority {
                        let priorityText = selectedPriority == 3 ? "高" : selectedPriority == 2 ? "中" : "低"
                        FilterChip(text: "優先度: \(priorityText)") {
                            viewModel.clearPriorityFilter()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct WishlistItemRow: View {
    let item: WishlistItem
    let viewModel: WishlistViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.medium)

                    Text(item.distillery)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    PriorityIndicator(priority: item.priority)

                    if item.estimatedPrice?.doubleValue ?? 0 > 0 {
                        Text(item.estimatedPriceText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !item.displaySummary.isEmpty {
                Text(item.displaySummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PriorityBadge: View {
    let count: Int
    let priority: Int16
    let color: Color

    private var priorityText: String {
        switch priority {
        case 3: return "高"
        case 2: return "中"
        case 1: return "低"
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text("優先度\(priorityText)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PriorityIndicator: View {
    let priority: Int16

    private var priorityInfo: (String, Color) {
        switch priority {
        case 3: return ("高", .red)
        case 2: return ("中", .orange)
        case 1: return ("低", .blue)
        default: return ("", .gray)
        }
    }

    var body: some View {
        let (text, color) = priorityInfo
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(4)
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

struct WishlistItemFormView: View {
    @ObservedObject var viewModel: WishlistViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var distillery: String = ""
    @State private var region: String = ""
    @State private var type: String = ""
    @State private var vintage: String = ""
    @State private var estimatedPrice: String = ""
    @State private var priority: Int16 = 1
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("ボトル名", text: $name)
                    TextField("蒸留所", text: $distillery)
                    TextField("地域", text: $region)
                    TextField("タイプ", text: $type)
                }

                Section("詳細情報") {
                    TextField("ヴィンテージ", text: $vintage)
                        .keyboardType(.numberPad)
                    TextField("推定価格", text: $estimatedPrice)
                        .keyboardType(.decimalPad)

                    Picker("優先度", selection: $priority) {
                        Text("低").tag(Int16(1))
                        Text("中").tag(Int16(2))
                        Text("高").tag(Int16(3))
                    }
                    .pickerStyle(.segmented)
                }

                Section("メモ") {
                    TextField("メモ", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("ウィッシュリストに追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        Task {
                            await viewModel.createItem(name: name, distillery: distillery)
                        }
                    }
                    .disabled(name.isEmpty || distillery.isEmpty)
                }
            }
        }
    }
}

#Preview {
    WishlistView()
}