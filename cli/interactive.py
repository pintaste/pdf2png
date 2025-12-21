#!/usr/bin/env python3
"""
交互式命令行界面模块

提供用户友好的菜单驱动交互体验
遵循 SRP 原则：仅处理交互式用户界面
"""
import os
import sys
import glob
from typing import Optional, Tuple, Dict, List, Callable, Any

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from converter import PDFConverter, ConversionError, format_file_size
from constants import DPIConfig, SizeConfig, ConverterConfig


# ============================================================================
# UI 辅助函数
# ============================================================================

def print_header(title: str, width: int = 70) -> None:
    """打印标题头"""
    print("=" * width)
    print(title.center(width))
    print("=" * width)


def print_welcome() -> None:
    """打印欢迎信息"""
    print_header("欢迎使用 PDF 转 PNG 高清转换工具 - 交互模式")
    print()


def get_input(
    prompt: str,
    default: Optional[str] = None,
    validation_func: Optional[Callable[[str], Tuple[bool, Any]]] = None
) -> Any:
    """
    获取用户输入并验证

    Args:
        prompt: 提示信息
        default: 默认值
        validation_func: 验证函数，返回 (is_valid, result_or_error_msg)

    Returns:
        验证后的输入值
    """
    while True:
        if default:
            user_input = input(f"{prompt} [默认: {default}]: ").strip()
            if not user_input:
                return default
        else:
            user_input = input(f"{prompt}: ").strip()
            if not user_input:
                print("❌ 输入不能为空，请重新输入")
                continue

        if validation_func:
            valid, result = validation_func(user_input)
            if valid:
                return result
            else:
                print(f"❌ {result}")
        else:
            return user_input


# ============================================================================
# 验证函数
# ============================================================================

def validate_positive_number(s: str) -> Tuple[bool, Any]:
    """验证正数"""
    try:
        val = float(s)
        if val > 0:
            return True, val
        return False, "必须大于 0"
    except ValueError:
        return False, "请输入有效的数字"


def validate_dpi(s: str) -> Tuple[bool, Any]:
    """验证 DPI 值"""
    try:
        val = int(s)
        if DPIConfig.validate(val):
            return True, val
        return False, f"DPI 范围应在 {DPIConfig.MIN_DPI}-{DPIConfig.MAX_DPI} 之间"
    except ValueError:
        return False, "请输入有效的整数"


# ============================================================================
# 文件扫描和选择
# ============================================================================

def scan_and_display_pdf_files() -> List[str]:
    """扫描并显示当前目录的 PDF 文件"""
    pdf_files = sorted(glob.glob("*.pdf"))

    if pdf_files:
        print(f"📂 在当前目录发现 {len(pdf_files)} 个 PDF 文件:")
        for i, f in enumerate(pdf_files, 1):
            file_size = os.path.getsize(f)
            size_str = format_file_size(file_size)
            print(f"  {i}. {f} ({size_str})")
        print()
    else:
        print("📂 当前目录没有发现 PDF 文件")
        print()

    return pdf_files


def select_single_file(pdf_files: List[str]) -> str:
    """选择单个 PDF 文件"""
    print()
    if pdf_files:
        print("请选择 PDF 文件:")
        print("  0. 手动输入文件路径")
        for i, f in enumerate(pdf_files, 1):
            print(f"  {i}. {f}")

        def validate_choice(choice):
            try:
                idx = int(choice)
                if idx == 0:
                    return True, 0
                elif 1 <= idx <= len(pdf_files):
                    return True, pdf_files[idx - 1]
                else:
                    return False, f"请输入 0-{len(pdf_files)} 之间的数字"
            except ValueError:
                return False, "请输入有效的数字"

        pdf_file = get_input(
            f"\n请输入选项 (0-{len(pdf_files)})",
            validation_func=validate_choice
        )

        if pdf_file == 0:
            pdf_file = get_input("请输入 PDF 文件路径")
    else:
        pdf_file = get_input("请输入 PDF 文件路径")

    return pdf_file


# ============================================================================
# 模式选择和配置
# ============================================================================

