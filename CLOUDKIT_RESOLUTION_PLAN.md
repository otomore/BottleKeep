# CloudKit問題 解決プラン

**作成日**: 2025-10-12
**最終更新**: 2025-10-12 02:04 JST (GitHub Actions実行完了後)
**対象**: `_pcs_data`システムレコードタイプ欠落問題
**現在のステータス**: ✅ GitHub Actions実行完了 → ⚠️ スキーマ初期化状況確認必要

---

## 🔄 最新の実行結果（2025-10-12）

### GitHub Actions実行 - Run #18432219295

**実行サマリー**:
- ✅ **テストジョブ**: 成功（2m49s）
  - DEBUGビルド成功
  - シミュレーター起動成功
  - アプリ起動成功（PID: 18242）
  - 60秒待機完了
- ❌ **ビルドジョブ**: 失敗（21s）
  - エラー: プロビジョニングプロファイルに新CloudKitコンテナ含まれず
- ⏭️ **TestFlight配信**: スキップ

**⚠️ 重要な発見**:
1. **CloudKitログが出力されていない**
   - `grep -i "cloudkit|schema|_pcs_data"` で関連ログが見つからず
   - CoreDataManagerのログメッセージが一切表示されていない
   - **可能性1**: アプリがクラッシュした（iCloudアカウント未設定など）
   - **可能性2**: スキーマ初期化は既に完了していてUserDefaultsにフラグが立っている
   - **可能性3**: ログが別の場所に出力された

2. **プロビジョニングプロファイルの問題**（RELEASE buildのみ）
   ```
   Provisioning profile "BottleKeep Distribution" doesn't match the entitlements
   file's value for the com.apple.developer.icloud-container-identifiers entitlement.
   ```
   - 現在のプロファイル: 旧コンテナ `iCloud.com.bottlekeep.whiskey` のみ
   - 必要な設定: 新コンテナ `iCloud.com.bottlekeep.whiskey.v2` を追加

**次のアクション**:
1. **最優先**: CloudKitダッシュボードで`_pcs_data`の存在確認（ユーザー操作必須）
2. **優先**: Apple Developer Portalでプロビジョニングプロファイル更新（ユーザー操作必須）

---

## 📊 現状サマリー

### ✅ 完了済み（Claude Codeで実施）

1. **新CloudKitコンテナへの移行**
   - ✅ `iCloud.com.bottlekeep.whiskey` → `iCloud.com.bottlekeep.whiskey.v2`
   - ✅ entitlementsファイル更新完了
   - ✅ CoreDataManager.swift更新完了
   - ✅ Development環境に設定済み

2. **コード最適化**
   - ✅ スキーマ初期化ロジック改善（DEBUGビルドで自動実行）
   - ✅ 新コンテナ検知時のUserDefaultsクリア処理追加
   - ✅ 詳細なログ出力機能実装

3. **GitHub Actions準備**
   - ✅ シミュレーター起動＆スキーマ初期化ワークフロー整備
   - ✅ 60秒待機＋ログ抽出機能実装

4. **GitHub Actions実行（2025-10-12）**
   - ✅ ワークフロー手動トリガー（Run #18432219295）
   - ✅ DEBUGビルド＆シミュレーター起動成功
   - ✅ アプリ起動完了（60秒間実行）
   - ⚠️ CloudKitログが出力されず（原因調査必要）

### ⏳ 未完了（ユーザー操作が必要）

1. **Apple Developer Portalでの確認・操作**
   - ⏳ 新コンテナ `iCloud.com.bottlekeep.whiskey.v2` が作成済みか確認
   - ❗ **プロビジョニングプロファイルに新コンテナが含まれていない**（確定）
     - GitHub Actions Run #18432219295でビルドエラー確認済み
     - 現在: 旧コンテナ `iCloud.com.bottlekeep.whiskey` のみ
     - 必要: 新コンテナ `iCloud.com.bottlekeep.whiskey.v2` を追加
   - ❗ **新しいプロビジョニングプロファイルの作成＆GitHub Secrets更新が必須**

