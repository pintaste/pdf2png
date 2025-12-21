#!/usr/bin/env python3
"""
空状态组件 - ENCRYPTO 风格设计

重构后：使用统一主题模块
"""
import sys
import os

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QFileDialog, QGraphicsDropShadowEffect
)
from PyQt6.QtCore import Qt, pyqtSignal, QPropertyAnimation, QEasingCurve, pyqtProperty
from PyQt6.QtGui import QFont, QColor, QPainter

from constants import WindowConfig, UIConfig
from gui_pyqt.theme import Theme
from gui_pyqt.i18n import I18n
from gui_pyqt.widgets.macos_controls import MacOSControlButtons


class YellowDropZone(QWidget):
    """黄色拖放区域 - 带微光悬停效果"""

    clicked = pyqtSignal()
    files_dropped = pyqtSignal(list)

    HEIGHT = 150

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setAcceptDrops(True)
        self._glow_opacity = 0.0
        self.setFixedHeight(self.HEIGHT)

        self._setup_animation()
        self._setup_ui()

    def _setup_animation(self):
        """设置微光动画"""
        self._animation = QPropertyAnimation(self, b"glow_opacity")
        self._animation.setDuration(WindowConfig.ANIMATION_DURATION)
        self._animation.setEasingCurve(QEasingCurve.Type.InOutCubic)

    def _setup_ui(self):
        """设置UI"""
        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.icon_label = QLabel("↓")
        self.icon_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self._arrow_font = QFont()
        self._arrow_font.setPointSize(48)
        self._arrow_font.setWeight(QFont.Weight.Light)
        self._plus_font = QFont()
        self._plus_font.setPointSize(72)
        self._plus_font.setWeight(QFont.Weight.Light)
        self.icon_label.setFont(self._arrow_font)
        self.icon_label.setStyleSheet("color: #000000;")
        layout.addWidget(self.icon_label)

    # 属性定义
    def get_glow_opacity(self):
        return self._glow_opacity

    def set_glow_opacity(self, value):
        self._glow_opacity = value
        self.update()

    glow_opacity = pyqtProperty(float, get_glow_opacity, set_glow_opacity)

    def paintEvent(self, event):
        """绘制黄色背景 + 微光效果"""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        painter.fillRect(self.rect(), QColor(Theme.colors.accent))

        if self._glow_opacity > 0:
            glow = QColor(255, 255, 255, int(30 * self._glow_opacity))
            painter.fillRect(self.rect(), glow)

    def enterEvent(self, event):
        """鼠标进入 - 启动微光 + 图标变加号"""
        self._animation.setStartValue(0.0)
        self._animation.setEndValue(1.0)
        self._animation.start()
        self.icon_label.setFont(self._plus_font)
        self.icon_label.setText("+")
        super().enterEvent(event)

    def leaveEvent(self, event):
        """鼠标离开 - 关闭微光 + 图标变箭头"""
        self._animation.setStartValue(self._glow_opacity)
        self._animation.setEndValue(0.0)
        self._animation.start()
        self.icon_label.setFont(self._arrow_font)
        self.icon_label.setText("↓")
        super().leaveEvent(event)

    def mousePressEvent(self, event):
        """点击触发文件选择"""
        if event.button() == Qt.MouseButton.LeftButton:
            self.clicked.emit()

    def dragEnterEvent(self, event):
        """拖入事件"""
        if event.mimeData().hasUrls():
            event.acceptProposedAction()

    def dropEvent(self, event):
        """拖放事件"""
        files = [
            url.toLocalFile()
            for url in event.mimeData().urls()
            if url.toLocalFile().lower().endswith('.pdf')
        ]
        if files:
            self.files_dropped.emit(files)


