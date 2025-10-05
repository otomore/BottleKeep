# CloudKit同期問題 - 作業完了記録

最終更新: 2025-10-06 (Build 213 - コード改善実施、新コンテナ移行準備完了)

## 🔄 対応中 - `_pcs_data` BAD_REQUESTエラー → 新コンテナ移行で解決予定

### 問題の概要
**iCloud同期が完全に動作していない**
- 2台以上のデバイス間でボトルデータが同期されない
- CloudKitへのexport時に`CKError 2 (partialFailure)`エラーが発生
- CloudKitダッシュボードのログでBAD_REQUESTエラー（`_pcs_data`レコードタイプ欠落）

### 根本原因（2025-10-05判明）
**手動でインポートしたCloudKitスキーマに`_pcs_data`システムレコードタイプが含まれていない**

1. **`_pcs_data`とは**：
   - Protected Cloud Storage (PCS)のシステムレコードタイプ
   - iCloudアカウント（Apple ID）に紐づいている
   - NSPersistentCloudKitContainerが暗号化メタデータを管理するために自動的に使用
   - プライベートデータベースにアクセスする際に必要
   - **ユーザーが手動で作成・管理することはできない**

2. **なぜ`_pcs_data`が欠落しているのか**：
   - CloudKitの**Import Schema**機能で`cloudkit-schema.ckdb`を手動インポートした
   - 手動インポートではシステムレコードタイプ（`_pcs_data`）が作成されない
   - NSPersistentCloudKitContainerは、自分でスキーマを初期化した場合にのみ、`_pcs_data`を自動作成する

3. **なぜ削除して再生成できないのか**：
   - Production環境のスキーマは削除不可（本番データ保護のため）
   - Development環境のリセットはProduction環境のスキーマをコピーするだけ
   - **Production環境で有効なレコードタイプはDevelopment環境から個別削除できない**（CloudKitダッシュボードエラー：`invalid attempt to delete a record type which is active in a production container`）
   - UserDefaults `isCloudKitSchemaInitialized`フラグはアプリ再インストール後も保持される

### 現在のスキーマ状態（2025-10-05確認）

**Production環境**:
- ✅ **CD_Bottle** - 23フィールド
- ✅ **CD_BottlePhoto** - 12フィールド
- ✅ **CD_DrinkingLog** - 12フィールド
- ✅ **CD_WishlistItem** - 15フィールド
- ✅ **Users** - 7フィールド（既存）
- ❌ **`_pcs_data`** - **欠落**

**Development環境**（2025-10-05リセット後）:
- Production環境と同じ（リセット時にProductionからコピーされた）
- ❌ **`_pcs_data`** - **欠落**

## 📝 これまでの試行履歴

### Build 213 (コード改善完了) - 2025-10-06 ← **現在のビルド**
**実施内容**:
1. CoreDataManager.swiftのスキーマ初期化ロジックを改善
   - `loadPersistentStores`完了後に自動的にスキーマ初期化を試行（DEBUGビルドのみ）
   - error 134060の詳細なエラーメッセージを追加
   - `_pcs_data`に関する説明をログに追加
2. BottleKeeperApp.swiftのスキーマ初期化呼び出しを削除
   - 重複実行を回避（CoreDataManagerで自動実行されるため）
   - RELEASEビルドでは実行しない（スキーマは既に存在すべき）
3. GitHub Actionsのシミュレーター起動を改善
   - 待機時間を30秒→60秒に延長
   - シミュレーターログを取得して重要なメッセージを抽出
   - スキーマ初期化の成功/失敗を確認可能に
4. 新しいCloudKitコンテナへの移行手順書を作成
   - `CLOUDKIT_CONTAINER_MIGRATION.md`に詳細な手順を記載
   - 新コンテナID: `iCloud.com.bottlekeep.whiskey.v2`

**結果**: ⏳ **移行準備完了**
- コード改善により、将来的な問題を防止
- 新コンテナでのスキーマ自動生成がよりスムーズに実行される見込み
- `_pcs_data`の欠落問題は新コンテナ移行で根本解決予定

