import Foundation
import SwiftUI

/// 依存性注入コンテナ
@MainActor
class DIContainer: ObservableObject {

    // MARK: - Services
    private let coreDataManager: CoreDataManager
    private let photoManager: PhotoManager

    // MARK: - Repositories
    private let bottleRepository: BottleRepositoryProtocol
    private let wishlistRepository: WishlistRepositoryProtocol

    // MARK: - Initialization

    init() {
        // Services
        self.coreDataManager = CoreDataManager.shared
        self.photoManager = PhotoManager.shared

        // Repositories
        self.bottleRepository = BottleRepository(coreDataManager: coreDataManager)
        self.wishlistRepository = WishlistRepository(coreDataManager: coreDataManager)
    }

    // MARK: - ViewModels Factory

    func makeBottleListViewModel() -> BottleListViewModel {
        return BottleListViewModel(repository: bottleRepository)
    }

    func makeBottleDetailViewModel(bottle: Bottle) -> BottleDetailViewModel {
        return BottleDetailViewModel(
            bottle: bottle,
            repository: bottleRepository,
            photoManager: photoManager
        )
    }

    func makeBottleFormViewModel(bottle: Bottle? = nil) -> BottleFormViewModel {
        return BottleFormViewModel(
            bottle: bottle,
            repository: bottleRepository,
            photoManager: photoManager
        )
    }

    func makeStatisticsViewModel() -> StatisticsViewModel {
        return StatisticsViewModel(repository: bottleRepository)
    }

    func makeWishlistViewModel() -> WishlistViewModel {
        return WishlistViewModel(repository: wishlistRepository)
    }

    // MARK: - Services Access

    func getCoreDataManager() -> CoreDataManager {
        return coreDataManager
    }

    func getPhotoManager() -> PhotoManager {
        return photoManager
    }

    func getBottleRepository() -> BottleRepositoryProtocol {
        return bottleRepository
    }

    func getWishlistRepository() -> WishlistRepositoryProtocol {
        return wishlistRepository
    }
}