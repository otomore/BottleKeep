# BottleKeep 保守・メンテナンス手順書

## 1. 保守戦略概要

### 1.1 保守方針
- **予防保守**: 定期的な監視・更新による問題予防
- **修正保守**: バグ修正・セキュリティアップデート
- **改善保守**: 新機能追加・パフォーマンス向上
- **適応保守**: iOS新バージョン・新端末対応

### 1.2 保守範囲
```
アプリケーション層:
- iOS App (Swift/SwiftUI)
- Core Data モデル
- CloudKit 連携

インフラ層:
- iCloud Services
- Apple Developer Account
- App Store Connect

開発環境:
- Xcode プロジェクト
- 依存ライブラリ
- CI/CD パイプライン
```

### 1.3 保守サイクル
- **日次**: ログ確認、エラー監視
- **週次**: パフォーマンス確認、ユーザーフィードバック確認、データバックアップ確認
- **月次**: セキュリティアップデート、依存関係更新、データ整合性チェック
- **四半期**: iOS新バージョン対応、機能追加計画、障害対応手順訓練
- **年次**: アーキテクチャ見直し、技術的負債整理、ディザスタリカバリテスト

## 2. 日常監視・保守

### 2.1 App Store Analytics監視

#### 2.1.1 日次確認項目
```
App Store Connect → Analytics:
- ダウンロード数の変化
- クラッシュ率（目標: 1%未満）
- アプリ評価の平均値
- ユーザーレビューの確認
```

#### 2.1.2 アラート基準
```
要注意レベル:
- クラッシュ率 > 2%
- 評価平均 < 3.5
- ダウンロード数が前週比50%減
- ネガティブレビューが連続3件以上

緊急対応レベル:
- クラッシュ率 > 5%
- 評価平均 < 3.0
- セキュリティ関連の報告
- データ消失の報告

### インシデント対応フロー:
1. **検知・報告** (5分以内)
2. **初期対応** (30分以内): 影響範囲の特定
3. **原因調査** (2時間以内): ログ解析、再現テスト
4. **修正対応** (24時間以内): パッチ適用、緊急リリース
5. **事後対応** (1週間以内): 再発防止策、プロセス改善
```

#### 2.1.3 監視スクリプト例
```bash
#!/bin/bash
# app_analytics_check.sh

# App Store Connect API経由でメトリクス取得
API_KEY="your_api_key"
APP_ID="your_app_id"

# クラッシュ率取得
CRASH_RATE=$(curl -H "Authorization: Bearer $API_KEY" \
  "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/betaAppReviewDetails" \
  | jq '.data.attributes.crashRate')

# 基準値チェック
if (( $(echo "$CRASH_RATE > 0.02" | bc -l) )); then
  echo "⚠️ クラッシュ率が基準値を超過: $CRASH_RATE"
  # Slack/メール通知
fi

echo "✅ 日次監視完了 - $(date)"
```

### 2.2 CloudKit同期監視

#### 2.2.1 同期状況確認
```
CloudKit Console → Development → Operations:
- 同期エラー頻度
- データ転送量
- API呼び出し回数
- ストレージ使用量
```

#### 2.2.2 同期問題対応
```swift
// CloudKit同期エラー監視
class CloudKitHealthChecker {
    func checkSyncHealth() async {
        let container = CKContainer.default()

        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                Logger.info("CloudKit: アカウント正常")
            case .noAccount:
                Logger.warning("CloudKit: iCloudアカウントなし")
            case .restricted:
                Logger.error("CloudKit: アクセス制限")
            case .couldNotDetermine:
                Logger.error("CloudKit: 状態不明")
            @unknown default:
                Logger.error("CloudKit: 未知の状態")
            }
        } catch {
            Logger.error("CloudKit: ヘルスチェック失敗 - \(error)")
        }
    }
}
```

### 2.3 パフォーマンス監視

