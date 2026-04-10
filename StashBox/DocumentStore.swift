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

    // MARK: - Save File (PDF, etc.)

    func saveFile(from sourceURL: URL, type: DocumentType = .other) -> DocumentMetadata? {
        let id = UUID().uuidString
        let ext = sourceURL.pathExtension.lowercased()
        let destURL = baseDir.appendingPathComponent("\(id).\(ext)")

        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        var success = false

        // Access security-scoped resource for files from document picker
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessing { sourceURL.stopAccessingSecurityScopedResource() } }

        coordinator.coordinate(writingItemAt: destURL, options: .forReplacing, error: &coordError) { url in
            do {
                try FileManager.default.copyItem(at: sourceURL, to: url)
                success = true
            } catch {}
        }

        guard success else { return nil }

        let mimeType: String
        switch ext {
        case "pdf": mimeType = "application/pdf"
        case "png": mimeType = "image/png"
        case "jpg", "jpeg": mimeType = "image/jpeg"
        case "heic": mimeType = "image/heic"
        default: mimeType = "application/octet-stream"
        }

        return DocumentMetadata(
            id: id,
            originalFilename: sourceURL.lastPathComponent,
            type: type,
            mimeType: mimeType,
            createdAt: pythonISO()
        )
    }

    // MARK: - Load File URL

    func fileURL(for documentID: String) -> URL? {
        let fm = FileManager.default
        // Check common extensions
        for ext in ["jpg", "jpeg", "png", "pdf", "heic"] {
            let url = baseDir.appendingPathComponent("\(documentID).\(ext)")
            if fm.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    // MARK: - Load

    func loadImage(for documentID: String) -> UIImage? {
        guard let url = fileURL(for: documentID) else { return nil }
        var result: UIImage?
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordError) { readURL in
            if let data = try? Data(contentsOf: readURL) {
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
        if let url = fileURL(for: documentID) {
            try? FileManager.default.removeItem(at: url)
        }
        let thumbURL = thumbnailDir.appendingPathComponent("\(documentID)_thumb.jpg")
        try? FileManager.default.removeItem(at: thumbURL)
    }
}
