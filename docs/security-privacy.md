# BottleKeep セキュリティ・プライバシー要件

## 1. 概要

### 1.1 目的
BottleKeepアプリのセキュリティとプライバシー保護要件を定義し、ユーザーデータの安全性を確保する。App Store審査と法的要件に準拠した実装ガイドラインを提供する。

### 1.2 基本方針
- **プライバシー・バイ・デザイン**: 設計段階からプライバシー保護を組み込み
- **最小データ収集**: 必要最小限のデータのみ収集
- **透明性**: データ利用について明確に説明
- **ユーザー制御**: ユーザーが自身のデータをコントロール可能

### 1.3 適用法令・ガイドライン
- Apple App Store Review Guidelines
- iOS Human Interface Guidelines (Privacy)
- 個人情報保護法（日本）
- GDPR（EU、該当する場合）

## 2. データ分類と保護レベル

### 2.1 データ分類

#### 2.1.1 個人データ（高保護レベル）
```swift
enum PersonalDataType {
    case userProfile        // ユーザープロフィール情報
    case deviceIdentifiers  // デバイス固有ID
    case locationData      // 位置情報（将来実装時）
    case purchaseHistory   // 購入履歴データ
}
```

**取り扱い方針**:
- ローカル保存のみ（外部送信禁止）
- 暗号化必須
- アクセス制御実装

#### 2.1.2 コレクションデータ（中保護レベル）
```swift
enum CollectionDataType {
    case bottleInformation  // ボトル情報
    case tastingNotes      // テイスティングノート
    case ratings          // 評価データ
    case photos           // 写真データ
    case consumptionLogs  // 消費履歴
}
```

**取り扱い方針**:
- iCloud同期可能
- ユーザー同意後のみ同期
- 適切なアクセス制御

#### 2.1.3 アプリケーションデータ（低保護レベル）
```swift
enum AppDataType {
    case appSettings      // アプリ設定
    case userPreferences  // ユーザー設定
    case cacheData       // キャッシュデータ
    case analyticsData   // 使用統計（匿名化済み）
}
```

**取り扱い方針**:
- 一般的なセキュリティ対策
- 必要に応じて外部送信可能

### 2.2 データ保護実装

#### 2.2.1 Core Data暗号化
```swift
// Core Data暗号化設定
class SecureCoreDataStack {
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "BottleKeep")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }

        // ファイル保護レベル設定
        description.setOption(FileProtectionType.complete as NSString,
                            forKey: NSPersistentStoreFileProtectionKey)

        // SQLite暗号化（iOS標準）
        description.setOption(true as NSNumber,
                            forKey: NSPersistentStoreFileProtectionKey)

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }

        return container
    }()
}
```

#### 2.2.2 Keychain利用
```swift
import Security

class SecureStorage {
    private let service = "com.yourcompany.bottlekeep"

    func store(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // 既存項目の更新
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]

            let updateData: [String: Any] = [
                kSecValueData as String: data
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateData as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.updateFailed
            }
        } else if status != errSecSuccess {
            throw KeychainError.storeFailed
        }
    }

    func retrieve(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed
        }

        return result as? Data
    }
}

enum KeychainError: Error {
    case storeFailed
    case updateFailed
    case retrieveFailed
}
```

## 3. 認証・アクセス制御

### 3.1 生体認証実装

#### 3.1.1 Face ID / Touch ID
```swift
import LocalAuthentication

class BiometricAuthManager {
    private let context = LAContext()

    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var biometricType: LABiometryType {
        return context.biometryType
    }

    func authenticateUser(reason: String) async throws -> Bool {
        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }
}

// 使用例
class AppAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    private let biometricAuth = BiometricAuthManager()

    func authenticateIfNeeded() async {
        guard UserDefaults.standard.bool(forKey: "biometric_auth_enabled") else {
            isAuthenticated = true
            return
        }

        do {
            let success = try await biometricAuth.authenticateUser(
                reason: "ボトルコレクションにアクセスするため認証が必要です"
            )
            DispatchQueue.main.async {
                self.isAuthenticated = success
            }
        } catch {
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        }
    }
}
```

### 3.2 アプリレベルアクセス制御

#### 3.2.1 画面保護
```swift
class ScreenProtectionManager: ObservableObject {
    @Published var isAppInBackground = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        isAppInBackground = true
    }

    @objc private func appWillEnterForeground() {
        // 認証が必要な場合はここで処理
        isAppInBackground = false
    }
}

// SwiftUIでの使用
struct ContentView: View {
    @StateObject private var screenProtection = ScreenProtectionManager()
    @StateObject private var authManager = AppAuthManager()

    var body: some View {
        Group {
            if screenProtection.isAppInBackground {
                PrivacyScreenView()
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .task {
            await authManager.authenticateIfNeeded()
        }
    }
}
```

