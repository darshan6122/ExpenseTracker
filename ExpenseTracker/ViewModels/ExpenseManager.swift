import Foundation
import CoreData

enum ExpenseError: Error {
    case accountNotFound
    case invalidAmount
    case invalidDate
    case saveFailed
    case insufficientFunds
    case invalidCategory
}

class ExpenseManager: ObservableObject {
    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var budgets: [Budget] = []
    @Published private(set) var recurringExpenses: [RecurringExpense] = []
    
    private let coreDataManager = CoreDataManager.shared
    
    init() {
        loadData()
        if accounts.isEmpty {
            // Create a default account if none exist
            let defaultAccount = Account(
                name: "Main Account",
                identifier: "MAIN",
                balance: 0.0
            )
            addAccount(defaultAccount)
        }
    }
    
    // MARK: - Account Management
    
    func addAccount(_ account: Account) {
        let cdAccount = coreDataManager.createAccount(
            name: account.name,
            identifier: account.identifier,
            balance: account.balance
        )
        accounts.append(Account(from: cdAccount))
    }
    
    func updateAccount(_ updatedAccount: Account) {
        if let cdAccount = coreDataManager.fetchAccounts().first(where: { $0.id == updatedAccount.id }) {
            cdAccount.name = updatedAccount.name
            cdAccount.identifier = updatedAccount.identifier
            cdAccount.balance = updatedAccount.balance
            coreDataManager.updateAccount(cdAccount)
            
            if let index = accounts.firstIndex(where: { $0.id == updatedAccount.id }) {
                accounts[index] = updatedAccount
            }
        }
    }
    
    func deleteAccounts(at offsets: IndexSet) {
        offsets.forEach { index in
            let account = accounts[index]
            if let cdAccount = coreDataManager.fetchAccounts().first(where: { $0.id == account.id }) {
                coreDataManager.deleteAccount(cdAccount)
                accounts.remove(at: index)
            }
        }
    }
    
    func hasExpenses(for account: Account) -> Bool {
        expenses.contains { $0.accountId == account.id }
    }
    
    func getAccount(byIdentifier identifier: String) -> Account? {
        accounts.first { $0.identifier.uppercased() == identifier.uppercased() }
    }
    
