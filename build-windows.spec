# -*- mode: python ; coding: utf-8 -*-
"""PDF2PNG Windows 优化打包配置"""

block_cipher = None

a = Analysis(
    ['pdf2png-gui.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[
        'PyQt6.QtCore',
        'PyQt6.QtGui',
        'PyQt6.QtWidgets',
        'gui_pyqt.main_window',
        'gui_pyqt.theme',
        'gui_pyqt.i18n',
        'gui_pyqt.widgets.file_list',
        'gui_pyqt.widgets.empty_state',
        'gui_pyqt.widgets.compact_title_bar',
        'gui_pyqt.widgets.collapsible_settings',
        'gui_pyqt.widgets.macos_controls',
        'gui_pyqt.utils.converter_worker',
        'gui_pyqt.utils.converter_process',
        'gui_pyqt.utils.sound',
        'config',
        'constants',
        'converter',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'tkinter', 'tk', 'tcl', '_tkinter',
        'matplotlib', 'scipy', 'pandas', 'numpy.distutils',
        'IPython', 'jupyter', 'notebook',
        'pytest', 'unittest', 'pydoc', 'doctest',
        'cv2', 'opencv',
        'PyQt6.QtWebEngineWidgets', 'PyQt6.QtWebEngineCore',
        'PyQt6.QtQml', 'PyQt6.QtQuick', 'PyQt6.QtOpenGL',
        'PyQt6.QtSql', 'PyQt6.QtNetwork', 'PyQt6.QtTest',
        'PyQt6.QtDBus', 'PyQt6.QtMultimedia',
        'PyQt6.QtBluetooth', 'PyQt6.QtPositioning',
        'PyQt6.QtSensors', 'PyQt6.QtSerialPort', 'PyQt6.QtNfc',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='PDF2PNG',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
)
