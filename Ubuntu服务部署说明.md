# PDF OCR WebUI Ubuntu 24.04 服务部署说明

## 📋 概述

这是一个专为Ubuntu 24.04设计的PDF OCR WebUI服务部署脚本，支持：

- 🚀 **后台运行**: 使用systemd管理服务
- 🔄 **自动重启**: 服务异常时自动重启
- 📝 **日志管理**: 完整的日志记录和轮转
- 🔧 **系统集成**: 开机自启动和系统服务管理
- 📊 **资源监控**: 内存和CPU使用监控
- 🛡️ **安全配置**: 最小权限原则和安全限制

## 🚀 快速开始

### 1. 下载和准备

```bash
# 确保脚本有执行权限
chmod +x start_ubuntu_service.sh

# 运行安装脚本
./start_ubuntu_service.sh install
```

### 2. 启动服务

```bash
# 启动服务并设置开机自启
./service_start.sh
```

### 3. 验证服务

```bash
# 查看服务状态
./service_status.sh

# 访问Web界面
# 浏览器打开: http://localhost:5000
```

## 📚 详细使用说明

### 安装步骤

1. **系统要求检查**
   - Ubuntu 24.04 (其他Ubuntu版本也兼容)
   - Python 3.8+
   - systemd 支持
   - 至少2GB可用内存

2. **运行安装脚本**
   ```bash
   ./start_ubuntu_service.sh install
   ```
   
   脚本会自动：
   - 检查系统要求
   - 安装Python依赖
   - 创建systemd服务文件
   - 设置日志管理
   - 创建监控脚本
   - 生成管理脚本

3. **启动服务**
   ```bash
   ./service_start.sh
   ```

### 管理命令

#### 基本管理
```bash
./service_start.sh      # 启动服务并设置开机自启
./service_stop.sh       # 停止服务
./service_restart.sh    # 重启服务
./service_status.sh     # 查看服务状态
./view_logs.sh          # 查看日志（交互式选择）
```

#### 系统命令
```bash
# 服务管理
sudo systemctl start pdf-ocr-webui.service
sudo systemctl stop pdf-ocr-webui.service
sudo systemctl restart pdf-ocr-webui.service
sudo systemctl enable pdf-ocr-webui.service    # 开机自启
sudo systemctl disable pdf-ocr-webui.service   # 禁用自启

# 查看状态
systemctl status pdf-ocr-webui.service
systemctl is-active pdf-ocr-webui.service
systemctl is-enabled pdf-ocr-webui.service
```

### 日志管理

#### 日志位置
- **应用日志**: `/var/log/pdf-ocr-webui/app.log`
- **错误日志**: `/var/log/pdf-ocr-webui/error.log`
- **监控日志**: `/var/log/pdf-ocr-webui/monitor.log`

#### 查看日志
```bash
# 实时查看应用日志
sudo tail -f /var/log/pdf-ocr-webui/app.log

# 查看最近的错误
sudo tail -n 100 /var/log/pdf-ocr-webui/error.log

# 使用交互式日志查看器
./view_logs.sh
```

#### 日志轮转
- 日志每天自动轮转
- 保留30天的历史日志
- 自动压缩旧日志文件

### 监控功能

系统包含一个监控服务(`pdf-ocr-webui-monitor.service`)，会：

- **服务状态检查**: 每60秒检查一次服务状态
- **资源监控**: 监控内存和CPU使用
- **自动重启**: 服务异常时自动重启
- **端口检查**: 确保端口5000正常监听

#### 监控配置
可以编辑 `monitor_service.sh` 调整监控参数：
```bash
CHECK_INTERVAL=60        # 检查间隔（秒）
MAX_MEMORY_MB=4096      # 最大内存使用（MB）
MAX_CPU_PERCENT=90      # 最大CPU使用率（%）
```

### 访问配置

#### 本地访问
- URL: `http://localhost:5000`

#### 局域网访问
- URL: `http://[服务器IP]:5000`
- 确保防火墙允许5000端口

#### 外网访问配置
1. **防火墙配置**
   ```bash
   # Ubuntu UFW防火墙
   sudo ufw allow 5000/tcp
   sudo ufw reload
   
   # 或使用iptables
   sudo iptables -A INPUT -p tcp --dport 5000 -j ACCEPT
   ```

2. **路由器端口转发**
   - 登录路由器管理界面
   - 设置端口转发：外部端口5000 -> 内部IP:5000

## 🔧 高级配置

### 服务配置文件

systemd服务文件位置：`/etc/systemd/system/pdf-ocr-webui.service`

#### 主要配置项
```ini
[Service]
# 重启策略
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3

# 资源限制
MemoryMax=4G
LimitNOFILE=65536

# 安全配置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
```

### 修改端口

如需修改默认端口5000：

1. 编辑服务文件：
   ```bash
   sudo systemctl edit pdf-ocr-webui.service
   ```

2. 添加覆盖配置：
   ```ini
   [Service]
   ExecStart=
   ExecStart=/usr/bin/python3 /path/to/your/project/run.py --host 0.0.0.0 --port 8080
   ```

3. 重新加载并重启：
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart pdf-ocr-webui.service
   ```

### 环境变量

可以在服务文件中添加环境变量：
```ini
[Service]
Environment=CUDA_VISIBLE_DEVICES=0
Environment=OMP_NUM_THREADS=4
```

## 🛠️ 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 查看详细错误信息
sudo journalctl -u pdf-ocr-webui.service -f

# 检查Python依赖
pip3 list | grep -E "(flask|pdf-craft)"

# 手动测试启动
cd /path/to/project
python3 run.py
```

#### 2. 端口被占用
```bash
# 查看端口占用
sudo netstat -tulpn | grep :5000
sudo lsof -i :5000

# 修改端口或停止占用进程
sudo kill -9 <PID>
```

#### 3. 权限问题
```bash
# 检查文件权限
ls -la /var/log/pdf-ocr-webui/
ls -la /path/to/project/

# 修复权限
sudo chown -R $USER:$USER /var/log/pdf-ocr-webui/
chmod +x *.sh
```

#### 4. 内存不足
```bash
# 查看内存使用
free -h
ps aux --sort=-%mem | head

# 调整内存限制
sudo systemctl edit pdf-ocr-webui.service
# 添加: MemoryMax=2G
```

### 日志分析

#### 查看启动错误
```bash
sudo journalctl -u pdf-ocr-webui.service --since "1 hour ago"
```

#### 查看性能问题
```bash
# CPU使用情况
top -p $(pgrep -f "run.py")

# 内存使用情况
ps -o pid,ppid,cmd,%mem,%cpu -p $(pgrep -f "run.py")
```

## 🗑️ 卸载

完全卸载服务：
```bash
./start_ubuntu_service.sh uninstall
```

这会：
- 停止并禁用服务
- 删除systemd服务文件
- 删除日志轮转配置
- 保留应用文件和日志

## 📞 支持

如果遇到问题：

1. 查看日志文件获取错误信息
2. 检查系统资源使用情况
3. 验证网络和防火墙配置
4. 确保所有依赖正确安装

## 🔒 安全建议

1. **网络安全**
   - 使用防火墙限制访问
   - 考虑使用反向代理(nginx)
   - 启用HTTPS(可选)

2. **系统安全**
   - 定期更新系统和依赖
   - 监控日志异常访问
   - 使用非root用户运行服务

3. **访问控制**
   - 限制局域网访问
   - 使用VPN进行远程访问
   - 定期检查访问日志
``` 