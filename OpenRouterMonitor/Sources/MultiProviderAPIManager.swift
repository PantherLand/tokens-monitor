//
//  MultiProviderAPIManager.swift
//  OpenRouterMonitor
//
//  Unified API manager supporting multiple providers
//

import Foundation
import Combine

class MultiProviderAPIManager: ObservableObject {
    @Published var usageData: [APIProvider: UsageData] = [:]
    @Published var isLoading: Bool = false
    @Published var lastError: Error?
    
    private let keychainService = "ai.tokens.monitor"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - API Key Management
    
    func getAPIKey(for provider: APIProvider) -> String? {
        // Use UserDefaults instead of Keychain to avoid repeated password prompts
        return UserDefaults.standard.string(forKey: "apiKey_\(provider.rawValue)")
    }
    
    func setAPIKey(_ key: String?, for provider: APIProvider) {
        if let key = key, !key.isEmpty {
            UserDefaults.standard.set(key, forKey: "apiKey_\(provider.rawValue)")
        } else {
            UserDefaults.standard.removeObject(forKey: "apiKey_\(provider.rawValue)")
        }
    }
    
    func getAllConfiguredProviders() -> [APIProvider] {
        return APIProvider.allCases.filter { getAPIKey(for: $0) != nil }
    }
    
    // MARK: - Fetch Usage
    
