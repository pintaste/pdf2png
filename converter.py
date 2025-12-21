#!/usr/bin/env python3
"""
PDF 到 PNG 转换器核心模块

重构后：
- 使用统一常量配置
- 遵循 SOLID 原则的共享转换逻辑
- 性能优化：消除重复渲染和双重 I/O
- 多页并行处理支持
"""
from typing import List, Optional, Callable, Dict, Any, Tuple
from concurrent.futures import ProcessPoolExecutor, as_completed
import multiprocessing
import os
import io

from constants import DPIConfig, ConverterConfig


# ============================================================================
# 多进程工作函数（必须在模块级别定义）
# ============================================================================

def _convert_page_worker(args: Tuple) -> Tuple[int, str, int, Optional[str]]:
    """
    多进程工作函数：转换单个页面

    策略：渐进式调整 + 强制验证 + 向上逼近
    目标：绝不超限 + 尽量接近限制（98%+）

    Args:
        args: (pdf_path, page_num, output_path, params_dict)

    Returns:
        (page_num, output_path, actual_dpi, error_msg)
        error_msg 为 None 表示成功
    """
    pdf_path, page_num, output_path, params = args

    try:
        import fitz
        from PIL import Image
        import io

        max_size_mb = params['max_size_mb']
        min_dpi = params['min_dpi']
        max_dpi = params['max_dpi']
        quality_first = params['quality_first']
        png_compress_level = params['png_compress_level']

        max_size_bytes = int(max_size_mb * 1024 * 1024)

        # 每个进程单独打开 PDF
        doc = fitz.open(pdf_path)
        page = doc[page_num]

        def render_to_memory(dpi: int) -> Tuple[bytes, int, int]:
            """渲染到内存，返回 (png_bytes, width, height)"""
            zoom = dpi / DPIConfig.PDF_BASE_DPI
            mat = fitz.Matrix(zoom, zoom)
            pix = page.get_pixmap(matrix=mat, alpha=False)
            img = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
            buffer = io.BytesIO()
            img.save(buffer, 'PNG', optimize=True, compress_level=png_compress_level)
            png_bytes = buffer.getvalue()
            w, h = pix.width, pix.height
            del pix
            return (png_bytes, w, h)

        def save_bytes(png_bytes: bytes) -> int:
            """保存字节到文件"""
            with open(output_path, 'wb') as f:
                f.write(png_bytes)
            return len(png_bytes)

        try:
            # 质量优先模式：直接使用最高 DPI
            if quality_first:
                png_bytes, _, _ = render_to_memory(max_dpi)
                save_bytes(png_bytes)
                return (page_num, output_path, max_dpi, None)

            # ===== 文件大小限制模式 =====
            # 策略：渐进式调整 + 强制验证 + 向上逼近

            # 第一步：尝试最高 DPI
            result_bytes, _, _ = render_to_memory(max_dpi)
            actual_size = len(result_bytes)

            # 如果最高 DPI 不超限，直接使用
            if actual_size <= max_size_bytes:
                save_bytes(result_bytes)
                return (page_num, output_path, max_dpi, None)

            # 第二步：超限了，渐进式降低 DPI 直到不超限
            current_dpi = max_dpi
            safety = 0.95

            for _ in range(3):
                ratio = max_size_bytes / actual_size
                current_dpi = int(current_dpi * (ratio ** 0.5) * safety)
                current_dpi = max(min_dpi, current_dpi)

                result_bytes, _, _ = render_to_memory(current_dpi)
                actual_size = len(result_bytes)

                if actual_size <= max_size_bytes:
                    break
                safety *= 0.95  # 更保守

            # 第三步：如果仍然超限，使用二分法继续降低 DPI
            if actual_size > max_size_bytes and current_dpi > min_dpi:
                low_dpi = min_dpi
                high_dpi = current_dpi

                while high_dpi - low_dpi > 5:
                    mid_dpi = (low_dpi + high_dpi) // 2
                    mid_bytes, _, _ = render_to_memory(mid_dpi)

                    if len(mid_bytes) <= max_size_bytes:
                        low_dpi = mid_dpi
                        result_bytes = mid_bytes
                        current_dpi = mid_dpi
                        actual_size = len(mid_bytes)
                    else:
                        high_dpi = mid_dpi

                # 如果二分法后仍超限，使用 min_dpi
                if actual_size > max_size_bytes:
                    result_bytes, _, _ = render_to_memory(min_dpi)
                    current_dpi = min_dpi
                    actual_size = len(result_bytes)

            # 第四步：如果不超限但太保守（<90%限制），尝试向上逼近
            if actual_size <= max_size_bytes * 0.90 and current_dpi < max_dpi:
                best_bytes = result_bytes
                best_dpi = current_dpi

                low_dpi = current_dpi
                high_dpi = min(int(current_dpi * 1.15), max_dpi)

                while high_dpi - low_dpi > 10:
                    mid_dpi = (low_dpi + high_dpi) // 2
                    mid_bytes, _, _ = render_to_memory(mid_dpi)

                    if len(mid_bytes) <= max_size_bytes:
                        low_dpi = mid_dpi
                        best_bytes = mid_bytes
                        best_dpi = mid_dpi
                    else:
                        high_dpi = mid_dpi

                result_bytes = best_bytes
                current_dpi = best_dpi

            # 第五步：最终强制验证（绝不超限）
            final_size = len(result_bytes)
            if final_size > max_size_bytes:
                # 仍然超限，强制使用 min_dpi
                result_bytes, _, _ = render_to_memory(min_dpi)
                current_dpi = min_dpi
                final_size = len(result_bytes)

                # 如果 min_dpi 仍超限，继续降低直到满足或达到绝对最低
                emergency_dpi = min_dpi
                while final_size > max_size_bytes and emergency_dpi > 36:
                    emergency_dpi = int(emergency_dpi * 0.8)
                    result_bytes, _, _ = render_to_memory(emergency_dpi)
                    final_size = len(result_bytes)
                    current_dpi = emergency_dpi

            save_bytes(result_bytes)
            return (page_num, output_path, current_dpi, None)

        finally:
            doc.close()

    except Exception as e:
        return (page_num, output_path, 0, str(e))


