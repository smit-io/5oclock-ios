import Testing
import Foundation
@testable import FiveOClockKit

private func utc(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
}

@Suite struct TimeMatcherTests {
    @Test func localTimeHandlesStandardOffset() {
        // New York in January = EST (UTC-5). 12:00 UTC -> 07:00 local.
        let (h, m) = TimeMatcher.localHourMinute("America/New_York", at: utc(2026, 1, 15, 12, 0))!
        #expect(h == 7 && m == 0)
    }

    @Test func localTimeHandlesDST() {
        // Same zone in July = EDT (UTC-4). 12:00 UTC -> 08:00 local. Proves DST is applied.
        let (h, m) = TimeMatcher.localHourMinute("America/New_York", at: utc(2026, 7, 15, 12, 0))!
        #expect(h == 8 && m == 0)
    }

    @Test func tightWindowMatchesKolkata() {
        // India is UTC+5:30 (no DST). Local 17:00 occurs at 11:30 UTC.
        // Match over the dataset's own zones so we get "Asia/Kolkata", not the alias.
        let match = TimeMatcher.match(at: utc(2026, 3, 15, 11, 30),
                                      zones: CityStore().availableZones)
        #expect(match.zones.contains("Asia/Kolkata"))
        #expect(match.usedFallback == false)
    }

    @Test func citiesAtLoadsFeaturedCities() {
        // 11:30 UTC -> India at 5 PM. Delhi/Mumbai should surface with cities.
        let result = CityStore().citiesAt(utc(2026, 3, 15, 11, 30))
        #expect(!result.cities.isEmpty)
        #expect(result.cities.contains { $0.countryCode == "IN" })
    }

    @Test func alwaysMatchesSomeZone() {
        // The fallback guarantee: no minute of the day leaves the app blank.
        for minute in stride(from: 0, to: 24 * 60, by: 1) {
            let date = utc(2026, 3, 15, 0, 0).addingTimeInterval(Double(minute) * 60)
            #expect(!TimeMatcher.match(at: date).zones.isEmpty, "empty at minute \(minute)")
        }
    }

    @Test func fallbackIsSometimesNeeded() {
        var tight = 0, fallback = 0
        for minute in stride(from: 0, to: 24 * 60, by: 1) {
            let date = utc(2026, 3, 15, 0, 0).addingTimeInterval(Double(minute) * 60)
            if TimeMatcher.match(at: date).usedFallback { fallback += 1 } else { tight += 1 }
        }
        #expect(tight > 0 && fallback > 0)  // both paths exercised over a day
    }
}

@Suite struct CityStoreTests {
    @Test func loadsCitiesForZoneSortedByPopulation() {
        let cities = CityStore().cities(inZones: ["Europe/Paris"])
        #expect(cities.first?.name == "Paris")
        #expect(cities.first?.countryCode == "FR")
        // sorted descending
        #expect(zip(cities, cities.dropFirst()).allSatisfy { $0.population >= $1.population })
    }

    @Test func missingZoneIsSkipped() {
        #expect(CityStore().cities(inZones: ["Not/AZone"]).isEmpty)
    }
}

@Suite struct SolarTimeTests {
    @Test func londonSummerSolstice() {
        // London 2026-06-21: sunrise ~04:43 UTC, sunset ~20:21 UTC.
        let r = SolarTime.events(latitude: 51.5074, longitude: -0.1278, on: utc(2026, 6, 21, 12, 0))
        let sr = try! #require(r.sunrise), ss = try! #require(r.sunset)
        #expect(sr < ss)
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
        #expect((3...6).contains(cal.component(.hour, from: sr)))
        #expect((19...21).contains(cal.component(.hour, from: ss)))
    }
}
