# BottleKeeper データモデル定義書（現実版）

## 1. 概要

### 1.1 目的
BottleKeeperアプリのCore Dataモデルを定義し、すぐに実装できる形で提供する。趣味開発なので、まず動くものを作って、必要に応じて改善していく。

### 1.2 設計方針
- **シンプル重視**: 複雑なデータ制約は避けて、基本機能に集中
- **すぐ実装**: コピペで使えるコード例を提供
- **後から拡張**: 将来の機能追加に対応できる余地を残す
- **iOS標準**: Core Dataの基本機能をシンプルに使う

### 1.3 技術スタック
- **フレームワーク**: Core Data (iOS 16.0+)
- **永続化**: SQLite Store（デフォルト）
- **同期**: 将来CloudKit対応予定（今は考えない）

## 2. Core Data設定

### 2.1 基本設定
```swift
// CoreDataStack.swift
import CoreData
import Foundation

class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BottleKeeper")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func save() throws {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data保存エラー: \(error.localizedDescription)")
                throw error
            }
        }
    }
}
```

## 3. エンティティ定義

### 3.1 Bottle エンティティ

#### 3.1.1 基本属性

| 属性名 | データ型 | 制約 | デフォルト値 | 説明 |
|--------|---------|------|-------------|------|
| **id** | UUID | 必須 | UUID() | プライマリキー |
| **name** | String | 必須 | - | 銘柄名 |
| **distillery** | String | 必須 | - | 蒸留所名 |
| **region** | String | Optional | - | 生産地域 |
| **type** | String | Optional | - | 種類(Single Malt等) |
| **abv** | Double | 必須 | 40.0 | アルコール度数 |
| **volume** | Int32 | 必須 | 700 | 総容量(ml) |
| **remainingVolume** | Int32 | 必須 | volume値 | 残量(ml) |
| **vintage** | Int32 | Optional | - | 蒸留年 |
| **purchaseDate** | Date | 必須 | Date() | 購入日 |
| **purchasePrice** | Decimal | Optional | - | 購入価格 |
| **shop** | String | Optional | - | 購入店舗 |
| **openedDate** | Date | Optional | - | 開栓日 |
| **rating** | Int16 | Optional | - | 5段階評価 |
| **notes** | String | Optional | - | テイスティングノート |
| **createdAt** | Date | 必須 | Date() | 作成日時 |
| **updatedAt** | Date | 必須 | Date() | 更新日時 |

#### 3.1.2 計算プロパティ
```swift
// Bottle+CoreDataClass.swift
extension Bottle {
    // 残量パーセンテージ
    var remainingPercentage: Double {
        guard volume > 0 else { return 0.0 }
        return Double(remainingVolume) / Double(volume) * 100.0
    }

    // 消費量
    var consumedVolume: Int32 {
        return volume - remainingVolume
    }

    // 残量状況（シンプル版）
    var remainingStatus: String {
        let percentage = remainingPercentage
        switch percentage {
        case 0: return "飲み切り"
        case 0.01...10: return "残りわずか"
        case 10.01...50: return "半分以下"
        default: return "十分"
        }
    }

    // 開栓済みかどうか
    var isOpened: Bool {
        return openedDate != nil
    }
}
```

### 3.2 Photo エンティティ

#### 3.2.1 基本属性

| 属性名 | データ型 | 制約 | デフォルト値 | 説明 |
|--------|---------|------|-------------|------|
| **id** | UUID | 必須 | UUID() | プライマリキー |
| **fileName** | String | 必須 | UUID().jpg | ファイル名 |
| **isMain** | Bool | 必須 | false | メイン写真フラグ |
| **createdAt** | Date | 必須 | Date() | 作成日時 |

#### 3.2.2 画像管理（シンプル版）
```swift
// PhotoManager.swift
import UIKit

class PhotoManager {
    static let shared = PhotoManager()

    private var photosDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Photos")
    }

    init() {
        // 写真フォルダ作成
        try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }

    // 写真保存
    func savePhoto(_ image: UIImage) -> String? {
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        // リサイズして保存（シンプル版）
        let resized = image.resized(maxSize: CGSize(width: 1024, height: 1024))
        guard let data = resized.jpegData(compressionQuality: 0.8) else { return nil }

        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("写真保存エラー: \(error)")
            return nil
        }
    }

    // 写真読み込み
    func loadPhoto(fileName: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }

    // 写真削除
    func deletePhoto(fileName: String) {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// UIImage拡張（シンプルリサイズ）
extension UIImage {
    func resized(maxSize: CGSize) -> UIImage {
        let scale = min(maxSize.width / size.width, maxSize.height / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? self
    }
}
```