    func fetchAllUsage(completion: @escaping (Result<[APIProvider: UsageData], Error>) -> Void) {
        let providers = getAllConfiguredProviders()
        guard !providers.isEmpty else {
            completion(.failure(NSError(domain: "MultiProviderAPIManager", code: 401, 
                userInfo: [NSLocalizedDescriptionKey: "No API keys configured"])))
            return
        }
        
        isLoading = true
        var results: [APIProvider: UsageData] = [:]
        let group = DispatchGroup()
        var lastError: Error?
        
        for provider in providers {
            group.enter()
            fetchUsage(for: provider) { result in
                switch result {
                case .success(let usage):
                    results[provider] = usage
                case .failure(let error):
                    lastError = error
                    print("[\(provider.rawValue)] Error: \(error.localizedDescription)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            if results.isEmpty, let error = lastError {
                completion(.failure(error))
            } else {
                self?.usageData = results
                completion(.success(results))
            }
        }
    }
    
    func fetchUsage(for provider: APIProvider, completion: @escaping (Result<UsageData, Error>) -> Void) {
        guard let apiKey = getAPIKey(for: provider) else {
            completion(.failure(NSError(domain: "MultiProviderAPIManager", code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No API key for \(provider.rawValue)"])))
            return
        }
        
        switch provider {
        case .openrouter:
            fetchOpenRouterUsage(apiKey: apiKey, completion: completion)
        case .openai:
            fetchOpenAIUsage(apiKey: apiKey, completion: completion)
        case .google:
            fetchGoogleUsage(apiKey: apiKey, completion: completion)
        }
    }
    
    // MARK: - Provider-Specific Implementations
    
    private func fetchOpenRouterUsage(apiKey: String, completion: @escaping (Result<UsageData, Error>) -> Void) {
        let url = URL(string: "\(APIProvider.openrouter.baseURL)/auth/key")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        print("[OpenRouter] Fetching usage data...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[OpenRouter] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[OpenRouter] Invalid response")
                completion(.failure(NSError(domain: "OpenRouter", code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            print("[OpenRouter] HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMsg = httpResponse.statusCode == 401 ? "Invalid API key" : "HTTP \(httpResponse.statusCode)"
                print("[OpenRouter] Error: \(errorMsg)")
                completion(.failure(NSError(domain: "OpenRouter", code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            
            guard let data = data else {
                print("[OpenRouter] No data received")
                completion(.failure(NSError(domain: "OpenRouter", code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[OpenRouter] Response: \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(OpenRouterKeyResponse.self, from: data)
                let usage = self.convertOpenRouterResponse(response)
                print("[OpenRouter] Success: \(usage.tokensToday) tokens today")
                completion(.success(usage))
            } catch {
                print("[OpenRouter] Parse error: \(error)")
                // Return empty data instead of failing
                let emptyUsage = UsageData(
                    provider: .openrouter,
                    tokensToday: 0,
                    tokensThisMonth: 0,
                    costThisMonth: 0.0,
                    remainingCredits: 0.0,
                    modelBreakdown: []
                )
                completion(.success(emptyUsage))
            }
        }.resume()
    }
    
    private func convertOpenRouterResponse(_ response: OpenRouterKeyResponse) -> UsageData {
        let limit = response.data?.limit
        let usageDaily = response.data?.usageDaily ?? 0.0
        let usageMonthly = response.data?.usageMonthly ?? 0.0
        
        // Calculate remaining credits (if limit exists)
        let remaining: Double
        if let limit = limit {
            remaining = max(0, limit - usageMonthly)
        } else {
            remaining = 0.0
        }
        
        // Estimate tokens from cost ($0.01 per ~1000 tokens average)
        let tokensDaily = Int(usageDaily * 100_000)
        let tokensMonthly = Int(usageMonthly * 100_000)
        
        return UsageData(
            provider: .openrouter,
            tokensToday: tokensDaily,
            tokensThisMonth: tokensMonthly,
            costThisMonth: usageMonthly,
            remainingCredits: remaining,
            modelBreakdown: []
        )
    }
    
    private func fetchOpenAIUsage(apiKey: String, completion: @escaping (Result<UsageData, Error>) -> Void) {
        // Best-effort implementation using OpenAI billing endpoints.
        // Note: this returns cost (USD). We estimate tokens from cost for a consistent UI.
        // Endpoints (legacy but widely used):
        // - /v1/dashboard/billing/usage?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
        // - /v1/dashboard/billing/credit_grants
        print("[OpenAI] Fetching billing usage...")

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // Start of month
        let comps = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: comps) ?? startOfToday

        // Billing API uses inclusive dates; using end_date = tomorrow keeps 'today' included.
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        let df = DateFormatter()
        df.calendar = calendar
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        let todayStart = df.string(from: startOfToday)
        let tomorrowStr = df.string(from: tomorrow)
        let monthStart = df.string(from: startOfMonth)

        let group = DispatchGroup()
        var todayCostUSD: Double = 0.0
        var monthCostUSD: Double = 0.0
        var remainingUSD: Double = 0.0
        var lastErr: Error?

        group.enter()
        fetchOpenAIBillingUsage(apiKey: apiKey, startDate: todayStart, endDate: tomorrowStr) { result in
            switch result {
            case .success(let cost):
                todayCostUSD = cost
            case .failure(let err):
                lastErr = err
            }
            group.leave()
        }

        group.enter()
        fetchOpenAIBillingUsage(apiKey: apiKey, startDate: monthStart, endDate: tomorrowStr) { result in
            switch result {
            case .success(let cost):
                monthCostUSD = cost
            case .failure(let err):
                lastErr = err
            }
            group.leave()
        }

        group.enter()
        fetchOpenAICreditGrants(apiKey: apiKey) { result in
            switch result {
            case .success(let remaining):
                remainingUSD = remaining
            case .failure(let err):
                // Credits endpoint may be disabled for some accounts; don't fail overall.
                print("[OpenAI] Credit grants unavailable: \(err.localizedDescription)")
            }
            group.leave()
        }

        group.notify(queue: .global()) {
            // Estimate tokens from cost ($0.01 per ~1K tokens average => $1 per ~100K tokens)
            let estTokensToday = Int(todayCostUSD * 100_000)
            let estTokensMonth = Int(monthCostUSD * 100_000)

            let usage = UsageData(
                provider: .openai,
                tokensToday: estTokensToday,
                tokensThisMonth: estTokensMonth,
                costThisMonth: monthCostUSD,
                remainingCredits: remainingUSD,
                modelBreakdown: []
            )

            if let lastErr = lastErr {
                print("[OpenAI] Partial error: \(lastErr.localizedDescription)")
            }
            completion(.success(usage))
        }
    }

    private func fetchOpenAIBillingUsage(apiKey: String, startDate: String, endDate: String, completion: @escaping (Result<Double, Error>) -> Void) {
        var comps = URLComponents(string: "https://api.openai.com/v1/dashboard/billing/usage")
        comps?.queryItems = [
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate)
        ]
        guard let url = comps?.url else {
            completion(.failure(NSError(domain: "OpenAI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid billing usage URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "OpenAI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            guard http.statusCode == 200 else {
                let msg = http.statusCode == 401 ? "Invalid API key" : "HTTP \(http.statusCode)"
                completion(.failure(NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAI", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(OpenAIBillingUsageResponse.self, from: data)
                // total_usage is in cents
                completion(.success((decoded.totalUsage ?? 0.0) / 100.0))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func fetchOpenAICreditGrants(apiKey: String, completion: @escaping (Result<Double, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/dashboard/billing/credit_grants")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "OpenAI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            guard http.statusCode == 200 else {
                let msg = http.statusCode == 401 ? "Invalid API key" : "HTTP \(http.statusCode)"
                completion(.failure(NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAI", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(OpenAICreditGrantsResponse.self, from: data)
                completion(.success(decoded.totalAvailable ?? 0.0))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func fetchGoogleUsage(apiKey: String, completion: @escaping (Result<UsageData, Error>) -> Void) {
        // Google Gemini is currently free (for many users/tiers), and there's no simple public usage API here.
        print("[Google] Free tier - no usage tracking")
        let usage = UsageData(
            provider: .google,
            tokensToday: 0,
            tokensThisMonth: 0,
            costThisMonth: 0.0,
            remainingCredits: 0.0,
            modelBreakdown: []
        )
        completion(.success(usage))
    }
}

// MARK: - OpenAI Billing Response Models

private struct OpenAIBillingUsageResponse: Codable {
    let totalUsage: Double?

    enum CodingKeys: String, CodingKey {
        case totalUsage = "total_usage"
    }
}

private struct OpenAICreditGrantsResponse: Codable {
    let totalAvailable: Double?

    enum CodingKeys: String, CodingKey {
        case totalAvailable = "total_available"
    }
}

// MARK: - OpenRouter API Response Models

struct OpenRouterKeyResponse: Codable {
    let data: OpenRouterKeyData?
}

struct OpenRouterKeyData: Codable {
    let label: String?
    let limit: Double?
    let limitRemaining: Double?
    let usage: Double?
    let usageDaily: Double?
    let usageWeekly: Double?
    let usageMonthly: Double?
    let byokUsage: Double?
    let byokUsageDaily: Double?
    let byokUsageWeekly: Double?
    let byokUsageMonthly: Double?
    let isFreeTier: Bool?
    let isProvisioningKey: Bool?
    let expiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case label
        case limit
        case limitRemaining = "limit_remaining"
        case usage
        case usageDaily = "usage_daily"
        case usageWeekly = "usage_weekly"
        case usageMonthly = "usage_monthly"
        case byokUsage = "byok_usage"
        case byokUsageDaily = "byok_usage_daily"
        case byokUsageWeekly = "byok_usage_weekly"
        case byokUsageMonthly = "byok_usage_monthly"
        case isFreeTier = "is_free_tier"
        case isProvisioningKey = "is_provisioning_key"
        case expiresAt = "expires_at"
    }
}

struct OpenRouterRateLimit: Codable {
    let requests: Int?
    let interval: String?
}

// MARK: - Keychain Helper

class KeychainHelper {
    static func save(service: String, account: String, data: String) {
        let data = Data(data.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
