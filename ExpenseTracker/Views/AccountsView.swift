import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct AccountsView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @State private var showingAddAccount = false
    @State private var selectedAccount: Account?
    @State private var showingFilePicker = false
    @State private var showingImportError = false
    @State private var errorMessage = ""
    @State private var selectedAccountForImport: UUID?
    @State private var showingAccountSelection = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        if expenseManager.accounts.isEmpty {
                            errorMessage = "Please add at least one account before importing expenses."
                            showingImportError = true
                        } else {
                            showingAccountSelection = true
                        }
                    }) {
                        Label("Import CSV", systemImage: "doc.badge.plus")
                    }
                    
                    ForEach(expenseManager.accounts) { account in
                        AccountRow(account: account)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAccount = account
                            }
                    }
                    .onDelete(perform: deleteAccounts)
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
                    .environmentObject(expenseManager)
            }
            .sheet(item: $selectedAccount) { account in
                AccountDetailView(account: account)
                    .environmentObject(expenseManager)
            }
            .sheet(isPresented: $showingAccountSelection) {
                AccountSelectionForImportView(
                    selectedAccountId: $selectedAccountForImport,
                    showingFilePicker: $showingFilePicker
                )
                .environmentObject(expenseManager)
            }
            .alert("Import Error", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteAccounts(at offsets: IndexSet) {
        expenseManager.deleteAccounts(at: offsets)
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [.commaSeparatedText, .text, .plainText]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            parent.onPick(url)
        }
    }
}

struct AccountSelectionForImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    @Binding var selectedAccountId: UUID?
    @Binding var showingFilePicker: Bool
    @State private var showingImportError = false
    @State private var errorMessage = ""
    @State private var showingDocumentPicker = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Instructions")) {
                    Text("1. Select an account below")
                    Text("2. Click Import to choose a CSV file")
                    Text("3. CSV format: Date,Amount,Category,Description")
                    Text("Example: 2024-03-14,25.99,Food,Lunch")
                }
                
                Section(header: Text("Select Account")) {
                    ForEach(expenseManager.accounts) { account in
                        Button(action: {
                            selectedAccountId = account.id
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(account.name)
                                        .font(.headline)
                                    Text(account.identifier)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedAccountId == account.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Import Expenses")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    @State private var importedCount = 0
    
    private func importCSV(from url: URL) {
        guard let accountId = selectedAccountId else { return }
        
        do {
            let contents = try String(contentsOf: url)
            let rows = contents.components(separatedBy: .newlines)
            
            // Skip header row and empty rows
            let dataRows = rows.dropFirst().filter { !$0.isEmpty }
            importedCount = 0
            
            for row in dataRows {
                let columns = row.components(separatedBy: ",")
                guard columns.count >= 4 else { continue }
                
                let dateStr = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let amountStr = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let categoryStr = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let description = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard let date = DateFormatter.csvDate.date(from: dateStr),
                      let amount = Double(amountStr),
                      let category = Category(rawValue: categoryStr) else {
                    continue
                }
                
                let expense = Expense(
                    amount: amount,
                    description: description,
                    category: category,
                    date: date,
                    accountId: accountId
                )
                
                do {
                    try expenseManager.addExpense(expense)
                    importedCount += 1
                } catch {
                    errorMessage = "Failed to import expense: \(error.localizedDescription)"
                }
            }
            
            if importedCount > 0 {
                errorMessage = "Successfully imported \(importedCount) expenses"
                // Force UI update by accessing the expenses
                let _ = expenseManager.expensesForAccount(accountId)
                // Dismiss the sheet after successful import
                DispatchQueue.main.async {
                    dismiss()
                }
            } else {
                errorMessage = "No valid expenses found in the CSV file. Please check the format:\nDate (YYYY-MM-DD),Amount,Category,Description"
            }
            showingImportError = true
        } catch {
            errorMessage = "Failed to read CSV file: \(error.localizedDescription)\nPlease make sure it's a valid CSV file."
            showingImportError = true
        }
    }
}

extension DateFormatter {
    static let csvDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    
    @State private var name = ""
    @State private var identifier = ""
    @State private var initialBalance = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Account Name", text: $name)
                    TextField("Account Identifier (e.g., MAIN, SAV)", text: $identifier)
                        .textInputAutocapitalization(.characters)
                    
                    HStack {
                        Text("C$")
                            .foregroundColor(.secondary)
                        TextField("Initial Balance", text: $initialBalance)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section {
                    Button("Add Account") {
                        addAccount()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(name.isEmpty || identifier.isEmpty)
                }
            }
            .navigationTitle("Add Account")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func addAccount() {
        let balance = Double(initialBalance) ?? 0
        let account = Account(
            name: name,
            identifier: identifier,
            balance: balance
        )
        expenseManager.addAccount(account)
        dismiss()
    }
}

struct AccountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    let account: Account
    
    @State private var showingAddIncome = false
    @State private var incomeAmount = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Balance")
                            .font(.headline)
                        Text(account.balance, format: .currency(code: "CAD"))
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button {
                        showingAddIncome = true
                    } label: {
                        Label("Add Income", systemImage: "plus.circle.fill")
                    }
                }
                
                Section("Recent Transactions") {
                    ForEach(expenseManager.expensesForAccount(account.id).sorted(by: { $0.date > $1.date })) { expense in
                        TransactionRow(expense: expense)
                    }
                }
            }
            .navigationTitle(account.name)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert("Add Income", isPresented: $showingAddIncome) {
                TextField("Amount", text: $incomeAmount)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    addIncome()
                }
                .disabled(incomeAmount.isEmpty)
            } message: {
                Text("Enter the amount to add to your account")
            }
        }
    }
    
    private func addIncome() {
        if let amount = Double(incomeAmount) {
            var updatedAccount = account
            updatedAccount.balance += amount
            expenseManager.updateAccount(updatedAccount)
            incomeAmount = ""
        }
    }
}

struct TransactionRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(expense.description)
                    .font(.headline)
                Text(expense.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(expense.amount, format: .currency(code: "CAD"))
                    .font(.headline)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AccountsView()
} 
