import SwiftUI

struct AdvancedSearchView: View {
    @StateObject private var searchManager = AdvancedSearchManager.shared
    @State private var searchCriteria = SearchCriteria()
    @State private var searchResults: SearchResult?
    @State private var showingSaveSearchSheet = false
    @State private var showingSavedSearches = false
    @State private var newSearchName = ""
    @State private var isLoading = false
    @State private var quickFilters: [QuickFilter] = []

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 検索バー
                searchBar

                // コンテンツ
                if let results = searchResults {
                    searchResultsView(results)
                } else {
                    searchFormView
                }
            }
            .navigationTitle("高度な検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu("メニュー") {
                        Button("保存済み検索", systemImage: "bookmark") {
                            showingSavedSearches = true
                        }

                        if searchResults != nil {
                            Button("検索を保存", systemImage: "plus") {
                                showingSaveSearchSheet = true
                            }
                        }

                        Button("検索をリセット", systemImage: "arrow.clockwise") {
                            resetSearch()
                        }
                    }
                }
            }
            .task {
                quickFilters = await searchManager.generateQuickFilters()
            }
            .sheet(isPresented: $showingSaveSearchSheet) {
                saveSearchSheet
            }
            .sheet(isPresented: $showingSavedSearches) {
                savedSearchesSheet
            }
        }
    }

    @ViewBuilder
    private var searchBar: some View {
        HStack {
            TextField("検索キーワード", text: $searchCriteria.searchText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    Task { await performSearch() }
                }

            Button("検索") {
                Task { await performSearch() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .padding(.horizontal)
        .padding(.top)
    }

    @ViewBuilder
    private var searchFormView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // クイックフィルタ
                quickFiltersSection

                // 詳細フィルタ
                detailedFiltersSection

                // ソート設定
                sortOptionsSection

                // 検索ボタン
                Button("検索を実行") {
                    Task { await performSearch() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isLoading)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("クイックフィルタ")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(quickFilters, id: \.name) { filter in
                    QuickFilterCard(filter: filter) {
                        searchCriteria = filter.criteria
                        Task { await performSearch() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var detailedFiltersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細フィルタ")
                .font(.headline)
                .fontWeight(.semibold)

            // 評価フィルタ
            ratingFilterSection

            // 価格フィルタ
            priceFilterSection

            // ABVフィルタ
            abvFilterSection

            // 開栓状態フィルタ
            openedStatusSection

            // 地域・タイプ・蒸留所フィルタ
            categoryFiltersSection

            // ヴィンテージフィルタ
            vintageFilterSection

            // 日付フィルタ
            dateFilterSection
        }
    }

    @ViewBuilder
    private var ratingFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("評価")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Text("最低")
                Picker("最低評価", selection: Binding(
                    get: { searchCriteria.minRating ?? 0 },
                    set: { searchCriteria.minRating = $0 == 0 ? nil : $0 }
                )) {
                    Text("指定なし").tag(0)
                    ForEach(1...5, id: \.self) { rating in
                        HStack {
                            ForEach(0..<rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                            }
                        }.tag(rating)
                    }
                }
                .pickerStyle(.menu)

                Text("〜")

                Text("最高")
                Picker("最高評価", selection: Binding(
                    get: { searchCriteria.maxRating ?? 5 },
                    set: { searchCriteria.maxRating = $0 == 5 ? nil : $0 }
                )) {
                    ForEach(1...5, id: \.self) { rating in
                        HStack {
                            ForEach(0..<rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                            }
                        }.tag(rating)
                    }
                    Text("指定なし").tag(5)
                }
                .pickerStyle(.menu)
            }
        }
    }

    @ViewBuilder
    private var priceFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("購入価格 (¥)")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                TextField("最低価格", value: $searchCriteria.minPrice, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)

                Text("〜")

                TextField("最高価格", value: $searchCriteria.maxPrice, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
        }
    }

    @ViewBuilder
    private var abvFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("アルコール度数 (%)")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                TextField("最低", value: $searchCriteria.minABV, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)

                Text("〜")

                TextField("最高", value: $searchCriteria.maxABV, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
            }
        }
    }

    @ViewBuilder
    private var openedStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("開栓状態")
                .font(.subheadline)
                .fontWeight(.medium)

            Picker("開栓状態", selection: $searchCriteria.openedStatus) {
                ForEach(SearchCriteria.OpenedStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var categoryFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 地域選択
            MultiSelectSection(
                title: "地域",
                selections: $searchCriteria.regions,
                options: ["スコットランド", "日本", "アイルランド", "アメリカ", "カナダ", "その他"]
            )

            // タイプ選択
            MultiSelectSection(
                title: "タイプ",
                selections: $searchCriteria.types,
                options: ["シングルモルト", "ブレンデッド", "バーボン", "ライウイスキー", "テネシーウイスキー"]
            )
        }
    }

    @ViewBuilder
    private var vintageFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ヴィンテージ")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                TextField("最古", value: Binding(
                    get: { searchCriteria.minVintage.map { Int($0) } },
                    set: { searchCriteria.minVintage = $0.map { Int32($0) } }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

                Text("〜")

                TextField("最新", value: Binding(
                    get: { searchCriteria.maxVintage.map { Int($0) } },
                    set: { searchCriteria.maxVintage = $0.map { Int32($0) } }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
            }
        }
    }

    @ViewBuilder
    private var dateFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("購入日")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                DatePicker("開始日", selection: Binding(
                    get: { searchCriteria.purchaseDateStart ?? Date() },
                    set: { searchCriteria.purchaseDateStart = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)

                DatePicker("終了日", selection: Binding(
                    get: { searchCriteria.purchaseDateEnd ?? Date() },
                    set: { searchCriteria.purchaseDateEnd = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
            }
        }
    }

    @ViewBuilder
    private var sortOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("並び順")
                .font(.headline)
                .fontWeight(.semibold)

            // ソートオプション（簡略化版）
            Picker("並び順", selection: Binding(
                get: {
                    searchCriteria.sortOptions.first?.field ?? .name
                },
                set: { field in
                    searchCriteria.sortOptions = [SearchSortOption(field: field, ascending: true)]
                }
            )) {
                ForEach(SearchSortOption.SortField.allCases, id: \.self) { field in
                    Text(field.displayName).tag(field)
                }
            }
            .pickerStyle(.menu)
        }
    }

    @ViewBuilder
    private func searchResultsView(_ results: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 結果統計
            searchResultsHeader(results)

            // 結果一覧
            List {
                ForEach(results.bottles) { bottle in
                    BottleRow(bottle: bottle)
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private func searchResultsHeader(_ results: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(results.totalCount)件の結果")
                    .font(.headline)

                Spacer()

                Button("新しい検索") {
                    searchResults = nil
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            // 統計サマリー
            HStack(spacing: 16) {
                StatisticLabel(title: "開栓済み", value: "\(results.statistics.openedBottles)件")
                StatisticLabel(title: "平均評価", value: String(format: "%.1f⭐", results.statistics.averageRating))
                StatisticLabel(title: "総価値", value: formatCurrency(results.statistics.totalValue))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var saveSearchSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("検索名", text: $newSearchName)
                } header: {
                    Text("検索を保存")
                } footer: {
                    Text("この検索条件を保存して後で使用できます。")
                }
            }
            .navigationTitle("検索を保存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        showingSaveSearchSheet = false
                        newSearchName = ""
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        searchManager.saveSearch(searchCriteria, name: newSearchName)
                        showingSaveSearchSheet = false
                        newSearchName = ""
                    }
                    .disabled(newSearchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var savedSearchesSheet: some View {
        NavigationStack {
            List {
                ForEach(searchManager.savedSearches) { savedSearch in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(savedSearch.name)
                            .font(.headline)
                        Text("作成日: \(savedSearch.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            searchCriteria = savedSearch.criteria
                            showingSavedSearches = false
                            await performSearch()
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        searchManager.deleteSavedSearch(searchManager.savedSearches[index])
                    }
                }
            }
            .navigationTitle("保存済み検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        showingSavedSearches = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func performSearch() async {
        isLoading = true
        do {
            let results = try await searchManager.performAdvancedSearch(searchCriteria)
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func resetSearch() {
        searchCriteria = SearchCriteria()
        searchResults = nil
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: NSNumber(value: amount.doubleValue)) ?? "¥0"
    }
}

// MARK: - Supporting Views

struct QuickFilterCard: View {
    let filter: QuickFilter
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: filter.icon)
                    .foregroundColor(Color(filter.color))
                    .frame(width: 24)

                Text(filter.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct MultiSelectSection: View {
    let title: String
    @Binding var selections: [String]
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Toggle(option, isOn: Binding(
                        get: { selections.contains(option) },
                        set: { isSelected in
                            if isSelected {
                                selections.append(option)
                            } else {
                                selections.removeAll { $0 == option }
                            }
                        }
                    ))
                    .toggleStyle(.button)
                    .controlSize(.small)
                }
            }
        }
    }
}

struct StatisticLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption2)
        }
    }
}

struct BottleRow: View {
    let bottle: Bottle

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.name)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(bottle.distillery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let region = bottle.region {
                    Text(region)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if bottle.rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<Int(bottle.rating), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }

                if let price = bottle.purchasePrice {
                    Text("¥\(price.intValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AdvancedSearchView()
}