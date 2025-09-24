# BottleKeep アーキテクチャ設計書

## 1. システム概要

### 1.1 アーキテクチャパターン
- **アーキテクチャ**: MVVM (Model-View-ViewModel) パターン
- **データフロー**: Unidirectional Data Flow
- **状態管理**: SwiftUI @State, @StateObject, @ObservableObject

### 1.2 システム構成図
```
┌─────────────────┐
│   SwiftUI Views │ ← Presentation Layer
├─────────────────┤
│   ViewModels    │ ← Business Logic Layer
├─────────────────┤
│   Repositories  │ ← Data Access Layer
├─────────────────┤
│   Core Data     │ ← Data Persistence Layer
│   + CloudKit    │
├─────────────────┤
│   iOS Services  │ ← Platform Services
│ (Camera, Photos)│
└─────────────────┘
```

## 2. レイヤー設計

### 2.1 Presentation Layer (UI Layer)
**責務**: ユーザーインターフェースの表示とユーザーインタラクションの処理

#### 主要コンポーネント
- `ContentView`: メインのタブビュー
- `BottleListView`: ボトル一覧表示
- `BottleDetailView`: ボトル詳細表示
- `BottleFormView`: ボトル登録・編集フォーム
- `WishlistView`: ウィッシュリスト表示
- `StatisticsView`: 統計情報表示

#### 設計原則
- Single Responsibility: 各Viewは単一の責務を持つ
- Reusable Components: 再利用可能なコンポーネント設計
- Accessibility First: VoiceOver, Dynamic Type対応

### 2.2 Business Logic Layer (ViewModel Layer)
**責務**: ビジネスロジック、UIの状態管理、データの変換

#### 主要コンポーネント
- `BottleListViewModel`: ボトル一覧の状態管理
- `BottleDetailViewModel`: ボトル詳細の状態管理
- `BottleFormViewModel`: フォームの状態管理とバリデーション
- `WishlistViewModel`: ウィッシュリストの状態管理
- `StatisticsViewModel`: 統計データの計算と状態管理

#### 設計原則
- ObservableObject プロトコル準拠
- @Published プロパティでUI更新
- Repository経由でのデータアクセス
- @MainActor による UI更新の安全性確保
- Async/await パターンでの非同期処理

### 2.3 Data Access Layer (Repository Layer)
**責務**: データの取得、保存、更新、削除の抽象化

#### 主要コンポーネント
- `BottleRepository`: ボトルデータの CRUD 操作
- `PhotoRepository`: 写真データの管理
- `WishlistRepository`: ウィッシュリストの CRUD 操作
- `StatisticsRepository`: 統計データの計算

#### 設計原則
- Protocol-based design (テスタビリティ向上)
- Error handling with Result型
- Async/await 対応
- Dependency Injection パターンの活用

#### プロトコル設計例
```swift
protocol BottleRepositoryProtocol {
    func fetchBottles() async throws -> [Bottle]
    func saveBottle(_ bottle: Bottle) async throws
    func deleteBottle(_ bottle: Bottle) async throws
    func searchBottles(query: String) async throws -> [Bottle]
}

protocol PhotoRepositoryProtocol {
    func savePhoto(_ image: UIImage, for bottleID: UUID) async throws -> String
    func loadPhoto(path: String) async throws -> UIImage?
    func deletePhoto(path: String) async throws
}
```

### 2.4 Data Persistence Layer
**責務**: データの永続化、CloudKit同期

#### 主要コンポーネント
- Core Data Stack
- CloudKit Container
- Data Migration Manager

## 3. データフロー設計

### 3.1 基本的なデータフロー
```
User Action → View → ViewModel → Repository → Core Data
                ↑                               ↓
              UI Update ← ObservableObject ← CloudKit Sync
```

### 3.2 写真保存フロー
```
Camera/Photos → PhotoPicker → Image Processing → File System → Core Data Reference → CloudKit Asset
```

### 3.3 検索・フィルタフロー
```
Search Input → ViewModel → NSPredicate → Core Data Fetch → Filtered Results → UI Update
```

## 4. パッケージ構成

