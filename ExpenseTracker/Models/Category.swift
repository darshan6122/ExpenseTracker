import Foundation

public enum Category: String, Codable, CaseIterable {
    case food = "Food"
    case transportation = "Transportation"
    case utilities = "Utilities"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case healthcare = "Healthcare"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "tv.fill"
        case .shopping: return "cart.fill"
        case .healthcare: return "heart.fill"
        case .other: return "square.fill"
        }
    }
} 