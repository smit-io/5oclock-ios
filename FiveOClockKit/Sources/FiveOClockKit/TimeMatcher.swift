import Foundation

/// Result of asking "where is it 5 PM right now".
public struct TimeMatch: Equatable, Sendable {
    /// IANA zone identifiers whose local time falls in the target window.
    public let zones: [String]
    /// True when the tight 5:00–5:30 window was empty and we widened to 5:00–6:00.
    public let usedFallback: Bool
}

/// Pure timezone math — the heart of the app. No I/O, fully testable.
///
/// At any instant, a zone matches when its *local* clock reads 5:00–5:30 PM.
/// Offsets are ~1h apart, so that 30-min window leaves a 30-min gap each hour
/// where nothing matches; `usedFallback` widens to a full hour to guarantee a hit.
public enum TimeMatcher {
    static let targetHour = 17          // 5 PM
    static let tightWindowMinutes = 30  // 5:00–5:30
    static let fallbackWindowMinutes = 60

    /// Zones whose local time is in the target window at `date`.
    public static func match(at date: Date,
                             zones: [String] = TimeZone.knownTimeZoneIdentifiers) -> TimeMatch {
        let tight = zones.filter { inWindow($0, at: date, minutes: tightWindowMinutes) }
        if !tight.isEmpty {
            return TimeMatch(zones: tight.sorted(), usedFallback: false)
        }
        let wide = zones.filter { inWindow($0, at: date, minutes: fallbackWindowMinutes) }
        return TimeMatch(zones: wide.sorted(), usedFallback: true)
    }

    /// Local hour/minute for `zone` at `date`, DST-correct via `secondsFromGMT(for:)`.
    static func localHourMinute(_ zone: String, at date: Date) -> (hour: Int, minute: Int)? {
        guard let tz = TimeZone(identifier: zone) else { return nil }
        let local = date.timeIntervalSince1970 + Double(tz.secondsFromGMT(for: date))
        let totalMinutes = Int((local / 60).rounded(.down))
        let minutesOfDay = ((totalMinutes % 1440) + 1440) % 1440  // handle negatives
        return (minutesOfDay / 60, minutesOfDay % 60)
    }

    static func inWindow(_ zone: String, at date: Date, minutes: Int) -> Bool {
        guard let (h, m) = localHourMinute(zone, at: date) else { return false }
        return h == targetHour && m < minutes
    }
}
