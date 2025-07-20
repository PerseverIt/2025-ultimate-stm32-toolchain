@echo off
echo 🔄 同步GitLab仓库到GitHub
echo ================================

echo 当前远程仓库:
git remote -v
echo.

echo 检查GitHub远程仓库是否已添加...
git remote get-url github >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ GitHub远程仓库已配置
) else (
    echo ❌ 请先添加GitHub远程仓库:
    echo git remote add github https://github.com/PerseverIt/2025-ultimate-stm32-toolchain.git
    echo.
    echo 然后重新运行此脚本
    pause
    exit /b 1
)

echo.
echo 🚀 开始推送到GitHub...
git push github main

if %errorlevel% equ 0 (
    echo.
    echo 🎉 成功同步到GitHub!
    echo.
    echo 📋 现在你的项目在两个平台都有了:
    echo 🦊 GitLab: https://gitlab.com/perseverit-group/2025-ultimate-stm32-toolchain
    echo 🐱 GitHub: https://github.com/PerseverIt/2025-ultimate-stm32-toolchain
    echo.
    echo 💡 后续更新可以同时推送到两个平台:
    echo git push origin main    ^(GitLab^)
    echo git push github main    ^(GitHub^)
    echo.
    echo 🌟 建议在GitHub上:
    echo - 添加项目标签: stm32, llvm, clang, cmake, ninja, embedded
    echo - 设置项目描述和网站链接
    echo - 启用Issues和Discussions
) else (
    echo ❌ 推送到GitHub失败
    echo 请检查:
    echo 1. GitHub仓库是否存在
    echo 2. 是否有推送权限
    echo 3. 网络连接是否正常
)

echo.
pause
