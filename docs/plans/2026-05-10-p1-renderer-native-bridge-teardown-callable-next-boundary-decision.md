# P1 内部渲染器 native bridge teardown callable 后续边界结论

日期：2026-05-10

状态：docs-only next-boundary / 选择 manifest stabilization

## 当前证据

[teardown callable value owner 复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-closure-review.md) 已确认：

- `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` 已作为当前 no-native-bridge-teardown-callable endpoint 落地。
- default draft `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()` 只消费 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`。
- 本轮没有新增 native teardown callable。
- 本轮没有实现 token table、destroy、retain、release、resource callable 或 public API。

## 候选选择

A 胜出：`P1 internal Renderer native bridge teardown callable manifest stabilization bundle`。

理由：

- 当前 owner 足够封账 no-destroy callable policy、revoke-before-destroy callable policy、double-destroy / dangling-token classification policy 与 main-thread destroy callable gate policy。
- 直接进入 resource creation admission 前，应先把 teardown callable planning 的 owner / endpoint / stop-line 固定。
- 当前没有 token table implementation，不能直接进入 native teardown callable implementation。

B 暂缓：resource creation admission preflight。该入口适合 manifest 封账后的下一阶段。

C 暂缓：token table implementation blocker follow-up。当前没有触发 blocker，table implementation 仍是 future runway。

D 暂缓：no-resource teardown admission callable first implementation preflight。没有 token table与可验证 revoke source 前，继续不建议。

E 拒绝：actual destroy / native object / public API / Metal / AppKit。

## 后续入口

manifest 封账后唯一后续入口建议写为：

`P1 internal Renderer native bridge resource creation admission preflight decision`

该入口只能评估 resource creation admission 的前置条件，不得把 teardown callable planning 误读成 native object、native handle、destroy、Metal / AppKit、backend-ready 或 public API permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，teardown callable value boundary 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，确认 `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()` 足够作为当前 no-native-bridge-teardown-callable endpoint。
- 本轮是否改变 owner / truth / stop-line：是，owner / truth / stop-line 将在 manifest 固定。
- 本轮是否改变唯一 next opening：是，manifest 封账后转为 `P1 internal Renderer native bridge resource creation admission preflight decision`。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：待 manifest stabilization 记录。
