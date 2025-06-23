#!/bin/bash

# 强力停止PDF OCR WebUI服务脚本
# 能够处理各种顽固进程和停止失败的情况

set -e

# 配置
SERVICE_NAME="pdf-ocr-webui.service"
MONITOR_SERVICE_NAME="pdf-ocr-webui-monitor.service"
APP_NAME="pdf-ocr-webui"
PROCESS_NAMES=("run.py" "app.py" "python.*run.py" "python.*app.py")
PORTS=(5000)

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
    echo "║                  强力停止PDF OCR WebUI服务                   ║"
    echo "║                                                              ║"
    echo "║  🛑 停止systemd服务                                          ║"
    echo "║  🔍 查找并终止相关进程                                        ║"
    echo "║  🌐 释放占用的端口                                            ║"
    echo "║  🧹 清理临时文件                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# 停止systemd服务
stop_systemd_services() {
    print_message $BLUE "停止systemd服务..."
    
    # 停止主服务
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_message $BLUE "停止主服务: $SERVICE_NAME"
        sudo systemctl stop "$SERVICE_NAME" || {
            print_message $YELLOW "正常停止失败，尝试强制停止..."
            sudo systemctl kill --signal=SIGKILL "$SERVICE_NAME" 2>/dev/null || true
            sleep 2
        }
    else
        print_message $GREEN "主服务已停止: $SERVICE_NAME"
    fi
    
    # 停止监控服务
    if systemctl is-active --quiet "$MONITOR_SERVICE_NAME" 2>/dev/null; then
        print_message $BLUE "停止监控服务: $MONITOR_SERVICE_NAME"
        sudo systemctl stop "$MONITOR_SERVICE_NAME" || {
            print_message $YELLOW "监控服务停止失败，尝试强制停止..."
            sudo systemctl kill --signal=SIGKILL "$MONITOR_SERVICE_NAME" 2>/dev/null || true
            sleep 2
        }
    else
        print_message $GREEN "监控服务已停止: $MONITOR_SERVICE_NAME"
    fi
    
    # 等待服务完全停止
    sleep 3
}

# 查找并终止相关进程
kill_related_processes() {
    print_message $BLUE "查找并终止相关进程..."
    
    local found_processes=false
    
    # 查找Python进程
    for process_name in "${PROCESS_NAMES[@]}"; do
        local pids=$(pgrep -f "$process_name" 2>/dev/null || true)
        if [[ -n "$pids" ]]; then
            found_processes=true
            print_message $YELLOW "发现进程: $process_name (PID: $pids)"
            
            # 首先尝试优雅停止 (SIGTERM)
            for pid in $pids; do
                if kill -0 "$pid" 2>/dev/null; then
                    print_message $BLUE "尝试优雅停止进程 $pid..."
                    kill -TERM "$pid" 2>/dev/null || true
                fi
            done
            
            # 等待进程退出
            sleep 5
            
            # 检查进程是否仍在运行，如果是则强制终止
            for pid in $pids; do
                if kill -0 "$pid" 2>/dev/null; then
                    print_message $YELLOW "进程 $pid 仍在运行，强制终止..."
                    kill -KILL "$pid" 2>/dev/null || true
                fi
            done
        fi
    done
    
    # 通过端口查找进程
    for port in "${PORTS[@]}"; do
        local port_pids=$(lsof -ti :$port 2>/dev/null || true)
        if [[ -n "$port_pids" ]]; then
            found_processes=true
            print_message $YELLOW "发现占用端口 $port 的进程: $port_pids"
            
            for pid in $port_pids; do
                local process_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                print_message $BLUE "终止占用端口 $port 的进程 $pid ($process_name)..."
                
                # 首先尝试优雅停止
                kill -TERM "$pid" 2>/dev/null || true
                sleep 2
                
                # 如果仍在运行则强制终止
                if kill -0 "$pid" 2>/dev/null; then
                    print_message $YELLOW "强制终止进程 $pid..."
                    kill -KILL "$pid" 2>/dev/null || true
                fi
            done
        fi
    done
    
    if [[ "$found_processes" == false ]]; then
        print_message $GREEN "未发现相关进程"
    fi
}

