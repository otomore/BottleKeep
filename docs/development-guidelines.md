# BottleKeep 開発ガイドライン・コーディング規約

## 1. 全般的な開発原則

### 1.1 基本方針
- **Simplicity**: シンプルで理解しやすいコード
- **Consistency**: 一貫したコーディングスタイル
- **Maintainability**: メンテナンスしやすい設計
- **Performance**: パフォーマンスを意識した実装
- **Accessibility**: アクセシビリティを考慮した開発

### 1.2 コード品質基準
- **Code Coverage**: 80%以上のテストカバレッジ目標
- **Warning Free**: 警告のないコード
- **SwiftLint**: 静的解析ツールの活用
- **Documentation**: 複雑な処理には適切なコメント

## 2. Swift コーディング規約

### 2.1 命名規約

#### 2.1.1 一般的な命名ルール
```swift
// ✅ Good
class BottleRepository { }
struct BottleDetailViewModel { }
enum NetworkError { }
protocol DataSourceProtocol { }

// ❌ Bad
class bottleRepo { }
struct BottleDetailVM { }
enum networkErr { }
protocol dataSource { }
```

#### 2.1.2 変数・プロパティ
```swift
// ✅ Good - camelCase
var bottleName: String
var purchaseDate: Date
var isMainPhoto: Bool
var remainingVolume: Int

// ❌ Bad
var bottle_name: String
var PurchaseDate: Date
var is_main_photo: Bool
```

#### 2.1.3 定数
```swift
// ✅ Good - camelCase for properties, UPPER_CASE for static constants
struct Constants {
    static let MAX_PHOTO_COUNT = 5
    static let DEFAULT_ABV = 40.0
    static let CACHE_DURATION = 3600
}

class BottleView {
    private let defaultRating = 3
    private let animationDuration = 0.3
}
```

#### 2.1.4 関数・メソッド
```swift
// ✅ Good - 動詞で始まる、明確な意図
func fetchBottles() async throws -> [Bottle]
func saveBottle(_ bottle: Bottle) async throws
func deleteBottle(by id: UUID) async throws
func calculateAverageRating() -> Double

// ❌ Bad
func bottles() -> [Bottle]  // 動詞がない
func save(_ bottle: Bottle)  // 何を保存するか不明確
func delete(id: UUID)  // 何を削除するか不明確
```

### 2.2 コード構造

#### 2.2.1 クラス・構造体の構成順序
```swift
class BottleDetailViewModel: ObservableObject {
    // MARK: - Properties
    @Published var bottle: Bottle
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: BottleRepositoryProtocol
    private let photoManager: PhotoManager

    // MARK: - Initialization
    init(bottle: Bottle, repository: BottleRepositoryProtocol) {
        self.bottle = bottle
        self.repository = repository
        self.photoManager = PhotoManager()
    }

    // MARK: - Public Methods
    func loadBottleDetails() async {
        // Implementation
    }

    func updateBottle() async throws {
        // Implementation
    }

    // MARK: - Private Methods
    private func validateBottle() -> Bool {
        // Implementation
    }

    private func processPhotos() {
        // Implementation
    }
}
```

#### 2.2.2 MARK コメントの使用
```swift
class BottleFormViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var distillery: String = ""

    // MARK: - Private Properties
    private let repository: BottleRepositoryProtocol

    // MARK: - Computed Properties
    var isValidForm: Bool {
        !name.isEmpty && !distillery.isEmpty
    }

    // MARK: - Lifecycle
    init(repository: BottleRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods
    func saveBottle() async throws {
        // Implementation
    }

    // MARK: - Validation
    private func validateInput() -> ValidationResult {
        // Implementation
    }

    // MARK: - Helper Methods
    private func resetForm() {
        // Implementation
    }
}
```

### 2.3 型とプロトコル設計

