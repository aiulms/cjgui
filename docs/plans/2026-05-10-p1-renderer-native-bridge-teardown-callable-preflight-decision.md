# P1 内部渲染器 native bridge teardown callable 预检结论

日期：2026-05-10

状态：docs-only preflight / 选择 planning value boundary

## 预检问题

本轮从 [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md) 进入，目标是评估 teardown callable runway 是否可以打开。

当前证据链已经固定：

- `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` 存在并只表达 bridge-local opaque token table policy、table mutability confinement、generation / epoch invalidation、revoke-before-destroy ordering 与 double-revoke / dangling-token failure classification facts。
- 当前仍没有 token table implementation。
- 当前仍没有 native token C ABI。
- 当前仍没有 destroy / retain / release implementation。
- 当前 production native bridge 只有 no-resource status / capability / no-resource admission / main-thread query callable。

因此可以打开 teardown callable runway，但第一阶段必须仍是 internal planning value boundary，而不是新增 native teardown callable。

## 候选判断

A 胜出：`P1 internal Renderer native bridge teardown callable planning value boundary bundle`。

选择理由：

- no-resource teardown admission callable 如果要表达 revoke / double-destroy / dangling-token，必须依赖 token table 或可验证 token facts；当前 table 未实现，不能伪造 callable truth。
- `cjgui_native_bridge_teardown_admission`、`cjgui_native_bridge_destroy_not_supported`、`cjgui_native_bridge_revoke_before_destroy_required` 这类 future callable 名称可以作为候选词汇，但本轮不应写入 native `.h/.m`。
- main-thread destroy confinement 只能连接到现有 `cjgui_native_bridge_is_main_thread` 的 classification evidence；它不是 AppKit / Metal 创建 permission，也不是 destroy permission。
- double-destroy / dangling-token 当前只能做 classification policy，不做状态变更。
- revoke-before-destroy 是顺序契约，不是 revoke implementation 或 destroy implementation。

B 暂不选择：no-resource teardown admission callable first implementation。当前没有 token table、没有 native state、没有可验证 revoke source，写 callable 容易把 “不支持” 包成 callable permission。

C 暂不选择：destroy token table blocker follow-up。当前 table mutability risk 已由上游 hardening owner 固定，可先落 teardown callable planning owner。

D 拒绝：actual destroy / retain / release / native object / public API / Metal / AppKit。

## 本轮允许写集

- 新增 `runtime/cjgui/src/runtime_renderer_native_bridge_teardown_callable.cj`。
- 新增本轮 preflight、closure、next-boundary、manifest 与 manifest closure。
- 同步 `README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`docs/plans/DESIGN_INTENT_INDEX.md` 与三个 topic manifest。
- 给相关 upstream manifest 补 downstream 指向。

## 本轮禁止写集

- 不修改 `runtime/cjgui/native/cjgui_native_bridge.h`。
- 不修改 `runtime/cjgui/native/cjgui_native_bridge.m`。
- 不修改 native probe scripts。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不修改 `runtime/cjgui/src/runtime_state.cj`。
- 不新增 public API / diagnostics。

## stop-line

- no actual destroy。
- no retain / release / destroy call。
- no token table implementation。
- no native token C ABI。
- no native object / handle / raw pointer。
- no native pointer return。
- no resource callable。
- no public API / diagnostics。
- no Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no renderer state write。
- no backend-ready truth。

## GitNexus 预检

按 AGENTS 要求，在编辑 runtime symbol 前对上游入口运行 impact：

- `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`：`UNKNOWN / not found`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft`：`UNKNOWN / not found`，`impactedCount=0`。

该结果按近期新增 owner 尚未被索引记录处理；本轮继续用源码、`cjpm build`、probe、scan 与 GitNexus `detect_changes` 兜底。未出现 HIGH / CRITICAL risk。

## 同形边界刹车

不得把 teardown callable planning、token table ownership、main-thread query、token callable planning 或 smoke evidence 包装成 destroy permission、native object permission、native handle permission、resource creation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，teardown callable runway 从预检进入 planning value boundary。
- 本轮是否改变 canonical tail / endpoint：预期会改变为 `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：预期新增 `runtime_renderer_native_bridge_teardown_callable.cj`，truth 固定为 no-destroy callable policy、revoke-before-destroy callable policy、double-destroy / dangling-token classification policy、main-thread destroy callable gate policy 与 no-native-bridge-teardown-callable readiness facts；stop-line 继续禁止 actual destroy、token table、resource callable、native object、Metal / AppKit、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：预期封账后转为 `P1 internal Renderer native bridge resource creation admission preflight decision`。
- 是否同步 topic manifest：本轮结束前同步。
- 已同步哪些 topic manifest：待 closure / manifest 记录。