2. **CloudKitダッシュボードでの確認**（🔥 最優先）
   - ⏳ **Development環境のスキーマ状態確認**
   - ⏳ **`_pcs_data`レコードタイプの存在確認**
   - 📍 URL: https://icloud.developer.apple.com/dashboard/
   - 📍 Container: `iCloud.com.bottlekeep.whiskey.v2`
   - 📍 Environment: **Development**
   - 📍 Schema → Record Types
   - ✅ 確認すべきレコードタイプ:
     - `CD_Bottle`
     - `CD_BottlePhoto`
     - `CD_DrinkingLog`
     - `CD_WishlistItem`
     - **`_pcs_data`** ← **これが最重要**

   **この確認結果により次のアクションが決まります**:
   - ✅ `_pcs_data`が存在 → スキーマ初期化成功！ステップ3（Production展開）へ
   - ❌ `_pcs_data`が存在しない → トラブルシューティング必要（ログ調査、再実行など）

3. **実機/TestFlightでの動作確認**
   - ⏳ 2台のデバイスでデータ同期テスト

---

## 🎯 解決プラン（3ステップ）

### ステップ1: Apple Developer Portalでの確認・準備

#### 1-1. 新CloudKitコンテナの確認

**URL**: https://developer.apple.com/account/resources/identifiers/list/cloudContainer

**確認内容**:
- [ ] `iCloud.com.bottlekeep.whiskey.v2` が存在するか確認

**結果によるアクション**:
- ✅ **存在する場合**: ステップ1-2へ進む
- ❌ **存在しない場合**: 以下の手順で作成
  1. 「+」ボタンをクリック
  2. 「CloudKit Container」を選択
  3. Identifier: `iCloud.com.bottlekeep.whiskey.v2` を入力
  4. 「Register」をクリック

#### 1-2. プロビジョニングプロファイルの確認

**URL**: https://developer.apple.com/account/resources/profiles/list

**確認内容**:
- [ ] 現在のプロビジョニングプロファイル（BottleKeeper Distribution）を選択
- [ ] 「Edit」をクリック
- [ ] 「iCloud Services」セクションで以下のコンテナが**両方**含まれているか確認:
  - `iCloud.com.bottlekeep.whiskey` （旧コンテナ - 互換性のため残す）
  - `iCloud.com.bottlekeep.whiskey.v2` （新コンテナ - **これが重要**）

**結果によるアクション**:
- ✅ **両方含まれている場合**: ステップ2へ進む
- ❌ **新コンテナが含まれていない場合**: 以下の手順で追加
  1. 「iCloud Services」セクションで `iCloud.com.bottlekeep.whiskey.v2` にチェックを入れる
  2. 「Save」をクリック
  3. 新しいプロビジョニングプロファイルをダウンロード
  4. GitHub Secretsを更新（後述）

#### 1-3. GitHub Secretsの更新（新プロファイルをダウンロードした場合のみ）

**手順**:
```bash
# Windows PowerShellで実行
$profile = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("ダウンロードしたプロファイル.mobileprovision"))

# GitHub CLIで更新
gh secret set BUILD_PROVISION_PROFILE_BASE64_NEW --body $profile
```

---

### ステップ2: GitHub ActionsでCloudKitスキーマ初期化

#### 2-1. ワークフローの手動実行

**URL**: https://github.com/あなたのユーザー名/BottleKeeper/actions/workflows/ios-build.yml

**手順**:
1. 「Run workflow」ボタンをクリック
2. Branch: `main` を選択
3. 「Run workflow」をクリック

#### 2-2. ビルド実行の監視

**確認項目**:
- [ ] **test**ジョブが成功（緑のチェックマーク）
- [ ] シミュレーターが起動してアプリが60秒間実行される
- [ ] ログに以下のメッセージが含まれる:
  ```
  ✅ CloudKit schema initialized successfully
  ✅ _pcs_data system record type should now be created
  ```

**エラーが発生した場合**:
- `Error 134060`: 既にスキーマが存在する（正常な場合もある）
- `iCloud not available`: iCloudアカウントが設定されていない（シミュレーター設定を確認）

#### 2-3. CloudKitダッシュボードでの確認

**URL**: https://icloud.developer.apple.com/dashboard/

**手順**:
1. Container: `iCloud.com.bottlekeep.whiskey.v2` を選択
2. Environment: **Development** を選択
3. 「Schema」→「Record Types」へ移動

