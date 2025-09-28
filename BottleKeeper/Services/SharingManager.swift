import SwiftUI
import UIKit

/// コレクションやウィッシュリストの共有を管理するサービス
class SharingManager: ObservableObject {

    static let shared = SharingManager()

    private let bottleRepository: BottleRepositoryProtocol
    private let wishlistRepository: WishlistRepositoryProtocol

    private init() {
        self.bottleRepository = BottleRepository()
        self.wishlistRepository = WishlistRepository()
    }

    // MARK: - Collection Sharing

    /// コレクション全体を共有用テキストとして生成
    func generateCollectionShareText() async throws -> String {
        let bottles = try await bottleRepository.fetchAllBottles()
        let totalValue = bottles.compactMap { $0.purchasePrice?.decimalValue }.reduce(Decimal(0), +)
        let averageRating = bottles.filter { $0.rating > 0 }.map { Double($0.rating) }.reduce(0, +) / Double(bottles.filter { $0.rating > 0 }.count)

        var shareText = "🥃 My Whiskey Collection - BottleKeep\n\n"
        shareText += "📊 Collection Stats:\n"
        shareText += "• Total Bottles: \(bottles.count)\n"
        shareText += "• Collection Value: \(formatCurrency(totalValue))\n"
        shareText += "• Average Rating: \(String(format: "%.1f", averageRating))/5\n\n"

        shareText += "🏆 Top Rated Bottles:\n"
        let topRated = bottles.filter { $0.rating >= 4 }.sorted { $0.rating > $1.rating }.prefix(5)
        for bottle in topRated {
            shareText += "• \(bottle.name) (\(bottle.distillery)) - \(bottle.rating)⭐\n"
        }

        shareText += "\n📱 Shared via BottleKeep App"
        return shareText
    }

    /// 特定のボトルを共有用テキストとして生成
    func generateBottleShareText(bottle: Bottle) -> String {
        var shareText = "🥃 \(bottle.name)\n"
        shareText += "🏭 Distillery: \(bottle.distillery)\n"

        if let region = bottle.region, !region.isEmpty {
            shareText += "🌍 Region: \(region)\n"
        }

        if let type = bottle.type, !type.isEmpty {
            shareText += "🏷️ Type: \(type)\n"
        }

        if bottle.vintage > 0 {
            shareText += "📅 Vintage: \(bottle.vintage)\n"
        }

        if bottle.abv > 0 {
            shareText += "🌡️ ABV: \(String(format: "%.1f", bottle.abv))%\n"
        }

        if bottle.rating > 0 {
            shareText += "⭐ Rating: \(bottle.rating)/5\n"
        }

        if let notes = bottle.notes, !notes.isEmpty {
            shareText += "📝 Notes: \(notes)\n"
        }

        shareText += "\n📱 Shared via BottleKeep App"
        return shareText
    }

    /// ウィッシュリストを共有用テキストとして生成
    func generateWishlistShareText() async throws -> String {
        let wishlistItems = try await wishlistRepository.fetchAllWishlistItems()
        let highPriority = wishlistItems.filter { $0.priority == 3 }
        let mediumPriority = wishlistItems.filter { $0.priority == 2 }
        let lowPriority = wishlistItems.filter { $0.priority == 1 }

        var shareText = "🎯 My Whiskey Wishlist - BottleKeep\n\n"
        shareText += "📊 Wishlist Stats:\n"
        shareText += "• Total Items: \(wishlistItems.count)\n"
        shareText += "• High Priority: \(highPriority.count)\n"
        shareText += "• Medium Priority: \(mediumPriority.count)\n"
        shareText += "• Low Priority: \(lowPriority.count)\n\n"

        if !highPriority.isEmpty {
            shareText += "🔥 High Priority:\n"
            for item in highPriority.prefix(5) {
                shareText += "• \(item.name) (\(item.distillery))"
                if let price = item.estimatedPrice, price.doubleValue > 0 {
                    shareText += " - \(formatCurrency(price.decimalValue))"
                }
                shareText += "\n"
            }
            shareText += "\n"
        }

        if !mediumPriority.isEmpty {
            shareText += "📝 Medium Priority:\n"
            for item in mediumPriority.prefix(3) {
                shareText += "• \(item.name) (\(item.distillery))\n"
            }
            shareText += "\n"
        }

        shareText += "📱 Shared via BottleKeep App"
        return shareText
    }

