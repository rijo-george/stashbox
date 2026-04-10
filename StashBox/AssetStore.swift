import Foundation
import SwiftUI

// MARK: - Store (reads/writes JSON with iCloud sync)

class AssetStore: ObservableObject {
    @Published var data: StashBoxData

    private let dataFile: URL
    private let configFile: URL
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var metadataQuery: NSMetadataQuery?

    init() {
        let dir = Self.storageDirectory()
        dataFile = dir.appendingPathComponent("data.json")
        configFile = dir.appendingPathComponent("config.json")
        data = StashBoxData()
        coordinatedLoad()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Storage resolution

    static func storageDirectory() -> URL {
        let fm = FileManager.default

        if let iCloudURL = fm.url(forUbiquityContainerIdentifier: "iCloud.com.rijo.stashbox") {
            let docsURL = iCloudURL.appendingPathComponent("Documents")
            try? fm.createDirectory(at: docsURL, withIntermediateDirectories: true)
            return docsURL
        }

        if let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rijo.stashbox") {
            let dir = groupURL.appendingPathComponent("StashBox")
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }

        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("StashBox")
        try? fm.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs
    }

    // MARK: - Coordinated Load / Save

    func load() { coordinatedLoad() }

    func coordinatedLoad() {
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        var needsSave = false
        coordinator.coordinate(readingItemAt: dataFile, options: [], error: &coordError) { url in
            guard let raw = try? Data(contentsOf: url),
                  let disk = try? JSONDecoder().decode(StashBoxData.self, from: raw)
            else { return }
            let merged = Self.merge(local: self.data, remote: disk)
            needsSave = !Self.dataEqual(merged, disk)
            DispatchQueue.main.async {
                self.data = merged
                SpotlightIndexer.shared.indexAll(assets: merged.assets)
            }
        }
        if needsSave { save() }
    }

    func save() {
        let snapshot = self.data
        let coordinator = NSFileCoordinator()
        var coordError: NSError?

        coordinator.coordinate(writingItemAt: dataFile, options: .forReplacing,
                               error: &coordError) { writeURL in
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let raw = try? encoder.encode(snapshot) else { return }
            try? raw.write(to: writeURL, options: .atomic)
        }
    }

    private static func dataEqual(_ a: StashBoxData, _ b: StashBoxData) -> Bool {
        Set(a.assets.map(\.id)) == Set(b.assets.map(\.id)) &&
        Set(a.documents.map(\.id)) == Set(b.documents.map(\.id))
    }

    // MARK: - Merge logic (union by ID, tiebreak by updatedAt)

    private static func merge(local: StashBoxData, remote: StashBoxData) -> StashBoxData {
        let mergedAssets = mergeAssets(local: local.assets, remote: remote.assets)
        let mergedDocs = mergeDocs(local: local.documents, remote: remote.documents)
        return StashBoxData(
            assets: mergedAssets,
            documents: mergedDocs,
            settings: local.settings
        )
    }

    private static func mergeAssets(local: [Asset], remote: [Asset]) -> [Asset] {
        var byID: [String: Asset] = [:]
        for item in remote { byID[item.id] = item }
        for item in local {
            if let existing = byID[item.id] {
                // Keep the one with later updatedAt
                let localDate = ISO8601Flexible.date(from: item.updatedAt) ?? .distantPast
                let remoteDate = ISO8601Flexible.date(from: existing.updatedAt) ?? .distantPast
                byID[item.id] = localDate >= remoteDate ? item : existing
            } else {
                byID[item.id] = item
            }
        }
        // Preserve order: local items first, then new remote items
        var result: [Asset] = []
        var seen = Set<String>()
        for item in local {
            if seen.insert(item.id).inserted { result.append(byID[item.id]!) }
        }
        for item in remote {
            if seen.insert(item.id).inserted { result.append(byID[item.id]!) }
        }
        return result
    }

