import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataStore: BudgetDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var newProfileName: String = ""
    @State private var newProfileRole: ProfileRole = .viewer
    @State private var requestAmount: Double = 0
    @State private var requestNote: String = ""
    @State private var requestCategory: TransactionCategory = .groceries
    
    @State private var localMonthlyIncome: Double = 0
    @State private var localSavingsGoal: Double = 0
    @State private var localCurrentSavings: Double = 0
    @State private var localSavingsGoalName: String = ""
    @State private var localSpouseIncome: Double = 0
    @State private var localFamilySize: Int = 1
    @State private var localChildAges: [Int] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("⚙️ Settings")
                        .font(.largeTitle.bold())
                    Spacer()
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                }
                
                Divider()

                // Profiles & Roles
                settingsSection("👥 Profiles") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Active Profile")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { dataStore.activeProfile.id },
                                set: { id in
                                    if let profile = dataStore.profiles.first(where: { $0.id == id }) {
                                        dataStore.selectProfile(profile)
                                    }
                                }
                            )) {
                                ForEach(dataStore.profiles) { profile in
                                    Text("\(profile.name) (\(profile.role.displayName))").tag(profile.id)
                                }
                            }
                            .frame(width: 260)
                        }

                        Divider()

                        Text("Add Profile")
                            .font(.headline)
                        HStack {
                            TextField("Name", text: $newProfileName)
                                .textFieldStyle(.roundedBorder)
                            Picker("Role", selection: $newProfileRole) {
                                ForEach(ProfileRole.allCases, id: \.self) { role in
                                    Text(role.displayName).tag(role)
                                }
                            }
                            .pickerStyle(.segmented)
                            Button("Add") {
                                let trimmed = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    dataStore.addProfile(name: trimmed, role: newProfileRole)
                                    newProfileName = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if !dataStore.fundRequests.isEmpty && dataStore.activeProfile.role == .manager {
                            Divider()
                            Text("Pending Fund Requests")
                                .font(.headline)
                            ForEach(dataStore.fundRequests) { request in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(request.requesterName)
                                        Text("(\(request.role.rawValue))")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(request.createdAt, style: .date)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Text("\(request.category.rawValue): \(AppFormatters.formatCurrency(request.amount))")
                                        .fontWeight(.semibold)
                                    Text(request.note)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Spacer()
                                        Button("Mark Reviewed") {
                                            dataStore.resolveFundRequest(request)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .padding(8)
                                .background(Color.appCardBackground)
                                .cornerRadius(8)
                            }
                        }

                        if dataStore.activeProfile.role == .contributor {
                            Divider()
                            Text("Request Additional Funds")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Category", selection: $requestCategory) {
                                    ForEach(TransactionCategory.allCases.filter { $0 != .income && $0 != .uncategorized }, id: \.self) { category in
                                        Text(category.rawValue).tag(category)
                                    }
                                }
                                HStack {
                                    Text("Amount")
                                    Spacer()
                                    TextField("$", value: $requestAmount, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                }
                                TextField("Note to Manager", text: $requestNote, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                HStack {
                                    Spacer()
                                    Button("Send Request") {
                                        let note = requestNote.trimmingCharacters(in: .whitespacesAndNewlines)
                                        guard requestAmount > 0 else { return }
                                        dataStore.addFundRequest(
                                            category: requestCategory,
                                            amount: requestAmount,
                                            note: note.isEmpty ? "No note provided" : note,
                                            requester: dataStore.activeProfile
                                        )
                                        requestAmount = 0
                                        requestNote = ""
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                }
                
                // Income Mode
                settingsSection("💵 Income Mode") {
                    Picker("Mode", selection: $dataStore.userSettings.incomeMode) {
                        Text("Auto (from transactions)").tag(IncomeMode.auto)
                        Text("Manual (use Monthly Income)").tag(IncomeMode.manual)
                    }
                    .pickerStyle(.segmented)
                    
                    if dataStore.userSettings.incomeMode == .manual {
                        HStack {
                            Text("Manual Monthly Income")
                            Spacer()
                            TextField("$", value: $localMonthlyIncome, format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .onChange(of: localMonthlyIncome) { newValue in
                                    dataStore.userSettings.monthlyIncome = newValue
                                }
                        }
                    } else {
                        Text("Income will update automatically from imported transactions.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Emergency Fund Mode
                settingsSection("🛟 Emergency Fund") {
                    Picker("Mode", selection: $dataStore.userSettings.emergencyFundMode) {
                        Text("AI (recommended)").tag(EmergencyFundMode.ai)
                        Text("Manual").tag(EmergencyFundMode.manual)
                    }
                    .pickerStyle(.segmented)
                    
                    if dataStore.userSettings.emergencyFundMode == .manual {
                        Picker("Months of expenses", selection: $dataStore.userSettings.emergencyFundMonths) {
                            Text("3 months").tag(3)
                            Text("6 months").tag(6)
                            Text("9 months").tag(9)
                            Text("12 months").tag(12)
                        }
                        .pickerStyle(.segmented)
                    } else {
                        Text("AI will suggest the emergency fund based on your spending vs income.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Target Fund")
                        Spacer()
                        Text(AppFormatters.formatCurrency(dataStore.emergencyFundTarget))
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 13))
                }

                // Family & Household Section
                settingsSection("👨‍👩‍👧‍👦 Family & Household") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Family Size")
                            Spacer()
                            Stepper("\(localFamilySize) people", value: $localFamilySize, in: 1...20)
                                .onChange(of: localFamilySize) { newValue in
                                    dataStore.userSettings.familySize = newValue
                                    dataStore.syncFamilyProfiles()
                                }
                        }
                        
                        Divider()
                        
                        Toggle("Spouse is working", isOn: $dataStore.userSettings.isSpouseWorking)
                        
                        if dataStore.userSettings.isSpouseWorking {
                            HStack {
                                Text("Spouse's Monthly Income")
                                Spacer()
                                TextField("$", value: $localSpouseIncome, format: .currency(code: "USD"))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 150)
                                    .onChange(of: localSpouseIncome) { newValue in
                                        dataStore.userSettings.spouseIncome = newValue
                                    }
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Children")
                                Spacer()
                                Button("Add Child") {
                                    localChildAges.append(0)
                                    dataStore.userSettings.childAges = localChildAges
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            ForEach(0..<localChildAges.count, id: \.self) { index in
                                HStack {
                                    Text("Child \(index + 1) Age")
                                    Spacer()
                                    TextField("Age", value: $localChildAges[index], format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                        .onChange(of: localChildAges[index]) { _ in
                                            dataStore.userSettings.childAges = localChildAges
                                        }
                                    Button(role: .destructive) {
                                        localChildAges.remove(at: index)
                                        dataStore.userSettings.childAges = localChildAges
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Budget Management")
                                .font(.headline)
                            Picker("Mode", selection: $dataStore.userSettings.convergenceMode) {
                                Text("Converged (Combined)").tag(BudgetConvergenceMode.converged)
                                Text("Separated (Individual)").tag(BudgetConvergenceMode.separated)
                            }
                            .pickerStyle(.segmented)
                            
                            Text(dataStore.userSettings.convergenceMode == .converged ? 
                                 "Budgets for all family members are pooled together." : 
                                 "Each profile maintains its own separate budget.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Savings Goal Section
                settingsSection("🎯 Savings Goal") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Goal Name")
                            Spacer()
                            TextField("Emergency Fund", text: $localSavingsGoalName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                                .onChange(of: localSavingsGoalName) { newValue in
                                    dataStore.userSettings.savingsGoalName = newValue
                                }
                        }
                        
                        HStack {
                            Text("Target Amount")
                            Spacer()
                            TextField("$", value: $localSavingsGoal, format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .onChange(of: localSavingsGoal) { newValue in
                                    dataStore.userSettings.savingsGoal = newValue
                                }
                        }
                        
                        HStack {
                            Text("Current Savings")
                            Spacer()
                            TextField("$", value: $localCurrentSavings, format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .onChange(of: localCurrentSavings) { newValue in
                                    dataStore.userSettings.currentSavings = newValue
                                }
                        }
                        
                        HStack {
                            Text("Target Date")
                            Spacer()
                            DatePicker("", selection: $dataStore.userSettings.savingsGoalDeadline, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        // Progress
                        let progress = dataStore.userSettings.currentSavings / max(1, dataStore.userSettings.savingsGoal)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Progress")
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .fontWeight(.semibold)
                            }
                            ProgressView(value: min(1, progress))
                                .tint(progress >= 1 ? .green : .accentColor)
                        }
                    }
                }
                
                // Budget Limits Section
                settingsSection("📊 Monthly Budget Limits") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(TransactionCategory.allCases.filter { $0 != .income && $0 != .uncategorized }, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)
                                Text(category.rawValue)
                                    .font(.system(size: 12))
                                Spacer()
                                TextField("$", value: Binding(
                                    get: { dataStore.userSettings.budgetLimits[category] ?? 0 },
                                    set: { dataStore.userSettings.budgetLimits[category] = $0 }
                                ), format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            }
                        }
                    }
                }
                
                // Lifestyle Preferences
                settingsSection("🎚️ Lifestyle Preferences") {
                    VStack(alignment: .leading, spacing: 12) {
                        preferencePicker("Savings Pace", selection: $dataStore.userSettings.savingsPace)
                        preferencePicker("Dining Importance", selection: $dataStore.userSettings.diningImportance)
                        preferencePicker("Entertainment Importance", selection: $dataStore.userSettings.entertainmentImportance)
                        preferencePicker("Shopping Importance", selection: $dataStore.userSettings.shoppingImportance)
                    }
                }
                
                // AI Budgeting Section
                settingsSection("🤖 AI Budgeting") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("AI Tier", selection: $dataStore.userSettings.aiTier) {
                            ForEach(AITier.allCases, id: \.self) { tier in
                                Text(tier.rawValue).tag(tier)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if dataStore.userSettings.aiTier == .free {
                            Text("Deepseek (with Groq fallback) enabled.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Advanced AI Models Enabled")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Priority processing and more accurate budget strategies.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(30)
        }
        .frame(minWidth: 600, minHeight: 700)
        .onAppear {
            localMonthlyIncome = dataStore.userSettings.monthlyIncome
            localSavingsGoal = dataStore.userSettings.savingsGoal
            localCurrentSavings = dataStore.userSettings.currentSavings
            localSavingsGoalName = dataStore.userSettings.savingsGoalName
            localSpouseIncome = dataStore.userSettings.spouseIncome
            localFamilySize = dataStore.userSettings.familySize
            localChildAges = dataStore.userSettings.childAges
        }
        .onChange(of: dataStore.userSettings) { _ in
            dataStore.save()
        }
    }
    
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
    
    private func preferencePicker<T: RawRepresentable & CaseIterable & Hashable>(_ label: String, selection: Binding<T>) -> some View where T.RawValue == String, T.AllCases: RandomAccessCollection {
        HStack {
            Text(label)
            Spacer()
            Picker("", selection: selection) {
                ForEach(Array(T.allCases), id: \.self) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)
        }
    }
    
    private func formatCurrencyLocal(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}
