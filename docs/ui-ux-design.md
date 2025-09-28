# BottleKeeper UI/UX設計書

## 1. デザイン概要

### 1.1 デザイン哲学
- **ミニマリズム**: 機能を優先したシンプルなデザイン
- **iOS Native**: Human Interface Guidelinesに準拠
- **アクセシビリティ**: すべてのユーザーが使いやすいインターフェース
- **効率性**: 最小タップ数での目的達成

### 1.2 デザインシステム

#### カラーパレット
```swift
struct ColorScheme {
    // Primary Colors
    static let primary = Color.blue
    static let secondary = Color.orange

    // Neutral Colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)

    // Text Colors
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)

    // Status Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red

    // Whiskey Theme Colors
    static let amber = Color(red: 0.96, green: 0.76, blue: 0.33)
    static let bourbon = Color(red: 0.72, green: 0.45, blue: 0.20)
    static let peat = Color(red: 0.34, green: 0.31, blue: 0.25)
}
```

#### タイポグラフィ
```swift
struct Typography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title1 = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.medium)
    static let title3 = Font.title3.weight(.medium)
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
}
```

#### アイコンセット
- SF Symbols 4.0使用
- カスタムウイスキーアイコン（必要に応じて）

#### レスポンシブデザイン
```swift
struct ResponsiveLayout {
    // iPhone対応
    static let minTouchTarget: CGFloat = 44
    static let standardPadding: CGFloat = 16
    static let compactPadding: CGFloat = 12

    // iPad対応
    static let wideScreenThreshold: CGFloat = 600
    static let sidePadding: CGFloat = 32
    static let maxContentWidth: CGFloat = 1024
}
```
- 一貫したアイコンサイズ（16pt, 20pt, 24pt）

## 2. 画面構成・情報アーキテクチャ

### 2.1 アプリ構造
```
TabView (Main Navigation)
├── Bottles Tab
│   ├── BottleListView
│   │   ├── SearchBar
│   │   ├── FilterOptions
│   │   └── BottleCard (List/Grid)
│   ├── BottleDetailView
│   │   ├── PhotoCarousel
│   │   ├── BasicInfo
│   │   ├── PurchaseInfo
│   │   ├── TastingNotes
│   │   └── Actions
│   └── BottleFormView
│       ├── PhotoSection
│       ├── BasicInfoForm
│       ├── PurchaseInfoForm
│       └── TastingSection
├── Wishlist Tab
│   ├── WishlistView
│   │   └── WishlistCard
│   └── WishlistFormView
├── Statistics Tab
│   ├── StatisticsView
│   │   ├── Overview
│   │   ├── Charts
│   │   └── Insights
└── Settings Tab
    ├── SettingsView
    │   ├── iCloud Sync
    │   ├── Export Data
    │   ├── About
    └── └── Privacy Policy
```

### 2.2 ナビゲーションパターン
- **Tab Navigation**: メイン機能間の移動
- **Navigation Stack**: 階層的な画面遷移
- **Modal Presentation**: フォーム・設定画面
- **Sheet Presentation**: 軽量なアクション

## 3. 詳細画面設計

### 3.1 BottleListView（ボトル一覧）

#### レイアウト構成
```
┌─────────────────────────────────────┐
│ Bottles                    [+ Add]  │ ← Navigation Bar
├─────────────────────────────────────┤
│ 🔍 Search bottles...               │ ← Search Bar
├─────────────────────────────────────┤
│ [All] [Opened] [Closed] [Rating⭐]  │ ← Filter Chips
├─────────────────────────────────────┤
│ ┌─────┐ Macallan 18              ⭐│ ← Bottle Card
│ │Photo│ Single Malt Scotch         │
│ │     │ Purchased: 2023-05-15      │
│ └─────┘ ¥45,000                    │
├─────────────────────────────────────┤
│ ┌─────┐ Hibiki 17                 ⭐│
│ │Photo│ Japanese Blended           │
│ │     │ Opened: 2023-08-20         │
│ └─────┘ ¥28,000                    │
└─────────────────────────────────────┘
```

