import SwiftUI
import CoreData

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("lowStockThreshold") private var lowStockThreshold = 10.0
    @AppStorage("notifyAt30Days") private var notifyAt30Days = true
    @AppStorage("notifyAt60Days") private var notifyAt60Days = true
    @AppStorage("notifyAt90Days") private var notifyAt90Days = true

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false

    var body: some View {
        List {
            authorizationStatusSection
            notificationToggleSection
            lowStockSection
            elapsedDaysSection
            debugSection
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                authorizationStatus = await NotificationManager.shared.checkAuthorizationStatus()
            }
        }
        .onChange(of: notificationsEnabled) { _, newValue in
            handleNotificationsEnabledChange(newValue)
        }
        .onChange(of: lowStockThreshold) { _, _ in
            handleSettingsChange()
        }
        .onChange(of: notifyAt30Days) { _, _ in
            handleSettingsChange()
        }
        .onChange(of: notifyAt60Days) { _, _ in
            handleSettingsChange()
        }
        .onChange(of: notifyAt90Days) { _, _ in
            handleSettingsChange()
        }
        .alert("通知権限が必要です", isPresented: $showingPermissionAlert) {
            Button("設定を開く") {
                openSettings()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("通知を受け取るには、設定アプリで通知を許可してください。")
        }
    }

    // MARK: - サブビュー

    private var authorizationStatusSection: some View {
        Section {
            HStack {
                Image(systemName: authorizationStatusIcon)
                    .foregroundColor(authorizationStatusColor)
                Text("通知の状態")
                Spacer()
                Text(authorizationStatusText)
                    .foregroundColor(.secondary)
            }

            if authorizationStatus == .denied {
                Button("設定アプリで許可") {
                    openSettings()
                }
            }
        } footer: {
            Text("通知を受け取るには、システム設定で通知を許可してください。")
        }
    }

    private var notificationToggleSection: some View {
        Section {
            Toggle("通知を有効にする", isOn: $notificationsEnabled)
                .disabled(authorizationStatus != .authorized)
        } footer: {
            Text("通知を無効にすると、すべての通知が送信されなくなります。")
        }
    }

    private var lowStockSection: some View {
        Section {
            HStack {
                Text("閾値")
                Spacer()
                Text("\(Int(lowStockThreshold))%")
                    .foregroundColor(.secondary)
            }

            Slider(value: $lowStockThreshold, in: 5...30, step: 5)
                .disabled(!notificationsEnabled || authorizationStatus != .authorized)
        } header: {
            Text("残量少なし通知")
        } footer: {
            Text("ボトルの残量がこのパーセンテージ以下になると通知されます。")
        }
    }

    private var elapsedDaysSection: some View {
        Section {
            Toggle("30日後", isOn: $notifyAt30Days)
                .disabled(!notificationsEnabled || authorizationStatus != .authorized)

            Toggle("60日後", isOn: $notifyAt60Days)
                .disabled(!notificationsEnabled || authorizationStatus != .authorized)

            Toggle("90日後", isOn: $notifyAt90Days)
                .disabled(!notificationsEnabled || authorizationStatus != .authorized)
        } header: {
            Text("開栓後経過日数通知")
        } footer: {
            Text("開栓してから指定の日数が経過すると通知されます。")
        }
    }

    @ViewBuilder
    private var debugSection: some View {
        #if DEBUG
        Section {
            Button("通知をテスト") {
                sendTestNotification()
            }

            Button("ペンディング通知を表示") {
                Task {
                    await NotificationManager.shared.printPendingNotifications()
                }
            }
        } header: {
            Text("デバッグ")
        }
        #endif
    }

    // MARK: - ヘルパーメソッド

    private func handleNotificationsEnabledChange(_ newValue: Bool) {
        if newValue {
            Task {
                await rescheduleNotifications()
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    private func handleSettingsChange() {
        Task {
            await rescheduleNotifications()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var authorizationStatusIcon: String {
        switch authorizationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle"
        case .provisional:
            return "checkmark.circle"
        case .ephemeral:
            return "checkmark.circle"
        @unknown default:
            return "questionmark.circle"
        }
    }

    private var authorizationStatusColor: Color {
        switch authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional:
            return .green
        case .ephemeral:
            return .green
        @unknown default:
            return .gray
        }
    }

    private var authorizationStatusText: String {
        switch authorizationStatus {
        case .authorized:
            return "許可済み"
        case .denied:
            return "拒否"
        case .notDetermined:
            return "未設定"
        case .provisional:
            return "仮許可"
        case .ephemeral:
            return "一時許可"
        @unknown default:
            return "不明"
        }
    }

    private func rescheduleNotifications() async {
        guard notificationsEnabled else { return }

        // 全てのボトルを取得して通知を再スケジュール
        let context = CoreDataManager.shared.container.viewContext
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()

        do {
            let bottles = try context.fetch(request)
            await NotificationManager.shared.scheduleAllNotifications(for: bottles)
        } catch {
            print("ボトルの取得に失敗: \(error)")
        }
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "テスト通知"
        content.body = "通知設定が正しく機能しています。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("テスト通知の送信に失敗: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
