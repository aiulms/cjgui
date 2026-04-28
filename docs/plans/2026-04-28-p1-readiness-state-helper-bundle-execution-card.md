# P1 readiness state helper bundle execution card

日期：2026-04-28

类型：bundled execution card / W2 internal concept bundle

## Task Intent

bounded implementation authorization. 创建本卡不等于实现。

## Prompt Weight

W2 internal concept bundle：授权后续 2 个低风险 internal-only runtime helper slices，共用本卡；不得为 Slice A 单独创建新的 execution card。

## Authority

- [2026-04-28-p1-app-lifecycle-platform-readiness-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-app-lifecycle-platform-readiness-state-closure-review.md)
- [2026-04-28-p1-window-lifecycle-platform-readiness-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-window-lifecycle-platform-readiness-state-closure-review.md)
- Bundled execution card rule in [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)

## Goal

授权后续两个 internal-only readiness helper slices，让已落地的 app/window observed platform readiness state 可以被默认 internal helper 读取，并提供一条更明确的 coordination readiness sanity helper。

## Bundle Slices

### Slice A: app/window readiness helper predicates

允许新增默认 internal helper functions，用于判断:

- app state 是否已 observed platform ready。
- window state 是否已 observed platform ready。

允许修改:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

Slice A 不改变 state shape，不新增 public API / public C ABI。

### Slice B: coordination readiness sanity helper

允许新增默认 internal function，复用 `cjguiInternalLifecycleCoordinationSanity()`，返回或暴露 internal readiness sanity result。

如果需要新增 internal result type，只能是默认 internal、脱水 Bool summary、无平台对象、无 public、无 C ABI。

允许修改:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- bundle mini-compaction / bundled closure
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`

Slice B 不实现真实 runtime behavior。

## Bundle Forbidden

- 不接入 AppKit / Metal / Objective-C。
- 不暴露 platform object / native handle / raw pointer。
- 不实现 event loop / callback binding / queue / drain。
- 不实现 app run / shutdown。
- 不实现 window create / close / destroy / release。
- 不新增 handle table / generation。
- 不新增 public runtime API。
- 不新增 public C ABI。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` / `package_anchor.cj`。
- 不修改 `labs/macos_bridge_smoke`。

## Bundle Verification

每个 slice 完成后都必须运行:

- `cjpm build --target-dir /tmp/<slice-specific-target> --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

bundle 结束后还必须检查 forbidden 文件未改。

## Closure Rhythm

- Slice A 完成后只需在 `GUI_TASK_TRACKER.md` 记录简短 slice log。
- Slice B 完成后创建一份 mini-compaction / bundled closure，并同步 `docs/plans/README.md`。
- 如果任一 slice 发现 HIGH / CRITICAL 风险、public API / C ABI、platform bridge、event loop、queue / drain、handle table / generation、跨 owner truth 或安全边界需求，立即停止 bundle 并回到单卡单 closure。

## Next Implementation Expectation

下一轮默认进入 `P1 readiness helper bundle slice A`。

除非发现 HIGH / CRITICAL 风险或 authority 冲突，不得为 Slice A 单独创建新的 preflight / execution card 替代实现。
