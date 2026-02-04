#!/bin/bash

# OpenRouter Monitor - 推送到 GitHub 脚本
# 使用方法：
# 1. 在 GitHub 上创建新仓库（命名为 openrouter-monitor）
# 2. 不要初始化 README、.gitignore 或 LICENSE（已经有了）
# 3. 运行此脚本：./PUSH_TO_GITHUB.sh YOUR_GITHUB_USERNAME

set -e  # 遇到错误立即退出

if [ -z "$1" ]; then
    echo "❌ 错误：请提供 GitHub 用户名"
    echo ""
    echo "使用方法："
    echo "  ./PUSH_TO_GITHUB.sh YOUR_GITHUB_USERNAME"
    echo ""
    echo "例如："
    echo "  ./PUSH_TO_GITHUB.sh octocat"
    exit 1
fi

USERNAME="$1"
REPO_URL="https://github.com/$USERNAME/openrouter-monitor.git"

echo "🚀 准备推送到 GitHub..."
echo ""
echo "📍 仓库地址: $REPO_URL"
echo ""

# 检查是否已有 remote
if git remote | grep -q '^origin$'; then
    echo "⚠️  检测到已存在的 origin remote"
    echo "当前 origin: $(git remote get-url origin)"
    read -p "是否要覆盖？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote remove origin
        echo "✅ 已移除旧的 origin"
    else
        echo "❌ 取消操作"
        exit 1
    fi
fi

# 添加 remote
git remote add origin "$REPO_URL"
echo "✅ 已添加 remote: $REPO_URL"

# 推送
echo ""
echo "📤 正在推送到 GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 成功！项目已推送到 GitHub"
    echo ""
    echo "📍 查看你的项目："
    echo "   https://github.com/$USERNAME/openrouter-monitor"
    echo ""
    echo "📝 下一步："
    echo "   1. 访问上面的 URL 查看项目"
    echo "   2. 编辑 README.md 中的占位符（yourusername → $USERNAME）"
    echo "   3. 在 Mac 上用 Xcode 打开项目并测试"
    echo "   4. 参考 PROJECT_SUMMARY.md 继续开发"
else
    echo ""
    echo "❌ 推送失败"
    echo ""
    echo "可能的原因："
    echo "   1. 仓库不存在 - 请先在 GitHub 上创建"
    echo "   2. 没有权限 - 检查你的 GitHub 认证"
    echo "   3. 仓库地址错误 - 确认用户名正确"
    echo ""
    echo "手动推送命令："
    echo "   git remote add origin $REPO_URL"
    echo "   git push -u origin main"
fi
