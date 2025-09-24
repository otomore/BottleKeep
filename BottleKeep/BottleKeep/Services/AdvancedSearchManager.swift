import Foundation
import CoreData

/// 高度な検索・フィルタ機能を管理するサービス
class AdvancedSearchManager: ObservableObject {

    static let shared = AdvancedSearchManager()

    @Published var savedSearches: [SavedSearch] = []
    @Published var recentSearches: [String] = []
    @Published var searchSuggestions: [SearchSuggestion] = []

    private let bottleRepository: BottleRepositoryProtocol
    private let wishlistRepository: WishlistRepositoryProtocol
    private let maxRecentSearches = 20

    private init() {
        self.bottleRepository = BottleRepository()
        self.wishlistRepository = WishlistRepository()
        loadSavedSearches()
        loadRecentSearches()
    }

    // MARK: - Advanced Search

    /// 高度な検索を実行
    func performAdvancedSearch(_ criteria: SearchCriteria) async throws -> SearchResult {
        let predicate = buildPredicate(from: criteria)
        let sortDescriptors = buildSortDescriptors(from: criteria.sortOptions)

        let bottles = try await bottleRepository.fetchBottles(with: predicate, sortDescriptors: sortDescriptors)

        // 検索結果の統計を計算
        let statistics = calculateSearchStatistics(bottles: bottles)

        // 最近の検索履歴に追加
        if !criteria.searchText.isEmpty {
            addToRecentSearches(criteria.searchText)
        }

        return SearchResult(
            bottles: bottles,
            totalCount: bottles.count,
            statistics: statistics,
            criteria: criteria
        )
    }

    /// ウィッシュリストの高度な検索
    func performWishlistSearch(_ criteria: WishlistSearchCriteria) async throws -> WishlistSearchResult {
        let predicate = buildWishlistPredicate(from: criteria)
        let sortDescriptors = buildWishlistSortDescriptors(from: criteria.sortOptions)

        let items = try await wishlistRepository.fetchWishlistItems(with: predicate, sortDescriptors: sortDescriptors)

        return WishlistSearchResult(
            items: items,
            totalCount: items.count,
            criteria: criteria
        )
    }

    /// 検索予測・提案を生成
    func generateSearchSuggestions(for query: String) async {
        guard !query.isEmpty else {
            searchSuggestions = []
            return
        }

        do {
            let bottles = try await bottleRepository.fetchAllBottles()
            var suggestions: Set<SearchSuggestion> = []

            // 名前からの提案
            for bottle in bottles {
                if bottle.name.lowercased().contains(query.lowercased()) {
                    suggestions.insert(SearchSuggestion(
                        text: bottle.name,
                        type: .bottleName,
                        category: "ボトル名"
                    ))
                }

                if bottle.distillery.lowercased().contains(query.lowercased()) {
                    suggestions.insert(SearchSuggestion(
                        text: bottle.distillery,
                        type: .distillery,
                        category: "蒸留所"
                    ))
                }

                if let region = bottle.region, region.lowercased().contains(query.lowercased()) {
                    suggestions.insert(SearchSuggestion(
                        text: region,
                        type: .region,
                        category: "地域"
                    ))
                }

                if let type = bottle.type, type.lowercased().contains(query.lowercased()) {
                    suggestions.insert(SearchSuggestion(
                        text: type,
                        type: .type,
                        category: "タイプ"
                    ))
                }
            }

            // 最近の検索から提案
            for recentSearch in recentSearches.prefix(5) {
                if recentSearch.lowercased().contains(query.lowercased()) {
                    suggestions.insert(SearchSuggestion(
                        text: recentSearch,
                        type: .recent,
                        category: "最近の検索"
                    ))
                }
            }

            await MainActor.run {
                self.searchSuggestions = Array(suggestions).sorted { $0.text < $1.text }
            }

        } catch {
            print("検索提案の生成に失敗: \(error)")
            await MainActor.run {
                self.searchSuggestions = []
            }
        }
    }

    // MARK: - Saved Searches

    /// 検索条件を保存
    func saveSearch(_ criteria: SearchCriteria, name: String) {
        let savedSearch = SavedSearch(
            id: UUID(),
            name: name,
            criteria: criteria,
            createdAt: Date()
        )

        savedSearches.append(savedSearch)
        saveSavedSearches()
    }

    /// 保存済み検索を削除
    func deleteSavedSearch(_ savedSearch: SavedSearch) {
        savedSearches.removeAll { $0.id == savedSearch.id }
        saveSavedSearches()
    }

