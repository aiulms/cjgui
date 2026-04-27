# P1 Minimal App / Window Lifecycle Runtime Execution Card

日期：2026-04-26

类型：execution card

状态：完成；创建本卡本身不等于实现；不自动开启 runtime implementation

## 0. Authority

本卡的唯一 implementation authority 是：

- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)

本卡必须同时吸收以下 red-team guardrails：

- [2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)

本卡只把未来 first slice 收束为一个极窄的 minimal runtime skeleton / app-window lifecycle surface authorization。任何实现仍必须由后续明确 opening 执行；本卡不写 runtime 代码、不创建 runtime 目录、不修改 smoke。

## 1. Future First Slice Scope

未来 first slice 最多只能创建最小 runtime skeleton / app-window lifecycle surface，用于把 smoke 经验迁移为正式 runtime 的边界形状，而不是迁移 smoke 代码。

允许的未来目标：

- 新建独立 runtime 目录骨架，避免继续扩写 `labs/macos_bridge_smoke`。
- 声明 app lifecycle owner、window lifecycle owner、main-thread queue / drain owner。
- 声明 platform adapter 与 core runtime 的边界。
- 声明最小 app/window lifecycle surface 的占位形状。
- 保留 single-window first slice。
- 把 handle table / generation、multi-window、target update、Renderer / Scene / Widget / Layout / DSL 都保留为 future slot。
- 继续把 smoke guard 作为旧链路验证命令。

不允许的未来目标：

- 不复用 `labs/macos_bridge_smoke` 作为 runtime 目录。
- 不迁移 smoke 代码。
- 不直接升格 smoke C ABI 为 public runtime API。
- 不暴露平台对象。
- 不实现真实 app run / event loop / window create / close / destroy 行为。
- 不实现 handle table / generation。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 command-list hash、pixel diff、baseline、offscreen renderer。
- 不进入 semantic tree / Action Router。
- 不创建治理 manifest。

## 2. Runtime Directory Authorization

未来 first slice 是否允许创建 runtime 目录：允许，但只能在后续 bounded implementation opening 中按本卡执行。

推荐最小目录根：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/`

未来 first slice 的最大 write set：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`
- future closure review under `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

如果 future implementation 判断 Cangjie code skeleton 仍过早，可以只创建 README / placeholder 文档；不得为了填满 write set 而写无意义代码。

## 3. Public Surface Boundary

runtime skeleton 是否允许包含 public API：不授权稳定 public runtime API。

未来 first slice 最多允许：

- 在 `runtime/cjgui` 内声明实验期、非稳定、非 C ABI 的 app/window lifecycle surface 占位。
- 使用脱水的 Cangjie 层概念，例如 `AppLifecycle`、`WindowLifecycle`、`WindowToken`、`LifecycleError` 这类候选名称。
- 明确这些名称不是正式 public API，不得向外承诺稳定签名、ABI 或行为。

未来 first slice 不允许：

- 新增 public C ABI。
- 新增可被 smoke 或外部示例依赖的正式 runtime API。
- 暴露 `NSWindow*`、`NSView*`、`CAMetalLayer*`、`MTLDevice*`、`MTLCommandQueue*`、`NSEvent*`、`CGImageRef`、Objective-C `id` 或任何平台对象裸指针。
- 把 smoke 的 `cjgui_app_run()`、`last_error`、auto-close、clear-color render path 或 diagnostics 字段升格为 public runtime contract。

## 4. App Lifecycle Surface

未来 first slice 的 app lifecycle surface 最多允许占位：

- `init`：声明 app lifecycle 初始化 owner。
- `run`：声明 event loop 未来 slot，但不实现真实 event loop。
- `requestQuit`：声明受控退出请求 slot。
- `shutdown`：声明关闭后资源释放 slot。
- `drainMainThreadQueue`：声明主线程 queue / drain owner，但不实现跨线程 runtime 队列。

边界：

- macOS event loop 必须属于 macOS platform adapter / bridge，不属于 core runtime truth。
- core runtime 不得持有 `NSRunLoop`、`NSEvent`、`dispatch_main` 或 Objective-C callback truth。
- core runtime 未来只能消费脱水 lifecycle / input / frame step / queue drain 等抽象事实。
- `tick` / `step` / input buffer 可以作为 future candidate，但本卡不承诺游戏引擎式 API。

## 5. Window Lifecycle Surface

未来 first slice 的 window lifecycle surface 最多允许占位：

- `createWindow`：声明未来 create slot；不实现真实窗口创建。
- `requestClose`：声明 close request 必须进入主线程 lifecycle path。
- `destroy` / `release`：声明单一路径、幂等销毁约束。
- `WindowToken`：声明 opaque token 候选，不是长期 public handle。
- `WindowState`：声明 created / closeRequested / destroyed 等状态候选。

边界：

- destroyed / stale token 后不得复活窗口。
- stale message 应安全丢弃或在 future error strategy 中分类；不得直接触碰平台对象。
- auto-close、manual-close、future async close 必须汇入同一 lifecycle state machine。
- 第一刀允许保持 single-window，因为当前没有 public handle、target update、多窗口 routing 或 handle generation。

## 6. Handle Table / Generation

未来 first slice 不允许实现 handle table / generation。

原因：

- 目标仍是 minimal skeleton，不是多窗口 runtime。
- 当前 first slice 可以继续 single-window。
- 尚未开放 public handle。
- 尚未开放 target update message。
- 尚未开放 multi-window routing。

必须保留的 future slot：

- 一旦进入 multi-window、target update、public handle 或 async target message，就必须另开 execution card，最小实现 handle table / generation validation。

## 7. Platform Adapter / Core Runtime Boundary

platform adapter 负责：

- 平台 event loop 接入。
- 平台窗口对象持有。
- 平台消息转译。
- 平台错误转译。
- AppKit / Metal / CoreGraphics 对象生命周期。

core runtime 负责：

- 脱水 lifecycle state。
- 脱水 window token / state。
- 脱水 queue drain fact。
- 脱水 error record。
- 与平台无关的最小 contract 形状。

core runtime 不得：

- 持有平台对象。
- 假定 AppKit runloop 是 runtime 真相。
- 把 Objective-C callback 作为 core truth。
- 把 macOS smoke bridge 的 C ABI 形态当作跨平台或正式 runtime API。

## 8. Error Strategy Boundary

future runtime 不能直接迁移 smoke `last_error`。

原因：

- smoke `last_error` 是实验期观察口。
- 它是全局状态，不适合作为长期并发错误系统。
- 它不能可靠关联调用、窗口、生命周期阶段或线程。
- 它不能承载 future multi-window / async / Agent action 场景。

未来 first slice 最多允许声明：

- `LifecycleError` 或等价脱水错误占位。
- 错误必须调用关联。
- 错误不得依赖全局 mutable `last_error`。
- 并发安全错误策略保留为 future implementation slot。

## 9. Smoke Guard Boundary

smoke guard 继续作为旧链路不退化验证，而不是正式 runtime test framework。

未来 first slice 的验证可以继续运行：

- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`

