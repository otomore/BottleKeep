# Liquid Glass デザイン実装計画書

## 📌 はじめに

**本ドキュメントは、iOS 26 / iPadOS 26で導入されたLiquid Glassデザイン言語をBottleKeeperアプリに適用するための実装計画書です。**

### 前提条件

- **iOS 26 / iPadOS 26**: 2025年9月15日にリリース済み
- **Xcode 26**: 2025年9月にリリース済み（iOS 26 SDKを含む）
- **現在のBottleKeeperプロジェクト**: Deployment Target iOS 18.0（iOS 18〜26をサポート）
- **実装方針**: Liquid Glass APIを使用し、iOS 25以下向けにフォールバック実装を提供

### 実装前のクイックチェック

以下を確認してから実装を開始してください：

```
□ Xcode 26以降がインストールされている
□ プロジェクトがXcode 26で開ける
□ テストファイル（LiquidGlassTest.swift）でビルドが成功する
□ GitHub Actionsを使用する場合、macOS 26イメージを指定（後述）
```

### Liquid Glass API検証用テストファイル

プロジェクト内に`LiquidGlassTest.swift`を作成済みです。このファイルでビルドが成功すれば、`.glassEffect()` APIが利用可能です。

```swift
// BottleKeeper/Views/LiquidGlassTest.swift
import SwiftUI

struct LiquidGlassTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Liquid Glass Test")
                .font(.title)
                .padding()
                .background(.clear)
                .glassEffect() // ← このAPIの存在を確認

            Button("Test Button") {
                print("Button tapped")
            }
            .padding()
            .glassEffect(.regular.tint(.blue.opacity(0.5)))
        }
        .padding()
    }
}
```

**ビルド結果に応じた対応**:
- ✅ **成功**: Liquid Glass APIが利用可能。本計画書に従って実装を進める
- ❌ **失敗**: 「フォールバック実装戦略」セクション（8章）を参照し、`.ultraThinMaterial`ベースの実装を使用

---

