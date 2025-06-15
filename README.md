# 基于光学字符识别和本地大语言模型的文档转换平台

版本号 1.0

<div align="center">

![PDF-Craft Logo](https://img.shields.io/badge/PDF--Craft-WebUI-blue?style=for-the-badge&logo=python)
![License](https://img.shields.io/badge/license-MIT-orange?style=for-the-badge)

[🚀 快速开始](#快速开始) • [📖 功能特性](#功能特性) • [🛠️ 安装指南](#安装指南) • [📚 使用文档](#使用文档) • [❓ 常见问题](#常见问题)

</div>

---

## 🌟 项目简介

本软件是一个功能强大的智能文档转换平台，集成了多种先进的OCR引擎和本地大语言模型，为用户提供高质量的PDF文档识别和转换服务。无论是学术论文、技术文档还是多语言材料，都能获得出色的识别效果。

### ✨ 核心亮点

- 🔧 **多引擎OCR**：集成5种主流OCR引擎，智能选择最优方案
- 🌍 **多语言支持**：支持15+种语言，包括中日韩等亚洲语言
- ⚡ **性能优化**：GPU加速、多进程处理、智能批处理
- 📊 **实时对比**：OCR引擎性能实时测试和对比分析
- 🎯 **智能推荐**：根据文档特征自动推荐最佳处理方案
- 🔄 **重新处理**：支持已完成任务的重新处理和配置调整
- 🌐 **外网访问**：支持局域网和公网访问，便于团队协作
- 📱 **响应式UI**：现代化界面设计，支持移动端访问

---

## 🚀 快速开始

### 一键安装（Ubuntu 24.04）

```bash
# 下载并运行安装脚本
wget https://raw.githubusercontent.com/EasyCam/pdf-ocr-webui/main/install_ubuntu.sh
chmod +x install_ubuntu.sh
sudo ./install_ubuntu.sh
```

### 手动启动

```bash
# 克隆项目
git clone https://github.com/EasyCam/pdf-ocr-webui.git
cd pdf-ocr-webui

# 安装依赖
pip install -r requirements.txt

# 启动服务
python run.py
```

访问 http://localhost:5000 开始使用！

---

## 📖 功能特性

### 🔧 OCR引擎支持

| 引擎 | 特点 | 适用场景 | 速度 | 准确率 |
|------|------|----------|------|--------|
| **PDF-Craft** | 复杂文档结构支持 | 学术论文、技术文档 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **PaddleOCR** | 中文识别优秀 | 中文文档、票据 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **EasyOCR** | 深度学习OCR | 手写文字、复杂背景 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Tesseract** | 多语言支持 | 多语言文档 | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **RapidOCR** | 轻量级高速 | 大批量处理 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

### 🌍 语言支持

- **亚洲语言**：中文（简/繁）、日文、韩文
- **欧洲语言**：英文、法文、德文、西班牙文、俄文
- **其他语言**：阿拉伯文等
- **智能组合**：多语言混合识别、智能分离识别
- **自定义组合**：支持中文语言名称输入（如"中文+英文+日文"）

### 📊 处理模式

#### 🛡️ 兼容模式（默认）
- **特点**：最高稳定性，适合所有环境
- **配置**：CPU处理，单线程，低内存占用
- **适用**：生产环境、资源受限系统

#### ⚖️ 平衡模式
- **特点**：性能与稳定性并重
- **配置**：GPU加速（可选），适度并行
- **适用**：日常使用、中等配置系统

#### 🚀 性能模式
- **特点**：最大化处理速度
- **配置**：GPU加速、多进程、大批处理
- **适用**：高性能硬件、大批量处理

### 📄 输出格式

- **📝 Markdown**：标准格式，支持图片嵌入
- **📄 Word文档**：完整格式保留，可编辑
- **📋 带文本PDF**：可搜索、可复制
- **📦 完整压缩包**：包含所有格式和资源文件

---

## 🛠️ 安装指南

### Ubuntu 24.04 详细安装

#### 系统要求

- **操作系统**：Ubuntu 24.04 LTS
- **Python**：3.8+ （推荐3.10+）
- **内存**：4GB+（推荐8GB+）
- **存储**：2GB+可用空间
- **GPU**：NVIDIA GPU（可选，用于加速）

#### 步骤1：系统准备

```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 安装基础依赖
sudo apt install -y python3 python3-pip python3-venv git wget curl

# 安装系统库依赖
sudo apt install -y \
    tesseract-ocr \
    tesseract-ocr-chi-sim \
    tesseract-ocr-chi-tra \
    tesseract-ocr-jpn \
    tesseract-ocr-kor \
    libtesseract-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1
```

#### 步骤2：Python环境设置

```bash
# 创建项目目录
mkdir -p ~/pdf-ocr-webui
cd ~/pdf-ocr-webui

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 升级pip
pip install --upgrade pip setuptools wheel
```

#### 步骤3：安装项目

```bash
# 克隆项目（替换为实际仓库地址）
git clone https://github.com/EasyCam/pdf-ocr-webui.git .

# 安装Python依赖
pip install -r requirements.txt

# 自动安装OCR引擎
python install_ocr_engines.py
```

#### 步骤4：GPU支持（可选）

```bash
# 检查NVIDIA驱动
nvidia-smi

# 安装CUDA支持的PyTorch（如果有GPU）
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

#### 步骤5：启动服务

```bash
# 启动服务
python run.py

# 后台运行
nohup python run.py > app.log 2>&1 &

# 使用systemd服务（推荐生产环境）
sudo cp pdf-ocr-webui.service /etc/systemd/system/
sudo systemctl enable pdf-ocr-webui
sudo systemctl start pdf-ocr-webui
```

### 其他系统安装

#### Windows 10/11

```powershell
# 安装Python 3.10+
# 下载并安装：https://www.python.org/downloads/

# 克隆项目
git clone https://github.com/EasyCam/pdf-ocr-webui.git
cd pdf-ocr-webui

# 创建虚拟环境
python -m venv venv
venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt
python install_ocr_engines.py

# 启动服务
python run.py
```

#### macOS

```bash
# 安装Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装依赖
brew install python@3.10 tesseract tesseract-lang

# 后续步骤与Ubuntu类似
```

#### Docker部署

```bash
# 构建镜像
docker build -t pdf-ocr-webui .

# 运行容器
docker run -d \
  --name pdf-ocr-webui \
  -p 5000:5000 \
  -v $(pwd)/uploads:/app/uploads \
  -v $(pwd)/results:/app/results \
  pdf-ocr-webui

# 使用docker-compose
docker-compose up -d
```

---

## 📚 使用文档

### 基本使用流程

1. **📁 上传文件**：支持单个或批量PDF文件上传
2. **⚙️ 配置参数**：选择OCR引擎、语言、处理级别
3. **🚀 开始处理**：实时监控处理进度
4. **📥 下载结果**：多格式文件下载
5. **🔄 重新处理**：调整参数重新识别

### 高级功能

#### 性能对比测试

```bash
# 访问性能对比功能
点击"OCR引擎性能对比" → 选择测试文件 → 查看结果
```

#### 批量处理优化

```bash
# 调整批处理大小
设置 → 批处理大小 → 根据系统性能调整（1-10）
```

#### 外网访问配置

```bash
# 启动时指定监听地址
python run.py --host 0.0.0.0 --port 5000

# 防火墙配置帮助
python run.py --help-firewall
```

### API接口

#### 上传文件

```bash
curl -X POST \
  -F "files[]=@document.pdf" \
  -F "ocr_engine=paddleocr" \
  -F "ocr_language=chinese" \
  http://localhost:5000/upload
```

#### 查询任务状态

```bash
curl http://localhost:5000/job/{job_id}
```

#### 下载结果

```bash
curl -O http://localhost:5000/download/{job_id}?type=markdown
```

---

## ⚙️ 配置说明

### 环境变量

```bash
# 服务配置
export HOST=0.0.0.0          # 监听地址
export PORT=5000             # 监听端口
export DEBUG=False           # 调试模式

# 性能配置
export USE_GPU=True          # 启用GPU
export BATCH_SIZE=5          # 批处理大小
export MAX_WORKERS=4         # 最大工作线程

# 路径配置
export MODEL_DIR=./models    # 模型目录
export UPLOAD_DIR=./uploads  # 上传目录
export RESULT_DIR=./results  # 结果目录
```

### 配置文件

创建 `config.yaml`：

```yaml
# 服务配置
server:
  host: "0.0.0.0"
  port: 5000
  debug: false

# OCR配置
ocr:
  default_engine: "pdf_craft"
  default_language: "auto"
  default_level: "standard"

# 性能配置
performance:
  use_gpu: true
  batch_size: 5
  max_workers: 4
  enable_multiprocessing: false

# 路径配置
paths:
  model_dir: "./models"
  upload_dir: "./uploads"
  result_dir: "./results"
```

---

## 🔧 故障排除

### 常见问题解决

#### 1. OCR引擎安装失败

```bash
# 检查引擎状态
python -c "from app import ocr_manager; print(ocr_manager.get_available_engines())"

# 重新安装特定引擎
pip install paddleocr --upgrade
pip install easyocr --upgrade

# 清理缓存重新安装
pip cache purge
pip install -r requirements.txt --force-reinstall
```

#### 2. GPU不可用

```bash
# 检查CUDA
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"

# 重新安装CUDA版本PyTorch
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

#### 3. 内存不足

```bash
# 调整配置
export BATCH_SIZE=1
export MAX_WORKERS=1

# 使用轻量级引擎
选择 RapidOCR 或 Tesseract
```

#### 4. 端口占用

```bash
# 查找占用进程
sudo lsof -i :5000

# 终止进程
sudo kill -9 <PID>

# 使用其他端口
python run.py --port 8080
```

#### 5. 权限问题

```bash
# 修复文件权限
sudo chown -R $USER:$USER ~/pdf-ocr-webui
chmod +x run.py

# 创建必要目录
mkdir -p uploads results models
```

### 日志调试

```bash
# 启用详细日志
python run.py --debug

# 查看日志文件
tail -f app.log

# 检查系统资源
htop
nvidia-smi
```

---

## 🚀 性能优化

### 硬件建议

#### 最低配置
- **CPU**：2核心
- **内存**：4GB
- **存储**：2GB
- **网络**：1Mbps

#### 推荐配置
- **CPU**：4核心+
- **内存**：8GB+
- **存储**：10GB+ SSD
- **GPU**：NVIDIA GTX 1060+
- **网络**：10Mbps+

#### 高性能配置
- **CPU**：8核心+
- **内存**：16GB+
- **存储**：50GB+ NVMe SSD
- **GPU**：NVIDIA RTX 3060+
- **网络**：100Mbps+

### 性能调优

#### 系统级优化

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

#### 应用级优化

```python
# 在config.yaml中调整
performance:
  batch_size: 8              # 根据内存调整
  max_workers: 8             # 根据CPU核心数调整
  enable_multiprocessing: true
  gpu_batch_size: 16         # GPU批处理大小
  cpu_batch_size: 4          # CPU批处理大小
```

---

## 🤝 贡献指南

### 开发环境设置

```bash
# 克隆开发分支
git clone -b develop https://github.com/EasyCam/pdf-ocr-webui.git
cd pdf-ocr-webui

# 安装开发依赖
pip install -r requirements-dev.txt

# 安装pre-commit钩子
pre-commit install

# 运行测试
pytest tests/
```

### 代码规范

- **Python**：遵循PEP 8规范
- **JavaScript**：使用ESLint配置
- **提交信息**：遵循Conventional Commits

### 提交流程

1. Fork项目
2. 创建功能分支：`git checkout -b feature/amazing-feature`
3. 提交更改：`git commit -m 'Add amazing feature'`
4. 推送分支：`git push origin feature/amazing-feature`
5. 创建Pull Request

---

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 🙏 致谢

感谢以下开源项目的支持：

- [PDF-Craft](https://github.com/oomol-lab/pdf-craft) - 核心PDF处理引擎
- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) - 百度开源OCR引擎
- [EasyOCR](https://github.com/JaidedAI/EasyOCR) - 深度学习OCR引擎
- [Tesseract](https://github.com/tesseract-ocr/tesseract) - Google开源OCR引擎
- [RapidOCR](https://github.com/RapidAI/RapidOCR) - 轻量级OCR引擎

---


<div align="center">

**⭐ 如果这个项目对您有帮助，请给我们一个Star！⭐**

[🔝 回到顶部](#pdf-ocr-webui---智能文档转换平台)

</div>