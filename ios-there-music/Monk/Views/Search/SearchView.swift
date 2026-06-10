import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var player: PlayerManager
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isSearchFocused ? ColorPalette.accent : ColorPalette.textSecondary)

                        TextField("Артисты, треки, жанры...", text: $searchText)
                            .font(.body)
                            .foregroundStyle(.white)
                            .tint(ColorPalette.accent)
                            .focused($isSearchFocused)
                            .onSubmit { viewModel.commitSearch(searchText) }
                            .onChange(of: searchText) { _, val in
                                viewModel.query = val
                                if val.isEmpty { viewModel.results = [] }
                            }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                viewModel.query = ""
                                viewModel.results = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(ColorPalette.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(ColorPalette.elevated.opacity(0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if isSearchFocused {
                        Button("Отмена") {
                            searchText = ""
                            viewModel.query = ""
                            viewModel.results = []
                            isSearchFocused = false
                        }
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.accent)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: isSearchFocused)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if searchText.isEmpty {
                            genreSection
                        } else {
                            resultsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 140)
                }
            }
        }
        .onAppear { isSearchFocused = true }
    }

    // MARK: - Genre grid

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Жанры")
                .font(.title3.bold())
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.genreCards) { card in
                    GenreArtworkCard(card: card) {
                        searchText = card.searchQuery
                        viewModel.query = card.searchQuery
                        viewModel.commitSearch(card.searchQuery)
                    }
                }
            }
        }
    }

    // MARK: - Search results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.isLoading {
                HStack(spacing: 12) {
                    ProgressView().tint(ColorPalette.accent)
                    Text("Ищем музыку...")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else if viewModel.results.isEmpty && !searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(ColorPalette.textSecondary.opacity(0.5))
                    Text("Ничего не найдено")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textSecondary)
                    Text("Попробуйте другой запрос")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                Text("Результаты")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                ForEach(viewModel.results) { track in
                    TrackRowView(track: track) {
                        player.play(track, queue: viewModel.results)
                    }
                }
            }
        }
    }
}

// MARK: - Genre Card

struct GenreArtworkCard: View {
    let card: GenreCardData
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Background: real artwork or genre gradient
                if let url = card.artworkURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        default:
                            genreGradient
                        }
                    }
                } else {
                    genreGradient
                }

                // Overlay gradient
                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Icon top-right
                Image(systemName: card.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.22))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)

                // Title bottom-left
                Text(card.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
            .frame(height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity) {} onPressingChanged: { pressing in
            isPressed = pressing
        }
    }

    private var genreGradient: some View {
        LinearGradient(
            colors: card.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

typealias GenreCategoryGridView  = SearchView
typealias SearchResultsView      = SearchView
typealias SearchHistoryView      = SearchView
typealias CategoryDetailView     = SearchView
