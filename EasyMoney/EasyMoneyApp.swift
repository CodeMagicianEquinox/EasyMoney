//
//  EasyMoneyApp.swift
//  EasyMoney
//
//  Created by Tim Terrance on 8/4/26.
//

import SwiftUI
import SwiftData

@main
struct EasyMoneyApp: App {
    @AppStorage("seenWelcomeView") private var seenWelcomeView: Bool = false
    @AppStorage("userId") private var userId: String = ""

    init() {
        _ = BudgetNotificationManager.shared
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            MoneyTransaction.self,
            Expense.self,
            ExpenseCategory.self,
            Budget.self,
        ])
        
        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            let context = container.mainContext
            let existingCategories = try context.fetch(FetchDescriptor<ExpenseCategory>())
            if existingCategories.isEmpty {
                for category in ExpenseCategory.defaults {
                    context.insert(
                        ExpenseCategory(name: category.name, iconName: category.icon)
                    )
                }
                try context.save()
            }

            let existingBudgets = try context.fetch(FetchDescriptor<Budget>())
            if existingBudgets.isEmpty {
                let categories = try context.fetch(FetchDescriptor<ExpenseCategory>())
                for category in categories {
                    context.insert(Budget(
                        category: category.name,
                        limit: BudgetRules.defaultLimit(for: category.name)
                    ))
                }
                try context.save()
            }
            return container
        } catch {
            fatalError("Error setting up SwiftData: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if !seenWelcomeView {
                OnboardingView()
            } else {
                if userId.isEmpty {
                    // no user logged in
                    NavigationStack {
                        LoginView()
                    }
                }
                else {
                    // already logged in
                    ContentView()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
