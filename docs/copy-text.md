# BottleKeep エラーメッセージ・文言集

## 1. 概要

### 1.1 目的
BottleKeepアプリ内で使用する全ての文言を統一し、一貫したユーザー体験を提供する。エラーメッセージ、ボタンラベル、説明文等を日本語で整理し、Localizable.stringsファイルの作成に活用する。

### 1.2 文言設計原則
- **明確性**: ユーザーが理解しやすい表現
- **親しみやすさ**: 丁寧語を基本とした親近感のある言葉遣い
- **簡潔性**: 必要十分な情報を短く伝える
- **一貫性**: アプリ全体で統一された表現

### 1.3 トーン・マナー
- **基本トーン**: 丁寧かつフレンドリー
- **専門用語**: 最小限に留め、必要に応じて説明を併記
- **呼びかけ**: 「です・ます調」で統一

## 2. エラーメッセージ

### 2.1 データ操作エラー

#### 2.1.1 保存エラー
```swift
// Key: "error.save_failed"
"保存に失敗しました。もう一度お試しください。"

// Key: "error.save_failed_detail"
"データの保存中にエラーが発生しました。アプリを再起動して、再度お試しください。"

// Key: "error.save_failed_storage_full"
"端末の容量が不足しています。容量を確保してから再度お試しください。"

// Key: "error.save_failed_permission"
"データの保存権限がありません。設定を確認してください。"
```

#### 2.1.2 読み込みエラー
```swift
// Key: "error.load_failed"
"データの読み込みに失敗しました。"

// Key: "error.load_failed_corrupted"
"データファイルが破損している可能性があります。アプリを再インストールすることをおすすめします。"

// Key: "error.load_failed_migration"
"データの移行中にエラーが発生しました。サポートにお問い合わせください。"
```

#### 2.1.3 削除エラー
```swift
// Key: "error.delete_failed"
"削除に失敗しました。もう一度お試しください。"

// Key: "error.delete_failed_in_use"
"使用中のため削除できません。しばらく待ってから再度お試しください。"
```

### 2.2 ネットワークエラー

#### 2.2.1 接続エラー
```swift
// Key: "error.network.no_connection"
"インターネットに接続されていません。接続を確認してください。"

// Key: "error.network.timeout"
"接続がタイムアウトしました。しばらく待ってから再度お試しください。"

// Key: "error.network.server_error"
"サーバーエラーが発生しました。時間をおいて再度お試しください。"

// Key: "error.network.api_limit"
"API利用制限に達しました。しばらく待ってから再度お試しください。"
```

#### 2.2.2 同期エラー
```swift
// Key: "error.sync.icloud_unavailable"
"iCloudが利用できません。設定でiCloudが有効になっているか確認してください。"

// Key: "error.sync.quota_exceeded"
"iCloudの容量が不足しています。容量を確保してから再度お試しください。"

// Key: "error.sync.account_issue"
"iCloudアカウントに問題があります。設定を確認してください。"

// Key: "error.sync.failed"
"同期に失敗しました。ネットワーク接続を確認してから再度お試しください。"
```

### 2.3 バリデーションエラー

#### 2.3.1 必須項目エラー
```swift
// Key: "error.validation.name_required"
"銘柄名を入力してください。"

// Key: "error.validation.distillery_required"
"蒸留所名を入力してください。"

// Key: "error.validation.abv_required"
"アルコール度数を入力してください。"

// Key: "error.validation.volume_required"
"容量を入力してください。"
```

#### 2.3.2 形式エラー
```swift
// Key: "error.validation.abv_range"
"アルコール度数は0〜100%の範囲で入力してください。"

// Key: "error.validation.volume_positive"
"容量は0より大きい値を入力してください。"

// Key: "error.validation.remaining_volume_invalid"
"残量が総容量を超えています。正しい値を入力してください。"

// Key: "error.validation.price_positive"
"価格は0以上の値を入力してください。"

// Key: "error.validation.rating_range"
"評価は1〜5の範囲で選択してください。"

// Key: "error.validation.date_future"
"開栓日は購入日以降の日付を選択してください。"
```

### 2.4 権限エラー

