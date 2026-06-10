import Combine
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    let player: PlayerManager
    let library: LibraryManager
    init(player: PlayerManager, library: LibraryManager) { self.player = player; self.library = library }
}

@MainActor
final class CommentViewModel: ObservableObject {
    @Published var text = ""
    private let persistence: PersistenceController
    init(persistence: PersistenceController) { self.persistence = persistence }
    func comments(for track: Track) -> [Comment] { persistence.comments.filter { $0.trackID == track.id } }
    func add(track: Track, user: User) { guard !text.isEmpty else { return }; persistence.saveComment(Comment(id: UUID().uuidString, trackID: track.id, userID: user.id, displayName: user.displayName, text: text, createdAt: Date())); text = "" }
    func delete(_ comment: Comment) { persistence.deleteComment(comment) }
}

final class QueueViewModel: ObservableObject {}
