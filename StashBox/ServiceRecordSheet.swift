import SwiftUI

struct ServiceRecordSheet: View {
    let assetID: String
    let warranties: [Warranty]
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var type: ServiceType = .repair
    @State private var description = ""
    @State private var servicer = ""
    @State private var cost = ""
    @State private var coveredByWarranty = false
    @State private var selectedWarrantyID: String? = nil
    @State private var notes = ""

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Service type
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Service Type", tc: tc)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ServiceType.allCases) { st in
                                        Button {
                                            type = st
                                            Haptic.fire(.selectionChanged)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: st.icon)
                                                    .font(.system(size: 13))
                                                Text(st.displayName)
                                                    .font(.system(size: 13, weight: .medium))
                                            }
                                            .foregroundStyle(type == st ? tc.accent : tc.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(type == st ? tc.accent.opacity(0.12) : tc.surface)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(type == st ? tc.accent.opacity(0.4) : tc.borderInactive, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        // Details
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Details", tc: tc)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Service Date")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(tc.textSecondary)
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(tc.accent)
                            }

                            inputField("Description *", text: $description, tc: tc)
                            inputField("Service Provider", text: $servicer, tc: tc)
                            inputField("Cost", text: $cost, tc: tc, keyboardType: .decimalPad)
                        }

                        // Warranty coverage
                        if !warranties.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $coveredByWarranty) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "shield.checkered")
                                            .foregroundStyle(tc.warrantyActive)
                                        Text("Covered by Warranty")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(tc.textPrimary)
                                    }
                                }
                                .tint(tc.accent)

                                if coveredByWarranty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Select Warranty")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(tc.textSecondary)

                                        ForEach(warranties) { w in
                                            Button {
                                                selectedWarrantyID = w.id
                                                Haptic.fire(.selectionChanged)
                                            } label: {
                                                HStack {
                                                    Image(systemName: selectedWarrantyID == w.id ? "checkmark.circle.fill" : "circle")
                                                        .foregroundStyle(selectedWarrantyID == w.id ? tc.accent : tc.textSecondary)
                                                    Text(w.name)
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(tc.textPrimary)
                                                    Spacer()
                                                }
                                                .padding(10)
                                                .background(tc.surface)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("Notes", tc: tc)
                            TextField("Optional notes...", text: $notes, axis: .vertical)
                                .font(.system(size: 14))
                                .foregroundStyle(tc.textPrimary)
                                .padding(12)
                                .background(tc.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.borderInactive, lineWidth: 1))
                                .lineLimit(2...4)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Service Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(tc.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveRecord() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(description.isEmpty ? tc.textSecondary : tc.accent)
                        .disabled(description.isEmpty)
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

    private func saveRecord() {
        let record = ServiceRecord(
            date: dateOnlyISO(date),
            type: type,
            description: description.trimmingCharacters(in: .whitespaces),
            servicer: servicer.trimmingCharacters(in: .whitespaces),
            cost: Double(cost.replacingOccurrences(of: ",", with: "")),
            coveredByWarranty: coveredByWarranty,
            warrantyID: coveredByWarranty ? selectedWarrantyID : nil,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        store.addServiceRecord(record, to: assetID)
        Haptic.fire(.success)
        dismiss()
    }
}
