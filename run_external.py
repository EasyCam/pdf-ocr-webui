#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
外网访问启动脚本
支持从外网访问PDF-Craft WebUI
"""

import os
import sys
import socket
import logging
from pathlib import Path

# 添加当前目录到Python路径
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def get_local_ip():
    """获取本机IP地址"""
    try:
        # 连接到一个远程地址来获取本机IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

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

def main():
    """主函数"""
    print("=" * 60)
    print("PDF-Craft WebUI - 外网访问启动器")
    print("=" * 60)
    
    # 尝试加载配置文件
    try:
        from external_config import SERVER_CONFIG, SECURITY_CONFIG, FIREWALL_HELP
        config_loaded = True
    except ImportError:
        logger.warning("未找到配置文件，使用默认配置")
        SERVER_CONFIG = {
            'HOST': '0.0.0.0',
            'PORT': 5000,
            'DEBUG': False,
            'THREADED': True,
            'USE_RELOADER': False,
        }
        SECURITY_CONFIG = {'ENABLE_ACCESS_CONTROL': False}
        config_loaded = False
    
    # 获取配置参数（环境变量优先）
    host = os.environ.get('HOST', SERVER_CONFIG.get('HOST', '0.0.0.0'))
    port = int(os.environ.get('PORT', SERVER_CONFIG.get('PORT', 5000)))
    debug = os.environ.get('DEBUG', str(SERVER_CONFIG.get('DEBUG', False))).lower() == 'true'
    
    # 获取本机IP
    local_ip = get_local_ip()
    
    # 检查端口是否可用
    if not check_port_available('0.0.0.0', port):
        logger.warning(f"端口 {port} 可能已被占用")
        # 尝试其他端口
        for test_port in range(port + 1, port + 10):
            if check_port_available('0.0.0.0', test_port):
                port = test_port
                logger.info(f"使用替代端口: {port}")
                break
        else:
            logger.error("无法找到可用端口")
            return
    
    # 设置环境变量
    os.environ['HOST'] = host
    os.environ['PORT'] = str(port)
    os.environ['DEBUG'] = str(debug)
    
    print(f"启动配置:")
    print(f"  主机: {host}")
    print(f"  端口: {port}")
    print(f"  调试模式: {debug}")
    print(f"  本机IP: {local_ip}")
    print()
    
    print("访问地址:")
    print(f"  本地访问: http://127.0.0.1:{port}")
    print(f"  局域网访问: http://{local_ip}:{port}")
    print(f"  外网访问: http://[您的公网IP]:{port}")
    print()
    
    print("注意事项:")
    print("1. 确保防火墙允许该端口的入站连接")
    print("2. 如需外网访问，请在路由器中设置端口转发")
    print("3. 外网访问时请注意安全，建议设置访问控制")
    print("4. 按 Ctrl+C 停止服务器")
    print()
    
    # 显示防火墙配置帮助
    if config_loaded:
        print("需要配置防火墙和路由器？输入 'help' 查看详细说明")
        user_input = input("按回车键继续启动，或输入 'help': ").strip().lower()
        if user_input == 'help':
            print("\n" + FIREWALL_HELP.format(port=port, local_ip=local_ip))
            input("\n按回车键继续...")
            print()
    
    try:
        # 导入并启动应用
        from app import app, logger as app_logger
        
        # 配置Flask应用
        app.config['ENV'] = 'development' if debug else 'production'
        
        app_logger.info("=" * 50)
        app_logger.info("PDF-Craft WebUI 外网访问模式启动")
        app_logger.info(f"服务器地址: {host}:{port}")
        app_logger.info(f"本机IP: {local_ip}")
        app_logger.info(f"调试模式: {debug}")
        app_logger.info("=" * 50)
        
        # 启动服务器
        app.run(
            host=host,
            port=port,
            debug=debug,
            threaded=SERVER_CONFIG.get('THREADED', True),
            use_reloader=SERVER_CONFIG.get('USE_RELOADER', False)
        )
        
    except KeyboardInterrupt:
        print("\n服务器已停止")
    except Exception as e:
        logger.error(f"启动失败: {str(e)}")
        return 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main()) 