# PDF2PNG Swift 原生版

macOS 原生 PDF 到 PNG 转换工具，使用 Swift + PDFKit 构建。

## 特性

- **原生性能**：基于 macOS PDFKit，比 Python 版本快 55%（扫描文档快 6-9 倍）
- **轻量体积**：应用仅 ~5MB（Python 版本 ~80MB）
- **即时启动**：启动时间 <0.5 秒
- **现代 UI**：SwiftUI 构建的原生 macOS 界面
- **智能压缩**：自动调整 DPI 以满足文件大小限制，支持应急降档至 18 DPI
- **批量处理**：支持多文件拖放和批量转换
- **双语支持**：中文/英文界面切换
- **深色模式**：完整的深色/浅色主题支持

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon 或 Intel Mac

## 构建

### 使用 Swift Package Manager

```bash
cd PDF2PNG-Swift
swift build -c release
```

### 使用 Xcode

1. 打开 `PDF2PNG-Swift` 目录
2. 双击 `Package.swift` 在 Xcode 中打开
3. 选择 `Product > Build` 或按 `Cmd+B`

## 使用方法

### GUI 模式

直接运行应用，然后：
1. 拖放 PDF 文件到窗口
2. 或点击"选择文件"按钮
3. 调整转换设置（可选）
4. 点击"开始转换"

### 命令行模式

```bash
# 基本转换
./PDF2PNG input.pdf

# 指定输出目录
./PDF2PNG input.pdf -o output_dir

# 质量优先模式
./PDF2PNG input.pdf -q

# 指定 DPI
./PDF2PNG input.pdf --max-dpi 1200

# 批量转换
./PDF2PNG *.pdf -o output_dir
```

## 转换设置

| 设置 | 说明 | 默认值 |
|------|------|--------|
| 最大 DPI | 输出图像的最大分辨率 | 600 |
| 最小 DPI | 降低质量时的下限 | 150 |
| 最大文件大小 | 单个 PNG 的大小限制 | 5 MB |
| 质量优先 | 忽略大小限制，使用最高 DPI | 关闭 |

## 性能对比

基于真实 PDF 文件测试（8 种不同类型）：

| 文档类型 | Swift 加速比 |
|---------|-------------|
| 扫描文档 | **5.75-9.19x** |
| 学术论文 | **4.18x** |
| 商业文档 | **1.60-1.90x** |
| 数据报告 | **1.56x** |
| 演示文稿 | **1.24x** |

## 项目结构

```
PDF2PNG-Swift/
├── Sources/
│   ├── App/
│   │   ├── PDF2PNGApp.swift      # 应用入口
│   │   └── AppState.swift        # 状态管理
│   ├── Core/
│   │   └── PDFConverter.swift    # PDF 转换核心
│   ├── Models/
│   │   ├── ConversionTask.swift  # 任务模型
│   │   ├── ConversionSettings.swift
│   │   └── AppError.swift        # 错误定义
│   ├── Views/
│   │   ├── MainView.swift        # 主界面
│   │   └── SettingsView.swift    # 设置界面
│   └── Resources/
│       ├── en.lproj/             # 英文本地化
│       └── zh-Hans.lproj/        # 中文本地化
├── Tests/
└── Package.swift
```

## 更新日志

### v4.2.0
- 🐛 修复大小限制算法，确保文件绝不超过限制
- ✨ Size Limit 模式显示 DPI 范围（如 `18-150DPI`）
- ✨ 任务完成后"重新开始"按钮可用
- 🎨 优化状态文字颜色饱和度，提升可读性

### v4.1.0
- 🌐 双语支持（中文/英文）
- 🌙 深色/浅色主题切换

### v4.0.0
- 🚀 首个 Swift 原生版本发布

## 许可证

MIT License