    private static func mergeDocs(local: [DocumentMetadata], remote: [DocumentMetadata]) -> [DocumentMetadata] {
        var byID: [String: DocumentMetadata] = [:]
        for doc in remote { byID[doc.id] = doc }
        for doc in local { byID[doc.id] = doc }
        var result: [DocumentMetadata] = []
        var seen = Set<String>()
        for doc in local {
            if seen.insert(doc.id).inserted { result.append(byID[doc.id]!) }
        }
        for doc in remote {
            if seen.insert(doc.id).inserted { result.append(byID[doc.id]!) }
        }
        return result
    }

    // MARK: - File monitoring

    private func startMonitoring() {
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, "data.json")
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        NotificationCenter.default.addObserver(
            self, selector: #selector(fileDidChange),
            name: .NSMetadataQueryDidUpdate, object: query)
        query.start()
        metadataQuery = query

        startFileMonitor()

        NotificationCenter.default.addObserver(
            self, selector: #selector(fileDidChange),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func startFileMonitor() {
        fileMonitor?.cancel()
        fileMonitor = nil

        let fd = open(dataFile.path, O_EVTONLY)
        guard fd >= 0 else { return }
        fileDescriptor = fd
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .rename], queue: .main)
        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.coordinatedLoad()
            self.startFileMonitor()
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        fileMonitor = source
    }

    private func stopMonitoring() {
        fileMonitor?.cancel()
        fileMonitor = nil
        metadataQuery?.stop()
        metadataQuery = nil
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func fileDidChange() {
        coordinatedLoad()
    }

    // MARK: - Asset CRUD

    func addAsset(_ asset: Asset) {
        data.assets.append(asset)
        save()
        SpotlightIndexer.shared.indexAsset(asset)
    }

    func updateAsset(_ asset: Asset) {
        var updated = asset
        updated.updatedAt = pythonISO()
        if let idx = data.assets.firstIndex(where: { $0.id == asset.id }) {
            data.assets[idx] = updated
        }
        save()
        SpotlightIndexer.shared.indexAsset(asset)
    }

    func archiveAsset(_ assetID: String) {
        if let idx = data.assets.firstIndex(where: { $0.id == assetID }) {
            data.assets[idx].isArchived = true
            data.assets[idx].updatedAt = pythonISO()
        }
        save()
    }

    func unarchiveAsset(_ assetID: String) {
        if let idx = data.assets.firstIndex(where: { $0.id == assetID }) {
            data.assets[idx].isArchived = false
            data.assets[idx].updatedAt = pythonISO()
        }
        save()
    }

    func disposeAsset(_ assetID: String, disposal: DisposalInfo) {
        if let idx = data.assets.firstIndex(where: { $0.id == assetID }) {
            data.assets[idx].disposal = disposal
            data.assets[idx].isArchived = true
            data.assets[idx].updatedAt = pythonISO()
        }
        save()
    }

    func deleteAsset(_ assetID: String) {
        data.assets.removeAll { $0.id == assetID }
        save()
        SpotlightIndexer.shared.removeAsset(assetID)
    }

    func asset(byID id: String) -> Asset? {
        data.assets.first { $0.id == id }
    }

    // MARK: - Warranty CRUD

    func addWarranty(_ warranty: Warranty, to assetID: String) {
        guard let idx = data.assets.firstIndex(where: { $0.id == assetID }) else { return }
        data.assets[idx].warranties.append(warranty)
        data.assets[idx].updatedAt = pythonISO()
        save()
    }

    func updateWarranty(_ warranty: Warranty, in assetID: String) {
        guard let aIdx = data.assets.firstIndex(where: { $0.id == assetID }),
              let wIdx = data.assets[aIdx].warranties.firstIndex(where: { $0.id == warranty.id })
        else { return }
        data.assets[aIdx].warranties[wIdx] = warranty
        data.assets[aIdx].updatedAt = pythonISO()
        save()
    }

    func deleteWarranty(_ warrantyID: String, from assetID: String) {
        guard let idx = data.assets.firstIndex(where: { $0.id == assetID }) else { return }
        data.assets[idx].warranties.removeAll { $0.id == warrantyID }
        data.assets[idx].updatedAt = pythonISO()
        save()
    }

    // MARK: - Service Record CRUD

    func addServiceRecord(_ record: ServiceRecord, to assetID: String) {
        guard let idx = data.assets.firstIndex(where: { $0.id == assetID }) else { return }
        data.assets[idx].serviceRecords.append(record)
        data.assets[idx].updatedAt = pythonISO()
        save()
    }

    func deleteServiceRecord(_ recordID: String, from assetID: String) {
        guard let idx = data.assets.firstIndex(where: { $0.id == assetID }) else { return }
        data.assets[idx].serviceRecords.removeAll { $0.id == recordID }
        data.assets[idx].updatedAt = pythonISO()
        save()
    }

    // MARK: - Notes

    func addNote(_ note: Note, to assetID: String) {
        guard let idx = data.assets.firstIndex(where: { $0.id == assetID }) else { return }
        data.assets[idx].notes.append(note)
        data.assets[idx].updatedAt = pythonISO()
        save()
    }

    func deleteNote(_ noteID: String, from assetID: String) {
        guard let idx = data.assets.firstIndex(where: { $0.id == assetID }) else { return }
        data.assets[idx].notes.removeAll { $0.id == noteID }
        data.assets[idx].updatedAt = pythonISO()
        save()
    }

    // MARK: - Warranty Claim

    func addClaim(_ claim: WarrantyClaim, to warrantyID: String, in assetID: String) {
        guard let aIdx = data.assets.firstIndex(where: { $0.id == assetID }),
              let wIdx = data.assets[aIdx].warranties.firstIndex(where: { $0.id == warrantyID })
        else { return }
        data.assets[aIdx].warranties[wIdx].claims.append(claim)
        data.assets[aIdx].updatedAt = pythonISO()
        save()
    }

    // MARK: - Document tracking

    func addDocumentMetadata(_ doc: DocumentMetadata) {
        data.documents.append(doc)
        save()
    }

    func removeDocumentMetadata(_ docID: String) {
        data.documents.removeAll { $0.id == docID }
        // Also remove from any asset/warranty/service record that references it
        for i in data.assets.indices {
            data.assets[i].documentIDs.removeAll { $0 == docID }
            for j in data.assets[i].warranties.indices {
                data.assets[i].warranties[j].documentIDs.removeAll { $0 == docID }
                for k in data.assets[i].warranties[j].claims.indices {
                    data.assets[i].warranties[j].claims[k].documentIDs.removeAll { $0 == docID }
                }
            }
            for j in data.assets[i].serviceRecords.indices {
                data.assets[i].serviceRecords[j].documentIDs.removeAll { $0 == docID }
            }
        }
        save()
    }

    func linkDocument(_ docID: String, to assetID: String) {
        guard let idx = data.assets.firstIndex(where: { $0.id == assetID }) else { return }
        if !data.assets[idx].documentIDs.contains(docID) {
            data.assets[idx].documentIDs.append(docID)
            data.assets[idx].updatedAt = pythonISO()
            save()
        }
    }

    // MARK: - Settings

    func updateSettings(_ settings: AppSettings) {
        data.settings = settings
        save()
    }

    // MARK: - Config persistence (theme, shared with macOS)

    struct AppConfig: Codable {
        var theme: String

        static func configFile() -> URL {
            AssetStore.storageDirectory().appendingPathComponent("config.json")
        }

        static func load() -> AppConfig {
            guard let raw = try? Data(contentsOf: configFile()),
                  let config = try? JSONDecoder().decode(AppConfig.self, from: raw)
            else { return AppConfig(theme: "dark") }
            return config
        }

        func save() {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            guard let raw = try? encoder.encode(self) else { return }
            try? raw.write(to: AppConfig.configFile(), options: .atomic)
        }
    }
}