#### 2.3.1 Optional の使用
```swift
// ✅ Good - 明確なOptional使用
struct Bottle {
    let id: UUID
    let name: String
    let distillery: String
    let vintage: Int?  // Optional: 年代情報がない場合がある
    let rating: Int?   // Optional: 未評価の場合がある
}

// ✅ Good - Guard文での早期リターン
func updateBottle(_ bottle: Bottle) throws {
    guard !bottle.name.isEmpty else {
        throw ValidationError.emptyName
    }

    guard let rating = bottle.rating, (1...5).contains(rating) else {
        throw ValidationError.invalidRating
    }

    // Process bottle
}

// ❌ Bad - Force unwrapping
func badExample(_ bottle: Bottle) {
    let rating = bottle.rating!  // Dangerous!
    // Process...
}
```

#### 2.3.2 Error Handling
```swift
// ✅ Good - カスタムエラー定義
enum BottleError: LocalizedError {
    case invalidBottleName
    case invalidABV(Double)
    case invalidVolume(Int)
    case photoProcessingFailed
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidBottleName:
            return "ボトル名が無効です"
        case .invalidABV(let abv):
            return "アルコール度数が無効です: \(abv)%"
        case .invalidVolume(let volume):
            return "容量が無効です: \(volume)ml"
        case .photoProcessingFailed:
            return "写真の処理に失敗しました"
        case .networkUnavailable:
            return "ネットワークに接続できません"
        }
    }
}

// ✅ Good - Result型の使用
func fetchBottleFromNetwork(id: UUID) async -> Result<Bottle, BottleError> {
    do {
        let bottle = try await networkService.fetchBottle(id: id)
        return .success(bottle)
    } catch {
        return .failure(.networkUnavailable)
    }
}
```

#### 2.3.3 プロトコル設計
```swift
// ✅ Good - 単一責任のプロトコル
protocol BottleRepositoryProtocol {
    func fetchAllBottles() async throws -> [Bottle]
    func fetchBottle(by id: UUID) async throws -> Bottle?
    func saveBottle(_ bottle: Bottle) async throws
    func deleteBottle(_ bottle: Bottle) async throws
}

protocol PhotoManagerProtocol {
    func savePhoto(_ image: UIImage, for bottleId: UUID) async throws -> String
    func loadPhoto(fileName: String) async -> UIImage?
    func deletePhoto(fileName: String) async throws
}

// ✅ Good - プロトコル拡張でデフォルト実装
extension BottleRepositoryProtocol {
    func searchBottles(query: String) async throws -> [Bottle] {
        let allBottles = try await fetchAllBottles()
        return allBottles.filter { bottle in
            bottle.name.localizedCaseInsensitiveContains(query) ||
            bottle.distillery.localizedCaseInsensitiveContains(query)
        }
    }
}
```

#### 2.3.4 非同期プログラミングのベストプラクティス
```swift
// ✅ Good - @MainActor で UI更新の安全性確保
@MainActor
class BottleListViewModel: ObservableObject {
    @Published var bottles: [Bottle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: BottleRepositoryProtocol

    init(repository: BottleRepositoryProtocol) {
        self.repository = repository
    }

    func loadBottles() async {
        isLoading = true
        errorMessage = nil

        do {
            bottles = try await repository.fetchAllBottles()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// ✅ Good - TaskGroupで並列処理
func loadBottleWithPhotos(bottleId: UUID) async throws -> BottleWithPhotos {
    return try await withThrowingTaskGroup(of: Void.self) { group in
        var bottle: Bottle?
        var photos: [Photo] = []

        group.addTask {
            bottle = try await self.bottleRepository.fetchBottle(by: bottleId)
        }

        group.addTask {
            photos = try await self.photoRepository.fetchPhotos(for: bottleId)
        }

        try await group.waitForAll()

        guard let bottle = bottle else {
            throw BottleError.notFound
        }

        return BottleWithPhotos(bottle: bottle, photos: photos)
    }
}
```

## 3. SwiftUI ベストプラクティス

### 3.1 View構成

