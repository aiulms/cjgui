# P1 内部渲染器 CAMetalLayer allocation/table runway 清单稳定化封账

日期：2026-05-11

状态：manifest stabilization closure / completed through C route

## 稳定化结论

本轮宏包完成 A、B、C 三层并封账：

- A：allocation without attachment feasibility。
- B：token-backed table shell。
- C：token-backed create/destroy first slice。

该结果只证明 production native bridge 能在 main thread 内管理未 attach、无 device 的 `CAMetalLayer` token lifecycle。它不证明 `NSView` attachment、Metal device binding、drawable acquisition、render execution、GPU submission、backend-ready truth 或 renderer state write permission。

## 验证摘要

新增 probe 已通过：

- allocation feasibility probe。
- object table probe。
- create/destroy probe。

`cjpm build --target-dir /tmp/cjgui-renderer-cametallayer-allocation-table-runway-target --skip-script` 已通过，只有既有 unused warnings 与新增 owner unused warning。

完整回归已通过：

- CAMetalLayer allocation feasibility / object table / create-destroy probes 通过。
- CAMetalLayer no-attach、NSView runtime-call / create-destroy / object table / feasibility、platform no-object creation、AppKit import / class / main-thread、teardown、token issue/revoke、no-resource call、isolated FFI、package link、cjpm package link、skeleton compile、symbol probe、cjpm boundary 均通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-cametallayer-allocation-table-runway-target --skip-script` 通过，仅保留既有 unused warnings 与新增 internal owner unused warning。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。
- Markdown absolute link / reachability / 中文标题正文 / public declaration / native forbidden / protected path / owner header 扫描通过。
- `runtime_state.cj` 仍为 `10065` 行。
- GitNexus `detect-changes --scope unstaged`：risk `low`，affected processes `0`。

## 唯一后续入口

`P1 internal Renderer CAMetalLayer NSView attach/detach preflight decision`

该入口已由 [CAMetalLayer NSView attachment manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-nsview-attachment-manifest.md) 接续并完成；当前唯一后续入口转为 `P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，主线从 no-attach class/runtime facts 推进到 `CAMetalLayer` token-backed create/destroy first slice。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerCreateDestroyDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增三个 owner 与 native callable；truth 限于 no-attach token lifecycle；stop-line 继续禁止 attach、Metal、drawable、public、state write。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer NSView attach/detach preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
