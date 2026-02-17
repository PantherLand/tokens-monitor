# 🛠️ 开发指南

本文档面向开发者，提供项目开发的详细指导。

---

## 🚀 快速开始

### 环境准备

```bash
# 1. 克隆项目
git clone https://github.com/PantherLand/tokens-monitor.git
cd tokens-monitor

# 2. 安装依赖（如需要）
# Swift Package Manager 会自动处理

# 3. 在 Xcode 中打开
open Package.swift
# 或者创建完整的 Xcode 项目（见 BUILD.md）
```

### 开发工作流

```bash
# 创建功能分支
git checkout -b feature/your-feature-name

# 开发...
# 测试...

# 提交
git add .
git commit -m "feat: add your feature"

# 推送并创建 PR
git push origin feature/your-feature-name
gh pr create --fill
```

---

## 📁 项目架构

### 目录结构

```
tokens-monitor/
├── OpenRouterMonitor/
│   ├── Sources/
│   │   ├── App/
│   │   │   └── OpenRouterMonitorApp.swift   # 应用入口
│   │   ├── Managers/
│   │   │   └── OpenRouterAPIManager.swift   # API 管理器
│   │   ├── Views/
│   │   │   └── SettingsView.swift           # 设置界面
│   │   ├── Models/                          # 数据模型（待添加）
│   │   ├── Utilities/                       # 工具类（待添加）
│   │   └── Extensions/                      # 扩展（待添加）
│   ├── Resources/
│   │   └── Assets.xcassets/                 # 图标资源
│   └── Info.plist
├── Tests/                                   # 单元测试（待添加）
├── docs/                                    # 扩展文档
└── scripts/                                 # 构建脚本
```

### 建议的代码组织

```swift
// OpenRouterMonitor/Sources/
App/
  - OpenRouterMonitorApp.swift      // 应用入口
  - AppDelegate.swift               // App Delegate

Managers/
  - OpenRouterAPIManager.swift      // API 调用
  - KeychainManager.swift           // Keychain 操作
  - NotificationManager.swift       // 通知管理

Models/
  - UsageData.swift                 // 使用数据模型
  - APIResponse.swift               // API 响应模型
  - Settings.swift                  // 设置模型

Views/
  - MenuBarView/
    - MenuBarController.swift       // 菜单栏控制器
    - UsageMenuView.swift           // 使用量显示
  - Settings/
    - SettingsView.swift            // 设置主界面
    - APIKeyView.swift              // API Key 配置
    - PreferencesView.swift         // 偏好设置

Utilities/
  - Logger.swift                    // 日志工具
  - Constants.swift                 // 常量定义
  - Extensions.swift                // 扩展方法
```

---

## 🔑 核心组件开发

### 1. OpenRouter API 集成

**当前状态：** 需要验证实际 API 响应格式

**TODO:**
1. 研究 OpenRouter API 文档
2. 更新数据模型以匹配实际响应
3. 实现完整的错误处理

**示例代码框架：**

```swift
// 更新 OpenRouterAPIManager.swift

struct OpenRouterAPIEndpoints {
    static let baseURL = "https://openrouter.ai/api/v1"
    static let keyInfo = "\(baseURL)/auth/key"
    static let usage = "\(baseURL)/generation"  // 待确认
}

// 错误类型
enum APIError: Error {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case rateLimitExceeded
    case serverError(Int)
}

// 请求方法
func fetchUsage(completion: @escaping (Result<UsageData, APIError>) -> Void) {
    // 实现带重试逻辑的请求
}
```

### 2. 菜单栏 UI 优化

**需求：**
- 显示实时使用量
- 支持多级菜单
- 加载状态指示
- 错误提示

**实现建议：**

```swift
// MenuBarController.swift
class MenuBarController {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    
    func updateDisplay(with usage: UsageData) {
        // 更新图标
        // 更新菜单内容
        // 显示通知（如需要）
    }
    
    func showError(_ error: Error) {
        // 显示错误状态
    }
    
    func showLoading() {
        // 显示加载动画
    }
}
```

### 3. 数据持久化

**需求：**
- 保存使用历史
- 缓存 API 响应
- 用户设置持久化

**技术选择：**
- UserDefaults: 简单设置
- Keychain: API Key（已实现）
- CoreData / SQLite: 历史数据（待实现）
- File-based: JSON 缓存（可选）

---

## 🧪 测试策略

### 单元测试

