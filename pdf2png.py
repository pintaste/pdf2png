#!/usr/bin/env python3
"""
PDF 转 PNG 命令行工具入口

支持交互模式和命令行参数模式
重构后：将实现逻辑分离到 cli 模块
"""
import sys
from cli.commands import main


if __name__ == "__main__":
    sys.exit(main())
