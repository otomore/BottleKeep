# BottleKeeper ビジネスロジック詳細仕様書

## 1. 概要

### 1.1 目的
BottleKeeperアプリのビジネスロジックを詳細に定義し、正確で一貫したアプリ動作を実現する。計算式、閾値、条件分岐を明確にして、実装時の判断に迷いがないよう具体的な仕様を提供する。

### 1.2 適用範囲
- 残量計算アルゴリズム
- 統計・分析計算
- 状態判定ロジック
- 通知・アラート条件
- 課金・広告表示ルール

## 2. 残量管理ロジック

### 2.1 残量パーセンテージ計算
```swift
/// 残量パーセンテージの計算
/// - Parameters:
///   - remainingVolume: 現在の残量（ml）
///   - totalVolume: 総容量（ml）
/// - Returns: 残量パーセンテージ（0.0-100.0）
func calculateRemainingPercentage(remainingVolume: Int32, totalVolume: Int32) -> Double {
    guard totalVolume > 0 else { return 0.0 }

    let percentage = Double(remainingVolume) / Double(totalVolume) * 100.0

    // 100%を超える場合は100%にクランプ（入力ミス対応）
    return min(max(percentage, 0.0), 100.0)
}
```

### 2.2 残量状況の判定
```swift
enum RemainingStatus: String, CaseIterable {
    case empty = "飲み切り"
    case veryLow = "残りわずか"
    case low = "少なめ"
    case moderate = "半分程度"
    case sufficient = "十分"
    case full = "満タン"
}

/// 残量状況の判定
/// - Parameter percentage: 残量パーセンテージ
/// - Returns: 残量状況
func determineRemainingStatus(percentage: Double) -> RemainingStatus {
    switch percentage {
    case 0.0:
        return .empty
    case 0.01...5.0:
        return .veryLow
    case 5.01...25.0:
        return .low
    case 25.01...75.0:
        return .moderate
    case 75.01...99.99:
        return .sufficient
    case 100.0:
        return .full
    default:
        return .empty
    }
}
```

### 2.3 残量状況別の色分け
```swift
/// 残量状況に対応するカラー
/// - Parameter status: 残量状況
/// - Returns: SwiftUIカラー
func colorForRemainingStatus(_ status: RemainingStatus) -> Color {
    switch status {
    case .empty:
        return .gray
    case .veryLow:
        return .red
    case .low:
        return .orange
    case .moderate:
        return .yellow
    case .sufficient:
        return .green
    case .full:
        return .blue
    }
}
```

## 3. 消費ペース分析

### 3.1 日次消費量計算
```swift
/// 1日あたりの平均消費量を計算
/// - Parameters:
///   - consumedVolume: 消費済み容量（ml）
///   - daysSinceOpened: 開栓からの日数
/// - Returns: 1日あたりの消費量（ml/日）
func calculateDailyConsumption(consumedVolume: Int32, daysSinceOpened: Int) -> Double {
    guard daysSinceOpened > 0 else { return 0.0 }
    return Double(consumedVolume) / Double(daysSinceOpened)
}
```

### 3.2 消費予測計算
```swift
/// 残量がなくなる予測日を計算
/// - Parameters:
///   - remainingVolume: 残量（ml）
///   - dailyConsumption: 1日あたりの消費量（ml/日）
/// - Returns: 予測消費完了日（nil = 消費予測不可）
func predictDepletionDate(remainingVolume: Int32, dailyConsumption: Double) -> Date? {
    guard dailyConsumption > 0, remainingVolume > 0 else { return nil }

    let daysRemaining = Double(remainingVolume) / dailyConsumption

    // 10年以上の場合は予測不可として扱う
    guard daysRemaining <= 3650 else { return nil }

    return Calendar.current.date(byAdding: .day, value: Int(daysRemaining), to: Date())
}
```

### 3.3 消費ペース分類
```swift
enum ConsumptionPace: String, CaseIterable {
    case veryFast = "飲みすぎ注意"
    case fast = "早めのペース"
    case moderate = "適度なペース"
    case slow = "ゆっくりペース"
    case verySlow = "ほとんど飲まない"
    case unknown = "データ不足"
}

/// 消費ペースの分類
/// - Parameter dailyConsumption: 1日あたりの消費量（ml）
/// - Returns: 消費ペース分類
func classifyConsumptionPace(dailyConsumption: Double) -> ConsumptionPace {
    switch dailyConsumption {
    case 0.0:
        return .unknown
    case 0.01...2.0:
        return .verySlow
    case 2.01...5.0:
        return .slow
    case 5.01...15.0:
        return .moderate
    case 15.01...30.0:
        return .fast
    case 30.01...:
        return .veryFast
    default:
        return .unknown
    }
}
```