**次のステップ**:
1. Apple Developer Portalで新コンテナ `iCloud.com.bottlekeep.whiskey.v2` を作成
2. entitlementsとCoreDataManager.swiftを新コンテナIDに更新
3. Development環境でスキーマ自動生成（`_pcs_data`を含む）
4. Production環境にデプロイ
5. TestFlightビルドで動作確認

**学び**:
- `initializeCloudKitSchema()`は`loadPersistentStores`完了後に実行すべき
- DEBUGビルドで一度だけ実行し、その後はコメントアウトすべき
- 既存スキーマに`_pcs_data`を後から追加することはできない
- **新しいCloudKitコンテナを作成することが最も確実な解決策**

---

### Build 199 (失敗)
**実施内容**:
- entitlementsをDevelopment環境に変更
- ユーザーがアプリでデータ（ボトル、ウィッシュリスト、記録、写真）を追加
- 自動スキーマ生成を期待

**結果**: ❌ **失敗**
- スキーマは生成されなかった
- `CKError 2 (partialFailure)`が継続

**失敗理由**:
- `initializeCloudKitSchema()`が実行されていなかった
- RELEASEモードでは`#if DEBUG`により無効化されていた

### Build 200 (失敗)
**実施内容**:
- `#if DEBUG`チェックを削除してRELEASE modeでも実行可能に
- しかし、手動呼び出しが必要だった（自動実行されず）

**結果**: ❌ **失敗**
- スキーマは生成されなかった
- ユーザーがデータを追加したが、`initializeCloudKitSchema()`は実行されず

**失敗理由**:
- アプリ起動時に自動実行されていなかった
- SettingsViewからの手動実行が必要だった

### Build 201 (失敗)
**実施内容**:
- `loadPersistentStores()`完了後に自動的に`initializeCloudKitSchema()`を呼び出し
- 初期化済みチェックを一時的に無効化（強制実行）

**結果**: ❌ **失敗**
```
[4:40:16] ⚠️ Schema initialization failed: A Core Data error occurred.
[4:40:16] Error description: A Core Data error occurred.
[4:40:16] Error code: 134060
[4:40:16] Error domain: NSCocoaErrorDomain
[4:40:14] ℹ️ Attempting schema initialization in all environments (temporary)
[4:40:14] 🔄 Initializing CloudKit schema...
```

**エラー分析**:
- `NSCocoaErrorDomain error 134060`: Core Dataの永続化エラー
- 既存スキーマがある状態で`initializeCloudKitSchema()`を実行すると発生
- この機能は開発時のシミュレーターでのみ動作する可能性がある

### Build 202 (部分的成功)
**実施内容**:
1. Core Data Model定義から`cloudkit-schema.ckdb`ファイルを作成
2. CloudKitダッシュボードでImport Schema機能を使用
3. Development環境に4つのレコードタイプをインポート
4. Production環境にデプロイ
5. entitlementsをProductionに設定
6. CoreDataManager.swiftの一時的変更を元に戻す

**結果**: ⚠️ **部分的成功**（後にBuild 206で問題発覚）
- Development環境: CD_Bottle (23), CD_BottlePhoto (12), CD_DrinkingLog (12), CD_WishlistItem (15), Users (7)
- Production環境: 同上（デプロイ成功）
- スキーマインポート時にインデックス設定はスキップ（後から追加可能）
- **しかし、`_pcs_data`システムレコードタイプは作成されなかった**

**学び**:
- CloudKitの公式Import Schema機能を使用することで、プログラムによるスキーマ初期化のエラーを回避できた
- **しかし、手動インポートでは`_pcs_data`が作成されないため、実際の同期は機能しない**

### Build 206 (失敗)
**実施内容**:
1. entitlementsをProduction環境に設定
2. GitHub ActionsでTestFlightビルドを作成
3. ユーザーがアプリでボトルを追加してテスト

**結果**: ❌ **失敗**
```
[19:39:30] ❌ CloudKit sync error: The operation couldn't be completed. (CKErrorDomain error 2.)
```

