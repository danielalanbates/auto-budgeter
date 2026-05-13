import Foundation

// MARK: - Transaction

struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var description: String
    var amount: Double
    var category: TransactionCategory
    var merchant: String
    var notes: String
    var isIncome: Bool
    var source: TransactionSource
    var profileId: UUID? // Associated profile
    
    init(id: UUID = UUID(), date: Date = Date(), description: String, amount: Double, 
         category: TransactionCategory = .uncategorized, merchant: String = "",
         notes: String = "", isIncome: Bool = false, source: TransactionSource = .manual,
         profileId: UUID? = nil) {
        self.id = id
        self.date = date
        self.description = description
        self.amount = abs(amount)
        self.category = category
        self.merchant = merchant
        self.notes = notes
        self.isIncome = isIncome
        self.source = source
        self.profileId = profileId
    }
}

enum TransactionSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case csvImport = "CSV Import"
    case pdfImport = "PDF Import"
    case excelImport = "Excel Import"
    case aiExtracted = "AI Extracted"
    case recurring = "Recurring"
}

// MARK: - Categories

enum TransactionCategory: String, Codable, CaseIterable {
    case housing = "Housing"
    case utilities = "Utilities"
    case transportation = "Transportation"
    case groceries = "Groceries"
    case diningOut = "Dining Out"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case healthcare = "Healthcare"
    case insurance = "Insurance"
    case debtPayments = "Debt Payments"
    case savings = "Savings"
    case subscriptions = "Subscriptions"
    case travel = "Travel"
    case education = "Education"
    case gifts = "Gifts & Donations"
    case personalCare = "Personal Care"
    case pets = "Pets"
    case income = "Income"
    case uncategorized = "Uncategorized"
    
    var icon: String {
        switch self {
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .transportation: return "car.fill"
        case .groceries: return "cart.fill"
        case .diningOut: return "fork.knife"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .healthcare: return "heart.fill"
        case .insurance: return "shield.fill"
        case .debtPayments: return "creditcard.fill"
        case .savings: return "banknote.fill"
        case .subscriptions: return "repeat"
        case .travel: return "airplane"
        case .education: return "book.fill"
        case .gifts: return "gift.fill"
        case .personalCare: return "sparkles"
        case .pets: return "pawprint.fill"
        case .income: return "arrow.down.circle.fill"
        case .uncategorized: return "questionmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .housing: return "blue"
        case .utilities: return "yellow"
        case .transportation: return "orange"
        case .groceries: return "green"
        case .diningOut: return "red"
        case .entertainment: return "purple"
        case .shopping: return "pink"
        case .healthcare: return "red"
        case .insurance: return "gray"
        case .debtPayments: return "brown"
        case .savings: return "mint"
        case .subscriptions: return "indigo"
        case .travel: return "cyan"
        case .education: return "teal"
        case .gifts: return "pink"
        case .personalCare: return "purple"
        case .pets: return "orange"
        case .income: return "green"
        case .uncategorized: return "gray"
        }
    }
}

// MARK: - Category Detection (AI-like)

struct CategoryDetector {
    static let rules: [TransactionCategory: [String]] = [
        .groceries: ["walmart", "safeway", "kroger", "costco", "trader joe", "whole foods", "grocery", "winco", "target", "instacart"],
        .diningOut: ["restaurant", "mcdonald", "burger", "pizza", "taco", "subway", "chipotle", "panera", "cafe", "starbucks", "coffee", "doordash", "uber eats", "grubhub"],
        .transportation: ["gas", "fuel", "chevron", "shell", "exxon", "uber", "lyft", "parking"],
        .utilities: ["electric", "water", "gas bill", "internet", "comcast", "verizon", "att", "t-mobile", "phone"],
        .entertainment: ["netflix", "hulu", "disney", "spotify", "apple music", "hbo", "gaming", "steam", "xbox", "playstation"],
        .shopping: ["amazon", "ebay", "best buy", "apple store", "mall", "clothing", "shoes"],
        .healthcare: ["pharmacy", "cvs", "walgreens", "doctor", "hospital", "medical", "dental", "gym", "fitness"],
        .subscriptions: ["subscription", "monthly", "premium", "membership"],
        .travel: ["airline", "hotel", "airbnb", "booking", "expedia", "flight"],
        .education: ["tuition", "school", "university", "course", "udemy", "books"],
        .gifts: ["donation", "charity", "church", "gift"],
        .insurance: ["insurance", "geico", "allstate", "progressive"],
        .housing: ["rent", "mortgage", "hoa", "property"],
        .pets: ["pet", "vet", "veterinary", "petco", "petsmart"],
        .income: ["payroll", "direct deposit", "salary", "paycheck", "deposit", "refund"]
    ]
    
