import Foundation

enum PlaybackState: String, Codable {
    case idle
    case loading
    case playing
    case paused
    case failed
}

struct PlayerSnapshot: Codable, Hashable {
    var state: PlaybackState
    var currentTrack: Track?
    var queue: [Track]
    var repeatMode: RepeatMode
    var isShuffleEnabled: Bool
}
