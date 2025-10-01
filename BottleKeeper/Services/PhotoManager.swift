import Foundation
import UIKit

class PhotoManager {
    static let shared = PhotoManager()

    private init() {}

    // 写真を保存するディレクトリを取得
    private var photosDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = documentsDirectory.appendingPathComponent("BottlePhotos")

        // ディレクトリが存在しない場合は作成
        if !FileManager.default.fileExists(atPath: photosDir.path) {
            try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        }

        return photosDir
    }

    // 写真を保存
    func savePhoto(_ image: UIImage, fileName: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return false
        }

        let fileURL = photosDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("写真の保存に失敗: \(error)")
            return false
        }
    }

    // 写真を読み込み（キャッシュを使用）
    func loadPhoto(fileName: String) -> UIImage? {
        // キャッシュにある場合はキャッシュから返す
        if let cachedImage = ImageCache.shared.getFullImage(forKey: fileName) {
            return cachedImage
        }

        // ディスクから読み込み
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        guard let image = UIImage(contentsOfFile: fileURL.path) else {
            return nil
        }

        // キャッシュに保存
        ImageCache.shared.setFullImage(image, forKey: fileName)

        return image
    }

    // サムネイル画像を読み込み（リストビュー用）
    func loadThumbnail(fileName: String) -> UIImage? {
        // サムネイルキャッシュにある場合はキャッシュから返す
        if let cachedThumbnail = ImageCache.shared.getThumbnail(forKey: fileName) {
            return cachedThumbnail
        }

        // フルサイズ画像を読み込み
        guard let fullImage = loadPhoto(fileName: fileName) else {
            return nil
        }

        // サムネイルを生成してキャッシュ
        return ImageCache.shared.generateAndCacheThumbnail(from: fullImage, forKey: fileName)
    }

    // 写真を削除
    func deletePhoto(fileName: String) -> Bool {
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return false
        }

        do {
            try FileManager.default.removeItem(at: fileURL)

            // キャッシュからも削除
            ImageCache.shared.removeCache(forKey: fileName)

            return true
        } catch {
            print("写真の削除に失敗: \(error)")
            return false
        }
    }

    // ファイルサイズを取得
    func getFileSize(fileName: String) -> Int64 {
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }

        return fileSize
    }
}