    static func detect(_ description: String) -> TransactionCategory {
        let lower = description.lowercased()
        
        for (category, keywords) in rules {
            for keyword in keywords {
                if lower.contains(keyword) {
                    return category
                }
            }
        }
        
        return .uncategorized
    }
    
    static func isLikelyIncome(_ description: String, amount: Double) -> Bool {
        let lower = description.lowercased()
        let incomeKeywords = ["payroll", "direct deposit", "salary", "paycheck", "deposit", "refund", "reimbursement", "transfer in"]
        
        for keyword in incomeKeywords {
            if lower.contains(keyword) {
                return true
            }
        }
        
        return amount > 1000 && (lower.contains("deposit") || lower.contains("credit"))
    }
}

// MARK: - Fund Requests

struct FundRequest: Identifiable, Codable, Hashable {
    let id: UUID
    let requesterProfileId: UUID
    let requesterName: String
    let role: ProfileRole
    let category: TransactionCategory
    let amount: Double
    let note: String
    let createdAt: Date
}

// MARK: - Custom Budget Category

struct CustomBudgetCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var limit: Double
    
    init(id: UUID = UUID(), name: String, emoji: String, colorHex: String, limit: Double) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.limit = limit
    }
}

// MARK: - Income Mode

enum IncomeMode: String, Codable {
    case auto   // derive from transactions
    case manual // use monthlyIncome field
}

// MARK: - Emergency Fund Mode

enum EmergencyFundMode: String, Codable {
    case ai
    case manual
}

// MARK: - Recurring Transaction

struct RecurringTransaction: Identifiable, Codable, Hashable {
    let id: UUID
    var description: String
    var amount: Double
    var category: TransactionCategory
    var merchant: String
    var isIncome: Bool
    var notes: String
    var startDate: Date
    var frequency: RecurringFrequency
    var endDate: Date?
    var isEnabled: Bool
    var lastGenerated: Date?

    init(id: UUID = UUID(), description: String, amount: Double,
         category: TransactionCategory = .uncategorized, merchant: String = "",
         isIncome: Bool = false, notes: String = "", startDate: Date = Date(),
         frequency: RecurringFrequency = .monthly, endDate: Date? = nil,
         isEnabled: Bool = true, lastGenerated: Date? = nil) {
        self.id = id
        self.description = description
        self.amount = abs(amount)
        self.category = category
        self.merchant = merchant
        self.isIncome = isIncome
        self.notes = notes
        self.startDate = startDate
        self.frequency = frequency
        self.endDate = endDate
        self.isEnabled = isEnabled
        self.lastGenerated = lastGenerated
    }

    /// Generate a Transaction from this recurring entry for a given date
    func generateTransaction(for date: Date) -> Transaction {
        Transaction(
            date: date,
            description: description,
            amount: amount,
            category: category,
            merchant: merchant,
            notes: notes.isEmpty ? "Recurring (\(frequency.rawValue))" : notes,
            isIncome: isIncome,
            source: .recurring
        )
    }

    /// Check if this recurring transaction should fire on the given date
    func shouldFire(on date: Date, asOf today: Date) -> Bool {
        guard isEnabled else { return false }
        guard date >= startDate else { return false }
        if let end = endDate, date > end { return false }
        if let last = lastGenerated, date <= last { return false }
        return true
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    func nextDate(from: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: from) ?? from
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: from) ?? from
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: from) ?? from
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: from) ?? from
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: from) ?? from
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: from) ?? from
        }
    }

    func datesBetween(start: Date, end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            current = nextDate(from: current)
        }
        return dates
    }
}

// MARK: - Export Formats

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case pdf = "PDF"
}

