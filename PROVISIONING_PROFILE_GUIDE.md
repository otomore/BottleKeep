# プロビジョニングプロファイル作成ガイド

## 概要

プロビジョニングプロファイルは、iOSアプリを実機やApp Storeで実行するために必要なファイルです。証明書、App ID、デバイス情報を組み合わせて、アプリの署名と配信を制御します。

## 前提条件

- Apple Developer Program登録済み
- 配布用証明書（Apple Distribution Certificate）作成済み ✅
- Apple Developer Portalへのアクセス権

## ステップ1: App IDの確認・作成

### 1.1 Apple Developer Portalにアクセス

1. [Apple Developer Portal](https://developer.apple.com) にアクセス
2. Apple IDでサインイン
3. **Account** → **Certificates, IDs & Profiles** をクリック

### 1.2 App IDの確認

1. 左サイドバーで **Identifiers** をクリック
2. 既存のApp IDを確認：
   - Bundle ID: `com.bottlekeep.app`
   - App Name: BottleKeep

### 1.3 App IDが存在しない場合の作成

1. **+** ボタンをクリック
2. **App IDs** を選択して **Continue**
3. **App** を選択して **Continue**
4. 以下の情報を入力：
   - **Description**: BottleKeep
   - **Bundle ID**: Explicit - `com.bottlekeep.app`
5. **Capabilities** で必要な機能を選択：
   - ☑️ Core Data
   - ☑️ PhotoKit
   - ☑️ Camera Access
   - ☑️ Photo Library Access
6. **Continue** → **Register**

## ステップ2: プロビジョニングプロファイルの作成

### 2.1 新規プロファイル作成開始

1. 左サイドバーで **Profiles** をクリック
2. **+** ボタンをクリック

### 2.2 配布タイプの選択

**App Store** を選択（TestFlightとApp Store配信用）
- ☑️ App Store
- **Continue**

### 2.3 App IDの選択

1. 作成したApp IDを選択：`com.bottlekeep.app (BottleKeep)`
2. **Continue**

### 2.4 証明書の選択

1. 先ほど作成した **Apple Distribution** 証明書を選択
2. 証明書名に「BottleKeep Distribution」が含まれていることを確認
3. **Continue**

### 2.5 プロファイル名の設定

1. **Provisioning Profile Name**: `BottleKeep Distribution`
2. **Generate**

### 2.6 プロファイルのダウンロード

1. **Download** ボタンをクリック
2. ファイル名: `BottleKeep_Distribution.mobileprovision`
3. プロジェクトのルートディレクトリに保存

## ステップ3: GitHub Secretsの設定

### 3.1 プロビジョニングプロファイルのBase64エンコード

**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("BottleKeep_Distribution.mobileprovision")) | Set-Clipboard
```

**macOS/Linux:**
```bash
base64 -i BottleKeep_Distribution.mobileprovision | pbcopy
```

### 3.2 GitHub Secretの追加

```bash
# プロビジョニングプロファイルをSecretに設定
echo "BASE64_ENCODED_VALUE_HERE" | gh secret set BUILD_PROVISION_PROFILE_BASE64
```

## ステップ4: Team IDの取得

### 4.1 Team ID確認方法

**Apple Developer Portal:**
1. **Account** → **Membership** をクリック
2. **Team ID** をコピー（例：ABC123XYZ）

**Xcode:**
1. Xcode → Preferences → Accounts
2. Apple IDを選択
3. **Manage Certificates** → Team IDを確認

### 4.2 GitHub SecretにTeam IDを設定

```bash
# 実際のTeam IDに置き換えて実行
echo "YOUR_ACTUAL_TEAM_ID" | gh secret set TEAM_ID
```

## ステップ5: ExportOptions.plistの更新

プロビジョニングプロファイル作成後、設定ファイルを更新：

```xml
<key>teamID</key>
<string>YOUR_ACTUAL_TEAM_ID</string>

<key>provisioningProfiles</key>
<dict>
    <key>com.bottlekeep.app</key>
    <string>BottleKeep Distribution</string>
</dict>
```

## 確認事項チェックリスト

- [ ] Apple Developer Program登録完了
- [ ] 配布用証明書（Apple Distribution Certificate）作成済み
- [ ] App ID (`com.bottlekeep.app`) 作成済み
- [ ] プロビジョニングプロファイル (`BottleKeep Distribution`) 作成済み
- [ ] プロビジョニングプロファイルをダウンロード済み
- [ ] `BUILD_PROVISION_PROFILE_BASE64` Secretに設定済み
- [ ] Team IDを確認済み
- [ ] `TEAM_ID` Secretに設定済み
- [ ] `ExportOptions.plist` を実際の値に更新済み

## トラブルシューティング

### エラー: "No profiles for 'com.bottlekeep.app' were found"

**原因**: プロビジョニングプロファイルが正しく作成されていない

**解決策**:
1. App IDが正確に `com.bottlekeep.app` で作成されているか確認
2. プロビジョニングプロファイルで同じBundle IDが選択されているか確認
3. 配布用証明書が有効で選択されているか確認

### エラー: "Certificate not found"

**原因**: 証明書とプロビジョニングプロファイルが一致していない

**解決策**:
1. 同じApple Developer アカウントで証明書とプロファイルを作成
2. 証明書の有効期限を確認
3. 必要に応じて新しい証明書を作成

### エラー: "Team ID mismatch"

**原因**: ExportOptions.plistのTeam IDが間違っている

**解決策**:
1. Apple Developer PortalでTeam IDを再確認
2. `ExportOptions.plist` と GitHub Secretの両方を更新

## 次のステップ

1. すべての設定が完了したら、GitHub ActionsでiOSビルドをテスト実行
2. ビルドが成功したら、TestFlightで配信テスト
3. 本番環境でのApp Store配信準備

---

**注意事項**:
- プロビジョニングプロファイルは1年間有効
- 証明書の有効期限前に更新が必要
- Bundle IDは変更不可（新規App ID作成が必要）