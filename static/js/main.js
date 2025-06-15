// 基于光学字符识别和本地大语言模型的文档转换平台- 主要JavaScript文件

document.addEventListener('DOMContentLoaded', function() {
    console.log('页面DOM加载完成，开始初始化...');

    // 初始化所有Bootstrap下拉菜单
    var dropdownElementList = [].slice.call(document.querySelectorAll('.dropdown-toggle'));
    var dropdownList = dropdownElementList.map(function (dropdownToggleEl) {
        return new bootstrap.Dropdown(dropdownToggleEl);
    });

    // 获取DOM元素
    const fileInput = document.getElementById('fileInput');
    const uploadButton = document.getElementById('uploadButton');
    const dropArea = document.getElementById('drop-area');
    const fileList = document.getElementById('file-list');
    const pendingFiles = document.getElementById('pending-files');
    const clearFilesBtn = document.getElementById('clearFiles');
    const jobsTableBody = document.getElementById('jobsTableBody');
    const useCustomConfig = document.getElementById('use-custom-config');
    const updateBatchSizeBtn = document.getElementById('update-batch-size');
    const batchSizeInput = document.getElementById('batch-size-input');
    const gpuToggle = document.getElementById('gpu-toggle');
    const deviceType = document.getElementById('device-type');
    const saveConfigBtn = document.getElementById('save-config');
    const resetConfigBtn = document.getElementById('reset-config');
    const ocrLevelSelect = document.getElementById('ocr-level');
    const tableFormatSelect = document.getElementById('table-format');
    const extractFormulaCheckbox = document.getElementById('extract-formula');
    const ollamaModelSelect = document.getElementById('ollama-model');
    const toggleConfigBtn = document.getElementById('toggle-config-panel');
    const configPanel = document.getElementById('config-panel');
    const showSystemInfoBtn = document.getElementById('show-system-info');
    const systemInfoModal = document.getElementById('systemInfoModal');
    const closeModalBtn = document.querySelector('.close');
    const clearJobsBtn = document.getElementById('clear-jobs');
    const changeModeBtn = document.getElementById('change-mode-btn');
    const runModeSpan = document.getElementById('run-mode');
    const queueCount = document.getElementById('queue-count');
    const batchSizeSpan = document.getElementById('batch-size');

    console.log('元素检查结果:');
    console.log('fileInput:', !!fileInput);
    console.log('uploadButton:', !!uploadButton);
    console.log('dropArea:', !!dropArea);
    console.log('toggleConfigBtn:', !!toggleConfigBtn);
    console.log('configPanel:', !!configPanel);
    console.log('showSystemInfoBtn:', !!showSystemInfoBtn);
    console.log('systemInfoModal:', !!systemInfoModal);
    console.log('saveConfigBtn:', !!saveConfigBtn);
    console.log('resetConfigBtn:', !!resetConfigBtn);

    // 待上传文件列表
    let selectedFiles = [];

    // 拖放文件功能
    if (dropArea && fileInput) {
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            dropArea.addEventListener(eventName, function(e) {
                e.preventDefault();
                e.stopPropagation();
            }, false);
        });

        ['dragenter', 'dragover'].forEach(eventName => {
            dropArea.addEventListener(eventName, function() {
                dropArea.classList.add('highlight');
            }, false);
        });

        ['dragleave', 'drop'].forEach(eventName => {
            dropArea.addEventListener(eventName, function() {
                dropArea.classList.remove('highlight');
            }, false);
        });

        dropArea.addEventListener('drop', function(e) {
            const dt = e.dataTransfer;
            const files = dt.files;
            handleFiles(files);
        }, false);

        // 文件选择变化
        fileInput.addEventListener('change', function() {
            console.log('文件选择事件触发, files:', this.files);
            handleFiles(this.files);
        });
    }

    // 处理选择的文件
    function handleFiles(files) {
        console.log('handleFiles called with:', files);
        console.log('files length:', files.length);
        
        const pdfFiles = Array.from(files).filter(file => {
            console.log('检查文件:', file.name, 'type:', file.type);
            return file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf');
        });

        console.log('PDF文件数量:', pdfFiles.length);

        if (pdfFiles.length === 0) {
            showMessage('请选择PDF文件', 'error');
            return;
        }

        selectedFiles = pdfFiles;
        console.log('selectedFiles updated:', selectedFiles);
        updateFileList();
    }

    // 更新文件列表显示
    function updateFileList() {
        console.log('updateFileList called, selectedFiles:', selectedFiles);
        console.log('fileList element:', fileList);
        console.log('pendingFiles element:', pendingFiles);
        
        if (selectedFiles.length === 0) {
            if (fileList) {
                fileList.style.display = 'none';
            }
            return;
        }

        if (fileList) {
            fileList.style.display = 'block';
        }
        if (pendingFiles) {
            pendingFiles.innerHTML = '';
        }

        selectedFiles.forEach((file, index) => {
            const li = document.createElement('li');
            li.className = 'list-group-item d-flex justify-content-between align-items-center';
            li.innerHTML = `
                <span>
                    <i class="fas fa-file-pdf text-danger"></i> 
                    ${file.name}
                    <small class="text-muted">(${formatFileSize(file.size)})</small>
                </span>
                <button type="button" class="btn btn-sm btn-outline-danger" onclick="removeFile(${index})">
                    <i class="fas fa-times"></i>
                </button>
            `;
            pendingFiles.appendChild(li);
        });
    }

    // 格式化文件大小
    function formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    // 移除文件
    window.removeFile = function(index) {
        selectedFiles.splice(index, 1);
        updateFileList();
    };

    // 清空文件列表
    if (clearFilesBtn) {
        clearFilesBtn.addEventListener('click', function() {
            selectedFiles = [];
            fileInput.value = '';
            updateFileList();
        });
    }

    // 上传按钮
    if (uploadButton) {
        uploadButton.addEventListener('click', function(e) {
            e.preventDefault();

            if (selectedFiles.length === 0) {
                showMessage('请先选择PDF文件', 'error');
                return;
            }

            const formData = new FormData();
            selectedFiles.forEach(file => {
                formData.append('files[]', file);
            });

            if (useCustomConfig && useCustomConfig.checked) {
                formData.append('use_custom_config', 'true');
                const ocrEngineSelect = document.getElementById('ocr-engine');
                const ocrLanguageSelect = document.getElementById('ocr-language');
                formData.append('ocr_engine', ocrEngineSelect ? ocrEngineSelect.value : 'pdf_craft');
                formData.append('ocr_level', ocrLevelSelect.value);
                
                // 处理语言选择
                const languageValue = ocrLanguageSelect ? ocrLanguageSelect.value : 'auto';
                formData.append('ocr_language', languageValue);
                
                // 如果是智能分离识别，添加选中的语言
                if (languageValue === 'smart_separate') {
                    const selectedLanguages = document.querySelectorAll('input[name="selected_languages"]:checked');
                    selectedLanguages.forEach(checkbox => {
                        formData.append('selected_languages', checkbox.value);
                    });
                }
                
                // 如果是自定义语言组合，添加自定义语言
                if (languageValue === 'custom') {
                    const customLanguages = document.getElementById('custom-languages');
                    if (customLanguages && customLanguages.value) {
                        formData.append('custom_languages', customLanguages.value);
                    }
                }
                
                formData.append('extract_table_format', tableFormatSelect.value);
                formData.append('extract_formula', extractFormulaCheckbox.checked);
                formData.append('ollama_model', ollamaModelSelect.value);
            }

            uploadButton.disabled = true;
            uploadButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> 上传中...';

            fetch('/upload', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showMessage(`成功上传 ${data.jobs.length} 个文件`, 'success');
                    selectedFiles = [];
                    fileInput.value = '';
                    updateFileList();
                    loadJobs();
                } else {
                    showMessage(`上传失败: ${data.error || '未知错误'}`, 'error');
                }
            })
            .catch(error => {
                console.error('上传错误:', error);
                showMessage(`上传出错: ${error.message}`, 'error');
            })
            .finally(() => {
                uploadButton.disabled = false;
                uploadButton.innerHTML = '<i class="fas fa-rocket"></i> 开始处理';
            });
        });
    }

    // 运行模式选择
    if (changeModeBtn) {
        changeModeBtn.addEventListener('click', function() {
            console.log('运行模式按钮被点击');
            showRunModePopup();
        });
    }

    // 显示运行模式弹出层
    function showRunModePopup() {
        const popup = document.getElementById('runModePopup');
        if (popup) {
            popup.style.display = 'flex';
            loadRunMode();
        }
    }

    // 关闭运行模式弹出层
    function closeRunModePopup() {
        const popup = document.getElementById('runModePopup');
        if (popup) {
            popup.style.display = 'none';
        }
    }

    // 绑定运行模式关闭事件
    const closeRunModeBtn = document.getElementById('closeRunMode');
    const cancelRunModeBtn = document.getElementById('cancelRunMode');
    const runModeBackdrop = document.querySelector('#runModePopup .popup-backdrop');

    if (closeRunModeBtn) {
        closeRunModeBtn.addEventListener('click', closeRunModePopup);
    }
    if (cancelRunModeBtn) {
        cancelRunModeBtn.addEventListener('click', closeRunModePopup);
    }
    if (runModeBackdrop) {
        runModeBackdrop.addEventListener('click', closeRunModePopup);
    }

    // 加载运行模式
    function loadRunMode() {
        fetch('/run_mode')
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                console.log('当前运行模式:', data.current_mode);
                // 高亮当前模式
                document.querySelectorAll('.mode-option').forEach(btn => {
                    btn.classList.remove('active');
                    if (btn.dataset.mode === data.current_mode) {
                        btn.classList.add('active');
                    }
                });
            })
            .catch(error => {
                console.error('加载运行模式失败:', error);
                showMessage('加载运行模式失败', 'error');
            });
    }

    // 模式选择
    document.querySelectorAll('.mode-option').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('选择模式:', this.dataset.mode);
            document.querySelectorAll('.mode-option').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });

    // 应用运行模式
    const applyModeBtn = document.getElementById('apply-mode');
    if (applyModeBtn) {
        applyModeBtn.addEventListener('click', function() {
            const selectedMode = document.querySelector('.mode-option.active');
            if (!selectedMode) {
                showMessage('请选择一个运行模式', 'error');
                return;
            }

            const mode = selectedMode.dataset.mode;
            
            fetch('/run_mode', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ mode: mode })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showMessage(data.message, 'success');
                    updateRunModeDisplay(mode);
                    closeRunModePopup();
                    
                    // 重新加载系统信息
                    loadSystemInfoToPopup();
                } else {
                    showMessage(`切换失败: ${data.error}`, 'error');
                }
            })
            .catch(error => {
                showMessage(`切换出错: ${error.message}`, 'error');
            });
        });
    }

    // 更新运行模式显示
    function updateRunModeDisplay(mode) {
        const modeNames = {
            'compatible': '兼容模式',
            'balanced': '平衡模式',
            'performance': '性能模式'
        };
        if (runModeSpan) {
            runModeSpan.textContent = modeNames[mode] || mode;
        }
    }

    // GPU切换
    if (gpuToggle) {
        gpuToggle.addEventListener('change', function() {
            fetch('/toggle_gpu', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            })
            .then(response => response.json())
            .then(data => {
                if (deviceType) {
                    deviceType.textContent = data.use_gpu ? 'GPU' : 'CPU';
                }
                showMessage(`已切换到${data.use_gpu ? 'GPU' : 'CPU'}模式`, 'info');
            })
            .catch(error => {
                console.error('GPU切换错误:', error);
                gpuToggle.checked = !gpuToggle.checked;
                showMessage('GPU切换失败', 'error');
            });
        });
    }

    // 批处理大小更新
    if (updateBatchSizeBtn && batchSizeInput) {
        updateBatchSizeBtn.addEventListener('click', function() {
            const batchSize = parseInt(batchSizeInput.value);
            if (isNaN(batchSize) || batchSize < 1 || batchSize > 10) {
                showMessage('批处理大小必须是1到10之间的数字', 'error');
                return;
            }

            fetch('/batch_size', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ batch_size: batchSize })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showMessage(`批处理大小已设置为 ${data.batch_size}`, 'success');
                    if (batchSizeSpan) {
                        batchSizeSpan.textContent = data.batch_size;
                    }
                } else {
                    showMessage(`设置失败: ${data.error}`, 'error');
                }
            })
            .catch(error => {
                showMessage(`设置出错: ${error.message}`, 'error');
            });
        });
    }

    // 配置选择变化事件
    if (ocrLevelSelect) {
        ocrLevelSelect.addEventListener('change', function() {
            const descriptions = {
                'fast': '快速OCR处理，适合简单文档',
                'standard': '标准OCR处理，平衡速度和准确性',
                'accurate': '高精度OCR处理，适合复杂文档',
                'detailed': '最详细的OCR处理，包含更多元数据'
            };
            document.getElementById('ocr-level-description').textContent = 
                descriptions[this.value] || '';
        });
    }

    if (tableFormatSelect) {
        tableFormatSelect.addEventListener('change', function() {
            const descriptions = {
                'none': '跳过表格提取',
                'simple': '基本表格提取',
                'standard': '标准表格处理，保持格式',
                'advanced': '高级表格处理，包含样式信息'
            };
            document.getElementById('table-format-description').textContent = 
                descriptions[this.value] || '';
        });
    }

    if (ollamaModelSelect) {
        ollamaModelSelect.addEventListener('change', function() {
            const descriptions = {
                'none': '不使用大语言模型进行处理',
                'llama3': '使用Llama 3模型进行处理',
                'mistral': '使用Mistral模型进行处理',
                'gemma': '使用Gemma模型进行处理',
                'phi3': '使用Phi-3模型进行处理'
            };
            const descElement = document.getElementById('ollama-model-description');
            if (descElement) {
                descElement.textContent = descriptions[this.value] || '';
            }
        });
    }

    // OCR引擎选择变化事件
    const ocrEngineSelect = document.getElementById('ocr-engine');
    const ocrLanguageSelect = document.getElementById('ocr-language');
    
    if (ocrEngineSelect) {
        ocrEngineSelect.addEventListener('change', function() {
            const descriptions = {
                'pdf_craft': '原始PDF-Craft引擎，支持复杂文档结构',
                'tesseract': 'Google Tesseract OCR，支持100+语言',
                'easyocr': '高精度深度学习OCR，支持80+语言',
                'paddleocr': '百度PaddleOCR，中文识别效果优秀',
                'rapidocr': '轻量级高速OCR，基于ONNX Runtime'
            };
            const descElement = document.getElementById('ocr-engine-description');
            if (descElement) {
                descElement.textContent = descriptions[this.value] || '';
            }
        });
    }

    if (ocrLanguageSelect) {
        ocrLanguageSelect.addEventListener('change', function() {
            const descriptions = {
                'auto': '自动检测文档语言',
                'chinese': '简体中文和繁体中文',
                'english': '英语文档',
                'japanese': '日语文档',
                'korean': '韩语文档',
                'french': '法语文档',
                'german': '德语文档',
                'spanish': '西班牙语文档',
                'russian': '俄语文档',
                'arabic': '阿拉伯语文档'
            };
            const descElement = document.getElementById('ocr-language-description');
            if (descElement) {
                descElement.textContent = descriptions[this.value] || '';
            }
        });
    }

    // OCR引擎性能对比
    const benchmarkOcrBtn = document.getElementById('benchmark-ocr');
    if (benchmarkOcrBtn) {
        benchmarkOcrBtn.addEventListener('click', function() {
            showOcrBenchmarkPopup();
        });
    }

    // 刷新OCR引擎
    const refreshEnginesBtn = document.getElementById('refresh-engines');
    if (refreshEnginesBtn) {
        refreshEnginesBtn.addEventListener('click', function() {
            refreshOcrEngines();
        });
    }

    // 显示OCR性能对比弹出层
    function showOcrBenchmarkPopup() {
        const popup = document.getElementById('ocrBenchmarkPopup');
        if (popup) {
            popup.style.display = 'flex';
            runOcrBenchmark();
        }
    }

    // 关闭OCR性能对比弹出层
    function closeOcrBenchmarkPopup() {
        const popup = document.getElementById('ocrBenchmarkPopup');
        if (popup) {
            popup.style.display = 'none';
        }
    }

    // 绑定OCR性能对比关闭事件
    const closeBenchmarkBtn = document.getElementById('closeBenchmark');
    const closeBenchmarkFooterBtn = document.getElementById('closeBenchmarkBtn');
    const runBenchmarkBtn = document.getElementById('runBenchmark');
    const benchmarkBackdrop = document.querySelector('#ocrBenchmarkPopup .popup-backdrop');

    if (closeBenchmarkBtn) {
        closeBenchmarkBtn.addEventListener('click', closeOcrBenchmarkPopup);
    }
    if (closeBenchmarkFooterBtn) {
        closeBenchmarkFooterBtn.addEventListener('click', closeOcrBenchmarkPopup);
    }
    if (runBenchmarkBtn) {
        runBenchmarkBtn.addEventListener('click', runOcrBenchmark);
    }
    if (benchmarkBackdrop) {
        benchmarkBackdrop.addEventListener('click', closeOcrBenchmarkPopup);
    }

    // 运行OCR性能测试
    function runOcrBenchmark() {
        const benchmarkContent = document.getElementById('benchmarkContent');
        if (!benchmarkContent) return;

        // 显示加载中
        benchmarkContent.innerHTML = `
            <div class="text-center">
                <div class="spinner-border text-primary" role="status">
                    <span class="sr-only">测试中...</span>
                </div>
                <p class="mt-2">正在测试各OCR引擎性能，请稍候...</p>
            </div>
        `;

        // 获取第一个已上传的文件作为测试文件
        const firstJob = Object.values(jobs || {}).find(job => job.file_path);
        const testFile = firstJob ? firstJob.file_path : null;

        if (!testFile) {
            benchmarkContent.innerHTML = `
                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle"></i>
                    需要先上传一个PDF文件才能进行性能测试
                </div>
            `;
            return;
        }

        fetch('/benchmark_ocr', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ test_file: testFile })
        })
        .then(response => response.json())
        .then(data => {
            if (data.benchmark_results) {
                displayBenchmarkResults(data.benchmark_results);
            } else {
                benchmarkContent.innerHTML = `
                    <div class="alert alert-danger">
                        <i class="fas fa-times-circle"></i>
                        性能测试失败: ${data.error || '未知错误'}
                    </div>
                `;
            }
        })
        .catch(error => {
            console.error('OCR性能测试失败:', error);
            benchmarkContent.innerHTML = `
                <div class="alert alert-danger">
                    <i class="fas fa-times-circle"></i>
                    性能测试出错: ${error.message}
                </div>
            `;
        });
    }

    // 显示性能测试结果
    function displayBenchmarkResults(results) {
        const benchmarkContent = document.getElementById('benchmarkContent');
        if (!benchmarkContent) return;

        let html = '<div class="table-responsive">';
        html += '<table class="table table-striped">';
        html += '<thead><tr><th>OCR引擎</th><th>状态</th><th>处理速度</th><th>平均页面时间</th><th>字符数</th><th>字符/秒</th></tr></thead>';
        html += '<tbody>';

        for (const [engineName, result] of Object.entries(results)) {
            html += '<tr>';
            html += `<td><strong>${engineName}</strong></td>`;
            
            if (result.available) {
                html += '<td><span class="badge badge-success">可用</span></td>';
                html += `<td>${result.pages_per_second ? result.pages_per_second.toFixed(2) + ' 页/秒' : '未知'}</td>`;
                html += `<td>${result.avg_page_time ? result.avg_page_time.toFixed(2) + ' 秒' : '未知'}</td>`;
                html += `<td>${result.total_text_length || 0}</td>`;
                html += `<td>${result.chars_per_second ? result.chars_per_second.toFixed(0) : '0'}</td>`;
            } else {
                html += '<td><span class="badge badge-danger">不可用</span></td>';
                html += `<td colspan="4"><small class="text-muted">${result.error || '引擎不可用'}</small></td>`;
            }
            
            html += '</tr>';
        }

        html += '</tbody></table></div>';

        // 添加推荐
        const availableResults = Object.entries(results).filter(([_, result]) => result.available);
        if (availableResults.length > 0) {
            const fastest = availableResults.reduce((prev, curr) => 
                (curr[1].pages_per_second || 0) > (prev[1].pages_per_second || 0) ? curr : prev
            );
            
            html += `
                <div class="alert alert-info mt-3">
                    <i class="fas fa-lightbulb"></i>
                    <strong>推荐:</strong> ${fastest[0]} 引擎在此测试中表现最佳 
                    (${fastest[1].pages_per_second ? fastest[1].pages_per_second.toFixed(2) + ' 页/秒' : ''})
                </div>
            `;
        }

        benchmarkContent.innerHTML = html;
    }

    // 刷新OCR引擎
    function refreshOcrEngines() {
        fetch('/ocr_engines')
        .then(response => response.json())
        .then(data => {
            if (data.engines) {
                updateOcrEngineOptions(data.engines);
                showMessage('OCR引擎列表已刷新', 'success');
            } else {
                showMessage(`刷新失败: ${data.error}`, 'error');
            }
        })
        .catch(error => {
            showMessage(`刷新出错: ${error.message}`, 'error');
        });
    }

    // 更新OCR引擎选项
    function updateOcrEngineOptions(engines) {
        if (!ocrEngineSelect) return;

        // 保存当前选择
        const currentValue = ocrEngineSelect.value;
        
        // 清空并重新填充选项
        ocrEngineSelect.innerHTML = '';
        
        for (const [key, engine] of Object.entries(engines)) {
            const option = document.createElement('option');
            option.value = key;
            option.textContent = engine.name + (engine.available ? '' : ' (不可用)');
            option.disabled = !engine.available;
            
            if (key === currentValue) {
                option.selected = true;
            }
            
            ocrEngineSelect.appendChild(option);
        }
    }

    // 保存配置
    if (saveConfigBtn) {
        saveConfigBtn.addEventListener('click', function() {
            const config = {
                ocr_engine: ocrEngineSelect ? ocrEngineSelect.value : 'pdf_craft',
                ocr_level: ocrLevelSelect.value,
                ocr_language: ocrLanguageSelect ? ocrLanguageSelect.value : 'auto',
                extract_table_format: tableFormatSelect.value,
                extract_formula: extractFormulaCheckbox.checked,
                ollama_model: ollamaModelSelect.value
            };

            fetch('/update_config', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(config)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showMessage('配置已保存', 'success');
                } else {
                    showMessage(`保存失败: ${data.error}`, 'error');
                }
            })
            .catch(error => {
                showMessage(`保存出错: ${error.message}`, 'error');
            });
        });
    }

    // 重置配置
    if (resetConfigBtn) {
        resetConfigBtn.addEventListener('click', function() {
            if (confirm('确定要重置为默认配置吗？')) {
                fetch('/reset_config', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // 更新界面
                        if (data.config.ocr_level) ocrLevelSelect.value = data.config.ocr_level;
                        if (data.config.extract_table_format) tableFormatSelect.value = data.config.extract_table_format;
                        if (data.config.extract_formula !== undefined) extractFormulaCheckbox.checked = data.config.extract_formula;
                        if (data.config.ollama_model) ollamaModelSelect.value = data.config.ollama_model;
                        
                        // 触发change事件更新描述
                        ocrLevelSelect.dispatchEvent(new Event('change'));
                        tableFormatSelect.dispatchEvent(new Event('change'));
                        ollamaModelSelect.dispatchEvent(new Event('change'));
                        
                        showMessage('配置已重置为默认值', 'success');
                    } else {
                        showMessage(`重置失败: ${data.error}`, 'error');
                    }
                })
                .catch(error => {
                    showMessage(`重置出错: ${error.message}`, 'error');
                });
            }
        });
    }

    // 清空所有任务
    if (clearJobsBtn) {
        clearJobsBtn.addEventListener('click', function() {
            if (confirm('确定要清空所有任务和相关文件吗？此操作不可撤销！')) {
                clearJobsBtn.disabled = true;
                clearJobsBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> 清空中...';

                fetch('/clear_all_jobs', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showMessage('所有任务和文件已清空', 'success');
                        loadJobs();
                    } else {
                        showMessage(`清空失败: ${data.error}`, 'error');
                    }
                })
                .catch(error => {
                    showMessage(`清空出错: ${error.message}`, 'error');
                })
                .finally(() => {
                    clearJobsBtn.disabled = false;
                    clearJobsBtn.innerHTML = '<i class="fas fa-trash"></i> 清空队列';
                });
            }
        });
    }

    // 系统信息
    if (showSystemInfoBtn) {
        showSystemInfoBtn.addEventListener('click', function() {
            console.log('系统信息按钮被点击');
            showSystemInfoPopup();
        });
    }

    // 显示系统信息弹出层
    function showSystemInfoPopup() {
        const popup = document.getElementById('systemInfoPopup');
        if (popup) {
            popup.style.display = 'flex';
            loadSystemInfoToPopup();
        }
    }

    // 关闭系统信息弹出层
    function closeSystemInfoPopup() {
        const popup = document.getElementById('systemInfoPopup');
        if (popup) {
            popup.style.display = 'none';
        }
    }

    // 绑定关闭事件
    const closeSystemInfoBtn = document.getElementById('closeSystemInfo');
    const closeSystemInfoFooterBtn = document.getElementById('closeSystemInfoBtn');
    const systemInfoBackdrop = document.querySelector('#systemInfoPopup .popup-backdrop');

    if (closeSystemInfoBtn) {
        closeSystemInfoBtn.addEventListener('click', closeSystemInfoPopup);
    }
    if (closeSystemInfoFooterBtn) {
        closeSystemInfoFooterBtn.addEventListener('click', closeSystemInfoPopup);
    }
    if (systemInfoBackdrop) {
        systemInfoBackdrop.addEventListener('click', closeSystemInfoPopup);
    }

    // 加载系统信息到弹出层
    function loadSystemInfoToPopup() {
        const systemInfoContent = document.getElementById('systemInfoPopupContent');
        if (!systemInfoContent) return;

        // 显示加载中
        systemInfoContent.innerHTML = `
            <div class="text-center">
                <div class="spinner-border text-primary" role="status">
                    <span class="sr-only">加载中...</span>
                </div>
            </div>
        `;

        fetch('/system_info')
            .then(response => response.json())
            .then(data => {
                let html = '<div class="row">';
                
                // 系统信息
                html += `
                    <div class="col-md-6">
                        <h6 class="text-primary">系统信息</h6>
                        <table class="table table-sm">
                            <tr><td>操作系统</td><td>${data.os_info || '未知'}</td></tr>
                            <tr><td>Python版本</td><td>${data.python_version || '未知'}</td></tr>
                            <tr><td>模型目录</td><td>${data.model_dir || '未知'}</td></tr>
                        </table>
                    </div>
                `;
                
                // GPU信息
                html += `
                    <div class="col-md-6">
                        <h6 class="text-primary">GPU信息</h6>
                        <table class="table table-sm">
                            <tr><td>CUDA可用</td><td>${data.cuda_available ? '<span class="text-success">是</span>' : '<span class="text-danger">否</span>'}</td></tr>
                            <tr><td>GPU数量</td><td>${data.cuda_device_count || 0}</td></tr>
                            <tr><td>设备名称</td><td>${data.cuda_device_name || '无'}</td></tr>
                            <tr><td>当前使用</td><td>${data.use_gpu ? 'GPU' : 'CPU'}</td></tr>
                        </table>
                    </div>
                `;
                
                // CPU和内存信息
                if (data.cpu_info) {
                    html += `
                        <div class="col-md-6">
                            <h6 class="text-primary">CPU和内存</h6>
                            <table class="table table-sm">
                                <tr><td>CPU核心数</td><td>${data.cpu_info.cpu_count || '未知'}</td></tr>
                                <tr><td>CPU使用率</td><td>${data.cpu_info.cpu_percent || 0}%</td></tr>
                                <tr><td>总内存</td><td>${data.cpu_info.memory_total ? data.cpu_info.memory_total.toFixed(1) + ' GB' : '未知'}</td></tr>
                                <tr><td>可用内存</td><td>${data.cpu_info.memory_available ? data.cpu_info.memory_available.toFixed(1) + ' GB' : '未知'}</td></tr>
                                <tr><td>内存使用率</td><td>${data.cpu_info.memory_percent || 0}%</td></tr>
                            </table>
                        </div>
                    `;
                }
                
                // 队列信息
                if (data.queue_info) {
                    html += `
                        <div class="col-md-6">
                            <h6 class="text-primary">处理队列</h6>
                            <table class="table table-sm">
                                <tr><td>排队作业</td><td>${data.queue_info.queued_jobs || 0}</td></tr>
                                <tr><td>活跃作业</td><td>${data.queue_info.active_jobs || 0}</td></tr>
                                <tr><td>批处理大小</td><td>${data.queue_info.batch_size || 5}</td></tr>
                                <tr><td>最大工作线程</td><td>${data.queue_info.max_workers || 4}</td></tr>
                            </table>
                        </div>
                    `;
                    
                    // 更新页面上的队列信息
                    if (queueCount) {
                        queueCount.textContent = data.queue_info.active_jobs || 0;
                    }
                }
                
                // 优化配置
                if (data.optimization_config) {
                    html += `
                        <div class="col-md-6">
                            <h6 class="text-primary">优化配置</h6>
                            <table class="table table-sm">
                                <tr><td>多进程处理</td><td>${data.optimization_config.multiprocessing_enabled ? '<span class="text-success">启用</span>' : '<span class="text-muted">禁用</span>'}</td></tr>
                                <tr><td>混合精度</td><td>${data.optimization_config.mixed_precision_enabled ? '<span class="text-success">启用</span>' : '<span class="text-muted">禁用</span>'}</td></tr>
                                <tr><td>内存优化</td><td>${data.optimization_config.memory_optimization_enabled ? '<span class="text-success">启用</span>' : '<span class="text-muted">禁用</span>'}</td></tr>
                                <tr><td>模型预加载</td><td>${data.optimization_config.model_preloading_enabled ? '<span class="text-success">启用</span>' : '<span class="text-muted">禁用</span>'}</td></tr>
                            </table>
                        </div>
                    `;
                }
                
                // Ollama状态
                html += `
                    <div class="col-md-6">
                        <h6 class="text-primary">AI模型服务</h6>
                        <table class="table table-sm">
                            <tr><td>Ollama服务</td><td>${data.ollama_available ? '<span class="text-success">可用</span>' : '<span class="text-danger">不可用</span>'}</td></tr>
                            <tr><td>可用模型数</td><td>${data.ollama_models ? data.ollama_models.length : 0}</td></tr>
                        </table>
                    </div>
                `;
                
                html += '</div>';
                
                // 性能统计
                if (data.performance_stats) {
                    html += `
                        <div class="mt-3">
                            <h6 class="text-primary">性能统计</h6>
                            <table class="table table-sm">
                                <tr><td>总处理页数</td><td>${data.performance_stats.total_pages_processed || 0}</td></tr>
                                <tr><td>平均处理速度</td><td>${data.performance_stats.average_pages_per_second ? data.performance_stats.average_pages_per_second.toFixed(2) + ' 页/秒' : '未知'}</td></tr>
                            </table>
                        </div>
                    `;
                }
                
                systemInfoContent.innerHTML = html;
            })
            .catch(error => {
                console.error('加载系统信息失败:', error);
                systemInfoContent.innerHTML = '<div class="alert alert-danger">加载系统信息失败</div>';
            });
    }

    // 加载系统信息
    function loadSystemInfo() {
        const systemInfoContent = document.getElementById('systemInfoContent');
        if (!systemInfoContent) return;

        // 显示加载中
        systemInfoContent.innerHTML = `
            <div class="text-center">
                <div class="spinner-border text-primary" role="status">
                    <span class="sr-only">加载中...</span>
                </div>
            </div>
        `;

        fetch('/system_info')
            .then(response => response.json())
            .then(data => {
                let html = '<div class="row">';
                
                // 系统信息
                html += `
                    <div class="col-md-6">
                        <h6 class="text-primary">系统信息</h6>
                        <table class="table table-sm">
                            <tr><td>操作系统</td><td>${data.os_info || '未知'}</td></tr>
                            <tr><td>Python版本</td><td>${data.python_version || '未知'}</td></tr>
                            <tr><td>模型目录</td><td>${data.model_dir || '未知'}</td></tr>
                        </table>
                    </div>
                `;
                
                // GPU信息
                html += `
                    <div class="col-md-6">
                        <h6 class="text-primary">GPU信息</h6>
                        <table class="table table-sm">
                            <tr><td>CUDA可用</td><td>${data.cuda_available ? '<span class="text-success">是</span>' : '<span class="text-danger">否</span>'}</td></tr>
                            <tr><td>GPU数量</td><td>${data.cuda_device_count || 0}</td></tr>
                            <tr><td>设备名称</td><td>${data.cuda_device_name || '无'}</td></tr>
                            <tr><td>当前使用</td><td>${data.use_gpu ? 'GPU' : 'CPU'}</td></tr>
                        </table>
                    </div>
                `;
                
                // CPU和内存信息
                if (data.cpu_info) {
                    html += `
                        <div class="col-md-6">
                            <h6 class="text-primary">CPU和内存</h6>
                            <table class="table table-sm">
                                <tr><td>CPU核心数</td><td>${data.cpu_info.cpu_count || '未知'}</td></tr>
                                <tr><td>CPU使用率</td><td>${data.cpu_info.cpu_percent || 0}%</td></tr>
                                <tr><td>总内存</td><td>${data.cpu_info.memory_total ? data.cpu_info.memory_total.toFixed(1) + ' GB' : '未知'}</td></tr>
                                <tr><td>可用内存</td><td>${data.cpu_info.memory_available ? data.cpu_info.memory_available.toFixed(1) + ' GB' : '未知'}</td></tr>
                                <tr><td>内存使用率</td><td>${data.cpu_info.memory_percent || 0}%</td></tr>
                            </table>
                        </div>
                    `;
                }
                
                // 队列信息
                if (data.queue_info) {
                    html += `
                        <div class="col-md-6">
                            <h6 class="text-primary">处理队列</h6>
                            <table class="table table-sm">
                                <tr><td>排队作业</td><td>${data.queue_info.queued_jobs || 0}</td></tr>
                                <tr><td>活跃作业</td><td>${data.queue_info.active_jobs || 0}</td></tr>
                                <tr><td>批处理大小</td><td>${data.queue_info.batch_size || 5}</td></tr>
                                <tr><td>最大工作线程</td><td>${data.queue_info.max_workers || 4}</td></tr>
                            </table>
                        </div>
                    `;
                    
                    // 更新页面上的队列信息
                    if (queueCount) {
                        queueCount.textContent = data.queue_info.active_jobs || 0;
                    }
                }
                
                // 优化配置
                if (data.optimization_config) {
                    html += `
                        <div class="col-md-6">
                            <h6 class="text-primary">优化配置</h6>
                            <table class="table table-sm">
                                <tr><td>多进程处理</td><td>${data.optimization_config.multiprocessing_enabled ? '<span class="text-success">启用</span>' : '<span class="text-muted">禁用</span>'}</td></tr>
                                <tr><td>混合精度</td><td>${data.optimization_config.mixed_precision_enabled ? '<span class="text-success">启用</span>' : '<span class="text-muted">禁用</span>'}</td></tr>
                                <tr><td>内存优化</td><td>${data.optimization_config.memory_optimization_enabled ? '<span class="text-success">启用</span>' : '<span class="text-muted">禁用</span>'}</td></tr>
                                <tr><td>模型预加载</td><td>${data.optimization_config.model_preloading_enabled ? '<span class="text-success">启用</span>' : '<span class="text-muted">禁用</span>'}</td></tr>
                            </table>
                        </div>
                    `;
                }
                
                // Ollama状态
                html += `
                    <div class="col-md-6">
                        <h6 class="text-primary">AI模型服务</h6>
                        <table class="table table-sm">
                            <tr><td>Ollama服务</td><td>${data.ollama_available ? '<span class="text-success">可用</span>' : '<span class="text-danger">不可用</span>'}</td></tr>
                            <tr><td>可用模型数</td><td>${data.ollama_models ? data.ollama_models.length : 0}</td></tr>
                        </table>
                    </div>
                `;
                
                html += '</div>';
                
                // 性能统计
                if (data.performance_stats) {
                    html += `
                        <div class="mt-3">
                            <h6 class="text-primary">性能统计</h6>
                            <table class="table table-sm">
                                <tr><td>总处理页数</td><td>${data.performance_stats.total_pages_processed || 0}</td></tr>
                                <tr><td>平均处理速度</td><td>${data.performance_stats.average_pages_per_second ? data.performance_stats.average_pages_per_second.toFixed(2) + ' 页/秒' : '未知'}</td></tr>
                            </table>
                        </div>
                    `;
                }
                
                systemInfoContent.innerHTML = html;
            })
            .catch(error => {
                console.error('加载系统信息失败:', error);
                systemInfoContent.innerHTML = '<div class="alert alert-danger">加载系统信息失败</div>';
            });
    }

    // 加载作业列表
    function loadJobs() {
        fetch('/jobs')
            .then(response => response.json())
            .then(data => {
                if (data.jobs && jobsTableBody) {
                    jobsTableBody.innerHTML = '';

                    if (data.jobs.length === 0) {
                        jobsTableBody.innerHTML = `
                            <tr>
                                <td colspan="4" class="text-center text-muted">
                                    暂无处理任务
                                </td>
                            </tr>
                        `;
                        return;
                    }

                    data.jobs.forEach(job => {
                        const row = document.createElement('tr');
                        const progress = job.progress ? job.progress.percentage || 0 : 0;
                        const originalName = job.original_filename || job.filename || '未知文件';

                        let statusBadge = '';
                        switch(job.status) {
                            case 'queued':
                                statusBadge = '<span class="badge bg-warning">排队中</span>';
                                break;
                            case 'processing':
                                statusBadge = '<span class="badge bg-info">处理中</span>';
                                break;
                            case 'completed':
                                statusBadge = '<span class="badge bg-success">已完成</span>';
                                break;
                            case 'failed':
                                statusBadge = '<span class="badge bg-danger">失败</span>';
                                break;
                            default:
                                statusBadge = `<span class="badge bg-secondary">${job.status}</span>`;
                        }

                        let progressHtml = '';
                        if (job.status === 'processing') {
                            progressHtml = `
                                <div class="progress" style="height: 20px;">
                                    <div class="progress-bar progress-bar-striped progress-bar-animated" 
                                         role="progressbar" style="width: ${progress}%">
                                        ${progress}%
                                    </div>
                                </div>
                            `;
                            if (job.progress && job.progress.pages_per_second) {
                                progressHtml += `<small class="text-muted">${job.progress.pages_per_second} 页/秒</small>`;
                            }
                        } else if (job.status === 'completed') {
                            progressHtml = '<span class="text-success">100%</span>';
                        } else if (job.status === 'failed') {
                            progressHtml = `<span class="text-danger">${job.error || '处理失败'}</span>`;
                        } else {
                            progressHtml = '<span class="text-muted">等待中</span>';
                        }

                        let actionsHtml = '';
                        if (job.status === 'completed') {
                            actionsHtml = `
                                <button type="button" class="btn btn-success btn-sm" onclick="showDownloadPopup('${job.id}', '${originalName}')" title="下载文件">
                                    <i class="fas fa-download"></i> 下载
                                </button>
                                <button type="button" class="btn btn-primary btn-sm ms-1" onclick="showReprocessPopup('${job.id}', '${originalName}')" title="重新处理">
                                    <i class="fas fa-redo"></i> 重新处理
                                </button>
                            `;
                        }
                        
                        actionsHtml += `
                            <button class="btn btn-sm btn-danger ms-1" onclick="deleteJob('${job.id}')" 
                                    title="删除任务">
                                <i class="fas fa-trash"></i>
                            </button>
                        `;

                        row.innerHTML = `
                            <td>${originalName}</td>
                            <td>${statusBadge}</td>
                            <td>${progressHtml}</td>
                            <td>${actionsHtml}</td>
                        `;
                        jobsTableBody.appendChild(row);
                    });
                }
            })
            .catch(error => {
                console.error('加载作业失败:', error);
                if (jobsTableBody) {
                    jobsTableBody.innerHTML = `
                        <tr>
                            <td colspan="4" class="text-center text-danger">
                                加载失败
                            </td>
                        </tr>
                    `;
                }
            });
    }

    // 显示下载弹出层
    window.showDownloadPopup = function(jobId, jobTitle) {
        const popup = document.getElementById('downloadPopup');
        const titleElement = document.getElementById('downloadJobTitle');
        
        if (popup && titleElement) {
            titleElement.textContent = `任务：${jobTitle}`;
            popup.dataset.jobId = jobId;
            popup.style.display = 'flex';
            
            // 重置选择状态
            resetDownloadSelection();
        }
    };

    // 显示重新处理弹出层
    window.showReprocessPopup = function(jobId, jobTitle) {
        const popup = document.getElementById('reprocessPopup');
        const titleElement = document.getElementById('reprocessJobTitle');
        
        if (popup && titleElement) {
            titleElement.textContent = `任务：${jobTitle}`;
            popup.dataset.jobId = jobId;
            popup.style.display = 'flex';
            
            // 重置表单
            resetReprocessForm();
            
            // 设置语言选择变化监听
            setupReprocessLanguageHandlers();
        }
    };

    // 关闭下载弹出层
    function closeDownloadPopup() {
        const popup = document.getElementById('downloadPopup');
        if (popup) {
            popup.style.display = 'none';
        }
    }

    // 重置下载选择
    function resetDownloadSelection() {
        const checkboxes = document.querySelectorAll('#downloadPopup input[type="checkbox"]:not(#download-all)');
        const selectAllCheckbox = document.getElementById('download-all');
        
        // 默认选中Markdown
        checkboxes.forEach(checkbox => {
            checkbox.checked = checkbox.value === 'markdown';
        });
        
        if (selectAllCheckbox) {
            selectAllCheckbox.checked = false;
        }
    }

    // 处理全选/取消全选
    function handleSelectAll() {
        const selectAllCheckbox = document.getElementById('download-all');
        const checkboxes = document.querySelectorAll('#downloadPopup input[type="checkbox"]:not(#download-all)');
        
        if (selectAllCheckbox) {
            checkboxes.forEach(checkbox => {
                checkbox.checked = selectAllCheckbox.checked;
            });
        }
    }

    // 处理单个选择变化
    function handleSingleSelection() {
        const selectAllCheckbox = document.getElementById('download-all');
        const checkboxes = document.querySelectorAll('#downloadPopup input[type="checkbox"]:not(#download-all)');
        
        if (selectAllCheckbox) {
            const allChecked = Array.from(checkboxes).every(checkbox => checkbox.checked);
            const noneChecked = Array.from(checkboxes).every(checkbox => !checkbox.checked);
            
            selectAllCheckbox.checked = allChecked;
            selectAllCheckbox.indeterminate = !allChecked && !noneChecked;
        }
    }

    // 确认下载
    function confirmDownload() {
        const popup = document.getElementById('downloadPopup');
        const jobId = popup.dataset.jobId;
        const checkboxes = document.querySelectorAll('#downloadPopup input[type="checkbox"]:not(#download-all):checked');
        
        if (checkboxes.length === 0) {
            showMessage('请至少选择一种文件类型', 'warning');
            return;
        }
        
        const selectedTypes = Array.from(checkboxes).map(checkbox => checkbox.value);
        
        // 关闭弹出层
        closeDownloadPopup();
        
        // 开始下载
        downloadMultipleFiles(jobId, selectedTypes);
    }

    // 下载多个文件
    function downloadMultipleFiles(jobId, types) {
        showMessage(`开始下载 ${types.length} 个文件...`, 'info');
        
        let downloadCount = 0;
        let successCount = 0;
        let errorCount = 0;
        
        types.forEach((type, index) => {
            setTimeout(() => {
                downloadSingleFile(jobId, type)
                    .then(() => {
                        successCount++;
                        downloadCount++;
                        checkDownloadComplete();
                    })
                    .catch(error => {
                        errorCount++;
                        downloadCount++;
                        console.error(`下载 ${type} 失败:`, error);
                        checkDownloadComplete();
                    });
            }, index * 500); // 每个下载间隔500ms，避免同时发起太多请求
        });
        
        function checkDownloadComplete() {
            if (downloadCount === types.length) {
                if (errorCount === 0) {
                    showMessage(`成功下载 ${successCount} 个文件`, 'success');
                } else if (successCount > 0) {
                    showMessage(`下载完成：成功 ${successCount} 个，失败 ${errorCount} 个`, 'warning');
                } else {
                    showMessage(`下载失败：所有 ${errorCount} 个文件都下载失败`, 'error');
                }
            }
        }
    }

    // 下载单个文件
    function downloadSingleFile(jobId, type) {
        return new Promise((resolve, reject) => {
            let downloadUrl = `/download/${jobId}`;
            if (type !== 'markdown') {
                downloadUrl += `?type=${type}`;
            }

            fetch(downloadUrl)
                .then(response => {
                    if (response.ok) {
                        // 创建隐藏的a标签来触发下载
                        const link = document.createElement('a');
                        link.href = downloadUrl;
                        link.style.display = 'none';
                        document.body.appendChild(link);
                        link.click();
                        document.body.removeChild(link);
                        resolve();
                    } else {
                        return response.json().then(data => {
                            throw new Error(data.error || '下载失败');
                        });
                    }
                })
                .catch(error => {
                    reject(error);
                });
        });
    }

    // 保留原有的单文件下载函数（用于兼容）
    window.downloadJob = function(jobId, type = 'markdown') {
        if (event) {
            event.preventDefault();
        }
        
        downloadSingleFile(jobId, type)
            .then(() => {
                showMessage('文件下载成功', 'success');
            })
            .catch(error => {
                showMessage(`下载失败: ${error.message}`, 'error');
            });
    };

    // 删除作业
    window.deleteJob = function(jobId) {
        if (confirm('确定要删除此作业吗？')) {
            fetch(`/job/${jobId}`, { method: 'DELETE' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showMessage('作业已删除', 'success');
                        loadJobs();
                    } else {
                        showMessage(`删除失败: ${data.error}`, 'error');
                    }
                })
                .catch(error => {
                    showMessage(`删除出错: ${error.message}`, 'error');
                });
        }
    };

    // 显示消息
    function showMessage(message, type = 'info') {
        const alertClass = {
            'info': 'alert-info',
            'success': 'alert-success',
            'error': 'alert-danger',
            'warning': 'alert-warning'
        }[type] || 'alert-info';

        const alertHtml = `
            <div class="alert ${alertClass} alert-dismissible fade show" role="alert">
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
        `;

        const alertContainer = document.createElement('div');
        alertContainer.innerHTML = alertHtml;
        alertContainer.style.position = 'fixed';
        alertContainer.style.top = '20px';
        alertContainer.style.right = '20px';
        alertContainer.style.zIndex = '9999';
        alertContainer.style.maxWidth = '400px';
        
        document.body.appendChild(alertContainer);

        // 自动关闭
        setTimeout(() => {
            const alert = alertContainer.querySelector('.alert');
            if (alert) {
                alert.classList.remove('show');
                alert.classList.add('fade');
                setTimeout(() => {
                    if (alertContainer.parentNode) {
                        alertContainer.parentNode.removeChild(alertContainer);
                    }
                }, 150);
            }
        }, 5000);
    }

    // 处理语言选择变化
    function handleLanguageSelectionChange() {
        const languageSelect = document.getElementById('ocr-language');
        const smartSeparateDiv = document.getElementById('smart-separate-languages');
        const customLanguagesDiv = document.getElementById('custom-languages-input');
        
        if (!languageSelect) return;
        
        const selectedValue = languageSelect.value;
        
        // 隐藏所有特殊选项
        if (smartSeparateDiv) smartSeparateDiv.style.display = 'none';
        if (customLanguagesDiv) customLanguagesDiv.style.display = 'none';
        
        // 根据选择显示相应的界面
        if (selectedValue === 'smart_separate' && smartSeparateDiv) {
            smartSeparateDiv.style.display = 'block';
        } else if (selectedValue === 'custom' && customLanguagesDiv) {
            customLanguagesDiv.style.display = 'block';
            // 为自定义语言输入框添加提示功能
            setupCustomLanguageInput();
        }
    }

    // 设置自定义语言输入框的提示功能
    function setupCustomLanguageInput() {
        const customLanguagesInput = document.getElementById('custom-languages');
        if (!customLanguagesInput) return;

        // 添加输入提示
        const availableLanguages = ['中文', '英文', '日文', '韩文', '法文', '德文', '西班牙文', '俄文', '阿拉伯文'];
        
        // 创建提示文本
        const helpText = customLanguagesInput.parentNode.querySelector('.form-text');
        if (helpText) {
            helpText.innerHTML = `
                使用+号分隔多个语言，如：中文+英文+法文<br>
                <small>支持的语言：${availableLanguages.join('、')}</small>
            `;
        }

        // 添加输入验证和提示
        customLanguagesInput.addEventListener('input', function() {
            const value = this.value;
            const languages = value.split('+').map(lang => lang.trim()).filter(lang => lang);
            
            // 检查是否有不支持的语言
            const unsupportedLanguages = languages.filter(lang => !availableLanguages.includes(lang));
            
            if (unsupportedLanguages.length > 0) {
                this.style.borderColor = '#ffc107';
                this.style.backgroundColor = '#fff3cd';
            } else {
                this.style.borderColor = '';
                this.style.backgroundColor = '';
            }
        });
    }

    // 选择常用语言组合
    function selectCommonLanguages() {
        const checkboxes = document.querySelectorAll('input[name="selected_languages"]');
        const commonLangs = ['chinese', 'english']; // 默认选择中英文
        
        checkboxes.forEach(checkbox => {
            checkbox.checked = commonLangs.includes(checkbox.value);
        });
    }

    // 清除语言选择
    function clearLanguageSelection() {
        const checkboxes = document.querySelectorAll('input[name="selected_languages"]');
        checkboxes.forEach(checkbox => {
            checkbox.checked = false;
        });
    }

    // 绑定语言选择事件
    const languageSelectElement = document.getElementById('ocr-language');
    if (languageSelectElement) {
        languageSelectElement.addEventListener('change', handleLanguageSelectionChange);
        // 初始化时也检查一次
        handleLanguageSelectionChange();
    }

    // 绑定语言选择按钮事件
    const selectCommonLangsBtn = document.getElementById('select-common-langs');
    if (selectCommonLangsBtn) {
        selectCommonLangsBtn.addEventListener('click', selectCommonLanguages);
    }

    const clearLangSelectionBtn = document.getElementById('clear-lang-selection');
    if (clearLangSelectionBtn) {
        clearLangSelectionBtn.addEventListener('click', clearLanguageSelection);
    }

    // 绑定下载弹出层事件
    const closeDownloadBtn = document.getElementById('closeDownload');
    const cancelDownloadBtn = document.getElementById('cancelDownload');
    const confirmDownloadBtn = document.getElementById('confirmDownload');
    const downloadAllCheckbox = document.getElementById('download-all');
    const downloadBackdrop = document.querySelector('#downloadPopup .popup-backdrop');

    if (closeDownloadBtn) {
        closeDownloadBtn.addEventListener('click', closeDownloadPopup);
    }
    if (cancelDownloadBtn) {
        cancelDownloadBtn.addEventListener('click', closeDownloadPopup);
    }
    if (confirmDownloadBtn) {
        confirmDownloadBtn.addEventListener('click', confirmDownload);
    }
    if (downloadBackdrop) {
        downloadBackdrop.addEventListener('click', closeDownloadPopup);
    }

    // 绑定全选复选框事件
    if (downloadAllCheckbox) {
        downloadAllCheckbox.addEventListener('change', handleSelectAll);
    }

    // 绑定单个文件类型复选框事件
    const downloadCheckboxes = document.querySelectorAll('#downloadPopup input[type="checkbox"]:not(#download-all)');
    downloadCheckboxes.forEach(checkbox => {
        checkbox.addEventListener('change', handleSingleSelection);
    });

    // 重置重新处理表单
    function resetReprocessForm() {
        // 重置选择框到默认值
        document.getElementById('reprocess-ocr-engine').value = 'pdf_craft';
        document.getElementById('reprocess-ocr-level').value = 'standard';
        document.getElementById('reprocess-ocr-language').value = 'auto';
        document.getElementById('reprocess-table-format').value = 'standard';
        document.getElementById('reprocess-extract-formula').checked = false;
        document.getElementById('reprocess-reason').value = '';
        
        // 隐藏条件显示的元素
        document.getElementById('reprocess-smart-languages').style.display = 'none';
        document.getElementById('reprocess-custom-languages').style.display = 'none';
        
        // 清空语言选择
        const languageCheckboxes = document.querySelectorAll('#reprocess-smart-languages input[type="checkbox"]');
        languageCheckboxes.forEach(checkbox => {
            checkbox.checked = false;
        });
        
        document.getElementById('reprocess-custom-languages-input').value = '';
    }

    // 设置重新处理语言选择处理器
    function setupReprocessLanguageHandlers() {
        const languageSelect = document.getElementById('reprocess-ocr-language');
        const smartLanguagesDiv = document.getElementById('reprocess-smart-languages');
        const customLanguagesDiv = document.getElementById('reprocess-custom-languages');
        
        if (languageSelect) {
            languageSelect.addEventListener('change', function() {
                const selectedValue = this.value;
                
                // 隐藏所有条件元素
                smartLanguagesDiv.style.display = 'none';
                customLanguagesDiv.style.display = 'none';
                
                // 根据选择显示相应元素
                if (selectedValue === 'smart_separate') {
                    smartLanguagesDiv.style.display = 'block';
                } else if (selectedValue === 'custom') {
                    customLanguagesDiv.style.display = 'block';
                }
            });
        }
    }

    // 关闭重新处理弹出层
    function closeReprocessPopup() {
        const popup = document.getElementById('reprocessPopup');
        if (popup) {
            popup.style.display = 'none';
        }
    }

    // 确认重新处理
    function confirmReprocess() {
        const popup = document.getElementById('reprocessPopup');
        const jobId = popup.dataset.jobId;
        
        // 收集表单数据
        const formData = {
            ocr_engine: document.getElementById('reprocess-ocr-engine').value,
            ocr_level: document.getElementById('reprocess-ocr-level').value,
            ocr_language: document.getElementById('reprocess-ocr-language').value,
            extract_table_format: document.getElementById('reprocess-table-format').value,
            extract_formula: document.getElementById('reprocess-extract-formula').checked,
            reason: document.getElementById('reprocess-reason').value || '用户重新处理'
        };
        
        // 处理智能分离识别
        if (formData.ocr_language === 'smart_separate') {
            const selectedLanguages = [];
            const checkboxes = document.querySelectorAll('#reprocess-smart-languages input[type="checkbox"]:checked');
            checkboxes.forEach(checkbox => {
                selectedLanguages.push(checkbox.value);
            });
            
            if (selectedLanguages.length === 0) {
                showMessage('请至少选择一种语言进行智能分离识别', 'warning');
                return;
            }
            
            formData.selected_languages = selectedLanguages;
        }
        
        // 处理自定义语言组合
        if (formData.ocr_language === 'custom') {
            const customLanguages = document.getElementById('reprocess-custom-languages-input').value.trim();
            if (!customLanguages) {
                showMessage('请输入自定义语言组合', 'warning');
                return;
            }
            formData.custom_languages = customLanguages;
        }
        
        // 发送重新处理请求
        fetch(`/job/${jobId}/reprocess`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showMessage(`任务已重新排队处理，新任务ID: ${data.new_job_id}`, 'success');
                closeReprocessPopup();
                loadJobs(); // 刷新任务列表
            } else {
                showMessage(`重新处理失败: ${data.error}`, 'error');
            }
        })
        .catch(error => {
            console.error('重新处理请求失败:', error);
            showMessage('重新处理请求失败', 'error');
        });
    }

    // 绑定重新处理弹出层事件
    const closeReprocessBtn = document.getElementById('closeReprocess');
    const cancelReprocessBtn = document.getElementById('cancelReprocess');
    const confirmReprocessBtn = document.getElementById('confirmReprocess');
    const reprocessBackdrop = document.querySelector('#reprocessPopup .popup-backdrop');

    if (closeReprocessBtn) {
        closeReprocessBtn.addEventListener('click', closeReprocessPopup);
    }
    if (cancelReprocessBtn) {
        cancelReprocessBtn.addEventListener('click', closeReprocessPopup);
    }
    if (confirmReprocessBtn) {
        confirmReprocessBtn.addEventListener('click', confirmReprocess);
    }
    if (reprocessBackdrop) {
        reprocessBackdrop.addEventListener('click', closeReprocessPopup);
    }

    // 初始加载
    loadJobs();
    setInterval(loadJobs, 5000); // 每5秒刷新一次作业列表

    console.log('JavaScript初始化完成');
});