import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject { let auth: AuthenticationManager; init(auth: AuthenticationManager) { self.auth = auth } }

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = UserDefaults.standard.string(forKey: "lastEmail") ?? ""
    @Published var password = ""
    let auth: AuthenticationManager
    init(auth: AuthenticationManager) { self.auth = auth }
    func signIn() { Task { await auth.signIn(email: email, password: password) } }
}

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var email = ""
    @Published var displayName = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    var strength: PasswordStrength { PasswordValidationHelper.strength(for: password) }
    let auth: AuthenticationManager
    init(auth: AuthenticationManager) { self.auth = auth }
    func createAccount() { guard password == confirmPassword else { auth.errorMessage = AuthError.passwordMismatch.localizedDescription; return }; Task { await auth.register(email: email, password: password, displayName: displayName) } }
}

@MainActor final class AppleSignInViewModel: ObservableObject { let auth: AuthenticationManager; init(auth: AuthenticationManager) { self.auth = auth }; func signIn() { auth.signInWithApple() } }
@MainActor final class GoogleSignInViewModel: ObservableObject { let auth: AuthenticationManager; init(auth: AuthenticationManager) { self.auth = auth }; func signIn() { Task { await auth.signInWithGoogle() } } }
@MainActor final class ForgotPasswordViewModel: ObservableObject { @Published var email = ""; @Published var newPassword = ""; @Published var didReset = false }