## 4. 評価・レーティングシステム

### 4.1 5段階評価システム
```swift
enum BottleRating: Int16, CaseIterable {
    case unrated = 0
    case poor = 1
    case fair = 2
    case good = 3
    case veryGood = 4
    case excellent = 5

    var displayText: String {
        switch self {
        case .unrated: return "未評価"
        case .poor: return "★☆☆☆☆"
        case .fair: return "★★☆☆☆"
        case .good: return "★★★☆☆"
        case .veryGood: return "★★★★☆"
        case .excellent: return "★★★★★"
        }
    }

    var description: String {
        switch self {
        case .unrated: return "まだ評価していません"
        case .poor: return "あまりおすすめしません"
        case .fair: return "普通です"
        case .good: return "良いです"
        case .veryGood: return "とても良いです"
        case .excellent: return "最高です！"
        }
    }
}
```

### 4.2 平均評価計算
```swift
/// コレクション全体の平均評価を計算
/// - Parameter bottles: ボトルの配列
/// - Returns: 平均評価（評価済みボトルのみ対象）
func calculateAverageRating(bottles: [Bottle]) -> Double? {
    let ratedBottles = bottles.filter { $0.rating > 0 }
    guard !ratedBottles.isEmpty else { return nil }

    let totalRating = ratedBottles.reduce(0) { $0 + Int($1.rating) }
    return Double(totalRating) / Double(ratedBottles.count)
}
```

## 5. 統計計算ロジック

### 5.1 コレクション価値計算
```swift
/// コレクション全体の価値を計算
/// - Parameter bottles: ボトルの配列
/// - Returns: 総購入価格、平均価格、最高価格
func calculateCollectionValue(bottles: [Bottle]) -> (total: Decimal, average: Decimal?, highest: Decimal?) {
    let bottlesWithPrice = bottles.compactMap { $0.purchasePrice }

    guard !bottlesWithPrice.isEmpty else {
        return (total: 0, average: nil, highest: nil)
    }

    let total = bottlesWithPrice.reduce(0, +)
    let average = total / Decimal(bottlesWithPrice.count)
    let highest = bottlesWithPrice.max()

    return (total: total, average: average, highest: highest)
}
```

### 5.2 地域別分布計算
```swift
/// 地域別のボトル分布を計算
/// - Parameter bottles: ボトルの配列
/// - Returns: 地域別のボトル数とパーセンテージ
func calculateRegionDistribution(bottles: [Bottle]) -> [(region: String, count: Int, percentage: Double)] {
    guard !bottles.isEmpty else { return [] }

    let regionCounts = bottles.reduce(into: [String: Int]()) { counts, bottle in
        let region = bottle.region?.isEmpty == false ? bottle.region! : "未分類"
        counts[region, default: 0] += 1
    }

    let totalCount = bottles.count

    return regionCounts.map { region, count in
        let percentage = Double(count) / Double(totalCount) * 100.0
        return (region: region, count: count, percentage: percentage)
    }.sorted { $0.count > $1.count }
}
```

### 5.3 月別購入トレンド
```swift
/// 月別の購入トレンドを計算
/// - Parameter bottles: ボトルの配列
/// - Returns: 月別の購入数と支出
func calculateMonthlyPurchaseTrend(bottles: [Bottle]) -> [(month: String, count: Int, amount: Decimal)] {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy年MM月"

    let groupedByMonth = Dictionary(grouping: bottles) { bottle in
        formatter.string(from: bottle.purchaseDate)
    }

    return groupedByMonth.map { month, bottles in
        let count = bottles.count
        let amount = bottles.compactMap { $0.purchasePrice }.reduce(0, +)
        return (month: month, count: count, amount: amount)
    }.sorted { $0.month < $1.month }
}
```

## 6. 通知・アラート条件

