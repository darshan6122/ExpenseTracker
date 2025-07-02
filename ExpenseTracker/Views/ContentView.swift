import SwiftUI

struct ContentView: View {
    @StateObject private var expenseManager = ExpenseManager()
    @State private var showingAddAccount = false
    @State private var showingAddBudget = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Accounts") {
                    ForEach(expenseManager.accounts) { account in
                        NavigationLink {
                            AccountDetailView(expenseManager: expenseManager, account: account)
                        } label: {
                            AccountRow(account: account)
                        }
                    }
                }
                
                Section("Budgets") {
                    ForEach(expenseManager.budgets) { budget in
                        NavigationLink {
                            BudgetDetailView(expenseManager: expenseManager, budget: budget)
                        } label: {
                            BudgetRow(budget: budget)
                        }
                    }
                }
                
                Section("Recurring Expenses") {
                    NavigationLink {
                        RecurringExpenseListView(expenseManager: expenseManager)
                    } label: {
                        Label("Manage Recurring Expenses", systemImage: "repeat")
                    }
                }
            }
            .navigationTitle("Expense Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddAccount = true
                        } label: {
                            Label("Add Account", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingAddBudget = true
                        } label: {
                            Label("Add Budget", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView(expenseManager: expenseManager)
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView(expenseManager: expenseManager)
            }
        }
    }
}

#Preview {
    ContentView()
} 