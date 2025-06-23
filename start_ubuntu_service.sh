#!/bin/bash

# PDF OCR WebUI Ubuntu 24.04 服务启动脚本
# 支持后台运行、自动重启、日志管理

set -e

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="pdf-ocr-webui"
SERVICE_NAME="${APP_NAME}.service"
USER_NAME=$(whoami)
PYTHON_BIN="python3"
LOG_DIR="/var/log/${APP_NAME}"
PID_FILE="/var/run/${APP_NAME}.pid"

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

# 打印启动横幅
print_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           PDF OCR WebUI Ubuntu 24.04 服务管理脚本            ║"
    echo "║                                                              ║"
    echo "║  🚀 支持后台运行                                              ║"
    echo "║  🔄 自动重启机制                                              ║"
    echo "║  📝 完整日志管理                                              ║"
    echo "║  🔧 系统服务集成                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_message $RED "错误: 请不要使用root用户运行此脚本"
        print_message $YELLOW "建议: 使用普通用户运行，脚本会在需要时请求sudo权限"
        exit 1
    fi
}

# 检查系统要求
check_system_requirements() {
    print_message $BLUE "检查系统要求..."
    
    # 检查Ubuntu版本
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_message $YELLOW "警告: 此脚本专为Ubuntu设计，当前系统可能不完全兼容"
    fi
    
    # 检查systemd
    if ! command -v systemctl &> /dev/null; then
        print_message $RED "错误: 系统不支持systemd"
        exit 1
    fi
    
    # 检查Python
    if ! command -v $PYTHON_BIN &> /dev/null; then
        print_message $RED "错误: 未找到Python3"
        print_message $YELLOW "请安装Python3: sudo apt update && sudo apt install python3 python3-pip"
        exit 1
    fi
    
    # 检查pip
    if ! command -v pip3 &> /dev/null; then
        print_message $YELLOW "警告: 未找到pip3，正在安装..."
        sudo apt update && sudo apt install python3-pip -y
    fi
    
    print_message $GREEN "✅ 系统要求检查通过"
}

# 安装Python依赖
install_dependencies() {
    print_message $BLUE "检查并安装Python依赖..."
    
    if [[ -f "${SCRIPT_DIR}/requirements.txt" ]]; then
        print_message $BLUE "安装requirements.txt中的依赖..."
        pip3 install -r "${SCRIPT_DIR}/requirements.txt" --user
    else
        print_message $YELLOW "未找到requirements.txt，跳过依赖安装"
    fi
    
    print_message $GREEN "✅ 依赖安装完成"
}

# 安装OCR引擎
install_ocr_engines() {
    print_message $BLUE "检查并安装OCR引擎..."
    
    # 询问是否安装OCR引擎
    read -p "是否安装OCR引擎 (Tesseract + EasyOCR)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f "${SCRIPT_DIR}/quick_fix_ocr.sh" ]]; then
            print_message $BLUE "运行OCR引擎快速安装脚本..."
            chmod +x "${SCRIPT_DIR}/quick_fix_ocr.sh"
            bash "${SCRIPT_DIR}/quick_fix_ocr.sh"
        else
            print_message $BLUE "手动安装基本OCR引擎..."
            # 安装Tesseract
            sudo apt install -y tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra tesseract-ocr-eng
            # 安装Python OCR包
            pip3 install --user pytesseract Pillow opencv-python numpy easyocr
        fi
        print_message $GREEN "✅ OCR引擎安装完成"
    else
        print_message $YELLOW "跳过OCR引擎安装"
    fi
}

# 创建日志目录
setup_logging() {
    print_message $BLUE "设置日志目录..."
    
    # 创建日志目录
    if [[ ! -d "$LOG_DIR" ]]; then
        sudo mkdir -p "$LOG_DIR"
        sudo chown $USER_NAME:$USER_NAME "$LOG_DIR"
    fi
    
    # 创建logrotate配置
    sudo tee /etc/logrotate.d/${APP_NAME} > /dev/null <<EOF
${LOG_DIR}/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 ${USER_NAME} ${USER_NAME}
    postrotate
        systemctl reload ${SERVICE_NAME} > /dev/null 2>&1 || true
    endscript
}
EOF
    
    print_message $GREEN "✅ 日志目录设置完成"
}

