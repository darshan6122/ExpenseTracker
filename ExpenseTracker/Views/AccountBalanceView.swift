import SwiftUI

struct AccountBalanceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseManager: ExpenseManager
    
    @State private var editedBalances: [UUID: String] = [:]
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(expenseManager.accounts) { account in
                    Section(header: Text(account.name)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField(
                                "Balance",
                                text: Binding(
                                    get: { editedBalances[account.id] ?? formatBalance(account.balance) },
                                    set: { editedBalances[account.id] = $0 }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if let currentText = editedBalances[account.id],
                               let newBalance = parseBalance(currentText),
                               newBalance != account.balance {
                                Text("New balance: \(currencyFormatter.string(from: NSNumber(value: newBalance)) ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Edit Account Balances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBalances()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func formatBalance(_ balance: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: balance)) ?? String(format: "%.2f", balance)
    }
    
    private func parseBalance(_ text: String) -> Double? {
        // Remove currency symbol and other formatting
        let cleanText = text.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
        return Double(cleanText)
    }
    
    private func saveBalances() {
        var hasError = false
        
        for (accountId, balanceText) in editedBalances {
            guard let account = expenseManager.accounts.first(where: { $0.id == accountId }),
                  let newBalance = parseBalance(balanceText) else {
                continue
            }
            
            if newBalance != account.balance {
                do {
                    try expenseManager.updateAccountBalance(accountId: accountId, newBalance: newBalance)
                } catch {
                    hasError = true
                    alertMessage = "Failed to update balance for \(account.name)"
                    break
                }
            }
        }
        
        if hasError {
            showingAlert = true
        } else {
            dismiss()
        }
    }
}

#Preview {
    AccountBalanceView()
        .environmentObject(ExpenseManager())
} 