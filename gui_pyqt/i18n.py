#!/usr/bin/env python3
"""
国际化模块 (i18n)

支持中文和英文切换
"""
from typing import Dict, Any, List, Callable


class I18n:
    """
    国际化字符串管理器

    使用方法:
        from gui_pyqt.i18n import I18n

        # 获取字符串
        text = I18n.get('convert')

        # 切换语言
        I18n.set_language('en')

        # 监听语言变化
        I18n.add_listener(my_callback)
    """

    _lang = 'zh'  # 默认中文
    _listeners: List[Callable[[], None]] = []

    # 所有 UI 字符串
    STRINGS: Dict[str, Dict[str, str]] = {
        'zh': {
            # 标题栏
            'title': 'PDF → PNG',
            'subtitle': '高清 PDF 转 PNG 工具',
            'advanced': '高级',
            'toggle_theme': '切换主题',

            # 空状态
            'drop_hint': '拖放 PDF 文件到此处\n或点击黄色区域选择文件',
            'drop_hint_list': '📂\n\n拖放PDF文件到这里\n或点击"添加文件"按钮',
            'select_pdf': '选择 PDF 文件',
            'pdf_filter': 'PDF 文件 (*.pdf);;所有文件 (*.*)',

            # 文件列表
            'file_list': '文件列表',
            'page_unit': '页',

            # 按钮
            'add': '+ 添加',
            'clear': '清空',
            'convert': '开始转换',
            'cancel': '取消',
            'confirm': '确定',
            'apply': '应用',
            'browse': '浏览...',

            # 右键菜单
            'menu_settings': '⚙️ 设置',
            'menu_delete': '🗑️ 删除',

            # 设置面板
            'mode': '模式:',
            'language': '语言:',
            'clarity': '清晰度',
            'file_size': '文件大小',
            'clarity_dpi': '清晰度 (DPI)',
            'file_size_limit': '文件大小限制',
            'mode_quality': '清晰度优先',
            'mode_size': '文件大小优先',
            'mode_quality_desc': '使用最高 DPI，不限制大小',
            'mode_size_desc': '自动调整 DPI 以满足大小限制',
            'dpi_label': 'DPI',
            'dpi_custom': '自定义',
            'limit_label': '限制:',
            'size_limit': '大小限制',

            # DPI 预设描述
            'dpi_150': '快速预览，文件最小',
            'dpi_200': '适合微信/网页查看',
            'dpi_300': '清晰可读 (推荐)',
            'dpi_450': '放大后仍清晰',
            'dpi_600': '可打印 A4 纸',
            'dpi_1200': '超高清，文件较大',
            'output_dir': '输出目录',
            'same_as_source': '与源文件相同',

            # 状态
            'converting': '转换中...',
            'completed': '转换完成',
            'failed': '转换失败',
            'file_not_found': '文件不存在',
            'pages': '页',

            # 对话框
            'hint': '提示',
            'no_files_hint': '请先添加PDF文件',
            'select_output_dir': '选择输出目录',
            'confirm_reconvert_title': '确认重新转换',
            'confirm_reconvert_msg': '有 {count} 个文件已完成转换。\n确定要重新转换吗？',
            'confirm_overwrite_title': '确认覆盖',
            'confirm_overwrite_msg': '以下输出文件已存在：\n\n{files}\n\n确定要覆盖吗？',
            'and_more_files': '... 等 {count} 个文件',

            # 文件验证
            'not_pdf': '不是PDF文件',
            'no_read_permission': '无读取权限',
            'files_skipped': '部分文件跳过',
            'files_skipped_msg': '以下文件无法添加：',

            # 设置对话框
            'settings': '设置',
            'file_settings': '文件设置',
        },
        'en': {
            # Title bar
            'title': 'PDF → PNG',
            'subtitle': 'HD PDF to PNG Converter',
            'advanced': 'Advanced',
            'toggle_theme': 'Toggle Theme',

            # Empty state
            'drop_hint': 'Drop PDF files here\nor click the yellow area to select',
            'drop_hint_list': '📂\n\nDrop PDF files here\nor click "Add" button',
            'select_pdf': 'Select PDF Files',
            'pdf_filter': 'PDF Files (*.pdf);;All Files (*.*)',

            # File list
            'file_list': 'File List',
            'page_unit': 'p',

            # Buttons
            'add': '+ Add',
            'clear': 'Clear',
            'convert': 'Convert',
            'cancel': 'Cancel',
            'confirm': 'OK',
            'apply': 'Apply',
            'browse': 'Browse...',

            # Context menu
            'menu_settings': '⚙️ Settings',
            'menu_delete': '🗑️ Delete',

            # Settings panel
            'mode': 'Mode:',
            'language': 'Language:',
            'clarity': 'Clarity',
            'file_size': 'File Size',
            'clarity_dpi': 'Clarity (DPI)',
            'file_size_limit': 'File Size Limit',
            'mode_quality': 'Quality First',
            'mode_size': 'Size First',
            'mode_quality_desc': 'Use max DPI, no size limit',
            'mode_size_desc': 'Auto adjust DPI to fit size limit',
            'dpi_label': 'DPI',
            'dpi_custom': 'Custom',
            'limit_label': 'Limit:',
            'size_limit': 'Size Limit',

            # DPI preset descriptions
            'dpi_150': 'Quick preview, smallest file',
            'dpi_200': 'Good for web/social media',
            'dpi_300': 'Clear and readable (Recommended)',
            'dpi_450': 'Still clear when zoomed',
            'dpi_600': 'Print quality A4',
            'dpi_1200': 'Ultra HD, larger file',
            'output_dir': 'Output Directory',
            'same_as_source': 'Same as source',

            # Status
            'converting': 'Converting...',
            'completed': 'Completed',
            'failed': 'Failed',
            'file_not_found': 'File not found',
            'pages': 'pages',

            # Dialogs
            'hint': 'Notice',
            'no_files_hint': 'Please add PDF files first',
            'select_output_dir': 'Select Output Directory',
            'confirm_reconvert_title': 'Confirm Re-convert',
            'confirm_reconvert_msg': '{count} file(s) already converted.\nRe-convert them?',
            'confirm_overwrite_title': 'Confirm Overwrite',
            'confirm_overwrite_msg': 'These output files exist:\n\n{files}\n\nOverwrite them?',
            'and_more_files': '... and {count} more files',

            # File validation
            'not_pdf': 'Not a PDF file',
            'no_read_permission': 'No read permission',
            'files_skipped': 'Some files skipped',
            'files_skipped_msg': 'Cannot add these files:',

            # Settings dialog
            'settings': 'Settings',
            'file_settings': 'File Settings',
        }
    }

    @classmethod
    def get(cls, key: str, **kwargs) -> str:
        """
        获取当前语言的字符串

        Args:
            key: 字符串键名
            **kwargs: 格式化参数

        Returns:
            翻译后的字符串
        """
        strings = cls.STRINGS.get(cls._lang, cls.STRINGS['zh'])
        text = strings.get(key, key)

        if kwargs:
            try:
                text = text.format(**kwargs)
            except KeyError:
                pass

        return text

    @classmethod
    def get_language(cls) -> str:
        """获取当前语言"""
        return cls._lang

    @classmethod
    def set_language(cls, lang: str) -> None:
        """
        设置语言

        Args:
            lang: 'zh' 或 'en'
        """
        if lang in cls.STRINGS and lang != cls._lang:
            cls._lang = lang
            cls._notify_listeners()

    @classmethod
    def toggle_language(cls) -> str:
        """切换语言，返回新语言"""
        new_lang = 'en' if cls._lang == 'zh' else 'zh'
        cls.set_language(new_lang)
        return new_lang

    @classmethod
    def add_listener(cls, callback: Callable[[], None]) -> None:
        """添加语言变化监听器"""
        if callback not in cls._listeners:
            cls._listeners.append(callback)

    @classmethod
    def remove_listener(cls, callback: Callable[[], None]) -> None:
        """移除语言变化监听器"""
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
