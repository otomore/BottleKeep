# BottleKeeper Core Data設計書

## 1. Core Dataモデル概要

### 1.1 Entity関係図
```
┌─────────────────┐     1:N     ┌─────────────────┐
│     Bottle      │◄────────────┤   PhotoEntity   │
│                 │             │                 │
│ - id (UUID)     │             │ - id (UUID)     │
│ - name          │             │ - fileName      │
│ - distillery    │             │ - isMain        │
│ - region        │             │ - createdAt     │
│ - type          │             │ - bottle        │
│ - abv           │             └─────────────────┘
│ - volume        │
│ - vintage       │
│ - purchaseDate  │
│ - purchasePrice │
│ - shop          │
│ - openedDate    │
│ - remainingVol  │
│ - rating        │
│ - notes         │
│ - createdAt     │
│ - updatedAt     │
│ - photos        │
└─────────────────┘

┌─────────────────┐
│ WishlistEntity  │
│                 │
│ - id (UUID)     │
│ - bottleName    │
│ - distillery    │
│ - priority      │
│ - budget        │
│ - notes         │
│ - targetPrice   │
│ - createdAt     │
│ - updatedAt     │
└─────────────────┘
```

## 2. Entity詳細設計

### 2.1 Bottle Entity
**目的**: ウイスキーボトルの基本情報と購入・飲酒履歴を管理

#### Attributes

| 属性名 | データ型 | Optional | CloudKit | 説明 |
|--------|----------|----------|----------|------|
| id | UUID | No | Yes | プライマリキー |
| name | String | No | Yes | 銘柄名 |
| distillery | String | No | Yes | 蒸留所名 |
| region | String | Yes | Yes | 生産地域 |
| type | String | Yes | Yes | タイプ（Single Malt, Blend等） |
| abv | Double | Yes | Yes | アルコール度数 |
| volume | Int32 | Yes | Yes | 容量（ml） |
| vintage | Int32 | Yes | Yes | 年代・ヴィンテージ |
| purchaseDate | Date | Yes | Yes | 購入日 |
| purchasePrice | Decimal | Yes | Yes | 購入価格 |
| shop | String | Yes | Yes | 購入店舗 |
| openedDate | Date | Yes | Yes | 開栓日 |
| remainingVolume | Int32 | Yes | Yes | 残量（ml） |
| rating | Int16 | Yes | Yes | 評価（1-5） |
| notes | String | Yes | Yes | テイスティングノート |
| createdAt | Date | No | Yes | 作成日時 |
| updatedAt | Date | No | Yes | 更新日時 |

#### Relationships
- `photos`: PhotoEntity への One-to-Many関係

#### Validation Rules
```swift
extension Bottle {
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }

        guard !distillery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyDistillery
        }

        if let abv = abv, !(0...100).contains(abv) {
            throw ValidationError.invalidABV
        }

        if let volume = volume, volume <= 0 {
            throw ValidationError.invalidVolume
        }

        if let remainingVolume = remainingVolume, let totalVolume = volume {
            guard remainingVolume <= totalVolume else {
                throw ValidationError.remainingVolumeExceedsTotal
            }
        }

        if let rating = rating, !(1...5).contains(rating) {
            throw ValidationError.invalidRating
        }
    }
}
```

### 2.2 PhotoEntity
**目的**: ボトルに関連する写真データの管理

#### Attributes

| 属性名 | データ型 | Optional | CloudKit | 説明 |
|--------|----------|----------|----------|------|
| id | UUID | No | Yes | プライマリキー |
| fileName | String | No | No | ローカルファイル名 |
| isMain | Bool | No | Yes | メイン写真フラグ |
| createdAt | Date | No | Yes | 作成日時 |
| ckAsset | String | Yes | Yes | CloudKit Asset参照 |

#### Relationships
- `bottle`: Bottle への Many-to-One関係

#### 写真管理戦略
```swift
class PhotoManager {
    private let documentsDirectory: URL

    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first!
    }

    func savePhoto(_ image: UIImage, for photoEntity: PhotoEntity) throws -> String {
        let fileName = "\(photoEntity.id.uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoError.compressionFailed
        }

        try data.write(to: fileURL)
        return fileName
    }

    func loadPhoto(fileName: String) -> UIImage? {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func deletePhoto(fileName: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        try FileManager.default.removeItem(at: fileURL)
    }
}
```

### 2.3 WishlistEntity
**目的**: 購入予定ボトルの管理

#### Attributes

| 属性名 | データ型 | Optional | CloudKit | 説明 |
|--------|----------|----------|----------|------|
| id | UUID | No | Yes | プライマリキー |
| bottleName | String | No | Yes | 欲しいボトル名 |
| distillery | String | Yes | Yes | 蒸留所名 |
| priority | Int16 | No | Yes | 優先度（1-5） |
| budget | Decimal | Yes | Yes | 予算 |
| notes | String | Yes | Yes | メモ |
| targetPrice | Decimal | Yes | Yes | 目標価格 |
| createdAt | Date | No | Yes | 作成日時 |
| updatedAt | Date | No | Yes | 更新日時 |

## 3. Core Data Stack設計

### 3.1 Persistent Container設定
```swift
import CoreData
import CloudKit

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "BottleKeeper")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }

        // CloudKit設定
        description.setOption(true as NSNumber,
                            forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber,
                            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // CloudKit container identifier
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.yourname.BottleKeeper"
        )

        // プライベートデータベース使用（機密性確保）
        description.cloudKitContainerOptions?.databaseScope = .private

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // 自動マージ設定
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func save() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
```

