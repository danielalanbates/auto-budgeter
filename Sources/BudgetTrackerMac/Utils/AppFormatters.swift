import Foundation

struct AppFormatters {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    static let currencyPrecise: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static func formatCurrency(_ amount: Double, precise: Bool = false) -> String {
        let formatter = precise ? currencyPrecise : currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}
