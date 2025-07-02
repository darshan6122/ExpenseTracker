import Foundation

class CSVImportService {
    static func parseCSV(from url: URL, accountId: UUID) throws -> [Expense] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines)
        
        // Skip header row
        guard rows.count > 1 else { return [] }
        
        return rows.dropFirst().compactMap { row -> Expense? in
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 5 else { return nil }
            
            // Parse date
            let dateString = columns[0].trimmingCharacters(in: .whitespaces)
            guard let date = DateFormatter.bankDateFormatter.date(from: dateString) else {
                print("Failed to parse date: \(dateString)")
                return nil
            }
            
            // Get description
            let description = columns[1].trimmingCharacters(in: .whitespaces)
            
            // Parse amount (expense or income)
            let expenseString = columns[2].trimmingCharacters(in: .whitespaces)
            let incomeString = columns[3].trimmingCharacters(in: .whitespaces)
            
            // Handle the amount based on whether it's an expense or income
            var amount: Double = 0
            if !expenseString.isEmpty {
                guard let expenseAmount = Double(expenseString) else {
                    print("Failed to parse expense amount: \(expenseString)")
                    return nil
                }
                amount = expenseAmount // Expense is positive
            } else if !incomeString.isEmpty {
                guard let incomeAmount = Double(incomeString) else {
                    print("Failed to parse income amount: \(incomeString)")
                    return nil
                }
                amount = -incomeAmount // Income/payment is negative (reduces expenses)
            } else {
                print("No amount found in row")
                return nil
            }
            
            // Account number is in columns[4], but we're using the provided accountId
            
            let category = determineCategory(from: description)
            
            return Expense(
                amount: amount,
                description: description,
                category: category,
                date: date,
                isRecurring: false,
                accountId: accountId
            )
        }
    }
    
    private static func determineCategory(from description: String) -> Category {
        let lowercasedDescription = description.lowercased()
        
        if lowercasedDescription.contains("food") || lowercasedDescription.contains("restaurant") || lowercasedDescription.contains("grocery") {
            return .food
        } else if lowercasedDescription.contains("uber") || lowercasedDescription.contains("lyft") || lowercasedDescription.contains("transit") {
            return .transportation
        } else if lowercasedDescription.contains("electric") || lowercasedDescription.contains("water") || lowercasedDescription.contains("gas") {
            return .utilities
        } else if lowercasedDescription.contains("netflix") || lowercasedDescription.contains("spotify") || lowercasedDescription.contains("amazon") {
            return .entertainment
        } else if lowercasedDescription.contains("store") || lowercasedDescription.contains("shop") {
            return .shopping
        } else if lowercasedDescription.contains("doctor") || lowercasedDescription.contains("pharmacy") {
            return .healthcare
        }
        
        return .other
    }
}

extension DateFormatter {
    static let bankDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // Update this format to match your CSV date format
        return formatter
    }()
} 