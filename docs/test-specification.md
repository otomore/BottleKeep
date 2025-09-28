# BottleKeeper テスト仕様書

## 1. テスト戦略概要

### 1.1 テストピラミッド
```
        /\
       /  \
      / UI \     E2E Tests (10%)
     /______\
    /        \
   / Integra- \   Integration Tests (20%)
  /   tion    \
 /____________\
/              \
|     Unit     |  Unit Tests (70%)
|    Tests     |
\______________/
```

### 1.2 テスト方針
- **Unit Tests**: ビジネスロジック、ViewModel、Repository層
- **Integration Tests**: Core Data操作、CloudKit同期
- **UI Tests**: 主要ユーザーフロー、クリティカルパス
- **Performance Tests**: 大量データ処理、メモリ使用量
- **Accessibility Tests**: VoiceOver、Dynamic Type対応

### 1.3 テスト環境
- **開発環境**: iOS Simulator、実機テスト
- **CI環境**: GitHub Actions、iOS Simulator
- **テストデータ**: Core Data In-Memory Store使用

### 1.4 品質目標
- **コードカバレッジ**: 80%以上（Unit Tests）
- **UI自動テスト**: 主要フロー100%カバー
- **実機テスト**: 最新3世代のiPhone/iPad
- **パフォーマンス**: 起動時間2秒以内、1000件データで動作保証

## 2. Unit Test仕様

### 2.1 ViewModel Tests

#### 2.1.1 BottleListViewModelTests
```swift
@MainActor
class BottleListViewModelTests: XCTestCase {
    var viewModel: BottleListViewModel!
    var mockRepository: MockBottleRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockBottleRepository()
        viewModel = BottleListViewModel(repository: mockRepository)
    }

    // MARK: - Loading Tests
    func testLoadBottlesSuccess() async {
        // Given
        let expectedBottles = [
            Bottle.testBottle(name: "Macallan 18"),
            Bottle.testBottle(name: "Hibiki 17")
        ]
        mockRepository.fetchAllBottlesResult = .success(expectedBottles)

        // When
        await viewModel.loadBottles()

        // Then
        XCTAssertEqual(viewModel.bottles.count, 2)
        XCTAssertEqual(viewModel.bottles[0].name, "Macallan 18")
        XCTAssertEqual(viewModel.bottles[1].name, "Hibiki 17")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadBottlesFailure() async {
        // Given
        mockRepository.fetchAllBottlesResult = .failure(BottleError.coreDataError(NSError()))

        // When
        await viewModel.loadBottles()

        // Then
        XCTAssertTrue(viewModel.bottles.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Search Tests
    func testSearchBottles() async {
        // Given
        let allBottles = [
            Bottle.testBottle(name: "Macallan 18", distillery: "Macallan"),
            Bottle.testBottle(name: "Hibiki 17", distillery: "Suntory"),
            Bottle.testBottle(name: "Ardbeg 10", distillery: "Ardbeg")
        ]
        mockRepository.fetchAllBottlesResult = .success(allBottles)
        await viewModel.loadBottles()

        // When
        viewModel.searchText = "Macallan"

        // Then
        XCTAssertEqual(viewModel.filteredBottles.count, 1)
        XCTAssertEqual(viewModel.filteredBottles[0].name, "Macallan 18")
    }

    // MARK: - Filter Tests
    func testFilterByRating() async {
        // Given
        let allBottles = [
            Bottle.testBottle(name: "High Rated", rating: 5),
            Bottle.testBottle(name: "Medium Rated", rating: 3),
            Bottle.testBottle(name: "Low Rated", rating: 1)
        ]
        mockRepository.fetchAllBottlesResult = .success(allBottles)
        await viewModel.loadBottles()

        // When
        viewModel.filterOption = .rating(4)

        // Then
        XCTAssertEqual(viewModel.filteredBottles.count, 1)
        XCTAssertEqual(viewModel.filteredBottles[0].name, "High Rated")
    }

    // MARK: - Delete Tests
    func testDeleteBottle() async {
        // Given
        let bottle = Bottle.testBottle(name: "To Delete")
        mockRepository.deleteBottleResult = .success(())

        // When
        await viewModel.deleteBottle(bottle)

        // Then
        XCTAssertTrue(mockRepository.deleteBottleCalled)
        XCTAssertNil(viewModel.errorMessage)
    }
}
```

