# P1 内部渲染器 platform object no-object creation callable 清单封账复核

日期：2026-05-10

状态：manifest stabilization closure / no-object callable first implementation

## 封账结论

platform object no-object creation callable stage 已完成 manifest stabilization。当前 canonical tail 固定为：

- Endpoint：`CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`
- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_no_object_creation_call.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness`

本阶段只证明 platform object creation entry 的 no-object / fail-closed callable surface 已在 production native bridge 与 internal runtime 链路内固定，不证明 platform object exists，不批准 native object creation。

## 固定事实

- no-object admission observed。
- main-thread requirement observed。
- token contract requirement observed。
- allocation blocked observed。
- creation entry fail-closed。
- no `Class` / `id` / pointer / handle return。
- no AppKit object allocation。
- no Metal / QuartzCore usage。
- no object table implementation。
- no token binding to native object。
- `runtime/cjgui/cjpm.toml` 未修改。
- Smoke native files 未修改。
- `runtime_state.cj` 未修改。

## 停止线

- 不创建 `NSWindow` / `NSView` / `NSApplication`。
- 不创建 `CALayer` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不调用 `alloc` / `init` / `new`。
- 不导入 Metal / QuartzCore。
- 不返回 `Class` / `id` / pointer / handle。
- 不保存 native object 或 class object。
- 不实现 object table。
- 不把 token 绑定到真实 native object。
- 不新增 public API / diagnostics。
- 不写 renderer state。
- 不声明 backend-ready truth。

## 封账验证

本阶段最终验证已完成：

- 新增 `verify_native_bridge_platform_object_no_object_creation.sh` 通过，观察到 no-object admission、main-thread requirement、token contract requirement、allocation blocked，且确认 AppKit object allocated false、native pointer returned false、Metal / QuartzCore imported false、public API modified false。
- AppKit import、AppKit class availability、AppKit main-thread admission probes 均通过，仍只观察 no-object / still-blocked / class availability / main-thread admission facts。
- Teardown admission、token issue/revoke、no-resource call、isolated FFI、package link、`cjpm` package link、skeleton compile、symbol probe 均通过；package link probes 已观察新增四个 no-object creation callable。
- `cjpm` boundary 初次提示 `cjpm` 未在当前 shell PATH；source `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` 后重跑通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-no-object-creation-callable-target --skip-script` 通过；编译器打印既有 unused warnings，本阶段无 build error。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，auto-close log assertions passed。
- `git diff --check` 通过；runtime / native / script / docs whitespace check 通过。
- Markdown absolute link missing target check 通过，项目 docs / README 范围内检查 `959` 个 Markdown 文件，missing count 为 `0`。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / 三个 topic manifest 对 no-object creation callable manifest 的 reachability 通过。
- 中文标题与中文正文抽查通过。
- Comment-aware public declaration scan 通过，仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Native forbidden scan 通过：无 Metal / QuartzCore import，无 AppKit / QuartzCore / Metal object allocation，无 pointer / handle / `Class` / `id` return 或静态保存模式。
- Owner header / stop-line scan 通过。
- `runtime_state.cj` 行数仍为 `10065`；`runtime/cjgui/cjpm.toml`、smoke native files、`runtime_state.cj` 均无 diff。
- GitNexus upstream impact 对上游 endpoint / default draft 已记录 not found / UNKNOWN、`impactedCount=0`，无 HIGH / CRITICAL；GitNexus `detect_changes(scope=unstaged)` 返回 `Risk level: low`、`Affected processes: 0`。

## 下游指向

唯一后续入口固定为：

该入口已由 [real NSView allocation feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer platform object token-backed NSView object table preflight decision`

该入口必须从 docs-only preflight 开始，不得跳过 object allocation risk review，不得把 no-object callable 包装成 object creation permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-object creation callable 从 first implementation 进入 manifest stabilization closure。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_no_object_creation_call.cj`；truth 固定为 no-object creation fail-closed facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、pointer / handle、object table、token binding、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，当时固定为 `P1 internal Renderer platform object real NSView allocation preflight decision`；当前已由 real `NSView` allocation feasibility stage 接续，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
