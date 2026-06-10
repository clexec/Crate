import Combine
import Foundation
import UserNotifications

final class NotificationService {
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }
}

@MainActor
final class NotificationManager: ObservableObject {
    @Published var releaseRadarEnabled = true
    @Published var discoverWeeklyEnabled = true
    private let service = NotificationService()
    func enable() { Task { _ = await service.requestAuthorization() } }
}
