import Foundation
import SwiftUI

/// ウィッシュリスト画面のViewModel
@MainActor
class WishlistViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var wishlistItems: [WishlistItem] = []
    @Published var filteredItems: [WishlistItem] = []
    @Published var searchText: String = "" {
        didSet { filterItems() }
    }
    @Published var selectedPriority: Int16? = nil {
        didSet { filterItems() }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingAddSheet: Bool = false

    // MARK: - Private Properties

    private let repository: WishlistRepositoryProtocol
    private var searchWorkItem: DispatchWorkItem?

    // MARK: - Initialization

    init(repository: WishlistRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// ウィッシュリストアイテムを読み込み
    func loadWishlistItems() async {
        isLoading = true
        errorMessage = nil

        do {
            let items = try await repository.fetchAllWishlistItems()
            self.wishlistItems = items
            filterItems()
            isLoading = false
        } catch {
            errorMessage = "ウィッシュリストの読み込みに失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// アイテムを削除
    func deleteItem(_ item: WishlistItem) async {
        do {
            try await repository.deleteWishlistItem(item)
            await loadWishlistItems()
        } catch {
            errorMessage = "アイテムの削除に失敗しました: \(error.localizedDescription)"
        }
    }

    /// アイテムを更新
    func updateItem(_ item: WishlistItem) async {
        do {
            try await repository.saveWishlistItem(item)
            await loadWishlistItems()
        } catch {
            errorMessage = "アイテムの更新に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 新しいアイテムを作成
    func createItem(name: String, distillery: String) async {
        guard !name.isEmpty && !distillery.isEmpty else {
            errorMessage = "名前と蒸留所名は必須です"
            return
        }

        do {
            _ = try await repository.createWishlistItem(name: name, distillery: distillery)
            await loadWishlistItems()
            showingAddSheet = false
        } catch {
            errorMessage = "アイテムの作成に失敗しました: \(error.localizedDescription)"
        }
    }

    /// データを更新
    func refreshData() async {
        await loadWishlistItems()
    }

    // MARK: - Private Methods

    /// アイテムをフィルタリング
    private func filterItems() {
        // 検索のデバウンス処理
        searchWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            Task { @MainActor in
                self.performFiltering()
            }
        }

        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    /// フィルタリングの実行
    private func performFiltering() {
        var filtered = wishlistItems

        // 検索テキストでフィルタ
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { item in
                item.name.lowercased().contains(query) ||
                item.distillery.lowercased().contains(query) ||
                item.region?.lowercased().contains(query) == true ||
                item.type?.lowercased().contains(query) == true
            }
        }

        // 優先度でフィルタ
        if let selectedPriority = selectedPriority {
            filtered = filtered.filter { $0.priority == selectedPriority }
        }

        filteredItems = filtered
    }

    /// 優先度フィルタをクリア
    func clearPriorityFilter() {
        selectedPriority = nil
    }

    /// 検索をクリア
    func clearSearch() {
        searchText = ""
    }

    /// エラーをクリア
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Computed Properties

extension WishlistViewModel {

    /// 高優先度アイテムの数
    var highPriorityCount: Int {
        wishlistItems.filter { $0.priority == 3 }.count
    }

    /// 中優先度アイテムの数
    var mediumPriorityCount: Int {
        wishlistItems.filter { $0.priority == 2 }.count
    }

    /// 低優先度アイテムの数
    var lowPriorityCount: Int {
        wishlistItems.filter { $0.priority == 1 }.count
    }

    /// 総アイテム数
    var totalItemsCount: Int {
        wishlistItems.count
    }

    /// 総推定価値
    var totalEstimatedValue: Decimal {
        wishlistItems.compactMap { $0.estimatedPrice?.decimalValue }
                    .reduce(Decimal(0), +)
    }

    /// 総推定価値の表示用文字列
    var totalEstimatedValueText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: NSNumber(value: totalEstimatedValue.doubleValue)) ?? "¥0"
    }

    /// アクティブなフィルタの数
    var activeFiltersCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if selectedPriority != nil { count += 1 }
        return count
    }

    /// フィルタが適用されているかどうか
    var hasActiveFilters: Bool {
        activeFiltersCount > 0
    }
}