#### 表示モード
1. **List Mode**: 詳細情報を含む縦列表示
2. **Grid Mode**: 写真中心の格子表示
3. **Compact Mode**: 最小情報での密集表示

#### インタラクション
- **Tap**: 詳細画面へ遷移
- **Long Press**: クイックアクションメニュー
- **Swipe Left**: 削除アクション
- **Swipe Right**: お気に入り追加
- **Pull to Refresh**: データ同期

### 3.2 BottleDetailView（ボトル詳細）

#### レイアウト構成
```
┌─────────────────────────────────────┐
│ ←                          [Edit]   │ ← Navigation Bar
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │ ← Photo Carousel
│ │         Main Photo              │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│ ● ○ ○                              │ ← Photo Indicators
├─────────────────────────────────────┤
│ Macallan 18 Year Old               │ ← Title
│ Single Malt Scotch Whisky          │ ← Subtitle
│ ⭐⭐⭐⭐⭐ (5.0)                      │ ← Rating
├─────────────────────────────────────┤
│ 📍 Speyside, Scotland              │ ← Basic Info
│ 🥃 43% ABV • 700ml                 │
│ 📅 Vintage: N/A                   │
├─────────────────────────────────────┤
│ 💰 Purchase Info                   │ ← Section Header
│ Date: May 15, 2023                 │
│ Price: ¥45,000                     │
│ Shop: Liquor Store Tokyo           │
├─────────────────────────────────────┤
│ 🍯 Tasting Notes                   │
│ Opened: Aug 20, 2023               │
│ Remaining: 650ml / 700ml           │
│ Notes: Rich honey and dried fruits │
│ with hints of oak and spice...     │
└─────────────────────────────────────┘
```

#### セクション構成
1. **Photo Carousel**: メイン写真とサブ写真
2. **Basic Information**: 基本情報
3. **Purchase Information**: 購入情報
4. **Tasting Information**: 飲酒・評価情報
5. **Action Buttons**: 編集・削除・共有

### 3.3 BottleFormView（ボトル登録・編集）

#### フォーム構成
```
┌─────────────────────────────────────┐
│ [Cancel]      Add Bottle     [Save] │ ← Navigation Bar
├─────────────────────────────────────┤
│ 📸 Photos                          │ ← Photo Section
│ ┌─────┐ ┌─────┐ ┌─────┐ [+]       │
│ │Photo│ │Photo│ │     │            │
│ │  1  │ │  2  │ │     │            │
│ └─────┘ └─────┘ └─────┘            │
├─────────────────────────────────────┤
│ 📋 Basic Information               │ ← Form Section
│ Name *         [Macallan 18      ] │
│ Distillery *   [Macallan         ] │
│ Region         [Speyside         ] │
│ Type           [Single Malt      ] │
│ ABV (%)        [43.0             ] │
│ Volume (ml)    [700              ] │
│ Vintage        [                 ] │
├─────────────────────────────────────┤
│ 💰 Purchase Information            │
│ Purchase Date  [May 15, 2023     ] │
│ Price          [¥45,000          ] │
│ Shop           [Liquor Store     ] │
├─────────────────────────────────────┤
│ 🍯 Tasting Information             │
│ Opened Date    [                 ] │
│ Rating         ⭐⭐⭐⭐⭐            │
│ Notes          [Rich honey and   ] │
│                [dried fruits...  ] │
└─────────────────────────────────────┘
```

#### バリデーション
- **必須フィールド**: Name, Distillery
- **数値範囲**: ABV (0-100%), Volume (>0)
- **日付検証**: 購入日 ≤ 開栓日
- **リアルタイム検証**: 入力時即座にフィードバック

### 3.4 StatisticsView（統計情報）

