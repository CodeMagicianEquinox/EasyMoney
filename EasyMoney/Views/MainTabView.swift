import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView() // Home View
                .tabItem { Label("Home", systemImage: "house.fill") }

            TransactionsView() // Activity View
                .tabItem { Label("Activity", systemImage: "list.bullet.rectangle") }

            BudgetsView()
                .tabItem { Label("Budgets", systemImage: "chart.pie.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(hex: "#16865A"))
    }
}

private struct DashboardView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    private var recentExpenses: ArraySlice<Expense> {
        expenses.prefix(3)
    }

    private var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var spentThisMonth: Double {
        expenses
            .filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total expenses")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(totalSpent.formatted(.currency(code: "USD")))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(spentThisMonth.formatted(.currency(code: "USD"))) this month")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(Backgrounds.gradient3)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text("This month")
                        .font(.title3.bold())

                    HStack(spacing: 12) {
                        SummaryCard(title: "Expenses", value: totalSpent.formatted(.currency(code: "USD")), icon: "arrow.up.right", color: .orange)
                        SummaryCard(title: "This month", value: spentThisMonth.formatted(.currency(code: "USD")), icon: "calendar", color: .blue)
                    }

                    HStack {
                        Text("Recent activity")
                            .font(.title3.bold())
                        Spacer()
                        Text(Date.now.formatted(.dateTime.month(.wide)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        if recentExpenses.isEmpty {
                            ContentUnavailableView(
                                "No Recent Expenses",
                                systemImage: "clock",
                                description: Text("Expenses you save will appear here.")
                            )
                            .padding()
                        } else {
                            ForEach(recentExpenses) { expense in
                                TransactionRow(
                                    icon: categoryIcon(for: expense.category),
                                    title: expense.title,
                                    subtitle: expense.date.formatted(date: .abbreviated, time: .omitted),
                                    amount: "-" + expense.amount.formatted(.currency(code: "USD")),
                                    color: categoryColor(for: expense.category)
                                )
                                Divider().padding(.leading, 54)
                            }
                        }
                    }
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hello, Demo")
        }
    }
}

private struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showingAddExpense = false

    var body: some View {
        NavigationStack {
            List {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses Yet",
                        systemImage: "tray",
                        description: Text("Tap the plus button to add your first expense.")
                    )
                } else {
                    ForEach(expenses) { expense in
                        TransactionRow(
                            icon: "creditcard.fill",
                            title: expense.title,
                            subtitle: expense.category,
                            amount: "-" + expense.amount.formatted(
                                .currency(code: "USD")
                            ),
                            color: .orange
                        )
                    }
                    .onDelete(perform: deleteExpenses)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add expense")
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
        try? modelContext.save()
    }
}

private struct BudgetsView: View {
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @Query private var expenses: [Expense]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(categories) { category in
                        BudgetCard(
                            title: category.name,
                            spent: spentThisMonth(for: category.name),
                            limit: budgetLimit(for: category.name),
                            color: categoryColor(for: category.name)
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budgets")
            .toolbar {
                Button(action: {}) { Image(systemName: "plus") }
            }
        }
    }

    private func spentThisMonth(for category: String) -> Double {
        expenses
            .filter {
                $0.category.caseInsensitiveCompare(category) == .orderedSame
                    && Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }

    private func budgetLimit(for category: String) -> Double {
        switch category.lowercased() {
        case "food": return 700
        case "transport": return 350
        case "entertainment": return 200
        case "shopping": return 500
        case "bills": return 800
        default: return 500
        }
    }
}

private struct LegacySettingsView: View {
    @AppStorage("userId") private var userId: String = ""
    @Query private var users: [User]

    private var currentUser: User? {
        guard let id = UUID(uuidString: userId) else { return nil }
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
                                Text(displayName(for: currentUser))
                                    .font(.headline)
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
                            LegacyEditProfileView(user: currentUser)
                        } label: {
                            Label("Edit Profile", systemImage: "person.crop.circle.badge.checkmark")
                        }
                    }
                }

                Section("Preferences") {
                    Label("Currency", systemImage: "dollarsign.circle")
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label("Categories", systemImage: "square.grid.2x2")
                    }
                }
                Section {
                    Button("Sign out", role: .destructive) {
                        userId = ""
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func displayName(for user: User) -> String {
        let name = "\(user.firstName) \(user.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "EasyMoney User" : name
    }
}

private struct LegacyEditProfileView: View {
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
                TextField("First name", text: $firstName)
                    .textContentType(.givenName)
                TextField("Last name", text: $lastName)
                    .textContentType(.familyName)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            Section("Change Password") {
                SecureField("Current password", text: $currentPassword)
                    .textContentType(.password)
                SecureField("New password", text: $newPassword)
                    .textContentType(.newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
                    .textContentType(.newPassword)

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
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your account information was saved.")
        }
    }

    private func saveProfile() {
        errorMessage = nil

        let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

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

        let wantsPasswordChange = !currentPassword.isEmpty
            || !newPassword.isEmpty
            || !confirmPassword.isEmpty

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
        if wantsPasswordChange {
            user.password = User.hashPassword(newPassword)
        }

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

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @State private var newCategoryName = ""

    var body: some View {
        List {
            Section("New Category") {
                HStack {
                    TextField("Category name", text: $newCategoryName)
                    Button("Add", action: addCategory)
                        .disabled(trimmedName.isEmpty || categoryAlreadyExists)
                }
            }

            Section("Expense Categories") {
                ForEach(categories) { category in
                    Label(category.name, systemImage: category.iconName)
                }
                .onDelete(perform: deleteCategories)
            }
        }
        .navigationTitle("Categories")
    }

    private var trimmedName: String {
        newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var categoryAlreadyExists: Bool {
        categories.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    private func addCategory() {
        guard !trimmedName.isEmpty, !categoryAlreadyExists else { return }
        modelContext.insert(ExpenseCategory(name: trimmedName))
        try? modelContext.save()
        newCategoryName = ""
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
        try? modelContext.save()
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct TransactionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let amount: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(amount).font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 10)
    }
}

private struct BudgetCard: View {
    let title: String
    let spent: Double
    let limit: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(spent.formatted(.currency(code: "USD"))) of \(limit.formatted(.currency(code: "USD")))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: spent, total: limit).tint(color)
            Text(remainingText)
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var remainingText: String {
        if spent > limit {
            return "\((spent - limit).formatted(.currency(code: "USD"))) over budget"
        }
        return "\((limit - spent).formatted(.currency(code: "USD"))) remaining"
    }
}

private func categoryIcon(for category: String) -> String {
    switch category.lowercased() {
    case "food": return "fork.knife"
    case "transport": return "car.fill"
    case "shopping": return "bag.fill"
    case "bills": return "doc.text.fill"
    case "entertainment": return "gamecontroller.fill"
    default: return "tag.fill"
    }
}

private func categoryColor(for category: String) -> Color {
    switch category.lowercased() {
    case "food": return .orange
    case "transport": return .blue
    case "shopping": return .pink
    case "bills": return .purple
    case "entertainment": return .indigo
    default: return .green
    }
}

#Preview {
    MainTabView()
        .modelContainer(
            for: [User.self, Expense.self, ExpenseCategory.self],
            inMemory: true
        )
}
