import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @State private var selectedAccountId: UUID?
    
    private var currentMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    private var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var filteredExpenses: [Category: Double] {
        let calendar = Calendar.current
        let filteredExpenses = expenseManager.expenses.filter { expense in
            let sameMonth = calendar.component(.month, from: expense.date) == calendar.component(.month, from: Date())
            let sameYear = calendar.component(.year, from: expense.date) == calendar.component(.year, from: Date())
            let matchesAccount = selectedAccountId == nil || expense.accountId == selectedAccountId
            return sameMonth && sameYear && matchesAccount
        }
        
        var categoryTotals: [Category: Double] = [:]
        for expense in filteredExpenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        return categoryTotals
    }
    
    private var totalExpenses: Double {
        let calendar = Calendar.current
        return expenseManager.expenses.filter { expense in
            let sameMonth = calendar.component(.month, from: expense.date) == calendar.component(.month, from: Date())
            let sameYear = calendar.component(.year, from: expense.date) == calendar.component(.year, from: Date())
            let matchesAccount = selectedAccountId == nil || expense.accountId == selectedAccountId
            return sameMonth && sameYear && matchesAccount
        }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Account", selection: $selectedAccountId) {
                        Text("All Accounts")
                            .tag(Optional<UUID>.none)
                        ForEach(expenseManager.accounts) { account in
                            Text(account.name)
                                .tag(Optional(account.id))
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formattedMonth)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(abs(totalExpenses), format: .currency(code: "CAD"))
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Expenses by Category") {
                    if !filteredExpenses.isEmpty {
                        Chart {
                            ForEach(Array(filteredExpenses.keys), id: \.self) { category in
                                SectorMark(
                                    angle: .value("Amount", abs(filteredExpenses[category] ?? 0)),
                                    innerRadius: .ratio(0.618),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Category", category.rawValue))
                            }
                        }
                        .frame(height: 200)
                        .padding(.vertical, 8)
                    } else {
                        Text("No expenses this month")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Category Breakdown") {
                    if !filteredExpenses.isEmpty {
                        ForEach(Array(filteredExpenses.keys), id: \.self) { category in
                            HStack {
                                Label(category.rawValue, systemImage: category.icon)
                                Spacer()
                                Text(abs(filteredExpenses[category] ?? 0), format: .currency(code: "CAD"))
                            }
                        }
                    } else {
                        Text("No expenses this month")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Analytics")
            .overlay {
                if expenseManager.expenses.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.pie",
                        description: Text("Add some expenses to see analytics")
                    )
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(ExpenseManager())
} 