**確認内容**:
- [ ] 以下のレコードタイプが存在するか確認:
  - ✅ `CD_Bottle`
  - ✅ `CD_BottlePhoto`
  - ✅ `CD_DrinkingLog`
  - ✅ `CD_WishlistItem`
  - ✅ **`_pcs_data`** ← **これが最重要**

**結果によるアクション**:
- ✅ **`_pcs_data`が存在する場合**: 🎉 成功！ステップ3へ進む
- ❌ **`_pcs_data`が存在しない場合**: 以下をトラブルシューティング
  1. GitHub Actionsのログを詳細に確認
  2. シミュレーター内でiCloudアカウントが設定されているか確認
  3. entitlementsが`Development`環境になっているか確認
  4. ステップ2-1を再試行

---

### ステップ3: Production環境へのデプロイとTestFlight配信

#### 3-1. entitlementsをProductionに変更

**ファイル**: `BottleKeeper/BottleKeeper.entitlements`

**変更内容**:
```xml
<!-- 変更前 -->
<key>com.apple.developer.icloud-container-environment</key>
<string>Development</string>

<!-- 変更後 -->
<key>com.apple.developer.icloud-container-environment</key>
<string>Production</string>
```

**コミット**:
```bash
git add BottleKeeper/BottleKeeper.entitlements
git commit -m "chore: CloudKit環境をProductionに変更して本番デプロイ準備完了

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

#### 3-2. CloudKitスキーマをProductionにデプロイ

**URL**: https://icloud.developer.apple.com/dashboard/

**手順**:
1. Container: `iCloud.com.bottlekeep.whiskey.v2` を選択
2. Environment: **Development** を選択
3. 「Schema」→「Deploy Schema Changes」をクリック
4. 「Deploy to Production」を選択
5. 確認ダイアログで「Deploy」をクリック

**注意**:
- ⚠️ Production環境へのデプロイは**取り消し不可**
- ⚠️ デプロイ前にDevelopment環境で十分にテストすること

#### 3-3. TestFlightビルドの作成

**URL**: https://github.com/あなたのユーザー名/BottleKeeper/actions/workflows/ios-build.yml

**手順**:
1. 「Run workflow」ボタンをクリック
2. Branch: `main` を選択
3. 「Run workflow」をクリック
4. **build**ジョブと**deploy-testflight**ジョブが成功することを確認

#### 3-4. TestFlightでの動作確認

**App Store Connect URL**: https://appstoreconnect.apple.com/

**テスト内容**:
1. 2台のデバイスにTestFlightビルドをインストール
2. デバイス1でボトルを追加
3. デバイス2で同期されるか確認（数分待つ）
4. デバイス2でボトルを編集
5. デバイス1で変更が同期されるか確認

**期待される結果**:
- ✅ デバイス間でデータが正常に同期される
- ✅ CloudKitダッシュボードのLogsでエラーが発生しない
- ✅ `BAD_REQUEST`エラーが発生しない

---

## 🔍 トラブルシューティング

### 問題1: 新CloudKitコンテナが作成できない

**症状**: Apple Developer Portalで「This identifier is already in use」エラー

**原因**: コンテナIDが既に使用されている

**解決策**:
1. 別のコンテナID（例：`iCloud.com.bottlekeep.whiskey.v3`）を使用
2. entitlementsとCoreDataManager.swiftを新しいIDに更新
3. ステップ1から再実行

---

### 問題2: GitHub Actionsでスキーマ初期化が失敗（Error 134060）

**症状**:
```
Error 134060: A Core Data error occurred.
```

**原因**: 以下のいずれか
1. Development環境に既にスキーマが存在する
2. Storesが正しくロードされていない

**解決策**:

**パターンA: 既にスキーマが存在する場合（正常）**
- CloudKitダッシュボードで`_pcs_data`が存在するか確認
- 存在する場合は成功扱い。ステップ3へ進む

**パターンB: Storesがロードされていない場合**
- GitHub Actionsのログで以下を確認:
  ```
  ✅ Core Data loaded successfully
  Store URL: ...
  ```
- このメッセージが表示されていない場合、Core Dataのロードに失敗している
- ステップ2-1を再試行

---

### 問題3: プロビジョニングプロファイルに新コンテナが含まれていない

**症状**: ビルド時に以下のエラー
```
Provisioning profile doesn't include the iCloud.com.bottlekeep.whiskey.v2 entitlement
```

**解決策**:
1. ステップ1-2に戻って新しいプロファイルを作成
2. ステップ1-3に従ってGitHub Secretsを更新
3. ステップ2-1を再実行

---

### 問題4: CloudKitダッシュボードで`_pcs_data`が表示されない

**症状**: スキーマ初期化は成功したが、`_pcs_data`が見つからない

**原因**:
- ブラウザキャッシュの問題
- スキーマの反映遅延

**解決策**:
1. ブラウザをリフレッシュ（Ctrl+F5 / Cmd+Shift+R）
2. 5分待ってから再度確認
3. それでも表示されない場合:
   - Development環境をリセット（Reset Environment）
   - ステップ2-1を再実行

---

### 問題5: TestFlightでデータ同期が動作しない

**症状**:
- ビルドは成功
- アプリは起動するがデータが同期されない

**原因**:
- Production環境に`_pcs_data`が存在しない
- スキーマがProductionにデプロイされていない

**解決策**:
1. CloudKitダッシュボードでProduction環境を確認
2. `_pcs_data`が存在しない場合:
   - ステップ3-2に戻ってスキーマをデプロイ
3. スキーマがデプロイ済みの場合:
   - アプリのログを確認（SettingsView → CloudKitログ）
   - エラーメッセージを`CLOUDKIT_SYNC_STATUS.md`と照合

---

## 📋 チェックリスト

### ステップ1: Apple Developer Portal（ユーザー操作）
- [ ] 新CloudKitコンテナ `iCloud.com.bottlekeep.whiskey.v2` が存在することを確認
- [ ] プロビジョニングプロファイルに新コンテナが含まれることを確認
- [ ] （必要に応じて）新プロファイルをダウンロード＆GitHub Secrets更新

### ステップ2: GitHub Actionsでスキーマ初期化（自動）
- [ ] ios-build.ymlワークフローを手動実行
- [ ] testジョブが成功
- [ ] ログに「CloudKit schema initialized successfully」が表示
- [ ] CloudKitダッシュボード（Development）で`_pcs_data`が存在することを確認

### ステップ3: Production環境へのデプロイ（ユーザー操作）
- [ ] entitlementsをProductionに変更してコミット＆プッシュ
- [ ] CloudKitスキーマをProductionにデプロイ
- [ ] ios-build.ymlワークフローを手動実行（TestFlight配信）
- [ ] 2台のデバイスでデータ同期をテスト
- [ ] 同期が正常に動作することを確認

---

## 🎯 成功の定義

以下の条件が**すべて**満たされた場合、問題は解決です：

1. ✅ CloudKitダッシュボード（Development & Production）で`_pcs_data`レコードタイプが存在する
2. ✅ 2台のデバイス間でボトルデータが正常に同期される
3. ✅ CloudKitダッシュボードのLogsで`BAD_REQUEST`エラーが発生しない
4. ✅ アプリのCloudKitログで「CloudKit sync error」が発生しない

---

## 📚 参考ドキュメント

| ファイル | 内容 |
|---------|------|
| `CLOUDKIT_SYNC_STATUS.md` | 問題の詳細な履歴（648行） |
| `CLOUDKIT_MIGRATION_NO_MAC.md` | Macなし環境での移行手順 |
| `CLAUDE.md` | プロジェクト設定とCloudKit知見 |
| `CoreDataManager.swift` | スキーマ初期化ロジック（559行） |
| `.github/workflows/ios-build.yml` | GitHub Actionsワークフロー（343行） |

---

## 🔄 次のアクション（推奨順）

### 最優先（今すぐ実施）
1. **Apple Developer Portalでの確認**: ステップ1-1と1-2を実施
2. **GitHub Actionsの実行**: ステップ2-1を実施
3. **CloudKitダッシュボードでの確認**: ステップ2-3を実施

### 優先度：中（スキーマ初期化成功後）
1. **Productionへのデプロイ**: ステップ3を実施
2. **TestFlightでの動作確認**: ステップ3-4を実施

### 優先度：低（問題解決後）
1. 未追跡ファイルの整理（`.gitignore`更新、ドキュメントコミット）
2. Liquid Glass実装の検討
3. プレミアム機能の実装

---

**作成者**: Claude Code
**最終更新**: 2025-10-12
