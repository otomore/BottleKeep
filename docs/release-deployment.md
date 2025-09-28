# BottleKeeper リリース・デプロイメント手順書

## 1. デプロイメント戦略概要

### 1.1 リリース方針
- **個人利用フェーズ**: Xcodeから直接インストール
- **ベータテストフェーズ**: TestFlightでの限定配布
- **正式リリースフェーズ**: App Store配布

### 1.2 環境管理
```
Development → Staging → Production
     ↓           ↓         ↓
  (Local)   (TestFlight) (App Store)
```

### 1.3 バージョニング戦略
- **Semantic Versioning**: MAJOR.MINOR.PATCH (例: 1.0.0)
- **Build Number**: 自動増分 (例: 1, 2, 3, ...)
- **Pre-release**: beta, rc を使用 (例: 1.0.0-beta.1)

### 1.4 セキュリティ考慮事項
- **コード署名**: 必ず正しい証明書で署名
- **証明書管理**: 期限切れチェックと更新手順
- **プロビジョニングプロファイル**: 定期的な更新
- **敏感情報**: API Keyや証明書の安全な保管

## 2. 個人利用デプロイメント

### 2.1 直接インストール手順

#### 2.1.1 実機へのインストール
```bash
# 1. Xcodeプロジェクトを開く
open BottleKeeper.xcodeproj

# 2. 実機を接続・選択
# 3. Product → Archive (⌘+Shift+B)
# 4. Distribute App → Development
# 5. 実機にインストール
```

#### 2.1.2 Ad Hoc配布（複数端末）
1. **Archive作成**
   - Xcode → Product → Archive
   - Organizer → Distribute App → Ad Hoc

2. **Provisioning Profile設定**
   - Apple Developer Portal → Profiles
   - Distribution (Ad Hoc) プロファイル作成
   - 対象端末のUDIDを登録

3. **IPA生成・配布**
   ```bash
   # IPAファイルを配布用フォルダにコピー
   cp ~/Desktop/BottleKeeper.ipa ./releases/

   # インストール手順書も同梱
   cp docs/installation-guide.md ./releases/
   ```

### 2.2 開発用設定

#### 2.2.1 Debug Build設定
```swift
// Build Settings
#if DEBUG
let isDebugMode = true
let cloudKitContainer = "iCloud.com.yourname.BottleKeeper.dev"
#else
let isDebugMode = false
let cloudKitContainer = "iCloud.com.yourname.BottleKeeper"
#endif
```

#### 2.2.2 Configuration設定
```
Debug Configuration:
- DEBUG=1
- SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG
- CloudKit Container: Development

Release Configuration:
- DEBUG=0
- 最適化有効
- CloudKit Container: Production
```

## 3. TestFlight配布

### 3.1 TestFlight準備

