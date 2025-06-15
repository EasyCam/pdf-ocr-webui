# -*- coding: utf-8 -*-
"""
多OCR引擎管理器
支持多种高性能OCR引擎，提供统一接口
"""

import os
import logging
import time
import numpy as np
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path
import fitz  # PyMuPDF
from PIL import Image
import io

logger = logging.getLogger(__name__)

class OCREngine:
    """OCR引擎基类"""
    
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description
        self.available = False
        self.error_message = ""
        
    def check_availability(self) -> bool:
        """检查引擎是否可用"""
        return self.available
        
    def extract_text_from_image(self, image: Image.Image, language: str = 'auto') -> str:
        """从图像提取文本"""
        raise NotImplementedError
        
    def extract_text_from_pdf_page(self, pdf_path: str, page_num: int, language: str = 'auto') -> Dict[str, Any]:
        """从PDF页面提取文本"""
        raise NotImplementedError

class PDFCraftEngine(OCREngine):
    """PDF-Craft引擎"""
    
    def __init__(self, model_dir: str, device: str = 'cpu'):
        super().__init__("PDF-Craft", "原始PDF-Craft引擎，支持复杂文档结构")
        self.model_dir = model_dir
        self.device = device
        self.extractor = None
        self._check_availability()
        
    def _check_availability(self):
        try:
            from pdf_craft import PDFPageExtractor
            self.extractor = PDFPageExtractor(
                device=self.device,
                model_dir_path=self.model_dir
            )
            self.available = True
            logger.info("PDF-Craft引擎初始化成功")
        except Exception as e:
            self.available = False
            self.error_message = str(e)
            logger.warning(f"PDF-Craft引擎不可用: {e}")
            
    def extract_text_from_pdf_page(self, pdf_path: str, page_num: int, language: str = 'auto') -> Dict[str, Any]:
        if not self.available:
            return {"text": "", "error": self.error_message}
            
        try:
            # 使用PDF-Craft处理单页
            results = list(self.extractor.extract(pdf=pdf_path))
            if page_num < len(results):
                return {
                    "text": str(results[page_num]),
                    "confidence": 0.9,
                    "processing_time": 0,
                    "engine": self.name
                }
            return {"text": "", "error": "页面不存在"}
        except Exception as e:
            return {"text": "", "error": str(e)}

