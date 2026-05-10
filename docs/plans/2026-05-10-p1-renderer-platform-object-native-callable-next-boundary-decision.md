# P1 内部渲染器 platform object native callable 后续边界选择

日期：2026-05-10

状态：next-boundary / docs-only

## 选择

选择 A：`P1 internal Renderer platform object native callable manifest stabilization bundle`。

`CjguiInternalRendererNoPlatformObjectNativeCallableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()` 足够作为当前 no-platform-object-native-callable endpoint。

## 候选评估

- A：推荐。当前只需要把 value boundary 封账。
- B：暂缓。native bridge teardown callable implementation preflight 可以作为下一阶段入口，但不能跳过本轮 manifest。
- C：暂缓。AppKit import preflight 必须等 no-object admission 封账后再开。
- D：暂缓。no-object admission callable first implementation 仍可能被误读成 creation permission，应先封账 value boundary。
- E：拒绝。actual platform object creation、public API、Metal / AppKit object creation 均超出本轮。

## 保持的边界

- 不新增 native platform object callable。
- 不创建 `NSWindow` / `NSView` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不导入 Cocoa / AppKit / Metal / QuartzCore。
- 不返回 token、native pointer 或 native handle。
- 不修改 public runtime API。
- 不写 renderer state。

## 后续入口

封账后唯一 next opening 建议为：

`P1 internal Renderer native bridge teardown callable implementation preflight decision`

该入口只能评估 teardown callable implementation runway，不能直接创建 platform object、AppKit object、Metal object、native handle、public API 或 renderer state write。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object native callable value boundary 准备封账。
- 本轮是否改变 canonical tail / endpoint：是，确认 `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness` 为当前 endpoint。
- 本轮是否改变 owner / truth / stop-line：是，owner / truth / stop-line 已由 value boundary 固定。
- 本轮是否改变唯一 next opening：是，封账后转为 `P1 internal Renderer native bridge teardown callable implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
