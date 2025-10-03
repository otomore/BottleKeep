import CoreData
import Foundation
import CloudKit

// MARK: - Constants

private enum CoreDataConstants {
    static let containerName = "BottleKeeper"
    static let cloudKitContainerIdentifier = "iCloud.com.bottlekeep.whiskey"
    static let maxLogCount = 100
    static let previewSampleCount = 5

    enum UserDefaultsKeys {
        static let cloudKitSchemaInitialized = "cloudKitSchemaInitialized"
        static let cloudKitSchemaInitializedDate = "cloudKitSchemaInitializedDate"
    }

    enum EntityNames {
        static let bottle = "Bottle"
        static let wishlistItem = "WishlistItem"
    }
}

// MARK: - CloudKit Logger

/// CloudKit同期のログを管理する構造体
struct CloudKitLogger {
    private(set) var logs: [String] = []
    private let maxLogs: Int

    init(maxLogs: Int = CoreDataConstants.maxLogCount) {
        self.maxLogs = maxLogs
    }

    mutating func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        logs.insert(logMessage, at: 0)
        if logs.count > maxLogs {
            logs.removeLast()
        }
        print(logMessage)
    }

    mutating func clearLogs() {
        logs.removeAll()
    }
}

// MARK: - Core Data Manager

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    static let preview: CoreDataManager = {
        let manager = CoreDataManager(inMemory: true)
        let viewContext = manager.container.viewContext

        // プレビュー用のサンプルデータを作成
        for i in 0..<CoreDataConstants.previewSampleCount {
            guard let newBottle = NSEntityDescription.insertNewObject(
                forEntityName: CoreDataConstants.EntityNames.bottle,
                into: viewContext
            ) as? NSManagedObject else {
                print("⚠️ Failed to create preview bottle object")
                continue
            }

            newBottle.setValue(UUID(), forKey: "id")
            newBottle.setValue("サンプルウイスキー \(i + 1)", forKey: "name")
            newBottle.setValue("サンプル蒸留所", forKey: "distillery")
            newBottle.setValue(40.0 + Double(i), forKey: "abv")
            newBottle.setValue(700, forKey: "volume")
            newBottle.setValue(Int32(700 - (i * 100)), forKey: "remainingVolume")
            newBottle.setValue(Date(), forKey: "purchaseDate")
            newBottle.setValue(Date(), forKey: "createdAt")
            newBottle.setValue(Date(), forKey: "updatedAt")
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("⚠️ Preview data save error: \(nsError), \(nsError.userInfo)")
        }
        return manager
    }()

    let container: NSPersistentCloudKitContainer
    private var iCloudAvailable = false
    private var logger = CloudKitLogger()

    // ログをPublishedプロパティとして公開
    @Published private(set) var logs: [String] = []

    private func log(_ message: String) {
        logger.log(message)
        DispatchQueue.main.async { [weak self] in
            self?.logs = self?.logger.logs ?? []
        }
    }

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: CoreDataConstants.containerName)

        if inMemory {
            // インメモリストアの設定（プレビューとテスト用）
            if let description = container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        } else {
            // iCloudアカウント状態を確認
            checkiCloudAccountStatus()

            // CloudKit同期の設定
            configureCloudKitSync()
        }

        // Persistent Storeをロード
        loadPersistentStores()

        // ViewContextの設定
        configureViewContext()

        // CloudKit同期イベントを監視
        if !inMemory {
            setupCloudKitNotifications()
        }
    }

    /// CloudKit同期の設定を行う
    private func configureCloudKitSync() {
        guard let description = container.persistentStoreDescriptions.first else {
            log("⚠️ No persistent store description found")
            return
        }

        // CloudKitコンテナIDを明示的に設定
        let options = NSPersistentCloudKitContainerOptions(
            containerIdentifier: CoreDataConstants.cloudKitContainerIdentifier
        )
        description.cloudKitContainerOptions = options
        log("CloudKit Container ID: \(CoreDataConstants.cloudKitContainerIdentifier)")

        // 履歴トラッキングを有効化（CloudKit同期に必要）
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        // リモート変更通知を有効化
        description.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )
    }

    /// Persistent Storeをロード
    private func loadPersistentStores() {
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                self?.log("❌ Core Data load error: \(error.localizedDescription)")
                self?.log("Error domain: \(error.domain)")
                self?.log("Error code: \(error.code)")
                self?.log("Working with local storage only")
                // エラーが発生してもアプリは続行（クラッシュさせない）
            } else {
                self?.log("✅ Core Data loaded successfully")
                self?.log("Store URL: \(storeDescription.url?.absoluteString ?? "unknown")")
                let cloudKitStatus = storeDescription.cloudKitContainerOptions != nil ? "Enabled" : "Disabled"
                self?.log("CloudKit options: \(cloudKitStatus)")
            }
        }
    }

    /// ViewContextの設定
    private func configureViewContext() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// iCloudアカウント状態を確認
    private func checkiCloudAccountStatus() {
        let container = CKContainer(identifier: CoreDataConstants.cloudKitContainerIdentifier)
        container.accountStatus { [weak self] status, error in
            guard let self = self else { return }

            if let error = error {
                self.log("❌ iCloud account check error: \(error.localizedDescription)")
                self.iCloudAvailable = false
                return
            }

            let statusMessage = self.accountStatusMessage(for: status)
            self.log(statusMessage)
            self.iCloudAvailable = (status == .available)
        }
    }

    /// アカウントステータスに応じたメッセージを返す
    private func accountStatusMessage(for status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "✅ iCloud account is available"
        case .noAccount:
            return "⚠️ No iCloud account configured"
        case .restricted:
            return "⚠️ iCloud account is restricted"
        case .couldNotDetermine:
            return "⚠️ Could not determine iCloud account status"
        case .temporarilyUnavailable:
            return "⚠️ iCloud account is temporarily unavailable"
        @unknown default:
            return "⚠️ Unknown iCloud account status"
        }
    }

    /// CloudKit同期イベントの監視を設定
    private func setupCloudKitNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container
        )
    }

    @objc private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            log("⚠️ Could not extract CloudKit event from notification")
            return
        }

        log("📡 CloudKit Event: \(eventTypeDescription(event.type))")
        log("Event start date: \(event.startDate)")
        if let endDate = event.endDate {
            log("Event end date: \(endDate)")
        }

        if let error = event.error {
            let nsError = error as NSError
            log("❌ CloudKit sync error: \(error.localizedDescription)")
            log("Error domain: \(nsError.domain)")
            log("Error code: \(nsError.code)")

            // CKErrorの詳細情報
            if nsError.domain == CKError.errorDomain {
                logCKErrorDetails(nsError)
            }

            // 重大なエラーの場合は追加情報をログ
            if nsError.code == CKError.quotaExceeded.rawValue {
                log("⚠️ iCloud storage quota exceeded")
            } else if nsError.code == CKError.networkFailure.rawValue {
                log("⚠️ Network connection issue")
            } else if nsError.code == CKError.notAuthenticated.rawValue {
                log("⚠️ User is not authenticated with iCloud")
            } else if nsError.code == CKError.networkUnavailable.rawValue {
                log("⚠️ Network is unavailable")
            }
        } else {
            log("✅ \(eventTypeDescription(event.type)) completed successfully")
        }
    }

    /// CKErrorの詳細情報をログに出力
    private func logCKErrorDetails(_ error: NSError) {
        // Partial Errorsをチェック
        if let partialErrors = error.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error] {
            log("Partial errors count: \(partialErrors.count)")
            for (key, partialError) in partialErrors {
                log("  Item [\(key)]: \((partialError as NSError).localizedDescription)")
            }
        }

        // Underlying Errorをチェック
        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            log("Underlying error: \(underlyingError.localizedDescription)")
            log("Underlying error domain: \(underlyingError.domain)")
            log("Underlying error code: \(underlyingError.code)")
        }

        // Retry After情報をチェック
        if let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? NSNumber {
            log("Retry after: \(retryAfter) seconds")
        }
    }

    /// イベントタイプの説明を返す
    private func eventTypeDescription(_ type: NSPersistentCloudKitContainer.EventType) -> String {
        switch type {
        case .setup:
            return "CloudKit setup"
        case .import:
            return "CloudKit import"
        case .export:
            return "CloudKit export"
        @unknown default:
            return "Unknown CloudKit event"
        }
    }
}

