import SwiftUI

struct ExportSheet: View {
    let asset: Asset?
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var toast = ToastState()

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 48))
                        .foregroundStyle(tc.accent.opacity(0.6))

                    Text("Export Data")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(tc.textPrimary)

                    VStack(spacing: 12) {
                        if let asset {
                            // Single asset PDF
                            ShareLink(
                                item: pdfData(for: asset),
                                preview: SharePreview("\(asset.name) Receipt", image: Image(systemName: "doc.richtext"))
                            ) {
                                exportButton(
                                    icon: "doc.richtext",
                                    title: "Export as PDF",
                                    subtitle: "Receipt for \(asset.name)",
                                    tc: tc
                                )
                            }
                        }

                        // CSV export
                        let csv = CSVExporter.exportAll(assets: store.data.activeAssets)
                        ShareLink(
                            item: csv,
                            preview: SharePreview("StashBox Export", image: Image(systemName: "tablecells"))
                        ) {
                            exportButton(
                                icon: "tablecells",
                                title: "Export All as CSV",
                                subtitle: "\(store.data.activeAssets.count) assets",
                                tc: tc
                            )
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(tc.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .toast(toast)
    }

    private func exportButton(icon: String, title: String, subtitle: String, tc: ThemeColors) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(tc.accent)
                .frame(width: 40, height: 40)
                .background(tc.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tc.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(tc.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tc.textSecondary.opacity(0.5))
        }
        .padding(14)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.borderInactive, lineWidth: 1))
    }

    private func pdfData(for asset: Asset) -> Data {
        PDFGenerator.generateReceipt(for: asset)
    }
}
