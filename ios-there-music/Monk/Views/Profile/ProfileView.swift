import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthenticationManager
    @EnvironmentObject private var library: LibraryManager
    @EnvironmentObject private var persistence: PersistenceController
    @State private var showSettings = false
    @State private var showImagePicker = false
    @State private var avatarScale: CGFloat = 1.0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                statsSection
                menuSection
                signOutButton
            }
            .padding(.bottom, 130)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
    }

    // MARK: - Header (avatar + name + username)

    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            // Gradient backdrop
            LinearGradient(
                colors: [ColorPalette.secondary.opacity(0.7), ColorPalette.accent.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 260)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 14) {
                // Avatar
                Button {
                    showImagePicker = true
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        avatarView
                            .scaleEffect(avatarScale)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: avatarScale)
                        // Camera badge
                        Circle()
                            .fill(ColorPalette.accent)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.black)
                            )
                            .shadow(radius: 4)
                            .offset(x: 4, y: 4)
                    }
                }
                .buttonStyle(.plain)
                .onLongPressGesture(minimumDuration: 0) {
                    avatarScale = 0.93
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { avatarScale = 1 }
                }

                // Display name
                Text(auth.currentUser?.displayName ?? "Слушатель")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                // Username
                if let email = auth.currentUser?.email, !email.isEmpty {
                    let username = "@" + (email.components(separatedBy: "@").first ?? email)
                    HStack(spacing: 6) {
                        Image(systemName: "at")
                            .font(.caption)
                        Text(email.components(separatedBy: "@").first ?? email)
                            .font(.subheadline)
                    }
                    .foregroundStyle(ColorPalette.textSecondary)
                }

                // Join date pill
                if let user = auth.currentUser {
                    Label(
                        "В Mono с \(user.creationDate.formatted(.dateTime.month().year()))",
                        systemImage: "music.note"
                    )
                    .font(.caption)
                    .foregroundStyle(ColorPalette.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    #if compiler(>=6.2)
                    .glassEffect(in: .capsule)
                    #else
                    .background(ColorPalette.elevated.opacity(0.8), in: Capsule())
                    #endif
                }

                Spacer().frame(height: 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ColorPalette.accent, ColorPalette.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .shadow(color: ColorPalette.accent.opacity(0.4), radius: 16, y: 6)

            if let user = auth.currentUser, !user.displayName.isEmpty {
                Text(String(user.displayName.prefix(1)).uppercased())
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    // MARK: - Stats row

    private var statsSection: some View {
        HStack(spacing: 0) {
            statCell(value: "\(library.likedTracks.count)", label: "Лайков", icon: "heart.fill", color: .red)
            divider
            statCell(value: "\(persistence.recentlyPlayed.count)", label: "Слушано", icon: "headphones", color: ColorPalette.accent)
            divider
            statCell(value: "∞", label: "Треков", icon: "music.note.list", color: .purple)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        #if compiler(>=6.2)
        .glassEffect(in: .rect(cornerRadius: 20))
        #else
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        #endif
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(ColorPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(ColorPalette.textSecondary.opacity(0.2))
            .frame(width: 1, height: 44)
    }

    // MARK: - Menu

    private var menuSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Настройки")
            menuItem(icon: "gearshape.fill", title: "Настройки", subtitle: "Тема, уведомления, кэш", color: .gray) {
                showSettings = true
            }
            menuItem(icon: "bell.badge.fill", title: "Уведомления", subtitle: "Новые релизы, рекомендации", color: .red) {}
            menuItem(icon: "headphones", title: "Качество аудио", subtitle: "Стриминг и загрузки", color: ColorPalette.accent) {}

            sectionHeader("Приватность")
            menuItem(icon: "shield.lefthalf.filled", title: "Конфиденциальность", subtitle: "Данные и безопасность", color: .blue) {}
            menuItem(icon: "iphone.and.arrow.forward", title: "Экспорт данных", subtitle: "Ваши лайки и история", color: .teal) {}

            sectionHeader("Поддержка")
            menuItem(icon: "questionmark.circle.fill", title: "Помощь", subtitle: "FAQ и обратная связь", color: .green) {}
            menuItem(icon: "star.fill", title: "Оценить приложение", subtitle: "Понравилось? Поставьте 5 ⭐️", color: .yellow) {}
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(ColorPalette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.leading, 4)
    }

    private func menuItem(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 19))
                            .foregroundStyle(color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ColorPalette.textSecondary.opacity(0.5))
            }
            .padding(12)
            .background(ColorPalette.elevated.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sign out

    private var signOutButton: some View {
        Button {
            auth.signOut()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                Text("Выйти из аккаунта")
                    .font(.headline)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
}

typealias UserSettingsView = ProfileView
typealias LogoutView = ProfileView