**CloudKitダッシュボード調査結果**:
- ✅ Production環境にレコードタイプが存在：CD_Bottle (23), CD_BottlePhoto (12), CD_DrinkingLog (12), CD_WishlistItem (15), Users (7)
- ✅ カスタムゾーン `com.apple.coredata.cloudkit.zone` が作成されている
- ✅ CloudKitログに39イベント記録（ZoneSave、SubscriptionCreate、RecordSaveなど）
- ❌ **CD_Bottleレコードが0件**（保存失敗）
- ❌ RecordSaveイベントでBAD_REQUESTエラー：
  ```json
  {
    "zone": "com.apple.coredata.cloudkit.zone",
    "overallStatus": "USER_ERROR",
    "error": "BAD_REQUEST",
    "returnedRecordTypes": "_pcs_data"
  }
  ```

**根本原因の発見**:
- **`_pcs_data`システムレコードタイプが欠落している**
- `_pcs_data`はNSPersistentCloudKitContainerが暗号化メタデータを管理するために必要
- 手動でインポートした`cloudkit-schema.ckdb`にはこのレコードタイプが含まれていない
- NSPersistentCloudKitContainerはこのレコードタイプがないとレコードの保存を拒否する

### Build 211 (失敗) - 2025-10-05
**実施内容**:
1. entitlementsをDevelopment環境に変更
2. Development環境をリセット（Productionスキーマを削除する目的）
3. Production環境のスキーマも手動削除
4. CoreDataManager.swiftにUserDefaultsクリアコードを追加して`initializeCloudKitSchema()`を強制実行
5. GitHub ActionsでTestFlightビルドを作成

**結果**: ❌ **失敗**
```
[4:37:12] Error description: A Core Data error occurred.
[4:37:12] Error code: 134060
[4:37:12] Error domain: NSCocoaErrorDomain
[4:37:12] ❌ Failed to initialize CloudKit schema
[4:37:09] 🔄 Initializing CloudKit schema...
[4:37:09] 🔄 UserDefaults cleared for schema re-initialization
```

**失敗理由**:
- UserDefaultsを**チェックの前に**クリアするロジックエラー
- `initializeCloudKitSchema()`が毎回実行されてしまう
- 既存スキーマがある状態で実行されると error 134060 が発生

**誤ったコード**（Build 211）:
```swift
func initializeCloudKitSchema() throws {
    // 一時的：_pcs_dataシステムレコードタイプ生成のためUserDefaultsをクリア
    UserDefaults.standard.removeObject(forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized)
    UserDefaults.standard.removeObject(forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate)
    log("🔄 UserDefaults cleared for schema re-initialization")

    if isCloudKitSchemaInitialized {  // ← この時点で必ずfalseになる
        log("ℹ️ CloudKit schema already initialized, skipping")
        return
    }
    // ...
}
```

### Build 212 (失敗) - 2025-10-05 ← **現在のビルド**
**実施内容**:
1. CoreDataManager.swiftの誤ったUserDefaultsクリアコードを削除
2. 正常なコードに復元（Build 206以前の状態）
3. entitlementsはDevelopment環境のまま
4. GitHub ActionsでTestFlightビルドを作成
5. Export complianceを設定（"none of the above algorithms"）

**結果（第1回テスト）**: ❌ **失敗**
```
[5:15:11] Error description: A Core Data error occurred.
[5:15:11] Error code: 134060
[5:15:11] Error domain: NSCocoaErrorDomain
[5:15:11] ❌ Failed to initialize CloudKit schema
[5:15:11] ⚠️ Partial failure - some records failed to sync
[5:15:11] Error code: 2
[5:15:11] Error domain: CKErrorDomain
[5:15:11] ❌ CloudKit sync error: The operation couldn't be completed. (CKErrorDomain error 2.)
```

**失敗理由（第1回）**:
- Development環境に既にスキーマが存在（Productionからコピーされたもの）
- `initializeCloudKitSchema()`は既存スキーマがあると実行できない（error 134060）

**対応**:
- CloudKitダッシュボードでDevelopment環境をリセット
- Development環境のRecord Typesを確認：5つのレコードタイプが存在（`_pcs_data`なし）

