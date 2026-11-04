#!/usr/bin/env python3
"""Compose the OHOS main-profile ABI header.

Input : runtime/cjgui/native/cjgui_internal_renderer.h (canonical common ABI)
        platforms/ohos/main_core/ohos_abi_supplement.h (OHOS-local additions)
Output: platforms/ohos/main_core/cjgui_internal_renderer.h

The supplement is inserted inside the header's extern "C" block so the OHOS
host definitions keep C linkage. Regenerate after the canonical header or the
supplement changes; the frozen-source manifest must then be refreshed.
"""
import pathlib

PLATFORM = pathlib.Path(__file__).resolve().parents[1]
CANON = PLATFORM.parents[1] / "native/cjgui_internal_renderer.h"
SUPPLEMENT = PLATFORM / "main_core/ohos_abi_supplement.h"
OUT = PLATFORM / "main_core/cjgui_internal_renderer.h"

canon = CANON.read_text()
supplement = SUPPLEMENT.read_text().rstrip() + "\n"
closing = '#ifdef __cplusplus\n}\n#endif'
if closing not in canon:
    raise SystemExit("canonical header extern C closing block not found")
canon = canon.replace(closing, supplement + "\n" + closing, 1)
OUT.write_text(canon)
print(f"wrote {OUT} ({len(canon)} bytes)")
