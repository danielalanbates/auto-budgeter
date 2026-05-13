import SwiftUI

struct TransactionsView: View {
    @ObservedObject var dataStore: BudgetDataStore
    @State private var searchText = ""
    @State private var selectedCategory: TransactionCategory?
    @State private var showingAddTransaction = false
    @State private var editingTransaction: Transaction?
    @State private var sortOrder: SortOrder = .dateDesc
    
    @State private var filteredTransactionsCache: [Transaction] = []
    @State private var isProcessing = false
    
    enum SortOrder: String, CaseIterable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case amountDesc = "Highest Amount"
        case amountAsc = "Lowest Amount"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search transactions...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(8)
                .background(Color.appCardBackground)
                .cornerRadius(8)
                .frame(maxWidth: 300)
                
                Spacer()
                
                // Category filter
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as TransactionCategory?)
                    Divider()
                    ForEach(TransactionCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat as TransactionCategory?)
                            .font(.system(size: 13))
                    }
                }
                .frame(width: 180)
                
                // Sort
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                            .font(.system(size: 13))
                    }
                }
                .frame(width: 150)
                
                // Add button
                Button(action: { showingAddTransaction = true }) {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Summary
            HStack(spacing: 30) {
                summaryCard("Total Income", amount: dataStore.totalIncome, color: .green)
                summaryCard("Total Expenses", amount: dataStore.totalExpenses, color: .red)
                summaryCard("Balance", amount: dataStore.balance, color: dataStore.balance >= 0 ? .green : .red)
                summaryCard("Transactions", count: dataStore.transactions.count)
            }
            .padding()
            .background(Color.appCardBackground)
            
            Divider()
            
            // Transaction list
            ZStack {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if filteredTransactionsCache.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No transactions found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        if dataStore.transactions.isEmpty {
                            Text("Import a file or add transactions manually")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredTransactionsCache) { transaction in
                            TransactionRow(transaction: transaction)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingTransaction = transaction
                                }
                                .contextMenu {
                                    Button("Edit") { editingTransaction = transaction }
                                    Button("Delete", role: .destructive) {
                                        dataStore.deleteTransaction(transaction)
                                    }
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                dataStore.deleteTransaction(filteredTransactionsCache[index])
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            TransactionEditorView(dataStore: dataStore, transaction: nil)
        }
        .sheet(item: $editingTransaction) { transaction in
            TransactionEditorView(dataStore: dataStore, transaction: transaction)
        }
        .onAppear {
            updateFilteredTransactions()
        }
        .onChange(of: searchText) { _ in updateFilteredTransactions() }
        .onChange(of: selectedCategory) { _ in updateFilteredTransactions() }
        .onChange(of: sortOrder) { _ in updateFilteredTransactions() }
        .onChange(of: dataStore.transactions) { _ in updateFilteredTransactions() }
    }
    
    private func updateFilteredTransactions() {
        let currentSearch = searchText
        let currentCategory = selectedCategory
        let currentSort = sortOrder
        let allTransactions = dataStore.transactions
        
        isProcessing = true
        
        // Use background thread for filtering large data sets
        DispatchQueue.global(qos: .userInteractive).async {
            var result = allTransactions
            
            if !currentSearch.isEmpty {
                result = result.filter {
                    $0.description.localizedCaseInsensitiveContains(currentSearch) ||
                    $0.merchant.localizedCaseInsensitiveContains(currentSearch) ||
                    $0.category.rawValue.localizedCaseInsensitiveContains(currentSearch)
                }
            }
            
            if let category = currentCategory {
                result = result.filter { $0.category == category }
            }
            
            switch currentSort {
            case .dateDesc: result.sort { $0.date > $1.date }
            case .dateAsc: result.sort { $0.date < $1.date }
            case .amountDesc: result.sort { $0.amount > $1.amount }
            case .amountAsc: result.sort { $0.amount < $1.amount }
            }
            
            DispatchQueue.main.async {
                self.filteredTransactionsCache = result
                self.isProcessing = false
            }
        }
    }
    
    private func summaryCard(_ title: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(formatCurrency(amount))
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(minWidth: 120)
    }
    
    private func summaryCard(_ title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.title2.bold())
        }
        .frame(minWidth: 120)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.category.icon)
                    .foregroundColor(categoryColor)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(transaction.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(transaction.date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount
            Text(formatAmount)
                .font(.headline)
                .foregroundColor(transaction.isIncome ? .green : .primary)
        }
        .padding(.vertical, 4)
    }
    
    private var categoryColor: Color {
        switch transaction.category.color {
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
    
    private var formatAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let str = formatter.string(from: NSNumber(value: transaction.amount)) ?? "$\(transaction.amount)"
        return transaction.isIncome ? "+\(str)" : str
    }
}

// MARK: - Transaction Editor

struct TransactionEditorView: View {
    @ObservedObject var dataStore: BudgetDataStore
    let transaction: Transaction?
    @Environment(\.dismiss) private var dismiss
    
    @State private var description = ""
    @State private var amount: Double = 0
    @State private var date = Date()
    @State private var category: TransactionCategory = .uncategorized
    @State private var isIncome = false
    @State private var notes = ""
    
    var isEditing: Bool { transaction != nil }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isEditing ? "Edit Transaction" : "Add Transaction")
                .font(.title2.bold())
            
            Form {
                TextField("Description", text: $description)
                
                HStack {
                    Text("$")
                    TextField("Amount", value: $amount, format: .number)
                }
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Picker("Category", selection: $category) {
                    ForEach(TransactionCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
                
                Toggle("This is income", isOn: $isIncome)
                
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3)
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                
                Spacer()
                
                if isEditing {
                    Button("Delete", role: .destructive) {
                        if let t = transaction {
                            dataStore.deleteTransaction(t)
                        }
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                
                Button(isEditing ? "Save" : "Add") {
                    saveTransaction()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty || amount <= 0)
            }
        }
        .padding(30)
        .background(Color.appBackground)
        .frame(width: 450, height: 450)
        .onAppear {
            if let t = transaction {
                description = t.description
                amount = t.amount
                date = t.date
                category = t.category
                isIncome = t.isIncome
                notes = t.notes
            }
        }
    }
    
    private func saveTransaction() {
        if let existing = transaction {
            var updated = existing
            updated.description = description
            updated.amount = amount
            updated.date = date
            updated.category = category
            updated.isIncome = isIncome
            updated.notes = notes
            dataStore.updateTransaction(updated)
        } else {
            let new = Transaction(
                date: date,
                description: description,
                amount: amount,
                category: category,
                notes: notes,
                isIncome: isIncome,
                source: .manual
            )
            dataStore.addTransaction(new)
        }
    }
}