# 清理临时文件和锁文件
cleanup_temp_files() {
    print_message $BLUE "清理临时文件..."
    
    # 可能的临时文件和锁文件位置
    local temp_patterns=(
        "/tmp/*pdf-ocr*"
        "/tmp/*run.py*"
        "/var/run/pdf-ocr-webui.pid"
        "/tmp/.pdf-ocr-webui*"
        "$HOME/.pdf-ocr-webui*"
    )
    
    for pattern in "${temp_patterns[@]}"; do
        if ls $pattern 2>/dev/null | head -1 | grep -q .; then
            print_message $BLUE "清理: $pattern"
            sudo rm -rf $pattern 2>/dev/null || true
        fi
    done
    
    print_message $GREEN "✅ 临时文件清理完成"
}

# 检查端口状态
check_port_status() {
    print_message $BLUE "检查端口状态..."
    
    for port in "${PORTS[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_message $RED "⚠️  端口 $port 仍被占用"
            print_message $BLUE "占用端口 $port 的进程:"
            lsof -i :$port 2>/dev/null || netstat -tulpn 2>/dev/null | grep ":$port "
        else
            print_message $GREEN "✅ 端口 $port 已释放"
        fi
    done
}

# 检查服务状态
check_service_status() {
    print_message $BLUE "检查服务状态..."
    
    # 检查主服务
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_message $RED "⚠️  主服务仍在运行: $SERVICE_NAME"
        systemctl status "$SERVICE_NAME" --no-pager -l
    else
        print_message $GREEN "✅ 主服务已停止: $SERVICE_NAME"
    fi
    
    # 检查监控服务
    if systemctl is-active --quiet "$MONITOR_SERVICE_NAME" 2>/dev/null; then
        print_message $RED "⚠️  监控服务仍在运行: $MONITOR_SERVICE_NAME"
        systemctl status "$MONITOR_SERVICE_NAME" --no-pager -l
    else
        print_message $GREEN "✅ 监控服务已停止: $MONITOR_SERVICE_NAME"
    fi
}

# 显示进程信息
show_process_info() {
    print_message $BLUE "当前相关进程信息:"
    
    echo "Python进程:"
    ps aux | grep -E "(python.*run\.py|python.*app\.py)" | grep -v grep || echo "  无相关Python进程"
    
    echo ""
    echo "端口占用情况:"
    for port in "${PORTS[@]}"; do
        echo "端口 $port:"
        lsof -i :$port 2>/dev/null || echo "  端口 $port 未被占用"
    done
}

# 主函数
main() {
    print_banner
    
    print_message $BLUE "开始强力停止PDF OCR WebUI服务..."
    
    # 显示当前状态
    show_process_info
    
    # 停止systemd服务
    stop_systemd_services
    
    # 终止相关进程
    kill_related_processes
    
    # 清理临时文件
    cleanup_temp_files
    
    # 等待系统稳定
    print_message $BLUE "等待系统稳定..."
    sleep 3
    
    # 检查最终状态
    print_message $GREEN "🎉 停止操作完成！"
    echo ""
    print_message $BLUE "最终状态检查:"
    check_service_status
    check_port_status
    
    echo ""
    print_message $GREEN "✅ PDF OCR WebUI服务已完全停止"
    print_message $BLUE "如需重新启动，请运行: ./service_start.sh"
}

# 处理中断信号
trap 'print_message $YELLOW "操作被中断"; exit 1' SIGINT SIGTERM

# 检查是否有必要的命令
check_commands() {
    local missing_commands=()
    
    for cmd in systemctl pgrep lsof netstat ps; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_message $RED "错误: 缺少必要的命令: ${missing_commands[*]}"
        print_message $YELLOW "请安装: sudo apt install procps net-tools lsof"
        exit 1
    fi
}

# 运行前检查
check_commands

# 运行主函数
main "$@" 