#### 2.4.1 写真アクセス権限
```swift
// Key: "error.permission.photos_denied"
"写真ライブラリへのアクセスが許可されていません。設定で権限を有効にしてください。"

// Key: "error.permission.camera_denied"
"カメラへのアクセスが許可されていません。設定で権限を有効にしてください。"

// Key: "error.permission.photos_limited"
"写真ライブラリへのアクセスが制限されています。より多くの写真を選択するには、設定で権限を変更してください。"
```

#### 2.4.2 生体認証エラー
```swift
// Key: "error.biometric.not_available"
"生体認証が利用できません。"

// Key: "error.biometric.not_enrolled"
"生体認証が設定されていません。端末の設定で生体認証を有効にしてください。"

// Key: "error.biometric.authentication_failed"
"認証に失敗しました。もう一度お試しください。"

// Key: "error.biometric.user_cancel"
"認証がキャンセルされました。"

// Key: "error.biometric.lockout"
"認証試行回数が上限に達しました。しばらく待ってから再度お試しください。"
```

### 2.5 制限エラー（無料プラン）

#### 2.5.1 ボトル数制限
```swift
// Key: "error.limit.bottle_count"
"無料プランでは20本まで登録できます。プレミアムプランにアップグレードすると無制限で登録できます。"

// Key: "error.limit.photo_count"
"無料プランではボトル1つにつき3枚まで写真を追加できます。"

// Key: "error.limit.custom_category"
"無料プランでは3つまでカスタムカテゴリを作成できます。"
```

## 3. 成功メッセージ

### 3.1 操作完了メッセージ
```swift
// Key: "success.bottle_saved"
"ボトルを保存しました。"

// Key: "success.bottle_updated"
"ボトル情報を更新しました。"

// Key: "success.bottle_deleted"
"ボトルを削除しました。"

// Key: "success.photo_added"
"写真を追加しました。"

// Key: "success.photo_deleted"
"写真を削除しました。"

// Key: "success.data_exported"
"データをエクスポートしました。"

// Key: "success.sync_completed"
"同期が完了しました。"

// Key: "success.backup_created"
"バックアップを作成しました。"
```

## 4. ボタンラベル

### 4.1 基本操作ボタン
```swift
// Key: "button.save"
"保存"

// Key: "button.cancel"
"キャンセル"

// Key: "button.delete"
"削除"

// Key: "button.edit"
"編集"

// Key: "button.add"
"追加"

// Key: "button.close"
"閉じる"

// Key: "button.done"
"完了"

// Key: "button.ok"
"OK"

// Key: "button.retry"
"再試行"

// Key: "button.settings"
"設定"
```

### 4.2 機能固有ボタン
```swift
// Key: "button.take_photo"
"写真を撮る"

// Key: "button.select_photo"
"写真を選択"

// Key: "button.add_to_wishlist"
"ウィッシュリストに追加"

// Key: "button.mark_as_opened"
"開栓済みにする"

// Key: "button.record_consumption"
"飲酒記録"

// Key: "button.share"
"共有"

// Key: "button.export_data"
"データエクスポート"

// Key: "button.sync_now"
"今すぐ同期"

// Key: "button.upgrade_premium"
"プレミアムにアップグレード"
```

### 4.3 確認ダイアログボタン
```swift
// Key: "button.confirm_delete"
"削除する"

// Key: "button.confirm_overwrite"
"上書きする"

// Key: "button.keep_both"
"両方保持"

// Key: "button.replace"
"置き換える"

// Key: "button.merge"
"統合する"
```

## 5. ラベル・見出し

### 5.1 フォームラベル
```swift
// Key: "label.bottle_name"
"銘柄名"

// Key: "label.distillery"
"蒸留所"

// Key: "label.region"
"地域"

// Key: "label.type"
"種類"

// Key: "label.abv"
"アルコール度数"

// Key: "label.volume"
"容量"

// Key: "label.remaining_volume"
"残量"

// Key: "label.vintage"
"年代"

// Key: "label.purchase_date"
"購入日"

// Key: "label.purchase_price"
"購入価格"

// Key: "label.shop"
"購入店舗"

// Key: "label.opened_date"
"開栓日"

// Key: "label.rating"
"評価"

// Key: "label.notes"
"テイスティングノート"
```

### 5.2 統計ラベル
```swift
// Key: "label.total_bottles"
"総ボトル数"

// Key: "label.total_value"
"総価値"

// Key: "label.average_rating"
"平均評価"

// Key: "label.opened_bottles"
"開栓済み"

// Key: "label.unopened_bottles"
"未開栓"

// Key: "label.most_expensive"
"最高価格"

// Key: "label.least_expensive"
"最低価格"

// Key: "label.recent_purchases"
"最近の購入"

// Key: "label.consumption_this_month"
"今月の消費"
```

