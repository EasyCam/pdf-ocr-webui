#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
快速测试脚本
验证多OCR引擎功能
"""

import sys
import os
import time
from pathlib import Path

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """测试导入"""
    print("🔍 测试模块导入...")
    
    try:
        from ocr_engines import OCREngineManager
        print("✓ OCR引擎管理器导入成功")
    except Exception as e:
        print(f"✗ OCR引擎管理器导入失败: {e}")
        return False
    
    try:
        from app import app
        print("✓ Flask应用导入成功")
    except Exception as e:
        print(f"✗ Flask应用导入失败: {e}")
        return False
    
    return True

def test_ocr_engines():
    """测试OCR引擎"""
    print("\n🔧 测试OCR引擎...")
    
    try:
        from ocr_engines import OCREngineManager
        
        # 初始化OCR管理器
        manager = OCREngineManager(
            model_dir="./models",
            use_gpu=False
        )
        
        # 获取可用引擎
        engines = manager.get_available_engines()
        
        print(f"发现 {len(engines)} 个OCR引擎:")
        available_count = 0
        
        for name, info in engines.items():
            status = "✓" if info['available'] else "✗"
            print(f"  {status} {info['name']}: {info['description']}")
            if not info['available'] and info['error_message']:
                print(f"    错误: {info['error_message']}")
            else:
                available_count += 1
        
        print(f"\n可用引擎数量: {available_count}/{len(engines)}")
        
        if available_count == 0:
            print("⚠️  没有可用的OCR引擎，请运行 'python install_ocr_engines.py' 安装")
            return False
        
        return True
        
    except Exception as e:
        print(f"✗ OCR引擎测试失败: {e}")
        return False

def test_flask_app():
    """测试Flask应用"""
    print("\n🌐 测试Flask应用...")
    
    try:
        from app import app
        
        # 测试应用配置
        print(f"✓ 上传文件夹: {app.config['UPLOAD_FOLDER']}")
        print(f"✓ 结果文件夹: {app.config['RESULTS_FOLDER']}")
        print(f"✓ 模型目录: {app.config['MODEL_DIR']}")
        print(f"✓ GPU支持: {app.config.get('USE_GPU', False)}")
        
        # 创建必要的目录
        os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
        os.makedirs(app.config['RESULTS_FOLDER'], exist_ok=True)
        os.makedirs(app.config['MODEL_DIR'], exist_ok=True)
        
        print("✓ 目录结构检查完成")
        
        return True
        
    except Exception as e:
        print(f"✗ Flask应用测试失败: {e}")
        return False

def test_api_endpoints():
    """测试API端点"""
    print("\n🔌 测试API端点...")
    
    try:
        from app import app
        
        with app.test_client() as client:
            # 测试主页
            response = client.get('/')
            if response.status_code == 200:
                print("✓ 主页端点正常")
            else:
                print(f"✗ 主页端点异常: {response.status_code}")
                return False
            
            # 测试OCR引擎端点
            response = client.get('/ocr_engines')
            if response.status_code == 200:
                print("✓ OCR引擎端点正常")
                data = response.get_json()
                if 'engines' in data:
                    print(f"  返回 {len(data['engines'])} 个引擎信息")
            else:
                print(f"✗ OCR引擎端点异常: {response.status_code}")
                return False
            
            # 测试系统信息端点
            response = client.get('/system_info')
            if response.status_code == 200:
                print("✓ 系统信息端点正常")
            else:
                print(f"✗ 系统信息端点异常: {response.status_code}")
                return False
        
        return True
        
    except Exception as e:
        print(f"✗ API端点测试失败: {e}")
        return False

def create_sample_pdf():
    """创建示例PDF文件用于测试"""
    print("\n📄 创建示例PDF文件...")
    
    try:
        from reportlab.lib.pagesizes import letter
        from reportlab.platypus import SimpleDocTemplate, Paragraph
        from reportlab.lib.styles import getSampleStyleSheet
        
        # 创建示例PDF
        pdf_path = "test_sample.pdf"
        doc = SimpleDocTemplate(pdf_path, pagesize=letter)
        styles = getSampleStyleSheet()
        
        story = []
        story.append(Paragraph("OCR测试文档", styles['Title']))
        story.append(Paragraph("这是一个用于测试OCR引擎的示例文档。", styles['Normal']))
        story.append(Paragraph("This is a sample document for testing OCR engines.", styles['Normal']))
        story.append(Paragraph("包含中文和英文内容，用于验证多语言识别能力。", styles['Normal']))
        
        doc.build(story)
        
        if os.path.exists(pdf_path):
            print(f"✓ 示例PDF创建成功: {pdf_path}")
            return pdf_path
        else:
            print("✗ 示例PDF创建失败")
            return None
            
    except ImportError:
        print("⚠️  reportlab未安装，跳过PDF创建")
        return None
    except Exception as e:
        print(f"✗ 示例PDF创建失败: {e}")
        return None

def test_ocr_processing(pdf_path):
    """测试OCR处理"""
    if not pdf_path or not os.path.exists(pdf_path):
        print("⚠️  没有可用的PDF文件，跳过OCR处理测试")
        return True
    
    print(f"\n⚡ 测试OCR处理: {pdf_path}")
    
    try:
        from ocr_engines import OCREngineManager
        
        manager = OCREngineManager(
            model_dir="./models",
            use_gpu=False
        )
        
        # 获取可用引擎
        engines = manager.get_available_engines()
        available_engines = [name for name, info in engines.items() if info['available']]
        
        if not available_engines:
            print("⚠️  没有可用的OCR引擎")
            return False
        
        # 测试第一个可用引擎
        test_engine = available_engines[0]
        print(f"使用 {test_engine} 引擎进行测试...")
        
        start_time = time.time()
        results = manager.extract_text_from_pdf(
            pdf_path=pdf_path,
            engine_name=test_engine,
            language='auto'
        )
        processing_time = time.time() - start_time
        
        if results:
            total_text = sum(len(result.get('text', '')) for result in results)
            print(f"✓ OCR处理成功")
            print(f"  处理时间: {processing_time:.2f}秒")
            print(f"  页面数: {len(results)}")
            print(f"  总字符数: {total_text}")
            
            # 显示第一页的部分内容
            if results and results[0].get('text'):
                preview = results[0]['text'][:100]
                print(f"  内容预览: {preview}...")
        else:
            print("✗ OCR处理失败")
            return False
        
        return True
        
    except Exception as e:
        print(f"✗ OCR处理测试失败: {e}")
        return False

def main():
    """主函数"""
    print("🚀 基于光学字符识别和本地大语言模型的文档转换平台- 快速测试")
    print("=" * 50)
    
    # 测试步骤
    tests = [
        ("模块导入", test_imports),
        ("OCR引擎", test_ocr_engines),
        ("Flask应用", test_flask_app),
        ("API端点", test_api_endpoints),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n📋 测试: {test_name}")
        print("-" * 30)
        
        try:
            if test_func():
                print(f"✅ {test_name} 测试通过")
                passed += 1
            else:
                print(f"❌ {test_name} 测试失败")
        except Exception as e:
            print(f"❌ {test_name} 测试异常: {e}")
    
    # 创建示例PDF并测试OCR
    pdf_path = create_sample_pdf()
    if pdf_path:
        print(f"\n📋 测试: OCR处理")
        print("-" * 30)
        if test_ocr_processing(pdf_path):
            print("✅ OCR处理 测试通过")
            passed += 1
        else:
            print("❌ OCR处理 测试失败")
        total += 1
        
        # 清理测试文件
        try:
            os.remove(pdf_path)
            print(f"🗑️  已清理测试文件: {pdf_path}")
        except:
            pass
    
    # 测试结果
    print("\n" + "=" * 50)
    print(f"📊 测试结果: {passed}/{total} 通过")
    
    if passed == total:
        print("🎉 所有测试通过！系统运行正常")
        print("\n🚀 可以运行以下命令启动应用:")
        print("   python run.py")
        return True
    else:
        print("⚠️  部分测试失败，请检查相关配置")
        print("\n💡 建议:")
        print("   1. 运行 'python install_ocr_engines.py' 安装OCR引擎")
        print("   2. 检查依赖包是否正确安装")
        print("   3. 查看详细错误信息")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 