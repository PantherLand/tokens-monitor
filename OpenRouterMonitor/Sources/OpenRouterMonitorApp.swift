//
//  OpenRouterMonitorApp.swift
//  OpenRouterMonitor
//
//  Multi-provider token usage monitor
//

import SwiftUI
import AppKit

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
    var apiManager: MultiProviderAPIManager?
    var settingsWindowController: NSWindowController? // Keep reference to prevent deallocation
    var detailWindowController: NSWindowController? // Detail view window
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
        
        // Create menubar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemName: "chart.bar.fill", accessibilityDescription: "Token Monitor")
            button.action = #selector(showMenu)
            button.target = self
        }
        
        // Initialize API Manager
        apiManager = MultiProviderAPIManager()
        
        // Build menu
        constructMenu()
        
        // Start periodic refresh
        startPeriodicRefresh()
        
        // Listen for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: NSNotification.Name("SettingsChanged"),
            object: nil
        )
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        // Usage display
        menu.addItem(NSMenuItem(title: "Loading...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Refresh
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func showMenu() {
        statusItem?.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: statusItem?.button)
    }
    
    @objc func refreshNow() {
        updateUsageDisplay()
    }
    
    @objc func openSettings() {
        // Close existing settings window if any
        settingsWindowController?.close()
        
        // Create new settings window
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Token Monitor Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        
        settingsWindowController = NSWindowController(window: window)
        settingsWindowController?.showWindow(nil)
        
        // Bring to front
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Token Monitor"
        alert.informativeText = "Multi-provider API usage monitor\n\nSupports: OpenRouter, OpenAI, Anthropic, Google\n\nVersion: 1.0.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "GitHub")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            if let url = URL(string: "https://github.com/PantherLand/tokens-monitor") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @objc func showProviderDetail(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              let provider = dict["provider"] as? APIProvider,
              let usage = dict["usage"] as? UsageData else {
            return
        }
        showDetailView(provider: provider, usage: usage)
    }
    
    func showDetailView(provider: APIProvider, usage: UsageData) {
        detailWindowController?.close()
        
        let detailView = UsageDetailView(provider: provider, usage: usage)
        let hostingController = NSHostingController(rootView: detailView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "\(provider.displayName) Usage Details"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()
        
        detailWindowController = NSWindowController(window: window)
        detailWindowController?.showWindow(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func settingsChanged() {
        // Restart refresh timer with new interval
        startPeriodicRefresh()
        // Immediate refresh
        updateUsageDisplay()
    }
    
    func startPeriodicRefresh() {
        let interval = UserDefaults.standard.double(forKey: "refreshInterval")
        let refreshInterval = interval > 0 ? interval * 60 : 300 // default 5 minutes
        
        Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            self.updateUsageDisplay()
        }
        
        // Immediate refresh
        updateUsageDisplay()
    }
    
    func updateUsageDisplay() {
        apiManager?.fetchAllUsage { [weak self] result in
            DispatchQueue.main.async {
                self?.updateMenuWithUsage(result)
            }
        }
    }
    
    func updateMenuWithUsage(_ result: Result<[APIProvider: UsageData], Error>) {
        guard let menu = statusItem?.menu else { return }
        
        // Remove old usage items
        while menu.items.count > 0 && menu.items[0].action == nil {
            menu.removeItem(at: 0)
        }
        
        switch result {
        case .success(let usageData):
            if usageData.isEmpty {
                menu.insertItem(NSMenuItem(title: "No API keys configured", action: nil, keyEquivalent: ""), at: 0)
                menu.insertItem(NSMenuItem(title: "→ Click Settings to add", action: nil, keyEquivalent: ""), at: 1)
            } else {
                var index = 0
                for (provider, usage) in usageData.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                    // Provider header - clickable to show details
                    let headerItem = NSMenuItem(title: "[\(provider.displayName)] - View Details", action: #selector(showProviderDetail(_:)), keyEquivalent: "")
                    headerItem.target = self
                    headerItem.representedObject = ["provider": provider, "usage": usage] as [String : Any]
                    headerItem.attributedTitle = NSAttributedString(
                        string: "[\(provider.displayName)]",
                        attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)]
                    )
                    menu.insertItem(headerItem, at: index)
                    index += 1
                    
                    // Usage details
                    menu.insertItem(NSMenuItem(title: "  Today: \(formatTokens(usage.tokensToday))", action: nil, keyEquivalent: ""), at: index)
                    index += 1
                    menu.insertItem(NSMenuItem(title: "  Month: $\(String(format: "%.2f", usage.costThisMonth))", action: nil, keyEquivalent: ""), at: index)
                    index += 1
                    
                    if usage.remainingCredits > 0 {
                        menu.insertItem(NSMenuItem(title: "  Credits: $\(String(format: "%.2f", usage.remainingCredits))", action: nil, keyEquivalent: ""), at: index)
                        index += 1
                    }
                    
                    // Separator between providers
                    if index < usageData.count * 4 {
                        menu.insertItem(NSMenuItem.separator(), at: index)
                        index += 1
                    }
                }
                
                // Update menubar button
                let totalTokens = usageData.values.reduce(0) { $0 + $1.tokensToday }
                if let button = statusItem?.button {
                    button.title = " \(formatTokens(totalTokens, short: true))"
                }
            }
            
        case .failure(let error):
            menu.insertItem(NSMenuItem(title: "Error: \(error.localizedDescription)", action: nil, keyEquivalent: ""), at: 0)
            menu.insertItem(NSMenuItem(title: "→ Check Settings", action: nil, keyEquivalent: ""), at: 1)
        }
    }
    
    private func formatTokens(_ tokens: Int, short: Bool = false) -> String {
        if short {
            if tokens >= 1_000_000 {
                return String(format: "%.1fM", Double(tokens) / 1_000_000.0)
            } else if tokens >= 1_000 {
                return String(format: "%.1fK", Double(tokens) / 1_000.0)
            } else {
                return "\(tokens)"
            }
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: tokens)) ?? "\(tokens)"
        }
    }
}
