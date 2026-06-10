import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var cache: CacheManager
    @EnvironmentObject private var notifications: NotificationManager
    var body: some View { Form { Section("Theme") { Toggle("Light theme", isOn: $theme.isLightMode) }; Section("Notifications") { Toggle("Discover Weekly", isOn: $notifications.discoverWeeklyEnabled); Toggle("Release Radar", isOn: $notifications.releaseRadarEnabled); Button("Enable Notifications") { notifications.enable() } }; Section("Cache") { Text(cache.estimatedSize); Button("Clear Cache") { cache.clear() } } }.scrollContentBackground(.hidden).background(Color.black).foregroundStyle(.white).navigationTitle("Settings") }
}

typealias ThemeSettingsView = SettingsView
typealias NotificationSettingsView = SettingsView
typealias CacheSettingsView = SettingsView
