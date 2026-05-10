# P1 内部渲染器 platform object token-backed NSView object table 预检结论

日期：2026-05-10

状态：preflight / 选择 B

## 预检结论

本轮选择 B：实现 production `NSView` object table first slice，但不创建 `NSView`。该 slice 只新增固定容量、main-thread confined、no-allocation、fail-closed 的 table shell / slot lifecycle facts 与 token classification facts；它不保存 `NSView`，不绑定 token 到真实 AppKit object，不返回 pointer / handle / `id` / `Class`。

不选择 A 的原因：上游 isolated `NSView` allocation feasibility 已通过，且 no-object creation callable、AppKit main-thread admission、token issue / revoke 与 teardown admission 已给出足够的 no-object / fail-closed 证据，可以进入更窄的 table shell callable 验证。

不选择 C 的原因：当前仍没有 token-backed `NSView` retention table、真实 destroy path 或 object lifecycle owner。即使 isolated allocation 已验证，也不能把 immediate allocation / cleanup 升格成 production retention 或 create/destroy first slice。

不选择 D 的原因：本轮不需要补 teardown / token / main-thread 基础证据；这些证据可支撑 no-allocation table shell，但不足以支撑长期 `NSView` 保存。

## 关键判断

- 是否只做 object table planning/value boundary：否，本轮允许 production no-allocation C ABI。
- 是否允许 production native 新增 allocation callable：否。
- 是否创建 `NSView` 后立即释放：否，本轮 production 不创建 `NSView`。
- 是否已有 token-backed object table 能保存它：否，本轮只建立 `NSView` object table shell facts，不保存对象。
- destroy / revoke-before-destroy / double-destroy 失败分类是否足够：足够支撑 fail-closed table shell；不足以支撑真实 object destroy。
- background thread 是否 fail-closed：是，table shell owner 与 callable 固定 main-thread confinement policy；本轮 callable 不执行对象创建。
- 是否需要 autorelease pool：否，因为 production route 不创建 `NSView`；isolated feasibility probe 已覆盖 autorelease pool 证据。
- 是否需要 `NSApplication`：否。
- 是否会触碰 `CALayer` / `CAMetalLayer` / Metal / QuartzCore：否。

## 允许写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_object_table.sh`
- 必要 native probe allowlist / symbol list / package-adjacent probe 维护
- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_object_table.cj`
- 本阶段 closure / next-boundary / manifest / manifest closure
- README / tracker / plans README / runtime README / design intent index / topic manifests / upstream downstream 指向

本轮不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不触碰 `runtime/cjgui/src/runtime_state.cj`。

## GitNexus impact

- `CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness`：GitNexus 返回 `UNKNOWN` / `impactedCount=0` / target not found。
- `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft`：GitNexus 返回 `UNKNOWN` / `impactedCount=0` / target not found。

判断：上游 owner 是近期新增符号，当前索引未覆盖。本轮记录 UNKNOWN，并用源码阅读、runtime build、native probe、symbol scan、forbidden scan 与 GitNexus detect changes 兜底。若后续 detect changes 出现 HIGH / CRITICAL，应停止并写 blocker。

## Same-shape Boundary Brake

`NSView` object table shell、capacity facts、empty facts、token classification facts、isolated allocation feasibility、token issue / revoke 或 teardown admission 不得被包装成 platform object creation permission、long-lived `NSView` storage permission、native handle permission、Metal / QuartzCore permission、backend-ready truth、renderer state write permission、render permission、receipt / record / publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，进入 token-backed `NSView` object table preflight，并选择 no-allocation table shell first slice。
- 本轮是否改变 canonical tail / endpoint：预期改变为 `CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()`。
- 本轮是否改变 owner / truth / stop-line：预期新增 `runtime_renderer_platform_object_nsview_object_table.cj`；truth 限于 table shell / no-allocation / fail-closed facts；stop-line 继续禁止 `NSView` 保存、pointer / handle / `id` / `Class` return、Metal / QuartzCore、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：预期转为 `P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`。
- 是否同步 topic manifest：待本轮 manifest stabilization 同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
