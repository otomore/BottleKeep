# BottleKeep 開発環境セットアップガイド

## 1. 前提条件

### 1.1 システム要件
- **macOS**: macOS 13.0 (Ventura) 以上
- **Xcode**: Xcode 15.0 以上
- **iOS**: iOS 16.0 以上 (テスト用)
- **Git**: Git 2.30 以上
- **Apple Developer Account**: 実機テスト・配布時に必要

### 1.2 推奨ハードウェア
- **Mac**: Apple Silicon (M1/M2) またはIntel Core i5以上
- **メモリ**: 16GB RAM以上
- **ストレージ**: 50GB以上の空き容量
- **iOS端末**: iPhone/iPad (実機テスト用)

## 2. 開発環境構築

### 2.1 Xcode インストール

#### 2.1.1 App Storeからインストール
1. Mac App Storeを開く
2. "Xcode"で検索
3. Xcode 15.0以上をインストール
4. 初回起動時にAdditional Componentsをインストール

#### 2.1.2 コマンドラインツールの設定
```bash
# Xcode Command Line Toolsインストール確認
xcode-select --install

# Xcodeパスの設定確認
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# インストール確認
xcodebuild -version
# Xcode 15.0
# Build version 15A240d
```

### 2.2 必要ツールのインストール

#### 2.2.1 Homebrew
```bash
# Homebrewインストール（未インストールの場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# PATHの設定（Apple Silicon Macの場合）
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# インストール確認
brew --version
```

#### 2.2.2 Git設定
```bash
# Git設定（初回のみ）
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# セキュリティ設定
git config --global init.defaultBranch main
git config --global pull.rebase true

# SSH認証設定（推奨）
ssh-keygen -t ed25519 -C "your.email@example.com"

# SSH Configファイル設定（macOS Keychain使用）
cat >> ~/.ssh/config << EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  UseKeychain yes
  AddKeysToAgent yes
EOF

# SSH Agent追加（macOS Keychain自動追加）
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# 公開鍵をGitHubに追加
cat ~/.ssh/id_ed25519.pub
# 出力された内容をGitHubのSSH Keysに追加

# SSH接続テスト
ssh -T git@github.com
```

#### 2.2.3 開発支援ツール
```bash
# SwiftLint（コード品質チェック）
brew install swiftlint

# SwiftFormat（コードフォーマッター）
brew install swiftformat

# CocoaPods（依存管理、必要に応じて）
brew install cocoapods

# FastLane（CI/CD、必要に応じて）
brew install fastlane

# インストール確認
swiftlint version
swiftformat --version
```

## 3. プロジェクト環境構築

### 3.1 リポジトリクローン
```bash
# プロジェクトディレクトリに移動
cd ~/Development  # または任意のディレクトリ

# リポジトリクローン
git clone git@github.com:yourusername/BottleKeep.git
cd BottleKeep

# ブランチ確認
git branch -a
git status
```

### 3.2 プロジェクト構造確認
```
BottleKeep/
├── BottleKeep.xcodeproj          # Xcodeプロジェクトファイル
├── BottleKeep/                   # メインアプリケーション
│   ├── App/                      # アプリケーション起動
│   ├── Views/                    # SwiftUI View
│   ├── ViewModels/               # ViewModel
│   ├── Models/                   # データモデル
│   ├── Repositories/             # データアクセス層
│   ├── Services/                 # 外部サービス
│   ├── Utils/                    # ユーティリティ
│   └── Resources/                # リソースファイル
├── BottleKeepTests/              # Unit Tests
├── BottleKeepUITests/            # UI Tests
├── docs/                         # ドキュメント
├── .swiftlint.yml               # SwiftLint設定
├── .gitignore                   # Git無視ファイル
└── README.md                    # プロジェクト概要
```

### 3.3 Xcodeプロジェクト設定

#### 3.3.1 プロジェクトを開く
```bash
# Xcodeでプロジェクトを開く
open BottleKeep.xcodeproj
```

#### 3.3.2 Team設定（実機テスト時）
1. Xcodeでプロジェクトを選択
2. TARGETSで"BottleKeep"を選択
3. "Signing & Capabilities"タブを開く
4. TeamでApple Developer Accountを選択
5. Bundle Identifierを設定（例：com.yourname.BottleKeep）