#### 3.1.1 View分割の原則
```swift
// ✅ Good - 小さく、再利用可能なView
struct BottleCard: View {
    let bottle: Bottle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BottlePhotoView(photoFileName: bottle.mainPhotoFileName)
            BottleInfoView(bottle: bottle)
            BottleRatingView(rating: bottle.rating)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct BottlePhotoView: View {
    let photoFileName: String?

    var body: some View {
        AsyncImage(url: photoURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.gray)
                )
        }
        .frame(height: 120)
        .clipped()
        .cornerRadius(8)
    }

    private var photoURL: URL? {
        // Photo URL generation logic
    }
}

// ❌ Bad - 大きすぎるView
struct MassiveBottleCard: View {
    let bottle: Bottle

    var body: some View {
        VStack {
            // 100+ lines of View code...
        }
    }
}
```

#### 3.1.2 State管理
```swift
// ✅ Good - 適切なState管理
struct BottleDetailView: View {
    @StateObject private var viewModel: BottleDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PhotoCarouselView(photos: viewModel.bottle.photos)
                BottleInfoSection(bottle: viewModel.bottle)
                PurchaseInfoSection(bottle: viewModel.bottle)
                TastingNotesSection(bottle: viewModel.bottle)
            }
        }
        .navigationTitle(viewModel.bottle.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BottleFormView(bottle: viewModel.bottle)
        }
        .alert("Delete Bottle", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteBottle()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// ❌ Bad - State乱用
struct BadBottleDetailView: View {
    @State private var bottle: Bottle
    @State private var name: String
    @State private var distillery: String
    @State private var rating: Int
    @State private var notes: String
    // ... too many individual states
}
```

### 3.2 パフォーマンス最適化

#### 3.2.1 LazyLoading とパフォーマンス最適化
```swift
// ✅ Good - LazyVStack使用
struct BottleListView: View {
    @StateObject private var viewModel = BottleListViewModel()

    var body: some View {
        NavigationView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.bottles) { bottle in
                    BottleCard(bottle: bottle)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(bottle)
                        }
                }
            }
            .padding()
        }
    }
}

// ✅ Good - メモリ効率的な画像読み込み
struct EfficientPhotoView: View {
    let photoFileName: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                PhotoPlaceholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            // メモリ解放
            image = nil
        }
    }

    private func loadImage() {
        Task {
            image = await PhotoManager.shared.loadThumbnail(fileName: photoFileName)
        }
    }
}

// ✅ Good - onReceive でメモリリーク防止
struct BottleObservingView: View {
    @StateObject private var viewModel = BottleViewModel()

    var body: some View {
        VStack {
            // Content
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            viewModel.cleanupResources()
        }
    }
}
```

### 3.3 アクセシビリティ

#### 3.3.1 VoiceOver対応
```swift
// ✅ Good - 適切なアクセシビリティ設定
struct AccessibleBottleCard: View {
    let bottle: Bottle

    var body: some View {
        VStack {
            // View content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Double tap to view bottle details")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        "\(bottle.name) from \(bottle.distillery)"
    }

    private var accessibilityValue: String {
        var value = ""
        if let rating = bottle.rating {
            value += "Rating: \(rating) out of 5 stars. "
        }
        if let price = bottle.purchasePrice {
            value += "Price: \(price) yen"
        }
        return value
    }
}

// ✅ Good - Dynamic Type対応
struct DynamicTypeView: View {
    var body: some View {
        VStack {
            Text("Bottle Name")
                .font(.headline)
                .dynamicTypeSize(.medium...(.accessibility3))

            Text("Description")
                .font(.body)
                .dynamicTypeSize(.medium...(.accessibility3))
        }
    }
}
```

## 4. Core Data ベストプラクティス

### 4.1 データアクセス

