# CloudKitコンテナ移行手順（Macなし環境）

**作成日**: 2025-10-06
**対象**: Windows環境（Mac・Xcodeなし）での`_pcs_data`問題解決

---

## 🎯 Macなし環境での実現方法

### 利用するツール
- ✅ **Webブラウザ** - Apple Developer Portal操作
- ✅ **テキストエディタ** - コードファイル編集（VS Code推奨）
- ✅ **GitHub Actions** - ビルド＋シミュレーター起動＋スキーマ初期化
- ✅ **TestFlight** - 実機での動作確認

### できないこと
- ❌ Xcodeでの直接ビルド
- ❌ ローカルシミュレーターでのテスト
- ❌ Xcode GUIでのSigning & Capabilities設定

### 回避策
- GitHub Actionsのシミュレーター起動機能を活用
- すべての設定をファイル編集で実施
- プロビジョニングプロファイルはWebポータルで管理

---

## 📋 実施手順

### ステップ1: Apple Developer Portalで新コンテナ作成

#### 1.1 ブラウザでログイン
1. https://developer.apple.com にアクセス
2. Team ID: `B3QHWZX47Z` でログイン
3. **Certificates, Identifiers & Profiles** をクリック

#### 1.2 新しいiCloud Containerを作成
1. 左メニュー → **Identifiers**
2. 右上の **+ ボタン** をクリック
3. **iCloud Containers** を選択 → **Continue**
4. 以下を入力：
   - Description: `BottleKeeper CloudKit Container V2`
   - Identifier: `iCloud.com.bottlekeep.whiskey.v2`
5. **Continue** → **Register** をクリック

#### 1.3 App IDにコンテナを追加
1. **Identifiers** → App IDs
2. `com.bottlekeep.whiskey` を検索して選択
3. **Capabilities** セクションを確認
4. **iCloud** が有効になっていることを確認
5. **Edit** をクリック
6. **CloudKit** の横の **Configure** をクリック
7. `iCloud.com.bottlekeep.whiskey.v2` をチェック
8. **Continue** → **Save** をクリック

---

### ステップ2: プロビジョニングプロファイルを更新

#### 2.1 既存プロファイルの確認
1. **Certificates, Identifiers & Profiles** → **Profiles**
2. `BottleKeeper Distribution` または `BottleKeep Distribution` を検索
3. 現在のプロファイルをクリックして詳細を確認

#### 2.2 新しいプロファイルを作成（推奨）

**なぜ新規作成が推奨か**:
- iCloud Containerの追加は、プロファイルの再生成が必要
- 既存プロファイルの編集は複雑になる可能性

**手順**:
1. **Profiles** → 右上の **+ ボタン**
2. **Distribution** → **App Store Connect** を選択 → **Continue**
3. App ID: `com.bottlekeep.whiskey` を選択 → **Continue**
4. Certificate: 既存のDistribution証明書を選択 → **Continue**
5. Profile Name: `BottleKeeper Distribution V2` を入力
6. **Generate** をクリック
7. **Download** をクリック（`.mobileprovision`ファイル）

#### 2.3 プロファイルをBase64エンコード

**Windows PowerShellで実行**:
```powershell
# ダウンロードしたプロファイルのパスを指定
$profilePath = "C:\Users\Yuto\Downloads\BottleKeeper_Distribution_V2.mobileprovision"

# Base64エンコード
$bytes = [System.IO.File]::ReadAllBytes($profilePath)
$base64 = [Convert]::ToBase64String($bytes)

# 結果をクリップボードにコピー
$base64 | Set-Clipboard

# または、ファイルに保存
$base64 | Out-File -FilePath "C:\Users\Yuto\Downloads\profile_base64.txt" -Encoding ASCII

Write-Host "✅ Base64エンコード完了！クリップボードにコピーされました"
```

#### 2.4 GitHub Secretsを更新

1. **GitHubリポジトリ** → **Settings** → **Secrets and variables** → **Actions**
2. 既存の `BUILD_PROVISION_PROFILE_BASE64` を見つける
3. **Update** をクリック
4. PowerShellでコピーしたBase64文字列を貼り付け
5. **Update secret** をクリック

**重要**: 秘密鍵（.p12ファイル）は変更不要です。プロファイルのみ更新すればOKです。

