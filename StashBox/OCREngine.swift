import Foundation
import Vision
import UIKit

// MARK: - OCR Result

struct OCRResult {
    let rawText: String
    let fields: ParsedReceiptFields
}

struct ParsedReceiptFields {
    var storeName: String?
    var date: Date?
    var totalAmount: Double?
    var currency: String?
    var serialNumber: String?
    var lineItems: [(name: String, price: Double?)]

    init() {
        lineItems = []
    }
}

// MARK: - OCR Engine (Apple Vision, fully on-device)

class OCREngine {
    static let shared = OCREngine()

    func recognizeText(from image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else {
            return OCRResult(rawText: "", fields: ParsedReceiptFields())
        }

        let observations = await performRecognition(cgImage: cgImage)
        let sortedTexts = observations
            .sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
            .compactMap { $0.topCandidates(1).first?.string }

        let rawText = sortedTexts.joined(separator: "\n")
        let fields = extractFields(from: rawText, lines: sortedTexts)

        return OCRResult(rawText: rawText, fields: fields)
    }

    func recognizeTexts(from images: [UIImage]) async -> [OCRResult] {
        await withTaskGroup(of: (Int, OCRResult).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let result = await self.recognizeText(from: image)
                    return (index, result)
                }
            }
            var results = [(Int, OCRResult)]()
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    // MARK: - Vision recognition

    private func performRecognition(cgImage: CGImage) async -> [VNRecognizedTextObservation] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: observations)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Field extraction

    private func extractFields(from rawText: String, lines: [String]) -> ParsedReceiptFields {
        var fields = ParsedReceiptFields()

        // Store name: typically the first non-empty line
        if let first = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            fields.storeName = first.trimmingCharacters(in: .whitespaces)
        }

        // Date extraction
        fields.date = extractDate(from: rawText)

        // Total amount
        fields.totalAmount = extractTotal(from: rawText)

        // Currency
        fields.currency = extractCurrency(from: rawText)

        // Serial number
        fields.serialNumber = extractSerialNumber(from: rawText)

        return fields
    }

    private func extractDate(from text: String) -> Date? {
        let patterns = [
            // MM/DD/YYYY or DD/MM/YYYY
            #"(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})"#,
            // Mon DD, YYYY
            #"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\.?\s+(\d{1,2}),?\s*(\d{4})"#,
            // DD Mon YYYY
            #"(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\.?\s+(\d{4})"#,
        ]

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let dateStr = String(text[match])
                for fmt in ["MM/dd/yyyy", "MM-dd-yyyy", "MM.dd.yyyy",
                            "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy",
                            "MM/dd/yy", "dd/MM/yy",
                            "MMM d, yyyy", "MMM dd, yyyy",
                            "MMMM d, yyyy", "MMMM dd, yyyy",
                            "d MMM yyyy", "dd MMM yyyy"] {
                    df.dateFormat = fmt
                    if let d = df.date(from: dateStr) { return d }
                }
            }
        }
        return nil
    }

    private func extractTotal(from text: String) -> Double? {
        let pattern = #"(?i)(?:total|amount|grand\s*total|amount\s*due|balance\s*due|net\s*amount)[:\s]*[$\u20B9\u20AC\u00A3]?\s*([\d,]+\.?\d*)"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            let matched = String(text[match])
            let numberPattern = #"[\d,]+\.?\d*$"#
            if let numMatch = matched.range(of: numberPattern, options: .regularExpression) {
                let numStr = String(matched[numMatch]).replacingOccurrences(of: ",", with: "")
                return Double(numStr)
            }
        }
        return nil
    }

    private func extractCurrency(from text: String) -> String? {
        if text.contains("$") { return "USD" }
        if text.contains("\u{20B9}") { return "INR" }
        if text.contains("\u{20AC}") { return "EUR" }
        if text.contains("\u{00A3}") { return "GBP" }
        return nil
    }

    private func extractSerialNumber(from text: String) -> String? {
        let pattern = #"(?i)(?:s/n|serial|sn|serial\s*(?:no|number|#))[:\s]*([A-Za-z0-9\-]{4,})"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            let matched = String(text[match])
            let valuePattern = #"[A-Za-z0-9\-]{4,}$"#
            if let valMatch = matched.range(of: valuePattern, options: .regularExpression) {
                return String(matched[valMatch])
            }
        }
        return nil
    }
}
