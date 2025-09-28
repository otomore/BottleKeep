# BottleKeep → BottleKeeper アプリ名変更計画書

## 概要
このドキュメントは、アプリケーション名を「BottleKeep」から「BottleKeeper」に変更するために必要なすべての修正箇所と手順を記載した計画書です。

## 修正対象ファイル一覧

### 1. プロジェクト構造の変更

#### ディレクトリ名の変更
```
C:\Users\Yuto\dev\BottleKeep\ → C:\Users\Yuto\dev\BottleKeeper\
```

#### プロジェクトファイル名の変更
```
BottleKeep.xcodeproj → BottleKeeper.xcodeproj
BottleKeep.xcodeproj.backup → BottleKeeper.xcodeproj.backup (必要に応じて)
```

#### メインアプリケーションディレクトリ
```
BottleKeep/ → BottleKeeper/
BottleKeepTests/ → BottleKeeperTests/
BottleKeepUITests/ → BottleKeeperUITests/
```

### 2. Xcodeプロジェクト設定ファイル

#### BottleKeep.xcodeproj/project.pbxproj
修正箇所（約30箇所）:
- Line 10: `BottleKeepApp.swift` の参照
- Line 14, 59, 348-354: `BottleKeep.xcdatamodeld` および `BottleKeep.xcdatamodel` の参照
- Line 54, 122, 249: `BottleKeep.app` の参照
- Line 114, 127, 141: ディレクトリパス `BottleKeep`
- Line 155: `BottleKeepApp.swift` の参照
- Line 235, 237, 247-248: ターゲット名 `BottleKeep`
- Line 267, 281: プロジェクト名 `BottleKeep`
- Line 303, 305: ソースファイルの参照
- Line 487, 491, 520, 524: Info.plistパスとDevelopment Asset Paths
- Line 549, 558: Build configuration list の参照

#### BottleKeep.xcodeproj/xcshareddata/xcschemes/BottleKeep.xcscheme
- スキーム名の変更: `BottleKeep.xcscheme` → `BottleKeeper.xcscheme`
- スキーム内のすべての `BottleKeep` 参照を `BottleKeeper` に変更

### 3. ソースコードファイル

#### メインアプリケーション

**BottleKeep/App/BottleKeepApp.swift → BottleKeeper/App/BottleKeeperApp.swift**
```swift
// Line 5: struct名の変更
struct BottleKeepApp: App → struct BottleKeeperApp: App
```

**BottleKeep/Info.plist → BottleKeeper/Info.plist**
```xml
Line 8:  <string>BottleKeep</string> → <string>BottleKeeper</string>  // CFBundleDisplayName
Line 10: <string>BottleKeep</string> → <string>BottleKeeper</string>  // CFBundleExecutable
Line 12: <string>com.bottlekeep.whiskey</string> → <string>com.bottlekeeper.whiskey</string>  // CFBundleIdentifier
Line 16: <string>BottleKeep</string> → <string>BottleKeeper</string>  // CFBundleName
```

#### Core Data関連

**BottleKeep/Repositories/BottleRepository.swift**
```swift
// Core Dataコンテナ名の変更（該当箇所があれば）
NSPersistentContainer(name: "BottleKeep") → NSPersistentContainer(name: "BottleKeeper")
```

**BottleKeep/Services/CoreDataManager.swift**
```swift
// Core Dataモデル名の変更
let container = NSPersistentContainer(name: "BottleKeep") → NSPersistentContainer(name: "BottleKeeper")
```

### 4. テストファイル

#### ユニットテスト

**BottleKeepTests/BottleRepositoryTests.swift**
```swift
Line 3: @testable import BottleKeep → @testable import BottleKeeper
Line 25: NSPersistentContainer(name: "BottleKeep") → NSPersistentContainer(name: "BottleKeeper")
```

**BottleKeepTests/BottleListViewModelTests.swift**
```swift
Line 3: @testable import BottleKeep → @testable import BottleKeeper
```

**BottleKeepTests/WishlistRepositoryTests.swift**
```swift
Line 3: @testable import BottleKeep → @testable import BottleKeeper
Line 25: NSPersistentContainer(name: "BottleKeep") → NSPersistentContainer(name: "BottleKeeper")
```

