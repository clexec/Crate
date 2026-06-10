import Foundation

struct SearchRepository {
    let api: MusicAPIServiceProtocol
    func search(_ query: String) async -> [Track] { (try? await api.search(term: query, limit: 30)) ?? [] }
}

struct TrackRepository {
    let api: MusicAPIServiceProtocol
    let recommendations: RecommendationServiceProtocol

    init(api: MusicAPIServiceProtocol) {
        self.api = api
        self.recommendations = api as? RecommendationServiceProtocol ?? MusicSourceProvider.shared
    }

    func trending() async -> [Track] {
        await recommendations.chart()
    }

    func recommendations(seed: String) async -> [Track] {
        // Используем реальный поиск по seed, если нет специализированных рекомендаций.
        (try? await api.search(term: seed, limit: 20)) ?? []
    }

    /// Чарт (топ-треки).
    func chart() async -> [Track] {
        await recommendations.chart()
    }

    /// Персональный фид.
    func feed() async -> [RecommendationSection] {
        await recommendations.feed()
    }

    /// Открытия / лендинг.
    func discover() async -> [RecommendationSection] {
        await recommendations.discover()
    }

    /// Похожие треки.
    func similarTracks(for track: Track) async -> [Track] {
        await recommendations.similarTracks(for: track)
    }

    /// Новые релизы.
    func newReleases() async -> [Track] {
        await recommendations.newReleases()
    }

    /// Дейли-миксы.
    func dailyMixes() async -> [GeneratedPlaylistSection] {
        await recommendations.dailyMixes()
    }
}

struct AlbumRepository { func albums(from tracks: [Track]) -> [Album] { Dictionary(grouping: tracks, by: \.albumTitle).map { Album(id: $0.key, title: $0.key, artistName: $0.value.first?.artistName ?? "Various Artists", artworkURL: $0.value.first?.artworkURL, releaseYear: "2026", tracks: $0.value) } } }
struct ArtistRepository { func artists(from tracks: [Track]) -> [Artist] { Dictionary(grouping: tracks, by: \.artistName).map { Artist(id: $0.key, name: $0.key, imageURL: $0.value.first?.artworkURL, genre: $0.value.first?.genre ?? "Music", topTracks: $0.value) } } }
struct PlaylistRepository { func make(title: String, tracks: [Track]) -> Playlist { Playlist(id: UUID().uuidString, title: title, subtitle: "Crate Music", artworkURL: tracks.first?.artworkURL, tracks: tracks, createdAt: Date()) } }
struct UserRepository { let persistence: PersistenceController }

@MainActor
struct CommentRepository {
    let persistence: PersistenceController
    func comments(trackID: Int) -> [Comment] { persistence.comments.filter { $0.trackID == trackID } }
}

struct RecommendationRepository { let trackRepository: TrackRepository }
