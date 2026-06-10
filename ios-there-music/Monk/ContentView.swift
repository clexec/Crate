import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthenticationManager
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if auth.currentUser == nil {
                AuthenticationView()
            } else if showOnboarding {
                OnboardingView(onComplete: { showOnboarding = false })
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: auth.currentUser) { _, newUser in
            if newUser != nil && !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                showOnboarding = true
            }
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Добро пожаловать в Mono",
            subtitle: "Вся ваша музыка в одном месте. Открывайте, слушайте и делитесь любимыми треками.",
            icon: "waveform.circle.fill",
            gradient: [ColorPalette.accent.opacity(0.6), ColorPalette.secondary]
        ),
        OnboardingPage(
            title: "Находите музыку",
            subtitle: "Ищите по жанрам, артистам и настроению. Свайпайте карточки жанров, чтобы найти новое.",
            icon: "magnifyingglass",
            gradient: [Color.purple.opacity(0.6), Color.blue.opacity(0.5)]
        ),
        OnboardingPage(
            title: "Собирайте коллекцию",
            subtitle: "Лайкайте треки, создавайте плейлисты и организуйте свою библиотеку звуков.",
            icon: "heart.fill",
            gradient: [Color.pink.opacity(0.6), Color.red.opacity(0.5)]
        ),
        OnboardingPage(
            title: "Слушайте с удовольствием",
            subtitle: "Полноэкранный плеер с визуализацией, управлением очередью и обменом треками.",
            icon: "headphones",
            gradient: [Color.cyan.opacity(0.6), Color.teal.opacity(0.5)]
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: pages[currentPage].gradient + [.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: pages[currentPage].icon)
                    .font(.system(size: 72))
                    .foregroundStyle(ColorPalette.accent)
                    .padding(.bottom, 32)

                // Title
                Text(pages[currentPage].title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Subtitle
                Text(pages[currentPage].subtitle)
                    .font(.body)
                    .foregroundStyle(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? ColorPalette.accent : ColorPalette.textSecondary.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Buttons
                if currentPage < pages.count - 1 {
                    HStack(spacing: 16) {
                        Button("Пропустить") {
                            finishOnboarding()
                        }
                        .foregroundStyle(ColorPalette.textSecondary)

                        Button("Далее") {
                            withAnimation { currentPage += 1 }
                        }
                        .thereButtonStyle()
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                } else {
                    Button("Начать слушать") {
                        finishOnboarding()
                    }
                    .thereButtonStyle()
                    .padding(.horizontal, 24)
                }

                Spacer().frame(height: 48)
            }
        }
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        onComplete()
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
}

#Preview { ContentView().environmentObject(AuthenticationManager(persistence: PersistenceController())).environmentObject(PlayerManager(persistence: PersistenceController())).environmentObject(LibraryManager(persistence: PersistenceController())).environmentObject(PersistenceController()).environmentObject(ThemeManager()).environmentObject(CacheManager()).environmentObject(NotificationManager()) }
