# BottleKeeper 技術スタック（現実版）

## 1. 概要

### 1.1 目的
BottleKeeperアプリの技術選択を明確にして、さくっと作って楽しく使えるアプリを作る。趣味開発なので、複雑すぎない現実的な技術を選ぶ。

### 1.2 技術選択の基本方針
- **シンプル重視**: 複雑な設定は避けて、すぐ作り始められる
- **Apple標準**: iOS標準のツールを使って安定性確保
- **学習コスト最小**: 新しい技術は最小限に
- **楽しさ優先**: 作るのが楽しい技術を選ぶ
- **将来考慮**: 後から改善できる余地は残す

## 2. iOS開発環境

### 2.1 開発環境要件

#### 2.1.1 必須環境
| 項目 | 要件 | 理由 |
|------|------|------|
| **macOS** | 今あるMac | 何でもOK |
| **Xcode** | Xcode 15.0+ | SwiftUIの新機能使いたい |
| **Swift** | Swift 5.9+ | async/awaitが便利 |
| **iOS Deployment Target** | iOS 16.0+ | SwiftUIが安定してる |

#### 2.1.2 開発マシン
今あるMacで十分。M1以降なら快適、Intelでも動く。

#### 2.1.3 サポート対象デバイス
```swift
// とりあえずiOS 16以降なら何でも
iPhone: iOS 16以降のiPhone
- iPhone SE (第3世代) 以降
- iPhone 12 以降推奨
iPad: iPadOS 16以降のiPad
- iPad (第8世代) 以降
- iPad Air (第4世代) 以降
- iPad Pro 全世代
// 後で動作が重かったら制限すればいい

メモリ: 4GB RAM 推奨（iPad Pro: 8GB+）
ストレージ: 100MB (アプリ) + 写真データ容量
```

### 2.2 iOS バージョン戦略

#### 2.2.1 サポートポリシー
- **iOS 16.0+**: これで十分。大体のiPhoneで動く
- 古いバージョンは考えない（開発が複雑になるだけ）

#### 2.2.2 使う機能
```swift
// iOS 16で使える基本機能
- SwiftUI NavigationStack
- Core Data
- PhotosPicker
- 基本的なCloudKit

// 新機能は後で考える
```

## 3. UIフレームワーク選択

### 3.1 SwiftUI採用決定

#### 3.1.1 選択理由
- 楽しい（重要）
- 書きやすい
- Previewが便利
- iPad対応が楽
- Appleが推してる

#### 3.1.2 SwiftUI vs UIKit
```swift
// SwiftUIを選ぶ理由
✅ 書いてて楽しい
✅ コードが短い
✅ プレビューですぐ確認できる
✅ アニメーションが簡単

// UIKitは今回パス
❌ 書くのが面倒
❌ 趣味開発には複雑すぎ
```

## 4. データ管理技術

### 4.1 Core Data + CloudKit選択

#### 4.1.1 選択理由
- Apple純正で安心
- CloudKitでiPhone/iPad間同期が楽
- SwiftUIとの統合が良い

#### 4.1.2 Core Data設定
```swift
// シンプルなセットアップ
import CoreData
import CloudKit

class CoreDataStack {
    static let shared = CoreDataStack()

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

#### 4.1.3 CloudKit連携
- 基本的にはCore DataのCloudKit統合に任せる
- 複雑な同期処理は書かない
- エラーが出たら後で考える

## 5. 依存関係管理

### 5.1 Swift Package Manager

#### 5.1.1 外部ライブラリは最小限
```swift
// 基本的には外部ライブラリなし
// iOS標準フレームワークで頑張る

// 将来検討するライブラリ:
// - SwiftLint (コード品質)
// - Quick/Nimble (テスト)
// - SwiftFormat (コードフォーマット)

// Package.swift 例
dependencies: [
    // テスト用
    .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
    // コード品質
    .package(url: "https://github.com/realm/SwiftLint.git", from: "0.50.0")
]
```

## 6. アーキテクチャ設計

### 6.1 MVVM（軽め）

#### 6.1.1 基本構造
```swift
// View: SwiftUI
struct BottleListView: View {
    @StateObject private var viewModel = BottleListViewModel()

    var body: some View {
        List(viewModel.bottles) { bottle in
            Text(bottle.name)
        }
        .onAppear {
            viewModel.loadBottles()
        }
    }
}

// ViewModel: ObservableObject
class BottleListViewModel: ObservableObject {
    @Published var bottles: [Bottle] = []

    func loadBottles() {
        // Core Dataから読み込み
        let request = Bottle.fetchRequest()
        bottles = try? CoreDataStack.shared.context.fetch(request) ?? []
    }
}

