import SwiftUI

struct RecurringTransactionsView: View {
    @ObservedObject var dataStore: BudgetDataStore
    @State private var showingAddRecurring = false
    @State private var editingRecurring: RecurringTransaction?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🔄 Recurring Transactions")
                    .font(.title2.bold())
                Spacer()
                Button(action: { showingAddRecurring = true }) {
                    Label("Add Recurring", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            if dataStore.recurringTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "repeat")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No recurring transactions yet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("Add subscriptions, rent, salary, or any repeating transaction")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(dataStore.recurringTransactions) { recurring in
                            recurringCard(recurring)
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingAddRecurring) {
            RecurringTransactionEditorView(dataStore: dataStore, transaction: nil)
        }
        .sheet(item: $editingRecurring) { recurring in
            RecurringTransactionEditorView(dataStore: dataStore, transaction: recurring)
        }
        .onAppear {
            dataStore.processRecurringTransactions()
        }
    }

    private func recurringCard(_ recurring: RecurringTransaction) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: recurring.category.icon)
                    .foregroundColor(.accentColor)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(recurring.description)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Text(recurring.frequency.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { recurring.isEnabled },
                    set: { isEnabled in
                        var updated = recurring
                        updated.isEnabled = isEnabled
                        dataStore.updateRecurringTransaction(updated)
                    }
                ))
                .labelsHidden()
                .scaleEffect(0.8)
            }

            HStack {
                Text(recurring.isIncome ? "+\(AppFormatters.formatCurrency(recurring.amount))" : AppFormatters.formatCurrency(recurring.amount))
                    .font(.title3.bold())
                    .foregroundColor(recurring.isIncome ? .green : .primary)
                Spacer()
                if let last = recurring.lastGenerated {
                    Text("Last: \(last, style: .date)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Spacer()
                Button("Edit") {
                    editingRecurring = recurring
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(role: .destructive) {
                    dataStore.deleteRecurringTransaction(recurring)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .opacity(recurring.isEnabled ? 1 : 0.6)
    }
}

// MARK: - Recurring Transaction Editor

struct RecurringTransactionEditorView: View {
    @ObservedObject var dataStore: BudgetDataStore
    let transaction: RecurringTransaction?
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var amount: Double = 0
    @State private var date = Date()
    @State private var category: TransactionCategory = .uncategorized
    @State private var isIncome = false
    @State private var notes = ""
    @State private var frequency: RecurringFrequency = .monthly
    @State private var endDate: Date?

    var isEditing: Bool { transaction != nil }

    var body: some View {
        VStack(spacing: 20) {
            Text(isEditing ? "Edit Recurring Transaction" : "Add Recurring Transaction")
                .font(.title2.bold())

            Form {
                TextField("Description (e.g., Rent, Netflix)", text: $description)

                HStack {
                    Text("$")
                    TextField("Amount", value: $amount, format: .number)
                }

                DatePicker("Start Date", selection: $date, displayedComponents: .date)

                Picker("Frequency", selection: $frequency) {
                    ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }

                DatePicker("End Date (optional)", selection: Binding(
                    get: { endDate ?? Date().addingTimeInterval(365 * 24 * 60 * 60) },
                    set: { endDate = $0 }
                ), displayedComponents: .date)

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
                            dataStore.deleteRecurringTransaction(t)
                        }
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }

                Button(isEditing ? "Save" : "Add") {
                    saveRecurringTransaction()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty || amount <= 0)
            }
        }
        .padding(30)
        .background(Color.appBackground)
        .frame(width: 450, height: 520)
        .onAppear {
            if let t = transaction {
                description = t.description
                amount = t.amount
                date = t.startDate
                category = t.category
                isIncome = t.isIncome
                notes = t.notes
                frequency = t.frequency
                endDate = t.endDate
            }
        }
    }

    private func saveRecurringTransaction() {
        if let existing = self.transaction {
            var updated = existing
            updated.description = description
            updated.amount = amount
            updated.startDate = date
            updated.category = category
            updated.isIncome = isIncome
            updated.notes = notes
            updated.frequency = frequency
            updated.endDate = endDate
            dataStore.updateRecurringTransaction(updated)
        } else {
            let new = RecurringTransaction(
                description: description,
                amount: amount,
                category: category,
                isIncome: isIncome,
                notes: notes,
                startDate: date,
                frequency: frequency,
                endDate: endDate
            )
            dataStore.addRecurringTransaction(new)
        }
    }
}
