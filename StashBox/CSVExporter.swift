import Foundation

class CSVExporter {
    static func exportAll(assets: [Asset]) -> String {
        var lines: [String] = []

        // Header
        lines.append("Name,Brand,Model,Serial Number,Category,Purchase Date,Price,Currency,Retailer,Warranty Status,Latest Expiry,Total Cost of Ownership,Notes")

        for asset in assets {
            let fields: [String] = [
                escapeCSV(asset.name),
                escapeCSV(asset.brand),
                escapeCSV(asset.model),
                escapeCSV(asset.serialNumber),
                escapeCSV(asset.category.displayName),
                asset.purchaseDate,
                asset.purchasePrice.map { String(format: "%.2f", $0) } ?? "",
                asset.purchaseCurrency,
                escapeCSV(asset.retailer),
                asset.expiryStatus.label,
                asset.latestExpiry.map { dateOnlyISO($0) } ?? "",
                String(format: "%.2f", asset.totalCostOfOwnership),
                escapeCSV(asset.notes)
            ]
            lines.append(fields.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
