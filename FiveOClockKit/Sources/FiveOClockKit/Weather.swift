import Foundation

/// Current conditions for a city, from Open-Meteo (free, no API key).
public struct Weather: Codable, Hashable, Sendable {
    public let temperatureC: Double
    public let weatherCode: Int
    public let isDay: Bool
    public let fetchedAt: Date

    public var temperatureF: Double { temperatureC * 9 / 5 + 32 }

    /// WMO weather-code → SF Symbol, day/night aware.
    public var symbolName: String {
        switch weatherCode {
        case 0:        return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2:     return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:        return "cloud.fill"
        case 45, 48:   return "cloud.fog.fill"
        case 51...57:  return "cloud.drizzle.fill"
        case 61...67:  return "cloud.rain.fill"
        case 71...77:  return "cloud.snow.fill"
        case 80...82:  return "cloud.heavyrain.fill"
        case 85, 86:   return "cloud.snow.fill"
        case 95:       return "cloud.bolt.fill"
        case 96, 99:   return "cloud.bolt.rain.fill"
        default:       return "cloud.fill"
        }
    }

    public var summary: String {
        switch weatherCode {
        case 0:        return "Clear"
        case 1, 2:     return "Partly cloudy"
        case 3:        return "Overcast"
        case 45, 48:   return "Fog"
        case 51...57:  return "Drizzle"
        case 61...67:  return "Rain"
        case 71...77:  return "Snow"
        case 80...82:  return "Showers"
        case 85, 86:   return "Snow showers"
        case 95, 96, 99: return "Thunderstorm"
        default:       return "—"
        }
    }
}

/// Fetches current weather with a lightweight on-disk cache keyed by location+hour.
/// Cache dir defaults to the caller's caches; pass an App Group container to share
/// results between the app and its widget (respects the widget refresh budget).
public actor WeatherService {
    private let session: URLSession
    private let cacheDirectory: URL
    private let calendar: Calendar

    public init(cacheDirectory: URL? = nil, session: URLSession = .shared) {
        self.session = session
        self.cacheDirectory = cacheDirectory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("weather", isDirectory: true)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        self.calendar = cal
        try? FileManager.default.createDirectory(at: self.cacheDirectory,
                                                 withIntermediateDirectories: true)
    }

    public func weather(for city: City, now: Date = Date()) async -> Weather? {
        let key = cacheKey(latitude: city.latitude, longitude: city.longitude, now: now)
        if let cached = readCache(key) { return cached }
        guard let fresh = await fetch(latitude: city.latitude, longitude: city.longitude,
                                      now: now) else {
            return readStale(latitude: city.latitude, longitude: city.longitude)
        }
        writeCache(key, fresh)
        return fresh
    }

    // MARK: Network

    private func fetch(latitude: Double, longitude: Double, now: Date) async -> Weather? {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "current", value: "temperature_2m,weather_code,is_day")
        ]
        guard let url = comps.url,
              let (data, resp) = try? await session.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        struct Payload: Decodable {
            struct Current: Decodable {
                let temperature_2m: Double
                let weather_code: Int
                let is_day: Int
            }
            let current: Current
        }
        guard let p = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
        return Weather(temperatureC: p.current.temperature_2m,
                       weatherCode: p.current.weather_code,
                       isDay: p.current.is_day == 1,
                       fetchedAt: now)
    }

    // MARK: Cache (one file per location+hour; plus a "latest" for offline fallback)

    private func cacheKey(latitude: Double, longitude: Double, now: Date) -> String {
        let hour = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        return String(format: "%.2f_%.2f_%04d%02d%02d%02d", latitude, longitude,
                      hour.year ?? 0, hour.month ?? 0, hour.day ?? 0, hour.hour ?? 0)
    }

    private func locationStub(latitude: Double, longitude: Double) -> String {
        String(format: "%.2f_%.2f", latitude, longitude)
    }

    private func url(_ key: String) -> URL {
        cacheDirectory.appendingPathComponent(key + ".json")
    }

    private func readCache(_ key: String) -> Weather? {
        guard let data = try? Data(contentsOf: url(key)) else { return nil }
        return try? JSONDecoder().decode(Weather.self, from: data)
    }

    private func writeCache(_ key: String, _ weather: Weather) {
        guard let data = try? JSONEncoder().encode(weather) else { return }
        try? data.write(to: url(key))
    }

    /// Last successful reading for this location, regardless of age (offline path).
    private func readStale(latitude: Double, longitude: Double) -> Weather? {
        let stub = locationStub(latitude: latitude, longitude: longitude)
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory,
                                                                  includingPropertiesForKeys: nil)) ?? []
        let match = files.filter { $0.lastPathComponent.hasPrefix(stub) }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }.first
        guard let match, let data = try? Data(contentsOf: match) else { return nil }
        return try? JSONDecoder().decode(Weather.self, from: data)
    }
}
