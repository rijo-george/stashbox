import Foundation
import SwiftUI

// MARK: - Asset Category

enum AssetCategory: String, Codable, CaseIterable, Identifiable {
    case electronics
    case appliances
    case vehicles
    case furniture
    case tools
    case clothing
    case jewelry
    case sports
    case homeImprovement = "home_improvement"
    case medical
    case subscription
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .electronics: return "Electronics"
        case .appliances: return "Appliances"
        case .vehicles: return "Vehicles"
        case .furniture: return "Furniture"
        case .tools: return "Tools"
        case .clothing: return "Clothing"
        case .jewelry: return "Jewelry"
        case .sports: return "Sports"
        case .homeImprovement: return "Home Improvement"
        case .medical: return "Medical"
        case .subscription: return "Subscription"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .electronics: return "desktopcomputer"
        case .appliances: return "refrigerator"
        case .vehicles: return "car"
        case .furniture: return "sofa"
        case .tools: return "wrench.and.screwdriver"
        case .clothing: return "tshirt"
        case .jewelry: return "sparkles"
        case .sports: return "sportscourt"
        case .homeImprovement: return "house"
        case .medical: return "cross.case"
        case .subscription: return "arrow.triangle.2.circlepath"
        case .other: return "shippingbox"
        }
    }

    var defaultWarrantyMonths: Int? {
        switch self {
        case .electronics: return 12
        case .appliances: return 24
        case .vehicles: return 36
        case .furniture: return 12
        case .tools: return 12
        case .medical: return 12
        case .subscription: return 12
        case .clothing, .jewelry, .sports, .homeImprovement, .other: return nil
        }
    }
}

// MARK: - Service Type

enum ServiceType: String, Codable, CaseIterable, Identifiable {
    case repair
    case maintenance
    case inspection
    case upgrade
    case replacement

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .repair: return "Repair"
        case .maintenance: return "Maintenance"
        case .inspection: return "Inspection"
        case .upgrade: return "Upgrade"
        case .replacement: return "Replacement"
        }
    }

    var icon: String {
        switch self {
        case .repair: return "wrench"
        case .maintenance: return "gearshape"
        case .inspection: return "magnifyingglass"
        case .upgrade: return "arrow.up.circle"
        case .replacement: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Document Type

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case receipt
    case warrantyCard = "warranty_card"
    case manual
    case invoice
    case serviceInvoice = "service_invoice"
    case photo
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .receipt: return "Receipt"
        case .warrantyCard: return "Warranty Card"
        case .manual: return "Manual"
        case .invoice: return "Invoice"
        case .serviceInvoice: return "Service Invoice"
        case .photo: return "Photo"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .receipt: return "receipt"
        case .warrantyCard: return "shield.checkered"
        case .manual: return "book"
        case .invoice: return "doc.text"
        case .serviceInvoice: return "doc.text.magnifyingglass"
        case .photo: return "photo"
        case .other: return "doc"
        }
    }
}

// MARK: - Expiry Urgency

enum ExpiryUrgency: Comparable {
    case expired
    case critical(days: Int)    // <= 7 days
    case warning(days: Int)     // <= 30 days
    case upcoming(days: Int)    // <= 90 days
    case safe(days: Int)        // > 90 days
    case lifetime
    case noWarranty

    static func from(daysRemaining: Int?) -> ExpiryUrgency {
        guard let days = daysRemaining else { return .noWarranty }
        if days < 0 { return .expired }
        if days <= 7 { return .critical(days: days) }
        if days <= 30 { return .warning(days: days) }
        if days <= 90 { return .upcoming(days: days) }
        return .safe(days: days)
    }

    var label: String {
        switch self {
        case .expired: return "Expired"
        case .critical(let d): return "\(d)d left"
        case .warning(let d): return "\(d)d left"
        case .upcoming(let d): return "\(d)d left"
        case .safe(let d): return "\(d)d left"
        case .lifetime: return "Lifetime"
        case .noWarranty: return "No Warranty"
        }
    }

    var sortOrder: Int {
        switch self {
        case .expired: return 0
        case .critical: return 1
        case .warning: return 2
        case .upcoming: return 3
        case .safe: return 4
        case .lifetime: return 5
        case .noWarranty: return 6
        }
    }

    static func < (lhs: ExpiryUrgency, rhs: ExpiryUrgency) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Sort & Filter

enum SortOption: String, CaseIterable, Identifiable {
    case name
    case purchaseDate = "purchase_date"
    case expiryDate = "expiry_date"
    case category
    case price

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .name: return "Name"
        case .purchaseDate: return "Purchase Date"
        case .expiryDate: return "Expiry Date"
        case .category: return "Category"
        case .price: return "Price"
        }
    }

    var icon: String {
        switch self {
        case .name: return "textformat"
        case .purchaseDate: return "calendar"
        case .expiryDate: return "clock"
        case .category: return "square.grid.2x2"
        case .price: return "dollarsign"
        }
    }
}

