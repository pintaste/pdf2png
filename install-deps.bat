@echo off
REM 安装所有依赖 (Windows)

echo ======================================
echo   PDF2PNG 依赖安装
echo ======================================
echo.

echo 安装 PyMuPDF (PDF 处理)...
pip install PyMuPDF

echo.
echo 安装 tkinterdnd2 (拖放支持)...
pip install tkinterdnd2

echo.
echo ======================================
echo   安装完成！
echo ======================================
echo.
echo 现在可以运行:
echo   GUI 版本:   双击 run-gui.bat
echo   交互模式:   python pdf2png.py
echo   命令行:     python pdf2png.py file.pdf
echo.
pause