#### 2.1.2 BottleFormViewModelTests
```swift
@MainActor
class BottleFormViewModelTests: XCTestCase {
    var viewModel: BottleFormViewModel!
    var mockRepository: MockBottleRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockBottleRepository()
        viewModel = BottleFormViewModel(repository: mockRepository)
    }

    // MARK: - Validation Tests
    func testFormValidation_ValidInput() {
        // Given
        viewModel.name = "Macallan 18"
        viewModel.distillery = "Macallan"
        viewModel.abv = 43.0
        viewModel.volume = 700

        // When & Then
        XCTAssertTrue(viewModel.isValidForm)
        XCTAssertTrue(viewModel.validationErrors.isEmpty)
    }

    func testFormValidation_EmptyName() {
        // Given
        viewModel.name = ""
        viewModel.distillery = "Macallan"

        // When & Then
        XCTAssertFalse(viewModel.isValidForm)
        XCTAssertTrue(viewModel.validationErrors.contains(.emptyName))
    }

    func testFormValidation_InvalidABV() {
        // Given
        viewModel.name = "Test"
        viewModel.distillery = "Test"
        viewModel.abv = 150.0  // Invalid ABV

        // When & Then
        XCTAssertFalse(viewModel.isValidForm)
        XCTAssertTrue(viewModel.validationErrors.contains(.invalidABV))
    }

    // MARK: - Save Tests
    func testSaveBottle_Success() async {
        // Given
        viewModel.name = "Macallan 18"
        viewModel.distillery = "Macallan"
        mockRepository.saveBottleResult = .success(())

        // When
        let result = await viewModel.saveBottle()

        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(mockRepository.saveBottleCalled)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSaveBottle_ValidationFailure() async {
        // Given
        viewModel.name = ""  // Invalid

        // When
        let result = await viewModel.saveBottle()

        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(mockRepository.saveBottleCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Photo Tests
    func testAddPhoto() {
        // Given
        let testImage = UIImage(systemName: "photo")!

        // When
        viewModel.addPhoto(testImage)

        // Then
        XCTAssertEqual(viewModel.photos.count, 1)
        XCTAssertEqual(viewModel.photos[0], testImage)
    }

    func testAddPhoto_ExceedsLimit() {
        // Given
        for i in 0..<5 {
            viewModel.addPhoto(UIImage(systemName: "photo")!)
        }

        // When
        viewModel.addPhoto(UIImage(systemName: "photo")!)

        // Then
        XCTAssertEqual(viewModel.photos.count, 5) // Should not exceed limit
    }
}
```

### 2.2 Repository Tests

#### 2.2.1 BottleRepositoryTests
```swift
class BottleRepositoryTests: XCTestCase {
    var repository: BottleRepository!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        testContext = CoreDataTestStack.shared.context
        repository = BottleRepository(context: testContext)
    }

    override func tearDown() {
        CoreDataTestStack.shared.cleanup()
        super.tearDown()
    }

    // MARK: - Fetch Tests
    func testFetchAllBottles() async throws {
        // Given
        let bottle1 = Bottle.create(in: testContext, name: "Test 1", distillery: "Distillery 1")
        let bottle2 = Bottle.create(in: testContext, name: "Test 2", distillery: "Distillery 2")
        try testContext.save()

        // When
        let bottles = try await repository.fetchAllBottles()

        // Then
        XCTAssertEqual(bottles.count, 2)
        XCTAssertTrue(bottles.contains(bottle1))
        XCTAssertTrue(bottles.contains(bottle2))
    }

    func testFetchBottleById() async throws {
        // Given
        let bottle = Bottle.create(in: testContext, name: "Test Bottle", distillery: "Test Distillery")
        try testContext.save()

        // When
        let fetchedBottle = try await repository.fetchBottle(by: bottle.id)

        // Then
        XCTAssertNotNil(fetchedBottle)
        XCTAssertEqual(fetchedBottle?.id, bottle.id)
        XCTAssertEqual(fetchedBottle?.name, "Test Bottle")
    }

    // MARK: - Save Tests
    func testSaveNewBottle() async throws {
        // Given
        let bottle = Bottle.create(in: testContext, name: "New Bottle", distillery: "New Distillery")

        // When
        try await repository.saveBottle(bottle)

        // Then
        let fetchedBottles = try await repository.fetchAllBottles()
        XCTAssertEqual(fetchedBottles.count, 1)
        XCTAssertEqual(fetchedBottles[0].name, "New Bottle")
    }

    func testUpdateExistingBottle() async throws {
        // Given
        let bottle = Bottle.create(in: testContext, name: "Original Name", distillery: "Test Distillery")
        try testContext.save()

        // When
        bottle.name = "Updated Name"
        try await repository.saveBottle(bottle)

        // Then
        let fetchedBottle = try await repository.fetchBottle(by: bottle.id)
        XCTAssertEqual(fetchedBottle?.name, "Updated Name")
    }

    // MARK: - Delete Tests
    func testDeleteBottle() async throws {
        // Given
        let bottle = Bottle.create(in: testContext, name: "To Delete", distillery: "Test Distillery")
        try testContext.save()

        // When
        try await repository.deleteBottle(bottle)

        // Then
        let bottles = try await repository.fetchAllBottles()
        XCTAssertTrue(bottles.isEmpty)
    }

    // MARK: - Search Tests
    func testSearchBottles() async throws {
        // Given
        let bottle1 = Bottle.create(in: testContext, name: "Macallan 18", distillery: "Macallan")
        let bottle2 = Bottle.create(in: testContext, name: "Hibiki 17", distillery: "Suntory")
        let bottle3 = Bottle.create(in: testContext, name: "Ardbeg 10", distillery: "Ardbeg")
        try testContext.save()

        // When
        let searchResults = try await repository.searchBottles(query: "Macallan")

        // Then
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults[0].name, "Macallan 18")
    }
}
```

