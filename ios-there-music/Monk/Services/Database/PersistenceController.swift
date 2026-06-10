import Combine
import Foundation

@MainActor
final class PersistenceController: ObservableObject {
    @Published private(set) var users: [User] = []
    @Published private(set) var likedTracks: [Track] = []
    @Published private(set) var recentlyPlayed: [Track] = []
    @Published private(set) var comments: [Comment] = []

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() { load() }

    func saveUser(_ user: User) { upsert(user, in: &users); persist() }
    func user(email: String) -> User? { users.first { $0.email.lowercased() == email.lowercased() } }
    func toggleLike(_ track: Track) { likedTracks.contains(track) ? likedTracks.removeAll { $0.id == track.id } : likedTracks.insert(track, at: 0); persist() }
    func addRecentlyPlayed(_ track: Track) { recentlyPlayed.removeAll { $0.id == track.id }; recentlyPlayed.insert(track, at: 0); persist() }
    func saveComment(_ comment: Comment) { upsert(comment, in: &comments); persist() }
    func deleteComment(_ comment: Comment) { comments.removeAll { $0.id == comment.id }; persist() }
    func clearHistory() { recentlyPlayed.removeAll(); persist() }

    private func upsert<T: Identifiable>(_ item: T, in array: inout [T]) where T.ID: Equatable {
        if let index = array.firstIndex(where: { $0.id == item.id }) { array[index] = item } else { array.append(item) }
    }

    private func load() {
        users = load([User].self, key: "users") ?? []
        likedTracks = load([Track].self, key: "likedTracks") ?? []
        recentlyPlayed = load([Track].self, key: "recentlyPlayed") ?? []
        comments = load([Comment].self, key: "comments") ?? []
    }

    private func persist() {
        save(users, key: "users"); save(likedTracks, key: "likedTracks"); save(recentlyPlayed, key: "recentlyPlayed"); save(comments, key: "comments")
    }

    private func save<T: Encodable>(_ value: T, key: String) { defaults.set(try? encoder.encode(value), forKey: key) }
    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? { defaults.data(forKey: key).flatMap { try? decoder.decode(type, from: $0) } }
}

typealias CoreDataService = PersistenceController
typealias CoreDataManager = PersistenceController