def select_conversion_mode() -> str:
    """
    选择转换模式

    Returns:
        模式字符串: '1', '2', '3', '4'
    """
    while True:
        print("🎯 请选择操作模式:")
        print("  1. 快速转换（推荐，5MB以内高清）")
        print("  2. 极致质量（不限大小，最高清晰度）")
        print("  3. 自定义设置（高级用户）")
        print("  4. 批量转换（转换多个文件）")
        print("  5. 退出")
        print()

        choice = input("请输入选项 (1-5): ").strip()

        if choice == '5':
            print("\n👋 感谢使用，再见!")
            sys.exit(0)
        elif choice in ['1', '2', '3', '4']:
            return choice
        else:
            print("❌ 无效选项，请重新选择\n")


def configure_quick_mode() -> Dict:
    """配置快速转换模式"""
    print(f"\n⚙️  使用快速转换模式（文件大小 ≤ {SizeConfig.DEFAULT_SIZE_MB}MB，自动优化清晰度）")
    return {
        'max_size_mb': float(SizeConfig.DEFAULT_SIZE_MB),
        'min_dpi': ConverterConfig.DEFAULT_MIN_DPI,
        'max_dpi': ConverterConfig.DEFAULT_MAX_DPI,
        'quality_first': False
    }


def configure_quality_mode() -> Dict:
    """配置极致质量模式"""
    print(f"\n⚙️  使用极致质量模式（不限制文件大小）")

    dpi_presets = {
        '1': (600, "高清 (600 DPI) - 适合大多数场景"),
        '2': (800, "超清 (800 DPI) - 适合打印"),
        '3': (1200, "极致 (1200 DPI) - 专业印刷"),
    }

    print("\n选择清晰度:")
    for key, (dpi, desc) in dpi_presets.items():
        print(f"  {key}. {desc}")

    dpi_choice = input("请选择 (1-3) [默认: 1]: ").strip() or '1'
    max_dpi = dpi_presets.get(dpi_choice, (600, ""))[0]

    return {
        'max_size_mb': 100.0,
        'min_dpi': max_dpi,
        'max_dpi': max_dpi,
        'quality_first': True
    }


def configure_custom_mode() -> Dict:
    """配置自定义模式"""
    print(f"\n⚙️  自定义设置")

    max_size = get_input(
        "\n文件大小限制 (MB)",
        str(SizeConfig.DEFAULT_SIZE_MB),
        validate_positive_number
    )

    quality_mode = input(
        "是否启用质量优先模式（忽略大小限制）? (y/n) [默认: n]: "
    ).strip().lower()
    quality_first = quality_mode == 'y'

    max_dpi = get_input(
        "最高 DPI",
        str(ConverterConfig.DEFAULT_MAX_DPI),
        validate_dpi
    )
    min_dpi = get_input(
        "最低 DPI",
        str(ConverterConfig.DEFAULT_MIN_DPI),
        validate_dpi
    )

    if max_dpi < min_dpi:
        print("⚠️  最高 DPI 小于最低 DPI，已自动交换")
        max_dpi, min_dpi = min_dpi, max_dpi

    return {
        'max_size_mb': max_size,
        'min_dpi': min_dpi,
        'max_dpi': max_dpi,
        'quality_first': quality_first
    }


def configure_batch_mode(pdf_files: List[str]) -> Tuple[str, Optional[str]]:
    """
    配置批量转换模式

    Returns:
        (pattern, output_dir)
    """
    print_header("批量转换模式")
    print()

    if pdf_files:
        print("选项:")
        print("  1. 转换当前目录所有 PDF 文件")
        print("  2. 手动输入文件名模式（如: report_*.pdf）")
        batch_choice = input("\n请选择 (1-2): ").strip()

        if batch_choice == '1':
            pattern = "*.pdf"
        else:
            pattern = get_input(
                "请输入文件名模式（如 *.pdf 或 report_*.pdf）",
                "*.pdf"
            )
    else:
        pattern = get_input("请输入 PDF 文件路径或模式", "*.pdf")

    use_output_dir = input(
        "\n是否将结果输出到单独的文件夹? (y/n) [默认: n]: "
    ).strip().lower()

    if use_output_dir == 'y':
        output_dir = get_input("请输入输出文件夹名称", "png_output")
    else:
        output_dir = None

    return pattern, output_dir


