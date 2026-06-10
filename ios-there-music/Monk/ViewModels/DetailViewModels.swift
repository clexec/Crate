import Combine
import Foundation

final class ArtistDetailViewModel: ObservableObject { let artist: Artist; init(artist: Artist) { self.artist = artist } }
final class AlbumDetailViewModel: ObservableObject { let album: Album; init(album: Album) { self.album = album } }
final class PlaylistDetailViewModel: ObservableObject { let playlist: Playlist; init(playlist: Playlist) { self.playlist = playlist } }
@MainActor final class ProfileViewModel: ObservableObject { let auth: AuthenticationManager; init(auth: AuthenticationManager) { self.auth = auth } }
@MainActor final class SettingsViewModel: ObservableObject { let theme: ThemeManager; let cache: CacheManager; init(theme: ThemeManager, cache: CacheManager) { self.theme = theme; self.cache = cache } }