    func updateAccountBalance(accountId: UUID, newBalance: Double) throws {
        guard let cdAccount = coreDataManager.fetchAccounts().first(where: { $0.id == accountId }) else {
            throw ExpenseError.accountNotFound
        }
        
        // Calculate the difference to update the balance
        let difference = newBalance - cdAccount.balance
        cdAccount.balance = newBalance
        coreDataManager.updateAccount(cdAccount)
        
        // Update the account in the published array
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            var updatedAccount = accounts[index]
            updatedAccount.balance = newBalance
            accounts[index] = updatedAccount
        }
    }
    
    // MARK: - Expense Management
    
    func addExpense(_ expense: Expense) throws {
        guard let cdAccount = coreDataManager.fetchAccounts().first(where: { $0.id == expense.accountId }) else {
            throw ExpenseError.accountNotFound
        }
        
        guard cdAccount.balance >= expense.amount else {
            throw ExpenseError.insufficientFunds
        }
        
        let cdExpense = coreDataManager.createExpense(
            amount: expense.amount,
            description: expense.description,
            category: expense.category,
            date: expense.date,
            isRecurring: expense.isRecurring,
            account: cdAccount,
            receiptImageURL: expense.receiptImageURL
        )
        
        expenses.append(Expense(from: cdExpense))
    }
    
    func updateExpense(_ expense: Expense) throws {
        guard let cdAccount = coreDataManager.fetchAccounts().first(where: { $0.id == expense.accountId }) else {
            throw ExpenseError.accountNotFound
        }
        
        if let cdExpense = coreDataManager.fetchExpenses().first(where: { $0.id == expense.id }) {
            // First, restore the old amount to the account balance
            if let oldAccount = coreDataManager.fetchAccounts().first(where: { $0.id == cdExpense.account?.id }) {
                oldAccount.balance += cdExpense.amount
            }
            
            // Then, subtract the new amount from the new account balance
            guard cdAccount.balance >= expense.amount else {
                throw ExpenseError.insufficientFunds
            }
            
            cdExpense.amount = expense.amount
            cdExpense.expenseDescription = expense.description
            cdExpense.category = expense.category.rawValue
            cdExpense.date = expense.date
            cdExpense.isRecurring = expense.isRecurring
            cdExpense.account = cdAccount
            
            coreDataManager.updateExpense(cdExpense)
            
            if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                expenses[index] = expense
            }
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        if let cdExpense = coreDataManager.fetchExpenses().first(where: { $0.id == expense.id }) {
            coreDataManager.deleteExpense(cdExpense)
            expenses.removeAll { $0.id == expense.id }
        }
    }
    
    func expensesForAccount(_ accountId: UUID) -> [Expense] {
        expenses.filter { $0.accountId == accountId }
    }
    
    func totalExpensesForAccount(_ accountId: UUID) -> Double {
        expensesForAccount(accountId).reduce(0) { $0 + $1.amount }
    }
    
    func totalExpensesAcrossAllAccounts() -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    func expensesByCategoryForAccount(_ accountId: UUID) -> [Category: Double] {
        var result: [Category: Double] = [:]
        
        for expense in expensesForAccount(accountId) {
            result[expense.category, default: 0] += expense.amount
        }
        
        return result
    }
    
    func expensesByCategoryForSelectedAccount(_ accountId: UUID?) -> [Category: Double] {
        if let accountId = accountId {
            return expensesByCategoryForAccount(accountId)
        } else {
            var result: [Category: Double] = [:]
            for expense in expenses {
                result[expense.category, default: 0] += expense.amount
            }
            return result
        }
    }
    
    // MARK: - Budget Management
    
    func addBudget(_ budget: Budget) {
        let cdBudget = coreDataManager.createBudget(
            name: budget.name,
            amount: budget.amount,
            period: budget.period,
            category: budget.category
        )
        budgets.append(Budget(from: cdBudget))
    }
    
    func updateBudget(_ budget: Budget) {
        if let cdBudget = coreDataManager.fetchBudgets().first(where: { $0.id == budget.id }) {
            cdBudget.name = budget.name
            cdBudget.amount = budget.amount
            cdBudget.period = budget.period.rawValue
            cdBudget.category = budget.category
            cdBudget.startDate = budget.startDate
            cdBudget.isActive = budget.isActive
            coreDataManager.updateBudget(cdBudget)
            
            if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
                budgets[index] = budget
            }
        }
    }
    
    func deleteBudget(_ budget: Budget) {
        if let cdBudget = coreDataManager.fetchBudgets().first(where: { $0.id == budget.id }) {
            coreDataManager.deleteBudget(cdBudget)
            budgets.removeAll { $0.id == budget.id }
        }
    }
    
    func getBudgetProgress(_ budget: Budget) -> Double {
        let relevantExpenses = expenses.filter { expense in
            // Filter by date range
            let isInPeriod = expense.date >= budget.startDate &&
                            expense.date <= Calendar.current.date(byAdding: .day, value: budget.period.days, to: budget.startDate)!
            
            // Filter by category if specified
            let matchesCategory = budget.category == nil || budget.category == expense.category.rawValue
            
            return isInPeriod && matchesCategory
        }
        
        let totalSpent = relevantExpenses.reduce(0) { $0 + $1.amount }
        return totalSpent / budget.amount
    }
    
    func getRemainingBudget(_ budget: Budget) -> Double {
        let totalSpent = expenses.filter { expense in
            let isInPeriod = expense.date >= budget.startDate &&
                            expense.date <= Calendar.current.date(byAdding: .day, value: budget.period.days, to: budget.startDate)!
            let matchesCategory = budget.category == nil || budget.category == expense.category.rawValue
            return isInPeriod && matchesCategory
        }.reduce(0) { $0 + $1.amount }
        
        return budget.amount - totalSpent
    }
    
    func getActiveBudgets() -> [Budget] {
        budgets.filter { budget in
            let endDate = Calendar.current.date(byAdding: .day, value: budget.period.days, to: budget.startDate)!
            return budget.isActive && endDate >= Date()
        }
    }
    
    // MARK: - Recurring Expenses
    
    func addRecurringExpense(amount: Double, description: String, category: Category, startDate: Date, endDate: Date?, frequency: RecurringFrequency, accountId: UUID) {
        let recurringExpense = RecurringExpense(
            id: UUID(),
            amount: amount,
            description: description,
            category: category,
            startDate: startDate,
            endDate: endDate,
            frequency: frequency,
            accountId: accountId,
            lastProcessedDate: nil
        )
        
        if let cdRecurringExpense = CoreDataManager.shared.createRecurringExpense(
            amount: amount,
            description: description,
            category: category.rawValue,
            startDate: startDate,
            endDate: endDate,
            frequency: frequency.rawValue,
            accountId: accountId
        ) {
            recurringExpenses.append(recurringExpense)
        }
    }
    
    func fetchRecurringExpenses(for accountId: UUID) {
        let cdRecurringExpenses = CoreDataManager.shared.fetchRecurringExpenses(for: accountId)
        recurringExpenses = cdRecurringExpenses.compactMap { cdRecurringExpense in
            guard let id = cdRecurringExpense.id,
                  let category = Category(rawValue: cdRecurringExpense.category ?? ""),
                  let frequency = RecurringFrequency(rawValue: cdRecurringExpense.frequency ?? "") else {
                return nil
            }
            
            return RecurringExpense(
                id: id,
                amount: cdRecurringExpense.amount,
                description: cdRecurringExpense.expenseDescription ?? "",
                category: category,
                startDate: cdRecurringExpense.startDate ?? Date(),
                endDate: cdRecurringExpense.endDate,
                frequency: frequency,
                accountId: accountId,
                lastProcessedDate: cdRecurringExpense.lastProcessedDate
            )
        }
    }
    
    func updateRecurringExpense(_ recurringExpense: RecurringExpense, amount: Double, description: String, category: Category, startDate: Date, endDate: Date?, frequency: RecurringFrequency) {
        if let cdRecurringExpense = CoreDataManager.shared.fetchRecurringExpense(withId: recurringExpense.id) {
            if CoreDataManager.shared.updateRecurringExpense(
                cdRecurringExpense,
                amount: amount,
                description: description,
                category: category.rawValue,
                startDate: startDate,
                endDate: endDate,
                frequency: frequency.rawValue
            ) {
                if let index = recurringExpenses.firstIndex(where: { $0.id == recurringExpense.id }) {
                    recurringExpenses[index] = RecurringExpense(
                        id: recurringExpense.id,
                        amount: amount,
                        description: description,
                        category: category,
                        startDate: startDate,
                        endDate: endDate,
                        frequency: frequency,
                        accountId: recurringExpense.accountId,
                        lastProcessedDate: recurringExpense.lastProcessedDate
                    )
                }
            }
        }
    }
    
    func deleteRecurringExpense(_ recurringExpense: RecurringExpense) {
        if let cdRecurringExpense = CoreDataManager.shared.fetchRecurringExpense(withId: recurringExpense.id) {
            if CoreDataManager.shared.deleteRecurringExpense(cdRecurringExpense) {
                recurringExpenses.removeAll { $0.id == recurringExpense.id }
            }
        }
    }
    
    func processRecurringExpenses() {
        let calendar = Calendar.current
        let now = Date()
        
        for recurringExpense in recurringExpenses where recurringExpense.isActive {
            if let lastProcessedDate = recurringExpense.lastProcessedDate {
                let nextOccurrence = calendar.date(byAdding: recurringExpense.frequency.calendarComponent, value: recurringExpense.frequency.interval, to: lastProcessedDate) ?? lastProcessedDate
                
                if nextOccurrence <= now {
                    let expense = Expense(
                        amount: recurringExpense.amount,
                        description: recurringExpense.description,
                        category: recurringExpense.category,
                        date: nextOccurrence,
                        isRecurring: true,
                        accountId: recurringExpense.accountId
                    )
                    
                    try? addExpense(expense)
                    
                    if let cdRecurringExpense = coreDataManager.fetchRecurringExpense(withId: recurringExpense.id) {
                        coreDataManager.updateLastProcessedDate(for: cdRecurringExpense, date: nextOccurrence)
                    }
                }
            } else {
                let expense = Expense(
                    amount: recurringExpense.amount,
                    description: recurringExpense.description,
                    category: recurringExpense.category,
                    date: recurringExpense.startDate,
                    isRecurring: true,
                    accountId: recurringExpense.accountId
                )
                
                try? addExpense(expense)
                
                if let cdRecurringExpense = coreDataManager.fetchRecurringExpense(withId: recurringExpense.id) {
                    coreDataManager.updateLastProcessedDate(for: cdRecurringExpense, date: recurringExpense.startDate)
                }
            }
        }
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        // Load accounts
        accounts = coreDataManager.fetchAccounts().map { Account(from: $0) }
        
        // Load expenses
        expenses = coreDataManager.fetchExpenses().map { Expense(from: $0) }
        
        // Load budgets
        budgets = coreDataManager.fetchBudgets().map { Budget(from: $0) }
    }
    
    func clearAllExpenses() {
        coreDataManager.fetchExpenses().forEach { coreDataManager.deleteExpense($0) }
        expenses.removeAll()
    }
}

