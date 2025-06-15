# PDF-Craft WebUI 安装指南

## 📋 概述

本文档提供了PDF-Craft WebUI在Ubuntu 24.04系统上的详细安装指南，包括多种安装方式和配置选项。

## 🚀 快速安装

### 方式1：一键安装脚本

```bash
# 下载并运行完整安装脚本
wget https://raw.githubusercontent.com/EasyCam/pdf-ocr-webui/main/install_ubuntu.sh
chmod +x install_ubuntu.sh
sudo ./install_ubuntu.sh
```

### 方式2：快速安装脚本

```bash
# 下载并运行快速安装脚本
wget https://raw.githubusercontent.com/EasyCam/pdf-ocr-webui/main/quick_install.sh
chmod +x quick_install.sh
./quick_install.sh
```

### 方式3：Docker安装

```bash
# 使用Docker Compose
git clone https://github.com/EasyCam/pdf-ocr-webui.git
cd pdf-craft-webui
docker-compose up -d

# 或直接使用Docker
docker build -t pdf-craft-webui .
docker run -d -p 5000:5000 -v $(pwd)/uploads:/app/uploads pdf-craft-webui
```

## 📦 安装脚本说明

### install_ubuntu.sh - 完整安装脚本

**功能特点：**
- 完整的系统环境检查
- 自动安装所有系统依赖
- GPU支持检测和配置
- OCR引擎自动安装
- systemd服务配置
- 防火墙自动配置
- 详细的安装测试

**使用场景：**
- 生产环境部署
- 需要完整功能的安装
- 服务器环境配置

### quick_install.sh - 快速安装脚本

**功能特点：**
- 简化的安装流程
- 基础依赖快速安装
- 适合开发和测试环境
- 安装时间更短

**使用场景：**
- 开发环境搭建
- 快速测试部署
- 个人使用

## 🛠️ 手动安装步骤

### 1. 系统准备

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y git wget curl python3 python3-pip python3-venv
```

### 2. 安装系统依赖

```bash
# 安装OCR相关依赖
sudo apt install -y \
    tesseract-ocr \
    tesseract-ocr-chi-sim \
    tesseract-ocr-chi-tra \
    tesseract-ocr-jpn \
    tesseract-ocr-kor \
    libtesseract-dev

# 安装图像处理依赖
sudo apt install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    ffmpeg
```

### 3. 克隆项目

```bash
git clone https://github.com/EasyCam/pdf-ocr-webui.git
cd pdf-craft-webui
```

### 4. 创建虚拟环境

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
```

### 5. 安装Python依赖

```bash
# 安装基础依赖
pip install -r requirements.txt

# 安装PyTorch（根据需要选择CPU或GPU版本）
# CPU版本
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# GPU版本（需要CUDA）
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

### 6. 创建必要目录

```bash
mkdir -p uploads results models logs
```

### 7. 启动服务

```bash
python run.py
```

## 🐳 Docker部署

### 使用Docker Compose（推荐）

```bash
# 克隆项目
git clone https://github.com/EasyCam/pdf-ocr-webui.git
cd pdf-craft-webui

# 启动所有服务
docker-compose up -d

# 仅启动主服务
docker-compose up -d pdf-craft-webui

# 启动包含Nginx的完整服务
docker-compose --profile with-nginx up -d

# 启动包含Redis的服务
docker-compose --profile with-redis up -d
```

### 直接使用Docker

```bash
# 构建镜像
docker build -t pdf-craft-webui .

# 运行容器
docker run -d \
  --name pdf-craft-webui \
  -p 5000:5000 \
  -v $(pwd)/uploads:/app/uploads \
  -v $(pwd)/results:/app/results \
  -v $(pwd)/models:/app/models \
  pdf-craft-webui

# 查看日志
docker logs -f pdf-craft-webui

# 停止容器
docker stop pdf-craft-webui
```

## ⚙️ 系统服务配置

### 安装systemd服务

```bash
# 复制服务文件
sudo cp pdf-craft-webui.service /etc/systemd/system/

# 修改服务文件中的用户和路径
sudo nano /etc/systemd/system/pdf-craft-webui.service

# 重新加载systemd
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable pdf-craft-webui

# 启动服务
sudo systemctl start pdf-craft-webui

# 查看状态
sudo systemctl status pdf-craft-webui

# 查看日志
sudo journalctl -u pdf-craft-webui -f
```

### 服务管理命令

```bash
# 启动服务
sudo systemctl start pdf-craft-webui