class ConversionError(Exception):
    """转换过程中的错误"""
    pass


class PDFConverter:
    """
    PDF 到 PNG 转换器核心类

    职责：
    - 处理 PDF 到 PNG 的转换逻辑
    - 管理 DPI 调整策略
    - 处理单页和多页 PDF
    """

    def __init__(self):
        """初始化转换器，延迟导入 PyMuPDF"""
        try:
            import fitz  # PyMuPDF
            self.fitz = fitz
        except ImportError:
            raise ImportError(
                "未安装 PyMuPDF。请运行: pip install PyMuPDF"
            )

    def convert(
        self,
        pdf_path: str,
        output_path: Optional[str] = None,
        max_size_mb: float = ConverterConfig.DEFAULT_MAX_SIZE_MB,
        min_dpi: int = ConverterConfig.DEFAULT_MIN_DPI,
        max_dpi: int = ConverterConfig.DEFAULT_MAX_DPI,
        quality_first: bool = False,
        png_compress_level: int = ConverterConfig.DEFAULT_PNG_COMPRESS_LEVEL,
        progress_callback: Optional[Callable[[str], None]] = None,
        parallel: bool = True
    ) -> Dict[str, Any]:
        """
        将 PDF 转换为 PNG

        Args:
            pdf_path: PDF 文件路径
            output_path: 输出文件路径（可选，默认为同名 .png）
            max_size_mb: 最大文件大小（MB）
            min_dpi: 最低 DPI
            max_dpi: 最高 DPI
            quality_first: 优先质量模式（忽略文件大小限制）
            png_compress_level: PNG 压缩级别 (0-9)
            progress_callback: 进度回调函数
            parallel: 是否启用多页并行处理（默认 True）

        Returns:
            包含 files 列表和 dpi 值的字典

        Raises:
            ConversionError: 转换失败
            FileNotFoundError: 文件不存在
            ValueError: 参数无效
        """
        # 验证输入文件
        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"文件不存在: {pdf_path}")

        # 验证参数
        if max_size_mb <= 0:
            raise ValueError(f"max_size_mb 必须大于 0，当前值: {max_size_mb}")

        if not validate_dpi_range(min_dpi, max_dpi):
            raise ValueError(
                f"DPI 范围无效: min_dpi={min_dpi}, max_dpi={max_dpi}。"
                f"DPI 必须在 {DPIConfig.MIN_DPI}-{DPIConfig.MAX_DPI} 之间，且 min_dpi <= max_dpi"
            )

        if not (0 <= png_compress_level <= 9):
            raise ValueError(
                f"PNG 压缩级别必须在 0-9 之间，当前值: {png_compress_level}"
            )

        # 确定输出路径
        if output_path is None:
            output_path = os.path.splitext(pdf_path)[0] + ".png"

        output_dir = os.path.dirname(output_path) or "."
        output_basename = os.path.splitext(os.path.basename(output_path))[0]

        # 确保输出目录存在
        try:
            os.makedirs(output_dir, exist_ok=True)
        except OSError as e:
            raise ConversionError(f"无法创建输出目录: {e}")

        doc = None
        try:
            doc = self.fitz.open(pdf_path)
            page_count = len(doc)
            doc.close()
            doc = None

            if progress_callback:
                progress_callback(f"📄 {os.path.basename(pdf_path)} ({page_count} 页)")

            # 多页且启用并行时使用多进程
            if parallel and page_count > 1:
                return self._convert_parallel(
                    pdf_path, output_path, output_dir, output_basename,
                    page_count, max_size_mb, min_dpi, max_dpi,
                    quality_first, png_compress_level, progress_callback
                )

            # 单页或串行模式
            return self._convert_sequential(
                pdf_path, output_path, output_dir, output_basename,
                page_count, max_size_mb, min_dpi, max_dpi,
                quality_first, png_compress_level, progress_callback
            )

        except Exception as e:
            raise ConversionError(f"转换失败: {e}") from e
        finally:
            if doc:
                doc.close()

    def _convert_parallel(
        self,
        pdf_path: str,
        output_path: str,
        output_dir: str,
        output_basename: str,
        page_count: int,
        max_size_mb: float,
        min_dpi: int,
        max_dpi: int,
        quality_first: bool,
        png_compress_level: int,
        progress_callback: Optional[Callable[[str], None]]
    ) -> Dict[str, Any]:
        """
        多进程并行转换多页 PDF

        每个页面在独立进程中处理，充分利用多核 CPU
        """
        # 计算实际进程数
        actual_workers = max(1, min(page_count, multiprocessing.cpu_count() // 2, 4))
        if progress_callback:
            progress_callback(f"  🚀 启用并行处理 ({actual_workers} 进程)")

        # 准备任务参数
        params = {
            'max_size_mb': max_size_mb,
            'min_dpi': min_dpi,
            'max_dpi': max_dpi,
            'quality_first': quality_first,
            'png_compress_level': png_compress_level
        }

        tasks = []
        for page_num in range(page_count):
            page_output = self._get_output_filename(
                output_path, output_dir, output_basename,
                page_num, page_count
            )
            tasks.append((pdf_path, page_num, page_output, params))

        # 使用进程池并行处理
        generated_files = [None] * page_count
        dpi_list = []  # 收集每页 DPI
        errors = []

        with ProcessPoolExecutor(max_workers=actual_workers) as executor:
            futures = {executor.submit(_convert_page_worker, task): task[1] for task in tasks}

            for future in as_completed(futures):
                page_num = futures[future]
                try:
                    result = future.result()
                    page_idx, file_path, dpi, error = result

                    if error:
                        errors.append(f"页 {page_idx + 1}: {error}")
                        if progress_callback:
                            progress_callback(f"  ✗ 页 {page_idx + 1}: {error}")
                    else:
                        generated_files[page_idx] = file_path
                        dpi_list.append(dpi)
                        if progress_callback:
                            file_size_mb = os.path.getsize(file_path) / (1024 * 1024)
                            progress_callback(f"  ✓ 页 {page_idx + 1}: {file_size_mb:.2f}MB, {dpi}DPI")

                except Exception as e:
                    errors.append(f"页 {page_num + 1}: {str(e)}")

        # 过滤掉失败的页面
        generated_files = [f for f in generated_files if f is not None]

        if errors and progress_callback:
            for error in errors:
                progress_callback(f"  ⚠ {error}")

        # 返回 DPI 范围
        dpi_min = min(dpi_list) if dpi_list else max_dpi
        dpi_max = max(dpi_list) if dpi_list else max_dpi

        return {
            'files': generated_files,
            'dpi_min': dpi_min,
            'dpi_max': dpi_max
        }

    def _convert_sequential(
        self,
        pdf_path: str,
        output_path: str,
        output_dir: str,
        output_basename: str,
        page_count: int,
        max_size_mb: float,
        min_dpi: int,
        max_dpi: int,
        quality_first: bool,
        png_compress_level: int,
        progress_callback: Optional[Callable[[str], None]]
    ) -> Dict[str, Any]:
        """
        串行转换 PDF 页面（单页或禁用并行时使用）
        """
        doc = self.fitz.open(pdf_path)
        try:
            generated_files = []
            dpi_list = []  # 收集每页 DPI
            dpi_levels = generate_dpi_levels(min_dpi, max_dpi, quality_first)

            for page_num in range(page_count):
                current_output = self._get_output_filename(
                    output_path, output_dir, output_basename,
                    page_num, page_count
                )

                result = self._convert_page(
                    doc[page_num],
                    current_output,
                    dpi_levels,
                    max_size_mb,
                    quality_first,
                    png_compress_level,
                    page_num,
                    min_dpi,
                    progress_callback
                )

                if result:
                    file_path, page_dpi = result
                    generated_files.append(file_path)
                    dpi_list.append(page_dpi)

            # 返回 DPI 范围
            dpi_min = min(dpi_list) if dpi_list else max_dpi
            dpi_max = max(dpi_list) if dpi_list else max_dpi

            return {
                'files': generated_files,
                'dpi_min': dpi_min,
                'dpi_max': dpi_max
            }
        finally:
            doc.close()

    def _compress_and_save_png(
        self,
        pix,
        output_path: str,
        compress_level: int = 6
    ) -> Tuple[int, int, int]:
        """
        高效压缩并保存 PNG（内存中完成，单次 I/O）

        Args:
            pix: PyMuPDF pixmap 对象
            output_path: 输出文件路径
            compress_level: 压缩级别 (0-9)

        Returns:
            (file_size_bytes, width, height)
        """
        width, height = pix.width, pix.height

        try:
            from PIL import Image

            # 直接从 pixmap 获取 samples（原始像素数据）
            img = Image.frombytes("RGB", (width, height), pix.samples)

            # 在内存中压缩并保存（单次 I/O）
            img.save(
                output_path,
                'PNG',
                optimize=True,
                compress_level=compress_level
            )
            file_size = os.path.getsize(output_path)
            return (file_size, width, height)

        except ImportError:
            # PIL 不可用时，使用 PyMuPDF 直接保存
            pix.save(output_path)
            file_size = os.path.getsize(output_path)
            return (file_size, width, height)

    def _get_output_filename(
        self,
        output_path: str,
        output_dir: str,
        output_basename: str,
        page_num: int,
        page_count: int
    ) -> str:
        """确定输出文件名"""
        if page_count == 1:
            return output_path
        else:
            # 多页PDF：创建同名子文件夹
            subfolder = os.path.join(output_dir, output_basename)
            os.makedirs(subfolder, exist_ok=True)
            return os.path.join(subfolder, f"page{page_num + 1}.png")

    def _convert_page(
        self,
        page,
        output_path: str,
        dpi_levels: List[int],
        max_size_mb: float,
        quality_first: bool,
        png_compress_level: int,
        page_num: int,
        min_dpi: int,
        progress_callback: Optional[Callable[[str], None]]
    ) -> Optional[tuple]:
        """
        转换单个页面（使用二分搜索优化 DPI 查找 + PNG 压缩优化）

        Returns:
            成功返回 (文件路径, 实际DPI)，失败返回 None
        """
        # 质量优先模式：直接使用最高 DPI
        if quality_first:
            return self._render_quality_first(
                page, output_path, dpi_levels[0],
                png_compress_level, page_num, progress_callback
            )

        # 大小限制模式
        return self._render_with_size_limit(
            page, output_path, dpi_levels, max_size_mb,
            png_compress_level, page_num, min_dpi, progress_callback
        )

    def _render_quality_first(
        self,
        page,
        output_path: str,
        dpi: int,
        png_compress_level: int,
        page_num: int,
        progress_callback: Optional[Callable[[str], None]]
    ) -> tuple:
        """质量优先模式渲染（优化版：单次渲染+单次 I/O）"""
        if progress_callback:
            progress_callback(f"  渲染 {dpi} DPI...")

        zoom = dpi / DPIConfig.PDF_BASE_DPI
        mat = self.fitz.Matrix(zoom, zoom)
        pix = page.get_pixmap(matrix=mat, alpha=False)

        try:
            if progress_callback:
                progress_callback(f"  压缩保存中...")

            # 单次压缩+保存，避免双重 I/O
            file_size, width, height = self._compress_and_save_png(
                pix, output_path, png_compress_level
            )
            file_size_mb = file_size / (1024 * 1024)

            if progress_callback:
                progress_callback(
                    f"  ✓ 页 {page_num + 1}: {file_size_mb:.2f}MB, "
                    f"{width}×{height}, {dpi}DPI"
                )
            return (output_path, dpi)
        except Exception as e:
            raise ConversionError(f"保存文件失败: {e}") from e
        finally:
            del pix

    def _render_with_size_limit(
        self,
        page,
        output_path: str,
        dpi_levels: List[int],
        max_size_mb: float,
        png_compress_level: int,
        page_num: int,
        min_dpi: int,
        progress_callback: Optional[Callable[[str], None]]
    ) -> tuple:
        """
        大小限制模式渲染

        策略：渐进式调整 + 强制验证 + 向上逼近
        目标：绝不超限 + 尽量接近限制（98%+）
        """
        import io
        from PIL import Image

        max_size_bytes = int(max_size_mb * 1024 * 1024)
        max_dpi = dpi_levels[0]

        def render_to_memory(dpi: int):
            """渲染到内存"""
            zoom = dpi / DPIConfig.PDF_BASE_DPI
            mat = self.fitz.Matrix(zoom, zoom)
            pix = page.get_pixmap(matrix=mat, alpha=False)
            img = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
            buffer = io.BytesIO()
            img.save(buffer, 'PNG', optimize=True, compress_level=png_compress_level)
            png_bytes = buffer.getvalue()
            w, h = pix.width, pix.height
            del pix
            return (png_bytes, w, h)

        # 第一步：尝试最高 DPI
        if progress_callback:
            progress_callback(f"  尝试 {max_dpi} DPI...")

        result_bytes, result_w, result_h = render_to_memory(max_dpi)
        actual_size = len(result_bytes)

        # 如果最高 DPI 不超限，直接使用
        if actual_size <= max_size_bytes:
            with open(output_path, 'wb') as f:
                f.write(result_bytes)
            file_size_mb = actual_size / (1024 * 1024)
            if progress_callback:
                progress_callback(
                    f"  ✓ 页 {page_num + 1}: {file_size_mb:.2f}MB, "
                    f"{result_w}×{result_h}, {max_dpi}DPI"
                )
            return (output_path, max_dpi)

        # 第二步：超限了，渐进式降低 DPI 直到不超限
        current_dpi = max_dpi
        safety = 0.95

        for _ in range(3):
            ratio = max_size_bytes / actual_size
            current_dpi = int(current_dpi * (ratio ** 0.5) * safety)
            current_dpi = max(min_dpi, current_dpi)

            if progress_callback:
                progress_callback(f"  优化至 {current_dpi} DPI...")

            result_bytes, result_w, result_h = render_to_memory(current_dpi)
            actual_size = len(result_bytes)

            if actual_size <= max_size_bytes:
                break
            safety *= 0.95  # 更保守

        # 第三步：如果仍然超限，使用二分法继续降低 DPI
        if actual_size > max_size_bytes and current_dpi > min_dpi:
            if progress_callback:
                progress_callback(f"  二分法降低 DPI...")

            low_dpi = min_dpi
            high_dpi = current_dpi

            while high_dpi - low_dpi > 5:
                mid_dpi = (low_dpi + high_dpi) // 2
                mid_bytes, mid_w, mid_h = render_to_memory(mid_dpi)

                if len(mid_bytes) <= max_size_bytes:
                    low_dpi = mid_dpi
                    result_bytes = mid_bytes
                    result_w, result_h = mid_w, mid_h
                    current_dpi = mid_dpi
                    actual_size = len(mid_bytes)
                else:
                    high_dpi = mid_dpi

            # 如果二分法后仍超限，使用 min_dpi
            if actual_size > max_size_bytes:
                result_bytes, result_w, result_h = render_to_memory(min_dpi)
                current_dpi = min_dpi
                actual_size = len(result_bytes)

        # 第四步：如果不超限但太保守（<90%限制），尝试向上逼近
        if actual_size <= max_size_bytes * 0.90 and current_dpi < max_dpi:
            if progress_callback:
                progress_callback(f"  向上逼近...")

            best_bytes = result_bytes
            best_w, best_h = result_w, result_h
            best_dpi = current_dpi

            low_dpi = current_dpi
            high_dpi = min(int(current_dpi * 1.15), max_dpi)

            while high_dpi - low_dpi > 10:
                mid_dpi = (low_dpi + high_dpi) // 2
                mid_bytes, mid_w, mid_h = render_to_memory(mid_dpi)

                if len(mid_bytes) <= max_size_bytes:
                    low_dpi = mid_dpi
                    best_bytes = mid_bytes
                    best_w, best_h = mid_w, mid_h
                    best_dpi = mid_dpi
                else:
                    high_dpi = mid_dpi

            result_bytes = best_bytes
            result_w, result_h = best_w, best_h
            current_dpi = best_dpi

        # 第五步：最终强制验证（绝不超限）
        final_size = len(result_bytes)
        if final_size > max_size_bytes:
            if progress_callback:
                progress_callback(f"  强制降低 DPI...")

            # 仍然超限，强制使用 min_dpi
            result_bytes, result_w, result_h = render_to_memory(min_dpi)
            current_dpi = min_dpi
            final_size = len(result_bytes)

            # 如果 min_dpi 仍超限，继续降低直到满足或达到绝对最低
            emergency_dpi = min_dpi
            while final_size > max_size_bytes and emergency_dpi > 36:
                emergency_dpi = int(emergency_dpi * 0.8)
                result_bytes, result_w, result_h = render_to_memory(emergency_dpi)
                final_size = len(result_bytes)
                current_dpi = emergency_dpi

        # 保存最终结果
        with open(output_path, 'wb') as f:
            f.write(result_bytes)

        file_size_mb = len(result_bytes) / (1024 * 1024)
        if progress_callback:
            progress_callback(
                f"  ✓ 页 {page_num + 1}: {file_size_mb:.2f}MB, "
                f"{result_w}×{result_h}, {current_dpi}DPI"
            )
        return (output_path, current_dpi)

    def batch_convert(
        self,
        pattern: str,
        output_dir: Optional[str] = None,
        batch_progress_callback: Optional[Callable[[str], None]] = None,
        **kwargs
    ) -> List[str]:
        """
        批量转换 PDF 文件

        Args:
            pattern: 文件匹配模式（如 "*.pdf"）
            output_dir: 输出目录（可选）
            batch_progress_callback: 批量进度回调函数
            **kwargs: 传递给 convert() 的其他参数

        Returns:
            所有生成的文件列表
        """
        import glob

        pdf_files = sorted(glob.glob(pattern))

        if not pdf_files:
            raise FileNotFoundError(f"未找到匹配的文件: {pattern}")

        all_generated = []
        total = len(pdf_files)

        for i, pdf_file in enumerate(pdf_files, 1):
            if batch_progress_callback:
                batch_progress_callback(f"\n[{i}/{total}] 处理: {pdf_file}")

            if output_dir:
                os.makedirs(output_dir, exist_ok=True)
                basename = os.path.splitext(os.path.basename(pdf_file))[0]
                output_path = os.path.join(output_dir, f"{basename}.png")
            else:
                output_path = None

            try:
                result = self.convert(pdf_file, output_path, **kwargs)
                all_generated.extend(result.get('files', []))
            except Exception as e:
                if batch_progress_callback:
                    batch_progress_callback(f"  ✗ 转换失败: {e}")

        return all_generated


# ============================================================================
# 工具函数
# ============================================================================

def format_file_size(size_bytes: int) -> str:
    """
    格式化文件大小为人类可读的字符串

    Args:
        size_bytes: 字节数

    Returns:
        格式化的字符串（如 "1.5 MB", "500.0 KB"）
    """
    if size_bytes <= 0:
        return "0 KB"

    size_kb = size_bytes / 1024
    if size_kb < 1024:
        return f"{size_kb:.1f} KB"
    else:
        size_mb = size_kb / 1024
        return f"{size_mb:.2f} MB"


def generate_dpi_levels(
    min_dpi: int,
    max_dpi: int,
    quality_first: bool = False,
    step: int = ConverterConfig.DPI_STEP
) -> List[int]:
    """
    生成 DPI 等级列表

    Args:
        min_dpi: 最低 DPI
        max_dpi: 最高 DPI
        quality_first: 质量优先模式（仅返回最高 DPI）
        step: DPI 步长

    Returns:
        DPI 等级列表，从高到低排序
    """
    if quality_first:
        return [max_dpi]

    dpi_levels = list(range(max_dpi, min_dpi - 1, -step))

    if min_dpi not in dpi_levels:
        dpi_levels.append(min_dpi)

    return dpi_levels


def validate_dpi_range(min_dpi: int, max_dpi: int) -> bool:
    """
    验证 DPI 范围是否有效

    Args:
        min_dpi: 最低 DPI
        max_dpi: 最高 DPI

    Returns:
        True 如果有效，False 否则
    """
    return (
        DPIConfig.MIN_DPI <= min_dpi <= DPIConfig.MAX_DPI and
        DPIConfig.MIN_DPI <= max_dpi <= DPIConfig.MAX_DPI and
        min_dpi <= max_dpi
    )