## 4. ネットワークセキュリティ

### 4.1 HTTPS通信の確保

#### 4.1.1 App Transport Security設定
```xml
<!-- Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <!-- 必要に応じて例外ドメイン設定 -->
    </dict>
</dict>
```

#### 4.1.2 証明書ピニング（必要に応じて）
```swift
class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.defaultHandling, nil)
            return
        }

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.defaultHandling, nil)
            return
        }

        // 証明書検証ロジック
        let policy = SecPolicyCreateSSL(true, "your-api-domain.com" as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        var result: SecTrustResultType = .invalid
        let status = SecTrustEvaluate(serverTrust, &result)

        if status == errSecSuccess && (result == .unspecified || result == .proceed) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.defaultHandling, nil)
        }
    }
}
```

### 4.2 API認証情報保護

#### 4.2.1 API キー管理
```swift
// APIキーの安全な管理
class APIKeyManager {
    static let shared = APIKeyManager()
    private let secureStorage = SecureStorage()

    private init() {}

    func getAPIKey(for service: APIService) -> String? {
        // Keychainから取得
        guard let data = try? secureStorage.retrieve(key: service.rawValue),
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        return apiKey
    }

    func setAPIKey(_ key: String, for service: APIService) throws {
        let data = key.data(using: .utf8)!
        try secureStorage.store(key: service.rawValue, data: data)
    }
}

enum APIService: String {
    case amazon = "amazon_api_key"
    case rakuten = "rakuten_api_key"
}
```

## 5. プライバシー設定とユーザー制御

### 5.1 プライバシー設定画面

#### 5.1.1 設定項目
```swift
struct PrivacySettings {
    var iCloudSyncEnabled: Bool = false
    var analyticsEnabled: Bool = false
    var crashReportingEnabled: Bool = true
    var biometricAuthEnabled: Bool = false
    var photoAccessLevel: PhotoAccessLevel = .selectedPhotos

    enum PhotoAccessLevel: CaseIterable {
        case none
        case selectedPhotos
        case limitedLibrary
        case fullLibrary

        var displayName: String {
            switch self {
            case .none: return "アクセスしない"
            case .selectedPhotos: return "選択した写真のみ"
            case .limitedLibrary: return "制限付きライブラリ"
            case .fullLibrary: return "フルアクセス"
            }
        }
    }
}

class PrivacySettingsManager: ObservableObject {
    @Published var settings = PrivacySettings()

    init() {
        loadSettings()
    }

    private func loadSettings() {
        // UserDefaultsから設定を読み込み
        settings.iCloudSyncEnabled = UserDefaults.standard.bool(forKey: "icloud_sync_enabled")
        settings.analyticsEnabled = UserDefaults.standard.bool(forKey: "analytics_enabled")
        settings.crashReportingEnabled = UserDefaults.standard.bool(forKey: "crash_reporting_enabled")
        settings.biometricAuthEnabled = UserDefaults.standard.bool(forKey: "biometric_auth_enabled")
    }

    func updateSettings() {
        // UserDefaultsに設定を保存
        UserDefaults.standard.set(settings.iCloudSyncEnabled, forKey: "icloud_sync_enabled")
        UserDefaults.standard.set(settings.analyticsEnabled, forKey: "analytics_enabled")
        UserDefaults.standard.set(settings.crashReportingEnabled, forKey: "crash_reporting_enabled")
        UserDefaults.standard.set(settings.biometricAuthEnabled, forKey: "biometric_auth_enabled")
    }
}
```

#### 5.1.2 プライバシー設定UI
```swift
struct PrivacySettingsView: View {
    @StateObject private var settingsManager = PrivacySettingsManager()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("データ同期")) {
                    Toggle("iCloud同期", isOn: $settingsManager.settings.iCloudSyncEnabled)
                        .onChange(of: settingsManager.settings.iCloudSyncEnabled) { _ in
                            settingsManager.updateSettings()
                        }

                    if settingsManager.settings.iCloudSyncEnabled {
                        Text("ボトル情報がiCloudで同期されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("セキュリティ")) {
                    Toggle("生体認証", isOn: $settingsManager.settings.biometricAuthEnabled)
                        .onChange(of: settingsManager.settings.biometricAuthEnabled) { _ in
                            settingsManager.updateSettings()
                        }
                }

                Section(header: Text("データ利用")) {
                    Toggle("使用状況分析", isOn: $settingsManager.settings.analyticsEnabled)
                        .onChange(of: settingsManager.settings.analyticsEnabled) { _ in
                            settingsManager.updateSettings()
                        }

                    Toggle("クラッシュレポート", isOn: $settingsManager.settings.crashReportingEnabled)
                        .onChange(of: settingsManager.settings.crashReportingEnabled) { _ in
                            settingsManager.updateSettings()
                        }
                }

                Section(header: Text("データの削除")) {
                    Button("すべてのデータを削除") {
                        // データ削除処理
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("プライバシー設定")
        }
    }
}
```

