import Foundation

@MainActor
struct AuthRepository {
    let auth: AuthenticationManager
    func signOut() { auth.signOut() }
}
