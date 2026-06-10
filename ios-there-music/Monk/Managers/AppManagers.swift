import Combine
import SwiftUI

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var errorMessage: String?
    private let persistence: PersistenceController
    private lazy var emailService = EmailAuthService(persistence: persistence)
    private let googleService = GoogleSignInService()

    init(persistence: PersistenceController) {
        self.persistence = persistence
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }

    func signIn(email: String, password: String) async {
        do { setUser(try await emailService.signIn(email: email, password: password)) } catch { errorMessage = error.localizedDescription }
    }

    func register(email: String, password: String, displayName: String) async {
        do { setUser(try await emailService.register(email: email, password: password, displayName: displayName)) } catch { errorMessage = error.localizedDescription }
    }

    func signInWithApple() { setUser(AppleSignInService().makeUser(email: nil)) }
    func signInWithGoogle() async { do { setUser(try await googleService.signIn()) } catch { errorMessage = error.localizedDescription } }
    func signOut() { currentUser = nil; UserDefaults.standard.removeObject(forKey: "currentUser") }

    private func setUser(_ user: User) {
        currentUser = user
        UserDefaults.standard.set(try? JSONEncoder().encode(user), forKey: "currentUser")
    }
}

@MainActor
final class PlayerManager: ObservableObject {
    @Published var currentTrack: Track?
    @Published var queue: [Track] = []
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffleEnabled = false
    let audio = AudioPlayerService()
    private let persistence: PersistenceController
    // Forward audio state changes so every view observing PlayerManager re-renders on time tick
    private var audioCancellable: AnyCancellable?

    init(persistence: PersistenceController) {
        self.persistence = persistence
        AudioSessionManager().configure()
        audioCancellable = audio.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    func play(_ track: Track, queue: [Track] = []) {
        currentTrack = track
        self.queue = queue
        persistence.addRecentlyPlayed(track)
        // Полные треки из YM-API / YouTubeKit разрешаются лениво перед воспроизведением.
        Task { [weak self] in
            guard let self else { return }
            var resolved = track
            if resolved.streamURL == nil {
                resolved.streamURL = try? await MusicSourceProvider.shared.resolveStreamURL(for: track)
            }
            guard resolved.streamURL != nil, self.currentTrack?.id == track.id else { return }
            self.currentTrack = resolved
            self.audio.play(track: resolved)
        }
    }

    func toggle() { audio.toggle() }

    func next() {
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        play(next, queue: queue)
    }

    func previous() { audio.seek(to: 0) }
    func toggleShuffle() { isShuffleEnabled.toggle() }
    func cycleRepeat() { repeatMode = repeatMode == .off ? .all : repeatMode == .all ? .one : .off }
}

@MainActor
final class LibraryManager: ObservableObject {
    @Published var playlists: [Playlist] = []
    private let persistence: PersistenceController
    init(persistence: PersistenceController) { self.persistence = persistence }
    var likedTracks: [Track] { persistence.likedTracks }
    func toggleLike(_ track: Track) { persistence.toggleLike(track) }
    func isLiked(_ track: Track) -> Bool { persistence.likedTracks.contains { $0.id == track.id } }
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published var isLightMode: Bool { didSet { UserDefaults.standard.set(isLightMode, forKey: "isLightMode") } }
    init() { isLightMode = UserDefaults.standard.bool(forKey: "isLightMode") }
}

final class QueueManager: ObservableObject {}
final class UserDefaultsManager {}
final class AnalyticsManager { func track(_ event: String) {} }
