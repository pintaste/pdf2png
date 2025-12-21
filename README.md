# PDF2PNG

高清 PDF 转 PNG 转换工具，支持批量处理和智能质量控制。

![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)
![PyQt6](https://img.shields.io/badge/GUI-PyQt6-green.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## 特性

- **高清输出** - DPI 范围 150-1200，支持专业级打印质量
- **智能压缩** - 自动调整 DPI 满足文件大小限制
- **批量处理** - 多文件并行转换，进度实时显示
- **双模式** - 质量优先 / 大小优先，按需切换
- **现代界面** - PyQt6 深色主题，简洁优雅
- **跨平台** - macOS / Linux / Windows 全支持

## 安装

### 依赖安装

```bash
pip install PyMuPDF PyQt6
```

或使用安装脚本：

```bash
# macOS / Linux
./install-deps.sh

# Windows
install-deps.bat
```

### 下载预编译版本

从 [Releases](../../releases) 下载对应平台的预编译版本，无需安装 Python。

## 使用方法

### GUI 图形界面

```bash
python pdf2png-gui.py
```

**操作步骤：**
1. 拖放 PDF 文件到窗口，或点击「添加」按钮
2. 选择转换模式：质量优先 / 大小优先
3. 调整 DPI 设置（150-1200）
4. 点击「开始转换」

### 命令行

```bash
# 基本转换
python pdf2png.py input.pdf

# 高质量模式
python pdf2png.py input.pdf -q --max-dpi 1200

# 限制文件大小
python pdf2png.py input.pdf -s 5  # 5MB 限制

# 批量转换
python pdf2png.py "*.pdf" -b -d output/
```

### 交互模式

```bash
python pdf2png.py -i
```

## 命令行参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `input` | 输入 PDF 文件（支持通配符） | - |
| `-o, --output` | 输出文件路径 | 同名.png |
| `-s, --max-size` | 最大文件大小 (MB) | 5 |
| `-q, --quality-first` | 质量优先模式 | 关闭 |
| `--min-dpi` | 最低 DPI | 150 |
| `--max-dpi` | 最高 DPI | 600 |
| `-b, --batch` | 批量模式 | 关闭 |
| `-d, --output-dir` | 输出目录 | 原目录 |
| `-i, --interactive` | 交互模式 | 关闭 |

## DPI 参考

| DPI | 用途 | 文件大小 |
|-----|------|----------|
| 150 | 快速预览 | 小 |
| 300 | 屏幕显示 | 中 |
| 600 | 标准打印 | 大 |
| 1200 | 专业印刷 | 很大 |

## 项目结构

```
pdf2png/
├── pdf2png-gui.py      # GUI 入口
├── pdf2png.py          # CLI 入口
├── converter.py        # 核心转换引擎
├── config.py           # 配置管理
├── constants.py        # 常量定义
├── cli/                # 命令行模块
│   ├── commands.py     # 命令处理
│   └── interactive.py  # 交互模式
└── gui_pyqt/           # PyQt6 GUI
    ├── main_window.py  # 主窗口
    ├── theme.py        # 主题系统
    ├── i18n.py         # 国际化
    ├── widgets/        # UI 组件
    └── utils/          # 工具函数
```

## 构建独立应用

```bash
# 安装 PyInstaller
pip install pyinstaller

# 构建
pyinstaller build-optimized.spec

# 输出位置
# macOS: dist/PDF2PNG.app
# Linux: dist/PDF2PNG
# Windows: dist/PDF2PNG.exe
```

## 系统要求

- Python 3.8+
- PyMuPDF
- PyQt6

## 许可证

MIT License

## 致谢

- [PyMuPDF](https://pymupdf.readthedocs.io/) - PDF 渲染引擎
- [PyQt6](https://www.riverbankcomputing.com/software/pyqt/) - GUI 框架
