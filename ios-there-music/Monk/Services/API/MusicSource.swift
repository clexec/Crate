import Foundation

/// Единый протокол для всех музыкальных источников.
protocol MusicAPIServiceProtocol {
    func search(term: String, limit: Int) async throws -> [Track]
    /// Лениво разрешает прямую ссылку на полный трек для воспроизведения.
    func resolveStreamURL(for track: Track) async throws -> URL?
}

// MARK: - Рекомендации

/// Модели для рекомендаций поверх треков.

/// Секция рекомендаций — именованный список треков (например, «Чарт», «Похожие треки»).
struct RecommendationSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let tracks: [Track]
    /// Тип секции для UI-маркировки.
    let kind: Kind

    enum Kind: String {
        case feed           // Персональный фид
        case chart          // Чарт
        case discover       // Открытия / лендинг
        case similar        // Похожие на трек
        case newReleases    // Новые релизы
        case dailyMix       // Дейли-микс / сгенерированный плейлист
        case home           // YouTube Home / рекомендации
        case trending       // В тренде
    }
}

/// Модель сгенерированного плейлиста (из YM Feed / Landing).
struct GeneratedPlaylistSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let artworkURL: URL?
    let tracks: [Track]
    let source: MusicSource
}

/// Расширенный протокол с методами рекомендаций.
protocol RecommendationServiceProtocol {
    /// Персональный фид / домашняя страница.
    func feed() async -> [RecommendationSection]
    /// Чарт (топ-треки).
    func chart() async -> [Track]
    /// Открытия / лендинг (персональные блоки).
    func discover() async -> [RecommendationSection]
    /// Похожие треки для данного трека.
    func similarTracks(for track: Track) async -> [Track]
    /// Новые релизы.
    func newReleases() async -> [Track]
    /// Сгенерированные (daily-mix) плейлисты из фида.
    func dailyMixes() async -> [GeneratedPlaylistSection]
}

/// Агрегатор нативных источников Crate: Яндекс Музыка (YM-API) и YouTube (YouTubeKit).
/// Яндекс используется, когда задан токен; иначе — YouTube как fallback.
final class MusicSourceProvider: MusicAPIServiceProtocol, RecommendationServiceProtocol {
    static let shared = MusicSourceProvider()

    let yandex = YandexMusicService()
    let youtube = YouTubeMusicService()

    private var yandexEnabled: Bool { !APIConfig.yandexMusicToken.isEmpty }

    init() {
        if yandexEnabled {
            yandex.configure()
        }
    }

    // MARK: - Search

    func search(term: String, limit: Int = 30) async throws -> [Track] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if yandexEnabled {
            let ym = (try? await yandex.search(term: trimmed, limit: limit)) ?? []
            if !ym.isEmpty { return ym }
        }
        return (try? await youtube.search(term: trimmed, limit: limit)) ?? []
    }

    func resolveStreamURL(for track: Track) async throws -> URL? {
        if let existing = track.streamURL { return existing }
        switch track.source {
        case .yandex:  return try await yandex.resolveStreamURL(for: track)
        case .youtube: return try await youtube.resolveStreamURL(for: track)
        }
    }

    // MARK: - Recommendations

    func feed() async -> [RecommendationSection] {
        var sections: [RecommendationSection] = []
        if yandexEnabled {
            sections += await yandex.feed()
        }
        if sections.isEmpty {
            sections += await youtube.feed()
        }
        return sections
    }

    func chart() async -> [Track] {
        if yandexEnabled {
            let tracks = await yandex.chart()
            if !tracks.isEmpty { return tracks }
        }
        return await youtube.chart()
    }

    func discover() async -> [RecommendationSection] {
        var sections: [RecommendationSection] = []
        if yandexEnabled {
            sections += await yandex.discover()
        }
        if sections.isEmpty {
            sections += await youtube.discover()
        }
        return sections
    }

    func similarTracks(for track: Track) async -> [Track] {
        switch track.source {
        case .yandex:
            if yandexEnabled {
                return await yandex.similarTracks(for: track)
            }
            return []
        case .youtube:
            return await youtube.similarTracks(for: track)
        }
    }

    func newReleases() async -> [Track] {
        if yandexEnabled {
            let tracks = await yandex.newReleases()
            if !tracks.isEmpty { return tracks }
        }
        return await youtube.newReleases()
    }

    func dailyMixes() async -> [GeneratedPlaylistSection] {
        if yandexEnabled {
            let mixes = await yandex.dailyMixes()
            if !mixes.isEmpty { return mixes }
        }
        return await youtube.dailyMixes()
    }
}
