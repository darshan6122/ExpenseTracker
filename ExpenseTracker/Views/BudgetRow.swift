import SwiftUI

struct BudgetRow: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    let budget: Budget
    
    var progress: Double {
        expenseManager.getBudgetProgress(budget)
    }
    
    var remaining: Double {
        expenseManager.getRemainingBudget(budget)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Budget Name and Period
            HStack {
                Text(budget.name)
                    .font(.headline)
                Spacer()
                Text(budget.period.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Category if specified
            if let category = budget.category {
                Text(category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            ProgressView(value: progress)
                .tint(progress > 1.0 ? .red : (progress > 0.9 ? .orange : .blue))
            
            // Amount Details
            HStack {
                Text("Remaining: ")
                    .font(.caption)
                Text(String(format: "$%.2f", remaining))
                    .font(.caption)
                    .foregroundColor(remaining < 0 ? .red : .green)
                Spacer()
                Text("of ")
                    .font(.caption)
                Text(String(format: "$%.2f", budget.amount))
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BudgetRow(budget: Budget(name: "Test Budget", amount: 1000, period: .monthly))
        .environmentObject(ExpenseManager())
} 