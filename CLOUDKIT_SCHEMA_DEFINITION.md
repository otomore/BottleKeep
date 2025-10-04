# CloudKitスキーマ定義

このドキュメントは、Core Data Model定義に基づいた正確なCloudKitスキーマ定義です。
CloudKitダッシュボードで手動作成する際に使用してください。

最終更新: 2025-10-04

---

## 📋 レコードタイプ一覧

このアプリには以下の4つのレコードタイプが必要です：

1. **CD_Bottle** - ボトル情報
2. **CD_WishlistItem** - ウィッシュリスト項目
3. **CD_DrinkingLog** - 飲酒記録
4. **CD_BottlePhoto** - ボトル写真

---

## 1️⃣ CD_Bottle

### フィールド定義

| フィールド名 | タイプ | インデックス設定 | 必須 | デフォルト値 | 備考 |
|------------|--------|-----------------|------|------------|------|
| `recordName` | String | - | システム | - | CloudKitが自動生成 |
| `CD_id` | String | - | ○ | - | UUID文字列 |
| `CD_name` | String | QUERYABLE, SEARCHABLE | - | - | ボトル名 |
| `CD_abv` | Double | - | - | 0.0 | アルコール度数 |
| `CD_volume` | Int64 | - | - | 700 | 容量（ml） |
| `CD_remainingVolume` | Int64 | - | - | 0 | 残量（ml） |
| `CD_rating` | Int64 | - | - | 0 | 評価（0-5） |
| `CD_distillery` | String | QUERYABLE, SEARCHABLE | - | - | 蒸留所名 |
| `CD_region` | String | - | - | - | 産地 |
| `CD_type` | String | - | - | - | タイプ（スコッチ、バーボン等） |
| `CD_vintage` | Int64 | - | - | 0 | ヴィンテージ年 |
| `CD_purchaseDate` | Date/Time | - | - | - | 購入日 |
| `CD_purchasePrice` | Double | - | - | 0.0 | 購入価格 |
| `CD_openedDate` | Date/Time | - | - | - | 開栓日 |
| `CD_notes` | String | - | - | - | メモ |
| `CD_shop` | String | - | - | - | 購入店 |
| `CD_createdAt` | Date/Time | - | - | - | 作成日時 |
| `CD_updatedAt` | Date/Time | - | - | - | 更新日時 |

### リレーションシップ

- `CD_drinkingLogs`: CD_DrinkingLogへの逆参照（複数）
- `CD_photos`: CD_BottlePhotoへの逆参照（複数）

**注意**: CloudKitでは逆リレーションシップは自動的に設定されないため、手動での設定は不要です。子レコード側（CD_DrinkingLog、CD_BottlePhoto）から親レコード（CD_Bottle）への参照のみを設定します。

---

## 2️⃣ CD_WishlistItem

### フィールド定義

| フィールド名 | タイプ | インデックス設定 | 必須 | デフォルト値 | 備考 |
|------------|--------|-----------------|------|------------|------|
| `recordName` | String | - | システム | - | CloudKitが自動生成 |
| `CD_id` | String | - | ○ | - | UUID文字列 |
| `CD_name` | String | QUERYABLE, SEARCHABLE | - | - | アイテム名 |
| `CD_priority` | Int64 | - | - | 0 | 優先度 |
| `CD_distillery` | String | - | - | - | 蒸留所名 |
| `CD_budget` | Double | - | - | 0.0 | 予算 |
| `CD_targetPrice` | Double | - | - | 0.0 | 目標価格 |
| `CD_notes` | String | - | - | - | メモ |
| `CD_createdAt` | Date/Time | - | - | - | 作成日時 |
| `CD_updatedAt` | Date/Time | - | - | - | 更新日時 |

---

## 3️⃣ CD_DrinkingLog

### フィールド定義

| フィールド名 | タイプ | インデックス設定 | 必須 | デフォルト値 | 備考 |
|------------|--------|-----------------|------|------------|------|
| `recordName` | String | - | システム | - | CloudKitが自動生成 |
| `CD_id` | String | - | ○ | - | UUID文字列 |
| `CD_date` | Date/Time | - | - | - | 飲酒日 |
| `CD_volume` | Int64 | - | - | 30 | 飲んだ量（ml） |
| `CD_notes` | String | - | - | - | メモ |
| `CD_createdAt` | Date/Time | - | - | - | 作成日時 |
| `CD_bottle` | Reference | - | - | - | CD_Bottleへの参照 |

### リレーションシップ

- `CD_bottle`: CD_Bottleへの参照（必須ではないが推奨）

**参照設定**:
- Reference to: `CD_Bottle`
- Delete Action: `Nullify` または `Cascade`（親ボトルが削除されたら記録も削除する場合はCascade）

---

## 4️⃣ CD_BottlePhoto

### フィールド定義