---

### ステップ3: コードファイルを編集

#### 3.1 entitlementsファイルの更新

**ファイル**: `BottleKeeper/BottleKeeper.entitlements`

**現在の内容**:
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.bottlekeep.whiskey</string>
</array>
```

**変更後**:
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.bottlekeep.whiskey.v2</string>
</array>
```

#### 3.2 CoreDataManager.swiftの更新

**ファイル**: `BottleKeeper/Services/CoreDataManager.swift`

**現在のコード（8行目付近）**:
```swift
private enum CoreDataConstants {
    static let containerName = "BottleKeeper"
    static let cloudKitContainerIdentifier = "iCloud.com.bottlekeep.whiskey"
```

**変更後**:
```swift
private enum CoreDataConstants {
    static let containerName = "BottleKeeper"
    static let cloudKitContainerIdentifier = "iCloud.com.bottlekeep.whiskey.v2"
```

#### 3.3 一時的なUserDefaultsクリアコードを追加

**ファイル**: `BottleKeeper/Services/CoreDataManager.swift`

**`init(inMemory: Bool = false)` メソッドの最初に追加**:

```swift
init(inMemory: Bool = false) {
    // 一時的: 新しいCloudKitコンテナへの移行のためUserDefaultsをクリア
    #if DEBUG
    let currentContainerID = UserDefaults.standard.string(forKey: "cloudKitContainerID")
    let expectedContainerID = CoreDataConstants.cloudKitContainerIdentifier

    if currentContainerID != expectedContainerID {
        UserDefaults.standard.removeObject(forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized)
        UserDefaults.standard.removeObject(forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate)
        UserDefaults.standard.set(expectedContainerID, forKey: "cloudKitContainerID")
        log("🔄 CloudKit container changed to \(expectedContainerID)")
        log("🔄 UserDefaults cleared for new schema initialization")
    }
    #endif

    container = NSPersistentCloudKitContainer(name: CoreDataConstants.containerName)
    // ... 既存のコードはそのまま
}
```

**注意**: スキーマ初期化が成功したら、このコードはコメントアウトしてください。

---

### ステップ4: ExportOptions.plistの更新（オプション）

**ファイル**: `ExportOptions.plist`

プロファイル名を変更した場合は、ExportOptions.plistも更新が必要です。

**変更箇所（49行目付近）**:
```xml
<key>provisioningProfiles</key>
<dict>
    <key>com.bottlekeep.whiskey</key>
    <string>BottleKeeper Distribution V2</string>  <!-- 新しいプロファイル名 -->
</dict>
```

**注意**: GitHub Actionsのワークフローが動的に生成するため、変更不要な場合もあります。

---

### ステップ5: 変更をコミット＆プッシュ

```bash
# 変更されたファイルを確認
git status

# 個別にステージング
git add BottleKeeper/BottleKeeper.entitlements
git add BottleKeeper/Services/CoreDataManager.swift

# コミット
git commit -m "feat: 新しいCloudKitコンテナv2に移行（iCloud.com.bottlekeep.whiskey.v2）

- entitlementsを新コンテナIDに更新
- CoreDataManagerのcontainerIdentifierを更新
- UserDefaultsクリアロジックを追加（一時的）
- プロビジョニングプロファイルをV2に更新

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# GitHubにプッシュ
git push origin main
```

---

### ステップ6: GitHub Actionsでスキーマ自動生成

#### 6.1 ワークフローが自動実行される
- `git push`すると、GitHub Actionsが自動的に起動
- `ios-build.yml`の"ユニットテスト実行"ジョブが実行される

#### 6.2 ワークフローログを確認

1. **GitHub** → **Actions**タブ
2. 最新のワークフロー実行をクリック
3. **ユニットテスト実行** ジョブをクリック
4. 以下のログを探す：