// MARK: - App Data Store

@MainActor
class BudgetDataStore: ObservableObject {
    @Published var transactions: [Transaction] = [] {
        didSet { invalidateCache() }
    }
    @Published var userSettings: UserSettings = UserSettings() {
        didSet { invalidateCache() }
    }
    @Published var profiles: [UserProfile] = [
        UserProfile(name: "Manager", role: .manager),
        UserProfile(name: "Contributor", role: .contributor),
        UserProfile(name: "Viewer", role: .viewer)
    ]
    @Published var activeProfileId: UUID?
    @Published var fundRequests: [FundRequest] = []
    @Published var customBudgetCategories: [CustomBudgetCategory] = []
    @Published var recurringTransactions: [RecurringTransaction] = [] {
        didSet { save() }
    }
    
    // Caching for computed properties
    private var _cachedTotalIncome: Double?
    private var _cachedTotalExpenses: Double?
    private var _cachedExpensesByCategory: [TransactionCategory: Double]?
    private var _cachedAverageMonthlyExpenses: Double?
    
    private func invalidateCache() {
        _cachedTotalIncome = nil
        _cachedTotalExpenses = nil
        _cachedExpensesByCategory = nil
        _cachedAverageMonthlyExpenses = nil
    }

    private let transactionsKey = "budget_transactions"
    private let settingsKey = "budget_settings"
    private let profilesKey = "budget_profiles"
    private let activeProfileKey = "budget_active_profile"
    private let fundRequestsKey = "budget_fund_requests"
    private let customBudgetCategoriesKey = "budget_custom_categories"
    private let recurringTransactionsKey = "budget_recurring_transactions"
    
    private var saveTask: Task<Void, Never>?

    init() {
        load()
    }
    
    // MARK: - Persistence
    
    func save() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            guard !Task.isCancelled else { return }

