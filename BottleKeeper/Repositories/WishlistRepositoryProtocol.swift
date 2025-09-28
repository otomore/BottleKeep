import Foundation
import CoreData

/// WishlistRepositoryのプロトコル定義
protocol WishlistRepositoryProtocol {
    // MARK: - Fetch Operations
    func fetchAllWishlistItems() async throws -> [WishlistItem]
    func fetchWishlistItem(by id: UUID) async throws -> WishlistItem?
    func searchWishlistItems(query: String) async throws -> [WishlistItem]
    func fetchWishlistItems(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [WishlistItem]

    // MARK: - Save Operations
    func saveWishlistItem(_ item: WishlistItem) async throws
    func createWishlistItem(name: String, distillery: String) async throws -> WishlistItem

    // MARK: - Delete Operations
    func deleteWishlistItem(_ item: WishlistItem) async throws
    func deleteWishlistItem(by id: UUID) async throws

    // MARK: - Priority Operations
    func fetchWishlistItemsByPriority(_ priority: Int16) async throws -> [WishlistItem]
    func getWishlistItemCount() async throws -> Int
    func getTotalEstimatedValue() async throws -> Decimal
}

/// WishlistRepository層のエラー定義
enum WishlistRepositoryError: LocalizedError {
    case itemNotFound
    case coreDataError(Error)
    case invalidData
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "ウィッシュリストアイテムが見つかりません"
        case .coreDataError(let error):
            return "データベースエラー: \(error.localizedDescription)"
        case .invalidData:
            return "無効なデータです"
        case .saveFailed:
            return "保存に失敗しました"
        }
    }
}