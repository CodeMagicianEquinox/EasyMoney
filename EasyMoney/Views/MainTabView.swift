import SwiftUI

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
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total balance")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("$8,420.50")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("+$640 this month")
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
                        SummaryCard(title: "Income", value: "$3,800", icon: "arrow.down.left", color: .green)
                        SummaryCard(title: "Spent", value: "$2,145", icon: "arrow.up.right", color: .orange)
                    }

                    HStack {
                        Text("Recent activity")
                            .font(.title3.bold())
                        Spacer()
                        Text("August")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        TransactionRow(icon: "cart.fill", title: "Groceries", subtitle: "Today", amount: "-$84.20", color: .orange)
                        Divider().padding(.leading, 54)
                        TransactionRow(icon: "banknote.fill", title: "Salary", subtitle: "Aug 9", amount: "+$1,900.00", color: .green)
                        Divider().padding(.leading, 54)
                        TransactionRow(icon: "fuelpump.fill", title: "Fuel", subtitle: "Aug 8", amount: "-$52.75", color: .blue)
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
    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    TransactionRow(icon: "cart.fill", title: "Groceries", subtitle: "Food", amount: "-$84.20", color: .orange)
                    TransactionRow(icon: "cup.and.saucer.fill", title: "Coffee", subtitle: "Dining", amount: "-$5.80", color: .brown)
                }
                Section("Earlier") {
                    TransactionRow(icon: "banknote.fill", title: "Salary", subtitle: "Income", amount: "+$1,900.00", color: .green)
                    TransactionRow(icon: "fuelpump.fill", title: "Fuel", subtitle: "Transport", amount: "-$52.75", color: .blue)
                    TransactionRow(icon: "bolt.fill", title: "Electric bill", subtitle: "Utilities", amount: "-$96.40", color: .yellow)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                Button(action: {}) { Image(systemName: "plus") }
            }
        }
    }
}

private struct BudgetsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BudgetCard(title: "Food", spent: 420, limit: 700, color: .orange)
                    BudgetCard(title: "Transport", spent: 180, limit: 350, color: .blue)
                    BudgetCard(title: "Entertainment", spent: 145, limit: 200, color: .purple)
                    BudgetCard(title: "Shopping", spent: 310, limit: 500, color: .pink)
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
}

private struct SettingsView: View {
    @AppStorage("isDemoUserLoggedIn") private var isDemoUserLoggedIn = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(Color(hex: "#16865A"))
                        VStack(alignment: .leading) {
                            Text("Demo User").fontWeight(.semibold)
                            Text(DemoAccount.email).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Preferences") {
                    Label("Currency", systemImage: "dollarsign.circle")
                    Label("Notifications", systemImage: "bell")
                    Label("Categories", systemImage: "square.grid.2x2")
                }
                Section {
                    Button("Sign out", role: .destructive) {
                        isDemoUserLoggedIn = false
                    }
                }
            }
            .navigationTitle("Settings")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("$\(spent, specifier: "%.0f") of $\(limit, specifier: "%.0f")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: spent, total: limit).tint(color)
            Text("$\(limit - spent, specifier: "%.0f") remaining")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MainTabView()
}
