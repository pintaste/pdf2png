# PDF 转 PNG 高清转换工具

> 🎉 **最新版本**: v3.0 (PyQt6) | [查看v3.0文档](./README-PyQt6.md)

一个专业的 PDF 到 PNG 转换工具，支持高清输出、文件大小控制和批量处理。

---

## 🚀 版本选择

### **v3.0 - PyQt6 专业版** ⭐ 推荐

```bash
python3 pdf2png-gui.py
```

**核心特性**:
- ✅ 实时PDF预览（缩略图）
- ✅ 每个文件独立进度条
- ✅ 原生拖放支持（无第三方依赖）
- ✅ 极简主义界面
- ✅ 系统主题自适应
- ✅ 启动速度快3倍

**详细文档**: [README-PyQt6.md](./README-PyQt6.md)

### v2.0 - ttkbootstrap 版

```bash
python3 pdf2png-gui-ttkbootstrap.py
```

**特点**: Bootstrap风格、深色主题、动画丰富

---

## ✨ v2.0 特性 (ttkbootstrap版)

### 🎨 全新现代化界面
- **Bootstrap 风格设计** - 基于 ttkbootstrap，专业美观
- **圆角卡片布局** - 文件列表、设置面板均采用卡片式设计
- **3D 拖放区域** - 立体边框 + 大图标引导，拖入高亮动画
- **条纹进度条** - 实时动画反馈，转换状态一目了然
- **深色/亮色主题** - 一键切换，自动保存偏好

### ⚡ 交互体验提升
- **悬停效果** - 所有可点击元素悬停高亮
- **快捷键提示** - Tooltip 显示键盘快捷键
- **加载状态** - 按钮显示加载动画
- **响应式布局** - 窗口大小自适应

### 🛠️ 核心功能
- **智能文件管理** - ScrolledFrame 自动滚动，支持大量文件
- **Toolbutton 模式选择器** - 三种预设模式快速切换
- **实时数值显示** - DPI 和文件大小滑块实时更新
- **配置持久化** - 自动保存用户偏好（模式、DPI、主题等）
- **优雅降级** - 拖放功能不可用时自动切换到点击选择

### 📋 完整特性列表
- 🎨 **现代化 GUI** - Bootstrap 级别视觉设计
- 🎛️ **真正的自定义设置** - DPI 滑块 (150-1200)、文件大小滑块 (1-50MB)
- 📊 **实时进度显示** - 条纹动画进度条 + 彩色状态文字
- 🚫 **可中断转换** - 随时取消正在进行的转换
- 📁 **文件列表管理** - 添加、删除、清空，支持悬停效果
- 📂 **输出路径选择** - 自定义输出目录
- 🌓 **主题切换** - 深色/亮色模式，右上角一键切换
- ⌨️ **命令行 + 交互模式** - 适合不同用户群体
- 🔄 **批量处理** - 支持通配符批量转换

## 🎯 三种使用方式

| 方式 | 适合人群 | 特点 |
|------|---------|------|
| **🖼️ GUI 版本** | 所有用户 | 图形界面、拖放支持、实时进度 |
| **🤝 交互模式** | 命令行新手 | 菜单引导、零学习成本 |
| **⌨️ 命令行** | 高级用户 | 快速执行、可脚本化 |

## 📦 安装依赖

### 自动安装（推荐）

**macOS / Linux:**
```bash
./install-deps.sh
```

**Windows:**
```cmd
双击 install-deps.bat
```

### 手动安装

```bash
# 必需 - PDF 处理
pip install PyMuPDF

# 必需 - 现代化 GUI 框架
pip install ttkbootstrap

# 可选 - PNG 优化
pip install Pillow

# 可选 - GUI 拖放功能（推荐）
pip install tkinterdnd2
```

## 🚀 快速开始

### 方式一：GUI 图形界面（推荐）⭐

```bash
# macOS / Linux
./run-gui.sh

# Windows
双击 run-gui.bat
```

**GUI 功能：**
- 📄 拖放 PDF 文件（3D 拖放区 + 动画反馈）
- 📋 文件列表管理（卡片式 + 悬停效果）
- 🎛️ 三种转换模式：快速、高质、自定义（Toolbutton 样式）
- ✨ 自定义 DPI 滑块 (150-1200)（实时数值显示）
- 📦 文件大小限制滑块 (1-50MB)
- 📂 输出路径选择
- 📊 条纹动画进度条 + 彩色状态
- 🚫 取消转换功能
- 🌓 主题切换（深色/亮色）
- ⌨️ 快捷键提示（Tooltip）

### 方式二：交互模式

```bash
./pdf2png.py
# 或
./pdf2png.py -i
```

### 方式三：命令行模式

```bash
# 基本转换（5MB限制）
./pdf2png.py input.pdf

# 高质量模式（不限大小）
./pdf2png.py input.pdf -q --max-dpi 1200

# 批量转换
./pdf2png.py "*.pdf" -b -d output
```

## 📖 详细用法

### GUI 版本

1. **启动应用**：运行 `run-gui.sh`（或 `.bat`）
2. **添加文件**：拖放 PDF 或点击"添加文件"
3. **选择模式**：
   - 🚀 快速 (5MB) - 适合网页分享
   - ✨ 高质 (不限) - 适合打印存档
   - 🎛️ 自定义 - 完全控制 DPI 和文件大小
4. **自定义设置**（仅自定义模式）：
   - 调整清晰度滑块 (DPI)
   - 调整文件大小限制
   - 选择输出路径（可选）
5. **开始转换**：点击"开始转换"按钮
6. **查看进度**：实时进度条显示转换状态
7. **取消转换**：如需中断，点击"取消"按钮

### 命令行模式

#### 基本命令

