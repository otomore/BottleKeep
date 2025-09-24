# BottleKeep - ウイスキーコレクション管理アプリ

## 概要
BottleKeepは、ウイスキーコレクションを効率的に管理するためのiOS/iPadOSネイティブアプリです。

## 機能
- ✅ ボトル管理（登録・編集・削除・一覧表示）
- ✅ 写真管理（撮影・保存・表示）
- ✅ 検索・フィルタ機能
- ✅ Core Data + CloudKit統合
- ✅ テイスティングノート・評価機能
- 🔄 統計情報表示（実装予定）
- 🔄 ウィッシュリスト機能（実装予定）

## 技術スタック
- **言語**: Swift 5.9+
- **フレームワーク**: SwiftUI
- **データベース**: Core Data + CloudKit
- **アーキテクチャ**: MVVM + Repository Pattern
- **最小対応バージョン**: iOS 16.0+

## プロジェクト構造
```
BottleKeep/
├── BottleKeep/
│   ├── App/                    # アプリケーション起点
│   │   └── BottleKeepApp.swift
│   ├── Views/                  # SwiftUI Views
│   │   ├── ContentView.swift
│   │   ├── BottleListView.swift
│   │   ├── BottleDetailView.swift
│   │   ├── BottleFormView.swift
│   │   ├── WishlistView.swift
│   │   ├── StatisticsView.swift
│   │   └── SettingsView.swift
│   ├── ViewModels/            # ViewModels
│   │   ├── BottleListViewModel.swift
│   │   ├── BottleDetailViewModel.swift
│   │   ├── BottleFormViewModel.swift
│   │   └── StatisticsViewModel.swift
│   ├── Models/                # Core Data Models
│   │   ├── Bottle+CoreDataClass.swift
│   │   ├── Bottle+CoreDataProperties.swift
│   │   ├── BottlePhoto+CoreDataClass.swift
│   │   └── BottlePhoto+CoreDataProperties.swift
│   ├── Repositories/          # データアクセス層
│   │   ├── BottleRepositoryProtocol.swift
│   │   └── BottleRepository.swift
│   ├── Services/             # サービス層
│   │   ├── CoreDataManager.swift
│   │   ├── PhotoManager.swift
│   │   └── DIContainer.swift
│   └── Resources/            # リソースファイル
│       ├── BottleKeep.xcdatamodeld/
│       └── Info.plist
├── BottleKeepTests/          # Unit Tests
└── BottleKeepUITests/        # UI Tests
```

## セットアップ方法

### 必要な環境
- macOS 13.0 (Ventura) 以上
- Xcode 15.0 以上
- iOS 16.0以上の端末（実機テスト用）

### 手順
1. Xcodeでプロジェクトを開く
   ```bash
   open BottleKeep.xcodeproj
   ```

2. Apple Developer Accountでサインイン（CloudKit使用のため）

3. Bundle Identifierを設定
   - Target: BottleKeep
   - Bundle Identifier: com.yourname.bottlekeep

4. CloudKit設定
   - Capabilities → iCloud → CloudKit を有効化
   - Container: iCloud.com.yourname.bottlekeep

5. ビルド・実行
   ```bash
   ⌘+R
   ```

## 開発状況
- ✅ プロジェクト構造設計完了
- ✅ Core Data モデル実装完了
- ✅ Repository層実装完了
- ✅ ViewModel層実装完了
- ✅ 基本UI実装完了
- ✅ 基本的なCRUD操作実装完了
- 🔄 テスト実装中
- ⏳ 統計機能実装予定
- ⏳ ウィッシュリスト機能実装予定

## テスト実行
```bash
# Unit Test
⌘+U

# または コマンドライン
xcodebuild test \
  -scheme BottleKeep \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
```

## ライセンス
個人プロジェクト

## 作成者
BottleKeep Development Team