import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ExpenseTracker")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load Core Data store: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    // MARK: - Account Operations
    
    func createAccount(name: String, identifier: String, balance: Double = 0.0) -> CDAccount {
        let account = CDAccount(context: viewContext)
        account.id = UUID()
        account.name = name
        account.identifier = identifier.uppercased()
        account.balance = balance
        account.createdAt = Date()
        saveContext()
        return account
    }
    
    func fetchAccounts() -> [CDAccount] {
        let request: NSFetchRequest<CDAccount> = CDAccount.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDAccount.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching accounts: \(error)")
            return []
        }
    }
    
    func updateAccount(_ account: CDAccount) {
        saveContext()
    }
    
    func deleteAccount(_ account: CDAccount) {
        viewContext.delete(account)
        saveContext()
    }
    
    // MARK: - Expense Operations
    
    func createExpense(amount: Double, description: String, category: Category, date: Date, isRecurring: Bool = false, account: CDAccount, receiptImageURL: URL? = nil) -> CDExpense {
        let expense = CDExpense(context: viewContext)
        expense.id = UUID()
        expense.amount = amount
        expense.expenseDescription = description
        expense.category = category.rawValue
        expense.date = date
        expense.isRecurring = isRecurring
        expense.receiptImageURL = receiptImageURL
        expense.account = account
        
        account.balance -= amount
        saveContext()
        return expense
    }
    
    func fetchExpenses(for account: CDAccount? = nil) -> [CDExpense] {
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExpense.date, ascending: false)]
        
        if let account = account {
            request.predicate = NSPredicate(format: "account == %@", account)
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching expenses: \(error)")
            return []
        }
    }
    
    func updateExpense(_ expense: CDExpense) {
        saveContext()
    }
    
    func deleteExpense(_ expense: CDExpense) {
        if let account = expense.account {
            account.balance += expense.amount
        }
        
        // Delete receipt image file if it exists
        if let receiptURL = expense.receiptImageURL {
            try? FileManager.default.removeItem(at: receiptURL)
        }
        
        viewContext.delete(expense)
        saveContext()
    }
    
    // MARK: - Budget Operations
    
    func createBudget(name: String, amount: Double, period: Budget.BudgetPeriod, category: String? = nil) -> CDBudget {
        let budget = CDBudget(context: viewContext)
        budget.id = UUID()
        budget.name = name
        budget.amount = amount
        budget.period = period.rawValue
        budget.category = category
        budget.startDate = Date()
        budget.isActive = true
        saveContext()
        return budget
    }
    
    func fetchBudgets() -> [CDBudget] {
        let request: NSFetchRequest<CDBudget> = CDBudget.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBudget.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching budgets: \(error)")
            return []
        }
    }
    
    func updateBudget(_ budget: CDBudget) {
        saveContext()
    }
    
    func deleteBudget(_ budget: CDBudget) {
        viewContext.delete(budget)
        saveContext()
    }
    
    // MARK: - Recurring Expense Operations
    
    func createRecurringExpense(amount: Double, description: String, category: String, startDate: Date, endDate: Date?, frequency: String, accountId: UUID) -> CDRecurringExpense? {
        let context = persistentContainer.viewContext
        let recurringExpense = CDRecurringExpense(context: context)
        
        recurringExpense.id = UUID()
        recurringExpense.amount = amount
        recurringExpense.expenseDescription = description
        recurringExpense.category = category
        recurringExpense.startDate = startDate
        recurringExpense.endDate = endDate
        recurringExpense.frequency = frequency
        recurringExpense.lastProcessedDate = nil
        
        if let account = fetchAccount(withId: accountId) {
            recurringExpense.account = account
        }
        
        do {
            try context.save()
            return recurringExpense
        } catch {
            print("Error creating recurring expense: \(error)")
            context.rollback()
            return nil
        }
    }
    
    func fetchRecurringExpenses(for accountId: UUID) -> [CDRecurringExpense] {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<CDRecurringExpense> = CDRecurringExpense.fetchRequest()
        request.predicate = NSPredicate(format: "account.id == %@", accountId as CVarArg)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recurring expenses: \(error)")
            return []
        }
    }
    
    func updateRecurringExpense(_ recurringExpense: CDRecurringExpense, amount: Double, description: String, category: String, startDate: Date, endDate: Date?, frequency: String) -> Bool {
        let context = persistentContainer.viewContext
        
        recurringExpense.amount = amount
        recurringExpense.expenseDescription = description
        recurringExpense.category = category
        recurringExpense.startDate = startDate
        recurringExpense.endDate = endDate
        recurringExpense.frequency = frequency
        
        do {
            try context.save()
            return true
        } catch {
            print("Error updating recurring expense: \(error)")
            context.rollback()
            return false
        }
    }
    
    func deleteRecurringExpense(_ recurringExpense: CDRecurringExpense) -> Bool {
        let context = persistentContainer.viewContext
        context.delete(recurringExpense)
        
        do {
            try context.save()
            return true
        } catch {
            print("Error deleting recurring expense: \(error)")
            context.rollback()
            return false
        }
    }
    
    func updateLastProcessedDate(for recurringExpense: CDRecurringExpense, date: Date) {
        recurringExpense.lastProcessedDate = date
        saveContext()
    }
    
    func fetchAccount(withId id: UUID) -> CDAccount? {
        return fetchAccounts().first { $0.id == id }
    }
    
    // MARK: - Data Migration
    
    func migrateFromUserDefaults() {
        // Implementation for migrating data from UserDefaults to CoreData
        // This will be called once during app launch if needed
    }
    
    func fetchRecurringExpense(withId id: UUID) -> CDRecurringExpense? {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<CDRecurringExpense> = CDRecurringExpense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching recurring expense: \(error)")
            return nil
        }
    }
} 