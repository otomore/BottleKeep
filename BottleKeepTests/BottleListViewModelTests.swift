import XCTest
import CoreData
@testable import BottleKeep

@MainActor
class BottleListViewModelTests: XCTestCase {

    var viewModel: BottleListViewModel!
    var mockRepository: MockBottleRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockBottleRepository()
        viewModel = BottleListViewModel(repository: mockRepository)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Tests

    func testLoadBottles() async {
        // Given
        mockRepository.bottles = [
            createTestBottle(name: "ボトル1", distillery: "蒸留所1"),
            createTestBottle(name: "ボトル2", distillery: "蒸留所2")
        ]

        // When
        await viewModel.loadBottles()

        // Then
        XCTAssertEqual(viewModel.bottles.count, 2)
        XCTAssertEqual(viewModel.filteredBottles.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadBottlesWithError() async {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await viewModel.loadBottles()

        // Then
        XCTAssertTrue(viewModel.bottles.isEmpty)
        XCTAssertTrue(viewModel.filteredBottles.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testSearchBottles() async {
        // Given
        mockRepository.bottles = [
            createTestBottle(name: "山崎 12年", distillery: "サントリー"),
            createTestBottle(name: "白州 18年", distillery: "サントリー"),
            createTestBottle(name: "マッカラン 18年", distillery: "マッカラン")
        ]
        await viewModel.loadBottles()

        // When
        viewModel.searchText = "サントリー"

        // 検索のデバウンスを待機
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

        // Then
        XCTAssertEqual(viewModel.filteredBottles.count, 2)
        XCTAssertTrue(viewModel.filteredBottles.allSatisfy { $0.distillery == "サントリー" })
    }

    func testFilterByStatus() async {
        // Given
        let openedBottle = createTestBottle(name: "開栓済み", distillery: "蒸留所")
        openedBottle.openedDate = Date()
        let unopenedBottle = createTestBottle(name: "未開栓", distillery: "蒸留所")

        mockRepository.bottles = [openedBottle, unopenedBottle]
        await viewModel.loadBottles()

        // When - 開栓済みフィルタ
        viewModel.selectedStatus = .opened

        // Then
        XCTAssertEqual(viewModel.filteredBottles.count, 1)
        XCTAssertEqual(viewModel.filteredBottles.first?.name, "開栓済み")

        // When - 未開栓フィルタ
        viewModel.selectedStatus = .unopened

        // Then
        XCTAssertEqual(viewModel.filteredBottles.count, 1)
        XCTAssertEqual(viewModel.filteredBottles.first?.name, "未開栓")
    }

    func testSortBottles() async {
        // Given
        let bottle1 = createTestBottle(name: "A ボトル", distillery: "蒸留所")
        bottle1.createdAt = Date().addingTimeInterval(-100)
        let bottle2 = createTestBottle(name: "B ボトル", distillery: "蒸留所")
        bottle2.createdAt = Date()

        mockRepository.bottles = [bottle1, bottle2]
        await viewModel.loadBottles()

        // When - 名前順ソート
        viewModel.sortOption = .name

        // Then
        XCTAssertEqual(viewModel.filteredBottles.first?.name, "A ボトル")

        // When - 作成日順ソート（新しい順）
        viewModel.sortOption = .dateCreated

        // Then
        XCTAssertEqual(viewModel.filteredBottles.first?.name, "B ボトル")
    }

    func testDeleteBottle() async {
        // Given
        let bottle = createTestBottle(name: "削除テスト", distillery: "蒸留所")
        mockRepository.bottles = [bottle]
        await viewModel.loadBottles()

        // When
        await viewModel.deleteBottle(bottle)

        // Then
        XCTAssertTrue(mockRepository.deleteBottleCalled)
        XCTAssertTrue(viewModel.bottles.isEmpty)
    }

    // MARK: - Helper Methods

    private func createTestBottle(name: String, distillery: String) -> Bottle {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let bottle = Bottle(context: context)
        bottle.id = UUID()
        bottle.name = name
        bottle.distillery = distillery
        bottle.createdAt = Date()
        bottle.updatedAt = Date()
        return bottle
    }
}

// MARK: - Mock Repository

class MockBottleRepository: BottleRepositoryProtocol {
    var bottles: [Bottle] = []
    var shouldThrowError = false
    var deleteBottleCalled = false

    func fetchAllBottles() async throws -> [Bottle] {
        if shouldThrowError {
            throw RepositoryError.coreDataError(NSError(domain: "Test", code: 1))
        }
        return bottles
    }

    func fetchBottle(by id: UUID) async throws -> Bottle? {
        return bottles.first { $0.id == id }
    }

    func searchBottles(query: String) async throws -> [Bottle] {
        return bottles.filter { bottle in
            bottle.name.contains(query) || bottle.distillery.contains(query)
        }
    }

    func fetchBottles(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [Bottle] {
        var result = bottles

        if let predicate = predicate {
            result = result.filter { bottle in
                predicate.evaluate(with: bottle)
            }
        }

        return result
    }

    func saveBottle(_ bottle: Bottle) async throws {
        if shouldThrowError {
            throw RepositoryError.saveFailed
        }
    }

    func createBottle(name: String, distillery: String) async throws -> Bottle {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let bottle = Bottle(context: context)
        bottle.id = UUID()
        bottle.name = name
        bottle.distillery = distillery
        bottle.createdAt = Date()
        bottle.updatedAt = Date()
        bottles.append(bottle)
        return bottle
    }

    func deleteBottle(_ bottle: Bottle) async throws {
        deleteBottleCalled = true
        bottles.removeAll { $0.id == bottle.id }
    }

    func deleteBottle(by id: UUID) async throws {
        deleteBottleCalled = true
        bottles.removeAll { $0.id == id }
    }

    // Statistics methods
    func getBottleCount() async throws -> Int {
        return bottles.count
    }

    func getTotalValue() async throws -> Decimal {
        return bottles.compactMap { $0.purchasePrice?.decimalValue }.reduce(0, +)
    }

    func getAverageRating() async throws -> Double {
        let ratings = bottles.compactMap { $0.rating > 0 ? Double($0.rating) : nil }
        guard !ratings.isEmpty else { return 0.0 }
        return ratings.reduce(0, +) / Double(ratings.count)
    }

    func getBottlesByRegion() async throws -> [String: Int] {
        var regionCounts: [String: Int] = [:]
        for bottle in bottles {
            if let region = bottle.region, !region.isEmpty {
                regionCounts[region, default: 0] += 1
            }
        }
        return regionCounts
    }

    func fetchOpenedBottles() async throws -> [Bottle] {
        return bottles.filter { $0.openedDate != nil }
    }

    func getBottlesByType() async throws -> [String: Int] {
        var typeCounts: [String: Int] = [:]
        for bottle in bottles {
            if let type = bottle.type, !type.isEmpty {
                typeCounts[type, default: 0] += 1
            }
        }
        return typeCounts
    }

    func getVintageDistribution() async throws -> [Int: Int] {
        var vintageCounts: [Int: Int] = [:]
        for bottle in bottles {
            if bottle.vintage > 0 {
                let vintage = Int(bottle.vintage)
                vintageCounts[vintage, default: 0] += 1
            }
        }
        return vintageCounts
    }
}