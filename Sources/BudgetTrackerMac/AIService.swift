import Foundation

enum AIError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError
}

struct AISuggestion: Codable {
    let savingsAmount: Double
    let spendingAmount: Double
    let explanation: String
    let categories: [String: Double]
}

class AIService {
    static let shared = AIService()
    
    // In a real app, these would be in a secure location or provided by the user
    private var deepseekApiKey: String? { UserDefaults.standard.string(forKey: "deepseek_api_key") }
    private var groqApiKey: String? { UserDefaults.standard.string(forKey: "groq_api_key") }
    
    private let deepseekUrl = "https://api.deepseek.com/v1/chat/completions"
    private let groqUrl = "https://api.groq.com/openai/v1/chat/completions"
    
    func generateBudgetSuggestions(
        income: Double, 
        goal: Double, 
        months: Int,
        familySize: Int = 1,
        isSpouseWorking: Bool = false,
        spouseIncome: Double = 0,
        childAges: [Int] = [],
        tier: AITier = .free
    ) async throws -> AISuggestion {
        let childInfo = childAges.isEmpty ? "None" : childAges.map { "\($0)" }.joined(separator: ", ")
        let prompt = """
        You are a world-class financial advisor. Generate a precise monthly budget for a household with:
        - Total Monthly Income: $\(Int(income + (isSpouseWorking ? spouseIncome : 0)))
        - Primary Income: $\(Int(income))
        - Spouse Income: $\(Int(isSpouseWorking ? spouseIncome : 0))
        - Family Size: \(familySize)
        - Child Ages: \(childInfo)
        - Savings Goal: $\(Int(goal))
        - Timeline: \(months) months
        
        CRITICAL: Provide exact dollar amounts for every category. The sum of savingsAmount and spendingAmount MUST equal exactly \(Int(income + (isSpouseWorking ? spouseIncome : 0))).
        Adjust category allocations (especially Housing, Groceries, and Utilities) based on the family size and presence of children.
        
        Provide the response in JSON format:
        {
          "savingsAmount": number,
          "spendingAmount": number,
          "explanation": "Brief explanation of the strategy considering family needs",
          "categories": {
            "Housing": number,
            "Groceries": number,
            "Utilities": number,
            "Transport": number,
            "Healthcare": number,
            "Education/Childcare": number,
            "Discretionary": number
          }
        }
        """
        
        if tier == .premium {
            // Premium tier logic - could use GPT-4 or more advanced models
            // For now, let's assume it still uses Deepseek but maybe a more capable model or different prompt
            if let apiKey = deepseekApiKey {
                return try await callOpenAICompatible(url: deepseekUrl, apiKey: apiKey, prompt: "PREMIUM ADVISOR: " + prompt)
            }
        }
        
        // Free Tier: Try Deepseek first
        if let apiKey = deepseekApiKey {
            do {
                return try await callOpenAICompatible(url: deepseekUrl, apiKey: apiKey, prompt: prompt)
            } catch {
                print("Deepseek failed: \(error). Trying Groq fallback...")
            }
        }
        
        // Free Tier: Fallback to Groq
        if let apiKey = groqApiKey {
            return try await callOpenAICompatible(url: groqUrl, apiKey: apiKey, prompt: prompt)
        }
        
        // If no API keys, return a default heuristic-based suggestion
        return generateHeuristicSuggestion(income: income, goal: goal, months: months)
    }
    
    private func callOpenAICompatible(url: String, apiKey: String, prompt: String) async throws -> AISuggestion {
        guard let urlObj = URL(string: url) else { throw AIError.invalidURL }
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": url.contains("deepseek") ? "deepseek-chat" : "mixtral-8x7b-32768",
            "messages": [
                ["role": "system", "content": "You are a financial advisor budget generator. Always respond in valid JSON."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.apiError(errorMsg)
        }
        
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = json.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw AIError.decodingError
        }
        
        return try JSONDecoder().decode(AISuggestion.self, from: contentData)
    }
    
    private func generateHeuristicSuggestion(income: Double, goal: Double, months: Int) -> AISuggestion {
        let savingsNeeded = months > 0 ? goal / Double(months) : 0
        let savings = min(income * 0.4, savingsNeeded)
        let spending = income - savings
        
        return AISuggestion(
            savingsAmount: savings,
            spendingAmount: spending,
            explanation: "Based on your income and goal, we suggest saving $\(Int(savings)) monthly. (Note: Add API keys in Settings for AI-powered suggestions)",
            categories: [
                "Housing": spending * 0.35,
                "Groceries": spending * 0.15,
                "Utilities": spending * 0.10,
                "Transport": spending * 0.10,
                "Discretionary": spending * 0.30
            ]
        )
    }
}

private struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
