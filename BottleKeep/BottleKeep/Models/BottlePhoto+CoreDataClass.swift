import Foundation
import CoreData
import UIKit

@objc(BottlePhoto)
public class BottlePhoto: NSManagedObject {

    // MARK: - Computed Properties

    /// ファイル名からUIImageを取得
    var image: UIImage? {
        guard !fileName.isEmpty else { return nil }
        return PhotoManager.shared.loadPhoto(fileName: fileName)
    }

    /// メイン写真かどうかの判定
    var isMainPhoto: Bool {
        get { isMain }
        set { isMain = newValue }
    }

    // MARK: - Validation

    func validate() throws {
        guard !fileName.isEmpty else {
            throw PhotoValidationError.emptyFileName
        }

        guard fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg") || fileName.hasSuffix(".png") else {
            throw PhotoValidationError.invalidFileExtension
        }
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.createdAt = Date()
        self.isMain = false
    }
}

// MARK: - Photo Validation Error

enum PhotoValidationError: LocalizedError {
    case emptyFileName
    case invalidFileExtension
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .emptyFileName:
            return "ファイル名が設定されていません"
        case .invalidFileExtension:
            return "サポートされていないファイル形式です（jpg、jpeg、png のみ）"
        case .fileNotFound:
            return "写真ファイルが見つかりません"
        }
    }
}