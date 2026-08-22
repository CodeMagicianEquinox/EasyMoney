import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @State private var title = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var category = "Food"
    @State private var notes = ""
    @State private var saveError: String?

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
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!formIsValid)
                }
            }
        }
    }

    private func saveExpense() {
        guard let amount else { return }

        let expense = Expense(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            date: date,
            category: category,
            currencyCode: "USD",
            exchangeRate: 1,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        modelContext.insert(expense)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(expense)
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Expense.self, ExpenseCategory.self], inMemory: true)
}