#### 3.3.3 Build Settings確認
```
General:
- Deployment Target: iOS 16.0
- Bundle Identifier: com.yourname.BottleKeep
- Version: 1.0
- Build: 1

Signing & Capabilities:
- Automatically manage signing: ✓
- Team: Your Development Team
- Capabilities:
  - iCloud (CloudKit)
  - Camera Usage
  - Photo Library Usage
```

## 4. CloudKit設定

### 4.1 CloudKit Container作成

#### 4.1.1 Apple Developer Portalでの設定
1. [Apple Developer Portal](https://developer.apple.com) にログイン
2. "Certificates, Identifiers & Profiles" → "CloudKit Containers"
3. "+" ボタンで新しいContainerを作成
4. Container Identifier: `iCloud.com.yourname.BottleKeep`

#### 4.1.2 Xcode での CloudKit 設定
1. PROJECT → BottleKeep → "Signing & Capabilities"
2. "+ Capability" → "iCloud"
3. Services: "CloudKit" をチェック
4. Containers: 作成したContainerを選択

#### 4.1.3 Core Data + CloudKit設定確認
```swift
// CoreDataManager.swift での設定確認
let container = NSPersistentCloudKitContainer(name: "BottleKeep")

let description = container.persistentStoreDescriptions.first
description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.yourname.BottleKeep"
)
```

### 4.2 CloudKit Schema設定

#### 4.2.1 開発環境でのSchema生成
1. Xcodeでアプリをビルド・実行
2. Core Dataエンティティ作成（テストデータ）
3. CloudKit Consoleでスキーマ確認
4. 必要に応じてフィールド調整

#### 4.2.2 CloudKit Console確認
1. [CloudKit Console](https://icloud.developer.apple.com/) にアクセス
2. 作成したContainerを選択
3. Schema → Record Types でエンティティ確認
4. Development環境でテスト

## 5. 開発ツール設定

### 5.1 SwiftLint設定

#### 5.1.1 設定ファイル確認
```yaml
# .swiftlint.yml
included:
  - BottleKeep
  - BottleKeepTests

excluded:
  - BottleKeep/Resources
  - build

disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - explicit_init
  - first_where
  - force_unwrapping

line_length:
  warning: 120
  error: 200

function_body_length:
  warning: 50
  error: 100
```

#### 5.1.2 Xcode Build Phase追加
1. PROJECT → BottleKeep → "Build Phases"
2. "+" → "New Run Script Phase"
3. Scriptに以下を追加：
```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

### 5.2 Git Hooks設定

#### 5.2.1 Pre-commit Hook
```bash
# .git/hooks/pre-commit
#!/bin/sh

# SwiftLintチェック
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "SwiftLint not installed"
  exit 1
fi

# SwiftFormatチェック
if which swiftformat >/dev/null; then
  swiftformat --lint .
else
  echo "SwiftFormat not installed"
  exit 1
fi
```

```bash
# Hook実行権限付与
chmod +x .git/hooks/pre-commit
```

## 6. ビルド・実行

### 6.1 初回ビルド

#### 6.1.1 Simulatorでのビルド
1. Xcodeでシミュレーター選択（iPhone 15推奨）
2. ⌘+R でビルド・実行
3. エラーがないか確認

#### 6.1.2 実機でのビルド
1. iOS端末をMacに接続
2. Xcodeで端末を選択
3. "Trust This Computer"を端末で許可
4. ⌘+R でビルド・実行

### 6.2 トラブルシューティング

#### 6.2.1 よくある問題と解決法

**問題**: Code Signing Error
```
解決法:
1. Apple Developer Accountにログイン確認
2. Bundle Identifierの重複確認
3. Certificateの有効期限確認
4. "Automatically manage signing"の再設定
```

**問題**: CloudKit Container not found
```
解決法:
1. Container Identifier確認
2. Apple Developer Portalでの設定確認
3. iCloudアカウント設定確認
4. Simulator再起動
```

**問題**: SwiftLint Warnings
```
解決法:
1. swiftlint autocorrect実行
2. 手動でコード修正
3. 必要に応じて.swiftlint.yml調整
```

**問題**: Build Failed - Missing Dependencies
```
解決法:
1. Xcode Clean Build Folder (⌘+Shift+K)
2. Derived Data削除
3. Xcode再起動
4. macOS再起動（最終手段）
```

### 6.3 デバッグ設定

#### 6.3.1 Scheme設定
1. Product → Scheme → Edit Scheme
2. Run → Arguments タブ
3. Environment Variables追加:
```
DEBUG_MODE: 1
CORE_DATA_DEBUG: 1
CLOUDKIT_DEBUG: 1
```

#### 6.3.2 ログ設定
```swift
// Debug.swift
#if DEBUG
import os.log

struct Logger {
    static let general = os.Logger(subsystem: "com.yourname.BottleKeep", category: "general")
    static let coreData = os.Logger(subsystem: "com.yourname.BottleKeep", category: "coreData")
    static let cloudKit = os.Logger(subsystem: "com.yourname.BottleKeep", category: "cloudKit")
}
#endif
```

## 7. テスト環境設定

### 7.1 Unit Test設定

#### 7.1.1 Test Target確認
1. TARGETSで"BottleKeepTests"を選択
2. General → "Host Application"が"BottleKeep"に設定されていることを確認
3. Build Settings → "Bundle Loader"設定確認

#### 7.1.2 テスト実行
```bash
# コマンドラインでのテスト実行
xcodebuild test \
  -scheme BottleKeep \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  -configuration Debug

# Xcodeでのテスト実行
# ⌘+U または Product → Test
```

### 7.2 UI Test設定

#### 7.2.1 UI Test Target確認
1. TARGETSで"BottleKeepUITests"を選択
2. General → "Test Target"が"BottleKeep"に設定されていることを確認

#### 7.2.2 UI Test用引数設定
```swift
// BottleKeepUITests.swift
override func setUp() {
    super.setUp()
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    app.launch()
}
```

## 8. 初期セットアップ検証

### 8.1 チェックリスト

#### 8.1.1 環境確認
- [ ] Xcode 15.0以上インストール済み
- [ ] Command Line Toolsインストール済み
- [ ] Git設定完了
- [ ] SwiftLint/SwiftFormatインストール済み
- [ ] プロジェクトクローン完了

#### 8.1.2 プロジェクト確認
- [ ] Xcodeでプロジェクトが開ける
- [ ] Build Settingsが正しく設定されている
- [ ] CloudKit Containerが設定されている
- [ ] Code Signingが設定されている（実機テスト時）

#### 8.1.3 ビルド・実行確認
- [ ] Simulatorでビルド・実行できる
- [ ] 実機でビルド・実行できる（該当時）
- [ ] Unit Testが実行できる
- [ ] UI Testが実行できる
- [ ] SwiftLintでエラーがない

### 8.2 セットアップ完了確認

#### 8.2.1 サンプル実行
```bash
# プロジェクトディレクトリで以下を実行
cd BottleKeep

# SwiftLintチェック
swiftlint

# テスト実行
xcodebuild test \
  -scheme BottleKeep \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

echo "✅ セットアップ完了!"
```

#### 8.2.2 次のステップ
1. [開発ガイドライン](development-guidelines.md)を確認
2. [アーキテクチャ設計書](architecture.md)を確認
3. MVPの実装開始
4. 定期的なコミット・プッシュ

## 9. トラブルシューティング

### 9.1 Xcode関連

#### 9.1.1 Xcode起動しない
```bash
# Xcodeリセット
sudo xcode-select --reset
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 設定削除
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

#### 9.1.2 Simulator問題
```bash
# Simulator Device削除・再作成
xcrun simctl list devices
xcrun simctl delete unavailable
xcrun simctl create "iPhone 15" "iPhone 15" "iOS 17.0"
```

### 9.2 CloudKit関連

#### 9.2.1 同期しない
1. iCloudアカウント確認
2. Simulator iCloud設定確認
3. Container ID確認
4. Network接続確認

#### 9.2.2 Schema問題
1. CloudKit Console確認
2. Development Database確認
3. アプリ再インストール
4. Core Data Reset

### 9.3 Git関連

#### 9.3.1 Permission denied (SSH)
```bash
# SSH Key確認
ssh -T git@github.com

# SSH Agent確認
ssh-add -l

# SSH Key再追加
ssh-add ~/.ssh/id_ed25519
```

### 9.4 パフォーマンス改善

#### 9.4.1 Xcode高速化
```bash
# Index削除
rm -rf ~/Library/Developer/Xcode/DerivedData/*/Index

# Preview削除
rm -rf ~/Library/Developer/Xcode/UserData/Previews

# Archives削除（古いもの）
rm -rf ~/Library/Developer/Xcode/Archives/old_archives
```

## 10. リソース・参考資料

### 10.1 Apple公式ドキュメント
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Core Data Documentation](https://developer.apple.com/documentation/coredata)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)

### 10.2 サードパーティツール
- [SwiftLint GitHub](https://github.com/realm/SwiftLint)
- [SwiftFormat GitHub](https://github.com/nicklockwood/SwiftFormat)
- [Fastlane Documentation](https://docs.fastlane.tools/)

### 10.3 コミュニティリソース
- [Swift.org](https://swift.org/)
- [Hacking with Swift](https://www.hackingwithswift.com/)
- [Stack Overflow - iOS](https://stackoverflow.com/questions/tagged/ios)

---

## 11. セキュリティ設定強化

### 11.1 macOS セキュリティ設定
```bash
# FileVault暗号化確認（推奨）
sudo fdesetup status

# Firewall有効化
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Gatekeeper設定確認
spctl --status

# SSH設定セキュリティ強化
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/config
```

### 11.2 Xcode セキュリティ設定
```
プライベート情報の保護:
1. Build Settings → "Strip Debug Symbols During Copy": Release時にYes
2. Build Settings → "Generate Debug Symbols": Debug時のみYes
3. Capabilities → "App Sandbox": 必要最小限の権限のみ
4. Info.plist → Privacy Usage Descriptions: 適切な説明文
```

### 11.3 認証情報管理
```bash
# Keychain Access での証明書管理
# - Development Certificate: ローカル開発用
# - Distribution Certificate: App Store配布用
# - Provisioning Profiles: 定期更新

# Git Credential Helper設定（セキュア）
git config --global credential.helper osxkeychain

# 環境変数ファイル作成（.gitignore対象）
cat > .env.local << EOF
# 開発用設定（コミットしない）
CLOUDKIT_CONTAINER_ID=iCloud.com.yourname.BottleKeep.dev
DEBUG_MODE=true
EOF

# .gitignoreに追加
echo ".env.local" >> .gitignore
```

### 11.4 開発環境分離
```swift
// 環境別設定管理
#if DEBUG
struct Config {
    static let cloudKitContainer = "iCloud.com.yourname.BottleKeep.dev"
    static let enableLogging = true
    static let enableCloudKitConsoleOutput = true
}
#else
struct Config {
    static let cloudKitContainer = "iCloud.com.yourname.BottleKeep"
    static let enableLogging = false
    static let enableCloudKitConsoleOutput = false
}
#endif
```

## 12. パフォーマンス最適化設定

### 12.1 Xcode パフォーマンス設定
```bash
# DerivedData定期クリーンアップスクリプト
cat > ~/bin/xcode-cleanup.sh << 'EOF'
#!/bin/bash
echo "Xcodeパフォーマンス最適化実行中..."

# DerivedData削除
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ DerivedData削除完了"

# Archives古いもの削除（90日以上）
find ~/Library/Developer/Xcode/Archives -mtime +90 -delete
echo "✅ 古いArchives削除完了"

# iOS DeviceSupport古いもの削除
find ~/Library/Developer/Xcode/iOS\ DeviceSupport -mtime +180 -delete 2>/dev/null
echo "✅ 古いDeviceSupport削除完了"

echo "🎉 クリーンアップ完了!"
EOF

chmod +x ~/bin/xcode-cleanup.sh

# 週次実行のcron設定
(crontab -l 2>/dev/null; echo "0 9 * * 1 ~/bin/xcode-cleanup.sh") | crontab -
```

### 12.2 Build 設定最適化
```
Debug Configuration:
- Swift Compilation Mode: Incremental
- Swift Optimization Level: None (-Onone)
- GCC Optimization Level: None (-O0)

Release Configuration:
- Swift Compilation Mode: Whole Module
- Swift Optimization Level: Optimize for Speed (-O)
- GCC Optimization Level: Fastest, Smallest (-Os)
```

---

**文書バージョン**: 1.1
**作成日**: 2025-09-21
**最終更新**: 2025-09-23
**作成者**: 個人プロジェクト