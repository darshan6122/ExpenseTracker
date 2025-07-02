import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    let budget: Budget
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget Amount")
                        .font(.headline)
                    Text(currencyFormatter.string(from: NSNumber(value: budget.amount)) ?? "")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spent")
                        .font(.headline)
                    Text(currencyFormatter.string(from: NSNumber(value: expenseManager.getBudgetProgress(budget) * budget.amount)) ?? "")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remaining")
                        .font(.headline)
                    Text(currencyFormatter.string(from: NSNumber(value: expenseManager.getRemainingBudget(budget))) ?? "")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
            }
            
            Section("Recent Expenses") {
                ForEach(expenseManager.expenses.filter { expense in
                    let isInPeriod = expense.date >= budget.startDate &&
                                    expense.date <= Calendar.current.date(byAdding: .day, value: budget.period.days, to: budget.startDate)!
                    let matchesCategory = budget.category == nil || budget.category == expense.category.rawValue
                    return isInPeriod && matchesCategory
                }.sorted(by: { $0.date > $1.date })) { expense in
                    TransactionRow(expense: expense)
                }
            }
        }
        .navigationTitle(budget.name)
    }
}

#Preview {
    NavigationView {
        BudgetDetailView(budget: Budget(
            name: "Food Budget",
            amount: 500,
            period: .monthly,
            category: Category.food.rawValue
        ))
        .environmentObject(ExpenseManager())
    }
} 