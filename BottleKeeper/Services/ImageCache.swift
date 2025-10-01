import UIKit

/// 画像のメモリキャッシュを管理するサービス
class ImageCache {
    static let shared = ImageCache()

    // フルサイズ画像用のキャッシュ
    private let fullImageCache = NSCache<NSString, UIImage>()

    // サムネイル画像用のキャッシュ
    private let thumbnailCache = NSCache<NSString, UIImage>()

    // サムネイルのサイズ（リストビューで使用）
    private let thumbnailSize = CGSize(width: 200, height: 200)

    private init() {
        // キャッシュの最大数を設定
        fullImageCache.countLimit = 20  // フルサイズは20枚まで
        thumbnailCache.countLimit = 100 // サムネイルは100枚まで

        // メモリ警告の監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - フルサイズ画像のキャッシュ操作

    /// フルサイズ画像をキャッシュから取得
    func getFullImage(forKey key: String) -> UIImage? {
        return fullImageCache.object(forKey: key as NSString)
    }

    /// フルサイズ画像をキャッシュに保存
    func setFullImage(_ image: UIImage, forKey key: String) {
        fullImageCache.setObject(image, forKey: key as NSString)
    }

    // MARK: - サムネイル画像のキャッシュ操作

    /// サムネイル画像をキャッシュから取得
    func getThumbnail(forKey key: String) -> UIImage? {
        return thumbnailCache.object(forKey: key as NSString)
    }

    /// サムネイル画像をキャッシュに保存
    func setThumbnail(_ image: UIImage, forKey key: String) {
        thumbnailCache.setObject(image, forKey: key as NSString)
    }

    /// フルサイズ画像からサムネイルを生成してキャッシュ
    func generateAndCacheThumbnail(from image: UIImage, forKey key: String) -> UIImage {
        // 既にキャッシュにある場合は返す
        if let cached = getThumbnail(forKey: key) {
            return cached
        }

        // サムネイルを生成
        let thumbnail = generateThumbnail(from: image)

        // キャッシュに保存
        setThumbnail(thumbnail, forKey: key)

        return thumbnail
    }

    // MARK: - サムネイル生成

    /// 画像からサムネイルを生成
    private func generateThumbnail(from image: UIImage) -> UIImage {
        let size = thumbnailSize
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // アスペクト比を保ちながらリサイズ
            let aspectWidth = size.width / image.size.width
            let aspectHeight = size.height / image.size.height
            let aspectRatio = min(aspectWidth, aspectHeight)

            let newSize = CGSize(
                width: image.size.width * aspectRatio,
                height: image.size.height * aspectRatio
            )

            let xOffset = (size.width - newSize.width) / 2
            let yOffset = (size.height - newSize.height) / 2

            let rect = CGRect(
                x: xOffset,
                y: yOffset,
                width: newSize.width,
                height: newSize.height
            )

            image.draw(in: rect)
        }
    }

    // MARK: - キャッシュのクリア

    /// メモリ警告時にキャッシュをクリア
    @objc private func clearCache() {
        fullImageCache.removeAllObjects()
        thumbnailCache.removeAllObjects()
    }

    /// 特定のキーのキャッシュを削除
    func removeCache(forKey key: String) {
        fullImageCache.removeObject(forKey: key as NSString)
        thumbnailCache.removeObject(forKey: key as NSString)
    }

    /// すべてのキャッシュを手動でクリア
    func clearAllCache() {
        fullImageCache.removeAllObjects()
        thumbnailCache.removeAllObjects()
    }
}
