# 快速开始

## 5 分钟上手 OpenRouter Monitor

### 1. 获取 OpenRouter API Key

1. 访问 [OpenRouter](https://openrouter.ai/)
2. 登录或注册账户
3. 进入 [API Keys 页面](https://openrouter.ai/keys)
4. 点击 "Create Key"
5. 复制生成的 API Key（格式：`sk-or-v1-...`）

### 2. 安装应用

**下载预编译版本：**
- 前往 [Releases](https://github.com/PantherLand/openrouter-monitor/releases)
- 下载最新的 `.dmg` 文件
- 打开 DMG，拖动应用到 Applications 文件夹
- 右键点击应用，选择"打开"（首次运行需要）

**从源码构建：**
```bash
git clone https://github.com/PantherLand/openrouter-monitor.git
cd openrouter-monitor
swift build -c release
```

### 3. 首次配置

1. 启动应用后，你会在菜单栏看到 📊 图标
2. 点击图标 → 选择"设置..."
3. 在"OpenRouter API Key"字段粘贴你的 API Key
4. 设置刷新间隔（默认 5 分钟）
5. 点击"保存"

### 4. 开始使用

点击菜单栏图标，你将看到：
- **今日使用**：今天使用的 token 数量
- **本月费用**：本月累计费用
- **剩余额度**：账户剩余额度

点击"立即刷新"可手动更新数据。

## 常见问题

### Q: 为什么显示"加载失败"？

**A:** 可能的原因：
1. API Key 未设置或无效
   - 检查设置中的 API Key 是否正确
   - 确保 Key 以 `sk-or-v1-` 开头

2. 网络连接问题
   - 检查网络连接
   - 确认防火墙未阻止应用

3. OpenRouter API 服务问题
   - 访问 [OpenRouter Status](https://status.openrouter.ai/) 检查服务状态

### Q: 数据不更新怎么办？

**A:** 
- 点击"立即刷新"手动更新
- 检查设置中的刷新间隔
- 重启应用

### Q: API Key 安全吗？

**A:** 
- API Key 使用 macOS Keychain 加密存储
- 只在本地使用，不会上传到任何第三方服务器
- 应用代码开源，可自行审计

### Q: 如何卸载？

**A:** 
1. 退出应用（点击图标 → 退出）
2. 从 Applications 文件夹删除应用
3. API Key 会自动从 Keychain 中清除

### Q: 支持哪些 macOS 版本？

**A:** 
- macOS 10.15 (Catalina) 或更高版本
- 推荐 macOS 13 (Ventura) 或更高版本

## 高级使用

### 自定义刷新间隔

在设置中可以调整刷新间隔（1-30 分钟）。更短的间隔提供更实时的数据，但会增加 API 请求频率。

### 查看详细使用情况

点击菜单栏图标后，可以看到：
- 总使用量
- 按模型分类的使用量
- 费用明细

### 键盘快捷键

- `⌘,` - 打开设置
- `⌘R` - 立即刷新
- `⌘Q` - 退出应用

## 获取帮助

- 📖 [完整文档](https://github.com/PantherLand/openrouter-monitor)
- 🐛 [报告问题](https://github.com/PantherLand/openrouter-monitor/issues)
- 💬 [讨论区](https://github.com/PantherLand/openrouter-monitor/discussions)

## 下一步

- ⭐ 在 GitHub 上给项目加星
- 🔔 Watch 仓库以获取更新通知
- 🤝 参与贡献（见 [CONTRIBUTING.md](CONTRIBUTING.md)）

享受使用 OpenRouter Monitor！🎉
