# P1 渲染器真实后端 platform object 第一刀实现切片闭环复查

日期：2026-05-07

状态：implementation slice closure / internal shell only / no backend ready truth

## 文件定位

本文件复查 `P1 internal Renderer real backend platform object first implementation slice bundle`。本轮新增一个 internal-only runtime owner shell：

- [runtime_renderer_backend_platform_object_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj)

本 closure 不是 backend ready truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，不改变 protected path policy，不批准 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、native handle、GPU submission、renderer state write 或 public API。

## 设计意图入口

本轮先读取并对齐：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [real backend platform object first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)

入口结论保持：first implementation slice 只能落 internal shell facts；若必须修改 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、retain / release / destroy 或真实 native handle，必须回退到 `P1 internal Renderer native teardown contract hardening preflight decision`。本轮未触发回退条件。

## GitNexus 影响结果

实施前已按要求查询：

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`：GitNexus 未找到已索引 symbol，风险未升至 HIGH / CRITICAL。
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft`：GitNexus 未找到已索引 symbol，风险未升至 HIGH / CRITICAL。
- `CjguiInternalRendererNoNativeResourceBridgeReadiness`：GitNexus 未找到已索引 symbol，风险未升至 HIGH / CRITICAL。
- `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft`：GitNexus 未找到已索引 symbol，风险未升至 HIGH / CRITICAL。

由于这些 recent internal owner symbols 未在当前 GitNexus index 中命中，本轮使用源码读取、`cjpm build`、smoke、stop-line scan 与 `detect_changes` 作为补充护栏。

## 本轮新增 owner

Owner file：

- [runtime_renderer_backend_platform_object_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj)

唯一 runtime input：

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`
- `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`

Current truth：

- `CjguiInternalRendererRealBackendPlatformObjectIntent`
- `CjguiInternalRendererRealBackendPlatformObjectShellPolicy`
- `CjguiInternalRendererRealBackendPlatformObjectTeardownProof`
- `CjguiInternalRendererRealBackendPlatformObjectFailurePolicy`
- `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`

对应 builders 已新增：

- `cjguiInternalBuildRendererRealBackendPlatformObjectIntent`
- `cjguiInternalBuildRendererRealBackendPlatformObjectShellPolicy`
- `cjguiInternalBuildRendererRealBackendPlatformObjectTeardownProof`
- `cjguiInternalBuildRendererRealBackendPlatformObjectFailurePolicy`
- `cjguiInternalBuildRendererNoRealBackendPlatformObjectReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`

## 事实语义

`CjguiInternalRendererRealBackendPlatformObjectIntent` 只记录第一刀 shell intent facts。它不创建真实 platform object，不代表 backend-ready permission，不代表 native handle permission。

`CjguiInternalRendererRealBackendPlatformObjectShellPolicy` 只记录 owner-local shell policy facts。它不创建 backend object、platform object、Metal / AppKit resource 或 public surface。

`CjguiInternalRendererRealBackendPlatformObjectTeardownProof` 只记录 owner-local teardown proof facts。它不调用 bridge，不执行 retain / release / destroy，不注册 callback，不执行真实 resource lifecycle。

`CjguiInternalRendererRealBackendPlatformObjectFailurePolicy` 只记录 blocked / inconsistent fail-closed facts。它不发布 failure event，不写 renderer state，不生成 public diagnostics。

`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 封住当前 no-real-backend-platform-object shell facts。它不是 platform object permission、native handle permission、backend-ready permission、resource-ready permission、Metal / AppKit permission、GPU submission permission、renderer state write permission、public diagnostics permission 或 public API permission。

## 路径行为

- open path：仅在 upstream no-platform-object-implementation endpoint 自洽时形成 dehydrated shell facts。
- defer-only path：保留 defer，不伪装为 open。
- blocked / inconsistent path：fail-closed，形成 blocked facts。
- 默认 draft：只调用 `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`，不调用 native bridge / smoke / harness / Metal / AppKit / Objective-C。

