import Foundation

/// Нативный источник YouTube на базе YouTubeKit.
/// Поиск и воспроизведение не требуют API-ключа.
final class YouTubeMusicService: MusicAPIServiceProtocol {
    private let model = YouTubeModel()

    // MARK: - Search

    func search(term: String, limit: Int = 30) async throws -> [Track] {
        let response = try await SearchResponse.sendThrowingRequest(
            youtubeModel: model,
            data: [.query: term]
        )
        let videos = response.results.compactMap { $0 as? YTVideo }
        return videos.prefix(limit).map { Track(youtube: $0) }
    }

    func resolveStreamURL(for track: Track) async throws -> URL? {
        guard track.source == .youtube else { return nil }
        let info = try await VideoInfosWithDownloadFormatsResponse.sendThrowingRequest(
            youtubeModel: model,
            data: [.query: track.sourceID]
        )
        // Берём лучший audio-only формат, совместимый с AVFoundation (не webm).
        let audioFormats = info.downloadFormats.compactMap { $0 as? AudioOnlyFormat }
        let playable = audioFormats
            .filter { ($0.mimeType ?? "").contains("webm") == false }
            .sorted { ($0.averageBitrate ?? 0) > ($1.averageBitrate ?? 0) }
        return playable.first?.url ?? audioFormats.first?.url
    }

    // MARK: - Feed (YouTube Home Screen)

    /// Загружает домашнюю страницу YouTube — рекомендации «Что посмотреть».
    func feed() async -> [RecommendationSection] {
        do {
            let response = try await HomeScreenResponse.sendThrowingRequest(
                youtubeModel: model,
                data: [:]
            )
            let videos = response.results.compactMap { $0 as? YTVideo }
            let tracks = videos.map { Track(youtube: $0) }

            guard !tracks.isEmpty else { return [] }
            return [
                RecommendationSection(
                    id: "yt-home",
                    title: "Рекомендации YouTube",
                    subtitle: "Подборка на основе ваших интересов",
                    tracks: tracks,
                    kind: .home
                )
            ]
        } catch {
            return []
        }
    }

    // MARK: - Chart (Trending через поиск)

    /// YouTube не имеет прямого чарта — используем поиск «top charts music».
    func chart() async -> [Track] {
        if let result = try? await search(term: "top charts music 2025", limit: 25) {
            return result
        }
        return []
    }

    // MARK: - Discover (через жанровые поиски)

    /// Формирует секции «Открытия» на основе жанровых поисковых запросов.
    func discover() async -> [RecommendationSection] {
        let genres: [(id: String, title: String, query: String)] = [
            ("pop",        "Поп-хиты",      "pop hits 2025"),
            ("rock",       "Рок",            "rock music"),
            ("electronic", "Электроника",    "electronic music"),
            ("hiphop",     "Хип-хоп",        "hip hop hits"),
            ("jazz",       "Джаз",           "jazz"),
            ("classical",  "Классика",       "classical music"),
            ("rnb",        "R&B",            "r&b soul hits"),
            ("latin",      "Латин",          "latin music hits"),
            ("kpop",       "K-Pop",          "kpop hits"),
            ("indie",      "Инди",           "indie alternative")
        ]

        var sections: [RecommendationSection] = []
        await withTaskGroup(of: (String, [Track]).self) { group in
            for genre in genres {
                group.addTask {
                    let tracks = (try? await self.search(term: genre.query, limit: 10)) ?? []
                    return (genre.id, tracks)
                }
            }
            for await (id, tracks) in group {
                guard !tracks.isEmpty else { continue }
                let genreInfo = genres.first { $0.id == id }
                sections.append(RecommendationSection(
                    id: "yt-discover-\(id)",
                    title: genreInfo?.title ?? id,
                    subtitle: nil,
                    tracks: tracks,
                    kind: .discover
                ))
            }
        }
        return sections
    }

    // MARK: - Similar Tracks (Related Videos)

    /// Загружает похожие видео (recommended videos) для данного трека.
    func similarTracks(for track: Track) async -> [Track] {
        guard track.source == .youtube else { return [] }
        do {
            let response = try await MoreVideoInfosResponse.sendThrowingRequest(
                youtubeModel: model,
                data: [.query: track.sourceID]
            )
            let videos = response.recommendedVideos.compactMap { $0 as? YTVideo }
            return videos.map { Track(youtube: $0) }
        } catch {
            return []
        }
    }

    // MARK: - New Releases (через поиск)

    /// YouTube не имеет API новых релизов — делаем поиск по «new music».
    func newReleases() async -> [Track] {
        if let result = try? await search(term: "new music releases 2025", limit: 20) {
            return result
        }
        return []
    }

    // MARK: - Daily Mixes (синтетические миксы на основе жанров)

    /// Формирует синтетические «дейли-миксы» из жанровых поисковых запросов YouTube.
    func dailyMixes() async -> [GeneratedPlaylistSection] {
        let mixes: [(id: String, title: String, query: String)] = [
            ("electronic-mix",  "Электронный микс",   "electronic chill mix"),
            ("rock-mix",        "Рок-микс",           "rock mix"),
            ("pop-mix",         "Поп-микс",           "pop hits mix"),
            ("hiphop-mix",      "Хип-хоп микс",       "hip hop mix"),
            ("lofi-mix",        "Lo-Fi микс",         "lofi hip hop mix"),
            ("workout-mix",     "Тренировка",         "workout music mix")
        ]

        var sections: [GeneratedPlaylistSection] = []
        await withTaskGroup(of: (String, String, [Track]).self) { group in
            for mix in mixes {
                group.addTask {
                    let tracks = (try? await self.search(term: mix.query, limit: 15)) ?? []
                    return (mix.id, mix.title, tracks)
                }
            }
            for await (id, title, tracks) in group {
                guard !tracks.isEmpty else { continue }
                sections.append(GeneratedPlaylistSection(
                    id: "yt-mix-\(id)",
                    title: title,
                    subtitle: "YouTube Mix",
                    artworkURL: tracks.first?.artworkURL,
                    tracks: tracks,
                    source: .youtube
                ))
            }
        }
        return sections
    }
}

// MARK: - Track Mapping

private extension Track {
    init(youtube video: YTVideo) {
        let artwork = video.thumbnails.sorted { ($0.width ?? 0) > ($1.width ?? 0) }.first?.url
            ?? video.thumbnails.last?.url
        self.init(
            id: Track.stableID(source: .youtube, sourceID: video.videoId),
            sourceID: video.videoId,
            source: .youtube,
            title: video.title ?? "Unknown",
            artistName: video.channel?.name ?? "YouTube",
            albumTitle: "YouTube",
            artworkURL: artwork,
            streamURL: nil,
            durationMillis: Track.parseDuration(video.timeLength),
            genre: "Music",
            releaseDate: nil
        )
    }

    /// Преобразует "mm:ss" / "hh:mm:ss" в миллисекунды.
    static func parseDuration(_ text: String?) -> Int {
        guard let parts = text?.split(separator: ":").map({ Int($0) ?? 0 }), !parts.isEmpty else {
            return 0
        }
        let seconds = parts.reduce(0) { $0 * 60 + $1 }
        return seconds * 1000
    }
}
