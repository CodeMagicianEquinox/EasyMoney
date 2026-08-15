import SwiftUI
import SwiftData

struct SignUpView: View {
    private enum FormField: Hashable {
        case name
        case email
        case password
        case confirmPassword
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("userId") private var userId: String = ""
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var hasAttemptedSignUp = false
    @State private var accountError: String?
    @State private var errorMessage = ""
    @Query private var users: [User]
    @FocusState private var focusedField: FormField?

    private var validationMessage: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter your name."
        }
        if !email.contains("@") || !email.contains(".") {
            return "Enter a valid email address."
        }
        if password.count < 8 {
            return "Password must contain at least 8 characters."
        }
        if password != confirmPassword {
            return "Passwords do not match."
        }
        return nil
    }

    var body: some View {
        ZStack {
            Backgrounds.gradient2
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HeaderView(
                        title: "Create Account",
                        subtitle: "Start managing your money",
                        icon: "person.crop.circle.badge.plus"
                    )
                    .padding(.bottom, 26)

                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("Name")
                        textField(
                            title: "Your full name",
                            text: $name,
                            icon: "person",
                            field: .name
                        )

                        fieldLabel("Email")
                            .padding(.top, 4)
                        textField(
                            title: "you@mail.com",
                            text: $email,
                            icon: "envelope",
                            field: .email,
                            isEmail: true
                        )

                        fieldLabel("Password")
                            .padding(.top, 4)
                        passwordField(
                            title: "At least 8 characters",
                            text: $password,
                            field: .password,
                            showsVisibilityButton: true
                        )

                        fieldLabel("Confirm password")
                            .padding(.top, 4)
                        passwordField(
                            title: "Enter your password again",
                            text: $confirmPassword,
                            field: .confirmPassword
                        )

                        if hasAttemptedSignUp, let validationMessage {
                            Label(validationMessage, systemImage: "exclamationmark.circle.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.red)
                                .padding(.top, 4)
                        }

                        if let accountError {
                            Label(accountError, systemImage: "exclamationmark.circle.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.red)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 25)

                    Button {
                        hasAttemptedSignUp = true
                        focusedField = nil
                        performSignup()
                    } label: {
                        Text("Create account")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 170, height: 36)
                            .background(Color(hex: "#16865A"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.top, 18)

                    Button("Already have an account? Sign in") {
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#16865A"))
                    .padding(.top, 16)
                }
                .padding(.top, 24)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text("\(title):")
            .font(.system(size: 10))
            .foregroundStyle(.black)
    }

    private func textField(
        title: String,
        text: Binding<String>,
        icon: String,
        field: FormField,
        isEmail: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            TextField(title, text: text)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(isEmail ? .never : .words)
                .keyboardType(isEmail ? .emailAddress : .default)
                .autocorrectionDisabled(isEmail)
                .focused($focusedField, equals: field)
        }
        .font(.system(size: 14))
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(focusedField == field ? Color(hex: "#16865A") : .clear, lineWidth: 2)
        }
    }

    private func passwordField(
        title: String,
        text: Binding<String>,
        field: FormField,
        showsVisibilityButton: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Group {
                if isPasswordVisible {
                    TextField(title, text: text)
                } else {
                    SecureField(title, text: text)
                }
            }
            .textFieldStyle(.plain)
            .textInputAutocapitalization(.never)
            .focused($focusedField, equals: field)

            if showsVisibilityButton {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
            }
        }
        .font(.system(size: 14))
        .padding(.leading, 14)
        .padding(.trailing, showsVisibilityButton ? 4 : 14)
        .frame(height: 50)
        .background(.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(focusedField == field ? Color(hex: "#16865A") : .clear, lineWidth: 2)
        }
    }
    private func hideError() {
        errorMessage = ""
    }

    private func performSignup() {
    // data validations
        guard validationMessage == nil else { return }

    // check if the email hasnt been used yet
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !users.contains(where: { $0.email.lowercased() == normalizedEmail }) else {
            accountError = "An account with this email already exists."
            return
        }

        let nameParts = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ", maxSplits: 1)
        let firstName = String(nameParts.first ?? "")
        let lastName = nameParts.count > 1 ? String(nameParts[1]) : ""

// create the account
let user = User(
    firstName: firstName,
    lastName: lastName,
    email: email,
    password_text: password
)

do {
    modelContext.insert(user)
    try modelContext.save()
    print("User created!")

    // auto-login??
    userId = user.id.uuidString
} catch {
    print("Error creating user: \(error)")
    modelContext.delete(user)
    accountError = "The account could not be saved. Please try again."
}
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .modelContainer(for: User.self, inMemory: true)
}
