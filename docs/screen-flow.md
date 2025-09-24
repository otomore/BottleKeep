# BottleKeep 画面遷移図・ナビゲーション設計書

## 1. 概要

### 1.1 目的
BottleKeepアプリの全画面とそれらの間の遷移フローを明確に定義し、一貫したナビゲーション体験を提供する。SwiftUIの実装時に正確な画面構造を構築できるよう、詳細な遷移ルールを記載する。

### 1.2 設計原則
- **直感的なナビゲーション**: ユーザーが迷わない明確な動線
- **最小タップ数**: 目的の画面へ最短ルートでアクセス
- **一貫性**: 全画面で統一されたナビゲーションパターン
- **戻り動作**: 常に前の画面に戻れる設計

## 2. アプリ全体構造

### 2.1 基本ナビゲーション構造
```
BottleKeepApp
└── ContentView (TabView)
    ├── BottleListTab (NavigationStack)
    ├── WishlistTab (NavigationStack)
    ├── StatisticsTab (NavigationStack)
    └── SettingsTab (NavigationStack)
```

### 2.2 タブバー構成
```swift
TabView {
    BottleListView()
        .tabItem {
            Image(systemName: "bottle.fill")
            Text("コレクション")
        }
        .tag(0)

    WishlistView()
        .tabItem {
            Image(systemName: "heart.fill")
            Text("ウィッシュリスト")
        }
        .tag(1)

    StatisticsView()
        .tabItem {
            Image(systemName: "chart.bar.fill")
            Text("統計")
        }
        .tag(2)

    SettingsView()
        .tabItem {
            Image(systemName: "gearshape.fill")
            Text("設定")
        }
        .tag(3)
}
```

## 3. 詳細画面遷移フロー

### 3.1 ボトルコレクション画面群

#### 3.1.1 メイン遷移フロー
```
BottleListView (一覧)
├── BottleDetailView (詳細) ← タップ
│   ├── BottleEditView (編集) ← "編集"ボタン
│   │   └── PhotoPickerView (写真選択) ← "写真追加"
│   ├── PhotoGalleryView (写真一覧) ← 写真タップ
│   │   └── PhotoDetailView (写真詳細) ← 写真タップ
│   └── ConsumptionLogView (消費履歴) ← "飲酒記録"
├── BottleFormView (新規登録) ← "+"ボタン
│   └── PhotoPickerView (写真選択) ← "写真追加"
├── SearchView (検索) ← 検索バー
└── FilterView (フィルタ) ← フィルタボタン
```

#### 3.1.2 画面詳細仕様

**BottleListView (ボトル一覧)**
- **ナビゲーション**: TabView内のNavigationStack
- **表示形式**: LazyVStack（無限スクロール対応）
- **ヘッダー**: 検索バー + フィルタボタン
- **ツールバー**: "+"ボタン（新規登録）
- **遷移**:
  - ボトルカードタップ → BottleDetailView
  - "+"ボタン → BottleFormView（sheet）
  - 検索バー → SearchView（overlay）
  - フィルタボタン → FilterView（sheet）

**BottleDetailView (ボトル詳細)**
- **ナビゲーション**: NavigationLink destination
- **表示形式**: ScrollView（セクション分け）
- **ツールバー**: "編集"ボタン、"共有"ボタン
- **セクション**: 基本情報、写真、購入情報、テイスティングノート、消費履歴
- **遷移**:
  - "編集"ボタン → BottleEditView（sheet）
  - 写真タップ → PhotoGalleryView
  - "飲酒記録"ボタン → ConsumptionLogView

**BottleFormView (新規登録・編集)**
- **ナビゲーション**: Sheet presentation
- **表示形式**: Form（セクション分け）
- **ヘッダー**: "キャンセル"、"保存"ボタン
- **入力項目**: 基本情報、購入情報、写真、評価・ノート
- **遷移**:
  - "写真追加"ボタン → PhotoPickerView
  - "保存"ボタン → データ保存後dismiss
  - "キャンセル"ボタン → dismiss

### 3.2 検索・フィルタ画面群

#### 3.2.1 検索フロー
```
SearchView (検索画面)
├── 検索バー入力
├── 検索履歴表示
├── 候補表示（リアルタイム）
└── 検索結果 → BottleDetailView
```

**SearchView (検索画面)**
- **ナビゲーション**: Overlay presentation
- **表示形式**: VStack（検索バー + 結果リスト）
- **機能**: リアルタイム検索、検索履歴、検索候補
- **遷移**:
  - 結果タップ → BottleDetailView
  - 空エリアタップ → dismiss

#### 3.2.2 フィルタフロー
```
FilterView (フィルタ画面)
├── カテゴリー選択
├── 地域選択
├── 価格帯選択
├── 残量状況選択
└── 適用 → BottleListView更新
```

