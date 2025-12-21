#!/usr/bin/env python3
"""
PDF2PNG PyQt6 GUI 入口

v3.0 - 极简主义设计，专业级PDF转PNG工具
"""

import sys
import os

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gui_pyqt.main_window import main

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n用户中断")
        sys.exit(0)
    except Exception as e:
        print(f"启动失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