### 2.3 Model Tests

#### 2.3.1 BottleValidationTests
```swift
class BottleValidationTests: XCTestCase {
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        testContext = CoreDataTestStack.shared.context
    }

    func testValidBottle() throws {
        // Given
        let bottle = Bottle.create(in: testContext, name: "Valid Bottle", distillery: "Valid Distillery")
        bottle.abv = 43.0
        bottle.volume = 700
        bottle.rating = 4

        // When & Then
        XCTAssertNoThrow(try bottle.validate())
    }

    func testInvalidBottle_EmptyName() {
        // Given
        let bottle = Bottle.create(in: testContext, name: "", distillery: "Test")

        // When & Then
        XCTAssertThrowsError(try bottle.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyName)
        }
    }

    func testInvalidBottle_InvalidABV() {
        // Given
        let bottle = Bottle.create(in: testContext, name: "Test", distillery: "Test")
        bottle.abv = 150.0  // Invalid

        // When & Then
        XCTAssertThrowsError(try bottle.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .invalidABV)
        }
    }

    func testInvalidBottle_RemainingVolumeExceedsTotal() {
        // Given
        let bottle = Bottle.create(in: testContext, name: "Test", distillery: "Test")
        bottle.volume = 700
        bottle.remainingVolume = 800  // Exceeds total

        // When & Then
        XCTAssertThrowsError(try bottle.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .remainingVolumeExceedsTotal)
        }
    }
}
```

## 3. Integration Test仕様

### 3.1 Core Data Integration Tests

#### 3.1.1 CoreDataManagerTests
```swift
class CoreDataManagerTests: XCTestCase {
    var coreDataManager: CoreDataManager!

    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager.shared
    }

    func testPersistentContainerCreation() {
        // When & Then
        XCTAssertNotNil(coreDataManager.persistentContainer)
        XCTAssertNotNil(coreDataManager.context)
    }

    func testSaveContext() {
        // Given
        let bottle = Bottle.create(in: coreDataManager.context, name: "Test", distillery: "Test")

        // When
        coreDataManager.save()

        // Then
        XCTAssertFalse(coreDataManager.context.hasChanges)
        XCTAssertNotNil(bottle.objectID)
    }

    func testConcurrentContexts() async {
        // Given
        let backgroundContext = coreDataManager.persistentContainer.newBackgroundContext()

        // When
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let bottle1 = Bottle.create(in: self.coreDataManager.context, name: "Main Context", distillery: "Test")
                self.coreDataManager.save()
            }

            group.addTask {
                await backgroundContext.perform {
                    let bottle2 = Bottle.create(in: backgroundContext, name: "Background Context", distillery: "Test")
                    try? backgroundContext.save()
                }
            }
        }

        // Then
        let bottles = try? coreDataManager.context.fetch(Bottle.fetchRequest())
        XCTAssertEqual(bottles?.count, 2)
    }
}
```