#### 2.3.1 アプリサイズ監視
```bash
# アプリサイズ確認スクリプト
#!/bin/bash

ARCHIVE_PATH="build/BottleKeep.xcarchive"
APP_SIZE=$(du -sh "$ARCHIVE_PATH" | cut -f1)

echo "アプリサイズ: $APP_SIZE"

# 100MBを超えた場合は警告
if [[ $(du -s "$ARCHIVE_PATH" | cut -f1) -gt 100000 ]]; then
  echo "⚠️ アプリサイズが100MBを超過"
fi
```

#### 2.3.2 メモリ使用量確認
```swift
// メモリ使用量監視
extension UIApplication {
    var memoryUsage: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}
```

## 3. 定期メンテナンス

### 3.1 コード品質維持

#### 3.1.1 週次コード監査
```bash
#!/bin/bash
# weekly_code_audit.sh

echo "=== 週次コード監査 開始 ==="

# SwiftLint実行
echo "1. SwiftLint実行中..."
swiftlint > swiftlint_report.txt
if [ $? -eq 0 ]; then
  echo "✅ SwiftLint: 問題なし"
else
  echo "⚠️ SwiftLint: 警告・エラーあり"
  cat swiftlint_report.txt
fi

# TODO/FIXME検出
echo "2. TODO/FIXME検出中..."
grep -r "TODO\|FIXME" BottleKeep/ > todo_report.txt
TODO_COUNT=$(cat todo_report.txt | wc -l)
echo "TODO/FIXME件数: $TODO_COUNT"

# テストカバレッジ確認
echo "3. テストカバレッジ確認中..."
xcodebuild test \
  -scheme BottleKeep \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults

# カバレッジレポート生成
xcrun xccov view --report TestResults/*.xcresult > coverage_report.txt
COVERAGE=$(grep "All targets" coverage_report.txt | awk '{print $3}')
echo "テストカバレッジ: $COVERAGE"

echo "=== 週次コード監査 完了 ==="
```

#### 3.1.2 依存関係更新
```bash
# 月次依存関係更新
#!/bin/bash

echo "=== 依存関係更新チェック ==="

# Xcodeバージョン確認
XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo "現在のXcode: $XCODE_VERSION"

# SwiftLint更新確認
brew outdated swiftlint
if [ $? -eq 0 ]; then
  echo "SwiftLint更新あり"
  read -p "更新しますか？ (y/n): " choice
  if [ "$choice" = "y" ]; then
    brew upgrade swiftlint
  fi
fi

# Swift Package Manager更新
echo "Swift Package依存関係確認中..."
# プロジェクトで使用している場合
# xcodebuild -resolvePackageDependencies

echo "=== 依存関係チェック完了 ==="
```

### 3.2 データベースメンテナンス

#### 3.2.1 Core Data最適化
```swift
// Core Data最適化
class CoreDataMaintenanceService {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    // 不要なデータクリーンアップ
    func performMaintenance() async {
        await container.performBackgroundTask { context in
            // 古い削除マーカーのクリーンアップ
            self.cleanupDeletedRecords(context: context)

            // 孤立した写真データのクリーンアップ
            self.cleanupOrphanedPhotos(context: context)

            // データベース最適化
            self.optimizeDatabase(context: context)
        }
    }

    private func cleanupDeletedRecords(context: NSManagedObjectContext) {
        // CloudKit削除レコードのクリーンアップ
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Bottle")
        request.predicate = NSPredicate(format: "deletedAt != nil AND deletedAt < %@",
                                       Calendar.current.date(byAdding: .day, value: -30, to: Date())!)

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try? context.execute(deleteRequest)
    }

    private func cleanupOrphanedPhotos(context: NSManagedObjectContext) {
        // ボトルに関連付けられていない写真を削除
        let request = NSFetchRequest<PhotoEntity>(entityName: "PhotoEntity")
        request.predicate = NSPredicate(format: "bottle == nil")

        do {
            let orphanedPhotos = try context.fetch(request)
            for photo in orphanedPhotos {
                // ファイルシステムからも削除
                PhotoManager.shared.deletePhoto(fileName: photo.fileName)
                context.delete(photo)
            }
            try context.save()
        } catch {
            Logger.error("孤立写真削除エラー: \(error)")
        }
    }

    private func optimizeDatabase(context: NSManagedObjectContext) {
        // SQLiteデータベース最適化
        do {
            try context.execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "NSPersistentHistoryToken")))
            try context.save()
        } catch {
            Logger.error("データベース最適化エラー: \(error)")
        }
    }
}
```

