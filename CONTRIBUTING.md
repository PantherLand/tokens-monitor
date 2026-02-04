# 贡献指南

感谢你对 OpenRouter Monitor 的关注！我们欢迎各种形式的贡献。

## 如何贡献

### 报告 Bug

1. 检查 [Issues](https://github.com/PantherLand/openrouter-monitor/issues) 确认问题是否已被报告
2. 创建新 Issue，包含：
   - 清晰的标题和描述
   - 复现步骤
   - 预期行为 vs 实际行为
   - 系统信息（macOS 版本、应用版本等）
   - 截图（如果适用）

### 功能建议

1. 先在 [Discussions](https://github.com/PantherLand/openrouter-monitor/discussions) 讨论
2. 如果得到认可，创建 Feature Request Issue
3. 描述功能的用途和预期行为

### 提交代码

1. **Fork 仓库**
   ```bash
   # 在 GitHub 上 fork 仓库
   git clone https://github.com/your-username/openrouter-monitor.git
   cd openrouter-monitor
   ```

2. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/bug-description
   ```

3. **开发**
   - 遵循代码规范（见下文）
   - 添加必要的注释
   - 确保代码可以编译
   - 测试你的更改

4. **提交**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   # 或
   git commit -m "fix: resolve issue with ..."
   ```
   
   提交信息格式：
   - `feat:` 新功能
   - `fix:` Bug 修复
   - `docs:` 文档更新
   - `style:` 代码格式（不影响功能）
   - `refactor:` 重构
   - `test:` 测试相关
   - `chore:` 构建、工具等

5. **推送并创建 Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```
   
   在 GitHub 上创建 Pull Request：
   - 清晰描述改动内容
   - 链接相关 Issue
   - 如果有 UI 改动，附上截图

## 代码规范

### Swift 风格指南

遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

**命名约定：**
- 类型（类、结构体、枚举）：`PascalCase`
- 变量、函数：`camelCase`
- 常量：`camelCase` 或 `SCREAMING_SNAKE_CASE`（全局常量）

**示例：**
```swift
// ✅ Good
class OpenRouterAPIManager {
    private let baseURL = "https://openrouter.ai/api/v1"
    
    func fetchUsage(completion: @escaping (Result<UsageData, Error>) -> Void) {
        // ...
    }
}

// ❌ Bad
class openrouterAPImanager {
    private let base_url = "https://openrouter.ai/api/v1"
    
    func FetchUsage(completion: @escaping (Result<UsageData, Error>) -> Void) {
        // ...
    }
}
```

### 代码组织

- 使用 `// MARK: -` 分隔代码块
- 私有成员放在最后
- 相关功能组织在一起

```swift
class MyClass {
    // MARK: - Properties
    var publicProperty: String
    private var privateProperty: Int
    
    // MARK: - Initialization
    init() { }
    
    // MARK: - Public Methods
    func publicMethod() { }
    
    // MARK: - Private Methods
    private func privateMethod() { }
}
```

### 错误处理

优先使用 `Result` 类型而非抛出异常：

```swift
// ✅ Good
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // ...
}

// ❌ Avoid (除非必要)
func fetchData() throws -> Data {
    // ...
}
```

### 注释

- 对复杂逻辑添加注释
- 公开 API 使用文档注释

```swift
/// 从 OpenRouter API 获取使用量数据
/// - Parameter completion: 完成回调，包含 UsageData 或错误
func fetchUsage(completion: @escaping (Result<UsageData, Error>) -> Void) {
    // 实现...
}
```

## 项目结构

```
OpenRouterMonitor/
├── Sources/
│   ├── OpenRouterMonitorApp.swift    # 主应用入口
│   ├── OpenRouterAPIManager.swift    # API 管理
│   ├── SettingsView.swift            # 设置界面
│   └── Models/                       # 数据模型（如需要）
├── Resources/
│   └── Assets.xcassets/              # 图标、图片等
└── Info.plist                        # 应用配置
```

## 测试

### 单元测试

```swift
import XCTest
@testable import OpenRouterMonitor

final class OpenRouterAPIManagerTests: XCTestCase {
    func testAPIKeyStorage() {
        let manager = OpenRouterAPIManager()
        manager.apiKey = "test-key"
        XCTAssertEqual(manager.apiKey, "test-key")
    }
}
```

### 手动测试

在提交 PR 前，请测试：
- [ ] 应用启动正常
- [ ] 菜单栏图标显示
- [ ] 设置界面可以打开
- [ ] API Key 可以保存
- [ ] 数据刷新功能正常
- [ ] 退出功能正常

## 发布流程

**仅维护者可执行：**

1. 更新版本号
2. 更新 CHANGELOG.md
3. 创建 Git tag
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
4. GitHub Actions 自动构建并发布

## 问题？

如有疑问，请在 [Discussions](https://github.com/PantherLand/openrouter-monitor/discussions) 提问。

感谢你的贡献！🎉
