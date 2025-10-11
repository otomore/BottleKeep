# App Store Connect APIキー確認チェックリスト

TestFlightアップロード時の認証エラー「Authentication credentials are missing or invalid」の原因を特定するため、以下の項目を1つずつ確認してください。

---

## ✅ 確認項目

### 1. App Store ConnectでAPIアクセスがリクエスト・承認されているか

**確認場所:**
- App Store Connect → Users and Access → Integrations

**確認内容:**
- [ ] "Request Access"ボタンが表示されている場合は**未承認**
- [ ] "Team Keys"または"Individual Keys"タブが表示されている場合は**承認済み**

**注意点:**
- 個人開発者アカウント（Individual）の場合、初回はAccount HolderがAPIアクセスをリクエストする必要がある
- Appleによるケースバイケースの審査があり、通常数日以内に承認される

---

### 2. チームAPIキー（Team Key）を作成しているか（個人APIキーではない）

**確認場所:**
- App Store Connect → Users and Access → Integrations → **Team Keys**タブ

**確認内容:**
- [ ] "Team Keys"タブでAPIキーを作成している
- [ ] "Individual Keys"タブではなく、必ず"Team Keys"を使用している

**理由:**
- チームAPIキーはCI/CD環境との互換性が高い
- 個人APIキーは同時に1つしか保持できず、一部ツールで非対応
- fastlaneを含む多くのツールはチームAPIキーを推奨

**重要:**
- ❌ 個人APIキー（Individual Keys）は使用しない
- ✅ チームAPIキー（Team Keys）を使用する

---

### 3. APIキーのロールがApp Manager以上か

**確認場所:**
- App Store Connect → Users and Access → Integrations → Team Keys
- 作成済みキーの"Role"列を確認

**確認内容:**
- [ ] ロールが**App Manager**または**Admin**または**Account Holder**である
- [ ] "Access to Certificates, Identifiers & Profiles"権限が有効になっている（App Managerの場合）

**ロール別の権限:**

| ロール | TestFlightアップロード | ビルド情報更新 | 証明書管理 | 推奨度 |
|--------|----------------------|--------------|----------|--------|
| Account Holder | ✅ | ✅ | ✅ | ⭐⭐⭐ |
| Admin | ✅ | ✅ | ✅ | ⭐⭐⭐ |
| **App Manager** | ✅ | ✅ | ✅ | ⭐⭐⭐⭐⭐ **推奨** |
| Developer | ✅ | ❌ | 部分的 | ❌ 非推奨 |

**推奨: App Managerロール**
- TestFlightアップロードに十分な権限
- 最小権限の原則に従った適切な選択
- ユーザー管理や財務情報への不要なアクセスを避けられる

---

### 4. Key IDがGitHub Secretsに正確に設定されているか

**確認場所:**
- GitHub Repository → Settings → Secrets and variables → Actions

**確認内容:**
- [ ] シークレット名: `APP_STORE_CONNECT_API_KEY_ID`
- [ ] App Store Connectの"Key ID"と完全一致しているか
- [ ] タイポ（余分なスペース、大文字小文字の違い）がないか

**Key IDの確認方法:**
1. App Store Connect → Users and Access → Integrations → Team Keys
2. 該当キーの"Key ID"列を確認（例: `ABCD1234EF`）
3. GitHub Secretsの値と比較

**コマンドで確認（ローカル）:**
```bash
gh secret list | grep APP_STORE_CONNECT_API_KEY_ID
```

---

### 5. Issuer IDがGitHub Secretsに正確に設定されているか

**確認場所:**
- GitHub Repository → Settings → Secrets and variables → Actions

**確認内容:**
- [ ] シークレット名: `APP_STORE_CONNECT_ISSUER_ID`
- [ ] App Store Connectの"Issuer ID"と完全一致しているか
- [ ] UUID形式であることを確認（例: `69a6de80-2c1a-47e3-e053-5b8c7c11a4d1`）

**Issuer IDの確認方法:**
1. App Store Connect → Users and Access → Integrations
2. ページ上部に表示されている"Issuer ID"をコピー
3. GitHub Secretsの値と比較

**既知の値（確認済み）:**
- Issuer ID: `69a6de80-2c1a-47e3-e053-5b8c7c11a4d1`

**コマンドで確認（ローカル）:**
```bash
gh secret list | grep APP_STORE_CONNECT_ISSUER_ID
```

---

### 6. .p8ファイルがBase64エンコードされGitHub Secretsに正確に設定されているか

**確認場所:**
- GitHub Repository → Settings → Secrets and variables → Actions

**確認内容:**
- [ ] シークレット名: `APP_STORE_CONNECT_API_KEY`
- [ ] .p8ファイルの内容がBase64エンコードされている
- [ ] 改行が正しく処理されている

