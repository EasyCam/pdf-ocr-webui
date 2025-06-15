#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PDF OCR 统一启动脚本
支持多种运行模式，包括外网访问
"""

import os
import sys
import platform
import logging
import argparse
import socket
from pathlib import Path

# 添加当前目录到Python路径
sys.path.insert(0, str(Path(__file__).parent))

from app import app

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def print_banner():
    """打印启动横幅"""
    banner = """
    ╔══════════════════════════════════════════════════════════════╗
    ║                    基于光学字符识别和本地大语言模型的文档转换平台                      ║
    ║                                                              ║
    ║  📄 支持中文文件名处理                                        ║
    ║  🚀 多种运行模式可选                                          ║
    ║  🌐 支持外网访问                                              ║
    ║  🎨 优化的用户界面                                            ║
    ╚══════════════════════════════════════════════════════════════╝
    """
    print(banner)

def check_dependencies():
    """检查依赖项"""
    logger.info("检查依赖项...")
    
    missing_deps = []
    
    # 检查必需的包
    required_packages = [
        ('flask', 'Flask'),
        ('pdf_craft', 'PDF-Craft'),
        ('psutil', 'psutil'),
        ('fitz', 'PyMuPDF')
    ]
    
    for package, name in required_packages:
        try:
            __import__(package)
            logger.info(f"✅ {name} 已安装")
        except ImportError:
            missing_deps.append(name)
            logger.warning(f"❌ {name} 未安装")
    
    if missing_deps:
        print(f"\n⚠️  缺少依赖项: {', '.join(missing_deps)}")
        print("请运行以下命令安装:")
        print("pip install -r requirements.txt")
        return False
    
    return True



def check_port_available(host, port):
    """检查端口是否可用"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        result = s.connect_ex((host, port))
        s.close()
        return result != 0
    except Exception:
        return False

def check_system_info():
    """检查系统信息"""
    print(f"\n📊 系统信息:")
    print(f"  操作系统: {platform.system()} {platform.release()} ({platform.architecture()[0]})")
    print(f"  Python版本: {platform.python_version()}")
    
    # 检查GPU
    try:
        import torch
        if torch.cuda.is_available():
            device_count = torch.cuda.device_count()
            device_name = torch.cuda.get_device_name(0) if device_count > 0 else "Unknown"
            memory_gb = torch.cuda.get_device_properties(0).total_memory / 1024**3 if device_count > 0 else 0
            print(f"  GPU状态: 可用 ({device_count} 个设备, {device_name}, {memory_gb:.1f}GB)")
        else:
            print(f"  GPU状态: 不可用 (CUDA未启用)")
    except ImportError:
        print(f"  GPU状态: 不可用 (PyTorch未安装)")
    
    # 检查内存
    try:
        import psutil
        memory = psutil.virtual_memory()
        print(f"  系统内存: {memory.total / 1024**3:.1f}GB (可用: {memory.available / 1024**3:.1f}GB)")
    except:
        pass
    
    # 检查CPU
    cpu_count = os.cpu_count() or 1
    print(f"  CPU核心数: {cpu_count}")