enum FilterOption: Equatable, Identifiable {
    case all
    case category(AssetCategory)
    case expiringWithin(days: Int)
    case expired
    case active
    case archived

    var id: String {
        switch self {
        case .all: return "all"
        case .category(let c): return "cat_\(c.rawValue)"
        case .expiringWithin(let d): return "expiring_\(d)"
        case .expired: return "expired"
        case .active: return "active"
        case .archived: return "archived"
        }
    }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .category(let c): return c.displayName
        case .expiringWithin(let d): return "Expiring in \(d)d"
        case .expired: return "Expired"
        case .active: return "Active"
        case .archived: return "Archived"
        }
    }
}

// MARK: - Warranty Claim

struct WarrantyClaim: Codable, Identifiable, Hashable {
    var id: String
    var date: String
    var description: String
    var outcome: String
    var savedAmount: Double?
    var documentIDs: [String]

    init(id: String = UUID().uuidString, date: String = dateOnlyISO(), description: String = "",
         outcome: String = "", savedAmount: Double? = nil, documentIDs: [String] = []) {
        self.id = id
        self.date = date
        self.description = description
        self.outcome = outcome
        self.savedAmount = savedAmount
        self.documentIDs = documentIDs
    }
}

// MARK: - Warranty

struct Warranty: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var isExtended: Bool
    var startDate: String
    var endDate: String?
    var coverageDetails: String
    var providerName: String
    var providerContact: String
    var claims: [WarrantyClaim]
    var reminderDays: [Int]
    var documentIDs: [String]

    init(id: String = UUID().uuidString, name: String = "Manufacturer Warranty", isExtended: Bool = false,
         startDate: String = dateOnlyISO(), endDate: String? = nil, coverageDetails: String = "",
         providerName: String = "", providerContact: String = "", claims: [WarrantyClaim] = [],
         reminderDays: [Int] = [90, 30, 7, 1], documentIDs: [String] = []) {
        self.id = id
        self.name = name
        self.isExtended = isExtended
        self.startDate = startDate
        self.endDate = endDate
        self.coverageDetails = coverageDetails
        self.providerName = providerName
        self.providerContact = providerContact
        self.claims = claims
        self.reminderDays = reminderDays
        self.documentIDs = documentIDs
    }

    var isLifetime: Bool { endDate == nil }

    var isExpired: Bool {
        guard let end = endDate, let d = ISO8601Flexible.date(from: end) else { return false }
        return d < Date()
    }

    var daysRemaining: Int? {
        guard let end = endDate, let d = ISO8601Flexible.date(from: end) else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: d).day
    }

    var totalClaimSavings: Double {
        claims.compactMap(\.savedAmount).reduce(0, +)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Warranty, rhs: Warranty) -> Bool { lhs.id == rhs.id }
}

// MARK: - Service Record

struct ServiceRecord: Codable, Identifiable, Hashable {
    var id: String
    var date: String
    var type: ServiceType
    var description: String
    var servicer: String
    var cost: Double?
    var currency: String
    var coveredByWarranty: Bool
    var warrantyID: String?
    var documentIDs: [String]
    var notes: String

    init(id: String = UUID().uuidString, date: String = dateOnlyISO(), type: ServiceType = .repair,
         description: String = "", servicer: String = "", cost: Double? = nil,
         currency: String = Locale.current.currency?.identifier ?? "USD",
         coveredByWarranty: Bool = false, warrantyID: String? = nil,
         documentIDs: [String] = [], notes: String = "") {
        self.id = id
        self.date = date
        self.type = type
        self.description = description
        self.servicer = servicer
        self.cost = cost
        self.currency = currency
        self.coveredByWarranty = coveredByWarranty
        self.warrantyID = warrantyID
        self.documentIDs = documentIDs
        self.notes = notes
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ServiceRecord, rhs: ServiceRecord) -> Bool { lhs.id == rhs.id }
}

// MARK: - Document Metadata

struct DocumentMetadata: Codable, Identifiable, Hashable {
    var id: String
    var originalFilename: String
    var type: DocumentType
    var mimeType: String
    var createdAt: String
    var ocrText: String?

    init(id: String = UUID().uuidString, originalFilename: String = "", type: DocumentType = .receipt,
         mimeType: String = "image/jpeg", createdAt: String = pythonISO(), ocrText: String? = nil) {
        self.id = id
        self.originalFilename = originalFilename
        self.type = type
        self.mimeType = mimeType
        self.createdAt = createdAt
        self.ocrText = ocrText
    }
}

