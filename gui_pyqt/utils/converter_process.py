#!/usr/bin/env python3
"""
独立转换进程脚本

通过 QProcess 调用，完全独立于主进程运行
通过 stdout 输出 JSON 格式的进度和结果
"""

import sys
import os
import json
from pathlib import Path

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from converter import PDFConverter


def send_message(msg_type: str, data: dict):
    """发送 JSON 消息到 stdout"""
    message = {"type": msg_type, **data}
    print(json.dumps(message, ensure_ascii=False), flush=True)


def convert_file(file_path: str, output_path: str, params: dict) -> bool:
    """
    转换单个文件

    Returns:
        True 如果成功，False 如果失败
    """
    import time
    import fitz
    start_time = time.time()

    try:
        # 获取页数用于进度显示
        doc = fitz.open(file_path)
        page_count = len(doc)
        doc.close()

        # 发送开始信号（包含页数信息）
        send_message("start", {"file": file_path, "pages": page_count})

        # 提取参数
        quality_first = params.get('quality_first', True)
        max_size_mb = params.get('max_size_mb', 5)
        # 大小优先模式：使用高 DPI 上限以最大化清晰度
        # 清晰度优先模式：使用用户设置的 DPI
        default_max_dpi = 1200 if not quality_first else 300
        max_dpi = params.get('dpi', default_max_dpi)

        # 进度回调：发送页面进度
        completed_count = [0]  # 已完成页数

        def progress_callback(msg: str):
            # 检测页面完成消息（✓ 或 ✗ 开头表示页面处理完成）
            if ("✓ 页" in msg or "✗ 页" in msg or "⚠ 页" in msg) and ":" in msg:
                completed_count[0] += 1
                send_message("page_progress", {
                    "file": file_path,
                    "current": completed_count[0],
                    "total": page_count
                })

        # 创建转换器
        converter = PDFConverter()

        # 执行转换 - 返回字典 {'files': [...], 'dpi': actual_dpi}
        # min_dpi=72 允许在极小文件大小限制下继续降低 DPI
        result = converter.convert(
            pdf_path=file_path,
            output_path=output_path,
            max_size_mb=max_size_mb,
            min_dpi=72,
            max_dpi=max_dpi,
            quality_first=quality_first,
            png_compress_level=6,
            progress_callback=progress_callback
        )

        generated_files = result.get('files', [])
        dpi_min = result.get('dpi_min', max_dpi)
        dpi_max = result.get('dpi_max', max_dpi)

        if generated_files and len(generated_files) > 0:
            # 计算文件大小
            file_sizes = [os.path.getsize(f) for f in generated_files]
            total_size = sum(file_sizes)
            max_page_size = max(file_sizes)  # 最大单页大小（用于超限检查）
            size_mb = total_size / (1024 * 1024)
            max_page_size_mb = max_page_size / (1024 * 1024)
            elapsed_seconds = time.time() - start_time

            # 发送成功信号
            send_message("success", {
                "file": file_path,
                "size_mb": size_mb,
                "max_page_size_mb": max_page_size_mb,  # 最大单页大小
                "page_count": len(generated_files),
                "dpi_min": dpi_min,
                "dpi_max": dpi_max,
                "elapsed": elapsed_seconds,
                "output_files": generated_files
            })
            return True
        else:
            send_message("error", {
                "file": file_path,
                "message": "未生成输出文件"
            })
            return False

    except Exception as e:
        send_message("error", {
            "file": file_path,
            "message": str(e)
        })
        return False


def main():
    """主入口 - 从 stdin 读取任务"""
    # 从 stdin 读取 JSON 任务
    try:
        task_json = sys.stdin.read()
        task = json.loads(task_json)
    except Exception as e:
        send_message("fatal", {"message": f"无法解析任务: {e}"})
        sys.exit(1)

    files = task.get('files', [])
    params_dict = task.get('params_dict', {})
    output_dir = task.get('output_dir', None)

    success_count = 0
    failed_count = 0

    for file_path in files:
        # 获取参数
        params = params_dict.get(file_path, {
            'dpi': 300,
            'max_size_mb': 5,
            'quality_first': True
        })

        # 确定输出路径
        if output_dir:
            output_path = str(Path(output_dir) / (Path(file_path).stem + '.png'))
        else:
            output_path = str(Path(file_path).with_suffix('.png'))

        # 转换
        if convert_file(file_path, output_path, params):
            success_count += 1
        else:
            failed_count += 1

    # 发送完成信号
    send_message("completed", {
        "total": len(files),
        "success": success_count,
        "failed": failed_count
    })


if __name__ == '__main__':
    main()