**FilterView (フィルタ画面)**
- **ナビゲーション**: Sheet presentation
- **表示形式**: Form（フィルタ項目）
- **フィルタ項目**: カテゴリー、地域、価格帯、残量、評価、開栓状況
- **遷移**:
  - "適用"ボタン → フィルタ適用してdismiss
  - "リセット"ボタン → フィルタクリア
  - "キャンセル"ボタン → dismiss

### 3.3 ウィッシュリスト画面群

#### 3.3.1 ウィッシュリスト遷移フロー
```
WishlistView (ウィッシュリスト)
├── WishlistItemDetailView (詳細) ← タップ
│   └── WishlistEditView (編集) ← "編集"ボタン
├── WishlistFormView (新規追加) ← "+"ボタン
└── PurchaseLinkView (購入リンク) ← "購入"ボタン
```

**WishlistView (ウィッシュリスト一覧)**
- **ナビゲーション**: TabView内のNavigationStack
- **表示形式**: LazyVStack（優先度順ソート）
- **ツールバー**: "+"ボタン
- **遷移**:
  - アイテムタップ → WishlistItemDetailView
  - "+"ボタン → WishlistFormView（sheet）
  - "購入"ボタン → PurchaseLinkView（sheet）

### 3.4 統計画面群

#### 3.4.1 統計画面遷移フロー
```
StatisticsView (統計メイン)
├── CollectionStatsView (コレクション統計) ← カードタップ
├── ConsumptionStatsView (消費統計) ← カードタップ
├── PurchaseStatsView (購入統計) ← カードタップ
└── TrendAnalysisView (トレンド分析) ← カードタップ
```

**StatisticsView (統計メイン画面)**
- **ナビゲーション**: TabView内のNavigationStack
- **表示形式**: ScrollView（統計カード集合）
- **統計カード**: コレクション統計、消費統計、購入統計、トレンド分析
- **遷移**: 各カードタップ → 詳細統計画面

### 3.5 設定画面群

#### 3.5.1 設定画面遷移フロー
```
SettingsView (設定メイン)
├── ProfileSettingsView (プロフィール) ← タップ
├── NotificationSettingsView (通知設定) ← タップ
├── CloudSyncSettingsView (同期設定) ← タップ
├── ExportDataView (データエクスポート) ← タップ
├── AboutView (このアプリについて) ← タップ
└── PremiumUpgradeView (プレミアム) ← タップ
```

## 4. モーダル表示パターン

### 4.1 Sheet Presentation
```swift
// フォーム系画面（全画面表示）
.sheet(isPresented: $showingForm) {
    BottleFormView()
}

// 設定系画面（部分表示可能）
.sheet(isPresented: $showingSettings) {
    SettingsDetailView()
        .presentationDetents([.medium, .large])
}
```

### 4.2 Alert表示
```swift
// 削除確認
.alert("ボトルを削除", isPresented: $showingDeleteAlert) {
    Button("削除", role: .destructive) { deleteBottle() }
    Button("キャンセル", role: .cancel) { }
}

// エラー表示
.alert("エラー", isPresented: $showingError) {
    Button("OK") { }
} message: {
    Text(errorMessage)
}
```

### 4.3 ActionSheet表示
```swift
// 写真選択オプション
.confirmationDialog("写真を追加", isPresented: $showingPhotoOptions) {
    Button("カメラで撮影") { takePhoto() }
    Button("フォトライブラリから選択") { selectFromLibrary() }
    Button("キャンセル", role: .cancel) { }
}
```

## 5. iPad対応の画面構成

### 5.1 SplitView構成
```
iPad Layout (Landscape)
┌─────────────────┬─────────────────────────┐
│   Master View   │     Detail View         │
│                 │                         │
│ BottleListView  │  BottleDetailView       │
│ (Sidebar)       │  (Main Content)         │
│                 │                         │
│ - 検索バー      │  - 詳細情報             │
│ - フィルタ      │  - 写真ギャラリー       │
│ - ボトルリスト   │  - アクションボタン     │
└─────────────────┴─────────────────────────┘
```

### 5.2 iPad専用遷移
```swift
// iPad SplitView実装例
NavigationSplitView {
    // Sidebar
    BottleListSidebarView()
} detail: {
    // Detail
    if let selectedBottle = selectedBottle {
        BottleDetailView(bottle: selectedBottle)
    } else {
        EmptyDetailView()
    }
}
```

## 6. ナビゲーション実装詳細

