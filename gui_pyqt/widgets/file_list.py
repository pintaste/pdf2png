#!/usr/bin/env python3
"""
文件列表组件

重构后：使用统一的主题模块，分离 UI 和状态管理
"""
import sys
import os
from pathlib import Path
from typing import List, Dict, Optional

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QMenu, QFrame, QMessageBox,
    QGraphicsDropShadowEffect, QScrollArea
)
from PyQt6.QtCore import Qt, pyqtSignal, QTimer, QRectF
from PyQt6.QtGui import QAction, QColor, QPainter, QPen

from constants import WindowConfig, UIConfig
from gui_pyqt.theme import Theme
from gui_pyqt.i18n import I18n

from .settings_dialog import SettingsDialog


class SpinnerWidget(QWidget):
    """旋转加载指示器"""

    def __init__(self, size: int = 16, parent=None):
        super().__init__(parent)
        self._size = size
        self._angle = 0
        self.setFixedSize(size, size)

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._rotate)

    def start(self):
        """开始旋转"""
        if not self._timer.isActive():
            self._timer.start(WindowConfig.SPINNER_INTERVAL)
            self.show()

    def stop(self):
        """停止旋转"""
        if self._timer.isActive():
            self._timer.stop()
        self.hide()

    def _rotate(self):
        self._angle = (self._angle + WindowConfig.SPINNER_ROTATION_SPEED) % 360
        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        margin = 2
        rect = QRectF(margin, margin, self._size - 2*margin, self._size - 2*margin)

        pen = QPen(QColor(Theme.spinner_color()), 2)
        pen.setCapStyle(Qt.PenCapStyle.RoundCap)
        painter.setPen(pen)

        start_angle = self._angle * 16
        span_angle = 270 * 16
        painter.drawArc(rect, start_angle, span_angle)


