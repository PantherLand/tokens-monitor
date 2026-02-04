//
//  OpenRouterAPIManager.swift
//  OpenRouterMonitor
//
//  API 管理器：负责与 OpenRouter API 通信
//

import Foundation

struct UsageData: Codable {
    let tokensToday: Int
    let tokensThisMonth: Int
    let costThisMonth: Double
    let remainingCredits: Double
    let modelBreakdown: [ModelUsage]
}

struct ModelUsage: Codable {
    let model: String
    let tokens: Int
    let cost: Double
}

class OpenRouterAPIManager {
    private let baseURL = "https://openrouter.ai/api/v1"
    private let keychainService = "ai.openrouter.monitor"
    
    var apiKey: String? {
        get {
            return KeychainHelper.load(service: keychainService, account: "apiKey")
        }
        set {
            if let key = newValue {
                KeychainHelper.save(service: keychainService, account: "apiKey", data: key)
            } else {
                KeychainHelper.delete(service: keychainService, account: "apiKey")
            }
        }
    }
    
    func fetchUsage(completion: @escaping (Result<UsageData, Error>) -> Void) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "OpenRouterMonitor", code: 401, userInfo: [NSLocalizedDescriptionKey: "未设置 API Key"])))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/auth/key") else {
            completion(.failure(NSError(domain: "OpenRouterMonitor", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的 URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "OpenRouterMonitor", code: 500, userInfo: [NSLocalizedDescriptionKey: "无效的响应"])))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "OpenRouterMonitor", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenRouterMonitor", code: 500, userInfo: [NSLocalizedDescriptionKey: "空响应"])))
                return
            }
            
            do {
                // 解析 OpenRouter API 响应
                let response = try JSONDecoder().decode(OpenRouterKeyResponse.self, from: data)
                let usage = self.convertToUsageData(response)
                completion(.success(usage))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func convertToUsageData(_ response: OpenRouterKeyResponse) -> UsageData {
        // 这里需要根据 OpenRouter 实际的 API 响应结构来转换
        // 以下是示例实现
        let tokensToday = response.data?.usage?.tokensToday ?? 0
        let tokensThisMonth = response.data?.usage?.tokensThisMonth ?? 0
        let costThisMonth = response.data?.usage?.costThisMonth ?? 0.0
        let remainingCredits = response.data?.limit ?? 0.0
        
        let modelBreakdown = response.data?.usage?.models?.map { model in
            ModelUsage(model: model.id, tokens: model.tokens, cost: model.cost)
        } ?? []
        
        return UsageData(
            tokensToday: tokensToday,
            tokensThisMonth: tokensThisMonth,
            costThisMonth: costThisMonth,
            remainingCredits: remainingCredits,
            modelBreakdown: modelBreakdown
        )
    }
}

// OpenRouter API 响应结构
struct OpenRouterKeyResponse: Codable {
    let data: KeyData?
}

struct KeyData: Codable {
    let limit: Double?
    let usage: Usage?
}

struct Usage: Codable {
    let tokensToday: Int?
    let tokensThisMonth: Int?
    let costThisMonth: Double?
    let models: [ModelInfo]?
}

struct ModelInfo: Codable {
    let id: String
    let tokens: Int
    let cost: Double
}

// Keychain 辅助类
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
