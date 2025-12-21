#!/bin/bash
# 安装所有依赖

echo "======================================"
echo "  PDF2PNG 依赖安装"
echo "======================================"
echo ""

echo "📦 安装 PyMuPDF (PDF 处理)..."
pip3 install PyMuPDF

echo ""
echo "📦 安装 tkinterdnd2 (拖放支持)..."
pip3 install tkinterdnd2

echo ""
echo "======================================"
echo "  ✅ 安装完成！"
echo "======================================"
echo ""
echo "现在可以运行:"
echo "  GUI 版本:   ./run-gui.sh"
echo "  交互模式:   ./pdf2png.py"
echo "  命令行:     ./pdf2png.py file.pdf"
echo ""
