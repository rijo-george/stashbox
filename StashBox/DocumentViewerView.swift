import SwiftUI

struct DocumentViewerView: View {
    let documentID: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage? = nil
    @State private var scale: CGFloat = 1.0

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = value
                                }
                                .onEnded { _ in
                                    withAnimation { scale = max(1.0, min(scale, 4.0)) }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation { scale = scale > 1.0 ? 1.0 : 2.0 }
                        }
                } else {
                    ProgressView()
                        .tint(tc.accent)
                }
            }
            .navigationTitle("Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(tc.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let image {
                        ShareLink(item: Image(uiImage: image), preview: SharePreview("Document", image: Image(uiImage: image)))
                    }
                }
            }
            .onAppear {
                DispatchQueue.global(qos: .userInitiated).async {
                    let loaded = DocumentStore.shared.loadImage(for: documentID)
                    DispatchQueue.main.async {
                        image = loaded
                    }
                }
            }
        }
    }
}
