# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

PDF2PNG 是一个 PDF 到 PNG 的高清转换工具，提供三种使用模式：
- **GUI 图形界面** (`pdf2png-gui.py`) - 适合所有用户
- **交互模式** (`pdf2png.py -i`) - 命令行友好的菜单引导
- **命令行模式** (`pdf2png.py`) - 快速执行和脚本化

## 常用命令

### 依赖安装
```bash
# macOS/Linux
./install-deps.sh

# Windows
install-deps.bat

# 手动安装
pip install PyMuPDF tkinterdnd2
```

### 运行程序
```bash
# GUI 版本（推荐）
./run-gui.sh              # macOS/Linux
python3 pdf2png-gui.py    # 或直接运行

# 交互模式
./pdf2png.py              # 无参数自动进入交互模式
./pdf2png.py -i          # 显式指定交互模式

# 命令行模式
./pdf2png.py input.pdf                    # 基本转换（5MB限制）
./pdf2png.py input.pdf -q --max-dpi 1200  # 高质量模式
./pdf2png.py "*.pdf" -b -d output         # 批量转换
```

### 打包为独立应用
```bash
# macOS/Linux
./build-app.sh

# Windows
build-app.bat

# 手动打包
pip install pyinstaller
pyinstaller --onefile --windowed --name PDF2PNG pdf2png-gui.py
```

## 核心架构

### 双引擎设计

项目采用双引擎架构，共享核心转换逻辑：

1. **pdf2png.py** (544行) - 命令行/交互引擎
   - `convert_pdf_to_png()` 函数：核心转换逻辑
   - 参数：`pdf_path`, `output_path`, `max_size_mb`, `min_dpi`, `max_dpi`, `quality_first`
   - 支持单文件和批量处理
   - 交互模式提供4种转换预设

2. **pdf2png-gui.py** (610行) - GUI 引擎
   - `PDF2PNGConverter` 类：封装转换逻辑
   - tkinter GUI：主界面和控件
   - 多线程设计：`threading.Thread` 避免界面卡顿
   - 可选 `tkinterdnd2` 支持拖放功能

### 智能转换算法

**核心算法**（两个文件中实现相同）：
1. 生成 DPI 等级列表（从 `max_dpi` 到 `min_dpi`，步长通常为50）
2. 从最高 DPI 开始逐级尝试渲染
3. 检查生成文件大小是否满足 `max_size_mb` 要求
4. 满足则停止，不满足则降低 DPI 重试
5. 质量优先模式 (`quality_first=True`) 直接使用 `max_dpi`，跳过大小检查

**多页处理**：
- 单页 PDF：生成 `filename.png`
- 多页 PDF：生成 `filename_page1.png`, `filename_page2.png`, ...

### 关键依赖

- **PyMuPDF** (`import fitz`): 必需，PDF 渲染引擎
  - `fitz.open(pdf_path)` - 打开 PDF
  - `doc[page_num]` - 获取页面
  - `page.get_pixmap(matrix=mat, alpha=False)` - 渲染为图像
  - `pix.save(output_path)` - 保存 PNG

- **tkinterdnd2**: 可选，仅用于 GUI 拖放功能
  - 缺失时 GUI 仍可正常使用（点击选择文件）

## 代码修改指南

### 修改转换参数
- 默认 DPI 范围：150-600（见 `min_dpi`, `max_dpi` 参数）
- 默认文件大小限制：5MB（见 `max_size_mb` 参数）
- DPI 步长计算：`step = max(50, (max_dpi - min_dpi) // 6)`

### 添加新功能
- 核心转换逻辑需在两个文件中同步修改：
  - `pdf2png.py` 的 `convert_pdf_to_png()` 函数
  - `pdf2png-gui.py` 的 `PDF2PNGConverter.convert()` 方法
- GUI 界面修改仅需编辑 `pdf2png-gui.py`

### 多线程注意事项
- GUI 版本使用 `threading.Thread` 执行转换
- 进度回调通过 `queue.Queue` 传递消息到主线程
- 避免在工作线程中直接操作 tkinter 组件

## 文档结构

- **README.md**: 完整功能文档和参数说明
- **QUICKSTART.md**: 快速上手指南
- **GUI-GUIDE.md**: GUI 详细使用指南
- **FEATURES.md**: 功能特性对比
- **PROJECT-INFO.md**: 项目总览和技术细节

## 平台兼容性

- **全平台支持**: Windows / macOS / Linux
- **tkinter**: Python 标准库，无需额外安装
- **打包应用**: PyInstaller 生成独立可执行文件
  - Windows: `dist/PDF2PNG.exe`
  - macOS: `dist/PDF2PNG.app`
  - Linux: `dist/PDF2PNG`