### 6.1 NavigationPath管理
```swift
@StateObject private var navigationState = NavigationState()

class NavigationState: ObservableObject {
    @Published var path = NavigationPath()

    func navigateToBottleDetail(_ bottle: Bottle) {
        path.append(bottle)
    }

    func navigateToEdit(_ bottle: Bottle) {
        path.append(EditDestination.bottle(bottle))
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    // 状態保存・復元機能
    func saveNavigationState() {
        if let data = try? JSONEncoder().encode(path.codable) {
            UserDefaults.standard.set(data, forKey: "navigation_state")
        }
    }

    func restoreNavigationState() {
        guard let data = UserDefaults.standard.data(forKey: "navigation_state"),
              let codablePath = try? JSONDecoder().decode(NavigationPath.CodableRepresentation.self, from: data) else {
            return
        }
        path = NavigationPath(codablePath)
    }
}
```

### 6.2 Deep Link対応
```swift
enum DeepLinkDestination {
    case bottleDetail(UUID)
    case wishlistItem(UUID)
    case statistics
    case settings
}

// URL Scheme: bottlekeep://bottle/[UUID]
// Universal Link: https://bottlekeep.app/bottle/[UUID]
```

### 6.3 バックナビゲーション
```swift
// 戻るボタンカスタマイズ
.navigationBarBackButtonHidden(true)
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button(action: { dismiss() }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("戻る")
            }
        }
    }
}
```

## 7. 状態管理と画面間データ受け渡し

### 7.1 状態管理パターン
```swift
// 画面間共有状態
@StateObject private var bottleStore = BottleStore()
@StateObject private var navigationState = NavigationState()

// 親から子への伝播
.environmentObject(bottleStore)
.environmentObject(navigationState)
```

### 7.2 データ受け渡し例
```swift
// BottleListView → BottleDetailView
NavigationLink(value: bottle) {
    BottleCardView(bottle: bottle)
}

// BottleDetailView → BottleEditView (Sheet)
.sheet(isPresented: $showingEdit) {
    BottleEditView(bottle: bottle) { updatedBottle in
        // コールバックでデータ更新
        bottleStore.update(updatedBottle)
    }
}
```

## 8. アニメーション・トランジション

### 8.1 画面遷移アニメーション
```swift
// NavigationStack遷移
.navigationTransition(.slide)

// Sheet表示
.presentationTransition(.move(edge: .bottom))

// カスタムトランジション
.transition(.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .move(edge: .leading)
))
```

### 8.2 要素アニメーション
```swift
// リスト項目のアニメーション
.animation(.easeInOut(duration: 0.3), value: bottles)

// 状態変化のアニメーション
.animation(.spring(response: 0.5, dampingFraction: 0.8), value: isLoading)
```

## 9. エラーハンドリングと画面遷移

### 9.1 エラー時のナビゲーション
```swift
// エラー発生時の処理
func handleError(_ error: Error) {
    switch error {
    case BottleError.notFound:
        // 一覧画面に戻る
        navigationState.popToRoot()
        showErrorAlert = true
    case BottleError.networkError:
        // 現在画面でエラー表示
        showNetworkError = true
    }
}
```

### 9.2 オフライン時の画面制御
```swift
// ネットワーク状態による画面制御
.disabled(!networkMonitor.isConnected)
.overlay {
    if !networkMonitor.isConnected {
        OfflineIndicatorView()
    }
}
```

## 10. アクセシビリティとナビゲーション

### 10.1 VoiceOver対応
```swift
// ナビゲーション要素のアクセシビリティ
.accessibilityLabel("ボトル詳細に移動")
.accessibilityHint("タップしてボトルの詳細情報を表示")
.accessibilityIdentifier("bottle_detail_link")
```

### 10.2 キーボードナビゲーション
```swift
// iPadでのキーボードショートカット
.keyboardShortcut("n", modifiers: .command) // 新規作成
.keyboardShortcut("f", modifiers: .command) // 検索
.keyboardShortcut("w", modifiers: .command) // 画面を閉じる
```

---

## 付録: 画面遷移チェックリスト

### A.1 実装時確認項目
- [ ] 全画面からタブバーの他タブにアクセス可能
- [ ] 深い階層からもルートに戻る手段がある
- [ ] モーダル画面に適切な閉じるボタンがある
- [ ] エラー時に適切な画面に遷移する
- [ ] iPad/iPhone両方で正常に動作する
- [ ] VoiceOverで全ナビゲーションが使用可能
- [ ] Deep Linkで正しい画面に遷移する
- [ ] バックボタンの動作が直感的

### A.2 テスト項目
- [ ] 全画面遷移パスのテスト
- [ ] エラー状態での遷移テスト
- [ ] メモリリーク（画面積み重ね）のテスト
- [ ] 異なる画面サイズでのレイアウトテスト

---

**文書バージョン**: 1.0
**作成日**: 2025-09-23
**最終更新**: 2025-09-23
**作成者**: Claude Code

この画面遷移図により、開発時に正確で一貫したナビゲーション体験を実装できます。