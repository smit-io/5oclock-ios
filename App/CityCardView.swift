import SwiftUI
import FiveOClockKit

struct CityCardView: View {
    let city: City
    let weather: Weather?
    let distance: String?
    let sun: SolarTime.Result

    var body: some View {
        VStack(spacing: 20) {
            // City + country
            VStack(spacing: 6) {
                Text(city.name)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.onGradient)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                Text([city.admin1, city.countryName].compactMap { $0 }.joined(separator: ", "))
                    .font(.title3)
                    .foregroundStyle(Theme.onGradientSecondary)
            }

            // Live local clock — ticks every second.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(city.localTime(at: context.date))
                    .font(.system(size: 60, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.onGradient)
                    .contentTransition(.numericText())
            }

            // Weather — reserve the slot and cross-fade so it doesn't pop the layout.
            ZStack {
                if let weather {
                    HStack(spacing: 10) {
                        Image(systemName: weather.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.title)
                        Text("\(Int(weather.temperatureC.rounded()))°C · \(weather.summary)")
                            .font(.title3.weight(.medium))
                    }
                    .foregroundStyle(Theme.onGradient)
                    .transition(.opacity)
                } else {
                    Image(systemName: "cloud.fill")
                        .font(.title)
                        .foregroundStyle(Theme.onGradientSecondary.opacity(0.4))
                        .transition(.opacity)
                }
            }
            .frame(height: 34)
            .animation(.easeInOut(duration: 0.35), value: weather)

            // Fact chips
            HStack(spacing: 10) {
                Chip(icon: "person.3.fill", text: Format.population(city.population))
                if let distance {
                    Chip(icon: "location.fill", text: distance)
                }
            }
            HStack(spacing: 10) {
                if let sunrise = sun.sunrise {
                    Chip(icon: "sunrise.fill", text: timeString(sunrise))
                }
                if let sunset = sun.sunset {
                    Chip(icon: "sunset.fill", text: timeString(sunset))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
    }

    /// Sun event shown in the *city's* local time.
    private func timeString(_ date: Date) -> String {
        var f = Date.FormatStyle(date: .omitted, time: .shortened)
        if let tz = city.timeZone { f.timeZone = tz }
        return date.formatted(f)
    }
}

private struct Chip: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.onGradient)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white.opacity(0.15), in: Capsule())
    }
}
