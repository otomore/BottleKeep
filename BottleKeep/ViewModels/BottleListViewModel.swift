import Foundation
import SwiftUI
import Combine

/// ボトル一覧画面のViewModel
@MainActor
class BottleListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var bottles: [Bottle] = []
    @Published var filteredBottles: [Bottle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = "" {
        didSet {
            filterBottles()
        }
    }
    @Published var filterOption: FilterOption = .all {
        didSet {
            filterBottles()
        }
    }
    @Published var sortOption: SortOption = .updatedDate {
        didSet {
            sortBottles()
        }
    }

    // MARK: - Dependencies

    private let repository: BottleRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(repository: BottleRepositoryProtocol) {
        self.repository = repository
        setupSearchDebouncing()
    }

    // MARK: - Public Methods

    /// ボトル一覧を読み込み
    func loadBottles() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedBottles = try await repository.fetchAllBottles()
            bottles = fetchedBottles
            filterBottles()
            isLoading = false
        } catch {
            errorMessage = "ボトルの読み込みに失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// ボトルを削除
    func deleteBottle(_ bottle: Bottle) async {
        do {
            try await repository.deleteBottle(bottle)
            await loadBottles() // リロード
        } catch {
            errorMessage = "ボトルの削除に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 複数のボトルを削除
    func deleteBottles(at offsets: IndexSet) async {
        for index in offsets {
            let bottle = filteredBottles[index]
            await deleteBottle(bottle)
        }
    }

    /// データを更新
    func refreshData() async {
        await loadBottles()
    }

    // MARK: - Private Methods

    /// 検索のデバウンス処理を設定
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { _ in
                self.filterBottles()
            }
            .store(in: &cancellables)
    }

    /// ボトルをフィルタ
    private func filterBottles() {
        var filtered = bottles

        // 検索テキストでフィルタ
        if !searchText.isEmpty {
            filtered = filtered.filter { bottle in
                bottle.name.localizedCaseInsensitiveContains(searchText) ||
                bottle.distillery.localizedCaseInsensitiveContains(searchText) ||
                bottle.region?.localizedCaseInsensitiveContains(searchText) == true ||
                bottle.type?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // フィルタオプションを適用
        switch filterOption {
        case .all:
            break
        case .opened:
            filtered = filtered.filter { $0.isOpened }
        case .unopened:
            filtered = filtered.filter { !$0.isOpened }
        case .rating(let minRating):
            filtered = filtered.filter { $0.rating >= minRating }
        case .region(let region):
            filtered = filtered.filter { $0.region == region }
        }

        filteredBottles = filtered
        sortBottles()
    }

    /// ボトルをソート
    private func sortBottles() {
        switch sortOption {
        case .name:
            filteredBottles.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .distillery:
            filteredBottles.sort { $0.distillery.localizedCompare($1.distillery) == .orderedAscending }
        case .purchaseDate:
            filteredBottles.sort { ($0.purchaseDate ?? .distantPast) > ($1.purchaseDate ?? .distantPast) }
        case .rating:
            filteredBottles.sort { $0.rating > $1.rating }
        case .updatedDate:
            filteredBottles.sort { $0.updatedAt > $1.updatedAt }
        case .price:
            filteredBottles.sort { ($0.purchasePrice?.doubleValue ?? 0) > ($1.purchasePrice?.doubleValue ?? 0) }
        }
    }
}

// MARK: - Supporting Types

extension BottleListViewModel {

    enum FilterOption: CaseIterable {
        case all
        case opened
        case unopened
        case rating(Int16)
        case region(String)

        var title: String {
            switch self {
            case .all:
                return "すべて"
            case .opened:
                return "開栓済み"
            case .unopened:
                return "未開栓"
            case .rating(let rating):
                return "\(rating)星以上"
            case .region(let region):
                return region
            }
        }

        static var allCases: [FilterOption] {
            return [.all, .opened, .unopened]
        }
    }

    enum SortOption: String, CaseIterable {
        case updatedDate = "更新日時"
        case name = "名前"
        case distillery = "蒸留所"
        case purchaseDate = "購入日"
        case rating = "評価"
        case price = "価格"

        var title: String {
            return rawValue
        }
    }
}

// MARK: - Statistics Extension

extension BottleListViewModel {

    /// フィルタされたボトルの統計
    var statistics: BottleStatistics {
        return BottleStatistics(
            totalCount: filteredBottles.count,
            openedCount: filteredBottles.filter { $0.isOpened }.count,
            averageRating: filteredBottles.compactMap { $0.rating > 0 ? Double($0.rating) : nil }.average,
            totalValue: filteredBottles.compactMap { $0.purchasePrice?.doubleValue }.reduce(0, +)
        )
    }
}

struct BottleStatistics {
    let totalCount: Int
    let openedCount: Int
    let averageRating: Double
    let totalValue: Double

    var unopenedCount: Int {
        return totalCount - openedCount
    }
}

// MARK: - Array Extension

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}