            if let encoded = try? JSONEncoder().encode(transactions) {
                UserDefaults.standard.set(encoded, forKey: transactionsKey)
            }
            if let encoded = try? JSONEncoder().encode(userSettings) {
                UserDefaults.standard.set(encoded, forKey: settingsKey)
            }
            if let encoded = try? JSONEncoder().encode(profiles) {
                UserDefaults.standard.set(encoded, forKey: profilesKey)
            }
            if let active = activeProfileId?.uuidString {
                UserDefaults.standard.set(active, forKey: activeProfileKey)
            }
            if let encoded = try? JSONEncoder().encode(fundRequests) {
                UserDefaults.standard.set(encoded, forKey: fundRequestsKey)
            }
            if let encoded = try? JSONEncoder().encode(customBudgetCategories) {
                UserDefaults.standard.set(encoded, forKey: customBudgetCategoriesKey)
            }
            if let encoded = try? JSONEncoder().encode(recurringTransactions) {
                UserDefaults.standard.set(encoded, forKey: recurringTransactionsKey)
            }
        }
    }
    
    func load() {
        Task {
            let transactionsData = UserDefaults.standard.data(forKey: transactionsKey)
            let settingsData = UserDefaults.standard.data(forKey: settingsKey)
            let profilesData = UserDefaults.standard.data(forKey: profilesKey)
            let fundRequestsData = UserDefaults.standard.data(forKey: fundRequestsKey)
            let customCategoriesData = UserDefaults.standard.data(forKey: customBudgetCategoriesKey)
            let recurringTransactionsData = UserDefaults.standard.data(forKey: recurringTransactionsKey)
            let activeProfileIdString = UserDefaults.standard.string(forKey: activeProfileKey)
            
            // Perform decoding off the main thread if possible, but since we are @MainActor
            // and this is called during init, we should be careful.
            // Actually, init calls load() which is synchronously defined currently.
            
            if let data = transactionsData,
               let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
                self.transactions = decoded
            }
            if let data = settingsData,
               let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
                self.userSettings = decoded
            }
            if let data = profilesData,
               let decoded = try? JSONDecoder().decode([UserProfile].self, from: data),
               !decoded.isEmpty {
                self.profiles = decoded
            }
            if let idString = activeProfileIdString,
               let uuid = UUID(uuidString: idString) {
                self.activeProfileId = uuid
            } else {
                self.activeProfileId = self.profiles.first?.id
            }
            if let data = fundRequestsData,
               let decoded = try? JSONDecoder().decode([FundRequest].self, from: data) {
                self.fundRequests = decoded
            }
            if let data = customCategoriesData,
               let decoded = try? JSONDecoder().decode([CustomBudgetCategory].self, from: data) {
                self.customBudgetCategories = decoded
            }
            if let data = recurringTransactionsData,
               let decoded = try? JSONDecoder().decode([RecurringTransaction].self, from: data) {
                self.recurringTransactions = decoded
            }
            self.invalidateCache()
        }
    }
    
    // MARK: - Transaction Management
    
    func addTransaction(_ transaction: Transaction) {
        var newTransaction = transaction
        // Assign to active profile if in separated mode and not already assigned
        if userSettings.convergenceMode == .separated && newTransaction.profileId == nil {
            newTransaction.profileId = activeProfileId
        }
        transactions.append(newTransaction)
        save()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        save()
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            save()
        }
    }
    
    func importTransactions(_ newTransactions: [Transaction]) {
        let processed = newTransactions.map { t -> Transaction in
            var nt = t
            if userSettings.convergenceMode == .separated && nt.profileId == nil {
                nt.profileId = activeProfileId
            }
            return nt
        }
        transactions.append(contentsOf: processed)
        save()
    }
    
    // MARK: - Computed Properties
    
    /// Returns transactions based on current convergence mode and active profile
    var filteredTransactions: [Transaction] {
        if userSettings.convergenceMode == .converged {
            return transactions
        } else {
            // In separated mode, only show transactions for the active profile
            // If profileId is nil, it's considered "Shared" or "Primary"
            return transactions.filter { 
                if let tid = $0.profileId {
                    return tid == activeProfileId
                } else {
                    // Default to primary profile if no profile assigned
                    return activeProfileId == profiles.first?.id
                }
            }
        }
    }
    
    var totalIncome: Double {
        if let cached = _cachedTotalIncome { return cached }
        let result = filteredTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        _cachedTotalIncome = result
        return result
    }
    
    var totalExpenses: Double {
        if let cached = _cachedTotalExpenses { return cached }
        let result = filteredTransactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        _cachedTotalExpenses = result
        return result
    }
    
    var balance: Double {
        totalIncome - totalExpenses
    }
    
    var expensesByCategory: [TransactionCategory: Double] {
        if let cached = _cachedExpensesByCategory { return cached }
        var result: [TransactionCategory: Double] = [:]
        for transaction in filteredTransactions where !transaction.isIncome {
            result[transaction.category, default: 0] += transaction.amount
        }
        _cachedExpensesByCategory = result
        return result
    }
    
    /// Income derived from imported data or manual setting, respecting convergence/separation
    var derivedIncome: Double {
        let baseIncome: Double
        switch userSettings.incomeMode {
        case .auto:
            baseIncome = totalIncome
        case .manual:
            if userSettings.convergenceMode == .converged {
                baseIncome = userSettings.monthlyIncome + (userSettings.isSpouseWorking ? userSettings.spouseIncome : 0)
            } else {
                // In separated mode, manual income should be profile-specific
                if activeProfile.name.lowercased().contains("spouse") {
                    baseIncome = userSettings.spouseIncome
                } else {
                    baseIncome = userSettings.monthlyIncome
                }
            }
        }
        return baseIncome
    }
    
    var averageMonthlyExpenses: Double {
        if let cached = _cachedAverageMonthlyExpenses { return cached }
        let expenses = filteredTransactions.filter { !$0.isIncome }
        guard !expenses.isEmpty else { return 0 }
        let calendar = Calendar.current
        let months = Set(expenses.map { calendar.component(.month, from: $0.date) + calendar.component(.year, from: $0.date) * 12 })
        let total = expenses.reduce(0) { $0 + $1.amount }
        let monthsCount = max(1, months.count)
        let result = total / Double(monthsCount)
        _cachedAverageMonthlyExpenses = result
        return result
    }
    
    var emergencyFundTarget: Double {
        let months: Int
        switch userSettings.emergencyFundMode {
        case .ai:
            months = aiRecommendedEmergencyMonths
        case .manual:
            months = max(3, userSettings.emergencyFundMonths)
        }
        return averageMonthlyExpenses * Double(months)
    }
    
    private var aiRecommendedEmergencyMonths: Int {
        // Simple heuristic: default 6 months, or 3 months if expenses are very low vs income
        let inc = max(derivedIncome, 1)
        let exp = averageMonthlyExpenses
        let ratio = exp / inc
        if ratio < 0.3 { return 3 }
        if ratio < 0.6 { return 6 }
        if ratio < 0.9 { return 9 }
        return 12
    }
    
    func transactionsForMonth(_ date: Date) -> [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
    }

    // MARK: - Profiles

    var activeProfile: UserProfile {
        profiles.first(where: { $0.id == activeProfileId }) ?? profiles.first ?? UserProfile(name: "Manager", role: .manager)
    }

    func selectProfile(_ profile: UserProfile) {
        activeProfileId = profile.id
        invalidateCache()
        save()
    }

    func addProfile(name: String, role: ProfileRole) {
        let profile = UserProfile(name: name, role: role)
        profiles.append(profile)
        activeProfileId = profile.id
        invalidateCache()
        save()
    }
    
    /// Syncs family profiles based on settings
    func syncFamilyProfiles() {
        if userSettings.familySize > 1 {
            // Check if a spouse profile exists
            let spouseExists = profiles.contains { $0.name.lowercased().contains("spouse") }
            if !spouseExists {
                let spouseProfile = UserProfile(name: "Spouse", role: .manager)
                profiles.append(spouseProfile)
            }
        }
        save()
    }

    func remainingBudget(for category: TransactionCategory) -> Double {
        let limit = userSettings.budgetLimits[category] ?? 0
        let spent = expensesByCategory[category] ?? 0
        return limit - spent
    }

    var totalRemainingBudget: Double {
        userSettings.budgetLimits.reduce(0) { partial, entry in
            let remaining = remainingBudget(for: entry.key)
            return partial + max(0, remaining)
        }
    }
    
    // MARK: - Custom Budgets
    
    func addCustomCategory(name: String, limit: Double) {
        let emoji = inferEmoji(for: name)
        let colorHex = inferColorHex(for: name)
        let newCat = CustomBudgetCategory(name: name, emoji: emoji, colorHex: colorHex, limit: limit)
        customBudgetCategories.append(newCat)
        save()
    }
    
    private func inferEmoji(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("rent") || lower.contains("home") || lower.contains("house") { return "🏠" }
        if lower.contains("groc") || lower.contains("food") { return "🛒" }
        if lower.contains("eat") || lower.contains("dine") || lower.contains("restaurant") { return "🍽️" }
        if lower.contains("gas") || lower.contains("trans") || lower.contains("car") { return "🚗" }
        if lower.contains("health") || lower.contains("medical") { return "💊" }
        if lower.contains("insur") { return "🛡️" }
        if lower.contains("util") || lower.contains("electric") || lower.contains("water") { return "💡" }
        if lower.contains("travel") || lower.contains("flight") { return "✈️" }
        if lower.contains("gift") || lower.contains("donat") { return "🎁" }
        if lower.contains("entertain") || lower.contains("game") || lower.contains("stream") { return "🎮" }
        if lower.contains("shop") || lower.contains("retail") { return "🛍️" }
        return "💡"
    }
    
    private func inferColorHex(for name: String) -> String {
        let palette = [
            "#4A90E2", "#2ECC71", "#E67E22", "#E74C3C", "#9B59B6",
            "#16A085", "#F1C40F", "#1ABC9C", "#D35400", "#7F8C8D"
        ]
        let hash = abs(name.hashValue)
        return palette[hash % palette.count]
    }

    // MARK: - Fund Requests

    func addFundRequest(category: TransactionCategory, amount: Double, note: String, requester: UserProfile) {
        let request = FundRequest(
            id: UUID(),
            requesterProfileId: requester.id,
            requesterName: requester.name,
            role: requester.role,
            category: category,
            amount: amount,
            note: note,
            createdAt: Date()
        )
        fundRequests.append(request)
        save()
    }

    func resolveFundRequest(_ request: FundRequest) {
        fundRequests.removeAll { $0.id == request.id }
        save()
    }

    // MARK: - Recurring Transactions

    func addRecurringTransaction(_ transaction: RecurringTransaction) {
        recurringTransactions.append(transaction)
        save()
    }

    func deleteRecurringTransaction(_ transaction: RecurringTransaction) {
        recurringTransactions.removeAll { $0.id == transaction.id }
        save()
    }

    func updateRecurringTransaction(_ transaction: RecurringTransaction) {
        if let index = recurringTransactions.firstIndex(where: { $0.id == transaction.id }) {
            recurringTransactions[index] = transaction
            save()
        }
    }

    /// Process all recurring transactions that should fire today
    func processRecurringTransactions() {
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)

        for var recurring in recurringTransactions where recurring.isEnabled {
            if recurring.lastGenerated == nil || calendar.compare(recurring.lastGenerated!, to: startOfDay, toGranularity: .day) != .orderedSame {
                let transaction = recurring.generateTransaction(for: startOfDay)
                addTransaction(transaction)
                recurring.lastGenerated = startOfDay
                updateRecurringTransaction(recurring)
            }
        }
    }

    /// Get upcoming recurring transactions for the next N days
    func upcomingRecurringTransactions(days: Int = 30) -> [(RecurringTransaction, Date)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: days, to: today) ?? today
        var results: [(RecurringTransaction, Date)] = []

        for recurring in recurringTransactions where recurring.isEnabled {
            let dates = recurring.frequency.datesBetween(start: max(recurring.startDate, today), end: endDate)
            for date in dates {
                if recurring.shouldFire(on: date, asOf: today) {
                    results.append((recurring, date))
                }
            }
        }

        return results.sorted { $0.1 < $1.1 }
    }

    // MARK: - Monthly Income/Expense History (for charts)

    struct MonthlyHistory: Identifiable {
        let id = UUID()
        let month: Date
        let income: Double
        let expenses: Double
        let net: Double
    }

    /// Get monthly income and expenses for the last N months
    func getMonthlyHistory(months: Int = 12) -> [MonthlyHistory] {
        let calendar = Calendar.current
        let now = Date()
        var history: [MonthlyHistory] = []

        for i in (0..<months).reversed() {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                let monthTransactions = transactions.filter {
                    calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month)
                }
                let income = monthTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
                let expenses = monthTransactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
                history.append(MonthlyHistory(month: monthDate, income: income, expenses: expenses, net: income - expenses))
            }
        }

        return history
    }

    // MARK: - Export Reports

    func exportToCSV(transactions: [Transaction]? = nil) -> String {
        let txns = transactions ?? self.transactions.sorted { $0.date > $1.date }
        var csv = "Date,Description,Amount,Category,Merchant,Notes,Source,Is Income\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for t in txns {
            let dateStr = dateFormatter.string(from: t.date)
            let desc = "\"\(t.description.replacingOccurrences(of: "\"", with: "\"\""))\""
            let amount = String(format: "%.2f", t.amount)
            let category = t.category.rawValue
            let merchant = "\"\(t.merchant.replacingOccurrences(of: "\"", with: "\"\""))\""
            let notes = "\"\(t.notes.replacingOccurrences(of: "\"", with: "\"\""))\""
            let source = t.source.rawValue
            let isIncome = t.isIncome ? "Yes" : "No"

            csv += "\(dateStr),\(desc),\(amount),\(category),\(merchant),\(notes),\(source),\(isIncome)\n"
        }

        return csv
    }

    func exportToJSON(transactions: [Transaction]? = nil) -> String {
        let txns = transactions ?? self.transactions.sorted { $0.date > $1.date }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let data = try? encoder.encode(txns),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "[]"
    }

    func exportMonthlyReport(months: Int = 12) -> String {
        let history = getMonthlyHistory(months: months)
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        var report = "Monthly Financial Report\n"
        report += "Generated: \(formatter.string(from: Date()))\n"
        report += String(repeating: "=", count: 60) + "\n\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"

        var totalIncome: Double = 0
        var totalExpenses: Double = 0

        for entry in history {
            let monthStr = dateFormatter.string(from: entry.month)
            report += "\(monthStr)\n"
            report += "  Income:   \(AppFormatters.formatCurrency(entry.income))\n"
            report += "  Expenses: \(AppFormatters.formatCurrency(entry.expenses))\n"
            report += "  Net:      \(entry.net >= 0 ? "+" : "")\(AppFormatters.formatCurrency(entry.net))\n"
            report += "\n"
            totalIncome += entry.income
            totalExpenses += entry.expenses
        }

        report += String(repeating: "-", count: 40) + "\n"
        report += "TOTALS\n"
        report += "  Total Income:   \(AppFormatters.formatCurrency(totalIncome))\n"
        report += "  Total Expenses: \(AppFormatters.formatCurrency(totalExpenses))\n"
        report += "  Net:            \(AppFormatters.formatCurrency(totalIncome - totalExpenses))\n"

        return report
    }
}


