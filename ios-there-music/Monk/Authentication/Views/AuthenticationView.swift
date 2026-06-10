import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var auth: AuthenticationManager
    @State private var route: AuthRoute?
    @State private var backgroundTracks: [Track] = []
    @State private var bgOffsetY: CGFloat = 0
    @State private var bgOffsetX: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated moving album covers background
                animatedAlbumGrid

                // Dark gradient overlay
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.55), location: 0),
                        .init(color: .black.opacity(0.25), location: 0.4),
                        .init(color: .black.opacity(0.85), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Content
                VStack(spacing: 0) {
                    Spacer()

                    // Logo block
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(ColorPalette.accent.opacity(0.18))
                                .frame(width: 90, height: 90)
                                .blur(radius: 12)
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [ColorPalette.accent, ColorPalette.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 78, height: 78)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.white)
                        }

                        Text(AppConstants.appName)
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(AppConstants.appDescription)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.65))
                            .padding(.horizontal, 36)
                    }

                    Spacer()

                    // Auth buttons
                    VStack(spacing: 14) {
                        Button {
                            auth.signInWithApple()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Войти через Apple")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(.white, in: Capsule())
                            .foregroundStyle(.black)
                        }

                        Button {
                            route = .email
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Войти по email")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 54)
                            #if compiler(>=6.2)
                            .glassEffect(in: .capsule)
                            #else
                            .background(.ultraThinMaterial, in: Capsule())
                            #endif
                            .foregroundStyle(.white)
                        }

                        Button {
                            route = .register
                        } label: {
                            Text("Нет аккаунта? **Зарегистрироваться**")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 4) {
                        Text("Условия использования")
                        Text("•")
                        Text("Конфиденциальность")
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
            }
            .alert("Ошибка", isPresented: .constant(auth.errorMessage != nil)) {
                Button("OK") { auth.errorMessage = nil }
            } message: {
                Text(auth.errorMessage ?? "")
            }
            .navigationDestination(item: $route) { route in
                switch route {
                case .email: LoginView(startAsRegister: false)
                case .register: LoginView(startAsRegister: true)
                }
            }
        }
        .task { await loadBackgroundCovers() }
        .onAppear { startAnimation() }
    }

    // MARK: - Animated Album Grid

    private var animatedAlbumGrid: some View {
        GeometryReader { geo in
            let cellSize: CGFloat = 96
            let spacing: CGFloat = 3
            let cols = Int(geo.size.width / (cellSize + spacing)) + 3
            let rows = Int(geo.size.height / (cellSize + spacing)) + 4

            HStack(spacing: spacing) {
                ForEach(0..<max(cols, 5), id: \.self) { col in
                    VStack(spacing: spacing) {
                        ForEach(0..<max(rows, 9), id: \.self) { row in
                            let index = (col * max(rows, 9) + row) % max(backgroundTracks.count, 1)
                            Group {
                                if index < backgroundTracks.count {
                                    AsyncImage(url: backgroundTracks[index].artworkURL) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        default:
                                            ColorPalette.elevated
                                        }
                                    }
                                } else {
                                    ColorPalette.elevated
                                }
                            }
                            .frame(width: cellSize, height: cellSize)
                            .clipped()
                            .cornerRadius(8)
                        }
                    }
                    // Alternate columns move in opposite directions for parallax feel
                    .offset(y: col.isMultiple(of: 2) ? bgOffsetY : -bgOffsetY)
                }
            }
            .offset(x: -cellSize / 2 + bgOffsetX, y: -cellSize)
        }
        .ignoresSafeArea()
        .opacity(0.55)
    }

    // MARK: - Animation

    private func startAnimation() {
        withAnimation(.linear(duration: 22).repeatForever(autoreverses: true)) {
            bgOffsetY = 180
        }
        withAnimation(.linear(duration: 35).repeatForever(autoreverses: true)) {
            bgOffsetX = 24
        }
    }

    private func loadBackgroundCovers() async {
        let api = MusicSourceProvider.shared
        do {
            let tracks = try await api.search(term: "top hits 2024", limit: 30)
            await MainActor.run { backgroundTracks = tracks }
        } catch {}
    }
}

enum AuthRoute: Hashable, Identifiable {
    case email
    case register
    var id: Int { hashValue }
}
