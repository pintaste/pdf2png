# PDF2PNG

高清 PDF 转 PNG 转换工具 - Swift 原生 macOS 应用

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![GitHub release](https://img.shields.io/github/v/release/pintaste/pdf2png)
![GitHub Downloads](https://img.shields.io/github/downloads/pintaste/pdf2png/total)
![GitHub Stars](https://img.shields.io/github/stars/pintaste/pdf2png)

## ✨ 特性

- **🎯 原生体验** - Swift + SwiftUI 构建，完美融入 macOS 生态
- **📐 高清输出** - DPI 范围 18-2400，支持专业级打印质量
- **🤖 智能算法** - 五步 DPI 优化算法，自动满足文件大小要求
- **⚡ 批量处理** - 多文件并行转换，实时进度显示
- **🎨 双模式** - 质量优先 / 大小限制，按需切换
- **🌓 深色模式** - 完整支持 macOS 深色/浅色主题
- **🌍 双语界面** - 中文 / English 运行时切换
- **📦 轻量级** - 应用大小仅 ~250KB，无需 Python 环境

## 🚀 快速开始

### 三步完成转换

1. **下载** - 从 [Releases](https://github.com/pintaste/pdf2png/releases/latest) 下载 `PDF2PNG-Swift-macOS.zip`
2. **安装** - 解压并移动到应用程序文件夹
3. **使用** - 拖放 PDF 文件到应用，点击"开始转换"

就是这么简单！

## 📥 安装

### 方法 1: 下载预编译应用（推荐）

从 [Releases](https://github.com/pintaste/pdf2png/releases) 下载最新的 `PDF2PNG-Swift-macOS.zip`：

```bash
unzip PDF2PNG-Swift-macOS.zip
mv PDF2PNG.app /Applications/
```

### 方法 2: 从源码构建

**系统要求：**
- macOS 13.0+
- Xcode 15.0+ 或 Swift 5.9+

**构建步骤：**

```bash
cd PDF2PNG-Swift
swift build -c release
```

**打包为 .app：**

参考 `PDF2PNG-Swift/README.md` 中的详细说明。

## 🚀 使用方法

### 拖放转换

1. 启动 PDF2PNG.app
2. 将 PDF 文件拖放到黄色区域
3. 选择转换模式（质量优先 / 大小限制）
4. 调整 DPI 设置
5. 点击「开始转换」

### 转换模式

**质量优先模式**
- 使用最高 DPI 渲染
- 忽略文件大小限制
- 适合专业印刷

**大小限制模式**
- 智能调整 DPI 满足文件大小要求
- 五步优化算法：初始尝试 → 渐进降低 → 二分精调 → 向上逼近 → 强制验证
- 默认限制：5 MB（可调整 2-50 MB）

## 🎛️ DPI 参考

| DPI | 用途 | 推荐场景 |
|-----|------|---------|
| 150 | 快速预览 | 屏幕查看 |
| 300 | 标准打印 | 普通文档 |
| 600 | 高质量打印 | 商业印刷 |
| 1200 | 专业印刷 | 出版物 |
| 2400 | 极限质量 | 特殊需求 |

## 📁 项目结构

```
PDF2PNG-Swift/
├── Sources/
│   ├── App/
│   │   ├── PDF2PNGApp.swift      # 应用入口
│   │   └── AppState.swift        # 全局状态管理
│   ├── Core/
│   │   └── PDFConverter.swift    # PDF 转换核心（五步 DPI 算法）
│   ├── Models/
│   │   ├── ConversionTask.swift  # 任务模型
│   │   ├── ConversionSettings.swift # 转换设置
│   │   └── AppError.swift        # 错误定义
│   ├── Views/
│   │   ├── MainView.swift        # 主界面（拖放、文件列表、控制）
│   │   └── SettingsView.swift    # 设置界面
│   └── Resources/
│       ├── en.lproj/Localizable.strings      # 英文本地化
│       └── zh-Hans.lproj/Localizable.strings # 中文本地化
├── Package.swift                 # SPM 包配置
├── Info.plist                    # 应用配置
└── README.md                     # Swift 版本文档
```

## ⚙️ 核心技术

- **Swift** - 类型安全的现代语言
- **SwiftUI** - 声明式 UI 框架
- **PDFKit** - macOS 原生 PDF 渲染
- **Concurrency** - Actor 并发模型
- **SPM** - Swift Package Manager

## 🔧 开发

### 运行测试

```bash
cd PDF2PNG-Swift
swift test
```

### 构建 Release 版本

```bash
swift build -c release
```

### 生成 Xcode 项目

```bash
swift package generate-xcodeproj
```

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 🙏 致谢

- [PDFKit](https://developer.apple.com/documentation/pdfkit) - macOS 原生 PDF 框架
- [Swift](https://swift.org/) - Apple 开源编程语言

---

## 🗂️ 版本历史

**最新版本：v4.2.0** (2025-12-27)
- ✅ 修复大小限制算法和 DPI 范围显示
- ✅ 支持中英文双语
- ✅ 支持深色模式
- ✅ 完整迁移到 Swift 原生实现

查看完整 [Changelog](PDF2PNG-Swift/README.md)
