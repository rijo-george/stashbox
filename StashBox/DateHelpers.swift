import Foundation

// MARK: - Flexible ISO 8601 parser (handles Python isoformat, full ISO8601, date-only)

enum ISO8601Flexible {
    private static let fullFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let basicFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func date(from string: String) -> Date? {
        let cleaned = string.count > 26 ? String(string.prefix(26)) : string
        if let d = fullFormatter.date(from: cleaned + "+00:00") { return d }
        if let d = fullFormatter.date(from: string + "+00:00") { return d }
        if let d = basicFormatter.date(from: string + "+00:00") { return d }
        if let d = basicFormatter.date(from: string) { return d }
        if let d = dateOnly.date(from: string) { return d }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"] {
            df.dateFormat = fmt
            if let d = df.date(from: string) { return d }
        }
        return nil
    }
}

// MARK: - Date formatting helpers

func pythonISO(_ date: Date = Date()) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
    return f.string(from: date)
}

func dateOnlyISO(_ date: Date = Date()) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

func displayDate(_ isoString: String) -> String {
    guard let d = ISO8601Flexible.date(from: isoString) else { return isoString }
    let fmt = DateFormatter()
    fmt.dateFormat = "MMM d, yyyy"
    return fmt.string(from: d)
}

func shortDate(_ isoString: String) -> String {
    guard let d = ISO8601Flexible.date(from: isoString) else { return isoString }
    let fmt = DateFormatter()
    fmt.dateFormat = "MMM d"
    return fmt.string(from: d)
}

func relativeDate(_ isoString: String) -> String {
    guard let d = ISO8601Flexible.date(from: isoString) else { return isoString }
    let days = Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? 0
    if days == 0 { return "Today" }
    if days == 1 { return "Yesterday" }
    if days < 30 { return "\(days) days ago" }
    let months = days / 30
    if months < 12 { return "\(months) month\(months == 1 ? "" : "s") ago" }
    let years = months / 12
    return "\(years) year\(years == 1 ? "" : "s") ago"
}

func relativeFuture(_ isoString: String) -> String {
    guard let d = ISO8601Flexible.date(from: isoString) else { return isoString }
    let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
    if days < 0 { return "Expired" }
    if days == 0 { return "Today" }
    if days == 1 { return "Tomorrow" }
    if days < 30 { return "in \(days) days" }
    let months = days / 30
    if months < 12 { return "in \(months) month\(months == 1 ? "" : "s")" }
    let years = months / 12
    return "in \(years) year\(years == 1 ? "" : "s")"
}

func daysBetween(_ from: String, _ to: String) -> Int? {
    guard let d1 = ISO8601Flexible.date(from: from),
          let d2 = ISO8601Flexible.date(from: to) else { return nil }
    return Calendar.current.dateComponents([.day], from: d1, to: d2).day
}
