# iCloud CloudKit 同期設定手順

このアプリでデバイス間のデータ同期を有効にするには、以下の手順でCloudKitを設定してください。

## 前提条件

- 有効なApple Developer Programアカウント
- Xcode 15.0以降
- iCloudアカウントでサインインしたデバイス

## 設定手順

### 1. Xcodeプロジェクトを開く

1. `BottleKeeper.xcodeproj`を開く
2. プロジェクトナビゲーターで`BottleKeeper`プロジェクトを選択
3. `TARGETS` → `BottleKeeper`を選択

### 2. Signing & Capabilitiesタブを開く

1. 上部タブから`Signing & Capabilities`を選択
2. `Team`を選択（Apple Developer Programチーム）
3. `Automatically manage signing`にチェックが入っていることを確認

### 3. iCloud Capabilityを追加

1. `+ Capability`ボタンをクリック
2. `iCloud`を検索して追加
3. 追加されたiCloudセクションで以下を設定:
   - `CloudKit`にチェック
   - `Containers`セクションで`+ ボタン`をクリック
   - 新しいコンテナを作成: `iCloud.com.yourname.BottleKeeper`
     - **注意**: `yourname`を実際のBundle Identifierに合わせて変更してください
     - 例: `iCloud.com.example.BottleKeeper`

### 4. CloudKit Container Identifierの更新

`CoreDataManager.swift`を開いて、CloudKitコンテナIDを更新してください:

```swift
description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.yourname.BottleKeeper"  // ← 実際のIDに変更
)
```

### 5. Entitlementsファイルの確認

`BottleKeeper.entitlements`ファイルが以下の内容になっていることを確認:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.yourname.BottleKeeper</string>  <!-- 実際のIDに変更 -->
</array>
```

### 6. テスト

1. アプリをビルドして実行
2. 異なるデバイス(または削除して再インストール)でアプリを起動
3. 同じiCloudアカウントでサインイン
4. データが同期されることを確認

## トラブルシューティング

### エラー: "CloudKit container not found"

**原因**: CloudKitコンテナが正しく設定されていない

**解決法**:
1. Xcode → Signing & Capabilitiesでコンテナ名を確認
2. Bundle Identifierとコンテナ名が一致しているか確認
3. Apple Developer Portalで該当のコンテナが作成されているか確認

### エラー: "Not authenticated with iCloud"

**原因**: デバイスがiCloudにサインインしていない

**解決法**:
1. 設定 → [ユーザー名] → iCloudでサインイン
2. iCloud Driveがオンになっているか確認
3. アプリを再起動

### データが同期されない

**原因**:
- ネットワーク接続の問題
- CloudKitサーバーの遅延
- 既存データとの競合

**解決法**:
1. インターネット接続を確認
2. 数分待ってから確認(CloudKitの同期には時間がかかることがあります)
3. アプリを完全に削除して再インストール
4. 異なるデバイスで新規にデータを作成してテスト

### 既存データが同期されない

**原因**: アプリのインストール時期とCloudKit実装のタイミング

**解決法**:
1. 各デバイスでアプリを削除
2. 最新版のアプリを全デバイスにインストール
3. 同じiCloudアカウントでサインイン
4. 1つのデバイスでデータを作成
5. 他のデバイスで同期されるまで数分待つ

## コード実装詳細

### CoreDataManager.swift

```swift
let container: NSPersistentCloudKitContainer

init(inMemory: Bool = false) {
    container = NSPersistentCloudKitContainer(name: "BottleKeeper")

    if !inMemory {
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("persistentStoreDescription not found")
        }

        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.yourname.BottleKeeper"
        )

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }

    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
}
```

### 主な変更点

1. **NSPersistentContainer → NSPersistentCloudKitContainer**
   - CloudKit統合に必要

2. **cloudKitContainerOptions**
   - CloudKitコンテナIDを指定

3. **Persistent History Tracking**
   - デバイス間の変更を追跡

4. **Merge Policy**
   - 競合解決の方法を指定

## 参考資料

- [Apple Developer Documentation - Setting Up Core Data with CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [CloudKit Console](https://icloud.developer.apple.com/)
- [Core Data + CloudKit Best Practices](https://developer.apple.com/videos/play/wwdc2021/10017/)