class FileItemWidget(QFrame):
    """
    单个文件项组件

    布局：
    ┌─────────────────────────────────────────┐
    │ 📄 document.pdf                    [×]  │
    │ ✓ 1.23 MB · 300 DPI · 2.5s              │
    └─────────────────────────────────────────┘
    """

    delete_requested = pyqtSignal(str)
    settings_requested = pyqtSignal(str)

    def __init__(self, file_path: str, parent=None):
        super().__init__(parent)

        self.file_path = file_path
        self.file_name = Path(file_path).name

        # 转换参数（默认质量优先模式）
        self.params = {
            'dpi': 300,
            'max_size_mb': 5,
            'quality_first': True
        }
        self._is_warning = False  # 记录警告状态（用于主题切换时刷新）

        self._init_ui()
        self._setup_shadow()
        self._apply_style()

    def _init_ui(self):
        """初始化UI"""
        self.setFrameShape(QFrame.Shape.StyledPanel)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(10, 8, 10, 8)
        layout.setSpacing(UIConfig.ITEM_SPACING)

        # 第一行：文件名 + 删除按钮
        top_row = QHBoxLayout()

        file_icon_label = QLabel("📄")
        file_icon_label.setFixedWidth(18)
        top_row.addWidget(file_icon_label)

        self.name_label = QLabel(self.file_name)
        self.name_label.setToolTip(self.file_path)
        self.name_label.setStyleSheet(Theme.file_item_name_style())
        top_row.addWidget(self.name_label, 1)

        # 旋转加载指示器
        self.spinner = SpinnerWidget(size=16)
        self.spinner.hide()
        top_row.addWidget(self.spinner)

        # 页面进度标签 (1/30)
        self.page_progress_label = QLabel("")
        self.page_progress_label.setStyleSheet(
            f"font-size: 11px; color: {Theme.colors.text_muted}; min-width: 40px;"
        )
        self.page_progress_label.hide()
        top_row.addWidget(self.page_progress_label)

        self.delete_btn = QPushButton("×")
        self.delete_btn.setFixedSize(20, 20)
        self.delete_btn.setStyleSheet(Theme.file_item_delete_btn_style())
        self.delete_btn.clicked.connect(lambda: self.delete_requested.emit(self.file_path))
        top_row.addWidget(self.delete_btn)

        layout.addLayout(top_row)

        # 结果标签
        self.result_label = QLabel("")
        self.result_label.setStyleSheet(Theme.file_item_result_style())
        self.result_label.hide()
        layout.addWidget(self.result_label)

    def update_params(self, params: dict):
        """更新转换参数"""
        self.params = params.copy()

    def is_completed(self) -> bool:
        """检查是否已完成转换"""
        return self.result_label.isVisible() and self.result_label.text().startswith("✓")

    def set_progress(self, value: int, status: str = ""):
        """设置进度 - 显示旋转指示器"""
        self.spinner.start()
        self.spinner.show()

    def set_page_progress(self, current: int, total: int):
        """设置页面进度 (1/30 格式)"""
        if total > 1:
            self.page_progress_label.setText(f"{current}/{total}")
            self.page_progress_label.show()
        else:
            self.page_progress_label.hide()

    def set_result(self, size_mb: float, max_page_size_mb: float, dpi_min: int, dpi_max: int, elapsed: float = 0, page_count: int = 1):
        """设置转换结果"""
        self.spinner.stop()
        self.page_progress_label.hide()

        limit = self.params.get('max_size_mb', 5)
        quality_first = self.params.get('quality_first', True)
        time_str = f" · {elapsed:.1f}s" if elapsed > 0 else ""

        # 使用最大单页大小判断是否超限
        is_warning = not quality_first and max_page_size_mb > limit
        self._is_warning = is_warning  # 保存状态用于主题刷新

        # 显示格式：多页显示总大小和页数，单页只显示大小
        if page_count > 1:
            size_text = f"{size_mb:.2f} MB ({page_count}{I18n.get('page_unit')})"
        else:
            size_text = f"{size_mb:.2f} MB"

        # DPI 显示：相同则显示单个值，不同则显示范围
        if dpi_min == dpi_max:
            dpi_text = f"{dpi_min} DPI"
        else:
            dpi_text = f"{dpi_min}-{dpi_max} DPI"

        if is_warning:
            self.result_label.setText(f"⚠ {size_text} · {dpi_text}{time_str}")
        else:
            self.result_label.setText(f"✓ {size_text} · {dpi_text}{time_str}")

        self.result_label.setStyleSheet(Theme.file_item_result_style(is_warning))
        self.result_label.show()

    def set_error(self, message: str):
        """设置错误状态"""
        self.spinner.stop()
        self.page_progress_label.hide()
        self._is_warning = True  # 错误状态视为警告
        self.result_label.setText(f"✗ {message}")
        self.result_label.setStyleSheet(Theme.file_item_result_style(is_warning=True))
        self.result_label.show()

    def refresh_result_style(self):
        """刷新结果标签样式（主题切换时调用）"""
        if self.result_label.isVisible():
            self.result_label.setStyleSheet(Theme.file_item_result_style(self._is_warning))

    def reset(self):
        """重置状态"""
        self.spinner.stop()
        self.page_progress_label.hide()
        self.page_progress_label.setText("")
        self.result_label.hide()
        self.result_label.setText("")

    def contextMenuEvent(self, event):
        """右键菜单"""
        menu = QMenu(self)

        settings_action = QAction(I18n.get('menu_settings'), self)
        settings_action.triggered.connect(lambda: self.settings_requested.emit(self.file_path))
        menu.addAction(settings_action)

        menu.addSeparator()

        delete_action = QAction(I18n.get('menu_delete'), self)
        delete_action.triggered.connect(lambda: self.delete_requested.emit(self.file_path))
        menu.addAction(delete_action)

        menu.exec(event.globalPos())

    def _setup_shadow(self):
        """设置阴影效果"""
        shadow_config = Theme.get_shadow_config(is_hover=False)
        self.shadow = QGraphicsDropShadowEffect(self)
        self.shadow.setBlurRadius(shadow_config['blur_radius'])
        self.shadow.setOffset(0, shadow_config['offset'])
        self.shadow.setColor(QColor(0, 0, 0, shadow_config['opacity']))
        self.setGraphicsEffect(self.shadow)

    def enterEvent(self, event):
        """鼠标进入 - 增强阴影效果"""
        shadow_config = Theme.get_shadow_config(is_hover=True)
        self.shadow.setBlurRadius(shadow_config['blur_radius'])
        self.shadow.setOffset(0, shadow_config['offset'])
        self.shadow.setColor(QColor(0, 0, 0, shadow_config['opacity']))
        super().enterEvent(event)

    def leaveEvent(self, event):
        """鼠标离开 - 恢复默认阴影"""
        shadow_config = Theme.get_shadow_config(is_hover=False)
        self.shadow.setBlurRadius(shadow_config['blur_radius'])
        self.shadow.setOffset(0, shadow_config['offset'])
        self.shadow.setColor(QColor(0, 0, 0, shadow_config['opacity']))
        super().leaveEvent(event)

    def _apply_style(self):
        """应用样式"""
        self.setStyleSheet(Theme.file_item_style())