#### 3.2.2 定期バックアップ検証
```bash
#!/bin/bash
# backup_verification.sh

echo "=== バックアップ検証 開始 ==="

# iCloudバックアップ状況確認
echo "1. iCloudバックアップ状況確認"
# CloudKit Consoleで確認

# エクスポート機能テスト
echo "2. データエクスポート機能テスト"
# 自動テストでエクスポート機能確認

# 復元テスト（テスト環境）
echo "3. データ復元テスト"
# 別端末での復元動作確認

echo "=== バックアップ検証 完了 ==="
```

### 3.3 セキュリティメンテナンス

#### 3.3.1 セキュリティ監査
```bash
#!/bin/bash
# security_audit.sh

echo "=== セキュリティ監査 開始 ==="

# 1. 証明書・プロビジョニングプロファイル確認
echo "1. 証明書有効期限確認"
security find-identity -v -p codesigning | grep "iPhone"

# 2. 依存関係脆弱性チェック
echo "2. 依存関係脆弱性チェック"
# Swift Package Managerを使用している場合
# swift package audit

# 3. API使用状況確認
echo "3. 危険なAPI使用確認"
grep -r "NSString stringWithFormat" BottleKeep/ || echo "✅ 安全でないAPI使用なし"
grep -r "malloc\|free" BottleKeep/ || echo "✅ 手動メモリ管理なし"

# 4. ハードコードされた秘密情報確認
echo "4. 秘密情報ハードコード確認"
grep -r "password\|secret\|api.*key" BottleKeep/ --exclude-dir=docs || echo "✅ 秘密情報なし"

echo "=== セキュリティ監査 完了 ==="
```

#### 3.3.2 プライバシー監査
```swift
// プライバシー関連チェック
class PrivacyAuditService {
    func auditPrivacyCompliance() {
        checkDataCollection()
        checkThirdPartyServices()
        checkUserConsent()
    }

    private func checkDataCollection() {
        // 収集データの確認
        Logger.info("収集データ: ボトル情報、写真、評価")
        Logger.info("保存場所: ローカル + iCloud")
        Logger.info("外部送信: なし")
    }

    private func checkThirdPartyServices() {
        // サードパーティサービス使用確認
        Logger.info("使用サービス: Apple CloudKit のみ")
        Logger.info("分析ツール: なし")
        Logger.info("広告: なし")
    }

    private func checkUserConsent() {
        // ユーザー同意確認
        Logger.info("カメラアクセス: 使用時許可要求")
        Logger.info("写真アクセス: 使用時許可要求")
        Logger.info("位置情報: 使用なし")
    }
}
```

## 4. 障害対応

### 4.1 緊急時対応プロセス

#### 4.1.1 障害分類
```
レベル1 (緊急):
- アプリクラッシュ > 10%
- データ消失報告
- セキュリティ脆弱性
- App Store配信停止

レベル2 (高):
- 特定機能の動作不良
- CloudKit同期障害
- パフォーマンス大幅劣化

レベル3 (中):
- UI不具合
- 軽微な機能問題
- ユーザビリティ問題

レベル4 (低):
- 要望・改善提案
- ドキュメント誤記
```

