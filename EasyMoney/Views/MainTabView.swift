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
    private enum DateFilter: String, CaseIterable, Identifiable {
        case all = "All Dates"
        case thisMonth = "This Month"
        case last30Days = "Last 30 Days"

        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?
    @State private var searchText = ""
    @State private var selectedCategory = "All Categories"
    @State private var dateFilter: DateFilter = .all
    @State private var saveError: String?

    private var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty
                || expense.title.localizedCaseInsensitiveContains(searchText)
                || expense.category.localizedCaseInsensitiveContains(searchText)
                || expense.notes.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All Categories"
                || expense.category.caseInsensitiveCompare(selectedCategory) == .orderedSame
            let matchesDate: Bool
            switch dateFilter {
            case .all:
                matchesDate = true
            case .thisMonth:
                matchesDate = Calendar.current.isDate(
                    expense.date,
                    equalTo: .now,
                    toGranularity: .month
                )
            case .last30Days:
                let startDate = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
                matchesDate = expense.date >= startDate && expense.date <= .now
            }
            return matchesSearch && matchesCategory && matchesDate
        }
    }

    private var isFiltering: Bool {
        selectedCategory != "All Categories" || dateFilter != .all
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        expenses.isEmpty ? "No Expenses Yet" : "No Matching Expenses",
                        systemImage: expenses.isEmpty ? "tray" : "magnifyingglass",
                        description: Text(expenses.isEmpty
                            ? "Tap the plus button to add your first expense."
                            : "Try changing your search or filters.")
                    )
                } else {
                    ForEach(filteredExpenses) { expense in
                        Button {
                            editingExpense = expense
                        } label: {
                            TransactionRow(
                                icon: categoryIcon(for: expense.category),
                                title: expense.title,
                                subtitle: expense.category,
                                amount: "-" + expense.amount.formatted(
                                    .currency(code: expense.currencyCode)
                                ),
                                color: categoryColor(for: expense.category)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteExpenses)
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Category", selection: $selectedCategory) {
                            Text("All Categories").tag("All Categories")
                            ForEach(categories) { category in
                                Text(category.name).tag(category.name)
                            }
                        }
                        Picker("Date", selection: $dateFilter) {
                            ForEach(DateFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        if isFiltering {
                            Button("Clear Filters", role: .destructive) {
                                selectedCategory = "All Categories"
                                dateFilter = .all
                            }
                        }
                    } label: {
                        Image(systemName: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter transactions")

                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add expense")
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(item: $editingExpense) {
                AddExpenseView(expense: $0)
            }
            .alert("Could Not Delete Expense", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "Unknown error")
            }
        }
    }

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredExpenses[index])
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}

private struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.category) private var budgets: [Budget]
    @Query private var expenses: [Expense]
    @State private var showingCreateBudget = false
    @State private var editingBudget: Budget?
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if budgets.isEmpty {
                        ContentUnavailableView(
                            "No Budgets Yet",
                            systemImage: "chart.pie",
                            description: Text("Tap the plus button to create a monthly budget.")
                        )
                        .padding(.top, 80)
                    }
                    ForEach(budgets) { budget in
                        BudgetCard(
                            title: budget.category,
                            spent: spentThisMonth(for: budget.category),
                            limit: budget.limit,
                            color: categoryColor(for: budget.category),
                            onEdit: { editingBudget = budget },
                            onDelete: { deleteBudget(budget) }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budgets")
            .toolbar {
                Button { showingCreateBudget = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Create budget")
            }
            .sheet(isPresented: $showingCreateBudget) { BudgetEditorView() }
            .sheet(item: $editingBudget) { BudgetEditorView(budget: $0) }
            .alert("Could Not Delete Budget", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "Unknown error")
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

    private func deleteBudget(_ budget: Budget) {
        modelContext.delete(budget)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
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
    @State private var saveError: String?

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
        .alert("Could Not Save Categories", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "Unknown error")
        }
    }

    private var trimmedName: String {
        newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var categoryAlreadyExists: Bool {
        categories.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    private func addCategory() {
        guard !trimmedName.isEmpty, !categoryAlreadyExists else { return }
        let category = ExpenseCategory(name: trimmedName)
        modelContext.insert(category)
        do {
            try modelContext.save()
            newCategoryName = ""
        } catch {
            modelContext.delete(category)
            saveError = error.localizedDescription
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
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
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Menu {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Budget options for \(title)")
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