    // MARK: - Visual Sharing

    /// コレクション統計のビジュアルを生成
    func generateCollectionImage() async throws -> UIImage {
        let bottles = try await bottleRepository.fetchAllBottles()
        let openedCount = bottles.filter { $0.openedDate != nil }.count
        let totalValue = bottles.compactMap { $0.purchasePrice?.decimalValue }.reduce(Decimal(0), +)

        return try await createCollectionStatsImage(
            totalBottles: bottles.count,
            openedBottles: openedCount,
            totalValue: totalValue
        )
    }

    /// ボトル情報のビジュアルを生成
    func generateBottleImage(bottle: Bottle) async throws -> UIImage {
        return try await createBottleCardImage(bottle: bottle)
    }

    // MARK: - Social Media Sharing

    /// インスタグラムストーリー形式でシェア
    func shareToInstagramStories(image: UIImage, text: String) {
        guard let instagramURL = URL(string: "instagram-stories://share"),
              UIApplication.shared.canOpenURL(instagramURL) else {
            // Instagramアプリがインストールされていない場合の処理
            shareToGeneralSocial(items: [image, text])
            return
        }

        // Instagram Stories用のデータを準備
        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.stickerImage": image.pngData() as Any,
            "com.instagram.sharedSticker.backgroundTopColor": "#1A1A1A",
            "com.instagram.sharedSticker.backgroundBottomColor": "#8B4513"
        ]

