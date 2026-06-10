import Foundation

enum TimeFormatHelper {
    static func format(milliseconds: Int) -> String {
        let seconds = max(0, milliseconds / 1000)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

enum ValidationHelper {
    static func isValidEmail(_ email: String) -> Bool {
        email.range(of: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

enum PasswordStrength: String {
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
}

enum PasswordValidationHelper {
    static func strength(for password: String) -> PasswordStrength {
        let hasLetter = password.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil
        let hasNumber = password.range(of: #"\d"#, options: .regularExpression) != nil
        let hasSymbol = password.range(of: #"[^A-Za-z0-9]"#, options: .regularExpression) != nil
        if password.count >= 12, hasLetter, hasNumber, hasSymbol { return .strong }
        if password.count >= 8, hasLetter, hasNumber { return .medium }
        return .weak
    }

    static func isValid(_ password: String) -> Bool {
        password.count >= 8 && strength(for: password) != .weak
    }
}
