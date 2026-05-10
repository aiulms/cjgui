# P1 内部渲染器 native bridge resource creation admission 后续边界结论

日期：2026-05-10

状态：next-boundary decision / choose manifest stabilization

## 当前 endpoint 是否足够

`CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft()` 足够作为当前 no-native-resource-creation-admission endpoint。

该 endpoint 只说明 future resource creation 的 admission prerequisites 已被 internal value owner 固定；它不说明 resource exists，不说明 native bridge ready，也不说明 backend ready。

## 候选比较

- A 选择：`P1 internal Renderer native bridge resource creation admission manifest stabilization bundle`。当前 owner 与 stop-line 已足够封账，应先稳定 manifest。
- B 后续：`P1 internal Renderer native token table implementation preflight decision`。token table implementation 是 future resource creation 的下一层硬前置，适合作为封账后的唯一 next opening。
- C 暂缓：`P1 internal Renderer native bridge teardown callable implementation preflight decision`。teardown implementation 仍需要 token table / lifecycle 证据配合。
- D 暂缓：`P1 internal Renderer platform object native callable preflight decision`。不得绕过 token table implementation preflight。
- E 拒绝：direct native object / public API / Metal / AppKit。

## 停止线

下一步进入 manifest stabilization 仍不得：

- 新增 native resource C ABI。
- 修改 production native `.h/.m`。
- 创建 native object。
- 实现 token table。
- 调用 retain / release / destroy。
- 写 renderer state。
- 修改 `runtime_state.cj`。
- 扩 public API。
- 创建 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，resource creation admission value boundary 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，确认 `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness` 为当前 endpoint。
- 本轮是否改变 owner / truth / stop-line：是，owner / truth / stop-line 已由 value boundary closure 固定。
- 本轮是否改变唯一 next opening：是，manifest 后唯一 next opening 建议为 `P1 internal Renderer native token table implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
