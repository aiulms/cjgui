# P1 渲染器 native bridge callable C ABI 预检决议

日期：2026-05-09

状态：docs-only preflight / no callable implementation

## 文件定位

本决议回答 native bridge `cjpm` integration first implementation 封账后，是否可以打开 callable `C ABI` runway，以及第一步是否仍应停在 internal value boundary，而不是直接修改 production native `.h` / `.m`、实现 callable `C ABI` 或接 runtime FFI。

本轮不批准修改 `runtime/cjgui/native/cjgui_native_bridge.h`、`runtime/cjgui/native/cjgui_native_bridge.m`、`runtime/cjgui/cjpm.toml`、smoke native files、runtime `.cj` FFI declaration、public API 或 `runtime_state.cj`。

## 证据读取

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [native bridge cjpm integration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-manifest.md)
- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)
- [production native bridge header skeleton](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- [production native bridge implementation skeleton](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)
- [cjpm integration boundary script](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh)
- [skeleton compile probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh)

## 预检结论

可以打开 callable `C ABI` planning runway，但第一步仍必须是 internal value boundary。当前证据只证明 production skeleton、isolated skeleton compile、build system admission facts 与 `cjpm` boundary script 已经足够支撑 callable surface 的规划，不证明 native bridge callable implementation 可以落地。

第一批 callable `C ABI` 候选只能规划 status / capability / no-resource admission 形态，包括 bridge surface version query、bridge capability / status query、main-thread check query、no-resource init admission query 和 error taxonomy query。它们仍不得创建 native object，不得返回 native pointer，不得触发 destroy，不得获取 drawable，不得提交 GPU work。

必须先定义 callable naming policy，避免复用 smoke lab 的 `cjgui_app_run` / `cjgui_last_error_*` 名称。production callable 命名后续必须与 smoke callable 名称隔离，避免把 smoke implementation 误认为 runtime callable surface。

callable `C ABI` 与仓颉 runtime FFI 必须拆成两阶段：先做 native callable implementation preflight 与 isolated probe，再另开 runtime FFI declaration preflight。本轮不允许新增 runtime `.cj` FFI declaration。

## 候选比较

- A 胜出：`P1 internal Renderer native bridge callable C ABI planning value boundary bundle implementation`。理由是 build glue 与 skeleton contract 足够支撑 planning value boundary，但不足以直接实现 callable `C ABI`。
- B 暂缓：直接 callable `C ABI` first implementation preflight。该路线需要先封账 planning owner，否则 callable naming、no-resource guard 与 FFI separation 仍不够显式。
- C 暂缓：production status taxonomy hardening。当前 taxonomy 可先作为 planning owner 的字段事实，后续再决定是否硬化。
- D 拒绝：直接修改 production `.h` / `.m` 或实现 callable `C ABI`。这会越过本轮 no implementation stop-line。
- E 拒绝：直接接 FFI 或新增 runtime `.cj` FFI declaration。runtime FFI 必须晚于 native callable 与 isolated probe。
- F 拒绝：创建 AppKit / Metal object、native handle、raw pointer、GPU work、renderer state write、public diagnostics 或 public API。

## 同形边界刹车

不得把 build boundary、skeleton compile、C ABI surface contract、token ownership、teardown planning、build system admission、`cjpm` boundary script 或 callable planning facts 包装成 callable implementation permission、FFI permission、native bridge implementation permission、native-handle permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

若进入下一步，新增 owner 必须表达 callable naming、status / capability callable admission、no-resource callable guard、runtime FFI separation 与 no-callable-C-ABI readiness facts，而不是把上游 endpoint 薄包装成 callable-ready。

## 停止线

- no production native `.h` / `.m` modification。
- no callable `C ABI` implementation。
- no runtime `.cj` FFI declaration。
- no `runtime/cjgui/cjpm.toml` modification。
- no package / build config modification。
- no smoke native modification。
- no native handle / raw pointer。
- no raw pointer return。
- no AppKit / Metal object creation。
- no Cocoa / Metal / QuartzCore import in production skeleton。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics / API。
- no module-level mutable `var`。

## 设计意图出口自检

- 本轮是否改变主题状态：是。主题从 native bridge callable `C ABI` preflight 进入 callable `C ABI` planning value boundary。
- 本轮是否改变 canonical tail / endpoint：预检本身不改变 runtime endpoint；下一步若执行 A，将新增 `CjguiInternalRendererNoCallableCAbiReadiness`。
- 本轮是否改变 owner / truth / stop-line：预检本身不新增 owner；下一步 owner truth 限定为 callable planning facts，stop-line 继续禁止 implementation / FFI / native object。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge callable C ABI planning value boundary bundle implementation`。
- 是否同步 topic manifest：是，本轮后续宏包同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。
- 已同步的 topic manifest：见本宏包 closure 与 manifest stabilization closure 的出口自检。

## 唯一后续入口

`P1 internal Renderer native bridge callable C ABI planning value boundary bundle implementation`
