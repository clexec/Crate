import SwiftUI

@main
struct MonkApp: App {
    @StateObject private var persistence = PersistenceController()
    @StateObject private var theme = ThemeManager()
    @StateObject private var cache = CacheManager()
    @StateObject private var notifications = NotificationManager()
    @StateObject private var auth: AuthenticationManager
    @StateObject private var player: PlayerManager
    @StateObject private var library: LibraryManager

    init() {
        let persistence = PersistenceController()
        _persistence = StateObject(wrappedValue: persistence)
        _auth = StateObject(wrappedValue: AuthenticationManager(persistence: persistence))
        _player = StateObject(wrappedValue: PlayerManager(persistence: persistence))
        _library = StateObject(wrappedValue: LibraryManager(persistence: persistence))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(persistence)
                .environmentObject(auth)
                .environmentObject(player)
                .environmentObject(library)
                .environmentObject(theme)
                .environmentObject(cache)
                .environmentObject(notifications)
        }
    }
}
