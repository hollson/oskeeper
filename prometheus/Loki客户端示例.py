#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import time
import json
from typing import List, Dict, Optional

class LokiClient:
    """基于 requests 的 Loki 原生客户端（使用 /loki/api/v1/query_range）"""

    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.query_range_url = f"{self.base_url}/loki/api/v1/query"

    def query(self, logql: str, start_ns: int, end_ns: int, limit: int = 1000, direction: str = 'BACKWARD') -> List[Dict]:
        """
        使用 Loki API 查询指定时间范围内的日志

        Args:
            logql (str): Loki 查询语言语句，用于指定查询条件
            start_ns (int): 查询的开始时间，单位是纳秒
            end_ns (int): 查询的结束时间，单位是纳秒
            limit (int, optional): 返回的最大日志条数，默认是 1000
            direction (str, optional): 查询方向，'BACKWARD' 表示从最新到最旧，默认是 'BACKWARD'

        Returns:
            List[Dict]: 包含日志条目的列表，每个日志条目是一个字典，包含以下字段：
                - timestamp: 日志时间戳（纳秒）
                - line: 日志内容
                - labels: 日志的标签信息
        """

        params = {
            'query': logql,
            'start': str(start_ns),
            'end': str(end_ns),
            'limit': str(limit),
            'direction': direction
        }
        try:
            resp = requests.get(self.query_range_url, params=params, timeout=30)
            resp.raise_for_status()
            data = resp.json()
            return self._parse_loki_response(data)
        except requests.RequestException as e:
            print(f"Loki 查询失败: {e}")
            if 'resp' in locals():
                print(f"响应状态码: {resp.status_code}, 内容: {resp.text[:200]}")
            return []

    @staticmethod
    def _parse_loki_response(data: Dict) -> List[Dict]:
        results = []
        streams = data.get('data', {}).get('result', [])
        for stream in streams:
            labels = stream.get('stream', {})
            values = stream.get('values', [])
            for ts_str, line in values:
                results.append({
                    'timestamp': int(ts_str),
                    'line': line,
                    'labels': labels.copy()
                })
        return results
    
    @staticmethod
    def minutes_ago(minutes: float = 0) -> int:
        """返回当前时间往前推 minutes_ago 分钟的纳秒时间戳"""
        return int((time.time() - minutes * 60) * 1e9)    


if __name__ == "__main__":
    client = LokiClient("http://stride-107:3100")
    
    print("==================================== 测试用例1：查询n分钟内日志, 展示top3原始内容 ====================================")
    logql = '{service_name=~".+"} | json | __error__=""'
    result = client.query(logql, client.minutes_ago(5),client.minutes_ago(0),  limit=200)
    print(f"🚀 共获取 {len(result)} 条日志\n")
    
    print(f"😊 原始格式输出：")
    for i, log in enumerate(result[:3], 1):
        print(f"{i}. {log['line']}")
    
    
    print(f"\n😊 格式化输出：\n")
    print(f"{'id':<6} {'time':<26} {'app':<20} {'pid':<10} {'host':<25} {'level':<10} {'msg'}")
    for i, log in enumerate(result[:3], 1):
        try:
            data = json.loads(log['line'])
            ts_ns = log['timestamp']
            ts_sec = ts_ns / 1e9
            time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(ts_sec))
            
            attrs = data.get('attributes', {})
            app = attrs.get('appname', '')
            pid = attrs.get('proc_id', '')
            host = attrs.get('hostname', '')
            level = data.get('severity', '')
            if not level:
                pri = attrs.get('priority')
                level_map = {10: 'crit', 12: 'warning', 8: 'debug'}
                level = level_map.get(pri, 'unknown')
            raw_msg = attrs.get('message', '')
            if ']' in raw_msg:
                msg = raw_msg.rsplit(']', 1)[-1].strip()
            else:
                msg = raw_msg
            print(f"{i:<6} {time_str:<26} {app:<20} {pid:<10} {host:<25} {level:<10} {msg}")
        except Exception as e:
            print(f"{i}. 解析失败: {e}")
    
    
    print("\n\n========================================== 测试用例2：仅查询警告/错误日志 ===========================================")
    logql = '''{service_name=~".+"} | json | line_format "{{.body}}" |~ "(?i)(error|warn|fatal)"'''
    # logql = '''{service_name=~".+"} | json | line_format "{{.body}}" |~ "(?i)(error|fatal)"'''
    result = client.query(logql, client.minutes_ago(5),client.minutes_ago(0), limit=200)
    print(f"匹配到 {len(result)} 条错误/警告日志")
    for i, log in enumerate(result[:3], 1):
        print(f"{i}. {log['line']}")

    print("\n\n============================================= 测试用例3：按关键字查询 ==============================================")
    keyword_logql = '''{service_name=~".+"} | json | line_format "{{.body}}" |~ "down"'''
    logs_keyword = client.query(keyword_logql, client.minutes_ago(5),client.minutes_ago(0), limit=50)
    print(f"匹配到 {len(logs_keyword)} 条包含 'down' 的日志")
    for i, log in enumerate(logs_keyword[:3], 1):
        print(f"{i}. {log['line']}")
    

    print("\n\n============================================ 测试用例4：按应用名称查询 ==============================================")
    # 使用原始字符串，双引号内转义双引号
    program_logql = r'''{service_name=~".+"} | json | line_format "{{.body}}" |~ "program=\"stride_monitor\""'''
    logs_program = client.query(program_logql, client.minutes_ago(5), client.minutes_ago(0), limit=50)
    print(f"匹配到 {len(logs_program)} 条 program=stride_monitor 的日志")
    for i, log in enumerate(logs_program[:3], 1):
        print(f"{i}. {log['line']}")