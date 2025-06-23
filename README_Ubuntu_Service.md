# Ubuntu 24.04 服务部署文件

## 📁 新增文件说明

### 1. `start_ubuntu_service.sh` - 主要部署脚本
- **功能**: Ubuntu 24.04 服务部署和管理的主脚本
- **特性**: 
  - 自动安装依赖
  - 创建systemd服务
  - 配置日志管理
  - 设置监控服务
  - 生成管理脚本

### 2. `Ubuntu服务部署说明.md` - 详细文档
- **功能**: 完整的部署和使用说明文档
- **内容**:
  - 快速开始指南
  - 详细安装步骤
  - 管理命令说明
  - 故障排除指南
  - 安全配置建议

### 3. `test_script_syntax.sh` - 语法检查工具
- **功能**: 验证脚本语法正确性
- **用途**: 在部署前检查脚本是否有语法错误

## 🚀 快速使用

### 在Ubuntu 24.04系统中：

```bash
# 1. 设置执行权限
chmod +x start_ubuntu_service.sh

# 2. 安装和配置服务
./start_ubuntu_service.sh install

# 3. 启动服务
./service_start.sh

# 4. 检查服务状态
./service_status.sh
```

## ✨ 主要特性

- 🔄 **自动重启**: 服务异常时自动重启
- 📝 **日志管理**: 完整的日志记录和自动轮转
- 🔧 **系统集成**: 使用systemd管理，支持开机自启
- 📊 **资源监控**: 内存和CPU使用监控
- 🛡️ **安全配置**: 最小权限原则运行
- 🌐 **网络访问**: 支持本地、局域网和外网访问

## 📋 生成的管理脚本

部署完成后会自动生成以下管理脚本：

- `service_start.sh` - 启动服务
- `service_stop.sh` - 停止服务  
- `service_restart.sh` - 重启服务
- `service_status.sh` - 查看状态
- `view_logs.sh` - 查看日志
- `monitor_service.sh` - 监控脚本

## 🔗 访问地址

- **本地访问**: http://localhost:5000
- **局域网访问**: http://[服务器IP]:5000

## 📞 支持

详细使用说明请参考 `Ubuntu服务部署说明.md` 文档。 