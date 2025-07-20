#!/bin/bash

echo "🚀 推送2025年最强STM32工具链到GitLab"
echo "=========================================="

# 检查是否已经设置了远程仓库
if git remote get-url origin 2>/dev/null; then
    echo "✅ 远程仓库已设置"
    git remote -v
else
    echo "❌ 请先设置GitLab远程仓库URL:"
    echo "git remote add origin https://gitlab.com/你的用户名/2025-ultimate-stm32-toolchain.git"
    exit 1
fi

# 重命名分支为main
echo "🔄 重命名分支为main..."
git branch -M main

# 推送到GitLab
echo "📤 推送代码到GitLab..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 成功推送到GitLab!"
    echo ""
    echo "📋 仓库信息:"
    echo "- 名称: 2025-ultimate-stm32-toolchain"
    echo "- 描述: 🚀 2025年最强STM32开发工具链"
    echo "- 特性: 基于纯LLVM，编译速度提升10-100倍"
    echo ""
    echo "📚 包含文档:"
    echo "- README.md (主文档)"
    echo "- INSTALLATION.md (安装指南)"
    echo "- QUICKSTART.md (快速开始)"
    echo ""
    echo "🔧 核心文件:"
    echo "- cmake/pure-llvm-toolchain.cmake (工具链配置)"
    echo "- example-project/ (示例项目)"
    echo ""
    echo "🌟 现在可以分享给其他开发者了!"
else
    echo "❌ 推送失败，请检查网络连接和权限"
fi
