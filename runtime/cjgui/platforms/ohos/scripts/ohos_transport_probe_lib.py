#!/usr/bin/env python3
"""传输探针共享库（第五次复核 B.4）。

- 独立且严格的控制帧解析器：协议行、KIND、OP、END、键值格式、重复字段、
  空值全部校验；ERROR 帧不产生任何成功键。
- 严格业务终态解析：PROTOCOL/KIND/APPLIED/VERSION 显式校验。
- 全部 I/O 用绝对单调 deadline + 有界读取；禁止无界等。
- 原始请求/回包归档助手：随 run 归档，不只存布尔结论。
- 拒绝证据分类：EOF/reset/refused 才是「被拒」；超时一律记失败。
"""

import json
import socket
import time

CONTROL_PROTOCOL = "CONTROL CJGUI_VERIFY/1"
BUSINESS_PROTOCOL = "CJGUI_SHARED_OPERATION/2"


class FrameError(ValueError):
    pass


def parse_control_frame_strict(body: str) -> dict:
    """严格解析 verify 控制帧。

    合法形态（逐行校验，不做子串搜索）：
      CONTROL CJGUI_VERIFY/1
      KIND OK|ERROR
      OP <op>                      (KIND=OK 时必需)
      KEY VALUE ...                (0..n 行；KEY 全大写 [A-Z0-9_]，VALUE 非空)
      ERROR <reason>               (KIND=ERROR 时必需，且不得有其他键)
      END
    任何违反（首行不符、缺 END、重复键、空值、KIND=ERROR 携带额外键）
    都抛 FrameError。ERROR 帧绝不提供成功键。
    """
    if not isinstance(body, str):
        raise FrameError("回包不是文本")
    lines = body.split("\n")
    while lines and lines[-1] == "":
        lines.pop()
    if len(lines) < 3:
        raise FrameError(f"行数不足: {lines!r}")
    if lines[0] != CONTROL_PROTOCOL:
        raise FrameError(f"协议行不符: {lines[0]!r}")
    if lines[-1] != "END":
        raise FrameError(f"缺 END: {lines[-1]!r}")
    out = {}
    kind_parts = lines[1].split(" ", 1)
    if len(kind_parts) != 2 or kind_parts[0] != "KIND" or not kind_parts[1]:
        raise FrameError(f"KIND 行非法: {lines[1]!r}")
    out["KIND"] = kind_parts[1]
    is_error = kind_parts[1] == "ERROR"
    for line in lines[2:-1]:
        parts = line.split(" ", 1)
        if len(parts) != 2 or not parts[0] or not parts[1]:
            raise FrameError(f"键值行非法: {line!r}")
        key = parts[0]
        if not key.replace("_", "").isalnum() or not key.isupper():
            raise FrameError(f"键名非法: {key!r}")
        if key in out:
            raise FrameError(f"重复键: {key}")
        out[key] = parts[1]
    if is_error:
        if "ERROR" not in out:
            raise FrameError("ERROR 帧缺 ERROR 原因")
        allowed = {"KIND", "OP", "ERROR"}
        extra = set(out) - allowed
        if extra:
            raise FrameError(f"ERROR 帧携带非法键: {sorted(extra)}（错误帧不得提供成功键）")
        out.pop("OP", None)   # ERROR 帧的 OP 即使存在也不作为成功凭据
    else:
        if "OP" not in out:
            raise FrameError("OK 帧缺 OP")
    return out


