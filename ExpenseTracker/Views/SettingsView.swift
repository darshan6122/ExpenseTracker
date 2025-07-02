import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @State private var showingFilePicker = false
    @State private var showingImportError = false
    @State private var errorMessage = ""
    @State private var selectedAccountId: UUID?
    @State private var showingAccountSelection = false
    @State private var showingClearConfirmation = false
    @State private var confirmationText = ""
    @State private var showingExportOptions = false
    @State private var showingAccountBalances = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        showingAccountSelection = true
                    }) {
                        Label("Import CSV", systemImage: "doc.badge.plus")
                    }
                    .disabled(expenseManager.accounts.isEmpty)
                    
                    Button(action: {
                        showingExportOptions = true
                    }) {
                        Label("Export Expenses", systemImage: "square.and.arrow.up")
                    }
                    .disabled(expenseManager.expenses.isEmpty)
                } header: {
                    Text("Data")
                } footer: {
                    Text("Import expenses from a CSV file or export your data in CSV/PDF format")
                }
                
                Section {
                    Button(action: {
                        showingAccountBalances = true
                    }) {
                        Label("Edit Account Balances", systemImage: "banknote")
                    }
                    .disabled(expenseManager.accounts.isEmpty)
                    
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Label("Clear All Expenses", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Account Management")
                }
                
                Section("Account Management") {
                    NavigationLink(destination: AccountManagementView()) {
                        Label("Manage Accounts", systemImage: "creditcard")
                    }
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Expenses", isPresented: $showingClearConfirmation) {
                TextField("Type 'delete' to confirm", text: $confirmationText)
                    .autocapitalization(.none)
                Button("Cancel", role: .cancel) {
                    confirmationText = ""
                }
                Button("Clear All", role: .destructive) {
                    if confirmationText.lowercased() == "delete" {
                        expenseManager.clearAllExpenses()
                    }
                    confirmationText = ""
                }
                .disabled(confirmationText.lowercased() != "delete")
            } message: {
                Text("This action cannot be undone. Type 'delete' to confirm that you want to permanently remove all expenses.")
            }
            .sheet(isPresented: $showingAccountSelection) {
                AccountSelectionView(selectedAccountId: $selectedAccountId, showingFilePicker: $showingFilePicker)
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView()
            }
            .sheet(isPresented: $showingAccountBalances) {
                AccountBalanceView()
            }
        }
    }
}

struct AccountSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    @Binding var selectedAccountId: UUID?
    @Binding var showingFilePicker: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(expenseManager.accounts) { account in
                    HStack {
                        Text(account.name)
                        Spacer()
                        if selectedAccountId == account.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAccountId = account.id
                        dismiss()
                        showingFilePicker = true
                    }
                }
            }
            .navigationTitle("Select Account")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environmentObject(ExpenseManager())
} 