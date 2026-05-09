# P1 渲染器 native bridge teardown implementation planning manifest stabilization closure

日期：2026-05-09

状态：完成 / manifest stabilization closure / no teardown implementation

## 文件定位

本 closure 收束 `P1 internal Renderer native bridge teardown implementation planning manifest stabilization bundle implementation`。本轮封账 [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)，并同步 README、tracker、plans README、runtime README、设计意图索引与三个 topic manifest。

## 封账结论

`runtime/cjgui/src/runtime_renderer_native_bridge_teardown_plan.cj` 已作为唯一新增 runtime owner 落地。

`CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()` 足够作为当前 no-native-bridge-teardown-implementation endpoint。

该 endpoint 只代表 native bridge teardown planning intent、destroy admission guard policy、token invalidation before destroy policy、double-destroy / dangling-token denial policy、main-thread destroy confinement policy、teardown failure classification 与 no-native-bridge-teardown-implementation readiness facts。它不是 native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、native pointer return permission、C ABI implementation permission、FFI permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

## 验证记录

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-teardown-planning-macro-target --skip-script`：通过；仅保留既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，auto-close log assertions passed，并记录 `destroy complete`。
- `git diff --check`：通过。
- 新 runtime / docs no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，范围限定 project docs / README，避开 `reference_repos/`。
- README / tracker / plans README / runtime README / design index / topic manifest reachability：通过。
- Markdown 中文标题与中文正文抽查：通过。
- protected path check：通过；`runtime_state.cj` 行数仍为 `10065`，`runtime_state.cj` 与 `labs/macos_bridge_smoke/native/*` 无 status diff。
- comment-aware public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- new owner header / stop-line scan：通过，文件头包含 Owner / Truth / Stop-line / Same-shape Boundary Brake，未发现 operative native bridge / Objective-C / Metal / AppKit / FFI / C ABI / native handle / raw pointer / retain / release / destroy / GPU / render / renderer state write / public API 越线。
- native file forbidden scan：通过，未修改 `labs/macos_bridge_smoke/native/*`，未新增 production `.h` / `.m`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：risk `low`，`affected_count=0`，affected processes 为空；近期新增 owner 未产生已索引 changed symbols。

## 同步记录

本轮同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

本轮给 native handle token ownership manifest / closure、native bridge C ABI surface contract manifest、native teardown contract hardening manifest、native resource bridge manifest 与 Metal reference pack 补 downstream 指向。

## 同形边界刹车

本轮没有把 token ownership、C ABI surface contract、smoke lab、Metal reference pack、native teardown hardening manifest 或 teardown planning value facts 包成 native bridge implementation permission、destroy permission、native-handle permission、C ABI implementation permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

当前 branch 到此停止，不继续新增同构 no-* wrapper。下一步若继续推进，必须进入 native bridge first production write-set preflight，仍不得直接实现 native bridge、C ABI / FFI、destroy callback 或 native handle。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no native pointer return。
- no retain / release / destroy。
- no destroy callback implementation。
- no backend ready truth。
- no backend object。
- no `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API / C ABI expansion。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no module-level mutable `var`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 native handle token ownership manifest stabilization 推进到 native bridge teardown implementation planning manifest stabilization completed。
- 本轮是否改变 canonical tail / endpoint：是，当前最新 endpoint 是 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，固定 owner file、runtime input、current truth 与 no-native-bridge-teardown-implementation stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge first production write-set preflight decision`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge first production write-set preflight decision`
