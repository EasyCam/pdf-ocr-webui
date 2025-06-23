# PDF OCR WebUI Ubuntu 服务管理完整指南

## 📋 项目概述

这是一套完整的PDF OCR WebUI Ubuntu 24.04服务管理解决方案，提供了从安装到维护的全套工具。

## 🎯 完整文件列表

### 主要脚本文件

| 脚本文件 | 功能描述 | 状态 |
|---------|---------|------|
| `setup_scripts.sh` | 设置所有脚本权限和验证 | ✅ 新增 |
| `start_ubuntu_service.sh` | 主要安装和配置脚本 | ✅ 完整 |
| `force_stop_service.sh` | 强力停止服务脚本 | ✅ 新增 |
| `diagnose_service.sh` | 服务诊断工具 | ✅ 新增 |
| `install_ocr_ubuntu.sh` | 完整OCR引擎安装 | ✅ 完整 |
| `quick_fix_ocr.sh` | 快速OCR修复 | ✅ 新增 |
| `test_script_syntax.sh` | 脚本语法检查 | ✅ 完整 |

### 自动生成的管理脚本

运行 `start_ubuntu_service.sh install` 后会自动生成：

| 脚本文件 | 功能描述 |
|---------|---------|
| `service_start.sh` | 启动服务 |
| `service_stop.sh` | 停止服务（增强版） |
| `service_restart.sh` | 重启服务 |
| `service_status.sh` | 查看服务状态 |
| `view_logs.sh` | 查看日志 |
| `monitor_service.sh` | 监控脚本 |

### 快速访问脚本

运行 `setup_scripts.sh` 后会自动生成：

| 脚本文件 | 功能描述 |
|---------|---------|
| `install_all.sh` | 一键安装所有组件 |
| `stop_all.sh` | 一键停止所有服务 |
| `restart_all.sh` | 一键重启所有服务 |

### 文档文件

| 文档文件 | 内容描述 |
|---------|---------|
| `Ubuntu服务部署说明.md` | 详细部署文档 |
| `OCR引擎安装说明.md` | OCR安装指南 |
| `服务停止问题解决方案.md` | 停止问题解决方案 |
| `README_Ubuntu_Service.md` | 快速参考 |
| `Ubuntu服务管理完整指南.md` | 本文档 |

## 🚀 快速开始

### 1. 首次使用

```bash
# 1. 设置脚本权限
chmod +x setup_scripts.sh
./setup_scripts.sh

# 2. 一键安装
./install_all.sh

# 3. 检查状态
./diagnose_service.sh
```

### 2. 日常使用

```bash
# 启动服务
./service_start.sh

# 停止服务
./service_stop.sh

# 强力停止（如果常规停止失败）
./force_stop_service.sh

# 诊断问题
./diagnose_service.sh

# 查看日志
./view_logs.sh
```

## 🔧 详细使用指南

### 安装和配置

#### 完整安装流程

1. **准备环境**：
   ```bash
   # 设置脚本权限
   ./setup_scripts.sh
   ```

2. **安装服务**：
   ```bash
   # 完整安装（推荐）
   ./install_all.sh
   
   # 或手动安装
   ./start_ubuntu_service.sh install
   ```

3. **安装OCR引擎**：
   ```bash
   # 快速修复OCR问题
   ./quick_fix_ocr.sh
   
   # 或完整安装OCR
   ./install_ocr_ubuntu.sh
   ```

#### 自定义安装

```bash
# 只安装服务（不安装OCR）
./start_ubuntu_service.sh install
# 选择 'n' 跳过OCR安装

# 单独安装OCR引擎
./install_ocr_ubuntu.sh
```

### 服务管理

#### 基本操作

```bash
# 启动服务
./service_start.sh

# 停止服务
./service_stop.sh

# 重启服务
./service_restart.sh

# 查看状态
./service_status.sh
```

#### 高级操作

```bash
# 强力停止（处理顽固进程）
./force_stop_service.sh

# 完整诊断
./diagnose_service.sh

# 一键重启所有
./restart_all.sh
```

### 问题诊断

#### 自动诊断

```bash
# 运行完整诊断
./diagnose_service.sh
```

诊断内容包括：
- systemd服务状态
- 进程信息
- 端口占用
- 日志分析
- 系统资源
- 网络连接

#### 手动诊断

```bash
# 检查服务状态
systemctl status pdf-ocr-webui.service

# 检查进程
ps aux | grep python

# 检查端口
lsof -i :5000

# 查看日志
sudo journalctl -u pdf-ocr-webui.service -n 20
```

### 日志管理

#### 查看日志

```bash
# 交互式日志查看
./view_logs.sh

# 实时应用日志
sudo tail -f /var/log/pdf-ocr-webui/app.log

# 实时错误日志
sudo tail -f /var/log/pdf-ocr-webui/error.log
```

#### 日志位置

