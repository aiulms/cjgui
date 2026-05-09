# P1 渲染器 native bridge no-resource callable runtime 接入阶段 manifest 收口复核

日期：2026-05-09

状态：manifest closure / validation passed

## 封账结论

本阶段封账为 planning owner + native symbol probe，而不是实际 runtime FFI declaration。

`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()` 是当前阶段 canonical endpoint。它只确认 internal declaration planning、no-resource callable allowlist、link separation fallback 与 no-public-surface facts。

新增 `verify_native_bridge_no_resource_symbols.sh` 让四个 no-resource callable 的 object-level symbol presence 可重复验证，但不接 runtime FFI，不执行 callable，不修改 build config。

## 实际写集

- `runtime/cjgui/src/runtime_renderer_native_bridge_ffi_declaration.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-ffi-declaration-stage-preflight-decision.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-runtime-ffi-declaration-stage-closure-review.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-callable-runtime-integration-stage-next-boundary-decision.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest-stabilization-closure-review.md`
- README / tracker / plans index / runtime README / design intent index / topic manifests / upstream manifests downstream 指向。

## 仍保持的边界

- 未新增 public API。
- 未新增 public diagnostics。
- 未写真实 runtime FFI declaration。
- 未新增 runtime FFI call。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 package / build config。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未导入 Cocoa / Metal / QuartzCore。
- 未触碰 smoke native files。
- 未写 renderer state，未触碰 `runtime_state.cj`。
- 未创建 backend-ready truth。

## 验证记录

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过，production skeleton isolated compile 成功。
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`：裸 shell 首次因 `cjpm` 不在 `PATH` 失败；按仓颉 toolchain env 重跑后通过，继续证明 `cjpm build` 与 production skeleton isolated compile 分离。
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`：通过，四个 no-resource callable object-level symbol presence 均存在，未发现 forbidden native/runtime token。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-no-resource-runtime-integration-target --skip-script`：通过，仍有既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，auto-close log assertions passed。
- `git diff --check`：通过。
- 新 runtime / script / docs whitespace check：通过。
- Markdown absolute link missing target check：通过。
- README / tracker / plans README / runtime README reachability：通过。
- 中文标题与中文正文抽查：通过，已将本轮 closure 中的英文小标题改为中文。
- protected path check：通过，`runtime/cjgui/src/runtime_state.cj` 行数仍为 `10065`，`runtime/cjgui/cjpm.toml` 与 smoke native files 未修改。
- comment-aware public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- native/build forbidden scan：通过，未新增 resource callable、Cocoa / Metal / QuartzCore import、AppKit / Metal object、native pointer return、runtime FFI call 或 public API。
- owner header / stop-line scan：通过，新增 owner 文件头包含 Owner / Truth / Stop-line / Same-shape Boundary Brake。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：通过，risk `low`，changed_count `18`，affected_count `0`，affected processes 为空。

## 下游阶段

下游 [native bridge FFI syntax / link stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-ffi-syntax-link-stage-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-ffi-syntax-link-stage-manifest-stabilization-closure-review.md) 已完成。该 downstream 证明 no-resource callable 可由仓颉 `foreign func` 声明并 direct `cjc` link 调用，但仍不修改 runtime package link，不新增 runtime FFI call，不创建 native object，不扩 public API。

## 后续入口

`P1 internal Renderer native bridge package link integration preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，完成 no-resource callable runtime integration stage manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，当前阶段 endpoint 是 `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime owner 与 symbol probe；truth 仅限 planning / allowlist / link separation facts；stop-line 继续禁止真实 FFI、native object、public API、renderer state write。
- 本轮是否改变唯一 next opening：是，本阶段原转为 `P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`；下游 FFI syntax / link stage 已接续，当前唯一入口为 `P1 internal Renderer native bridge package link integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