```bash
# 单文件转换
./pdf2png.py input.pdf

# 指定输出文件
./pdf2png.py input.pdf -o output.png

# 自定义文件大小限制
./pdf2png.py input.pdf -s 10  # 10MB限制

# 优先质量模式
./pdf2png.py input.pdf -q

# 自定义 DPI 范围
./pdf2png.py input.pdf --min-dpi 200 --max-dpi 800
```

#### 批量转换

```bash
# 转换当前目录所有 PDF
./pdf2png.py "*.pdf" -b

# 转换并输出到指定目录
./pdf2png.py "*.pdf" -b -d output_folder

# 批量转换特定模式的文件
./pdf2png.py "report_*.pdf" -b
```

### 完整参数说明

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `input` | - | 输入 PDF 文件路径（支持通配符） | 可选* |
| `--interactive` | `-i` | 启动交互模式 | 自动** |
| `--output` | `-o` | 输出 PNG 文件路径 | 同名.png |
| `--max-size` | `-s` | 最大文件大小（MB） | 5 |
| `--quality-first` | `-q` | 优先质量模式（忽略大小限制） | 关闭 |
| `--min-dpi` | - | 最低 DPI | 150 |
| `--max-dpi` | - | 最高 DPI | 600 |
| `--batch` | `-b` | 批量模式 | 关闭 |
| `--output-dir` | `-d` | 批量转换时的输出目录 | 原目录 |

\* 如果不提供输入文件，自动进入交互模式
\*\* 直接运行 `./pdf2png.py` 会自动进入交互模式

## 🏗️ 项目架构 (v2.0)

本项目采用模块化设计，遵循 SOLID 原则：

```
pdf2png/
├── converter.py              # 核心转换模块（共享逻辑）
├── config.py                 # 配置管理
├── pdf2png.py                # 命令行 + 交互模式
├── pdf2png-gui.py            # GUI 入口（简化版）
│
├── gui/                      # GUI 模块目录
│   ├── __init__.py           # 模块导出
│   ├── constants.py          # UI 常量配置
│   ├── themes.py             # 主题管理系统
│   │
│   ├── components/           # 可复用组件
│   │   ├── file_list.py      # FileListCard（ScrolledFrame）
│   │   ├── drop_zone.py      # DropZone（3D 拖放）
│   │   ├── settings_panel.py # SettingsPanel（Toolbutton）
│   │   ├── progress.py       # ProgressCard（条纹动画）
│   │   └── tooltip.py        # ShortcutTooltip
│   │
│   ├── widgets/              # 自定义控件
│   │   ├── button.py         # ActionButton（加载状态）
│   │   ├── effects.py        # HoverEffect 工具
│   │   └── animations.py     # Animator 动画系统
│   │
│   └── app.py                # PDF2PNGApp 主应用类
│
├── run-gui.sh                # GUI 启动脚本
├── build-app.sh              # 应用打包脚本
└── README.md                 # 本文档
```

### 核心模块

**`converter.py`** - PDF 转换核心
- `PDFConverter` 类 - 二分搜索 DPI 优化、PNG 压缩
- 工具函数 - 文件大小格式化、DPI 等级生成、参数验证

**`config.py`** - 配置管理
- `AppConfig` 类 - 保存/加载用户偏好
- 配置路径：`~/.pdf2png/config.json`

### GUI 模块架构

**主题系统** (`gui/themes.py`)
- `ThemeManager` - 亮色/深色主题切换
- 自定义配色 - 紫色渐变主题
- 4 种主题变体 (default/blue/green/red)

**组件层** (`gui/components/`)
- `FileListCard` - 卡片式文件列表 + ScrolledFrame
- `DropZone` - 3D 拖放区 + 动画反馈
- `SettingsPanel` - Toolbutton 模式选择器 + 现代滑块
- `ProgressCard` - 条纹动画进度条 + 彩色状态
- `ShortcutTooltip` - 快捷键提示工具

**控件层** (`gui/widgets/`)
- `ActionButton` - 图标+文字组合按钮 + 加载状态
- `HoverEffect` - 悬停效果管理器
- `Animator` - 滑动展开/收起动画
- `ProgressAnimator` - 进度条平滑更新

**应用层** (`gui/app.py`)
- `PDF2PNGApp` - 主应用类
  - 窗口管理
  - 组件协调
  - 事件处理
  - 转换流程控制
  - 配置持久化

## 🛠️ 工作原理

1. **智能 DPI 调整**：从最高 DPI 开始尝试，逐步降低直到满足文件大小要求
2. **多页处理**：自动检测 PDF 页数，每页生成单独的 PNG 文件
3. **质量优先**：在满足大小限制的前提下，自动选择最高可用的 DPI

## 📦 打包为独立应用

创建无需 Python 的独立应用：

```bash
# macOS / Linux
./build-app.sh

# Windows
双击 build-app.bat
```

生成的应用可分发给任何人使用，无需安装 Python 或依赖！

## 💡 实际案例

### 案例 1: 学术论文高清转换

```bash
./pdf2png.py thesis.pdf -q --max-dpi 1200
```

### 案例 2: 网页展示用图

```bash
./pdf2png.py document.pdf -s 2
```

### 案例 3: 批量处理课程资料

```bash
./pdf2png.py "lecture_*.pdf" -b -d course_images
```

## 🔧 开发指南

### 代码规范

- 遵循 SOLID 原则
- 完整的类型注解
- 详细的文档字符串
- DRY（不重复自己）

### 扩展功能

要添加新功能，修改 `converter.py` 中的核心逻辑，然后在 `pdf2png.py` 和 `pdf2png-gui.py` 中调用。

## 系统要求

- Python 3.6+
- PyMuPDF (fitz) 库
- tkinterdnd2（可选，用于 GUI 拖放）

## 许可证

MIT License

## 作者

Created with Claude Code
