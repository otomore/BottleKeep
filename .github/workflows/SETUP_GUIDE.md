# GitHub Actions iOS ビルド設定ガイド

このガイドでは、BottleKeepアプリをGitHub Actionsでビルドするための設定手順を説明します。

## 前提条件

- Apple Developer Programへの登録
- 有効な配布用証明書とプロビジョニングプロファイル
- App Store Connect APIキー（TestFlight配信用）

## GitHub Secretsの設定

GitHub リポジトリの Settings → Secrets and variables → Actions から、以下のシークレットを設定してください：

### 1. 証明書関連

#### `BUILD_CERTIFICATE_BASE64`
配布用証明書（.p12）をBase64エンコードした値

```bash
# 証明書をBase64エンコード
base64 -i distribution_certificate.p12 | pbcopy
```

#### `P12_PASSWORD`
証明書（.p12）のパスワード

#### `BUILD_PROVISION_PROFILE_BASE64`
プロビジョニングプロファイル（.mobileprovision）をBase64エンコードした値

```bash
# プロビジョニングプロファイルをBase64エンコード
base64 -i BottleKeep_Distribution.mobileprovision | pbcopy
```

#### `KEYCHAIN_PASSWORD`
GitHub Actions上で作成する一時キーチェーンのパスワード（任意の強固なパスワード）

#### `TEAM_ID`
Apple Developer TeamのID（Developer PortalまたはXcodeで確認可能）

### 2. App Store Connect API（TestFlight配信用）

#### `APP_STORE_CONNECT_API_KEY_ID`
App Store Connect APIキーのKey ID

#### `APP_STORE_CONNECT_ISSUER_ID`
App Store Connect APIのIssuer ID

#### `APP_STORE_CONNECT_API_KEY`
App Store Connect APIキーの内容（.p8ファイルの全内容）

```bash
# APIキーファイルの内容をコピー
cat AuthKey_XXXXXX.p8 | pbcopy
```

### 3. 通知用（オプション）

#### `SLACK_WEBHOOK_URL`
Slack通知用のWebhook URL（オプション）

## 証明書の作成と取得方法

### 1. 配布用証明書の作成

1. Xcodeを開き、Preferences → Accounts を開く
2. Apple IDを選択し、「Manage Certificates」をクリック
3. 「+」ボタンをクリックし、「Apple Distribution」を選択
4. 作成された証明書を右クリックし、「Export Certificate」を選択
5. パスワードを設定して.p12ファイルとして保存

### 2. プロビジョニングプロファイルの作成

1. [Apple Developer Portal](https://developer.apple.com) にログイン
2. Certificates, IDs & Profiles → Profiles を選択
3. 「+」ボタンをクリックして新規プロファイルを作成
4. 「App Store」を選択
5. アプリのApp IDを選択
6. 配布用証明書を選択
7. プロファイル名を入力（例：BottleKeep Distribution）
8. 生成されたプロファイルをダウンロード

### 3. App Store Connect APIキーの作成

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. Users and Access → Keys を選択
3. 「+」ボタンをクリックして新規キーを作成
4. 名前を入力し、アクセス権限を「App Manager」に設定
5. キーをダウンロード（.p8ファイル）
6. Key IDとIssuer IDをメモ

## ワークフローのカスタマイズ

### プロジェクトパスの更新

`.github/workflows/ios-build.yml`ファイルの以下の部分を実際のプロジェクトに合わせて更新：

```yaml
env:
  XCODE_VERSION: '15.0' # 使用するXcodeバージョン
  SCHEME: 'BottleKeep' # Xcodeスキーム名
  PROJECT_PATH: 'BottleKeep.xcodeproj' # プロジェクトファイルのパス
```

### ExportOptions.plistの更新

`ExportOptions.plist`ファイルの以下の部分を更新：

```xml
<!-- チームIDを実際の値に更新 -->
<key>teamID</key>
<string>YOUR_TEAM_ID</string>

<!-- バンドルIDを実際の値に更新 -->
<key>provisioningProfiles</key>
<dict>
    <key>com.yourcompany.BottleKeep</key>
    <string>BottleKeep Distribution</string>
</dict>
```

## トラブルシューティング

### よくあるエラーと解決方法

#### 1. 証明書のインポートエラー
- Base64エンコードが正しく行われているか確認
- P12パスワードが正しいか確認
- 証明書が有効期限内か確認

#### 2. プロビジョニングプロファイルエラー
- プロファイルが証明書と一致しているか確認
- バンドルIDが正しいか確認
- プロファイルの有効期限を確認

#### 3. ビルドエラー
- Xcodeプロジェクトのパスが正しいか確認
- スキーム名が正しいか確認
- 依存関係が正しく解決されているか確認

#### 4. TestFlightアップロードエラー
- App Store Connect APIキーの権限を確認
- アプリがApp Store Connectに登録されているか確認
- バンドルIDが一致しているか確認

## セキュリティベストプラクティス

1. **証明書の管理**
   - 証明書ファイルは絶対にリポジトリにコミットしない
   - 定期的に証明書を更新する
   - 不要な証明書は削除する

2. **シークレットの保護**
   - GitHub Secretsのみを使用
   - ローカルでの証明書ファイルは安全に保管
   - APIキーは最小限の権限で作成

3. **アクセス制限**
   - リポジトリへのアクセスを制限
   - ワークフローの手動実行は管理者のみに制限
   - ブランチ保護ルールを設定

## 次のステップ

1. すべてのGitHub Secretsを設定
2. `ExportOptions.plist`を更新
3. ワークフローファイルのプロジェクトパスを更新
4. テストブランチでワークフローを実行
5. 成功したらmainブランチにマージ

## サポート

問題が発生した場合は、GitHub Actionsのログを確認し、エラーメッセージに基づいて対処してください。