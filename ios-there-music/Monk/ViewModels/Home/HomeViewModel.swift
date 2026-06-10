import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published State

    /// Чарт (топ-треки).
    @Published var chart: [Track] = []
    /// Персональный фид / рекомендации.
    @Published var feedSections: [RecommendationSection] = []
    /// Открытия (жанровые / лендинг блоки).
    @Published var discoverSections: [RecommendationSection] = []
    /// Новые релизы.
    @Published var newReleases: [Track] = []
    /// Дейли-миксы (сгенерированные плейлисты).
    @Published var dailyMixes: [GeneratedPlaylistSection] = []
    /// Состояние загрузки.
    @Published var isLoading = false

    private let provider = MusicSourceProvider.shared

    // MARK: - Load

    /// Загружает все секции рекомендаций параллельно.
    func load() async {
        isLoading = true

        async let chartTask: [Track] = provider.chart()
        async let feedTask: [RecommendationSection] = provider.feed()
        async let discoverTask: [RecommendationSection] = provider.discover()
        async let releasesTask: [Track] = provider.newReleases()
        async let mixesTask: [GeneratedPlaylistSection] = provider.dailyMixes()

        let (chartResult, feedResult, discoverResult, releasesResult, mixesResult) = await (
            chartTask, feedTask, discoverTask, releasesTask, mixesTask
        )

        chart = chartResult
        feedSections = feedResult
        discoverSections = discoverResult
        newReleases = releasesResult
        dailyMixes = mixesResult

        isLoading = false
    }

    /// Перезагружает конкретную секцию.
    func reloadSection(_ kind: RecommendationSection.Kind) async {
        switch kind {
        case .chart:
            chart = await provider.chart()
        case .feed:
            feedSections = await provider.feed()
        case .discover:
            discoverSections = await provider.discover()
        case .newReleases:
            newReleases = await provider.newReleases()
        case .dailyMix:
            dailyMixes = await provider.dailyMixes()
        default:
            break
        }
    }

    /// Загружает похожие треки для данного (используется из PlayerView).
    func similarTracks(for track: Track) async -> [Track] {
        await provider.similarTracks(for: track)
    }
}

// Legacy aliases — чтобы не ломать существующие ссылки.
final class DiscoverWeeklyViewModel: ObservableObject {}
final class ReleaseRadarViewModel: ObservableObject {}
final class RecentlyPlayedViewModel: ObservableObject {}
