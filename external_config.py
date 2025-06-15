# -*- coding: utf-8 -*-
"""
PDF-Craft WebUI 外网访问配置文件
"""

# 服务器配置
SERVER_CONFIG = {
    # 绑定地址 (0.0.0.0 表示绑定所有网络接口，支持外网访问)
    'HOST': '0.0.0.0',
    
    # 端口号
    'PORT': 5000,
    
    # 调试模式 (生产环境建议设为False)
    'DEBUG': False,
    
    # 多线程支持
    'THREADED': True,
    
    # 禁用自动重载 (外网模式建议禁用)
    'USE_RELOADER': False,
}

# 安全配置
SECURITY_CONFIG = {
    # 是否启用访问控制 (建议外网访问时启用)
    'ENABLE_ACCESS_CONTROL': False,
    
    # 允许的IP地址列表 (空列表表示允许所有IP)
    'ALLOWED_IPS': [
        # '192.168.1.0/24',  # 允许局域网
        # '10.0.0.0/8',      # 允许内网
    ],
    
    # 是否启用基本认证
    'ENABLE_BASIC_AUTH': False,
    
    # 基本认证用户名和密码
    'BASIC_AUTH_USERNAME': 'admin',
    'BASIC_AUTH_PASSWORD': 'password123',
    
    # 是否记录访问日志
    'LOG_ACCESS': True,
}

# 性能配置
PERFORMANCE_CONFIG = {
    # 最大并发连接数
    'MAX_CONNECTIONS': 100,
    
    # 请求超时时间（秒）
    'REQUEST_TIMEOUT': 300,
    
    # 文件上传大小限制（MB）
    'MAX_UPLOAD_SIZE': 100,
    
    # 是否启用压缩
    'ENABLE_COMPRESSION': True,
}

# 日志配置
LOGGING_CONFIG = {
    # 日志级别
    'LEVEL': 'INFO',
    
    # 日志文件路径
    'LOG_FILE': 'logs/external_access.log',
    
    # 是否输出到控制台
    'CONSOLE_OUTPUT': True,
    
    # 日志格式
    'FORMAT': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
}

# 防火墙配置提示
FIREWALL_HELP = """
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
   - 内部IP: {local_ip}
   - 协议: TCP
4. 保存并重启路由器

安全建议:
1. 使用强密码保护路由器管理界面
2. 定期更新路由器固件
3. 考虑使用VPN访问而不是直接暴露端口
4. 启用访问日志监控异常访问
5. 定期检查和更新应用程序
""" 