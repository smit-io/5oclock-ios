import Foundation

/// Shared container so the app and widget read/write the same weather cache.
public enum AppGroup {
    public static let id = "group.com.hyperse.5oclock"

    public static var weatherCacheURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)?
            .appendingPathComponent("weather", isDirectory: true)
    }
}