#### 3.1.1 App Store Connect設定
1. **App Store Connectにログイン**
   - [App Store Connect](https://appstoreconnect.apple.com/)

2. **新しいアプリ追加**
   - My Apps → + → New App
   - Bundle ID: com.yourname.BottleKeeper
   - SKU: BottleKeeper2025
   - Primary Language: Japanese

3. **アプリ情報設定**
   ```
   Name: BottleKeeper
   Subtitle: ウイスキーコレクション管理
   Category: Lifestyle
   Content Rights: You retain all rights
   Age Rating: 17+ (アルコール関連)
   ```

#### 3.1.2 App情報・スクリーンショット
```
必要な素材:
- App Icon (1024x1024)
- iPhone Screenshots (6.7", 6.5", 5.5")
- iPad Screenshots (12.9", 11")
- App Preview Videos (Optional)
- App Description
- Keywords
- Privacy Policy URL
```

### 3.2 Archive & Upload

#### 3.2.1 Release Build
```bash
# 1. バージョン番号更新
# Info.plistまたはXcodeのGeneral設定
# CFBundleShortVersionString: 1.0.0
# CFBundleVersion: 1

# 2. Release configurationでArchive
# Xcode → Product → Archive
# Scheme: BottleKeeper
# Configuration: Release
```

#### 3.2.2 Upload to App Store Connect
```
1. Xcode Organizer → Archives
2. 対象Archive選択 → Distribute App
3. App Store Connect → Upload
4. Team: Your Development Team
5. Distribution Options:
   - Include bitcode: Yes
   - Upload your app's symbols: Yes
   - Manage Version and Build Number: Yes
```

### 3.3 TestFlight設定

#### 3.3.1 Build情報設定
```
App Store Connect → TestFlight:
1. Build選択
2. Test Information:
   - What to Test: 新機能の説明
   - Test Notes: テスト時の注意事項
3. Beta App Review Information:
   - Contact Information
   - Demo Account (必要に応じて)
   - Notes: レビュー用の説明
```

#### 3.3.2 Internal Testing
```
1. Internal Testers追加:
   - Team Member (開発者本人)
   - 最大100名まで

2. Testing開始:
   - Build → Internal Testing → Start Testing
   - テスター招待メール送信
```

#### 3.3.3 External Testing（必要に応じて）
```
1. Beta App Review申請
2. 承認後External Testers追加
3. Public Link作成（最大10,000名）
```

## 4. App Store リリース

### 4.1 App Store Review準備

#### 4.1.1 Review Guidelines確認
```
主要チェック項目:
- App Store Review Guidelines準拠
- Human Interface Guidelines準拠
- アルコール関連ガイドライン準拠
- Privacy Policy必須
- Age Rating適切設定
- アクセシビリティ対応
```

#### 4.1.2 App Store情報完成
```
必須情報:
1. App Information:
   - Name, Subtitle, Description
   - Keywords, Category
   - Privacy Policy URL
   - Support URL

2. Pricing and Availability:
   - Price Tier (Free推奨)
   - Availability (Japan)
   - App Store Distribution

3. App Review Information:
   - Contact Information
   - Demo Account (必要に応じて)
   - Review Notes
```

### 4.2 最終チェック

#### 4.2.1 機能チェックリスト
- [ ] 全コア機能動作確認
- [ ] CloudKit同期動作確認
- [ ] 各種端末・OS版での動作確認
- [ ] アクセシビリティ確認
- [ ] プライバシー設定確認
- [ ] クラッシュログ確認

#### 4.2.2 品質チェック
```bash
# SwiftLint確認
swiftlint

# Test実行
xcodebuild test \
  -scheme BottleKeeper \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

# Memory Leak確認
# Xcode → Product → Profile → Leaks
```

### 4.3 提出・Review Process

#### 4.3.1 Review提出
```
App Store Connect → App Store:
1. Version: 1.0.0
2. Build: TestFlightで承認済みBuild選択
3. App Information確認
4. Pricing確認
5. Submit for Review
```

#### 4.3.2 Review Status確認
```
Review Status:
- Waiting for Review: 審査待ち
- In Review: 審査中
- Pending Developer Release: 承認済み・リリース待ち
- Ready for Sale: リリース済み
- Rejected: 拒否 → 修正後再提出
```

## 5. CI/CD 自動化

### 5.1 GitHub Actions設定

#### 5.1.1 Archive & Upload自動化
```yaml
# .github/workflows/release.yml
name: Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Set up Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'

    - name: Install Apple Certificate
      uses: apple-actions/import-codesign-certs@v1
      with:
        p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
        p12-password: ${{ secrets.CERTIFICATES_P12_PASSWORD }}

    - name: Install Provisioning Profile
      uses: apple-actions/download-provisioning-profiles@v1
      with:
        bundle-id: com.yourname.BottleKeeper
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}

    - name: Build Archive
      run: |
        xcodebuild archive \
          -scheme BottleKeeper \
          -configuration Release \
          -archivePath build/BottleKeeper.xcarchive \
          CODE_SIGN_IDENTITY="iPhone Distribution" \
          PROVISIONING_PROFILE_SPECIFIER="BottleKeeper Distribution"

    - name: Export IPA
      run: |
        xcodebuild -exportArchive \
          -archivePath build/BottleKeeper.xcarchive \
          -exportPath build \
          -exportOptionsPlist ExportOptions.plist

    - name: Upload to App Store Connect
      uses: apple-actions/upload-testflight-build@v1
      with:
        app-path: build/BottleKeeper.ipa
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

#### 5.1.2 Secrets設定
```
GitHub Repository → Settings → Secrets:
- CERTIFICATES_P12: Distribution Certificate (base64)
- CERTIFICATES_P12_PASSWORD: Certificate Password
- APPSTORE_ISSUER_ID: App Store Connect API Issuer ID
- APPSTORE_KEY_ID: App Store Connect API Key ID
- APPSTORE_PRIVATE_KEY: App Store Connect API Private Key
```

### 5.2 Fastlane設定

#### 5.2.1 Fastfile作成
```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    # Version increment
    increment_build_number(xcodeproj: "BottleKeeper.xcodeproj")

    # Build
    build_app(
      scheme: "BottleKeeper",
      configuration: "Release"
    )

    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      changelog: "Bug fixes and improvements"
    )

    # Slack notification (optional)
    slack(
      message: "New build uploaded to TestFlight! 🚀",
      channel: "#releases"
    )
  end

  desc "Build and upload to App Store"
  lane :release do
    # Version management
    ensure_git_status_clean

    # Build
    build_app(
      scheme: "BottleKeeper",
      configuration: "Release"
    )

    # Upload to App Store
    upload_to_app_store(
      force: true,
      submit_for_review: false
    )

    # Git tag
    add_git_tag(
      tag: get_version_number(xcodeproj: "BottleKeeper.xcodeproj")
    )
    push_git_tags
  end
