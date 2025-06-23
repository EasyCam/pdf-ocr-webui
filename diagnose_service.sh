#!/bin/bash

# PDF OCR WebUI 服务诊断脚本
# 快速诊断服务状态和常见问题

# 配置
SERVICE_NAME="pdf-ocr-webui.service"
MONITOR_SERVICE_NAME="pdf-ocr-webui-monitor.service"
APP_NAME="pdf-ocr-webui"
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
    echo "║              PDF OCR WebUI 服务诊断工具                      ║"
    echo "║                                                              ║"
    echo "║  🔍 检查服务状态                                              ║"
    echo "║  🌐 检查端口占用                                              ║"
    echo "║  📋 显示进程信息                                              ║"
    echo "║  💡 提供解决建议                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# 检查systemd服务状态
check_systemd_status() {
    print_message $BLUE "📋 检查systemd服务状态..."
    echo ""
    
    # 检查主服务
    echo "主服务状态 ($SERVICE_NAME):"
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_message $GREEN "  ✅ 运行中"
        echo "  启动时间: $(systemctl show -p ActiveEnterTimestamp --value $SERVICE_NAME)"
        echo "  主进程PID: $(systemctl show -p MainPID --value $SERVICE_NAME)"
    else
        print_message $RED "  ❌ 未运行"
        if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
            print_message $BLUE "  📌 已设置开机自启"
        else
            print_message $YELLOW "  ⚠️  未设置开机自启"
        fi
    fi
    
    # 检查监控服务
    echo ""
    echo "监控服务状态 ($MONITOR_SERVICE_NAME):"
    if systemctl is-active --quiet "$MONITOR_SERVICE_NAME" 2>/dev/null; then
        print_message $GREEN "  ✅ 运行中"
    else
        print_message $YELLOW "  ⚠️  未运行或不存在"
    fi
}

# 检查进程信息
check_processes() {
    print_message $BLUE "🔍 检查相关进程..."
    echo ""
    
    # Python进程
    echo "Python相关进程:"
    local python_procs=$(ps aux | grep -E "(python.*run\.py|python.*app\.py)" | grep -v grep)
    if [[ -n "$python_procs" ]]; then
        echo "$python_procs"
    else
        print_message $YELLOW "  未发现Python相关进程"
    fi
    
    echo ""
    
    # 所有PDF OCR相关进程
    echo "PDF OCR相关进程:"
    local ocr_procs=$(ps aux | grep -i "pdf.*ocr\|ocr.*pdf" | grep -v grep)
    if [[ -n "$ocr_procs" ]]; then
        echo "$ocr_procs"
    else
        print_message $YELLOW "  未发现PDF OCR相关进程"
    fi
}

# 检查端口状态
check_ports() {
    print_message $BLUE "🌐 检查端口状态..."
    echo ""
    
    for port in "${PORTS[@]}"; do
        echo "端口 $port 状态:"
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_message $GREEN "  ✅ 端口 $port 正在监听"
            
            # 显示占用进程
            local port_info=$(lsof -i :$port 2>/dev/null)
            if [[ -n "$port_info" ]]; then
                echo "  占用进程:"
                echo "$port_info" | tail -n +2 | while read line; do
                    echo "    $line"
                done
            fi
        else
            print_message $RED "  ❌ 端口 $port 未被监听"
        fi
        echo ""
    done
}

# 检查日志
check_logs() {
    print_message $BLUE "📝 检查最近日志..."
    echo ""
    
    local log_dir="/var/log/$APP_NAME"
    
    if [[ -d "$log_dir" ]]; then
        echo "日志目录: $log_dir"
        
        # 检查应用日志
        if [[ -f "$log_dir/app.log" ]]; then
            echo ""
            echo "最近应用日志 (最后10行):"
            sudo tail -n 10 "$log_dir/app.log" 2>/dev/null || echo "  无法读取应用日志"
        fi
        
        # 检查错误日志
        if [[ -f "$log_dir/error.log" ]]; then
            echo ""
            echo "最近错误日志 (最后5行):"
            sudo tail -n 5 "$log_dir/error.log" 2>/dev/null || echo "  无法读取错误日志"
        fi
    else
        print_message $YELLOW "  日志目录不存在: $log_dir"
    fi
    
    # 检查systemd日志
    echo ""
    echo "systemd服务日志 (最后5行):"
    sudo journalctl -u "$SERVICE_NAME" -n 5 --no-pager 2>/dev/null || echo "  无法读取systemd日志"
}

# 检查系统资源
check_resources() {
    print_message $BLUE "💻 检查系统资源..."
    echo ""
    
    # 内存使用
    echo "内存使用情况:"
    free -h
    
    echo ""
    
    # 磁盘使用
    echo "磁盘使用情况:"
    df -h | head -5
    
    echo ""
    
    # CPU负载
    echo "CPU负载:"
    uptime
}

# 检查网络连接
check_network() {
    print_message $BLUE "🌍 检查网络连接..."
    echo ""
    
    # 检查本地连接
    echo "本地连接测试:"
    if curl -s --connect-timeout 5 http://localhost:5000 >/dev/null 2>&1; then
        print_message $GREEN "  ✅ 本地连接正常 (http://localhost:5000)"
    else
        print_message $RED "  ❌ 本地连接失败"
    fi
    
    # 检查防火墙状态
    echo ""
    echo "防火墙状态:"
    if command -v ufw >/dev/null 2>&1; then
        local ufw_status=$(sudo ufw status 2>/dev/null | head -1)
        echo "  UFW: $ufw_status"
    else
        echo "  UFW: 未安装"
    fi
}

# 提供解决建议
provide_suggestions() {
    print_message $BLUE "💡 解决建议..."
    echo ""
    
    # 检查服务是否运行
    if ! systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_message $YELLOW "🔧 服务未运行，建议操作:"
        echo "  1. 启动服务: ./service_start.sh"
        echo "  2. 查看启动错误: sudo journalctl -u $SERVICE_NAME -f"
        echo "  3. 检查配置文件: ls -la /etc/systemd/system/$SERVICE_NAME"
        echo ""
    fi
    
    # 检查端口是否被占用
    local port_occupied=false
    for port in "${PORTS[@]}"; do
        if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
            port_occupied=true
            break
        fi
    done
    
    if $port_occupied; then
        print_message $YELLOW "🌐 端口问题，建议操作:"
        echo "  1. 强力停止服务: ./force_stop_service.sh"
        echo "  2. 检查端口占用: lsof -i :5000"
        echo "  3. 重启服务: ./service_restart.sh"
        echo ""
    fi
    
    # 通用建议
    print_message $BLUE "📋 常用操作命令:"
    echo "  启动服务:     ./service_start.sh"
    echo "  停止服务:     ./service_stop.sh"
    echo "  强力停止:     ./force_stop_service.sh"
    echo "  重启服务:     ./service_restart.sh"
    echo "  查看状态:     ./service_status.sh"
    echo "  查看日志:     ./view_logs.sh"
    echo "  诊断服务:     ./diagnose_service.sh"
}

# 主函数
main() {
    print_banner
    
    print_message $GREEN "开始诊断PDF OCR WebUI服务..."
    echo ""
    
    # 执行各项检查
    check_systemd_status
    echo ""
    
    check_processes
    echo ""
    
    check_ports
    echo ""
    
    check_logs
    echo ""
    
    check_resources
    echo ""
    
    check_network
    echo ""
    
    provide_suggestions
    
    print_message $GREEN "🎉 诊断完成！"
    print_message $BLUE "如需更多帮助，请查看日志或运行相应的管理脚本。"
}

# 运行主函数
main "$@" 