# ============================================================================
# 确认和执行
# ============================================================================

def confirm_parameters(
    mode: str,
    pdf_file: Optional[str],
    output_file: Optional[str],
    pattern: Optional[str],
    output_dir: Optional[str],
    params: Dict
) -> bool:
    """
    确认转换参数

    Returns:
        True 继续，False 取消
    """
    print_header("转换参数确认")

    if mode == '4':
        print(f"📁 转换模式: 批量转换")
        print(f"📄 文件模式: {pattern}")
        print(f"📂 输出目录: {output_dir if output_dir else '原文件所在目录'}")
    else:
        print(f"📁 转换模式: 单文件")
        print(f"📄 输入文件: {pdf_file}")
        print(f"📝 输出文件: {output_file if output_file else '自动命名'}")

    if params['quality_first']:
        print(f"🎨 质量模式: 优先质量（不限制文件大小）")
        print(f"📊 DPI 设置: {params['max_dpi']}")
    else:
        print(f"📦 大小限制: ≤ {params['max_size_mb']} MB")
        print(f"📊 DPI 范围: {params['min_dpi']} - {params['max_dpi']}")

    print("=" * 70)

    confirm = input("\n确认开始转换? (y/n) [默认: y]: ").strip().lower()
    return not confirm or confirm == 'y'


def execute_conversion(
    mode: str,
    pdf_file: Optional[str],
    output_file: Optional[str],
    pattern: Optional[str],
    output_dir: Optional[str],
    params: Dict
) -> int:
    """
    执行转换

    Returns:
        退出码
    """
    print_header("开始转换...")
    print()

    try:
        converter = PDFConverter()

        if mode == '4':
            # 批量转换
            files = converter.batch_convert(
                pattern,
                output_dir=output_dir,
                batch_progress_callback=print,
                **params
            )
            print(f"\n✅ 批量转换完成! 共生成 {len(files)} 个文件")
        else:
            # 单文件转换
            result = converter.convert(pdf_file, output_file, **params)
            files = result.get('files', [])

            if files:
                print(f"\n✅ 转换完成!")
                for f in files:
                    file_size = os.path.getsize(f)
                    size_str = format_file_size(file_size)
                    print(f"   📁 {f} ({size_str})")
            else:
                print("\n❌ 转换失败")
                return 1

    except KeyboardInterrupt:
        print("\n\n⚠️  用户中断转换")
        return 1
    except ConversionError as e:
        print(f"\n❌ 转换错误: {e}")
        return 1
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        return 1

    print_header("✨ 全部完成!")
    return 0


# ============================================================================
# 主函数
# ============================================================================

def interactive_mode() -> int:
    """交互式模式主流程"""
    print_welcome()

    # 扫描 PDF 文件
    pdf_files = scan_and_display_pdf_files()

    # 选择转换模式
    mode = select_conversion_mode()

    # 根据模式配置参数
    if mode == '1':
        params = configure_quick_mode()
    elif mode == '2':
        params = configure_quality_mode()
    elif mode == '3':
        params = configure_custom_mode()
    else:  # mode == '4'
        params = configure_custom_mode() if input(
            "\n使用自定义设置? (y/n) [默认: n]: "
        ).strip().lower() == 'y' else configure_quick_mode()

    # 选择文件
    if mode == '4':
        # 批量模式
        pattern, output_dir = configure_batch_mode(pdf_files)
        pdf_file = None
        output_file = None
    else:
        # 单文件模式
        pdf_file = select_single_file(pdf_files)
        pattern = None
        output_dir = None

        # 输出文件名
        custom_output = input(
            "\n是否自定义输出文件名? (y/n) [默认: n]: "
        ).strip().lower()
        if custom_output == 'y':
            output_file = get_input("请输入输出文件名（如 output.png）")
        else:
            output_file = None

    # 确认参数
    if not confirm_parameters(
        mode, pdf_file, output_file, pattern, output_dir, params
    ):
        print("❌ 已取消转换")
        return 0

    # 执行转换
    return execute_conversion(
        mode, pdf_file, output_file, pattern, output_dir, params
    )


if __name__ == "__main__":
    sys.exit(interactive_mode())
