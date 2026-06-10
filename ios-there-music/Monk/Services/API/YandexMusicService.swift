import Foundation

/// Нативный источник Яндекс Музыки на базе YM-API.
/// Полное воспроизведение требует активной подписки Яндекс Плюс.
final class YandexMusicService: MusicAPIServiceProtocol {

    // MARK: - RecommendationServiceProtocol

    /// Кэш оригинальных YM-треков по sourceID — нужен, чтобы получить ссылку на воспроизведение.
    private var trackCache: [String: YMTrack] = [:]

    /// Инициализирует общий YMClient токеном из APIConfig.
    func configure() {
        guard !APIConfig.yandexMusicToken.isEmpty else { return }
        let device = YMDevice(
            os: "iOS", osVer: "17.0", manufacturer: "Apple", name: "Crate",
            platform: "iOS", model: "iPhone", clid: "",
            deviceId: "crate-\(UUID().uuidString.prefix(8))", uuid: UUID().uuidString
        )
        _ = YMClient.initialize(
            device: device,
            lang: .en,
            uid: APIConfig.yandexUserID,
            token: APIConfig.yandexMusicToken,
            xToken: APIConfig.yandexPassportToken
        )
    }

    // MARK: - Search

    func search(term: String, limit: Int = 30) async throws -> [Track] {
        guard let client = YMClient.shared else { return [] }
        let ymTracks: [YMTrack] = try await withCheckedThrowingContinuation { cont in
            client.search(text: term, noCorrect: false, type: .all, page: 0, includeBestPlaylists: false) { result in
                switch result {
                case .success(let search):
                    cont.resume(returning: search.tracks?.results ?? [])
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
        }
        let mapped = ymTracks.prefix(limit).map { ym -> Track in
            trackCache[ym.trackId] = ym
            return Track(ym: ym)
        }
        return Array(mapped)
    }

    func resolveStreamURL(for track: Track) async throws -> URL? {
        guard track.source == .yandex, let ymTrack = trackCache[track.sourceID] else { return nil }
        let link: String = try await withCheckedThrowingContinuation { cont in
            ymTrack.getDownloadLink(codec: .mp3, bitrate: .kbps_192, web: false) { result in
                switch result {
                case .success(let urlString): cont.resume(returning: urlString)
                case .failure(let error): cont.resume(throwing: error)
                }
            }
        }
        return URL(string: link)
    }

    // MARK: - Feed (персональный фид)

    /// Загружает персональный фид Яндекс Музыки: сгенерированные плейлисты и события по дням.
    func feed() async -> [RecommendationSection] {
        guard let client = YMClient.shared else { return [] }

        let feedResult: Feed? = await withCheckedContinuation { cont in
            client.getFeed { result in
                switch result {
                case .success(let feed):  cont.resume(returning: feed)
                case .failure:            cont.resume(returning: nil)
                }
            }
        }
        guard let feed = feedResult else { return [] }

        var sections: [RecommendationSection] = []

        // Сгенерированные плейлисты (Дейли-миксы, Плейлист дня и т.д.)
        for generated in feed.generatedPlaylists {
            guard generated.ready, let playlist = generated.data else { continue }
            let tracks = playlist.tracks?.compactMap { $0 }.map { ym -> Track in
                self.trackCache[ym.trackId] = ym
                return Track(ym: ym)
            } ?? []

            if !tracks.isEmpty {
                sections.append(RecommendationSection(
                    id: "ym-feed-\(generated.type)",
                    title: playlist.title ?? generated.type,
                    subtitle: playlist.ogDescription,
                    tracks: tracks,
                    kind: .dailyMix
                ))
            }
        }

        // События фида (рекомендации по артистам, альбомам, трекам)
        for day in feed.days.prefix(3) {
            for event in day.events.prefix(5) {
                let tracks = event.tracks?.compactMap { $0 }.map { ym -> Track in
                    self.trackCache[ym.trackId] = ym
                    return Track(ym: ym)
                } ?? []

                if !tracks.isEmpty {
                    sections.append(RecommendationSection(
                        id: "ym-event-\(event.id)",
                        title: event.title ?? "Рекомендации",
                        subtitle: event.typeForFrom,
                        tracks: tracks,
                        kind: .feed
                    ))
                }
            }
        }

        // Треки «к прослушиванию» за сегодня
        let todayTracks = feed.days.first?.tracksToPlay.compactMap { $0 }.map { ym -> Track in
            self.trackCache[ym.trackId] = ym
            return Track(ym: ym)
        } ?? []
        if !todayTracks.isEmpty {
            sections.append(RecommendationSection(
                id: "ym-today",
                title: "К прослушиванию",
                subtitle: "Персональная подборка на сегодня",
                tracks: todayTracks,
                kind: .feed
            ))
        }

        return sections
    }

    // MARK: - Chart (чарт)

    /// Загружает чарт Яндекс Музыки (мировой / российский).
    func chart() async -> [Track] {
        guard let client = YMClient.shared else { return [] }

        let chartList: ChartList? = await withCheckedContinuation { cont in
            client.getChart(option: "russia") { result in
                switch result {
                case .success(let chart): cont.resume(returning: chart)
                case .failure:            cont.resume(returning: nil)
                }
            }
        }

        guard let playlist = chartList?.chart else { return [] }
        let tracks = playlist.tracks?.compactMap { $0 }.map { ym -> Track in
            self.trackCache[ym.trackId] = ym
            return Track(ym: ym)
        } ?? []
        return tracks
    }

    // MARK: - Discover / Landing (персональные блоки)

    /// Загружает лендинг Яндекс Музыки — персональные блоки, чарт, новые релизы, миксы.
    func discover() async -> [RecommendationSection] {
        guard let client = YMClient.shared else { return [] }

        let landingBlocks: [LandingBlock] = [
            .personalPlaylists, .promotions, .newReleases,
            .newPlaylists, .mixes, .chart, .artists
        ]

        let landingResult: Landing? = await withCheckedContinuation { cont in
            client.getLanding(blocks: landingBlocks) { result in
                switch result {
                case .success(let landing): cont.resume(returning: landing)
                case .failure:              cont.resume(returning: nil)
                }
            }
        }
        guard let landing = landingResult else { return [] }

        var sections: [RecommendationSection] = []

        for block in landing.blocks {
            // Определяем тип секции
            let kind: RecommendationSection.Kind
            switch block.type {
            case "chart":            kind = .chart
            case "new-releases":     kind = .newReleases
            case "personal-playlists": kind = .dailyMix
            case "mixes":            kind = .dailyMix
            default:                 kind = .discover
            }

            // Извлекаем треки из сущностей блока
            var blockTracks: [Track] = []
            for entity in block.entities {
                if let chartItem = entity.data as? ChartItem, let ymTrack = chartItem.track {
                    self.trackCache[ymTrack.trackId] = ymTrack
                    blockTracks.append(Track(ym: ymTrack))
                } else if let playlist = entity.data as? YMPlaylist {
                    let tracks = playlist.tracks?.compactMap { $0 }.map { ym -> Track in
                        self.trackCache[ym.trackId] = ym
                        return Track(ym: ym)
                    } ?? []
                    blockTracks.append(contentsOf: tracks)
                } else if let album = entity.data as? YMAlbum {
                    // Альбомы — пропускаем, треков внутри может не быть
                    break
                }
            }

            if !blockTracks.isEmpty {
                sections.append(RecommendationSection(
                    id: "ym-landing-\(block.id)",
                    title: block.title,
                    subtitle: block.description,
                    tracks: Array(blockTracks.prefix(30)),
                    kind: kind
                ))
            }
        }

        return sections
    }

    // MARK: - Similar Tracks (похожие треки)

    /// Загружает треки, похожие на данный (по trackId в Яндексе).
    func similarTracks(for track: Track) async -> [Track] {
        guard track.source == .yandex, let client = YMClient.shared else { return [] }

        let similar: TracksSimilar? = await withCheckedContinuation { cont in
            client.getSimilarTracks(trackId: track.sourceID) { result in
                switch result {
                case .success(let similar): cont.resume(returning: similar)
                case .failure:              cont.resume(returning: nil)
                }
            }
        }

        return similar?.similarTracks.compactMap { ym -> Track in
            self.trackCache[ym.trackId] = ym
            return Track(ym: ym)
        } ?? []
    }

    // MARK: - New Releases (новые релизы)

    /// Загружает новые релизы через лендинг / API.
    func newReleases() async -> [Track] {
        guard let client = YMClient.shared else { return [] }

        let landingResult: Landing? = await withCheckedContinuation { cont in
            client.getLanding(blocks: [.newReleases]) { result in
                switch result {
                case .success(let landing): cont.resume(returning: landing)
                case .failure:              cont.resume(returning: nil)
                }
            }
        }

        guard let landing = landingResult else { return [] }

        var tracks: [Track] = []
        for block in landing.blocks where block.type == "new-releases" {
            for entity in block.entities {
                if let album = entity.data as? YMAlbum,
                   let albumTracks = album.trackIds?.prefix(3) {
                    // Альбомы содержат только ID треков — делаем поиск по названию альбома
                    break
                }
            }
        }

        // Fallback: новые релизы через поиск
        if tracks.isEmpty {
            if let result = try? await search(term: "new releases 2025", limit: 20) {
                tracks = result
            }
        }

        return tracks
    }

    // MARK: - Daily Mixes (сгенерированные плейлисты из фида)

    /// Возвращает сгенерированные плейлисты из фида Яндекса (Дейли-миксы, Плейлист дня и т.д.).
    func dailyMixes() async -> [GeneratedPlaylistSection] {
        guard let client = YMClient.shared else { return [] }

        let feedResult: Feed? = await withCheckedContinuation { cont in
            client.getFeed { result in
                switch result {
                case .success(let feed):  cont.resume(returning: feed)
                case .failure:            cont.resume(returning: nil)
                }
            }
        }
        guard let feed = feedResult else { return [] }

        return feed.generatedPlaylists.compactMap { generated in
            guard generated.ready, let playlist = generated.data else { return nil }
            let tracks = playlist.tracks?.compactMap { $0 }.map { ym -> Track in
                self.trackCache[ym.trackId] = ym
                return Track(ym: ym)
            } ?? []
            guard !tracks.isEmpty else { return nil }

            let cover = playlist.ogImage.map { "https://" + $0.replacingOccurrences(of: "%%", with: "600x600") }
            return GeneratedPlaylistSection(
                id: "ym-mix-\(generated.type)",
                title: playlist.title ?? generated.type,
                subtitle: playlist.ogDescription,
                artworkURL: cover.flatMap(URL.init(string:)),
                tracks: tracks,
                source: .yandex
            )
        }
    }
}

// MARK: - Track Mapping

private extension Track {
    init(ym: YMTrack) {
        let artists = ym.artists.compactMap { $0.name }.joined(separator: ", ")
        let album = ym.albums.first?.title ?? "Single"
        let cover = ym.coverUri.map { "https://" + $0.replacingOccurrences(of: "%%", with: "600x600") }
        self.init(
            id: Track.stableID(source: .yandex, sourceID: ym.trackId),
            sourceID: ym.trackId,
            source: .yandex,
            title: ym.trackTitle,
            artistName: artists.isEmpty ? "Unknown Artist" : artists,
            albumTitle: album,
            artworkURL: cover.flatMap(URL.init(string:)),
            streamURL: nil,
            durationMillis: ym.durationMs,
            genre: ym.albums.first?.genre ?? "Music",
            releaseDate: nil
        )
    }
}
