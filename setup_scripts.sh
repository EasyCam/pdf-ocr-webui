#!/bin/bash

# 设置所有Ubuntu服务脚本的执行权限
# 并验证脚本完整性

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
    echo "║              Ubuntu服务脚本设置工具                          ║"
    echo "║                                                              ║"
    echo "║  🔧 设置脚本执行权限                                          ║"
    echo "║  ✅ 验证脚本完整性                                            ║"
    echo "║  📋 显示使用说明                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# 需要设置执行权限的脚本列表
SCRIPTS=(
    "start_ubuntu_service.sh"
    "force_stop_service.sh"
    "diagnose_service.sh"
    "install_ocr_ubuntu.sh"
    "quick_fix_ocr.sh"
    "test_script_syntax.sh"
)

# 检查脚本是否存在并设置权限
setup_script_permissions() {
    print_message $BLUE "设置脚本执行权限..."
    echo ""
    
    local missing_scripts=()
    local setup_count=0
    
    for script in "${SCRIPTS[@]}"; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
            print_message $GREEN "✅ $script - 权限已设置"
            ((setup_count++))
        else
            missing_scripts+=("$script")
            print_message $RED "❌ $script - 文件不存在"
        fi
    done
    
    echo ""
    print_message $BLUE "权限设置完成: $setup_count/${#SCRIPTS[@]} 个脚本"
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        print_message $YELLOW "缺少的脚本:"
        for script in "${missing_scripts[@]}"; do
            echo "  - $script"
        done
    fi
}

# 验证脚本语法
verify_script_syntax() {
    print_message $BLUE "验证脚本语法..."
    echo ""
    
    local syntax_errors=0
    
    for script in "${SCRIPTS[@]}"; do
        if [[ -f "$script" ]]; then
            if bash -n "$script" 2>/dev/null; then
                print_message $GREEN "✅ $script - 语法正确"
            else
                print_message $RED "❌ $script - 语法错误"
                echo "   错误详情:"
                bash -n "$script" 2>&1 | sed 's/^/     /'
                ((syntax_errors++))
            fi
        fi
    done
    
    echo ""
    if [[ $syntax_errors -eq 0 ]]; then
        print_message $GREEN "🎉 所有脚本语法检查通过！"
    else
        print_message $RED "⚠️  发现 $syntax_errors 个脚本有语法错误"
    fi
}

# 显示脚本信息
show_script_info() {
    print_message $BLUE "脚本信息概览..."
    echo ""
    
    for script in "${SCRIPTS[@]}"; do
        if [[ -f "$script" ]]; then
            local size=$(ls -lh "$script" | awk '{print $5}')
            local lines=$(wc -l < "$script")
            local executable=""
            
            if [[ -x "$script" ]]; then
                executable="🟢"
            else
                executable="🔴"
            fi
            
            echo "$executable $script ($size, $lines 行)"
        else
            echo "❌ $script (不存在)"
        fi
    done
}

