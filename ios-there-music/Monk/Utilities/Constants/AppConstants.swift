import SwiftUI

enum AppConstants {
    static let appName = "Mono"
    static let appDescription = "Вся твоя музыка в одном месте"
    static let googleClientID = ""

    // EmailJS configuration — https://www.emailjs.com (free 200 emails/month)
    // 1. Register at emailjs.com
    // 2. Add an Email Service (Gmail, Outlook, etc.)
    // 3. Create a Template with variables: {{to_email}}, {{code}}, {{app_name}}
    // 4. Fill in the three keys below
    static let emailjsServiceID  = ""   // e.g. "service_abc123"
    static let emailjsTemplateID = ""   // e.g. "template_xyz456"
    static let emailjsPublicKey  = ""   // e.g. "user_XXXXXXXXXXXXXXX"
}

enum ColorPalette {
    static let background    = Color.black
    static let surface       = Color(red: 0.06, green: 0.05, blue: 0.04)
    static let elevated      = Color(red: 0.12, green: 0.09, blue: 0.07)
    static let accent        = Color(red: 0.831, green: 0.647, blue: 0.455)
    static let accentAlt     = Color(red: 0.788, green: 0.663, blue: 0.380)
    static let secondary     = Color(red: 0.420, green: 0.267, blue: 0.137)
    static let textSecondary = Color(red: 0.702, green: 0.702, blue: 0.702)
}

enum UIConstants {
    static let horizontalPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 18
    static let cardRadius: CGFloat = 14
}
