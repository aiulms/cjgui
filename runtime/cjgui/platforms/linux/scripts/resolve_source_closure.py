#!/usr/bin/env python3
"""Compute the CJGUI consumer source closure that actually compiles this tree.

`native/scripts/lib_cjgui_source_set.sh` 是一份手工维护的命名集合，供 standalone
cjc 消费者与导出包使用。当共同层新增跨文件类型时，它可能滞后于工作区。本脚本
从该集合出发，反复把编译器报出的"未声明类型/标识符"的声明文件并进闭包，直到
在目标平台上编译通过或达到迭代上限。

用法：
    python3 resolve_source_closure.py [--guest oeuser@10.211.55.4] [--root /home/oeuser/cjgui-linux]
                                      [--max-rounds 12] [--out closure.txt]

输出：追加文件清单到 stdout，并把完整列表写到 --out。
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

RUNTIME = Path(__file__).resolve().parents[3]  # -> .../runtime/cjgui
REPO = RUNTIME.parents[1]
SRC = RUNTIME / "src"

DECL_PATTERNS = (
    "class {name}", "struct {name}", "interface {name}", "enum {name}",
    "func {name}", "let {name}", "var {name}", "const {name}",
    "type {name}",
)
UNDECLARED_RE = re.compile(
    r"undeclared (?:type name|identifier|type|name) '([A-Za-z_][A-Za-z0-9_.]*)'"
)
MISSING_DECL_RE = re.compile(
    r"cannot find|cannot access|no member named|not found|unknown"
)


def base_names() -> list[str]:
    out = subprocess.run(
        ["zsh", "-c", "source native/scripts/lib_cjgui_source_set.sh; cjgui_framework_source_names true"],
        cwd=RUNTIME, capture_output=True, text=True, check=True,
    )
    return [n.strip() for n in out.stdout.splitlines() if n.strip()]


def find_declaring_files(symbol: str, already: set[str]) -> list[str]:
    short = symbol.split(".")[0]
    hits: list[str] = []
    for pattern in DECL_PATTERNS:
        needle = pattern.format(name=short)
        out = subprocess.run(
            ["grep", "-rl", "--include=*.cj", needle, str(SRC)],
            capture_output=True, text=True,
        )
        for line in out.stdout.splitlines():
            name = Path(line).name
            if name not in already and name not in hits and not name.endswith("_test.cj"):
                hits.append(name)
        if hits:
            break
    return hits


def ssh(guest: str, command: str, timeout: int = 1800) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["ssh", "-o", "BatchMode=yes", guest, command],
        capture_output=True, text=True, timeout=timeout,
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--guest", default="oeuser@10.211.55.4")
    ap.add_argument("--root", default="/home/oeuser/cjgui-linux")
    ap.add_argument("--max-rounds", type=int, default=12)
    ap.add_argument("--out", default="closure.txt")
    args = ap.parse_args()

    names = base_names()
    added: list[str] = []

    for round_index in range(args.max_rounds):
        filelist = Path("/tmp/cjgui_closure_%d.txt" % round_index)
        filelist.write_text("\n".join(names) + "\n")
        dest = f"{args.guest}:{args.root}/runtime/cjgui/src/"
        rsync = subprocess.run(
            ["rsync", "-az", "--delete", f"--files-from={filelist}",
             str(SRC) + "/", dest],
            capture_output=True, text=True,
        )
        if rsync.returncode != 0:
            print("rsync failed:", rsync.stderr[-500:], file=sys.stderr)
            return 2
        build = ssh(
            args.guest,
            "source ~/cangjie-dl/cangjie/envsetup.sh >/dev/null 2>&1; "
            f"cd {args.root}/runtime/cjgui && rm -rf target && cjpm build --skip-script -j8 "
            "> /tmp/closure_build.log 2>&1; echo exit=$?",
        )
        tail = ssh(args.guest, "grep -oE \"undeclared [a-z ]*'[A-Za-z_][A-Za-z0-9_.]*'\" /tmp/closure_build.log | sort -u | head -60")
        symbols = sorted(set(UNDECLARED_RE.findall(tail.stdout)))
        print(f"[round {round_index}] names={len(names)} undeclared={len(symbols)}")
        if not symbols:
            print("closure compiles clean.")
            break
        already = set(names)
        grown = False
        for symbol in symbols:
            for candidate in find_declaring_files(symbol, already):
                names.append(candidate)
                added.append(candidate)
                already.add(candidate)
                grown = True
                print(f"   + {candidate}  (for {symbol})")
                break
        if not grown:
            print("no further declaring file found; stopping.", file=sys.stderr)
            print("still undeclared:", symbols[:20], file=sys.stderr)
            break

    Path(args.out).write_text("\n".join(names) + "\n")
    print(f"closure size={len(names)} added={len(added)} -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
