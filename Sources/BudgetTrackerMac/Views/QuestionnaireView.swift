import SwiftUI

struct QuestionnaireView: View {
    @Binding var response: QuestionnaireResponse
    @Binding var isComplete: Bool
    @State private var currentQuestion = 0
    
    private let totalQuestions = 14
    
    var body: some View {
        VStack(spacing: 0) {
            logoHeader
                .padding(.top, 12)
            
            // Progress bar
            ProgressView(value: Double(currentQuestion + 1), total: Double(totalQuestions))
                .progressViewStyle(.linear)
                .padding(.horizontal, 40)
                .padding(.top, 12)
            
            Text("Question \(currentQuestion + 1) of \(totalQuestions)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Spacer()
            
            // Question content
            VStack(spacing: 24) {
                questionContent
            }
            .padding(.horizontal, 60)
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if currentQuestion > 0 {
                    Button("⬅️ Previous") {
                        withAnimation { currentQuestion -= 1 }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button(currentQuestion < totalQuestions - 1 ? "Next ➡️" : "Generate Budget 🎯") {
                    if currentQuestion < totalQuestions - 1 {
                        withAnimation { currentQuestion += 1 }
                    } else {
                        // Finalize settings from questionnaire
                        isComplete = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isCurrentQuestionValid)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.appBackground)
    }
    
    @ViewBuilder
    private var questionContent: some View {
        switch currentQuestion {
        case 0:
            questionGoal
        case 1:
            questionGoalAmount
        case 2:
            questionTimeline
        case 3:
            questionFamilySize
        case 4:
            questionChildAges
        case 5:
            questionSpouseInfo
        case 6:
            questionConvergence
        case 7:
            questionIncome
        case 8:
            questionSavings
        case 9:
            questionDebt
        case 10:
            questionDining
        case 11:
            questionEntertainment
        case 12:
            questionShopping
        case 13:
            questionPace
        default:
            EmptyView()
        }
    }
    
    private var isCurrentQuestionValid: Bool {
        switch currentQuestion {
        case 1: return response.goalAmount > 0
        case 7: return response.monthlyIncome > 0
        default: return true
        }
    }
    
    private var questionFamilySize: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's your family size?")
                .font(.title2.bold())
            
            Stepper(value: $response.familySize, in: 1...20) {
                Text("\(response.familySize) person\(response.familySize == 1 ? "" : "s")")
                    .font(.title3)
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(8)
            
            Text("Include yourself, spouse, and dependents.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var questionChildAges: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ages of your children?")
                .font(.title2.bold())
            
            Text("This helps AI estimate childcare and education costs.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack {
                Text("Number of children:")
                Spacer()
                Picker("", selection: Binding(
                    get: { response.childAges.count },
                    set: { newVal in
                        if newVal > response.childAges.count {
                            response.childAges.append(contentsOf: Array(repeating: 0, count: newVal - response.childAges.count))
                        } else {
                            response.childAges = Array(response.childAges.prefix(newVal))
                        }
                    }
                )) {
                    ForEach(0...10, id: \.self) { num in
                        Text("\(num)").tag(num)
                    }
                }
            }
            
            if !response.childAges.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(0..<response.childAges.count, id: \.self) { index in
                            HStack {
                                Text("Child \(index + 1) age:")
                                Spacer()
                                TextField("Age", value: $response.childAges[index], format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }
    
    private var questionSpouseInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spouse Information")
                .font(.title2.bold())
            
            Toggle("Is your spouse currently working?", isOn: $response.isSpouseWorking)
                .padding(.vertical, 8)
            
            if response.isSpouseWorking {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spouse's monthly net income")
                        .font(.headline)
                    HStack {
                        Text("$")
                            .font(.title2)
                        TextField("Monthly Income", value: $response.spouseIncome, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .frame(maxWidth: 200)
                    }
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(8)
            }
        }
    }
    
    private var questionConvergence: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How should budgets be managed?")
                .font(.title2.bold())
            
            Picker("", selection: $response.convergenceMode) {
                Text("Converged (Combined household)").tag(BudgetConvergenceMode.converged)
                Text("Separated (Individual profiles)").tag(BudgetConvergenceMode.separated)
            }
            .pickerStyle(.radioGroup)
            
            Text(response.convergenceMode == .converged ? 
                 "Unified view of all income and expenses for the whole family." : 
                 "Each member sees their own budget based on their income share.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var questionGoal: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's your primary financial goal?")
                .font(.title2.bold())
            
            ForEach(FinancialGoal.allCases, id: \.self) { goal in
                Button(action: { response.primaryGoal = goal }) {
                    HStack {
                        Image(systemName: response.primaryGoal == goal ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(response.primaryGoal == goal ? .accentColor : .secondary)
                        Text(goal.label)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(response.primaryGoal == goal ? Color.appAccent.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var questionGoalAmount: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How much do you want to save?")
                .font(.title2.bold())
            
            HStack {
                Text("$")
                    .font(.title)
                TextField("10000", value: $response.goalAmount, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .frame(maxWidth: 200)
            }
            
            if response.goalAmount <= 0 {
                Text("Please enter an amount greater than $0")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
            }
        }
    }
    
    private var questionTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("When do you want to achieve this goal?")
                .font(.title2.bold())
            
            DatePicker("Target date:", selection: $response.goalTimeline, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .frame(maxWidth: 300)
            
            Text("That's \(response.timelineMonths) months from now")
                .foregroundColor(.secondary)
        }
    }
    
    private var questionIncome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's your monthly take-home income?")
                .font(.title2.bold())
            
            Text("After taxes, enter your net monthly income")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack {
                Text("$")
                    .font(.title)
                TextField("4500", value: $response.monthlyIncome, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .frame(maxWidth: 200)
            }
            
            if response.monthlyIncome <= 0 {
                Text("Please enter your income")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
            }
        }
    }
    
    private var questionSavings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How much do you currently have saved?")
                .font(.title2.bold())
            
            HStack {
                Text("$")
                    .font(.title)
                TextField("0", value: $response.currentSavings, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .frame(maxWidth: 200)
            }
        }
    }
    
    private var questionDebt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly debt payments (loans, credit cards)?")
                .font(.title2.bold())
            
            Text("Total minimum payments across all debts")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack {
                Text("$")
                    .font(.title)
                TextField("0", value: $response.monthlyDebtPayments, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .frame(maxWidth: 200)
            }
        }
    }
    
    private var questionDining: some View {
        importanceQuestion(
            title: "How important is dining out to you?",
            binding: $response.diningImportance,
            labels: [
                .high: "🍽️ Very important (can't give up)",
                .medium: "🥡 Moderately important (can reduce)",
                .low: "🍳 Not important (willing to cut)"
            ]
        )
    }
    
    private var questionEntertainment: some View {
        importanceQuestion(
            title: "How important is entertainment (movies, streaming, etc.)?",
            binding: $response.entertainmentImportance,
            labels: [
                .high: "🎬 Very important",
                .medium: "📺 Moderately important",
                .low: "📖 Not important"
            ]
        )
    }
    
    private var questionShopping: some View {
        importanceQuestion(
            title: "How important is shopping (clothes, gadgets, etc.)?",
            binding: $response.shoppingImportance,
            labels: [
                .high: "🛍️ Very important",
                .medium: "👕 Moderately important",
                .low: "♻️ Not important"
            ]
        )
    }
    
    private var questionPace: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How aggressive should your savings plan be?")
                .font(.title2.bold())
            ForEach(SavingsPace.allCases, id: \.self) { pace in
                Button(action: { response.savingsPace = pace }) {
                    HStack {
                        Image(systemName: response.savingsPace == pace ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(response.savingsPace == pace ? .accentColor : .secondary)
                        Text(pace.rawValue.capitalized)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(response.savingsPace == pace ? Color.appAccent.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func importanceQuestion(title: String, binding: Binding<ImportanceLevel>, labels: [ImportanceLevel: String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())
            
            ForEach(ImportanceLevel.allCases, id: \.self) { level in
                Button(action: { binding.wrappedValue = level }) {
                    HStack {
                        Image(systemName: binding.wrappedValue == level ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(binding.wrappedValue == level ? .accentColor : .secondary)
                        Text(labels[level] ?? level.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(binding.wrappedValue == level ? Color.appAccent.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Logo
    private var logoHeader: some View {
        HStack {
            Image("image", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4, y: 2)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
