# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

PDF2PNG 是一个 PDF 到 PNG 的高清转换工具，采用 **Swift 原生实现**，专为 macOS 平台打造。

- **技术栈**: Swift 5.9+ + SwiftUI + PDFKit
- **平台**: macOS 13.0+
- **构建**: Swift Package Manager (SPM)
- **特色**: 原生性能、深色模式、双语支持、智能 DPI 算法

## 常用命令

### 开发环境

```bash
# 编译项目
cd PDF2PNG-Swift
swift build

# 运行测试
swift test

# 生成 Xcode 项目
swift package generate-xcodeproj
```

### 构建 Release 版本

```bash
cd PDF2PNG-Swift
swift build -c release
```

### 打包为独立应用

```bash
cd PDF2PNG-Swift

# 1. 构建 Release 版本
swift build -c release

# 2. 创建 .app 目录结构
mkdir -p dist/PDF2PNG.app/Contents/{MacOS,Resources}

# 3. 复制可执行文件
cp .build/release/PDF2PNG dist/PDF2PNG.app/Contents/MacOS/

# 4. 复制资源 bundle
cp -r .build/release/PDF2PNG_PDF2PNG.bundle dist/PDF2PNG.app/Contents/Resources/

# 5. 复制 Info.plist
cp Info.plist dist/PDF2PNG.app/Contents/

# 6. 压缩发布
cd dist
zip -r PDF2PNG-Swift-macOS.zip PDF2PNG.app
```

## 核心架构

### 目录结构

```
PDF2PNG-Swift/
├── Sources/
│   ├── App/
│   │   ├── PDF2PNGApp.swift      # 应用入口 (@main)
│   │   └── AppState.swift        # 全局状态管理 (@MainActor)
│   ├── Core/
│   │   └── PDFConverter.swift    # PDF 转换核心 (actor)
│   ├── Models/
│   │   ├── ConversionTask.swift  # 任务模型 + TaskStatus
│   │   ├── ConversionSettings.swift # 转换设置
│   │   └── AppError.swift        # 错误定义
│   ├── Views/
│   │   ├── MainView.swift        # 主界面 (~1100行)
│   │   └── SettingsView.swift    # 设置界面
│   └── Resources/
│       ├── en.lproj/Localizable.strings      # 英文本地化
│       └── zh-Hans.lproj/Localizable.strings # 中文本地化
├── Package.swift                 # SPM 包配置
├── Info.plist                    # 应用配置
└── README.md                     # Swift 版本详细文档
```

### 关键类和结构

#### PDFConverter (actor)
PDF 转换核心，使用 Actor 保证线程安全：

```swift
actor PDFConverter {
    func convert(pdfURL: URL, settings: ConversionSettings, progress: @escaping (String) -> Void) async throws -> ConversionResult

    private func convertPage(page: PDFPage, settings: ConversionSettings) async throws -> (URL, Int)

    private func renderPage(page: PDFPage, dpi: Int) async throws -> Data
}
```

#### 五步 DPI 算法（大小限制模式）

1. **初始尝试** (`maxDPI`) - 直接尝试最高质量
2. **渐进降低** - 使用 0.95 安全系数逐步降低
3. **二分精调** - 在可行范围内精确定位（精度 5 DPI）
4. **向上逼近** - 从下限向上微调（步长 15 DPI）
5. **强制验证** - 最终确认并应急降档（最低 18 DPI）

#### AppState (@MainActor)
全局状态管理，所有 UI 更新在主线程：

```swift
@MainActor
class AppState: ObservableObject {
    @Published var tasks: [ConversionTask] = []
    @Published var isConverting = false
    @Published var settings = ConversionSettings()
    // ...
}
```

#### LanguageManager (ObservableObject)
运行时语言切换管理：

```swift
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: String
    @Published private(set) var bundle: Bundle

    func toggleLanguage() // 切换中英文
    func localized(_ key: String) -> String // 获取本地化字符串
}
```

**重要**: 本地化文件加载逻辑（MainView.swift:99-137）：
1. 优先从 `Bundle.main` 加载（打包后的应用）
2. 尝试从 `PDF2PNG_PDF2PNG.bundle` 加载资源
3. 回退到 `Bundle.module`（开发时使用）

### UI 组件（MainView.swift）

