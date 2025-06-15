#!/bin/bash

# PDF-Craft WebUI - Ubuntu 24.04 一键安装脚本
# 版本: 3.0.0
# 作者: PDF-Craft Team
# 日期: 2024

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_NAME="pdf-craft-webui"
PROJECT_DIR="$HOME/$PROJECT_NAME"
PYTHON_VERSION="3.10"
VENV_NAME="venv"
SERVICE_NAME="pdf-craft-webui"
DEFAULT_PORT=5000
GITHUB_REPO="https://github.com/EasyCam/pdf-ocr-webui.git"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 显示横幅
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                PDF-Craft WebUI 安装脚本                      ║
    ║                                                              ║
    ║  🚀 智能文档转换平台 - Ubuntu 24.04 一键安装                 ║
    ║  📄 支持多种OCR引擎和多语言识别                              ║
    ║  🌐 支持外网访问和团队协作                                   ║
    ║                                                              ║
    ║  版本: 3.0.0                                                ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 检查系统要求
check_system() {
    log_step "检查系统环境..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法检测操作系统版本"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_warning "此脚本专为Ubuntu设计，当前系统: $ID"
        read -p "是否继续安装? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 检查Ubuntu版本
    if [[ "$VERSION_ID" != "24.04" ]]; then
        log_warning "推荐使用Ubuntu 24.04，当前版本: $VERSION_ID"
    fi
    
    # 检查架构
    ARCH=$(uname -m)
    log_info "系统架构: $ARCH"
    
    # 检查内存
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $MEMORY_GB -lt 4 ]]; then
        log_warning "内存不足4GB，可能影响性能 (当前: ${MEMORY_GB}GB)"
    else
        log_success "内存检查通过: ${MEMORY_GB}GB"
    fi
    
    # 检查磁盘空间
    DISK_SPACE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $DISK_SPACE -lt 5 ]]; then
        log_error "磁盘空间不足5GB (可用: ${DISK_SPACE}GB)"
        exit 1
    else
        log_success "磁盘空间检查通过: ${DISK_SPACE}GB可用"
    fi
    
    log_success "系统环境检查完成"
}

# 检查网络连接
check_network() {
    log_step "检查网络连接..."
    
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "网络连接失败，请检查网络设置"
        exit 1
    fi
    
    log_success "网络连接正常"
}

# 更新系统包
update_system() {
    log_step "更新系统包..."
    
    sudo apt update -y
    sudo apt upgrade -y
    
    log_success "系统包更新完成"
}

# 安装系统依赖
install_system_dependencies() {
    log_step "安装系统依赖..."
    
    # 基础依赖
    local basic_deps=(
        "python3"
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "git"
        "wget"
        "curl"
        "build-essential"
        "pkg-config"
    )
    
    # OCR相关依赖
    local ocr_deps=(
        "tesseract-ocr"
        "tesseract-ocr-chi-sim"
        "tesseract-ocr-chi-tra"
        "tesseract-ocr-jpn"
        "tesseract-ocr-kor"
        "tesseract-ocr-fra"
        "tesseract-ocr-deu"
        "tesseract-ocr-spa"
        "tesseract-ocr-rus"
        "tesseract-ocr-ara"
        "libtesseract-dev"
    )
    
    # 图像处理依赖
    local image_deps=(
        "libgl1-mesa-glx"
        "libglib2.0-0"
        "libsm6"
        "libxext6"
        "libxrender-dev"
        "libgomp1"
        "libgcc-s1"
        "libopencv-dev"
        "python3-opencv"
    )
    
    # 其他依赖
    local other_deps=(
        "ffmpeg"
        "libmagic1"
        "poppler-utils"
        "ghostscript"
    )
    
    # 合并所有依赖
    local all_deps=("${basic_deps[@]}" "${ocr_deps[@]}" "${image_deps[@]}" "${other_deps[@]}")
    
    log_info "安装 ${#all_deps[@]} 个系统包..."
    
    for dep in "${all_deps[@]}"; do
        if ! dpkg -l | grep -q "^ii  $dep "; then
            log_info "安装: $dep"
            sudo apt install -y "$dep" || log_warning "安装 $dep 失败，继续..."
        else
            log_info "已安装: $dep"
        fi
    done
    
    log_success "系统依赖安装完成"
}