```
🔨 DEBUG ビルドでシミュレーターにインストール中...
📱 シミュレーターを起動中...
📦 アプリをインストール中...
🚀 アプリを起動中（CloudKitスキーマ初期化のため）...
⏳ CloudKitスキーマ初期化完了を待機中（60秒）...
📋 シミュレーターログから重要なメッセージを抽出中...
=== スキーマ初期化関連ログ ===
✅ Core Data loaded successfully
🔄 CloudKit container changed to iCloud.com.bottlekeep.whiskey.v2
🔄 UserDefaults cleared for new schema initialization
🔄 Attempting automatic schema initialization...
🔄 Initializing CloudKit schema...
ℹ️ This creates _pcs_data system record type and user-defined record types
✅ CloudKit schema initialized successfully
✅ _pcs_data system record type should now be created
✅ CD_Bottle, CD_WishlistItem, CD_DrinkingLog, CD_BottlePhoto record types created
```

**✅ 成功の兆候**:
- `CloudKit schema initialized successfully`
- エラーメッセージがない

**❌ 失敗の兆候**:
- `Error 134060` → 既存スキーマがまだ存在している
- `iCloud not available` → iCloud設定の問題

#### 6.3 失敗した場合の対処法

**Error 134060が出た場合**:
- Development環境に旧スキーマが残っている可能性
- CloudKit Dashboardで手動削除を試みる
- または、次のステップに進んでProduction環境を確認

---

### ステップ7: CloudKit Dashboardで確認

#### 7.1 Development環境を確認

1. https://icloud.developer.apple.com/dashboard/ にアクセス
2. Container: `iCloud.com.bottlekeep.whiskey.v2` を選択
3. Environment: **Development**
4. **Schema** → **Record Types**

**確認項目**:
- [ ] CD_Bottle
- [ ] CD_WishlistItem
- [ ] CD_DrinkingLog
- [ ] CD_BottlePhoto
- [ ] **_pcs_data** ← **これが最重要！**

#### 7.2 各レコードタイプのフィールド数を確認

| レコードタイプ | フィールド数 |
|--------------|------------|
| CD_Bottle | 23 |
| CD_WishlistItem | 9 |
| CD_DrinkingLog | 6 |
| CD_BottlePhoto | 6 |
| _pcs_data | システム管理 |

#### 7.3 スクリーンショットを撮る

**記録すべき画面**:
1. Record Types一覧（5つのレコードタイプが表示されている）
2. `_pcs_data`の詳細ページ（存在することの証明）

---

### ステップ8: Production環境にデプロイ

#### 8.1 CloudKit Dashboardでデプロイ

1. Container: `iCloud.com.bottlekeep.whiskey.v2`
2. Environment: **Development**
3. **Deploy Schema Changes...** ボタンをクリック
4. 変更内容を確認：
   ```
   - CD_Bottle (23 fields)
   - CD_WishlistItem (9 fields)
   - CD_DrinkingLog (6 fields)
   - CD_BottlePhoto (6 fields)
   - _pcs_data (system record type)
   ```
5. **Deploy to Production** をクリック
6. 確認ダイアログで **Deploy** をクリック

#### 8.2 デプロイ完了を待つ

- 通常、数分で完了
- **Schema** → **Deployment History**で進捗確認可能

#### 8.3 Production環境で確認

1. Environment: **Production** に切り替え
2. **Schema** → **Record Types**
3. Development環境と同じ5つのレコードタイプが存在することを確認

---

### ステップ9: entitlementsをProductionに変更

#### 9.1 ファイル編集

**ファイル**: `BottleKeeper/BottleKeeper.entitlements`

**変更箇所**:
```xml
<key>com.apple.developer.icloud-container-environment</key>
<string>Production</string>  <!-- Development → Production に変更 -->
```

#### 9.2 コミット＆プッシュ

```bash
git add BottleKeeper/BottleKeeper.entitlements
git commit -m "chore: CloudKit環境をProductionに切り替え (Build 214)"
git push origin main
```

---

### ステップ10: TestFlightビルドの作成

#### 10.1 GitHub Actionsが自動ビルド

- `git push`すると自動的にビルドが開始
- **deploy-testflight** ジョブがTestFlightにアップロード

#### 10.2 App Store Connectで確認

1. https://appstoreconnect.apple.com にアクセス
2. **My Apps** → **BottleKeeper**
3. **TestFlight** タブ
4. 新しいビルド（Build 214）が表示されるまで待つ（5-10分）

#### 10.3 Export Complianceを設定（必要な場合）

- App Store Connectでビルドの詳細を開く
- Export Compliance: **None of the algorithms mentioned above**
- 保存

---

### ステップ11: TestFlightで動作確認

