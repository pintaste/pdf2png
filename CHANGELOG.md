# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.3.0] - 2026-01-18

### 重大更新 - 完全迁移到 Swift 原生实现

**PDF2PNG 现在是 100% Swift 原生 macOS 应用！**

### Breaking Changes
- 移除 Python 版本 - 不再提供 Python/PyInstaller 打包版本
- 移除跨平台支持（Windows/Linux）- 专注 macOS 原生体验

### Fixed
- 修复本地化显示问题 - 打包后的应用现在能正确显示中英文文本
- 修复 Bundle 加载逻辑，支持从 Bundle.main 和 resource bundle 加载

### Changed
- 彻底清理 Python 相关文件和目录（34 个源文件 + 10 个脚本 + 3 个 spec 文件）
- 完全重写项目文档（README.md, CLAUDE.md）
- 更新 .gitignore 为 Swift/SPM 配置

### Technical Improvements
- 使用 Swift Concurrency（Actor 模型）替代 GCD
- 使用 SwiftUI 替代 PyQt6
- 使用 SPM 替代 pip/PyInstaller
- 应用大小从 55-220 MB 降至 250 KB

---

## [4.2.0] - 2025-12-27

### Fixed
- 修复大小限制算法，确保文件绝不超过限制
- 添加应急 DPI 降档机制（最低 18 DPI）

### Added
- Size Limit 模式显示 DPI 范围（如 `18-150DPI`）
- 任务完成后"重新开始"按钮可用

### Improved
- 优化状态文字颜色饱和度，提升可读性

---

## [4.1.0] - 2025-12-26

### Added
- 双语支持（中文/English）
- 运行时语言切换功能
- 完整的深色模式支持

### Changed
- 使用 LanguageManager 管理本地化
- 优化 UI 主题系统

---

## [4.0.0] - 2025-12-26

### 首个 Swift 原生版本

**重大里程碑：**从 Python 迁移到 Swift 原生实现！

### Added
- Swift + SwiftUI + PDFKit 原生 macOS 应用
- 基于 PDFKit 的 PDF 渲染引擎
- 五步智能 DPI 优化算法
- 批量文件处理支持
- 拖放文件支持

### Performance
- 转换速度提升 55%（普通文档）
- 扫描文档转换速度提升 6-9 倍
- 启动时间 <0.5 秒（vs Python 版本 2-3 秒）
- 应用体积减小 95%（~5MB vs ~80MB）

---

## [3.0.0] - 2025-12-21

### Python 版本（已废弃）

最后一个 Python 版本，基于 PyQt6 和 PyMuPDF。

### Features
- PyQt6 GUI 界面
- PyMuPDF PDF 渲染
- 跨平台支持（Windows/macOS/Linux）
- 批量转换
- 交互模式和命令行模式

---

## 版本对比

| 特性 | v3.0 (Python) | v4.0-4.2 (Swift Hybrid) | v4.3 (Pure Swift) |
|------|---------------|-------------------------|-------------------|
| 平台支持 | Win/Mac/Linux | macOS only | macOS only |
| 应用大小 | 55-220 MB | ~5 MB + Python assets | 250 KB |
| 启动速度 | 2-3 秒 | <0.5 秒 | <0.5 秒 |
| 转换性能 | 基准 | +55% | +55% |
| 深色模式 | 部分 | 完整 | 完整 |
| 语言切换 | 需重启 | 运行时 | 运行时 |
| Python 依赖 | 是 | 否 | 否 |

---

## 链接

- [GitHub Releases](https://github.com/pintaste/pdf2png/releases)
- [Issue Tracker](https://github.com/pintaste/pdf2png/issues)