### 3.2 CloudKit Integration Tests

#### 3.2.1 CloudKitSyncTests
```swift
class CloudKitSyncTests: XCTestCase {
    var cloudKitManager: CloudKitManager!

    override func setUp() {
        super.setUp()
        cloudKitManager = CloudKitManager.shared
    }

    func testCloudKitAccountStatus() async {
        // When
        let status = await cloudKitManager.accountStatus()

        // Then
        XCTAssertNotEqual(status, .couldNotDetermine)
    }

    func testSyncBottleToCloudKit() async throws {
        // Given
        let bottle = Bottle.testBottle()

        // When
        try await cloudKitManager.syncBottle(bottle)

        // Then
        // Verify bottle exists in CloudKit
        let cloudBottle = try await cloudKitManager.fetchBottle(by: bottle.id)
        XCTAssertNotNil(cloudBottle)
        XCTAssertEqual(cloudBottle?.name, bottle.name)
    }

    func testConflictResolution() async throws {
        // Given
        let localBottle = Bottle.testBottle(name: "Local Version")
        let cloudBottle = Bottle.testBottle(name: "Cloud Version")
        cloudBottle.id = localBottle.id

        // When
        let resolvedBottle = try await cloudKitManager.resolveConflict(
            local: localBottle,
            cloud: cloudBottle
        )

        // Then
        // Assuming "last write wins" strategy
        XCTAssertEqual(resolvedBottle.name, cloudBottle.name)
    }
}
```

## 4. UI Test仕様

### 4.1 主要ユーザーフロー

#### 4.1.1 BottleManagementFlowTests
```swift
class BottleManagementFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testCompleteBottleManagementFlow() {
        // Navigate to Bottles tab
        app.tabBars.buttons["Bottles"].tap()

        // Add new bottle
        app.navigationBars.buttons["Add"].tap()

        // Fill bottle information
        fillBottleForm()

        // Save bottle
        app.navigationBars.buttons["Save"].tap()

        // Verify bottle appears in list
        XCTAssertTrue(app.staticTexts["Macallan 18"].exists)

        // Tap to view details
        app.staticTexts["Macallan 18"].tap()

        // Verify detail view
        XCTAssertTrue(app.staticTexts["Single Malt Scotch"].exists)
        XCTAssertTrue(app.staticTexts["43% ABV"].exists)

        // Edit bottle
        app.navigationBars.buttons["Edit"].tap()

        // Update rating
        app.buttons["Rating 5"].tap()

        // Save changes
        app.navigationBars.buttons["Save"].tap()

        // Verify updated rating
        XCTAssertTrue(app.images["5 stars"].exists)
    }

    private func fillBottleForm() {
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Macallan 18")

        app.textFields["Distillery"].tap()
        app.textFields["Distillery"].typeText("Macallan")

        app.textFields["Region"].tap()
        app.textFields["Region"].typeText("Speyside")

        app.textFields["Type"].tap()
        app.textFields["Type"].typeText("Single Malt Scotch")

        app.textFields["ABV"].tap()
        app.textFields["ABV"].typeText("43")

        app.textFields["Volume"].tap()
        app.textFields["Volume"].typeText("700")
    }

    func testSearchBottles() {
        // Navigate to Bottles tab
        app.tabBars.buttons["Bottles"].tap()

        // Add test bottles first
        addTestBottles()

        // Use search
        app.searchFields["Search bottles"].tap()
        app.searchFields["Search bottles"].typeText("Macallan")

        // Verify search results
        XCTAssertTrue(app.staticTexts["Macallan 18"].exists)
        XCTAssertFalse(app.staticTexts["Hibiki 17"].exists)

        // Clear search
        app.buttons["Clear text"].tap()

        // Verify all bottles shown again
        XCTAssertTrue(app.staticTexts["Macallan 18"].exists)
        XCTAssertTrue(app.staticTexts["Hibiki 17"].exists)
    }

    func testBottleDeletion() {
        // Navigate to Bottles tab
        app.tabBars.buttons["Bottles"].tap()

        // Add test bottle
        addTestBottle(name: "To Delete")

        // Swipe to delete
        app.staticTexts["To Delete"].swipeLeft()
        app.buttons["Delete"].tap()

        // Confirm deletion
        app.alerts["Delete Bottle"].buttons["Delete"].tap()

        // Verify bottle is removed
        XCTAssertFalse(app.staticTexts["To Delete"].exists)
    }

    private func addTestBottles() {
        addTestBottle(name: "Macallan 18", distillery: "Macallan")
        addTestBottle(name: "Hibiki 17", distillery: "Suntory")
    }

    private func addTestBottle(name: String, distillery: String = "Test Distillery") {
        app.navigationBars.buttons["Add"].tap()
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText(name)
        app.textFields["Distillery"].tap()
        app.textFields["Distillery"].typeText(distillery)
        app.navigationBars.buttons["Save"].tap()
    }
}
```

