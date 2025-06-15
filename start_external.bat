@echo off
chcp 65001 >nul
title PDF-Craft WebUI - 外网访问启动器

echo ============================================================
echo PDF-Craft WebUI - 外网访问启动器
echo ============================================================
echo.

:: 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到Python，请先安装Python 3.7+
    pause
    exit /b 1
)

:: 检查是否在正确的目录
if not exist "app.py" (
    echo 错误: 请在包含app.py的目录中运行此脚本
    pause
    exit /b 1
)

:: 设置环境变量（可选）
:: set HOST=0.0.0.0
:: set PORT=5000
:: set DEBUG=False

echo 正在启动PDF-Craft WebUI外网访问模式...
echo.

:: 启动应用
python run_external.py

echo.
echo 服务器已停止
pause 