## 4. リレーションシップ

### 4.1 Bottle ↔ Photo (One-to-Many)

```swift
// Bottle側
@NSManaged public var photos: NSSet?

// Photo側
@NSManaged public var bottle: Bottle?

// 便利メソッド
extension Bottle {
    var photoArray: [Photo] {
        let set = photos as? Set<Photo> ?? []
        return set.sorted { $0.createdAt < $1.createdAt }
    }

    var mainPhoto: Photo? {
        return photoArray.first { $0.isMain }
    }

    // メイン写真設定（シンプル版）
    func setMainPhoto(_ photo: Photo) {
        // 既存のメイン写真フラグをクリア
        photoArray.forEach { $0.isMain = false }
        // 新しいメイン写真設定
        photo.isMain = true
    }
}
```

## 5. データ操作例

### 5.1 基本的なCRUD操作

```swift
// BottleRepository.swift
class BottleRepository {
    private let context = CoreDataStack.shared.context

    // 新規ボトル作成
    func createBottle(name: String, distillery: String, abv: Double, volume: Int32) -> Bottle {
        let bottle = Bottle(context: context)
        bottle.id = UUID()
        bottle.name = name
        bottle.distillery = distillery
        bottle.abv = abv
        bottle.volume = volume
        bottle.remainingVolume = volume
        bottle.purchaseDate = Date()
        bottle.createdAt = Date()
        bottle.updatedAt = Date()
        return bottle
    }

    // 全ボトル取得（エラーハンドリング改善）
    func fetchAllBottles() throws -> [Bottle] {
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Bottle.createdAt, ascending: false)]
        // メモリ効率のためバッチサイズ設定
        request.fetchBatchSize = 50

        do {
            return try context.fetch(request)
        } catch {
            print("ボトル取得エラー: \(error.localizedDescription)")
            throw error
        }
    }

    // 検索（エラーハンドリング改善）
    func searchBottles(keyword: String) throws -> [Bottle] {
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
        request.predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ OR distillery CONTAINS[cd] %@",
            keyword, keyword
        )
        request.fetchBatchSize = 50

        do {
            return try context.fetch(request)
        } catch {
            print("検索エラー: \(error.localizedDescription)")
            throw error
        }
    }

    // 保存（エラーハンドリング改善）
    func save() throws {
        do {
            try CoreDataStack.shared.context.save()
        } catch {
            print("保存エラー: \(error.localizedDescription)")
            throw error
        }
    }

    // 削除（エラーハンドリング改善）
    func delete(_ bottle: Bottle) throws {
        // 関連写真も削除
        for photo in bottle.photoArray {
            PhotoManager.shared.deletePhoto(fileName: photo.fileName)
            context.delete(photo)
        }
        context.delete(bottle)
        try save()
    }
}
```

### 5.2 写真付きボトル作成

```swift
// 写真付きボトルの作成例
func createBottleWithPhoto(name: String, distillery: String, image: UIImage) {
    let repository = BottleRepository()

    // ボトル作成
    let bottle = repository.createBottle(name: name, distillery: distillery, abv: 40.0, volume: 700)

    // 写真保存
    if let fileName = PhotoManager.shared.savePhoto(image) {
        let photo = Photo(context: CoreDataStack.shared.context)
        photo.id = UUID()
        photo.fileName = fileName
        photo.isMain = true
        photo.createdAt = Date()
        photo.bottle = bottle
    }

    try repository.save()
}
```

## 6. CloudKit連携準備

### 6.1 将来のCloudKit対応
今は実装しないが、将来対応する時のための準備：

```swift
// 将来CloudKit対応時に追加する属性
// ckRecordID: String? (CloudKitレコードID)
// ckLastModified: Date? (CloudKit最終更新日)

// CloudKit対応版CoreDataStack（将来実装）
/*
lazy var persistentContainer: NSPersistentCloudKitContainer = {
    let container = NSPersistentCloudKitContainer(name: "BottleKeeper")

    // CloudKit有効化
    let description = container.persistentStoreDescriptions.first!
    description.setOption(true as NSNumber, forKey: NSPersistentCloudKitContainerOptionsKey)

    container.loadPersistentStores { _, error in
        if let error = error {
            fatalError("Core Data error: \(error)")
        }
    }

    return container
}()
*/
```