- **应用日志**: `/var/log/pdf-ocr-webui/app.log`
- **错误日志**: `/var/log/pdf-ocr-webui/error.log`
- **监控日志**: `/var/log/pdf-ocr-webui/monitor.log`
- **系统日志**: `journalctl -u pdf-ocr-webui.service`

## 🛠️ 故障排除

### 常见问题及解决方案

#### 1. 服务无法停止

**现象**: `systemctl stop` 命令无响应

**解决方案**:
```bash
# 1. 尝试强力停止
./force_stop_service.sh

# 2. 手动终止进程
sudo pkill -f "run.py"
sudo kill -KILL $(lsof -ti :5000)
```

#### 2. OCR引擎不可用

**现象**: 界面显示 "Tesseract (不可用)" 或 "EasyOCR (不可用)"

**解决方案**:
```bash
# 1. 快速修复
./quick_fix_ocr.sh

# 2. 完整重装
./install_ocr_ubuntu.sh

# 3. 重启服务
./service_restart.sh
```

#### 3. 端口被占用

**现象**: 服务启动失败，提示端口5000被占用

**解决方案**:
```bash
# 1. 查找占用进程
lsof -i :5000

# 2. 终止占用进程
sudo kill -KILL $(lsof -ti :5000)

# 3. 重启服务
./service_restart.sh
```

#### 4. 权限问题

**现象**: 脚本无法执行或权限被拒绝

**解决方案**:
```bash
# 1. 重新设置权限
./setup_scripts.sh

# 2. 手动设置权限
chmod +x *.sh

# 3. 检查日志目录权限
sudo chown -R $USER:$USER /var/log/pdf-ocr-webui/
```

### 紧急恢复

如果所有方法都失效：

```bash
# 1. 完全停止
sudo systemctl kill --signal=SIGKILL pdf-ocr-webui.service
sudo pkill -f "python.*run.py"
sudo kill -KILL $(lsof -ti :5000)

# 2. 清理环境
sudo rm -rf /tmp/*pdf-ocr*
sudo systemctl daemon-reload

# 3. 重新安装
./start_ubuntu_service.sh uninstall
./install_all.sh

# 4. 重启系统（最后手段）
sudo reboot
```

## ⚙️ 系统配置

### systemd服务配置

服务文件位置: `/etc/systemd/system/pdf-ocr-webui.service`

主要配置项：
```ini
[Service]
Restart=always          # 自动重启
RestartSec=10           # 重启间隔
TimeoutStopSec=30       # 停止超时
MemoryMax=4G            # 内存限制
```

### 监控配置

监控脚本: `monitor_service.sh`

可调整参数：
```bash
CHECK_INTERVAL=60        # 检查间隔（秒）
MAX_MEMORY_MB=4096      # 最大内存（MB）
MAX_CPU_PERCENT=90      # 最大CPU使用率（%）
```

### 日志轮转

配置文件: `/etc/logrotate.d/pdf-ocr-webui`

- 每天轮转
- 保留30天
- 自动压缩

## 🔒 安全建议

### 网络安全

1. **防火墙配置**:
   ```bash
   sudo ufw allow 5000/tcp
   sudo ufw enable
   ```

2. **访问限制**:
   - 仅局域网访问
   - 使用VPN进行远程访问

### 系统安全

1. **用户权限**: 使用非root用户运行服务
2. **文件权限**: 限制敏感文件访问
3. **定期更新**: 保持系统和依赖更新

## 📊 性能优化

### 系统资源

- **内存**: 推荐4GB以上
- **CPU**: 多核处理器
- **存储**: SSD推荐

### 应用配置

可在Web界面中调整：
- 批处理大小
- 并发处理数
- GPU使用（如果可用）

## 🔄 维护计划

### 日常维护

```bash
# 每日检查
./diagnose_service.sh

# 查看资源使用
free -h && df -h

# 检查日志
./view_logs.sh
```

### 定期维护

```bash
# 每周重启（可选）
./restart_all.sh

# 每月清理日志
sudo journalctl --vacuum-time=30d

# 系统更新
sudo apt update && sudo apt upgrade
```

## 📞 获取帮助

### 自助诊断

1. 运行诊断脚本: `./diagnose_service.sh`
2. 查看详细日志: `./view_logs.sh`
3. 检查系统资源: `free -h && df -h`

### 问题报告

如需报告问题，请提供：
1. 诊断脚本输出
2. 相关日志信息
3. 系统信息
4. 操作步骤

## 🎉 总结

这套Ubuntu服务管理解决方案提供了：

- ✅ **完整的安装流程**
- ✅ **强力的停止机制**
- ✅ **智能的诊断工具**
- ✅ **便捷的管理脚本**
- ✅ **详细的文档支持**

现在您可以轻松地在Ubuntu 24.04上部署和管理PDF OCR WebUI服务！ 