//
//  SettingsView.swift
//  OpenRouterMonitor
//
//  设置界面
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var refreshInterval: Double = 5.0
    @State private var showingSaveAlert = false
    
    private let apiManager = OpenRouterAPIManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("OpenRouter Monitor 设置")
                .font(.title)
                .padding(.bottom, 10)
            
            // API Key 输入
            VStack(alignment: .leading, spacing: 8) {
                Text("OpenRouter API Key")
                    .font(.headline)
                
                SecureField("sk-or-v1-...", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                
                Text("在 openrouter.ai/keys 获取你的 API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 刷新间隔
            VStack(alignment: .leading, spacing: 8) {
                Text("刷新间隔")
                    .font(.headline)
                
                HStack {
                    Slider(value: $refreshInterval, in: 1...30, step: 1)
                    Text("\(Int(refreshInterval)) 分钟")
                        .frame(width: 60, alignment: .trailing)
                }
            }
            
            Spacer()
            
            // 保存按钮
            HStack {
                Spacer()
                
                Button("取消") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("保存") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 400, height: 300)
        .onAppear {
            loadSettings()
        }
        .alert("设置已保存", isPresented: $showingSaveAlert) {
            Button("确定", role: .cancel) {
                NSApplication.shared.keyWindow?.close()
            }
        }
    }
    
    private func loadSettings() {
        if let savedKey = apiManager.apiKey {
            apiKey = savedKey
        }
        
        if let savedInterval = UserDefaults.standard.object(forKey: "refreshInterval") as? Double {
            refreshInterval = savedInterval
        }
    }
    
    private func saveSettings() {
        apiManager.apiKey = apiKey.isEmpty ? nil : apiKey
        UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        
        showingSaveAlert = true
        
        // 通知 AppDelegate 重新启动刷新定时器
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
}

#Preview {
    SettingsView()
}