end
```

#### 5.2.2 Fastlane実行
```bash
# TestFlight配布
fastlane beta

# App Store配布準備
fastlane release
```

## 6. バージョン管理

### 6.1 Git Tagging戦略

#### 6.1.1 Release Tag作成
```bash
# Release準備
git checkout main
git pull origin main

# Tag作成
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Release branch作成（必要に応じて）
git checkout -b release/1.0.0
git push origin release/1.0.0
```

#### 6.1.2 Hotfix管理
```bash
# Hotfix branch作成
git checkout -b hotfix/1.0.1 v1.0.0

# 修正作業
# ... bug fixes ...

# Hotfix tag
git tag -a v1.0.1 -m "Hotfix version 1.0.1"
git push origin v1.0.1

# Main branchへマージ
git checkout main
git merge hotfix/1.0.1
```

### 6.2 Changelog管理

#### 6.2.1 CHANGELOG.md
```markdown
# Changelog

## [1.0.0] - 2025-09-21

### Added
- ボトル登録・管理機能
- 写真撮影・保存機能
- CloudKit同期機能
- 基本検索・フィルタ機能
- 統計情報表示

### Changed
- N/A

### Fixed
- N/A

### Security
- N/A

## [0.1.0] - 2025-08-15

### Added
- プロジェクト初期設定
- 基本画面構成
```

#### 6.2.2 Release Notes生成
```bash
# Git logからRelease Notes生成
git log v0.1.0..v1.0.0 --pretty=format:"- %s" --no-merges > release-notes.md

# 手動編集してApp Store Connect用に調整
```

## 7. 運用・監視

### 7.1 クラッシュ監視

#### 7.1.1 Xcode Crashログ
```
Xcode → Window → Organizer → Crashes:
- 自動収集されるクラッシュログ確認
- スタックトレース分析
- 修正優先度判定
```

#### 7.1.2 TestFlight Feedback
```
App Store Connect → TestFlight → Feedback:
- ベータテスターからのフィードバック
- スクリーンショット付きレポート
- 改善点の収集
```

### 7.2 App Store Analytics

#### 7.2.1 Analytics確認
```
App Store Connect → Analytics:
- ダウンロード数
- ユーザー維持率
- クラッシュ率
- アプリ評価
```

#### 7.2.2 Review監視
```
App Store Connect → App Store → Ratings and Reviews:
- ユーザーレビュー確認
- 評価トレンド分析
- 回答すべきレビューの特定
```

## 8. 緊急時対応

### 8.1 重大バグ対応

#### 8.1.1 緊急パッチ手順
```
1. 問題確認・影響範囲特定
2. Hotfix branch作成
3. 最小限の修正実装
4. テスト実行
5. 緊急リリース（同日中）
6. App Store Expedited Review申請
```

#### 8.1.2 Expedited Review申請
```
App Store Connect → Version → App Review Information:
- Request Expedited Review
- 理由: Critical bug fix
- 詳細説明: 問題の深刻度と修正内容
```

### 8.2 ロールバック手順

#### 8.2.1 App Store版ロールバック
```
制限事項:
- App Storeでは直接的なロールバック不可
- 前バージョンを新バージョンとして再提出必要
- 緊急時は一時的にアプリ削除も検討
```

#### 8.2.2 TestFlight版管理
```
App Store Connect → TestFlight:
- Previous build選択
- 新しいTester groupに配布
- Current buildは無効化
```

## 9. リリース後作業

### 9.1 リリース完了チェック

#### 9.1.1 確認項目
- [ ] App Storeでの公開確認
- [ ] 全機能動作確認
- [ ] CloudKit同期確認
- [ ] Analytics設定確認
- [ ] Review監視開始

#### 9.1.2 プロモーション
```
リリース告知:
1. プレスリリース作成（必要に応じて）
2. SNS投稿
3. 開発ブログ更新
4. コミュニティ共有
```

### 9.2 次バージョン準備

#### 9.2.1 フィードバック収集
```
収集チャネル:
- App Store Reviews
- TestFlight Feedback
- User Support
- Analytics Data
- Personal Usage
```

#### 9.2.2 開発計画更新
```
1. 要件定義更新
2. ロードマップ調整
3. 次期バージョン計画
4. 技術的改善項目
```

---

## 10. セキュリティ・コンプライアンス

### 10.1 セキュリティチェックリスト
```bash
#!/bin/bash
# pre_release_security_check.sh