# 检查GPU支持
check_gpu() {
    log_step "检查GPU支持..."
    
    if command -v nvidia-smi &> /dev/null; then
        log_success "检测到NVIDIA GPU"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits | while read line; do
            log_info "GPU: $line"
        done
        
        # 检查CUDA
        if command -v nvcc &> /dev/null; then
            CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $6}' | cut -c2-)
            log_success "CUDA版本: $CUDA_VERSION"
        else
            log_warning "未检测到CUDA，将安装CPU版本的PyTorch"
        fi
        
        return 0
    else
        log_info "未检测到NVIDIA GPU，将使用CPU模式"
        return 1
    fi
}

# 创建项目目录
create_project_directory() {
    log_step "创建项目目录..."
    
    if [[ -d "$PROJECT_DIR" ]]; then
        log_warning "项目目录已存在: $PROJECT_DIR"
        read -p "是否删除现有目录并重新安装? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_DIR"
            log_info "已删除现有目录"
        else
            log_error "安装取消"
            exit 1
        fi
    fi
    
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    log_success "项目目录创建完成: $PROJECT_DIR"
}

# 克隆项目
clone_project() {
    log_step "克隆项目代码..."
    
    # 如果是本地安装，复制当前目录的文件
    if [[ -f "$(dirname "$0")/app.py" ]]; then
        log_info "检测到本地安装，复制文件..."
        cp -r "$(dirname "$0")"/* "$PROJECT_DIR/"
    else
        log_info "从GitHub克隆项目..."
        git clone "$GITHUB_REPO" "$PROJECT_DIR"
    fi
    
    log_success "项目代码获取完成"
}

# 创建Python虚拟环境
create_virtual_environment() {
    log_step "创建Python虚拟环境..."
    
    cd "$PROJECT_DIR"
    
    # 检查Python版本
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装"
        exit 1
    fi
    
    PYTHON_VER=$(python3 --version | awk '{print $2}' | cut -d. -f1,2)
    log_info "Python版本: $PYTHON_VER"
    
    # 创建虚拟环境
    python3 -m venv "$VENV_NAME"
    source "$VENV_NAME/bin/activate"
    
    # 升级pip
    pip install --upgrade pip setuptools wheel
    
    log_success "虚拟环境创建完成"
}

# 安装Python依赖
install_python_dependencies() {
    log_step "安装Python依赖..."
    
    cd "$PROJECT_DIR"
    source "$VENV_NAME/bin/activate"
    
    # 检查requirements.txt
    if [[ ! -f "requirements.txt" ]]; then
        log_warning "requirements.txt不存在，创建基础依赖文件"
        create_requirements_file
    fi
    
    # 安装基础依赖
    log_info "安装基础Python包..."
    pip install -r requirements.txt
    
    # 根据GPU支持安装PyTorch
    if check_gpu; then
        log_info "安装GPU版本PyTorch..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    else
        log_info "安装CPU版本PyTorch..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    fi
    
    log_success "Python依赖安装完成"
}

# 创建requirements.txt文件
create_requirements_file() {
    cat > requirements.txt << 'EOF'
# Web框架
Flask==2.3.3
Werkzeug==2.3.7

# PDF处理
PyMuPDF==1.23.8
pdfplumber==0.10.3

# 图像处理
Pillow==10.0.1
opencv-python==4.8.1.78
scikit-image==0.21.0

# OCR引擎
pytesseract==0.3.10
easyocr==1.7.0
paddlepaddle==2.5.2
paddleocr==2.7.3
rapidocr-onnxruntime==1.3.11

# 文档处理
python-docx==0.8.11
markdown==3.5.1
reportlab==4.0.4

# 系统监控
psutil==5.9.6

# 其他工具
requests==2.31.0
numpy==1.24.4
pandas==2.1.1
tqdm==4.66.1
EOF
    log_info "已创建requirements.txt文件"
}

# 安装OCR引擎
install_ocr_engines() {
    log_step "安装OCR引擎..."
    
    cd "$PROJECT_DIR"
    source "$VENV_NAME/bin/activate"
    
    # 检查是否有安装脚本
    if [[ -f "install_ocr_engines.py" ]]; then
        log_info "运行OCR引擎安装脚本..."
        python install_ocr_engines.py
    else
        log_info "手动安装OCR引擎..."
        
        # 安装各个OCR引擎
        local engines=("pytesseract" "easyocr" "paddleocr" "rapidocr-onnxruntime")
        
        for engine in "${engines[@]}"; do
            log_info "安装 $engine..."
            pip install "$engine" || log_warning "安装 $engine 失败"
        done
    fi
    
    log_success "OCR引擎安装完成"
}

# 创建配置文件
create_config_files() {
    log_step "创建配置文件..."
    
    cd "$PROJECT_DIR"
    
    # 创建环境变量文件
    cat > .env << EOF
# 服务配置
HOST=0.0.0.0
PORT=$DEFAULT_PORT
DEBUG=False

# 性能配置
USE_GPU=True
BATCH_SIZE=5
MAX_WORKERS=4

# 路径配置
MODEL_DIR=./models
UPLOAD_DIR=./uploads
RESULT_DIR=./results
EOF
    
    # 创建systemd服务文件
    cat > "$SERVICE_NAME.service" << EOF
[Unit]
Description=PDF-Craft WebUI Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment=PATH=$PROJECT_DIR/$VENV_NAME/bin
ExecStart=$PROJECT_DIR/$VENV_NAME/bin/python run.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # 创建启动脚本
    cat > start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
python run.py
EOF
    chmod +x start.sh
    
    # 创建停止脚本
    cat > stop.sh << 'EOF'
#!/bin/bash
pkill -f "python run.py"
EOF
    chmod +x stop.sh
    
    log_success "配置文件创建完成"
}

# 创建必要目录
create_directories() {
    log_step "创建必要目录..."
    
    cd "$PROJECT_DIR"
    
    local dirs=("uploads" "results" "models" "logs")
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log_info "创建目录: $dir"
    done
    
    log_success "目录创建完成"
}

# 测试安装
test_installation() {
    log_step "测试安装..."
    
    cd "$PROJECT_DIR"
    source "$VENV_NAME/bin/activate"
    
    # 测试Python导入
    log_info "测试Python模块导入..."
    python -c "
import sys
print(f'Python版本: {sys.version}')

try:
    import flask
    print(f'✓ Flask: {flask.__version__}')
except ImportError as e:
    print(f'✗ Flask导入失败: {e}')

try:
    import fitz
    print(f'✓ PyMuPDF: {fitz.__version__}')
except ImportError as e:
    print(f'✗ PyMuPDF导入失败: {e}')

try:
    import cv2
    print(f'✓ OpenCV: {cv2.__version__}')
except ImportError as e:
    print(f'✗ OpenCV导入失败: {e}')

try:
    import torch
    print(f'✓ PyTorch: {torch.__version__}')
    print(f'  CUDA可用: {torch.cuda.is_available()}')
    if torch.cuda.is_available():
        print(f'  GPU数量: {torch.cuda.device_count()}')
except ImportError as e:
    print(f'✗ PyTorch导入失败: {e}')
"
    
    # 测试OCR引擎
    if [[ -f "app.py" ]]; then
        log_info "测试OCR引擎..."
        timeout 30 python -c "
try:
    from app import ocr_manager
    if ocr_manager:
        engines = ocr_manager.get_available_engines()
        print(f'可用OCR引擎: {len(engines)}')
        for name, info in engines.items():
            status = '✓' if info['available'] else '✗'
            print(f'  {status} {name}: {info[\"name\"]}')
    else:
        print('OCR管理器未初始化')
except Exception as e:
    print(f'OCR引擎测试失败: {e}')
" || log_warning "OCR引擎测试超时"
    fi
    
    log_success "安装测试完成"
}

# 配置防火墙
configure_firewall() {
    log_step "配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        log_info "配置UFW防火墙..."
        sudo ufw allow "$DEFAULT_PORT/tcp" || log_warning "防火墙配置失败"
        log_success "防火墙规则已添加: 端口 $DEFAULT_PORT"
    else
        log_warning "UFW未安装，请手动配置防火墙"
    fi
}

# 安装systemd服务
install_systemd_service() {
    log_step "安装systemd服务..."
    
    cd "$PROJECT_DIR"
    
    read -p "是否安装为系统服务（开机自启）? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo cp "$SERVICE_NAME.service" "/etc/systemd/system/"
        sudo systemctl daemon-reload
        sudo systemctl enable "$SERVICE_NAME"
        
        log_success "系统服务安装完成"
        log_info "服务管理命令:"
        log_info "  启动服务: sudo systemctl start $SERVICE_NAME"
        log_info "  停止服务: sudo systemctl stop $SERVICE_NAME"
        log_info "  查看状态: sudo systemctl status $SERVICE_NAME"
        log_info "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
    else
        log_info "跳过系统服务安装"
    fi
}

# 显示安装完成信息
show_completion_info() {
    log_success "安装完成！"
    
    echo -e "${GREEN}"
    cat << EOF

╔══════════════════════════════════════════════════════════════╗
║                    安装成功！                                ║
╚══════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"
    
    echo -e "${WHITE}项目信息:${NC}"
    echo -e "  📁 安装目录: ${CYAN}$PROJECT_DIR${NC}"
    echo -e "  🐍 Python环境: ${CYAN}$PROJECT_DIR/$VENV_NAME${NC}"
    echo -e "  🌐 访问地址: ${CYAN}http://localhost:$DEFAULT_PORT${NC}"
    echo -e "  🌍 外网访问: ${CYAN}http://[您的IP]:$DEFAULT_PORT${NC}"
    echo
    
    echo -e "${WHITE}启动方式:${NC}"
    echo -e "  ${YELLOW}方式1 - 直接启动:${NC}"
    echo -e "    cd $PROJECT_DIR"
    echo -e "    ./start.sh"
    echo
    echo -e "  ${YELLOW}方式2 - 手动启动:${NC}"
    echo -e "    cd $PROJECT_DIR"
    echo -e "    source $VENV_NAME/bin/activate"
    echo -e "    python run.py"
    echo
    
    if [[ -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
        echo -e "  ${YELLOW}方式3 - 系统服务:${NC}"
        echo -e "    sudo systemctl start $SERVICE_NAME"
        echo
    fi
    
    echo -e "${WHITE}管理命令:${NC}"
    echo -e "  停止服务: ${CYAN}./stop.sh${NC}"
    echo -e "  查看日志: ${CYAN}tail -f logs/app.log${NC}"
    echo -e "  更新项目: ${CYAN}git pull${NC}"
    echo
    
    echo -e "${WHITE}配置文件:${NC}"
    echo -e "  环境变量: ${CYAN}.env${NC}"
    echo -e "  系统服务: ${CYAN}$SERVICE_NAME.service${NC}"
    echo
    
    echo -e "${WHITE}故障排除:${NC}"
    echo -e "  查看帮助: ${CYAN}python run.py --help${NC}"
    echo -e "  防火墙配置: ${CYAN}python run.py --help-firewall${NC}"
    echo -e "  测试OCR引擎: ${CYAN}python -c \"from app import ocr_manager; print(ocr_manager.get_available_engines())\"${NC}"
    echo
    
    echo -e "${GREEN}🎉 享受使用PDF-Craft WebUI！${NC}"
    echo
}

# 主安装流程
main() {
    show_banner
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要使用root用户运行此脚本"
        exit 1
    fi
    
    # 检查sudo权限
    if ! sudo -n true 2>/dev/null; then
        log_info "此脚本需要sudo权限来安装系统依赖"
        sudo -v
    fi
    
    # 执行安装步骤
    check_system
    check_network
    update_system
    install_system_dependencies
    check_gpu
    create_project_directory
    clone_project
    create_virtual_environment
    install_python_dependencies
    install_ocr_engines
    create_config_files
    create_directories
    test_installation
    configure_firewall
    install_systemd_service
    show_completion_info
    
    # 询问是否立即启动
    echo
    read -p "是否立即启动服务? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cd "$PROJECT_DIR"
        log_info "启动服务..."
        if [[ -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
            sudo systemctl start "$SERVICE_NAME"
            log_success "服务已启动，访问 http://localhost:$DEFAULT_PORT"
        else
            ./start.sh &
            log_success "服务已在后台启动，访问 http://localhost:$DEFAULT_PORT"
        fi
    fi
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@" 