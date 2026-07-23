import SwiftUI

/// Golden-hour palette — it's always 5 o'clock somewhere, so lean into sunset.
/// Shared by the app and the widget.
public enum Theme {
    /// Background gradient, warmer by day and dusky at night, adapting to color scheme.
    public static func background(isDay: Bool, scheme: ColorScheme) -> LinearGradient {
        let colors: [Color]
        switch (isDay, scheme) {
        case (true, .light):
            colors = [Color(hue: 0.09, saturation: 0.35, brightness: 1.0),
                      Color(hue: 0.03, saturation: 0.55, brightness: 0.98)]
        case (false, .light):
            colors = [Color(hue: 0.62, saturation: 0.30, brightness: 0.75),
                      Color(hue: 0.90, saturation: 0.35, brightness: 0.70)]
        case (true, _):
            colors = [Color(hue: 0.06, saturation: 0.55, brightness: 0.45),
                      Color(hue: 0.02, saturation: 0.65, brightness: 0.28)]
        default:
            colors = [Color(hue: 0.68, saturation: 0.55, brightness: 0.22),
                      Color(hue: 0.90, saturation: 0.45, brightness: 0.14)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    public static let onGradient = Color.white
    public static let onGradientSecondary = Color.white.opacity(0.75)
}