# 创建systemd服务文件
create_systemd_service() {
    print_message $BLUE "创建systemd服务文件..."
    
    # 获取用户的Python路径
    local python_path=$(which $PYTHON_BIN)
    local user_home=$(eval echo ~$USER_NAME)
    
    # 创建服务文件
    sudo tee /etc/systemd/system/${SERVICE_NAME} > /dev/null <<EOF
[Unit]
Description=PDF OCR WebUI Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=${USER_NAME}
Group=${USER_NAME}
WorkingDirectory=${SCRIPT_DIR}
Environment=PATH=${user_home}/.local/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=${SCRIPT_DIR}
Environment=HOME=${user_home}
ExecStart=${python_path} ${SCRIPT_DIR}/run.py --host 0.0.0.0 --port 5000
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=30
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3

# 日志配置
StandardOutput=append:${LOG_DIR}/app.log
StandardError=append:${LOG_DIR}/error.log

# 安全配置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=${SCRIPT_DIR} ${LOG_DIR} /tmp

# 资源限制
LimitNOFILE=65536
MemoryMax=4G

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd配置
    sudo systemctl daemon-reload
    
    print_message $GREEN "✅ systemd服务文件创建完成"
}

# 创建监控脚本
create_monitor_script() {
    print_message $BLUE "创建服务监控脚本..."
    
    cat > "${SCRIPT_DIR}/monitor_service.sh" <<'EOF'
#!/bin/bash

# PDF OCR WebUI 服务监控脚本

SERVICE_NAME="pdf-ocr-webui.service"
LOG_FILE="/var/log/pdf-ocr-webui/monitor.log"
CHECK_INTERVAL=60  # 检查间隔（秒）
MAX_MEMORY_MB=4096  # 最大内存使用（MB）
MAX_CPU_PERCENT=90  # 最大CPU使用率（%）

# 日志函数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查服务状态
check_service_status() {
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        log_message "警告: 服务 $SERVICE_NAME 未运行，尝试重启..."
        systemctl restart "$SERVICE_NAME"
        sleep 10
        
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_message "信息: 服务 $SERVICE_NAME 重启成功"
        else
            log_message "错误: 服务 $SERVICE_NAME 重启失败"
        fi
    fi
}

# 检查资源使用
check_resource_usage() {
    local pid=$(systemctl show --property MainPID --value "$SERVICE_NAME")
    
    if [[ "$pid" != "0" ]] && [[ -n "$pid" ]]; then
        # 检查内存使用
        local memory_kb=$(ps -o rss= -p "$pid" 2>/dev/null || echo "0")
        local memory_mb=$((memory_kb / 1024))
        
        if [[ $memory_mb -gt $MAX_MEMORY_MB ]]; then
            log_message "警告: 内存使用过高 (${memory_mb}MB > ${MAX_MEMORY_MB}MB)，重启服务"
            systemctl restart "$SERVICE_NAME"
            return
        fi
        
        # 检查CPU使用
        local cpu_percent=$(ps -o %cpu= -p "$pid" 2>/dev/null | awk '{print int($1)}' || echo "0")
        
        if [[ $cpu_percent -gt $MAX_CPU_PERCENT ]]; then
            log_message "警告: CPU使用过高 (${cpu_percent}% > ${MAX_CPU_PERCENT}%)，记录状态"
        fi
        
        log_message "信息: 资源使用 - 内存: ${memory_mb}MB, CPU: ${cpu_percent}%"
    fi
}

# 检查端口可用性
check_port_availability() {
    if ! netstat -tuln | grep -q ":5000 "; then
        log_message "警告: 端口5000未监听，服务可能异常"
        systemctl restart "$SERVICE_NAME"
    fi
}

# 主监控循环
main() {
    log_message "信息: 监控脚本启动"
    
    while true; do
        check_service_status
        check_resource_usage
        check_port_availability
        sleep $CHECK_INTERVAL
    done
}

# 处理信号
trap 'log_message "信息: 监控脚本停止"; exit 0' SIGTERM SIGINT

main
EOF
    
    chmod +x "${SCRIPT_DIR}/monitor_service.sh"
    
    print_message $GREEN "✅ 监控脚本创建完成"
}

