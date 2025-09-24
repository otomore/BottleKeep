import XCTest
@testable import BottleKeep

@MainActor
class StatisticsViewModelTests: XCTestCase {

    var viewModel: StatisticsViewModel!
    var mockRepository: MockBottleRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockBottleRepository()
        viewModel = StatisticsViewModel(repository: mockRepository)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Tests

    func testLoadStatistics() async {
        // Given
        mockRepository.bottles = [
            createTestBottleWithStats(name: "山崎", region: "日本", rating: 5, price: 15000, opened: true),
            createTestBottleWithStats(name: "白州", region: "日本", rating: 4, price: 12000, opened: false),
            createTestBottleWithStats(name: "マッカラン", region: "スコットランド", rating: 5, price: 25000, opened: true)
        ]

        // When
        await viewModel.loadStatistics()

        // Then
        XCTAssertEqual(viewModel.totalCount, 3)
        XCTAssertEqual(viewModel.totalValue, Decimal(52000))
        XCTAssertEqual(viewModel.averageRating, 4.666666666666667, accuracy: 0.01)
        XCTAssertEqual(viewModel.openedCount, 2)
        XCTAssertEqual(viewModel.regionDistribution["日本"], 2)
        XCTAssertEqual(viewModel.regionDistribution["スコットランド"], 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadStatisticsWithError() async {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await viewModel.loadStatistics()

        // Then
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertEqual(viewModel.totalValue, 0)
        XCTAssertEqual(viewModel.averageRating, 0)
        XCTAssertEqual(viewModel.openedCount, 0)
        XCTAssertTrue(viewModel.regionDistribution.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testComputedProperties() async {
        // Given
        mockRepository.bottles = [
            createTestBottleWithStats(name: "テスト1", region: "日本", rating: 4, price: 10000, opened: true),
            createTestBottleWithStats(name: "テスト2", region: "日本", rating: 5, price: 20000, opened: false),
            createTestBottleWithStats(name: "テスト3", region: "スコットランド", rating: 3, price: 15000, opened: false)
        ]

        await viewModel.loadStatistics()

        // When & Then
        XCTAssertEqual(viewModel.unopenedCount, 2)
        XCTAssertEqual(viewModel.openedPercentage, 33.333333333333336, accuracy: 0.01)
        XCTAssertEqual(viewModel.averagePrice, 15000.0, accuracy: 0.01)
        XCTAssertTrue(viewModel.totalValueText.contains("45,000"))
        XCTAssertEqual(viewModel.averageRatingText, "4.0/5")

        let sortedRegions = viewModel.sortedRegions
        XCTAssertEqual(sortedRegions.first?.0, "日本") // 最多地域
        XCTAssertEqual(sortedRegions.first?.1, 2)
    }

    func testStatisticsSummary() async {
        // Given
        mockRepository.bottles = [
            createTestBottleWithStats(name: "テスト", region: "日本", rating: 5, price: 10000, opened: true)
        ]

        await viewModel.loadStatistics()

        // When
        let summary = viewModel.summary

        // Then
        XCTAssertEqual(summary.totalCount, 1)
        XCTAssertEqual(summary.openedCount, 1)
        XCTAssertEqual(summary.unopenedCount, 0)
        XCTAssertEqual(summary.totalValue, Decimal(10000))
        XCTAssertEqual(summary.averagePrice, 10000.0)
        XCTAssertEqual(summary.averageRating, 5.0)
    }

    func testRefreshData() async {
        // Given
        mockRepository.bottles = [
            createTestBottleWithStats(name: "テスト", region: "日本", rating: 5, price: 10000, opened: true)
        ]

        // When
        await viewModel.refreshData()

        // Then
        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testEmptyStatistics() async {
        // Given - 空のリポジトリ
        mockRepository.bottles = []

        // When
        await viewModel.loadStatistics()

        // Then
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertEqual(viewModel.totalValue, 0)
        XCTAssertEqual(viewModel.averageRating, 0)
        XCTAssertEqual(viewModel.openedCount, 0)
        XCTAssertEqual(viewModel.unopenedCount, 0)
        XCTAssertEqual(viewModel.openedPercentage, 0)
        XCTAssertEqual(viewModel.averagePrice, 0)
        XCTAssertTrue(viewModel.regionDistribution.isEmpty)
        XCTAssertEqual(viewModel.averageRatingText, "未評価")
    }

    // MARK: - Helper Methods

    private func createTestBottleWithStats(
        name: String,
        region: String,
        rating: Int16,
        price: Double,
        opened: Bool
    ) -> Bottle {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let bottle = Bottle(context: context)
        bottle.id = UUID()
        bottle.name = name
        bottle.distillery = "テスト蒸留所"
        bottle.region = region
        bottle.rating = rating
        bottle.purchasePrice = NSDecimalNumber(value: price)
        bottle.createdAt = Date()
        bottle.updatedAt = Date()

        if opened {
            bottle.openedDate = Date()
        }

        return bottle
    }
}