class TesseractEngine(OCREngine):
    """Tesseract OCR引擎"""
    
    def __init__(self):
        super().__init__("Tesseract", "Google Tesseract OCR，支持100+语言")
        self._check_availability()
        
    def _check_availability(self):
        try:
            import pytesseract
            from PIL import Image
            # 测试Tesseract是否可用
            test_image = Image.new('RGB', (100, 50), color='white')
            pytesseract.image_to_string(test_image)
            self.available = True
            logger.info("Tesseract引擎初始化成功")
        except Exception as e:
            self.available = False
            self.error_message = str(e)
            logger.warning(f"Tesseract引擎不可用: {e}")
            
    def extract_text_from_image(self, image: Image.Image, language: str = 'auto') -> str:
        if not self.available:
            return ""
            
        try:
            import pytesseract
            
            # 如果是多语言分别识别模式
            if language.startswith('separate:'):
                return self._extract_with_separate_languages(image, language[9:])
            
            # 支持多语言组合，用+分隔
            if '+' in language:
                # 直接使用用户指定的语言组合
                tesseract_lang = language
            else:
                # 单语言映射
                lang_map = {
                    'auto': 'chi_sim+chi_tra+eng',
                    'chinese': 'chi_sim+chi_tra',
                    'english': 'eng',
                    'japanese': 'jpn',
                    'korean': 'kor',
                    'french': 'fra',
                    'german': 'deu',
                    'spanish': 'spa',
                    'russian': 'rus',
                    'arabic': 'ara',
                    'multi_asian': 'chi_sim+chi_tra+jpn+kor+eng',  # 亚洲多语言
                    'multi_european': 'eng+fra+deu+spa+rus',  # 欧洲多语言
                    'multi_all': 'chi_sim+chi_tra+eng+jpn+kor+fra+deu+spa+rus+ara'  # 全语言
                }
                
                tesseract_lang = lang_map.get(language, 'chi_sim+chi_tra+eng')
            
            # 配置Tesseract参数
            config = '--oem 3 --psm 6'
            
            text = pytesseract.image_to_string(image, lang=tesseract_lang, config=config)
            return text.strip()
        except Exception as e:
            logger.error(f"Tesseract OCR失败: {e}")
            return ""
    
    def _extract_with_separate_languages(self, image: Image.Image, languages: str) -> str:
        """分别用每种语言进行OCR识别，然后整合结果"""
        import pytesseract
        
        # 解析语言列表
        lang_list = [lang.strip() for lang in languages.split(',')]
        
        # 语言映射
        lang_map = {
            'chinese': 'chi_sim+chi_tra',
            'english': 'eng',
            'japanese': 'jpn',
            'korean': 'kor',
            'french': 'fra',
            'german': 'deu',
            'spanish': 'spa',
            'russian': 'rus',
            'arabic': 'ara'
        }
        
        results = {}
        confidences = {}
        
        # 对每种语言分别进行OCR
        for lang in lang_list:
            if lang in lang_map:
                try:
                    tesseract_lang = lang_map[lang]
                    config = '--oem 3 --psm 6'
                    
                    # 获取详细结果包括置信度
                    data = pytesseract.image_to_data(image, lang=tesseract_lang, config=config, output_type=pytesseract.Output.DICT)
                    
                    # 提取文本和置信度
                    text_parts = []
                    conf_scores = []
                    
                    for i in range(len(data['text'])):
                        if int(data['conf'][i]) > 30:  # 置信度阈值
                            text = data['text'][i].strip()
                            if text:
                                text_parts.append(text)
                                conf_scores.append(int(data['conf'][i]))
                    
                    if text_parts:
                        results[lang] = ' '.join(text_parts)
                        confidences[lang] = sum(conf_scores) / len(conf_scores) if conf_scores else 0
                        logger.info(f"Tesseract {lang} OCR: 置信度 {confidences[lang]:.1f}%, 文本长度 {len(results[lang])}")
                    
                except Exception as e:
                    logger.warning(f"Tesseract {lang} OCR失败: {e}")
        
        # 整合结果
        return self._merge_ocr_results(results, confidences)
    
    def _merge_ocr_results(self, results: dict, confidences: dict) -> str:
        """智能整合多语言OCR结果"""
        if not results:
            return ""
        
        if len(results) == 1:
            return list(results.values())[0]
        
        # 按置信度排序
        sorted_results = sorted(results.items(), key=lambda x: confidences.get(x[0], 0), reverse=True)
        
        # 使用最高置信度的结果作为基础
        best_lang, best_text = sorted_results[0]
        best_confidence = confidences.get(best_lang, 0)
        
        logger.info(f"选择最佳OCR结果: {best_lang} (置信度: {best_confidence:.1f}%)")
        
        # 如果最佳结果置信度很高，直接使用
        if best_confidence > 80:
            return best_text
        
        # 否则尝试合并多个结果
        merged_text = best_text
        
        # 简单的文本合并策略：如果其他语言的结果包含更多内容，进行补充
        for lang, text in sorted_results[1:]:
            conf = confidences.get(lang, 0)
            if conf > 50 and len(text) > len(merged_text) * 1.2:
                # 如果其他语言的结果明显更长且置信度可接受，进行合并
                merged_text = self._smart_text_merge(merged_text, text)
                logger.info(f"合并 {lang} 的OCR结果")
        
        return merged_text
    
    def _smart_text_merge(self, text1: str, text2: str) -> str:
        """智能文本合并"""
        # 简单的合并策略：选择更长的文本，但保留两者的独特部分
        if len(text2) > len(text1) * 1.5:
            return text2
        elif len(text1) > len(text2) * 1.5:
            return text1
        else:
            # 尝试行级合并
            lines1 = text1.split('\n')
            lines2 = text2.split('\n')
            
            merged_lines = []
            max_lines = max(len(lines1), len(lines2))
            
            for i in range(max_lines):
                line1 = lines1[i] if i < len(lines1) else ""
                line2 = lines2[i] if i < len(lines2) else ""
                
                # 选择更长的行
                if len(line2) > len(line1):
                    merged_lines.append(line2)
                else:
                    merged_lines.append(line1)
            
            return '\n'.join(merged_lines)
            
    def extract_text_from_pdf_page(self, pdf_path: str, page_num: int, language: str = 'auto') -> Dict[str, Any]:
        if not self.available:
            return {"text": "", "error": self.error_message}
            
        start_time = time.time()
        try:
            # 将PDF页面转换为图像
            doc = fitz.open(pdf_path)
            if page_num >= len(doc):
                return {"text": "", "error": "页面不存在"}
                
            page = doc[page_num]
            mat = fitz.Matrix(2.0, 2.0)  # 提高分辨率
            pix = page.get_pixmap(matrix=mat)
            img_data = pix.tobytes("png")
            image = Image.open(io.BytesIO(img_data))
            doc.close()
            
            # OCR识别
            text = self.extract_text_from_image(image, language)
            processing_time = time.time() - start_time
            
            return {
                "text": text,
                "confidence": 0.8,
                "processing_time": processing_time,
                "engine": self.name
            }
        except Exception as e:
            return {"text": "", "error": str(e)}