def parse_business_terminal_strict(body: str) -> dict:
    """严格解析业务终态回包（实测真实词表）：

      PROTOCOL CJGUI_SHARED_OPERATION/2
      KIND SNAPSHOT|RESULT|ERROR
      RESULT:    APPLIED true|false / CONFLICT true|false / VERSION_AFTER <int> 必需
      ERROR:     恰好一行 ERROR <reason>
    返回 dict：KIND、APPLIED、VERSION_BEFORE/AFTER、RAW。
    """
    if not isinstance(body, str) or not body:
        raise FrameError("业务回包为空")
    lines = body.split("\n")
    if not lines or not lines[0].startswith("PROTOCOL "):
        raise FrameError(f"业务协议行缺失: {lines[0]!r}")
    if lines[0].split(" ", 1)[1] != BUSINESS_PROTOCOL:
        raise FrameError(f"业务协议版本不符: {lines[0]!r}")
    kinds = [ln for ln in lines if ln.startswith("KIND ")]
    if len(kinds) != 1:
        raise FrameError(f"KIND 行缺失或不唯一: {kinds!r}")
    kind = kinds[0].split(" ", 1)[1]
    if kind not in ("SNAPSHOT", "RESULT", "ERROR"):
        raise FrameError(f"KIND 值非法: {kind!r}")

    def single_value(key: str):
        vals = [ln.split(" ", 1)[1] for ln in lines
                if ln.startswith(key + " ")]
        if len(vals) > 1:
            raise FrameError(f"{key} 行不唯一")
        return vals[0] if vals else None

    out = {"KIND": kind, "APPLIED": None, "VERSION_BEFORE": None,
           "VERSION_AFTER": None, "RAW": body}
    if kind == "RESULT":
        applied = single_value("APPLIED")
        if applied not in ("true", "false"):
            raise FrameError(f"RESULT 缺合法 APPLIED: {applied!r}")
        conflict = single_value("CONFLICT")
        if conflict not in ("true", "false"):
            raise FrameError(f"RESULT 缺合法 CONFLICT: {conflict!r}")
        after = single_value("VERSION_AFTER")
        if after is None or not after.isdigit():
            raise FrameError(f"RESULT 缺合法 VERSION_AFTER: {after!r}")
        out["APPLIED"] = applied
        out["CONFLICT"] = conflict
        out["VERSION_AFTER"] = int(after)
        vb = single_value("VERSION_BEFORE")
        if vb is not None and vb.isdigit():
            out["VERSION_BEFORE"] = int(vb)
    errors = [ln for ln in lines if ln.startswith("ERROR ")]
    if kind == "ERROR" and len(errors) != 1:
        raise FrameError("KIND ERROR 缺唯一 ERROR 行")
    if kind in ("SNAPSHOT", "RESULT") and errors:
        raise FrameError(f"KIND {kind} 不得携带 ERROR 行")
    return out


def classify_failure(exc: BaseException) -> str:
    """拒绝证据分类（B.1）：只有 EOF/reset/refused 算「被拒」。

    超时（socket.timeout/TimeoutError）只说明本侧没等到应答，不能推导
    「连接被拒」——一律返回 "timeout" 供调用方记失败。
    """
    if isinstance(exc, (socket.timeout, TimeoutError)):
        return "timeout"
    return type(exc).__name__


class BoundedExchange:
    """带绝对单调 deadline 与原始帧归档的帧交换。"""

    def __init__(self, host: str, port: int, archive_path: str = ""):
        self.host = host
        self.port = port
        self.archive_path = archive_path
        self.raw_log = []

    def _archive(self, direction: str, text: str):
        entry = {"t": time.time(), "dir": direction, "raw": text}
        self.raw_log.append(entry)

    def flush_archive(self):
        if self.archive_path:
            with open(self.archive_path, "w", encoding="utf-8") as f:
                json.dump(self.raw_log, f, ensure_ascii=False, indent=1)

    def frame_bytes(self, payload: str) -> bytes:
        encoded = payload.encode("utf-8")
        return str(len(encoded)).encode("ascii") + b"\n" + encoded

    def read_frame_bounded(self, sock: socket.socket, deadline: float):
        """有界读取一帧：必须在单调 deadline 前完成，否则抛 timeout。"""
        received = bytearray()
        header_end = -1
        expected = None
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise socket.timeout("deadline exceeded while reading frame")
            sock.settimeout(remaining)
            chunk = sock.recv(4096)
            if not chunk:
                raise ConnectionError("eof")
            received.extend(chunk)
            if header_end < 0:
                header_end = received.find(b"\n")
                if header_end < 0:
                    if len(received) > 16:
                        raise FrameError("header 过长且无换行")
                    continue
                expected = int(bytes(received[:header_end]).decode("ascii"))
            total = header_end + 1 + expected
            if len(received) >= total:
                return bytes(received[header_end + 1: total]).decode("utf-8")

    def exchange_strict(self, payload_lines, timeout: float):
        """一请求一响应；deadline 为绝对单调时刻；原始帧归档。"""
        payload = "\n".join(payload_lines)
        deadline = time.monotonic() + timeout
        with socket.create_connection((self.host, self.port),
                                      timeout=max(0.1, deadline - time.monotonic())) as sock:
            sock.sendall(self.frame_bytes(payload))
            self._archive("request", payload)
            body = self.read_frame_bounded(sock, deadline)
            self._archive("response", body)
        return payload, body


