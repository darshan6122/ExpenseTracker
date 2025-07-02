import SwiftUI

struct AccountManagementView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @State private var showingAddAccount = false
    @State private var showingEditAccount: Account?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            ForEach(expenseManager.accounts) { account in
                AccountRow(account: account)
                    .onTapGesture {
                        showingEditAccount = account
                    }
            }
            .onDelete(perform: deleteAccounts)
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddAccount = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            NavigationView {
                AccountFormView(mode: .add)
            }
        }
        .sheet(item: $showingEditAccount) { account in
            NavigationView {
                AccountFormView(mode: .edit(account))
            }
        }
        .alert("Account Management", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            let account = expenseManager.accounts[index]
            if expenseManager.hasExpenses(for: account) {
                alertMessage = "Cannot delete account '\(account.name)' as it has associated expenses."
                showingAlert = true
                return
            }
        }
        expenseManager.deleteAccounts(at: offsets)
    }
}

struct AccountFormView: View {
    enum Mode {
        case add
        case edit(Account)
    }
    
    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    
    @State private var name = ""
    @State private var identifier = ""
    @State private var balance = 0.0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var isEditing: Bool {
        switch mode {
        case .add: return false
        case .edit: return true
        }
    }
    
    var body: some View {
        Form {
            Section("Account Details") {
                TextField("Account Name", text: $name)
                TextField("Account Identifier (e.g., MAIN, SAV)", text: $identifier)
                    .textInputAutocapitalization(.characters)
                
                HStack {
                    Text("Balance")
                    Spacer()
                    TextField("Balance", value: $balance, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Account" : "New Account")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveAccount()
                }
            }
        }
        .onAppear {
            if case .edit(let account) = mode {
                name = account.name
                identifier = account.identifier
                balance = account.balance
            }
        }
        .alert("Account Management", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveAccount() {
        // Validate input
        guard !name.isEmpty else {
            alertMessage = "Please enter an account name."
            showingAlert = true
            return
        }
        
        guard !identifier.isEmpty else {
            alertMessage = "Please enter an account identifier."
            showingAlert = true
            return
        }
        
        let cleanIdentifier = identifier.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if identifier is unique
        let otherAccounts = expenseManager.accounts.filter { account in
            if case .edit(let editingAccount) = mode {
                return account.id != editingAccount.id
            }
            return true
        }
        
        if otherAccounts.contains(where: { $0.identifier == cleanIdentifier }) {
            alertMessage = "An account with this identifier already exists."
            showingAlert = true
            return
        }
        
        // Save account
        switch mode {
        case .add:
            let newAccount = Account(
                name: name,
                identifier: cleanIdentifier,
                balance: balance
            )
            expenseManager.addAccount(newAccount)
            
        case .edit(let account):
            var updatedAccount = account
            updatedAccount.name = name
            updatedAccount.identifier = cleanIdentifier
            updatedAccount.balance = balance
            expenseManager.updateAccount(updatedAccount)
        }
        
        dismiss()
    }
} 