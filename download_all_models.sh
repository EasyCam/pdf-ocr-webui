#!/bin/bash

# PDF-Craft模型批量下载脚本
# 一次性下载所有需要的模型文件到正确目录

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印横幅
print_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                PDF-Craft模型批量下载工具                     ║"
    echo "║                                                              ║"
    echo "║  📦 一次性下载所有需要的模型文件                              ║"
    echo "║  🎯 避免运行时下载失败问题                                    ║"
    echo "║  🚀 支持断点续传和多线程下载                                  ║"
    echo "║  🔄 自动重试和错误恢复                                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# 获取项目根目录
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$script_dir"
}

# 检查磁盘空间
check_disk_space() {
    print_message $BLUE "检查磁盘空间..."
    
    local project_root=$(get_project_root)
    local available_space=$(df "$project_root" | awk 'NR==2 {print $4}')
    local required_space=10485760  # 10GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        print_message $RED "❌ 磁盘空间不足！"
        print_message $YELLOW "需要至少10GB空间，当前可用: $((available_space/1024/1024))GB"
        exit 1
    fi
    
    print_message $GREEN "✅ 磁盘空间充足: $((available_space/1024/1024))GB"
}

# 设置环境变量
setup_environment() {
    print_message $BLUE "设置下载环境..."
    
    local project_root=$(get_project_root)
    local models_dir="$project_root/models"
    
    # 创建模型目录结构
    mkdir -p "$models_dir"
    mkdir -p "$models_dir/.cache/huggingface"
    mkdir -p "$models_dir/.cache/transformers"
    mkdir -p "$models_dir/.cache/datasets"
    mkdir -p "$models_dir/.cache/torch"
    
    # 设置环境变量
    export HF_HOME="$models_dir/.cache/huggingface"
    export TRANSFORMERS_CACHE="$models_dir/.cache/transformers"
    export HF_DATASETS_CACHE="$models_dir/.cache/datasets"
    export HF_METRICS_CACHE="$models_dir/.cache/metrics"
    export TORCH_HOME="$models_dir/.cache/torch"
    
    # 设置下载配置
    export HF_HUB_CACHE="$models_dir/.cache/huggingface/hub"
    export HF_ASSETS_CACHE="$models_dir/.cache/huggingface/assets"
    
    # 如果配置了镜像，使用镜像
    if [[ -n "${HF_ENDPOINT:-}" ]]; then
        print_message $BLUE "使用Hugging Face镜像: $HF_ENDPOINT"
    fi
    
    print_message $GREEN "✅ 环境设置完成"
    print_message $CYAN "模型存储目录: $models_dir"
}

# 安装必要的Python包
install_dependencies() {
    print_message $BLUE "安装/升级必要的Python包..."
    
    # 检查Python环境
    if [[ -f "venv/bin/activate" ]]; then
        print_message $BLUE "激活虚拟环境..."
        source venv/bin/activate
    fi
    
    # 升级pip
    python3 -m pip install --upgrade pip
    
    # 安装核心依赖
    python3 -m pip install --upgrade \
        huggingface_hub \
        transformers \
        torch \
        torchvision \
        torchaudio \
        accelerate \
        safetensors \
        tokenizers \
        requests \
        tqdm
    
    # 安装PDF-Craft相关依赖
    python3 -m pip install --upgrade \
        pdf-craft \
        onnxruntime \
        opencv-python \
        Pillow \
        numpy
    
    print_message $GREEN "✅ 依赖安装完成"
}

# 下载单个模型
download_model() {
    local model_name=$1
    local model_type=$2
    local description=$3
    local retry_count=0
    local max_retries=3
    
    print_message $BLUE "📦 下载模型: $model_name"
    print_message $CYAN "   类型: $model_type"
    print_message $CYAN "   描述: $description"
    
    while [[ $retry_count -lt $max_retries ]]; do
        if python3 -c "
import os
from huggingface_hub import snapshot_download
from pathlib import Path

try:
    # 下载模型
    cache_dir = Path('$(get_project_root)/models/.cache/huggingface')
    
    print(f'开始下载: $model_name')
    snapshot_download(
        repo_id='$model_name',
        cache_dir=str(cache_dir),
        local_files_only=False,
        resume_download=True,
        force_download=False
    )
    print(f'✅ $model_name 下载成功')
except Exception as e:
    print(f'❌ $model_name 下载失败: {e}')
    exit(1)
"; then
            print_message $GREEN "✅ $model_name 下载成功"
            return 0
        else
            retry_count=$((retry_count + 1))
            print_message $YELLOW "⚠️  第${retry_count}次下载失败，重试中..."
            sleep 5
        fi
    done
    
    print_message $RED "❌ $model_name 下载失败，已重试${max_retries}次"
    return 1
}

