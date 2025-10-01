import SwiftUI
import CoreData

@main
struct BottleKeeperApp: App {
    let persistenceController = CoreDataManager.shared
    @State private var hasRequestedNotificationPermission = false

    init() {
        // 通知マネージャーの初期化
        _ = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // 初回起動時のみ通知権限をリクエスト
                    if !hasRequestedNotificationPermission {
                        Task {
                            do {
                                let granted = try await NotificationManager.shared.requestAuthorization()
                                if granted {
                                    print("通知権限が許可されました")
                                    await scheduleNotifications()
                                } else {
                                    print("通知権限が拒否されました")
                                }
                            } catch {
                                print("通知権限のリクエストに失敗: \(error)")
                            }
                            hasRequestedNotificationPermission = true
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // フォアグラウンドに戻ったときに通知を更新
                    Task {
                        await scheduleNotifications()
                    }
                }
        }
    }

    private func scheduleNotifications() async {
        // 全てのボトルを取得して通知をスケジュール
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Bottle> = Bottle.fetchRequest()

        do {
            let bottles = try context.fetch(request)
            await NotificationManager.shared.scheduleAllNotifications(for: bottles)
        } catch {
            print("ボトルの取得に失敗: \(error)")
        }
    }
}