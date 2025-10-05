# CloudKitコンテナ移行手順

**作成日**: 2025-10-06
**対象**: `_pcs_data`システムレコードタイプ欠落問題の根本解決

---

## 📋 移行の概要

### 目的
現在のCloudKitコンテナ（`iCloud.com.bottlekeep.whiskey`）には`_pcs_data`システムレコードタイプが欠落しており、手動インポートしたスキーマのため削除・再生成ができません。新しいコンテナを作成してクリーンな状態からスキーマを自動生成します。

### 移行前後のコンテナID

| 項目 | 旧コンテナ | 新コンテナ |
|------|-----------|-----------|
| **Container ID** | `iCloud.com.bottlekeep.whiskey` | `iCloud.com.bottlekeep.whiskey.v2` |
| **スキーマ生成方法** | 手動Import Schema | NSPersistentCloudKitContainer自動生成 |
| **_pcs_data** | ❌ 欠落 | ✅ 自動生成 |
| **データ** | 汚染済み | クリーン |

---

## 🎯 実施手順

### ステップ1: Apple Developer Portalでの新コンテナ作成

1. **Apple Developer Portalにアクセス**
   - https://developer.apple.com
   - Team ID: `B3QHWZX47Z` でログイン

2. **新しいCloudKitコンテナを作成**
   - Certificates, Identifiers & Profiles → Identifiers
   - "+" ボタンをクリック
   - "iCloud Containers" を選択
   - Container ID: `iCloud.com.bottlekeep.whiskey.v2` を入力
   - Description: `BottleKeeper CloudKit Container V2 (Clean Schema)`
   - 「Continue」→「Register」をクリック

3. **App IDにコンテナを追加**
   - App ID: `com.bottlekeep.whiskey` を選択
   - iCloud Capability → 「Edit」
   - 新しいコンテナ `iCloud.com.bottlekeep.whiskey.v2` をチェック
   - 保存

---

### ステップ2: Xcodeプロジェクトの設定更新

#### 2.1 entitlementsファイルの更新

**ファイル**: `BottleKeeper/BottleKeeper.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
	<key>com.apple.developer.icloud-container-environment</key>
	<string>Development</string>
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.com.bottlekeep.whiskey.v2</string>
	</array>
	<key>com.apple.developer.icloud-services</key>
	<array>
		<string>CloudKit</string>
	</array>
	<key>com.apple.developer.team-identifier</key>
	<string>B3QHWZX47Z</string>
</dict>
</plist>
```

**変更点**:
- `iCloud.com.bottlekeep.whiskey` → `iCloud.com.bottlekeep.whiskey.v2`

#### 2.2 CoreDataManager.swiftの更新

**ファイル**: `BottleKeeper/Services/CoreDataManager.swift`

変更箇所（8-9行目付近）:

```swift
private enum CoreDataConstants {
    static let containerName = "BottleKeeper"
    static let cloudKitContainerIdentifier = "iCloud.com.bottlekeep.whiskey.v2"  // ← 変更
    static let maxLogCount = 100
    static let previewSampleCount = 5
    // ...
}
```

**変更点**:
- `cloudKitContainerIdentifier` の値を `"iCloud.com.bottlekeep.whiskey.v2"` に変更

---

### ステップ3: Xcode Signing & Capabilitiesの更新

1. **Xcodeでプロジェクトを開く**
   - `BottleKeeper.xcodeproj` をダブルクリック

2. **Signing & Capabilitiesタブを開く**
   - プロジェクトナビゲーター → `BottleKeeper` プロジェクト
   - `TARGETS` → `BottleKeeper`
   - `Signing & Capabilities` タブ

3. **iCloud Containerを更新**
   - `iCloud` セクションを確認
   - `Containers` リストから `iCloud.com.bottlekeep.whiskey` のチェックを外す
   - `iCloud.com.bottlekeep.whiskey.v2` をチェック

4. **自動署名の更新**
   - Xcodeが自動的にプロビジョニングプロファイルを更新するまで待つ
   - エラーが表示される場合は、`Automatically manage signing` のチェックを一度外してから再度有効化

---

### ステップ4: UserDefaultsのクリア（重要）

**目的**: 既存の`isCloudKitSchemaInitialized`フラグをクリアして、新しいコンテナでスキーマ初期化を許可

#### 4.1 一時的なUserDefaultsクリアコードを追加

**ファイル**: `BottleKeeper/Services/CoreDataManager.swift`

`init(inMemory: Bool = false)` メソッドの最初に以下を追加:

```swift
init(inMemory: Bool = false) {
    // 一時的: 新しいCloudKitコンテナへの移行のためUserDefaultsをクリア
    #if DEBUG
    let containerChanged = UserDefaults.standard.string(forKey: "cloudKitContainerID") != CoreDataConstants.cloudKitContainerIdentifier
    if containerChanged {
        UserDefaults.standard.removeObject(forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized)
        UserDefaults.standard.removeObject(forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate)
        UserDefaults.standard.set(CoreDataConstants.cloudKitContainerIdentifier, forKey: "cloudKitContainerID")
        log("🔄 CloudKit container changed, UserDefaults cleared for new schema initialization")
    }
    #endif

    container = NSPersistentCloudKitContainer(name: CoreDataConstants.containerName)
    // ... 以降のコードはそのまま
}
```

**注意**: この変更は一時的なものです。スキーマ初期化が成功したら、このコードはコメントアウトまたは削除してください。

---

### ステップ5: Development環境でのスキーマ自動生成

#### 5.1 ローカル開発環境でのテスト

