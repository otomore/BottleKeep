# BottleKeep 🥃

ウイスキーコレクション管理iOS/iPadアプリ

[![iOS Build](https://github.com/otomore/BottleKeep/actions/workflows/ios-build.yml/badge.svg)](https://github.com/otomore/BottleKeep/actions/workflows/ios-build.yml)
[![TestFlight](https://img.shields.io/badge/TestFlight-Available-blue)](https://testflight.apple.com/)

## 🎯 概要

BottleKeepは、ウイスキー愛好家のためのコレクション管理アプリです。あなたの貴重なウイスキーコレクションを整理し、テイスティング体験を記録できます。

## ✨ 機能

- 📦 **ボトル管理**: ウイスキーボトルの詳細情報を記録
- 📝 **テイスティングノート**: 味わいの特徴やレビューを保存
- 🔍 **検索・フィルタ**: コレクションから素早く目的のボトルを発見
- 📸 **写真カタログ**: ボトルの写真付きで視覚的に管理
- 📊 **統計情報**: コレクションの傾向やお気に入りを分析

## 🛠 技術スタック

- **開発言語**: Swift 5.9+
- **UI Framework**: SwiftUI
- **データ管理**: Core Data
- **対応OS**: iOS 15.0+, iPadOS 15.0+
- **開発環境**: Xcode 15+
- **パッケージ管理**: Swift Package Manager

## 🚀 CI/CD & 配信

このプロジェクトでは完全自動化されたビルド・配信パイプラインを構築しています：

### GitHub Actions ワークフロー
- ✅ **自動ビルド**: mainブランチへのpush時
- ✅ **ユニットテスト**: 品質保証の自動実行
- ✅ **TestFlight配信**: 自動でベータ版をリリース
- ✅ **コード署名**: 証明書とプロビジョニングプロファイルの自動管理

### 配信フロー
```
コード変更 → GitHub Push → 自動ビルド → TestFlight → App Store
```

## 📖 開発者向けガイド

### 環境セットアップ
1. リポジトリをクローン
```bash
git clone https://github.com/otomore/BottleKeep.git
cd BottleKeep
```

2. Swift Package Managerで依存関係を解決
```bash
swift package resolve
```

3. Xcodeでプロジェクトを開く
```bash
# Package.swiftから直接開く
xed .
```

### ビルド & テスト
```bash
# ビルド実行
swift build

# テスト実行
swift test

# iOS Simulatorでビルド
xcodebuild build -scheme BottleKeep -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
```

## 🔧 CI/CD セットアップガイド

### 1. 証明書とプロビジョニングプロファイル
詳細な手順は [`PROVISIONING_PROFILE_GUIDE.md`](PROVISIONING_PROFILE_GUIDE.md) を参照

### 2. App Store Connect API設定
TestFlight自動配信のセットアップは [`APP_STORE_CONNECT_SETUP.md`](APP_STORE_CONNECT_SETUP.md) を参照

### 3. TestFlight配信テスト
配信テストの手順は [`TESTFLIGHT_GUIDE.md`](TESTFLIGHT_GUIDE.md) を参照

## 📱 TestFlight ベータテスト

現在、TestFlightでベータ版を配信中です。テストに参加希望の方は以下の手順で参加できます：

1. iOS 15.0以上のデバイスを準備
2. TestFlightアプリをインストール
3. 招待リンクからアクセス
4. フィードバックをお待ちしています！

## 🏗 アーキテクチャ

```
BottleKeep/
├── BottleKeep/           # メインアプリケーション
│   ├── Models/           # Core Data モデル
│   ├── Views/            # SwiftUI ビュー
│   ├── Services/         # ビジネスロジック
│   └── Resources/        # アセット・設定ファイル
├── Tests/                # ユニットテスト
├── .github/workflows/    # GitHub Actions設定
└── Package.swift         # Swift Package Manager設定
```

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. Pull Requestを作成

## 📄 ライセンス

Private Repository - All Rights Reserved

## 📞 サポート

- GitHub Issues: バグ報告や機能要望
- TestFlight: ベータ版フィードバック
- Email: 開発者への直接連絡

---

**Made with ❤️ for whiskey enthusiasts**

## ライセンス

Private Repository - All Rights Reserved