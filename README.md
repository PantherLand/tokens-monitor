# OpenRouter Monitor

<img src="assets/icon.png" alt="OpenRouter Monitor" width="128"/>

一个轻量级的 macOS 菜单栏应用，用于实时监控 OpenRouter API token 使用量。

## 功能特性

- 🔄 实时显示 token 使用量
- 📊 支持多模型使用统计
- 💰 显示当前费用和剩余额度
- ⚙️ 简洁的配置界面
- 🎨 原生 macOS 菜单栏体验（类似 ClashX）
- 🔐 本地安全存储 API Key

## 系统要求

- macOS 10.15 (Catalina) 或更高版本
- Swift 5.0+
- Xcode 13.0+

## 安装

### 方式一：下载预编译版本
1. 前往 [Releases](https://github.com/yourusername/openrouter-monitor/releases) 页面
2. 下载最新的 `.dmg` 文件
3. 打开 DMG，将应用拖入 Applications 文件夹
4. 首次运行时右键点击应用，选择"打开"

### 方式二：从源码构建
```bash
git clone https://github.com/yourusername/openrouter-monitor.git
cd openrouter-monitor
xcodebuild -scheme OpenRouterMonitor -configuration Release
```

## 使用方法

1. **首次配置**
   - 启动应用后，点击菜单栏图标
   - 选择"设置"
   - 输入你的 OpenRouter API Key
   - 设置刷新间隔（默认 5 分钟）

2. **查看使用量**
   - 点击菜单栏图标即可查看：
     - 今日总使用 tokens
     - 按模型分类的使用量
     - 当前费用
     - 剩余额度

3. **刷新数据**
   - 点击"立即刷新"手动更新数据
   - 或等待自动刷新

## OpenRouter API Key 获取

1. 访问 [OpenRouter](https://openrouter.ai/)
2. 登录你的账户
3. 前往 [API Keys](https://openrouter.ai/keys) 页面
4. 创建新的 API Key
5. 复制 Key 并粘贴到应用设置中

## 安全性

- API Key 使用 macOS Keychain 安全存储
- 所有数据仅在本地处理
- 不会上传任何信息到第三方服务器

## 截图

<img src="assets/screenshot.png" alt="应用截图" width="400"/>

## 技术栈

- Swift 5
- SwiftUI
- Combine
- URLSession (OpenRouter API 调用)
- Keychain (安全存储)

## 开发计划

- [ ] 支持历史使用趋势图表
- [ ] 使用量警报功能
- [ ] 支持多账户切换
- [ ] 导出使用报告
- [ ] 深色/浅色主题自动切换

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 致谢

灵感来源于 [ClashX](https://github.com/yichengchen/clashX)
