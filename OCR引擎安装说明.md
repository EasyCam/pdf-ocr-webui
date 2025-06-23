# Ubuntu 24.04 OCR引擎安装说明

## 🔍 问题描述

在Ubuntu 24.04下，PDF OCR WebUI可能会显示：
- Tesseract (不可用)
- EasyOCR (不可用)

这通常是因为缺少必要的系统依赖或Python包。

## 🚀 解决方案

### 方案一：快速修复（推荐）

```bash
# 运行快速修复脚本
chmod +x quick_fix_ocr.sh
./quick_fix_ocr.sh
```

### 方案二：完整安装

```bash
# 运行完整安装脚本
chmod +x install_ocr_ubuntu.sh
./install_ocr_ubuntu.sh
```

### 方案三：集成安装

```bash
# 在服务部署时一起安装
./start_ubuntu_service.sh install
# 选择 'y' 安装OCR引擎
```

### 方案四：手动安装

```bash
# 1. 更新系统
sudo apt update

# 2. 安装Tesseract
sudo apt install -y tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra tesseract-ocr-eng

# 3. 安装Python依赖
sudo apt install -y python3-pip python3-dev build-essential

# 4. 安装OCR Python包
python3 -m pip install --user pytesseract Pillow opencv-python numpy easyocr
```

## 🧪 验证安装

### 检查Tesseract

```bash
# 检查Tesseract版本
tesseract --version

# 检查支持的语言
tesseract --list-langs
```

### 检查Python包

```bash
# 运行测试脚本
python3 test_ocr_installation.py

# 或手动检查
python3 -c "import pytesseract; print('pytesseract OK')"
python3 -c "import easyocr; print('easyocr OK')"
```

### 检查WebUI

1. 重启PDF OCR WebUI服务：
   ```bash
   ./service_restart.sh
   ```

2. 访问Web界面：http://localhost:5000

3. 在OCR引擎选择中应该看到：
   - ✅ Tesseract (可用)
   - ✅ EasyOCR (可用)

## 🔧 常见问题

### 1. Tesseract命令找不到

```bash
# 检查安装
which tesseract

# 如果没有，重新安装
sudo apt install -y tesseract-ocr
```

### 2. Python包导入错误

```bash
# 检查pip安装的包
pip3 list | grep -E "(tesseract|easyocr|opencv|pillow)"

# 重新安装
python3 -m pip install --user --force-reinstall pytesseract easyocr
```

### 3. 权限问题

```bash
# 确保用户有权限访问已安装的包
ls -la ~/.local/lib/python*/site-packages/

# 如果需要，修复权限
chmod -R 755 ~/.local/
```

### 4. 环境变量问题

```bash
# 添加到PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 设置Tesseract路径
echo 'export TESSERACT_CMD="/usr/bin/tesseract"' >> ~/.bashrc
source ~/.bashrc
```

### 5. 系统依赖缺失

```bash
# 安装编译依赖
sudo apt install -y build-essential python3-dev

# 安装图像处理库
sudo apt install -y libjpeg-dev libtiff5-dev libpng-dev

# 安装OpenCV依赖
sudo apt install -y libavcodec-dev libavformat-dev libswscale-dev
```

## 📊 性能优化

### GPU加速（可选）

如果有NVIDIA GPU：

```bash
# 安装CUDA支持
sudo apt install -y nvidia-cuda-toolkit

# 安装GPU版本的包
python3 -m pip install --user torch torchvision --index-url https://download.pytorch.org/whl/cu118

# EasyOCR自动使用GPU（如果可用）
```

### 内存优化

对于内存较小的系统：

```bash
# 只安装必要的语言包
sudo apt install -y tesseract-ocr-chi-sim tesseract-ocr-eng

# 使用轻量级OCR引擎
python3 -m pip install --user rapidocr-onnxruntime
```

## 📝 支持的语言

### Tesseract支持的语言

- `eng` - 英语
- `chi_sim` - 简体中文
- `chi_tra` - 繁体中文
- `jpn` - 日语
- `kor` - 韩语
- `fra` - 法语
- `deu` - 德语
- `spa` - 西班牙语
- `rus` - 俄语
- `ara` - 阿拉伯语

### EasyOCR支持的语言

EasyOCR支持80+种语言，包括但不限于：
- 中文（简体/繁体）
- 英语
- 日语
- 韩语
- 泰语
- 越南语
- 等等

## 🔄 重启服务

安装完成后，记得重启服务：

```bash
# 如果使用systemd服务
./service_restart.sh

# 或者手动重启
sudo systemctl restart pdf-ocr-webui.service

# 检查状态
./service_status.sh
```

## 📞 获取帮助

如果仍有问题：

1. 查看服务日志：
   ```bash
   ./view_logs.sh
   ```

2. 运行诊断脚本：
   ```bash
   python3 test_ocr_installation.py
   ```

3. 检查系统资源：
   ```bash
   free -h
   df -h
   ``` 