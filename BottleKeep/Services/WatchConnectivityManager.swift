import Foundation
import WatchConnectivity

/// Apple Watchとの通信を管理するサービス
class WatchConnectivityManager: NSObject, ObservableObject {

    static let shared = WatchConnectivityManager()

    @Published var isWatchConnected = false
    @Published var isWatchAppInstalled = false
    @Published var recentTastingNotes: [WatchTastingNote] = []

    private let session = WCSession.default
    private let bottleRepository: BottleRepositoryProtocol
    private let wishlistRepository: WishlistRepositoryProtocol

    private override init() {
        self.bottleRepository = BottleRepository()
        self.wishlistRepository = WishlistRepository()
        super.init()

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Watch Communication

    /// 統計情報をWatchに送信
    func sendStatisticsToWatch() async {
        guard session.activationState == .activated && session.isWatchAppInstalled else { return }

        do {
            let bottles = try await bottleRepository.fetchAllBottles()
            let wishlistItems = try await wishlistRepository.fetchAllWishlistItems()

            let stats = WatchStatistics(
                totalBottles: bottles.count,
                openedBottles: bottles.filter { $0.openedDate != nil }.count,
                avgRating: calculateAverageRating(bottles: bottles),
                highPriorityWishlist: wishlistItems.filter { $0.priority == 3 }.count,
                recentlyAdded: bottles.filter {
                    Calendar.current.isDateInToday($0.createdAt) ||
                    Calendar.current.isDateInYesterday($0.createdAt)
                }.count
            )

            let message: [String: Any] = [
                "type": "statistics",
                "data": try stats.toDictionary()
            ]

            try session.updateApplicationContext(message)
        } catch {
            print("統計情報の送信に失敗: \(error)")
        }
    }

    /// 最近のボトル情報をWatchに送信
    func sendRecentBottlesToWatch() async {
        guard session.activationState == .activated && session.isWatchAppInstalled else { return }

        do {
            let recentBottles = try await bottleRepository.fetchAllBottles()
                .sorted { $0.updatedAt > $1.updatedAt }
                .prefix(10)

            let watchBottles = recentBottles.map { bottle in
                WatchBottle(
                    id: bottle.id.uuidString,
                    name: bottle.name,
                    distillery: bottle.distillery,
                    rating: Int(bottle.rating),
                    isOpened: bottle.openedDate != nil,
                    remainingPercentage: bottle.remainingPercentage
                )
            }

            let message: [String: Any] = [
                "type": "recentBottles",
                "bottles": try watchBottles.map { try $0.toDictionary() }
            ]

            try session.updateApplicationContext(message)
        } catch {
            print("最近のボトル情報の送信に失敗: \(error)")
        }
    }

    /// ウィッシュリスト情報をWatchに送信
    func sendWishlistToWatch() async {
        guard session.activationState == .activated && session.isWatchAppInstalled else { return }

        do {
            let highPriorityItems = try await wishlistRepository.fetchHighPriorityItems()
                .prefix(5)

            let watchWishlistItems = highPriorityItems.map { item in
                WatchWishlistItem(
                    id: item.id.uuidString,
                    name: item.name,
                    distillery: item.distillery,
                    priority: Int(item.priority),
                    estimatedPrice: item.estimatedPrice?.doubleValue
                )
            }

            let message: [String: Any] = [
                "type": "wishlist",
                "items": try watchWishlistItems.map { try $0.toDictionary() }
            ]

            try session.updateApplicationContext(message)
        } catch {
            print("ウィッシュリスト情報の送信に失敗: \(error)")
        }
    }

    /// Watchからのテイスティングノートを処理
    func processTastingNoteFromWatch(_ note: WatchTastingNote) async {
        do {
            guard let bottleId = UUID(uuidString: note.bottleId),
                  let bottle = try await bottleRepository.fetchBottle(by: bottleId) else {
                print("ボトルが見つかりません: \(note.bottleId)")
                return
            }

            // 評価を更新
            bottle.rating = Int16(note.rating)

            // ノートを追加
            let currentNotes = bottle.notes ?? ""
            let newNote = "\n[Watch] \(note.timestamp.formatted()) - Rating: \(note.rating)⭐"
            bottle.notes = currentNotes + newNote

            try await bottleRepository.saveBottle(bottle)

            await MainActor.run {
                recentTastingNotes.insert(note, at: 0)
                if recentTastingNotes.count > 20 {
                    recentTastingNotes.removeLast()
                }
            }

            // 確認メッセージを送信
            sendMessageToWatch([
                "type": "tastingNoteConfirmation",
                "bottleId": note.bottleId,
                "success": true
            ])

        } catch {
            print("テイスティングノートの処理に失敗: \(error)")

            sendMessageToWatch([
                "type": "tastingNoteConfirmation",
                "bottleId": note.bottleId,
                "success": false,
                "error": error.localizedDescription
            ])
        }
    }

    /// Watchにメッセージを送信
    func sendMessageToWatch(_ message: [String: Any]) {
        guard session.activationState == .activated && session.isReachable else { return }

        session.sendMessage(message, replyHandler: nil) { error in
            print("Watchメッセージ送信エラー: \(error)")
        }
    }

    /// Watchアプリの統計データを送信（定期実行）
    func startPeriodicSync() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // 5分間隔
            Task {
                await self.sendStatisticsToWatch()
                await self.sendRecentBottlesToWatch()
            }
        }
    }

    // MARK: - Helper Methods

    private func calculateAverageRating(bottles: [Bottle]) -> Double {
        let ratedBottles = bottles.filter { $0.rating > 0 }
        guard !ratedBottles.isEmpty else { return 0.0 }

        let totalRating = ratedBottles.reduce(0) { $0 + Int($1.rating) }
        return Double(totalRating) / Double(ratedBottles.count)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }

        if activationState == .activated {
            Task {
                await sendStatisticsToWatch()
                await sendRecentBottlesToWatch()
                await sendWishlistToWatch()
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleWatchMessage(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleWatchMessage(message)
        replyHandler(["status": "received"])
    }

    private func handleWatchMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "requestStatistics":
            Task {
                await sendStatisticsToWatch()
            }

        case "requestRecentBottles":
            Task {
                await sendRecentBottlesToWatch()
            }

        case "requestWishlist":
            Task {
                await sendWishlistToWatch()
            }

        case "tastingNote":
            if let noteData = message["data"] as? [String: Any],
               let tastingNote = WatchTastingNote.fromDictionary(noteData) {
                Task {
                    await processTastingNoteFromWatch(tastingNote)
                }
            }

        case "quickRating":
            if let bottleId = message["bottleId"] as? String,
               let rating = message["rating"] as? Int {
                Task {
                    await processQuickRating(bottleId: bottleId, rating: rating)
                }
            }

        default:
            print("未知のWatchメッセージタイプ: \(type)")
        }
    }

    private func processQuickRating(bottleId: String, rating: Int) async {
        do {
            guard let uuid = UUID(uuidString: bottleId),
                  let bottle = try await bottleRepository.fetchBottle(by: uuid) else {
                return
            }

            bottle.rating = Int16(rating)
            try await bottleRepository.saveBottle(bottle)

            sendMessageToWatch([
                "type": "quickRatingConfirmation",
                "bottleId": bottleId,
                "success": true
            ])
        } catch {
            sendMessageToWatch([
                "type": "quickRatingConfirmation",
                "bottleId": bottleId,
                "success": false,
                "error": error.localizedDescription
            ])
        }
    }
}

