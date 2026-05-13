import Foundation

// MARK: - Questionnaire Models

enum FinancialGoal: String, CaseIterable, Codable {
    case car = "car"
    case house = "house"
    case emergency = "emergency"
    case debtPayoff = "debt_payoff"
    case retirement = "retirement"
    case vacation = "vacation"
    case other = "other"
    
    var label: String {
        switch self {
        case .car: return "💵 Save for a car"
        case .house: return "🏠 Save for a house down payment"
        case .emergency: return "🚨 Build emergency fund"
        case .debtPayoff: return "💳 Pay off debt"
        case .retirement: return "🏖️ Invest for retirement"
        case .vacation: return "✈️ Save for vacation/travel"
        case .other: return "📌 Other"
        }
    }
}

enum ImportanceLevel: String, CaseIterable, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var multiplier: Double {
        switch self {
        case .high: return 0.9
        case .medium: return 0.7
        case .low: return 0.4
        }
    }
}

enum SavingsPace: String, CaseIterable, Codable {
    case conservative = "conservative"
    case moderate = "moderate"
    case aggressive = "aggressive"
    
    var label: String {
        switch self {
        case .conservative: return "🐢 Comfortable pace (minimal lifestyle changes)"
        case .moderate: return "🚶 Moderate pace (some lifestyle changes)"
        case .aggressive: return "🏃 As fast as possible (major changes)"
        }
    }
    
    var factor: Double {
        switch self {
        case .conservative: return 0.7
        case .moderate: return 1.0
        case .aggressive: return 1.5
        }
    }
}

// MARK: - Questionnaire Response

struct QuestionnaireResponse: Codable {
    var primaryGoal: FinancialGoal = .car
    var goalAmount: Double = 10000
    var goalTimeline: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var monthlyIncome: Double = 4500
    var currentSavings: Double = 0
    var monthlyDebtPayments: Double = 0
    var diningImportance: ImportanceLevel = .medium
    var entertainmentImportance: ImportanceLevel = .medium
    var shoppingImportance: ImportanceLevel = .medium
    var savingsPace: SavingsPace = .moderate
    
    // Family Budgeting
    var familySize: Int = 1
    var isSpouseWorking: Bool = false
    var spouseIncome: Double = 0
    var childAges: [Int] = []
    var convergenceMode: BudgetConvergenceMode = .converged
    
    var totalHouseholdIncome: Double {
        monthlyIncome + (isSpouseWorking ? spouseIncome : 0)
    }
    
    var timelineMonths: Int {
        let months = Calendar.current.dateComponents([.month], from: Date(), to: goalTimeline).month ?? 12
        return max(1, months)
    }
}

// MARK: - Budget Plan

struct BudgetPlan: Identifiable {
    let id = UUID()
    let name: String
    let scenarioType: String
    let monthlySavings: Double
    let timelineMonths: Int
    let categories: [String: Double]
    let totalAllocated: Double
    let remaining: Double
    let lifestyleImpact: String
    let successProbability: Double
    
    var lifestyleImpactShort: String {
        lifestyleImpact.components(separatedBy: " - ").first ?? lifestyleImpact
    }
}

// MARK: - Budget Generator

class BudgetGenerator {
    let response: QuestionnaireResponse
    
    init(response: QuestionnaireResponse) {
        self.response = response
    }
    
    func generateAllScenarios() -> [String: BudgetPlan] {
        return [
            "conservative": generateScenario(.conservative),
            "moderate": generateScenario(.moderate),
            "aggressive": generateScenario(.aggressive)
        ]
    }
    
    func generateScenario(_ pace: SavingsPace) -> BudgetPlan {
        let months = Double(max(1, response.timelineMonths))
        let requiredSavings = response.goalAmount / months
        var monthlySavings = requiredSavings * pace.factor
        
        let fixedCosts = estimateFixedCosts()
        let fixedTotal = fixedCosts.values.reduce(0, +)
        var discretionary = response.monthlyIncome - monthlySavings - fixedTotal
        
        var adjustedTimeline = response.timelineMonths
        
        if discretionary < 0 {
            // If we can't afford the savings, limit savings to 50% of available income after fixed costs
            monthlySavings = max(0, (response.monthlyIncome - fixedTotal) * 0.5)
            discretionary = response.monthlyIncome - monthlySavings - fixedTotal
            
            if monthlySavings > 1 {
                let monthsNeeded = response.goalAmount / monthlySavings
                adjustedTimeline = Int(min(999, ceil(monthsNeeded)))
            } else {
                adjustedTimeline = 999
            }
        } else if monthlySavings > 1 {
            let monthsNeeded = response.goalAmount / monthlySavings
            adjustedTimeline = Int(min(999, ceil(monthsNeeded)))
        }
        
        let discretionaryAllocations = allocateDiscretionary(max(0, discretionary), pace: pace)
        var allCategories = fixedCosts
        for (key, value) in discretionaryAllocations {
            allCategories[key] = value
        }
        
        let totalAllocated = allCategories.values.reduce(0, +)
        
        return BudgetPlan(
            name: "\(pace.rawValue.capitalized) Plan",
            scenarioType: pace.rawValue,
            monthlySavings: monthlySavings,
            timelineMonths: adjustedTimeline,
            categories: allCategories,
            totalAllocated: totalAllocated,
            remaining: response.monthlyIncome - monthlySavings - totalAllocated,
            lifestyleImpact: getLifestyleImpact(pace),
            successProbability: getSuccessProbability(pace)
        )
    }
    
