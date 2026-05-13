import SwiftUI
import Charts

struct BudgetResultsView: View {
    let response: QuestionnaireResponse
    @Binding var showQuestionnaire: Bool
    
    @State private var sliderValue: Double = 0.5
    @State private var debouncedSliderValue: Double = 0.5
    @State private var customPlan: BudgetPlan?
    @State private var plans: [String: BudgetPlan] = [:]
    @State private var selectedTab = 1 // Default to moderate
    @State private var sliderTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                Divider()
                
                // Goal summary
                goalSummary
                
                Divider()
                
                // Three scenarios
                if !plans.isEmpty {
                    scenarioTabs
                    
                    Divider()
                    
                    // Custom slider
                    customSliderSection
                } else {
                    ProgressView("Calculating plans...")
                        .padding()
                }
                
                Divider()
                
                // Start over button
                Button("🔄 Start Over") {
                    showQuestionnaire = true
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            updatePlans()
            updateCustomPlan()
        }
        .onChange(of: sliderValue) { newValue in
            sliderTask?.cancel()
            sliderTask = Task {
                // Throttle slider updates to prevent UI jank
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                guard !Task.isCancelled else { return }
                debouncedSliderValue = newValue
                updateCustomPlan()
            }
        }
    }
    
    private func updatePlans() {
        let gen = BudgetGenerator(response: response)
        let newPlans = gen.generateAllScenarios()
        
        // Only update if actually different to prevent redraw loops
        if plans.isEmpty || plans["moderate"]?.monthlySavings != newPlans["moderate"]?.monthlySavings {
            self.plans = newPlans
        }
    }
    
    private func updateCustomPlan() {
        let gen = BudgetGenerator(response: response)
        self.customPlan = gen.generateCustomScenario(sliderPosition: debouncedSliderValue)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🎯 Your Personalized Budget Plans")
                .font(.system(size: 24, weight: .bold))
            Text("Based on your questionnaire responses")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    private var goalSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Your Goal")
                .font(.system(size: 18, weight: .bold))
            
            HStack(spacing: 40) {
                metricView(title: "💰 Goal Amount", value: AppFormatters.formatCurrency(response.goalAmount))
                metricView(title: "📅 Timeline", value: "\(response.timelineMonths) months")
                metricView(title: "💵 Monthly Income", value: AppFormatters.formatCurrency(response.monthlyIncome))
                metricView(title: "🏦 Current Savings", value: AppFormatters.formatCurrency(response.currentSavings))
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
    
    private var scenarioTabs: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📈 Three Budget Scenarios")
                .font(.system(size: 18, weight: .bold))
            
            Text("Choose the plan that fits your lifestyle")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Picker("Scenario", selection: $selectedTab) {
                Text("🐢 Conservative").tag(0)
                Text("🚶 Moderate").tag(1)
                Text("🏃 Aggressive").tag(2)
            }
            .pickerStyle(.segmented)
            
            if let plan = currentPlan {
                planDetailView(plan)
            }
        }
    }
    
    private var currentPlan: BudgetPlan? {
        switch selectedTab {
        case 0: return plans["conservative"]
        case 1: return plans["moderate"]
        case 2: return plans["aggressive"]
        default: return nil
        }
    }
    
    private var customSliderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎚️ Customize Your Plan")
                .font(.system(size: 18, weight: .bold))
            
            Text("Drag the slider to adjust savings aggressiveness")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            HStack {
                Text("Conservative")
                    .font(.system(size: 12))
                Slider(value: $sliderValue, in: 0...1, step: 0.05)
                Text("Aggressive")
                    .font(.system(size: 12))
            }
            
            if let plan = customPlan {
                planDetailView(plan)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
    
    private func planDetailView(_ plan: BudgetPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Key metrics
            HStack(spacing: 30) {
                metricView(title: "💰 Monthly Savings", value: AppFormatters.formatCurrency(plan.monthlySavings))
                metricView(title: "📅 Timeline", value: "\(plan.timelineMonths) months")
                metricView(title: "🎯 Success Rate", value: "\(Int(plan.successProbability * 100))%")
                metricView(title: "🔄 Impact", value: plan.lifestyleImpactShort)
            }
            
            // Lifestyle impact info
            Text(plan.lifestyleImpact)
                .font(.system(size: 13))
                .padding(10)
                .background(Color.appAccent.opacity(0.2))
                .cornerRadius(8)
            
            // Category breakdown
            Text("📋 Budget Breakdown")
                .font(.system(size: 16, weight: .bold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(plan.categories.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                    HStack {
                        Text(category)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(AppFormatters.formatCurrency(amount))
                            .font(.system(size: 13))
                        if response.monthlyIncome > 0 {
                            Text("(\(Int(amount / response.monthlyIncome * 100))%)")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Chart
            if #available(macOS 14.0, *) {
                categoryChart(plan)
            }
            
            // Summary row
            HStack(spacing: 30) {
                metricView(title: "Total Allocated", value: AppFormatters.formatCurrency(plan.totalAllocated))
                metricView(title: "Monthly Savings", value: AppFormatters.formatCurrency(plan.monthlySavings))
                metricView(title: "Remaining", value: AppFormatters.formatCurrency(plan.remaining))
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
    
    @available(macOS 14.0, *)
    private func categoryChart(_ plan: BudgetPlan) -> some View {
        Chart {
            ForEach(plan.categories.sorted(by: { $0.value > $1.value }).prefix(8), id: \.key) { category, amount in
                BarMark(
                    x: .value("Amount", amount),
                    y: .value("Category", category)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
        }
        .frame(height: 200)
        .padding(.vertical)
    }
    
    private func metricView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold())
        }
    }
}