class EasyOCREngine(OCREngine):
    """EasyOCR引擎"""
    
    def __init__(self, gpu: bool = False):
        super().__init__("EasyOCR", "高精度深度学习OCR，支持80+语言")
        self.gpu = gpu
        self.reader = None
        self._check_availability()
        
    def _check_availability(self):
        try:
            import easyocr
            # 初始化EasyOCR，只使用繁体中文和英文
            self.reader = easyocr.Reader(['ch_tra', 'en'], gpu=self.gpu)
            self.available = True
            logger.info(f"EasyOCR引擎初始化成功 (GPU: {self.gpu})")
        except Exception as e:
            self.available = False
            self.error_message = str(e)
            logger.warning(f"EasyOCR引擎不可用: {e}")
            
    def extract_text_from_image(self, image: Image.Image, language: str = 'auto') -> str:
        if not self.available:
            return ""
            
        try:
            # 转换PIL图像为numpy数组
            img_array = np.array(image)
            
            # EasyOCR识别
            results = self.reader.readtext(img_array)
            
            # 提取文本
            texts = []
            for (bbox, text, confidence) in results:
                if confidence > 0.5:  # 置信度阈值
                    texts.append(text)
                    
            return '\n'.join(texts)
        except Exception as e:
            logger.error(f"EasyOCR识别失败: {e}")
            return ""
            
    def extract_text_from_pdf_page(self, pdf_path: str, page_num: int, language: str = 'auto') -> Dict[str, Any]:
        if not self.available:
            return {"text": "", "error": self.error_message}
            
        start_time = time.time()
        try:
            # 将PDF页面转换为图像
            doc = fitz.open(pdf_path)
            if page_num >= len(doc):
                return {"text": "", "error": "页面不存在"}
                
            page = doc[page_num]
            mat = fitz.Matrix(2.0, 2.0)
            pix = page.get_pixmap(matrix=mat)
            img_data = pix.tobytes("png")
            image = Image.open(io.BytesIO(img_data))
            doc.close()
            
            # OCR识别
            text = self.extract_text_from_image(image, language)
            processing_time = time.time() - start_time
            
            return {
                "text": text,
                "confidence": 0.85,
                "processing_time": processing_time,
                "engine": self.name
            }
        except Exception as e:
            return {"text": "", "error": str(e)}

