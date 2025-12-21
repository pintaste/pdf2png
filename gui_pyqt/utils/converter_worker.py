#!/usr/bin/env python3
"""
转换工作器

使用 QProcess 在独立进程中执行转换
完全避免 GIL 影响，确保 UI 动画流畅
"""

import os
import sys
import json
from pathlib import Path
from typing import List, Dict

from PyQt6.QtCore import QObject, QProcess, pyqtSignal


class ConverterWorker(QObject):
    """
    PDF 转换工作器

    使用 QProcess 在独立进程中运行转换
    主线程 UI 完全不受影响

    信号：
    - progress_updated: (file_path, progress, status)
    - file_completed: (file_path, success, message)
    - file_result: (file_path, size_mb, dpi, elapsed)
    - all_completed: (total, success_count, failed_count)
    """

    progress_updated = pyqtSignal(str, int, str)  # 文件路径, 进度, 状态
    page_progress = pyqtSignal(str, int, int)     # 文件路径, 当前页, 总页数
    file_completed = pyqtSignal(str, bool, str)   # 文件路径, 是否成功, 消息
    file_result = pyqtSignal(str, float, float, int, int, float, int)  # 文件路径, 大小MB, 最大单页大小MB, DPI最小, DPI最大, 耗时秒, 页数
    all_completed = pyqtSignal(int, int, int)     # 总数, 成功数, 失败数

    def __init__(self, files: List[str], params_dict: Dict[str, dict], output_dir: str = None):
        """
        初始化转换工作器

        Args:
            files: PDF 文件列表
            params_dict: 每个文件的参数字典 {file_path: params}
            output_dir: 输出目录（None 则输出到同目录）
        """
        super().__init__()

        self.files = files
        self.params_dict = params_dict
        self.output_dir = output_dir

        self._process = None
        self._buffer = ""

    def start(self):
        """启动转换进程"""
        # 第一步：检查所有源文件是否存在
        missing_files = []
        valid_files = []
        for file_path in self.files:
            if os.path.exists(file_path):
                valid_files.append(file_path)
            else:
                missing_files.append(file_path)

        # 立即报告不存在的文件
        for file_path in missing_files:
            self.progress_updated.emit(file_path, 0, "文件不存在")
            self.file_completed.emit(file_path, False, "文件不存在")

        # 如果没有有效文件，直接结束
        if not valid_files:
            self.all_completed.emit(len(self.files), 0, len(missing_files))
            return

        # 更新文件列表为有效文件
        self.files = valid_files

        # 获取转换脚本路径
        script_path = Path(__file__).parent / "converter_process.py"

        # 创建进程
        self._process = QProcess(self)
        self._process.readyReadStandardOutput.connect(self._on_stdout)
        self._process.readyReadStandardError.connect(self._on_stderr)
        self._process.finished.connect(self._on_finished)

        # 启动进程
        self._process.start(sys.executable, [str(script_path)])

        # 等待进程启动
        if not self._process.waitForStarted(5000):
            self.all_completed.emit(len(self.files), 0, len(self.files))
            return

        # 发送任务数据
        task = {
            "files": self.files,
            "params_dict": self.params_dict,
            "output_dir": self.output_dir
        }
        task_json = json.dumps(task, ensure_ascii=False)
        self._process.write(task_json.encode('utf-8'))
        self._process.closeWriteChannel()

        # 立即为所有文件发送开始信号（启动 spinner）
        for file_path in self.files:
            self.progress_updated.emit(file_path, 0, "")

    def cancel(self):
        """取消转换"""
        if self._process and self._process.state() == QProcess.ProcessState.Running:
            self._process.terminate()
            # 给进程一点时间正常退出
            if not self._process.waitForFinished(1000):
                self._process.kill()

    def _on_stdout(self):
        """处理标准输出"""
        data = self._process.readAllStandardOutput().data().decode('utf-8')
        self._buffer += data

        # 按行处理
        while '\n' in self._buffer:
            line, self._buffer = self._buffer.split('\n', 1)
            line = line.strip()
            if line:
                self._process_message(line)

    def _on_stderr(self):
        """处理标准错误（忽略，避免干扰）"""
        # 读取但不处理
        self._process.readAllStandardError()

    def _on_finished(self, exit_code: int, exit_status: QProcess.ExitStatus):
        """进程结束"""
        # 处理缓冲区中剩余的数据
        if self._buffer.strip():
            self._process_message(self._buffer.strip())
            self._buffer = ""

    def _process_message(self, line: str):
        """处理一条 JSON 消息"""
        try:
            msg = json.loads(line)
            msg_type = msg.get("type", "")

            if msg_type == "start":
                file_path = msg.get("file", "")
                self.progress_updated.emit(file_path, 0, "转换中...")

            elif msg_type == "success":
                file_path = msg.get("file", "")
                size_mb = msg.get("size_mb", 0)
                max_page_size_mb = msg.get("max_page_size_mb", 0)
                dpi_min = msg.get("dpi_min", 300)
                dpi_max = msg.get("dpi_max", 300)
                elapsed = msg.get("elapsed", 0)
                page_count = msg.get("page_count", 1)
                output_files = msg.get("output_files", [])

                self.progress_updated.emit(file_path, 100, "转换完成")
                self.file_result.emit(file_path, size_mb, max_page_size_mb, dpi_min, dpi_max, elapsed, page_count)

                if len(output_files) == 1:
                    message = f"已保存到: {output_files[0]}"
                else:
                    message = f"已保存 {len(output_files)} 个文件"
                self.file_completed.emit(file_path, True, message)

            elif msg_type == "error":
                file_path = msg.get("file", "")
                error_msg = msg.get("message", "未知错误")
                self.progress_updated.emit(file_path, 0, "转换失败")
                self.file_completed.emit(file_path, False, error_msg)

            elif msg_type == "page_progress":
                file_path = msg.get("file", "")
                current = msg.get("current", 0)
                total = msg.get("total", 0)
                self.page_progress.emit(file_path, current, total)

            elif msg_type == "completed":
                total = msg.get("total", 0)
                success = msg.get("success", 0)
                failed = msg.get("failed", 0)
                self.all_completed.emit(total, success, failed)

            elif msg_type == "fatal":
                # 致命错误
                self.all_completed.emit(len(self.files), 0, len(self.files))

        except json.JSONDecodeError:
            # 忽略非 JSON 行
            pass
