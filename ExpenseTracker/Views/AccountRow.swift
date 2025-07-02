import SwiftUI
import Foundation

struct AccountRow: View {
    let account: Account
    @EnvironmentObject var expenseManager: ExpenseManager
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
    
    init(account: Account) {
        self.account = account
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(account.name)
                    .font(.headline)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: account.balance)) ?? "")
                    .font(.headline)
                    .foregroundColor(account.balance >= 0 ? .green : .red)
            }
            
            HStack {
                Text("ID: \(account.identifier)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(account.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AccountRow(account: Account(name: "Test Account", identifier: "TEST", balance: 1000.0))
        .environmentObject(ExpenseManager())
} 