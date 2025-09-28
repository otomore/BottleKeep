import XCTest
import CoreData
@testable import BottleKeeper

class CoreDataIntegrationTests: XCTestCase {

    var coreDataManager: CoreDataManager!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager.shared
        testContext = coreDataManager.context
    }

    override func tearDown() {
        // テストデータをクリーンアップ
        cleanUpTestData()
        coreDataManager = nil
        testContext = nil
        super.tearDown()
    }

    // MARK: - Core Data Stack Tests

    func testCoreDataStackInitialization() {
        XCTAssertNotNil(coreDataManager.persistentContainer)
        XCTAssertNotNil(coreDataManager.context)
        XCTAssertEqual(coreDataManager.context.concurrencyType, .mainQueueConcurrencyType)
    }

    func testBackgroundContext() {
        let backgroundContext = coreDataManager.backgroundContext
        XCTAssertNotNil(backgroundContext)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(backgroundContext.parent, coreDataManager.context)
    }

    // MARK: - Entity Relationship Tests

    func testBottlePhotoRelationship() {
        // Given
        let bottle = Bottle(context: testContext, name: "テストボトル", distillery: "テスト蒸留所")
        let photo = BottlePhoto(context: testContext)
        photo.id = UUID()
        photo.fileName = "test.jpg"
        photo.isMain = true
        photo.createdAt = Date()

        // When
        bottle.addToPhotos(photo)

        // Then
        XCTAssertEqual(bottle.photos?.count, 1)
        XCTAssertEqual(photo.bottle, bottle)
        XCTAssertTrue(photo.isMain)

        do {
            try testContext.save()
            XCTAssertFalse(bottle.objectID.isTemporaryID)
            XCTAssertFalse(photo.objectID.isTemporaryID)
        } catch {
            XCTFail("保存に失敗: \(error)")
        }
    }

    func testCascadeDelete() {
        // Given
        let bottle = Bottle(context: testContext, name: "削除テスト", distillery: "テスト蒸留所")
        let photo1 = BottlePhoto(context: testContext)
        photo1.id = UUID()
        photo1.fileName = "test1.jpg"
        photo1.createdAt = Date()

        let photo2 = BottlePhoto(context: testContext)
        photo2.id = UUID()
        photo2.fileName = "test2.jpg"
        photo2.createdAt = Date()

        bottle.addToPhotos(photo1)
        bottle.addToPhotos(photo2)

        do {
            try testContext.save()
        } catch {
            XCTFail("保存に失敗: \(error)")
        }

        // When - ボトルを削除
        testContext.delete(bottle)

        do {
            try testContext.save()
        } catch {
            XCTFail("削除保存に失敗: \(error)")
        }

        // Then - 写真も cascade delete される
        let photoRequest: NSFetchRequest<BottlePhoto> = BottlePhoto.fetchRequest()
        do {
            let remainingPhotos = try testContext.fetch(photoRequest)
            XCTAssertTrue(remainingPhotos.isEmpty, "写真が cascade delete されていません")
        } catch {
            XCTFail("写真の確認に失敗: \(error)")
        }
    }

    // MARK: - CloudKit Integration Tests

    func testCloudKitContainerConfiguration() {
        let container = coreDataManager.persistentContainer
        XCTAssertTrue(container is NSPersistentCloudKitContainer)

        // CloudKit コンテナの設定を確認
        let description = container.persistentStoreDescriptions.first
        XCTAssertNotNil(description?.cloudKitContainerOptions)
    }

    // MARK: - Data Validation Tests

    func testBottleValidation() {
        // Given
        let bottle = Bottle(context: testContext)

        // When & Then - 必須フィールドのバリデーション
        XCTAssertThrowsError(try bottle.validate()) { error in
            XCTAssertTrue(error is ValidationError)
        }

        // 有効なデータを設定
        bottle.name = "有効なボトル"
        bottle.distillery = "有効な蒸留所"
        bottle.createdAt = Date()
        bottle.updatedAt = Date()
        bottle.id = UUID()

        XCTAssertNoThrow(try bottle.validate())
    }

    func testWishlistItemValidation() {
        // Given
        let item = WishlistItem(context: testContext)

        // When & Then - 必須フィールドのバリデーション
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertTrue(error is ValidationError)
        }

        // 有効なデータを設定
        item.name = "有効なアイテム"
        item.distillery = "有効な蒸留所"
        item.priority = 2
        item.createdAt = Date()
        item.updatedAt = Date()
        item.id = UUID()

        XCTAssertNoThrow(try item.validate())
    }

    // MARK: - Performance Tests

    func testBatchInsertPerformance() {
        measure {
            let bottles = (1...100).map { index in
                let bottle = Bottle(context: testContext, name: "パフォーマンステスト\(index)", distillery: "蒸留所\(index)")
                bottle.rating = Int16.random(in: 1...5)
                bottle.purchasePrice = NSDecimalNumber(value: Double.random(in: 5000...50000))
                return bottle
            }

            do {
                try testContext.save()
            } catch {
                XCTFail("バッチ挿入に失敗: \(error)")
            }

            // クリーンアップ
            bottles.forEach { testContext.delete($0) }
            try? testContext.save()
        }
    }

    func testBatchFetchPerformance() {
        // Given - テストデータを準備
        let bottles = (1...100).map { index in
            Bottle(context: testContext, name: "フェッチテスト\(index)", distillery: "蒸留所\(index)")
        }

        do {
            try testContext.save()
        } catch {
            XCTFail("テストデータの保存に失敗: \(error)")
        }

        // When & Then - フェッチ性能をテスト
        measure {
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Bottle.name, ascending: true)]

            do {
                let fetchedBottles = try testContext.fetch(request)
                XCTAssertEqual(fetchedBottles.count, 100)
            } catch {
                XCTFail("フェッチに失敗: \(error)")
            }
        }

        // クリーンアップ
        bottles.forEach { testContext.delete($0) }
        try? testContext.save()
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSave() {
        let expectation = expectation(description: "並行保存完了")
        expectation.expectedFulfillmentCount = 2

        // 背景コンテキストでの保存
        DispatchQueue.global().async {
            let backgroundContext = self.coreDataManager.backgroundContext
            backgroundContext.perform {
                let bottle = Bottle(context: backgroundContext, name: "背景ボトル", distillery: "背景蒸留所")
                do {
                    try backgroundContext.save()
                    expectation.fulfill()
                } catch {
                    XCTFail("背景コンテキストの保存に失敗: \(error)")
                }
            }
        }

        // メインコンテキストでの保存
        DispatchQueue.main.async {
            let bottle = Bottle(context: self.testContext, name: "メインボトル", distillery: "メイン蒸留所")
            do {
                try self.testContext.save()
                expectation.fulfill()
            } catch {
                XCTFail("メインコンテキストの保存に失敗: \(error)")
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Helper Methods

    private func cleanUpTestData() {
        let bottleRequest: NSFetchRequest<NSFetchRequestResult> = Bottle.fetchRequest()
        let bottleDeleteRequest = NSBatchDeleteRequest(fetchRequest: bottleRequest)

        let wishlistRequest: NSFetchRequest<NSFetchRequestResult> = WishlistItem.fetchRequest()
        let wishlistDeleteRequest = NSBatchDeleteRequest(fetchRequest: wishlistRequest)

        do {
            try testContext.execute(bottleDeleteRequest)
            try testContext.execute(wishlistDeleteRequest)
            try testContext.save()
        } catch {
            print("テストデータのクリーンアップに失敗: \(error)")
        }
    }
}