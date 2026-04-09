import SwiftUI
import PhotosUI

struct ScanReceiptSheet: View {
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingCamera = false
    @State private var pickedImages: [UIImage] = []
    @State private var isProcessing = false
    @State private var ocrResults: [OCRResult] = []
    @State private var currentReviewIndex = 0
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingAddSheet = false
    @State private var currentPrefill: OCRPrefill? = nil
    @State private var savedDocID: String? = nil

    private enum ScanState {
        case capture
        case processing
        case review
    }

    private var scanState: ScanState {
        if isProcessing { return .processing }
        if !ocrResults.isEmpty { return .review }
        return .capture
    }

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                switch scanState {
                case .capture:
                    captureView(tc: tc)
                case .processing:
                    processingView(tc: tc)
                case .review:
                    reviewView(tc: tc)
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if scanState == .review {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { resetState() }
                            .foregroundStyle(tc.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet, onDismiss: {
                advanceOrReset()
            }) {
                AddAssetSheet(prefill: currentPrefill)
            }
        }
    }

    // MARK: - Capture View

    @ViewBuilder
    private func captureView(tc: ThemeColors) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(tc.accent.opacity(0.6))

            VStack(spacing: 8) {
                Text("Scan a Receipt")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(tc.textPrimary)
                Text("Take a photo or select from your library.\nWe'll extract the details automatically.")
                    .font(.system(size: 14))
                    .foregroundStyle(tc.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    showingCamera = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(tc.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Library")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tc.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(tc.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .onChange(of: selectedPhotoItems) { _, items in
                    Task { await loadPhotos(items) }
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .fullScreenCover(isPresented: $showingCamera) {
            ImagePickerView(sourceType: .camera) { image in
                showingCamera = false
                pickedImages = [image]
                Task { await processImages() }
            } onCancel: {
                showingCamera = false
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Processing View

    @ViewBuilder
    private func processingView(tc: ThemeColors) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(tc.accent)

            Text("Scanning \(pickedImages.count) receipt\(pickedImages.count == 1 ? "" : "s")...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(tc.textPrimary)

            Text("Extracting text with on-device OCR")
                .font(.system(size: 13))
                .foregroundStyle(tc.textSecondary)
        }
    }

    // MARK: - Review View

    @ViewBuilder
    private func reviewView(tc: ThemeColors) -> some View {
        if currentReviewIndex < ocrResults.count {
            let result = ocrResults[currentReviewIndex]
            let fields = result.fields

            ScrollView {
                VStack(spacing: 20) {
                    // Progress indicator for batch
                    if ocrResults.count > 1 {
                        Text("Receipt \(currentReviewIndex + 1) of \(ocrResults.count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(tc.textSecondary)
                    }

                    // Scanned image preview
                    if currentReviewIndex < pickedImages.count {
                        Image(uiImage: pickedImages[currentReviewIndex])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.cardBorder, lineWidth: 1))
                    }

                    // Extracted fields
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Extracted Information")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(tc.textPrimary)

                        if let storeName = fields.storeName {
                            extractedRow("Store", storeName, icon: "bag", tc: tc)
                        }
                        if let date = fields.date {
                            let df = DateFormatter()
                            let _ = df.dateFormat = "MMM d, yyyy"
                            extractedRow("Date", df.string(from: date), icon: "calendar", tc: tc)
                        }
                        if let amount = fields.totalAmount {
                            let currency = fields.currency ?? "USD"
                            extractedRow("Total", "\(currency) \(String(format: "%.2f", amount))", icon: "dollarsign.circle", tc: tc)
                        }
                        if let serial = fields.serialNumber {
                            extractedRow("Serial", serial, icon: "number", tc: tc)
                        }

                        if fields.storeName == nil && fields.date == nil && fields.totalAmount == nil {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(tc.warrantyExpiring)
                                Text("Couldn't extract structured data. You can still create an asset manually with the scanned image attached.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(tc.textSecondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(tc.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.cardBorder, lineWidth: 1))

                    // Raw text preview
                    if !result.rawText.isEmpty {
                        DisclosureGroup {
                            Text(result.rawText)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(tc.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Text("Raw OCR Text")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(tc.textSecondary)
                        }
                        .padding(12)
                        .background(tc.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Actions
                    VStack(spacing: 10) {
                        Button {
                            openAddSheet(from: result)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Asset")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(tc.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if ocrResults.count > 1 && currentReviewIndex < ocrResults.count - 1 {
                            Button {
                                currentReviewIndex += 1
                            } label: {
                                Text("Skip to Next Receipt")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(tc.textSecondary)
                            }
                        }

                        Button {
                            resetState()
                        } label: {
                            Text("Scan Another")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(tc.accent)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
    }

    private func extractedRow(_ label: String, _ value: String, icon: String, tc: ThemeColors) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tc.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(tc.textSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tc.textPrimary)
            }
            Spacer()
        }
    }

    // MARK: - Actions

    private func openAddSheet(from result: OCRResult) {
        let fields = result.fields

        // Save the scanned image as a document
        if currentReviewIndex < pickedImages.count {
            let meta = DocumentStore.shared.saveImage(pickedImages[currentReviewIndex], type: .receipt)
            store.addDocumentMetadata(meta)
            savedDocID = meta.id
        }

        currentPrefill = OCRPrefill(
            name: fields.storeName,
            retailer: fields.storeName,
            date: fields.date,
            price: fields.totalAmount,
            serialNumber: fields.serialNumber
        )
        showingAddSheet = true
    }

    private func advanceOrReset() {
        if currentReviewIndex < ocrResults.count - 1 {
            currentReviewIndex += 1
        } else {
            resetState()
        }
        currentPrefill = nil
        savedDocID = nil
    }

    private func resetState() {
        pickedImages = []
        ocrResults = []
        currentReviewIndex = 0
        isProcessing = false
        selectedPhotoItems = []
        currentPrefill = nil
        savedDocID = nil
    }

    // MARK: - Processing

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        if !images.isEmpty {
            pickedImages = images
            await processImages()
        }
    }

    private func processImages() async {
        await MainActor.run { isProcessing = true }
        let results = await OCREngine.shared.recognizeTexts(from: pickedImages)
        await MainActor.run {
            ocrResults = results
            isProcessing = false
            currentReviewIndex = 0
        }
    }
}