### 6.1 残量少なし通知
```swift
/// 残量少なし通知の条件判定
/// - Parameter bottles: ボトルの配列
/// - Returns: 通知対象のボトル
func getBottlesForLowStockNotification(bottles: [Bottle]) -> [Bottle] {
    return bottles.filter { bottle in
        // 開栓済みで残量5%以下のボトル
        bottle.isOpened && bottle.remainingPercentage <= 5.0
    }
}
```

### 6.2 長期未飲ボトル通知
```swift
/// 長期間飲んでいないボトルの通知条件
/// - Parameter bottles: ボトルの配列
/// - Returns: 通知対象のボトル
func getBottlesForLongUnusedNotification(bottles: [Bottle]) -> [Bottle] {
    let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!

    return bottles.filter { bottle in
        // 開栓済みで3ヶ月間飲酒記録がないボトル
        guard bottle.isOpened else { return false }

        // 最後の飲酒記録を取得（実装時はConsumptionRecordから）
        // 暫定的に開栓日を使用
        return bottle.openedDate ?? bottle.purchaseDate < threeMonthsAgo
    }
}
```

### 6.3 お気に入り在庫切れアラート
```swift
/// お気に入りボトルの在庫切れアラート条件
/// - Parameter bottles: ボトルの配列
/// - Returns: アラート対象のボトル
func getFavoriteBottlesOutOfStock(bottles: [Bottle]) -> [Bottle] {
    return bottles.filter { bottle in
        // 評価4以上で残量0%のボトル
        bottle.rating >= 4 && bottle.remainingPercentage == 0.0
    }
}
```

## 7. 課金・広告表示ロジック

### 7.1 無料プラン制限チェック
```swift
enum PlanType {
    case free
    case premium
}

struct FreePlanLimits {
    static let maxBottles = 20
    static let maxCustomCategories = 3
    static let maxPhotosPerBottle = 3
}

/// 無料プランの制限チェック
/// - Parameters:
///   - currentCount: 現在の数
///   - planType: プランタイプ
///   - limitType: 制限タイプ
/// - Returns: 制限に達しているかどうか
func isLimitReached(currentCount: Int, planType: PlanType, limitType: LimitType) -> Bool {
    guard planType == .free else { return false }

    switch limitType {
    case .bottles:
        return currentCount >= FreePlanLimits.maxBottles
    case .customCategories:
        return currentCount >= FreePlanLimits.maxCustomCategories
    case .photosPerBottle:
        return currentCount >= FreePlanLimits.maxPhotosPerBottle
    }
}

enum LimitType {
    case bottles
    case customCategories
    case photosPerBottle
}
```

### 7.2 広告表示タイミング
```swift
/// インタースティシャル広告表示の条件
/// - Parameter actionCount: 操作回数
/// - Returns: 広告を表示するかどうか
func shouldShowInterstitialAd(actionCount: Int) -> Bool {
    // 5回の操作ごとに広告表示
    return actionCount > 0 && actionCount % 5 == 0
}

/// バナー広告表示の条件
/// - Parameters:
///   - planType: プランタイプ
///   - screenType: 画面タイプ
/// - Returns: バナー広告を表示するかどうか
func shouldShowBannerAd(planType: PlanType, screenType: ScreenType) -> Bool {
    guard planType == .free else { return false }

    switch screenType {
    case .bottleList, .statistics:
        return true
    case .bottleDetail, .settings:
        return false
    }
}

enum ScreenType {
    case bottleList
    case bottleDetail
    case statistics
    case settings
}
```

### 7.3 アフィリエイトリンク表示条件
```swift
/// アフィリエイトリンク表示の条件
/// - Parameter bottle: ボトル
/// - Returns: アフィリエイトリンクを表示するかどうか
func shouldShowAffiliateLink(for bottle: Bottle) -> Bool {
    // 残量10%以下、または飲み切りボトル
    return bottle.remainingPercentage <= 10.0
}

/// 商品推奨の条件
/// - Parameters:
///   - bottle: 基準ボトル
///   - allBottles: 全ボトル
/// - Returns: 推奨商品を表示するかどうか
func shouldShowRecommendations(for bottle: Bottle, allBottles: [Bottle]) -> Bool {
    // 高評価（4以上）で残量少ない場合
    guard bottle.rating >= 4, bottle.remainingPercentage <= 20.0 else { return false }

    // 同じ地域の類似商品がある場合
    let similarBottles = allBottles.filter { otherBottle in
        otherBottle.region == bottle.region && otherBottle.id != bottle.id
    }

    return !similarBottles.isEmpty
}
```