## 6. プレースホルダーテキスト

### 6.1 入力フィールド
```swift
// Key: "placeholder.bottle_name"
"例: 山崎 12年"

// Key: "placeholder.distillery"
"例: サントリー"

// Key: "placeholder.region"
"例: 日本"

// Key: "placeholder.type"
"例: シングルモルト"

// Key: "placeholder.shop"
"例: 酒屋田中"

// Key: "placeholder.notes"
"香り、味わい、フィニッシュなどを記録"

// Key: "placeholder.search"
"銘柄名や蒸留所で検索"

// Key: "placeholder.wishlist_item"
"欲しいボトルの名前"
```

## 7. 説明文・ヘルプテキスト

### 7.1 機能説明
```swift
// Key: "help.remaining_volume"
"現在の残量をmlまたは%で入力してください。"

// Key: "help.abv"
"ボトルに記載されているアルコール度数を入力してください。"

// Key: "help.vintage"
"蒸留年またはボトリング年を入力してください。"

// Key: "help.icloud_sync"
"iCloud同期を有効にすると、複数の端末でデータを共有できます。"

// Key: "help.biometric_auth"
"Face IDまたはTouch IDでアプリを保護できます。"

// Key: "help.data_export"
"すべてのデータをJSONファイルとしてエクスポートできます。"
```

### 7.2 状態説明
```swift
// Key: "status.syncing"
"同期中..."

// Key: "status.loading"
"読み込み中..."

// Key: "status.saving"
"保存中..."

// Key: "status.exporting"
"エクスポート中..."

// Key: "status.no_bottles"
"まだボトルが登録されていません。\n\"+\"ボタンから最初のボトルを追加しましょう。"

// Key: "status.no_wishlist_items"
"ウィッシュリストは空です。\n欲しいボトルを追加してみましょう。"

// Key: "status.no_search_results"
"該当するボトルが見つかりませんでした。\n検索条件を変更してみてください。"

// Key: "status.offline"
"オフライン - 一部の機能が制限されています"
```

## 8. 通知メッセージ

### 8.1 プッシュ通知
```swift
// Key: "notification.low_stock.title"
"残量少なし"

// Key: "notification.low_stock.body"
"%@の残量が少なくなっています。"

// Key: "notification.long_unused.title"
"開栓済みボトル"

// Key: "notification.long_unused.body"
"%@を長い間飲んでいません。たまには味わってみませんか？"

// Key: "notification.backup_reminder.title"
"バックアップのお知らせ"

// Key: "notification.backup_reminder.body"
"データのバックアップを作成することをおすすめします。"
```

### 8.2 アプリ内通知
```swift
// Key: "toast.photo_saved"
"写真を保存しました"

// Key: "toast.copied_to_clipboard"
"クリップボードにコピーしました"

// Key: "toast.filter_applied"
"フィルターを適用しました"

// Key: "toast.sort_updated"
"並び順を変更しました"
```

## 9. オンボーディング・チュートリアル

### 9.1 初回起動時
```swift
// Key: "onboarding.welcome.title"
"BottleKeepへようこそ"

// Key: "onboarding.welcome.subtitle"
"あなたのウイスキーコレクションを\n美しく管理しましょう"

// Key: "onboarding.features.title"
"主な機能"

// Key: "onboarding.features.collection"
"コレクション管理\nボトルの詳細情報と写真を記録"

// Key: "onboarding.features.tasting"
"テイスティングノート\n味わいの記録と評価"

// Key: "onboarding.features.statistics"
"統計分析\nコレクションの傾向を把握"

// Key: "onboarding.privacy.title"
"プライバシー保護"

// Key: "onboarding.privacy.description"
"あなたのデータは端末内に安全に保存され、\n同意なしに外部に送信されることはありません。"

// Key: "onboarding.get_started"
"はじめる"
```

### 9.2 機能紹介
```swift
// Key: "tutorial.add_bottle.title"
"最初のボトルを追加"

// Key: "tutorial.add_bottle.description"
"\"+\"ボタンから新しいボトルを追加できます。"

// Key: "tutorial.take_photo.title"
"写真を追加"

// Key: "tutorial.take_photo.description"
"カメラボタンから美しいボトル写真を撮影しましょう。"

// Key: "tutorial.rate_bottle.title"
"評価とノート"

// Key: "tutorial.rate_bottle.description"
"星評価とテイスティングノートで味わいを記録できます。"
```