// MARK: - Asset

struct Asset: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var brand: String
    var model: String
    var serialNumber: String
    var category: AssetCategory
    var purchaseDate: String
    var purchasePrice: Double?
    var purchaseCurrency: String
    var retailer: String
    var notes: String
    var warranties: [Warranty]
    var serviceRecords: [ServiceRecord]
    var documentIDs: [String]
    var tags: [String]
    var isArchived: Bool
    var createdAt: String
    var updatedAt: String

    init(id: String = UUID().uuidString, name: String = "", brand: String = "", model: String = "",
         serialNumber: String = "", category: AssetCategory = .electronics,
         purchaseDate: String = dateOnlyISO(), purchasePrice: Double? = nil,
         purchaseCurrency: String = Locale.current.currency?.identifier ?? "USD",
         retailer: String = "", notes: String = "", warranties: [Warranty] = [],
         serviceRecords: [ServiceRecord] = [], documentIDs: [String] = [],
         tags: [String] = [], isArchived: Bool = false,
         createdAt: String = pythonISO(), updatedAt: String = pythonISO()) {
        self.id = id
        self.name = name
        self.brand = brand
        self.model = model
        self.serialNumber = serialNumber
        self.category = category
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.purchaseCurrency = purchaseCurrency
        self.retailer = retailer
        self.notes = notes
        self.warranties = warranties
        self.serviceRecords = serviceRecords
        self.documentIDs = documentIDs
        self.tags = tags
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var totalServiceCost: Double {
        serviceRecords.compactMap(\.cost).reduce(0, +)
    }

    var totalCostOfOwnership: Double {
        (purchasePrice ?? 0) + totalServiceCost
    }

    var primaryWarranty: Warranty? {
        warranties.first { !$0.isExtended } ?? warranties.first
    }

    var latestExpiry: Date? {
        warranties.compactMap { w in
            guard let end = w.endDate else { return nil as Date? }
            return ISO8601Flexible.date(from: end)
        }.max()
    }

    var hasLifetimeWarranty: Bool {
        warranties.contains { $0.isLifetime }
    }

    var expiryStatus: ExpiryUrgency {
        if warranties.isEmpty { return .noWarranty }
        if hasLifetimeWarranty { return .lifetime }
        guard let latest = latestExpiry else { return .noWarranty }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: latest).day ?? 0
        return ExpiryUrgency.from(daysRemaining: days)
    }

    var totalSavings: Double {
        warranties.reduce(0) { $0 + $1.totalClaimSavings }
    }

    var priceDisplay: String {
        guard let price = purchasePrice else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = purchaseCurrency
        return formatter.string(from: NSNumber(value: price)) ?? "\(purchaseCurrency) \(price)"
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Asset, rhs: Asset) -> Bool { lhs.id == rhs.id }
}

// MARK: - App Settings

struct AppSettings: Codable {
    var defaultReminderDays: [Int]
    var defaultCurrency: String
    var hasCompletedOnboarding: Bool
    var notificationsEnabled: Bool
    var lastSyncTimestamp: String?

    init(defaultReminderDays: [Int] = [90, 30, 7, 1],
         defaultCurrency: String = Locale.current.currency?.identifier ?? "USD",
         hasCompletedOnboarding: Bool = false,
         notificationsEnabled: Bool = true,
         lastSyncTimestamp: String? = nil) {
        self.defaultReminderDays = defaultReminderDays
        self.defaultCurrency = defaultCurrency
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.notificationsEnabled = notificationsEnabled
        self.lastSyncTimestamp = lastSyncTimestamp
    }
}

// MARK: - Root Data

struct StashBoxData: Codable {
    var assets: [Asset]
    var documents: [DocumentMetadata]
    var settings: AppSettings

    init(assets: [Asset] = [], documents: [DocumentMetadata] = [], settings: AppSettings = AppSettings()) {
        self.assets = assets
        self.documents = documents
        self.settings = settings
    }

    var activeAssets: [Asset] { assets.filter { !$0.isArchived } }
    var archivedAssets: [Asset] { assets.filter { $0.isArchived } }

    var totalValue: Double {
        activeAssets.compactMap(\.purchasePrice).reduce(0, +)
    }

    var totalSavings: Double {
        activeAssets.reduce(0) { $0 + $1.totalSavings }
    }

    var expiringAssets: [Asset] {
        activeAssets.filter {
            switch $0.expiryStatus {
            case .critical, .warning: return true
            default: return false
            }
        }.sorted {
            ($0.latestExpiry ?? .distantFuture) < ($1.latestExpiry ?? .distantFuture)
        }
    }
}
