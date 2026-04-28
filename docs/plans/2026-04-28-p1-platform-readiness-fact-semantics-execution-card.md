# P1 platform readiness fact semantics execution card

日期：2026-04-28

类型：execution card / W2 internal concept slice

## Task Intent

bounded implementation authorization. 创建本卡不等于实现。

## Prompt Weight

W2 internal concept slice：下一刀只把当前泛化的 internal platform marker fact 推进到更明确的 platform readiness fact 语义；不新增 public contract、平台桥接、runtime behavior 或 platform object exposure。

## Authority

- [2026-04-28-p1-internal-lifecycle-coordination-sanity-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-lifecycle-coordination-sanity-closure-review.md)

## Goal

授权下一轮把 `CjguiInternalPlatformAdapterFact` 的泛化 marker fact 从 `hasPlatformFact` 推进为更明确的 platform readiness fact 语义。

该 fact 仍必须保持:

- internal-only
- 脱水 Bool fact
- 无平台对象
- 无 native handle / raw pointer
- 无 public runtime API
- 无 public C ABI

## Write Set

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- closure review
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Allowed Implementation Shape

- 可以在 `CjguiInternalPlatformAdapterFact` 中新增或替换为 `isPlatformReady: Bool`。
- 可以更新 `CjguiInternalPlatformAdapterFact` constructor shape。
- 可以更新 `cjguiInternalNoOpPlatformAdapterFactIngestion`，保持 readiness 语义下的 no-op ingestion。
- 可以更新 platform fact -> app/window lifecycle projection，使它消费 readiness 语义。
- 可以更新 `cjguiInternalCoordinateLifecycleFromPlatformFact` 相关调用路径的注释或 internal naming clarity。
- 可以更新 `cjguiInternalLifecycleCoordinationSanity`，用 readiness 语义构造最小 fact。
- 可以保留兼容性字段，或选择窄口替换；但 closure review 必须明确说明采用哪一种，以及为什么没有扩大 public surface。

## Forbidden

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

## Verification

- `cjpm build --target-dir /tmp/cjgui-platform-readiness-fact-semantics-card-target --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`
- 链接检查

## Next Implementation Expectation

下一轮默认进入 `P1 platform readiness fact semantics first slice`。

除非发现 HIGH / CRITICAL 风险或 authority 冲突，不得继续创建新的 preflight / execution card 替代实现。
