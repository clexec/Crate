import SwiftUI

struct LoginView: View {
    var startAsRegister: Bool = false
    @EnvironmentObject private var auth: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var isRegister: Bool
    @State private var showCodeVerification = false
    @State private var showForgot = false
    @State private var isLoading = false
    @State private var localError: String?
    @FocusState private var focused: Field?

    enum Field { case email, name, password, confirmPassword }

    init(startAsRegister: Bool = false) {
        self.startAsRegister = startAsRegister
        _isRegister = State(initialValue: startAsRegister)
    }

    private var canProceed: Bool {
        let emailOK = ValidationHelper.isValidEmail(email)
        let passOK = !password.isEmpty
        if isRegister {
            return emailOK && passOK && !displayName.isEmpty && password == confirmPassword
        }
        return emailOK && passOK
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isRegister ? "Создать аккаунт" : "С возвращением 👋")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text(isRegister ? "Заполните данные для регистрации" : "Войдите в Mono")
                            .font(.subheadline)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    // Fields
                    VStack(spacing: 14) {
                        inputField("Email", placeholder: "email@example.com", text: $email,
                                   keyboard: .emailAddress, focused: $focused, tag: .email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if isRegister {
                            inputField("Имя", placeholder: "Как тебя зовут?", text: $displayName,
                                       focused: $focused, tag: .name)
                        }

                        secureField("Пароль", placeholder: "Минимум 8 символов", text: $password,
                                    focused: $focused, tag: .password)

                        if isRegister {
                            secureField("Подтвердите пароль", placeholder: "Повторите пароль",
                                        text: $confirmPassword, focused: $focused, tag: .confirmPassword)
                        }
                    }

                    // Error
                    if let err = localError ?? auth.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Action button
                    Button { handleAction() } label: {
                        if isLoading {
                            ProgressView().tint(.black).frame(maxWidth: .infinity, minHeight: 52)
                        } else {
                            Text(isRegister ? "Далее" : "Войти")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                    }
                    .background(canProceed ? ColorPalette.accent : ColorPalette.accent.opacity(0.4), in: Capsule())
                    .foregroundStyle(.black)
                    .disabled(!canProceed || isLoading)

                    // Toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRegister.toggle()
                            localError = nil
                            auth.errorMessage = nil
                        }
                    } label: {
                        Text(isRegister ? "Уже есть аккаунт? " : "Нет аккаунта? ")
                            .foregroundStyle(ColorPalette.textSecondary)
                        + Text(isRegister ? "Войти" : "Зарегистрироваться")
                            .foregroundStyle(ColorPalette.accent)
                    }
                    .font(.subheadline)

                    if !isRegister {
                        Button("Забыли пароль?") { showForgot = true }
                            .font(.footnote)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCodeVerification) {
            CodeVerificationView(email: email, displayName: displayName, password: password)
        }
        .sheet(isPresented: $showForgot) {
            ForgotPasswordView()
        }
    }

    // MARK: - Actions

    private func handleAction() {
        focused = nil
        localError = nil
        auth.errorMessage = nil

        if isRegister {
            guard password == confirmPassword else {
                localError = "Пароли не совпадают"
                return
            }
            guard PasswordValidationHelper.isValid(password) else {
                localError = "Пароль слишком слабый (мин. 8 символов, буквы и цифры)"
                return
            }
            showCodeVerification = true
        } else {
            Task {
                isLoading = true
                await auth.signIn(email: email, password: password)
                isLoading = false
            }
        }
    }

    // MARK: - Input helpers

    @ViewBuilder
    private func inputField(_ label: String, placeholder: String, text: Binding<String>,
                            keyboard: UIKeyboardType = .default,
                            focused: FocusState<Field?>.Binding, tag: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ColorPalette.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .focused(focused, equals: tag)
                .submitLabel(.next)
                .padding(14)
                .background(ColorPalette.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.white)
                .tint(ColorPalette.accent)
        }
    }

    @ViewBuilder
    private func secureField(_ label: String, placeholder: String, text: Binding<String>,
                             focused: FocusState<Field?>.Binding, tag: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ColorPalette.textSecondary)
            SecureField(placeholder, text: text)
                .focused(focused, equals: tag)
                .submitLabel(.done)
                .padding(14)
                .background(ColorPalette.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.white)
                .tint(ColorPalette.accent)
        }
    }
}

// MARK: - Email Code Verification

struct CodeVerificationView: View {
    let email: String
    let displayName: String
    let password: String