## 目次
1. [Liquid Glassとは](#liquid-glassとは)
2. [デザイン哲学と原則](#デザイン哲学と原則)
3. [技術的実装方法](#技術的実装方法)
4. [実装前の準備](#実装前の準備)
5. [ファイル別実装リスト](#ファイル別実装リスト)
6. [実装の優先順位（フェーズ別）](#実装の優先順位フェーズ別)
7. [コード実装例（Before/After）](#コード実装例beforeafter)
8. [フォールバック実装戦略](#フォールバック実装戦略)
9. [実装チェックリスト](#実装チェックリスト)
10. [トラブルシューティング](#トラブルシューティング)
11. [注意事項とベストプラクティス](#注意事項とベストプラクティス)

---

## Liquid Glassとは

### 概要
Liquid Glassは、Appleが2025年6月のWWDC25で発表し、iOS 26、iPadOS 26、macOS Tahoe 26、watchOS 26、tvOS 26（2025年9月15日リリース）で採用された新しいデザイン言語です。iOS 7以来、約12年ぶりの大規模なUI刷新となります。

### 歴史的位置づけ
- **Mac OS X の Aqua UI** → **iOS 7 のフラットデザイン** → **iPhone X の流動性** → **Dynamic Island** → **visionOS** → **Liquid Glass**
- visionOSの深さと立体性からインスピレーションを得ている
- 全プラットフォームで統一されたビジュアル体験を提供

### 主な特徴
- **半透明な素材**：光を透過し、背景を透かして見せる
- **反射と屈折**：周囲の要素を反射・屈折させる物理的なガラスの特性を再現
- **動的変化**：ユーザーの操作やデバイスの動きに応じて流動的に変化
- **リアルタイムレンダリング**：スペキュラーハイライトを含むリアルタイム描画
- **コンテンツ中心**：UIはコンテンツを引き立てる脇役として機能

---

## デザイン哲学と原則

### 1. コアフィロソフィー

#### 「コンテンツを通して見る」デザイン
Liquid Glassの基本理念は、**UIを「見る」のではなく「通して見る」**ことです。写真、動画、テキストなどのコンテンツが主役であり、UIはそれを引き立てる透明な層として機能します。

#### 空間的階層の表現
従来のフラットデザインとは異なり、Liquid Glassは**深さ（depth）を通じて階層を表現**します。要素は前後関係を持ち、重なり合うことで自然な奥行き感を生み出します。

#### デジタルメタマテリアル
Liquid Glassは、物理世界のガラスを単純に再現したものではなく、**光を動的に曲げ、形作る新しいデジタル素材**です。現実のガラス以上に柔軟で表現力豊かな特性を持ちます。

### 2. デザイン原則

#### 原則1：階層とフォーカス
- **1画面に1つのプライマリガラスシート**を配置
- ナビゲーション要素（TabBar、NavigationBar、Toolbar）に最適
- 最大4つのコンポジティングレイヤーまで

#### 原則2：ガラスの上にガラスを配置しない
- ガラスエフェクトは互いにサンプリングできない
- 複数のガラス要素を配置する場合は`GlassEffectContainer`でグループ化

#### 原則3：インタラクティブ性
- タッチやホバー状態に対して流動的なアニメーション
- 近接するガラス要素は互いに融合・分離する動的な表現

#### 原則4：適応性
- ライト・ダークモードに自動適応
- 背景に応じてテキストやアイコンの可読性を保つ
- デバイスの動き（iOS/iPadOS）に反応

### 3. 視覚的特徴

#### レイヤー構造
Liquid Glassは3つの主要レイヤーで構成されます：

1. **ハイライトレイヤー**：光の当たり方と動きを表現
2. **シャドウレイヤー**：深さを追加
3. **イルミネーションレイヤー**：素材の柔軟な特性を表現

#### 2つのバリエーション

**Regular（レギュラー）**
- 汎用性が高い
- より適応的でコンテキストに応じて変化
- ほとんどのケースで推奨

**Clear（クリア）**
- より透明度が高い
- 適応性は低い
- 特定の美的要求がある場合に使用

---

## 技術的実装方法

### 1. SwiftUIでの基本実装（理想的な場合）

#### 必要な環境
- **Xcode 26以降**（2025年9月リリース）
- **iOS 26 / iPadOS 26 / macOS 26 / visionOS 26 SDK**（Xcode 26に含まれる）
- **SwiftUI framework**（追加パッケージは不要）

#### 基本的な使い方

```swift
// 最もシンプルな適用
SomeView()
    .glassEffect()

// カスタマイズした適用
SomeView()
    .glassEffect(.regular.tint(.purple.opacity(0.8)).interactive())
```

### 2. 主要なAPI

#### `.glassEffect()` モディファイア
ビューにLiquid Glassエフェクトを適用します。

```swift
// 基本形
.glassEffect()

// スタイル指定
.glassEffect(.regular)
.glassEffect(.clear)

// ティント（色付け）
.glassEffect(.regular.tint(.blue.opacity(0.6)))

// インタラクティブモード有効化
.glassEffect(.regular.interactive())
```

#### `GlassEffectContainer`
複数のガラス要素をグループ化し、融合・モーフィング効果を実現します。

```swift
GlassEffectContainer {
    Button("Home") { }
        .glassEffect()

    Button("Profile") { }
        .glassEffect()

    Button("Settings") { }
        .glassEffect()
}
```

#### `.glassEffectID(_:in:)` モディファイア
ガラス要素間のモーフィングアニメーションを実現します。

```swift
@State private var isExpanded = false

var body: some View {
    GlassEffectContainer {
        if isExpanded {
            ExpandedView()
                .glassEffect()
                .glassEffectID("mainView", in: "container")
        } else {
            CompactView()
                .glassEffect()
                .glassEffectID("mainView", in: "container")
        }
    }
    .onTapGesture {
        withAnimation {
            isExpanded.toggle()
        }
    }
}
```

---

## 実装前の準備

### 1. プロジェクト情報の確認

#### 現在のBottleKeeperプロジェクト
- **Deployment Target**: iOS 18.0
- **サポート範囲**: iOS 18.0 〜 iOS 26（Deployment Targetが18.0の場合、18以降の全てのバージョンで動作）
- **SwiftUI**: iOS 18対応
- **現在のXcodeバージョン**（GitHub Actions）: Xcode 16.2（iOS 26 SDKを含まない）

#### Xcode 26へのアップグレード

Liquid Glass APIを使用するには、Xcode 26が必要です。

**ローカル環境**:
1. Mac App Storeまたは[Apple Developer](https://developer.apple.com/download/)からXcode 26をダウンロード
2. インストール後、以下を確認:
   ```bash
   xcodebuild -version
   # 出力例: Xcode 26.0
   ```

**GitHub Actions**:
- 現在のワークフロー: `.github/workflows/ios-build.yml`でXcode 16.2を使用
- Xcode 26にアップグレードする場合: 「GitHub Actionsセクション」（次節）を参照

#### 必要な確認事項チェックリスト

```
□ Xcode 26以降がインストールされている（ローカル環境）
□ xcodebuild -version でXcode 26を確認
□ .glassEffect() APIの存在確認（LiquidGlassTest.swiftでビルド）
□ GitHub ActionsでmacOS 26イメージを使用（CI/CD環境）
□ Apple Developer Documentationで公式情報を確認
```

### 2. Liquid Glass API検証

既にプロジェクト内に`BottleKeeper/Views/LiquidGlassTest.swift`を作成済みです。

このファイルをXcode 26でビルドして、`.glassEffect()` APIの存在を確認してください。

**確認手順**:
1. Xcode 26でBottleKeeperプロジェクトを開く
2. `LiquidGlassTest.swift`を選択
3. `Cmd + B` でビルド
4. エラーの有無を確認

**結果の解釈**:
- ✅ **ビルド成功**: Liquid Glass APIが利用可能。実装を進める
- ❌ **ビルドエラー**: `.glassEffect()` APIが存在しない。フォールバック実装のみを使用（8章参照）

**注**: APIが存在しない場合でも、本ドキュメントの実装計画は有効です。`ViewExtensions+Glass.swift`のフォールバック実装により、`.ultraThinMaterial`ベースの近似的なガラスエフェクトが提供されます。

### 3. バックアップの作成

実装前に必ずバックアップを作成：

```bash
# Gitでコミット（個別にファイルを指定）
git status  # 変更ファイルを確認
git add <変更したファイル1>
git add <変更したファイル2>
git commit -m "feat: Liquid Glass実装前のバックアップ"

# または新しいブランチを作成
git checkout -b feature/liquid-glass-design
```

**注**: このプロジェクトでは`git add -A`と`git add .`の使用が禁止されています。必ず個別にファイルを指定してください。

### 4. 新規ファイルの準備

以下の新規ファイルを作成することを推奨：

```
BottleKeeper/
├── Helpers/
│   ├── GlassEffectHelpers.swift     # ガラスエフェクト用ヘルパー
│   └── ViewExtensions+Glass.swift   # View extensionでラッパー
├── Components/
│   ├── GlassSection.swift           # 再利用可能なガラスセクション
│   ├── GlassCard.swift              # 再利用可能なガラスカード
│   └── CustomGlassTabBar.swift      # カスタムガラスタブバー
```

### 5. GitHub Actions設定（CI/CD環境）

GitHub ActionsでLiquid Glass実装をビルドする場合、Xcode 26とmacOS 26イメージが必要です。

#### 現在の設定

`.github/workflows/ios-build.yml`:
```yaml
env:
  XCODE_VERSION: '16.2'
```

#### Xcode 26へのアップグレード

**方法1: macOS 26イメージを使用（推奨）**

```yaml
name: iOS Build

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-26  # ← macOS 26イメージに変更

    steps:
    - uses: actions/checkout@v4

    - name: Set up Xcode
      run: |
        sudo xcode-select --switch /Applications/Xcode_26.0.app
        xcodebuild -version

    - name: Build
      run: |
        xcodebuild -scheme BottleKeeper \
          -configuration Debug \
          -destination 'platform=iOS Simulator,name=iPhone 15' \
          build
```

**方法2: Xcode 26を手動でインストール（非推奨）**

macOS 26イメージが利用できない場合のフォールバック：

```yaml
jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v4

    - name: Download and Install Xcode 26
      run: |
        # Apple Developer からXcode 26をダウンロード（要認証）
        # この方法は時間がかかるため推奨されません
```

#### macOS 26イメージの可用性

- **ステータス**: パブリックプレビュー（2025年10月時点）
- **利用方法**: `runs-on: macos-26`を指定
- **ドキュメント**: [GitHub Actions - macOS runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)

#### 注意事項

1. **ローカル開発優先**: まずローカル環境でLiquid Glass実装を完成させる
2. **GitHub Actions は後回し**: 実装が完了してから、CI/CDの設定を更新
3. **Xcode 16.2でのビルド**: Liquid Glass APIが存在しない場合でも、フォールバック実装により従来のXcodeでもビルド可能

---

## ファイル別実装リスト

### 実装ファイルの優先順位と詳細

#### 【フェーズ1】ナビゲーション要素（最優先）

##### ファイル1: `BottleKeeper/Helpers/ViewExtensions+Glass.swift` ★新規作成★

```swift
// このファイルを最初に作成
// 全体で使用する共通のガラスエフェクトラッパーを定義

import SwiftUI

extension View {
    /// Liquid Glassエフェクトを適用（アクセシビリティ対応）
    @ViewBuilder
    func adaptiveGlassEffect(
        style: GlassEffectStyle = .regular,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        #if compiler(>=6.0) // iOS 26+を想定
        if #available(iOS 26, *) {
            @Environment(\.accessibilityReduceTransparency) var reduceTransparency

            if reduceTransparency {
                // 透明度を下げる設定が有効な場合
                self
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // 通常のガラスエフェクト
                var effect = style
                if let tint = tint {
                    effect = effect.tint(tint)
                }
                if interactive {
                    effect = effect.interactive()
                }
                self.glassEffect(effect)
            }
        } else {
            // iOS 26未満のフォールバック
            fallbackGlassEffect(tint: tint)
        }
        #else
        // Liquid Glass APIが存在しない場合のフォールバック
        fallbackGlassEffect(tint: tint)
        #endif
    }

    /// フォールバック実装（既存のSwiftUI機能で近似）
    private func fallbackGlassEffect(tint: Color?) -> some View {
        self
            .background(.ultraThinMaterial)
            .background(tint?.opacity(0.1) ?? Color.clear)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// アプリ全体で使用するプリセット
extension View {
    func primaryGlassEffect() -> some View {
        adaptiveGlassEffect(tint: .blue.opacity(0.3), interactive: false)
    }

    func secondaryGlassEffect() -> some View {
        adaptiveGlassEffect(tint: .gray.opacity(0.2), interactive: false)
    }

    func accentGlassEffect() -> some View {
        adaptiveGlassEffect(tint: .brown.opacity(0.25), interactive: true)
    }
}
```

**実装手順**:
1. `BottleKeeper/Helpers`ディレクトリを作成（存在しない場合）
2. 上記ファイルを作成
3. プロジェクトにファイルを追加
4. ビルドして構文エラーがないか確認
5. `.glassEffect()`がない場合、`#if compiler`ブロックが正しくフォールバックに切り替わるか確認

---

##### ファイル2: `BottleKeeper/Components/GlassSection.swift` ★新規作成★

```swift
// 再利用可能なガラスセクションコンポーネント

import SwiftUI

struct GlassSection<Content: View>: View {
    let title: String
    let icon: String?
    let tintColor: Color
    @ViewBuilder let content: Content

    init(
        title: String,
        icon: String? = nil,
        tintColor: Color = .gray,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.tintColor = tintColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(tintColor)
                }
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding()
        .background(.clear)
        .adaptiveGlassEffect(tint: tintColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

**実装手順**:
1. `BottleKeeper/Components`ディレクトリを作成（存在しない場合）
2. 上記ファイルを作成
3. プロジェクトにファイルを追加
4. ビルドして動作確認

---

##### ファイル3: `BottleKeeper/Components/CustomGlassTabBar.swift` ★新規作成★

```swift
// カスタムガラスタブバー

import SwiftUI

struct CustomGlassTabBar: View {
    @Binding var selectedTab: Int
    @State private var isCompact = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let tabs = [
        (0, "list.bullet", "コレクション"),
        (1, "star", "ウィッシュリスト"),
        (2, "chart.bar", "統計"),
        (3, "gear", "設定")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { tag, icon, title in
                Button {
                    if reduceMotion {
                        selectedTab = tag
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tag
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: isCompact ? 20 : 22))
                            .symbolEffect(.bounce, value: selectedTab == tag)
                        if !isCompact {
                            Text(title)
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(selectedTab == tag ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.clear)
        .adaptiveGlassEffect(tint: .gray.opacity(0.3), interactive: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
```

**実装手順**:
1. 上記ファイルを作成
2. プロジェクトに追加
3. ビルド確認

---

##### ファイル4: `BottleKeeper/Views/ContentView.swift` ★修正★

**対象行**: 全体（構造を変更）

**Before**:
```swift
// iPhone用レイアウト（従来通り）
TabView(selection: $selectedTab) {
    BottleListView()
        .tabItem {
            Label("コレクション", systemImage: "list.bullet")
        }
        .tag(0)

    WishlistView()
        .tabItem {
            Label("ウィッシュリスト", systemImage: "star")
        }
        .tag(1)
    // ... 以下同様
}
```

**After**:
```swift
// iPhone用レイアウト（Liquid Glass適用）
ZStack(alignment: .bottom) {
    TabView(selection: $selectedTab) {
        BottleListView()
            .tag(0)
        WishlistView()
            .tag(1)
        StatisticsView()
            .tag(2)
        SettingsView()
            .tag(3)
    }
    .tabViewStyle(.page(indexDisplayMode: .never))

    // カスタムガラスタブバー
    CustomGlassTabBar(selectedTab: $selectedTab)
}
```

**実装手順**:
1. ContentView.swiftを開く
2. `else`ブロック（iPhone用レイアウト）を上記のように変更
3. ビルド
4. シミュレーターで動作確認
5. タブ切り替えが正常に動作するか確認

---

##### ファイル5: `BottleKeeper/Views/ContentView.swift` ★修正（iPad部分）★

**対象行**: NavigationSplitView部分

**Before**:
```swift
NavigationSplitView(columnVisibility: $columnVisibility) {
    // サイドバー
    List(selection: $selectedTab) {
        NavigationLink(value: 0) {
            Label("コレクション", systemImage: "list.bullet")
        }
        // ...
    }
    .navigationTitle("BottleKeeper")
    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
} detail: {
    // メインコンテンツ
    selectedView
        .navigationBarTitleDisplayMode(.inline)
}
```

**After**:
```swift
NavigationSplitView(columnVisibility: $columnVisibility) {
    // サイドバー
    List(selection: $selectedTab) {
        NavigationLink(value: 0) {
            Label("コレクション", systemImage: "list.bullet")
        }
        NavigationLink(value: 1) {
            Label("ウィッシュリスト", systemImage: "star")
        }
        NavigationLink(value: 2) {
            Label("統計", systemImage: "chart.bar")
        }
        NavigationLink(value: 3) {
            Label("設定", systemImage: "gear")
        }
    }
    .navigationTitle("BottleKeeper")
    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
    .background(.clear)
    .scrollContentBackground(.hidden)
    .background {
        Color.clear
            .adaptiveGlassEffect(tint: .gray.opacity(0.2))
            .ignoresSafeArea()
    }
} detail: {
    // メインコンテンツ
    selectedView
        .navigationBarTitleDisplayMode(.inline)
}
```

**実装手順**:
1. NavigationSplitViewのListに`.background`と`.scrollContentBackground`を追加
2. ビルド
3. iPadシミュレーターで確認
4. サイドバーがガラス効果を持つか確認

---

#### 【フェーズ2】カード要素

##### ファイル6: `BottleKeeper/Views/StatisticsView.swift` ★修正★

**対象**: `StatCardView`構造体

**対象行**: 342-362行目

**Before**:
```swift
struct StatCardView: View {
    // ...
    var body: some View {
        VStack(spacing: 12) {
            // ...
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
```

**After**:
```swift
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .symbolEffect(.bounce, value: value)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.clear)
        .adaptiveGlassEffect(tint: color.opacity(0.3))
    }
}
```

**実装手順**:
1. StatisticsView.swiftを開く
2. `StatCardView`を検索
3. `.background`と`.cornerRadius`を削除
4. `.background(.clear)`と`.adaptiveGlassEffect`を追加
5. ビルド
6. 統計画面で確認

---

##### ファイル7: `BottleKeeper/Views/BottleListView.swift` ★修正★

**対象**: `BottleRowView`構造体

**対象行**: 156-217行目

**Before**:
```swift
struct BottleRowView: View {
    // ...
    var body: some View {
        HStack(spacing: 12) {
            BottleShapeView(...)
            VStack(alignment: .leading, spacing: 4) {
                // ...
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
```

**After**:
```swift
struct BottleRowView: View {
    let bottle: Bottle
    @ObservedObject var motionManager: MotionManager

    var body: some View {
        HStack(spacing: 12) {
            // ボトル形状はそのまま維持
            BottleShapeView(
                remainingPercentage: bottle.remainingPercentage / 100.0,
                motionManager: motionManager
            )
            .frame(width: 50, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.wrappedName)
                    .font(.headline)

                Text(bottle.wrappedDistillery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    if bottle.isOpened {
                        Label("\(bottle.remainingPercentage, specifier: "%.0f")%",
                              systemImage: "drop.fill")
                            .font(.caption)
                            .foregroundColor(remainingColor(for: bottle.remainingPercentage))
                    } else {
                        Label("未開栓", systemImage: "seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    if bottle.rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("\(bottle.rating)")
                                .font(.caption)
                        }
                        .foregroundColor(.yellow)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(.clear)
        .adaptiveGlassEffect(tint: .brown.opacity(0.2))
    }

    private func remainingColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100:
            return .green
        case 20..<50:
            return .orange
        default:
            return .red
        }
    }
}
```

**実装手順**:
1. BottleListView.swiftを開く
2. `BottleRowView`を検索
3. `.padding(.vertical, 4)`を`.padding()`に変更
4. `.background(.clear)`と`.adaptiveGlassEffect`を追加
5. ビルド
6. リスト表示を確認

---

#### 【フェーズ3】詳細ビュー

##### ファイル8: `BottleKeeper/Views/BottleDetailView.swift` ★修正★

**対象**: 各セクション（基本情報、残量情報、購入情報、評価・ノート）

**Before（例：基本情報セクション）**:
```swift
// 基本情報セクション
VStack(alignment: .leading, spacing: 12) {
    Text("基本情報")
        .font(.headline)

    DetailRowView(title: "銘柄", value: bottle.wrappedName)
    // ...
}
```

**After**:
```swift
// 基本情報セクション
GlassSection(
    title: "基本情報",
    icon: "info.circle",
    tintColor: .blue
) {
    DetailRowView(title: "銘柄", value: bottle.wrappedName)
    DetailRowView(title: "蒸留所", value: bottle.wrappedDistillery)
    DetailRowView(title: "地域", value: bottle.wrappedRegion)
    DetailRowView(title: "タイプ", value: bottle.wrappedType)
    DetailRowView(title: "アルコール度数", value: "\(String(format: "%.1f", bottle.abv))%")
    DetailRowView(title: "容量", value: "\(bottle.volume)ml")

    if bottle.vintage > 0 {
        DetailRowView(title: "年代", value: "\(bottle.vintage)年")
    }
}
```

**実装手順**:
1. BottleDetailView.swiftを開く
2. 「基本情報セクション」を検索
3. `VStack`を`GlassSection`に置き換え
4. 同様に「残量情報」「購入情報」「評価・ノート」セクションも変更
5. ビルド
6. 詳細画面で各セクションを確認

---

##### ファイル9: `BottleKeeper/Views/StatisticsView.swift` ★修正（グラフ）★

**対象**: 円グラフと棒グラフの背景

**Before（円グラフ）**:
```swift
Chart(typeDistribution, id: \.0) { type, count in
    // ...
}
.frame(height: 250)
.chartLegend(position: .bottom, alignment: .center, spacing: 10)
```

**After**:
```swift
Chart(typeDistribution, id: \.0) { type, count in
    SectorMark(
        angle: .value("本数", count),
        innerRadius: .ratio(0.5),
        angularInset: 1.5
    )
    .foregroundStyle(by: .value("タイプ", type))
    .annotation(position: .overlay) {
        Text("\(count)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
}
.frame(height: 250)
.padding()
.background(.clear)
.adaptiveGlassEffect(tint: .blue.opacity(0.1))
.clipShape(RoundedRectangle(cornerRadius: 16))
.chartLegend(position: .bottom, alignment: .center, spacing: 10)
```

**実装手順**:
1. StatisticsView.swiftを開く
2. 円グラフ部分を検索
3. `.padding()`、`.background(.clear)`、`.adaptiveGlassEffect`を追加
4. 棒グラフも同様に修正
5. ビルド
6. 統計画面でグラフ表示を確認

---

#### 【フェーズ4】モーダルとボタン

##### ファイル10: `BottleKeeper/Components/PrimaryActionButton.swift` ★新規作成★

```swift
import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(.clear)
            .adaptiveGlassEffect(tint: .blue.opacity(0.8), interactive: true)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !reduceMotion {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    if !reduceMotion {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
                }
        )
    }
}
```

**実装手順**:
1. 上記ファイルを作成
2. プロジェクトに追加
3. ビルド
4. 必要な箇所でこのボタンを使用

---

## 実装の優先順位（フェーズ別）

### フェーズ1：基礎実装（最優先）
**目標：ナビゲーション要素にLiquid Glassを適用**

| ステップ | ファイル | 作業内容 | 所要時間 | 必須度 |
|---------|---------|---------|---------|--------|
| 1.1 | ViewExtensions+Glass.swift | 新規作成：共通ヘルパー | 30分 | ★★★★★ |
| 1.2 | GlassSection.swift | 新規作成：セクションコンポーネント | 20分 | ★★★★☆ |
| 1.3 | CustomGlassTabBar.swift | 新規作成：カスタムタブバー | 40分 | ★★★★★ |
| 1.4 | ContentView.swift | 修正：iPhone用TabView | 30分 | ★★★★★ |
| 1.5 | ContentView.swift | 修正：iPad用NavigationSplitView | 30分 | ★★★★☆ |

**ビルド＆テスト**: 各ステップ完了後にビルドして動作確認

**完了確認**:
- [ ] ビルドエラーがない
- [ ] iPhone TabBarがガラス効果を持つ
- [ ] iPad サイドバーがガラス効果を持つ
- [ ] タブ切り替えが正常に動作
- [ ] ダークモードでも正常に表示

---

### フェーズ2：カード要素（高優先）
**目標：主要なカード表示にLiquid Glassを適用**

| ステップ | ファイル | 作業内容 | 所要時間 | 必須度 |
|---------|---------|---------|---------|--------|
| 2.1 | StatisticsView.swift | StatCardView修正 | 20分 | ★★★★☆ |
| 2.2 | BottleListView.swift | BottleRowView修正 | 30分 | ★★★★★ |
| 2.3 | WishlistView.swift | WishlistRowView修正 | 25分 | ★★★☆☆ |

**完了確認**:
- [ ] 統計カードがガラス効果を持つ
- [ ] ボトルリストアイテムがガラス効果を持つ
- [ ] ウィッシュリストアイテムがガラス効果を持つ
- [ ] スクロール時のパフォーマンスが良好

---

### フェーズ3：詳細ビュー（中優先）

| ステップ | ファイル | 作業内容 | 所要時間 | 必須度 |
|---------|---------|---------|---------|--------|
| 3.1 | BottleDetailView.swift | 各セクションをGlassSectionに置き換え | 40分 | ★★★☆☆ |
| 3.2 | StatisticsView.swift | グラフ背景にガラスエフェクト | 30分 | ★★★☆☆ |

**完了確認**:
- [ ] 詳細画面の各セクションがガラス効果を持つ
- [ ] グラフ背景がガラス効果を持つ
- [ ] 写真とガラスエフェクトが調和している

---

### フェーズ4：モーダルとボタン（低優先）

| ステップ | ファイル | 作業内容 | 所要時間 | 必須度 |
|---------|---------|---------|---------|--------|
| 4.1 | PrimaryActionButton.swift | 新規作成：インタラクティブボタン | 30分 | ★★☆☆☆ |
| 4.2 | 各フォームView | モーダル背景にガラスエフェクト | 40分 | ★★☆☆☆ |

**完了確認**:
- [ ] ボタンがインタラクティブなガラス効果を持つ
- [ ] モーダルシートが適切に表示される

---

### フェーズ5：最適化とポリッシュ

| ステップ | 作業内容 | 所要時間 | 必須度 |
|---------|---------|---------|--------|
| 5.1 | パフォーマンステスト（古いデバイス） | 30分 | ★★★★☆ |
| 5.2 | アクセシビリティテスト | 30分 | ★★★★★ |
| 5.3 | ダークモード対応確認 | 20分 | ★★★★★ |
| 5.4 | 細かい調整（色、間隔、アニメーション） | 40分 | ★★★☆☆ |

**完了確認**:
- [ ] iPhone 11以前でもスムーズに動作
- [ ] 「透明度を下げる」設定で適切にフォールバック
- [ ] 「モーション削減」設定でアニメーション無効化
- [ ] ダークモードで全画面が適切に表示
- [ ] コントラスト比がWCAG 2.2 AA基準を満たす

---

## コード実装例（Before/After）

### 例1: StatCardViewの完全な実装

#### Before
```swift
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
```

#### After
```swift
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .symbolEffect(.bounce, value: value) // iOS 17+のシンボルアニメーション

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .contentTransition(.numericText()) // スムーズな数値変化

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.clear)
        .adaptiveGlassEffect(tint: color.opacity(0.3)) // ← Liquid Glass適用
    }
}
```

---

### 例2: BottleDetailViewセクションの完全な実装

#### Before
```swift
// 基本情報セクション
VStack(alignment: .leading, spacing: 12) {
    Text("基本情報")
        .font(.headline)

    DetailRowView(title: "銘柄", value: bottle.wrappedName)
    DetailRowView(title: "蒸留所", value: bottle.wrappedDistillery)
    DetailRowView(title: "地域", value: bottle.wrappedRegion)
    DetailRowView(title: "タイプ", value: bottle.wrappedType)
    DetailRowView(title: "アルコール度数", value: "\(String(format: "%.1f", bottle.abv))%")
    DetailRowView(title: "容量", value: "\(bottle.volume)ml")

    if bottle.vintage > 0 {
        DetailRowView(title: "年代", value: "\(bottle.vintage)年")
    }
}
```

#### After
```swift
// 基本情報セクション
GlassSection(
    title: "基本情報",
    icon: "info.circle",
    tintColor: .blue
) {
    DetailRowView(title: "銘柄", value: bottle.wrappedName)
    DetailRowView(title: "蒸留所", value: bottle.wrappedDistillery)
    DetailRowView(title: "地域", value: bottle.wrappedRegion)
    DetailRowView(title: "タイプ", value: bottle.wrappedType)
    DetailRowView(title: "アルコール度数", value: "\(String(format: "%.1f", bottle.abv))%")
    DetailRowView(title: "容量", value: "\(bottle.volume)ml")

    if bottle.vintage > 0 {
        DetailRowView(title: "年代", value: "\(bottle.vintage)年")
    }
}
```

---

### 例3: ContentViewの完全な実装（iPhone部分）

#### Before
```swift
// iPhone用レイアウト（従来通り）
TabView(selection: $selectedTab) {
    BottleListView()
        .tabItem {
            Label("コレクション", systemImage: "list.bullet")
        }
        .tag(0)

    WishlistView()
        .tabItem {
            Label("ウィッシュリスト", systemImage: "star")
        }
        .tag(1)

    StatisticsView()
        .tabItem {
            Label("統計", systemImage: "chart.bar")
        }
        .tag(2)

    SettingsView()
        .tabItem {
            Label("設定", systemImage: "gear")
        }
        .tag(3)
}
```

#### After
```swift
// iPhone用レイアウト（Liquid Glass適用）
ZStack(alignment: .bottom) {
    TabView(selection: $selectedTab) {
        BottleListView()
            .tag(0)
        WishlistView()
            .tag(1)
        StatisticsView()
            .tag(2)
        SettingsView()
            .tag(3)
    }
    .tabViewStyle(.page(indexDisplayMode: .never))

    // カスタムガラスタブバー
    CustomGlassTabBar(selectedTab: $selectedTab)
}
```

---

## フォールバック実装戦略

### iOS 25以下およびAPI未対応環境向けの代替実装

Liquid Glass APIはiOS 26で導入されたため、iOS 25以下のデバイスや、何らかの理由でAPIが利用できない環境では、既存のSwiftUI機能を使用した代替実装を提供します。

#### 戦略1: `.ultraThinMaterial`を使用

既存のSwiftUIマテリアルで近似的な効果を実現：

```swift
extension View {
    func fallbackGlassEffect(tint: Color? = nil) -> some View {
        self
            .background {
                ZStack {
                    // 背景ブラー
                    Rectangle()
                        .fill(.ultraThinMaterial)

                    // ティント色
                    if let tint = tint {
                        tint.opacity(0.15)
                    }
                }
            }
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}
```

#### 戦略2: カスタムブラー効果

```swift
struct GlassBackgroundView: View {
    let tintColor: Color

    var body: some View {
        ZStack {
            // ベースレイヤー
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)

            // ティントレイヤー
            RoundedRectangle(cornerRadius: 16)
                .fill(tintColor.opacity(0.1))

            // 光沢レイヤー
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.clear,
                    Color.white.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
```

#### 戦略3: iOS 18以下での完全なフォールバック実装

```swift
extension View {
    @ViewBuilder
    func adaptiveGlassEffect(
        style: GlassEffectStyle = .regular,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26, *) {
            // iOS 26以降：Liquid Glass使用（存在する場合）
            #if compiler(>=6.0)
            self.glassEffect(style)
            #else
            // コンパイラが古い場合のフォールバック
            self.fallbackGlassEffect(tint: tint)
            #endif
        } else {
            // iOS 25以下：フォールバック実装
            self.fallbackGlassEffect(tint: tint)
        }
    }

    private func fallbackGlassEffect(tint: Color?) -> some View {
        self
            .background {
                GlassBackgroundView(
                    tintColor: tint ?? .gray
                )
            }
    }
}

struct GlassBackgroundView: View {
    let tintColor: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Material
            if #available(iOS 15.0, *) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            } else {
                // iOS 14以下
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground).opacity(0.8))
                    .blur(radius: 10)
            }

            // Tint
            RoundedRectangle(cornerRadius: 16)
                .fill(tintColor.opacity(colorScheme == .dark ? 0.2 : 0.1))

            // Highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.clear,
                    Color.white.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}
```

#### 戦略4: 完全な互換レイヤー

Liquid Glass APIをエミュレートする完全な互換レイヤー：

```swift
// GlassEffectEmulation.swift
import SwiftUI

// Liquid Glass APIが存在しない場合のエミュレーション

enum GlassEffectStyle {
    case regular
    case clear

    func tint(_ color: Color) -> GlassEffectConfiguration {
        GlassEffectConfiguration(style: self, tint: color, interactive: false)
    }
}

struct GlassEffectConfiguration {
    let style: GlassEffectStyle
    let tint: Color?
    let interactive: Bool

    func tint(_ color: Color) -> GlassEffectConfiguration {
        GlassEffectConfiguration(style: style, tint: color, interactive: interactive)
    }

    func interactive() -> GlassEffectConfiguration {
        GlassEffectConfiguration(style: style, tint: tint, interactive: true)
    }
}

extension View {
    func glassEffect(_ config: GlassEffectConfiguration = GlassEffectConfiguration(style: .regular, tint: nil, interactive: false)) -> some View {
        modifier(GlassEffectModifier(configuration: config))
    }
}

struct GlassEffectModifier: ViewModifier {
    let configuration: GlassEffectConfiguration
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background {
                glassBackground
            }
            .scaleEffect(configuration.interactive && isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                if configuration.interactive {
                    isHovered = hovering
                }
            }
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Base material
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.style == .regular ? .ultraThinMaterial : .thinMaterial)

            // Tint layer
            if let tint = configuration.tint {
                RoundedRectangle(cornerRadius: 16)
                    .fill(tint.opacity(colorScheme == .dark ? 0.25 : 0.15))
            }

            // Specular highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(0.4),
                    Color.clear,
                    Color.white.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Interactive shimmer
            if configuration.interactive && isHovered {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}
```

---

## 実装チェックリスト

### 実装前

- [ ] プロジェクトのバックアップを作成（Gitコミット）
- [ ] Xcodeバージョンを確認
- [ ] iOS SDKバージョンを確認
- [ ] テストプロジェクトで`.glassEffect()`の存在を確認
- [ ] Apple Developer Documentationでliquid Glassを検索
- [ ] 新規ディレクトリ作成（`Helpers/`, `Components/`）

### フェーズ1実装中

- [ ] `ViewExtensions+Glass.swift`作成完了
- [ ] ビルドエラーなし（`.glassEffect()`が存在しない場合、フォールバックが動作）
- [ ] `GlassSection.swift`作成完了
- [ ] `CustomGlassTabBar.swift`作成完了
- [ ] `ContentView.swift`のiPhone部分修正完了
- [ ] `ContentView.swift`のiPad部分修正完了
- [ ] iPhoneシミュレーターでタブバー表示確認
- [ ] iPadシミュレーターでサイドバー表示確認
- [ ] ダークモード切り替えテスト

### フェーズ1完了確認

- [ ] ビルドエラーゼロ
- [ ] ランタイムエラーなし
- [ ] タブ切り替え動作正常
- [ ] スクロール時のパフォーマンス良好（60fps維持）
- [ ] ライト/ダークモード両方で表示OK
- [ ] セーフエリアが適切に処理されている

### フェーズ2実装中

- [ ] `StatCardView`修正完了
- [ ] `BottleRowView`修正完了
- [ ] `WishlistRowView`修正完了
- [ ] 統計画面で4つのカード表示確認
- [ ] ボトルリストでガラスカード表示確認
- [ ] ウィッシュリストでガラスカード表示確認

### フェーズ2完了確認

- [ ] カードのタップ動作正常
- [ ] リストスクロール時のパフォーマンス良好
- [ ] カード内のテキスト可読性OK（コントラスト十分）
- [ ] BottleShapeViewとガラスエフェクトが調和

### フェーズ3実装中

- [ ] `BottleDetailView`の基本情報セクション修正完了
- [ ] `BottleDetailView`の残量情報セクション修正完了
- [ ] `BottleDetailView`の購入情報セクション修正完了
- [ ] `BottleDetailView`の評価・ノートセクション修正完了
- [ ] 円グラフ背景にガラスエフェクト適用完了
- [ ] 棒グラフ背景にガラスエフェクト適用完了

### フェーズ3完了確認

- [ ] 詳細画面の全セクションが適切に表示
- [ ] グラフが正しく表示される
- [ ] セクション間の間隔が適切
- [ ] 写真とガラスエフェクトが重ならない

### フェーズ4実装中

- [ ] `PrimaryActionButton.swift`作成完了
- [ ] 主要なアクションボタンに適用
- [ ] モーダルシート背景に適用（必要に応じて）

### フェーズ4完了確認

- [ ] ボタンのタップ動作正常
- [ ] インタラクティブエフェクト動作確認
- [ ] モーダル表示・非表示が正常

### フェーズ5：最適化

- [ ] 古いデバイス（iPhone 11など）でテスト
- [ ] GPUプロファイリング実施（Instruments使用）
- [ ] メモリ使用量確認
- [ ] バッテリー消費テスト（10分間操作）

### フェーズ5：アクセシビリティ

- [ ] 設定 > アクセシビリティ > 透明度を下げる → ON → 確認
- [ ] 設定 > アクセシビリティ > 視差効果を減らす → ON → 確認
- [ ] VoiceOverで各画面をテスト
- [ ] Dynamic Typeで各サイズをテスト
- [ ] コントラスト比測定（WCAG 2.2 AA基準）

### 最終確認

- [ ] 全画面でライト/ダークモード動作確認
- [ ] iPhone SE、iPhone 15、iPhone 15 Pro Maxで確認
- [ ] iPad（縦・横）で確認
- [ ] 既存機能が全て動作（ボトル追加、削除、編集、検索等）
- [ ] クラッシュなし
- [ ] メモリリークなし
- [ ] AppStoreスクリーンショット撮影

---

## トラブルシューティング

### 問題1: `.glassEffect()`が見つからない

**症状**:
```
Value of type 'some View' has no member 'glassEffect'
```

**原因**: Liquid Glass APIが存在しない、またはiOS SDKが古い

**対処法**:
1. `ViewExtensions+Glass.swift`の`#if compiler`ブロックが正しくフォールバックしているか確認
2. フォールバック実装（`.ultraThinMaterial`）が動作するか確認
3. 「フォールバック実装戦略」セクションの完全な互換レイヤーを使用

```swift
// 修正例：常にフォールバックを使用
extension View {
    func adaptiveGlassEffect(tint: Color? = nil) -> some View {
        self.fallbackGlassEffect(tint: tint)
    }

    private func fallbackGlassEffect(tint: Color?) -> some View {
        self
            .background(.ultraThinMaterial)
            .background(tint?.opacity(0.1) ?? Color.clear)
            .cornerRadius(12)
    }
}
```

---

### 問題2: `GlassEffectContainer`が見つからない

**症状**:
```
Cannot find 'GlassEffectContainer' in scope
```

**対処法**:
1. `GlassEffectContainer`の使用を削除
2. 通常の`VStack`や`HStack`で代替
3. 各要素に個別に`.adaptiveGlassEffect()`を適用

```swift
// Before（GlassEffectContainer使用）
GlassEffectContainer {
    Button("A") { }.glassEffect()
    Button("B") { }.glassEffect()
}

// After（代替実装）
HStack {
    Button("A") { }
        .padding()
        .adaptiveGlassEffect()

    Button("B") { }
        .padding()
        .adaptiveGlassEffect()
}
```

---

### 問題3: TabBarが二重に表示される

**症状**: 標準のTabBarとCustomGlassTabBarが両方表示される

**対処法**:
```swift
// ContentView.swift
ZStack(alignment: .bottom) {
    TabView(selection: $selectedTab) {
        BottleListView()
            .tag(0)
        // ...
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .toolbar(.hidden, for: .tabBar) // ← 追加：標準TabBarを非表示

    CustomGlassTabBar(selectedTab: $selectedTab)
}
```

---

### 問題4: パフォーマンスが悪い（カクつく）

**症状**: スクロール時にフレームレートが低下

**対処法**:
1. ガラスエフェクトの適用箇所を減らす
2. リストの各行ではなく、セクション単位で適用
3. シンプルなフォールバック実装に切り替え

```swift
// 重い実装（各行に適用）
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .adaptiveGlassEffect() // ← 重い
    }
}

// 軽い実装（リスト全体に適用）
List {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
.background(.ultraThinMaterial) // ← 軽い
```

---

### 問題5: テキストが読みにくい

**症状**: ガラスエフェクトの背景でテキストのコントラストが不足

**対処法**:
1. ティントの不透明度を上げる
2. テキストに背景を追加

```swift
// 対処法1：ティント強化
.adaptiveGlassEffect(tint: .white.opacity(0.5)) // 不透明度を上げる

// 対処法2：テキストに背景
Text("重要なテキスト")
    .padding(4)
    .background(Color.black.opacity(0.5))
    .cornerRadius(4)
```

---

### 問題6: ダークモードで見た目が悪い

**症状**: ダークモードでガラスエフェクトが目立たない、または逆に明るすぎる

**対処法**:
カラースキームに応じてティント色を調整

```swift
extension View {
    func adaptiveTintedGlassEffect(lightTint: Color, darkTint: Color) -> some View {
        modifier(AdaptiveTintedGlassModifier(lightTint: lightTint, darkTint: darkTint))
    }
}

struct AdaptiveTintedGlassModifier: ViewModifier {
    let lightTint: Color
    let darkTint: Color
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .adaptiveGlassEffect(
                tint: colorScheme == .dark ? darkTint : lightTint
            )
    }
}

// 使用例
SomeView()
    .adaptiveTintedGlassEffect(
        lightTint: .gray.opacity(0.2),
        darkTint: .gray.opacity(0.4)
    )
```

---

### 問題7: ビルドは成功するが実行時にクラッシュ

**症状**: アプリ起動時またはガラスエフェクト適用画面でクラッシュ

**対処法**:
1. Xcodeのコンソールでエラーメッセージ確認
2. `.adaptiveGlassEffect()`内の条件分岐を確認
3. フォールバック実装のみを使用

```swift
// 最もシンプルで安全な実装
extension View {
    func adaptiveGlassEffect(tint: Color? = nil) -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(12)
    }
}
```

---

### 問題8: NavigationSplitViewのサイドバーが透明すぎる

**対処法**:
ティントの不透明度を上げるか、Materialを変更

```swift
List(selection: $selectedTab) {
    // ...
}
.background(.clear)
.scrollContentBackground(.hidden)
.background {
    Color.clear
        .background(.regularMaterial) // ← ultraThinMaterial から regularMaterial に変更
        .adaptiveGlassEffect(tint: .gray.opacity(0.4)) // ← 不透明度を上げる
        .ignoresSafeArea()
}
```

---

### 問題9: Xcodeでプレビューが動作しない

**症状**: `#Preview`マクロでガラスエフェクトが表示されない

**対処法**:
プレビューでは背景を追加

```swift
#Preview {
    StatCardView(
        title: "テスト",
        value: "100",
        icon: "star.fill",
        color: .blue
    )
    .padding()
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ) // ← プレビュー用背景
}
```

---

### 問題10: Git差分が大きくなりすぎる

**症状**: コミット時の差分が大きすぎて管理しにくい

**対処法**:
フェーズごとにコミット

```bash
# フェーズ1完了時（個別にファイルを指定）
git add BottleKeeper/Helpers/ViewExtensions+Glass.swift
git add BottleKeeper/Components/GlassSection.swift
git add BottleKeeper/Components/CustomGlassTabBar.swift
git add BottleKeeper/Views/ContentView.swift
git commit -m "feat(ui): フェーズ1 - ナビゲーション要素にLiquid Glassを適用

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# フェーズ2完了時
git add BottleKeeper/Views/StatisticsView.swift
git add BottleKeeper/Views/BottleListView.swift
git add BottleKeeper/Views/WishlistView.swift
git commit -m "feat(ui): フェーズ2 - カード要素にLiquid Glassを適用

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 以下同様
```

**注**: `git add -A` や `git add .` は使用禁止です。

---

## 注意事項とベストプラクティス

### 1. アクセシビリティ（必須）

#### WCAG 2.2 AA基準を満たす
- **コントラスト比 4.5:1以上**を確保
- ツール: [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Xcodeの Accessibility Inspector を使用

#### システム設定への対応（必須実装）

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    if reduceTransparency {
        // 透明度を下げた代替表示
        SomeView()
            .background(Color(.systemBackground))
    } else {
        // 通常のガラスエフェクト
        SomeView()
            .adaptiveGlassEffect()
    }
}
```

### 2. パフォーマンス最適化

#### レイヤー数の制限（重要）
```swift
// ❌ 悪い例：ネストが深すぎる
VStack {
    HStack {
        SomeView().adaptiveGlassEffect()
    }.adaptiveGlassEffect()
}.adaptiveGlassEffect()

// ✅ 良い例：適切なレイヤー数
VStack {
    HStack {
        SomeView()
    }
}.adaptiveGlassEffect()
```

#### リストのパフォーマンス

```swift
// ❌ 悪い例：各セルにガラスエフェクト
List {
    ForEach(items) { item in
        ItemRow(item)
            .adaptiveGlassEffect() // ← スクロール時に重い
    }
}

// ✅ 良い例：セクションまたはリスト全体に適用
List {
    ForEach(items) { item in
        ItemRow(item)
    }
}
.background(.ultraThinMaterial)
```

### 3. デザインの一貫性

#### カラーパレットの定義

プロジェクト全体で使用する色を定義：

```swift
// BottleKeeper/Helpers/GlassColors.swift
import SwiftUI

enum GlassColors {
    static let primaryTint = Color.blue.opacity(0.3)
    static let secondaryTint = Color.gray.opacity(0.2)
    static let accentTint = Color.brown.opacity(0.25)

    static let infoTint = Color.blue.opacity(0.15)
    static let successTint = Color.green.opacity(0.15)
    static let warningTint = Color.orange.opacity(0.15)
    static let errorTint = Color.red.opacity(0.15)
}
```

### 4. テスト戦略

#### デバイステスト（必須）
- [ ] iPhone SE（小画面）
- [ ] iPhone 15（標準）
- [ ] iPhone 15 Pro Max（大画面）
- [ ] iPad（縦・横）
- [ ] iPad Pro（縦・横）

#### シナリオテスト
1. **明るい背景**での可読性確認
2. **暗い背景**での可読性確認
3. **写真背景**での可読性確認
4. **動的背景**（スクロール時など）での動作確認
5. **ダークモード**での全画面確認

#### パフォーマンステスト
- **フレームレート**: Xcodeの Debug → View Debugging → Rendering
- **GPU使用率**: Instruments → Metal System Trace
- **メモリ使用**: Instruments → Allocations
- **バッテリー消費**: Instruments → Energy Log

### 5. コードレビューのポイント

実装後、以下を確認：

- [ ] 全てのガラスエフェクトにフォールバックが実装されている
- [ ] アクセシビリティ設定に対応している
- [ ] パフォーマンスが許容範囲内（60fps維持）
- [ ] コードの重複がない（ヘルパー関数を活用）
- [ ] ダークモードで適切に表示される
- [ ] コメントが適切に記述されている
- [ ] ネーミングが一貫している

### 6. 将来のメンテナンス

#### ドキュメント化
実装後、以下をドキュメント化：

```swift
// MARK: - Liquid Glass Implementation Notes
//
// このプロジェクトではLiquid Glassデザインを採用しています。
//
// 使用方法：
// - 新しいビューには `.adaptiveGlassEffect()` を使用
// - カスタムティントは `GlassColors` から選択
// - セクションには `GlassSection` コンポーネントを使用
//
// フォールバック：
// - iOS 26未満または`.glassEffect()`が存在しない場合、
//   自動的に `.ultraThinMaterial` にフォールバック
//
// パフォーマンス：
// - リストの各セルには適用しない
// - ネストは2レイヤーまで
//
```

---

## まとめ

### 実装の流れ

1. **実装前確認**：iOS 26とLiquid Glass APIの存在確認
2. **フェーズ1**：ナビゲーション要素（最優先・約2-3時間）
3. **フェーズ2**：カード要素（高優先・約3-4時間）
4. **フェーズ3**：詳細ビュー（中優先・約2-3時間）
5. **フェーズ4**：モーダルとボタン（低優先・約3-4時間）
6. **フェーズ5**：最適化とアクセシビリティ（必須・約2-3時間）

### 期待される効果

- **視覚的印象の向上**：モダンで洗練されたUI
- **ブランド価値の向上**：最新のデザイントレンドに準拠
- **ユーザー体験の向上**：流動的でインタラクティブな操作感
- **コンテンツへのフォーカス**：ボトルの写真や情報が際立つ

### 重要な注意事項

1. **Xcode 26必須**: Liquid Glass APIを使用するにはXcode 26以降が必要
2. **iOS 25以下のサポート**: フォールバック実装により、iOS 18〜25のデバイスでも動作
3. **段階的実装**: フェーズごとに実装し、各段階でテスト
4. **パフォーマンス優先**: 見た目よりもパフォーマンスを優先
5. **アクセシビリティ必須**: 全てのユーザーが使える実装を心がける

### 次のステップ

1. **このドキュメントを精読**
2. **実装前確認チェックリスト完了**
3. **テストプロジェクトで検証**
4. **フェーズ1から順次実装開始**
5. **各フェーズ完了後にテスト**
6. **問題発生時はトラブルシューティング参照**

---

**作成日**：2025年10月1日（改訂版）
**対象アプリ**：BottleKeeper
**サポートOS**：iOS 18.0以降（Deployment Target）
**Liquid Glass対応OS**：iOS 26以降
**作成者**：Claude Code

---

## 付録A: 完全なファイル構成

実装後のプロジェクト構造：

```
BottleKeeper/
├── App/
│   └── BottleKeeperApp.swift
├── Models/
│   ├── Bottle+CoreDataClass.swift
│   ├── Bottle+CoreDataProperties.swift
│   ├── BottlePhoto+CoreDataClass.swift
│   ├── BottlePhoto+CoreDataProperties.swift
│   ├── WishlistItem+CoreDataClass.swift
│   ├── WishlistItem+CoreDataProperties.swift
│   ├── DrinkingLog+CoreDataClass.swift
│   └── DrinkingLog+CoreDataProperties.swift
├── Views/
│   ├── ContentView.swift ★修正
│   ├── BottleListView.swift ★修正
│   ├── BottleDetailView.swift ★修正
│   ├── StatisticsView.swift ★修正
│   ├── WishlistView.swift ★修正
│   ├── SettingsView.swift
│   ├── BottleFormView.swift
│   ├── WishlistFormView.swift
│   ├── RemainingVolumeUpdateView.swift
│   ├── DrinkingLogFormView.swift
│   ├── NotificationSettingsView.swift
│   └── ImagePicker.swift
├── Components/ ★新規ディレクトリ
│   ├── GlassSection.swift ★新規
│   ├── CustomGlassTabBar.swift ★新規
│   └── PrimaryActionButton.swift ★新規
├── Helpers/ ★新規ディレクトリ
│   ├── ViewExtensions+Glass.swift ★新規
│   └── GlassColors.swift ★新規（推奨）
├── Services/
│   ├── CoreDataManager.swift
│   ├── MotionManager.swift
│   ├── NotificationManager.swift
│   └── PhotoManager.swift
└── Resources/
    └── BottleKeeper.xcdatamodeld
```

---

## 付録B: クイックリファレンス

### よく使うコード片

#### 基本的なガラスエフェクト
```swift
SomeView()
    .padding()
    .background(.clear)
    .adaptiveGlassEffect()
```

#### ティント付きガラスエフェクト
```swift
SomeView()
    .padding()
    .background(.clear)
    .adaptiveGlassEffect(tint: .blue.opacity(0.3))
```

#### インタラクティブガラスエフェクト
```swift
Button("Action") { }
    .padding()
    .background(.clear)
    .adaptiveGlassEffect(tint: .blue.opacity(0.5), interactive: true)
```

#### セクションの作成
```swift
GlassSection(
    title: "セクション名",
    icon: "icon.name",
    tintColor: .blue
) {
    // コンテンツ
}
```

#### アクセシビリティ対応の確認
```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

if reduceTransparency {
    // フォールバック実装
} else {
    // ガラスエフェクト
}
```

---

**このドキュメントで実装が可能になりましたか？不明点があればお気軽にお聞きください。**