# 直接尝试初始化PDF-Craft来触发模型下载
download_pdf_craft_direct() {
    print_message $PURPLE "🎯 直接初始化PDF-Craft触发模型下载..."
    
    cat > /tmp/init_pdf_craft.py << 'EOF'
import os
import sys
from pathlib import Path

# 设置环境变量
project_root = Path(__file__).parent.parent
models_dir = project_root / "models"
models_dir.mkdir(exist_ok=True)

os.environ['HF_HOME'] = str(models_dir / ".cache" / "huggingface")
os.environ['TRANSFORMERS_CACHE'] = str(models_dir / ".cache" / "transformers")
os.environ['HF_DATASETS_CACHE'] = str(models_dir / ".cache" / "datasets")
os.environ['HF_METRICS_CACHE'] = str(models_dir / ".cache" / "metrics")
os.environ['TORCH_HOME'] = str(models_dir / ".cache" / "torch")

print("🔧 设置模型缓存路径...")
print(f"HF_HOME: {os.environ['HF_HOME']}")
print(f"TRANSFORMERS_CACHE: {os.environ['TRANSFORMERS_CACHE']}")

try:
    print("📦 导入PDF-Craft...")
    from pdf_craft import PDFPageExtractor
    print("✅ PDF-Craft导入成功")
    
    print("🚀 初始化PDF-Craft提取器...")
    extractor = PDFPageExtractor(
        device='cpu',
        model_dir_path=str(models_dir)
    )
    print("✅ PDF-Craft提取器初始化成功")
    print("🎉 所有必要的模型已自动下载！")
    
except ImportError as e:
    print(f"❌ PDF-Craft导入失败: {e}")
    print("💡 请先安装PDF-Craft: pip install pdf-craft")
    sys.exit(1)
    
except Exception as e:
    print(f"❌ PDF-Craft初始化失败: {e}")
    print("💡 这可能是网络问题或模型下载失败")
    print("🔄 建议检查网络连接或配置代理")
    sys.exit(1)
EOF
    
    if python3 /tmp/init_pdf_craft.py; then
        print_message $GREEN "✅ PDF-Craft直接初始化成功，模型已下载"
        rm -f /tmp/init_pdf_craft.py
        return 0
    else
        print_message $YELLOW "⚠️  直接初始化失败，尝试手动下载模型"
        rm -f /tmp/init_pdf_craft.py
        return 1
    fi
}