# 创建管理脚本
create_management_scripts() {
    print_message $BLUE "创建管理脚本..."
    
    # 创建启动脚本
    cat > "${SCRIPT_DIR}/service_start.sh" <<EOF
#!/bin/bash
echo "启动 PDF OCR WebUI 服务..."
sudo systemctl start ${SERVICE_NAME}
sudo systemctl enable ${SERVICE_NAME}
echo "服务已启动并设置为开机自启"
systemctl status ${SERVICE_NAME}
EOF
    
    # 创建停止脚本
    cat > "${SCRIPT_DIR}/service_stop.sh" <<EOF
#!/bin/bash
echo "停止 PDF OCR WebUI 服务..."

# 停止主服务
echo "正在停止主服务..."
if sudo systemctl stop ${SERVICE_NAME}; then
    echo "✅ 主服务停止成功"
else
    echo "⚠️  主服务停止失败，尝试强制停止..."
    sudo systemctl kill --signal=SIGKILL ${SERVICE_NAME} 2>/dev/null || true
    sleep 2
fi

# 停止监控服务
echo "正在停止监控服务..."
if sudo systemctl stop ${APP_NAME}-monitor.service 2>/dev/null; then
    echo "✅ 监控服务停止成功"
else
    echo "⚠️  监控服务停止失败或不存在"
fi

# 检查并终止残留进程
echo "检查残留进程..."
PIDS=\$(pgrep -f "run.py" 2>/dev/null || true)
if [[ -n "\$PIDS" ]]; then
    echo "发现残留进程，正在终止: \$PIDS"
    kill -TERM \$PIDS 2>/dev/null || true
    sleep 3
    # 如果仍在运行则强制终止
    PIDS=\$(pgrep -f "run.py" 2>/dev/null || true)
    if [[ -n "\$PIDS" ]]; then
        echo "强制终止残留进程: \$PIDS"
        kill -KILL \$PIDS 2>/dev/null || true
    fi
fi

# 检查端口占用
PORT_PIDS=\$(lsof -ti :5000 2>/dev/null || true)
if [[ -n "\$PORT_PIDS" ]]; then
    echo "发现占用端口5000的进程，正在终止: \$PORT_PIDS"
    kill -TERM \$PORT_PIDS 2>/dev/null || true
    sleep 2
    # 强制终止
    PORT_PIDS=\$(lsof -ti :5000 2>/dev/null || true)
    if [[ -n "\$PORT_PIDS" ]]; then
        kill -KILL \$PORT_PIDS 2>/dev/null || true
    fi
fi

echo ""
echo "🎉 服务停止完成！"
echo "最终状态:"
systemctl status ${SERVICE_NAME} --no-pager || true
EOF
    
    # 创建重启脚本
    cat > "${SCRIPT_DIR}/service_restart.sh" <<EOF
#!/bin/bash
echo "重启 PDF OCR WebUI 服务..."
sudo systemctl restart ${SERVICE_NAME}
echo "服务已重启"
systemctl status ${SERVICE_NAME}
EOF
    
    # 创建状态查看脚本
    cat > "${SCRIPT_DIR}/service_status.sh" <<EOF
#!/bin/bash
echo "PDF OCR WebUI 服务状态:"
systemctl status ${SERVICE_NAME}
echo ""
echo "最近日志:"
sudo tail -n 20 ${LOG_DIR}/app.log
EOF
    
    # 创建日志查看脚本
    cat > "${SCRIPT_DIR}/view_logs.sh" <<EOF
#!/bin/bash
echo "选择要查看的日志:"
echo "1) 应用日志 (实时)"
echo "2) 错误日志 (实时)"
echo "3) 应用日志 (最近100行)"
echo "4) 错误日志 (最近100行)"
echo "5) 监控日志"
read -p "请选择 (1-5): " choice

case \$choice in
    1) sudo tail -f ${LOG_DIR}/app.log ;;
    2) sudo tail -f ${LOG_DIR}/error.log ;;
    3) sudo tail -n 100 ${LOG_DIR}/app.log ;;
    4) sudo tail -n 100 ${LOG_DIR}/error.log ;;
    5) sudo tail -n 100 ${LOG_DIR}/monitor.log ;;
    *) echo "无效选择" ;;
