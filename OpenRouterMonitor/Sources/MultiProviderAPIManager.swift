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
        case .anthropic:
            fetchAnthropicUsage(apiKey: apiKey, completion: completion)
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
        // Extract actual data from OpenRouter response
        let limit = response.data?.limit ?? 0.0
        let usage = response.data?.usage ?? 0.0
        let remaining = max(0, limit - usage)
        
        // For now, we can't get daily breakdown from this endpoint
        // Would need to call /api/v1/generation endpoint for detailed usage
        return UsageData(
            provider: .openrouter,
            tokensToday: 0, // TODO: Need different endpoint
            tokensThisMonth: Int(usage * 1000), // Rough estimate
            costThisMonth: usage,
            remainingCredits: remaining,
            modelBreakdown: []
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

struct OpenRouterKeyResponse: Codable {
    let data: OpenRouterKeyData?
}

struct OpenRouterKeyData: Codable {
    let label: String?
    let usage: Double? // Total usage in dollars
    let limit: Double? // Credit limit
    let isFreeTier: Bool?
    let rateLimit: OpenRouterRateLimit?
    
    enum CodingKeys: String, CodingKey {
        case label
        case usage
        case limit
        case isFreeTier = "is_free_tier"
        case rateLimit = "rate_limit"
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