#### 4.1.2 緊急対応手順
```
1. 問題確認・影響範囲特定 (15分以内)
   - 症状の再現
   - 影響ユーザー数推定
   - 根本原因分析

2. 一次対応 (1時間以内)
   - 回避策の検討・案内
   - App Store レビューでの告知
   - 関係者への報告

3. 修正版開発 (24時間以内)
   - ホットフィックス開発
   - テスト実行
   - 緊急リリース申請

4. 恒久対応 (1週間以内)
   - 根本原因修正
   - 再発防止策実装
   - 監視強化
```

### 4.2 ログ解析・診断

#### 4.2.1 クラッシュログ解析
```bash
#!/bin/bash
# crash_analysis.sh

echo "=== クラッシュログ解析 ==="

# Xcode Organizerからクラッシュログ取得
ORGANIZER_PATH="~/Library/Developer/Xcode/Products"

# 最新のクラッシュログ確認
find "$ORGANIZER_PATH" -name "*.crash" -mtime -7 | while read crashfile; do
  echo "解析中: $crashfile"

  # symbolicate実行
  symbolicatecrash "$crashfile" > "${crashfile}.symbolicated"

  # 共通パターン抽出
  grep -A 5 -B 5 "BottleKeep" "${crashfile}.symbolicated"
done

echo "=== 解析完了 ==="
```

#### 4.2.2 Core Data問題診断
```swift
// Core Data診断ツール
class CoreDataDiagnostics {
    static func runDiagnostics() {
        checkStoreHealth()
        checkMemoryUsage()
        checkSyncStatus()
    }

    static func checkStoreHealth() {
        let context = CoreDataManager.shared.context

        do {
            // エンティティ数確認
            let bottleCount = try context.count(for: Bottle.fetchRequest())
            let photoCount = try context.count(for: PhotoEntity.fetchRequest())

            Logger.info("ボトル数: \(bottleCount)")
            Logger.info("写真数: \(photoCount)")

            // 整合性確認
            let orphanedPhotos = try context.fetch(PhotoEntity.fetchRequest())
                .filter { $0.bottle == nil }

            if !orphanedPhotos.isEmpty {
                Logger.warning("孤立写真検出: \(orphanedPhotos.count)件")
            }

        } catch {
            Logger.error("Core Data診断エラー: \(error)")
        }
    }

    static func checkMemoryUsage() {
        let memoryUsage = UIApplication.shared.memoryUsage
        Logger.info("メモリ使用量: \(memoryUsage / 1024 / 1024)MB")

        if memoryUsage > 500 * 1024 * 1024 { // 500MB超過
            Logger.warning("メモリ使用量が多すぎます")
        }
    }

    static func checkSyncStatus() {
        // CloudKit同期状況確認
        Logger.info("CloudKit同期状況確認中...")
        // 実装...
    }
}
```

### 4.3 データ復旧手順

#### 4.3.1 iCloudからの復旧
```swift
// iCloudデータ復旧
class iCloudRecoveryService {
    func recoverFromiCloud() async throws {
        let container = CKContainer.default()

        // アカウント状況確認
        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            throw RecoveryError.iCloudUnavailable
        }

        // データベース確認
        let database = container.privateCloudDatabase

        // 全ボトルレコード取得
        let query = CKQuery(recordType: "CD_Bottle", predicate: NSPredicate(value: true))
        let results = try await database.records(matching: query)

        Logger.info("iCloudから\(results.matchResults.count)件のボトルを発見")

        // ローカルデータベースに復元
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                try await restoreBottleRecord(record)
            case .failure(let error):
                Logger.error("レコード復元エラー: \(error)")
            }
        }
    }

    private func restoreBottleRecord(_ record: CKRecord) async throws {
        let context = CoreDataManager.shared.context

        await context.perform {
            let bottle = Bottle(context: context)
            bottle.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
            bottle.name = record["name"] as? String ?? ""
            bottle.distillery = record["distillery"] as? String ?? ""
            // ... 他のフィールド復元

            try? context.save()
        }
    }
}
```