## 7. .xcdatamodeld設定

### 7.1 Xcodeでの設定手順

1. **新しいData Modelファイル作成**
   - File → New → File → Core Data → Data Model
   - 名前: "BottleKeeper"

2. **Bottleエンティティ作成**
   - Entity名: Bottle
   - Codegen: Category/Extension
   - 上記の属性を追加

3. **Photoエンティティ作成**
   - Entity名: Photo
   - Codegen: Category/Extension
   - 上記の属性を追加

4. **リレーションシップ設定**
   - Bottle → Photo: photos (To Many, Cascade)
   - Photo → Bottle: bottle (To One, Nullify)

### 7.2 基本的なバリデーション
```swift
// Bottle+CoreDataClass.swift
extension Bottle {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateData()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateData()
    }

    private func validateData() throws {
        // 基本的なチェックのみ
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "BottleValidation", code: 1, userInfo: [NSLocalizedDescriptionKey: "銘柄名は必須です"])
        }

        guard remainingVolume <= volume else {
            throw NSError(domain: "BottleValidation", code: 2, userInfo: [NSLocalizedDescriptionKey: "残量が総容量を超えています"])
        }
    }
}
```

## 8. 使用例

### 8.1 SwiftUIでの使用例
```swift
// BottleListView.swift
struct BottleListView: View {
    @StateObject private var repository = BottleRepository()
    @State private var bottles: [Bottle] = []

    var body: some View {
        List(bottles, id: \.id) { bottle in
            BottleRowView(bottle: bottle)
        }
        .onAppear {
            bottles = repository.fetchAllBottles()
        }
    }
}

struct BottleRowView: View {
    let bottle: Bottle

    var body: some View {
        HStack {
            // メイン写真表示
            if let mainPhoto = bottle.mainPhoto,
               let image = PhotoManager.shared.loadPhoto(fileName: mainPhoto.fileName) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading) {
                Text(bottle.name)
                    .font(.headline)
                Text(bottle.distillery)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("残量: \(bottle.remainingStatus)")
                    .font(.caption)
            }

            Spacer()
        }
    }
}
```

## 9. テスト・デバッグ支援

### 9.1 基本的なテストの書き方
```swift
// BottleRepositoryTests.swift
import XCTest
import CoreData
@testable import BottleKeeper

class BottleRepositoryTests: XCTestCase {
    var repository: BottleRepository!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        // テスト用のインメモリストア作成
        testContext = createInMemoryContext()
        repository = BottleRepository()
    }

    func testCreateBottle() {
        let bottle = repository.createBottle(
            name: "山崎",
            distillery: "サントリー",
            abv: 43.0,
            volume: 700
        )

        XCTAssertEqual(bottle.name, "山崎")
        XCTAssertEqual(bottle.remainingVolume, 700)
        XCTAssertEqual(bottle.remainingPercentage, 100.0, accuracy: 0.01)
    }

    func testRemainingStatus() {
        let bottle = repository.createBottle(name: "テスト", distillery: "テスト", abv: 40.0, volume: 700)

        bottle.remainingVolume = 700
        XCTAssertEqual(bottle.remainingStatus, "十分")

        bottle.remainingVolume = 300
        XCTAssertEqual(bottle.remainingStatus, "半分以下")

        bottle.remainingVolume = 50
        XCTAssertEqual(bottle.remainingStatus, "残りわずか")

        bottle.remainingVolume = 0
        XCTAssertEqual(bottle.remainingStatus, "飲み切り")
    }

    private func createInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "BottleKeeper")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Test context creation failed: \(error)")
            }
        }

        return container.viewContext
    }
}
```

