import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var dataStore: BudgetDataStore
    @State private var showingAddCategory = false
    @State private var newCategoryName: String = ""
    @State private var newCategoryLimit: Double = 0
    
    @State private var categoryRows: [CategoryRowItem] = []
    @State private var topSpendingCategories: [(TransactionCategory, Double)] = []
    @State private var recentTransactions: [Transaction] = []
    
    struct CategoryRowItem: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let color: Color
        let limit: Double
        let spent: Double
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                quickStatsSection
                
                budgetCategoriesSection
                
                goalProgressSection
                
                spendingChartSection
                
                recentTransactionsSection
            }
            .padding(24)
        }
        .onAppear {
            updateDashboardData()
        }
        .onChange(of: dataStore.transactions) { _ in
            updateDashboardData()
        }
        .onChange(of: dataStore.userSettings) { _ in
            updateDashboardData()
        }
        .onChange(of: dataStore.activeProfileId) { _ in
            updateDashboardData()
        }
    }
    
    private func updateDashboardData() {
        let defaults: [TransactionCategory] = [
            .housing, .groceries, .diningOut, .utilities, .transportation,
            .healthcare, .insurance, .debtPayments, .savings, .entertainment, .shopping
        ]
        
        let defaultRows = defaults.map { cat -> CategoryRowItem in
            let limit = dataStore.userSettings.budgetLimits[cat] ?? 0
            let spent = dataStore.expensesByCategory[cat] ?? 0
            return CategoryRowItem(name: cat.rawValue, emoji: categoryEmoji(cat), color: colorFor(cat), limit: limit, spent: spent)
        }
        
        let customRows = dataStore.customBudgetCategories.map { cat -> CategoryRowItem in
            // For custom categories, we'd need to calculate spent from transactions
            let spent = dataStore.filteredTransactions
                .filter { !$0.isIncome && $0.category == .uncategorized && $0.description.lowercased().contains(cat.name.lowercased()) }
                .reduce(0) { $0 + $1.amount }
            return CategoryRowItem(name: cat.name, emoji: cat.emoji, color: Color(hex: cat.colorHex), limit: cat.limit, spent: spent)
        }
        
        self.categoryRows = defaultRows + customRows
        self.topSpendingCategories = Array(dataStore.expensesByCategory.sorted { $0.value > $1.value }.prefix(8))
        self.recentTransactions = Array(dataStore.filteredTransactions.sorted { $0.date > $1.date }.prefix(5))
    }
    
    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Dashboard")
                .font(.largeTitle.bold())
            Text(Date(), style: .date)
                .foregroundColor(.secondary)
                .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 20) {
            statCard("Monthly Income", value: AppFormatters.formatCurrency(dataStore.derivedIncome), icon: "arrow.down.circle.fill", color: .green)
            statCard("Total Spent", value: AppFormatters.formatCurrency(dataStore.totalExpenses), icon: "arrow.up.circle.fill", color: .red)
            statCard("Balance", value: AppFormatters.formatCurrency(dataStore.balance), icon: "banknote.fill", color: dataStore.balance >= 0 ? .green : .red)
            statCard("Transactions", value: "\(dataStore.filteredTransactions.count)", icon: "list.bullet.rectangle", color: .blue)
        }
    }
    
    private func statCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
    
    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎯 \(dataStore.userSettings.savingsGoalName)")
                    .font(.headline)
                Spacer()
                Text("\(AppFormatters.formatCurrency(dataStore.userSettings.currentSavings)) / \(AppFormatters.formatCurrency(dataStore.userSettings.savingsGoal))")
                    .foregroundColor(.secondary)
            }
            
            let progress = dataStore.userSettings.currentSavings / max(1, dataStore.userSettings.savingsGoal)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progress >= 1 ? Color.green : Color.accentColor)
                        .frame(width: geo.size.width * max(0, min(1, progress)))
                }
            }
            .frame(height: 24)
            
            HStack {
                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                if let deadline = Calendar.current.dateComponents([.day], from: Date(), to: dataStore.userSettings.savingsGoalDeadline).day {
                    Text("\(deadline) days remaining")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
    
    private var budgetCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🗂️ Budget Categories")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(categoryRows) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(item.emoji) \(item.name)")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text(AppFormatters.formatCurrency(item.limit))
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        
                        let remaining = item.limit - item.spent
                        let pct = item.limit > 0 ? min(1, item.spent / item.limit) : 0
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.color.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .scaleEffect(x: pct, y: 1, anchor: .leading)
                                .frame(height: 10)
                        }
                        
                        HStack {
                            Text("Spent: \(AppFormatters.formatCurrency(item.spent))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(remaining >= 0 ? "Left: \(AppFormatters.formatCurrency(remaining))" : "Over: \(AppFormatters.formatCurrency(abs(remaining)))")
                                .font(.system(size: 12))
                                .foregroundColor(remaining >= 0 ? .secondary : .red)
                        }
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground.opacity(0.5))
        .cornerRadius(12)
        .sheet(isPresented: $showingAddCategory) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Budget Category")
                    .font(.title2.bold())
                TextField("Category name", text: $newCategoryName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Text("Monthly limit")
                    Spacer()
                    TextField("$", value: $newCategoryLimit, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
                HStack {
                    Spacer()
                    Button("Cancel") {
                        showingAddCategory = false
                    }
                    Button("Save") {
                        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        dataStore.addCustomCategory(name: trimmed, limit: newCategoryLimit)
                        newCategoryName = ""
                        newCategoryLimit = 0
                        showingAddCategory = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 360)
        }
    }
    
    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Spending by Category")
                .font(.headline)
            
            if !topSpendingCategories.isEmpty {
                if #available(macOS 14.0, *) {
                    Chart {
                        ForEach(topSpendingCategories, id: \.0) { category, amount in
                            BarMark(
                                x: .value("Amount", amount),
                                y: .value("Category", category.rawValue)
                            )
                            .foregroundStyle(colorFor(category).gradient)
                        }
                    }
                    .frame(height: 250)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(topSpendingCategories, id: \.0) { category, amount in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(colorFor(category))
                                Text(category.rawValue)
                                    .font(.system(size: 12))
                                Spacer()
                                Text(AppFormatters.formatCurrency(amount))
                                    .fontWeight(.medium)
                            }
                            .padding(8)
                            .background(Color.appCardBackground)
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                Text("No spending data yet")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📝 Recent Transactions")
                    .font(.headline)
                Spacer()
            }
            
            if recentTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No transactions yet")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Import a file or add transactions manually")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
            } else {
                ForEach(recentTransactions) { transaction in
                    HStack {
                        Image(systemName: transaction.category.icon)
                            .foregroundColor(colorFor(transaction.category))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text(transaction.description)
                                .font(.system(size: 14))
                                .lineLimit(1)
                            Text(transaction.date, style: .date)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(transaction.isIncome ? "+\(AppFormatters.formatCurrency(transaction.amount))" : AppFormatters.formatCurrency(transaction.amount))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(transaction.isIncome ? .green : .primary)
                    }
                    .padding(.vertical, 4)
                    
                    if transaction.id != recentTransactions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
    
    private func colorFor(_ category: TransactionCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "brown": return .brown
        case "cyan": return .cyan
        case "teal": return .teal
        case "indigo": return .indigo
        case "mint": return .mint
        default: return .gray
        }
    }

    private func categoryEmoji(_ category: TransactionCategory) -> String {
        switch category {
        case .housing: return "🏠"
        case .groceries: return "🛒"
        case .diningOut: return "🍽️"
        case .utilities: return "💡"
        case .transportation: return "🚗"
        case .healthcare: return "💊"
        case .insurance: return "🛡️"
        case .debtPayments: return "💳"
        case .savings: return "💰"
        case .entertainment: return "🎮"
        case .shopping: return "🛍️"
        default: return "📊"
        }
    }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexSanitized.count == 6 { hexSanitized.append("FF") }
        var int: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&int)
        let a = Double((int >> 24) & 0xff) / 255.0
        let r = Double((int >> 16) & 0xff) / 255.0
        let g = Double((int >> 8) & 0xff) / 255.0
        let b = Double(int & 0xff) / 255.0
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
