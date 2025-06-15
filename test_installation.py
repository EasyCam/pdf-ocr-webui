#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PDF-Craft WebUI 安装测试脚本
用于验证安装是否成功
"""

import sys
import os
import subprocess
import importlib
import platform
import time
import requests
from pathlib import Path

def print_header(title):
    """打印标题"""
    print(f"\n{'='*60}")
    print(f" {title}")
    print(f"{'='*60}")

def print_success(message):
    """打印成功信息"""
    print(f"✅ {message}")

def print_error(message):
    """打印错误信息"""
    print(f"❌ {message}")

def print_warning(message):
    """打印警告信息"""
    print(f"⚠️  {message}")

def print_info(message):
    """打印信息"""
    print(f"ℹ️  {message}")

def test_system_info():
    """测试系统信息"""
    print_header("系统信息")
    
    print_info(f"操作系统: {platform.system()} {platform.release()}")
    print_info(f"架构: {platform.machine()}")
    print_info(f"Python版本: {platform.python_version()}")
    print_info(f"当前目录: {os.getcwd()}")
    
    # 检查内存
    try:
        import psutil
        memory = psutil.virtual_memory()
        print_info(f"总内存: {memory.total / 1024**3:.1f}GB")
        print_info(f"可用内存: {memory.available / 1024**3:.1f}GB")
    except ImportError:
        print_warning("psutil未安装，无法获取内存信息")

def test_python_modules():
    """测试Python模块导入"""
    print_header("Python模块测试")
    
    required_modules = [
        ('flask', 'Flask'),
        ('fitz', 'PyMuPDF'),
        ('cv2', 'OpenCV'),
        ('PIL', 'Pillow'),
        ('numpy', 'NumPy'),
        ('requests', 'Requests'),
        ('psutil', 'psutil'),
    ]
    
    optional_modules = [
        ('torch', 'PyTorch'),
        ('pytesseract', 'Tesseract'),
        ('easyocr', 'EasyOCR'),
        ('paddleocr', 'PaddleOCR'),
        ('rapidocr_onnxruntime', 'RapidOCR'),
    ]
    
    print("必需模块:")
    for module_name, display_name in required_modules:
        try:
            module = importlib.import_module(module_name)
            version = getattr(module, '__version__', 'Unknown')
            print_success(f"{display_name}: {version}")
        except ImportError as e:
            print_error(f"{display_name}: 导入失败 - {e}")
    
    print("\n可选模块:")
    for module_name, display_name in optional_modules:
        try:
            module = importlib.import_module(module_name)
            version = getattr(module, '__version__', 'Unknown')
            print_success(f"{display_name}: {version}")
        except ImportError:
            print_warning(f"{display_name}: 未安装")

def test_gpu_support():
    """测试GPU支持"""
    print_header("GPU支持测试")
    
    try:
        import torch
        print_info(f"PyTorch版本: {torch.__version__}")
        
        if torch.cuda.is_available():
            device_count = torch.cuda.device_count()
            print_success(f"CUDA可用，检测到 {device_count} 个GPU设备")
            
            for i in range(device_count):
                props = torch.cuda.get_device_properties(i)
                memory_gb = props.total_memory / 1024**3
                print_info(f"GPU {i}: {props.name} ({memory_gb:.1f}GB)")
        else:
            print_warning("CUDA不可用，将使用CPU模式")
            
    except ImportError:
        print_error("PyTorch未安装")

def test_ocr_engines():
    """测试OCR引擎"""
    print_header("OCR引擎测试")
    
    # 测试Tesseract
    try:
        import pytesseract
        version = pytesseract.get_tesseract_version()
        print_success(f"Tesseract: {version}")
    except Exception as e:
        print_error(f"Tesseract: {e}")
    
    # 测试EasyOCR
    try:
        import easyocr
        print_success("EasyOCR: 可用")
    except Exception as e:
        print_error(f"EasyOCR: {e}")
    
    # 测试PaddleOCR
    try:
        import paddleocr
        print_success("PaddleOCR: 可用")
    except Exception as e:
        print_error(f"PaddleOCR: {e}")
    
    # 测试RapidOCR
    try:
        import rapidocr_onnxruntime
        print_success("RapidOCR: 可用")
    except Exception as e:
        print_error(f"RapidOCR: {e}")

def test_file_structure():
    """测试文件结构"""
    print_header("文件结构测试")
    
    required_files = [
        'app.py',
        'run.py',
        'requirements.txt',
        'templates/index.html',
        'static/css/style.css',
        'static/js/main.js',
    ]
    
    required_dirs = [
        'uploads',
        'results',
        'models',
        'templates',
        'static',
    ]
    
    print("必需文件:")
    for file_path in required_files:
        if os.path.exists(file_path):
            print_success(f"{file_path}")
        else:
            print_error(f"{file_path}: 文件不存在")
    
    print("\n必需目录:")
    for dir_path in required_dirs:
        if os.path.exists(dir_path):
            print_success(f"{dir_path}/")
        else:
            print_error(f"{dir_path}/: 目录不存在")

def test_app_import():
    """测试应用导入"""
    print_header("应用导入测试")
    
    try:
        # 添加当前目录到Python路径
        sys.path.insert(0, os.getcwd())
        
        # 测试导入主应用
        from app import app
        print_success("Flask应用导入成功")
        
        # 测试OCR管理器
        try:
            from app import ocr_manager
            if ocr_manager:
                engines = ocr_manager.get_available_engines()
                print_success(f"OCR管理器初始化成功，可用引擎: {len(engines)}")
                for name, info in engines.items():
                    status = "✅" if info['available'] else "❌"
                    print_info(f"  {status} {name}: {info['name']}")
            else:
                print_warning("OCR管理器未初始化")
        except Exception as e:
            print_error(f"OCR管理器测试失败: {e}")
            
    except Exception as e:
        print_error(f"应用导入失败: {e}")

def test_service_startup():
    """测试服务启动"""
    print_header("服务启动测试")
    
    print_info("尝试启动服务进行测试...")
    
    try:
        # 启动服务进程
        process = subprocess.Popen(
            [sys.executable, 'run.py', '--port', '5001'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=os.getcwd()
        )
        
        # 等待服务启动
        time.sleep(10)
        
        # 测试服务是否响应
        try:
            response = requests.get('http://localhost:5001/', timeout=5)
            if response.status_code == 200:
                print_success("服务启动成功，HTTP响应正常")
            else:
                print_error(f"服务响应异常，状态码: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print_error(f"服务连接失败: {e}")
        
        # 终止测试进程
        process.terminate()
        process.wait(timeout=5)
        
    except Exception as e:
        print_error(f"服务启动测试失败: {e}")

def test_permissions():
    """测试文件权限"""
    print_header("文件权限测试")
    
    test_dirs = ['uploads', 'results', 'models', 'logs']
    
    for dir_path in test_dirs:
        if os.path.exists(dir_path):
            if os.access(dir_path, os.R_OK | os.W_OK):
                print_success(f"{dir_path}: 读写权限正常")
            else:
                print_error(f"{dir_path}: 权限不足")
        else:
            print_warning(f"{dir_path}: 目录不存在")

def main():
    """主函数"""
    print("🚀 PDF-Craft WebUI 安装测试")
    print("=" * 60)
    
    # 执行各项测试
    test_system_info()
    test_python_modules()
    test_gpu_support()
    test_ocr_engines()
    test_file_structure()
    test_permissions()
    test_app_import()
    
    # 询问是否进行服务启动测试
    print("\n" + "="*60)
    response = input("是否进行服务启动测试？这将临时启动服务 (y/N): ")
    if response.lower() in ['y', 'yes']:
        test_service_startup()
    
    print_header("测试完成")
    print("如果所有测试都通过，您可以运行以下命令启动服务:")
    print("  python run.py")
    print("\n然后访问: http://localhost:5000")

if __name__ == '__main__':
    main() 