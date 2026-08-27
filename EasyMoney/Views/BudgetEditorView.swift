import SwiftUI
import SwiftData

struct BudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    private let budget: Budget?
    @State private var category: String
    @State private var limitText: String
    @State private var saveError: String?

    init(budget: Budget? = nil) {
        self.budget = budget
        _category = State(initialValue: budget?.category ?? "")
        _limitText = State(initialValue: budget.map { String($0.limit) } ?? "")
    }

    private var limit: Double? { Double(limitText) }
    private var formIsValid: Bool { !category.isEmpty && (limit ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget") {
                    Picker("Category", selection: $category) {
                        ForEach(categories) { item in
                            Label(item.name, systemImage: item.iconName).tag(item.name)
                        }
                    }
                    .disabled(budget != nil)

                    TextField("Monthly limit", text: $limitText)
                        .keyboardType(.decimalPad)
                }
            }
            .onAppear {
                if category.isEmpty { category = categories.first?.name ?? "" }
            }
            .navigationTitle(budget == nil ? "Create Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveBudget).disabled(!formIsValid)
                }
            }
            .alert("Could Not Save Budget", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "Unknown error")
            }
        }
    }

    private func saveBudget() {
        guard let limit, limit > 0 else { return }

        let descriptor = FetchDescriptor<Budget>()
        let existingBudget = (try? modelContext.fetch(descriptor))?.first {
            $0.category.caseInsensitiveCompare(category) == .orderedSame
        }
        let budgetToSave = budget ?? existingBudget ?? Budget(category: category, limit: limit)
        let oldLimit = budgetToSave.limit
        budgetToSave.limit = limit
        if budget == nil, existingBudget == nil { modelContext.insert(budgetToSave) }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            budgetToSave.limit = oldLimit
            if budget == nil, existingBudget == nil { modelContext.delete(budgetToSave) }
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    BudgetEditorView()
        .modelContainer(for: [Budget.self, ExpenseCategory.self], inMemory: true)
}
