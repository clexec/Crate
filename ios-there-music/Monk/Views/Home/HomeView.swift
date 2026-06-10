import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var persistence: PersistenceController
    @EnvironmentObject private var auth: AuthenticationManager

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Доброе утро"
        case 12..<17: return "Добрый день"
        case 17..<23: return "Добрый вечер"
        default:      return "Доброй ночи"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header

                // Индикатор загрузки
                if viewModel.isLoading {
                    ProgressView()
                        .tint(ColorPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }

                if !viewModel.isLoading {
                    // 1. Недавно слушали
                    if !persistence.recentlyPlayed.isEmpty {
                        musicSection("Недавно слушали", tracks: persistence.recentlyPlayed)
                    }

                    // 2. Дейли-миксы / сгенерированные плейлисты
                    if !viewModel.dailyMixes.isEmpty {
                        mixSection
                    }

                    // 3. Персональный фид (секции от API)
                    ForEach(viewModel.feedSections) { section in
                        musicSection(section.title, subtitle: section.subtitle, tracks: section.tracks)
                    }

                    // 4. Чарт
                    if !viewModel.chart.isEmpty {
                        chartSection
                    }

                    // 5. Открытия (жанровые / лендинг блоки)
                    ForEach(viewModel.discoverSections.prefix(4)) { section in
                        musicSection(section.title, subtitle: section.subtitle, tracks: section.tracks)
                    }

                    // 6. Новые релизы
                    if !viewModel.newReleases.isEmpty {
                        musicSection("Новые релизы", tracks: viewModel.newReleases)
                    }
                }
            }
            .padding(.horizontal, UIConstants.horizontalPadding)
            .padding(.bottom, 130)
        }
        .background(Color.black.ignoresSafeArea())
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                if let name = auth.currentUser?.displayName, !name.isEmpty {
                    Text(name)
                        .font(.callout)
                        .foregroundStyle(ColorPalette.textSecondary)
                }
            }
            Spacer()
            NavigationLink {
                ProfileView()
                    .environmentObject(auth)
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ColorPalette.accent, ColorPalette.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    if let name = auth.currentUser?.displayName, !name.isEmpty {
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Music section

    private func musicSection(_ title: String, subtitle: String? = nil, tracks: [Track]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(tracks) { track in
                        AlbumCardView(
                            title: track.title,
                            subtitle: track.artistName,
                            artworkURL: track.artworkURL
                        )
                        .onTapGesture {
                            let q = tracks.filter { $0.id != track.id }
                            player.play(track, queue: q)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Chart Section (с позициями)

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Чарт")
                .font(.title3.bold())
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(viewModel.chart.prefix(20).enumerated()), id: \.element.id) { index, track in
                        ZStack(alignment: .topLeading) {
                            AlbumCardView(
                                title: track.title,
                                subtitle: track.artistName,
                                artworkURL: track.artworkURL
                            )
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(ColorPalette.accent)
                                .clipShape(Circle())
                                .offset(x: 4, y: 4)
                        }
                        .onTapGesture {
                            let q = viewModel.chart.filter { $0.id != track.id }
                            player.play(track, queue: q)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Daily Mixes

    private var mixSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Дейли-миксы")
                .font(.title3.bold())
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.dailyMixes) { mix in
                        PlaylistCardView(
                            title: mix.title,
                            subtitle: mix.subtitle,
                            artworkURL: mix.artworkURL
                        )
                        .onTapGesture {
                            // Играем первый трек из микса, остальные — в очередь
                            if let first = mix.tracks.first {
                                let q = Array(mix.tracks.dropFirst())
                                player.play(first, queue: q)
                            }
                        }
                    }
                }
            }
        }
    }
}

typealias DiscoverWeeklyView = HomeView
typealias ReleaseRadarView   = HomeView
typealias DailyMixView       = HomeView
typealias RecentlyPlayedView = HomeView

struct RecommendationCardView: View {
    let track: Track
    var body: some View { AlbumCardView(title: track.title, subtitle: track.artistName, artworkURL: track.artworkURL) }
}
