import SwiftUI

struct DocumentGalleryView: View {
    let assetID: String
    let documentIDs: [String]
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingImagePicker = false
    @State private var selectedDocID: String? = nil
    @State private var thumbnails: [String: UIImage] = [:]

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                if documentIDs.isEmpty {
                    EmptyStateView(
                        icon: "doc.on.doc",
                        title: "No Documents",
                        subtitle: "Attach receipts, warranty cards, or manuals",
                        actionTitle: "Add Document",
                        action: { showingImagePicker = true }
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100), spacing: 10)
                        ], spacing: 10) {
                            ForEach(documentIDs, id: \.self) { docID in
                                Button {
                                    selectedDocID = docID
                                } label: {
                                    documentThumbnail(docID, tc: tc)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        store.removeDocumentMetadata(docID)
                                        DocumentStore.shared.deleteDocument(docID)
                                        Haptic.fire(.warning)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }

                            // Add button
                            Button {
                                showingImagePicker = true
                            } label: {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .foregroundStyle(tc.accent)
                                }
                                .frame(width: 100, height: 100)
                                .background(tc.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(tc.accent.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(tc.accent)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView(sourceType: .photoLibrary) { image in
                    showingImagePicker = false
                    let meta = DocumentStore.shared.saveImage(image)
                    store.addDocumentMetadata(meta)
                    store.linkDocument(meta.id, to: assetID)
                    Haptic.fire(.success)
                } onCancel: {
                    showingImagePicker = false
                }
            }
            .sheet(item: $selectedDocID) { docID in
                DocumentViewerView(documentID: docID)
            }
            .onAppear { loadThumbnails() }
        }
    }

    @ViewBuilder
    private func documentThumbnail(_ docID: String, tc: ThemeColors) -> some View {
        Group {
            if let thumb = thumbnails[docID] {
                Image(uiImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "doc")
                    .font(.system(size: 24))
                    .foregroundStyle(tc.textSecondary)
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.borderInactive, lineWidth: 1))
    }

    private func loadThumbnails() {
        for docID in documentIDs {
            if thumbnails[docID] == nil {
                DispatchQueue.global(qos: .userInitiated).async {
                    if let thumb = DocumentStore.shared.loadThumbnail(for: docID) {
                        DispatchQueue.main.async {
                            thumbnails[docID] = thumb
                        }
                    }
                }
            }
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
