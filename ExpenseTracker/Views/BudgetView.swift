import SwiftUI
import Foundation

struct BudgetView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @State private var showingAddBudget = false
    
    var body: some View {
        NavigationView {
            List {
                // Active Budgets Section
                Section(header: Text("Active Budgets")) {
                    ForEach(expenseManager.getActiveBudgets()) { budget in
                        BudgetRow(budget: budget)
                    }
                    .onDelete(perform: deleteBudgets)
                }
                
                // Add Budget Button
                Section {
                    Button(action: {
                        showingAddBudget = true
                    }) {
                        Label("Add New Budget", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Budgets")
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView()
            }
        }
    }
    
    private func deleteBudgets(at offsets: IndexSet) {
        let budgetsToDelete = offsets.map { expenseManager.getActiveBudgets()[$0] }
        budgetsToDelete.forEach { expenseManager.deleteBudget($0) }
    }
}

struct AddBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    
    @State private var name = ""
    @State private var amount = ""
    @State private var period = Budget.BudgetPeriod.monthly
    @State private var selectedCategory: ExpenseTracker.Category?
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Budget Name", text: $name)
                
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                
                Picker("Period", selection: $period) {
                    ForEach(Budget.BudgetPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                
                Picker("Category (Optional)", selection: $selectedCategory) {
                    Text("All Categories").tag(Optional<ExpenseTracker.Category>.none)
                    ForEach(ExpenseTracker.Category.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(Optional(category))
                    }
                }
            }
            .navigationTitle("New Budget")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if let amountDouble = Double(amount), !name.isEmpty {
                        let newBudget = Budget(
                            name: name,
                            amount: amountDouble,
                            period: period,
                            category: selectedCategory?.rawValue
                        )
                        expenseManager.addBudget(newBudget)
                        dismiss()
                    }
                }
                .disabled(name.isEmpty || amount.isEmpty)
            )
        }
    }
}

struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetView()
            .environmentObject(ExpenseManager())
    }
} 