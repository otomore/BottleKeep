import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    @State private var tempOpeningDays: Double = 30

    var body: some View {
        NavigationStack {
            List {
                // 通知許可セクション
                permissionSection

                if notificationManager.isNotificationPermissionGranted {
                    // 開栓リマインダー
                    openingRemindersSection

                    // 購入リマインダー
                    purchaseRemindersSection

                    // ウィッシュリスト通知
                    wishlistSection

                    // コレクション管理
                    collectionSection

                    // マナーモード設定
                    quietHoursSection
                }
            }
            .navigationTitle("通知設定")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                tempOpeningDays = Double(notificationManager.notificationSettings.openingReminderDays)
            }
            .alert("通知許可が必要です", isPresented: $showingPermissionAlert) {
                Button("設定を開く") {
                    openAppSettings()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("BottleKeepからの通知を受け取るには、設定アプリで通知を有効にしてください。")
            }
        }
    }

    @ViewBuilder
    private var permissionSection: some View {
        Section {
            HStack {
                Image(systemName: notificationManager.isNotificationPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(notificationManager.isNotificationPermissionGranted ? .green : .red)

                VStack(alignment: .leading, spacing: 4) {
                    Text("通知許可")
                        .font(.headline)
                    Text(notificationManager.isNotificationPermissionGranted ? "許可済み" : "未許可")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !notificationManager.isNotificationPermissionGranted {
                    Button("許可") {
                        Task {
                            let granted = await notificationManager.requestNotificationPermission()
                            if !granted {
                                showingPermissionAlert = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } header: {
            Text("通知許可")
        } footer: {
            Text("リマインダーや重要な通知を受け取るには通知の許可が必要です。")
        }
    }

    @ViewBuilder
    private var openingRemindersSection: some View {
        Section {
            Toggle("開栓リマインダー", isOn: Binding(
                get: { notificationManager.notificationSettings.openingReminders },
                set: { newValue in
                    var settings = notificationManager.notificationSettings
                    settings.openingReminders = newValue
                    notificationManager.updateNotificationSettings(settings)
                }
            ))

            if notificationManager.notificationSettings.openingReminders {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("通知タイミング")
                        Spacer()
                        Text("\(Int(tempOpeningDays))日後")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $tempOpeningDays, in: 7...90, step: 1) {
                        Text("日数")
                    } minimumValueLabel: {
                        Text("7")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("90")
                            .font(.caption)
                    } onEditingChanged: { editing in
                        if !editing {
                            var settings = notificationManager.notificationSettings
                            settings.openingReminderDays = Int(tempOpeningDays)
                            notificationManager.updateNotificationSettings(settings)
                        }
                    }
                }
            }
        } header: {
            Text("開栓リマインダー")
        } footer: {
            Text("購入したボトルの開栓を促すリマインダーです。")
        }
    }

    @ViewBuilder
    private var purchaseRemindersSection: some View {
        Section {
            Toggle("購入リマインダー", isOn: Binding(
                get: { notificationManager.notificationSettings.purchaseReminders },
                set: { newValue in
                    var settings = notificationManager.notificationSettings
                    settings.purchaseReminders = newValue
                    notificationManager.updateNotificationSettings(settings)
                }
            ))
        } header: {
            Text("購入リマインダー")
        } footer: {
            Text("ウィッシュリストの高優先度アイテムの購入を促すリマインダーです。")
        }
    }

    @ViewBuilder
    private var wishlistSection: some View {
        Section {
            Toggle("ウィッシュリスト通知", isOn: Binding(
                get: { notificationManager.notificationSettings.wishlistNotifications },
                set: { newValue in
                    var settings = notificationManager.notificationSettings
                    settings.wishlistNotifications = newValue
                    notificationManager.updateNotificationSettings(settings)
                }
            ))
        } header: {
            Text("ウィッシュリスト")
        } footer: {
            Text("毎週金曜日にウィッシュリストの確認をお知らせします。")
        }
    }

    @ViewBuilder
    private var collectionSection: some View {
        Section {
            Toggle("コレクション管理リマインダー", isOn: Binding(
                get: { notificationManager.notificationSettings.collectionReminders },
                set: { newValue in
                    var settings = notificationManager.notificationSettings
                    settings.collectionReminders = newValue
                    notificationManager.updateNotificationSettings(settings)
                }
            ))
        } header: {
            Text("コレクション管理")
        } footer: {
            Text("毎月1日にコレクションの整理をお知らせします。")
        }
    }

    @ViewBuilder
    private var quietHoursSection: some View {
        Section {
            Toggle("マナーモード", isOn: Binding(
                get: { notificationManager.notificationSettings.quietHoursEnabled },
                set: { newValue in
                    var settings = notificationManager.notificationSettings
                    settings.quietHoursEnabled = newValue
                    notificationManager.updateNotificationSettings(settings)
                }
            ))

            if notificationManager.notificationSettings.quietHoursEnabled {
                DatePicker(
                    "開始時刻",
                    selection: Binding(
                        get: { notificationManager.notificationSettings.quietHoursStart },
                        set: { newValue in
                            var settings = notificationManager.notificationSettings
                            settings.quietHoursStart = newValue
                            notificationManager.updateNotificationSettings(settings)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )

                DatePicker(
                    "終了時刻",
                    selection: Binding(
                        get: { notificationManager.notificationSettings.quietHoursEnd },
                        set: { newValue in
                            var settings = notificationManager.notificationSettings
                            settings.quietHoursEnd = newValue
                            notificationManager.updateNotificationSettings(settings)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("マナーモード")
        } footer: {
            Text("指定した時間帯は通知を送信しません。")
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

#Preview {
    NotificationSettingsView()
}