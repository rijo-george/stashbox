import SwiftUI

struct EditAssetSheet: View {
    let asset: Asset
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var brand: String
    @State private var model: String
    @State private var serialNumber: String
    @State private var category: AssetCategory
    @State private var purchaseDate: Date
    @State private var purchasePrice: String
    @State private var retailer: String

    init(asset: Asset) {
        self.asset = asset
        _name = State(initialValue: asset.name)
        _brand = State(initialValue: asset.brand)
        _model = State(initialValue: asset.model)
        _serialNumber = State(initialValue: asset.serialNumber)
        _category = State(initialValue: asset.category)
        _purchaseDate = State(initialValue: ISO8601Flexible.date(from: asset.purchaseDate) ?? Date())
        _purchasePrice = State(initialValue: asset.purchasePrice.map { String(format: "%.2f", $0) } ?? "")
        _retailer = State(initialValue: asset.retailer)
    }

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

                        // Fields
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Details", tc: tc)
                            inputField("Product Name *", text: $name, tc: tc)
                            inputField("Brand", text: $brand, tc: tc)
                            HStack(spacing: 12) {
                                inputField("Model", text: $model, tc: tc)
                                inputField("Serial Number", text: $serialNumber, tc: tc)
                            }
                        }

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

                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(tc.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveChanges() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(name.isEmpty ? tc.textSecondary : tc.accent)
                        .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

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

    private func saveChanges() {
        var updated = asset
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.brand = brand.trimmingCharacters(in: .whitespaces)
        updated.model = model.trimmingCharacters(in: .whitespaces)
        updated.serialNumber = serialNumber.trimmingCharacters(in: .whitespaces)
        updated.category = category
        updated.purchaseDate = dateOnlyISO(purchaseDate)
        updated.purchasePrice = Double(purchasePrice.replacingOccurrences(of: ",", with: ""))
        updated.retailer = retailer.trimmingCharacters(in: .whitespaces)
        store.updateAsset(updated)
        Haptic.fire(.success)
        dismiss()
    }
}
