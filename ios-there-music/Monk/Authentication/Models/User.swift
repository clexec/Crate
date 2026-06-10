import Foundation

enum AuthProvider: String, Codable, CaseIterable {
    case apple
    case google
    case email
}

struct User: Identifiable, Codable, Hashable {
    let id: String
    var email: String
    var displayName: String
    var avatarData: Data?
    let creationDate: Date
    let provider: AuthProvider
}

struct AuthCredentials: Codable, Hashable {
    let email: String
    let password: String
}

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case accountExists
    case accountNotFound
    case invalidCredentials
    case googleClientIDMissing
    case appleSignInFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidEmail: "Enter a valid email address."
        case .weakPassword: "Password must contain at least 8 characters, a letter, a number, and a symbol."
        case .passwordMismatch: "Passwords do not match."
        case .accountExists: "An account already exists for this email."
        case .accountNotFound: "No account exists for this email."
        case .invalidCredentials: "Incorrect email or password."
        case .googleClientIDMissing: "Google Sign-In needs a Google OAuth client ID."
        case .appleSignInFailed: "Apple Sign-In could not be completed."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}