## 8. データ整合性チェック

### 8.1 ボトルデータ検証
```swift
/// ボトルデータの整合性チェック
/// - Parameter bottle: ボトル
/// - Returns: バリデーション結果
func validateBottleData(_ bottle: Bottle) -> ValidationResult {
    var errors: [String] = []

    // 基本必須項目チェック
    if bottle.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        errors.append("銘柄名は必須です")
    }

    if bottle.distillery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        errors.append("蒸留所名は必須です")
    }

    // 数値範囲チェック
    if bottle.abv < 0 || bottle.abv > 100 {
        errors.append("アルコール度数は0-100%の範囲で入力してください")
    }

    if bottle.volume <= 0 {
        errors.append("容量は0より大きい値を入力してください")
    }

    if bottle.remainingVolume < 0 {
        errors.append("残量は0以上の値を入力してください")
    }

    if bottle.remainingVolume > bottle.volume {
        errors.append("残量が総容量を超えています")
    }

    // 評価範囲チェック
    if bottle.rating < 0 || bottle.rating > 5 {
        errors.append("評価は1-5の範囲で入力してください")
    }

    // 日付チェック
    if bottle.openedDate != nil && bottle.openedDate! < bottle.purchaseDate {
        errors.append("開栓日は購入日以降の日付を入力してください")
    }

    // 価格チェック
    if let price = bottle.purchasePrice, price < 0 {
        errors.append("購入価格は0以上の値を入力してください")
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors)
}

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}
```

### 8.2 重複チェック
```swift
/// 重複ボトルのチェック
/// - Parameters:
///   - newBottle: 新規ボトル
///   - existingBottles: 既存ボトル
/// - Returns: 重複の可能性があるボトル
func checkForDuplicateBottles(newBottle: Bottle, existingBottles: [Bottle]) -> [Bottle] {
    return existingBottles.filter { existing in
        // 名前と蒸留所が完全一致
        let nameMatch = existing.name.lowercased() == newBottle.name.lowercased()
        let distilleryMatch = existing.distillery.lowercased() == newBottle.distillery.lowercased()

        // 年代も一致（オプション項目なので両方nilまたは値が一致）
        let vintageMatch = existing.vintage == newBottle.vintage

        return nameMatch && distilleryMatch && vintageMatch
    }
}
```

## 9. 検索・フィルタロジック

### 9.1 検索アルゴリズム
```swift
/// ボトル検索のスコア計算
/// - Parameters:
///   - bottle: ボトル
///   - query: 検索クエリ
/// - Returns: 関連度スコア（0.0-1.0）
func calculateSearchScore(bottle: Bottle, query: String) -> Double {
    let queryLower = query.lowercased()
    var score: Double = 0.0

    // 名前での完全一致（最高スコア）
    if bottle.name.lowercased() == queryLower {
        score += 1.0
    }
    // 名前での前方一致
    else if bottle.name.lowercased().hasPrefix(queryLower) {
        score += 0.8
    }
    // 名前での部分一致
    else if bottle.name.lowercased().contains(queryLower) {
        score += 0.6
    }

    // 蒸留所での一致
    if bottle.distillery.lowercased().contains(queryLower) {
        score += 0.4
    }

    // 地域での一致
    if let region = bottle.region, region.lowercased().contains(queryLower) {
        score += 0.2
    }

    // ノートでの一致
    if let notes = bottle.notes, notes.lowercased().contains(queryLower) {
        score += 0.1
    }

    return min(score, 1.0)
}
```

