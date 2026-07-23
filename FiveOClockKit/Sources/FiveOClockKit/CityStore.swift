import Foundation

/// Loads cities for specific timezones from the bundled per-zone JSON files.
///
/// The dataset is split into one file per IANA zone (`Europe~Paris.json`, …) so a
/// tick only decodes the 1–3 files it needs — keeps the widget well under its
/// ~30 MB memory limit instead of holding all ~25k cities.
public struct CityStore: Sendable {
    let bundle: Bundle
    static let subdirectory = "cities"

    public init(bundle: Bundle? = nil) {
        self.bundle = bundle ?? .module
    }

    /// IANA zones the dataset actually contains, derived from the bundled files.
    /// Using this as the matcher's input avoids alias drift (e.g. the system lists
    /// `Asia/Calcutta` while GeoNames uses `Asia/Kolkata`).
    public var availableZones: [String] {
        let urls = bundle.urls(forResourcesWithExtension: "json",
                               subdirectory: Self.subdirectory) ?? []
        return urls.map {
            $0.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "~", with: "/")
        }
    }

    /// GeoNames zone identifiers contain "/", illegal in filenames → mapped to "~".
    static func fileName(for zone: String) -> String {
        zone.replacingOccurrences(of: "/", with: "~") + ".json"
    }

    /// Cities in the given zones, highest population first. Missing files are skipped.
    public func cities(inZones zones: [String]) -> [City] {
        let decoder = JSONDecoder()
        var result: [City] = []
        for zone in zones {
            let file = Self.fileName(for: zone)
            guard let url = bundle.url(forResource: file, withExtension: nil,
                                       subdirectory: Self.subdirectory),
                  let data = try? Data(contentsOf: url),
                  let cities = try? decoder.decode([City].self, from: data) else { continue }
            result.append(contentsOf: cities)
        }
        return result.sorted { $0.population > $1.population }
    }

    /// Convenience: match the clock over the dataset's zones, then load the cities.
    public func citiesAt(_ date: Date = Date()) -> (match: TimeMatch, cities: [City]) {
        let match = TimeMatcher.match(at: date, zones: availableZones)
        return (match, cities(inZones: match.zones))
    }
}
