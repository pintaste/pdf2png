#!/usr/bin/env python3
"""
统一主题管理模块

集中管理所有 UI 样式，消除重复代码
遵循 Clean Code 原则：DRY（Don't Repeat Yourself）

支持 Dark 和 Light 主题切换
"""
from dataclasses import dataclass
from typing import Dict, List, Callable


@dataclass(frozen=True)
class DarkPalette:
    """暗色主题调色板 - ENCRYPTO 深棕色系"""

    # 主色调
    background_primary: str = "#302723"      # 主背景
    background_secondary: str = "#3d322e"    # 次级背景（卡片等）
    background_tertiary: str = "#4a3f3a"     # 三级背景（hover）
    background_input: str = "#252019"        # 输入框背景

    # 边框
    border_normal: str = "#5a4f4a"
    border_hover: str = "#6a5f5a"
    border_focus: str = "#FFD34E"
    separator: str = "#5a4f4a"              # 分隔线

    # 文字
    text_primary: str = "#FFFFFF"
    text_secondary: str = "#e0d5d0"
    text_result: str = "#F8F8F8"            # 结果文字（珍珠白）
    text_muted: str = "#c0b5b0"
    text_disabled: str = "#8a7f7a"

    # 强调色
    accent: str = "#FFD34E"                  # 主强调色（黄色）
    accent_hover: str = "#FFE082"
    accent_pressed: str = "#FFC107"

    # 状态色
    success: str = "#4ade80"
    warning: str = "#FFA500"
    error: str = "#ef4444"

    # 阴影
    shadow_color: str = "rgba(0, 0, 0, 0.4)"
    shadow_color_hover: str = "rgba(0, 0, 0, 0.8)"


@dataclass(frozen=True)
class LightPalette:
    """亮色主题调色板"""

    # 主色调
    background_primary: str = "#F5F5F5"      # 主背景
    background_secondary: str = "#FFFFFF"    # 次级背景（卡片等）
    background_tertiary: str = "#EBEBEB"     # 三级背景（hover）
    background_input: str = "#FFFFFF"        # 输入框背景

    # 边框
    border_normal: str = "#D0D0D0"
    border_hover: str = "#B0B0B0"
    border_focus: str = "#E6A800"
    separator: str = "#909090"              # 分隔线（深灰）

    # 文字
    text_primary: str = "#1A1A1A"
    text_secondary: str = "#4A4A4A"
    text_result: str = "#2A2A2A"            # 结果文字（深灰）
    text_muted: str = "#7A7A7A"
    text_disabled: str = "#A0A0A0"

    # 强调色
    accent: str = "#F5C400"                  # 主强调色（黄色，稍暗）
    accent_hover: str = "#FFD700"
    accent_pressed: str = "#E6A800"

    # 状态色
    success: str = "#22c55e"
    warning: str = "#F59E0B"
    error: str = "#dc2626"

    # 阴影
    shadow_color: str = "rgba(0, 0, 0, 0.15)"
    shadow_color_hover: str = "rgba(0, 0, 0, 0.25)"