class PaddleOCREngine(OCREngine):
    """PaddleOCR引擎"""
    
    def __init__(self, gpu: bool = False):
        super().__init__("PaddleOCR", "百度PaddleOCR，中文识别效果优秀")
        self.gpu = gpu
        self.ocr = None
        self._check_availability()
        
    def _check_availability(self):
        try:
            # 首先检查PaddlePaddle是否可用
            import paddle
            paddle.disable_signal_handler()  # 禁用信号处理器，避免一些潜在问题
            
            # 检查CUDA是否可用（如果需要GPU）
            if self.gpu:
                try:
                    if paddle.device.is_compiled_with_cuda():
                        logger.info(f"PaddlePaddle已启用CUDA支持: {paddle.device.get_device()}")
                        cuda_version = paddle.device.cuda.get_cuda_version()
                        logger.info(f"CUDA版本: {cuda_version}")
                    else:
                        logger.warning("PaddlePaddle未编译CUDA支持，回退到CPU模式")
                        self.gpu = False
                except Exception as e:
                    logger.warning(f"检查CUDA支持时出错，回退到CPU模式: {e}")
                    self.gpu = False
            
            # 初始化PaddleOCR
            from paddleocr import PaddleOCR
            try:
                self.ocr = PaddleOCR(
                    use_angle_cls=True,
                    lang='ch',
                    device='gpu' if self.gpu else 'cpu'  # 使用device参数
                )
                self.available = True
                logger.info(f"PaddleOCR引擎初始化成功 (GPU: {self.gpu})")
            except Exception as e:
                if self.gpu:
                    logger.warning(f"GPU模式初始化失败，尝试CPU模式: {e}")
                    try:
                        self.gpu = False
                        self.ocr = PaddleOCR(
                            use_angle_cls=True,
                            lang='ch',
                            device='cpu'
                        )
                        self.available = True
                        logger.info("PaddleOCR引擎初始化成功 (CPU模式)")
                    except Exception as e2:
                        self.available = False
                        self.error_message = f"GPU和CPU模式都初始化失败: {e2}"
                        logger.warning(f"PaddleOCR引擎不可用: {e2}")
                else:
                    self.available = False
                    self.error_message = str(e)
                    logger.warning(f"PaddleOCR引擎不可用: {e}")
                    
        except ImportError as e:
            self.available = False
            self.error_message = f"缺少必要的库: {e}"
            logger.warning(f"PaddleOCR引擎不可用: {e}")
        except Exception as e:
            self.available = False
            self.error_message = str(e)
            logger.warning(f"PaddleOCR引擎不可用: {e}")
            
    def extract_text_from_image(self, image: Image.Image, language: str = 'auto') -> str:
        """从图片中提取文本"""
        if not self.available or not self.ocr:
            return ""
            
        try:
            # 如果是多语言分别识别模式
            if language.startswith('separate:'):
                return self._extract_with_separate_languages_paddle(image, language[9:])
            
            # 将PIL图像转换为numpy数组
            import numpy as np
            img_array = np.array(image)
            
            # 设置语言参数，支持多语言
            lang_map = {
                'auto': 'ch',
                'chinese': 'ch',
                'english': 'en',
                'japanese': 'japan',
                'korean': 'korean',
                'french': 'french',
                'german': 'german',
                'spanish': 'spanish',
                'russian': 'cyrillic',
                'arabic': 'arabic',
                'multi_asian': 'ch',  # 多语言时使用中文模型
                'multi_european': 'en',  # 多语言时使用英文模型
                'multi_all': 'ch'  # 全语言时使用中文模型
            }
            
            lang = lang_map.get(language, 'ch')
            
            # 如果是多语言模式，我们将进行多次识别并合并结果
            is_multi_lang = language.startswith('multi_') or '+' in language
            
            # 如果需要切换语言，重新初始化OCR
            if hasattr(self, '_current_lang') and self._current_lang != lang:
                try:
                    from paddleocr import PaddleOCR
                    self.ocr = PaddleOCR(
                        use_angle_cls=True,
                        lang=lang,
                        device='gpu' if self.gpu else 'cpu'
                    )
                    self._current_lang = lang
                except Exception as e:
                    logger.warning(f"切换PaddleOCR语言失败: {e}")
            elif not hasattr(self, '_current_lang'):
                self._current_lang = lang
            
            result = self.ocr.ocr(img_array, cls=True)
            if not result or len(result) == 0:
                return ""
                
            # 提取文本
            text = ""
            for line in result:
                if isinstance(line, list):  # 处理新版本PaddleOCR的输出格式
                    for item in line:
                        if isinstance(item, (list, tuple)) and len(item) >= 2:
                            text += item[1][0] + "\n"  # 添加文本内容
                elif isinstance(line, (list, tuple)) and len(line) >= 2:  # 处理旧版本格式
                    text += line[1][0] + "\n"
                    
            return text.strip()
            
        except Exception as e:
            error_msg = f"文本提取失败: {str(e)}"
            logger.error(error_msg)
            return ""
    
    def _extract_with_separate_languages_paddle(self, image: Image.Image, languages: str) -> str:
        """PaddleOCR分别用每种语言进行OCR识别，然后整合结果"""
        from paddleocr import PaddleOCR
        import numpy as np
        
        # 解析语言列表
        lang_list = [lang.strip() for lang in languages.split(',')]
        
        # PaddleOCR语言映射
        lang_map = {
            'chinese': 'ch',
            'english': 'en',
            'japanese': 'japan',
            'korean': 'korean',
            'french': 'french',
            'german': 'german',
            'spanish': 'spanish',
            'russian': 'cyrillic',
            'arabic': 'arabic'
        }
        
        results = {}
        confidences = {}
        img_array = np.array(image)
        
        # 对每种语言分别进行OCR
        for lang in lang_list:
            if lang in lang_map:
                try:
                    paddle_lang = lang_map[lang]
                    
                    # 为每种语言创建独立的OCR实例
                    ocr_instance = PaddleOCR(
                        use_angle_cls=True,
                        lang=paddle_lang,
                        device='gpu' if self.gpu else 'cpu'
                    )
                    
                    result = ocr_instance.ocr(img_array, cls=True)
                    
                    if result and len(result) > 0:
                        text_parts = []
                        conf_scores = []
                        
                        for line in result:
                            if isinstance(line, list):
                                for item in line:
                                    if isinstance(item, (list, tuple)) and len(item) >= 2:
                                        text = item[1][0]
                                        confidence = item[1][1] if len(item[1]) > 1 else 0.8
                                        
                                        if confidence > 0.3:  # 置信度阈值
                                            text_parts.append(text)
                                            conf_scores.append(confidence)
                        
                        if text_parts:
                            results[lang] = '\n'.join(text_parts)
                            confidences[lang] = (sum(conf_scores) / len(conf_scores)) * 100 if conf_scores else 0
                            logger.info(f"PaddleOCR {lang} OCR: 置信度 {confidences[lang]:.1f}%, 文本长度 {len(results[lang])}")
                    
                except Exception as e:
                    logger.warning(f"PaddleOCR {lang} OCR失败: {e}")
        
        # 整合结果
        return self._merge_ocr_results_paddle(results, confidences)
    
    def _merge_ocr_results_paddle(self, results: dict, confidences: dict) -> str:
        """智能整合PaddleOCR多语言结果"""
        if not results:
            return ""
        
        if len(results) == 1:
            return list(results.values())[0]
        
        # 按置信度排序
        sorted_results = sorted(results.items(), key=lambda x: confidences.get(x[0], 0), reverse=True)
        
        # 使用最高置信度的结果作为基础
        best_lang, best_text = sorted_results[0]
        best_confidence = confidences.get(best_lang, 0)
        
        logger.info(f"PaddleOCR选择最佳结果: {best_lang} (置信度: {best_confidence:.1f}%)")
        
        # 如果最佳结果置信度很高，直接使用
        if best_confidence > 85:
            return best_text
        
        # 否则尝试合并多个结果
        merged_text = best_text
        
        # 合并其他高质量结果
        for lang, text in sorted_results[1:]:
            conf = confidences.get(lang, 0)
            if conf > 60 and len(text) > len(merged_text) * 1.1:
                # 如果其他语言的结果质量可接受且更完整，进行合并
                merged_text = self._smart_text_merge_paddle(merged_text, text)
                logger.info(f"PaddleOCR合并 {lang} 的结果")
        
        return merged_text
    
    def _smart_text_merge_paddle(self, text1: str, text2: str) -> str:
        """PaddleOCR智能文本合并"""
        # 如果一个文本明显更长，优先选择
        if len(text2) > len(text1) * 1.3:
            return text2
        elif len(text1) > len(text2) * 1.3:
            return text1
        
        # 行级合并
        lines1 = text1.split('\n')
        lines2 = text2.split('\n')
        
        merged_lines = []
        max_lines = max(len(lines1), len(lines2))
        
        for i in range(max_lines):
            line1 = lines1[i].strip() if i < len(lines1) else ""
            line2 = lines2[i].strip() if i < len(lines2) else ""
            
            # 选择更完整的行
            if len(line2) > len(line1) and line2:
                merged_lines.append(line2)
            elif line1:
                merged_lines.append(line1)
            elif line2:
                merged_lines.append(line2)
        
        return '\n'.join(merged_lines)
            
    def extract_text_from_pdf_page(self, pdf_path: str, page_num: int, language: str = 'auto') -> Dict[str, Any]:
        if not self.available:
            return {"text": "", "error": self.error_message}
            
        start_time = time.time()
        try:
            # 将PDF页面转换为图像
            doc = fitz.open(pdf_path)
            if page_num >= len(doc):
                return {"text": "", "error": "页面不存在"}
                
            page = doc[page_num]
            mat = fitz.Matrix(2.0, 2.0)
            pix = page.get_pixmap(matrix=mat)
            img_data = pix.tobytes("png")
            image = Image.open(io.BytesIO(img_data))
            doc.close()
            
            # OCR识别
            text = self.extract_text_from_image(image, language)
            processing_time = time.time() - start_time
            
            return {
                "text": text,
                "confidence": 0.9,
                "processing_time": processing_time,
                "engine": self.name
            }
        except Exception as e:
            return {"text": "", "error": str(e)}

