import Foundation
import UserNotifications
import UIKit

/// 通知を管理するサービス
class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published var isNotificationPermissionGranted = false
    @Published var notificationSettings: NotificationSettings

    private let userNotificationCenter = UNUserNotificationCenter.current()
    private let bottleRepository: BottleRepositoryProtocol
    private let wishlistRepository: WishlistRepositoryProtocol

    override init() {
        self.notificationSettings = NotificationSettings.loadFromUserDefaults()
        self.bottleRepository = BottleRepository()
        self.wishlistRepository = WishlistRepository()
        super.init()

        userNotificationCenter.delegate = self
        Task {
            await checkNotificationPermission()
        }
    }

    // MARK: - Permission Management

    /// 通知許可をリクエスト
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await userNotificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )

            await MainActor.run {
                isNotificationPermissionGranted = granted
            }

            if granted {
                await registerForRemoteNotifications()
                await scheduleAllNotifications()
            }

            return granted
        } catch {
            print("通知許可リクエストに失敗: \(error)")
            return false
        }
    }

    /// 通知許可状態を確認
    func checkNotificationPermission() async {
        let settings = await userNotificationCenter.notificationSettings()

        await MainActor.run {
            isNotificationPermissionGranted = settings.authorizationStatus == .authorized ||
                                            settings.authorizationStatus == .provisional
        }
    }

    /// リモート通知に登録
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Notification Scheduling

    /// 全ての通知をスケジュール
    func scheduleAllNotifications() async {
        await cancelAllNotifications()

        if notificationSettings.openingReminders {
            await scheduleOpeningReminders()
        }

        if notificationSettings.purchaseReminders {
            await schedulePurchaseReminders()
        }

        if notificationSettings.wishlistNotifications {
            await scheduleWishlistNotifications()
        }

        if notificationSettings.collectionReminders {
            await scheduleCollectionReminders()
        }
    }

    /// 開栓リマインダーをスケジュール
    private func scheduleOpeningReminders() async {
        do {
            let unopenedBottles = try await bottleRepository.fetchUnopenedBottles()

            for bottle in unopenedBottles {
                // 購入から一定期間経過したボトルに通知を設定
                if let purchaseDate = bottle.purchaseDate,
                   let reminderDate = Calendar.current.date(byAdding: .day,
                                                         value: notificationSettings.openingReminderDays,
                                                         to: purchaseDate),
                   reminderDate > Date() {

                    let content = UNMutableNotificationContent()
                    content.title = "開栓のお誘い"
                    content.body = "\(bottle.name) はいかがですか？購入から\(notificationSettings.openingReminderDays)日が経過しました。"
                    content.sound = .default
                    content.userInfo = [
                        "type": "opening_reminder",
                        "bottleId": bottle.id.uuidString
                    ]

                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                                     from: reminderDate),
                        repeats: false
                    )

                    let request = UNNotificationRequest(
                        identifier: "opening_\(bottle.id.uuidString)",
                        content: content,
                        trigger: trigger
                    )

                    try await userNotificationCenter.add(request)
                }
            }
        } catch {
            print("開栓リマインダーのスケジュールに失敗: \(error)")
        }
    }

    /// 購入リマインダーをスケジュール
    private func schedulePurchaseReminders() async {
        do {
            let highPriorityWishlistItems = try await wishlistRepository.fetchHighPriorityItems()

            for item in highPriorityWishlistItems {
                // 高優先度アイテムの購入リマインダー
                let reminderDate = Calendar.current.date(byAdding: .weekOfYear,
                                                       value: 2,
                                                       to: Date()) ?? Date()

                let content = UNMutableNotificationContent()
                content.title = "購入検討のリマインダー"
                content.body = "高優先度の\(item.name)の購入を検討してみませんか？"
                content.sound = .default
                content.userInfo = [
                    "type": "purchase_reminder",
                    "wishlistItemId": item.id.uuidString
                ]

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                                 from: reminderDate),
                    repeats: false
                )

                let request = UNNotificationRequest(
                    identifier: "purchase_\(item.id.uuidString)",
                    content: content,
                    trigger: trigger
                )

                try await userNotificationCenter.add(request)
            }
        } catch {
            print("購入リマインダーのスケジュールに失敗: \(error)")
        }
    }

    /// ウィッシュリスト通知をスケジュール
    private func scheduleWishlistNotifications() async {
        // 毎週金曜日にウィッシュリストの確認通知
        let content = UNMutableNotificationContent()
        content.title = "ウィッシュリストの確認"
        content.body = "今週気になったボトルはありませんか？ウィッシュリストを更新してみましょう。"
        content.sound = .default
        content.userInfo = ["type": "wishlist_check"]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: 19, minute: 0, weekday: 6), // 金曜日 19:00
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "wishlist_weekly_check",
            content: content,
            trigger: trigger
        )

        do {
            try await userNotificationCenter.add(request)
        } catch {
            print("ウィッシュリスト通知のスケジュールに失敗: \(error)")
        }
    }

    /// コレクション管理リマインダーをスケジュール
    private func scheduleCollectionReminders() async {
        // 月次のコレクション整理リマインダー
        let content = UNMutableNotificationContent()
        content.title = "コレクションの整理"
        content.body = "今月のテイスティングはいかがでしたか？評価を記録してコレクションを整理しましょう。"
        content.sound = .default
        content.userInfo = ["type": "collection_maintenance"]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(day: 1, hour: 10, minute: 0), // 毎月1日 10:00
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "collection_monthly_maintenance",
            content: content,
            trigger: trigger
        )

        do {
            try await userNotificationCenter.add(request)
        } catch {
            print("コレクション管理リマインダーのスケジュールに失敗: \(error)")
        }
    }

    /// カスタム通知をスケジュール
    func scheduleCustomNotification(title: String, body: String, date: Date, identifier: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["type": "custom", "customId": identifier]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await userNotificationCenter.add(request)
    }

    /// 全ての通知をキャンセル
    func cancelAllNotifications() async {
        userNotificationCenter.removeAllPendingNotificationRequests()
    }

    /// 特定の通知をキャンセル
    func cancelNotification(identifier: String) {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// ペンディング中の通知を取得
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await userNotificationCenter.pendingNotificationRequests()
    }

    /// 配信済みの通知を取得
    func getDeliveredNotifications() async -> [UNNotification] {
        return await userNotificationCenter.deliveredNotifications()
    }

    // MARK: - Settings Management

    /// 通知設定を更新
    func updateNotificationSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        settings.saveToUserDefaults()

        Task {
            await scheduleAllNotifications()
        }
    }

    /// 通知設定をリセット
    func resetNotificationSettings() {
        let defaultSettings = NotificationSettings()
        updateNotificationSettings(defaultSettings)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// 通知がフォアグラウンドで受信された時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    /// 通知がタップされた時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        Task {
            await handleNotificationResponse(userInfo: userInfo)
            completionHandler()
        }
    }

    private func handleNotificationResponse(userInfo: [AnyHashable: Any]) async {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "opening_reminder":
            if let bottleId = userInfo["bottleId"] as? String,
               let uuid = UUID(uuidString: bottleId) {
                // ボトル詳細画面に遷移
                await navigateToBottleDetail(bottleId: uuid)
            }

        case "purchase_reminder":
            if let itemId = userInfo["wishlistItemId"] as? String,
               let uuid = UUID(uuidString: itemId) {
                // ウィッシュリストアイテム詳細に遷移
                await navigateToWishlistItem(itemId: uuid)
            }

        case "wishlist_check":
            // ウィッシュリスト画面に遷移
            await navigateToWishlist()

        case "collection_maintenance":
            // 統計画面に遷移
            await navigateToStatistics()

        case "custom":
            // カスタム通知の処理
            break

        default:
            break
        }
    }

    private func navigateToBottleDetail(bottleId: UUID) async {
        // 実際のナビゲーション実装はアプリの構造により異なる
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToBottleDetail,
                object: nil,
                userInfo: ["bottleId": bottleId]
            )
        }
    }

    private func navigateToWishlistItem(itemId: UUID) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToWishlistItem,
                object: nil,
                userInfo: ["itemId": itemId]
            )
        }
    }

    private func navigateToWishlist() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .navigateToWishlist, object: nil)
        }
    }

    private func navigateToStatistics() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .navigateToStatistics, object: nil)
        }
    }
}

