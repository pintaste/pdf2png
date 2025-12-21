#!/usr/bin/env python3
"""
音效模块

在关键操作时播放系统提示音
"""
import subprocess
import platform


class Sound:
    """
    系统音效播放器

    使用 macOS 系统音效，无需额外依赖
    """

    # macOS 系统音效路径
    SOUNDS = {
        'success': '/System/Library/Sounds/Purr.aiff',       # 完成音效（轻柔）
        'error': '/System/Library/Sounds/Basso.aiff',        # 错误音效
        'warning': '/System/Library/Sounds/Sosumi.aiff',     # 警告音效
    }

    _enabled = True  # 全局开关

    @classmethod
    def play(cls, sound_name: str) -> None:
        """
        播放指定音效

        Args:
            sound_name: 音效名称 ('success', 'error', 'warning')
        """
        if not cls._enabled:
            return

        if platform.system() != 'Darwin':
            return  # 仅支持 macOS

        sound_path = cls.SOUNDS.get(sound_name)
        if not sound_path:
            return

        try:
            # 使用 afplay 播放音效（异步，不阻塞 UI）
            subprocess.Popen(
                ['afplay', sound_path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        except Exception:
            pass  # 静默失败

    @classmethod
    def play_success(cls) -> None:
        """播放成功音效"""
        cls.play('success')

    @classmethod
    def play_error(cls) -> None:
        """播放错误音效"""
        cls.play('error')

    @classmethod
    def play_warning(cls) -> None:
        """播放警告音效"""
        cls.play('warning')

    @classmethod
    def set_enabled(cls, enabled: bool) -> None:
        """设置音效开关"""
        cls._enabled = enabled

    @classmethod
    def is_enabled(cls) -> bool:
        """获取音效开关状态"""
        return cls._enabled
