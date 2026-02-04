//
//  SettingsView.swift
//  OpenRouterMonitor
//
//  Multi-provider settings interface
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var apiManager = MultiProviderAPIManager()
    @State private var apiKeys: [APIProvider: String] = [:]
    @State private var refreshInterval: Double = 5.0
    @State private var showingSaveAlert = false
    @State private var selectedProvider: APIProvider = .openrouter
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Token Monitor Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // API Providers Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API Providers")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Configure API keys for the services you want to monitor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(APIProvider.allCases, id: \.self) { provider in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: getProviderIcon(provider))
                                        .foregroundColor(getProviderColor(provider))
                                    Text(provider.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                SecureField("API Key", text: binding(for: provider))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text(getProviderHint(provider))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Divider()
                    
                    // Refresh Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Refresh Interval")
                            .font(.headline)
                        
                        HStack {
                            Slider(value: $refreshInterval, in: 1...30, step: 1)
                            Text("\(Int(refreshInterval)) min")
                                .frame(width: 60, alignment: .trailing)
                                .font(.subheadline)
                        }
                        
                        Text("How often to update usage statistics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    closeWindow()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadSettings()
        }
        .alert("Settings Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {
                closeWindow()
            }
        } message: {
            Text("Your API keys and preferences have been saved securely.")
        }
    }
    
    // MARK: - Helpers
    
    private func binding(for provider: APIProvider) -> Binding<String> {
        return Binding(
            get: { apiKeys[provider] ?? "" },
            set: { apiKeys[provider] = $0 }
        )
    }
    
    private func getProviderIcon(_ provider: APIProvider) -> String {
        switch provider {
        case .openrouter: return "arrow.triangle.swap"
        case .openai: return "brain"
        case .anthropic: return "cpu"
        case .google: return "sparkles"
        }
    }
    
    private func getProviderColor(_ provider: APIProvider) -> Color {
        switch provider {
        case .openrouter: return .blue
        case .openai: return .green
        case .anthropic: return .orange
        case .google: return .red
        }
    }
    
    private func getProviderHint(_ provider: APIProvider) -> String {
        switch provider {
        case .openrouter:
            return "Get your key at openrouter.ai/keys (starts with sk-or-v1-...)"
        case .openai:
            return "Get your key at platform.openai.com/api-keys (starts with sk-...)"
        case .anthropic:
            return "Get your key at console.anthropic.com (starts with sk-ant-...)"
        case .google:
            return "Get your key at makersuite.google.com/app/apikey"
        }
    }
    
    private func loadSettings() {
        // Load API keys from Keychain
        for provider in APIProvider.allCases {
            if let key = apiManager.getAPIKey(for: provider) {
                apiKeys[provider] = key
            }
        }
        
        // Load refresh interval from UserDefaults
        if let savedInterval = UserDefaults.standard.object(forKey: "refreshInterval") as? Double {
            refreshInterval = savedInterval
        }
    }
    
    private func saveSettings() {
        // Save API keys to Keychain
        for provider in APIProvider.allCases {
            let key = apiKeys[provider]
            apiManager.setAPIKey(key, for: provider)
        }
        
        // Save refresh interval
        UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        
        // Notify app to refresh
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        
        showingSaveAlert = true
    }
    
    private func closeWindow() {
        if let window = NSApp.windows.first(where: { $0.title.contains("Settings") }) {
            window.close()
        }
    }
}

#Preview {
    SettingsView()
}