```swift
// Tests/OpenRouterAPIManagerTests.swift
import XCTest
@testable import OpenRouterMonitor

final class OpenRouterAPIManagerTests: XCTestCase {
    var apiManager: OpenRouterAPIManager!
    
    override func setUp() {
        apiManager = OpenRouterAPIManager()
    }
    
    func testAPIKeyStorage() {
        let testKey = "test-key-123"
        apiManager.apiKey = testKey
        XCTAssertEqual(apiManager.apiKey, testKey)
    }
    
    func testAPIRequestBuilding() {
        // 测试请求构建逻辑
    }
    
    func testResponseParsing() {
        // 测试响应解析
    }
}
```

### 集成测试

```swift
func testEndToEndUsageFetch() {
    let expectation = XCTestExpectation(description: "Fetch usage")
    
    apiManager.fetchUsage { result in
        switch result {
        case .success(let usage):
            XCTAssertGreaterThanOrEqual(usage.tokensToday, 0)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
        expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 10.0)
}
```

### 手动测试清单

见 [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) 中的完整清单。

---

## 🎨 UI/UX 设计指南

### 设计原则

1. **简洁优先** - 菜单栏空间有限，保持简洁
2. **一致性** - 遵循 macOS Human Interface Guidelines
3. **可读性** - 清晰的层次和排版
4. **响应式** - 及时反馈用户操作

### 颜色方案

```swift
// 建议的配色
extension Color {
    static let tokenUsageNormal = Color.green
    static let tokenUsageWarning = Color.orange
    static let tokenUsageCritical = Color.red
    
    static let backgroundPrimary = Color(.windowBackgroundColor)
    static let textPrimary = Color(.labelColor)
    static let textSecondary = Color(.secondaryLabelColor)
}
```

### 图标设计

**菜单栏图标要求：**
- 尺寸：16x16 pt @ 1x, 32x32 pt @ 2x
- 格式：Template image (单色，支持深色模式)
- 风格：简洁、可识别

**应用图标：**
- macOS 标准尺寸（1024x1024 原始）
- 遵循 macOS Big Sur 设计语言

---

## 🔄 CI/CD 流程

### GitHub Actions

当前配置：`.github/workflows/build.yml`

**触发条件：**
- Push to main
- Pull requests
- Tags (v*)

**构建步骤：**
1. 代码检出
2. 环境设置
3. Swift build
4. 运行测试
5. 打包（仅 release）

**改进计划：**
- [ ] 添加代码质量检查（SwiftLint）
- [ ] 自动化测试覆盖率报告
- [ ] 自动发布到 GitHub Releases
- [ ] 签名和公证（需要证书）

---

## 📝 代码规范

### Swift 风格

遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

**关键要点：**
- 使用清晰的命名
- 优先使用值类型（struct）
- 合理使用可选类型
- 避免强制解包

### 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)

```
feat: 新功能
fix: Bug 修复
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具

示例：
feat: add usage trend chart
fix: resolve keychain access issue
docs: update API integration guide
```

---

## 🐛 调试技巧

### 查看日志

```bash
# Console.app 查看应用日志
# 或命令行：
log stream --predicate 'subsystem == "ai.openrouter.monitor"' --level debug
```

### Xcode 调试

```swift
// 添加断点
// 使用 LLDB 命令
// 查看内存图

// 打印调试信息
#if DEBUG
print("Debug: API Response = \(response)")
#endif
```

### 性能分析

使用 Xcode Instruments：
- Time Profiler: CPU 使用
- Allocations: 内存分配
- Leaks: 内存泄漏
- Network: 网络请求

---

## 📚 资源链接

### 官方文档
- [Swift.org](https://swift.org/documentation/)
- [SwiftUI](https://developer.apple.com/documentation/swiftui/)
- [AppKit](https://developer.apple.com/documentation/appkit/)

### 相关项目
- [OpenRouter](https://openrouter.ai/docs) - API 文档

### 工具
- [SwiftLint](https://github.com/realm/SwiftLint) - 代码规范检查
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - 代码格式化

---

## 🤔 常见问题

### Q: 如何测试 API 集成？

使用真实 API Key 在开发环境测试，或创建 mock API 响应。

### Q: 如何处理不同 macOS 版本兼容性？

使用 `@available` 检查：
```swift
if #available(macOS 13.0, *) {
    // 新 API
} else {
    // 降级方案
}
```

### Q: 如何优化启动速度？

- 延迟加载非必需组件
- 异步初始化
- 缓存数据

---

**需要帮助？** 在 [Discussions](https://github.com/PantherLand/tokens-monitor/discussions) 提问！
