# OHOS main-core freeze (2026-10-27)

Frozen copy of the accepted common core for the OHOS HAP:

- `src/`: copy of `runtime/cjgui/src` at main revision
  `c590b3189803b212d4958011999f33d73ee0214d` plus the working-tree state
  recorded in `SOURCE_REVISION.txt` (content hashes are authoritative).
- `shared_operation_core/src/`: the same-source shared operation core.
- `cjgui_internal_renderer.h`: canonical `runtime/cjgui/native/cjgui_internal_renderer.h`
  plus the OHOS-only proxy-restore-ticket declarations kept by the platform host.
- `MANIFEST.sha256`: integrity gate used by `scripts/sync_platform.sh` for
  `CJGUI_CORE_PROFILE=main`.

Do not edit files here to carry platform behavior: OHOS differences belong in
`platforms/ohos/host_main` and the narrow adapter sources. Regenerate the freeze
from the main tree only as a whole, then rebuild the manifest.