    /// 保存済み検索を実行
    func executeSavedSearch(_ savedSearch: SavedSearch) async throws -> SearchResult {
        return try await performAdvancedSearch(savedSearch.criteria)
    }

    // MARK: - Quick Filters

    /// クイックフィルタを生成
    func generateQuickFilters() async -> [QuickFilter] {
        do {
            let bottles = try await bottleRepository.fetchAllBottles()
            var filters: [QuickFilter] = []

            // 評価別フィルタ
            filters.append(QuickFilter(
                name: "高評価 (4★以上)",
                criteria: SearchCriteria(minRating: 4),
                icon: "star.fill",
                color: "yellow"
            ))

            // 開栓状態フィルタ
            filters.append(QuickFilter(
                name: "未開栓",
                criteria: SearchCriteria(openedStatus: .unopened),
                icon: "circle",
                color: "blue"
            ))

            filters.append(QuickFilter(
                name: "開栓済み",
                criteria: SearchCriteria(openedStatus: .opened),
                icon: "checkmark.circle",
                color: "green"
            ))

            // 価格帯フィルタ
            filters.append(QuickFilter(
                name: "高価格帯 (¥20,000以上)",
                criteria: SearchCriteria(minPrice: 20000),
                icon: "yensign.circle",
                color: "red"
            ))

            // 地域別フィルタ（動的生成）
            let regions = Set(bottles.compactMap { $0.region }).sorted()
            for region in regions.prefix(5) {
                filters.append(QuickFilter(
                    name: region,
                    criteria: SearchCriteria(regions: [region]),
                    icon: "globe",
                    color: "purple"
                ))
            }

            return filters

        } catch {
            print("クイックフィルタの生成に失敗: \(error)")
            return []
        }
    }

    // MARK: - Smart Search

    /// スマート検索（自然言語処理）
    func performSmartSearch(_ naturalLanguageQuery: String) async throws -> SearchResult {
        let criteria = parseNaturalLanguageQuery(naturalLanguageQuery)
        return try await performAdvancedSearch(criteria)
    }

    /// 自然言語クエリを解析
    private func parseNaturalLanguageQuery(_ query: String) -> SearchCriteria {
        var criteria = SearchCriteria()
        let lowercaseQuery = query.lowercased()

        // 評価に関するキーワード
        if lowercaseQuery.contains("高評価") || lowercaseQuery.contains("おすすめ") {
            criteria.minRating = 4
        } else if lowercaseQuery.contains("低評価") {
            criteria.maxRating = 2
        }

        // 開栓状態に関するキーワード
        if lowercaseQuery.contains("未開栓") || lowercaseQuery.contains("まだ開けてない") {
            criteria.openedStatus = .unopened
        } else if lowercaseQuery.contains("開栓済み") || lowercaseQuery.contains("飲んだ") {
            criteria.openedStatus = .opened
        }

        // 価格に関するキーワード
        if lowercaseQuery.contains("高い") || lowercaseQuery.contains("高価") {
            criteria.minPrice = 15000
        } else if lowercaseQuery.contains("安い") || lowercaseQuery.contains("安価") {
            criteria.maxPrice = 10000
        }

        // 地域に関するキーワード
        let regionKeywords = ["スコットランド", "日本", "アイルランド", "アメリカ", "カナダ"]
        for keyword in regionKeywords {
            if lowercaseQuery.contains(keyword.lowercased()) {
                criteria.regions = [keyword]
                break
            }
        }

        // タイプに関するキーワード
        let typeKeywords = ["シングルモルト", "ブレンデッド", "バーボン", "ライ", "テネシー"]
        for keyword in typeKeywords {
            if lowercaseQuery.contains(keyword.lowercased()) {
                criteria.types = [keyword]
                break
            }
        }

        return criteria
    }

    // MARK: - Helper Methods

