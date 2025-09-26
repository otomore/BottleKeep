import XCTest
import CoreData
@testable import BottleKeep

class WishlistRepositoryTests: XCTestCase {

    var repository: WishlistRepository!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        testContext = createInMemoryContext()
        repository = WishlistRepository(coreDataManager: createTestCoreDataManager())
    }

    override func tearDown() {
        repository = nil
        testContext = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    private func createInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "BottleKeep")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load in-memory store: \(error?.localizedDescription ?? "")")
        }

        return container.viewContext
    }

    private func createTestCoreDataManager() -> CoreDataManager {
        return CoreDataManager.shared
    }

    // MARK: - Tests

    func testCreateWishlistItem() async {
        // Given
        let name = "テストアイテム"
        let distillery = "テスト蒸留所"

        // When
        do {
            let item = try await repository.createWishlistItem(name: name, distillery: distillery)

            // Then
            XCTAssertEqual(item.name, name)
            XCTAssertEqual(item.distillery, distillery)
            XCTAssertNotNil(item.id)
            XCTAssertNotNil(item.createdAt)
            XCTAssertNotNil(item.updatedAt)
            XCTAssertEqual(item.priority, 1) // デフォルト優先度
        } catch {
            XCTFail("ウィッシュリストアイテム作成に失敗: \(error)")
        }
    }

    func testFetchAllWishlistItems() async {
        // Given
        do {
            _ = try await repository.createWishlistItem(name: "アイテム1", distillery: "蒸留所1")
            _ = try await repository.createWishlistItem(name: "アイテム2", distillery: "蒸留所2")

            // When
            let items = try await repository.fetchAllWishlistItems()

            // Then
            XCTAssertEqual(items.count, 2)
            XCTAssertTrue(items.contains { $0.name == "アイテム1" })
            XCTAssertTrue(items.contains { $0.name == "アイテム2" })
        } catch {
            XCTFail("ウィッシュリストアイテム取得に失敗: \(error)")
        }
    }

    func testSearchWishlistItems() async {
        // Given
        do {
            _ = try await repository.createWishlistItem(name: "山崎 12年", distillery: "サントリー")
            _ = try await repository.createWishlistItem(name: "白州 18年", distillery: "サントリー")
            _ = try await repository.createWishlistItem(name: "マッカラン 18年", distillery: "マッカラン")

            // When
            let searchResults = try await repository.searchWishlistItems(query: "サントリー")

            // Then
            XCTAssertEqual(searchResults.count, 2)
            XCTAssertTrue(searchResults.allSatisfy { $0.distillery == "サントリー" })
        } catch {
            XCTFail("ウィッシュリストアイテム検索に失敗: \(error)")
        }
    }

    func testDeleteWishlistItem() async {
        // Given
        do {
            let item = try await repository.createWishlistItem(name: "削除テスト", distillery: "テスト蒸留所")
            let itemId = item.id

            // When
            try await repository.deleteWishlistItem(item)

            // Then
            let deletedItem = try await repository.fetchWishlistItem(by: itemId)
            XCTAssertNil(deletedItem)
        } catch {
            XCTFail("ウィッシュリストアイテム削除に失敗: \(error)")
        }
    }

    func testFetchWishlistItemsByPriority() async {
        // Given
        do {
            let highItem = try await repository.createWishlistItem(name: "高優先度", distillery: "テスト")
            let mediumItem = try await repository.createWishlistItem(name: "中優先度", distillery: "テスト")
            let lowItem = try await repository.createWishlistItem(name: "低優先度", distillery: "テスト")

            // 優先度を設定
            highItem.priority = 3
            mediumItem.priority = 2
            lowItem.priority = 1

            try await repository.saveWishlistItem(highItem)
            try await repository.saveWishlistItem(mediumItem)
            try await repository.saveWishlistItem(lowItem)

            // When
            let highPriorityItems = try await repository.fetchWishlistItemsByPriority(3)
            let mediumPriorityItems = try await repository.fetchWishlistItemsByPriority(2)
            let lowPriorityItems = try await repository.fetchWishlistItemsByPriority(1)

            // Then
            XCTAssertEqual(highPriorityItems.count, 1)
            XCTAssertEqual(mediumPriorityItems.count, 1)
            XCTAssertEqual(lowPriorityItems.count, 1)
            XCTAssertEqual(highPriorityItems.first?.priority, 3)
            XCTAssertEqual(mediumPriorityItems.first?.priority, 2)
            XCTAssertEqual(lowPriorityItems.first?.priority, 1)
        } catch {
            XCTFail("優先度別アイテム取得に失敗: \(error)")
        }
    }

    func testWishlistItemValidation() {
        // Given
        let item = WishlistItem(context: testContext)

        // When & Then
        // 空の名前は無効
        item.name = ""
        item.distillery = "テスト蒸留所"
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyName)
        }

        // 空の蒸留所名は無効
        item.name = "テストアイテム"
        item.distillery = ""
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyDistillery)
        }

        // 無効な優先度は無効
        item.distillery = "テスト蒸留所"
        item.priority = 0
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .invalidPriority)
        }

        item.priority = 4
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .invalidPriority)
        }

        // 有効なデータは通る
        item.priority = 2
        item.vintage = 2020
        XCTAssertNoThrow(try item.validate())
    }

    func testWishlistItemDisplayProperties() {
        // Given
        let item = WishlistItem(context: testContext)
        item.name = "テストアイテム"
        item.distillery = "テスト蒸留所"
        item.region = "スコットランド"
        item.type = "シングルモルト"
        item.vintage = 2020
        item.priority = 2
        item.estimatedPrice = NSDecimalNumber(value: 15000)

        // When & Then
        XCTAssertEqual(item.priorityText, "中")
        XCTAssertEqual(item.priorityColor, "orange")
        XCTAssertTrue(item.estimatedPriceText.contains("15,000"))
        XCTAssertEqual(item.displaySummary, "スコットランド • シングルモルト • 2020年")
    }

    func testGetWishlistStatistics() async {
        // Given
        do {
            let item1 = try await repository.createWishlistItem(name: "アイテム1", distillery: "蒸留所1")
            let item2 = try await repository.createWishlistItem(name: "アイテム2", distillery: "蒸留所2")

            item1.estimatedPrice = NSDecimalNumber(value: 10000)
            item2.estimatedPrice = NSDecimalNumber(value: 20000)

            try await repository.saveWishlistItem(item1)
            try await repository.saveWishlistItem(item2)

            // When
            let count = try await repository.getWishlistItemCount()
            let totalValue = try await repository.getTotalEstimatedValue()

            // Then
            XCTAssertEqual(count, 2)
            XCTAssertEqual(totalValue, Decimal(30000))
        } catch {
            XCTFail("統計情報の取得に失敗: \(error)")
        }
    }
}