### 3.2 CloudKit設定

#### Container Options
```swift
// CloudKit Configuration
let options = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.yourname.BottleKeeper"
)

// レコードタイプ設定
options.databaseScope = .private
```

#### CloudKit Schema
```
Record Types:
- CD_Bottle
  - Fields: name, distillery, region, type, abv, volume, vintage,
           purchaseDate, purchasePrice, shop, openedDate,
           remainingVolume, rating, notes, createdAt, updatedAt
- CD_PhotoEntity
  - Fields: fileName, isMain, createdAt, ckAsset, bottle
- CD_WishlistEntity
  - Fields: bottleName, distillery, priority, budget, notes,
           targetPrice, createdAt, updatedAt
```

## 4. データアクセスパターン

### 4.1 Repository Pattern実装
```swift
protocol BottleRepositoryProtocol {
    func fetchAllBottles() async throws -> [Bottle]
    func fetchBottle(by id: UUID) async throws -> Bottle?
    func saveBottle(_ bottle: Bottle) async throws
    func deleteBottle(_ bottle: Bottle) async throws
    func searchBottles(query: String) async throws -> [Bottle]
}

class BottleRepository: BottleRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }

    func fetchAllBottles() async throws -> [Bottle] {
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Bottle.updatedAt, ascending: false)
        ]

        return try await context.perform {
            try self.context.fetch(request)
        }
    }

    func searchBottles(query: String) async throws -> [Bottle] {
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
        request.predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ OR distillery CONTAINS[cd] %@",
            query, query
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Bottle.name, ascending: true)
        ]

        return try await context.perform {
            try self.context.fetch(request)
        }
    }
}
```

### 4.2 パフォーマンス最適化

#### Index設計
```swift
// Bottle entityのインデックス設定
// name, distillery, region にインデックスを設定
// 検索性能向上のため
```

#### Batch Fetching
```swift
func fetchBottlesWithPhotos() async throws -> [Bottle] {
    let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
    request.relationshipKeyPathsForPrefetching = ["photos"]
    request.fetchBatchSize = 20

    return try await context.perform {
        try self.context.fetch(request)
    }
}
```

#### Predicate最適化
```swift
extension BottleRepository {
    func fetchBottlesByRegion(_ region: String) async throws -> [Bottle] {
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
        request.predicate = NSPredicate(format: "region == %@", region)

        return try await context.perform {
            try self.context.fetch(request)
        }
    }

    func fetchOpenedBottles() async throws -> [Bottle] {
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
        request.predicate = NSPredicate(format: "openedDate != nil")

        return try await context.perform {
            try self.context.fetch(request)
        }
    }
}
```

## 5. Data Migration戦略

### 5.1 Version管理
```swift
// BottleKeeper.xcdatamodeld versions:
// - BottleKeeper.xcdatamodel (v1.0)
// - BottleKeeper 2.xcdatamodel (v2.0) - future versions
```

### 5.2 Migration Policy
```swift
class BottleKeeperMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        // Custom migration logic here
        try super.createDestinationInstances(
            forSource: sInstance,
            in: mapping,
            manager: manager
        )
    }
}
```

## 6. CloudKit同期設計

### 6.1 同期戦略
- **Automatic Sync**: バックグラウンドでの自動同期
- **Conflict Resolution**: Last Write Wins戦略
- **Delta Sync**: 差分同期でパフォーマンス向上

### 6.2 エラーハンドリング
```swift
class CloudKitSyncManager {
    func handleSyncError(_ error: Error) {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable:
                // オフライン状態での処理
                break
            case .quotaExceeded:
                // 容量上限での処理
                break
            case .accountTemporarilyUnavailable:
                // iCloudアカウント問題
                break
            default:
                // その他のエラー
                break
            }
        }
    }
}
```

## 7. データバックアップ・復元

### 7.1 ローカルバックアップ
```swift
class LocalBackupManager {
    func createBackup() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first!
        let backupPath = documentsPath.appendingPathComponent("backup_\(Date().timeIntervalSince1970).zip")

        // Core Dataファイルと写真ファイルをZIP化
        // 実装詳細...

        return backupPath
    }

    func restoreFromBackup(url: URL) throws {
        // バックアップファイルから復元
        // 実装詳細...
    }
}
```

### 7.2 エクスポート機能
```swift
class DataExportService {
    func exportToCSV() throws -> URL {
        let bottles = try CoreDataManager.shared.context.fetch(Bottle.fetchRequest())
        var csvString = "Name,Distillery,Region,Type,ABV,Volume,Purchase Date,Price\n"

        for bottle in bottles {
            let row = "\(bottle.name),\(bottle.distillery),\(bottle.region ?? ""),\(bottle.type ?? ""),\(bottle.abv),\(bottle.volume),\(bottle.purchaseDate?.description ?? ""),\(bottle.purchasePrice?.description ?? "")\n"
            csvString.append(row)
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first!
        let csvPath = documentsPath.appendingPathComponent("bottles_export.csv")
        try csvString.write(to: csvPath, atomically: true, encoding: .utf8)

        return csvPath
    }
}
```

---

**文書バージョン**: 1.0
**作成日**: 2025-09-21
**最終更新**: 2025-09-21
**作成者**: 個人プロジェクト