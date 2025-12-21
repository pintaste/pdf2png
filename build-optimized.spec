# -*- mode: python ; coding: utf-8 -*-
"""
PDF2PNG 优化打包配置 (onedir 模式)

功能：
- 使用 onedir 模式（推荐的 macOS 打包方式）
- 移除未使用的模块
- 启用 Strip 压缩
- 最小化体积

使用方法：
    pyinstaller build-optimized.spec

预期体积：~60MB
"""

block_cipher = None

a = Analysis(
    ['pdf2png-gui.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[
        # PyQt6 核心模块
        'PyQt6.QtCore',
        'PyQt6.QtGui',
        'PyQt6.QtWidgets',

        # 应用核心模块
        'gui_pyqt.main_window',
        'gui_pyqt.theme',
        'gui_pyqt.i18n',

        # 组件模块
        'gui_pyqt.widgets.file_list',
        'gui_pyqt.widgets.empty_state',
        'gui_pyqt.widgets.compact_title_bar',
        'gui_pyqt.widgets.collapsible_settings',
        'gui_pyqt.widgets.macos_controls',

        # 工具模块
        'gui_pyqt.utils.converter_worker',
        'gui_pyqt.utils.converter_process',
        'gui_pyqt.utils.sound',

        # 配置和转换
        'config',
        'constants',
        'converter',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        # 排除未使用的GUI框架
        'tkinter',
        'tk',
        'tcl',
        '_tkinter',

        # 排除OpenCV（已确认未使用）
        'cv2',
        'opencv',
        'opencv-python',

        # 排除其他未使用的大型库
        'matplotlib',
        'scipy',
        'pandas',
        'numpy.distutils',
        'IPython',
        'jupyter',
        'notebook',

        # 排除测试和文档
        'pytest',
        'unittest',
        'pydoc',
        'doctest',

        # 排除其他未使用的模块
        'email',
        'xml.etree',
        'http.server',
        'xmlrpc',

        # 排除未使用的 PyQt6 大型模块（节省 ~80MB）
        'PyQt6.QtWebEngineWidgets',
        'PyQt6.QtWebEngineCore',
        'PyQt6.QtQml',
        'PyQt6.QtQuick',
        'PyQt6.QtOpenGL',
        'PyQt6.QtSql',
        'PyQt6.QtNetwork',
        'PyQt6.QtTest',
        'PyQt6.QtDBus',
        'PyQt6.QtMultimedia',
        'PyQt6.QtBluetooth',
        'PyQt6.QtPositioning',
        'PyQt6.QtSensors',
        'PyQt6.QtSerialPort',
        'PyQt6.QtNfc',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# onedir 模式：EXE 只包含脚本，binaries/datas 由 COLLECT 收集
exe = EXE(
    pyz,
    a.scripts,
    [],  # onedir 模式：binaries 由 COLLECT 处理
    exclude_binaries=True,  # 关键：启用 onedir 模式
    name='PDF2PNG',
    debug=False,
    bootloader_ignore_signals=False,
    strip=True,        # 移除调试符号
    upx=False,         # macOS 上禁用 UPX（兼容性问题）
    console=False,     # GUI应用不需要控制台
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

# 收集所有文件到目录
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=True,
    upx=False,
    upx_exclude=[],
    name='PDF2PNG',
)

# macOS App Bundle
app = BUNDLE(
    coll,  # 使用 COLLECT 输出而非单个 EXE
    name='PDF2PNG.app',
    icon=None,
    bundle_identifier='com.pdf2png.app',
    info_plist={
        'CFBundleShortVersionString': '3.0.0',
        'CFBundleVersion': '3.0.0',
        'NSHighResolutionCapable': 'True',
        'NSRequiresAquaSystemAppearance': 'False',  # 支持深色模式
    },
)
