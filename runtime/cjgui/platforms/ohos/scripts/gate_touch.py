#!/usr/bin/env python3
"""测试通道触摸注入（down+up，走 ID 握手）。

替身会话档下真实 uitest 点击不达 XComponent（真实 window 未获渲染准入），
字段聚焦/失焦必须经测试通道注入；ArkUI 代理与页面按钮仍用真实 uitest。
用法： gate_touch.py <token> <x> <y>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ohos_transport_probe_lib import BoundedExchange, gate_command  # noqa: E402

tok, x, y = sys.argv[1], sys.argv[2], sys.argv[3]
E = BoundedExchange("127.0.0.1", 17856, "/tmp/gate_touch_raw.json")
gate_command(E, tok, f"TOUCH_0_{x}_{y}", timeout=8)
gate_command(E, tok, f"TOUCH_1_{x}_{y}", timeout=8)
print("touch ok", x, y)
