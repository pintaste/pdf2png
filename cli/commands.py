#!/usr/bin/env python3
"""
命令行参数模式模块

处理 argparse 命令行参数解析和执行
遵循 SRP 原则：仅处理命令行参数模式
"""
import argparse
import os
import sys

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from converter import (
    PDFConverter,
    ConversionError,
    validate_dpi_range
)
from constants import DPIConfig, SizeConfig, ConverterConfig
from cli.interactive import interactive_mode


def create_parser() -> argparse.ArgumentParser:
    """创建命令行参数解析器"""
    parser = argparse.ArgumentParser(
        description='PDF 转 PNG 高清转换工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
示例用法:
  # 交互模式（推荐新手）
  %(prog)s -i
  %(prog)s

  # 基本转换
  %(prog)s input.pdf

  # 指定输出文件
  %(prog)s input.pdf -o output.png

  # 设置最大文件大小为 10MB
  %(prog)s input.pdf -s 10

  # 优先质量模式（不限制文件大小）
  %(prog)s input.pdf -q

  # 自定义 DPI 范围
  %(prog)s input.pdf --min-dpi 200 --max-dpi 800

  # 批量转换当前目录所有 PDF
  %(prog)s "*.pdf" -b

  # 批量转换并输出到指定目录
  %(prog)s "*.pdf" -b -d output_folder

配置说明:
  DPI 范围: {DPIConfig.MIN_DPI} - {DPIConfig.MAX_DPI}
  默认大小限制: {SizeConfig.DEFAULT_SIZE_MB} MB
        """)

    parser.add_argument(
        'input', nargs='?',
        help='输入 PDF 文件路径（支持通配符，如 *.pdf）'
    )
    parser.add_argument(
        '-i', '--interactive', action='store_true',
        help='启动交互模式（适合新手，提供友好的引导界面）'
    )
    parser.add_argument(
        '-o', '--output',
        help='输出 PNG 文件路径（默认为同名 .png）'
    )
    parser.add_argument(
        '-s', '--max-size', type=float,
        default=SizeConfig.DEFAULT_SIZE_MB,
        help=f'最大文件大小（MB，默认: {SizeConfig.DEFAULT_SIZE_MB}）'
    )
    parser.add_argument(
        '-q', '--quality-first', action='store_true',
        help='优先质量模式（使用最高 DPI，忽略文件大小限制）'
    )
    parser.add_argument(
        '--min-dpi', type=int,
        default=ConverterConfig.DEFAULT_MIN_DPI,
        help=f'最低 DPI（默认: {ConverterConfig.DEFAULT_MIN_DPI}）'
    )
    parser.add_argument(
        '--max-dpi', type=int,
        default=ConverterConfig.DEFAULT_MAX_DPI,
        help=f'最高 DPI（默认: {ConverterConfig.DEFAULT_MAX_DPI}）'
    )
    parser.add_argument(
        '-b', '--batch', action='store_true',
        help='批量模式（支持通配符）'
    )
    parser.add_argument(
        '-d', '--output-dir',
        help='批量转换时的输出目录'
    )

    return parser


def validate_args(args: argparse.Namespace) -> bool:
    """
    验证命令行参数

    Returns:
        True 如果参数有效，否则打印错误并返回 False
    """
    if not validate_dpi_range(args.min_dpi, args.max_dpi):
        print(
            f"❌ 错误: DPI 范围无效（应在 {DPIConfig.MIN_DPI}-{DPIConfig.MAX_DPI} 之间，"
            f"且 min <= max）"
        )
        return False

    if args.max_size <= 0:
        print("❌ 错误: max-size 必须大于 0")
        return False

    return True


def print_banner() -> None:
    """打印程序横幅"""
    print("=" * 60)
    print("PDF 转 PNG 高清转换工具".center(60))
    print("=" * 60)
    print()


def run_single_convert(args: argparse.Namespace) -> int:
    """
    执行单文件转换

    Returns:
        退出码
    """
    if '*' in args.input or '?' in args.input:
        print("❌ 错误: 检测到通配符，请使用 -b/--batch 参数启用批量模式")
        return 1

    try:
        converter = PDFConverter()
        result = converter.convert(
            args.input,
            args.output,
            max_size_mb=args.max_size,
            min_dpi=args.min_dpi,
            max_dpi=args.max_dpi,
            quality_first=args.quality_first
        )

        files = result.get('files', [])
        if files:
            print(f"\n✅ 转换完成!")
            for f in files:
                print(f"   📁 {f}")
            return 0
        else:
            return 1

    except ConversionError as e:
        print(f"\n❌ 转换错误: {e}")
        return 1
    except FileNotFoundError as e:
        print(f"\n❌ {e}")
        return 1
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        return 1


def run_batch_convert(args: argparse.Namespace) -> int:
    """
    执行批量转换

    Returns:
        退出码
    """
    try:
        converter = PDFConverter()
        files = converter.batch_convert(
            args.input,
            output_dir=args.output_dir,
            batch_progress_callback=print,
            max_size_mb=args.max_size,
            min_dpi=args.min_dpi,
            max_dpi=args.max_dpi,
            quality_first=args.quality_first
        )
        print(f"\n✅ 批量转换完成! 共生成 {len(files)} 个文件")
        return 0

    except FileNotFoundError as e:
        print(f"\n❌ {e}")
        return 1
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        return 1


def main() -> int:
    """命令行模式主函数"""
    parser = create_parser()
    args = parser.parse_args()

    # 如果没有输入文件且没有指定交互模式，自动进入交互模式
    if not args.input and not args.interactive:
        return interactive_mode()

    # 如果指定了交互模式
    if args.interactive:
        return interactive_mode()

    # 验证参数
    if not validate_args(args):
        return 1

    print_banner()

    # 批量模式或单文件模式
    if args.batch:
        return run_batch_convert(args)
    else:
        return run_single_convert(args)


if __name__ == "__main__":
    sys.exit(main())
