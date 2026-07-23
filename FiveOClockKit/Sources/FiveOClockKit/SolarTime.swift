import Foundation

/// Offline sunrise/sunset via the classic NOAA/Almanac sunrise equation.
/// Avoids a network round-trip just for two timestamps.
public enum SolarTime {
    public struct Result: Equatable, Sendable {
        public let sunrise: Date?   // nil during polar night
        public let sunset: Date?    // nil during polar day
    }

    static let zenith = 90.833      // official sunrise/sunset (includes refraction)

    public static func events(latitude: Double, longitude: Double,
                              on date: Date) -> Result {
        Result(sunrise: solarEvent(rising: true, latitude: latitude, longitude: longitude, date: date),
               sunset: solarEvent(rising: false, latitude: latitude, longitude: longitude, date: date))
    }

    private static func solarEvent(rising: Bool, latitude: Double, longitude: Double,
                                   date: Date) -> Date? {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let comps = utc.dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year,
              let doy = utc.ordinality(of: .day, in: .year, for: date) else { return nil }

        let lngHour = longitude / 15.0
        let t = Double(doy) + ((rising ? 6.0 : 18.0) - lngHour) / 24.0

        let M = 0.9856 * t - 3.289
        var L = M + 1.916 * sinDeg(M) + 0.020 * sinDeg(2 * M) + 282.634
        L = norm(L, 360)

        var RA = atanDeg(0.91764 * tanDeg(L))
        RA = norm(RA, 360)
        // Put RA in the same quadrant as L.
        let lQuad = (floor(L / 90)) * 90
        let raQuad = (floor(RA / 90)) * 90
        RA = (RA + (lQuad - raQuad)) / 15.0

        let sinDec = 0.39782 * sinDeg(L)
        let cosDec = cos(asin(sinDec))

        let cosH = (cosDeg(zenith) - sinDec * sinDeg(latitude)) / (cosDec * cosDeg(latitude))
        if cosH > 1 { return nil }   // sun never rises
        if cosH < -1 { return nil }  // sun never sets

        let H = (rising ? 360 - acosDeg(cosH) : acosDeg(cosH)) / 15.0
        let T = H + RA - 0.06571 * t - 6.622
        let ut = norm(T - lngHour, 24)

        let midnight = utc.date(from: DateComponents(year: year,
                                                     month: comps.month, day: comps.day))!
        return midnight.addingTimeInterval(ut * 3600)
    }

    // Degree-based trig helpers.
    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func sinDeg(_ d: Double) -> Double { sin(rad(d)) }
    private static func cosDeg(_ d: Double) -> Double { cos(rad(d)) }
    private static func tanDeg(_ d: Double) -> Double { tan(rad(d)) }
    private static func atanDeg(_ x: Double) -> Double { atan(x) * 180 / .pi }
    private static func acosDeg(_ x: Double) -> Double { acos(x) * 180 / .pi }
    private static func norm(_ v: Double, _ range: Double) -> Double {
        let r = v.truncatingRemainder(dividingBy: range)
        return r < 0 ? r + range : r
    }
}
