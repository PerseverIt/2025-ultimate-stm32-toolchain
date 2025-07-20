@echo off
echo 🚀 同时推送到GitLab和GitHub
echo ===============================

echo 检查是否有未提交的更改...
git status --porcelain | findstr . >nul
if %errorlevel% equ 0 (
    echo ⚠️  发现未提交的更改，请先提交:
    echo git add .
    echo git commit -m "你的提交信息"
    echo.
    git status
    pause
    exit /b 1
)

echo ✅ 工作目录干净，开始推送...
echo.

echo 📤 推送到GitLab...
git push origin main
if %errorlevel% neq 0 (
    echo ❌ GitLab推送失败
    pause
    exit /b 1
)
echo ✅ GitLab推送成功

echo.
echo 📤 推送到GitHub...
git push github main
if %errorlevel% neq 0 (
    echo ❌ GitHub推送失败
    pause
    exit /b 1
)
echo ✅ GitHub推送成功

echo.
echo 🎉 成功推送到两个平台!
echo 🦊 GitLab: https://gitlab.com/perseverit-group/2025-ultimate-stm32-toolchain
echo 🐱 GitHub: https://github.com/PerseverIt/2025-ultimate-stm32-toolchain

pause
