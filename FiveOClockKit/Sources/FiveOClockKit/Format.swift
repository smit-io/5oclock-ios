import Foundation

public enum Format {
    /// "2.1M", "845K" — compact population.
    public static func population(_ n: Int) -> String {
        n.formatted(.number.notation(.compactName))
    }

    /// Distance in the locale's preferred units, e.g. "5,400 km" / "3,355 mi".
    public static func distance(kilometers: Double) -> String {
        let usesMetric = Locale.current.measurementSystem == .metric
        let value = usesMetric ? kilometers : kilometers * 0.621371
        let unit = usesMetric ? "km" : "mi"
        return "\(value.formatted(.number.precision(.fractionLength(0)))) \(unit)"
    }
}

public extension City {
    /// The city's wall-clock time at `date`, e.g. "5:12 PM".
    func localTime(at date: Date = Date()) -> String {
        var f = Date.FormatStyle(date: .omitted, time: .shortened)
        if let tz = timeZone { f.timeZone = tz }
        return date.formatted(f)
    }

    /// Great-circle distance from a coordinate, in kilometers.
    func distanceKm(fromLatitude lat: Double, longitude lon: Double) -> Double {
        let r = 6371.0
        let dLat = (latitude - lat) * .pi / 180
        let dLon = (longitude - lon) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat * .pi / 180) * cos(latitude * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
