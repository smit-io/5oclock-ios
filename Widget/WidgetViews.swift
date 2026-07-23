import WidgetKit
import SwiftUI
import FiveOClockKit

struct FiveOClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FiveOClockEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            if let hero = entry.hero {
                Text("5PM in \(hero.name)")
            } else {
                Text("5 O'Clock")
            }
        case .accessoryRectangular:
            accessoryRectangular
        case .systemSmall:
            small
        default:
            medium
        }
    }

    @ViewBuilder private var accessoryRectangular: some View {
        if let hero = entry.hero {
            VStack(alignment: .leading, spacing: 2) {
                Text("It's 5 o'clock in").font(.caption2)
                Text(hero.name).font(.headline)
                Text(hero.countryName).font(.caption2)
            }
        }
    }

    @ViewBuilder private var small: some View {
        if let hero = entry.hero {
            VStack(alignment: .leading, spacing: 4) {
                Text("It's 5 o'clock in")
                    .font(.caption2).foregroundStyle(Theme.onGradientSecondary)
                Spacer(minLength: 0)
                Text(hero.name)
                    .font(.title2.weight(.bold)).foregroundStyle(Theme.onGradient)
                    .minimumScaleFactor(0.6).lineLimit(2)
                Text(hero.countryName)
                    .font(.caption).foregroundStyle(Theme.onGradientSecondary)
                if let w = entry.weather {
                    Label("\(Int(w.temperatureC.rounded()))°C", systemImage: w.symbolName)
                        .font(.caption).foregroundStyle(Theme.onGradient)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private var medium: some View {
        if let hero = entry.hero {
            VStack(alignment: .leading, spacing: 6) {
                Text("It's 5 o'clock in")
                    .font(.caption).foregroundStyle(Theme.onGradientSecondary)
                HStack(alignment: .firstTextBaseline) {
                    Text(hero.name)
                        .font(.title.weight(.bold)).foregroundStyle(Theme.onGradient)
                        .minimumScaleFactor(0.6).lineLimit(1)
                    Spacer()
                    if let w = entry.weather {
                        Label("\(Int(w.temperatureC.rounded()))°C", systemImage: w.symbolName)
                            .font(.headline).foregroundStyle(Theme.onGradient)
                    }
                }
                Text([hero.admin1, hero.countryName].compactMap { $0 }.joined(separator: ", "))
                    .font(.subheadline).foregroundStyle(Theme.onGradientSecondary)
                Spacer(minLength: 0)
                if entry.cities.count > 1 {
                    Text("also 5 o'clock: " + entry.cities.dropFirst()
                        .prefix(3).map(\.name).joined(separator: ", "))
                        .font(.caption).foregroundStyle(Theme.onGradientSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
