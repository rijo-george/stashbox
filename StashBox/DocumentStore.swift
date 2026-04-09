import Foundation
import UIKit

class DocumentStore {
    static let shared = DocumentStore()

    private var baseDir: URL {
        let dir = AssetStore.storageDirectory().appendingPathComponent("Attachments")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var thumbnailDir: URL {
        let dir = baseDir.appendingPathComponent("thumbnails")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Save

    func saveImage(_ image: UIImage, type: DocumentType = .receipt, originalFilename: String = "photo.jpg") -> DocumentMetadata {
        let id = UUID().uuidString
        let data = image.jpegData(compressionQuality: 0.8)
        let fileURL = baseDir.appendingPathComponent("\(id).jpg")

        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordError) { url in
            try? data?.write(to: url, options: .atomic)
        }

        // Generate thumbnail
        let thumbSize: CGFloat = 200
        let scale = min(thumbSize / image.size.width, thumbSize / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let thumbData = thumbnail?.jpegData(compressionQuality: 0.7) {
            let thumbURL = thumbnailDir.appendingPathComponent("\(id)_thumb.jpg")
            coordinator.coordinate(writingItemAt: thumbURL, options: .forReplacing, error: &coordError) { url in
                try? thumbData.write(to: url, options: .atomic)
            }
        }

        return DocumentMetadata(
            id: id,
            originalFilename: originalFilename,
            type: type,
            mimeType: "image/jpeg",
            createdAt: pythonISO()
        )
    }

    // MARK: - Load

    func loadImage(for documentID: String) -> UIImage? {
        let fileURL = baseDir.appendingPathComponent("\(documentID).jpg")
        var result: UIImage?
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        coordinator.coordinate(readingItemAt: fileURL, options: [], error: &coordError) { url in
            if let data = try? Data(contentsOf: url) {
                result = UIImage(data: data)
            }
        }
        return result
    }

    func loadThumbnail(for documentID: String) -> UIImage? {
        let thumbURL = thumbnailDir.appendingPathComponent("\(documentID)_thumb.jpg")
        if let data = try? Data(contentsOf: thumbURL) {
            return UIImage(data: data)
        }
        // Fall back to full image
        return loadImage(for: documentID)
    }

    // MARK: - Delete

    func deleteDocument(_ documentID: String) {
        let fileURL = baseDir.appendingPathComponent("\(documentID).jpg")
        let thumbURL = thumbnailDir.appendingPathComponent("\(documentID)_thumb.jpg")
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: thumbURL)
    }
}
