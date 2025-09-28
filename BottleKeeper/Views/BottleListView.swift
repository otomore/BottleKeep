import SwiftUI

struct BottleListView: View {
    @StateObject private var viewModel: BottleListViewModel
    @EnvironmentObject private var diContainer: DIContainer

    @State private var showingAddBottle = false
    @State private var showingFilters = false

    // MARK: - Initialization

    init() {
        // この初期化はSwiftUIのプレビューやテスト用の暫定的なもの
        // 実際にはDIContainerから注入される
        self._viewModel = StateObject(wrappedValue: BottleListViewModel(
            repository: BottleRepository()
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {
                // 検索バー
                searchBar

                // フィルタチップ
                if viewModel.filterOption != .all {
                    filterChips
                }

                // ボトル一覧
                bottlesList
            }
            .navigationTitle("ボトル")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    filterButton
                }
            }
            .sheet(isPresented: $showingAddBottle) {
                BottleFormView()
            }
            .sheet(isPresented: $showingFilters) {
                FilterOptionsView(
                    selectedFilter: $viewModel.filterOption,
                    selectedSort: $viewModel.sortOption
                )
            }
            .task {
                await viewModel.loadBottles()
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            // DIContainerから適切なViewModelを取得
            if let properViewModel = try? diContainer.makeBottleListViewModel() as? BottleListViewModel {
                // ViewModelを更新（実際の実装では初期化時に行う）
            }
        }
    }

    // MARK: - View Components

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("ボトルを検索...", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                FilterChip(
                    title: viewModel.filterOption.title,
                    isSelected: true
                ) {
                    viewModel.filterOption = .all
                }
            }
            .padding(.horizontal)
        }
    }

    private var bottlesList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredBottles.isEmpty {
                emptyStateView
            } else {
                bottlesListContent
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("読み込み中...")
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "wineglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text(viewModel.searchText.isEmpty ? "ボトルがありません" : "検索結果がありません")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.searchText.isEmpty
                 ? "最初のボトルを追加してコレクションを始めましょう"
                 : "別のキーワードで検索してみてください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.searchText.isEmpty {
                Button("最初のボトルを追加") {
                    showingAddBottle = true
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var bottlesListContent: some View {
        List {
            ForEach(viewModel.filteredBottles) { bottle in
                NavigationLink(destination: BottleDetailView(bottle: bottle)) {
                    BottleRowView(bottle: bottle)
                }
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteBottles(at: indexSet)
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private var addButton: some View {
        Button(action: {
            showingAddBottle = true
        }) {
            Image(systemName: "plus")
        }
    }

    private var filterButton: some View {
        Button(action: {
            showingFilters = true
        }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - Supporting Views

struct BottleRowView: View {
    let bottle: Bottle

    var body: some View {
        HStack {
            // 写真（サムネイル）
            AsyncImage(url: nil) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "wineglass")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                // ボトル名
                Text(bottle.name)
                    .font(.headline)
                    .lineLimit(1)

                // 蒸留所
                Text(bottle.distillery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // 詳細情報
                if !bottle.shortDescription.isEmpty {
                    Text(bottle.shortDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // 評価
                if bottle.rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(bottle.rating)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                // 価格
                if let price = bottle.purchasePrice {
                    Text("¥\(price.intValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 開栓状態
                if bottle.isOpened {
                    Text("開栓済み")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    BottleListView()
        .environmentObject(DIContainer())
}