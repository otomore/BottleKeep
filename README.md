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

- **開発言語**: Swift 5.0+
- **UI Framework**: SwiftUI
- **データ管理**: Core Data
- **対応OS**: iOS 15.0+, iPadOS 15.0+
- **開発環境**: Xcode 15+
- **プロジェクト形式**: Xcodeプロジェクト (.xcodeproj)

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

2. Xcodeでプロジェクトを開く
```bash
# Xcodeプロジェクトファイルを開く
open BottleKeep.xcodeproj
```

または、Xcode GUIから `BottleKeep.xcodeproj` を開いてください。

### ビルド & テスト
```bash
# ビルド実行
xcodebuild build -project BottleKeep.xcodeproj -scheme BottleKeep -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

# テスト実行
xcodebuild test -project BottleKeep.xcodeproj -scheme BottleKeep -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

# アーカイブビルド（リリース用）
xcodebuild archive -project BottleKeep.xcodeproj -scheme BottleKeep -destination 'generic/platform=iOS' -archivePath ./BottleKeep.xcarchive
```

## 🔧 CI/CD セットアップガイド

このプロジェクトでは、GitHub ActionsとGitHub Secretsを使用した完全自動化CI/CDパイプラインを構築済みです。

### 必要なGitHub Secrets
以下のSecretsが設定済みです：
- `BUILD_CERTIFICATE_BASE64`: iOS配信用証明書
- `P12_PASSWORD`: 証明書のパスワード
- `BUILD_PROVISION_PROFILE_BASE64`: プロビジョニングプロファイル
- `KEYCHAIN_PASSWORD`: キーチェーンパスワード
- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API キーID
- `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect Issuer ID
- `APP_STORE_CONNECT_API_KEY`: App Store Connect API キー

## 📱 TestFlight ベータテスト

現在、TestFlightでベータ版を配信中です。テストに参加希望の方は以下の手順で参加できます：

1. iOS 15.0以上のデバイスを準備
2. TestFlightアプリをインストール
3. 招待リンクからアクセス
4. フィードバックをお待ちしています！

## 🏗 アーキテクチャ

```
BottleKeep/
├── BottleKeep.xcodeproj/     # Xcodeプロジェクト設定
├── BottleKeep/               # メインアプリケーション
│   ├── App/                  # アプリエントリーポイント
│   ├── Models/               # Core Data モデル
│   ├── Views/                # SwiftUI ビュー
│   ├── ViewModels/           # ビューモデル（MVVM）
│   ├── Services/             # ビジネスロジック
│   ├── Repositories/         # データアクセス層
│   ├── Utils/                # ユーティリティ
│   ├── Assets.xcassets       # アプリアイコン・画像リソース
│   ├── BottleKeep.xcdatamodeld # Core Data モデル
│   ├── Preview Content/      # SwiftUI プレビュー用
│   └── Info.plist           # アプリ設定
├── BottleKeepTests/          # ユニットテスト
├── BottleKeepUITests/        # UIテスト
└── .github/workflows/        # GitHub Actions設定
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