// MARK: - Watch Data Models

struct WatchStatistics: Codable {
    let totalBottles: Int
    let openedBottles: Int
    let avgRating: Double
    let highPriorityWishlist: Int
    let recentlyAdded: Int

    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

struct WatchBottle: Codable {
    let id: String
    let name: String
    let distillery: String
    let rating: Int
    let isOpened: Bool
    let remainingPercentage: Double

    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

struct WatchWishlistItem: Codable {
    let id: String
    let name: String
    let distillery: String
    let priority: Int
    let estimatedPrice: Double?

    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

struct WatchTastingNote: Codable {
    let bottleId: String
    let rating: Int
    let quickNote: String?
    let timestamp: Date

    static func fromDictionary(_ dict: [String: Any]) -> WatchTastingNote? {
        guard let bottleId = dict["bottleId"] as? String,
              let rating = dict["rating"] as? Int,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return nil
        }

        return WatchTastingNote(
            bottleId: bottleId,
            rating: rating,
            quickNote: dict["quickNote"] as? String,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
    }
}

// MARK: - Watch Complication Data

struct WatchComplicationData {
    let totalBottles: String
    let recentRating: String
    let todaysBottles: String
    let wishlistCount: String

    init(statistics: WatchStatistics) {
        self.totalBottles = "\(statistics.totalBottles)"
        self.recentRating = String(format: "%.1f★", statistics.avgRating)
        self.todaysBottles = "\(statistics.recentlyAdded)"
        self.wishlistCount = "\(statistics.highPriorityWishlist)"
    }
}

// MARK: - Watch Shortcuts

extension WatchConnectivityManager {

    /// Siri Shortcutsで使用するためのデータを準備
    func prepareShortcutData() async -> [String: Any] {
        do {
            let bottles = try await bottleRepository.fetchAllBottles()
            let recentBottles = bottles.sorted { $0.updatedAt > $1.updatedAt }.prefix(5)

            return [
                "recentBottles": recentBottles.map { bottle in
                    [
                        "id": bottle.id.uuidString,
                        "name": bottle.name,
                        "distillery": bottle.distillery,
                        "rating": bottle.rating
                    ]
                }
            ]
        } catch {
            return [:]
        }
    }

    /// 音声でのクイック評価
    func processVoiceRating(bottleName: String, rating: Int) async -> Bool {
        do {
            let bottles = try await bottleRepository.fetchAllBottles()
            guard let bottle = bottles.first(where: { $0.name.lowercased().contains(bottleName.lowercased()) }) else {
                return false
            }

            bottle.rating = Int16(rating)
            try await bottleRepository.saveBottle(bottle)
            return true
        } catch {
            return false
        }
    }
}