### 9.2 フィルタ条件組み合わせ
```swift
/// 複合フィルタ条件の適用
/// - Parameters:
///   - bottles: ボトル配列
///   - filters: フィルタ条件
/// - Returns: フィルタ済みボトル配列
func applyFilters(bottles: [Bottle], filters: FilterCriteria) -> [Bottle] {
    return bottles.filter { bottle in
        // 地域フィルタ
        if let regions = filters.regions, !regions.isEmpty {
            guard let bottleRegion = bottle.region, regions.contains(bottleRegion) else {
                return false
            }
        }

        // 残量フィルタ
        if let remainingStatus = filters.remainingStatus {
            guard determineRemainingStatus(percentage: bottle.remainingPercentage) == remainingStatus else {
                return false
            }
        }

        // 評価フィルタ
        if let minRating = filters.minRating {
            guard bottle.rating >= minRating else {
                return false
            }
        }

        // 価格範囲フィルタ
        if let priceRange = filters.priceRange, let bottlePrice = bottle.purchasePrice {
            guard priceRange.contains(bottlePrice) else {
                return false
            }
        }

        // 開栓状況フィルタ
        if let isOpened = filters.isOpened {
            guard bottle.isOpened == isOpened else {
                return false
            }
        }

        return true
    }
}

struct FilterCriteria {
    let regions: [String]?
    let remainingStatus: RemainingStatus?
    let minRating: Int16?
    let priceRange: ClosedRange<Decimal>?
    let isOpened: Bool?
}
```

## 10. パフォーマンス最適化ロジック

### 10.1 大量データ処理
```swift
/// 大量データの統計計算（バックグラウンド処理）
/// - Parameter bottles: ボトル配列
/// - Returns: 統計結果
func calculateStatisticsAsync(bottles: [Bottle]) async -> StatisticsResult {
    return await withTaskGroup(of: Void.self) { group in
        var result = StatisticsResult()

        // 並列で各統計を計算
        group.addTask {
            result.collectionValue = calculateCollectionValue(bottles: bottles)
        }

        group.addTask {
            result.regionDistribution = calculateRegionDistribution(bottles: bottles)
        }

        group.addTask {
            result.averageRating = calculateAverageRating(bottles: bottles)
        }

        await group.waitForAll()
        return result
    }
}

struct StatisticsResult {
    var collectionValue: (total: Decimal, average: Decimal?, highest: Decimal?) = (0, nil, nil)
    var regionDistribution: [(region: String, count: Int, percentage: Double)] = []
    var averageRating: Double? = nil
}
```

### 10.2 キャッシュ戦略
```swift
/// 計算結果のキャッシュ管理
class CalculationCache {
    private var cache: [String: Any] = [:]
    private var lastModified: [String: Date] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5分

    func getCachedResult<T>(key: String, type: T.Type) -> T? {
        guard let lastMod = lastModified[key],
              Date().timeIntervalSince(lastMod) < cacheExpiry,
              let result = cache[key] as? T else {
            return nil
        }
        return result
    }

    func setCachedResult<T>(key: String, value: T) {
        cache[key] = value
        lastModified[key] = Date()
    }

    func invalidateCache() {
        cache.removeAll()
        lastModified.removeAll()
    }
}
```

---

## 付録: 単体テスト例

### A.1 残量計算テスト
```swift
func testRemainingPercentageCalculation() {
    // 正常ケース
    XCTAssertEqual(calculateRemainingPercentage(remainingVolume: 350, totalVolume: 700), 50.0, accuracy: 0.01)

    // エッジケース
    XCTAssertEqual(calculateRemainingPercentage(remainingVolume: 0, totalVolume: 700), 0.0)
    XCTAssertEqual(calculateRemainingPercentage(remainingVolume: 700, totalVolume: 700), 100.0)

    // 異常ケース
    XCTAssertEqual(calculateRemainingPercentage(remainingVolume: 100, totalVolume: 0), 0.0)
    XCTAssertEqual(calculateRemainingPercentage(remainingVolume: 800, totalVolume: 700), 100.0) // クランプ
}
```

### A.2 状況判定テスト
```swift
func testRemainingStatusDetermination() {
    XCTAssertEqual(determineRemainingStatus(percentage: 0.0), .empty)
    XCTAssertEqual(determineRemainingStatus(percentage: 3.0), .veryLow)
    XCTAssertEqual(determineRemainingStatus(percentage: 15.0), .low)
    XCTAssertEqual(determineRemainingStatus(percentage: 50.0), .moderate)
    XCTAssertEqual(determineRemainingStatus(percentage: 90.0), .sufficient)
    XCTAssertEqual(determineRemainingStatus(percentage: 100.0), .full)
}
```

---

**文書バージョン**: 1.0
**作成日**: 2025-09-23
**最終更新**: 2025-09-23
**作成者**: Claude Code

この仕様書により、BottleKeeperアプリのビジネスロジックを正確かつ一貫して実装できます。