# 创建快速访问脚本
create_quick_access() {
    print_message $BLUE "创建快速访问脚本..."
    
    # 创建一键安装脚本
    cat > "install_all.sh" << 'EOF'
#!/bin/bash
echo "🚀 一键安装PDF OCR WebUI服务..."
echo ""

# 1. 设置脚本权限
if [[ -f "setup_scripts.sh" ]]; then
    chmod +x setup_scripts.sh
    ./setup_scripts.sh
fi

# 2. 安装服务
if [[ -f "start_ubuntu_service.sh" ]]; then
    ./start_ubuntu_service.sh install
else
    echo "❌ 安装脚本不存在"
    exit 1
fi
EOF
    
    # 创建一键停止脚本
    cat > "stop_all.sh" << 'EOF'
#!/bin/bash
echo "🛑 一键停止PDF OCR WebUI服务..."
echo ""

# 1. 尝试诊断
if [[ -f "diagnose_service.sh" ]]; then
    echo "📊 当前服务状态:"
    ./diagnose_service.sh
    echo ""
fi

# 2. 强力停止
if [[ -f "force_stop_service.sh" ]]; then
    echo "🔨 执行强力停止..."
    ./force_stop_service.sh
else
    echo "❌ 强力停止脚本不存在"
    exit 1
fi
EOF
    
    # 创建一键重启脚本
    cat > "restart_all.sh" << 'EOF'
#!/bin/bash
echo "🔄 一键重启PDF OCR WebUI服务..."
echo ""

# 1. 停止服务
if [[ -f "stop_all.sh" ]]; then
    ./stop_all.sh
else
    echo "🛑 手动停止服务..."
    if [[ -f "force_stop_service.sh" ]]; then
        ./force_stop_service.sh
    fi
fi

echo ""
echo "⏳ 等待5秒..."
sleep 5

# 2. 启动服务
if [[ -f "service_start.sh" ]]; then
    echo "🚀 启动服务..."
    ./service_start.sh
else
    echo "❌ 启动脚本不存在，请先运行安装"
    echo "运行: ./install_all.sh"
fi
EOF
    
    # 设置执行权限
    chmod +x "install_all.sh"
    chmod +x "stop_all.sh"
    chmod +x "restart_all.sh"
    
    print_message $GREEN "✅ 快速访问脚本创建完成"
    echo "  - install_all.sh  (一键安装)"
    echo "  - stop_all.sh     (一键停止)"
    echo "  - restart_all.sh  (一键重启)"
}

# 显示使用说明
show_usage() {
    print_message $GREEN "🎉 脚本设置完成！"
    echo ""
    
    print_message $BLUE "📋 主要脚本说明:"
    echo ""
    echo "🔧 服务管理:"
    echo "  ./start_ubuntu_service.sh install  # 安装和配置服务"
    echo "  ./service_start.sh                 # 启动服务"
    echo "  ./service_stop.sh                  # 停止服务"
    echo "  ./force_stop_service.sh            # 强力停止服务"
    echo "  ./service_restart.sh               # 重启服务"
    echo ""
    echo "🔍 诊断和维护:"
    echo "  ./diagnose_service.sh              # 诊断服务状态"
    echo "  ./service_status.sh                # 查看服务状态"
    echo "  ./view_logs.sh                     # 查看日志"
    echo ""
    echo "🔧 OCR引擎:"
    echo "  ./install_ocr_ubuntu.sh            # 完整OCR安装"
    echo "  ./quick_fix_ocr.sh                 # 快速修复OCR"
    echo ""
    echo "⚡ 快速操作:"
    echo "  ./install_all.sh                   # 一键安装所有"
    echo "  ./stop_all.sh                      # 一键停止所有"
    echo "  ./restart_all.sh                   # 一键重启所有"
    echo ""
    
    print_message $BLUE "🚀 快速开始:"
    echo "1. 首次安装: ./install_all.sh"
    echo "2. 启动服务: ./service_start.sh"
    echo "3. 检查状态: ./diagnose_service.sh"
    echo "4. 访问界面: http://localhost:5000"
    echo ""
    
    print_message $YELLOW "💡 如果遇到问题:"
    echo "1. 诊断问题: ./diagnose_service.sh"
    echo "2. 强力停止: ./force_stop_service.sh"
    echo "3. 查看日志: ./view_logs.sh"
    echo "4. 重新安装: ./start_ubuntu_service.sh install"
}

# 主函数
main() {
    print_banner
    
    print_message $GREEN "开始设置Ubuntu服务脚本..."
    echo ""
    
    # 设置权限
    setup_script_permissions
    
    # 验证语法
    verify_script_syntax
    
    # 显示信息
    show_script_info
    
    # 创建快速访问脚本
    create_quick_access
    
    # 显示使用说明
    show_usage
}

# 运行主函数
main "$@" 