**.p8ファイルのBase64エンコード方法（macOS/Linux）:**
```bash
cat AuthKey_XXXXX.p8 | base64
```

**.p8ファイルのBase64エンコード方法（Windows PowerShell）:**
```powershell
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("AuthKey_XXXXX.p8"))
```

**重要な注意点:**
- .p8ファイルは**一度だけ**ダウンロード可能
- 紛失した場合は新しいキーを作成する必要がある
- Base64エンコード時に改行を正しく保持すること
- エンコード前のファイルは`-----BEGIN PRIVATE KEY-----`で始まり`-----END PRIVATE KEY-----`で終わる

**検証方法（デコードして確認）:**
```bash
# GitHub Secretsの値をデコード（ローカルでテスト）
echo "BASE64_STRING" | base64 -d
# 正しい場合、-----BEGIN PRIVATE KEY-----が表示される
```

**コマンドで確認（ローカル）:**
```bash
gh secret list | grep APP_STORE_CONNECT_API_KEY
```

---

### 7. Fastfileにdurationパラメータ（500以下）を追加

**確認場所:**
- `fastlane/Fastfile`

**確認内容:**
- [ ] `app_store_connect_api_key`にdurationパラメータが設定されている
- [ ] durationの値が500以下である（最大1200=20分だが、500を推奨）

**現在のFastfile:**
```ruby
api_key = app_store_connect_api_key(
  key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
  issuer_id: ENV["APP_STORE_CONNECT_ISSUER_ID"],
  key_content: ENV["APP_STORE_CONNECT_API_KEY"],
  is_key_content_base64: true
  # duration: 500  # ← これが欠けている！
)
```

**修正後のFastfile:**
```ruby
api_key = app_store_connect_api_key(
  key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
  issuer_id: ENV["APP_STORE_CONNECT_ISSUER_ID"],
  key_content: ENV["APP_STORE_CONNECT_API_KEY"],
  is_key_content_base64: true,
  duration: 500  # ✅ 追加（JWTトークンの有効期限を500秒=約8分に設定）
)
```

**理由:**
- JWTトークンの有効期限は最大20分（1200秒）
- durationパラメータが未指定の場合、デフォルト値が使用される
- 明示的に500秒以下を設定することで、認証エラーを回避

**注意:**
- duration > 1200（20分）の場合、即座に401エラーとなる
- 推奨値: 500秒（約8分）

---

## 📊 確認フロー

```
┌─────────────────────────────────────┐
│ 1. APIアクセスが承認されているか？    │
└────────────┬────────────────────────┘
             │ YES
             ↓
┌─────────────────────────────────────┐
│ 2. チームAPIキーを使用しているか？    │
└────────────┬────────────────────────┘
             │ YES
             ↓
┌─────────────────────────────────────┐
│ 3. ロールがApp Manager以上か？       │
└────────────┬────────────────────────┘
             │ YES
             ↓
┌─────────────────────────────────────┐
│ 4. Key IDが正確に設定されているか？   │
└────────────┬────────────────────────┘
             │ YES
             ↓
┌─────────────────────────────────────┐
│ 5. Issuer IDが正確に設定されているか？│
└────────────┬────────────────────────┘
             │ YES
             ↓
┌─────────────────────────────────────┐
│ 6. .p8ファイルのBase64が正確か？     │
└────────────┬────────────────────────┘
             │ YES
             ↓
┌─────────────────────────────────────┐
│ 7. Fastfileにdurationが設定されているか│
└────────────┬────────────────────────┘
             │ YES
             ↓
        ✅ 完了！
```

---

## 🔧 トラブルシューティング

### すべて確認したがまだエラーが出る場合

1. **Apple Developer Statusを確認**
   - https://developer.apple.com/system-status/
   - App Store Connect APIがダウンしていないか確認

2. **新しいAPIキーを作成**
   - 古いキーを失効
   - 新しいチームAPIキー（App Managerロール）を作成
   - .p8ファイルを再ダウンロード
   - GitHub Secretsを全て更新

3. **fastlaneのバージョンを確認**
   - 最新版を使用しているか確認
   - `bundle update fastlane`

4. **ログを詳細に確認**
   - GitHub Actionsのログで正確なエラーメッセージを確認
   - JWTトークン生成の問題か、API呼び出しの問題かを特定

---

## 📚 参考資料

- [Creating API Keys for App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
- [fastlane - Using App Store Connect API](https://docs.fastlane.tools/app-store-connect-api/)
- [Generating Tokens for API Requests](https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests)

---

**作成日:** 2025年9月30日
**対象プロジェクト:** BottleKeeper
**エラー:** Authentication credentials are missing or invalid