#### ダッシュボード構成
```
┌─────────────────────────────────────┐
│ Statistics                         │ ← Navigation Bar
├─────────────────────────────────────┤
│ 📊 Overview                        │ ← Overview Section
│ ┌─────────┐ ┌─────────┐ ┌─────────┐│
│ │   45    │ │¥342,000 │ │  4.2/5  ││
│ │ Bottles │ │  Total  │ │ Avg Rate││
│ └─────────┘ └─────────┘ └─────────┘│
├─────────────────────────────────────┤
│ 🌍 By Region                       │ ← Chart Section
│ ┌─────────────────────────────────┐ │
│ │        Pie Chart                │ │
│ │    Scotland: 60%                │ │
│ │    Japan: 25%                   │ │
│ │    Ireland: 10%                 │ │
│ │    Others: 5%                   │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ 📈 Purchase Trend                  │
│ ┌─────────────────────────────────┐ │
│ │        Line Chart               │ │
│ │    Monthly purchases            │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ 🏆 Top Rated                       │ ← Insights Section
│ 1. Macallan 25    ⭐⭐⭐⭐⭐        │
│ 2. Hibiki 17      ⭐⭐⭐⭐⭐        │
│ 3. Ardbeg 10      ⭐⭐⭐⭐○        │
└─────────────────────────────────────┘
```

## 4. レスポンシブデザイン

### 4.1 iPhone対応
```swift
// iPhone Portrait
struct iPhonePortraitLayout {
    static let listItemHeight: CGFloat = 80
    static let photoCarouselHeight: CGFloat = 300
    static let tabBarHeight: CGFloat = 83
}

// iPhone Landscape
struct iPhoneLandscapeLayout {
    static let listItemHeight: CGFloat = 60
    static let photoCarouselHeight: CGFloat = 200
}
```

### 4.2 iPad対応
```swift
// iPad Portrait
struct iPadPortraitLayout {
    static let maxContentWidth: CGFloat = 600
    static let sidebarWidth: CGFloat = 320
    static let detailMinWidth: CGFloat = 500
}

// iPad Landscape
struct iPadLandscapeLayout {
    static let navigationSplitView = true
    static let sidebarWidth: CGFloat = 380
    static let detailMinWidth: CGFloat = 600
}
```

### 4.3 アダプティブレイアウト
```swift
struct AdaptiveBottleListView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            // iPhone Layout
            NavigationView {
                BottleListView()
            }
        } else {
            // iPad Layout
            NavigationSplitView {
                BottleListSidebar()
            } detail: {
                BottleDetailView()
            }
        }
    }
}
```

## 5. インタラクションデザイン

### 5.1 ジェスチャーマップ
```swift
struct GestureMap {
    // List View
    static let tapToDetail = TapGesture()
    static let longPressMenu = LongPressGesture(minimumDuration: 0.5)
    static let swipeToDelete = DragGesture()
    static let pullToRefresh = DragGesture()

    // Detail View
    static let photoZoom = MagnificationGesture()
    static let photoSwipe = DragGesture()
    static let doubleTapZoom = TapGesture(count: 2)

    // Form View
    static let tapToDismiss = TapGesture()
    static let swipeToNavigate = DragGesture()
}
```

### 5.2 アニメーション仕様
```swift
struct AnimationSpecs {
    static let standard = Animation.easeInOut(duration: 0.3)
    static let quick = Animation.easeInOut(duration: 0.2)
    static let slow = Animation.easeInOut(duration: 0.5)

    // Custom animations
    static let cardFlip = Animation.easeInOut(duration: 0.6)
    static let slideIn = Animation.spring(dampingFraction: 0.8)
    static let fadeInOut = Animation.opacity.speed(1.5)
}
```

### 5.3 フィードバック
```swift
struct HapticFeedback {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
```

## 6. アクセシビリティ設計

### 6.1 VoiceOver対応
```swift
extension View {
    func bottleCardAccessibility(bottle: Bottle) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(bottle.name), \(bottle.distillery)")
            .accessibilityValue("Rating: \(bottle.rating)/5 stars")
            .accessibilityHint("Double tap to view details")
            .accessibilityAddTraits(.isButton)
    }
}
```

