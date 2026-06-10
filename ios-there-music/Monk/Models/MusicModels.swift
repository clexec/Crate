import Foundation

struct Album: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artistName: String
    let artworkURL: URL?
    let releaseYear: String
    let tracks: [Track]
}

struct Artist: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let imageURL: URL?
    let genre: String
    let topTracks: [Track]
}

struct Playlist: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var subtitle: String
    var artworkURL: URL?
    var tracks: [Track]
    var createdAt: Date
}

struct Comment: Identifiable, Codable, Hashable {
    let id: String
    let trackID: Int
    let userID: String
    let displayName: String
    var text: String
    let createdAt: Date
}

struct Genre: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let symbolName: String
    let query: String
}

struct Recommendation: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let reason: String
    let tracks: [Track]
}

enum RepeatMode: String, Codable, CaseIterable {
    case off
    case one
    case all
}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case playlists = "Playlists"
    case albums = "Albums"
    case artists = "Artists"
    case liked = "Liked"
    var id: String { rawValue }
}

enum SortOption: String, CaseIterable, Identifiable {
    case recentlyAdded = "Recently Added"
    case title = "Title"
    case artist = "Artist"
    case duration = "Duration"
    var id: String { rawValue }
}
