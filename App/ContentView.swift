import SwiftUI
import FiveOClockKit

struct ContentView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var model = AppModel()

    private var isDay: Bool { model.currentWeather?.isDay ?? true }

    var body: some View {
        ZStack {
            Theme.background(isDay: isDay, scheme: scheme)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: isDay)

            if let city = model.current {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 0)
                    CityCardView(city: city,
                                 weather: model.currentWeather,
                                 distance: model.distanceString(for: city),
                                 sun: model.sunEvents(for: city))
                        .id(city.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)))
                    Spacer(minLength: 0)
                    footer
                }
                .padding()
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: city.id)
            } else {
                ProgressView().tint(Theme.onGradient)
            }
        }
        .preferredColorScheme(nil)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { model.advance() } }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("It's 5 o'clock in")
                .font(.headline.weight(.medium))
                .foregroundStyle(Theme.onGradientSecondary)
            if model.match?.usedFallback == true {
                Text("(somewhere between 5 and 6 PM)")
                    .font(.caption)
                    .foregroundStyle(Theme.onGradientSecondary)
            }
        }
        .padding(.top)
    }

    private var footer: some View {
        Text("\(model.index + 1) of \(model.cities.count) cities · tap for next")
            .font(.footnote)
            .foregroundStyle(Theme.onGradientSecondary)
            .padding(.bottom, 8)
    }
}

#Preview {
    ContentView()
}