class EmptyStateWidget(QWidget):
    """
    ENCRYPTO 风格空状态组件

    三段式布局：
    - 顶部：macOS 三色圆点 + 标题 + 副标题
    - 中部：黄色拖放区域
    - 底部：提示文字
    """

    files_selected = pyqtSignal(list)

    BORDER_RADIUS = 12

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("empty_state")
        self._setup_ui()
        self._apply_style()
        self._apply_shadow()

    def _setup_ui(self):
        """初始化UI"""
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        layout.addWidget(self._create_top_section())
        layout.addWidget(self._create_drop_zone())
        layout.addWidget(self._create_bottom_section())

    def _create_top_section(self) -> QWidget:
        """创建顶部区域"""
        section = QWidget()
        section.setObjectName("top_section")

        layout = QVBoxLayout(section)
        layout.setContentsMargins(15, 10, 15, 20)
        layout.setSpacing(15)

        # 控制按钮（绿色最大化按钮禁用）
        controls = QHBoxLayout()
        self._control_buttons = MacOSControlButtons()
        self._control_buttons.close_clicked.connect(lambda: self.window().close())
        self._control_buttons.minimize_clicked.connect(lambda: self.window().showMinimized())
        controls.addWidget(self._control_buttons)
        controls.addStretch()
        layout.addLayout(controls)

        # 标题
        self._title_label = QLabel("P D F  →  P N G")
        self._title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        font = QFont()
        font.setPointSize(20)
        font.setWeight(QFont.Weight.Light)
        font.setLetterSpacing(QFont.SpacingType.AbsoluteSpacing, 4)
        self._title_label.setFont(font)
        self._title_label.setStyleSheet(f"color: {Theme.colors.text_primary};")
        layout.addWidget(self._title_label)

        # 副标题
        self._subtitle_label = QLabel(I18n.get('subtitle'))
        self._subtitle_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        font = QFont()
        font.setPointSize(11)
        font.setWeight(QFont.Weight.Light)
        self._subtitle_label.setFont(font)
        self._subtitle_label.setStyleSheet(f"color: {Theme.colors.text_primary};")
        layout.addWidget(self._subtitle_label)

        return section

    def _create_drop_zone(self) -> YellowDropZone:
        """创建拖放区域"""
        zone = YellowDropZone()
        zone.clicked.connect(self._browse_files)
        zone.files_dropped.connect(self.files_selected.emit)
        return zone

    def _create_bottom_section(self) -> QWidget:
        """创建底部区域"""
        section = QWidget()
        section.setObjectName("bottom_section")

        layout = QVBoxLayout(section)
        layout.setContentsMargins(15, 20, 15, 30)

        self._hint_label = QLabel(I18n.get('drop_hint'))
        self._hint_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        font = QFont()
        font.setPointSize(12)
        font.setWeight(QFont.Weight.Normal)
        self._hint_label.setFont(font)
        self._hint_label.setStyleSheet(f"color: {Theme.colors.text_primary};")
        layout.addWidget(self._hint_label)

        return section

    def _apply_style(self):
        """应用样式"""
        bg = Theme.colors.background_primary
        self.setStyleSheet(f"""
            #empty_state {{
                background-color: {bg};
                border-radius: {self.BORDER_RADIUS}px;
            }}
            #top_section {{
                background-color: {bg};
                border-top-left-radius: {self.BORDER_RADIUS}px;
                border-top-right-radius: {self.BORDER_RADIUS}px;
            }}
            #bottom_section {{
                background-color: {bg};
                border-bottom-left-radius: {self.BORDER_RADIUS}px;
                border-bottom-right-radius: {self.BORDER_RADIUS}px;
            }}
        """)

    def _apply_shadow(self):
        """应用阴影"""
        shadow = QGraphicsDropShadowEffect(self)
        shadow.setBlurRadius(30)
        shadow.setOffset(0, 10)
        shadow.setColor(QColor(0, 0, 0, 100))
        self.setGraphicsEffect(shadow)

    def _browse_files(self):
        """浏览文件"""
        files, _ = QFileDialog.getOpenFileNames(
            self,
            I18n.get('select_pdf'),
            "",
            I18n.get('pdf_filter')
        )
        if files:
            self.files_selected.emit(files)

    def update_texts(self):
        """更新所有文本（语言变化时调用）"""
        self._subtitle_label.setText(I18n.get('subtitle'))
        self._hint_label.setText(I18n.get('drop_hint'))

    def refresh_style(self):
        """刷新所有样式（主题变化时调用）"""
        self._apply_style()
        self._title_label.setStyleSheet(f"color: {Theme.colors.text_primary};")
        self._subtitle_label.setStyleSheet(f"color: {Theme.colors.text_primary};")
        self._hint_label.setStyleSheet(f"color: {Theme.colors.text_primary};")