class Theme:
    """
    主题管理器

    提供统一的样式表生成方法
    支持 Dark/Light 主题切换
    """

    _mode = 'dark'  # 默认暗色
    _listeners: List[Callable[[], None]] = []

    # 调色板实例
    _dark = DarkPalette()
    _light = LightPalette()

    # 当前颜色（动态属性）
    colors = _dark  # 初始化为暗色

    @classmethod
    def _update_colors(cls):
        """更新 colors 属性"""
        cls.colors = cls._dark if cls._mode == 'dark' else cls._light

    @classmethod
    def get_mode(cls) -> str:
        """获取当前主题模式"""
        return cls._mode

    @classmethod
    def set_mode(cls, mode: str) -> None:
        """
        设置主题模式

        Args:
            mode: 'dark' 或 'light'
        """
        if mode in ('dark', 'light') and mode != cls._mode:
            cls._mode = mode
            cls._update_colors()
            cls._notify_listeners()

    @classmethod
    def toggle_mode(cls) -> str:
        """切换主题模式，返回新模式"""
        new_mode = 'light' if cls._mode == 'dark' else 'dark'
        cls.set_mode(new_mode)
        return new_mode

    @classmethod
    def is_dark(cls) -> bool:
        """是否为暗色主题"""
        return cls._mode == 'dark'

    @classmethod
    def add_listener(cls, callback: Callable[[], None]) -> None:
        """添加主题变化监听器"""
        if callback not in cls._listeners:
            cls._listeners.append(callback)

    @classmethod
    def remove_listener(cls, callback: Callable[[], None]) -> None:
        """移除主题变化监听器"""
        if callback in cls._listeners:
            cls._listeners.remove(callback)

    @classmethod
    def _notify_listeners(cls) -> None:
        """通知所有监听器"""
        for callback in cls._listeners:
            try:
                callback()
            except Exception:
                pass

    # ========================================================================
    # 组件样式生成器
    # ========================================================================

    @classmethod
    def main_window_style(cls) -> str:
        """主窗口样式"""
        return "QMainWindow { background: transparent; }"

    @classmethod
    def working_state_style(cls) -> str:
        """工作状态容器样式"""
        c = cls.colors
        return f"""
            #working_state {{
                background-color: {c.background_primary};
                border-radius: 12px;
            }}
            #bottom_bar {{
                background-color: {c.background_primary};
                border-top: 1px solid {c.border_normal};
                border-bottom-left-radius: 12px;
                border-bottom-right-radius: 12px;
            }}
            #bottom_bar QPushButton {{
                background: transparent;
                border: 1px solid {c.border_normal};
                border-radius: 8px;
                padding: 0 16px;
                font-size: 14px;
                color: {c.text_secondary};
            }}
            #bottom_bar QPushButton:hover {{
                background: {c.background_secondary};
                border-color: {c.border_hover};
            }}
            #bottom_bar QPushButton:pressed {{
                background: {c.background_input};
            }}
            #convert_btn {{
                background-color: {c.accent};
                border: none;
                color: #000000;
                font-weight: 600;
            }}
            #convert_btn:hover {{
                background-color: {c.accent_hover};
            }}
            #convert_btn:pressed {{
                background-color: {c.accent_pressed};
            }}
        """

    @classmethod
    def file_list_style(cls) -> str:
        """文件列表容器样式"""
        c = cls.colors
        return f"""
            #file_list_widget {{
                background-color: {c.background_primary};
            }}
            #file_scroll_area {{
                background-color: {c.background_primary};
                border: none;
            }}
            #file_container {{
                background-color: {c.background_primary};
            }}
            QScrollBar:vertical {{
                background-color: {c.background_primary};
                width: 8px;
                border-radius: 4px;
            }}
            QScrollBar::handle:vertical {{
                background-color: {c.border_normal};
                border-radius: 4px;
                min-height: 20px;
            }}
            QScrollBar::handle:vertical:hover {{
                background-color: {c.border_hover};
            }}
            QScrollBar::add-line:vertical,
            QScrollBar::sub-line:vertical {{
                height: 0;
            }}
            QScrollBar:horizontal {{
                background-color: {c.background_primary};
                height: 8px;
                border-radius: 4px;
            }}
            QScrollBar::handle:horizontal {{
                background-color: {c.border_normal};
                border-radius: 4px;
                min-width: 20px;
            }}
            QScrollBar::handle:horizontal:hover {{
                background-color: {c.border_hover};
            }}
            QScrollBar::add-line:horizontal,
            QScrollBar::sub-line:horizontal {{
                width: 0;
            }}
        """

    @classmethod
    def file_item_style(cls) -> str:
        """单个文件项样式"""
        c = cls.colors
        return f"""
            FileItemWidget {{
                background-color: {c.background_secondary};
                border: 1px solid {c.border_normal};
                border-radius: 8px;
                padding: 6px;
                margin: 2px;
            }}
            FileItemWidget:hover {{
                border-color: {c.border_hover};
                background-color: {c.background_tertiary};
            }}
        """

    @classmethod
    def file_item_name_style(cls) -> str:
        """文件名标签样式"""
        c = cls.colors
        return f"font-weight: 600; font-size: 13px; color: {c.text_primary};"

    @classmethod
    def file_item_delete_btn_style(cls) -> str:
        """删除按钮样式"""
        c = cls.colors
        return f"""
            QPushButton {{
                border: none;
                background-color: transparent;
                color: {c.text_disabled};
                font-size: 14px;
                font-weight: bold;
                border-radius: 4px;
            }}
            QPushButton:hover {{
                color: {c.error};
                background-color: {c.background_tertiary};
            }}
        """

    @classmethod
    def file_item_result_style(cls, is_warning: bool = False) -> str:
        """结果标签样式"""
        c = cls.colors
        color = c.warning if is_warning else c.text_result
        return f"color: {color}; font-size: 11px;"

    @classmethod
    def collapsible_settings_style(cls) -> str:
        """可折叠设置面板样式"""
        c = cls.colors
        return f"""
            #collapsible_settings {{
                background: {c.background_secondary};
                border: 1px solid {c.border_normal};
                border-radius: 8px;
            }}
            QLabel {{
                color: {c.text_primary};
            }}
            QRadioButton {{
                color: {c.text_secondary};
            }}
            QSlider::groove:horizontal {{
                background: {c.background_input};
                height: 6px;
                border-radius: 3px;
            }}
            QSlider::handle:horizontal {{
                background: {c.accent};
                width: 16px;
                margin: -5px 0;
                border-radius: 8px;
            }}
            QSlider::sub-page:horizontal {{
                background: {c.accent};
                border-radius: 3px;
            }}
            QLineEdit {{
                background: {c.background_input};
                border: 1px solid {c.border_normal};
                border-radius: 4px;
                padding: 4px 6px;
                color: {c.text_primary};
                font-size: 13px;
            }}
            QLineEdit:focus {{
                border-color: {c.accent};
            }}
        """

    @classmethod
    def empty_state_style(cls) -> str:
        """空状态提示样式"""
        c = cls.colors
        return f"""
            QLabel {{
                color: {c.text_muted};
                font-size: 14px;
                padding: 60px;
                border: 2px dashed {c.border_normal};
                border-radius: 8px;
            }}
        """

    @classmethod
    def empty_state_widget_style(cls) -> str:
        """空状态组件容器样式"""
        c = cls.colors
        return f"""
            #empty_state {{
                background-color: {c.background_primary};
                border-radius: 12px;
            }}
        """

    @classmethod
    def title_bar_style(cls) -> str:
        """标题栏样式"""
        c = cls.colors
        return f"""
            #compact_title_bar {{
                background-color: {c.background_primary};
                border-bottom: 1px solid {c.border_normal};
                border-top-left-radius: 12px;
                border-top-right-radius: 12px;
            }}
            #compact_title_bar QLabel {{
                color: {c.text_primary};
                font-size: 14px;
                font-weight: 600;
            }}
            #compact_title_bar QPushButton {{
                background: transparent;
                border: none;
                color: {c.text_muted};
                font-size: 16px;
                border-radius: 6px;
                padding: 4px;
            }}
            #compact_title_bar QPushButton:hover {{
                background: {c.background_secondary};
                color: {c.text_primary};
            }}
            #close_btn:hover {{
                background: {c.error};
                color: white;
            }}
        """

    @classmethod
    def icon_button_style(cls) -> str:
        """图标按钮样式（语言/主题切换）"""
        c = cls.colors
        return f"""
            QPushButton {{
                background: transparent;
                border: 1px solid transparent;
                border-radius: 6px;
                color: {c.text_muted};
                font-size: 13px;
                font-weight: 500;
                padding: 4px 8px;
                min-width: 32px;
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

    @classmethod
    def spinner_color(cls) -> str:
        """旋转加载指示器颜色"""
        return cls.colors.accent

    @classmethod
    def separator_style(cls) -> str:
        """分隔线样式"""
        return f"background-color: {cls.colors.separator};"

    # ========================================================================
    # 工具方法
    # ========================================================================

    @classmethod
    def get_shadow_config(cls, is_hover: bool = False) -> Dict:
        """获取阴影配置"""
        if is_hover:
            return {
                'blur_radius': 16,
                'offset': 4,
                'opacity': 80 if cls.is_dark() else 40
            }
        return {
            'blur_radius': 8,
            'offset': 2,
            'opacity': 40 if cls.is_dark() else 20
        }