#### 4.1.2 StatisticsFlowTests
```swift
class StatisticsFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--with-test-data"]
        app.launch()
    }

    func testStatisticsView() {
        // Navigate to Statistics tab
        app.tabBars.buttons["Statistics"].tap()

        // Verify overview section
        XCTAssertTrue(app.staticTexts["Total Bottles"].exists)
        XCTAssertTrue(app.staticTexts["Total Value"].exists)
        XCTAssertTrue(app.staticTexts["Average Rating"].exists)

        // Verify charts exist
        XCTAssertTrue(app.otherElements["RegionChart"].exists)
        XCTAssertTrue(app.otherElements["PurchaseTrendChart"].exists)

        // Verify top rated section
        XCTAssertTrue(app.staticTexts["Top Rated"].exists)
    }

    func testStatisticsFilters() {
        // Navigate to Statistics tab
        app.tabBars.buttons["Statistics"].tap()

        // Apply region filter
        app.buttons["All Regions"].tap()
        app.buttons["Scotland"].tap()

        // Verify filtered data
        XCTAssertTrue(app.staticTexts["Scotland Only"].exists)

        // Apply time filter
        app.buttons["All Time"].tap()
        app.buttons["Last Year"].tap()

        // Verify filtered data
        XCTAssertTrue(app.staticTexts["Last Year Data"].exists)
    }
}
```

### 4.2 Accessibility Tests

#### 4.2.1 VoiceOverTests
```swift
class VoiceOverTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testVoiceOverNavigation() {
        // Enable VoiceOver simulation
        XCUIDevice.shared.system.accessibility.voiceOverEnabled = true

        // Navigate to Bottles tab
        app.tabBars.buttons["Bottles"].tap()

        // Test VoiceOver labels
        let bottleCard = app.buttons["Macallan 18 from Macallan"]
        XCTAssertTrue(bottleCard.exists)

        // Test accessibility value
        XCTAssertTrue(bottleCard.label.contains("Rating: 4 out of 5 stars"))

        // Test accessibility hint
        XCTAssertTrue(bottleCard.hint.contains("Double tap to view details"))
    }

    func testDynamicTypeSupport() {
        // Test with larger text sizes
        XCUIDevice.shared.system.accessibility.increaseTextSize()

        app.tabBars.buttons["Bottles"].tap()

        // Verify text is still readable and doesn't truncate
        let bottleName = app.staticTexts["Macallan 18"]
        XCTAssertTrue(bottleName.exists)
        XCTAssertFalse(bottleName.label.hasSuffix("..."))
    }
}
```

## 5. Performance Test仕様

### 5.1 Load Performance Tests

#### 5.1.1 LargeDatasetTests
```swift
class LargeDatasetTests: XCTestCase {
    var repository: BottleRepository!

    override func setUp() {
        super.setUp()
        repository = BottleRepository(context: CoreDataTestStack.shared.context)
    }

    func testLoadLargeBottleCollection() async throws {
        // Given - Create 1000 bottles
        for i in 0..<1000 {
            let bottle = Bottle.create(
                in: repository.context,
                name: "Bottle \(i)",
                distillery: "Distillery \(i % 100)"
            )
        }
        try repository.context.save()

        // When - Measure fetch time
        let startTime = CFAbsoluteTimeGetCurrent()
        let bottles = try await repository.fetchAllBottles()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Then
        XCTAssertEqual(bottles.count, 1000)
        XCTAssertLessThan(timeElapsed, 1.0) // Should load within 1 second
    }

    func testSearchPerformanceWithLargeDataset() async throws {
        // Given - Create large dataset
        createLargeTestDataset()

        // When - Measure search time
        let startTime = CFAbsoluteTimeGetCurrent()
        let results = try await repository.searchBottles(query: "Test Query")
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Then
        XCTAssertLessThan(timeElapsed, 0.5) // Search should be fast
    }

    private func createLargeTestDataset() {
        // Implementation to create test data
    }
}
```