// MARK: - Public Interface

extension CoreDataManager {
    /// iCloud同期が利用可能かどうか
    var isCloudSyncAvailable: Bool {
        return iCloudAvailable
    }

    /// CloudKitスキーマが初期化済みかどうか
    var isCloudKitSchemaInitialized: Bool {
        return UserDefaults.standard.bool(forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized)
    }

    /// CloudKitスキーマの初期化日時
    var cloudKitSchemaInitializedDate: Date? {
        return UserDefaults.standard.object(
            forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate
        ) as? Date
    }

    /// CloudKitスキーマを初期化（初回セットアップ時のみ実行）
    func initializeCloudKitSchema() throws {
        log("🔄 Initializing CloudKit schema...")

        guard isCloudSyncAvailable else {
            let error = NSError(
                domain: "CoreDataManager",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "iCloud is not available"]
            )
            log("❌ Cannot initialize schema: iCloud not available")
            throw error
        }

        // Production環境では initializeCloudKitSchema() は使用できない
        // Development環境でのみ動作する
        #if DEBUG
        log("ℹ️ Running in DEBUG mode - attempting schema initialization")
        #else
        log("⚠️ Running in RELEASE mode - schema should be deployed via CloudKit Dashboard")
        log("ℹ️ For Production environment, schema initialization is not supported")
        log("ℹ️ Schema will be created automatically when data is first synced")