#### 4.3.2 エクスポートファイルからの復旧
```swift
// CSVからのデータ復旧
class CSVRecoveryService {
    func recoverFromCSV(_ csvData: Data) throws {
        let csvString = String(data: csvData, encoding: .utf8) ?? ""
        let lines = csvString.components(separatedBy: .newlines)

        guard lines.count > 1 else {
            throw RecoveryError.invalidCSVFormat
        }

        let headers = lines[0].components(separatedBy: ",")
        let context = CoreDataManager.shared.context

        context.performAndWait {
            for line in lines.dropFirst() {
                guard !line.isEmpty else { continue }

                let values = line.components(separatedBy: ",")
                guard values.count == headers.count else { continue }

                let bottle = Bottle(context: context)

                for (index, header) in headers.enumerated() {
                    let value = values[index].trimmingCharacters(in: .whitespacesAndNewlines)

                    switch header {
                    case "ボトル名":
                        bottle.name = value
                    case "蒸留所":
                        bottle.distillery = value
                    case "地域":
                        bottle.region = value.isEmpty ? nil : value
                    // ... 他のフィールド
                    default:
                        break
                    }
                }

                bottle.id = UUID()
                bottle.createdAt = Date()
                bottle.updatedAt = Date()
            }

            try? context.save()
        }
    }
}
```

## 5. パフォーマンス最適化

### 5.1 定期パフォーマンス測定

#### 5.1.1 ベンチマークテスト
```swift
// パフォーマンステスト
class PerformanceBenchmark {
    func runBenchmarks() {
        measureBottleListLoad()
        measureImageLoading()
        measureSearchPerformance()
        measureCoreDataOperations()
    }

    func measureBottleListLoad() {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 1000件のボトルロード測定
        Task {
            let bottles = try await BottleRepository().fetchAllBottles()
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            Logger.info("ボトルリスト読み込み(\(bottles.count)件): \(timeElapsed)秒")

            if timeElapsed > 2.0 {
                Logger.warning("ボトルリスト読み込みが遅い")
            }
        }
    }

    func measureImageLoading() {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 50枚の画像読み込み測定
        for i in 0..<50 {
            _ = PhotoManager.shared.loadThumbnail(fileName: "test_\(i).jpg")
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        Logger.info("画像読み込み(50枚): \(timeElapsed)秒")
    }

    func measureSearchPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()

        Task {
            let results = try await BottleRepository().searchBottles(query: "test")
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            Logger.info("検索処理(\(results.count)件): \(timeElapsed)秒")
        }
    }
}
```

#### 5.1.2 メモリプロファイリング
```bash
#!/bin/bash
# memory_profiling.sh

echo "=== メモリプロファイリング ==="

# Instrumentsでメモリリーク検出
instruments -t "Leaks" \
  -D memory_profile.trace \
  -l 60000 \
  ~/Library/Developer/Xcode/DerivedData/BottleKeep-*/Build/Products/Debug-iphonesimulator/BottleKeep.app

# 結果解析
echo "メモリプロファイル完了: memory_profile.trace"
```

### 5.2 最適化実装

#### 5.2.1 画像最適化
```swift
// 画像最適化マネージャー
class OptimizedPhotoManager {
    private let imageCache = NSCache<NSString, UIImage>()
    private let thumbnailCache = NSCache<NSString, UIImage>()

    init() {
        // メモリ制限設定
        imageCache.countLimit = 50  // 最大50枚
        thumbnailCache.countLimit = 200  // 最大200枚

        // メモリ警告時のクリア
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCaches),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    func loadImage(fileName: String) async -> UIImage? {
        // キャッシュ確認
        if let cachedImage = imageCache.object(forKey: fileName as NSString) {
            return cachedImage
        }

        // ファイルから読み込み
        guard let image = await loadFromFile(fileName: fileName) else {
            return nil
        }

        // キャッシュに保存
        imageCache.setObject(image, forKey: fileName as NSString)
        return image
    }

    func loadThumbnail(fileName: String) async -> UIImage? {
        let thumbnailKey = "thumb_\(fileName)" as NSString

        // サムネイルキャッシュ確認
        if let thumbnail = thumbnailCache.object(forKey: thumbnailKey) {
            return thumbnail
        }

        // オリジナル画像からサムネイル生成
        guard let originalImage = await loadImage(fileName: fileName) else {
            return nil
        }

        let thumbnail = originalImage.resized(to: CGSize(width: 100, height: 100))
        thumbnailCache.setObject(thumbnail, forKey: thumbnailKey)

        return thumbnail
    }

    @objc private func clearCaches() {
        imageCache.removeAllObjects()
        thumbnailCache.removeAllObjects()
        Logger.info("メモリ警告によりキャッシュクリア")
    }
}
```

