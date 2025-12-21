#!/usr/bin/env python3
"""
可折叠设置面板组件

重构后：使用统一的常量和主题模块
"""
import sys
import os

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QSlider, QRadioButton, QButtonGroup, QFrame, QLineEdit
)
from PyQt6.QtCore import Qt, pyqtSignal, QPropertyAnimation, QEasingCurve
from PyQt6.QtGui import QIntValidator

from constants import DPIConfig, SizeConfig, WindowConfig
from gui_pyqt.theme import Theme
from gui_pyqt.i18n import I18n


class CollapsibleSettingsPanel(QWidget):
    """
    可折叠设置面板

    特性：
    - 优化模式单选框（质量优先/大小优先）
    - DPI 滑块（质量优先模式）
    - 大小限制滑块（大小优先模式）
    - 展开/收起动画
    """

    # 信号
    priority_changed = pyqtSignal(str)  # 'quality' or 'size'
    dpi_changed = pyqtSignal(int)       # DPI 值
    size_changed = pyqtSignal(int)      # 大小限制值
    language_changed = pyqtSignal(str)  # 'zh' or 'en'

    def __init__(self, parent=None):
        super().__init__(parent)
        self._expanded = False
        self._init_ui()
        self._setup_animations()

    def _init_ui(self):
        """初始化UI"""
        self.setObjectName("collapsible_settings")

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(15, 10, 15, 10)
        main_layout.setSpacing(15)

        # 语言选择（最上面）
        main_layout.addLayout(self._create_language_selector())

        # 分隔线
        separator1 = QFrame()
        separator1.setFrameShape(QFrame.Shape.HLine)
        separator1.setStyleSheet(Theme.separator_style())
        separator1.setFixedHeight(1)
        main_layout.addWidget(separator1)

        # 模式选择区域
        main_layout.addLayout(self._create_mode_selector())

        # 分隔线
        separator2 = QFrame()
        separator2.setFrameShape(QFrame.Shape.HLine)
        separator2.setStyleSheet(Theme.separator_style())
        separator2.setFixedHeight(1)
        main_layout.addWidget(separator2)

        # 质量优先模式控件组
        self.dpi_container = self._create_dpi_controls()
        main_layout.addWidget(self.dpi_container)

        # 大小优先模式控件组
        self.size_container = self._create_size_controls()
        main_layout.addWidget(self.size_container)

        # 初始状态：显示质量优先，隐藏大小优先
        self.dpi_container.show()
        self.size_container.hide()

        # 应用样式
        self.setStyleSheet(Theme.collapsible_settings_style())

        # 初始设置为折叠状态
        self.setMaximumHeight(0)
        self.hide()

    def _create_mode_selector(self) -> QHBoxLayout:
        """创建模式选择器"""
        layout = QHBoxLayout()
        layout.setSpacing(8)

        self._mode_label = QLabel(I18n.get('mode'))
        self._mode_label.setStyleSheet("font-size: 13px; font-weight: 500;")
        layout.addWidget(self._mode_label)

        # 创建单选框组
        self.priority_group = QButtonGroup()

        self.quality_radio = QRadioButton(I18n.get('clarity'))
        self.quality_radio.setStyleSheet("font-size: 13px;")
        self.quality_radio.setMinimumWidth(80)
        self.quality_radio.setChecked(True)
        self.priority_group.addButton(self.quality_radio, 0)
        layout.addWidget(self.quality_radio)

        self.size_radio = QRadioButton(I18n.get('file_size'))
        self.size_radio.setStyleSheet("font-size: 13px;")
        self.size_radio.setMinimumWidth(80)
        self.priority_group.addButton(self.size_radio, 1)
        layout.addWidget(self.size_radio)

        layout.addStretch()

        # 连接信号
        self.priority_group.buttonClicked.connect(self._on_priority_clicked)

        return layout

    def _create_dpi_controls(self) -> QWidget:
        """创建 DPI 控件组"""
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(4)

        # DPI 标题 + 描述（同一行）
        title_layout = QHBoxLayout()
        self._dpi_title_label = QLabel(I18n.get('clarity_dpi'))
        self._dpi_title_label.setStyleSheet("font-size: 13px; font-weight: 600;")
        title_layout.addWidget(self._dpi_title_label)

        # 获取初始描述（只要描述部分，不要 DPI 数值）
        initial_desc = DPIConfig.PRESETS[DPIConfig.value_to_position(DPIConfig.DEFAULT_DPI)].description
        self.dpi_desc_label = QLabel(f"- {initial_desc}")
        self.dpi_desc_label.setStyleSheet(
            f"font-size: 12px; color: {Theme.colors.text_muted};"
        )
        title_layout.addWidget(self.dpi_desc_label)
        title_layout.addStretch()
        layout.addLayout(title_layout)

        # DPI 滑块 + 自定义输入
        slider_layout = QHBoxLayout()
        slider_layout.setSpacing(12)

        # 滑块容器（滑块 + 刻度标签）
        slider_container = QWidget()
        slider_container_layout = QVBoxLayout(slider_container)
        slider_container_layout.setContentsMargins(0, 0, 0, 0)
        slider_container_layout.setSpacing(2)

        self.dpi_slider = QSlider(Qt.Orientation.Horizontal)
        self.dpi_slider.setMinimum(0)
        self.dpi_slider.setMaximum(len(DPIConfig.PRESETS) - 1)
        self.dpi_slider.setSingleStep(1)
        self.dpi_slider.setPageStep(1)
        self.dpi_slider.setValue(DPIConfig.value_to_position(DPIConfig.DEFAULT_DPI))
        self.dpi_slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.dpi_slider.setTickInterval(1)
        self.dpi_slider.valueChanged.connect(self._on_dpi_changed)
        slider_container_layout.addWidget(self.dpi_slider)

        # 刻度标签行
        tick_labels_layout = QHBoxLayout()
        tick_labels_layout.setContentsMargins(0, 0, 0, 0)
        tick_labels_layout.setSpacing(0)
        for i, preset in enumerate(DPIConfig.PRESETS):
            label = QLabel(str(preset.value))
            label.setStyleSheet(f"font-size: 9px; color: {Theme.colors.text_muted};")
            if i == 0:
                label.setAlignment(Qt.AlignmentFlag.AlignLeft)
            elif i == len(DPIConfig.PRESETS) - 1:
                label.setAlignment(Qt.AlignmentFlag.AlignRight)
            else:
                label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            tick_labels_layout.addWidget(label, 1)
        slider_container_layout.addLayout(tick_labels_layout)

        slider_layout.addWidget(slider_container, 1)

        # DPI 输入框
        self.dpi_input = QLineEdit(str(DPIConfig.DEFAULT_DPI))
        self.dpi_input.setValidator(
            QIntValidator(DPIConfig.MIN_DPI, DPIConfig.MAX_DPI)
        )
        self.dpi_input.setFixedSize(50, 28)  # 固定尺寸，与文件大小输入框一致
        self.dpi_input.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.dpi_input.editingFinished.connect(self._on_dpi_input_changed)
        slider_layout.addWidget(self.dpi_input)

        self._dpi_unit_label = QLabel("DPI")
        self._dpi_unit_label.setStyleSheet(f"font-size: 13px; color: {Theme.colors.text_muted};")
        slider_layout.addWidget(self._dpi_unit_label)

        layout.addLayout(slider_layout)

        return container

    def _create_size_controls(self) -> QWidget:
        """创建文件大小控件组"""
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(4)

        # 大小限制标题
        title_layout = QHBoxLayout()
        self._size_title_label = QLabel(I18n.get('file_size_limit'))
        self._size_title_label.setStyleSheet("font-size: 13px; font-weight: 600;")
        title_layout.addWidget(self._size_title_label)
        title_layout.addStretch()
        layout.addLayout(title_layout)

        # 大小限制滑块 + 自定义输入
        slider_layout = QHBoxLayout()
        slider_layout.setSpacing(12)

        # 滑块容器（滑块 + 刻度标签）
        slider_container = QWidget()
        slider_container_layout = QVBoxLayout(slider_container)
        slider_container_layout.setContentsMargins(0, 0, 0, 0)
        slider_container_layout.setSpacing(2)

        self.size_slider = QSlider(Qt.Orientation.Horizontal)
        self.size_slider.setMinimum(0)
        self.size_slider.setMaximum(len(SizeConfig.PRESETS) - 1)
        self.size_slider.setSingleStep(1)
        self.size_slider.setPageStep(1)
        default_position = SizeConfig.value_to_position(SizeConfig.DEFAULT_SIZE_MB)
        self.size_slider.setValue(default_position if default_position >= 0 else 3)
        self.size_slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.size_slider.setTickInterval(1)
        self.size_slider.valueChanged.connect(self._on_size_slider_changed)
        slider_container_layout.addWidget(self.size_slider)

        # 刻度标签行
        tick_labels_layout = QHBoxLayout()
        tick_labels_layout.setContentsMargins(0, 0, 0, 0)
        tick_labels_layout.setSpacing(0)
        for i, preset in enumerate(SizeConfig.PRESETS):
            label = QLabel(str(preset.value))
            label.setStyleSheet(f"font-size: 9px; color: {Theme.colors.text_muted};")
            if i == 0:
                label.setAlignment(Qt.AlignmentFlag.AlignLeft)
            elif i == len(SizeConfig.PRESETS) - 1:
                label.setAlignment(Qt.AlignmentFlag.AlignRight)
            else:
                label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            tick_labels_layout.addWidget(label, 1)
        slider_container_layout.addLayout(tick_labels_layout)

        slider_layout.addWidget(slider_container, 1)

        self.size_input = QLineEdit(str(SizeConfig.DEFAULT_SIZE_MB))
        self.size_input.setValidator(
            QIntValidator(SizeConfig.MIN_SIZE_MB, SizeConfig.MAX_SIZE_MB)
        )
        self.size_input.setFixedSize(50, 28)  # 固定尺寸
        self.size_input.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.size_input.editingFinished.connect(self._on_size_input_changed)
        slider_layout.addWidget(self.size_input)

        self._mb_unit_label = QLabel("MB")
        self._mb_unit_label.setStyleSheet(f"font-size: 13px; color: {Theme.colors.text_muted};")
        slider_layout.addWidget(self._mb_unit_label)

        layout.addLayout(slider_layout)
        return container

    def _create_language_selector(self) -> QHBoxLayout:
        """创建语言选择器"""
        layout = QHBoxLayout()
        layout.setSpacing(8)

        self._lang_label = QLabel(I18n.get('language'))
        self._lang_label.setStyleSheet("font-size: 13px; font-weight: 500;")
        layout.addWidget(self._lang_label)

        # 语言单选框组
        self.lang_group = QButtonGroup()

        self.zh_radio = QRadioButton("中文")
        self.zh_radio.setStyleSheet("font-size: 13px;")
        self.zh_radio.setChecked(I18n.get_language() == 'zh')
        self.lang_group.addButton(self.zh_radio, 0)
        layout.addWidget(self.zh_radio)

        self.en_radio = QRadioButton("English")
        self.en_radio.setStyleSheet("font-size: 13px;")
        self.en_radio.setChecked(I18n.get_language() == 'en')
        self.lang_group.addButton(self.en_radio, 1)
        layout.addWidget(self.en_radio)

        layout.addStretch()

        # 连接信号
        self.lang_group.buttonClicked.connect(self._on_language_clicked)

        return layout

    def _on_language_clicked(self, button):
        """语言选择变化"""
        new_lang = 'zh' if self.lang_group.id(button) == 0 else 'en'
        if new_lang != I18n.get_language():
            I18n.set_language(new_lang)
            self.language_changed.emit(new_lang)

    def _setup_animations(self):
        """设置动画"""
        self.height_animation = QPropertyAnimation(self, b"maximumHeight")
        self.height_animation.setDuration(WindowConfig.ANIMATION_DURATION)
        self.height_animation.setEasingCurve(QEasingCurve.Type.InOutCubic)

    # ========================================================================
    # 事件处理
    # ========================================================================

    def _on_priority_clicked(self, button):
        """优化模式变化"""
        is_quality_mode = (self.priority_group.id(button) == 0)

        self.dpi_container.setVisible(is_quality_mode)
        self.size_container.setVisible(not is_quality_mode)

        priority_mode = 'quality' if is_quality_mode else 'size'
        self.priority_changed.emit(priority_mode)

    def _on_dpi_changed(self, position: int):
        """DPI 档位变化"""
        dpi_value = DPIConfig.position_to_value(position)
        self.dpi_desc_label.setText(DPIConfig.get_description(position))

        # 同步到输入框
        self.dpi_input.blockSignals(True)
        self.dpi_input.setText(str(dpi_value))
        self.dpi_input.blockSignals(False)

        self.dpi_changed.emit(dpi_value)

    def _on_dpi_input_changed(self):
        """自定义 DPI 输入变化"""
        text = self.dpi_input.text().strip()
        if not text:
            return

        try:
            dpi = int(text)
            # 限制在有效范围内
            dpi = max(DPIConfig.MIN_DPI, min(DPIConfig.MAX_DPI, dpi))
        except ValueError:
            return

        # 更新输入框显示（可能被限制）
        self.dpi_input.setText(str(dpi))

        # 尝试匹配滑块档位
        position = DPIConfig.value_to_position(dpi)
        self.dpi_slider.blockSignals(True)
        self.dpi_slider.setValue(position)
        self.dpi_slider.blockSignals(False)

        # 更新描述（显示自定义 DPI）
        if position == DPIConfig.value_to_position(dpi):
            self.dpi_desc_label.setText(DPIConfig.get_description(position))
        else:
            self.dpi_desc_label.setText(f"{dpi} DPI - {I18n.get('dpi_custom')}")

        self.dpi_changed.emit(dpi)

    def _on_size_slider_changed(self, position: int):
        """文件大小限制档位变化"""
        size_mb = SizeConfig.position_to_value(position)

        # 同步到输入框
        self.size_input.blockSignals(True)
        self.size_input.setText(str(size_mb))
        self.size_input.blockSignals(False)

        self.size_changed.emit(size_mb)

    def _on_size_input_changed(self):
        """自定义大小输入变化"""
        text = self.size_input.text().strip()
        if not text:
            return

        try:
            size_mb = SizeConfig.clamp(int(text))
        except ValueError:
            return

        # 尝试匹配滑块档位
        position = SizeConfig.value_to_position(size_mb)
        if position >= 0:
            self.size_slider.blockSignals(True)
            self.size_slider.setValue(position)
            self.size_slider.blockSignals(False)

        self.size_changed.emit(size_mb)

    # ========================================================================
    # 公共接口
    # ========================================================================

    def toggle(self):
        """切换展开/收起状态"""
        if self._expanded:
            self.collapse()
        else:
            self.expand()

    def expand(self):
        """展开"""
        if self._expanded:
            return

        self._expanded = True
        self.show()

        self.setMaximumHeight(16777215)
        target_height = self.sizeHint().height()

        self.height_animation.setStartValue(0)
        self.height_animation.setEndValue(target_height)
        self.height_animation.start()

    def collapse(self):
        """收起"""
        if not self._expanded:
            return

        self._expanded = False
        current_height = self.height()

        self.height_animation.setStartValue(current_height)
        self.height_animation.setEndValue(0)
        self.height_animation.finished.connect(self._on_collapse_finished)
        self.height_animation.start()

    def _on_collapse_finished(self):
        """收起动画完成"""
        self.hide()
        self.height_animation.finished.disconnect(self._on_collapse_finished)

    def is_expanded(self) -> bool:
        """是否已展开"""
        return self._expanded

    def set_priority_mode(self, mode: str):
        """设置优化模式"""
        is_quality = (mode == 'quality')
        self.quality_radio.setChecked(is_quality)
        self.size_radio.setChecked(not is_quality)
        self.dpi_container.setVisible(is_quality)
        self.size_container.setVisible(not is_quality)

    def set_dpi(self, dpi: int):
        """设置 DPI 值"""
        position = DPIConfig.value_to_position(dpi)
        self.dpi_slider.setValue(position)
        self.dpi_input.setText(str(dpi))

    def set_size_limit(self, size_mb: int):
        """设置大小限制值"""
        self.size_input.setText(str(size_mb))
        position = SizeConfig.value_to_position(size_mb)
        if position >= 0:
            self.size_slider.setValue(position)

    def get_current_params(self) -> dict:
        """获取当前参数"""
        if self.quality_radio.isChecked():
            # 从输入框获取 DPI（支持自定义值）
            try:
                dpi_value = int(self.dpi_input.text())
                dpi_value = max(DPIConfig.MIN_DPI, min(DPIConfig.MAX_DPI, dpi_value))
            except ValueError:
                dpi_value = DPIConfig.DEFAULT_DPI
            return {
                'quality_first': True,
                'dpi': dpi_value
            }
        else:
            try:
                size_mb = int(self.size_input.text())
            except ValueError:
                size_mb = SizeConfig.DEFAULT_SIZE_MB
            return {
                'quality_first': False,
                'max_size_mb': size_mb
            }

    def update_texts(self):
        """更新所有文本（语言变化时调用）"""
        self._mode_label.setText(I18n.get('mode'))
        self.quality_radio.setText(I18n.get('clarity'))
        self.size_radio.setText(I18n.get('file_size'))
        self._dpi_title_label.setText(I18n.get('clarity_dpi'))
        self._size_title_label.setText(I18n.get('file_size_limit'))
        self._lang_label.setText(I18n.get('language'))
        # 刷新 DPI 描述（国际化文本）
        position = self.dpi_slider.value()
        self.dpi_desc_label.setText(DPIConfig.get_description(position))

    def refresh_style(self):
        """刷新所有样式（主题变化时调用）"""
        self.setStyleSheet(Theme.collapsible_settings_style())
        self.dpi_desc_label.setStyleSheet(
            f"font-size: 12px; color: {Theme.colors.text_muted};"
        )
        self._dpi_unit_label.setStyleSheet(
            f"font-size: 13px; color: {Theme.colors.text_muted};"
        )
        self._mb_unit_label.setStyleSheet(
            f"font-size: 13px; color: {Theme.colors.text_muted};"
        )
