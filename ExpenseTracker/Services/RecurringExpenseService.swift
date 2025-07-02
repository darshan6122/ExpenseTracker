import Foundation
import CoreData

enum RecurringFrequency: String, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
    
    var interval: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 1
        case .monthly: return 1
        case .yearly: return 1
        }
    }
}

struct RecurringExpense: Codable, Identifiable {
    let id: UUID
    var amount: Double
    var description: String
    var category: Category
    var startDate: Date
    var endDate: Date?
    var frequency: RecurringFrequency
    var accountId: UUID
    var lastProcessedDate: Date?
    
    var isActive: Bool {
        guard let endDate = endDate else { return true }
        return Date() <= endDate
    }
}

class RecurringExpenseService {
    private let expenseManager: ExpenseManager
    
    init(expenseManager: ExpenseManager) {
        self.expenseManager = expenseManager
    }
    
    func processRecurringExpenses() {
        let calendar = Calendar.current
        let now = Date()
        
        for recurringExpense in expenseManager.recurringExpenses where recurringExpense.isActive {
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
                    
                    try? expenseManager.addExpense(expense)
                    
                    if let cdRecurringExpense = CoreDataManager.shared.fetchRecurringExpense(withId: recurringExpense.id) {
                        CoreDataManager.shared.updateLastProcessedDate(for: cdRecurringExpense, date: nextOccurrence)
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
                
                try? expenseManager.addExpense(expense)
                
                if let cdRecurringExpense = CoreDataManager.shared.fetchRecurringExpense(withId: recurringExpense.id) {
                    CoreDataManager.shared.updateLastProcessedDate(for: cdRecurringExpense, date: recurringExpense.startDate)
                }
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func createRecurringExpense(_ expense: RecurringExpense) async throws {
        // Implementation for creating a recurring expense
    }
    
    func fetchRecurringExpenses() async throws -> [RecurringExpense] {
        // Implementation for fetching recurring expenses
        return []
    }
    
    func updateRecurringExpense(_ expense: RecurringExpense) async throws {
        // Implementation for updating a recurring expense
    }
    
    func deleteRecurringExpense(_ expense: RecurringExpense) async throws {
        // Implementation for deleting a recurring expense
    }
    
    // MARK: - Helper Methods
    
    func calculateNextOccurrence(for expense: RecurringExpense) -> Date? {
        guard let lastProcessedDate = expense.lastProcessedDate else {
            return expense.startDate
        }
        
        let calendar = Calendar.current
        return calendar.date(
            byAdding: expense.frequency.calendarComponent,
            value: expense.frequency.interval,
            to: lastProcessedDate
        )
    }
    
    func isExpenseDue(_ expense: RecurringExpense) -> Bool {
        guard let nextOccurrence = calculateNextOccurrence(for: expense) else {
            return false
        }
        
        return nextOccurrence <= Date()
    }
} 