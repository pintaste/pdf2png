#!/usr/bin/env python3
"""
转换历史记录管理器

功能：
- 记录每次转换历史
- 持久化存储
- 收藏管理
- 历史查询和删除
"""

import json
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional


class ConversionHistory:
    """转换历史记录"""

    def __init__(self, file_path: str, params: Dict, timestamp: str = None,
                 output_files: List[str] = None, status: str = "success",
                 favorite: bool = False):
        """
        初始化历史记录

        Args:
            file_path: PDF文件路径
            params: 转换参数
            timestamp: 时间戳
            output_files: 输出文件列表
            status: 状态（success/failed）
            favorite: 是否收藏
        """
        self.file_path = file_path
        self.file_name = Path(file_path).name
        self.params = params.copy()
        self.timestamp = timestamp or datetime.now().isoformat()
        self.output_files = output_files or []
        self.status = status
        self.favorite = favorite

    def to_dict(self) -> Dict:
        """转换为字典"""
        return {
            'file_path': self.file_path,
            'file_name': self.file_name,
            'params': self.params,
            'timestamp': self.timestamp,
            'output_files': self.output_files,
            'status': self.status,
            'favorite': self.favorite
        }

    @classmethod
    def from_dict(cls, data: Dict) -> 'ConversionHistory':
        """从字典创建"""
        return cls(
            file_path=data['file_path'],
            params=data['params'],
            timestamp=data.get('timestamp'),
            output_files=data.get('output_files', []),
            status=data.get('status', 'success'),
            favorite=data.get('favorite', False)
        )


class HistoryManager:
    """历史记录管理器"""

    def __init__(self, history_file: Optional[Path] = None):
        """
        初始化管理器

        Args:
            history_file: 历史文件路径，默认为 ~/.pdf2png/history.json
        """
        if history_file is None:
            history_dir = Path.home() / ".pdf2png"
            history_dir.mkdir(parents=True, exist_ok=True)
            history_file = history_dir / "history.json"

        self.history_file = history_file
        self.histories: List[ConversionHistory] = []
        self._load()

    def _load(self):
        """加载历史记录"""
        if not self.history_file.exists():
            return

        try:
            with open(self.history_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.histories = [
                    ConversionHistory.from_dict(item)
                    for item in data
                ]
        except Exception:
            self.histories = []

    def _save(self):
        """保存历史记录"""
        try:
            with open(self.history_file, 'w', encoding='utf-8') as f:
                data = [h.to_dict() for h in self.histories]
                json.dump(data, f, ensure_ascii=False, indent=2)
        except Exception:
            pass  # 静默处理保存失败

    def add(self, file_path: str, params: Dict, output_files: List[str], status: str = "success"):
        """
        添加历史记录

        Args:
            file_path: PDF文件路径
            params: 转换参数
            output_files: 输出文件列表
            status: 状态
        """
        history = ConversionHistory(
            file_path=file_path,
            params=params,
            output_files=output_files,
            status=status
        )
        self.histories.insert(0, history)  # 最新的在前面

        # 限制历史记录数量（保留最近100条）
        if len(self.histories) > 100:
            # 保留收藏的记录
            favorites = [h for h in self.histories if h.favorite]
            recent = [h for h in self.histories if not h.favorite][:100]
            self.histories = recent + favorites

        self._save()

    def get_all(self) -> List[ConversionHistory]:
        """获取所有历史记录"""
        return self.histories.copy()

    def get_recent(self, limit: int = 10) -> List[ConversionHistory]:
        """
        获取最近的历史记录

        Args:
            limit: 数量限制

        Returns:
            历史记录列表
        """
        return self.histories[:limit]

    def get_favorites(self) -> List[ConversionHistory]:
        """获取收藏的历史记录"""
        return [h for h in self.histories if h.favorite]

    def toggle_favorite(self, timestamp: str) -> bool:
        """
        切换收藏状态

        Args:
            timestamp: 时间戳

        Returns:
            新的收藏状态
        """
        for history in self.histories:
            if history.timestamp == timestamp:
                history.favorite = not history.favorite
                self._save()
                return history.favorite
        return False

    def remove(self, timestamp: str):
        """
        删除历史记录

        Args:
            timestamp: 时间戳
        """
        self.histories = [
            h for h in self.histories
            if h.timestamp != timestamp
        ]
        self._save()

    def clear_all(self, keep_favorites: bool = True):
        """
        清空所有历史记录

        Args:
            keep_favorites: 是否保留收藏
        """
        if keep_favorites:
            self.histories = [h for h in self.histories if h.favorite]
        else:
            self.histories = []
        self._save()

    def search(self, keyword: str) -> List[ConversionHistory]:
        """
        搜索历史记录

        Args:
            keyword: 关键词（搜索文件名）

        Returns:
            匹配的历史记录
        """
        keyword = keyword.lower()
        return [
            h for h in self.histories
            if keyword in h.file_name.lower()
        ]