### 5.2 Memory Performance Tests

#### 5.2.1 MemoryUsageTests
```swift
class MemoryUsageTests: XCTestCase {
    func testImageLoadingMemoryUsage() {
        // Measure memory usage while loading multiple images
        measure(metrics: [XCTMemoryMetric()]) {
            let photoManager = PhotoManager()
            for i in 0..<100 {
                let image = generateTestImage()
                _ = photoManager.processImage(image)
            }
        }
    }

    func testCoreDataMemoryUsage() {
        // Measure memory usage during Core Data operations
        measure(metrics: [XCTMemoryMetric()]) {
            let context = CoreDataTestStack.shared.context
            for i in 0..<1000 {
                let bottle = Bottle.create(in: context, name: "Test \(i)", distillery: "Test")
            }
            try? context.save()
        }
    }

    private func generateTestImage() -> UIImage {
        // Generate test image
        return UIImage(systemName: "photo")!
    }
}
```

## 6. Test Data Management

### 6.1 Test Fixtures

#### 6.1.1 BottleTestFactory
```swift
class BottleTestFactory {
    static func createTestBottle(
        name: String = "Test Bottle",
        distillery: String = "Test Distillery",
        region: String? = "Test Region",
        type: String? = "Single Malt",
        abv: Double? = 43.0,
        volume: Int32? = 700,
        vintage: Int32? = nil,
        rating: Int16? = 4,
        context: NSManagedObjectContext
    ) -> Bottle {
        let bottle = Bottle(context: context)
        bottle.id = UUID()
        bottle.name = name
        bottle.distillery = distillery
        bottle.region = region
        bottle.type = type
        bottle.abv = abv ?? 0
        bottle.volume = volume ?? 0
        bottle.vintage = vintage ?? 0
        bottle.rating = rating ?? 0
        bottle.createdAt = Date()
        bottle.updatedAt = Date()
        return bottle
    }

    static func createMacallan18(context: NSManagedObjectContext) -> Bottle {
        return createTestBottle(
            name: "Macallan 18",
            distillery: "Macallan",
            region: "Speyside",
            type: "Single Malt Scotch",
            abv: 43.0,
            volume: 700,
            rating: 5,
            context: context
        )
    }

    static func createHibiki17(context: NSManagedObjectContext) -> Bottle {
        return createTestBottle(
            name: "Hibiki 17",
            distillery: "Suntory",
            region: "Japan",
            type: "Japanese Blended",
            abv: 43.0,
            volume: 700,
            rating: 5,
            context: context
        )
    }
}
```

### 6.2 Core Data Test Stack

#### 6.2.1 CoreDataTestStack
```swift
class CoreDataTestStack {
    static let shared = CoreDataTestStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BottleKeeper")

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Test Core Data error: \(error)")
            }
        }

        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func cleanup() {
        let entities = persistentContainer.managedObjectModel.entities
        for entity in entities {
            guard let entityName = entity.name else { continue }
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            let objects = try? context.fetch(fetchRequest)
            objects?.forEach { context.delete($0) }
        }
        try? context.save()
    }
}
```

## 7. Test実行・CI/CD設定

### 7.1 GitHub Actions Test Configuration

#### 7.1.1 test.yml
```yaml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest

    strategy:
      matrix:
        destination:
          - 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
          - 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation),OS=17.0'

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Set up Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'

    - name: Install dependencies
      run: |
        brew install swiftlint

    - name: Run SwiftLint
      run: swiftlint

    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -scheme BottleKeeper \
          -destination '${{ matrix.destination }}' \
          -configuration Debug \
          -enableCodeCoverage YES \
          -resultBundlePath TestResults \
          CODE_SIGN_IDENTITY="" \
          CODE_SIGNING_REQUIRED=NO

    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results-${{ matrix.destination }}
        path: TestResults

    - name: Generate code coverage report
      run: |
        xcrun xccov view --report --json TestResults/*.xcresult > coverage.json

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage.json
```

### 7.2 Test Report Generation