**BottleKeepTests/StatisticsViewModelTests.swift**
```swift
Line 2: @testable import BottleKeep → @testable import BottleKeeper
```

**BottleKeepTests/CoreDataIntegrationTests.swift**
```swift
Line 3: @testable import BottleKeep → @testable import BottleKeeper
```

#### UIテスト

**BottleKeepUITests/BottleKeepUITests.swift → BottleKeeperUITests/BottleKeeperUITests.swift**
```swift
Line 3: final class BottleKeepUITests → final class BottleKeeperUITests
```

**BottleKeepUITests/BottleKeepUITestsLaunchTests.swift → BottleKeeperUITests/BottleKeeperUITestsLaunchTests.swift**
```swift
// クラス名の変更
class BottleKeepUITestsLaunchTests → class BottleKeeperUITestsLaunchTests
```

### 5. ビルド設定・証明書関連

#### ExportOptions.plist
```xml
Line 49: <string>BottleKeep Distribution</string> → <string>BottleKeeper Distribution</string>
```

### 6. GitHub Actions ワークフロー

#### .github/workflows/certificate-helper.yml
```yaml
Line 17: openssl genrsa -out BottleKeep_Distribution.key → BottleKeeper_Distribution.key
Line 20-21: BottleKeep_Distribution.csr → BottleKeeper_Distribution.csr
Line 21: /O=BottleKeep/CN=BottleKeep Distribution → /O=BottleKeeper/CN=BottleKeeper Distribution
Line 38-39, 87, 101-102, 108-109, 118, 120, 123: すべてのファイル名を変更
```

#### .github/workflows/create-ios-certificates.yml
```yaml
Line 17-18: CERTIFICATE_NAME と ORGANIZATION を変更
Line 38, 42-43, 49, 53, 60, 92-93, 119-120, 124, 145, 150, 159, 162, 171: すべての参照を変更
```

#### .github/workflows/ios-build.yml
```yaml
プロジェクト名とスキーム名の変更:
-project BottleKeep.xcodeproj → BottleKeeper.xcodeproj
-scheme BottleKeep → BottleKeeper
```

#### .github/workflows/ios-simple-build.yml, test-build.yml
```yaml
同様にプロジェクト名とスキーム名を変更
```

### 7. ドキュメントファイル

#### README.md
```markdown
Line 1: # BottleKeep 🥃 → # BottleKeeper 🥃
Line 5: GitHubバッジのURL更新
Line 10: アプリ説明文の更新
Line 49-50: クローンコマンドとディレクトリ名
Line 56, 59, 64, 67, 70: ビルドコマンドの更新
Line 99-114: プロジェクト構造の説明
```

#### docs/配下のすべてのドキュメント
以下のファイルで「BottleKeep」を「BottleKeeper」に置換:
- api-specification.md
- architecture.md
- business-logic.md
- copy-text.md
- coredata-design.md
- data-model.md
- development-environment.md
- development-guidelines.md
- development-progress.md
- feature-requirements.md
- maintenance-guide.md
- mvp-features.md
- release-deployment.md
- requirements.md
- screen-flow.md
- security-privacy.md
- setup-guide.md
- tech-stack-enterprise.md
- tech-stack.md
- test-specification.md
- ui-ux-design.md
- user-manual.md

### 8. Git関連

#### .git/config
```
リモートリポジトリのURLを更新（必要に応じて）:
url = https://github.com/otomore/BottleKeep.git → https://github.com/otomore/BottleKeeper.git
```

## 実施手順

### Phase 1: 準備
1. プロジェクト全体のバックアップを作成
2. Xcodeを閉じる
3. Git でコミット（変更前の状態を保存）

### Phase 2: ファイル名とディレクトリ名の変更
1. メインアプリケーションディレクトリ名を変更
   - `BottleKeep/` → `BottleKeeper/`
   - `BottleKeepTests/` → `BottleKeeperTests/`
   - `BottleKeepUITests/` → `BottleKeeperUITests/`

2. Xcodeプロジェクトファイル名を変更
   - `BottleKeep.xcodeproj` → `BottleKeeper.xcodeproj`

3. スキーマファイル名を変更
   - `BottleKeep.xcscheme` → `BottleKeeper.xcscheme`