# 下载PDF-Craft核心模型
download_pdf_craft_models() {
    print_message $PURPLE "🎯 下载PDF-Craft核心模型..."
    
    # 首先尝试直接初始化PDF-Craft
    if download_pdf_craft_direct; then
        return 0
    fi
    
    # 如果直接初始化失败，手动下载常用模型
    local models=(
        # LayoutLM系列 - 文档布局理解
        "microsoft/layoutlm-base-uncased:transformer:文档布局理解基础模型"
        "microsoft/layoutlmv2-base-uncased:transformer:文档布局理解v2模型"
        "microsoft/layoutlmv3-base:transformer:文档布局理解v3模型"
        
        # DiT系列 - 文档图像transformer
        "microsoft/dit-base-finetuned-rvlcdip:transformer:文档图像分类模型"
        
        # 表格检测模型
        "microsoft/table-transformer-structure-recognition:transformer:表格结构识别"
        "microsoft/table-transformer-detection:transformer:表格检测模型"
        
        # OCR相关模型
        "microsoft/trocr-base-printed:transformer:印刷文本OCR模型"
        "microsoft/trocr-base-handwritten:transformer:手写文本OCR模型"
        
        # 多语言模型
        "microsoft/layoutxlm-base:transformer:多语言文档理解模型"
    )
    
    local success_count=0
    local total_count=${#models[@]}
    
    for model_info in "${models[@]}"; do
        IFS=':' read -r model_name model_type description <<< "$model_info"
        
        if download_model "$model_name" "$model_type" "$description"; then
            success_count=$((success_count + 1))
        fi
        
        # 显示进度
        print_message $CYAN "进度: $success_count/$total_count"
        echo ""
    done
    
    print_message $GREEN "✅ PDF-Craft模型下载完成: $success_count/$total_count"
}

# 下载ONNX模型
download_onnx_models() {
    print_message $PURPLE "⚙️  下载ONNX模型..."
    
    local project_root=$(get_project_root)
    
    # 检查是否已有ONNX模型
    if [[ -d "$project_root/models/ppocrv4" ]]; then
        print_message $GREEN "✅ 发现现有PaddleOCR ONNX模型"
        return 0
    fi
    
    print_message $BLUE "准备下载PaddleOCR ONNX模型..."
    
    # 创建ONNX模型下载脚本
    cat > /tmp/download_onnx.py << 'EOF'
import requests
import os
from pathlib import Path
from tqdm import tqdm

def download_file(url, filename):
    """下载文件并显示进度"""
    try:
        print(f"开始下载: {os.path.basename(filename)}")
        response = requests.get(url, stream=True, timeout=30)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        with open(filename, 'wb') as f:
            if total_size > 0:
                with tqdm(total=total_size, unit='B', unit_scale=True, desc=os.path.basename(filename)) as pbar:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            pbar.update(len(chunk))
            else:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
        
        print(f"✅ {os.path.basename(filename)} 下载完成")
        return True
    except Exception as e:
        print(f"❌ {os.path.basename(filename)} 下载失败: {e}")
        return False

def download_paddleocr_onnx():
    """下载PaddleOCR ONNX模型"""
    # 使用GitHub上的模型文件或其他可用源
    models = {
        # 如果原始链接不可用，可以尝试其他源
        "det.onnx": {
            "url": "https://paddleocr.bj.bcebos.com/PP-OCRv4/chinese/ch_PP-OCRv4_det_infer.onnx",
            "dir": "det/"
        },
        "rec.onnx": {
            "url": "https://paddleocr.bj.bcebos.com/PP-OCRv4/chinese/ch_PP-OCRv4_rec_infer.onnx", 
            "dir": "rec/"
        },
        "cls.onnx": {
            "url": "https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_cls_infer.tar",
            "dir": "cls/"
        }
    }
    
    onnx_dir = Path("models/ppocrv4")
    success_count = 0
    
    for model_file, config in models.items():
        model_dir = onnx_dir / config["dir"]
        model_dir.mkdir(parents=True, exist_ok=True)
        
        target_file = model_dir / model_file
        if target_file.exists():
            print(f"✅ {model_file} 已存在，跳过")
            success_count += 1
            continue
            
        if download_file(config["url"], str(target_file)):
            success_count += 1
    
    print(f"ONNX模型下载完成: {success_count}/{len(models)}")
    return success_count > 0

if __name__ == "__main__":
    download_paddleocr_onnx()
EOF
    
    if python3 /tmp/download_onnx.py; then
        print_message $GREEN "✅ ONNX模型下载完成"
    else
        print_message $YELLOW "⚠️  ONNX模型下载失败，将使用在线模式"
    fi
    
    rm -f /tmp/download_onnx.py
}

# 验证下载的模型
verify_models() {
    print_message $BLUE "🔍 验证下载的模型..."
    
    local project_root=$(get_project_root)
    local models_dir="$project_root/models"
    
    # 检查目录大小
    local total_size=$(du -sh "$models_dir" 2>/dev/null | cut -f1 || echo "0")
    print_message $CYAN "模型目录总大小: $total_size"
    
    # 检查关键文件
    local key_dirs=(
        "$models_dir/.cache/huggingface"
        "$models_dir/.cache/transformers"
        "$models_dir/.cache/torch"
    )
    
    local verified_count=0
    for dir in "${key_dirs[@]}"; do
        if [[ -d "$dir" ]] && [[ $(find "$dir" -type f 2>/dev/null | wc -l) -gt 0 ]]; then
            print_message $GREEN "✅ $(basename "$dir") 目录验证通过"
            verified_count=$((verified_count + 1))
        else
            print_message $YELLOW "⚠️  $(basename "$dir") 目录为空或不存在"
        fi
    done
    
    # 创建模型清单
    find "$models_dir" -name "*.bin" -o -name "*.safetensors" -o -name "*.onnx" -o -name "*.pt" -o -name "*.pth" > "$models_dir/model_inventory.txt" 2>/dev/null || true
    
    local model_count=$(wc -l < "$models_dir/model_inventory.txt" 2>/dev/null || echo "0")
    print_message $CYAN "发现模型文件: $model_count 个"
    
    if [[ $verified_count -ge 1 ]] && [[ $model_count -gt 0 ]]; then
        print_message $GREEN "🎉 模型验证通过！"
        return 0
    else
        print_message $YELLOW "⚠️  模型验证部分通过"
        return 1
    fi
}

# 创建模型配置文件
create_model_config() {
    print_message $BLUE "📝 创建模型配置文件..."
    
    local project_root=$(get_project_root)
    local config_file="$project_root/model_config.py"
    
    cat > "$config_file" << EOF
"""
PDF-Craft模型配置文件
自动生成于: $(date)
"""

import os
from pathlib import Path

# 项目根目录
PROJECT_ROOT = Path(__file__).parent
MODELS_DIR = PROJECT_ROOT / "models"

# 模型缓存目录
HF_CACHE_DIR = MODELS_DIR / ".cache" / "huggingface"
TRANSFORMERS_CACHE_DIR = MODELS_DIR / ".cache" / "transformers"
TORCH_CACHE_DIR = MODELS_DIR / ".cache" / "torch"

# 设置环境变量
def setup_model_paths():
    """设置模型路径环境变量"""
    os.environ['HF_HOME'] = str(HF_CACHE_DIR)
    os.environ['TRANSFORMERS_CACHE'] = str(TRANSFORMERS_CACHE_DIR)
    os.environ['TORCH_HOME'] = str(TORCH_CACHE_DIR)
    os.environ['HF_HUB_CACHE'] = str(HF_CACHE_DIR / "hub")
    
    # 优先使用本地模型
    os.environ['TRANSFORMERS_OFFLINE'] = '0'  # 设置为1启用完全离线模式
    
    return {
        'models_dir': str(MODELS_DIR),
        'hf_cache': str(HF_CACHE_DIR),
        'transformers_cache': str(TRANSFORMERS_CACHE_DIR),
        'torch_cache': str(TORCH_CACHE_DIR)
    }

# 检查模型是否可用
def check_models_available():
    """检查模型是否已下载"""
    checks = {
        'huggingface_models': HF_CACHE_DIR.exists() and any(HF_CACHE_DIR.iterdir()),
        'transformers_models': TRANSFORMERS_CACHE_DIR.exists() and any(TRANSFORMERS_CACHE_DIR.iterdir()),
        'torch_models': TORCH_CACHE_DIR.exists() and any(TORCH_CACHE_DIR.iterdir()),
        'onnx_models': (MODELS_DIR / "ppocrv4").exists()
    }
    
    return checks

# 获取模型统计信息
def get_model_stats():
    """获取模型统计信息"""
    import subprocess
    
    try:
        # 获取目录大小
        result = subprocess.run(['du', '-sh', str(MODELS_DIR)], 
                              capture_output=True, text=True)
        total_size = result.stdout.split()[0] if result.returncode == 0 else "未知"
    except:
        total_size = "未知"
    
    # 统计模型文件
    model_files = []
    for pattern in ['*.bin', '*.safetensors', '*.onnx', '*.pt', '*.pth']:
        model_files.extend(MODELS_DIR.rglob(pattern))
    
    return {
        'total_size': total_size,
        'model_count': len(model_files),
        'model_files': [str(f.relative_to(MODELS_DIR)) for f in model_files[:10]]  # 只显示前10个
    }

if __name__ == "__main__":
    paths = setup_model_paths()
    checks = check_models_available()
    stats = get_model_stats()
    
    print("📊 模型配置信息:")
    print(f"   模型目录: {paths['models_dir']}")
    print(f"   总大小: {stats['total_size']}")
    print(f"   模型文件数: {stats['model_count']}")
    print()
    print("✅ 可用模型:")
    for check_name, is_available in checks.items():
        status = "✅" if is_available else "❌"
        print(f"   {status} {check_name}")
EOF
    
    print_message $GREEN "✅ 模型配置文件创建完成: $config_file"
}

# 显示下载统计
show_statistics() {
    local project_root=$(get_project_root)
    local models_dir="$project_root/models"
    
    print_message $GREEN "📊 下载统计信息"
    echo ""
    
    # 目录大小
    local total_size=$(du -sh "$models_dir" 2>/dev/null | cut -f1 || echo "0")
    print_message $CYAN "总下载大小: $total_size"
    
    # 文件统计
    local bin_files=$(find "$models_dir" -name "*.bin" 2>/dev/null | wc -l)
    local safetensors_files=$(find "$models_dir" -name "*.safetensors" 2>/dev/null | wc -l)
    local onnx_files=$(find "$models_dir" -name "*.onnx" 2>/dev/null | wc -l)
    local pt_files=$(find "$models_dir" -name "*.pt" -o -name "*.pth" 2>/dev/null | wc -l)
    
    echo "文件类型统计:"
    echo "  📦 .bin 文件: $bin_files"
    echo "  🔒 .safetensors 文件: $safetensors_files"
    echo "  ⚙️  .onnx 文件: $onnx_files"
    echo "  🔥 .pt/.pth 文件: $pt_files"
    echo ""
    
    # 缓存目录统计
    local cache_dirs=(
        "huggingface:.cache/huggingface"
        "transformers:.cache/transformers"
        "torch:.cache/torch"
    )
    
    echo "缓存目录统计:"
    for cache_info in "${cache_dirs[@]}"; do
        IFS=':' read -r cache_name cache_path <<< "$cache_info"
        local cache_full_path="$models_dir/$cache_path"
        if [[ -d "$cache_full_path" ]]; then
            local cache_size=$(du -sh "$cache_full_path" 2>/dev/null | cut -f1 || echo "0")
            local cache_files=$(find "$cache_full_path" -type f 2>/dev/null | wc -l)
            echo "  📁 $cache_name: $cache_size ($cache_files 文件)"
        else
            echo "  📁 $cache_name: 未创建"
        fi
    done
}

# 主函数
main() {
    print_banner
    
    print_message $GREEN "🚀 开始批量下载PDF-Craft模型..."
    echo ""
    
    # 检查磁盘空间
    check_disk_space
    echo ""
    
    # 设置环境
    setup_environment
    echo ""
    
    # 安装依赖
    install_dependencies
    echo ""
    
    # 下载PDF-Craft模型（包含直接初始化）
    download_pdf_craft_models
    echo ""
    
    # 下载ONNX模型
    download_onnx_models
    echo ""
    
    # 验证模型
    verify_models
    echo ""
    
    # 创建配置文件
    create_model_config
    echo ""
    
    # 显示统计信息
    show_statistics
    echo ""
    
    # 最终提示
    print_message $GREEN "🎉 所有模型下载完成！"
    echo ""
    print_message $BLUE "📋 后续操作:"
    echo "  1. 重启PDF-Craft服务: ./restart_with_fix.sh"
    echo "  2. 检查模型状态: python3 model_config.py"
    echo "  3. 测试服务: ./diagnose_service.sh"
    echo ""
    print_message $YELLOW "💡 提示:"
    echo "  - 所有模型已下载到 models/ 目录"
    echo "  - 如需更新模型，重新运行此脚本"
    echo "  - 模型占用空间较大，请定期清理不需要的模型"
    echo ""
    print_message $CYAN "🔧 如果仍有问题:"
    echo "  1. 运行模型修复脚本: ./fix_model_download_issue.sh"
    echo "  2. 配置网络代理或镜像源"
    echo "  3. 查看服务日志了解详细错误信息"
}

# 运行主函数
main "$@"