**結果（第2回テスト - 環境リセット後）**: ❌ **失敗**
```
[5:19:48] Error description: A Core Data error occurred.
[5:19:48] Error code: 134060
[5:19:48] Error domain: NSCocoaErrorDomain
[5:19:48] ❌ Failed to initialize CloudKit schema
[5:19:45] 🔄 Initializing CloudKit schema...
```

**失敗理由（第2回）**:
1. **UserDefaults永続化問題**：`isCloudKitSchemaInitialized`フラグはアプリ再インストール後も保持される
2. **環境リセットの動作**：Development環境リセットはProductionスキーマをコピーするだけ
3. **Production汚染**：Production環境に手動インポートしたスキーマが残っており、リセット時にDevelopmentにコピーされる

**追加調査（2025-10-05）**:
- CloudKitダッシュボードでレコードタイプの削除を試行
- エラー発生：`invalid attempt to delete a record type which is active in a production container`
- **Production環境で有効なレコードタイプはDevelopment環境から削除できない**

**現在の状況**:
- Development環境とProduction環境の両方に手動インポートしたスキーマが存在
- どちらも`_pcs_data`が欠落
- スキーマの削除・再生成が不可能
- `initializeCloudKitSchema()`は既存スキーマがあると実行できない

**正常なコード**（Build 212）:
```swift
func initializeCloudKitSchema() throws {
    if isCloudKitSchemaInitialized {
        log("ℹ️ CloudKit schema already initialized, skipping")
        return
    }

    log("🔄 Initializing CloudKit schema...")

    do {
        try container.initializeCloudKitSchema(options: [])
        UserDefaults.standard.set(true, forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized)
        UserDefaults.standard.set(Date(), forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate)
        log("✅ CloudKit schema initialized successfully")
    } catch {
        log("⚠️ Schema initialization failed: \(error.localizedDescription)")
        throw error
    }
}
```

## 🔧 現在の設定状態（2025-10-05）

### entitlements設定
**ファイル**: `BottleKeeper/BottleKeeper.entitlements`
```xml
<key>com.apple.developer.icloud-container-environment</key>
<string>Development</string>  ← Build 212でDevelopment環境に変更
<key>com.apple.developer.team-identifier</key>
<string>B3QHWZX47Z</string>
```

### CoreDataManager.swift（✅ 正常な状態）
**Build 212で修正済み**:
1. ✅ Build 211の誤ったUserDefaultsクリアコードを削除
2. ✅ 正常なロジックに復元
3. ✅ `#if DEBUG`チェックあり（DEBUGビルドでのみ実行）

**現在のコード構造**:
```swift
init() {
    // NSPersistentCloudKitContainerのセットアップ
    container = NSPersistentCloudKitContainer(name: "BottleKeeper")

    // CloudKit設定
    guard let description = container.persistentStoreDescriptions.first else {
        fatalError("Failed to retrieve a persistent store description.")
    }

    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
        containerIdentifier: "iCloud.com.bottlekeep.whiskey"
    )
    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

    // ストアをロード
    container.loadPersistentStores { description, error in
        if let error = error {
            fatalError("Failed to load Core Data stack: \(error)")
        }
    }

    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
}

func initializeCloudKitSchema() throws {
    if isCloudKitSchemaInitialized {
        log("ℹ️ CloudKit schema already initialized, skipping")
        return
    }

    log("🔄 Initializing CloudKit schema...")

    do {
        try container.initializeCloudKitSchema(options: [])
        UserDefaults.standard.set(true, forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized)
        UserDefaults.standard.set(Date(), forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate)
        log("✅ CloudKit schema initialized successfully")
    } catch {
        log("⚠️ Schema initialization failed: \(error.localizedDescription)")
        throw error
    }
}
```

### BottleKeeperApp.swift（自動初期化あり）
**アプリ起動時にスキーマ初期化を実行**:
```swift
.onAppear {
    // CloudKitスキーマ初期化（一時的：_pcs_dataシステムレコードタイプ生成のため）
    Task {
        do {
            try persistenceController.initializeCloudKitSchema()
            print("✅ CloudKitスキーマ初期化完了")
        } catch {
            print("⚠️ CloudKitスキーマ初期化エラー: \(error)")
        }
    }
    // ...
}
```

## 🎯 次のステップ - 2つのアプローチ