// Model: Core Data Entity
// Xcode Data Model Editorで作る
```

### 6.2 プロジェクト構造
```
BottleKeeper/
├── Views/
│   ├── BottleListView.swift
│   ├── BottleDetailView.swift
│   └── BottleFormView.swift
├── ViewModels/
│   ├── BottleListViewModel.swift
│   └── BottleDetailViewModel.swift
├── Models/
│   └── BottleKeeper.xcdatamodeld
├── Core/
│   └── CoreDataStack.swift
└── Resources/
    └── Assets.xcassets
```

## 7. 開発ツールとワークフロー

### 7.1 ビルド設定
- Debug/Releaseの基本設定だけ
- 複雑なビルド設定は避ける

### 7.2 テスト

#### 7.2.1 基本テストだけ
```swift
// とりあえず基本的なテストだけ書く
import XCTest
@testable import BottleKeeper

class BottleTests: XCTestCase {
    func testBottleCreation() {
        // ボトルが作れるかだけチェック
        let bottle = Bottle()
        bottle.name = "Test Bottle"
        XCTAssertEqual(bottle.name, "Test Bottle")
    }

    func testRemainingVolumeCalculation() {
        // 残量計算が正しいかだけチェック
        let bottle = Bottle()
        bottle.volume = 700
        bottle.remainingVolume = 350
        XCTAssertEqual(bottle.remainingPercentage, 50.0)
    }
}

// UIテストは後で考える（手動テストで十分）
```

#### 7.2.2 テストの考え方
趣味アプリなので：
- 基本的なロジックのテストだけ書く
- UIテストは手動で十分
- カバレッジは気にしない
- 動かなくなったらテストを追加

### 7.3 コード品質

#### 7.3.1 シンプルに保つ
- Xcodeの基本的な警告を無視しない
- コードが読みづらくなったらリファクタリング
- SwiftLintは後で入れてもいい（無くても死なない）

### 7.4 バージョン管理
- Git + GitHub
- 基本的なcommit/push/pullだけ
- ブランチ戦略とかは考えない（一人だし）

## 8. パフォーマンス

### 8.1 基本的なことだけ
重くなったら考える程度で。

#### 8.1.1 画像の管理
```swift
// 基本的なキャッシュだけ
class SimpleImageCache {
    private let cache = NSCache<NSString, UIImage>()

    func get(_ key: String) -> UIImage? {
        cache.object(forKey: NSString(string: key))
    }

    func set(_ image: UIImage, key: String) {
        cache.setObject(image, forKey: NSString(string: key))
    }
}

// メモリ警告が出たらキャッシュをクリア
// iOSが自動でやってくれるけど、一応
```

#### 8.1.2 Core Dataはシンプルに
```swift
// 普通にfetchするだけ
// 数千本もボトルを登録しないし
// 重くなったらページングを考える
func fetchBottles() -> [Bottle] {
    let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
    return try? context.fetch(request) ?? []
}
```

### 8.2 画像の扱い

#### 8.2.1 シンプルなリサイズ
```swift
// とりあえず小さくするだけ
func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    image.draw(in: CGRect(origin: .zero, size: size))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resized
}

// 保存時に圧縮
func compressImage(_ image: UIImage) -> Data? {
    return image.jpegData(compressionQuality: 0.7)
}

// 複雑なことは後で考える
```

#### 8.2.2 AsyncImageは標準で十分
```swift
// iOS標準のAsyncImageをそのまま使う
AsyncImage(url: bottle.imageURL) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fill)
} placeholder: {
    Rectangle()
        .fill(Color.gray.opacity(0.3))
}
.frame(width: 100, height: 100)
.clipShape(RoundedRectangle(cornerRadius: 8))

// カスタムキャッシュは重くなったら考える
```

## 9. セキュリティ・プライバシー

### 9.1 基本的なセキュリティ
- Core DataはiOSが暗号化してくれる
- CloudKitもAppleが暗号化してくれる
- 複雑な暗号化は今は考えない

### 9.2 プライバシー
- 写真にアクセスする権限だけ設定
- データは外部に送信しない
- Info.plistに必要な権限を書く

```xml
<!-- Info.plist -->
<key>NSPhotoLibraryUsageDescription</key>
<string>ボトルの写真を選択するために使用します</string>
<key>NSCameraUsageDescription</key>
<string>ボトルの写真を撮影するために使用します</string>
```

## 10. 配布戦略

### 10.1 App Store配布準備
- Apple Developer Program登録（$99/年）
- 基本的な App Store Connect設定
- スクリーンショット撮影
- 簡単な説明文作成

### 10.2 TestFlight
- 自分でテストしてから公開
- 友達に頼んでテストしてもらう
- 致命的なバグがなければOK

## 11. 将来の拡張

### 11.1 やりたいことリスト（優先度低）
- Apple Watch対応
- ウィジェット
- Shortcuts対応
- より詳細な統計
- ARで在庫確認

### 11.2 今は考えない
- 複雑なパフォーマンス最適化
- マイクロサービス化
- 高度なセキュリティ
- 大規模なテスト自動化
- 複雑な監視システム

---

## まとめ

**趣味開発の原則**:
1. **まず動くものを作る**
2. **楽しく開発する**
3. **必要になったら改善する**
4. **完璧を求めすぎない**

このスタックで素早くMVPを作って、実際に使いながら改善していく。

**次のアクション**: データモデル設計から始めよう！

---

## 12. 技術的負債管理

### 12.1 許容範囲内の技術的負債
```swift
// 趣味開発だからこそ意識したい技術的負債
許容できる負債:
- 完璧でないテストカバレッジ
- 一部のハードコーディング
- 最適化されていないクエリ

