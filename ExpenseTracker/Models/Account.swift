import Foundation

struct Account: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var identifier: String // User-friendly identifier like "MAIN", "SAV"
    var balance: Double
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, identifier: String, balance: Double = 0.0, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.identifier = identifier.uppercased() // Store identifiers in uppercase for consistency
        self.balance = balance
        self.createdAt = createdAt
    }
}

enum AccountType: String, Codable, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case credit = "Credit Card"
    case cash = "Cash"
    case investment = "Investment"
    
    var icon: String {
        switch self {
        case .checking: return "creditcard"
        case .savings: return "banknote"
        case .credit: return "creditcard.fill"
        case .cash: return "dollarsign.circle"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }
} 