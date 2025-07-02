import SwiftUI

struct RecurringExpenseListView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @State private var showingAddRecurringExpense = false
    @State private var selectedAccount: Account?

    var body: some View {
        List {
            ForEach(expenseManager.recurringExpenses, id: \.id) { recurringExpense in
                RecurringExpenseRow(recurringExpense: recurringExpense)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            expenseManager.deleteRecurringExpense(recurringExpense)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("Recurring Expenses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddRecurringExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecurringExpense) {
            if let account = selectedAccount {
                AddRecurringExpenseView(expenseManager: expenseManager, account: account)
            }
        }
        .onAppear {
            if let account = selectedAccount {
                expenseManager.fetchRecurringExpenses(for: account.id)
            }
        }
    }
}

struct RecurringExpenseRow: View {
    let recurringExpense: RecurringExpense

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recurringExpense.description)
                    .font(.headline)
                Spacer()
                Text(recurringExpense.amount, format: .currency(code: "USD"))
                    .font(.headline)
            }

            HStack {
                Label(recurringExpense.category.rawValue, systemImage: recurringExpense.category.icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(recurringExpense.frequency.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let lastProcessedDate = recurringExpense.lastProcessedDate {
                Text("Last processed: \(lastProcessedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let endDate = recurringExpense.endDate {
                Text("Ends: \(endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddRecurringExpenseView: View {
    @ObservedObject var expenseManager: ExpenseManager
    let account: Account
    @Environment(\.dismiss) private var dismiss

    @State private var amountString = ""
    @State private var description: String = ""
    @State private var category: Category = .other
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var frequency: RecurringFrequency = .monthly
    @State private var hasEndDate = false

    private var amount: Double {
        Double(amountString) ?? 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Amount")
                }

                Section {
                    TextField("Description", text: $description)

                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue)
                                .tag(category)
                        }
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue)
                                .tag(frequency)
                        }
                    }
                } header: {
                    Text("Details")
                }

                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    Toggle("Has End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Schedule")
                }
            }
            .navigationTitle("Add Recurring Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        expenseManager.addRecurringExpense(
                            amount: amount,
                            description: description,
                            category: category,
                            startDate: startDate,
                            endDate: hasEndDate ? endDate : nil,
                            frequency: frequency,
                            accountId: account.id
                        )
                        dismiss()
                    }
                    .disabled(amount <= 0 || description.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        RecurringExpenseListView(expenseManager: ExpenseManager())
    }
}