但必须明确：

- smoke guard 只保护 smoke bridge。
- screenshot / frame hash harness 只保护 smoke evidence line。
- 它们不是 runtime visual regression framework。
- 它们不能证明 future runtime API 正确。
- 它们不能要求 runtime 迁就 smoke diagnostics 字段。

## 10. Red-Team Guardrails Absorbed

### 10.1 Governance

本卡吸收以下治理约束：

- 不扩大每轮必读历史文档集。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。
- 只登记 future `P1 governance compaction / truth manifest preflight`，不在本卡实现治理 manifest。

### 10.2 Pixel / Hash

本卡吸收以下验证证据约束：

- 不进入 pixel diff / baseline。
- 不保存或输出 hash value。
- 不实现 command-list hash。
- 只登记 future `P1 render evidence model / command list hash preflight`，不在本卡定义 Display List / Command Buffer API。

### 10.3 macOS Overfitting

本卡吸收以下平台边界约束：

- AppKit event loop 只能属于 macOS platform adapter / bridge。
- core runtime 不得持有 `NSRunLoop`、`NSEvent`、`dispatch_main` 或 Objective-C callback truth。
- core runtime 未来只能消费脱水 lifecycle / input / frame step / queue drain 等抽象事实。
- `tick` / `step` / input buffer 只作为 future candidate，本卡不承诺游戏引擎式 API。

### 10.4 Semantic Tree

本卡吸收以下 semantic guardrails：

- 不实现 semantic tree / Action Router。
- 只登记 future lazy / dirty-driven semantic projection invariant。
- render hot path 不维护完整 semantic tree。
- semantic dirty 与 render dirty 未来必须分离。

## 11. Future Implementation Verification

未来 bounded implementation first slice 至少必须验证：

- `bash -n` 或等价语法检查适用于新增脚本时；若无脚本则说明不适用。
- 若新增 Cangjie skeleton，必须运行可用的 Cangjie 语法 / build 检查；若工具链不支持该骨架构建，closure review 必须记录原因。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- forbidden write set 未修改。
- 新 runtime 目录没有引用 `labs/macos_bridge_smoke` 内部 C ABI 作为 public API。
- 新 runtime skeleton 没有平台对象裸指针。
- 新 runtime skeleton 没有 Renderer / Scene / Widget / Layout / DSL。
- 新 runtime skeleton 没有 semantic tree / Action Router。
- 新 runtime skeleton 没有 command-list hash、pixel diff、baseline、offscreen renderer。
- closure review 能从 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md` 和 `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md` 找到。
- `git diff --check` 通过。

## 12. Future Forbidden Write Set

未来 first slice 禁止修改：

- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- screenshot / frame hash harness
- public C ABI / public runtime API
- native bridge
- Renderer / Scene / Widget / Layout / DSL
- cross-platform backend
- text / input / IME / accessibility
- semantic tree / Action Router
- command-list hash / pixel diff / baseline / offscreen renderer
- `CJGUI_TRUTH_MANIFEST.md`

## 13. Stop-Line For This Card Creation

本轮创建 execution card 的强制 stop-line：

- 不写 runtime 代码。
- 不创建 runtime 目录。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 harness。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不实现 app lifecycle。
- 不实现 window lifecycle。
- 不实现 handle table / generation。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本 / 输入法 / 无障碍。
- 不做 pixel diff / baseline / offscreen renderer。
- 不实现 command-list hash。
- 不实现 semantic tree / Action Router。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 14. Next Opening

本卡之后的下一条 opening 建议为：

- `P1 minimal app/window lifecycle runtime skeleton bounded implementation first slice`

该 opening 不自动开启实现。它只能在用户明确批准后执行，并且必须严格遵守本卡 write set、forbidden write set、red-team guardrails 和 stop-line。
