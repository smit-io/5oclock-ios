import Foundation

/// A city from the bundled GeoNames dataset. One record per notable city.
public struct City: Codable, Hashable, Identifiable, Sendable {
    public let id: Int          // GeoNames geonameid
    public let name: String
    public let countryCode: String   // ISO-3166 alpha-2, e.g. "FR"
    public let admin1: String?       // state/region name where available
    public let latitude: Double
    public let longitude: Double
    public let population: Int
    public let timeZoneID: String    // IANA identifier, e.g. "Europe/Paris"

    public init(id: Int, name: String, countryCode: String, admin1: String?,
                latitude: Double, longitude: Double, population: Int, timeZoneID: String) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.admin1 = admin1
        self.latitude = latitude
        self.longitude = longitude
        self.population = population
        self.timeZoneID = timeZoneID
    }

    /// Localized country name, e.g. "France". Falls back to the raw code.
    public var countryName: String {
        Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode
    }

    public var timeZone: TimeZone? { TimeZone(identifier: timeZoneID) }

    public var coordinate: (latitude: Double, longitude: Double) {
        (latitude, longitude)
    }
}
