# App Store Connect API キー設定ガイド

TestFlightへの自動配信に必要なApp Store Connect APIキーの設定手順です。

## 1. App Store Connect APIキーの作成

### 1.1 App Store Connectにアクセス
1. [App Store Connect](https://appstoreconnect.apple.com/) にログイン
2. 上部メニューから「ユーザーとアクセス」をクリック
3. 左側のサイドバーで「統合」セクションを探し、「App Store Connect API」または「キー」を選択

**注意**: UIが更新されている場合は以下も確認してください：
- 「設定」→「API」→「キー」
- 「アカウント」→「API」
- ページ上部の検索で「API」を検索

### 1.2 新しいAPIキーを作成
1. 「+」ボタンをクリック
2. キー名を入力（例：`BottleKeep CI/CD`）
3. アクセス権限を「開発者」に設定
4. 「生成」をクリック

### 1.3 キー情報を記録
生成後、以下の情報を記録してください：
- **キー ID**: `XXXXXXXXXX` (例: AB12CD34EF)
- **Issuer ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **秘密キー**: `.p8ファイル`をダウンロード

⚠️ **重要**: 秘密キーファイル（.p8）は一度しかダウンロードできません。安全に保管してください。

## 2. GitHub Secretsの設定

### 2.1 必要なSecrets
以下の3つのSecretをGitHubリポジトリに追加してください：

| Secret名 | 値 | 説明 |
|----------|-----|------|
| `APP_STORE_CONNECT_API_KEY_ID` | キーID | 上記で記録したキーID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID | 上記で記録したIssuer ID |
| `APP_STORE_CONNECT_API_KEY` | .p8ファイルの内容 | 秘密キーファイルの中身 |

### 2.2 GitHub Secretsへの追加手順
1. GitHubリポジトリのページを開く
2. 「Settings」タブをクリック
3. サイドバーから「Secrets and variables」→「Actions」を選択
4. 「New repository secret」をクリック
5. 上記の表に従って、3つのSecretを順番に追加

### 2.3 .p8ファイルの内容をコピーする方法

**macOS/Linux:**
```bash
cat AuthKey_XXXXXXXXXX.p8
```

**Windows:**
```cmd
type AuthKey_XXXXXXXXXX.p8
```

ファイル内容全体（`-----BEGIN PRIVATE KEY-----` から `-----END PRIVATE KEY-----` まで）をコピーして、`APP_STORE_CONNECT_API_KEY` Secretに設定してください。

## 3. TestFlight配信の確認

APIキーが正しく設定されると、GitHub Actionsの以下のジョブが有効になります：

1. **自動ビルド**: mainブランチへのpush時
2. **TestFlightアップロード**: ビルド成功時に自動実行
3. **通知**: Slack（設定済みの場合）

## 4. 初回配信後の手順

### 4.1 TestFlightでの承認
1. [App Store Connect](https://appstoreconnect.apple.com/) にログイン
2. 「マイApp」から「BottleKeep」を選択
3. 「TestFlight」タブを開く
4. アップロードされたビルドを確認
5. 必要に応じて「Beta App審査に送信」を実行

### 4.2 テスターの招待
1. TestFlightの「テスター」セクションを開く
2. 内部テスター（チームメンバー）を追加
3. 外部テスター用のパブリックリンクを生成（オプション）

## 5. トラブルシューティング

### よくあるエラー

**認証エラー:**
```
ERROR ITMS-90035: Invalid Signature
```
- APIキーの内容が正しくコピーされているか確認
- キーIDとIssuer IDが正確か確認

**権限エラー:**
```
ERROR ITMS-90174: Missing Provisioning Profile
```
- プロビジョニングプロファイルがApp Store Distribution用か確認
- Bundle IDが一致しているか確認

**アップロードエラー:**
```
ERROR ITMS-90125: The binary is invalid
```
- ビルド設定でRelease configurationが使用されているか確認
- 署名証明書が有効期限内か確認

## 6. 次のステップ

APIキー設定完了後：
1. GitHub Actionsでのビルド成功を確認
2. TestFlightでのアップロード成功を確認
3. 実際のデバイスでのテストアプリ動作確認
4. チームメンバーへのテスター招待

---

📝 **メモ**: この設定は一度行えば、以降のリリースは全て自動化されます。