## 10. 設定画面

### 10.1 設定項目
```swift
// Key: "settings.general"
"一般"

// Key: "settings.privacy"
"プライバシー"

// Key: "settings.data"
"データ"

// Key: "settings.appearance"
"外観"

// Key: "settings.about"
"このアプリについて"

// Key: "settings.icloud_sync"
"iCloud同期"

// Key: "settings.biometric_auth"
"生体認証"

// Key: "settings.notifications"
"通知"

// Key: "settings.default_volume"
"デフォルト容量"

// Key: "settings.currency"
"通貨"

// Key: "settings.theme"
"テーマ"

// Key: "settings.language"
"言語"
```

### 10.2 設定説明
```swift
// Key: "settings.icloud_sync.description"
"複数の端末でデータを共有します"

// Key: "settings.biometric_auth.description"
"Face IDまたはTouch IDでアプリを保護"

// Key: "settings.notifications.description"
"残量少なしなどの通知を受け取る"

// Key: "settings.analytics.description"
"匿名の使用統計でアプリ改善に協力"
```

## 11. 単位・数値表示

### 11.1 単位表示
```swift
// Key: "unit.ml"
"ml"

// Key: "unit.percent"
"%"

// Key: "unit.yen"
"円"

// Key: "unit.bottles"
"本"

// Key: "unit.days"
"日"

// Key: "unit.months"
"ヶ月"

// Key: "unit.years"
"年"
```

### 11.2 相対日付
```swift
// Key: "date.today"
"今日"

// Key: "date.yesterday"
"昨日"

// Key: "date.days_ago"
"%d日前"

// Key: "date.weeks_ago"
"%d週間前"

// Key: "date.months_ago"
"%dヶ月前"

// Key: "date.years_ago"
"%d年前"
```

## 12. エクスポート用 Localizable.strings

### 12.1 使用例
```strings
/* エラーメッセージ */
"error.save_failed" = "保存に失敗しました。もう一度お試しください。";
"error.network.no_connection" = "インターネットに接続されていません。接続を確認してください。";

/* ボタンラベル */
"button.save" = "保存";
"button.cancel" = "キャンセル";
"button.delete" = "削除";

/* フォームラベル */
"label.bottle_name" = "銘柄名";
"label.distillery" = "蒸留所";
"label.abv" = "アルコール度数";

/* プレースホルダー */
"placeholder.bottle_name" = "例: 山崎 12年";
"placeholder.search" = "銘柄名や蒸留所で検索";

/* 成功メッセージ */
"success.bottle_saved" = "ボトルを保存しました。";
"toast.photo_saved" = "写真を保存しました";
```

### 12.2 多言語対応準備
```swift
// 将来の英語対応時のキー設計
enum LocalizedKey: String {
    case errorSaveFailed = "error.save_failed"
    case buttonSave = "button.save"
    case labelBottleName = "label.bottle_name"

    var localized: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}

// 使用例
Text(LocalizedKey.buttonSave.localized)
```

---

## 付録: 文言管理ベストプラクティス

### A.1 キーの命名規則
- **エラー**: `error.category.specific`
- **ボタン**: `button.action`
- **ラベル**: `label.field_name`
- **プレースホルダー**: `placeholder.field_name`
- **説明**: `help.topic`
- **通知**: `notification.type.element`

### A.2 文言更新時の注意点
- [ ] 既存キーの変更は影響範囲を確認
- [ ] 新しい文言は一貫性を保つ
- [ ] 長すぎる文言は改行位置を考慮
- [ ] 専門用語は必要に応じて説明を追加

### A.3 実装時チェックリスト
- [ ] 全ての文言がLocalizable.stringsに定義済み
- [ ] ハードコーディングされた文言がない
- [ ] Dynamic Typeに対応したレイアウト
- [ ] 文言の長さによるレイアウト崩れがない

---

**文書バージョン**: 1.0
**作成日**: 2025-09-23
**最終更新**: 2025-09-23
**作成者**: Claude Code

この文言集により、一貫したユーザー体験と効率的な多言語対応の基盤を構築できます。