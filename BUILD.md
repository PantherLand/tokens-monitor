# 构建指南

## 前置要求

- macOS 10.15 (Catalina) 或更高版本
- Xcode 13.0 或更高版本
- Swift 5.0 或更高版本

## 开发环境设置

1. **克隆仓库**
```bash
git clone https://github.com/yourusername/openrouter-monitor.git
cd openrouter-monitor
```

2. **使用 Xcode 打开项目**

有两种方式：

### 方式 A：使用 Swift Package Manager (推荐)
```bash
open Package.swift
```

### 方式 B：创建 Xcode 项目

如果你想要完整的 Xcode 项目：

1. 打开 Xcode
2. File → New → Project
3. 选择 macOS → App
4. 项目设置：
   - Product Name: `OpenRouterMonitor`
   - Team: 选择你的开发者账户
   - Organization Identifier: `ai.openrouter.monitor`
   - Interface: SwiftUI
   - Language: Swift
   - 取消勾选 "Use Core Data"
   - 取消勾选 "Include Tests"

5. 将本仓库的 `OpenRouterMonitor/Sources` 目录下的所有 `.swift` 文件添加到项目中
6. 将 `Info.plist` 复制到项目中

## 项目配置

### 1. 设置为菜单栏应用

在 `Info.plist` 中确保有以下配置：

```xml
<key>LSUIElement</key>
<true/>
```

这会让应用以菜单栏模式运行（不显示在 Dock 中）。

### 2. 配置 App Sandbox（可选）

如果要发布到 Mac App Store，需要启用 Sandbox：

1. 在 Xcode 中选择项目
2. 选择 Target → Signing & Capabilities
3. 点击 "+ Capability"
4. 添加 "App Sandbox"
5. 启用以下权限：
   - Outgoing Connections (Client)
   - Keychain

### 3. 代码签名

1. 选择 Signing & Capabilities
2. 勾选 "Automatically manage signing"
3. 选择你的 Team

## 构建应用

### Debug 构建

```bash
swift build
```

或在 Xcode 中按 `⌘B`

### Release 构建

```bash
swift build -c release
```

或在 Xcode 中：
1. Product → Scheme → Edit Scheme
2. Run → Build Configuration → Release
3. Product → Archive

## 运行应用

### 开发模式

在 Xcode 中按 `⌘R` 运行

### 命令行运行

```bash
swift run
```

## 创建分发包

### 方式一：使用 Xcode Archive

1. Product → Archive
2. 等待构建完成
3. 在 Organizer 窗口中，选择刚才的 Archive
4. 点击 "Distribute App"
5. 选择 "Copy App"
6. 导出 `.app` 文件

### 方式二：手动打包 DMG

```bash
# 1. 创建 DMG 临时目录
mkdir -p dmg_temp
cp -r build/Release/OpenRouterMonitor.app dmg_temp/

# 2. 创建 DMG
hdiutil create -volname "OpenRouter Monitor" -srcfolder dmg_temp -ov -format UDZO OpenRouterMonitor.dmg

# 3. 清理
rm -rf dmg_temp
```

## 故障排除

### 问题：编译错误 "Cannot find type 'NSStatusItem'"

**解决方案：** 确保在 Target 设置中，Deployment Target 设置为 macOS 10.15 或更高。

### 问题：应用无法访问网络

**解决方案：** 
1. 检查 App Sandbox 是否启用了 "Outgoing Connections"
2. 确保 Info.plist 中没有限制网络访问的配置

### 问题：API Key 无法保存

**解决方案：** 
1. 确保启用了 Keychain 访问权限
2. 在 Sandbox 设置中启用 "Keychain" capability

## 测试

运行单元测试（如果添加了测试）：

```bash
swift test
```

## 调试技巧

### 查看日志

在 Xcode Console 中可以看到应用日志，或使用：

```bash
log stream --predicate 'subsystem == "ai.openrouter.monitor"' --level debug
```

### 调试 API 请求

在 `OpenRouterAPIManager.swift` 中添加打印语句：

```swift
print("Request URL: \(request.url?.absoluteString ?? "")")
print("Response: \(String(data: data, encoding: .utf8) ?? "")")
```

## 性能优化

- 使用 Instruments 分析内存和 CPU 使用
- 确保 API 请求在后台线程执行
- 缓存 API 响应以减少请求频率

## 发布检查清单

- [ ] 更新版本号（CFBundleShortVersionString）
- [ ] 更新构建号（CFBundleVersion）
- [ ] 测试所有功能
- [ ] 检查内存泄漏
- [ ] 验证 API Key 安全性
- [ ] 准备发布说明
- [ ] 创建 Git tag
- [ ] 构建 Release 版本
- [ ] 公证应用（如果要分发）
- [ ] 上传到 GitHub Releases
