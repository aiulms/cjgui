# 可绘制纹理生命周期实现恢复封账复核

## 本轮结论

本轮完成 docs-only / evidence-first recovery 复核，选择 A：production drawable lifetime 暂停，并把 visible-window ownership、bounded run loop、display-backed layer 与 cleanup co-ownership 拆成独立 `visible-window production harness` 分支。

本轮没有新增 runtime owner、native C ABI、probe、package route 或 public API；没有调用 production `nextDrawable`，没有配置 `colorAttachments[0]`，没有创建 command buffer / encoder，没有 `commit` / `present`，没有 GPU submission，也没有 renderer state write。

## 关键回答

- Isolated visible-window no-present evidence 只能保留为 feasibility evidence。它证明临时 probe 可以构造窗口环境并观察 `nextDrawable`，但不证明 production runtime 拥有 visible `NSWindow`、bounded run loop、display-backed layer、drawable token table、release / stale / double-release classification 或 descriptor / drawable / layer / device / view cleanup 共同所有权。
- Production drawable lifetime 仍缺 hard evidence：visible-window ownership、bounded production run loop、display-backed `CAMetalLayer` ownership、drawable acquire / classify / release lifecycle、cleanup order 与 headless / CI-like shell fail-closed 策略。
- 不应继续在 drawable acquire / release 上硬推。缺少 production harness 时调用 `nextDrawable` 会把 isolated probe 语义误升格为 runtime truth。
- Visible-window ownership、bounded run loop、display backing 与 cleanup co-ownership 应拆为独立 stage，先做 `P1 internal Renderer visible-window production harness preflight decision`。
- No-submit branch 已足够作为非显示链 milestone；pipeline descriptor、shader library / function、pipeline state、vertex buffer 与 draw input facts 已封账，但它们不替代 display / drawable chain。

## 固定边界

本轮不是 runtime truth，只是 docs-only / evidence-first recovery 复核；isolated probe 继续只作为 feasibility evidence 保留。

- 不授权 production drawable acquisition。
- 不授权 render pass descriptor color attachment。
- 不授权 render command encoder。
- 不授权 command buffer creation。
- 不授权 `commit` / `present`。
- 不授权 GPU submission / render。
- 不授权 renderer state write。
- 不授权 backend-ready truth。
- 不授权 public API / diagnostics。

## 同步结果

- 已同步 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)。
- 已同步 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 已同步 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 已同步 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)。
- 已同步 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)。
- 已同步 [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)。
- 已同步 [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)。
- 已同步 [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)。

## 验证记录

- 2026-06-21 本轮复核补记：CodeLattice 可调用，但本阶段只获得 static-only / low-confidence 项目级 evidence；`runtime/cjgui` compact overview 返回 single-project、`sourceFileCount=1015`、`symbolCount=0`、stale baseline，且没有执行 runtime/build/probe。本阶段为 docs-only recovery，没有执行 per-symbol implementation impact，也没有新增 runtime/native/script；复核仍以 first-slice manifest / closure / next-boundary、visible-window probe、drawable no-present acquisition、no-submit milestone、color attachment recovery、Metal device binding 与 `CAMetalLayer` runtime attachment manifests 为证据，并用 Markdown / reachability / public / protected scans 与 GitNexus detect-changes 兜底。
- 2026-06-21 本轮复核补记：重新读取 production drawable texture lifetime first slice、旧 drawable lifetime planning / recovery、drawable no-present、visible-window probe、no-submit milestone、color attachment recovery、Metal device binding 与 `CAMetalLayer` runtime attachment manifests 后，确认本阶段仍选择 A：暂停 production drawable lifetime implementation，并把 visible-window production harness 拆成独立后续分支。
- `git diff --check`：2026-06-21 本次复跑通过。
- Markdown absolute link check：2026-06-21 本次复跑检查项目 docs / README 范围内 2049 个 Markdown 文件、17471 个项目绝对链接，missing target 数量为 `0`。
- Reachability：2026-06-21 本次复跑确认 README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX 与三个 topic manifest 均能检索到本轮 recovery decision / closure / manifest 与完整后续入口 `P1 internal Renderer visible-window production harness preflight decision`，每个关键 needle 命中 8 个索引面。
- 中文标题与正文抽查：2026-06-21 复跑确认本轮 decision / closure / manifest 主标题均为中文，正文抽查包含中文说明，并且均包含“设计意图出口自检”。
- public declaration scan：2026-06-21 本次复跑确认本阶段未修改 `.cj`；全工作树 tracked `.cj` diff 中没有新增 public declaration。本轮没有新增 `.cj`、public C ABI 或 public diagnostics。
- protected path scan：2026-06-21 本次复跑确认 `runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 在本阶段没有 diff。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：2026-06-21 本次复跑输出 `Changes: 10 files, 2 symbols` / `Affected processes: 0` / `Risk level: low`；图谱只识别 README 标题级 symbols，按 GitNexus 文档变更有限覆盖处理，不作为完整安全证明。本阶段仍以文档读取、链接 / reachability / public / protected scans 作为 docs-only 兜底。
- 本轮未运行 `cjpm build` / smoke：本阶段为 docs-only recovery；没有修改 `.cj`、native 或 script。
- `git diff --check`：2026-06-17 复跑通过。
- Markdown absolute link check：2026-06-17 复跑检查项目 docs / README 范围内 2025 个 Markdown 文件、17308 个项目绝对链接，missing target 数量为 `0`。
- Reachability：README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX 与三个 topic manifest 均能检索到本轮 recovery decision / closure / manifest 或 `visible-window production harness preflight` 接续。
- 中文标题与正文抽查：本轮 decision / closure / manifest 主标题均为中文，正文抽查包含中文说明。
- protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 在本阶段未出现 diff。
- public declaration scan：2026-06-17 复跑 `git diff -- '*.cj' | rg '^\+.*public'` 无匹配；本阶段没有新增 `.cj` 或 public API。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：2026-06-17 复跑返回 affected processes `0` / risk `low`；图谱只识别 README 标题级改动，未覆盖当前工作树所有未提交文件，按源码和 docs scan 兜底。
- 本轮未运行 `cjpm build` / smoke：本阶段为 docs-only recovery，未修改 `.cj`、native 或 script。

## 后续入口

`P1 internal Renderer visible-window production harness preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是。production drawable lifetime implementation recovery 固定为 visible-window production harness 分支拆分。
- 本轮是否改变 canonical tail / endpoint：否。没有新增 runtime owner；仍引用 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` 与 `CjguiInternalRendererNoDrawInputBundleReadiness`。
- 本轮是否改变 owner / truth / stop-line：是。truth 明确 isolated probe 不能升格；stop-line 保持 no production `nextDrawable`、no color attachment、no encoder、no present、no render。
- 本轮是否改变唯一 next opening：是。唯一后续入口固定为 `P1 internal Renderer visible-window production harness preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
