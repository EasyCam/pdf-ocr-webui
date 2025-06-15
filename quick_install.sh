#!/bin/bash

# PDF-Craft WebUI - 快速安装脚本
# 适用于Ubuntu 24.04及其他Debian系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 PDF-Craft WebUI 快速安装脚本${NC}"
echo -e "${BLUE}================================${NC}"

# 检查系统
echo -e "${YELLOW}[1/8]${NC} 检查系统环境..."
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}错误: 请不要使用root用户运行此脚本${NC}"
    exit 1
fi

# 更新系统
echo -e "${YELLOW}[2/8]${NC} 更新系统包..."
sudo apt update -y

# 安装基础依赖
echo -e "${YELLOW}[3/8]${NC} 安装系统依赖..."
sudo apt install -y \
    python3 python3-pip python3-venv python3-dev \
    git wget curl build-essential pkg-config \
    tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra \
    tesseract-ocr-jpn tesseract-ocr-kor libtesseract-dev \
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 \
    libxrender-dev libgomp1 libgcc-s1 ffmpeg

# 创建项目目录
echo -e "${YELLOW}[4/8]${NC} 创建项目目录..."
PROJECT_DIR="$HOME/pdf-craft-webui"
if [[ -d "$PROJECT_DIR" ]]; then
    echo -e "${YELLOW}警告: 目录已存在，将备份为 ${PROJECT_DIR}.backup${NC}"
    mv "$PROJECT_DIR" "${PROJECT_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 复制项目文件（如果是本地安装）
echo -e "${YELLOW}[5/8]${NC} 获取项目代码..."
if [[ -f "$(dirname "$0")/app.py" ]]; then
    echo "检测到本地安装，复制文件..."
    cp -r "$(dirname "$0")"/* "$PROJECT_DIR/"
else
    echo "从GitHub克隆项目..."
    git clone https://github.com/EasyCam/pdf-ocr-webui.git .
fi

# 创建虚拟环境
echo -e "${YELLOW}[6/8]${NC} 创建Python虚拟环境..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel

# 安装Python依赖
echo -e "${YELLOW}[7/8]${NC} 安装Python依赖..."
if [[ ! -f "requirements.txt" ]]; then
    echo "创建requirements.txt..."
    cat > requirements.txt << 'EOF'
Flask==2.3.3
PyMuPDF==1.23.8
pdfplumber==0.10.3
Pillow==10.0.1
opencv-python==4.8.1.78
pytesseract==0.3.10
easyocr==1.7.0
paddlepaddle==2.5.2
paddleocr==2.7.3
rapidocr-onnxruntime==1.3.11
python-docx==0.8.11
markdown==3.5.1
reportlab==4.0.4
psutil==5.9.6
requests==2.31.0
numpy==1.24.4
tqdm==4.66.1
EOF
fi

pip install -r requirements.txt

# 安装PyTorch（CPU版本）
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# 创建启动脚本
echo -e "${YELLOW}[8/8]${NC} 创建启动脚本..."
cat > start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
echo "启动PDF-Craft WebUI..."
echo "访问地址: http://localhost:5000"
python run.py
EOF
chmod +x start.sh

cat > stop.sh << 'EOF'
#!/bin/bash
echo "停止PDF-Craft WebUI..."
pkill -f "python run.py"
EOF
chmod +x stop.sh

# 创建必要目录
mkdir -p uploads results models logs

# 配置防火墙（如果有UFW）
if command -v ufw &> /dev/null; then
    echo "配置防火墙..."
    sudo ufw allow 5000/tcp 2>/dev/null || true
fi

echo -e "${GREEN}✅ 安装完成！${NC}"
echo
echo -e "${GREEN}🎉 PDF-Craft WebUI 已成功安装！${NC}"
echo
echo -e "${BLUE}安装目录:${NC} $PROJECT_DIR"
echo -e "${BLUE}启动命令:${NC} cd $PROJECT_DIR && ./start.sh"
echo -e "${BLUE}访问地址:${NC} http://localhost:5000"
echo
echo -e "${YELLOW}提示:${NC}"
echo "1. 首次启动可能需要下载模型文件，请耐心等待"
echo "2. 如需GPU加速，请手动安装CUDA版本的PyTorch"
echo "3. 如需外网访问，请配置防火墙和路由器端口转发"
echo

read -p "是否立即启动服务? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    cd "$PROJECT_DIR"
    echo -e "${BLUE}正在启动服务...${NC}"
    ./start.sh
fi 