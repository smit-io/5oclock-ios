import Foundation
import FiveOClockKit

/// Drives the rotating carousel of "it's 5 o'clock here" cities.
@MainActor @Observable
final class AppModel {
    private let store = CityStore()
    private let weather = WeatherService(cacheDirectory: AppGroup.weatherCacheURL)
    let location = LocationManager()

    private(set) var match: TimeMatch?
    private(set) var cities: [City] = []
    private(set) var index = 0
    private(set) var weatherByCity: [Int: Weather] = [:]

    private var loop: Task<Void, Never>?
    private let rotateEvery: Duration = .seconds(6)

    var current: City? { cities.indices.contains(index) ? cities[index] : nil }
    var currentWeather: Weather? { current.flatMap { weatherByCity[$0.id] } }

    func start() {
        location.request()
        refresh()
        loop?.cancel()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: self?.rotateEvery ?? .seconds(6))
                self?.tick()
            }
        }
    }

    func stop() { loop?.cancel() }

    /// Re-run the clock match; keep showing the same city if it still qualifies.
    func refresh(now: Date = Date()) {
        let result = store.citiesAt(now)
        let previousID = current?.id
        match = result.match
        cities = result.cities
        index = cities.firstIndex { $0.id == previousID } ?? 0
        prefetchWeather()
    }

    private func tick() {
        // If the 5 o'clock window has moved to new zones, re-match; else just rotate.
        let live = TimeMatcher.match(at: Date(), zones: store.availableZones)
        if live.zones != match?.zones {
            refresh()
        } else {
            advance()
        }
    }

    func advance() {
        guard !cities.isEmpty else { return }
        index = (index + 1) % cities.count
        prefetchWeather()
    }

    /// Fetch the current city's weather and warm the next one, so rotation usually
    /// lands with weather already in hand instead of popping in a beat later.
    private func prefetchWeather() {
        fetchWeather(for: current)
        if !cities.isEmpty {
            fetchWeather(for: cities[(index + 1) % cities.count])
        }
    }

    private func fetchWeather(for city: City?) {
        guard let city, weatherByCity[city.id] == nil else { return }
        Task { [weak self] in
            guard let w = await self?.weather.weather(for: city) else { return }
            self?.weatherByCity[city.id] = w
        }
    }

    func distanceString(for city: City) -> String? {
        guard let c = location.coordinate else { return nil }
        return Format.distance(kilometers: city.distanceKm(fromLatitude: c.latitude,
                                                            longitude: c.longitude))
    }

    func sunEvents(for city: City) -> SolarTime.Result {
        SolarTime.events(latitude: city.latitude, longitude: city.longitude, on: Date())
    }
}
