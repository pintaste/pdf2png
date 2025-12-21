#!/usr/bin/env python3
"""
macOS 风格控制按钮组件

统一的窗口控制按钮实现，遵循 DRY 原则
"""
from PyQt6.QtWidgets import QWidget
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QColor, QPainter


class MacOSControlButtons(QWidget):
    """
    macOS 风格双色圆点控制按钮（关闭 + 最小化）

    Signals:
        close_clicked: 点击关闭按钮时触发
        minimize_clicked: 点击最小化按钮时触发
    """

    close_clicked = pyqtSignal()
    minimize_clicked = pyqtSignal()

    # 按钮尺寸常量
    DOT_SIZE = 12
    DOT_SPACING = 8

    # macOS 标准颜色
    COLOR_CLOSE = "#FF5F57"     # 红色 - 关闭
    COLOR_MINIMIZE = "#FFBD2E"  # 黄色 - 最小化

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedSize(self.DOT_SIZE * 2 + self.DOT_SPACING, self.DOT_SIZE)

    def paintEvent(self, event):
        """绘制两个圆点按钮"""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        painter.setPen(Qt.PenStyle.NoPen)

        colors = [self.COLOR_CLOSE, self.COLOR_MINIMIZE]
        for i, color in enumerate(colors):
            painter.setBrush(QColor(color))
            x = i * (self.DOT_SIZE + self.DOT_SPACING)
            painter.drawEllipse(x, 0, self.DOT_SIZE, self.DOT_SIZE)

    def mousePressEvent(self, event):
        """处理点击事件"""
        x = event.position().x()
        if x < self.DOT_SIZE:
            self.close_clicked.emit()
        else:
            self.minimize_clicked.emit()
