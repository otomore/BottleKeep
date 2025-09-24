import Foundation
import CoreData

/// BottleRepositoryのプロトコル定義
protocol BottleRepositoryProtocol {
    // MARK: - Fetch Operations
    func fetchAllBottles() async throws -> [Bottle]
    func fetchBottle(by id: UUID) async throws -> Bottle?
    func searchBottles(query: String) async throws -> [Bottle]
    func fetchBottles(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [Bottle]

    // MARK: - Save Operations
    func saveBottle(_ bottle: Bottle) async throws
    func createBottle(name: String, distillery: String) async throws -> Bottle

    // MARK: - Delete Operations
    func deleteBottle(_ bottle: Bottle) async throws
    func deleteBottle(by id: UUID) async throws

    // MARK: - Statistics
    func getBottleCount() async throws -> Int
    func getTotalValue() async throws -> Decimal
    func getAverageRating() async throws -> Double
    func getBottlesByRegion() async throws -> [String: Int]
    func fetchOpenedBottles() async throws -> [Bottle]
    func getBottlesByType() async throws -> [String: Int]
    func getVintageDistribution() async throws -> [Int: Int]
}

/// Repository層のエラー定義
enum RepositoryError: LocalizedError {
    case bottleNotFound
    case coreDataError(Error)
    case invalidData
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .bottleNotFound:
            return "ボトルが見つかりません"
        case .coreDataError(let error):
            return "データベースエラー: \(error.localizedDescription)"
        case .invalidData:
            return "無効なデータです"
        case .saveFailed:
            return "保存に失敗しました"
        }
    }
}