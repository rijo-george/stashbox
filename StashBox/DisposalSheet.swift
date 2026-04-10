import SwiftUI

struct DisposalSheet: View {
    let assetID: String
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var type: DisposalType = .sold
    @State private var date = Date()
    @State private var toWhom = ""
    @State private var amount = ""
    @State private var notes = ""

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Type picker
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("What happened?", tc: tc)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                                ForEach(DisposalType.allCases) { dt in
                                    Button {
                                        type = dt
                                        Haptic.fire(.selectionChanged)
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: dt.icon)
                                                .font(.system(size: 18))
                                            Text(dt.displayName)
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        .foregroundStyle(type == dt ? tc.accent : tc.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(type == dt ? tc.accent.opacity(0.12) : tc.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(type == dt ? tc.accent.opacity(0.4) : tc.borderInactive, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }

                        // Date
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("Date", tc: tc)
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                                .tint(tc.accent)
                        }

                        // To whom (for sold/gifted/returned)
                        if type == .sold || type == .gifted || type == .returned {
                            VStack(alignment: .leading, spacing: 6) {
                                sectionLabel(type == .sold ? "Sold to" : type == .gifted ? "Gifted to" : "Returned to", tc: tc)
                                inputField("Name or place", text: $toWhom, tc: tc)
                            }
                        }

                        // Amount (for sold/returned)
                        if type == .sold || type == .returned {
                            VStack(alignment: .leading, spacing: 6) {
                                sectionLabel("Amount received", tc: tc)
                                inputField("Amount", text: $amount, tc: tc, keyboardType: .decimalPad)
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("Notes", tc: tc)
                            TextField("Optional...", text: $notes, axis: .vertical)
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
            .navigationTitle("Mark as \(type.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(tc.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirm") { save() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tc.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
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

    private func save() {
        let disposal = DisposalInfo(
            type: type,
            date: dateOnlyISO(date),
            toWhom: toWhom.trimmingCharacters(in: .whitespaces),
            amount: Double(amount.replacingOccurrences(of: ",", with: "")),
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        store.disposeAsset(assetID, disposal: disposal)
        Haptic.fire(.success)
        dismiss()
    }
}
