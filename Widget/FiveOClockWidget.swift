@preconcurrency import WidgetKit
import SwiftUI
import FiveOClockKit

struct FiveOClockEntry: TimelineEntry, Sendable {
    let date: Date
    let cities: [City]        // in-window cities, largest first
    let weather: Weather?     // for the hero city, when available
    let usedFallback: Bool

    var hero: City? { cities.first }
}

struct Provider: TimelineProvider {
    private let store = CityStore()

    func placeholder(in context: Context) -> FiveOClockEntry {
        entry(at: Date(), weather: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (FiveOClockEntry) -> Void) {
        completion(entry(at: Date(), weather: nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FiveOClockEntry>) -> Void) {
        // WidgetKit's completion is safe to call once from any context; the escape
        // hatch lets us await weather before delivering the timeline.
        nonisolated(unsafe) let deliver = completion
        Task {
            let now = Date()
            let dates = [now] + boundaries(after: now, count: 12)

            // Fetch weather only for the current hero (cheap, respects refresh budget).
            var currentWeather: Weather?
            if let hero = entry(at: now, weather: nil).hero {
                let service = WeatherService(cacheDirectory: AppGroup.weatherCacheURL)
                currentWeather = await service.weather(for: hero)
            }

            let entries = dates.enumerated().map { i, date in
                entry(at: date, weather: i == 0 ? currentWeather : nil)
            }
            deliver(Timeline(entries: entries, policy: .atEnd))
        }
    }

    private func entry(at date: Date, weather: Weather?) -> FiveOClockEntry {
        let result = store.citiesAt(date)
        return FiveOClockEntry(date: date,
                               cities: Array(result.cities.prefix(5)),
                               weather: weather,
                               usedFallback: result.match.usedFallback)
    }

    /// Next N half-hour marks (:00 / :30) — where the featured zone changes.
    private func boundaries(after date: Date, count: Int) -> [Date] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = comps.minute ?? 0
        var next = cal.date(from: comps)!.addingTimeInterval(Double(minute < 30 ? 30 - minute : 60 - minute) * 60)
        var result: [Date] = []
        for _ in 0..<count {
            result.append(next)
            next = next.addingTimeInterval(30 * 60)
        }
        return result
    }
}

struct FiveOClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FiveOClockWidget", provider: Provider()) { entry in
            FiveOClockWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Theme.background(isDay: entry.weather?.isDay ?? true, scheme: .light)
                }
        }
        .configurationDisplayName("5 O'Clock")
        .description("See where in the world it's 5 PM right now.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryInline])
    }
}
