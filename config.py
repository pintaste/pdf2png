#!/usr/bin/env python3
"""
应用配置管理模块
负责保存和加载用户偏好设置
"""
import json
from pathlib import Path
from typing import Dict, Any


class AppConfig:
    """应用配置管理器"""

    CONFIG_DIR = Path.home() / '.pdf2png'
    CONFIG_FILE = CONFIG_DIR / 'config.json'

    DEFAULT_CONFIG = {
        # 转换设置
        'last_mode': 'quick',           # 最后使用的模式 (quick/quality/custom)
        'priority_mode': 'quality',     # 优化模式 (quality=质量优先, size=大小优先)
        'last_dpi': 600,                # 最后使用的 DPI
        'last_size': 5,                 # 最后使用的文件大小限制（MB）
        'last_output_dir': '',          # 最后使用的输出目录
        'compression_level': 6,         # PNG 压缩级别 (0-9)

        # 界面设置
        'language': 'zh',               # 语言 (zh=中文, en=英文)
        'theme': 'dark',                # 主题 (dark=暗色, light=亮色)
        'window_width': 1000,           # 窗口宽度
        'window_height': 800,           # 窗口高度
        'preview_visible': False,       # PDF预览是否显示（默认隐藏）

        # 性能设置
        'parallel_enabled': True,       # 并行处理（预留）
    }

    @classmethod
    def load(cls) -> Dict[str, Any]:
        """
        加载配置（带验证）

        Returns:
            配置字典
        """
        if cls.CONFIG_FILE.exists():
            try:
                with open(cls.CONFIG_FILE, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)

                # 验证配置值类型
                validated_config = {}
                for key, default_value in cls.DEFAULT_CONFIG.items():
                    if key in user_config:
                        user_value = user_config[key]
                        # 类型检查
                        if isinstance(default_value, type(user_value)) or user_value is None:
                            validated_config[key] = user_value
                        else:
                            # 类型不匹配，使用默认值
                            validated_config[key] = default_value
                    else:
                        validated_config[key] = default_value

                return validated_config

            except (json.JSONDecodeError, IOError):
                # 配置文件损坏，使用默认配置
                return cls.DEFAULT_CONFIG.copy()
        else:
            return cls.DEFAULT_CONFIG.copy()

    @classmethod
    def save(cls, config: Dict[str, Any]) -> None:
        """
        保存配置

        Args:
            config: 配置字典
        """
        try:
            # 确保配置目录存在
            cls.CONFIG_DIR.mkdir(parents=True, exist_ok=True)

            # 保存配置
            with open(cls.CONFIG_FILE, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2, ensure_ascii=False)
        except IOError:
            # 保存失败不影响应用运行
            pass

    @classmethod
    def get_config_path(cls) -> str:
        """
        获取配置文件路径（用于调试）

        Returns:
            配置文件路径字符串
        """
        return str(cls.CONFIG_FILE)
