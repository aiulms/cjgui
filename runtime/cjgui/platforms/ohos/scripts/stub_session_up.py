#!/usr/bin/env python3
"""替身会话使能（第九次复核 §E）：控制通道 STUB_ARM + STUB_SESSION。

必须走 ID 握手（期望码等待**执行**回执）——单槽命令面下「发布≠执行」，
只等 PUBLISHED 会被下一条命令覆盖（实测 ARM 丢失 → backend=None 拒绝）。

用法： stub_session_up.py <token> <generation> [w] [h]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ohos_transport_probe_lib import BoundedExchange, gate_command  # noqa: E402

tok, gen = sys.argv[1], int(sys.argv[2])
w = int(sys.argv[3]) if len(sys.argv) > 3 else 1320
h = int(sys.argv[4]) if len(sys.argv) > 4 else 2856

E = BoundedExchange("127.0.0.1", 17856, "/tmp/stub_session_up_raw.json")
print("STUB_ARM ->", str(gate_command(E, tok, "STUB_ARM", expect_tokens=("stub_arm=0",), timeout=10))[:60])
print("STUB_SESSION ->", str(gate_command(
    E, tok, f"STUB_SESSION {gen} {w} {h}", expect_tokens=("stub_session=0",), timeout=10))[:60])