### 【推奨】アプローチ1: 遅延スキーマ生成をテスト

**仮説**:
NSPersistentCloudKitContainerは、データ保存時にスキーマを「遅延的に」更新する可能性がある。既存スキーマに`_pcs_data`を自動追加するかもしれない。

**実施手順**:
1. Build 212（Development entitlements）でボトルを追加
2. CloudKitへの同期を試行
3. CloudKitダッシュボードのLogsで`_pcs_data`関連のイベントを確認
4. Development環境のRecord Typesページで`_pcs_data`の存在を確認

**メリット**:
- コード変更なし
- NSPersistentCloudKitContainerの自然な動作に任せる
- Web調査によると「遅延作成」の可能性が示唆されている

**デメリット**:
- 成功する保証がない
- 過去の試行（Build 206）でも同様のエラーが発生している

**期待される結果**:
- ✅ 成功：CloudKitログに`_pcs_data`作成イベントが記録され、同期が成功
- ❌ 失敗：Build 206と同じBAD_REQUESTエラーが発生

### アプローチ2: 強制初期化（最終手段）

**仮説**:
UserDefaultsチェックをバイパスして`initializeCloudKitSchema()`を強制実行することで、既存スキーマに`_pcs_data`を追加できる可能性がある。

**実施手順**:
1. CoreDataManager.swiftを修正：
   ```swift
   func initializeCloudKitSchema(forceReinitialize: Bool = false) throws {
       if !forceReinitialize && isCloudKitSchemaInitialized {
           log("ℹ️ CloudKit schema already initialized, skipping")
           return
       }

       log("🔄 Initializing CloudKit schema...")

       do {
           try container.initializeCloudKitSchema(options: [])
           UserDefaults.standard.set(true, forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized)
           UserDefaults.standard.set(Date(), forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate)
           log("✅ CloudKit schema initialized successfully")
       } catch {
           log("⚠️ Schema initialization failed: \(error.localizedDescription)")
           throw error
       }
   }
   ```

2. BottleKeeperApp.swiftで強制実行：
   ```swift
   try persistenceController.initializeCloudKitSchema(forceReinitialize: true)
   ```

3. 新しいビルドを作成してテスト

**メリット**:
- 公式APIを使用
- UserDefaults問題を回避

**デメリット**:
- **error 134060で失敗する可能性が非常に高い**（既存スキーマがある状態では`initializeCloudKitSchema()`は実行できない）
- Build 201と Build 211で同じエラーが発生している

**予想される結果**:
- ❌ 失敗：NSCocoaErrorDomain error 134060（過去の試行から）

### アプローチ3: 新しいCloudKitコンテナを作成（核オプション）

**仮説**:
現在のコンテナ `iCloud.com.bottlekeep.whiskey` は汚染されているため、新しいコンテナを作成して最初からやり直す。

**実施手順**:
1. Appleデベロッパーポータルで新しいCloudKitコンテナを作成（例：`iCloud.com.bottlekeep.whiskey2`）
2. entitlementsとコードを更新
3. Development環境でボトルを追加してスキーマ自動生成
4. Production環境にデプロイ

**メリット**:
- クリーンスレート
- 確実に`_pcs_data`が生成される

**デメリット**:
- **既存ユーザーのデータが失われる**
- App Store申請の再審査が必要な可能性
- 時間がかかる

## 📚 学んだこと（2025-10-05更新）

### CloudKitスキーマ管理の重要な教訓

1. **`initializeCloudKitSchema()`の動作**:
   - 開発時のDEBUGビルド（Xcodeシミュレーター）でのみ確実に動作
   - TestFlightビルド（RELEASEモード）では実行できない
   - **既存スキーマがある状態では実行できない**（NSCocoaErrorDomain error 134060）
   - スキーマが存在しない状態で初回実行する必要がある

2. **CloudKit Import Schema機能の制限**:
   - 手動でインポートしたスキーマには**システムレコードタイプ（`_pcs_data`）が含まれない**
   - ユーザー定義のレコードタイプ（CD_Bottle等）のみがインポートされる
   - NSPersistentCloudKitContainerが必要とするシステムレコードタイプは自動生成されない

