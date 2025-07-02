import Foundation

struct Expense: Identifiable, Codable {
    let id: UUID
    var amount: Double
    var description: String
    var category: Category
    var date: Date
    var isRecurring: Bool
    var accountId: UUID
    var receiptImageURL: URL?
    
    init(id: UUID = UUID(), amount: Double, description: String, category: Category, date: Date = Date(), isRecurring: Bool = false, accountId: UUID, receiptImageURL: URL? = nil) {
        self.id = id
        self.amount = amount
        self.description = description
        self.category = category
        self.date = date
        self.isRecurring = isRecurring
        self.accountId = accountId
        self.receiptImageURL = receiptImageURL
    }
} 