#### 5.2.2 Core Data最適化
```swift
// Core Data最適化
extension BottleRepository {
    // バッチ処理での効率的な操作
    func batchUpdateBottles(_ updates: [(UUID, [String: Any])]) async throws {
        let context = CoreDataManager.shared.context

        try await context.perform {
            for (bottleId, updateData) in updates {
                let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", bottleId as CVarArg)
                request.fetchLimit = 1

                guard let bottle = try context.fetch(request).first else { continue }

                // バッチ更新
                for (key, value) in updateData {
                    bottle.setValue(value, forKey: key)
                }
            }

            try context.save()
        }
    }

    // ページング対応の効率的な取得
    func fetchBottlesPaginated(offset: Int, limit: Int) async throws -> [Bottle] {
        let context = CoreDataManager.shared.context

        return try await context.perform {
            let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Bottle.updatedAt, ascending: false)
            ]
            request.fetchOffset = offset
            request.fetchLimit = limit
            request.fetchBatchSize = limit

            return try context.fetch(request)
        }
    }
}
```

## 6. 長期保守計画

### 6.1 技術的負債管理

#### 6.1.1 コード負債追跡
```bash
#!/bin/bash
# technical_debt_tracking.sh

echo "=== 技術的負債レポート ==="

# TODO/FIXME件数追跡
TODO_COUNT=$(grep -r "TODO" BottleKeep/ | wc -l)
FIXME_COUNT=$(grep -r "FIXME" BottleKeep/ | wc -l)
HACK_COUNT=$(grep -r "HACK" BottleKeep/ | wc -l)

echo "TODO: $TODO_COUNT件"
echo "FIXME: $FIXME_COUNT件"
echo "HACK: $HACK_COUNT件"

# 複雑度測定（概算）
LARGE_FILES=$(find BottleKeep/ -name "*.swift" -exec wc -l {} + | awk '$1 > 300 {print $2}' | wc -l)
echo "大きなファイル(300行超): $LARGE_FILES件"

# 循環依存チェック
echo "循環依存チェック実行中..."
# カスタムスクリプトまたはツール使用

echo "=== レポート完了 ==="
```

#### 6.1.2 アーキテクチャ進化計画
```
年次レビュー項目:
1. Swift新バージョンへの移行
2. iOS新機能の活用検討
3. 廃止予定APIの置き換え
4. パフォーマンス改善
5. セキュリティ強化

例: 2026年計画
- Swift 6.0移行
- iOS 19新機能対応
- Core Data → SwiftData移行検討
- CloudKit新機能活用
```

### 6.2 ドキュメント保守

#### 6.2.1 ドキュメント更新チェック
```bash
#!/bin/bash
# docs_maintenance.sh

echo "=== ドキュメント保守チェック ==="

# コードとドキュメントの同期確認
echo "1. API変更確認"
git log --since="1 month ago" --grep="API" --oneline

# 古いドキュメント検出
echo "2. 古いドキュメント検出"
find docs/ -name "*.md" -mtime +90 | while read file; do
  echo "更新検討: $file (90日以上未更新)"
done

# リンク切れチェック
echo "3. リンク切れチェック"
find docs/ -name "*.md" -exec grep -l "http" {} \; | while read file; do
  echo "リンクチェック対象: $file"
done

echo "=== ドキュメント保守完了 ==="
```