### 6.2 Dynamic Type対応
```swift
struct ScaledFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .dynamicTypeSize(.medium...(.accessibility3))
    }
}
```

### 6.3 高コントラスト対応
```swift
struct AccessibleColors {
    @Environment(\.colorSchemeContrast) var contrast

    var primaryButton: Color {
        contrast == .increased ? .black : .blue
    }

    var background: Color {
        contrast == .increased ? .white : Color(.systemBackground)
    }
}
```

## 7. ダークモード設計

### 7.1 カラーシステム
```swift
extension Color {
    static let adaptiveBackground = Color(.systemBackground)
    static let adaptiveSecondaryBackground = Color(.secondarySystemBackground)
    static let adaptiveTertiaryBackground = Color(.tertiarySystemBackground)

    static let adaptiveText = Color(.label)
    static let adaptiveSecondaryText = Color(.secondaryLabel)

    // Custom adaptive colors
    static let adaptiveAmber = Color("AdaptiveAmber") // Asset Catalog
    static let adaptivePrimary = Color("AdaptivePrimary")
}
```

### 7.2 Asset Catalog設定
```
AdaptiveAmber:
  - Any Appearance: #F5C242
  - Dark Appearance: #D4A520

AdaptivePrimary:
  - Any Appearance: #007AFF
  - Dark Appearance: #0A84FF
```

## 8. エラー状態・空状態UI

### 8.1 エラー状態
```swift
struct ErrorView: View {
    let error: AppError
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

### 8.2 空状態
```swift
struct EmptyBottleListView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wineglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No bottles yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start building your whiskey collection by adding your first bottle")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Your First Bottle") {
                // Action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 40)
    }
}
```

## 9. パフォーマンス最適化

### 9.1 レイジーローディング
```swift
struct LazyBottleGrid: View {
    let bottles: [Bottle]

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(bottles) { bottle in
                BottleCard(bottle: bottle)
                    .onAppear {
                        // Load additional data if needed
                    }
            }
        }
    }
}
```

### 9.2 画像最適化
```swift
struct OptimizedImageView: View {
    let imageURL: URL?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        // Async image loading with caching
    }
}
```

---

## 10. ユーザビリティテスト指針

### 10.1 主要タスクフロー
```swift
// 基本タスクの測定指標
struct UsabilityMetrics {
    // タスク1: ボトル登録
    static let addBottleTarget: TimeInterval = 120 // 2分以内
    static let addBottleSteps = 8 // 最大8ステップ

    // タスク2: ボトル検索
    static let searchBottleTarget: TimeInterval = 30 // 30秒以内
    static let searchBottleSteps = 3 // 最大3ステップ

    // タスク3: 統計確認
    static let viewStatsTarget: TimeInterval = 15 // 15秒以内
    static let viewStatsSteps = 2 // 最大2ステップ
}
```

### 10.2 ユーザビリティ原則
```swift
// Nielsen's 10 Usability Heuristics 適用
enum UsabilityPrinciple {
    case visibilityOfSystemStatus    // 同期状況の表示
    case matchSystemAndRealWorld     // ウイスキー用語の適切な使用
    case userControlAndFreedom      // 操作の取り消し機能
    case consistencyAndStandards    // iOS標準パターンの遵守
    case errorPrevention            // 入力バリデーション
    case recognitionRatherThanRecall // 視覚的な手がかり
    case flexibilityAndEfficiency   // ショートカット機能
    case aestheticAndMinimalistDesign // シンプルなインターフェース
    case helpUsersWithErrors        // エラー時の具体的な案内
    case helpAndDocumentation       // オンボーディング
}
```

### 10.3 A/Bテスト候補
```swift
// UI要素のA/Bテスト項目
struct ABTestCandidates {
    // ボトルカードレイアウト
    static let cardLayoutA = "写真重視（大きな写真）"
    static let cardLayoutB = "情報重視（詳細テキスト）"

