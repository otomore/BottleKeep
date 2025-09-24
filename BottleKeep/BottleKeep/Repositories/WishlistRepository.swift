import Foundation
import CoreData
import os.log

/// WishlistItemのCore Data操作を管理するRepository
class WishlistRepository: WishlistRepositoryProtocol {

    private let coreDataManager: CoreDataManager
    private let logger = Logger(subsystem: "com.bottlekeep.app", category: "WishlistRepository")

    // MARK: - Initialization

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    // MARK: - Fetch Operations

    func fetchAllWishlistItems() async throws -> [WishlistItem] {
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \WishlistItem.priority, ascending: false),
            NSSortDescriptor(keyPath: \WishlistItem.createdAt, ascending: false),
            NSSortDescriptor(keyPath: \WishlistItem.name, ascending: true)
        ]
        return try await fetchWishlistItems(with: nil, sortDescriptors: sortDescriptors)
    }

    func fetchWishlistItem(by id: UUID) async throws -> WishlistItem? {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<WishlistItem> = WishlistItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let items = try context.fetch(request)
            return items.first
        }
    }

    func searchWishlistItems(query: String) async throws -> [WishlistItem] {
        let predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ OR distillery CONTAINS[cd] %@ OR region CONTAINS[cd] %@ OR type CONTAINS[cd] %@",
            query, query, query, query
        )

        let sortDescriptors = [
            NSSortDescriptor(keyPath: \WishlistItem.name, ascending: true)
        ]

        return try await fetchWishlistItems(with: predicate, sortDescriptors: sortDescriptors)
    }

    func fetchWishlistItems(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [WishlistItem] {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<WishlistItem> = WishlistItem.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors

            let items = try context.fetch(request)
            return items
        }
    }

    // MARK: - Save Operations

    func saveWishlistItem(_ item: WishlistItem) async throws {
        do {
            try item.validate()

            try await coreDataManager.performBackgroundTask { context in
                // アイテムを現在のコンテキストに取得
                guard let objectID = item.objectID.isTemporaryID ? nil : item.objectID else {
                    logger.error("WishlistItem objectID is nil")
                    throw WishlistRepositoryError.invalidData
                }

                let contextItem = try context.existingObject(with: objectID) as? WishlistItem
                    ?? item

                contextItem.updatedAt = Date()

                try context.save()
            }

            logger.info("WishlistItem saved successfully: \(item.name)")

        } catch let error as ValidationError {
            logger.error("WishlistItem validation failed: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Failed to save WishlistItem: \(error.localizedDescription)")
            throw WishlistRepositoryError.saveFailed
        }
    }

    func createWishlistItem(name: String, distillery: String) async throws -> WishlistItem {
        return try await coreDataManager.performBackgroundTask { context in
            let item = WishlistItem(context: context, name: name, distillery: distillery)

            try item.validate()
            try context.save()

            return item
        }
    }

    // MARK: - Delete Operations

    func deleteWishlistItem(_ item: WishlistItem) async throws {
        try await coreDataManager.performBackgroundTask { context in
            guard let objectID = item.objectID.isTemporaryID ? nil : item.objectID else {
                throw WishlistRepositoryError.itemNotFound
            }

            let contextItem = try context.existingObject(with: objectID)
            context.delete(contextItem)

            try context.save()
        }

        logger.info("WishlistItem deleted successfully: \(item.name)")
    }

    func deleteWishlistItem(by id: UUID) async throws {
        guard let item = try await fetchWishlistItem(by: id) else {
            throw WishlistRepositoryError.itemNotFound
        }

        try await deleteWishlistItem(item)
    }

    // MARK: - Priority Operations

    func fetchWishlistItemsByPriority(_ priority: Int16) async throws -> [WishlistItem] {
        let predicate = NSPredicate(format: "priority == %d", priority)
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \WishlistItem.createdAt, ascending: false),
            NSSortDescriptor(keyPath: \WishlistItem.name, ascending: true)
        ]
        return try await fetchWishlistItems(with: predicate, sortDescriptors: sortDescriptors)
    }

    // MARK: - Statistics

    func getWishlistItemCount() async throws -> Int {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<WishlistItem> = WishlistItem.fetchRequest()
            return try context.count(for: request)
        }
    }

    func getTotalEstimatedValue() async throws -> Decimal {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<WishlistItem> = WishlistItem.fetchRequest()
            request.predicate = NSPredicate(format: "estimatedPrice != nil")

            let items = try context.fetch(request)
            let totalValue = items.compactMap { $0.estimatedPrice }
                                  .reduce(Decimal(0)) { $0 + $1.decimalValue }

            return totalValue
        }
    }
}

// MARK: - Convenience Extensions

extension WishlistRepository {

    /// 高優先度アイテムを取得
    func fetchHighPriorityItems() async throws -> [WishlistItem] {
        return try await fetchWishlistItemsByPriority(3)
    }

    /// 中優先度アイテムを取得
    func fetchMediumPriorityItems() async throws -> [WishlistItem] {
        return try await fetchWishlistItemsByPriority(2)
    }

    /// 低優先度アイテムを取得
    func fetchLowPriorityItems() async throws -> [WishlistItem] {
        return try await fetchWishlistItemsByPriority(1)
    }

    /// 推定価格が設定されているアイテムを取得
    func fetchItemsWithPrice() async throws -> [WishlistItem] {
        let predicate = NSPredicate(format: "estimatedPrice != nil AND estimatedPrice > 0")
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \WishlistItem.estimatedPrice, ascending: false)
        ]
        return try await fetchWishlistItems(with: predicate, sortDescriptors: sortDescriptors)
    }

    /// 最近追加されたアイテムを取得
    func fetchRecentItems(limit: Int = 10) async throws -> [WishlistItem] {
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \WishlistItem.createdAt, ascending: false)
        ]

        let items = try await fetchWishlistItems(with: nil, sortDescriptors: sortDescriptors)
        return Array(items.prefix(limit))
    }
}