enum BudgetConvergenceMode: String, Codable {
    case converged
    case separated
}

enum AITier: String, Codable, CaseIterable {
    case free = "Free (Deepseek/Groq)"
    case premium = "Premium (Advanced AI)"
}

struct UserSettings: Codable, Equatable {
    static func == (lhs: UserSettings, rhs: UserSettings) -> Bool {
        lhs.savingsGoal == rhs.savingsGoal &&
        lhs.savingsGoalDeadline == rhs.savingsGoalDeadline &&
        lhs.monthlyIncome == rhs.monthlyIncome &&
        lhs.currentSavings == rhs.currentSavings &&
        lhs.diningImportance == rhs.diningImportance &&
        lhs.entertainmentImportance == rhs.entertainmentImportance &&
        lhs.shoppingImportance == rhs.shoppingImportance &&
        lhs.savingsPace == rhs.savingsPace &&
        lhs.incomeMode == rhs.incomeMode &&
        lhs.emergencyFundMode == rhs.emergencyFundMode &&
        lhs.emergencyFundMonths == rhs.emergencyFundMonths &&
        lhs.budgetLimits == rhs.budgetLimits &&
        lhs.familySize == rhs.familySize &&
        lhs.spouseIncome == rhs.spouseIncome &&
        lhs.isSpouseWorking == rhs.isSpouseWorking &&
        lhs.childAges == rhs.childAges &&
        lhs.convergenceMode == rhs.convergenceMode &&
        lhs.aiTier == rhs.aiTier
    }
    