        UIPasteboard.general.setItems([pasteboardItems])
        UIApplication.shared.open(instagramURL)
    }

    /// Twitter形式でシェア
    func shareToTwitter(text: String) {
        let tweetText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let twitterURL = URL(string: "twitter://post?message=\(tweetText)")
        let webTwitterURL = URL(string: "https://twitter.com/intent/tweet?text=\(tweetText)")

        if let url = twitterURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let webURL = webTwitterURL {
            UIApplication.shared.open(webURL)
        }
    }

    /// 一般的なシェア（UIActivityViewController）
    func shareToGeneralSocial(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // iPadでの表示調整
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = rootViewController.view
            popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                                 y: rootViewController.view.bounds.midY,
                                                 width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        rootViewController.present(activityViewController, animated: true)
    }

    // MARK: - Import from Share

    /// 共有されたデータからボトル情報を抽出
    func parseSharedBottleText(_ text: String) -> BottleShareData? {
        let lines = text.components(separatedBy: .newlines)
        var bottleData = BottleShareData()

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.starts(with: "🥃 ") {
                bottleData.name = String(trimmedLine.dropFirst(3))
            } else if trimmedLine.starts(with: "🏭 Distillery: ") {
                bottleData.distillery = String(trimmedLine.dropFirst(15))
            } else if trimmedLine.starts(with: "🌍 Region: ") {
                bottleData.region = String(trimmedLine.dropFirst(11))
            } else if trimmedLine.starts(with: "🏷️ Type: ") {
                bottleData.type = String(trimmedLine.dropFirst(9))
            } else if trimmedLine.starts(with: "📅 Vintage: ") {
                if let vintage = Int(String(trimmedLine.dropFirst(12))) {
                    bottleData.vintage = vintage
                }
            } else if trimmedLine.starts(with: "🌡️ ABV: ") {
                let abvString = String(trimmedLine.dropFirst(8)).replacingOccurrences(of: "%", with: "")
                bottleData.abv = Double(abvString)
            } else if trimmedLine.starts(with: "⭐ Rating: ") {
                let ratingString = String(trimmedLine.dropFirst(11)).components(separatedBy: "/").first ?? ""
                bottleData.rating = Int(ratingString)
            } else if trimmedLine.starts(with: "📝 Notes: ") {
                bottleData.notes = String(trimmedLine.dropFirst(10))
            }
        }

        return bottleData.isValid ? bottleData : nil
    }

    // MARK: - Private Methods

    private func createCollectionStatsImage(totalBottles: Int, openedBottles: Int, totalValue: Decimal) async throws -> UIImage {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // 背景
            UIColor.systemBackground.setFill()
            context.fill(rect)

            // タイトル
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.label
            ]

            let title = "🥃 My Collection"
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: (size.width - titleSize.width) / 2, y: 50, width: titleSize.width, height: titleSize.height)
            title.draw(in: titleRect, withAttributes: titleAttributes)

            // 統計情報
            let statsFont = UIFont.systemFont(ofSize: 18, weight: .medium)
            let statsAttributes: [NSAttributedString.Key: Any] = [
                .font: statsFont,
                .foregroundColor: UIColor.label
            ]

            let stats = [
                "Total Bottles: \(totalBottles)",
                "Opened: \(openedBottles)",
                "Value: \(formatCurrency(totalValue))"
            ]

            var yOffset: CGFloat = 150
            for stat in stats {
                let statSize = stat.size(withAttributes: statsAttributes)
                let statRect = CGRect(x: (size.width - statSize.width) / 2, y: yOffset, width: statSize.width, height: statSize.height)
                stat.draw(in: statRect, withAttributes: statsAttributes)
                yOffset += 40
            }

            // フッター
            let footerFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.secondaryLabel
            ]

            let footer = "Created with BottleKeep"
            let footerSize = footer.size(withAttributes: footerAttributes)
            let footerRect = CGRect(x: (size.width - footerSize.width) / 2, y: size.height - 50, width: footerSize.width, height: footerSize.height)
            footer.draw(in: footerRect, withAttributes: footerAttributes)
        }
    }

    private func createBottleCardImage(bottle: Bottle) async throws -> UIImage {
        let size = CGSize(width: 350, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // 背景
            UIColor.systemBackground.setFill()
            context.fill(rect)

            // 角丸の背景
            let cardRect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 20)
            UIColor.secondarySystemBackground.setFill()
            path.fill()

            // ボトル名
            let nameFont = UIFont.systemFont(ofSize: 20, weight: .bold)
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: nameFont,
                .foregroundColor: UIColor.label
            ]

            let nameRect = CGRect(x: 40, y: 60, width: cardRect.width - 40, height: 30)
            bottle.name.draw(in: nameRect, withAttributes: nameAttributes)

            // 蒸留所
            let distilleryFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            let distilleryAttributes: [NSAttributedString.Key: Any] = [
                .font: distilleryFont,
                .foregroundColor: UIColor.secondaryLabel
            ]

            let distilleryRect = CGRect(x: 40, y: 100, width: cardRect.width - 40, height: 25)
            bottle.distillery.draw(in: distilleryRect, withAttributes: distilleryAttributes)

            // 評価
            if bottle.rating > 0 {
                let ratingText = "Rating: \(bottle.rating)⭐"
                let ratingRect = CGRect(x: 40, y: 140, width: cardRect.width - 40, height: 25)
                ratingText.draw(in: ratingRect, withAttributes: distilleryAttributes)
            }
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: NSNumber(value: amount.doubleValue)) ?? "¥0"
    }
}

// MARK: - Supporting Types

struct BottleShareData {
    var name: String = ""
    var distillery: String = ""
    var region: String?
    var type: String?
    var vintage: Int?
    var abv: Double?
    var rating: Int?
    var notes: String?

    var isValid: Bool {
        return !name.isEmpty && !distillery.isEmpty
    }
}

// MARK: - SwiftUI Integration

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View Extensions

extension View {
    /// ボトル共有シートを表示
    func shareBottle(_ bottle: Bottle, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            ShareSheet(activityItems: [SharingManager.shared.generateBottleShareText(bottle: bottle)])
        }
    }

    /// コレクション共有シートを表示
    func shareCollection(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            ShareSheetForCollection()
        }
    }
}

struct ShareSheetForCollection: View {
    @State private var shareText = ""
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("共有データを準備中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ShareSheet(activityItems: [shareText])
            }
        }
        .task {
            do {
                shareText = try await SharingManager.shared.generateCollectionShareText()
                isLoading = false
            } catch {
                shareText = "コレクションの共有データを準備できませんでした"
                isLoading = false
            }
        }
    }
}