## 同形边界刹车

本轮新增的是 real backend platform object shell / teardown proof / failure policy / no-real-backend-platform-object 语义，不是把 `CjguiInternalRendererNoPlatformObjectImplementationReadiness`、`CjguiInternalRendererNoNativeResourceBridgeReadiness`、platform object owner manifest 或 preflight evidence 包成 platform-object permission wrapper、native-handle-ready wrapper、backend-ready wrapper、resource-ready wrapper、Metal-device wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 不得被继续包装成 thin wrapper。下一步必须先做 closure / next decision，确认该 endpoint 是否足够封账，不能直接推进 native bridge、Metal / AppKit 或 backend-ready truth。

## 停止线

本轮确认继续禁止：

- 不修改 native bridge / Objective-C / Metal / AppKit 代码。
- 不新增 C ABI / FFI declaration。
- 不调用 bridge / retain / release / destroy。
- 不创建 native handle / raw pointer。
- 不创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`。
- 不获取 drawable。
- 不创建 command buffer、render pass、encoder、pipeline state、shader、descriptor。
- 不发出 draw call。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不触碰 `runtime_state.cj`。
- 不新增 module-level `var`。
- 不发布 public diagnostics / API。
- 不扩 public API。
- 不触碰 `runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## 文档同步

已同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real backend platform object first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)
- [platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)

## 核验记录

- GitNexus impact：四个指定 symbols 均未命中当前 index，未出现 HIGH / CRITICAL。
- `cjpm build --target-dir /tmp/cjgui-renderer-real-backend-platform-object-first-slice-target --skip-script`：通过；裸 `cjpm` 不在 PATH，已使用本机 toolchain env；输出仍有既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过；auto-close log assertions passed。
- `git diff --check`：通过。
- 新 runtime owner / closure no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：均可找到本轮 closure 或设计意图导航入口。
- protected path check：`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER 无本轮 diff / status；`runtime_state.cj` 行数仍为 `10065`。
- comment-aware public declaration scan：仍只发现 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- 新 owner 文件头维护注释：已包含 Owner / Truth / Stop-line / Same-shape Boundary Brake。
- 新 owner stop-line：未引入 native bridge / Objective-C / Metal / AppKit 修改，未新增 C ABI / FFI declaration，未创建 native handle / raw pointer，未调用 retain / release / destroy，未创建 Metal resource、drawable、command buffer、render pass、encoder、pipeline、draw call、GPU submission、renderer state write、module-level `var` 或 public API。
- GitNexus `detect_changes(scope=unstaged)`：changed files `21`、changed symbols `37`、affected processes `0`、risk `low`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，Renderer implementation admission chain 与 backend readiness runway 从 platform object first implementation preflight completed 推进到 first implementation slice completed。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 作为本 slice 的 canonical endpoint；backend readiness implementation admission branch tail 仍是 `CjguiInternalRendererNoBackendReadyImplementationReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`，truth 限于 shell intent / shell policy / teardown proof / failure policy / no-real-backend-platform-object readiness facts；stop-line 继续禁止 native bridge、native handle、Metal / AppKit、GPU submission、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real backend platform object first implementation slice closure / next real backend platform object decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real backend platform object first implementation slice closure / next real backend platform object decision`

## 下游后续边界决策

下游 closure / next decision 已完成：

- [real backend platform object first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 no-real-backend-platform-object shell endpoint，且下一步只能进入 manifest stabilization。该 downstream 不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建 native handle、Metal resource、GPU submission、renderer state write 或 public API。

新的下游后续入口：

`P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`

## 下游切片 manifest 稳定化

下游 manifest stabilization 已完成：

- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [real backend platform object first implementation slice manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream 固定 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 的 manifest 语义。它不新增 tail wrapper，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建 native handle、Metal resource、GPU submission、renderer state write 或 public API。

新的下游后续入口：

`P1 internal Renderer real backend platform object branch closure / next real platform object decision`
