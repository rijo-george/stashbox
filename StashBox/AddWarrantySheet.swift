import SwiftUI

struct AddWarrantySheet: View {
    let assetID: String
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = "Manufacturer Warranty"
    @State private var isExtended = false
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var isLifetime = false
    @State private var coverageDetails = ""
    @State private var providerName = ""
    @State private var providerContact = ""
    @State private var selectedReminderDays: Set<Int> = [90, 30, 7, 1]

    var editingWarranty: Warranty? = nil

    init(assetID: String, editingWarranty: Warranty? = nil) {
        self.assetID = assetID
        self.editingWarranty = editingWarranty
        if let w = editingWarranty {
            _name = State(initialValue: w.name)
            _isExtended = State(initialValue: w.isExtended)
            _startDate = State(initialValue: ISO8601Flexible.date(from: w.startDate) ?? Date())
            _endDate = State(initialValue: w.endDate.flatMap { ISO8601Flexible.date(from: $0) } ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())!)
            _isLifetime = State(initialValue: w.isLifetime)
            _coverageDetails = State(initialValue: w.coverageDetails)
            _providerName = State(initialValue: w.providerName)
            _providerContact = State(initialValue: w.providerContact)
            _selectedReminderDays = State(initialValue: Set(w.reminderDays))
        }
    }

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Name and type
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Warranty Info", tc: tc)
                            inputField("Warranty Name", text: $name, tc: tc)

                            Toggle(isOn: $isExtended) {
                                Text("Extended Warranty")
                                    .font(.system(size: 14))
                                    .foregroundStyle(tc.textPrimary)
                            }
                            .tint(tc.accent)
                        }

                        // Dates
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Coverage Period", tc: tc)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start Date")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(tc.textSecondary)
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(tc.accent)
                            }

                            Toggle(isOn: $isLifetime) {
                                Text("Lifetime Warranty")
                                    .font(.system(size: 14))
                                    .foregroundStyle(tc.textPrimary)
                            }
                            .tint(tc.accent)

                            if !isLifetime {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("End Date")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(tc.textSecondary)
                                    DatePicker("", selection: $endDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(tc.accent)
                                }
                            }
                        }

                        // Coverage
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Coverage Details", tc: tc)
                            TextField("e.g., Parts and labor, accidental damage", text: $coverageDetails, axis: .vertical)
                                .font(.system(size: 14))
                                .foregroundStyle(tc.textPrimary)
                                .padding(12)
                                .background(tc.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.borderInactive, lineWidth: 1))
                                .lineLimit(2...4)
                        }

                        // Provider
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Provider", tc: tc)
                            inputField("Provider Name", text: $providerName, tc: tc)
                            inputField("Contact (phone/email/URL)", text: $providerContact, tc: tc)
                        }

                        // Reminders
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Reminders", tc: tc)
                            Text("Notify before expiry:")
                                .font(.system(size: 13))
                                .foregroundStyle(tc.textSecondary)

                            HStack(spacing: 10) {
                                ForEach([90, 30, 7, 1], id: \.self) { days in
                                    Button {
                                        if selectedReminderDays.contains(days) {
                                            selectedReminderDays.remove(days)
                                        } else {
                                            selectedReminderDays.insert(days)
                                        }
                                        Haptic.fire(.selectionChanged)
                                    } label: {
                                        Text("\(days)d")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(selectedReminderDays.contains(days) ? tc.accent : tc.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(selectedReminderDays.contains(days) ? tc.accent.opacity(0.12) : tc.surface)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(
                                                    selectedReminderDays.contains(days) ? tc.accent.opacity(0.3) : tc.borderInactive,
                                                    lineWidth: 1
                                                )
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(editingWarranty == nil ? "Add Warranty" : "Edit Warranty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(tc.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveWarranty() }
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

    private func inputField(_ placeholder: String, text: Binding<String>, tc: ThemeColors) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 14))
            .foregroundStyle(tc.textPrimary)
            .padding(12)
            .background(tc.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.borderInactive, lineWidth: 1))
    }

    private func saveWarranty() {
        let warranty = Warranty(
            id: editingWarranty?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            isExtended: isExtended,
            startDate: dateOnlyISO(startDate),
            endDate: isLifetime ? nil : dateOnlyISO(endDate),
            coverageDetails: coverageDetails.trimmingCharacters(in: .whitespaces),
            providerName: providerName.trimmingCharacters(in: .whitespaces),
            providerContact: providerContact.trimmingCharacters(in: .whitespaces),
            claims: editingWarranty?.claims ?? [],
            reminderDays: Array(selectedReminderDays).sorted(by: >),
            documentIDs: editingWarranty?.documentIDs ?? []
        )

        if editingWarranty != nil {
            store.updateWarranty(warranty, in: assetID)
        } else {
            store.addWarranty(warranty, to: assetID)
        }
        Haptic.fire(.success)
        dismiss()
    }
}