許容できない負債:
- 明らかなメモリリーク
- セキュリティホール
- データ損失リスク
- 基本的なクラッシュ
```

### 12.2 定期レビューポイント
```swift
// 月次で確認することリスト
月1回チェック:
1. アプリサイズ（100MB以下維持）
2. クラッシュ率（1%以下維持）
3. 使わない機能の削除検討
4. Core Dataデータ量（必要に応じてクリーンアップ）

四半期チェック:
1. iOS新バージョン対応検討
2. 非推奨API使用チェック
3. 依存ライブラリ更新
4. パフォーマンス測定
```

## 13. 開発体験（DX）重視

### 13.1 開発効率化ツール
```bash
# 開発を楽にするスクリプト作成
# scripts/dev-tools.sh

# 素早くシミュレーター起動
alias ios-sim="xcrun simctl boot 'iPhone 15' && open -a Simulator"

# プロジェクトクリーンアップ
alias xc-clean="rm -rf ~/Library/Developer/Xcode/DerivedData/*"

# SwiftLint自動修正
alias swift-fix="swiftlint --fix && swiftformat ."

# TestFlight自動アップロード（Fastlane使用時）
alias deploy-beta="fastlane beta"
```

### 13.2 デバッグ支援
```swift
// デバッグを楽にする設定
#if DEBUG
struct DebugSettings {
    static let enableVerboseLogging = true
    static let showCoreDataStats = true
    static let enableCloudKitLogging = true

    // デバッグメニュー表示
    static func showDebugMenu() {
        // Core Dataリセット
        // テストデータ生成
        // CloudKit強制同期
    }
}

// プレビュー用のサンプルデータ
extension Bottle {
    static let sampleData: [Bottle] = [
        // プレビュー用の豊富なサンプルデータ
    ]
}
#endif
```

## 14. エラーハンドリング戦略

### 14.1 ユーザーフレンドリーなエラー
```swift
// 趣味アプリだからこそ、エラーは親切に
enum BottleKeeperError: LocalizedError {
    case coreDataSaveFailure
    case photoTooLarge
    case cloudKitUnavailable

    var errorDescription: String? {
        switch self {
        case .coreDataSaveFailure:
            return "データの保存に失敗しました。アプリを再起動してみてください。"
        case .photoTooLarge:
            return "写真のサイズが大きすぎます。別の写真を選択してください。"
        case .cloudKitUnavailable:
            return "iCloudとの同期ができません。Wi-Fi接続を確認してください。"
        }
    }

    // 復旧の提案も含める
    var recoverySuggestion: String? {
        switch self {
        case .coreDataSaveFailure:
            return "アプリを再起動しても解決しない場合は、フィードバックをお送りください。"
        case .photoTooLarge:
            return "写真アプリで画像を圧縮してから再度お試しください。"
        case .cloudKitUnavailable:
            return "オフラインでもアプリは使用できます。接続が復活したら自動で同期されます。"
        }
    }
}
```

### 14.2 段階的な機能縮退
```swift
// CloudKitが使えなくても諦めない
class GracefulDegradationManager {
    static let shared = GracefulDegradationManager()

    func handleCloudKitFailure() {
        // CloudKit失敗時はローカルのみモードに
        AppSettings.shared.cloudKitEnabled = false
        showUserNotification("オフラインモードで動作しています")
    }

    func handlePhotoSaveFailure() {
        // 写真保存失敗時は基本情報だけ保存
        showUserNotification("写真以外の情報は保存されました")
    }
}
```

---

**文書バージョン**: 1.1（現実版 + プロフェッショナル要素）
**作成日**: 2025-09-23
**最終更新**: 2025-09-23
**作成者**: 現実的な開発者