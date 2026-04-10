import SwiftUI

struct AddAssetSheet: View {
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var serialNumber = ""
    @State private var category: AssetCategory = .electronics
    @State private var purchaseDate = Date()
    @State private var purchasePrice = ""
    @State private var retailer = ""

    // Optional warranty inline
    @State private var addWarranty = false
    @State private var warrantyName = "Manufacturer Warranty"
    @State private var warrantyEndDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var warrantyIsLifetime = false
    @State private var coverageDetails = ""

    // Camera
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var attachedDocID: String? = nil

    // Pre-fill from OCR
    var prefill: OCRPrefill? = nil

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Category picker
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("Category", tc: tc)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(AssetCategory.allCases) { cat in
                                        Button {
                                            category = cat
                                            Haptic.fire(.selectionChanged)
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 18))
                                                Text(cat.displayName)
                                                    .font(.system(size: 10, weight: .medium))
                                            }
                                            .foregroundStyle(category == cat ? tc.accent : tc.textSecondary)
                                            .frame(width: 70, height: 56)
                                            .background(category == cat ? tc.accent.opacity(0.12) : tc.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(category == cat ? tc.accent.opacity(0.4) : tc.borderInactive, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        // Required fields
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Details", tc: tc)
                            inputField("Product Name *", text: $name, tc: tc)
                            inputField("Brand", text: $brand, tc: tc)
                            HStack(spacing: 12) {
                                inputField("Model", text: $model, tc: tc)
                                inputField("Serial Number", text: $serialNumber, tc: tc)
                            }
                        }

                        // Purchase info
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Purchase Info", tc: tc)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Purchase Date")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(tc.textSecondary)
                                DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(tc.accent)
                            }

                            HStack(spacing: 12) {
                                inputField("Price", text: $purchasePrice, tc: tc, keyboardType: .decimalPad)
                                inputField("Retailer", text: $retailer, tc: tc)
                            }
                        }

                        // Attach receipt
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Receipt Photo", tc: tc)
                            if attachedDocID != nil {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(tc.warrantyActive)
                                    Text("Receipt attached")
                                        .font(.system(size: 13))
                                        .foregroundStyle(tc.textPrimary)
                                    Spacer()
                                    Button("Remove") {
                                        if let id = attachedDocID {
                                            DocumentStore.shared.deleteDocument(id)
                                            store.removeDocumentMetadata(id)
                                        }
                                        attachedDocID = nil
                                    }
                                    .font(.system(size: 12))
                                    .foregroundStyle(tc.destructive)
                                }
                                .padding(12)
                                .background(tc.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                HStack(spacing: 10) {
                                    Button {
                                        showingCamera = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "camera")
                                            Text("Camera")
                                        }
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(tc.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(tc.accent.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    Button {
                                        showingPhotoPicker = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "photo")
                                            Text("Library")
                                        }
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(tc.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(tc.accent.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }

                        // Warranty toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $addWarranty) {
                                HStack(spacing: 6) {
                                    Image(systemName: "shield.checkered")
                                        .foregroundStyle(tc.accent)
                                    Text("Add Warranty")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(tc.textPrimary)
                                }
                            }
                            .tint(tc.accent)

                            if addWarranty {
                                inputField("Warranty Name", text: $warrantyName, tc: tc)

                                Toggle(isOn: $warrantyIsLifetime) {
                                    Text("Lifetime Warranty")
                                        .font(.system(size: 13))
                                        .foregroundStyle(tc.textPrimary)
                                }
                                .tint(tc.accent)

                                if !warrantyIsLifetime {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Warranty End Date")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(tc.textSecondary)
                                        DatePicker("", selection: $warrantyEndDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .tint(tc.accent)
                                    }
                                }

                                inputField("Coverage Details", text: $coverageDetails, tc: tc)
                            }
                        }

                        // Notes can be added from the asset detail view after creation
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(tc.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveAsset() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(name.isEmpty ? tc.textSecondary : tc.accent)
                        .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear { applyPrefill() }
        .fullScreenCover(isPresented: $showingCamera) {
            ImagePickerView(sourceType: .camera) { image in
                showingCamera = false
                attachImage(image)
            } onCancel: {
                showingCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingPhotoPicker) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                showingPhotoPicker = false
                attachImage(image)
            } onCancel: {
                showingPhotoPicker = false
            }
        }
    }

    private func attachImage(_ image: UIImage) {
        let meta = DocumentStore.shared.saveImage(image, type: .receipt)
        store.addDocumentMetadata(meta)
        attachedDocID = meta.id
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, tc: ThemeColors) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(tc.textSecondary)
            .textCase(.uppercase)
    }

    private func inputField(_ placeholder: String, text: Binding<String>, tc: ThemeColors,
                            keyboardType: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 14))
            .foregroundStyle(tc.textPrimary)
            .keyboardType(keyboardType)
            .padding(12)
            .background(tc.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.borderInactive, lineWidth: 1))
    }

    private func saveAsset() {
        let price = Double(purchasePrice.replacingOccurrences(of: ",", with: ""))

        var warranties: [Warranty] = []
        if addWarranty {
            warranties.append(Warranty(
                name: warrantyName.isEmpty ? "Manufacturer Warranty" : warrantyName,
                startDate: dateOnlyISO(purchaseDate),
                endDate: warrantyIsLifetime ? nil : dateOnlyISO(warrantyEndDate),
                coverageDetails: coverageDetails
            ))
        }

        let asset = Asset(
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            serialNumber: serialNumber.trimmingCharacters(in: .whitespaces),
            category: category,
            purchaseDate: dateOnlyISO(purchaseDate),
            purchasePrice: price,
            retailer: retailer.trimmingCharacters(in: .whitespaces),
            warranties: warranties,
            documentIDs: attachedDocID.map { [$0] } ?? []
        )

        store.addAsset(asset)
        Haptic.fire(.success)
        dismiss()
    }

    private func applyPrefill() {
        guard let p = prefill else { return }
        if let n = p.name { name = n }
        if let b = p.brand { brand = b }
        if let r = p.retailer { retailer = r }
        if let d = p.date { purchaseDate = d }
        if let pr = p.price { purchasePrice = String(format: "%.2f", pr) }
        if let s = p.serialNumber { serialNumber = s }
    }
}

// MARK: - OCR Prefill data

struct OCRPrefill {
    var name: String?
    var brand: String?
    var retailer: String?
    var date: Date?
    var price: Double?
    var serialNumber: String?
}