# 停止服务
sudo systemctl stop pdf-craft-webui

# 重启服务
sudo systemctl restart pdf-craft-webui

# 查看状态
sudo systemctl status pdf-craft-webui

# 查看日志
sudo journalctl -u pdf-craft-webui -f

# 禁用服务
sudo systemctl disable pdf-craft-webui
```

## 🔧 配置说明

### 环境变量配置

创建 `.env` 文件：

```bash
# 服务配置
HOST=0.0.0.0
PORT=5000
DEBUG=False

# 性能配置
USE_GPU=True
BATCH_SIZE=5
MAX_WORKERS=4

# 路径配置
MODEL_DIR=./models
UPLOAD_DIR=./uploads
RESULT_DIR=./results
```

### 防火墙配置

```bash
# Ubuntu UFW
sudo ufw allow 5000/tcp
sudo ufw enable

# CentOS/RHEL firewalld
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

### Nginx反向代理配置

创建 `/etc/nginx/sites-available/pdf-craft-webui`：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 文件上传大小限制
        client_max_body_size 100M;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

启用配置：

```bash
sudo ln -s /etc/nginx/sites-available/pdf-craft-webui /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🧪 安装测试

### 运行测试脚本

```bash
# 运行完整测试
python test_installation.py

# 测试特定模块
python -c "from app import ocr_manager; print(ocr_manager.get_available_engines())"

# 测试GPU支持
python -c "import torch; print(f'CUDA可用: {torch.cuda.is_available()}')"
```

### 手动测试

```bash
# 测试服务启动
python run.py --port 5001

# 在另一个终端测试连接
curl http://localhost:5001/

# 测试OCR引擎
python -c "
import pytesseract
import easyocr
import paddleocr
print('所有OCR引擎测试通过')
"
```

## 🚨 故障排除

### 常见问题

#### 1. 端口被占用

```bash
# 查找占用进程
sudo lsof -i :5000

# 终止进程
sudo kill -9 <PID>

# 使用其他端口
python run.py --port 8080
```

#### 2. 权限问题

```bash
# 修复文件权限
sudo chown -R $USER:$USER ~/pdf-craft-webui
chmod +x run.py start.sh stop.sh

# 创建必要目录
mkdir -p uploads results models logs
```

#### 3. 依赖安装失败

```bash
# 清理pip缓存
pip cache purge

# 重新安装
pip install -r requirements.txt --force-reinstall

# 使用国内镜像源
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

#### 4. GPU不可用

```bash
# 检查NVIDIA驱动
nvidia-smi

# 检查CUDA
nvcc --version

# 重新安装PyTorch
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

#### 5. OCR引擎问题

```bash
# 重新安装Tesseract
sudo apt remove tesseract-ocr
sudo apt install tesseract-ocr tesseract-ocr-chi-sim

# 重新安装Python OCR包
pip uninstall pytesseract easyocr paddleocr rapidocr-onnxruntime
pip install pytesseract easyocr paddleocr rapidocr-onnxruntime
```

### 日志调试

```bash
# 启用详细日志
python run.py --debug

# 查看应用日志
tail -f logs/app.log

# 查看系统服务日志
sudo journalctl -u pdf-craft-webui -f

# 查看Docker日志
docker logs -f pdf-craft-webui
```

## 📈 性能优化

### 系统级优化

```bash
# 增加文件描述符限制
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# 优化内存管理
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

# 重启生效
sudo reboot
```

### 应用级优化

在页面中调整以下设置：

- **批处理大小**：根据内存大小调整（4-16）
- **工作线程数**：根据CPU核心数调整
- **GPU加速**：如有GPU则启用
- **运行模式**：选择适合的模式（兼容/平衡/性能）

## 🔄 更新升级

### 更新应用

```bash
cd ~/pdf-craft-webui
git pull origin main
source venv/bin/activate
pip install -r requirements.txt --upgrade
sudo systemctl restart pdf-craft-webui
```

### 更新Docker镜像

```bash
docker-compose pull
docker-compose up -d
```

## 📞 技术支持

如果遇到问题，请：

1. 查看本文档的故障排除部分
2. 运行 `python test_installation.py` 进行诊断
3. 查看应用日志文件
4. 在GitHub Issues中提交问题
5. 参考项目文档和Wiki

## 📝 更新日志

- **v3.0.0**: 添加多OCR引擎支持，完善安装脚本
- **v2.0.0**: 重构安装流程，添加Docker支持
- **v1.0.0**: 初始版本发布 