esac
EOF
    
    # 复制强力停止脚本和诊断脚本
    if [[ -f "${SCRIPT_DIR}/force_stop_service.sh" ]]; then
        chmod +x "${SCRIPT_DIR}/force_stop_service.sh"
        print_message $BLUE "强力停止脚本已就绪"
    fi
    
    if [[ -f "${SCRIPT_DIR}/diagnose_service.sh" ]]; then
        chmod +x "${SCRIPT_DIR}/diagnose_service.sh"
        print_message $BLUE "诊断脚本已就绪"
    fi
    
    # 设置执行权限
    chmod +x "${SCRIPT_DIR}/service_start.sh"
    chmod +x "${SCRIPT_DIR}/service_stop.sh"
    chmod +x "${SCRIPT_DIR}/service_restart.sh"
    chmod +x "${SCRIPT_DIR}/service_status.sh"
    chmod +x "${SCRIPT_DIR}/view_logs.sh"
    
    print_message $GREEN "✅ 管理脚本创建完成"
}

# 创建监控服务
create_monitor_service() {
    print_message $BLUE "创建监控服务..."
    
    # 创建监控服务文件
    sudo tee /etc/systemd/system/${APP_NAME}-monitor.service > /dev/null <<EOF
[Unit]
Description=PDF OCR WebUI Monitor Service
After=${SERVICE_NAME}
Requires=${SERVICE_NAME}

[Service]
Type=simple
User=${USER_NAME}
Group=${USER_NAME}
WorkingDirectory=${SCRIPT_DIR}
ExecStart=${SCRIPT_DIR}/monitor_service.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    
    print_message $GREEN "✅ 监控服务创建完成"
}

# 显示使用说明
show_usage() {
    print_message $GREEN "🎉 服务配置完成！"
    echo ""
    echo "📋 管理命令:"
    echo "  启动服务:     ./service_start.sh"
    echo "  停止服务:     ./service_stop.sh"
    echo "  强力停止:     ./force_stop_service.sh"
    echo "  重启服务:     ./service_restart.sh"
    echo "  查看状态:     ./service_status.sh"
    echo "  诊断服务:     ./diagnose_service.sh"
    echo "  查看日志:     ./view_logs.sh"
    echo ""
    echo "🔧 系统命令:"
    echo "  sudo systemctl start ${SERVICE_NAME}      # 启动服务"
    echo "  sudo systemctl stop ${SERVICE_NAME}       # 停止服务"
    echo "  sudo systemctl restart ${SERVICE_NAME}    # 重启服务"
    echo "  sudo systemctl enable ${SERVICE_NAME}     # 开机自启"
    echo "  sudo systemctl disable ${SERVICE_NAME}    # 禁用自启"
    echo "  systemctl status ${SERVICE_NAME}          # 查看状态"
    echo ""
    echo "📝 日志位置:"
    echo "  应用日志:     ${LOG_DIR}/app.log"
    echo "  错误日志:     ${LOG_DIR}/error.log"
    echo "  监控日志:     ${LOG_DIR}/monitor.log"
    echo ""
    echo "🌐 访问地址:"
    echo "  本地访问:     http://localhost:5000"
    echo "  局域网访问:   http://[服务器IP]:5000"
    echo ""
    echo "⚠️  重要提示:"
    echo "  1. 服务将在系统启动时自动启动"
    echo "  2. 服务异常时会自动重启（最多3次/分钟）"
    echo "  3. 日志会自动轮转，保留30天"
    echo "  4. 监控服务会检查资源使用和服务状态"
    echo ""
    print_message $YELLOW "现在运行 './service_start.sh' 启动服务"
}

# 主函数
main() {
    print_banner
    
    # 解析命令行参数
    case "${1:-install}" in
        install)
            check_root
            check_system_requirements
            install_dependencies
            install_ocr_engines
            setup_logging
            create_systemd_service
            create_monitor_script
            create_management_scripts
            create_monitor_service
            show_usage
            ;;
        uninstall)
            print_message $BLUE "卸载服务..."
            sudo systemctl stop ${SERVICE_NAME} 2>/dev/null || true
            sudo systemctl disable ${SERVICE_NAME} 2>/dev/null || true
            sudo systemctl stop ${APP_NAME}-monitor.service 2>/dev/null || true
            sudo systemctl disable ${APP_NAME}-monitor.service 2>/dev/null || true
            sudo rm -f /etc/systemd/system/${SERVICE_NAME}
            sudo rm -f /etc/systemd/system/${APP_NAME}-monitor.service
            sudo rm -f /etc/logrotate.d/${APP_NAME}
            sudo systemctl daemon-reload
            print_message $GREEN "✅ 服务已卸载"
            ;;
        *)
            echo "用法: $0 [install|uninstall]"
            echo "  install   - 安装并配置服务（默认）"
            echo "  uninstall - 卸载服务"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@" 