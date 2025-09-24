import Foundation
import CoreData
import os.log

/// BottleのCore Data操作を管理するRepository
class BottleRepository: BottleRepositoryProtocol {

    private let coreDataManager: CoreDataManager
    private let logger = Logger(subsystem: "com.bottlekeep.app", category: "BottleRepository")

    // MARK: - Initialization

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    // MARK: - Fetch Operations

    func fetchAllBottles() async throws -> [Bottle] {
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \Bottle.updatedAt, ascending: false),
            NSSortDescriptor(keyPath: \Bottle.name, ascending: true)
        ]
        return try await fetchBottles(with: nil, sortDescriptors: sortDescriptors)
    }

    func fetchBottle(by id: UUID) async throws -> Bottle? {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let bottles = try context.fetch(request)
            return bottles.first
        }
    }

    func searchBottles(query: String) async throws -> [Bottle] {
        let predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ OR distillery CONTAINS[cd] %@ OR region CONTAINS[cd] %@ OR type CONTAINS[cd] %@",
            query, query, query, query
        )

        let sortDescriptors = [
            NSSortDescriptor(keyPath: \Bottle.name, ascending: true)
        ]

        return try await fetchBottles(with: predicate, sortDescriptors: sortDescriptors)
    }

    func fetchBottles(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [Bottle] {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors

            do {
                let bottles = try context.fetch(request)
                self.logger.info("Fetched \(bottles.count) bottles")
                return bottles
            } catch {
                self.logger.error("Fetch bottles error: \(error)")
                throw RepositoryError.coreDataError(error)
            }
        }
    }

    // MARK: - Save Operations

    func saveBottle(_ bottle: Bottle) async throws {
        return try await coreDataManager.performBackgroundTask { context in
            // バリデーション
            try bottle.validate()

            // 既存のボトルの場合は更新
            if !bottle.isInserted {
                bottle.updatedAt = Date()
            }

            do {
                try context.save()
                self.logger.info("Bottle saved successfully: \(bottle.name)")
            } catch {
                self.logger.error("Save bottle error: \(error)")
                throw RepositoryError.saveFailed
            }
        }
    }

    func createBottle(name: String, distillery: String) async throws -> Bottle {
        return try await coreDataManager.performBackgroundTask { context in
            let bottle = Bottle(context: context)
            bottle.name = name
            bottle.distillery = distillery

            try bottle.validate()

            do {
                try context.save()
                self.logger.info("New bottle created: \(name)")
                return bottle
            } catch {
                self.logger.error("Create bottle error: \(error)")
                throw RepositoryError.saveFailed
            }
        }
    }

    // MARK: - Delete Operations

    func deleteBottle(_ bottle: Bottle) async throws {
        return try await coreDataManager.performBackgroundTask { context in
            // 関連する写真も削除
            if let photos = bottle.photos {
                for photo in photos {
                    if let bottlePhoto = photo as? BottlePhoto {
                        // 物理ファイルも削除
                        PhotoManager.shared.deletePhoto(fileName: bottlePhoto.fileName)
                        context.delete(bottlePhoto)
                    }
                }
            }

            context.delete(bottle)

            do {
                try context.save()
                self.logger.info("Bottle deleted successfully: \(bottle.name)")
            } catch {
                self.logger.error("Delete bottle error: \(error)")
                throw RepositoryError.saveFailed
            }
        }
    }

    func deleteBottle(by id: UUID) async throws {
        guard let bottle = try await fetchBottle(by: id) else {
            throw RepositoryError.bottleNotFound
        }
        try await deleteBottle(bottle)
    }

    // MARK: - Statistics

    func getBottleCount() async throws -> Int {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            return try context.count(for: request)
        }
    }

    func getTotalValue() async throws -> Decimal {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            request.predicate = NSPredicate(format: "purchasePrice != nil")

            let bottles = try context.fetch(request)
            let totalValue = bottles.compactMap { $0.purchasePrice }
                                   .reduce(Decimal(0)) { $0 + $1.decimalValue }

            return totalValue
        }
    }

    func getAverageRating() async throws -> Double {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            request.predicate = NSPredicate(format: "rating > 0")

            let bottles = try context.fetch(request)
            guard !bottles.isEmpty else { return 0.0 }

            let totalRating = bottles.reduce(0) { $0 + Int($1.rating) }
            return Double(totalRating) / Double(bottles.count)
        }
    }

    func getBottlesByRegion() async throws -> [String: Int] {
        return try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            request.predicate = NSPredicate(format: "region != nil AND region != ''")

            let bottles = try context.fetch(request)
            var regionCounts: [String: Int] = [:]

            for bottle in bottles {
                if let region = bottle.region {
                    regionCounts[region, default: 0] += 1
                }
            }

            return regionCounts
        }
    }
}

// MARK: - Convenience Extensions

extension BottleRepository {

    /// 開栓済みボトルを取得
    func fetchOpenedBottles() async throws -> [Bottle] {
        let predicate = NSPredicate(format: "openedDate != nil")
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \Bottle.openedDate, ascending: false)
        ]
        return try await fetchBottles(with: predicate, sortDescriptors: sortDescriptors)
    }

    /// 未開栓ボトルを取得
    func fetchUnopenedBottles() async throws -> [Bottle] {
        let predicate = NSPredicate(format: "openedDate == nil")
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \Bottle.purchaseDate, ascending: false),
            NSSortDescriptor(keyPath: \Bottle.name, ascending: true)
        ]
        return try await fetchBottles(with: predicate, sortDescriptors: sortDescriptors)
    }

    /// 高評価ボトルを取得（4星以上）
    func fetchHighRatedBottles() async throws -> [Bottle] {
        let predicate = NSPredicate(format: "rating >= 4")
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \Bottle.rating, ascending: false),
            NSSortDescriptor(keyPath: \Bottle.name, ascending: true)
        ]
        return try await fetchBottles(with: predicate, sortDescriptors: sortDescriptors)
    }
}