# P1 内部渲染器 native bridge teardown callable implementation 预检

日期：2026-05-10

状态：implementation preflight / no-resource callable admission

## 预检结论

可以打开 no-resource teardown admission callable first implementation runway，选择：

`P1 internal Renderer native bridge no-resource teardown admission callable first implementation bundle`

本轮只允许新增 teardown admission / not-supported / revoke-before-destroy-required / double-destroy classification callable。它们只返回整数 status / classification facts，不执行真实 destroy，不调用 retain / release，不触碰 native object，不绑定 token 到 resource，不写 renderer state，也不扩 public API。

## 证据输入

- 最新 platform object native callable endpoint 是 `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()`。
- platform object native callable 仍停在 no-object admission boundary，没有新增 platform object native C ABI。
- token issue / revoke 已由 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness` 固定为 bridge-local opaque token mechanics。
- 现有 token table issue / revoke callable 只分配和撤销 opaque token，不绑定 native object，不保存 raw pointer，不执行 destroy。
- 现有 teardown callable manifest 只固定 no-destroy policy，尚未实现 native teardown admission callable。

## 本轮允许的 callable

本轮允许新增以下 no-resource callable：

- `cjgui_native_bridge_teardown_admission(uint64_t token)`：只对 token 做 fail-closed admission classification。
- `cjgui_native_bridge_destroy_not_supported(void)`：只返回 destroy-not-supported classification。
- `cjgui_native_bridge_revoke_before_destroy_required(void)`：只返回 revoke-before-destroy-required classification。
- `cjgui_native_bridge_double_destroy_classify(uint64_t token)`：只把 stale / invalid token 分类为 double-destroy 或 dangling-token denial。

这些 callable 不返回 token，不返回 pointer，不返回 handle，不创建 object，不调用 resource lifecycle。

## 状态与分类策略

- valid token 的 teardown admission 仍返回 revoke-before-destroy-required，不进入 destroy。
- invalid token / dangling token 必须 fail-closed。
- stale token 可作为 double-destroy denial evidence。
- destroy-not-supported 必须是稳定整数事实，不代表 destroy callback 存在。
- main-thread gate 由现有 main-thread query 与 platform object admission owner 的 prerequisite facts 间接保护；本轮不做线程调度，不新增 AppKit import。

## 写集授权

本轮允许修改：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/native/scripts/*` 中与 no-resource callable allowlist / teardown admission probe 相关的脚本
- `runtime/cjgui/src/runtime_renderer_native_bridge_teardown_admission_call.cj`
- README、tracker、plans README、runtime README、设计意图索引与 topic manifests
- 本阶段 closure / next-boundary / manifest 文档

本轮默认不修改 `runtime/cjgui/cjpm.toml`。

## 停止线

- no actual destroy。
- no retain / release。
- no native object。
- no token-to-resource binding。
- no raw pointer / native pointer / native handle。
- no `NSWindow` / `NSView` / `CAMetalLayer`。
- no `MTLDevice` / `MTLCommandQueue`。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no smoke native edits。
- no Cocoa / Metal / QuartzCore import。
- no backend-ready truth。

## GitNexus 预检

编辑 runtime owner 前已对上游入口运行 impact：

- `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`：GitNexus 返回 not found / UNKNOWN，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft`：GitNexus 返回 not found / UNKNOWN，`impactedCount=0`。
- `cjgui_native_bridge_surface_capabilities`：GitNexus 返回 not found / UNKNOWN，`impactedCount=0`。

这些符号属于近期新增或 native surface，当前索引未收录。未出现 HIGH / CRITICAL；本轮继续使用源码、build、probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，teardown callable implementation runway 从 planning value boundary 进入 no-resource admission callable first implementation。
- 本轮是否改变 canonical tail / endpoint：预检阶段暂未改变，若实现成功将新增 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：预检阶段暂未改变 owner，truth 选择 no-resource teardown admission classification；stop-line 继续禁止 actual destroy / native object / public API。
- 本轮是否改变唯一 next opening：预检阶段暂未最终改变，若实现通过将转为 manifest stabilization。
- 是否同步 topic manifest：将在 closure 与 manifest 阶段同步。
- 已同步哪些 topic manifest：预检阶段待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
