//
//  Models.swift
//  OpenRouterMonitor
//
//  Data models for API providers and usage tracking
//

import Foundation

// MARK: - API Provider Types

enum APIProvider: String, CaseIterable, Codable {
    case openrouter = "OpenRouter"
    case openai = "OpenAI"
    case google = "Google (Gemini)"
    
    var displayName: String {
        return self.rawValue
    }
    
    var baseURL: String {
        switch self {
        case .openrouter:
            return "https://openrouter.ai/api/v1"
        case .openai:
            return "https://api.openai.com/v1"
        case .google:
            return "https://generativelanguage.googleapis.com/v1"
        }
    }
}

// MARK: - Usage Data

struct UsageData: Codable {
    let provider: APIProvider
    let tokensToday: Int
    let tokensThisMonth: Int
    let costThisMonth: Double
    let remainingCredits: Double
    let modelBreakdown: [ModelUsage]
    let lastUpdated: Date
    
    init(provider: APIProvider = .openrouter,
         tokensToday: Int = 0,
         tokensThisMonth: Int = 0,
         costThisMonth: Double = 0.0,
         remainingCredits: Double = 0.0,
         modelBreakdown: [ModelUsage] = [],
         lastUpdated: Date = Date()) {
        self.provider = provider
        self.tokensToday = tokensToday
        self.tokensThisMonth = tokensThisMonth
        self.costThisMonth = costThisMonth
        self.remainingCredits = remainingCredits
        self.modelBreakdown = modelBreakdown
        self.lastUpdated = lastUpdated
    }
}

struct ModelUsage: Codable, Identifiable {
    let id: String
    let model: String
    let tokens: Int
    let cost: Double
    
    init(id: String? = nil, model: String, tokens: Int, cost: Double) {
        self.id = id ?? model
        self.model = model
        self.tokens = tokens
        self.cost = cost
    }
}

// MARK: - API Key Configuration

struct APIKeyConfig: Codable {
    let provider: APIProvider
    let apiKey: String
    let enabled: Bool
    
    init(provider: APIProvider, apiKey: String, enabled: Bool = true) {
        self.provider = provider
        self.apiKey = apiKey
        self.enabled = enabled
    }
}

// MARK: - Settings

struct AppSettings: Codable {
    var refreshInterval: Double // in minutes
    var enabledProviders: Set<APIProvider>
    var showNotifications: Bool
    var notificationThreshold: Double // percentage
    
    static let `default` = AppSettings(
        refreshInterval: 5.0,
        enabledProviders: [.openrouter],
        showNotifications: true,
        notificationThreshold: 80.0
    )
}