#### 4.1.1 Repository Pattern
```swift
// ✅ Good - Repository実装
class BottleRepository: BottleRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }

    func fetchAllBottles() async throws -> [Bottle] {
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Bottle.updatedAt, ascending: false)
        ]
        request.fetchBatchSize = 20

        return try await context.perform {
            try self.context.fetch(request)
        }
    }

    func saveBottle(_ bottle: Bottle) async throws {
        try await context.perform {
            bottle.updatedAt = Date()
            try self.context.save()
        }
    }
}

// ❌ Bad - 直接Core Dataアクセス
class BadViewModel: ObservableObject {
    func saveBottle() {
        let context = CoreDataManager.shared.context
        // Direct Core Data access in ViewModel
        try? context.save()
    }
}
```

#### 4.1.2 エラーハンドリング
```swift
// ✅ Good - 適切なエラーハンドリング
class SafeBottleRepository: BottleRepositoryProtocol {
    func fetchBottles() async throws -> [Bottle] {
        do {
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            return try await context.perform {
                try self.context.fetch(request)
            }
        } catch {
            throw BottleError.coreDataError(error)
        }
    }

    func saveBottle(_ bottle: Bottle) async throws {
        do {
            try await context.perform {
                try self.context.save()
            }
        } catch {
            // Rollback on error
            context.rollback()
            throw BottleError.coreDataError(error)
        }
    }
}
```

## 5. テスト戦略

### 5.1 Unit Test

#### 5.1.1 ViewModel テスト
```swift
// ✅ Good - ViewModelのテスト
@MainActor
class BottleDetailViewModelTests: XCTestCase {
    var viewModel: BottleDetailViewModel!
    var mockRepository: MockBottleRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockBottleRepository()
        let testBottle = Bottle.testBottle()
        viewModel = BottleDetailViewModel(
            bottle: testBottle,
            repository: mockRepository
        )
    }

    func testUpdateBottleSuccess() async throws {
        // Given
        mockRepository.saveBottleResult = .success(())

        // When
        await viewModel.updateBottle()

        // Then
        XCTAssertTrue(mockRepository.saveBottleCalled)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUpdateBottleFailure() async throws {
        // Given
        mockRepository.saveBottleResult = .failure(BottleError.invalidBottleName)

        // When
        await viewModel.updateBottle()

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
```

#### 5.1.2 Repository テスト
```swift
class BottleRepositoryTests: XCTestCase {
    var repository: BottleRepository!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        testContext = CoreDataTestStack.shared.context
        repository = BottleRepository(context: testContext)
    }

    func testFetchAllBottles() async throws {
        // Given
        let bottle1 = Bottle.create(in: testContext, name: "Test 1")
        let bottle2 = Bottle.create(in: testContext, name: "Test 2")
        try testContext.save()

        // When
        let bottles = try await repository.fetchAllBottles()

        // Then
        XCTAssertEqual(bottles.count, 2)
        XCTAssertTrue(bottles.contains(bottle1))
        XCTAssertTrue(bottles.contains(bottle2))
    }
}
```

### 5.2 UI Test

#### 5.2.1 基本的なUI テスト
```swift
class BottleKeepUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testAddNewBottle() {
        // Navigate to add bottle screen
        app.tabBars.buttons["Bottles"].tap()
        app.navigationBars.buttons["Add"].tap()

        // Fill form
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Macallan 18")

        app.textFields["Distillery"].tap()
        app.textFields["Distillery"].typeText("Macallan")

        // Save bottle
        app.navigationBars.buttons["Save"].tap()

        // Verify bottle was added
        XCTAssertTrue(app.staticTexts["Macallan 18"].exists)
    }
}
```

## 6. コードレビューガイドライン

### 6.1 レビュー観点

#### 6.1.1 必須チェック項目
- [ ] コーディング規約準拠
- [ ] 適切なエラーハンドリング
- [ ] パフォーマンス考慮
- [ ] アクセシビリティ対応
- [ ] テストカバレッジ
- [ ] セキュリティ考慮

