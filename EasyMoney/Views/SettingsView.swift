import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("userId") private var loggedInUserId = ""
    @AppStorage("isDarkMode1") private var isDarkMode = false
    @AppStorage("showColorInExpense") private var showColor = true
    @Query private var users: [User]

    private var currentUser: User? {
        guard let id = UUID(uuidString: loggedInUserId) else { return nil }
        return users.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let currentUser {
                        HStack(spacing: 14) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(hex: "#16865A"))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(displayName(for: currentUser)).font(.headline)
                                Text(currentUser.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        ContentUnavailableView(
                            "Account Not Found",
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            description: Text("Sign in again to reload your account.")
                        )
                    }
                }

                if let currentUser {
                    Section("Account") {
                        NavigationLink {
                            EditProfileView(user: currentUser)
                        } label: {
                            Label("Edit Profile", systemImage: "person.crop.circle.badge.checkmark")
                        }
                    }
                }

                Section("Preferences") {
                    Toggle("Dark Mode", systemImage: "moon.fill", isOn: $isDarkMode)
                    Toggle("Category Colors", systemImage: "paintpalette.fill", isOn: $showColor)
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label("Categories", systemImage: "square.grid.2x2")
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        loggedInUserId = ""
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private func displayName(for user: User) -> String {
        let name = "\(user.firstName) \(user.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "EasyMoney User" : name
    }
}

private struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    let user: User

    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    init(user: User) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _email = State(initialValue: user.email)
    }

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("First name", text: $firstName).textContentType(.givenName)
                TextField("Last name", text: $lastName).textContentType(.familyName)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            Section("Change Password") {
                SecureField("Current password", text: $currentPassword)
                SecureField("New password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
                Text("Leave these fields empty to keep your existing password.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: saveProfile)
            }
        }
        .alert("Profile Updated", isPresented: $showingSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your account information was saved.")
        }
    }

    private func saveProfile() {
        errorMessage = nil
        let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !cleanFirstName.isEmpty else {
            errorMessage = "Enter your first name."
            return
        }
        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            errorMessage = "Enter a valid email address."
            return
        }
        guard !users.contains(where: {
            $0.id != user.id && $0.email.caseInsensitiveCompare(normalizedEmail) == .orderedSame
        }) else {
            errorMessage = "Another account already uses this email address."
            return
        }

        let wantsPasswordChange = !currentPassword.isEmpty || !newPassword.isEmpty || !confirmPassword.isEmpty
        if wantsPasswordChange {
            guard User.hashPassword(currentPassword) == user.password else {
                errorMessage = "Your current password is incorrect."
                return
            }
            guard newPassword.count >= 8 else {
                errorMessage = "The new password must contain at least 8 characters."
                return
            }
            guard newPassword == confirmPassword else {
                errorMessage = "The new passwords do not match."
                return
            }
        }

        let oldFirstName = user.firstName
        let oldLastName = user.lastName
        let oldEmail = user.email
        let oldPassword = user.password

        user.firstName = cleanFirstName
        user.lastName = cleanLastName
        user.email = normalizedEmail
        if wantsPasswordChange { user.password = User.hashPassword(newPassword) }

        do {
            try modelContext.save()
            showingSuccess = true
        } catch {
            user.firstName = oldFirstName
            user.lastName = oldLastName
            user.email = oldEmail
            user.password = oldPassword
            errorMessage = "Your profile could not be saved. Please try again."
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [User.self, ExpenseCategory.self], inMemory: true)
}