        // Production環境では自動的にスキーマが作成されるため、初期化済みとマーク
        UserDefaults.standard.set(
            true,
            forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized
        )
        UserDefaults.standard.set(
            Date(),
            forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate
        )

        log("✅ Schema initialization skipped for Production environment")
        log("💡 Data will sync automatically when you add or modify records")
        return
        #endif

        do {
            try container.initializeCloudKitSchema(options: [])
            log("✅ CloudKit schema initialized successfully")

            UserDefaults.standard.set(
                true,
                forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitialized
            )
            UserDefaults.standard.set(
                Date(),
                forKey: CoreDataConstants.UserDefaultsKeys.cloudKitSchemaInitializedDate
            )
        } catch let error as NSError {
            log("❌ Failed to initialize CloudKit schema")
            log("Error domain: \(error.domain)")
            log("Error code: \(error.code)")
            log("Error description: \(error.localizedDescription)")

            // CKErrorの詳細情報を取得
            if error.domain == "CKErrorDomain" {
                log("CloudKit error code: \(error.code)")

                if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                    log("Underlying error: \(underlyingError.localizedDescription)")
                    log("Underlying error domain: \(underlyingError.domain)")
                    log("Underlying error code: \(underlyingError.code)")
                }

                if let partialErrors = error.userInfo["CKPartialErrors"] as? [AnyHashable: Error] {
                    log("Partial errors found: \(partialErrors.count)")
                    for (key, partialError) in partialErrors {
                        log("Partial error [\(key)]: \(partialError.localizedDescription)")
                    }
                }
            }

            throw error
        }
    }

    /// ログをクリア
    func clearLogs() {
        logger.clearLogs()
        logs = []
        log("🗑️ Logs cleared")
    }

    /// CloudKit同期の診断情報を取得
    func diagnosticCloudKitStatus() -> String {
        var status = "=== CloudKit診断情報 ===\n"
        status += "iCloud利用可能: \(iCloudAvailable ? "はい" : "いいえ")\n"
        status += "スキーマ初期化済み: \(isCloudKitSchemaInitialized ? "はい" : "いいえ")\n"

        if let date = cloudKitSchemaInitializedDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            status += "スキーマ初期化日時: \(formatter.string(from: date))\n"
        }

        // Store Descriptionの情報
        if let description = container.persistentStoreDescriptions.first {
            status += "\nストア情報:\n"
            status += "URL: \(description.url?.lastPathComponent ?? "不明")\n"
            status += "CloudKit有効: \(description.cloudKitContainerOptions != nil ? "はい" : "いいえ")\n"
            if let options = description.cloudKitContainerOptions {
                status += "コンテナID: \(options.containerIdentifier)\n"
            }
        }

        status += "\n最新のログ（5件）:\n"
        for log in logs.prefix(5) {
            status += "\(log)\n"
        }

        log(status)
        return status
    }

    /// iCloudアカウント状態を再確認
    func recheckiCloudStatus() {
        checkiCloudAccountStatus()
    }
}

// MARK: - Core Data Operations

extension CoreDataManager {
    /// コンテキストの変更を保存
    func save() {
        let context = container.viewContext

        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
            log("💾 Core Data saved successfully")
            if iCloudAvailable {
                log("☁️ iCloud sync will begin automatically")
            }
        } catch {
            let nsError = error as NSError
            log("❌ Core Data save error: \(nsError.localizedDescription)")
            log("Error code: \(nsError.code), Domain: \(nsError.domain)")
            // エラーが発生してもアプリは続行（クラッシュさせない）
            // ユーザーデータの損失を防ぐため、次回の保存を試みる
        }
    }

    /// オブジェクトを削除して保存
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        log("🗑️ Deleted object: \(object.entity.name ?? "Unknown")")
        save()
    }

    /// 複数のオブジェクトをバッチ削除
    func batchDelete(_ objects: [NSManagedObject]) {
        guard !objects.isEmpty else { return }

        let context = container.viewContext
        objects.forEach { context.delete($0) }

        log("🗑️ Batch deleted \(objects.count) objects")
        save()
    }
}