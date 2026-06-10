import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryManager
    @EnvironmentObject private var player: PlayerManager
    @State private var selectedFilter: LibraryFilter = .playlists

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Библиотека")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                // Filter tabs with Liquid Glass
                filters

                // Content based on selected filter
                switch selectedFilter {
                case .playlists:
                    playlistsContent
                case .albums:
                    albumsContent
                case .artists:
                    artistsContent
                case .liked:
                    likedContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Filter Tabs with Liquid Glass

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .foregroundStyle(selectedFilter == filter ? ColorPalette.accent : .white)
                            #if compiler(>=6.2)
                            .glassEffect(in: .rect(cornerRadius: 18))
                            #else
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            #endif
                    }
                }
            }
        }
    }

    // MARK: - Playlists Content

    private var playlistsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            AlbumCardView(
                title: "Mono Favorites",
                subtitle: "Автоплейлист",
                artworkURL: library.likedTracks.first?.artworkURL
            )

            if library.likedTracks.isEmpty {
                Text("Создайте плейлист, чтобы начать коллекцию.")
                    .foregroundStyle(ColorPalette.textSecondary)
                    .thereCard()
            }
        }
    }

    // MARK: - Albums Content with Genre Cards

    private var albumsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Жанры")
                .font(.title2.bold())
                .foregroundStyle(.white)

            // Genre grid with gradient cards
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(genreCategories) { genre in
                    GenreCategoryCard(
                        title: genre.title,
                        gradient: genre.gradient,
                        iconName: genre.iconName
                    )
                }
            }

            // Saved albums
            if !library.likedTracks.isEmpty {
                Text("Сохранённые альбомы")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(library.likedTracks.prefix(6)) { track in
                            AlbumCardView(
                                title: track.title,
                                subtitle: track.artistName,
                                artworkURL: track.artworkURL
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Artists Content

    private var artistsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Following Artists")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Artists appear here after you follow them.")
                .foregroundStyle(ColorPalette.textSecondary)
                .thereCard()
        }
    }

    // MARK: - Liked Content

    private var likedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Liked Songs")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(library.likedTracks.count) треков")
                    .font(.subheadline)
                    .foregroundStyle(ColorPalette.textSecondary)
            }

            ForEach(library.likedTracks) { track in
                TrackRowView(track: track) {
                    player.play(track, queue: library.likedTracks)
                }
            }

            if library.likedTracks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(ColorPalette.textSecondary.opacity(0.5))
                    Text("Лайкайте треки из плеера, чтобы собрать коллекцию.")
                        .foregroundStyle(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .thereCard()
            }
        }
    }

    // MARK: - Genre Categories Data

    private var genreCategories: [GenreCategoryData] {
        [
            GenreCategoryData(title: "Pop", gradient: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)], iconName: "music.mic"),
            GenreCategoryData(title: "Rock", gradient: [Color.red.opacity(0.8), Color.orange.opacity(0.6)], iconName: "guitars"),
            GenreCategoryData(title: "Hip-Hop", gradient: [Color.yellow.opacity(0.7), Color.red.opacity(0.6)], iconName: "waveform"),
            GenreCategoryData(title: "Jazz", gradient: [Color.blue.opacity(0.7), Color.indigo.opacity(0.5)], iconName: "saxophone"),
            GenreCategoryData(title: "Electronic", gradient: [Color.cyan.opacity(0.7), Color.purple.opacity(0.6)], iconName: "slider.horizontal.3"),
            GenreCategoryData(title: "Soul", gradient: [Color.orange.opacity(0.7), Color.pink.opacity(0.5)], iconName: "heart.fill"),
            GenreCategoryData(title: "R&B", gradient: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)], iconName: "music.note.list"),
            GenreCategoryData(title: "Classical", gradient: [Color.green.opacity(0.6), Color.teal.opacity(0.5)], iconName: "pianokeys")
        ]
    }
}

// MARK: - Genre Category Data Model

private struct GenreCategoryData: Identifiable {
    let id = UUID()
    let title: String
    let gradient: [Color]
    let iconName: String
}

// MARK: - Genre Category Card View

struct GenreCategoryCard: View {
    let title: String
    let gradient: [Color]
    let iconName: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 90)

            // Large icon — semi-transparent, top-right
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.22))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 6)
                .padding(.top, 2)

            // Title
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

typealias PlaylistsView = LibraryView
typealias LikedSongsView = LibraryView
typealias SavedAlbumsView = LibraryView
typealias FollowingArtistsView = LibraryView
typealias LibraryFiltersView = LibraryView
