import Combine
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Track] = []
    @Published var isLoading = false
    @Published var history: [String] = UserDefaults.standard.stringArray(forKey: "searchHistory") ?? []
    @Published var genreCards: [GenreCardData] = GenreCardData.defaultCards

    private let repository = SearchRepository(api: MusicSourceProvider.shared)
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() { loadGenreArtwork() }

    func search() {
        searchTask?.cancel()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { results = []; return }

        isLoading = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            let tracks = await repository.search(text)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.results = tracks
                self.isLoading = false
            }
        }
    }

    func commitSearch(_ value: String) {
        let val = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !val.isEmpty else { return }
        history.removeAll { $0 == val }
        history.insert(val, at: 0)
        UserDefaults.standard.set(Array(history.prefix(12)), forKey: "searchHistory")
        search()
    }

    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: "searchHistory")
    }

    private func loadGenreArtwork() {
        Task {
            let api = MusicSourceProvider.shared
            await withTaskGroup(of: (Int, URL?).self) { group in
                for (index, card) in genreCards.enumerated() {
                    group.addTask {
                        let tracks = try? await api.search(term: card.searchQuery, limit: 5)
                        return (index, tracks?.first?.artworkURL)
                    }
                }
                for await (index, url) in group {
                    if let url {
                        await MainActor.run { genreCards[index].artworkURL = url }
                    }
                }
            }
        }
    }
}

// MARK: - Genre card data

struct GenreCardData: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let searchQuery: String
    let gradientColors: [Color]
    var artworkURL: URL?

    static let defaultCards: [GenreCardData] = [
        .init(id: "pop",        title: "Поп",       iconName: "music.mic",           searchQuery: "pop hits 2024",      gradientColors: [.pink, .purple]),
        .init(id: "rock",       title: "Рок",       iconName: "guitars",              searchQuery: "rock",               gradientColors: [.red, .orange]),
        .init(id: "hiphop",     title: "Хип-хоп",   iconName: "waveform",             searchQuery: "hip hop",            gradientColors: [.yellow.opacity(0.8), .orange]),
        .init(id: "electronic", title: "Электро",   iconName: "slider.horizontal.3",  searchQuery: "electronic music",   gradientColors: [.cyan, .blue]),
        .init(id: "jazz",       title: "Джаз",      iconName: "music.note",           searchQuery: "jazz",               gradientColors: [.brown.opacity(0.9), Color(red: 0.5, green: 0.3, blue: 0.1)]),
        .init(id: "rnb",        title: "R&B",       iconName: "heart.fill",           searchQuery: "r&b soul",           gradientColors: [.indigo, .purple]),
        .init(id: "classical",  title: "Классика",  iconName: "pianokeys",            searchQuery: "classical music",    gradientColors: [Color(red: 0.2, green: 0.2, blue: 0.5), .teal.opacity(0.7)]),
        .init(id: "latin",      title: "Латин",     iconName: "music.quarternote.3",  searchQuery: "latin reggaeton",    gradientColors: [.green, .yellow]),
        .init(id: "kpop",       title: "K-Pop",     iconName: "star.fill",            searchQuery: "kpop",               gradientColors: [.pink.opacity(0.7), .blue]),
        .init(id: "indie",      title: "Инди",      iconName: "guitars",              searchQuery: "indie alternative",  gradientColors: [.mint, .teal])
    ]
}

final class GenreCategoryViewModel: ObservableObject {}
final class SearchResultViewModel: ObservableObject {}