    func generateCustomScenario(sliderPosition: Double) -> BudgetPlan {
        let t = sliderPosition
        
        if t <= 0.5 {
            let localT = t * 2
            let conservative = generateScenario(.conservative)
            let moderate = generateScenario(.moderate)
            return interpolateScenarios(conservative, moderate, t: localT)
        } else {
            let localT = (t - 0.5) * 2
            let moderate = generateScenario(.moderate)
            let aggressive = generateScenario(.aggressive)
            return interpolateScenarios(moderate, aggressive, t: localT)
        }
    }
    
    private func interpolateScenarios(_ a: BudgetPlan, _ b: BudgetPlan, t: Double) -> BudgetPlan {
        let monthlySavings = a.monthlySavings * (1 - t) + b.monthlySavings * t
        
        let timeline: Int
        if monthlySavings > 1 {
            let monthsNeeded = response.goalAmount / monthlySavings
            timeline = Int(min(999, ceil(monthsNeeded)))
        } else {
            timeline = 999
        }
        
        var categories: [String: Double] = [:]
        for key in a.categories.keys {
            let valA = a.categories[key] ?? 0
            let valB = b.categories[key] ?? 0
            categories[key] = valA * (1 - t) + valB * t
        }
        
        let impacts = [
            "MINIMAL - Small adjustments, maintain current lifestyle",
            "MODERATE - Noticeable changes, some sacrifices required",
            "SIGNIFICANT - Major lifestyle changes, strict discipline needed"
        ]
        let impactIndex = min(2, Int(t * 2))
        
        let totalAllocated = categories.values.reduce(0, +)
        
        return BudgetPlan(
            name: "Custom Plan",
            scenarioType: "custom",
            monthlySavings: monthlySavings,
            timelineMonths: timeline,
            categories: categories,
            totalAllocated: totalAllocated,
            remaining: response.monthlyIncome - monthlySavings - totalAllocated,
            lifestyleImpact: impacts[impactIndex],
            successProbability: max(0, min(1, 0.85 - (t * 0.4)))
        )
    }
    
    private func estimateFixedCosts() -> [String: Double] {
        let housing = response.monthlyIncome * 0.275
        
        let utilities: Double
        if response.monthlyIncome < 3000 {
            utilities = 100
        } else if response.monthlyIncome < 5000 {
            utilities = 150
        } else {
            utilities = 200
        }
        
        let transportation = max(200, response.monthlyIncome * 0.08)
        let healthcare: Double = 100
        
        return [
            "Housing": housing,
            "Utilities": utilities,
            "Transportation": transportation,
            "Healthcare": healthcare,
            "Debt Payments": response.monthlyDebtPayments
        ]
    }
    
    private func allocateDiscretionary(_ amount: Double, pace: SavingsPace) -> [String: Double] {
        guard amount > 0 else {
            return [
                "Groceries": 0,
                "Dining Out": 0,
                "Entertainment": 0,
                "Shopping": 0,
                "Subscriptions": 0,
                "Miscellaneous": 0
            ]
        }
        
        let baseAllocations: [String: Double] = [
            "Groceries": 0.35,
            "Dining Out": 0.15,
            "Entertainment": 0.10,
            "Shopping": 0.15,
            "Subscriptions": 0.05,
            "Miscellaneous": 0.20
        ]
        
        let scenarioAdjustment: Double
        switch pace {
        case .conservative: scenarioAdjustment = 1.2
        case .moderate: scenarioAdjustment = 1.0
        case .aggressive: scenarioAdjustment = 0.6
        }
        
        var allocations: [String: Double] = [:]
        
        for (category, basePct) in baseAllocations {
            let importance = getImportanceFor(category)
            let importanceMult = importance.multiplier
            
            let finalPct: Double
            if category == "Groceries" {
                finalPct = basePct
            } else {
                finalPct = basePct * scenarioAdjustment * (importanceMult / 0.7)
            }
            
            allocations[category] = amount * finalPct
        }
        
        let total = allocations.values.reduce(0, +)
        if total > 0 {
            let scale = amount / total
            for key in allocations.keys {
                allocations[key] = (allocations[key] ?? 0) * scale
            }
        }
        
        return allocations
    }
    
    private func getImportanceFor(_ category: String) -> ImportanceLevel {
        switch category {
        case "Dining Out": return response.diningImportance
        case "Entertainment": return response.entertainmentImportance
        case "Shopping": return response.shoppingImportance
        default: return .medium
        }
    }
    
    private func getLifestyleImpact(_ pace: SavingsPace) -> String {
        switch pace {
        case .conservative: return "MINIMAL - Small adjustments, maintain current lifestyle"
        case .moderate: return "MODERATE - Noticeable changes, some sacrifices required"
        case .aggressive: return "SIGNIFICANT - Major lifestyle changes, strict discipline needed"
        }
    }
    
    private func getSuccessProbability(_ pace: SavingsPace) -> Double {
        switch pace {
        case .conservative: return 0.85
        case .moderate: return 0.70
        case .aggressive: return 0.45
        }
    }
}
