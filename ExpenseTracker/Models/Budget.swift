import Foundation

struct Budget: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var period: BudgetPeriod
    var category: String? // Stores the Category.rawValue
    var startDate: Date
    var isActive: Bool
    
    enum BudgetPeriod: String, Codable, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
        
        var days: Int {
            switch self {
            case .weekly: return 7
            case .monthly: return 30
            case .yearly: return 365
            }
        }
    }
    
    init(id: UUID = UUID(), name: String, amount: Double, period: BudgetPeriod, category: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.period = period
        self.category = category
        self.startDate = Date()
        self.isActive = true
    }
    
    var dailyLimit: Double {
        amount / Double(period.days)
    }
    
    // Helper to get Category enum if category string exists
    var categoryEnum: Category? {
        guard let categoryString = category else { return nil }
        return Category(rawValue: categoryString)
    }
} 