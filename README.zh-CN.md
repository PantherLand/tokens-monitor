# OpenRouter Monitor

<p align="center">
  <img src="assets/icon.png" alt="OpenRouter Monitor" width="128"/>
</p>

<p align="center">
  🔄 轻量级的 macOS 菜单栏应用，实时监控 OpenRouter API token 使用量
</p>

<p align="center">
  <a href="https://github.com/PantherLand/tokens-monitor/releases"><img src="https://img.shields.io/github/v/release/PantherLand/tokens-monitor?include_prereleases" alt="Release"></a>
  <a href="https://github.com/PantherLand/tokens-monitor/blob/main/LICENSE"><img src="https://img.shields.io/github/license/PantherLand/tokens-monitor" alt="License"></a>
  <a href="https://github.com/PantherLand/tokens-monitor/stargazers"><img src="https://img.shields.io/github/stars/PantherLand/tokens-monitor" alt="Stars"></a>
</p>

<p align="center">
  <a href="README.md">English</a> | 简体中文
</p>

## ✨ 功能特性

- 🔄 实时显示 token 使用量
- 📊 支持多模型使用统计
- 💰 显示当前费用和剩余额度
- ⚙️ 原生 macOS 菜单栏体验（类似 ClashX）
- 🔐 本地安全存储 API Key（macOS Keychain）
- 🎨 原生设计，支持深色模式

## 📸 截图

<img src="assets/screenshot.png" alt="应用截图" width="400"/>

## 🚀 快速开始

### 安装

**方式一：下载预编译版本**
1. 前往 [Releases](https://github.com/PantherLand/tokens-monitor/releases) 页面
2. 下载最新的 `.dmg` 文件
3. 打开 DMG，将应用拖入 Applications 文件夹
4. 首次运行时右键点击应用，选择"打开"

**方式二：从源码构建**
```bash
# 克隆仓库
git clone https://github.com/PantherLand/tokens-monitor.git
cd tokens-monitor

# 运行应用
make run

# 或构建 Release 版本
make build
```

### 首次配置

1. 启动应用后，你会在菜单栏看到 📊 图标
2. 点击图标 → 选择"设置..."
3. 粘贴你的 OpenRouter API Key
4. 设置刷新间隔（默认 5 分钟）
5. 点击"保存"

### 获取 OpenRouter API Key

1. 访问 [OpenRouter](https://openrouter.ai/)
2. 登录你的账户
3. 前往 [API Keys](https://openrouter.ai/keys) 页面
4. 创建新的 API Key
5. 复制并粘贴到应用设置中

## 🛠️ 开发

### 前置要求

- macOS 10.15 (Catalina) 或更高版本
- Xcode 13.0+
- Swift 5.0+

### 构建命令

```bash
# 安装依赖（如有）
make install

# 开发模式运行
make run

# 构建 Release 版本
make build

# 运行测试
make test

# 清理构建产物
make clean

# 格式化代码
make format

# 查看所有命令
make help
```

### 项目结构

```
tokens-monitor/
├── OpenRouterMonitor/
│   ├── Sources/
│   │   ├── OpenRouterMonitorApp.swift    # 应用入口
│   │   ├── OpenRouterAPIManager.swift    # API 客户端 & Keychain
│   │   └── SettingsView.swift            # 设置界面
│   ├── Resources/                        # 资源文件和图标
│   └── Info.plist
├── Makefile                              # 构建自动化
├── Package.swift                         # SPM 配置
└── docs/                                 # 文档
```

## 📖 文档

- 🚀 [快速开始指南](QUICKSTART.md)
- 🔧 [构建说明](BUILD.md)
- 💻 [开发指南](DEVELOPMENT.md)
- 🗺️ [开发路线图](ROADMAP.md)
- 🤝 [贡献指南](CONTRIBUTING.md)

## 🔒 安全性

- API Key 使用 macOS Keychain 加密存储
- 所有数据仅在本地处理
- 不会上传任何信息到第三方服务器
- 开源代码，可自行审计

## 🤝 贡献

我们欢迎各种形式的贡献！详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

### 如何贡献

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📝 更新日志

查看 [Releases](https://github.com/PantherLand/tokens-monitor/releases) 了解版本历史。

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- 灵感来源于 [ClashX](https://github.com/yichengchen/clashX)
- 使用 Swift 和 SwiftUI 构建
- 由 [OpenRouter](https://openrouter.ai/) 提供支持

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=PantherLand/tokens-monitor&type=Date)](https://star-history.com/#PantherLand/tokens-monitor&Date)

---

<p align="center">用 ❤️ 为 OpenRouter 社区打造</p>
