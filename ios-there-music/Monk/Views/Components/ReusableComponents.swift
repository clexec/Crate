import SwiftUI

struct RemoteArtworkView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        ColorPalette.elevated
            .frame(width: size, height: size)
            .overlay {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        case .failure: Image(systemName: "music.note").font(.title).foregroundStyle(ColorPalette.accent)
                        default: ProgressView().tint(ColorPalette.accent)
                        }
                    }
                } else {
                    Image(systemName: "music.note").font(.title).foregroundStyle(ColorPalette.accent)
                }
            }
            .clipShape(.rect(cornerRadius: 10))
    }
}

struct TrackRowView: View {
    let track: Track
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RemoteArtworkView(url: track.artworkURL, size: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                    Text(track.artistName).font(.caption).foregroundStyle(ColorPalette.textSecondary).lineLimit(1)
                }
                Spacer()
                Text(track.durationText).font(.caption2).foregroundStyle(ColorPalette.textSecondary)
                Image(systemName: "ellipsis").foregroundStyle(ColorPalette.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Add to Playlist", systemImage: "text.badge.plus") {}
            Button("Add to Liked Songs", systemImage: "heart") {}
            Button("Go to Artist", systemImage: "person") {}
            Button("Go to Album", systemImage: "square.stack") {}
            ShareLink(item: "Слушай \(track.title) от \(track.artistName) в Mono") { Label("Поделиться", systemImage: "square.and.arrow.up") }
            Button("View Song Details", systemImage: "info.circle") {}
        }
    }
}

struct AlbumCardView: View {
    let title: String
    let subtitle: String
    let artworkURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            RemoteArtworkView(url: artworkURL, size: 148)
            Text(title).font(.subheadline.weight(.bold)).foregroundStyle(.white).lineLimit(1)
            Text(subtitle).font(.caption).foregroundStyle(ColorPalette.textSecondary).lineLimit(1)
        }
        .frame(width: 148, alignment: .leading)
    }
}

typealias PlaylistCardView = AlbumCardView
typealias ArtistCardView = AlbumCardView

struct LoadingView: View {
    var body: some View { ProgressView().tint(ColorPalette.accent).frame(maxWidth: .infinity, maxHeight: .infinity) }
}

struct AudioVisualizerView: View {
    let isPlaying: Bool
    @State private var animate = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(ColorPalette.accent)
                    .frame(width: 5, height: animate && isPlaying ? CGFloat(14 + index * 5) : 8)
                    .animation(.spring(response: 0.32, dampingFraction: 0.55).repeatForever().delay(Double(index) * 0.08), value: animate)
            }
        }.onAppear { animate = true }
    }
}

struct GlassEffectView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    @ViewBuilder
    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            content.glassEffect()
        } else {
            content.background(.ultraThinMaterial)
        }
        #else
        content.background(.ultraThinMaterial)
        #endif
    }
}
