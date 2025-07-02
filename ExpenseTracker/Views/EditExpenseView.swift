import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    let expense: Expense
    
    @State private var amount: String
    @State private var description: String
    @State private var category: Category
    @State private var date: Date
    @State private var isRecurring: Bool
    @State private var selectedAccountId: UUID
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(expense: Expense) {
        self.expense = expense
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _description = State(initialValue: expense.description)
        _category = State(initialValue: expense.category)
        _date = State(initialValue: expense.date)
        _isRecurring = State(initialValue: expense.isRecurring)
        _selectedAccountId = State(initialValue: expense.accountId)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    HStack {
                        Text("C$")
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Description", text: $description)
                    
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    Picker("Account", selection: $selectedAccountId) {
                        ForEach(expenseManager.accounts) { account in
                            Text(account.name)
                                .tag(account.id)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Toggle("Recurring Expense", isOn: $isRecurring)
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(amount.isEmpty || description.isEmpty)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveChanges() {
        guard let amountValue = Double(amount) else { return }
        
        let updatedExpense = Expense(
            id: expense.id,
            amount: amountValue,
            description: description,
            category: category,
            date: date,
            isRecurring: isRecurring,
            accountId: selectedAccountId
        )
        
        do {
            try expenseManager.updateExpense(updatedExpense)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

#Preview {
    EditExpenseView(expense: Expense(
        amount: 100,
        description: "Test Expense",
        category: .food,
        date: Date(),
        isRecurring: false,
        accountId: UUID()
    ))
    .environmentObject(ExpenseManager())
} 