class GateCommandError(RuntimeError):
    """第七次复核 A1：闸门命令握手/执行失败（未发布、未知操作、错 ID、负返回）。"""


def gate_command(exchange, token: str, op: str, expect_tokens=(), timeout: float = 12.0) -> str:
    """发布闸门命令并等待**同 PUBLISHED ID** 的执行回执。

    - 发布回执必须含 PUBLISHED <id>（缺失/非正 = 命令未被接受）；
    - 轮询 GATE_STATE 直到 RESULT_ID == 本次 PUBLISHED id（不读"最新任意结果"）；
    - RESULT 含 unknown/error、或缺少 expect_tokens 中任一成功码 → 失败。
    返回 RESULT 文本；失败抛 GateCommandError。单执行者串行握手：调用方
    必须等上一条命令的结果回来再发下一条（单槽语义）。
    """
    _, body = exchange.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {token}", f"OP {op}", "END"], timeout)
    published = None
    for line in body.splitlines():
        if line.startswith("PUBLISHED "):
            try:
                published = int(line.split(" ", 1)[1])
            except ValueError:
                published = None
    if not published or published <= 0:
        raise GateCommandError(f"{op}: 命令未被发布（body={body[:120]!r}）")
    deadline = time.monotonic() + timeout
    result = ""
    while time.monotonic() < deadline:
        _, gs = exchange.exchange_strict(
            ["CONTROL CJGUI_VERIFY/1", f"TOKEN {token}", "OP GATE_STATE", "END"], timeout)
        rid = None
        for line in gs.splitlines():
            if line.startswith("RESULT_ID "):
                try:
                    rid = int(line.split(" ", 1)[1])
                except ValueError:
                    rid = None
            if line.startswith("RESULT "):
                result = line.split(" ", 1)[1]
        if rid == published:
            low = result.lower()
            if "unknown" in low or "error" in low:
                raise GateCommandError(f"{op}: 执行失败（{result!r}）")
            for tok in expect_tokens:
                if tok not in result:
                    raise GateCommandError(f"{op}: 成功码缺失（{tok!r} 不在 {result!r}）")
            return result
        time.sleep(0.15)
    raise GateCommandError(f"{op}: 等待 RESULT_ID={published} 超时（最后 RESULT={result!r}）")


def gate_stage_held(exchange, token: str, slot: int, timeout: float = 6.0) -> int:
    """读 stageHeld packed 计数的指定槽位（0=permit 1=create 2=create_return
    3=draw 4=admission 5=flush 6=dequeue；每槽 9 位饱和）。
    GATE_A2_STATS 同为发布式命令：经 gate_command 等同 ID 回执后解析。"""
    result = gate_command(exchange, token, "GATE_A2_STATS", timeout=timeout)
    held = None
    for token_str in result.split():
        if token_str.startswith("stageHeld="):
            v = token_str.split("=", 1)[1].strip()
            if v.lstrip("-").isdigit():
                held = int(v)
    if held is None or held < 0:
        return -1
    return (held >> (slot * 9)) & 0x1FF
