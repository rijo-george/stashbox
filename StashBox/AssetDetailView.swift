import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var toast = ToastState()
    @State private var showingEditSheet = false
    @State private var showingAddWarranty = false
    @State private var showingAddService = false
    @State private var showingDocuments = false
    @State private var showingDeleteConfirm = false
    @State private var showingExport = false
    @State private var showingAddNote = false
    @State private var newNoteText = ""
    @State private var showingDisposal = false

    private var liveAsset: Asset {
        store.asset(byID: asset.id) ?? asset
    }

    var body: some View {
        let tc = themeManager.colors
        let current = liveAsset

        ScrollView {
            VStack(spacing: 16) {
                if let disposal = current.disposal {
                    disposalBanner(disposal, tc: tc)
                }
                headerCard(current, tc: tc)
                warrantySection(current, tc: tc)
                serviceSection(current, tc: tc)
                costSection(current, tc: tc)
                documentsSection(current, tc: tc)
                notesSection(current, tc: tc)
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(tc.bg.ignoresSafeArea())
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        showingExport = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    if current.disposal == nil {
                        Button {
                            showingDisposal = true
                        } label: {
                            Label("Mark as Sold/Gifted...", systemImage: "arrow.right.circle")
                        }
                    }
                    Button {
                        store.archiveAsset(current.id)
                        Haptic.fire(.success)
                        toast.show(current.isArchived ? "Unarchived" : "Archived")
                    } label: {
                        Label(current.isArchived ? "Unarchive" : "Archive",
                              systemImage: current.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(tc.accent)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditAssetSheet(asset: current)
        }
        .sheet(isPresented: $showingAddWarranty) {
            AddWarrantySheet(assetID: current.id)
        }
        .sheet(isPresented: $showingAddService) {
            ServiceRecordSheet(assetID: current.id, warranties: current.warranties)
        }
        .sheet(isPresented: $showingDocuments) {
            DocumentGalleryView(assetID: current.id, documentIDs: current.documentIDs)
        }
        .sheet(isPresented: $showingExport) {
            ExportSheet(asset: current)
        }
        .sheet(isPresented: $showingDisposal) {
            DisposalSheet(assetID: current.id)
        }
        .alert("Delete Asset?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.deleteAsset(current.id)
                Haptic.fire(.warning)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(current.name)\" and all its data.")
        }
        .toast(toast)
    }

    // MARK: - Header Card

    @ViewBuilder
    private func headerCard(_ asset: Asset, tc: ThemeColors) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: asset.category.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(tc.categoryTint)
                    .frame(width: 52, height: 52)
                    .background(tc.categoryTint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text(asset.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(tc.textPrimary)

                    HStack(spacing: 6) {
                        if !asset.brand.isEmpty {
                            Text(asset.brand)
                                .foregroundStyle(tc.textSecondary)
                        }
                        if !asset.model.isEmpty {
                            Text("· \(asset.model)")
                                .foregroundStyle(tc.textSecondary)
                        }
                    }
                    .font(.system(size: 13))
                }

                Spacer()

                StatusBadge(urgency: asset.expiryStatus)
            }

            Divider().overlay(tc.borderInactive)

            // Details grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                detailItem("calendar", "Purchased", displayDate(asset.purchaseDate), tc: tc)
                detailItem("dollarsign.circle", "Price", asset.priceDisplay, tc: tc)
                detailItem("bag", "Retailer", asset.retailer.isEmpty ? "—" : asset.retailer, tc: tc)
                detailItem("number", "Serial", asset.serialNumber.isEmpty ? "—" : asset.serialNumber, tc: tc)
            }
        }
        .padding(16)
        .background(tc.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tc.cardBorder, lineWidth: 1))
    }

    private func detailItem(_ icon: String, _ label: String, _ value: String, tc: ThemeColors) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(tc.textSecondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(tc.textSecondary)
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(tc.textPrimary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    // MARK: - Warranty Section

    @ViewBuilder
    private func warrantySection(_ asset: Asset, tc: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Warranties")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)
                Spacer()
                Button {
                    showingAddWarranty = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(tc.accent)
                }
            }

            if asset.warranties.isEmpty {
                HStack {
                    Image(systemName: "shield.slash")
                        .foregroundStyle(tc.textSecondary.opacity(0.5))
                    Text("No warranties added")
                        .font(.system(size: 13))
                        .foregroundStyle(tc.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tc.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(asset.warranties) { warranty in
                    warrantyCard(warranty, tc: tc)
                }
            }
        }
    }

    private func warrantyCard(_ warranty: Warranty, tc: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(warranty.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(tc.textPrimary)
                        if warranty.isExtended {
                            Text("EXT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(tc.accentSecondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(tc.accentSecondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    if !warranty.providerName.isEmpty {
                        Text(warranty.providerName)
                            .font(.system(size: 12))
                            .foregroundStyle(tc.textSecondary)
                    }
                }

                Spacer()

                if warranty.isLifetime {
                    ExpiryCountdown(urgency: .lifetime, compact: true)
                } else if let days = warranty.daysRemaining {
                    ExpiryCountdown(urgency: ExpiryUrgency.from(daysRemaining: days), compact: true)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Start")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(tc.textSecondary)
                    Text(shortDate(warranty.startDate))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(tc.textPrimary)
                }

                if let endDate = warranty.endDate {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("End")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(tc.textSecondary)
                        Text(shortDate(endDate))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(tc.textPrimary)
                    }
                }

                if !warranty.coverageDetails.isEmpty {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Coverage")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(tc.textSecondary)
                        Text(warranty.coverageDetails)
                            .font(.system(size: 12))
                            .foregroundStyle(tc.textPrimary)
                            .lineLimit(1)
                    }
                }
            }

            if !warranty.claims.isEmpty {
                Divider().overlay(tc.borderInactive)
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(tc.warrantyActive)
                    Text("\(warranty.claims.count) claim\(warranty.claims.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(tc.textSecondary)
                    if warranty.totalClaimSavings > 0 {
                        Text("· Saved \(formatCurrency(warranty.totalClaimSavings))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(tc.warrantyActive)
                    }
                }
            }
        }
        .padding(12)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.borderInactive, lineWidth: 1))
    }

    // MARK: - Service Section

    @ViewBuilder
    private func serviceSection(_ asset: Asset, tc: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Service Records")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)
                Spacer()
                Button {
                    showingAddService = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(tc.accent)
                }
            }

            if asset.serviceRecords.isEmpty {
                HStack {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundStyle(tc.textSecondary.opacity(0.5))
                    Text("No service records")
                        .font(.system(size: 13))
                        .foregroundStyle(tc.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tc.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(asset.serviceRecords.sorted(by: {
                    (ISO8601Flexible.date(from: $0.date) ?? .distantPast) >
                    (ISO8601Flexible.date(from: $1.date) ?? .distantPast)
                })) { record in
                    serviceRecordRow(record, tc: tc)
                }
            }
        }
    }

    private func serviceRecordRow(_ record: ServiceRecord, tc: ThemeColors) -> some View {
        HStack(spacing: 10) {
            Image(systemName: record.type.icon)
                .font(.system(size: 14))
                .foregroundStyle(tc.accent)
                .frame(width: 30, height: 30)
                .background(tc.accent.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(record.description.isEmpty ? record.type.displayName : record.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(tc.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(shortDate(record.date))
                        .font(.system(size: 11, design: .monospaced))
                    if !record.servicer.isEmpty {
                        Text("· \(record.servicer)")
                            .font(.system(size: 11))
                    }
                }
                .foregroundStyle(tc.textSecondary)
            }

            Spacer()

            if let cost = record.cost {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatCurrency(cost, currency: record.currency))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(record.coveredByWarranty ? tc.warrantyActive : tc.textPrimary)
                    if record.coveredByWarranty {
                        Text("Covered")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(tc.warrantyActive)
                    }
                }
            }
        }
        .padding(10)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Cost Section

    @ViewBuilder
    private func costSection(_ asset: Asset, tc: ThemeColors) -> some View {
        if asset.purchasePrice != nil || !asset.serviceRecords.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cost of Ownership")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)

                VStack(spacing: 8) {
                    costRow("Purchase Price", asset.priceDisplay, tc: tc)

                    if !asset.serviceRecords.isEmpty {
                        let serviceCost = asset.serviceRecords
                            .filter { !$0.coveredByWarranty }
                            .compactMap(\.cost)
                            .reduce(0, +)
                        costRow("Service Costs", formatCurrency(serviceCost, currency: asset.purchaseCurrency), tc: tc)
                    }

                    Divider().overlay(tc.borderInactive)

                    HStack {
                        Text("Total")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(tc.textPrimary)
                        Spacer()
                        Text(formatCurrency(asset.totalCostOfOwnership, currency: asset.purchaseCurrency))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(tc.accent)
                    }

                    if asset.totalSavings > 0 {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(tc.warrantyActive)
                            Text("Saved \(formatCurrency(asset.totalSavings, currency: asset.purchaseCurrency)) through warranty claims")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(tc.warrantyActive)
                        }
                    }
                }
                .padding(12)
                .background(tc.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func costRow(_ label: String, _ value: String, tc: ThemeColors) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(tc.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(tc.textPrimary)
        }
    }

    // MARK: - Documents Section

    @ViewBuilder
    private func documentsSection(_ asset: Asset, tc: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Documents")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)

                if !asset.documentIDs.isEmpty {
                    Text("\(asset.documentIDs.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(tc.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tc.accent.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                Button {
                    showingDocuments = true
                } label: {
                    Text(asset.documentIDs.isEmpty ? "Add" : "View All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(tc.accent)
                }
            }
        }
    }

    // MARK: - Notes Section

    @ViewBuilder
    private func notesSection(_ asset: Asset, tc: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Notes")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)
                Spacer()
                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(tc.accent)
                }
            }

            if asset.notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(tc.textSecondary.opacity(0.5))
                    Text("No notes yet")
                        .font(.system(size: 13))
                        .foregroundStyle(tc.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tc.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(asset.notes.sorted(by: {
                    (ISO8601Flexible.date(from: $0.createdAt) ?? .distantPast) >
                    (ISO8601Flexible.date(from: $1.createdAt) ?? .distantPast)
                })) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.text)
                            .font(.system(size: 13))
                            .foregroundStyle(tc.textPrimary)
                        Text(relativeDate(note.createdAt))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(tc.textSecondary.opacity(0.6))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(tc.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contextMenu {
                        Button(role: .destructive) {
                            store.deleteNote(note.id, from: asset.id)
                            Haptic.fire(.warning)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .alert("Add Note", isPresented: $showingAddNote) {
            TextField("Note", text: $newNoteText)
            Button("Add") {
                let trimmed = newNoteText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    store.addNote(Note(text: trimmed), to: asset.id)
                    Haptic.fire(.success)
                }
                newNoteText = ""
            }
            Button("Cancel", role: .cancel) { newNoteText = "" }
        }
    }

    // MARK: - Disposal Banner

    private func disposalBanner(_ disposal: DisposalInfo, tc: ThemeColors) -> some View {
        HStack(spacing: 10) {
            Image(systemName: disposal.type.icon)
                .font(.system(size: 16))
                .foregroundStyle(tc.warrantyExpiring)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(disposal.type.displayName) on \(displayDate(disposal.date))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tc.textPrimary)
                if !disposal.toWhom.isEmpty {
                    Text("To: \(disposal.toWhom)")
                        .font(.system(size: 11))
                        .foregroundStyle(tc.textSecondary)
                }
                if let amount = disposal.amount {
                    Text("for \(formatCurrency(amount))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(tc.warrantyActive)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(tc.warrantyExpiring.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.warrantyExpiring.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double, currency: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? liveAsset.purchaseCurrency
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
}
