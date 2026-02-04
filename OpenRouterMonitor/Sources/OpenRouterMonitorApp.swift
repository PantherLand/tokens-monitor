//
//  OpenRouterMonitorApp.swift
//  OpenRouterMonitor
//
//  Created on 2026-02-04
//

import SwiftUI

@main
struct OpenRouterMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var apiManager: OpenRouterAPIManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "OpenRouter Monitor")
            button.action = #selector(togglePopover)
        }
        
        // 初始化 API Manager
        apiManager = OpenRouterAPIManager()
        
        // 构建菜单
        constructMenu()
        
        // 开始定时刷新
        startPeriodicRefresh()
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = popover, popover.isShown {
                popover.performClose(nil)
            } else {
                showMenu()
            }
        }
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        // Token 使用量显示
        menu.addItem(NSMenuItem(title: "正在加载...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // 立即刷新
        menu.addItem(NSMenuItem(title: "立即刷新", action: #selector(refreshNow), keyEquivalent: "r"))
        
        // 设置
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func showMenu() {
        statusItem?.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: statusItem?.button)
    }
    
    @objc func refreshNow() {
        updateUsageDisplay()
    }
    
    @objc func openSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.center()
        settingsWindow.title = "OpenRouter Monitor 设置"
        settingsWindow.contentView = NSHostingView(rootView: SettingsView())
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func startPeriodicRefresh() {
        // 每5分钟刷新一次
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.updateUsageDisplay()
        }
        
        // 立即刷新一次
        updateUsageDisplay()
    }
    
    func updateUsageDisplay() {
        apiManager?.fetchUsage { result in
            DispatchQueue.main.async {
                self.updateMenuWithUsage(result)
            }
        }
    }
    
    func updateMenuWithUsage(_ result: Result<UsageData, Error>) {
        guard let menu = statusItem?.menu else { return }
        
        // 移除旧的使用量显示项
        while menu.items.count > 0 && menu.items[0].action == nil {
            menu.removeItem(at: 0)
        }
        
        switch result {
        case .success(let usage):
            menu.insertItem(NSMenuItem(title: "今日使用: \(usage.tokensToday.formatted()) tokens", action: nil, keyEquivalent: ""), at: 0)
            menu.insertItem(NSMenuItem(title: "本月费用: $\(String(format: "%.2f", usage.costThisMonth))", action: nil, keyEquivalent: ""), at: 1)
            menu.insertItem(NSMenuItem(title: "剩余额度: $\(String(format: "%.2f", usage.remainingCredits))", action: nil, keyEquivalent: ""), at: 2)
            
            // 更新菜单栏图标显示
            if let button = statusItem?.button {
                button.title = " \(usage.tokensToday / 1000)K"
            }
            
        case .failure(let error):
            menu.insertItem(NSMenuItem(title: "加载失败: \(error.localizedDescription)", action: nil, keyEquivalent: ""), at: 0)
        }
    }
}
