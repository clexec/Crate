import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var player: PlayerManager
    @State private var showFull = false

    var body: some View {
        if let track = player.currentTrack {
            Button { showFull = true } label: {
                HStack(spacing: 10) {
                    RemoteArtworkView(url: track.artworkURL, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(track.artistName)
                            .font(.caption)
                            .foregroundStyle(ColorPalette.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button { player.toggle() } label: {
                        Image(systemName: player.audio.state == .playing ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    Button { player.next() } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                #if compiler(>=6.2)
                .glassEffect(in: .rect(cornerRadius: 16))
                #else
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                #endif
                .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showFull) { FullPlayerView() }
        }
    }
}

struct FullPlayerView: View {
    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var library: LibraryManager
    @EnvironmentObject private var auth: AuthenticationManager
    @EnvironmentObject private var persistence: PersistenceController
    @State private var showQueue = false
    @State private var showComments = false
    @State private var similarTracks: [Track] = []
    @State private var isLoadingSimilar = false

    var body: some View {
        if let track = player.currentTrack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Capsule()
                        .fill(ColorPalette.textSecondary.opacity(0.5))
                        .frame(width: 38, height: 5)
                        .padding(.top, 10)

                    RemoteArtworkView(url: track.artworkURL, size: 310)
                        .shadow(color: ColorPalette.accent.opacity(0.22), radius: 28)

                    HStack {
                        VStack(alignment: .leading) {
                            Text(track.title)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text(track.artistName)
                                .foregroundStyle(ColorPalette.textSecondary)
                        }
                        Spacer()
                        Button { library.toggleLike(track) } label: {
                            Image(systemName: library.isLiked(track) ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundStyle(ColorPalette.accent)
                        }
                    }

                    ProgressBarView(
                        value: Binding(get: { player.audio.currentTime }, set: { player.audio.seek(to: $0) }),
                        duration: player.audio.duration
                    )

                    PlaybackControlsView()
                    VolumeSliderView(value: Binding(get: { player.audio.volume }, set: { player.audio.volume = $0 }))

                    HStack(spacing: 28) {
                        AudioVisualizerView(isPlaying: player.audio.state == .playing)
                        Button { showComments = true } label: { Image(systemName: "text.bubble") }
                        Button { showQueue = true } label: { Image(systemName: "list.bullet") }
                        ShareLink(item: "Слушай \(track.title) от \(track.artistName) в Mono") {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .font(.title3)
                    .foregroundStyle(.white)

                    // Похожие треки
                    if isLoadingSimilar {
                        ProgressView()
                            .tint(ColorPalette.accent)
                    } else if !similarTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Похожие треки")
                                .font(.headline)
                                .foregroundStyle(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(similarTracks) { similar in
                                        AlbumCardView(
                                            title: similar.title,
                                            subtitle: similar.artistName,
                                            artworkURL: similar.artworkURL
                                        )
                                        .onTapGesture {
                                            let q = similarTracks.filter { $0.id != similar.id }
                                            player.play(similar, queue: q)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [ColorPalette.secondary.opacity(0.7), .black],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
            )
            .sheet(isPresented: $showQueue) { QueueView() }
            .sheet(isPresented: $showComments) { CommentView(track: track) }
            .task {
                isLoadingSimilar = true
                similarTracks = await HomeViewModel().similarTracks(for: track)
                isLoadingSimilar = false
            }
        }
    }
}

struct PlaybackControlsView: View {
    @EnvironmentObject private var player: PlayerManager
    var body: some View {
        HStack(spacing: 28) {
            Button { player.toggleShuffle() } label: { Image(systemName: "shuffle") }
            Button { player.previous() } label: { Image(systemName: "backward.fill") }
            Button { player.toggle() } label: {
                Image(systemName: player.audio.state == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 68))
            }
            Button { player.next() } label: { Image(systemName: "forward.fill") }
            Button { player.cycleRepeat() } label: { Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat") }
        }
        .font(.title2)
        .foregroundStyle(.white)
    }
}

struct ProgressBarView: View {
    @Binding var value: Double
    let duration: Double

    var body: some View {
        VStack(spacing: 4) {
            Slider(value: $value, in: 0...max(duration, 1))
                .tint(ColorPalette.accent)
            HStack {
                Text(TimeFormatHelper.format(milliseconds: Int(value * 1000)))
                Spacer()
                Text(TimeFormatHelper.format(milliseconds: Int(duration * 1000)))
            }
            .font(.caption)
            .foregroundStyle(ColorPalette.textSecondary)
        }
    }
}

struct VolumeSliderView: View {
    @Binding var value: Float
    var body: some View {
        HStack {
            Image(systemName: "speaker.fill")
            Slider(value: Binding(get: { Double(value) }, set: { value = Float($0) }), in: 0...1)
                .tint(ColorPalette.accent)
            Image(systemName: "speaker.wave.3.fill")
        }
        .foregroundStyle(ColorPalette.textSecondary)
    }
}

struct QueueView: View {
    @EnvironmentObject private var player: PlayerManager
    var body: some View {
        NavigationStack {
            List {
                if let current = player.currentTrack {
                    Section("Сейчас играет") { Text(current.title) }
                }
                Section("Далее") {
                    ForEach(player.queue) { Text($0.title) }
                        .onMove { player.queue.move(fromOffsets: $0, toOffset: $1) }
                        .onDelete { player.queue.remove(atOffsets: $0) }
                }
            }
            .navigationTitle("Очередь")
            .toolbar { EditButton() }
        }
    }
}

struct CommentView: View {
    let track: Track
    @EnvironmentObject private var persistence: PersistenceController
    @EnvironmentObject private var auth: AuthenticationManager
    @State private var text = ""
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(persistence.comments.filter { $0.trackID == track.id }) { comment in
                        VStack(alignment: .leading) {
                            Text(comment.displayName).font(.caption.bold())
                            Text(comment.text)
                        }
                    }
                    .onDelete { indexSet in
                        let all = persistence.comments.filter { $0.trackID == track.id }
                        indexSet.map { all[$0] }.forEach(persistence.deleteComment)
                    }
                }
                HStack {
                    TextField("Комментарий", text: $text)
                        .textFieldStyle(.roundedBorder)
                    Button("Отправить") {
                        if let user = auth.currentUser, !text.isEmpty {
                            persistence.saveComment(Comment(id: UUID().uuidString, trackID: track.id, userID: user.id, displayName: user.displayName, text: text, createdAt: Date()))
                            text = ""
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Комментарии")
        }
    }
}