### 5.2 データエクスポート・削除

#### 5.2.1 データエクスポート
```swift
class DataExportManager {
    func exportUserData() async throws -> URL {
        let exportData = UserDataExport()

        // ボトルデータ
        let bottles = try await BottleRepository().fetchAllBottles()
        exportData.bottles = bottles.map { BottleExportData(from: $0) }

        // 写真データ（ファイルパスのみ）
        exportData.photos = bottles.flatMap { bottle in
            bottle.photoArray.map { PhotoExportData(from: $0) }
        }

        // 設定データ
        exportData.settings = SettingsExportData()

        let jsonData = try JSONEncoder().encode(exportData)

        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first!
        let exportURL = documentsPath.appendingPathComponent("bottlekeep_export_\(Date().timeIntervalSince1970).json")

        try jsonData.write(to: exportURL)

        return exportURL
    }
}

struct UserDataExport: Codable {
    var bottles: [BottleExportData] = []
    var photos: [PhotoExportData] = []
    var settings: SettingsExportData = SettingsExportData()
    let exportDate = Date()
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
}
```

#### 5.2.2 完全データ削除
```swift
class DataDeletionManager {
    func deleteAllUserData() throws {
        // Core Dataの全データ削除
        let context = CoreDataStack.shared.context

        let bottleRequest: NSFetchRequest<NSFetchRequestResult> = Bottle.fetchRequest()
        let bottleDeleteRequest = NSBatchDeleteRequest(fetchRequest: bottleRequest)
        try context.execute(bottleDeleteRequest)

        let photoRequest: NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()
        let photoDeleteRequest = NSBatchDeleteRequest(fetchRequest: photoRequest)
        try context.execute(photoDeleteRequest)

        // 写真ファイルの削除
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first!
        let photosPath = documentsPath.appendingPathComponent("Photos")

        if FileManager.default.fileExists(atPath: photosPath.path) {
            try FileManager.default.removeItem(at: photosPath)
        }

        // UserDefaultsのクリア
        let appDomain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: appDomain)

        // Keychainのクリア
        try clearKeychain()

        try context.save()
    }

    private func clearKeychain() throws {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]

        for secItemClass in secItemClasses {
            let dictionary = [kSecClass as String: secItemClass]
            SecItemDelete(dictionary as CFDictionary)
        }
    }
}
```

## 6. App Store プライバシー要件

### 6.1 Privacy Nutrition Labels

#### 6.1.1 データ収集の申告
```
収集するデータ:
- 連絡先情報: なし
- 健康とフィットネス: なし
- 財務情報: なし
- 位置: なし
- 機密情報: なし
- 連絡先: なし
- ユーザーコンテンツ: あり（ボトル情報、写真、評価）
- 閲覧履歴: なし
- 検索履歴: なし
- 識別子: なし
- 購入: あり（購入価格、店舗情報）
- 使用状況データ: あり（アプリ使用統計）
- 診断: あり（クラッシュデータ）
- その他のデータ: なし

データの用途:
- アプリの機能: あり
- 分析: あり（匿名化済み）
- 開発者の広告または販促: なし
- 第三者の広告または販促: なし
- その他: なし

第三者との共有:
- なし（すべてローカル保存またはiCloud）
```

#### 6.1.2 プライバシーポリシー
```markdown
# BottleKeep プライバシーポリシー

## データの収集について
BottleKeepは以下のデータを収集します：

### 必須データ
- ボトル情報（銘柄、蒸留所、価格等）
- 写真（ユーザーが追加したボトル写真）
- 評価とノート（ユーザーが入力したテイスティング情報）

### オプションデータ
- アプリ使用統計（匿名化）
- クラッシュレポート（問題解決のため）

## データの利用について
収集したデータは以下の目的で利用します：
- アプリ機能の提供
- ユーザー体験の向上
- 技術的問題の解決

## データの共有について
ユーザーのデータを第三者と共有することはありません。

## データの保存について
- ローカル端末での暗号化保存
- iCloud同期（ユーザーが有効化した場合のみ）

## ユーザーの権利
- データの確認・修正・削除の権利
- 設定画面からの制御
- 完全なデータ削除オプション

## 連絡先
プライバシーに関するお問い合わせ: privacy@bottlekeep.app
```

