import XCTest
import CoreData
@testable import BottleKeep

class BottleRepositoryTests: XCTestCase {

    var repository: BottleRepository!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        testContext = createInMemoryContext()
        repository = BottleRepository(coreDataManager: createTestCoreDataManager())
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
        // テスト用のCoreDataManagerの作成
        // 実際の実装では、テスト用のCoreDataManagerを作成する
        return CoreDataManager.shared
    }

    // MARK: - Tests

    func testCreateBottle() async {
        // Given
        let name = "テストボトル"
        let distillery = "テスト蒸留所"

        // When
        do {
            let bottle = try await repository.createBottle(name: name, distillery: distillery)

            // Then
            XCTAssertEqual(bottle.name, name)
            XCTAssertEqual(bottle.distillery, distillery)
            XCTAssertNotNil(bottle.id)
            XCTAssertNotNil(bottle.createdAt)
            XCTAssertNotNil(bottle.updatedAt)
        } catch {
            XCTFail("ボトル作成に失敗: \(error)")
        }
    }

    func testFetchAllBottles() async {
        // Given
        do {
            _ = try await repository.createBottle(name: "ボトル1", distillery: "蒸留所1")
            _ = try await repository.createBottle(name: "ボトル2", distillery: "蒸留所2")

            // When
            let bottles = try await repository.fetchAllBottles()

            // Then
            XCTAssertEqual(bottles.count, 2)
            XCTAssertTrue(bottles.contains { $0.name == "ボトル1" })
            XCTAssertTrue(bottles.contains { $0.name == "ボトル2" })
        } catch {
            XCTFail("ボトル取得に失敗: \(error)")
        }
    }

    func testSearchBottles() async {
        // Given
        do {
            _ = try await repository.createBottle(name: "山崎 12年", distillery: "サントリー")
            _ = try await repository.createBottle(name: "白州 18年", distillery: "サントリー")
            _ = try await repository.createBottle(name: "マッカラン 18年", distillery: "マッカラン")

            // When
            let searchResults = try await repository.searchBottles(query: "サントリー")

            // Then
            XCTAssertEqual(searchResults.count, 2)
            XCTAssertTrue(searchResults.allSatisfy { $0.distillery == "サントリー" })
        } catch {
            XCTFail("ボトル検索に失敗: \(error)")
        }
    }

    func testDeleteBottle() async {
        // Given
        do {
            let bottle = try await repository.createBottle(name: "削除テスト", distillery: "テスト蒸留所")
            let bottleId = bottle.id

            // When
            try await repository.deleteBottle(bottle)

            // Then
            let deletedBottle = try await repository.fetchBottle(by: bottleId)
            XCTAssertNil(deletedBottle)
        } catch {
            XCTFail("ボトル削除に失敗: \(error)")
        }
    }

    func testBottleValidation() {
        // Given
        let bottle = Bottle(context: testContext)

        // When & Then
        // 空の名前は無効
        bottle.name = ""
        bottle.distillery = "テスト蒸留所"
        XCTAssertThrowsError(try bottle.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyName)
        }

        // 無効なABVは無効
        bottle.name = "テストボトル"
        bottle.abv = 150.0
        XCTAssertThrowsError(try bottle.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .invalidABV)
        }

        // 有効なデータは通る
        bottle.abv = 43.0
        bottle.volume = 700
        bottle.remainingVolume = 700
        XCTAssertNoThrow(try bottle.validate())
    }

    func testBottleRemainingPercentage() {
        // Given
        let bottle = Bottle(context: testContext)
        bottle.volume = 700
        bottle.remainingVolume = 350

        // When
        let percentage = bottle.remainingPercentage

        // Then
        XCTAssertEqual(percentage, 50.0, accuracy: 0.1)
    }
}