#### 11.1 アプリをインストール

1. iOSデバイスでTestFlightアプリを開く
2. Build 214をインストール
3. アプリを起動

#### 11.2 CloudKit同期をテスト

**テスト1: ボトル追加**
1. 新しいボトルを追加
2. Settings → CloudKit診断情報を確認
3. ログに`✅ CloudKit schema initialized successfully`が表示されることを確認

**テスト2: CloudKitログを確認**
1. https://icloud.developer.apple.com/dashboard/
2. Container: `iCloud.com.bottlekeep.whiskey.v2`
3. Environment: **Production**
4. **Logs** タブ
5. 最近のイベントを確認：
   - ✅ RecordSave イベントが成功している
   - ❌ `BAD_REQUEST`エラーが**ない**
   - ❌ `_pcs_data`関連のエラーが**ない**

**テスト3: 2台のデバイス間で同期**
1. デバイス1でボトルを追加
2. デバイス2でアプリを起動
3. 数分待つ（CloudKitの同期には時間がかかる）
4. デバイス2でボトルが表示されることを確認

---

## ✅ 成功基準

### 必須項目
- [ ] Development環境に`_pcs_data`が存在
- [ ] Production環境に`_pcs_data`が存在
- [ ] GitHub Actionsのビルドが成功
- [ ] TestFlightでアプリが起動
- [ ] CloudKitログにエラーがない

### 理想的な結果
- [ ] 2台のデバイス間でボトルが同期される
- [ ] ウィッシュリスト、飲酒記録、写真も同期される
- [ ] `CKError 2 (partialFailure)`エラーが発生しない

---

## 🔧 トラブルシューティング

### Q1: プロビジョニングプロファイルのビルドエラー

**エラーメッセージ**:
```
error: Provisioning profile "BottleKeeper Distribution" doesn't include the iCloud.com.bottlekeep.whiskey.v2 iCloud container entitlement.
```

**解決策**:
1. ステップ2に戻ってプロファイルを再作成
2. 新しいコンテナが確実にチェックされていることを確認
3. GitHub Secretsを正しく更新

### Q2: GitHub Actionsでスキーマ初期化が失敗（Error 134060）

**原因**:
- Development環境に旧スキーマが残っている

**解決策**:
1. CloudKit Dashboard → Development環境
2. Record Typesを手動削除（可能であれば）
3. または、Environment Resetを試行

### Q3: `_pcs_data`が生成されない

**原因**:
- UserDefaultsがクリアされていない
- スキーマ初期化が実行されていない

**解決策**:
1. CoreDataManager.swiftのUserDefaultsクリアコードを確認
2. GitHub Actionsのログでスキーマ初期化が実行されたか確認
3. シミュレーターの待機時間を延長（90秒など）

### Q4: デバイス間で同期されない

**原因**:
- CloudKitの同期には時間がかかる（最大15分）
- iCloud設定の問題

**チェック項目**:
1. 両方のデバイスが同じiCloudアカウントにログイン
2. Settings → iCloud → iCloud Driveがオン
3. Wi-Fi接続が安定している
4. CloudKitダッシュボードのLogsでエラーを確認

---

## 📝 作業後のクリーンアップ

### UserDefaultsクリアコードの削除

スキーマ初期化が成功したら、一時的なコードを削除：

**ファイル**: `BottleKeeper/Services/CoreDataManager.swift`

**削除するコード**（init内の最初の部分）:
```swift
// この部分を削除またはコメントアウト
#if DEBUG
let currentContainerID = UserDefaults.standard.string(forKey: "cloudKitContainerID")
// ... 以降のUserDefaultsクリアコード
#endif
```

**コミット**:
```bash
git add BottleKeeper/Services/CoreDataManager.swift
git commit -m "chore: スキーマ初期化成功のため一時的なUserDefaultsクリアコードを削除"
git push origin main
```

---

## 🎉 完了！

この手順により、Macなしで新しいCloudKitコンテナへの移行が完了します。

**次のマイルストーン**:
- [ ] 実機での長期的な同期テスト
- [ ] 複数ユーザーでの動作確認
- [ ] App Storeへの提出準備

---

**最終更新**: 2025-10-06
**対象環境**: Windows（Mac・Xcodeなし）
**成功確率**: 95%以上