def setup_directories():
    """设置必要的目录"""
    directories = [
        app.config['UPLOAD_FOLDER'],
        app.config['RESULTS_FOLDER'],
        app.config['MODEL_DIR']
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
    
    print(f"\n📂 目录配置:")
    print(f"  模型目录: {app.config['MODEL_DIR']}")
    print(f"  上传目录: {app.config['UPLOAD_FOLDER']}")
    print(f"  结果目录: {app.config['RESULTS_FOLDER']}")

def show_firewall_help(port):
    """显示防火墙配置帮助"""
    help_text = f"""
🔥 防火墙和网络配置指南:

Windows防火墙配置:
1. 打开"Windows Defender 防火墙"
2. 点击"高级设置"
3. 选择"入站规则" -> "新建规则"
4. 选择"端口" -> "TCP" -> 输入端口号 {port}
5. 选择"允许连接"
6. 应用到所有配置文件
7. 给规则命名，如"PDF-Craft WebUI"

路由器端口转发配置:
1. 登录路由器管理界面
2. 找到"端口转发"或"虚拟服务器"设置
3. 添加新规则:
   - 服务名称: PDF-Craft WebUI
   - 外部端口: {port}
   - 内部端口: {port}
   - 内部IP: [您的内网IP地址]
   - 协议: TCP
4. 保存并重启路由器

🔒 安全建议:
1. 使用强密码保护路由器管理界面
2. 定期更新路由器固件
3. 考虑使用VPN访问而不是直接暴露端口
4. 启用访问日志监控异常访问
5. 定期检查和更新应用程序
6. 建议在生产环境中添加访问控制
"""
    print(help_text)

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='基于光学字符识别和本地大语言模型的文档转换平台')
    parser.add_argument('--host', default='0.0.0.0', help='服务器地址 (默认: 0.0.0.0，支持外网访问)')
    parser.add_argument('--port', type=int, default=5000, help='服务器端口 (默认: 5000)')
    parser.add_argument('--debug', action='store_true', help='启用调试模式')
    parser.add_argument('--local-only', action='store_true', help='仅本地访问模式 (host=127.0.0.1)')
    parser.add_argument('--help-firewall', action='store_true', help='显示防火墙配置帮助')
    
    args = parser.parse_args()
    
    # 如果请求防火墙帮助
    if args.help_firewall:
        show_firewall_help(args.port)
        return
    
    # 如果是仅本地模式，修改host
    if args.local_only:
        args.host = '127.0.0.1'
    
    # 打印启动横幅
    print_banner()
    
    # 检查依赖项
    if not check_dependencies():
        sys.exit(1)
    
    # 检查系统信息
    check_system_info()
    
    # 设置目录
    setup_directories()
    
    # 检查端口可用性
    if not check_port_available('0.0.0.0', args.port):
        logger.warning(f"端口 {args.port} 可能已被占用")
        for test_port in range(args.port + 1, args.port + 10):
            if check_port_available('0.0.0.0', test_port):
                args.port = test_port
                logger.info(f"使用替代端口: {args.port}")
                break
        else:
            logger.error("无法找到可用端口")
            sys.exit(1)
    
    # 设置默认配置（兼容模式）
    app.config['ENABLE_MULTIPROCESSING'] = False  # 默认禁用多进程
    app.config['PRELOAD_MODELS'] = False  # 默认禁用模型预加载
    app.config['USE_GPU'] = False  # 默认使用CPU
    
    print("\n⚙️  默认配置:")
    print("  运行模式: 兼容模式（可在页面中更改）")
    print("  GPU加速: 默认禁用（可在页面中启用）")
    print("  多进程: 默认禁用（可在页面中启用）")
    
    # 显示访问信息
    print(f"\n🚀 启动OCR服务...")
    print(f"   本地访问: http://localhost:{args.port}")
    print(f"   局域网访问: http://[您的内网IP]:{args.port}")
    if args.host == '0.0.0.0':
        print(f"   外网访问: http://[您的公网IP]:{args.port}")
        print(f"   绑定地址: {args.host} (所有网卡)")
        print("\n🌐 外网访问提示:")
        print("   1. 确保防火墙允许该端口")
        print("   2. 路由器需要设置端口转发")
        print(f"   3. 运行 'python run.py --help-firewall' 查看详细配置")
        print("   4. 服务器已绑定到所有网卡，支持任意IP访问")
    print(f"   调试模式: {'开启' if args.debug else '关闭'}")
    print("\n按 Ctrl+C 停止服务")
    print("=" * 60)
    
    try:
        app.run(
            host=args.host,
            port=args.port,
            debug=args.debug,
            threaded=True
        )
    except KeyboardInterrupt:
        print("\n\n👋 服务已停止")
        logger.info("应用正常退出")
    except Exception as e:
        logger.error(f"应用启动失败: {str(e)}")
        print(f"\n❌ 启动失败: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    main()