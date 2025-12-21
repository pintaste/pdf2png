#!/usr/bin/env python3
"""
常量定义模块

集中管理所有 Magic Numbers 和配置常量
遵循 Clean Code 原则：消除硬编码，提高可维护性
"""
from dataclasses import dataclass
from typing import Dict, Tuple

# 延迟导入 I18n 避免循环依赖
def _get_i18n():
    from gui_pyqt.i18n import I18n
    return I18n


# ============================================================================
# DPI 配置
# ============================================================================

@dataclass(frozen=True)
class DPIPreset:
    """DPI 预设配置"""
    value: int
    name: str
    description: str


class DPIConfig:
    """
    DPI 配置管理

    统一管理 DPI 相关的所有常量和映射
    """

    # DPI 有效范围
    MIN_DPI = 72
    MAX_DPI = 2400
    DEFAULT_DPI = 300

    # PDF 标准 DPI（用于缩放计算）
    PDF_BASE_DPI = 72

    # DPI 预设档位（从低到高）
    PRESETS: Tuple[DPIPreset, ...] = (
        DPIPreset(150, "预览", "快速预览，文件最小"),
        DPIPreset(200, "网页", "适合微信/网页查看"),
        DPIPreset(300, "标准", "清晰可读 (推荐)"),
        DPIPreset(450, "高清", "放大后仍清晰"),
        DPIPreset(600, "打印", "可打印 A4 纸"),
        DPIPreset(1200, "超清", "超高清，文件较大"),
    )

    # 类级别缓存（避免重复计算）
    _position_map: Dict[int, int] = None
    _value_map: Dict[int, int] = None

    @classmethod
    def get_preset_values(cls) -> Tuple[int, ...]:
        """获取所有预设 DPI 值"""
        return tuple(p.value for p in cls.PRESETS)

    @classmethod
    def get_position_map(cls) -> Dict[int, int]:
        """获取 DPI 值到滑块位置的映射（带缓存）"""
        if cls._position_map is None:
            cls._position_map = {p.value: i for i, p in enumerate(cls.PRESETS)}
        return cls._position_map

    @classmethod
    def get_value_map(cls) -> Dict[int, int]:
        """获取滑块位置到 DPI 值的映射（带缓存）"""
        if cls._value_map is None:
            cls._value_map = {i: p.value for i, p in enumerate(cls.PRESETS)}
        return cls._value_map

    @classmethod
    def get_description(cls, position: int) -> str:
        """根据滑块位置获取描述（支持国际化）"""
        if 0 <= position < len(cls.PRESETS):
            preset = cls.PRESETS[position]
            # 使用 i18n 获取本地化描述
            I18n = _get_i18n()
            desc = I18n.get(f'dpi_{preset.value}')
            return f"{preset.value} DPI - {desc}"
        return f"{cls.DEFAULT_DPI} DPI"

    @classmethod
    def value_to_position(cls, dpi: int) -> int:
        """DPI 值转换为滑块位置"""
        return cls.get_position_map().get(dpi, 2)  # 默认位置 2 (300 DPI)

    @classmethod
    def position_to_value(cls, position: int) -> int:
        """滑块位置转换为 DPI 值"""
        return cls.get_value_map().get(position, cls.DEFAULT_DPI)

    @classmethod
    def validate(cls, dpi: int) -> bool:
        """验证 DPI 值是否有效"""
        return cls.MIN_DPI <= dpi <= cls.MAX_DPI


# ============================================================================
# 文件大小配置
# ============================================================================

@dataclass(frozen=True)
class SizePreset:
    """文件大小预设配置"""
    value: int  # MB
    description: str


