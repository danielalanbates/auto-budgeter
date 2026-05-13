import SwiftUI

struct BudgetPlannerView: View {
    @ObservedObject var dataStore: BudgetDataStore
    @State private var sliderValue: Double = 0.5
    @State private var debouncedSliderValue: Double = 0.5
    @State private var sliderTask: Task<Void, Never>?
    @State private var aiSuggestion: AISuggestion?
    @State private var isGeneratingAI = false
    @State private var scenarios: [String: BudgetPlan] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("🎯 Budget Planner")
                        .font(.largeTitle.bold())
                    Spacer()
                    Button(action: generateAISuggestion) {
                        Label(isGeneratingAI ? "Generating..." : "AI Suggestion", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGeneratingAI)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let ai = aiSuggestion {
                    aiSuggestionCard(ai)
                }
                
                // Scenario tabs - use the cached scenarios state to avoid re-generation in body
                if !scenarios.isEmpty {
                    let response = createResponse()
                    scenarioSection(scenarios, response: response)
                    
                    // Custom slider
                    sliderSection(response: response)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Analyzing your financial data...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding(24)
        }
        .onAppear {
            updateScenarios()
            if aiSuggestion == nil {
                generateAISuggestion()
            }
        }
        .onChange(of: dataStore.userSettings) { _ in
            updateScenarios()
        }
        .onChange(of: sliderValue) { newValue in
            sliderTask?.cancel()
            sliderTask = Task {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms throttle
                guard !Task.isCancelled else { return }
                debouncedSliderValue = newValue
            }
        }
    }
    
    private func updateScenarios() {
        // Prevent redundant calculation if data hasn't changed
        let response = createResponse()
        let generator = BudgetGenerator(response: response)
        let newScenarios = generator.generateAllScenarios()
        
        // Only update state if results are actually different to avoid UI loops
        if self.scenarios.isEmpty || self.scenarios["moderate"]?.monthlySavings != newScenarios["moderate"]?.monthlySavings {
            DispatchQueue.main.async {
                self.scenarios = newScenarios
            }
        }
    }
    
    private func createResponse() -> QuestionnaireResponse {
        QuestionnaireResponse(
            primaryGoal: .other,
            goalAmount: dataStore.userSettings.savingsGoal,
            goalTimeline: dataStore.userSettings.savingsGoalDeadline,
            monthlyIncome: max(1, dataStore.userSettings.monthlyIncome),
            currentSavings: dataStore.userSettings.currentSavings,
            monthlyDebtPayments: 0,
            diningImportance: dataStore.userSettings.diningImportance,
            entertainmentImportance: dataStore.userSettings.entertainmentImportance,
            shoppingImportance: dataStore.userSettings.shoppingImportance,
            savingsPace: dataStore.userSettings.savingsPace
        )
    }
    
    private func generateAISuggestion() {
        isGeneratingAI = true
        let resp = createResponse()
        
        Task {
            do {
                let suggestion = try await AIService.shared.generateBudgetSuggestions(
                    income: resp.monthlyIncome,
                    goal: resp.goalAmount,
                    months: resp.timelineMonths,
                    familySize: dataStore.userSettings.familySize,
                    isSpouseWorking: dataStore.userSettings.isSpouseWorking,
                    spouseIncome: dataStore.userSettings.spouseIncome,
                    childAges: dataStore.userSettings.childAges,
                    tier: dataStore.userSettings.aiTier
                )
                await MainActor.run {
                    self.aiSuggestion = suggestion
                    self.isGeneratingAI = false
                }
            } catch {
                print("AI Error: \(error)")
                await MainActor.run {
                    self.isGeneratingAI = false
                }
            }
        }
    }
    
    private func aiSuggestionCard(_ ai: AISuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("✨ AI Recommended Plan")
                    .font(.headline)
                Spacer()
                Text("Powered by Deepseek")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(ai.explanation)
                .font(.system(size: 13))
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Monthly Savings")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(AppFormatters.formatCurrency(ai.savingsAmount))
                        .font(.title3.bold())
                }
                
                VStack(alignment: .leading) {
                    Text("Monthly Spending")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(AppFormatters.formatCurrency(ai.spendingAmount))
                        .font(.title3.bold())
                }
            }
            
            Divider()
            
            Text("Suggested Breakdown:")
                .font(.system(size: 12).bold())
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(ai.categories.sorted(by: { $0.value > $1.value }), id: \.key) { cat, amt in
                    HStack {
                        Text(cat)
                        Spacer()
                        Text(AppFormatters.formatCurrency(amt))
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 12))
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appSecondary.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func scenarioSection(_ plans: [String: BudgetPlan], response: QuestionnaireResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📈 Budget Scenarios")
                .font(.headline)
            
            HStack(spacing: 16) {
                ForEach(["conservative", "moderate", "aggressive"], id: \.self) { key in
                    if let plan = plans[key] {
                        planCard(plan, income: response.monthlyIncome)
                    }
                }
            }
        }
    }
    
    private func planCard(_ plan: BudgetPlan, income: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.name)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Monthly Savings")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(AppFormatters.formatCurrency(plan.monthlySavings))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Timeline")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(plan.timelineMonths) months")
                }
                
                HStack {
                    Text("Success Rate")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(plan.successProbability * 100))%")
                }
            }
            .font(.callout)
            
            Text(plan.lifestyleImpactShort)
                .font(.system(size: 12))
                .padding(6)
                .background(Color.appAccent.opacity(0.2))
                .cornerRadius(6)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
    
    private func sliderSection(response: QuestionnaireResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎚️ Custom Plan")
                .font(.headline)
            
            HStack {
                Text("Conservative")
                    .font(.system(size: 12))
                Slider(value: $sliderValue, in: 0...1, step: 0.05)
                Text("Aggressive")
                    .font(.system(size: 12))
            }
            
            let generator = BudgetGenerator(response: response)
            let custom = generator.generateCustomScenario(sliderPosition: debouncedSliderValue)
            planCard(custom, income: response.monthlyIncome)
        }
    }
}