- **LanguageToggleButton** - 地球图标语言切换
- **ThemeToggleButton** - 月亮/太阳图标主题切换
- **ThemedNSSlider** - 自适应主题的滑块（NSViewRepresentable）
- **ThemedNumberField** - 自适应主题的数字输入（NSViewRepresentable）
- **FileRowView** - 文件列表行组件

### 并发模型

- **AppState**: `@MainActor` 确保所有 UI 更新在主线程
- **PDFConverter**: `actor` 保证转换操作线程安全
- **Task**: 使用 Swift Concurrency 异步处理转换任务

## 代码修改指南

### 修改转换参数

在 `ConversionSettings.swift` 中修改默认值：

```swift
struct ConversionSettings {
    var maxDPI: Int = 600        // 默认最大 DPI
    var minDPI: Int = 150        // 默认最小 DPI
    var maxSizeMB: Int = 5       // 默认文件大小限制
    var qualityFirst: Bool = false
}
```

### 添加新功能

1. **修改转换逻辑** - 编辑 `PDFConverter.swift`
2. **修改 UI** - 编辑 `MainView.swift` 或 `SettingsView.swift`
3. **添加状态** - 在 `AppState.swift` 中添加新的 `@Published` 属性
4. **添加本地化** - 在两个 `Localizable.strings` 文件中添加对应键值

### 本地化字符串

**添加步骤：**

1. 在 `en.lproj/Localizable.strings` 添加英文：
   ```
   "new.feature.title" = "New Feature";
   ```

2. 在 `zh-Hans.lproj/Localizable.strings` 添加中文：
   ```
   "new.feature.title" = "新功能";
   ```

3. 在代码中使用：
   ```swift
   // 方法 1: 运行时本地化（推荐）
   Text(LanguageManager.shared.localized("new.feature.title"))

   // 方法 2: 编译时本地化
   Text(String(localized: "new.feature.title", bundle: LanguageManager.shared.bundle))
   ```

### 多线程注意事项

- **UI 更新**: 必须在 `@MainActor` 上下文中
- **转换操作**: 在 `PDFConverter` (actor) 中自动序列化
- **异步调用**: 使用 `async/await`，避免回调地狱

```swift
// ✅ 正确
Task {
    let result = try await converter.convert(...)
    await MainActor.run {
        // 更新 UI
    }
}

// ❌ 错误
DispatchQueue.global().async {
    // 不要用 GCD，使用 Swift Concurrency
}
```

## 文档结构

- **README.md** (根目录) - 项目总览，面向用户
- **PDF2PNG-Swift/README.md** - Swift 版本详细文档，面向开发者
- **CLAUDE.md** (本文件) - AI 助手指南

## 构建系统

### Swift Package Manager (SPM)

- **Package.swift** - 包配置文件
- **Dependencies** - 目前无外部依赖，仅使用 macOS 系统框架
- **Resources** - 通过 `.process("Resources")` 包含本地化文件

### Info.plist

关键配置：
- `CFBundleIdentifier`: `com.pdf2png.app`
- `LSMinimumSystemVersion`: `13.0`
- `CFBundleDocumentTypes`: 支持 PDF 文件类型

## 测试

```bash
# 运行所有测试
swift test

# 运行特定测试
swift test --filter PDFConverterTests
```

## 发布流程

1. 更新版本号（`Info.plist` 中的 `CFBundleShortVersionString`）
2. 构建 Release 版本
3. 打包为 .app
4. 压缩为 ZIP
5. 创建 GitHub Release
6. 上传 `PDF2PNG-Swift-macOS.zip`

## 已知问题与注意事项

1. **本地化 Bundle 路径** - 打包后需要从 `Bundle.main` 或 `PDF2PNG_PDF2PNG.bundle` 加载
2. **SPM 目录名** - 编译后可能是小写（`zh-hans.lproj`），需兼容处理
3. **最低 DPI 限制** - 大小限制模式下，绝对最小值为 18 DPI
4. **NSSlider 主题** - 需要显式设置 `NSAppearance` 以支持深色模式

## 版本历史

- **v4.2.0** (2025-12-27) - 修复大小限制算法，DPI 范围显示，重新开始按钮
- **v4.1.0** (2025-12-26) - 双语支持（中/英），深色模式
- **v4.0.0** (2025-12-26) - 首个 Swift 原生版本

查看完整版本历史：[PDF2PNG-Swift/README.md](PDF2PNG-Swift/README.md)