### 6.3 引き継ぎ準備

#### 6.3.1 知識ベース整理
```
必要な引き継ぎドキュメント:
1. アーキテクチャ概要
2. 重要な設計判断の経緯
3. 既知の問題・制限事項
4. 運用手順・チェックリスト
5. 緊急時対応手順
6. 外部サービス・アカウント情報
```

#### 6.3.2 自動化の強化
```yaml
# 保守作業の自動化拡張
name: Weekly Maintenance

on:
  schedule:
    - cron: '0 9 * * 1'  # 毎週月曜日9時

jobs:
  maintenance:
    runs-on: macos-latest
    steps:
    - name: Code Quality Check
      run: ./scripts/weekly_code_audit.sh

    - name: Security Audit
      run: ./scripts/security_audit.sh

    - name: Performance Benchmark
      run: ./scripts/performance_benchmark.sh

    - name: Documentation Update Check
      run: ./scripts/docs_maintenance.sh

    - name: Generate Maintenance Report
      run: ./scripts/generate_maintenance_report.sh

    - name: Send Report
      uses: 8398a7/action-slack@v3
      with:
        status: custom
        custom_payload: |
          {
            text: "週次メンテナンス完了",
            attachments: [{
              color: "good",
              fields: [{
                title: "レポート",
                value: "詳細はArtifactsを確認"
              }]
            }]
          }
```

---

## 7. 高度な監視・アラート設定

### 7.1 App Store Connect API自動監視
```swift
// App Store Connect API監視サービス
class AppStoreMonitoringService {
    private let apiKey: String
    private let alertThresholds = AppStoreAlertThresholds()

    func performDailyCheck() async {
        await checkCrashRates()
        await checkReviewSentiment()
        await checkDownloadTrends()
        await checkRevenueTrends()
    }

    private func checkCrashRates() async {
        do {
            let crashData = try await fetchCrashRates()

            if crashData.crashRate > alertThresholds.maxCrashRate {
                await sendAlert(.highCrashRate(crashData.crashRate))
            }

            if crashData.hasNewCrashPatterns {
                await sendAlert(.newCrashPattern(crashData.topCrashes))
            }
        } catch {
            Logger.error("クラッシュ率監視エラー: \(error)")
        }
    }

    private func checkReviewSentiment() async {
        do {
            let reviews = try await fetchRecentReviews()
            let negativeSentimentCount = reviews.filter { $0.rating <= 2 }.count

            if negativeSentimentCount >= 3 {
                await sendAlert(.negativeReviewSpike(negativeSentimentCount))
            }
        } catch {
            Logger.error("レビュー監視エラー: \(error)")
        }
    }
}

struct AppStoreAlertThresholds {
    let maxCrashRate: Double = 0.02  // 2%
    let maxNegativeReviews: Int = 3
    let minDownloadChangeThreshold: Double = -0.5  // 50%減
}
```

### 7.2 リアルタイムパフォーマンス監視
```swift
// リアルタイムパフォーマンス監視
class RealTimePerformanceMonitor {
    private let metricsCollector = MetricsCollector()
    private let alertManager = AlertManager()

    func startMonitoring() {
        // アプリ起動時間監視
        monitorAppLaunchTime()

        // メモリ使用量監視
        monitorMemoryUsage()

        // Core Data操作時間監視
        monitorDatabasePerformance()

        // ネットワーク応答時間監視
        monitorNetworkPerformance()
    }

    private func monitorAppLaunchTime() {
        let startTime = CFAbsoluteTimeGetCurrent()

        // アプリ完全起動時
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let launchTime = CFAbsoluteTimeGetCurrent() - startTime

            self.metricsCollector.recordLaunchTime(launchTime)

            if launchTime > 3.0 {
                self.alertManager.sendPerformanceAlert(.slowLaunch(launchTime))
            }
        }
    }

    private func monitorMemoryUsage() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let memoryUsage = UIApplication.shared.memoryUsage
            let memoryUsageMB = Double(memoryUsage) / 1024.0 / 1024.0

            self.metricsCollector.recordMemoryUsage(memoryUsageMB)

            if memoryUsageMB > 200.0 { // 200MB超過
                self.alertManager.sendPerformanceAlert(.highMemoryUsage(memoryUsageMB))
            }
        }
    }
}
```

