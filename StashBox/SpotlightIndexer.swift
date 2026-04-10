import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    private let domainID = "com.rijo.stashbox.assets"

    func indexAll(assets: [Asset]) {
        // Remove old index first
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainID]) { _ in
            let items = assets.filter { !$0.isArchived }.map { self.searchableItem(for: $0) }
            CSSearchableIndex.default().indexSearchableItems(items)
        }
    }

    func indexAsset(_ asset: Asset) {
        let item = searchableItem(for: asset)
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    func removeAsset(_ assetID: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [assetID])
    }

    private func searchableItem(for asset: Asset) -> CSSearchableItem {
        let attrs = CSSearchableItemAttributeSet(contentType: .item)
        attrs.title = asset.name
        attrs.contentDescription = [
            asset.brand,
            asset.category.displayName,
            asset.retailer,
            asset.expiryStatus.label
        ].filter { !$0.isEmpty }.joined(separator: " · ")
        attrs.keywords = [asset.name, asset.brand, asset.model, asset.retailer, asset.category.displayName] + asset.tags

        let item = CSSearchableItem(
            uniqueIdentifier: asset.id,
            domainIdentifier: domainID,
            attributeSet: attrs
        )
        return item
    }
}