#### 7.2.1 スクリプト例
```bash
#!/bin/bash
# generate_test_report.sh

# Run tests and generate report
xcodebuild test \
  -scheme BottleKeeper \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  -configuration Debug \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults

# Generate HTML coverage report
xcrun xccov view --report --json TestResults/*.xcresult > coverage.json
xcrun xccov view --report TestResults/*.xcresult > coverage.txt

echo "Test execution completed. Results available in TestResults/"
echo "Coverage summary:"
cat coverage.txt
```

---

## 8. Mock Objects実装

### 8.1 MockBottleRepository
```swift
class MockBottleRepository: BottleRepositoryProtocol {
    // Test control properties
    var fetchAllBottlesResult: Result<[Bottle], Error> = .success([])
    var fetchBottleResult: Result<Bottle?, Error> = .success(nil)
    var saveBottleResult: Result<Void, Error> = .success(())
    var deleteBottleResult: Result<Void, Error> = .success(())
    var searchBottlesResult: Result<[Bottle], Error> = .success([])

    // Call tracking
    var fetchAllBottlesCalled = false
    var fetchBottleCalled = false
    var saveBottleCalled = false
    var deleteBottleCalled = false
    var searchBottlesCalled = false

    func fetchAllBottles() async throws -> [Bottle] {
        fetchAllBottlesCalled = true
        return try fetchAllBottlesResult.get()
    }

    func fetchBottle(by id: UUID) async throws -> Bottle? {
        fetchBottleCalled = true
        return try fetchBottleResult.get()
    }

    func saveBottle(_ bottle: Bottle) async throws {
        saveBottleCalled = true
        try saveBottleResult.get()
    }

    func deleteBottle(_ bottle: Bottle) async throws {
        deleteBottleCalled = true
        try deleteBottleResult.get()
    }

    func searchBottles(query: String) async throws -> [Bottle] {
        searchBottlesCalled = true
        return try searchBottlesResult.get()
    }
}
```

### 8.2 MockPhotoRepository
```swift
class MockPhotoRepository: PhotoRepositoryProtocol {
    var savePhotoResult: Result<String, Error> = .success("test-photo.jpg")
    var loadPhotoResult: UIImage? = UIImage(systemName: "photo")
    var deletePhotoResult: Result<Void, Error> = .success(())

    var savePhotoCalled = false
    var loadPhotoCalled = false
    var deletePhotoCalled = false

    func savePhoto(_ image: UIImage, for bottleId: UUID) async throws -> String {
        savePhotoCalled = true
        return try savePhotoResult.get()
    }

    func loadPhoto(fileName: String) async -> UIImage? {
        loadPhotoCalled = true
        return loadPhotoResult
    }

    func deletePhoto(fileName: String) async throws {
        deletePhotoCalled = true
        try deletePhotoResult.get()
    }
}
```

## 9. テスト自動化・継続的テスト

### 9.1 並列テスト実行
```yaml
# parallel-test.yml
name: Parallel Test Execution

on:
  push:
    branches: [ main, develop ]

jobs:
  unit-tests:
    runs-on: macos-latest
    strategy:
      matrix:
        test-target:
          - ViewModelTests
          - RepositoryTests
          - ModelTests
          - UtilityTests
    steps:
    - name: Run ${{ matrix.test-target }}
      run: |
        xcodebuild test \
          -scheme BottleKeeper \
          -only-testing:BottleKeeperTests/${{ matrix.test-target }} \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

  integration-tests:
    runs-on: macos-latest
    needs: unit-tests
    steps:
    - name: Run Integration Tests
      run: |
        xcodebuild test \
          -scheme BottleKeeper \
          -only-testing:BottleKeeperIntegrationTests \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

  ui-tests:
    runs-on: macos-latest
    needs: integration-tests
    strategy:
      matrix:
        ui-test-suite:
          - BottleManagementFlowTests
          - StatisticsFlowTests
          - AccessibilityTests
    steps:
    - name: Run ${{ matrix.ui-test-suite }}
      run: |
        xcodebuild test \
          -scheme BottleKeeper \
          -only-testing:BottleKeeperUITests/${{ matrix.ui-test-suite }} \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
```