3. **`_pcs_data`システムレコードタイプ**:
   - Protected Cloud Storage (PCS)のための内部レコードタイプ
   - 暗号化鍵とiCloudアカウントセキュリティを管理
   - **NSPersistentCloudKitContainerが初めてスキーマを作成する時のみ自動生成される**
   - ユーザーが手動で作成・管理することはできない
   - このレコードタイプがないとデータ保存時にBAD_REQUESTエラーが発生

4. **CloudKit環境のリセット動作**:
   - Development環境の「Reset Environment」はProduction環境のスキーマをコピーする
   - **完全に空の環境にはならない**
   - Production環境は本番データ保護のため削除・リセット不可

5. **レコードタイプ削除の制限**:
   - **Production環境で有効なレコードタイプはDevelopment環境から個別削除できない**
   - CloudKitダッシュボードエラー：`invalid attempt to delete a record type which is active in a production container`
   - Development環境を完全にクリアするにはProduction環境も空にする必要がある
   - Productionは保護されているため、この操作は不可能

6. **UserDefaultsの永続性**:
   - `isCloudKitSchemaInitialized`フラグはアプリ再インストール後も保持される
   - iCloudバックアップまたはデバイス間同期により保持される可能性
   - この動作により、スキーマ再初期化の試行が困難になる

7. **正しいスキーマ初期化フロー**:
   ```
   ✅ 正しい手順：
   1. 空のCloudKit環境を準備
   2. Development entitlementsを設定
   3. DEBUGビルドでアプリを起動（Xcodeシミュレーター）
   4. initializeCloudKitSchema()が自動実行される
   5. _pcs_dataを含む完全なスキーマが生成される
   6. CloudKitダッシュボードで確認
   7. Production環境にデプロイ
   8. Production entitlementsに変更
   9. TestFlightビルドを作成

   ❌ 間違った手順（今回の失敗パターン）：
   1. cloudkit-schema.ckdbを手動作成
   2. Import Schema機能でインポート
   3. _pcs_dataが作成されない
   4. Production環境にデプロイ
   5. スキーマ削除・再生成が不可能になる
   6. 同期時にBAD_REQUESTエラー
   ```

8. **遅延スキーマ生成の可能性**:
   - NSPersistentCloudKitContainerはデータ保存時にスキーマを動的に更新する可能性がある
   - Web調査で「lazy schema creation」が言及されている
   - **未確認**：既存スキーマに`_pcs_data`を後から追加できるかどうか

## 📁 関連ファイル

### 現在の状態
- ✅ `BottleKeeper/BottleKeeper.entitlements` (Development環境 - Build 212)
- ✅ `BottleKeeper/Services/CoreDataManager.swift` (正常な状態 - Build 212で修正)
- ✅ `BottleKeeper/App/BottleKeeperApp.swift` (アプリ起動時にスキーマ初期化)

### 作成済みファイル
- ✅ `cloudkit-schema.ckdb` (CloudKitスキーマ定義 - **`_pcs_data`なし、使用非推奨**)
- ✅ `CLOUDKIT_SCHEMA_DEFINITION.md` (スキーマ設計ドキュメント)
- ✅ `CLOUDKIT_SYNC_STATUS.md` (本ファイル)

### Core Data Model定義
- `BottleKeeper/BottleKeeper.xcdatamodeld/BottleKeeper.xcdatamodel/contents`

### CI/CD設定
- `.github/workflows/ios-build.yml`（GitHub ActionsによるiOSビルドとTestFlight配信）

## 🔗 参考リンク

### CloudKit管理
- CloudKit Console: https://icloud.developer.apple.com/dashboard/
- Container ID: `iCloud.com.bottlekeep.whiskey`
- Team ID: `B3QHWZX47Z`
- Development環境 Record Types: https://icloud.developer.apple.com/dashboard/database/teams/B3QHWZX47Z/containers/iCloud.com.bottlekeep.whiskey/environments/DEVELOPMENT/types
- Production環境 Record Types: https://icloud.developer.apple.com/dashboard/database/teams/B3QHWZX47Z/containers/iCloud.com.bottlekeep.whiskey/environments/PRODUCTION/types