    // ナビゲーション
    static let navigationA = "タブバーのみ"
    static let navigationB = "タブバー + サイドメニュー"

    // 評価システム
    static let ratingA = "5つ星評価"
    static let ratingB = "10点満点評価"
}
```

## 11. マイクロインタラクション

### 11.1 詳細アニメーション仕様
```swift
// ボトルカード相互作用
struct BottleCardMicroInteractions {
    // タップフィードバック
    static let tapScale = Animation.easeInOut(duration: 0.1)
    static let tapScaleAmount: CGFloat = 0.95

    // ホバー効果（iPad）
    static let hoverShadow = Animation.easeOut(duration: 0.2)
    static let hoverShadowRadius: CGFloat = 8

    // 削除スワイプ
    static let deleteReveal = Animation.spring(dampingFraction: 0.8)
    static let deleteThreshold: CGFloat = 100
}

// 写真ギャラリー
struct PhotoGalleryAnimations {
    // 写真切り替え
    static let photoTransition = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    ).combined(with: .opacity)

    // ピンチズーム
    static let zoomSpring = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8,
        blendDuration: 0
    )
}

// フォーム入力
struct FormAnimations {
    // フィールドフォーカス
    static let fieldFocus = Animation.easeOut(duration: 0.2)
    static let fieldHighlightColor = Color.blue.opacity(0.3)

    // バリデーションエラー
    static let errorShake = Animation.linear(duration: 0.1).repeatCount(3, autoreverses: true)
    static let errorHighlight = Color.red.opacity(0.3)
}
```

### 11.2 状態遷移アニメーション
```swift
// ローディング状態
struct LoadingStates {
    static let shimmerEffect = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
    static let pulseEffect = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    static let spinEffect = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
}

// データ更新
struct DataUpdateAnimations {
    // リスト更新
    static let listItemInsert = AnyTransition.slide.combined(with: .opacity)
    static let listItemDelete = AnyTransition.scale.combined(with: .opacity)

    // 統計数値更新
    static let numberCountUp = Animation.easeOut(duration: 0.8)
    static let chartUpdate = Animation.spring(dampingFraction: 0.7)
}
```

## 12. プロトタイピング・デザインシステム

### 12.1 SwiftUIプレビュー活用
```swift
// デザインシステムプレビュー
struct DesignSystemPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            // カラーパレット
            ColorPalettePreview()
                .previewDisplayName("Colors")

            // タイポグラフィ
            TypographyPreview()
                .previewDisplayName("Typography")

            // コンポーネント
            ComponentsPreview()
                .previewDisplayName("Components")

            // レイアウト
            LayoutSystemPreview()
                .previewDisplayName("Layouts")
        }
    }
}

struct ColorPalettePreview: View {
    var body: some View {
        VStack {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                HStack {
                    Rectangle()
                        .fill(color.swiftUIColor)
                        .frame(width: 50, height: 50)
                    Text(color.name)
                    Spacer()
                    Text(color.hexValue)
                        .font(.monospaced(.caption)())
                }
            }
        }
        .padding()
    }
}
```

### 12.2 レスポンシブプレビュー
```swift
// 複数デバイスプレビュー
struct ResponsiveBottleListPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            BottleListView()
                .previewDevice("iPhone 15")
                .previewDisplayName("iPhone 15")

            BottleListView()
                .previewDevice("iPhone 15 Plus")
                .previewDisplayName("iPhone 15 Plus")

            BottleListView()
                .previewDevice("iPad Pro (12.9-inch)")
                .previewDisplayName("iPad Pro")

            BottleListView()
                .previewDevice("iPad Pro (12.9-inch)")
                .previewInterfaceOrientation(.landscapeLeft)
                .previewDisplayName("iPad Pro Landscape")
        }
    }
}
```

---

**文書バージョン**: 1.1
**作成日**: 2025-09-21
**最終更新**: 2025-09-23
**作成者**: 個人プロジェクト