    private func buildPredicate(from criteria: SearchCriteria) -> NSPredicate? {
        var predicates: [NSPredicate] = []

        // テキスト検索
        if !criteria.searchText.isEmpty {
            let searchPredicate = NSPredicate(
                format: "name CONTAINS[cd] %@ OR distillery CONTAINS[cd] %@ OR notes CONTAINS[cd] %@",
                criteria.searchText, criteria.searchText, criteria.searchText
            )
            predicates.append(searchPredicate)
        }

        // 評価フィルタ
        if let minRating = criteria.minRating {
            predicates.append(NSPredicate(format: "rating >= %d", minRating))
        }
        if let maxRating = criteria.maxRating {
            predicates.append(NSPredicate(format: "rating <= %d", maxRating))
        }

        // 価格フィルタ
        if let minPrice = criteria.minPrice {
            predicates.append(NSPredicate(format: "purchasePrice >= %@", NSDecimalNumber(value: minPrice)))
        }
        if let maxPrice = criteria.maxPrice {
            predicates.append(NSPredicate(format: "purchasePrice <= %@", NSDecimalNumber(value: maxPrice)))
        }

        // ABVフィルタ
        if let minABV = criteria.minABV {
            predicates.append(NSPredicate(format: "abv >= %f", minABV))
        }
        if let maxABV = criteria.maxABV {
            predicates.append(NSPredicate(format: "abv <= %f", maxABV))
        }

        // 開栓状態フィルタ
        switch criteria.openedStatus {
        case .opened:
            predicates.append(NSPredicate(format: "openedDate != nil"))
        case .unopened:
            predicates.append(NSPredicate(format: "openedDate == nil"))
        case .all:
            break
        }

        // 地域フィルタ
        if !criteria.regions.isEmpty {
            let regionPredicate = NSPredicate(format: "region IN %@", criteria.regions)
            predicates.append(regionPredicate)
        }

        // タイプフィルタ
        if !criteria.types.isEmpty {
            let typePredicate = NSPredicate(format: "type IN %@", criteria.types)
            predicates.append(typePredicate)
        }

        // 蒸留所フィルタ
        if !criteria.distilleries.isEmpty {
            let distilleryPredicate = NSPredicate(format: "distillery IN %@", criteria.distilleries)
            predicates.append(distilleryPredicate)
        }

        // ヴィンテージフィルタ
        if let minVintage = criteria.minVintage {
            predicates.append(NSPredicate(format: "vintage >= %d", minVintage))
        }
        if let maxVintage = criteria.maxVintage {
            predicates.append(NSPredicate(format: "vintage <= %d", maxVintage))
        }

        // 日付フィルタ
        if let startDate = criteria.purchaseDateStart {
            predicates.append(NSPredicate(format: "purchaseDate >= %@", startDate as NSDate))
        }
        if let endDate = criteria.purchaseDateEnd {
            predicates.append(NSPredicate(format: "purchaseDate <= %@", endDate as NSDate))
        }

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func buildWishlistPredicate(from criteria: WishlistSearchCriteria) -> NSPredicate? {
        var predicates: [NSPredicate] = []

        // テキスト検索
        if !criteria.searchText.isEmpty {
            let searchPredicate = NSPredicate(
                format: "name CONTAINS[cd] %@ OR distillery CONTAINS[cd] %@ OR notes CONTAINS[cd] %@",
                criteria.searchText, criteria.searchText, criteria.searchText
            )
            predicates.append(searchPredicate)
        }

        // 優先度フィルタ
        if !criteria.priorities.isEmpty {
            let priorityPredicate = NSPredicate(format: "priority IN %@", criteria.priorities)
            predicates.append(priorityPredicate)
        }

        // その他のフィルタも同様に実装...

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func buildSortDescriptors(from sortOptions: [SearchSortOption]) -> [NSSortDescriptor] {
        return sortOptions.map { option in
            let keyPath: String
            switch option.field {
            case .name:
                keyPath = "name"
            case .distillery:
                keyPath = "distillery"
            case .rating:
                keyPath = "rating"
            case .purchasePrice:
                keyPath = "purchasePrice"
            case .purchaseDate:
                keyPath = "purchaseDate"
            case .createdAt:
                keyPath = "createdAt"
            case .updatedAt:
                keyPath = "updatedAt"
            case .abv:
                keyPath = "abv"
            case .vintage:
                keyPath = "vintage"
            }
            return NSSortDescriptor(key: keyPath, ascending: option.ascending)
        }
    }

    private func buildWishlistSortDescriptors(from sortOptions: [WishlistSortOption]) -> [NSSortDescriptor] {
        return sortOptions.map { option in
            let keyPath: String
            switch option.field {
            case .name:
                keyPath = "name"
            case .distillery:
                keyPath = "distillery"
            case .priority:
                keyPath = "priority"
            case .estimatedPrice:
                keyPath = "estimatedPrice"
            case .createdAt:
                keyPath = "createdAt"
            }
            return NSSortDescriptor(key: keyPath, ascending: option.ascending)
        }
    }

    private func calculateSearchStatistics(bottles: [Bottle]) -> SearchStatistics {
        let totalValue = bottles.compactMap { $0.purchasePrice?.decimalValue }.reduce(Decimal(0), +)
        let averageRating = bottles.filter { $0.rating > 0 }.map { Double($0.rating) }.reduce(0, +) / Double(bottles.filter { $0.rating > 0 }.count)
        let openedCount = bottles.filter { $0.openedDate != nil }.count

        return SearchStatistics(
            totalBottles: bottles.count,
            openedBottles: openedCount,
            averageRating: averageRating.isNaN ? 0 : averageRating,
            totalValue: totalValue
        )
    }

    // MARK: - Persistence

    private func loadSavedSearches() {
        if let data = UserDefaults.standard.data(forKey: "SavedSearches"),
           let searches = try? JSONDecoder().decode([SavedSearch].self, from: data) {
            savedSearches = searches
        }
    }

    private func saveSavedSearches() {
        if let data = try? JSONEncoder().encode(savedSearches) {
            UserDefaults.standard.set(data, forKey: "SavedSearches")
        }
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "RecentSearches") ?? []
    }

    private func addToRecentSearches(_ searchText: String) {
        recentSearches.removeAll { $0 == searchText }
        recentSearches.insert(searchText, at: 0)

        if recentSearches.count > maxRecentSearches {
            recentSearches.removeLast()
        }

        UserDefaults.standard.set(recentSearches, forKey: "RecentSearches")
    }
}

// MARK: - Supporting Types

struct SearchCriteria: Codable {
    var searchText: String = ""
    var minRating: Int? = nil
    var maxRating: Int? = nil
    var minPrice: Double? = nil
    var maxPrice: Double? = nil
    var minABV: Double? = nil
    var maxABV: Double? = nil
    var openedStatus: OpenedStatus = .all
    var regions: [String] = []
    var types: [String] = []
    var distilleries: [String] = []
    var minVintage: Int32? = nil
    var maxVintage: Int32? = nil
    var purchaseDateStart: Date? = nil
    var purchaseDateEnd: Date? = nil
    var sortOptions: [SearchSortOption] = []