class FileListWidget(QWidget):
    """
    文件列表组件

    管理多个文件项，支持添加、删除、设置
    """

    files_changed = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.file_items: Dict[str, FileItemWidget] = {}
        self._init_ui()

    def _init_ui(self):
        """初始化UI"""
        self.setObjectName("file_list_widget")

        layout = QVBoxLayout(self)
        layout.setContentsMargins(UIConfig.CONTENT_MARGIN, UIConfig.CONTENT_MARGIN,
                                  UIConfig.CONTENT_MARGIN, UIConfig.CONTENT_MARGIN)

        # 标题行
        title_row = QHBoxLayout()
        title_row.setContentsMargins(5, 0, 5, 0)

        self.title_label = QLabel(I18n.get('file_list'))
        self.title_label.setStyleSheet(
            f"font-size: {UIConfig.FONT_SIZE_TITLE}px; font-weight: 600; "
            f"color: {Theme.colors.text_primary};"
        )
        title_row.addWidget(self.title_label)

        title_row.addStretch()

        self.settings_summary = QLabel("DPI: 300")
        self.settings_summary.setStyleSheet(
            f"font-size: 12px; color: {Theme.colors.text_muted};"
        )
        title_row.addWidget(self.settings_summary)

        layout.addLayout(title_row)

        # 滚动区域
        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setFrameShape(QFrame.Shape.NoFrame)
        self.scroll_area.setObjectName("file_scroll_area")

        # 容器
        self.container = QWidget()
        self.container.setObjectName("file_container")
        self.container_layout = QVBoxLayout(self.container)
        self.container_layout.setContentsMargins(0, 0, 0, 0)
        self.container_layout.setSpacing(UIConfig.ITEM_SPACING)
        self.container_layout.addStretch()

        self.scroll_area.setWidget(self.container)
        layout.addWidget(self.scroll_area, 1)

        # 空状态提示
        self.empty_label = QLabel(I18n.get('drop_hint_list'))
        self.empty_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.empty_label.setStyleSheet(Theme.empty_state_style())
        self.container_layout.insertWidget(0, self.empty_label)

        # 应用样式
        self.setStyleSheet(Theme.file_list_style())

    def add_files(self, file_paths: List[str]):
        """添加文件（带验证）"""
        added_count = 0
        skipped_files = []

        for file_path in file_paths:
            # 验证：文件存在性
            if not os.path.exists(file_path):
                skipped_files.append((file_path, I18n.get('file_not_found')))
                continue

            # 验证：是PDF文件
            if not file_path.lower().endswith('.pdf'):
                skipped_files.append((file_path, I18n.get('not_pdf')))
                continue

            # 验证：可读性
            if not os.access(file_path, os.R_OK):
                skipped_files.append((file_path, I18n.get('no_read_permission')))
                continue

            # 避免重复
            if file_path in self.file_items:
                continue

            # 创建文件项
            item = FileItemWidget(file_path)
            item.delete_requested.connect(self._on_delete_file)
            item.settings_requested.connect(self._on_settings_file)

            # 添加到布局
            insert_index = self.container_layout.count() - 1
            self.container_layout.insertWidget(insert_index, item)

            self.file_items[file_path] = item
            added_count += 1

        if added_count > 0:
            self.empty_label.hide()
            self.files_changed.emit()

        # 报告跳过的文件
        if skipped_files:
            skipped_msg = "\n".join([f"• {Path(f).name}: {reason}" for f, reason in skipped_files])
            QMessageBox.warning(
                self,
                I18n.get('files_skipped'),
                f"{I18n.get('files_skipped_msg')}\n\n{skipped_msg}"
            )

    def remove_file(self, file_path: str):
        """删除文件"""
        if file_path in self.file_items:
            item = self.file_items.pop(file_path)
            item.deleteLater()

            if not self.file_items:
                self.empty_label.show()

            self.files_changed.emit()

    def clear(self):
        """清空列表"""
        for file_path in list(self.file_items.keys()):
            self.remove_file(file_path)

        self.empty_label.show()
        self.files_changed.emit()

    def get_files(self) -> List[str]:
        """获取所有文件路径"""
        return list(self.file_items.keys())

    def get_file_params(self, file_path: str) -> Optional[dict]:
        """获取文件的转换参数"""
        if file_path in self.file_items:
            return self.file_items[file_path].params.copy()
        return None

    def update_all_params(self, params: dict):
        """更新所有文件项的参数"""
        for item in self.file_items.values():
            item.update_params(params)

    def update_progress(self, file_path: str, progress: int, status: str = ""):
        """更新文件进度"""
        if file_path in self.file_items:
            self.file_items[file_path].set_progress(progress, status)

    def update_page_progress(self, file_path: str, current: int, total: int):
        """更新文件页面进度"""
        if file_path in self.file_items:
            self.file_items[file_path].set_page_progress(current, total)

    def update_result(self, file_path: str, size_mb: float, max_page_size_mb: float, dpi_min: int, dpi_max: int, elapsed: float = 0, page_count: int = 1):
        """更新文件转换结果"""
        if file_path in self.file_items:
            self.file_items[file_path].set_result(size_mb, max_page_size_mb, dpi_min, dpi_max, elapsed, page_count)

    def update_error(self, file_path: str, message: str):
        """更新文件错误状态"""
        if file_path in self.file_items:
            self.file_items[file_path].set_error(message)

    def reset_all(self):
        """重置所有文件状态"""
        for item in self.file_items.values():
            item.reset()

    def has_completed_files(self) -> bool:
        """检查是否有已完成的文件"""
        return any(item.is_completed() for item in self.file_items.values())

    def get_completed_count(self) -> int:
        """获取已完成文件数量"""
        return sum(1 for item in self.file_items.values() if item.is_completed())

    def update_settings_summary(self, text: str):
        """更新设置摘要显示"""
        self.settings_summary.setText(text)

    # ========================================================================
    # 内部事件处理
    # ========================================================================

    def _on_delete_file(self, file_path: str):
        """删除文件回调"""
        self.remove_file(file_path)

    def _on_settings_file(self, file_path: str):
        """设置文件回调"""
        if file_path not in self.file_items:
            return

        file_item = self.file_items[file_path]

        dialog = SettingsDialog(file_path, file_item.params, self)
        if dialog.exec():
            new_params = dialog.get_params()
            file_item.update_params(new_params)

    def update_texts(self):
        """更新所有文本（语言变化时调用）"""
        self.title_label.setText(I18n.get('file_list'))
        self.empty_label.setText(I18n.get('drop_hint_list'))

    def refresh_style(self):
        """刷新所有样式（主题变化时调用）"""
        self.setStyleSheet(Theme.file_list_style())
        self.title_label.setStyleSheet(
            f"font-size: {UIConfig.FONT_SIZE_TITLE}px; font-weight: 600; "
            f"color: {Theme.colors.text_primary};"
        )
        self.settings_summary.setStyleSheet(
            f"font-size: 12px; color: {Theme.colors.text_muted};"
        )
        self.empty_label.setStyleSheet(Theme.empty_state_style())
        # 刷新所有文件项样式
        for item in self.file_items.values():
            item._apply_style()
            item.name_label.setStyleSheet(Theme.file_item_name_style())
            item.delete_btn.setStyleSheet(Theme.file_item_delete_btn_style())
            item.page_progress_label.setStyleSheet(
                f"font-size: 11px; color: {Theme.colors.text_muted}; min-width: 40px;"
            )
            item.refresh_result_style()  # 刷新结果标签颜色
