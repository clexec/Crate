import SwiftUI

struct MainTabView: View {
    @State private var showSearch = false
    @EnvironmentObject private var player: PlayerManager

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            tabContent
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    // Mini player sits just above the system tab bar
                    if player.currentTrack != nil {
                        MiniPlayerView()
                            .padding(.horizontal, 10)
                            .padding(.bottom, 6)
                            .padding(.top, 4)
                    }
                }

            // Floating search icon — separate from tab bar, positioned bottom-right
            searchButton
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
    }

    // MARK: - Tab content

    @ViewBuilder
    private var tabContent: some View {
        #if compiler(>=6.2)
        nativeTabView
        #else
        fallbackTabView
        #endif
    }

    // MARK: - Native iOS 26 TabView (3 tabs — no Create)

    #if compiler(>=6.2)
    @ViewBuilder
    private var nativeTabView: some View {
        TabView {
            Tab("Главная", systemImage: "house.fill") {
                NavigationStack { HomeView() }
            }
            Tab("Избранное", systemImage: "heart.fill") {
                NavigationStack { LibraryView() }
            }
            Tab("Профиль", systemImage: "person.fill") {
                NavigationStack { ProfileView() }
            }
        }
    }
    #endif

    // MARK: - Fallback TabView (Xcode 16)

    private var fallbackTabView: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Главная", systemImage: "house.fill") }
            NavigationStack { LibraryView() }
                .tabItem { Label("Избранное", systemImage: "heart.fill") }
            NavigationStack { ProfileView() }
                .tabItem { Label("Профиль", systemImage: "person.fill") }
        }
    }

    // MARK: - Floating Search Button (separate from tab bar, bottom-right)

    private var searchButton: some View {
        Button {
            showSearch = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
        }
        #if compiler(>=6.2)
        .glassEffect(in: .circle)
        #else
        .background(.ultraThinMaterial, in: Circle())
        #endif
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .padding(.trailing, 16)
        // Float above tab bar + mini player if active
        .padding(.bottom, player.currentTrack != nil ? 160 : 92)
    }
}

typealias TabBarView = MainTabView