    var monthlyIncome: Double = 5000
    var savingsGoal: Double = 10000
    var savingsGoalName: String = "Emergency Fund"
    var savingsGoalDeadline: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var currentSavings: Double = 0
    var incomeMode: IncomeMode = .auto
    var emergencyFundMode: EmergencyFundMode = .ai
    var emergencyFundMonths: Int = 6
    var budgetLimits: [TransactionCategory: Double] = [:]
    
    var savingsPace: SavingsPace = .moderate
    var diningImportance: ImportanceLevel = .medium
    var entertainmentImportance: ImportanceLevel = .medium
    var shoppingImportance: ImportanceLevel = .low
    
    // Family Budgeting
    var familySize: Int = 1
    var spouseIncome: Double = 0
    var isSpouseWorking: Bool = false
    var childAges: [Int] = []
    var convergenceMode: BudgetConvergenceMode = .converged
    
    // AI Tiers
    var aiTier: AITier = .free
}

// MARK: - Profiles / Roles

enum ProfileRole: String, Codable, CaseIterable {
    case manager
    case contributor
    case viewer
    
    var permissions: [String] {
        switch self {
        case .manager: return ["full"]
        case .contributor: return ["limited"]
        case .viewer: return ["read"]
        }
    }
    
    var displayName: String {
        switch self {
        case .manager: return "Manager"
        case .contributor: return "Contributor"
        case .viewer: return "Viewer"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value.lowercased() {
        case "manager": self = .manager
        case "deputy", "contributor": self = .contributor
        case "viewer": self = .viewer
        default: self = .viewer
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var role: ProfileRole
    
    init(id: UUID = UUID(), name: String, role: ProfileRole) {
        self.id = id
        self.name = name
        self.role = role
    }
}