class RapidOCREngine(OCREngine):
    """RapidOCR引擎"""
    
    def __init__(self):
        super().__init__("RapidOCR", "轻量级高速OCR，基于ONNX Runtime")
        self.ocr = None
        self._check_availability()
        
    def _check_availability(self):
        try:
            from rapidocr_onnxruntime import RapidOCR
            self.ocr = RapidOCR()
            self.available = True
            logger.info("RapidOCR引擎初始化成功")
        except Exception as e:
            self.available = False
            self.error_message = str(e)
            logger.warning(f"RapidOCR引擎不可用: {e}")
            
    def extract_text_from_image(self, image: Image.Image, language: str = 'auto') -> str:
        if not self.available:
            return ""
            
        try:
            # 转换PIL图像为numpy数组
            img_array = np.array(image)
            
            # RapidOCR识别
            result, elapse = self.ocr(img_array)
            
            # 提取文本
            texts = []
            if result:
                for line in result:
                    if len(line) >= 2:
                        text = line[1]
                        confidence = line[2] if len(line) > 2 else 1.0
                        if confidence > 0.5:
                            texts.append(text)
                            
            return '\n'.join(texts)
        except Exception as e:
            logger.error(f"RapidOCR识别失败: {e}")
            return ""
            
    def extract_text_from_pdf_page(self, pdf_path: str, page_num: int, language: str = 'auto') -> Dict[str, Any]:
        if not self.available:
            return {"text": "", "error": self.error_message}
            
        start_time = time.time()
        try:
            # 将PDF页面转换为图像
            doc = fitz.open(pdf_path)
            if page_num >= len(doc):
                return {"text": "", "error": "页面不存在"}
                
            page = doc[page_num]
            mat = fitz.Matrix(2.0, 2.0)
            pix = page.get_pixmap(matrix=mat)
            img_data = pix.tobytes("png")
            image = Image.open(io.BytesIO(img_data))
            doc.close()
            
            # OCR识别
            text = self.extract_text_from_image(image, language)
            processing_time = time.time() - start_time
            
            return {
                "text": text,
                "confidence": 0.85,
                "processing_time": processing_time,
                "engine": self.name
            }
        except Exception as e:
            return {"text": "", "error": str(e)}

