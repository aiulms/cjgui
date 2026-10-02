#!/usr/bin/env python3
"""S4 共用严格 UTF-16 ↔ UTF-8 判据 oracle。

计划 R4/判据行要求：一个共用 oracle，覆盖非 BMP 前缀、代理对中点、反向/空
选区与 EOF；期望在操作前冻结，不能从结果反推。Python 的 str 按码点索引，
不是 UTF-16 单元——两段旧脚本用 Python 字符切片当 UTF-16 正是判据缺陷来源。
"""

import codecs


def utf16_len(data: bytes) -> int:
    """UTF-8 字节串的 UTF-16 码元长度（每个 BMP 标量 1、非 BMP 2）。"""
    return len(data.decode("utf-8", "strict").encode("utf-16-le")) // 2


def utf16_to_byte_offset(data: bytes, units: int) -> int:
    """UTF-16 单位偏移 → UTF-8 字节偏移。非 [0, len] 或劈开代理对 → ValueError。

    判据（与计划 R4 一致）：
      - 0 与 EOF（units == utf16_len）是合法边界；
      - 非 BMP 标量（代理对）占 2 个单位，单位中点（odd 落在代理对内）必须拒绝；
      - 合法单位边界精确映射到码点首字节。
    """
    if units < 0:
        raise ValueError(f"negative utf16 offset: {units}")
    text = data.decode("utf-8", "strict")
    total = utf16_len(data)
    if units > total:
        raise ValueError(f"utf16 offset {units} past end {total}")
    consumed = 0
    for ch in text:
        if consumed == units:
            break
        width = 2 if ord(ch) >= 0x10000 else 1
        if consumed + width > units:
            # 落在代理对中间：劈开非 BMP 标量，拒绝
            raise ValueError(f"utf16 offset {units} splits surrogate pair at {consumed}")
        consumed += width
    # consumed == units：返回对应码点的首字节偏移
    return len(text[: _char_index_for_units(text, units)].encode("utf-8"))


def _char_index_for_units(text: str, units: int) -> int:
    consumed = 0
    for index, ch in enumerate(text):
        if consumed == units:
            return index
        consumed += 2 if ord(ch) >= 0x10000 else 1
    return len(text)


def expected_replacement(data: bytes, start16: int, end16: int, new_text: str) -> bytes:
    """冻结期望：owner 应变为 前缀 + new_text + 后缀（UTF-16 域 [start16,end16)）。

    端点非法（倒置/越界/劈开代理对）直接抛 ValueError——调用方在操作**前**用
    它冻结期望，非法意图不得发出。
    """
    if end16 < start16:
        raise ValueError(f"inverted selection [{start16},{end16})")
    s = utf16_to_byte_offset(data, start16)
    e = utf16_to_byte_offset(data, end16)
    return data[:s] + new_text.encode("utf-8") + data[e:]


def self_check() -> None:
    """oracle 自检（含计划点名的反例）。任何断言失败都是 oracle 本身的缺陷。"""
    # A😀B：A=1 unit/1B，😀=2 units/4B，B=1 unit/1B
    data = "A😀B".encode("utf-8")
    assert utf16_len(data) == 4
    assert utf16_to_byte_offset(data, 0) == 0          # EOF 起点
    assert utf16_to_byte_offset(data, 1) == 1          # A 之后
    assert utf16_to_byte_offset(data, 3) == 5          # 😀 之后（A😀=3 units = 5B）
    assert utf16_to_byte_offset(data, 4) == 6          # EOF
    # 😀 的单位区间是 [1,3)：中点 2 落在代理对内部，必须拒绝
    try:
        utf16_to_byte_offset(data, 2)
        raise AssertionError("A[😀] surrogate midpoint must refuse")
    except ValueError:
        pass
    try:
        utf16_to_byte_offset(data, 5)
        raise AssertionError("offset 5 past end must refuse")
    except ValueError:
        pass
    # 😀 单独：unit 中点 1 劈开代理对
    emoji = "😀".encode("utf-8")
    assert utf16_to_byte_offset(emoji, 0) == 0
    assert utf16_to_byte_offset(emoji, 2) == 4
    try:
        utf16_to_byte_offset(emoji, 1)
        raise AssertionError("surrogate midpoint must refuse")
    except ValueError:
        pass
    # 期望冻结：A😀B 替换 [1,3)（😀）→ A + X + B
    want = expected_replacement(data, 1, 3, "X")
    assert want == "AXB".encode("utf-8"), want
    # 空选区替换 = 插入（unit1 = 😀 前）
    assert expected_replacement(data, 1, 1, "-") == "A-😀B".encode("utf-8")
    # 倒置拒绝
    try:
        expected_replacement(data, 3, 1, "Y")
        raise AssertionError("inverted must refuse")
    except ValueError:
        pass


self_check()