### 7.3 セキュリティインシデント対応強化
```swift
// セキュリティインシデント検知・対応
class SecurityIncidentHandler {
    private let incidentLogger = SecurityLogger()

    func detectSecurityAnomalies() {
        // 異常なアクセスパターン検知
        detectAbnormalAccessPatterns()

        // 不正なデータ操作検知
        detectUnauthorizedDataOperations()

        // システム改ざん検知
        detectSystemTampering()
    }

    private func detectAbnormalAccessPatterns() {
        // 短時間での大量データアクセス
        let recentOperations = getRecentDatabaseOperations()

        if recentOperations.count > 1000 && recentOperations.timeSpan < 60 {
            reportSecurityIncident(.suspiciousDataAccess(
                operationCount: recentOperations.count,
                timeSpan: recentOperations.timeSpan
            ))
        }
    }

    private func detectSystemTampering() {
        // アプリバンドルの整合性確認
        guard verifyAppIntegrity() else {
            reportSecurityIncident(.appIntegrityViolation)
            return
        }

        // Jailbreak検知
        if isJailbroken() {
            reportSecurityIncident(.jailbreakDetected)
        }
    }

    private func reportSecurityIncident(_ incident: SecurityIncident) {
        incidentLogger.log(incident)

        // 緊急時はアプリ機能制限
        if incident.severity == .critical {
            AppSecurity.enableRestrictedMode()
        }
    }
}

enum SecurityIncident {
    case suspiciousDataAccess(operationCount: Int, timeSpan: TimeInterval)
    case appIntegrityViolation
    case jailbreakDetected
    case unauthorizedDataExport

    var severity: SecuritySeverity {
        switch self {
        case .suspiciousDataAccess:
            return .medium
        case .appIntegrityViolation, .jailbreakDetected:
            return .critical
        case .unauthorizedDataExport:
            return .high
        }
    }
}
```

### 7.4 自動修復・自己回復機能
```swift
// 自動修復システム
class AutoRecoverySystem {
    func performHealthCheck() async {
        await checkAndRepairDatabaseIntegrity()
        await checkAndRepairCloudKitSync()
        await checkAndRepairFileSystemIssues()
        await checkAndRepairUserPreferences()
    }

    private func checkAndRepairDatabaseIntegrity() async {
        do {
            let diagnostics = try await CoreDataDiagnostics.runFullDiagnostics()

            if diagnostics.hasIntegrityIssues {
                Logger.warning("データベース整合性問題を検出、自動修復を開始")
                try await repairDatabaseIntegrity(issues: diagnostics.issues)
                Logger.info("データベース自動修復完了")
            }
        } catch {
            Logger.error("データベース診断・修復エラー: \(error)")
        }
    }

    private func checkAndRepairCloudKitSync() async {
        let cloudKitManager = CloudKitManager.shared

        do {
            let syncStatus = try await cloudKitManager.checkSyncHealth()

            if syncStatus.hasStuckOperations {
                Logger.warning("CloudKit同期スタック検出、リセットを実行")
                try await cloudKitManager.resetStuckSyncOperations()
                Logger.info("CloudKit同期リセット完了")
            }
        } catch {
            Logger.error("CloudKit同期修復エラー: \(error)")
        }
    }
}
```

---

**文書バージョン**: 1.1
**作成日**: 2025-09-21
**最終更新**: 2025-09-23
**作成者**: 個人プロジェクト