import Combine
import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var selectedFilter: LibraryFilter?
    @Published var sortOption: SortOption = .recentlyAdded
    let library: LibraryManager
    init(library: LibraryManager) { self.library = library }
}

final class PlaylistsViewModel: ObservableObject {}
final class LikedSongsViewModel: ObservableObject {}
final class SavedAlbumsViewModel: ObservableObject {}
final class FollowingArtistsViewModel: ObservableObject {}
