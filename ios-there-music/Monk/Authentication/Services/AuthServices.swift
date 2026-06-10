import AuthenticationServices
import CryptoKit
import Foundation
import Security

protocol AuthenticationServiceProtocol {
    func signIn(email: String, password: String) async throws -> User
    func register(email: String, password: String, displayName: String) async throws -> User
}

struct PasswordHashingService {
    func hash(_ password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((password + salt).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

final class KeychainService {
    func save(_ value: String, for key: String) {
        let data = Data(value.utf8)
        SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrAccount: key] as CFDictionary)
        SecItemAdd([kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecValueData: data] as CFDictionary, nil)
    }

    func read(_ key: String) -> String? {
        var result: AnyObject?
        let status = SecItemCopyMatching([kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne] as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(_ key: String) { SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrAccount: key] as CFDictionary) }
}

final class EmailAuthService: AuthenticationServiceProtocol {
    private let persistence: PersistenceController
    private let hashing = PasswordHashingService()
    private let keychain = KeychainService()

    init(persistence: PersistenceController) { self.persistence = persistence }

    func signIn(email: String, password: String) async throws -> User {
        guard ValidationHelper.isValidEmail(email) else { throw AuthError.invalidEmail }
        guard let user = await persistence.user(email: email) else { throw AuthError.accountNotFound }
        let stored = keychain.read("password.\(email.lowercased())")
        let hash = hashing.hash(password, salt: email.lowercased())
        guard stored == hash else { throw AuthError.invalidCredentials }
        UserDefaults.standard.set(email, forKey: "lastEmail")
        return user
    }

    func register(email: String, password: String, displayName: String) async throws -> User {
        guard ValidationHelper.isValidEmail(email) else { throw AuthError.invalidEmail }
        guard PasswordValidationHelper.isValid(password) else { throw AuthError.weakPassword }
        if await persistence.user(email: email) != nil { throw AuthError.accountExists }
        let user = User(id: UUID().uuidString, email: email, displayName: displayName.isEmpty ? email.components(separatedBy: "@").first ?? "Listener" : displayName, avatarData: nil, creationDate: Date(), provider: .email)
        keychain.save(hashing.hash(password, salt: email.lowercased()), for: "password.\(email.lowercased())")
        await persistence.saveUser(user)
        UserDefaults.standard.set(email, forKey: "lastEmail")
        return user
    }

    func resetPassword(email: String, newPassword: String) async throws {
        guard await persistence.user(email: email) != nil else { throw AuthError.accountNotFound }
        guard PasswordValidationHelper.isValid(newPassword) else { throw AuthError.weakPassword }
        keychain.save(hashing.hash(newPassword, salt: email.lowercased()), for: "password.\(email.lowercased())")
    }
}

final class AppleSignInService {
    func makeUser(email: String?) -> User {
        User(id: UUID().uuidString, email: email ?? "apple-user@privaterelay.appleid.com", displayName: "Apple Listener", avatarData: nil, creationDate: Date(), provider: .apple)
    }
}

final class GoogleSignInService {
    func signIn() async throws -> User {
        guard !AppConstants.googleClientID.isEmpty else { throw AuthError.googleClientIDMissing }
        return User(id: UUID().uuidString, email: "google@there.music", displayName: "Google Listener", avatarData: nil, creationDate: Date(), provider: .google)
    }
}

final class TokenService {
    private let keychain = KeychainService()
    func save(token: String, provider: AuthProvider) { keychain.save(token, for: "token.\(provider.rawValue)") }
    func clear(provider: AuthProvider) { keychain.delete("token.\(provider.rawValue)") }
}