| フィールド名 | タイプ | インデックス設定 | 必須 | デフォルト値 | 備考 |
|------------|--------|-----------------|------|------------|------|
| `recordName` | String | - | システム | - | CloudKitが自動生成 |
| `CD_id` | String | - | ○ | - | UUID文字列 |
| `CD_fileName` | String | - | - | - | ファイル名 |
| `CD_fileSize` | Int64 | - | - | 0 | ファイルサイズ（バイト） |
| `CD_isMain` | Int64 | - | - | 0 | メイン画像フラグ（0=false, 1=true） |
| `CD_createdAt` | Date/Time | - | - | - | 作成日時 |
| `CD_bottle` | Reference | - | - | - | CD_Bottleへの参照 |

### リレーションシップ

- `CD_bottle`: CD_Bottleへの参照（必須ではないが推奨）

**参照設定**:
- Reference to: `CD_Bottle`
- Delete Action: `Nullify` または `Cascade`

---

## 🔧 CloudKitダッシュボードでの作成手順

### 前提条件
- Apple Developer Accountにログイン
- Team ID: `B3QHWZX47Z`
- Container ID: `iCloud.com.bottlekeep.whiskey`

### 手順

1. **CloudKit Consoleにアクセス**
   - https://icloud.developer.apple.com/dashboard/
   - Container `iCloud.com.bottlekeep.whiskey` を選択

2. **Development環境を選択**
   - 上部のドロップダウンから "Development" を選択

3. **Record Typesページを開く**
   - 左メニューから "Schema" → "Record Types" を選択

4. **各レコードタイプを作成**

   **4.1 CD_Bottleを作成**
   - "+" ボタンをクリック
   - Type Name: `CD_Bottle`
   - 上記の表に従って各フィールドを追加
     - "Add Field" をクリック
     - Field Name, Field Type, Indexを設定
     - QUERYABLEフィールドは "Add Index" で "Queryable" を選択
     - SEARCHABLEフィールドは "Add Index" で "Searchable" を選択

   **4.2 CD_WishlistItemを作成**
   - 同様に作成

   **4.3 CD_DrinkingLogを作成**
   - 同様に作成
   - `CD_bottle` フィールドは Type を "Reference" に設定
   - Reference Type: `CD_Bottle` を選択
   - Delete Action: `Cascade` を選択（推奨）

   **4.4 CD_BottlePhotoを作成**
   - 同様に作成
   - `CD_bottle` フィールドは Type を "Reference" に設定
   - Reference Type: `CD_Bottle` を選択
   - Delete Action: `Cascade` を選択（推奨）

5. **スキーマの確認**
   - 4つのレコードタイプが作成されたことを確認
   - 各フィールドの設定を再確認

6. **Productionにデプロイ**
   - "Deploy Schema Changes..." ボタンをクリック
   - "Deploy to Production" を選択
   - 変更内容を確認して "Deploy" をクリック

7. **確認**
   - 上部のドロップダウンから "Production" を選択
   - 4つのレコードタイプが存在することを確認

---

## 📝 重要な注意事項

### データタイプのマッピング

Core DataとCloudKitのデータタイプには以下の違いがあります：

| Core Data | CloudKit | 備考 |
|-----------|----------|------|
| UUID | String | UUIDを文字列として保存 |
| Integer 16/32/64 | Int64 | すべてInt64に統一 |
| Decimal | Double | 精度が異なるため注意 |
| Boolean | Int64 | 0（false）または1（true） |

### フィールド名のプレフィックス

- Core Dataエンティティ名: `Bottle`, `WishlistItem`, etc.
- CloudKitレコードタイプ名: `CD_Bottle`, `CD_WishlistItem`, etc.
- CloudKitフィールド名: `CD_id`, `CD_name`, `CD_createdAt`, etc.

すべてのフィールドに `CD_` プレフィックスが付きます（Core Dataの命名規則）。

### インデックス設定

検索やクエリで使用するフィールドには適切なインデックスを設定してください：
- **QUERYABLE**: `NSPredicate`でのクエリに使用
- **SEARCHABLE**: テキスト検索に使用

推奨設定：
- `CD_name` (Bottle, WishlistItem): QUERYABLE + SEARCHABLE
- `CD_distillery` (Bottle): QUERYABLE + SEARCHABLE

### Productionデプロイの注意

⚠️ **重要**: Productionにデプロイしたスキーマは削除できません
- フィールドの追加は可能
- フィールドの削除や型変更は制限があります
- 必ずDevelopment環境で十分にテストしてからProductionにデプロイしてください

---

## ✅ 作成後のチェックリスト

- [ ] CD_Bottleが17フィールド + 参照で作成されている
- [ ] CD_WishlistItemが9フィールドで作成されている
- [ ] CD_DrinkingLogが5フィールド + CD_Bottle参照で作成されている
- [ ] CD_BottlePhotoが5フィールド + CD_Bottle参照で作成されている
- [ ] name/distilleryフィールドにQUERYABLE + SEARCHABLEインデックスが設定されている
- [ ] Reference typeのDelete ActionがCascadeに設定されている
- [ ] Development環境からProduction環境にデプロイ完了
- [ ] Production環境で4つのレコードタイプが確認できる

---

**作成日時**: 2025-10-04
**ソース**: BottleKeeper.xcdatamodel/contents