1. **Xcodeでシミュレーターを起動**
   - `Product` → `Run` (⌘R)
   - iPhone 16 Pro シミュレーターを選択

2. **アプリを起動してログを確認**
   - Xcodeコンソールで以下のログを確認:
     ```
     ✅ Core Data loaded successfully
     🔄 Attempting automatic schema initialization...
     🔄 Initializing CloudKit schema...
     ℹ️ This creates _pcs_data system record type and user-defined record types
     ✅ CloudKit schema initialized successfully
     ✅ _pcs_data system record type should now be created
     ```

3. **CloudKit Dashboardで確認**
   - https://icloud.developer.apple.com/dashboard/
   - Container: `iCloud.com.bottlekeep.whiskey.v2`
   - Environment: `Development`
   - Schema → Record Types
   - 以下のレコードタイプが存在することを確認:
     - ✅ `CD_Bottle`
     - ✅ `CD_WishlistItem`
     - ✅ `CD_DrinkingLog`
     - ✅ `CD_BottlePhoto`
     - ✅ `_pcs_data` ← **これが重要！**

#### 5.2 GitHub Actionsでの自動生成

1. **変更をコミット**
   ```bash
   git add BottleKeeper/BottleKeeper.entitlements
   git add BottleKeeper/Services/CoreDataManager.swift
   git commit -m "feat: 新しいCloudKitコンテナv2に移行して_pcs_data問題を解決"
   ```

2. **GitHub Actionsを手動実行**
   - GitHub → Actions → "iOS アプリビルド"
   - "Run workflow" → "main" ブランチで実行

3. **ワークフローログを確認**
   - "ユニットテスト実行" ジョブのログで `_pcs_data` 生成を確認

---

### ステップ6: Production環境へのデプロイ

#### 6.1 Development → Productionデプロイ

1. **CloudKit Dashboardにアクセス**
   - https://icloud.developer.apple.com/dashboard/
   - Container: `iCloud.com.bottlekeep.whiskey.v2`
   - Environment: `Development`

2. **スキーマをProductionにデプロイ**
   - "Deploy Schema Changes..." ボタンをクリック
   - 変更内容を確認:
     - CD_Bottle (23 fields)
     - CD_WishlistItem (9 fields)
     - CD_DrinkingLog (6 fields)
     - CD_BottlePhoto (6 fields)
     - _pcs_data (system record type)
   - "Deploy to Production" をクリック

3. **デプロイ完了を待つ**
   - 数分かかる場合があります
   - 完了したら、Production環境で全てのレコードタイプが表示されることを確認

#### 6.2 entitlementsをProductionに変更

**ファイル**: `BottleKeeper/BottleKeeper.entitlements`

```xml
<key>com.apple.developer.icloud-container-environment</key>
<string>Production</string>  <!-- Development → Production に変更 -->
```

---

### ステップ7: TestFlightビルドの作成と配信

1. **ビルド番号を更新**
   - 次のビルド番号（例: Build 213）

2. **GitHub Actionsで自動ビルド**
   ```bash
   git add BottleKeeper/BottleKeeper.entitlements
   git commit -m "chore: Production環境に切り替え (Build 213)"
   git push origin main
   ```

3. **TestFlightでの動作確認**
   - アプリをインストール
   - ボトルを追加
   - CloudKit Dashboardのログを確認
   - エラーがないことを確認

---

## ✅ 成功基準

### スキーマ確認
- [ ] Development環境に5つのレコードタイプが存在（`_pcs_data`を含む）
- [ ] Production環境に5つのレコードタイプが存在（`_pcs_data`を含む）
- [ ] CloudKit Logsに`BAD_REQUEST`エラーが表示されない

### 同期確認
- [ ] 2台のデバイス間でボトルデータが正常に同期される
- [ ] `CKError 2 (partialFailure)`エラーが発生しない
- [ ] ウィッシュリスト、飲酒記録、写真も正常に同期される

---

## 🔄 ロールバック手順（問題が発生した場合）

1. **旧コンテナに戻す**
   - `BottleKeeper.entitlements`: `iCloud.com.bottlekeep.whiskey` に戻す
   - `CoreDataManager.swift`: `cloudKitContainerIdentifier` を戻す

2. **変更をコミット**
   ```bash
   git add .
   git commit -m "revert: 旧CloudKitコンテナに戻す"
   git push origin main
   ```

---

## 📝 注意事項

### データ移行について
- **既存ユーザーのデータは失われます**
- 新しいコンテナはクリーンな状態から開始
- 現在ユーザーが少ない段階での移行を推奨

### 旧コンテナの処理
- 旧コンテナ（`iCloud.com.bottlekeep.whiskey`）は削除せずに残しておく
- 将来的にデータ移行ツールを作成する可能性に備える

### 一時的なコードの削除
- UserDefaultsクリアコード（ステップ4.1）は、スキーマ初期化成功後にコメントアウト
- 次のビルドで完全に削除

---

## 🔗 関連リンク

- CloudKit Console: https://icloud.developer.apple.com/dashboard/
- 新コンテナ（Development）: https://icloud.developer.apple.com/dashboard/database/teams/B3QHWZX47Z/containers/iCloud.com.bottlekeep.whiskey.v2/environments/DEVELOPMENT/types
- 新コンテナ（Production）: https://icloud.developer.apple.com/dashboard/database/teams/B3QHWZX47Z/containers/iCloud.com.bottlekeep.whiskey.v2/environments/PRODUCTION/types

---

**最終更新**: 2025-10-06
**ステータス**: 準備完了 - Apple Developer Portalでのコンテナ作成待ち