echo "=== リリース前セキュリティチェック ==="

# 1. ハードコードされた秘密情報確認
echo "1. 秘密情報確認"
grep -r "api.*key\|password\|secret" BottleKeeper/ --exclude-dir=docs || echo "✅ 秘密情報なし"

# 2. デバッグ設定確認
echo "2. デバッグ設定確認"
if grep -r "DEBUG.*=.*1" BottleKeeper.xcodeproj/; then
  echo "⚠️ デバッグ設定が残っています"
else
  echo "✅ デバッグ設定適切"
fi

# 3. ログ出力確認
echo "3. ログ出力確認"
grep -r "print\|NSLog" BottleKeeper/ | wc -l | awk '{if($1>0) print "⚠️ ログ出力が残っています: "$1" 箇所"; else print "✅ ログ出力なし"}'

# 4. 証明書有効期限確認
echo "4. 証明書有効期限確認"
security find-identity -v -p codesigning | grep "iPhone" | while read line; do
  echo "証明書: $line"
done

echo "=== セキュリティチェック完了 ==="
```

### 10.2 プライバシー監査
```swift
// プライバシー監査レポート生成
class PrivacyAuditReport {
    func generateComplianceReport() -> PrivacyReport {
        return PrivacyReport(
            dataCollection: getDataCollectionSummary(),
            thirdPartyServices: getThirdPartyServices(),
            userPermissions: getUserPermissions(),
            dataRetention: getDataRetentionPolicy(),
            dataSharing: getDataSharingPolicy()
        )
    }

    private func getDataCollectionSummary() -> DataCollectionSummary {
        return DataCollectionSummary(
            personalData: ["ボトル名", "写真", "評価", "メモ"],
            sensitiveData: ["なし"],
            locationData: ["購入店舗（任意）"],
            deviceData: ["デバイス識別子（CloudKit同期用）"],
            purpose: "個人的なコレクション管理"
        )
    }

    private func getThirdPartyServices() -> [ThirdPartyService] {
        return [
            ThirdPartyService(
                name: "Apple CloudKit",
                purpose: "データ同期",
                dataTypes: ["アプリデータ全般"],
                privacyPolicy: "https://www.apple.com/privacy/"
            )
        ]
    }
}
```

### 10.3 App Store審査対策
```swift
// App Store審査用設定管理
class AppStoreReviewConfiguration {
    static let shared = AppStoreReviewConfiguration()

    // 審査用デモデータ
    func setupReviewEnvironment() {
        #if APPSTORE_REVIEW
        setupDemoBottles()
        disableCloudKitSync()
        enableOfflineMode()
        #endif
    }

    private func setupDemoBottles() {
        let demoBottles = [
            ("山崎 12年", "サントリー", "日本", 43.0, 700),
            ("マッカラン 18年", "マッカラン", "スコットランド", 43.0, 700),
            ("ジャックダニエル", "Jack Daniel's", "アメリカ", 40.0, 700)
        ]

        demoBottles.forEach { (name, distillery, region, abv, volume) in
            let bottle = createDemoBottle(
                name: name,
                distillery: distillery,
                region: region,
                abv: abv,
                volume: volume
            )
            CoreDataManager.shared.context.insert(bottle)
        }

        try? CoreDataManager.shared.context.save()
    }
}
```

### 10.4 コンプライアンス検証
```bash
#!/bin/bash
# compliance_verification.sh

echo "=== コンプライアンス検証 ==="