### 9.2 テスト結果分析・レポート
```swift
// TestAnalyzer.swift - テスト結果分析ツール
struct TestAnalyzer {
    static func analyzeTestResults() async {
        let testResults = await loadTestResults()
        let coverage = await calculateCoverage()
        let performance = await analyzePerformance()

        generateReport(
            testResults: testResults,
            coverage: coverage,
            performance: performance
        )
    }

    private static func generateReport(
        testResults: TestResults,
        coverage: CoverageReport,
        performance: PerformanceReport
    ) {
        let report = """
        ## テスト実行結果レポート

        ### 総合結果
        - 実行テスト数: \(testResults.totalTests)
        - 成功: \(testResults.passedTests)
        - 失敗: \(testResults.failedTests)
        - スキップ: \(testResults.skippedTests)

        ### カバレッジ
        - 総合カバレッジ: \(coverage.overallCoverage)%
        - ライン カバレッジ: \(coverage.lineCoverage)%
        - 関数カバレッジ: \(coverage.functionCoverage)%

        ### パフォーマンス
        - 平均実行時間: \(performance.averageExecutionTime)秒
        - 最遅テスト: \(performance.slowestTest.name) (\(performance.slowestTest.duration)秒)

        ### 推奨改善点
        \(generateRecommendations(testResults, coverage, performance))
        """

        writeReport(report)
    }
}
```

### 9.3 品質ゲート自動化
```bash
#!/bin/bash
# quality-gate.sh - 品質ゲートチェック

echo "🔍 品質ゲートチェック開始"

# 1. テストカバレッジチェック
COVERAGE=$(xcrun xccov view --report TestResults/*.xcresult | grep "Total coverage" | awk '{print $3}' | sed 's/%//')
MIN_COVERAGE=80

if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
    echo "❌ テストカバレッジ不足: ${COVERAGE}% (最低要求: ${MIN_COVERAGE}%)"
    exit 1
else
    echo "✅ テストカバレッジ: ${COVERAGE}%"
fi

# 2. テスト実行時間チェック
MAX_TEST_DURATION=300  # 5分
TEST_DURATION=$(grep "Test session results" TestResults/*.xcresult/Info.plist | grep -o '[0-9]*\.[0-9]*')

if (( $(echo "$TEST_DURATION > $MAX_TEST_DURATION" | bc -l) )); then
    echo "❌ テスト実行時間超過: ${TEST_DURATION}秒 (上限: ${MAX_TEST_DURATION}秒)"
    exit 1
else
    echo "✅ テスト実行時間: ${TEST_DURATION}秒"
fi

# 3. 失敗テストチェック
FAILED_TESTS=$(xcrun xcresulttool get --format json --path TestResults/*.xcresult | jq '.issues.testFailureSummaries | length')

if [ "$FAILED_TESTS" -gt 0 ]; then
    echo "❌ 失敗テストあり: ${FAILED_TESTS}件"
    exit 1
else
    echo "✅ 全テスト成功"
fi

echo "🎉 品質ゲートチェック完了 - リリース準備OK"
```

## 10. テストベストプラクティス

### 10.1 テスト命名規約
```swift
// ✅ Good - 3A形式での命名
func testSaveBottle_WithValidData_ShouldSucceed() async {
    // Arrange, Act, Assert
}

func testDeleteBottle_WhenBottleNotFound_ShouldThrowError() async {
    // Arrange, Act, Assert
}

// ✅ Good - Given-When-Then形式
func testSearchBottles_GivenMultipleBottles_WhenSearchingByName_ThenReturnsMatchingBottles() async {
    // Given, When, Then
}

// ❌ Bad - 曖昧な命名
func testSave() { }
func testDelete() { }
```

### 10.2 テストデータ管理
```swift
enum TestDataBuilder {
    static func bottleBuilder() -> BottleBuilder {
        return BottleBuilder()
    }
}

class BottleBuilder {
    private var bottle: BottleData = BottleData()

    func withName(_ name: String) -> BottleBuilder {
        bottle.name = name
        return self
    }

    func withDistillery(_ distillery: String) -> BottleBuilder {
        bottle.distillery = distillery
        return self
    }

    func withRating(_ rating: Int) -> BottleBuilder {
        bottle.rating = rating
        return self
    }

    func build(in context: NSManagedObjectContext) -> Bottle {
        return Bottle.create(from: bottle, in: context)
    }
}

// 使用例
let bottle = TestDataBuilder.bottleBuilder()
    .withName("Macallan 18")
    .withDistillery("Macallan")
    .withRating(5)
    .build(in: testContext)
```

---

**文書バージョン**: 1.1
**作成日**: 2025-09-21
**最終更新**: 2025-09-23
**作成者**: 個人プロジェクト