#### 6.1.2 コード品質チェック
```swift
// ✅ Good - レビューしやすいコード
class WellDocumentedClass {
    /// ボトル情報を取得する
    /// - Parameter id: ボトルID
    /// - Returns: ボトル情報、見つからない場合はnil
    /// - Throws: データベースエラー
    func fetchBottle(by id: UUID) async throws -> Bottle? {
        // Implementation with clear logic
    }
}

// ❌ Bad - レビューしにくいコード
class PoorlyDocumentedClass {
    func fetch(id: UUID) -> Bottle? {
        // Complex logic without comments
        // Multiple responsibilities
        // No error handling
    }
}
```

## 7. パフォーマンス監視とメトリクス

### 7.1 パフォーマンス測定
```swift
// ✅ Good - パフォーマンス測定の実装
class PerformanceMetrics {
    private let signposter = OSSignposter(subsystem: "com.bottlekeep.app", category: "Performance")

    func measureDatabaseOperation<T>(_ operation: @escaping () async throws -> T) async rethrows -> T {
        let signpostID = signposter.makeSignpostID()
        let state = signposter.beginInterval("database_operation", id: signpostID)

        defer {
            signposter.endInterval("database_operation", state)
        }

        return try await operation()
    }

    func trackMemoryUsage() {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0 // MB
            Logger.shared.info("Memory usage: \(memoryUsage) MB")
        }
    }
}
```

### 7.2 クラッシュレポート設定
```swift
// ✅ Good - クラッシュハンドリング
class CrashHandler {
    static func setup() {
        NSSetUncaughtExceptionHandler { exception in
            Logger.shared.error("Uncaught exception: \(exception)")
            // クラッシュ情報を保存
            saveCrashReport(exception: exception)
        }
    }

    private static func saveCrashReport(exception: NSException) {
        let crashData = [
            "timestamp": Date().iso8601String,
            "exception": exception.description,
            "callStack": exception.callStackSymbols
        ]

        UserDefaults.standard.set(crashData, forKey: "last_crash_report")
    }
}
```

## 8. CI/CD と自動化

### 8.1 GitHub Actions設定例
```yaml
name: iOS CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'

    - name: Install SwiftLint
      run: brew install swiftlint

    - name: Run SwiftLint
      run: swiftlint

    - name: Run tests
      run: |
        xcodebuild test \
          -scheme BottleKeep \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
          -configuration Debug \
          CODE_SIGN_IDENTITY="" \
          CODE_SIGNING_REQUIRED=NO
```

### 8.2 SwiftLint設定
```yaml
# .swiftlint.yml
included:
  - Sources
  - Tests

excluded:
  - Pods
  - .build

disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - explicit_init
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional

line_length:
  warning: 120
  error: 200

function_body_length:
  warning: 50
  error: 100

type_body_length:
  warning: 300
  error: 500
```

---

## 9. コードメトリクス・品質管理

### 9.1 品質ゲート設定
```swift
// ✅ Good - 品質ゲートの設定例
struct QualityGate {
    static let minimumCodeCoverage: Double = 80.0
    static let maximumCyclomaticComplexity = 10
    static let maximumLinesOfCode = 300
    static let maximumParameterCount = 5

    static func validate(coverage: Double, complexity: Int, loc: Int, params: Int) -> Bool {
        return coverage >= minimumCodeCoverage &&
               complexity <= maximumCyclomaticComplexity &&
               loc <= maximumLinesOfCode &&
               params <= maximumParameterCount
    }
}
```

### 9.2 継続的インテグレーション品質チェック
```yaml
# 品質チェック用GitHub Actions
quality_check:
  runs-on: macos-latest
  steps:
    - name: Code Coverage Check
      run: |
        coverage=$(xcodebuild test -scheme BottleKeep | grep "Code coverage" | awk '{print $3}')
        if (( $(echo "$coverage < 80" | bc -l) )); then
          echo "Code coverage $coverage% is below threshold"
          exit 1
        fi

    - name: Complexity Analysis
      run: |
        # 複雑度チェック
        slather coverage --scheme BottleKeep
        lizard -l swift -w Sources/
```

---

**文書バージョン**: 1.1
**作成日**: 2025-09-21
**最終更新**: 2025-09-23
**作成者**: 個人プロジェクト