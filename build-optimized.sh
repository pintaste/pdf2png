#!/bin/bash
# PDF2PNG 优化打包脚本

set -e  # 遇到错误立即退出

echo "🚀 PDF2PNG v3.0 优化打包脚本"
echo "================================"
echo ""

# 检查依赖
echo "📋 检查依赖..."

if ! command -v pyinstaller &> /dev/null; then
    echo "❌ PyInstaller 未安装"
    echo "   安装: pip install pyinstaller"
    exit 1
fi

echo "✅ PyInstaller 已安装"

# 可选：检查UPX
if command -v upx &> /dev/null; then
    echo "✅ UPX 已安装（将启用额外压缩）"
    UPX_AVAILABLE=true
else
    echo "⚠️  UPX 未安装（跳过UPX压缩）"
    echo "   可选安装: brew install upx"
    UPX_AVAILABLE=false
fi

echo ""
echo "🧹 清理旧构建..."
rm -rf build dist

echo ""
echo "📦 开始打包..."
echo "   配置文件: build-optimized.spec"
echo "   输出目录: dist/"
echo ""

# 执行打包
pyinstaller build-optimized.spec

# 检查结果
if [ -d "dist/PDF2PNG.app" ]; then
    echo ""
    echo "✅ 打包成功！"
    echo ""
    echo "📊 体积统计:"
    echo "================================"

    # 计算App大小
    APP_SIZE=$(du -sh dist/PDF2PNG.app | cut -f1)
    echo "   应用体积: $APP_SIZE"

    # 如果有UPX，显示压缩信息
    if [ "$UPX_AVAILABLE" = true ]; then
        echo "   ✅ UPX压缩已启用"
    else
        echo "   ⚠️  UPX压缩未启用（可进一步减小30%）"
    fi

    echo ""
    echo "📂 输出位置:"
    echo "   dist/PDF2PNG.app"
    echo ""
    echo "🎉 完成！可以在 Finder 中打开 dist/ 文件夹查看"

    # 打开dist目录
    open dist/

else
    echo ""
    echo "❌ 打包失败"
    exit 1
fi