// MARK: - Model Extensions

extension Account {
    init(from cdAccount: CDAccount) {
        self.id = cdAccount.id ?? UUID()
        self.name = cdAccount.name ?? ""
        self.identifier = cdAccount.identifier ?? ""
        self.balance = cdAccount.balance
        self.createdAt = cdAccount.createdAt ?? Date()
    }
}

extension Expense {
    init(from cdExpense: CDExpense) {
        self.id = cdExpense.id ?? UUID()
        self.amount = cdExpense.amount
        self.description = cdExpense.expenseDescription ?? ""
        self.category = Category(rawValue: cdExpense.category ?? "") ?? .other
        self.date = cdExpense.date ?? Date()
        self.isRecurring = cdExpense.isRecurring
        self.accountId = cdExpense.account?.id ?? UUID()
        self.receiptImageURL = cdExpense.receiptImageURL
    }
}

extension Budget {
    init(from cdBudget: CDBudget) {
        self.id = cdBudget.id ?? UUID()
        self.name = cdBudget.name ?? ""
        self.amount = cdBudget.amount
        self.period = BudgetPeriod(rawValue: cdBudget.period ?? "") ?? .monthly
        self.category = cdBudget.category
        self.startDate = cdBudget.startDate ?? Date()
        self.isActive = cdBudget.isActive
    }
} 