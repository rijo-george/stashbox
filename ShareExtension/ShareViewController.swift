import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        handleSharedItems()
    }

    private func handleSharedItems() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        let group = DispatchGroup()
        var savedFiles: [String] = []

        for item in items {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier) { data, _ in
                        if let url = data as? URL, let imageData = try? Data(contentsOf: url),
                           let _ = UIImage(data: imageData) {
                            if let path = self.saveToAppGroup(data: imageData, ext: "jpg") {
                                savedFiles.append(path)
                            }
                        } else if let image = data as? UIImage,
                                  let jpegData = image.jpegData(compressionQuality: 0.8) {
                            if let path = self.saveToAppGroup(data: jpegData, ext: "jpg") {
                                savedFiles.append(path)
                            }
                        }
                        group.leave()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) { data, _ in
                        if let url = data as? URL, let pdfData = try? Data(contentsOf: url) {
                            if let path = self.saveToAppGroup(data: pdfData, ext: "pdf") {
                                savedFiles.append(path)
                            }
                        }
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            // Write a pending file list for the main app to pick up
            if !savedFiles.isEmpty {
                self.writePendingList(savedFiles)
            }
            self.showConfirmation(count: savedFiles.count)
        }
    }

    private func saveToAppGroup(data: Data, ext: String) -> String? {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.rijo.stashbox"
        ) else { return nil }

        let pendingDir = groupURL.appendingPathComponent("Pending")
        try? FileManager.default.createDirectory(at: pendingDir, withIntermediateDirectories: true)

        let filename = UUID().uuidString + "." + ext
        let fileURL = pendingDir.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    private func writePendingList(_ files: [String]) {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.rijo.stashbox"
        ) else { return }

        let listURL = groupURL.appendingPathComponent("pending_imports.json")
        let existing: [String] = {
            guard let data = try? Data(contentsOf: listURL),
                  let list = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return list
        }()

        let combined = existing + files
        if let data = try? JSONEncoder().encode(combined) {
            try? data.write(to: listURL, options: .atomic)
        }
    }

    private func showConfirmation(count: Int) {
        let alert = UIAlertController(
            title: "Saved to StashBox",
            message: "\(count) file\(count == 1 ? "" : "s") saved. Open StashBox to create an asset.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            self.close()
        })
        present(alert, animated: true)
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
