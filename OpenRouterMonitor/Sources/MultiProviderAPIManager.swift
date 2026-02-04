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
        return KeychainHelper.load(service: keychainService, account: provider.rawValue)
    }
    
    func setAPIKey(_ key: String?, for provider: APIProvider) {
        if let key = key, !key.isEmpty {
            KeychainHelper.save(service: keychainService, account: provider.rawValue, data: key)
        } else {
            KeychainHelper.delete(service: keychainService, account: provider.rawValue)
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let _ = data else {
                completion(.failure(NSError(domain: "OpenRouter", code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            // TODO: Parse actual OpenRouter response
            // For now, return mock data
            let usage = UsageData(
                provider: .openrouter,
                tokensToday: 0,
                tokensThisMonth: 0,
                costThisMonth: 0.0,
                remainingCredits: 0.0,
                modelBreakdown: []
            )
            completion(.success(usage))
        }.resume()
    }
    
    private func fetchOpenAIUsage(apiKey: String, completion: @escaping (Result<UsageData, Error>) -> Void) {
        // OpenAI doesn't provide a direct usage API
        // Would need to track via organization billing or usage endpoints
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
        // Anthropic API usage tracking
        // TODO: Implement actual API call
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
        // Google AI API usage tracking
        // TODO: Implement actual API call
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
