#!/usr/bin/env python3
"""
PDF2PNG 主窗口

重构后：
- 使用统一主题模块
- 分离 UI 创建和事件处理
- 使用常量配置替代硬编码
"""
import sys
import os
from typing import List

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from PyQt6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QFileDialog, QMessageBox, QApplication, QStackedWidget,
    QDialog, QLabel
)
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QDragEnterEvent, QDropEvent, QShortcut, QKeySequence

from config import AppConfig
from constants import WindowConfig, UIConfig
from gui_pyqt.theme import Theme
from gui_pyqt.i18n import I18n
from gui_pyqt.utils.sound import Sound


class PDF2PNGMainWindow(QMainWindow):
    """PDF2PNG 主窗口"""

    def __init__(self):
        super().__init__()

        self.config = AppConfig.load()
        self.converter_worker = None
        self.current_output_dir = None
        self._drag_pos = None

        # 先应用语言和主题设置（UI 创建前）
        self._apply_language_theme()

        self._init_ui()
        self._apply_config()
        self._setup_shortcuts()
        self.setAcceptDrops(True)

    # ========================================================================
    # UI 初始化
    # ========================================================================

    def _init_ui(self):
        """初始化UI"""
        self.setWindowTitle("PDF → PNG")
        self.setMinimumSize(WindowConfig.MIN_WIDTH, WindowConfig.MIN_HEIGHT)
        self.resize(WindowConfig.DEFAULT_WIDTH, WindowConfig.DEFAULT_HEIGHT)

        # 无边框圆角窗口
        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.NoDropShadowWindowHint
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setStyleSheet(Theme.main_window_style())

        # 双状态管理
        self.stack = QStackedWidget()
        self.setCentralWidget(self.stack)

        self.empty_state = self._create_empty_state()
        self.stack.addWidget(self.empty_state)

        self.working_state = self._create_working_state()
        self.stack.addWidget(self.working_state)

        self.stack.setCurrentIndex(0)
        self.statusBar().hide()

    def _create_empty_state(self) -> QWidget:
        """创建空状态"""
        from .widgets.empty_state import EmptyStateWidget
        widget = EmptyStateWidget()
        widget.files_selected.connect(self._on_files_dropped)
        return widget

    def _create_working_state(self) -> QWidget:
        """创建工作状态"""
        widget = QWidget()
        widget.setObjectName("working_state")
        widget.setAttribute(Qt.WidgetAttribute.WA_StyledBackground, True)

        layout = QVBoxLayout(widget)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # 标题栏
        from .widgets.compact_title_bar import CompactTitleBar
        self.title_bar = CompactTitleBar()
        self.title_bar.settings_toggle_requested.connect(self._toggle_settings)
        self.title_bar.theme_changed.connect(self._on_theme_changed)
        layout.addWidget(self.title_bar)

        # 设置面板
        from .widgets.collapsible_settings import CollapsibleSettingsPanel
        self.settings_panel = CollapsibleSettingsPanel()
        self.settings_panel.priority_changed.connect(self._on_priority_changed)
        self.settings_panel.dpi_changed.connect(self._on_dpi_changed)
        self.settings_panel.size_changed.connect(self._on_size_changed)
        self.settings_panel.language_changed.connect(self._on_language_changed)
        layout.addWidget(self.settings_panel)

        # 内容区
        layout.addWidget(self._create_content_area(), 1)
        layout.addWidget(self._create_bottom_bar())

        # 应用样式
        widget.setStyleSheet(Theme.working_state_style())

        return widget

    def _create_content_area(self) -> QWidget:
        """创建内容区"""
        from .widgets.file_list import FileListWidget
        self.file_list_widget = FileListWidget()
        self.file_list_widget.files_changed.connect(self._on_files_changed)
        return self.file_list_widget

    def _create_bottom_bar(self) -> QWidget:
        """创建底部栏"""
        widget = QWidget()
        widget.setObjectName("bottom_bar")
        widget.setAttribute(Qt.WidgetAttribute.WA_StyledBackground, True)
        widget.setFixedHeight(UIConfig.BOTTOM_BAR_HEIGHT)

        layout = QHBoxLayout(widget)
        layout.setContentsMargins(15, 10, 15, 10)
        layout.setSpacing(10)

        self.add_btn = QPushButton(I18n.get('add'))
        self.add_btn.setFixedSize(75, UIConfig.BUTTON_HEIGHT)
        self.add_btn.clicked.connect(self._add_files)
        layout.addWidget(self.add_btn)

        self.clear_btn = QPushButton(I18n.get('clear'))
        self.clear_btn.setFixedSize(70, UIConfig.BUTTON_HEIGHT)
        self.clear_btn.clicked.connect(self._clear_files)
        layout.addWidget(self.clear_btn)

        layout.addStretch()

        self.convert_btn = QPushButton(I18n.get('convert'))
        self.convert_btn.setObjectName("convert_btn")
        self.convert_btn.setFixedSize(100, UIConfig.BUTTON_HEIGHT)
        self.convert_btn.clicked.connect(self._start_conversion)
        layout.addWidget(self.convert_btn)

        self.cancel_btn = QPushButton(I18n.get('cancel'))
        self.cancel_btn.setFixedSize(80, UIConfig.BUTTON_HEIGHT)
        self.cancel_btn.clicked.connect(self._cancel_conversion)
        self.cancel_btn.hide()
        layout.addWidget(self.cancel_btn)

        return widget

    def _apply_language_theme(self):
        """应用语言和主题设置（UI 创建前调用）"""
        saved_lang = self.config.get('language', 'zh')
        saved_theme = self.config.get('theme', 'dark')

        if saved_lang != I18n.get_language():
            I18n.set_language(saved_lang)

        if saved_theme != Theme.get_mode():
            Theme.set_mode(saved_theme)

    def _apply_config(self):
        """应用配置"""
        # 转换设置
        self.settings_panel.set_priority_mode(self.config.get('priority_mode', 'quality'))
        self.settings_panel.set_dpi(self.config.get('last_dpi', 300))
        self.settings_panel.set_size_limit(self.config.get('last_size', 5))
        self._update_settings_summary()

    def _setup_shortcuts(self):
        """设置快捷键"""
        QShortcut(QKeySequence("Ctrl+W"), self).activated.connect(self._clear_files)
        QShortcut(QKeySequence("Ctrl+Return"), self).activated.connect(self._start_conversion)
        QShortcut(QKeySequence("Esc"), self).activated.connect(self._cancel_conversion)

    # ========================================================================
    # 事件处理
    # ========================================================================

    def dragEnterEvent(self, event: QDragEnterEvent):
        if event.mimeData().hasUrls():
            for url in event.mimeData().urls():
                if url.toLocalFile().lower().endswith('.pdf'):
                    event.acceptProposedAction()
                    return
        event.ignore()

    def dropEvent(self, event: QDropEvent):
        files = [
            url.toLocalFile()
            for url in event.mimeData().urls()
            if url.toLocalFile().lower().endswith('.pdf')
        ]
        if files:
            self._add_files_to_list(files)

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton and self.stack.currentIndex() == 0:
            self._drag_pos = event.globalPosition().toPoint() - self.frameGeometry().topLeft()
            event.accept()

    def mouseMoveEvent(self, event):
        if event.buttons() == Qt.MouseButton.LeftButton and self._drag_pos:
            self.move(event.globalPosition().toPoint() - self._drag_pos)
            event.accept()

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self._drag_pos = None

    def closeEvent(self, event):
        AppConfig.save(self.config)
        event.accept()

    # ========================================================================
    # 状态管理
    # ========================================================================

    def _on_files_dropped(self, files: List[str]):
        """文件拖入"""
        self.stack.setCurrentIndex(1)
        self._add_files_to_list(files)

    def _toggle_settings(self):
        """切换设置面板"""
        self.settings_panel.toggle()

    def _on_language_changed(self, lang: str):
        """语言切换回调"""
        self.config['language'] = lang
        AppConfig.save(self.config)
        self._refresh_all_texts()

    def _on_theme_changed(self, mode: str):
        """主题切换回调"""
        self.config['theme'] = mode
        AppConfig.save(self.config)
        self._refresh_all_styles()

    def _refresh_all_texts(self):
        """刷新所有 UI 文本"""
        self.title_bar.update_texts()
        self.settings_panel.update_texts()
        self.add_btn.setText(I18n.get('add'))
        self.clear_btn.setText(I18n.get('clear'))
        self.convert_btn.setText(I18n.get('convert'))
        self.cancel_btn.setText(I18n.get('cancel'))
        self.file_list_widget.update_texts()
        self.empty_state.update_texts()
        self._update_settings_summary()

    def _refresh_all_styles(self):
        """刷新所有 UI 样式"""
        self.setStyleSheet(Theme.main_window_style())
        self.working_state.setStyleSheet(Theme.working_state_style())
        self.title_bar.refresh_style()
        self.settings_panel.refresh_style()
        self.file_list_widget.refresh_style()
        self.empty_state.refresh_style()

    def _update_settings_summary(self):
        """更新设置摘要"""
        params = self.settings_panel.get_current_params()
        if params.get('quality_first'):
            text = f"DPI: {params.get('dpi', 300)}"
        else:
            text = f"{I18n.get('limit_label')} {params.get('max_size_mb', 5)} MB"
        self.file_list_widget.update_settings_summary(text)

    # ========================================================================
    # 设置变更处理
    # ========================================================================

    def _on_priority_changed(self, mode: str):
        """优化模式变更"""
        self.config['priority_mode'] = mode
        AppConfig.save(self.config)
        self._sync_params_to_file_list()
        self._update_settings_summary()

    def _on_dpi_changed(self, dpi: int):
        """DPI 变更"""
        self.config['last_dpi'] = dpi
        AppConfig.save(self.config)
        self._sync_params_to_file_list()
        self._update_settings_summary()

    def _on_size_changed(self, size_mb: int):
        """大小限制变更"""
        self.config['last_size'] = size_mb
        AppConfig.save(self.config)
        self._sync_params_to_file_list()
        self._update_settings_summary()

    def _sync_params_to_file_list(self):
        """同步参数到文件列表"""
        self.file_list_widget.update_all_params(self.settings_panel.get_current_params())

    # ========================================================================
    # 文件操作
    # ========================================================================

    def _add_files(self):
        """添加文件对话框"""
        files, _ = QFileDialog.getOpenFileNames(
            self, I18n.get('select_pdf'), "",
            I18n.get('pdf_filter')
        )
        if files:
            self._add_files_to_list(files)

    def _add_files_to_list(self, files: List[str]):
        """添加文件到列表"""
        self.file_list_widget.add_files(files)
        self.file_list_widget.update_all_params(self.settings_panel.get_current_params())

    def _clear_files(self):
        """清空文件列表"""
        self.file_list_widget.clear()
        self.stack.setCurrentIndex(0)

    def _on_files_changed(self):
        """文件列表变更"""
        count = len(self.file_list_widget.get_files())
        self.convert_btn.setEnabled(count > 0)

    # ========================================================================
    # 对话框
    # ========================================================================

    def _show_confirm_dialog(self, title: str, message: str) -> bool:
        """显示暗色主题确认对话框（无边框设计）"""
        c = Theme.colors
        dialog = QDialog(self)
        dialog.setModal(True)
        dialog.setMinimumWidth(380)
        dialog.setMaximumWidth(500)

        # 无边框窗口
        dialog.setWindowFlags(
            Qt.WindowType.Dialog |
            Qt.WindowType.FramelessWindowHint
        )
        dialog.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)

        # 主容器（用于圆角和背景）
        container = QWidget(dialog)
        container.setObjectName("dialog_container")

        dialog_layout = QVBoxLayout(dialog)
        dialog_layout.setContentsMargins(0, 0, 0, 0)
        dialog_layout.addWidget(container)

        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # 自定义标题栏
        title_bar = QWidget()
        title_bar.setObjectName("dialog_title_bar")
        title_bar.setFixedHeight(40)
        title_layout = QHBoxLayout(title_bar)
        title_layout.setContentsMargins(16, 0, 16, 0)

        title_label = QLabel(title)
        title_label.setStyleSheet(f"color: {c.text_primary}; font-size: 14px; font-weight: 600;")
        title_layout.addWidget(title_label)
        title_layout.addStretch()

        layout.addWidget(title_bar)

        # 内容区域
        content = QWidget()
        content.setObjectName("dialog_content")
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(20, 16, 20, 20)
        content_layout.setSpacing(20)

        # 消息文本
        msg_label = QLabel(message)
        msg_label.setWordWrap(True)
        msg_label.setStyleSheet(f"color: {c.text_secondary}; font-size: 13px; line-height: 1.5;")
        content_layout.addWidget(msg_label)

        # 按钮行
        btn_layout = QHBoxLayout()
        btn_layout.setSpacing(12)
        btn_layout.addStretch()

        no_btn = QPushButton("取消")
        no_btn.setFixedSize(90, 34)
        no_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        no_btn.clicked.connect(dialog.reject)
        btn_layout.addWidget(no_btn)

        yes_btn = QPushButton("确定")
        yes_btn.setFixedSize(90, 34)
        yes_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        yes_btn.clicked.connect(dialog.accept)
        yes_btn.setDefault(True)
        btn_layout.addWidget(yes_btn)

        content_layout.addLayout(btn_layout)
        layout.addWidget(content)

        # 应用暗色主题样式
        container.setStyleSheet(f"""
            #dialog_container {{
                background-color: {c.background_primary};
                border: 1px solid {c.border_normal};
                border-radius: 12px;
            }}
            #dialog_title_bar {{
                background-color: {c.background_secondary};
                border-top-left-radius: 12px;
                border-top-right-radius: 12px;
                border-bottom: 1px solid {c.border_normal};
            }}
            #dialog_content {{
                background-color: {c.background_primary};
                border-bottom-left-radius: 12px;
                border-bottom-right-radius: 12px;
            }}
            QPushButton {{
                background: {c.background_secondary};
                border: 1px solid {c.border_normal};
                border-radius: 6px;
                color: {c.text_secondary};
                font-size: 13px;
            }}
            QPushButton:hover {{
                background: {c.background_tertiary};
                border-color: {c.border_hover};
            }}
            QPushButton:default {{
                background: {c.accent};
                border: none;
                color: #000000;
                font-weight: 600;
            }}
            QPushButton:default:hover {{
                background: {c.accent_hover};
            }}
        """)

        # 调整大小并居中
        dialog.adjustSize()

        return dialog.exec() == QDialog.DialogCode.Accepted

    # ========================================================================
    # 转换操作
    # ========================================================================

    def _start_conversion(self):
        """开始转换"""
        files = self.file_list_widget.get_files()
        if not files:
            QMessageBox.warning(self, I18n.get('hint'), I18n.get('no_files_hint'))
            return

        # 检查是否有已完成的文件
        if self.file_list_widget.has_completed_files():
            completed_count = self.file_list_widget.get_completed_count()
            if not self._show_confirm_dialog(
                I18n.get('confirm_reconvert_title'),
                I18n.get('confirm_reconvert_msg', count=completed_count)
            ):
                return

        output_dir = QFileDialog.getExistingDirectory(
            self, I18n.get('select_output_dir'), "",
            QFileDialog.Option.ShowDirsOnly
        )
        if not output_dir:
            return

        # 检查是否有文件会被覆盖
        import os
        from pathlib import Path
        existing_outputs = []
        for file_path in files:
            pdf_name = Path(file_path).stem
            # 检查单页输出文件
            png_path = os.path.join(output_dir, f"{pdf_name}.png")
            # 检查多页输出文件夹
            folder_path = os.path.join(output_dir, pdf_name)
            if os.path.exists(png_path):
                existing_outputs.append(f"{pdf_name}.png")
            elif os.path.exists(folder_path):
                existing_outputs.append(f"{pdf_name}/")

        if existing_outputs:
            if len(existing_outputs) <= 3:
                files_text = "\n".join(f"  • {f}" for f in existing_outputs)
            else:
                files_text = "\n".join(f"  • {f}" for f in existing_outputs[:3])
                files_text += f"\n  {I18n.get('and_more_files', count=len(existing_outputs))}"

            if not self._show_confirm_dialog(
                I18n.get('confirm_overwrite_title'),
                I18n.get('confirm_overwrite_msg', files=files_text)
            ):
                return

        self.current_output_dir = output_dir
        params_dict = {f: self.file_list_widget.get_file_params(f) for f in files}

        from .utils.converter_worker import ConverterWorker
        self.converter_worker = ConverterWorker(files, params_dict, output_dir)
        self.converter_worker.progress_updated.connect(self._on_progress)
        self.converter_worker.page_progress.connect(self._on_page_progress)
        self.converter_worker.file_completed.connect(self._on_file_done)
        self.converter_worker.file_result.connect(self._on_file_result)
        self.converter_worker.all_completed.connect(self._on_all_done)

        self._set_converting_ui(True)
        self.file_list_widget.reset_all()
        self.converter_worker.start()

    def _cancel_conversion(self):
        """取消转换"""
        if self.converter_worker:
            self.converter_worker.cancel()
            self._set_converting_ui(False)
            self.file_list_widget.reset_all()

    def _on_progress(self, file_path: str, progress: int, status: str):
        """进度更新"""
        self.file_list_widget.update_progress(file_path, progress, status)

    def _on_page_progress(self, file_path: str, current: int, total: int):
        """页面进度更新"""
        self.file_list_widget.update_page_progress(file_path, current, total)

    def _on_file_done(self, file_path: str, success: bool, message: str):
        """单文件完成"""
        if not success:
            self.file_list_widget.update_error(file_path, message)

    def _on_file_result(self, file_path: str, size_mb: float, max_page_size_mb: float, dpi_min: int, dpi_max: int, elapsed: float, page_count: int):
        """文件转换结果"""
        self.file_list_widget.update_result(file_path, size_mb, max_page_size_mb, dpi_min, dpi_max, elapsed, page_count)

    def _on_all_done(self, total: int, success: int, failed: int):
        """全部完成"""
        self._set_converting_ui(False)
        # 播放音效
        if failed > 0:
            Sound.play_error()
        elif success > 0:
            Sound.play_success()

    def _set_converting_ui(self, converting: bool):
        """设置转换中的 UI 状态"""
        self.convert_btn.setVisible(not converting)
        self.cancel_btn.setVisible(converting)
        self.add_btn.setEnabled(not converting)
        self.clear_btn.setEnabled(not converting)


def main():
    """应用入口"""
    app = QApplication(sys.argv)
    app.setApplicationName("PDF2PNG")
    app.setApplicationVersion("3.0.0")

    window = PDF2PNGMainWindow()
    window.show()

    sys.exit(app.exec())


if __name__ == '__main__':
    main()