4. ソースファイル名を変更
   - `BottleKeepApp.swift` → `BottleKeeperApp.swift`
   - `BottleKeepUITests.swift` → `BottleKeeperUITests.swift`
   - `BottleKeepUITestsLaunchTests.swift` → `BottleKeeperUITestsLaunchTests.swift`

5. Core Dataモデル名を変更
   - `BottleKeep.xcdatamodeld` → `BottleKeeper.xcdatamodeld`
   - `BottleKeep.xcdatamodel` → `BottleKeeper.xcdatamodel`

### Phase 3: ファイル内容の修正
1. Xcodeプロジェクトファイル（project.pbxproj）の修正
2. Info.plistの修正
3. すべてのSwiftソースファイルの修正
4. テストファイルの修正
5. GitHub Actionsワークフローファイルの修正
6. ドキュメントファイルの修正

### Phase 4: 検証
1. Xcodeでプロジェクトを開く
2. ビルドエラーがないことを確認
3. シミュレータでアプリを実行
4. ユニットテストを実行
5. UIテストを実行

### Phase 5: 最終確認
1. すべての「BottleKeep」文字列が「BottleKeeper」に変更されたことを確認
   ```bash
   grep -r "BottleKeep" . --exclude-dir=.git
   ```

2. Git で変更をコミット
3. GitHub Actionsのワークフローが正常に動作することを確認

### Phase 6: プロジェクトルートディレクトリの変更（オプション）
最後に、プロジェクトルートディレクトリ自体を変更:
```bash
cd ..
mv BottleKeep BottleKeeper
cd BottleKeeper
```

## 注意事項

1. **Bundle Identifier**: `com.bottlekeep.whiskey` から `com.bottlekeeper.whiskey` への変更は、App Store への影響があるため慎重に検討が必要

2. **証明書とプロビジョニングプロファイル**: Bundle IDを変更する場合、新しい証明書とプロビジョニングプロファイルの作成が必要

3. **Git履歴**: ディレクトリ名の変更は Git の履歴に影響するため、適切にコミットメッセージを記載

4. **CI/CD**: GitHub Actions以外のCI/CDツールを使用している場合は、それらの設定も更新が必要

5. **依存関係**: 外部ライブラリやフレームワークがプロジェクト名に依存している場合は、追加の修正が必要

## 自動化スクリプト（参考）

以下は、一部の変更を自動化するためのスクリプト例です：

```bash
#!/bin/bash

# バックアップ作成
cp -r . ../BottleKeep_backup

# ディレクトリ名の変更
mv BottleKeep BottleKeeper
mv BottleKeepTests BottleKeeperTests
mv BottleKeepUITests BottleKeeperUITests

# プロジェクトファイル名の変更
mv BottleKeep.xcodeproj BottleKeeper.xcodeproj

# ファイル内の文字列置換（macOS/Linux）
find . -type f -name "*.swift" -exec sed -i '' 's/BottleKeep/BottleKeeper/g' {} +
find . -type f -name "*.plist" -exec sed -i '' 's/BottleKeep/BottleKeeper/g' {} +
find . -type f -name "*.pbxproj" -exec sed -i '' 's/BottleKeep/BottleKeeper/g' {} +
find . -type f -name "*.md" -exec sed -i '' 's/BottleKeep/BottleKeeper/g' {} +
find . -type f -name "*.yml" -exec sed -i '' 's/BottleKeep/BottleKeeper/g' {} +

echo "変更が完了しました。Xcodeでプロジェクトを開いて確認してください。"
```

**注意**: このスクリプトは参考例です。実際に使用する前に必ずバックアップを作成し、各ステップを慎重に確認してください。

## 完了チェックリスト

- [ ] プロジェクトのバックアップを作成
- [ ] すべてのディレクトリ名を変更
- [ ] すべてのファイル名を変更
- [ ] project.pbxprojファイルを修正
- [ ] Info.plistを修正
- [ ] すべてのSwiftファイルを修正
- [ ] すべてのテストファイルを修正
- [ ] GitHub Actionsワークフローを修正
- [ ] ドキュメントを更新
- [ ] ビルドエラーがないことを確認
- [ ] テストが成功することを確認
- [ ] アプリが正常に動作することを確認
- [ ] Gitにコミット
- [ ] CI/CDパイプラインが正常に動作することを確認

## 更新履歴

- 2024-09-28: 初版作成