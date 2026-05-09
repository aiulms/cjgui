# P1 内部渲染器 native bridge no-resource runtime FFI call owner 后续口径

日期：2026-05-09

状态：docs-only next-boundary / proceed to manifest stabilization

## 当前端点判断

`CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()` 足够作为当前 no-resource runtime FFI call owner endpoint。

它只代表：

- internal no-resource runtime call intent。
- script-managed package link route preservation。
- surface version observed facts。
- capabilities observed facts。
- status ok observed facts。
- no-resource admission observed facts。
- unexpected value fail-closed facts。

它不代表：

- public API。
- resource callable。
- native object、native handle、raw pointer 或 native pointer return。
- Metal / AppKit resource。
- `runtime/cjgui/cjpm.toml` integration。
- backend-ready truth。
- GPU submission、render execution 或 renderer state write。

## 候选比较

选择 A：

`P1 internal Renderer native bridge no-resource runtime FFI call owner manifest stabilization bundle`

暂缓 B：

`P1 internal Renderer native bridge package config runtime call blocker follow-up`

理由：本轮主包 static build 与 no-resource probe 通过，未触发 package config blocker；但 `runtime/cjgui/cjpm.toml` 仍未正式接入 native archive，因此 blocker 不应删除，只应保留为后续 package config integration 风险。

暂缓 C：

`P1 internal Renderer native bridge main-thread no-resource callable preflight decision`

理由：main-thread callable 需要重新评估 Foundation / pthread / platform import 与 cross-platform fallback，不应与本轮 no-resource deterministic call 混在一起。

## 下游接续

下游 [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md) 已完成。该接续选择 pthread route，只新增 no-resource `cjgui_native_bridge_is_main_thread(void)` 与 internal owner facts；没有新增 public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。

拒绝 D：

resource callable / native object / public API / Metal / AppKit。

## 停止线

- 不把 internal no-resource call 包装成 public API permission。
- 不把 script-managed route 包装成 `runtime/cjgui/cjpm.toml` integration。
- 不把 static package build 包装成 runtime executable link guarantee。
- 不把 no-resource call observed facts 包装成 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，owner 已进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 与 observed facts 已固定；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge no-resource runtime FFI call owner manifest stabilization bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
