import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @Query private var budgets: [Budget]
    @AppStorage("budgetAlertsEnabled") private var budgetAlertsEnabled = false

    private let expense: Expense?

    @State private var title = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var category = "Food"
    @State private var notes = ""
    @State private var saveError: String?

    init(expense: Expense? = nil) {
        self.expense = expense
        _title = State(initialValue: expense?.title ?? "")
        _amountText = State(initialValue: expense.map { String($0.amount) } ?? "")
        _date = State(initialValue: expense?.date ?? .now)
        _category = State(initialValue: expense?.category ?? "Food")
        _notes = State(initialValue: expense?.notes ?? "")
    }

    private var amount: Double? {
        Double(amountText)
    }

    private var formIsValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category.name)
                        }
                    }

                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .onAppear {
                if !categories.contains(where: { $0.name == category }),
                   let firstCategory = categories.first {
                    category = firstCategory.name
                }
            }
            .alert("Could Not Save Expense", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "Unknown error")
            }
            .navigationTitle(expense == nil ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(expense == nil ? "Save" : "Update") {
                        saveExpense()
                    }
                    .disabled(!formIsValid)
                }
            }
        }
    }

    private func saveExpense() {
        guard let amount else { return }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let expenseToSave = expense ?? Expense(
            title: cleanTitle,
            amount: amount,
            date: date,
            category: category,
            currencyCode: "USD",
            exchangeRate: 1,
            notes: cleanNotes
        )
        let originalValues = (
            expenseToSave.title,
            expenseToSave.amount,
            expenseToSave.date,
            expenseToSave.category,
            expenseToSave.notes
        )

        expenseToSave.title = cleanTitle
        expenseToSave.amount = amount
        expenseToSave.date = date
        expenseToSave.category = category
        expenseToSave.notes = cleanNotes
        if expense == nil { modelContext.insert(expenseToSave) }

        do {
            try modelContext.save()
            sendBudgetAlertIfNeeded(for: expenseToSave)
            dismiss()
        } catch {
            if expense == nil {
                modelContext.delete(expenseToSave)
            } else {
                expenseToSave.title = originalValues.0
                expenseToSave.amount = originalValues.1
                expenseToSave.date = originalValues.2
                expenseToSave.category = originalValues.3
                expenseToSave.notes = originalValues.4
            }
            saveError = error.localizedDescription
        }
    }

    private func sendBudgetAlertIfNeeded(for expense: Expense) {
        guard budgetAlertsEnabled else { return }

        let descriptor = FetchDescriptor<Expense>()
        guard let expenses = try? modelContext.fetch(descriptor) else { return }
        let currentSpent = expenses
            .filter {
                $0.category.caseInsensitiveCompare(expense.category) == .orderedSame
                    && Calendar.current.isDate($0.date, equalTo: expense.date, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }

        guard let budget = budgets.first(where: {
            $0.category.caseInsensitiveCompare(expense.category) == .orderedSame
        }) else { return }

        BudgetNotificationManager.shared.sendAlertIfNeeded(
            category: expense.category,
            previousSpent: max(0, currentSpent - expense.amount),
            currentSpent: currentSpent,
            limit: budget.limit,
            date: expense.date
        )
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Expense.self, ExpenseCategory.self, Budget.self], inMemory: true)
}