class OCREngineManager:
    """OCR引擎管理器"""
    
    def __init__(self, model_dir: str, use_gpu: bool = False):
        self.model_dir = model_dir
        self.use_gpu = use_gpu
        self.engines = {}
        self._initialize_engines()
        
    def _initialize_engines(self):
        """初始化所有OCR引擎"""
        logger.info("初始化OCR引擎...")
        
        # PDF-Craft引擎
        device = 'cuda' if self.use_gpu else 'cpu'
        self.engines['pdf_craft'] = PDFCraftEngine(self.model_dir, device)
        
        # Tesseract引擎
        self.engines['tesseract'] = TesseractEngine()
        
        # EasyOCR引擎
        self.engines['easyocr'] = EasyOCREngine(gpu=self.use_gpu)
        
        # PaddleOCR引擎
        self.engines['paddleocr'] = PaddleOCREngine(gpu=self.use_gpu)
        
        # RapidOCR引擎
        self.engines['rapidocr'] = RapidOCREngine()
        
        # 统计可用引擎
        available_engines = [name for name, engine in self.engines.items() if engine.available]
        logger.info(f"可用OCR引擎: {available_engines}")
        
    def get_available_engines(self) -> Dict[str, Dict[str, Any]]:
        """获取可用的OCR引擎列表"""
        result = {}
        for name, engine in self.engines.items():
            result[name] = {
                'name': engine.name,
                'description': engine.description,
                'available': engine.available,
                'error_message': engine.error_message if not engine.available else ""
            }
        return result
        
    def extract_text_from_pdf(self, pdf_path: str, engine_name: str = 'pdf_craft', 
                             language: str = 'auto', progress_callback=None) -> List[Dict[str, Any]]:
        """使用指定引擎从PDF提取文本"""
        if engine_name not in self.engines:
            raise ValueError(f"未知的OCR引擎: {engine_name}")
            
        engine = self.engines[engine_name]
        if not engine.available:
            raise RuntimeError(f"OCR引擎不可用: {engine.error_message}")
            
        # 获取PDF页数
        doc = fitz.open(pdf_path)
        total_pages = len(doc)
        doc.close()
        
        results = []
        for page_num in range(total_pages):
            if progress_callback:
                progress_callback(page_num + 1, total_pages)
                
            result = engine.extract_text_from_pdf_page(pdf_path, page_num, language)
            result['page_number'] = page_num + 1
            results.append(result)
            
        return results
        
    def benchmark_engines(self, test_pdf_path: str, max_pages: int = 3) -> Dict[str, Dict[str, Any]]:
        """对比不同OCR引擎的性能"""
        results = {}
        
        for engine_name, engine in self.engines.items():
            if not engine.available:
                results[engine_name] = {
                    'available': False,
                    'error': engine.error_message
                }
                continue
                
            try:
                start_time = time.time()
                
                # 测试前几页
                doc = fitz.open(test_pdf_path)
                test_pages = min(max_pages, len(doc))
                doc.close()
                
                total_text_length = 0
                page_times = []
                
                for page_num in range(test_pages):
                    page_start = time.time()
                    result = engine.extract_text_from_pdf_page(test_pdf_path, page_num)
                    page_time = time.time() - page_start
                    page_times.append(page_time)
                    
                    if 'text' in result:
                        total_text_length += len(result['text'])
                        
                total_time = time.time() - start_time
                avg_page_time = sum(page_times) / len(page_times) if page_times else 0
                
                results[engine_name] = {
                    'available': True,
                    'total_time': total_time,
                    'avg_page_time': avg_page_time,
                    'pages_per_second': 1.0 / avg_page_time if avg_page_time > 0 else 0,
                    'total_text_length': total_text_length,
                    'chars_per_second': total_text_length / total_time if total_time > 0 else 0,
                    'test_pages': test_pages
                }
                
            except Exception as e:
                results[engine_name] = {
                    'available': False,
                    'error': str(e)
                }
                
        return results 