    enum OpenedStatus: String, Codable, CaseIterable {
        case all = "all"
        case opened = "opened"
        case unopened = "unopened"

        var displayName: String {
            switch self {
            case .all: return "すべて"
            case .opened: return "開栓済み"
            case .unopened: return "未開栓"
            }
        }
    }
}

struct WishlistSearchCriteria: Codable {
    var searchText: String = ""
    var priorities: [Int16] = []
    var minEstimatedPrice: Double? = nil
    var maxEstimatedPrice: Double? = nil
    var regions: [String] = []
    var types: [String] = []
    var distilleries: [String] = []
    var sortOptions: [WishlistSortOption] = []
}

struct SearchSortOption: Codable {
    let field: SortField
    let ascending: Bool

    enum SortField: String, Codable, CaseIterable {
        case name, distillery, rating, purchasePrice, purchaseDate, createdAt, updatedAt, abv, vintage

        var displayName: String {
            switch self {
            case .name: return "名前"
            case .distillery: return "蒸留所"
            case .rating: return "評価"
            case .purchasePrice: return "購入価格"
            case .purchaseDate: return "購入日"
            case .createdAt: return "登録日"
            case .updatedAt: return "更新日"
            case .abv: return "アルコール度数"
            case .vintage: return "ヴィンテージ"
            }
        }
    }
}

struct WishlistSortOption: Codable {
    let field: SortField
    let ascending: Bool

    enum SortField: String, Codable, CaseIterable {
        case name, distillery, priority, estimatedPrice, createdAt

        var displayName: String {
            switch self {
            case .name: return "名前"
            case .distillery: return "蒸留所"
            case .priority: return "優先度"
            case .estimatedPrice: return "推定価格"
            case .createdAt: return "追加日"
            }
        }
    }
}

struct SearchResult {
    let bottles: [Bottle]
    let totalCount: Int
    let statistics: SearchStatistics
    let criteria: SearchCriteria
}

struct WishlistSearchResult {
    let items: [WishlistItem]
    let totalCount: Int
    let criteria: WishlistSearchCriteria
}

struct SearchStatistics {
    let totalBottles: Int
    let openedBottles: Int
    let averageRating: Double
    let totalValue: Decimal
}

struct SavedSearch: Codable, Identifiable {
    let id: UUID
    let name: String
    let criteria: SearchCriteria
    let createdAt: Date
}

struct SearchSuggestion: Hashable, Identifiable {
    let id = UUID()
    let text: String
    let type: SuggestionType
    let category: String

    enum SuggestionType {
        case bottleName, distillery, region, type, recent
    }
}

struct QuickFilter {
    let name: String
    let criteria: SearchCriteria
    let icon: String
    let color: String
}