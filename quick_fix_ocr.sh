#!/bin/bash

# 快速修复Ubuntu 24.04下Tesseract和EasyOCR不可用问题

set -e

echo "🔧 快速修复OCR引擎问题..."

# 更新包列表
echo "📦 更新包列表..."
sudo apt update

# 安装Tesseract和语言包
echo "🔍 安装Tesseract OCR..."
sudo apt install -y tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra tesseract-ocr-eng

# 安装Python开发依赖
echo "🐍 安装Python依赖..."
sudo apt install -y python3-pip python3-dev build-essential

# 升级pip
python3 -m pip install --upgrade pip

# 安装OCR Python包
echo "📚 安装OCR Python包..."
python3 -m pip install --user pytesseract Pillow opencv-python numpy

# 安装EasyOCR
echo "🤖 安装EasyOCR..."
python3 -m pip install --user easyocr

# 验证安装
echo "✅ 验证安装..."

# 测试Tesseract
if command -v tesseract &> /dev/null; then
    echo "✅ Tesseract OCR 已安装: $(tesseract --version | head -n1)"
    echo "   支持的语言: $(tesseract --list-langs | tr '\n' ' ')"
else
    echo "❌ Tesseract OCR 安装失败"
fi

# 测试Python包
python3 -c "
try:
    import pytesseract
    print('✅ pytesseract 可用')
except ImportError:
    print('❌ pytesseract 不可用')

try:
    import easyocr
    print('✅ EasyOCR 可用')
except ImportError:
    print('❌ EasyOCR 不可用')

try:
    from PIL import Image
    print('✅ Pillow 可用')
except ImportError:
    print('❌ Pillow 不可用')

try:
    import cv2
    print('✅ OpenCV 可用')
except ImportError:
    print('❌ OpenCV 不可用')
"

echo ""
echo "🎉 快速修复完成！"
echo "请重启PDF OCR WebUI服务以应用更改："
echo "  ./service_restart.sh"
echo ""
echo "如果问题仍然存在，请运行完整安装脚本："
echo "  ./install_ocr_ubuntu.sh" 