### 9.2 デバッグ支援機能
```swift
// DebugHelper.swift
class DebugHelper {
    static let shared = DebugHelper()

    // データベース統計表示
    func printDatabaseStats() {
        let context = CoreDataStack.shared.context

        do {
            let bottleCount = try context.count(for: Bottle.fetchRequest())
            let photoCount = try context.count(for: Photo.fetchRequest())

            print("=== データベース統計 ===")
            print("ボトル数: \(bottleCount)")
            print("写真数: \(photoCount)")

            // 最新5件のボトル表示
            let recentBottles = try CoreDataStack.shared.context.fetch(Bottle.fetchRequest()).prefix(5)
            print("\n最新ボトル:")
            for bottle in recentBottles {
                print("- \(bottle.name) (\(bottle.distillery)) - 残量:\(bottle.remainingStatus)")
            }

        } catch {
            print("統計取得エラー: \(error)")
        }
    }

    // 開発用サンプルデータ作成
    func createSampleData() {
        let repository = BottleRepository()

        let sampleBottles = [
            ("山崎", "サントリー", 43.0, 700),
            ("白州", "サントリー", 43.0, 700),
            ("余市", "ニッカ", 45.0, 700),
            ("宮城峡", "ニッカ", 45.0, 700),
            ("イチローズモルト", "ベンチャーウイスキー", 46.0, 700)
        ]

        for (name, distillery, abv, volume) in sampleBottles {
            let bottle = repository.createBottle(
                name: name,
                distillery: distillery,
                abv: abv,
                volume: Int32(volume)
            )
            // ランダムな残量設定
            bottle.remainingVolume = Int32.random(in: 100...volume)
        }

        do {
            try repository.save()
            print("サンプルデータを作成しました")
        } catch {
            print("サンプルデータ作成エラー: \(error)")
        }
    }

    // データベースリセット（開発用）
    func resetDatabase() {
        let context = CoreDataStack.shared.context

        do {
            // 全ボトル削除
            let bottles = try context.fetch(Bottle.fetchRequest())
            for bottle in bottles {
                context.delete(bottle)
            }

            // 全写真削除
            let photos = try context.fetch(Photo.fetchRequest())
            for photo in photos {
                PhotoManager.shared.deletePhoto(fileName: photo.fileName)
                context.delete(photo)
            }

            try context.save()
            print("データベースをリセットしました")

        } catch {
            print("リセットエラー: \(error)")
        }
    }
}
```

## 10. マイグレーション戦略

### 10.1 データモデルバージョン管理
```swift
// マイグレーション戦略（シンプル版）
class MigrationManager {
    static let shared = MigrationManager()

    // 将来のバージョンアップ時の手順
    func performMigrationIfNeeded() {
        // 軽量マイグレーション対応の変更
        // - 新しいOptional属性の追加
        // - 属性名の変更（Renaming Identifierで対応）

        // 例：Version 1.0 → 1.1 (将来の拡張)
        /*
         新規追加予定の属性:
         - Bottle.categoryID: String? (カテゴリ機能追加時)
         - Bottle.lastTastedDate: Date? (テイスティング履歴)
         - Photo.thumbnailFileName: String? (サムネイル機能)
         */
    }

    // データ移行テスト用
    func validateMigration() {
        // 移行前後のデータ整合性チェック
        let context = CoreDataStack.shared.context

        do {
            let bottles = try context.fetch(Bottle.fetchRequest())
            print("移行後ボトル数: \(bottles.count)")

            // 基本的な整合性チェック
            for bottle in bottles {
                assert(bottle.remainingVolume <= bottle.volume, "残量が総容量を超過: \(bottle.name)")
                assert(!bottle.name.isEmpty, "銘柄名が空: \(bottle.id)")
            }

            print("データ移行検証完了")

        } catch {
            print("移行検証エラー: \(error)")
        }
    }
}
```

## 11. まとめ

### 11.1 このデータモデルで実現できること
- ボトルの基本情報管理
- 写真の登録・表示
- 残量管理
- 基本的な検索・フィルタリング
- 適切なエラーハンドリング
- テスト・デバッグ支援

### 11.2 今後の拡張予定
- CloudKit同期機能
- より詳細な統計機能
- バックアップ・復元機能
- カテゴリ・タグ機能

### 11.3 開発方針
**まず動くものを作って、使いながら改善していく**

複雑な機能は後回しにして、基本的な機能から実装する。このデータモデルがあれば、すぐにMVPの開発を始められる。テストとデバッグ機能も含めているので、安心して開発を進められる。

---

**文書バージョン**: 1.0（現実版）
**作成日**: 2025-09-23
**最終更新**: 2025-09-23
**作成者**: 現実的な開発者

**次のアクション**: Core Dataの設定とBottleエンティティの実装から始めよう！