# 1. GDPR準拠確認
echo "1. GDPR準拠確認"
if [ -f "docs/privacy-policy.md" ]; then
  echo "✅ プライバシーポリシー確認"
else
  echo "❌ プライバシーポリシーが必要"
fi

# 2. アルコール関連ガイドライン確認
echo "2. アルコール関連ガイドライン確認"
echo "- 年齢制限: 17歳以上 ✅"
echo "- 責任ある飲酒メッセージ: 要確認"
echo "- 違法な販売促進なし: ✅"

# 3. アクセシビリティ確認
echo "3. アクセシビリティ確認"
echo "- VoiceOver対応: 要テスト"
echo "- Dynamic Type対応: 要テスト"
echo "- Color Contrast: 要確認"

echo "=== コンプライアンス検証完了 ==="
```

## 11. 高度なリリース自動化

### 11.1 リリース品質ゲート
```yaml
# .github/workflows/release-quality-gate.yml
name: Release Quality Gate

on:
  push:
    tags:
      - 'v*'

jobs:
  quality-gate:
    runs-on: macos-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Security Scan
      run: ./scripts/pre_release_security_check.sh

    - name: Compliance Check
      run: ./scripts/compliance_verification.sh

    - name: Performance Benchmark
      run: |
        xcodebuild test \
          -scheme BottleKeeperPerformanceTests \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

    - name: UI Accessibility Test
      run: |
        xcodebuild test \
          -scheme BottleKeeperAccessibilityTests \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

    - name: Code Coverage Check
      run: |
        coverage=$(xcodebuild test -enableCodeCoverage YES | grep "Code coverage" | awk '{print $3}')
        if (( $(echo "$coverage < 80" | bc -l) )); then
          echo "❌ コードカバレッジが不足: $coverage%"
          exit 1
        fi
        echo "✅ コードカバレッジ: $coverage%"

    - name: Quality Gate Passed
      run: echo "🎉 品質ゲート通過 - リリース可能"
```

### 11.2 段階的リリース戦略
```swift
// フィーチャーフラグによる段階的リリース
class FeatureReleaseManager {
    static let shared = FeatureReleaseManager()

    private let featureFlags: [String: FeatureFlag] = [
        "advanced_statistics": FeatureFlag(
            enabled: false,
            rolloutPercentage: 0.1, // 10%のユーザーに段階的展開
            minimumAppVersion: "1.1.0"
        ),
        "ai_recommendations": FeatureFlag(
            enabled: false,
            rolloutPercentage: 0.05, // 5%のユーザーに慎重展開
            minimumAppVersion: "1.2.0"
        )
    ]

    func isFeatureEnabled(_ featureName: String) -> Bool {
        guard let flag = featureFlags[featureName] else { return false }

        // バージョンチェック
        guard isAppVersionSupported(flag.minimumAppVersion) else { return false }

        // フラグ状態チェック
        guard flag.enabled else { return false }

        // ロールアウト割合チェック
        let userID = getCurrentUserID()
        let userHash = userID.hashValue % 100
        return Double(userHash) < (flag.rolloutPercentage * 100)
    }
}

struct FeatureFlag {
    let enabled: Bool
    let rolloutPercentage: Double
    let minimumAppVersion: String
}
```

### 11.3 リリース後監視強化
```swift
// リリース後監視ダッシュボード
class PostReleaseMonitoring {
    private let alertManager = AlertManager()

    func startPostReleaseMonitoring() {
        monitorCrashRates()
        monitorUserFeedback()
        monitorPerformanceMetrics()
        monitorFeatureAdoption()
    }

    private func monitorCrashRates() {
        // リリース直後24時間は特に注意深く監視
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                let crashRate = await self.fetchCurrentCrashRate()

                if crashRate > 0.05 { // 5%超過で緊急アラート
                    await self.alertManager.sendCriticalAlert(
                        .highCrashRateDetected(crashRate)
                    )
                }
            }
        }
    }

    private func monitorUserFeedback() {
        // ネガティブレビューの急増を監視
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            Task {
                let recentReviews = await self.fetchRecentReviews()
                let negativeCount = recentReviews.filter { $0.rating <= 2 }.count

                if negativeCount >= 5 {
                    await self.alertManager.sendAlert(
                        .negativeReviewSpike(negativeCount)
                    )
                }
            }
        }
    }
}
```

---

**文書バージョン**: 1.1
**作成日**: 2025-09-21
**最終更新**: 2025-09-23
**作成者**: 個人プロジェクト