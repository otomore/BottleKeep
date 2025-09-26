import Foundation
import UIKit
import os.log

/// 写真の保存・読み込み・削除を管理するクラス
class PhotoManager {

    static let shared = PhotoManager()

    private let logger = Logger(subsystem: "com.bottlekeep.app", category: "PhotoManager")

    // MARK: - Directory Management

    /// 写真保存用のディレクトリを取得
    private var photosDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask)[0]
        let photosPath = documentsPath.appendingPathComponent("Photos")

        // ディレクトリが存在しない場合は作成
        if !FileManager.default.fileExists(atPath: photosPath.path) {
            do {
                try FileManager.default.createDirectory(at: photosPath,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
                logger.info("Photos directory created at: \(photosPath.path)")
            } catch {
                logger.error("Failed to create photos directory: \(error)")
            }
        }

        return photosPath
    }

    // MARK: - Save Operations

    /// 写真を保存し、ファイル名を返す
    func savePhoto(_ image: UIImage, for bottleId: UUID) async throws -> String {
        let fileName = "\(bottleId.uuidString)_\(Date().timeIntervalSince1970).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        // 画像を適切なサイズにリサイズ
        let resizedImage = await resizeImage(image, to: CGSize(width: 1024, height: 1024))

        // JPEG形式で圧縮（80%品質）
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw PhotoError.imageCompressionFailed
        }

        do {
            try imageData.write(to: fileURL)
            logger.info("Photo saved: \(fileName)")
            return fileName
        } catch {
            logger.error("Failed to save photo: \(error)")
            throw PhotoError.saveFailed
        }
    }

    /// 複数の写真を一括保存
    func savePhotos(_ images: [UIImage], for bottleId: UUID) async throws -> [String] {
        var fileNames: [String] = []

        for image in images {
            let fileName = try await savePhoto(image, for: bottleId)
            fileNames.append(fileName)
        }

        return fileNames
    }

    // MARK: - Load Operations

    /// ファイル名から写真を読み込み
    func loadPhoto(fileName: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.warning("Photo file not found: \(fileName)")
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    /// 写真を非同期で読み込み
    func loadPhotoAsync(fileName: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = self.loadPhoto(fileName: fileName)
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Delete Operations

    /// 写真ファイルを削除
    func deletePhoto(fileName: String) {
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(at: fileURL)
            logger.info("Photo deleted: \(fileName)")
        } catch {
            logger.error("Failed to delete photo: \(fileName), error: \(error)")
        }
    }

    /// 複数の写真を一括削除
    func deletePhotos(fileNames: [String]) {
        for fileName in fileNames {
            deletePhoto(fileName: fileName)
        }
    }

    // MARK: - Image Processing

    /// 画像をリサイズ
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: targetSize)
                let resizedImage = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: targetSize))
                }
                continuation.resume(returning: resizedImage)
            }
        }
    }

    /// 画像を正方形にクロップ
    func cropToSquare(_ image: UIImage) -> UIImage {
        let originalSize = image.size
        let cropSize = min(originalSize.width, originalSize.height)

        let cropX = (originalSize.width - cropSize) / 2
        let cropY = (originalSize.height - cropSize) / 2

        let cropRect = CGRect(x: cropX, y: cropY, width: cropSize, height: cropSize)

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Storage Management

    /// 写真保存用ディスクサイズを取得
    func getTotalPhotoStorageSize() -> Int64 {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: photosDirectory,
                                                                  includingPropertiesForKeys: [.fileSizeKey],
                                                                  options: [])
            var totalSize: Int64 = 0

            for file in files {
                let fileAttributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(fileAttributes.fileSize ?? 0)
            }

            return totalSize
        } catch {
            logger.error("Failed to calculate storage size: \(error)")
            return 0
        }
    }

    /// 古い写真ファイルをクリーンアップ（30日以上経過）
    func cleanupOldPhotos() async {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)

        do {
            let files = try FileManager.default.contentsOfDirectory(at: photosDirectory,
                                                                  includingPropertiesForKeys: [.creationDateKey],
                                                                  options: [])

            for file in files {
                let fileAttributes = try file.resourceValues(forKeys: [.creationDateKey])
                if let creationDate = fileAttributes.creationDate,
                   creationDate < thirtyDaysAgo {
                    try FileManager.default.removeItem(at: file)
                    logger.info("Cleaned up old photo: \(file.lastPathComponent)")
                }
            }
        } catch {
            logger.error("Failed to cleanup old photos: \(error)")
        }
    }

    // MARK: - Initialization

    private init() {
        // 写真ディレクトリの初期化
        _ = photosDirectory
    }
}

// MARK: - PhotoError

enum PhotoError: LocalizedError {
    case imageCompressionFailed
    case saveFailed
    case loadFailed
    case deleteFailed
    case invalidFileName

    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "画像の圧縮に失敗しました"
        case .saveFailed:
            return "写真の保存に失敗しました"
        case .loadFailed:
            return "写真の読み込みに失敗しました"
        case .deleteFailed:
            return "写真の削除に失敗しました"
        case .invalidFileName:
            return "無効なファイル名です"
        }
    }
}