### 4.1 ディレクトリ構造
```
BottleKeep/
├── App/
│   ├── BottleKeepApp.swift
│   └── ContentView.swift
├── Views/
│   ├── Bottle/
│   │   ├── BottleListView.swift
│   │   ├── BottleDetailView.swift
│   │   └── BottleFormView.swift
│   ├── Wishlist/
│   │   └── WishlistView.swift
│   ├── Statistics/
│   │   └── StatisticsView.swift
│   └── Components/
│       ├── PhotoPickerView.swift
│       ├── RatingView.swift
│       └── SearchBar.swift
├── ViewModels/
│   ├── BottleListViewModel.swift
│   ├── BottleDetailViewModel.swift
│   ├── BottleFormViewModel.swift
│   ├── WishlistViewModel.swift
│   └── StatisticsViewModel.swift
├── Models/
│   ├── CoreData/
│   │   ├── BottleKeep.xcdatamodeld
│   │   ├── Bottle+CoreDataClass.swift
│   │   ├── Bottle+CoreDataProperties.swift
│   │   ├── PhotoEntity+CoreDataClass.swift
│   │   └── WishlistEntity+CoreDataClass.swift
│   └── DTOs/
│       ├── BottleDTO.swift
│       └── StatisticsDTO.swift
├── Repositories/
│   ├── Protocols/
│   │   ├── BottleRepositoryProtocol.swift
│   │   └── PhotoRepositoryProtocol.swift
│   ├── BottleRepository.swift
│   ├── PhotoRepository.swift
│   └── WishlistRepository.swift
├── Services/
│   ├── CoreDataManager.swift
│   ├── PhotoManager.swift
│   ├── CloudKitManager.swift
│   └── ExportService.swift
├── Utils/
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── Image+Extensions.swift
│   │   └── Date+Extensions.swift
│   ├── Constants.swift
│   └── Validators.swift
└── Resources/
    ├── Localizable.strings
    └── Assets.xcassets
```

## 5. Core Data設計

### 5.1 Core Data Stack
```swift
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "BottleKeep")

        // CloudKit configuration
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func save() {
        if context.hasChanges {
            try? context.save()
        }
    }
}
```

#### 5.1.1 依存性注入の実装例
```swift
// DIコンテナの設計例
class DIContainer {
    private let bottleRepository: BottleRepositoryProtocol
    private let photoRepository: PhotoRepositoryProtocol

    init() {
        self.bottleRepository = BottleRepository()
        self.photoRepository = PhotoRepository()
    }

    func makeBottleListViewModel() -> BottleListViewModel {
        return BottleListViewModel(repository: bottleRepository)
    }

    func makeBottleDetailViewModel(bottle: Bottle) -> BottleDetailViewModel {
        return BottleDetailViewModel(
            bottle: bottle,
            bottleRepository: bottleRepository,
            photoRepository: photoRepository
        )
    }
}
```

### 5.2 CloudKit同期設定
- NSPersistentCloudKitContainer使用
- History Tracking有効化
- Remote Change Notification有効化
- 自動マージ設定

## 6. エラーハンドリング戦略

### 6.1 エラー分類
```swift
enum BottleKeepError: LocalizedError {
    case coreDataError(Error)
    case cloudKitError(Error)
    case photoProcessingError(String)
    case validationError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .coreDataError(let error):
            return "データベースエラー: \(error.localizedDescription)"
        case .cloudKitError(let error):
            return "同期エラー: \(error.localizedDescription)"
        case .photoProcessingError(let message):
            return "写真処理エラー: \(message)"
        case .validationError(let message):
            return "入力エラー: \(message)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}
```

### 6.2 エラー表示戦略
- Toast通知での軽微なエラー表示
- Alert表示での重要なエラー表示
- ログ記録による問題追跡

## 7. パフォーマンス最適化

### 7.1 Core Data最適化
- NSFetchRequest batching
- Faulting最適化
- 適切なNSPredicate使用

### 7.2 UI最適化
- LazyVStack/LazyHStackの活用
- 画像の遅延読み込み
- メモリ効率的な画像キャッシュ

### 7.3 メモリ管理戦略
- 弱参照（weak self）の適切な使用
- 画像キャッシュサイズの制限
- バックグラウンド時のメモリ解放
- Core Data フォルトオブジェクトの活用

### 7.4 CloudKit最適化
- バッチ操作の活用
- 差分同期の実装
- コンフリクト解決の最適化

## 8. セキュリティ設計

### 8.1 データ保護
- iOS標準暗号化の活用
- Keychain Services使用
- 適切なファイル保護属性設定

### 8.2 プライバシー保護
- 写真アクセス権限の最小化
- データの外部送信なし
- 適切なPrivacy.plist設定

## 9. テスト戦略

### 9.1 テストレイヤー
- Unit Tests: ViewModel, Repository層
- Integration Tests: Core Data操作
- UI Tests: 主要ユーザーフロー

### 9.2 テスト設計原則
- Protocol-based design でモック作成
- Test Core Data Stack分離
- Screenshot Tests活用

---

**文書バージョン**: 1.0
**作成日**: 2025-09-21
**最終更新**: 2025-09-21
**作成者**: 個人プロジェクト