    @EnvironmentObject private var auth: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var digits = Array(repeating: "", count: 6)
    @State private var sentCode = ""
    @State private var isVerifying = false
    @State private var errorMessage = ""
    @State private var timeRemaining = 60
    @State private var canResend = false
    @State private var isSending = false
    @FocusState private var focusedIndex: Int?

    private var enteredCode: String { digits.joined() }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                // Icon
                ZStack {
                    Circle()
                        .fill(ColorPalette.accent.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(ColorPalette.accent)
                }

                VStack(spacing: 8) {
                    Text("Проверьте почту")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Код отправлен на\n**\(email)**")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                // 6-digit input
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        digitCell(index: i)
                    }
                }
                .padding(.horizontal, 8)

                // Error
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Verify button
                Button { verify() } label: {
                    if isVerifying {
                        ProgressView().tint(.black).frame(maxWidth: .infinity, minHeight: 52)
                    } else {
                        Text("Подтвердить")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                }
                .background(enteredCode.count == 6 ? ColorPalette.accent : ColorPalette.accent.opacity(0.35), in: Capsule())
                .foregroundStyle(.black)
                .disabled(enteredCode.count < 6 || isVerifying)
                .padding(.horizontal, 24)

                // Resend
                if canResend {
                    Button {
                        Task { await resend() }
                    } label: {
                        if isSending {
                            ProgressView().tint(ColorPalette.accent)
                        } else {
                            Text("Отправить повторно")
                                .font(.subheadline)
                                .foregroundStyle(ColorPalette.accent)
                        }
                    }
                } else {
                    Text("Повторная отправка через \(timeRemaining) с")
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                // Debug hint (only in simulator/debug)
                #if DEBUG
                if !sentCode.isEmpty && AppConstants.emailjsPublicKey.isEmpty {
                    Text("DEBUG: \(sentCode)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(ColorPalette.textSecondary.opacity(0.6))
                }
                #endif

                Spacer()
            }
            .padding()
        }
        .onAppear { Task { await sendCode() }; startTimer() }
    }

    // MARK: - Digit cell

    @ViewBuilder
    private func digitCell(index: Int) -> some View {
        TextField("", text: $digits[index])
            .keyboardType(.numberPad)
            .font(.title2.bold())
            .multilineTextAlignment(.center)
            .frame(width: 46, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ColorPalette.elevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(focusedIndex == index ? ColorPalette.accent : Color.clear, lineWidth: 1.5)
                    )
            )
            .foregroundStyle(.white)
            .tint(ColorPalette.accent)
            .focused($focusedIndex, equals: index)
            .onChange(of: digits[index]) { _, newVal in
                let filtered = newVal.filter(\.isNumber)
                if filtered.count > 1 {
                    // Handle paste: distribute digits across all cells
                    let chars = Array(filtered.prefix(6))
                    for (i, ch) in chars.enumerated() {
                        if i < digits.count { digits[i] = String(ch) }
                    }
                    focusedIndex = nil
                } else {
                    digits[index] = String(filtered.prefix(1))
                    if !filtered.isEmpty && index < 5 {
                        focusedIndex = index + 1
                    }
                }
            }
    }

    // MARK: - Logic

    private func sendCode() async {
        isSending = true
        sentCode = await EmailVerificationService.shared.sendCode(to: email)
        isSending = false
    }

    private func resend() async {
        digits = Array(repeating: "", count: 6)
        errorMessage = ""
        canResend = false
        timeRemaining = 60
        await sendCode()
        startTimer()
        focusedIndex = 0
    }

    private func verify() {
        guard enteredCode.count == 6 else { return }
        if enteredCode == sentCode {
            isVerifying = true
            Task {
                await auth.register(email: email, password: password, displayName: displayName)
                isVerifying = false
                dismiss()
            }
        } else {
            errorMessage = "Неверный код. Попробуйте ещё раз."
            withAnimation(.spring(response: 0.3)) { digits = Array(repeating: "", count: 6) }
            focusedIndex = 0
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSent = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    if isSent {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.green)
                            Text("Готово!")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Инструкции отправлены на\n\(email)")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(ColorPalette.textSecondary)
                            Button("Закрыть") { dismiss() }
                                .thereButtonStyle()
                                .padding(.top, 8)
                        }
                    } else {
                        Text("Сброс пароля")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(ColorPalette.textSecondary)
                            TextField("email@example.com", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(ColorPalette.elevated, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }

                        Button("Отправить инструкции") {
                            isSent = true
                        }
                        .thereButtonStyle()
                        .disabled(email.isEmpty)
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(ColorPalette.accent)
                }
            }
        }
    }
}

typealias RegisterView = LoginView
typealias PasswordCreationView = LoginView
struct AuthButtonsView: View { var body: some View { EmptyView() } }
