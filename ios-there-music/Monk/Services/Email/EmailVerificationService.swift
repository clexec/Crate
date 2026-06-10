import Foundation

// MARK: - Email Verification Service
// Uses EmailJS REST API (https://www.emailjs.com — free 200 emails/month)
// Setup: create account → add email service → create template with {{code}} and {{to_email}}
// Then fill in AppConstants.emailjsServiceID / templateID / publicKey
//
// Template example:
//   Subject: Ваш код подтверждения Mono
//   Body:    Код: {{code}} (действует 10 минут)

final class EmailVerificationService {
    static let shared = EmailVerificationService()
    private init() {}

    // Returns the generated code so caller can compare on verify
    @discardableResult
    func sendCode(to email: String) async -> String {
        let code = String(format: "%06d", Int.random(in: 100_000...999_999))

        // If EmailJS is configured — send real email
        if !AppConstants.emailjsPublicKey.isEmpty {
            await sendViaEmailJS(code: code, to: email)
        } else {
            // Development fallback: post a local notification so developer sees the code
            #if DEBUG
            print("────────────────────────────────")
            print("📧 Mono – Verification code for \(email)")
            print("   Code: \(code)")
            print("────────────────────────────────")
            #endif
        }
        return code
    }

    // MARK: - EmailJS integration

    private func sendViaEmailJS(code: String, to email: String) async {
        guard let url = URL(string: "https://api.emailjs.com/api/v1.0/email/send") else { return }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "service_id": AppConstants.emailjsServiceID,
            "template_id": AppConstants.emailjsTemplateID,
            "user_id": AppConstants.emailjsPublicKey,
            "template_params": [
                "to_email": email,
                "code": code,
                "app_name": AppConstants.appName
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let http = response as? HTTPURLResponse
            if http?.statusCode != 200 {
                print("EmailJS error: status \(http?.statusCode ?? -1)")
            }
        } catch {
            print("EmailJS send error: \(error.localizedDescription)")
        }
    }
}