class SizeConfig:
    """
    文件大小配置管理

    统一管理文件大小相关的常量和映射
    """

    # 大小限制范围 (MB)
    MIN_SIZE_MB = 1
    MAX_SIZE_MB = 100
    DEFAULT_SIZE_MB = 5

    # 大小预设档位
    PRESETS: Tuple[SizePreset, ...] = (
        SizePreset(1, "极小"),
        SizePreset(2, "较小"),
        SizePreset(3, "适中"),
        SizePreset(5, "标准"),
        SizePreset(10, "较大"),
        SizePreset(20, "大"),
        SizePreset(50, "超大"),
    )

    @classmethod
    def get_preset_values(cls) -> Tuple[int, ...]:
        """获取所有预设大小值"""
        return tuple(p.value for p in cls.PRESETS)

    @classmethod
    def get_position_map(cls) -> Dict[int, int]:
        """获取大小值到滑块位置的映射"""
        return {p.value: i for i, p in enumerate(cls.PRESETS)}

    @classmethod
    def get_value_map(cls) -> Dict[int, int]:
        """获取滑块位置到大小值的映射"""
        return {i: p.value for i, p in enumerate(cls.PRESETS)}

    @classmethod
    def value_to_position(cls, size_mb: int) -> int:
        """大小值转换为滑块位置，无匹配返回 -1"""
        return cls.get_position_map().get(size_mb, -1)

    @classmethod
    def position_to_value(cls, position: int) -> int:
        """滑块位置转换为大小值"""
        return cls.get_value_map().get(position, cls.DEFAULT_SIZE_MB)

    @classmethod
    def validate(cls, size_mb: int) -> bool:
        """验证大小值是否有效"""
        return cls.MIN_SIZE_MB <= size_mb <= cls.MAX_SIZE_MB

    @classmethod
    def clamp(cls, size_mb: int) -> int:
        """将大小值限制在有效范围内"""
        return max(cls.MIN_SIZE_MB, min(cls.MAX_SIZE_MB, size_mb))


# ============================================================================
# 转换器配置
# ============================================================================

class ConverterConfig:
    """转换器核心配置"""

    # 默认参数
    DEFAULT_MAX_SIZE_MB = 5.0
    DEFAULT_MIN_DPI = 150
    DEFAULT_MAX_DPI = 600
    DEFAULT_PNG_COMPRESS_LEVEL = 6

    # DPI 搜索步长
    DPI_STEP = 25

    # PNG 压缩估算比例（像素数据 → 压缩后大小）
    # 典型 PDF 转换图像的 PNG 压缩比约为 0.10-0.20
    # 使用 0.15 作为保守估算（偏大以确保不超限）
    PNG_COMPRESS_ESTIMATE_RATIO = 0.15

    # PIL 压缩比估算系数（PyMuPDF PNG → PIL 优化后）
    PIL_COMPRESS_RATIO = 0.12

    # 重试配置
    MAX_RETRIES = 3
    DPI_SAFETY_MARGIN = 0.9  # 降档时的安全余量


# ============================================================================
# GUI 配置
# ============================================================================

class WindowConfig:
    """窗口配置"""

    # 窗口尺寸
    DEFAULT_WIDTH = 300
    DEFAULT_HEIGHT = 400
    MIN_WIDTH = 300
    MIN_HEIGHT = 400

    # 动画时长 (ms)
    ANIMATION_DURATION = 300
    SPINNER_INTERVAL = 16  # 约 60fps
    SPINNER_ROTATION_SPEED = 8  # 每帧旋转角度


class UIConfig:
    """UI 元素配置"""

    # 边距和间距
    CONTENT_MARGIN = 10
    ITEM_SPACING = 4
    BUTTON_HEIGHT = 36
    BOTTOM_BAR_HEIGHT = 60

    # 字体大小
    FONT_SIZE_TITLE = 14
    FONT_SIZE_NORMAL = 13
    FONT_SIZE_SMALL = 11
    FONT_SIZE_BUTTON = 14

    # 阴影效果
    SHADOW_BLUR_NORMAL = 8
    SHADOW_BLUR_HOVER = 16
    SHADOW_OFFSET_NORMAL = 2
    SHADOW_OFFSET_HOVER = 4
    SHADOW_OPACITY_NORMAL = 40
    SHADOW_OPACITY_HOVER = 80


# ============================================================================
# 文件格式配置
# ============================================================================

class FileConfig:
    """文件格式配置"""

    # 支持的输入格式
    INPUT_EXTENSIONS = ('.pdf',)

    # 输出格式
    OUTPUT_EXTENSION = '.png'

    # 文件对话框过滤器
    FILE_FILTER = "PDF 文件 (*.pdf);;所有文件 (*.*)"

    # 多页文件命名模板（输出到 {basename}/ 子文件夹）
    MULTIPAGE_TEMPLATE = "{basename}/page{page}.png"
