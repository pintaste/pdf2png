#!/usr/bin/env python3
"""
高级设置对话框

功能：
- DPI 设置
- 文件大小限制
- 质量优先模式
"""

from typing import Dict
from pathlib import Path

from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QSlider, QCheckBox,
    QGroupBox, QRadioButton, QButtonGroup
)
from PyQt6.QtCore import Qt


class SettingsDialog(QDialog):
    """
    高级设置对话框

    允许用户自定义每个文件的转换参数
    """

    def __init__(self, file_path: str, current_params: Dict, parent=None):
        """
        初始化设置对话框

        Args:
            file_path: PDF文件路径
            current_params: 当前参数字典
            parent: 父窗口
        """
        super().__init__(parent)

        self.file_path = file_path
        self.file_name = Path(file_path).name
        self.params = current_params.copy()

        self._init_ui()
        self._load_params()

    def _init_ui(self):
        """初始化UI"""
        self.setWindowTitle(f"设置 - {self.file_name}")
        self.setMinimumWidth(500)
        self.setMinimumHeight(450)

        # 应用 ENCRYPTO 深棕色样式
        self._apply_style()

        layout = QVBoxLayout(self)
        layout.setSpacing(15)

        # 文件信息
        info_label = QLabel(f"📄 {self.file_name}")
        info_label.setStyleSheet("font-size: 14px; font-weight: bold; padding: 10px; color: #FFFFFF;")
        layout.addWidget(info_label)

        # 1. 转换模式
        mode_group = self._create_mode_group()
        layout.addWidget(mode_group)

        # 2. DPI设置
        dpi_group = self._create_dpi_group()
        layout.addWidget(dpi_group)

        # 3. 文件大小设置
        size_group = self._create_size_group()
        layout.addWidget(size_group)

        # 弹簧
        layout.addStretch()

        # 底部按钮
        button_layout = QHBoxLayout()
        button_layout.addStretch()

        cancel_btn = QPushButton("取消")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)

        self.apply_btn = QPushButton("应用")
        self.apply_btn.setDefault(True)
        self.apply_btn.clicked.connect(self._apply_settings)
        self.apply_btn.setStyleSheet("""
            QPushButton {
                background-color: #FFD34E;
                color: #000000;
                border: none;
                padding: 8px 20px;
                border-radius: 8px;
                font-weight: 600;
            }
            QPushButton:hover {
                background-color: #FFE082;
            }
            QPushButton:pressed {
                background-color: #FFC107;
            }
        """)
        button_layout.addWidget(self.apply_btn)

        layout.addLayout(button_layout)

    def _create_mode_group(self) -> QGroupBox:
        """创建转换模式组"""
        group = QGroupBox("转换模式")
        layout = QVBoxLayout(group)

        self.mode_group = QButtonGroup(self)

        # 快速模式
        self.quick_radio = QRadioButton("🚀 快速模式（5MB限制）")
        self.quick_radio.setToolTip("适合网页分享，快速转换")
        self.mode_group.addButton(self.quick_radio, 0)
        layout.addWidget(self.quick_radio)

        # 高质量模式
        self.quality_radio = QRadioButton("✨ 高质量模式（不限大小）")
        self.quality_radio.setToolTip("适合打印存档，追求最佳质量")
        self.mode_group.addButton(self.quality_radio, 1)
        layout.addWidget(self.quality_radio)

        # 自定义模式
        self.custom_radio = QRadioButton("🎛️ 自定义模式")
        self.custom_radio.setToolTip("完全控制DPI和文件大小")
        self.mode_group.addButton(self.custom_radio, 2)
        layout.addWidget(self.custom_radio)

        # 连接信号
        self.mode_group.buttonClicked.connect(self._on_mode_changed)

        return group

    def _create_dpi_group(self) -> QGroupBox:
        """创建DPI设置组"""
        group = QGroupBox("DPI设置（清晰度）")
        layout = QVBoxLayout(group)

        # DPI滑块
        slider_layout = QHBoxLayout()

        slider_layout.addWidget(QLabel("DPI:"))

        self.dpi_slider = QSlider(Qt.Orientation.Horizontal)
        self.dpi_slider.setMinimum(150)
        self.dpi_slider.setMaximum(1200)
        self.dpi_slider.setValue(300)
        self.dpi_slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.dpi_slider.setTickInterval(150)
        self.dpi_slider.valueChanged.connect(self._on_dpi_changed)
        slider_layout.addWidget(self.dpi_slider)

        self.dpi_label = QLabel("300")
        self.dpi_label.setMinimumWidth(50)
        self.dpi_label.setStyleSheet("font-weight: bold;")
        slider_layout.addWidget(self.dpi_label)

        layout.addLayout(slider_layout)

        # DPI说明
        hint = QLabel("💡 DPI越高，图像越清晰，但文件越大")
        hint.setStyleSheet("color: #c0b5b0; font-size: 12px; padding: 5px;")
        layout.addWidget(hint)

        return group

    def _create_size_group(self) -> QGroupBox:
        """创建文件大小设置组"""
        group = QGroupBox("文件大小限制")
        layout = QVBoxLayout(group)

        # 大小滑块
        slider_layout = QHBoxLayout()

        slider_layout.addWidget(QLabel("限制:"))

        self.size_slider = QSlider(Qt.Orientation.Horizontal)
        self.size_slider.setMinimum(1)
        self.size_slider.setMaximum(50)
        self.size_slider.setValue(5)
        self.size_slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.size_slider.setTickInterval(5)
        self.size_slider.valueChanged.connect(self._on_size_changed)
        slider_layout.addWidget(self.size_slider)

        self.size_label = QLabel("5 MB")
        self.size_label.setMinimumWidth(60)
        self.size_label.setStyleSheet("font-weight: bold;")
        slider_layout.addWidget(self.size_label)

        layout.addLayout(slider_layout)

        # 质量优先选项
        self.quality_first_check = QCheckBox("🎯 优先质量（忽略大小限制）")
        self.quality_first_check.setToolTip("勾选后将使用最高DPI，忽略文件大小限制")
        self.quality_first_check.stateChanged.connect(self._on_quality_first_changed)
        layout.addWidget(self.quality_first_check)

        return group

    def _load_params(self):
        """加载参数到UI"""
        # DPI
        dpi = self.params.get('dpi', 300)
        self.dpi_slider.setValue(dpi)

        # 文件大小
        max_size = self.params.get('max_size_mb', 5)
        self.size_slider.setValue(int(max_size))

        # 质量优先
        quality_first = self.params.get('quality_first', False)
        self.quality_first_check.setChecked(quality_first)

        # 模式
        if quality_first:
            self.quality_radio.setChecked(True)
        elif max_size == 5 and dpi == 300:
            self.quick_radio.setChecked(True)
        else:
            self.custom_radio.setChecked(True)

        self._on_mode_changed()

    def _on_mode_changed(self):
        """模式切换"""
        if self.quick_radio.isChecked():
            # 快速模式
            self.dpi_slider.setValue(300)
            self.size_slider.setValue(5)
            self.quality_first_check.setChecked(False)
            self._set_controls_enabled(False)

        elif self.quality_radio.isChecked():
            # 高质量模式
            self.dpi_slider.setValue(600)
            self.quality_first_check.setChecked(True)
            self._set_controls_enabled(False)

        else:
            # 自定义模式
            self._set_controls_enabled(True)

    def _set_controls_enabled(self, enabled: bool):
        """设置控件启用状态"""
        self.dpi_slider.setEnabled(enabled)
        self.size_slider.setEnabled(enabled)
        self.quality_first_check.setEnabled(enabled)

    def _on_dpi_changed(self, value: int):
        """DPI变化"""
        self.dpi_label.setText(str(value))

    def _on_size_changed(self, value: int):
        """大小变化"""
        self.size_label.setText(f"{value} MB")

    def _on_quality_first_changed(self, state: int):
        """质量优先变化"""
        if state == Qt.CheckState.Checked.value:
            self.size_slider.setEnabled(False)
        else:
            self.size_slider.setEnabled(True)

    def _apply_settings(self):
        """应用设置"""
        self.params['dpi'] = self.dpi_slider.value()
        self.params['max_size_mb'] = self.size_slider.value()
        self.params['quality_first'] = self.quality_first_check.isChecked()
        self.accept()

    def get_params(self) -> Dict:
        """获取参数"""
        return self.params

    def _apply_style(self):
        """应用 ENCRYPTO 深棕色样式"""
        self.setStyleSheet("""
            QDialog {
                background-color: #302723;
            }
            QGroupBox {
                font-weight: bold;
                color: #FFFFFF;
                border: 1px solid #5a4f4a;
                border-radius: 8px;
                margin-top: 12px;
                padding-top: 10px;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 5px;
            }
            QLabel {
                color: #e0d5d0;
            }
            QRadioButton {
                color: #e0d5d0;
            }
            QRadioButton::indicator {
                width: 14px;
                height: 14px;
            }
            QCheckBox {
                color: #e0d5d0;
            }
            QSlider::groove:horizontal {
                background-color: #252019;
                height: 6px;
                border-radius: 3px;
            }
            QSlider::handle:horizontal {
                background-color: #FFD34E;
                width: 14px;
                height: 14px;
                margin: -4px 0;
                border-radius: 7px;
            }
            QPushButton {
                background-color: #3d322e;
                border: 1px solid #5a4f4a;
                border-radius: 8px;
                padding: 8px 16px;
                color: #e0d5d0;
            }
            QPushButton:hover {
                background-color: #4a3f3a;
                border-color: #6a5f5a;
            }
        """)