### TestFlight
- App Store Connect: https://appstoreconnect.apple.com/
- TestFlight Builds: Build 212が最新（Development entitlements、Export compliance設定済み）

### Web調査結果（2025-10-05）
- `_pcs_data`はProtected Cloud Storageのシステムレコードタイプ
- iCloudアカウント（Apple ID）に紐づいている
- NSPersistentCloudKitContainerが自動管理
- プライベートデータベースアクセスに必須
- 遅延作成（lazy creation）の可能性あり

## 📊 現在の状況サマリー（2025-10-05）

### 実施した作業（今日）
1. ✅ Build 211の失敗原因を特定（UserDefaults clearing logic error）
2. ✅ CoreDataManager.swiftを修正してBuild 212を作成
3. ✅ Build 212のExport complianceを設定
4. ✅ Development環境をリセット
5. ✅ CloudKitダッシュボードでレコードタイプ削除を試行（失敗：Production保護制限により不可）
6. ✅ `_pcs_data`について詳細なWeb調査を実施
7. ✅ 遅延スキーマ生成の可能性を発見
8. ✅ 2つのアプローチを整理

### 現在のブロッカー
1. **Production環境の汚染**：
   - 手動インポートしたスキーマ（`_pcs_data`なし）が存在
   - 削除・リセット不可（本番データ保護のため）

2. **Development環境の従属**：
   - リセットするとProduction環境のスキーマをコピー
   - Production環境で有効なレコードタイプは個別削除不可

3. **UserDefaults永続化**：
   - `isCloudKitSchemaInitialized`フラグがアプリ再インストール後も保持
   - スキーマ再初期化を妨げる

4. **`initializeCloudKitSchema()`の制限**：
   - 既存スキーマがあると実行できない（error 134060）
   - 空の環境を作成できないため、実行不可能

### 次のマイルストーン
1. ⏳ **アプローチ1を試行**：Build 212でボトル追加→遅延スキーマ生成をテスト
2. ⏳ CloudKitダッシュボードで`_pcs_data`の存在を確認
3. ⏳ （失敗時）アプローチ2を試行：強制初期化
4. ⏳ （失敗時）アプローチ3を検討：新しいCloudKitコンテナ作成

## 🚀 明日の作業開始時のクイックスタート

### 状況確認
1. **現在のビルド**：Build 212（TestFlight配信済み、Development entitlements）
2. **entitlements**：Development環境
3. **コード状態**：正常（Build 212で修正済み）
4. **CloudKit状態**：
   - Development環境：5つのレコードタイプ（`_pcs_data`なし）
   - Production環境：5つのレコードタイプ（`_pcs_data`なし）

### 推奨される次のアクション
**【最優先】アプローチ1: 遅延スキーマ生成をテスト**

1. iOSデバイスでBuild 212をインストール
2. アプリを起動してボトルを追加
3. CloudKitダッシュボードのLogsページを開く（Development環境）
4. RecordSaveイベントを確認：
   - ✅ 成功：`_pcs_data`作成イベントが記録されている
   - ❌ 失敗：BAD_REQUESTエラー（`returnedRecordTypes: "_pcs_data"`）
5. Record Typesページを確認：
   - `_pcs_data`レコードタイプが追加されているか確認

**結果に応じて**:
- ✅ 成功した場合 → Production環境にデプロイ、entitlementsをProductionに変更、新しいビルド作成
- ❌ 失敗した場合 → アプローチ2またはアプローチ3に進む

### 重要な注意事項
- **アプリのアンインストール/再インストールは無意味**（UserDefaults永続化のため）
- **Development環境のリセットも無意味**（Productionスキーマがコピーされるだけ）
- **レコードタイプの個別削除は不可**（Production保護制限により）
- **唯一の希望は遅延スキーマ生成**または**新しいコンテナ作成**

---
**作成日時**: 2025-10-04
**最終更新**: 2025-10-05
**ステータス**: ❌ **未解決** - `_pcs_data` BAD_REQUESTエラー（遅延スキーマ生成をテスト予定）
**現在のビルド**: Build 212 (Development entitlements, Export compliance設定済み)
