#!/usr/bin/env python3
"""
紧凑标题栏组件 - 工作状态顶部栏

重构后：使用统一主题模块
支持语言和主题切换
"""
import sys
import os

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from PyQt6.QtWidgets import QWidget, QHBoxLayout, QLabel, QPushButton
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QFont

from gui_pyqt.theme import Theme
from gui_pyqt.i18n import I18n
from gui_pyqt.widgets.macos_controls import MacOSControlButtons


class CompactTitleBar(QWidget):
    """
    工作状态顶部栏组件

    特性：
    - 左侧：macOS 控制按钮 + 标题
    - 右侧：语言切换 + 主题切换 + 高级选项按钮
    - 固定高度 50px
    """

    settings_toggle_requested = pyqtSignal()
    theme_changed = pyqtSignal(str)  # 'dark' or 'light'

    def __init__(self, parent=None):
        super().__init__(parent)
        self.settings_expanded = False
        self._drag_pos = None
        self._init_ui()

    def _init_ui(self):
        """初始化UI"""
        self.setFixedHeight(50)
        self.setObjectName("compact_title_bar")
        self.setAttribute(Qt.WidgetAttribute.WA_StyledBackground, True)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(16, 0, 12, 0)
        layout.setSpacing(6)  # 更紧凑的间距

        # macOS 控制按钮（关闭 + 最小化）
        self.control_buttons = MacOSControlButtons()
        self.control_buttons.close_clicked.connect(lambda: self.window().close())
        self.control_buttons.minimize_clicked.connect(lambda: self.window().showMinimized())
        layout.addWidget(self.control_buttons)

        # 标题（添加右边距防止与按钮重叠）
        self.title_label = QLabel(I18n.get('title'))
        title_font = QFont()
        title_font.setPointSize(14)
        title_font.setWeight(QFont.Weight.Bold)
        self.title_label.setFont(title_font)
        self.title_label.setContentsMargins(0, 0, 16, 0)  # 右边距
        self.title_label.setStyleSheet(f"color: {Theme.colors.text_primary};")
        layout.addWidget(self.title_label)

        # 弹性空间 - 将右侧按钮推到最右边
        layout.addStretch(1)

        # 主题切换按钮（紧凑尺寸）
        self.theme_btn = QPushButton(self._get_theme_icon())
        self.theme_btn.setFixedSize(26, 22)
        self.theme_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.theme_btn.setToolTip(I18n.get('toggle_theme'))
        self.theme_btn.clicked.connect(self._on_theme_toggle)
        layout.addWidget(self.theme_btn)

        # 设置按钮（齿轮图标，紧凑尺寸）
        self.settings_button = QPushButton(self._get_settings_icon())
        self.settings_button.setFixedSize(26, 22)
        self.settings_button.setCursor(Qt.CursorShape.PointingHandCursor)
        self.settings_button.setToolTip(I18n.get('advanced'))
        self.settings_button.clicked.connect(self._on_settings_toggle)
        layout.addWidget(self.settings_button)

        self._apply_style()

    def _get_theme_icon(self) -> str:
        """获取主题按钮图标 - 显示当前状态"""
        # 暗色模式显示月亮，亮色模式显示太阳
        return "🌙" if Theme.is_dark() else "☀️"

    def _get_settings_icon(self) -> str:
        """获取设置按钮图标"""
        return "⚙️"

    def mousePressEvent(self, event):
        """支持拖动窗口"""
        if event.button() == Qt.MouseButton.LeftButton:
            self._drag_pos = event.globalPosition().toPoint() - self.window().frameGeometry().topLeft()
            event.accept()

    def mouseMoveEvent(self, event):
        if event.buttons() == Qt.MouseButton.LeftButton and self._drag_pos:
            self.window().move(event.globalPosition().toPoint() - self._drag_pos)
            event.accept()

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self._drag_pos = None

    def _on_theme_toggle(self):
        """切换主题"""
        new_mode = Theme.toggle_mode()
        self.theme_btn.setText(self._get_theme_icon())
        self._apply_style()
        self.theme_changed.emit(new_mode)

    def _on_settings_toggle(self):
        """切换设置面板状态"""
        self.settings_expanded = not self.settings_expanded
        self.settings_toggle_requested.emit()

    def update_texts(self):
        """更新所有文本（语言变化时调用）"""
        self.title_label.setText(I18n.get('title'))
        self.theme_btn.setToolTip(I18n.get('toggle_theme'))
        self.settings_button.setToolTip(I18n.get('advanced'))

    def refresh_style(self):
        """刷新样式（主题变化时调用）"""
        self.theme_btn.setText(self._get_theme_icon())
        self.title_label.setStyleSheet(f"color: {Theme.colors.text_primary};")
        self._apply_style()

    def _apply_style(self):
        """应用样式"""
        c = Theme.colors
        self.setStyleSheet(f"""
            #compact_title_bar {{
                background: {c.background_primary};
                border-bottom: 1px solid {c.border_normal};
                border-top-left-radius: 12px;
                border-top-right-radius: 12px;
            }}
        """)

        # 图标按钮样式（主题、设置）- 紧凑尺寸
        icon_btn_style = f"""
            QPushButton {{
                background: transparent;
                border: 1px solid transparent;
                border-radius: 6px;
                color: {c.text_muted};
                font-size: 12px;
                padding: 2px 4px;
            }}
            QPushButton:hover {{
                background: {c.background_secondary};
                border-color: {c.border_normal};
                color: {c.text_primary};
            }}
            QPushButton:pressed {{
                background: {c.background_tertiary};
            }}
        """
        self.theme_btn.setStyleSheet(icon_btn_style)
        self.settings_button.setStyleSheet(icon_btn_style)
