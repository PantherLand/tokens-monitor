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
        case .anthropic:
            fetchAnthropicUsage(apiKey: apiKey, completion: completion)
        case .google:
            fetchGoogleUsage(apiKey: apiKey, completion: completion)
        }
    }
    
    // MARK: - Provider-Specific Implementations
    
    private func fetchOpenRouterUsage(apiKey: String, completion: @escaping (Result<UsageData, Error>) -> Void) {
        // Fetch both endpoints for complete data
        let group = DispatchGroup()
        var usageResponse: OpenRouterUsageResponse?
        var keyResponse: OpenRouterKeyResponse?
        var lastError: Error?
        
        // Fetch usage details
        group.enter()
        fetchOpenRouterUsageEndpoint(apiKey: apiKey) { result in
            switch result {
            case .success(let response):
                usageResponse = response
            case .failure(let error):
                lastError = error
            }
            group.leave()
        }
        
        // Fetch key info (credits)
        group.enter()
        fetchOpenRouterKeyEndpoint(apiKey: apiKey) { result in
            switch result {
            case .success(let response):
                keyResponse = response
            case .failure(let error):
                lastError = error
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let usage = usageResponse, let key = keyResponse {
                let combined = self.combineOpenRouterData(usage: usage, key: key)
                completion(.success(combined))
            } else if let usage = usageResponse {
                let data = self.convertOpenRouterUsageResponse(usage, credits: 0.0)
                completion(.success(data))
            } else if let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(UsageData(provider: .openrouter)))
            }
        }
    }
    
    private func fetchOpenRouterUsageEndpoint(apiKey: String, completion: @escaping (Result<OpenRouterUsageResponse, Error>) -> Void) {
        let url = URL(string: "\(APIProvider.openrouter.baseURL)/usage")!
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
                let response = try JSONDecoder().decode(OpenRouterUsageResponse.self, from: data)
                print("[OpenRouter /usage] Success")
                completion(.success(response))
            } catch {
                print("[OpenRouter /usage] Parse error: \(error)")
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("[OpenRouter /usage] Response: \(json)")
                }
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func fetchOpenRouterKeyEndpoint(apiKey: String, completion: @escaping (Result<OpenRouterKeyResponse, Error>) -> Void) {
        let url = URL(string: "\(APIProvider.openrouter.baseURL)/auth/key")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        print("[OpenRouter] Fetching key info...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[OpenRouter /key] Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenRouter", code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(OpenRouterKeyResponse.self, from: data)
                print("[OpenRouter /key] Success")
                completion(.success(response))
            } catch {
                print("[OpenRouter /key] Parse error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func combineOpenRouterData(usage: OpenRouterUsageResponse, key: OpenRouterKeyResponse) -> UsageData {
        let totalCost = usage.data?.totalCost ?? 0.0
        let limit = key.data?.limit ?? 0.0
        let remaining = max(0, limit - totalCost)
        
        let estimatedTokens = Int(totalCost * 100_000)
        
        let modelBreakdown = (usage.data?.usage ?? []).map { item in
            ModelUsage(
                model: item.model ?? "unknown",
                tokens: item.tokens ?? (item.requests ?? 0) * 1000,
                cost: item.cost ?? 0.0
            )
        }
        
        return UsageData(
            provider: .openrouter,
            tokensToday: estimatedTokens,
            tokensThisMonth: estimatedTokens,
            costThisMonth: totalCost,
            remainingCredits: remaining,
            modelBreakdown: modelBreakdown
        )
    }
    
    private func convertOpenRouterUsageResponse(_ response: OpenRouterUsageResponse, credits: Double) -> UsageData {
        let totalCost = response.data?.totalCost ?? 0.0
        let estimatedTokens = Int(totalCost * 100_000)
        
        let modelBreakdown = (response.data?.usage ?? []).map { item in
            ModelUsage(
                model: item.model ?? "unknown",
                tokens: item.tokens ?? (item.requests ?? 0) * 1000,
                cost: item.cost ?? 0.0
            )
        }
        
        return UsageData(
            provider: .openrouter,
            tokensToday: estimatedTokens,
            tokensThisMonth: estimatedTokens,
            costThisMonth: totalCost,
            remainingCredits: credits,
            modelBreakdown: modelBreakdown
        )
    }
    
    private func fetchOpenAIUsage(apiKey: String, completion: @escaping (Result<UsageData, Error>) -> Void) {
        // OpenAI doesn't have a simple usage API
        // Would need: https://api.openai.com/v1/organization/usage
        print("[OpenAI] Usage API not implemented yet")
        let usage = UsageData(
            provider: .openai,
            tokensToday: 0,
            tokensThisMonth: 0,
            costThisMonth: 0.0,
            remainingCredits: 0.0,
            modelBreakdown: []
        )
        completion(.success(usage))
    }
    
    private func fetchAnthropicUsage(apiKey: String, completion: @escaping (Result<UsageData, Error>) -> Void) {
        // Anthropic doesn't have a usage API endpoint yet
        print("[Anthropic] Usage API not available")
        let usage = UsageData(
            provider: .anthropic,
            tokensToday: 0,
            tokensThisMonth: 0,
            costThisMonth: 0.0,
            remainingCredits: 0.0,
            modelBreakdown: []
        )
        completion(.success(usage))
    }
    
    private func fetchGoogleUsage(apiKey: String, completion: @escaping (Result<UsageData, Error>) -> Void) {
        // Google Gemini is currently free, no usage API
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

// MARK: - OpenRouter API Response Models

struct OpenRouterUsageResponse: Codable {
    let data: OpenRouterUsageData?
}

struct OpenRouterUsageData: Codable {
    let totalCost: Double?
    let usage: [OpenRouterModelUsage]?
    
    enum CodingKeys: String, CodingKey {
        case totalCost = "total_cost"
        case usage
    }
}

struct OpenRouterModelUsage: Codable {
    let model: String?
    let requests: Int?
    let cost: Double?
    let tokens: Int?
}

struct OpenRouterKeyResponse: Codable {
    let data: OpenRouterKeyData?
}

struct OpenRouterKeyData: Codable {
    let label: String?
    let usage: Double?
    let limit: Double?
    let isFreeTier: Bool?
    
    enum CodingKeys: String, CodingKey {
        case label
        case usage
        case limit
        case isFreeTier = "is_free_tier"
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    static func save(service: String, account: String, data: String) {
        let data = Data(data.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
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
