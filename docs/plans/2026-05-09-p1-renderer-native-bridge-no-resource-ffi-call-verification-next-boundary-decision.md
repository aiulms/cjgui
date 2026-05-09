# P1 渲染器 native bridge no-resource FFI call verification 后续走向结论

日期：2026-05-09

状态：docs-only next-boundary / manifest stabilization selected

## 当前端点判断

当前阶段没有新增 runtime endpoint。已有 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()` 仍表示 runtime internal declaration readiness，不表示 runtime package call support。

新增 probe `verify_native_bridge_no_resource_call_probe.sh` 足够作为当前 stage 的 runtime-adjacent observed call evidence：

- 它确认 runtime declaration owner 声明了四个 `foreign func`。
- 它通过 temporary `cjpm` package 实际调用四个 no-resource C ABI。
- 它输出脱水 facts，不写状态，不扩 public API。
- 它不修改 `runtime/cjgui/cjpm.toml`，不创建 native object。

## 候选比较

- A 选择：`P1 internal Renderer native bridge no-resource FFI call verification manifest stabilization bundle`。当前 probe evidence 足够封账，但必须明确 actual route 是 runtime-adjacent probe，不是 runtime owner call。
- B 暂缓：`P1 internal Renderer native bridge runtime package link call support preflight decision`。这是下一轮更合适入口，用于判断是否把主包 package link 从 probe route 推进到真实 runtime package call support。
- C 暂缓：`P1 internal Renderer native bridge main-thread no-resource callable preflight decision`。当前还没有主包 call support，不应越过 package link gate。
- D 拒绝：resource callable / native object / public API / Metal / AppKit。

## 选择结果

选择 A，进入 manifest stabilization。

完成 manifest 后的唯一后续入口建议为：

`P1 internal Renderer native bridge runtime package link call support preflight decision`

## 同形边界刹车

不得把 runtime-adjacent no-resource call probe、observed facts、runtime declaration owner 或 package link probe 包装成 runtime owner call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-resource FFI call verification 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否，本轮没有新增 runtime endpoint；current declaration endpoint 仍是 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 固定为 runtime-adjacent observed call facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit 与 state write。
- 本轮是否改变唯一 next opening：是，manifest 后转为 `P1 internal Renderer native bridge runtime package link call support preflight decision`。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：本 decision 尚未同步，后续 manifest 同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