### 6.2 App Store申請用チェックリスト

#### 6.2.1 プライバシー関連
- [ ] プライバシーポリシーの公開
- [ ] Privacy Nutrition Labelsの正確な申告
- [ ] データ収集の最小化
- [ ] ユーザー同意の適切な取得
- [ ] 子供の個人情報保護

#### 6.2.2 セキュリティ関連
- [ ] データの暗号化
- [ ] 適切な認証実装
- [ ] HTTPS通信の確保
- [ ] 脆弱性テストの実施

## 7. 法的コンプライアンス

### 7.1 個人情報保護法対応

#### 7.1.1 適用要件
- 個人情報の適正な取得
- 利用目的の明示
- 第三者提供の制限
- 安全管理措置

#### 7.1.2 対応実装
```swift
class ComplianceManager {
    func checkConsentRequired() -> Bool {
        // ユーザーの同意が必要かチェック
        return !UserDefaults.standard.bool(forKey: "privacy_consent_given")
    }

    func recordConsent(for purposes: [ConsentPurpose]) {
        let consentRecord = ConsentRecord(
            purposes: purposes,
            timestamp: Date(),
            version: "1.0"
        )

        // 同意記録の保存
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(consentRecord) {
            UserDefaults.standard.set(data, forKey: "consent_record")
        }

        UserDefaults.standard.set(true, forKey: "privacy_consent_given")
    }
}

struct ConsentRecord: Codable {
    let purposes: [ConsentPurpose]
    let timestamp: Date
    let version: String
}

enum ConsentPurpose: String, Codable, CaseIterable {
    case appFunctionality = "アプリ機能の提供"
    case icloudSync = "iCloud同期"
    case analytics = "使用状況分析"
    case crashReporting = "クラッシュレポート"
}
```

## 8. セキュリティ監査とテスト

### 8.1 セキュリティテスト項目

#### 8.1.1 データ保護テスト
- [ ] Core Dataファイルの暗号化確認
- [ ] Keychainデータの適切な保護
- [ ] アプリバックアップ時のデータ保護
- [ ] メモリダンプでの機密情報漏洩チェック

#### 8.1.2 認証テスト
- [ ] 生体認証の正常動作
- [ ] 認証失敗時の適切な処理
- [ ] バックグラウンド時の画面保護
- [ ] アプリ終了時のデータ保護

#### 8.1.3 ネットワークテスト
- [ ] HTTPS通信の確認
- [ ] 証明書検証の動作
- [ ] 中間者攻撃への耐性
- [ ] データ送信時の暗号化

### 8.2 脆弱性対策

#### 8.2.1 一般的な脆弱性対策
```swift
// SQLインジェクション対策（Core Data使用により自動対策）
// XSS対策（WebView未使用により対象外）
// CSRF対策（Webアプリ機能なしにより対象外）

// 不正なファイルアクセス対策
class SecureFileManager {
    private let baseDirectory: URL

    init() {
        baseDirectory = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask).first!
    }

    func secureWriteFile(data: Data, filename: String) throws {
        // ファイル名の検証
        guard isValidFilename(filename) else {
            throw SecurityError.invalidFilename
        }

        let fileURL = baseDirectory.appendingPathComponent(filename)

        // パストラバーサル攻撃対策
        guard fileURL.path.hasPrefix(baseDirectory.path) else {
            throw SecurityError.pathTraversalAttempt
        }

        try data.write(to: fileURL)
    }

    private func isValidFilename(_ filename: String) -> Bool {
        // 危険な文字をチェック
        let dangerousChars = CharacterSet(charactersIn: "../\\")
        return filename.rangeOfCharacter(from: dangerousChars) == nil
    }
}

enum SecurityError: Error {
    case invalidFilename
    case pathTraversalAttempt
}
```

---

## 付録: セキュリティ実装チェックリスト

### A.1 実装前チェック
- [ ] プライバシー要件の理解
- [ ] 法的要件の確認
- [ ] セキュリティ設計の策定

### A.2 実装中チェック
- [ ] データ暗号化の実装
- [ ] 認証機能の実装
- [ ] プライバシー設定の実装
- [ ] セキュリティテストの実施

### A.3 App Store申請前チェック
- [ ] プライバシーポリシーの準備
- [ ] Privacy Nutrition Labelsの申告
- [ ] セキュリティ監査の実施
- [ ] 脆弱性テストの完了

---

**文書バージョン**: 1.0
**作成日**: 2025-09-23
**最終更新**: 2025-09-23
**作成者**: Claude Code

このセキュリティ・プライバシー要件により、安全で信頼できるアプリを構築できます。