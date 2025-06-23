#!/bin/bash

# Ubuntu 24.04 OCR引擎安装脚本
# 专门安装和配置Tesseract和EasyOCR

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印横幅
print_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Ubuntu 24.04 OCR引擎安装脚本                    ║"
    echo "║                                                              ║"
    echo "║  🔍 Tesseract OCR - Google开源OCR引擎                        ║"
    echo "║  🤖 EasyOCR - 深度学习OCR引擎                                ║"
    echo "║  📦 自动安装依赖和语言包                                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# 检查是否为Ubuntu系统
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_message $RED "错误: 此脚本专为Ubuntu系统设计"
        exit 1
    fi
    
    local version=$(lsb_release -rs)
    print_message $BLUE "检测到Ubuntu版本: $version"
    
    if [[ "$version" < "20.04" ]]; then
        print_message $YELLOW "警告: 建议使用Ubuntu 20.04或更高版本"
    fi
}

# 更新系统包
update_system() {
    print_message $BLUE "更新系统包列表..."
    sudo apt update
    
    print_message $BLUE "升级系统包..."
    sudo apt upgrade -y
}

# 安装基础依赖
install_basic_dependencies() {
    print_message $BLUE "安装基础依赖..."
    
    local packages=(
        "python3"
        "python3-pip"
        "python3-dev"
        "build-essential"
        "cmake"
        "pkg-config"
        "libjpeg-dev"
        "libtiff5-dev"
        "libpng-dev"
        "libavcodec-dev"
        "libavformat-dev"
        "libswscale-dev"
        "libv4l-dev"
        "libxvidcore-dev"
        "libx264-dev"
        "libfontconfig1-dev"
        "libcairo2-dev"
        "libgdk-pixbuf2.0-dev"
        "libpango1.0-dev"
        "libgtk2.0-dev"
        "libgtk-3-dev"
        "libatlas-base-dev"
        "gfortran"
        "libhdf5-dev"
        "libhdf5-serial-dev"
        "libhdf5-103"
        "libqtgui4"
        "libqtwebkit4"
        "libqt4-test"
        "python3-pyqt5"
        "wget"
        "curl"
        "unzip"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            print_message $BLUE "安装 $package..."
            sudo apt install -y "$package" || print_message $YELLOW "警告: $package 安装失败，继续..."
        else
            print_message $GREEN "$package 已安装"
        fi
    done
}

# 安装Tesseract OCR
install_tesseract() {
    print_message $BLUE "安装Tesseract OCR..."
    
    # 安装Tesseract主程序
    sudo apt install -y tesseract-ocr
    
    # 安装语言包
    print_message $BLUE "安装Tesseract语言包..."
    local lang_packages=(
        "tesseract-ocr-chi-sim"    # 简体中文
        "tesseract-ocr-chi-tra"    # 繁体中文
        "tesseract-ocr-eng"        # 英文
        "tesseract-ocr-jpn"        # 日文
        "tesseract-ocr-kor"        # 韩文
        "tesseract-ocr-fra"        # 法文
        "tesseract-ocr-deu"        # 德文
        "tesseract-ocr-spa"        # 西班牙文
        "tesseract-ocr-rus"        # 俄文
        "tesseract-ocr-ara"        # 阿拉伯文
    )
    
    for lang_package in "${lang_packages[@]}"; do
        if sudo apt install -y "$lang_package"; then
            print_message $GREEN "$lang_package 安装成功"
        else
            print_message $YELLOW "警告: $lang_package 安装失败，继续..."
        fi
    done
    
    # 验证Tesseract安装
    if command -v tesseract &> /dev/null; then
        local version=$(tesseract --version | head -n1)
        print_message $GREEN "✅ Tesseract安装成功: $version"
        
        # 显示可用语言
        print_message $BLUE "可用语言包:"
        tesseract --list-langs | grep -E "(chi_sim|chi_tra|eng|jpn|kor|fra|deu|spa|rus|ara)" || true
    else
        print_message $RED "❌ Tesseract安装失败"
        return 1
    fi
}

# 安装Python OCR包
install_python_packages() {
    print_message $BLUE "安装Python OCR包..."
    
    # 升级pip
    python3 -m pip install --upgrade pip
    
    # 安装基础图像处理包
    print_message $BLUE "安装基础图像处理包..."
    python3 -m pip install --user numpy
    python3 -m pip install --user Pillow
    python3 -m pip install --user opencv-python
    
    # 安装Tesseract Python接口
    print_message $BLUE "安装pytesseract..."
    python3 -m pip install --user pytesseract
    
    # 安装EasyOCR
    print_message $BLUE "安装EasyOCR..."
    python3 -m pip install --user easyocr
    
    # 安装其他有用的OCR相关包
    print_message $BLUE "安装其他OCR相关包..."
    python3 -m pip install --user pdf2image
    python3 -m pip install --user pdfplumber
    python3 -m pip install --user scikit-image
    
    print_message $GREEN "✅ Python包安装完成"
}

# 安装PaddleOCR (可选)
install_paddleocr() {
    print_message $BLUE "安装PaddleOCR (可选)..."
    
    # 询问用户是否安装PaddleOCR
    read -p "是否安装PaddleOCR? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message $BLUE "安装PaddlePaddle..."
        python3 -m pip install --user paddlepaddle
        
        print_message $BLUE "安装PaddleOCR..."
        python3 -m pip install --user paddleocr
        
        print_message $GREEN "✅ PaddleOCR安装完成"
    else
        print_message $YELLOW "跳过PaddleOCR安装"
    fi
}

# 安装RapidOCR (可选)
install_rapidocr() {
    print_message $BLUE "安装RapidOCR (可选)..."
    
    # 询问用户是否安装RapidOCR
    read -p "是否安装RapidOCR? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message $BLUE "安装RapidOCR..."
        python3 -m pip install --user rapidocr-onnxruntime
        
        print_message $GREEN "✅ RapidOCR安装完成"
    else
        print_message $YELLOW "跳过RapidOCR安装"
    fi
}

# 配置环境变量
setup_environment() {
    print_message $BLUE "配置环境变量..."
    
    # 检查PATH中是否包含用户本地bin目录
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        print_message $GREEN "已添加 ~/.local/bin 到PATH"
    fi
    
    # 设置Tesseract路径 (如果需要)
    if command -v tesseract &> /dev/null; then
        local tesseract_path=$(which tesseract)
        echo "export TESSERACT_CMD='$tesseract_path'" >> ~/.bashrc
        print_message $GREEN "已设置TESSERACT_CMD环境变量"
    fi
    
    print_message $YELLOW "请运行 'source ~/.bashrc' 或重新登录以应用环境变量更改"
}

# 创建测试脚本
create_test_script() {
    print_message $BLUE "创建OCR测试脚本..."
    
    cat > test_ocr_installation.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OCR引擎安装测试脚本
"""

import sys
import os
from PIL import Image, ImageDraw, ImageFont
import io

def create_test_image():
    """创建测试图像"""
    # 创建一个包含中英文文本的测试图像
    img = Image.new('RGB', (400, 200), color='white')
    draw = ImageDraw.Draw(img)
    
    # 尝试使用系统字体，如果没有就使用默认字体
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 20)
    except:
        font = ImageFont.load_default()
    
    # 绘制测试文本
    draw.text((10, 10), "Hello World!", fill='black', font=font)
    draw.text((10, 40), "你好世界！", fill='black', font=font)
    draw.text((10, 70), "OCR Test", fill='black', font=font)
    draw.text((10, 100), "光学字符识别", fill='black', font=font)
    
    return img

def test_tesseract():
    """测试Tesseract OCR"""
    print("🔍 测试Tesseract OCR...")
    try:
        import pytesseract
        from PIL import Image
        
        # 创建测试图像
        test_image = create_test_image()
        
        # 测试OCR
        text = pytesseract.image_to_string(test_image, lang='chi_sim+eng')
        print(f"✅ Tesseract OCR 可用")
        print(f"   识别结果: {text.strip()}")
        
        # 显示支持的语言
        try:
            langs = pytesseract.get_languages()
            print(f"   支持的语言: {', '.join(langs[:10])}{'...' if len(langs) > 10 else ''}")
        except:
            print("   无法获取支持的语言列表")
            
        return True
    except ImportError as e:
        print(f"❌ Tesseract OCR 不可用: 缺少pytesseract模块")
        return False
    except Exception as e:
        print(f"❌ Tesseract OCR 不可用: {e}")
        return False

def test_easyocr():
    """测试EasyOCR"""
    print("🤖 测试EasyOCR...")
    try:
        import easyocr
        import numpy as np
        
        # 创建测试图像
        test_image = create_test_image()
        img_array = np.array(test_image)
        
        # 初始化EasyOCR (只使用英文，避免下载大量模型)
        reader = easyocr.Reader(['en'], gpu=False)
        
        # 测试OCR
        results = reader.readtext(img_array)
        print(f"✅ EasyOCR 可用")
        
        if results:
            print("   识别结果:")
            for (bbox, text, confidence) in results:
                print(f"     {text} (置信度: {confidence:.2f})")
        else:
            print("   未识别到文本")
            
        return True
    except ImportError as e:
        print(f"❌ EasyOCR 不可用: 缺少easyocr模块")
        return False
    except Exception as e:
        print(f"❌ EasyOCR 不可用: {e}")
        return False

def test_paddleocr():
    """测试PaddleOCR"""
    print("🏮 测试PaddleOCR...")
    try:
        from paddleocr import PaddleOCR
        import numpy as np
        
        # 创建测试图像
        test_image = create_test_image()
        img_array = np.array(test_image)
        
        # 初始化PaddleOCR
        ocr = PaddleOCR(use_angle_cls=True, lang='ch', use_gpu=False)
        
        # 测试OCR
        result = ocr.ocr(img_array, cls=True)
        print(f"✅ PaddleOCR 可用")
        
        if result and len(result) > 0:
            print("   识别结果:")
            for line in result:
                if isinstance(line, list):
                    for item in line:
                        if len(item) >= 2:
                            text, confidence = item[1]
                            print(f"     {text} (置信度: {confidence:.2f})")
        else:
            print("   未识别到文本")
            
        return True
    except ImportError as e:
        print(f"❌ PaddleOCR 不可用: 缺少paddleocr模块")
        return False
    except Exception as e:
        print(f"❌ PaddleOCR 不可用: {e}")
        return False

def test_rapidocr():
    """测试RapidOCR"""
    print("⚡ 测试RapidOCR...")
    try:
        from rapidocr_onnxruntime import RapidOCR
        import numpy as np
        
        # 创建测试图像
        test_image = create_test_image()
        img_array = np.array(test_image)
        
        # 初始化RapidOCR
        ocr = RapidOCR()
        
        # 测试OCR
        result, elapse = ocr(img_array)
        print(f"✅ RapidOCR 可用 (耗时: {elapse:.2f}s)")
        
        if result:
            print("   识别结果:")
            for item in result:
                if len(item) >= 2:
                    text, confidence = item[1], item[2]
                    print(f"     {text} (置信度: {confidence:.2f})")
        else:
            print("   未识别到文本")
            
        return True
    except ImportError as e:
        print(f"❌ RapidOCR 不可用: 缺少rapidocr_onnxruntime模块")
        return False
    except Exception as e:
        print(f"❌ RapidOCR 不可用: {e}")
        return False

def main():
    """主函数"""
    print("=" * 60)
    print("OCR引擎安装测试")
    print("=" * 60)
    
    results = []
    
    # 测试各个OCR引擎
    results.append(("Tesseract", test_tesseract()))
    results.append(("EasyOCR", test_easyocr()))
    results.append(("PaddleOCR", test_paddleocr()))
    results.append(("RapidOCR", test_rapidocr()))
    
    # 显示总结
    print("\n" + "=" * 60)
    print("测试结果总结:")
    print("=" * 60)
    
    available_count = 0
    for name, available in results:
        status = "✅ 可用" if available else "❌ 不可用"
        print(f"{name:12} : {status}")
        if available:
            available_count += 1
    
    print(f"\n总计: {available_count}/{len(results)} 个OCR引擎可用")
    
    if available_count > 0:
        print("\n🎉 恭喜！至少有一个OCR引擎可以正常工作。")
        print("您现在可以在PDF OCR WebUI中使用这些OCR引擎了。")
    else:
        print("\n😞 很遗憾，没有OCR引擎可以正常工作。")
        print("请检查安装过程中是否有错误，或者重新运行安装脚本。")

if __name__ == "__main__":
    main()
EOF
    
    chmod +x test_ocr_installation.py
    print_message $GREEN "✅ 测试脚本创建完成: test_ocr_installation.py"
}

# 主函数
main() {
    print_banner
    
    # 检查系统
    check_ubuntu
    
    # 更新系统
    print_message $BLUE "是否更新系统包? (推荐)"
    read -p "更新系统包? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        update_system
    fi
    
    # 安装基础依赖
    install_basic_dependencies
    
    # 安装Tesseract
    install_tesseract
    
    # 安装Python包
    install_python_packages
    
    # 可选安装
    install_paddleocr
    install_rapidocr
    
    # 配置环境
    setup_environment
    
    # 创建测试脚本
    create_test_script
    
    print_message $GREEN "🎉 OCR引擎安装完成！"
    echo ""
    echo "📋 安装总结:"
    echo "  ✅ Tesseract OCR - 已安装"
    echo "  ✅ EasyOCR - 已安装"
    echo "  ✅ Python OCR包 - 已安装"
    echo "  ✅ 测试脚本 - 已创建"
    echo ""
    echo "🚀 下一步:"
    echo "  1. 重新加载环境变量: source ~/.bashrc"
    echo "  2. 运行测试脚本: python3 test_ocr_installation.py"
    echo "  3. 重启PDF OCR WebUI服务: ./service_restart.sh"
    echo ""
    print_message $YELLOW "注意: 如果使用systemd服务，请重启服务以应用更改"
}

# 运行主函数
main "$@" 