// MARK: - Supporting Types

struct NotificationSettings {
    var openingReminders: Bool = true
    var openingReminderDays: Int = 30
    var purchaseReminders: Bool = true
    var wishlistNotifications: Bool = true
    var collectionReminders: Bool = true
    var customNotifications: Bool = true
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

    // MARK: - UserDefaults Integration

    static func loadFromUserDefaults() -> NotificationSettings {
        let defaults = UserDefaults.standard
        var settings = NotificationSettings()

        settings.openingReminders = defaults.bool(forKey: "notif_opening_reminders")
        settings.openingReminderDays = defaults.integer(forKey: "notif_opening_days") == 0 ? 30 : defaults.integer(forKey: "notif_opening_days")
        settings.purchaseReminders = defaults.bool(forKey: "notif_purchase_reminders")
        settings.wishlistNotifications = defaults.bool(forKey: "notif_wishlist_notifications")
        settings.collectionReminders = defaults.bool(forKey: "notif_collection_reminders")
        settings.customNotifications = defaults.bool(forKey: "notif_custom_notifications")
        settings.quietHoursEnabled = defaults.bool(forKey: "notif_quiet_hours_enabled")

        if let quietStart = defaults.object(forKey: "notif_quiet_start") as? Date {
            settings.quietHoursStart = quietStart
        }
        if let quietEnd = defaults.object(forKey: "notif_quiet_end") as? Date {
            settings.quietHoursEnd = quietEnd
        }

        return settings
    }

    func saveToUserDefaults() {
        let defaults = UserDefaults.standard

        defaults.set(openingReminders, forKey: "notif_opening_reminders")
        defaults.set(openingReminderDays, forKey: "notif_opening_days")
        defaults.set(purchaseReminders, forKey: "notif_purchase_reminders")
        defaults.set(wishlistNotifications, forKey: "notif_wishlist_notifications")
        defaults.set(collectionReminders, forKey: "notif_collection_reminders")
        defaults.set(customNotifications, forKey: "notif_custom_notifications")
        defaults.set(quietHoursEnabled, forKey: "notif_quiet_hours_enabled")
        defaults.set(quietHoursStart, forKey: "notif_quiet_start")
        defaults.set(quietHoursEnd, forKey: "notif_quiet_end")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToBottleDetail = Notification.Name("navigateToBottleDetail")
    static let navigateToWishlistItem = Notification.Name("navigateToWishlistItem")
    static let navigateToWishlist = Notification.Name("navigateToWishlist")
    static let navigateToStatistics = Notification.Name("navigateToStatistics")
}