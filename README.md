# CJGUI

最后更新：2026-05-01

CJGUI 是一个围绕仓颉语言（Cangjie）的原生 GUI runtime / framework 实验项目。
它的长期目标是探索一条上层尽量保持仓颉原生、底层通过极窄平台桥接接入窗口系统和渲染后端的桌面 GUI 路线。

当前项目处于 `P1 runtime 受限实现 / runtime state transition runway`。仓库已经完成 macOS AppKit / Metal smoke、主线程 UI message queue、自动化 GUI 验证、用户可见窗口截图验证和 frame hash 可行性等实验链路；`runtime/cjgui` 也已经从最小 skeleton 推进到一组 internal-only runtime owner files。

这还不是可用的 GUI 框架，也不提供稳定 public API。现阶段更像一个有严格边界和审计记录的系统编程实验室：先把 app lifecycle、window lifecycle、platform adapter、runtime state、Action Router、handoff、queue boundary、验证链路和 stop-line 讲清楚，再逐步进入真实 runtime。

## 当前推进到哪里

- `runtime/cjgui` 已经可以作为最小 internal package 构建，并拆出了 app / window lifecycle、platform adapter、error boundary、runtime state、scheduler ingress、runtime ingress、Action Router、Action Handoff 和 Queue 相关 owner files。
- Action Router 主线已从 action intent / admission / routing 推进到 guarded execution、handoff downstream consumer 与 queue-adjacent integration；这些仍是 value-style facts，不是真实 action side effect。
- Queue 主线已从 admission 推进到 owner handoff、permission gate、staging、enqueue dry-run、value-style storage、commit gate、committed snapshot、immutable value-store owner shell、store write admission、immutable store write commit、write failure / rollback model、mutable store shell、mutable write admission、owner-local mutable write commit、mutable write result handoff、process-local write preflight、owner-local write realization、owner-local write result handoff、public boundary admission、public surface policy、public API admission、public result shape、public API shell、public exposure gate / symbol readiness 与 experimental public submit shell value facts；这些仍不写真实 queue storage，也不创建 global mutable queue。
- 当前所有 runtime 进展都保持 internal-only：不公开 public runtime API / public C ABI，不接 AI provider / prompt / external agent，不接真实 event loop / scheduler / queue drain。
- 项目治理也已经补上了文件体积闸门、AI 资源效率门、Tail Endpoint Exit Gate 和代码注释充分性门，避免 P1 被无限 thin wrapper 或不可维护注释债拖偏。

## 快速入口

- 想知道项目方向：看 [GUI_PROJECT_DIRECTION.md](docs/core/GUI_PROJECT_DIRECTION.md)。
- 想接着干活：看 [GUI_TASK_TRACKER.md](GUI_TASK_TRACKER.md)，以 `当前 active opening`、`当前 next opening` 和 `当前建议的下一步` 为准，不默认全文阅读历史流水。
- 想看当前 runtime execution runway：看 [2026-04-30-p1-runtime-tracker-compaction-execution-runway.md](docs/plans/2026-04-30-p1-runtime-tracker-compaction-execution-runway.md)。
- 想看正式 runtime 骨架和内部 stop-line：看 [runtime/cjgui](runtime/cjgui)。
- 想看 macOS 桥接实验：看 [labs/macos_bridge_smoke](labs/macos_bridge_smoke)。
- 想查历史决策：看 [docs/plans/README.md](docs/plans/README.md)。
- 想看 GUI framework 行业排雷雷达：看 [gui-framework-pitfalls-intelligence.md](docs/research/gui-framework-pitfalls-intelligence.md)。它是按需雷达，不是每轮 implementation 的默认必读项。
- 想看 AI-native GUI runtime 架构 intake：看 [ai-native-gui-runtime-architecture-intake.md](docs/research/ai-native-gui-runtime-architecture-intake.md)。它只在语义投影、Action Router、Hard / Soft Cycle、AI 协作边界前按需读取。
- 想看仓颉 1.1 owner / tooling / FFI 能力边界：看 [cangjie-1.1-owner-tooling-ffi-capability-intake.md](docs/research/cangjie-1.1-owner-tooling-ffi-capability-intake.md)。它只在 owner 语言保证、FFI / platform bridge、debug / profiling / memory tooling 或未来语言能力迁移前按需读取。
- 想看代数效应 / ECS / CRDT / Scene-DisplayList 这些未来架构雷达：看 [2026-05-01-p1-ai-native-architecture-radar-future-plan.md](docs/plans/2026-05-01-p1-ai-native-architecture-radar-future-plan.md)。它只记录未来规划，不改变当前 P1 implementation runway。
- 想看文档分区：看 [docs/README.md](docs/README.md)。
- 想控制 AI 每轮读多少上下文：看 [CJGUI_CONTEXT_LOADING_POLICY.md](docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md)。

## 当前不是什么

- 不是成熟 GUI toolkit。
- 不提供稳定 public runtime API。
- 不提供 public C ABI。
- 不是跨平台抽象层。
- 不是已经具备真实 queue storage、enqueue、drain、scheduler 或 event loop 的 runtime。
- 不是已经具备真实 Action execution、AI provider、prompt 接入或外部 Agent 公共入口的框架。
- 不包含声明式 UI DSL、控件库、布局系统、文本系统、IME 或无障碍实现。
- 不把 smoke demo、截图验证、frame hash 或实验诊断当成长期 runtime contract。

## 仓库结构

- `runtime/cjgui/`：未来正式 runtime 的 internal package，目前承载 runtime state、lifecycle、ingress、Action Router / Handoff、Queue value-style boundary 等 owner files；仍不提供 public API。
- `labs/`：实验室 smoke 和验证脚本，当前主要是 macOS AppKit / Metal bridge smoke。
- `docs/core/`：项目方向、治理、风险、AI 原生 UI 语义和协作边界。
- `docs/setup/`：本地工具链、构建、资料索引和仓颉上游倒推 / 贡献账本。
- `docs/plans/`：每一刀 preflight、execution card、closure review 的历史索引。
- `docs/research/`：sidecar research、行业排雷和不阻塞 runtime 主线的架构风险情报。
- `GUI_TASK_TRACKER.md`：当前阶段判断、healthy stop-line、active / future openings。

本机工作区可能还包含 `sources/`、`repos/`、`reference_repos/` 等资料镜像和参考仓库；它们通常由各自 Git 仓库管理，不作为 CJGUI 根仓库的一部分提交。

## 个人工作区入口

如果以后上下文丢失，优先按这个顺序读取：

1. [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)：总入口和文档索引。
2. [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)：当前状态、stop-line、下一步 opening。
3. [docs/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/README.md)：文档中心和目录职责。
4. [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)：项目方向和长期边界。
5. [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)：开工门禁和 preflight / gate / closure 规则。
6. [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)：已识别风险与盲点总账。
7. [CJGUI_CONTEXT_LOADING_POLICY.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md)：AI 每轮最小上下文装载策略，避免过量阅读。
8. [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)：历史 preflight / execution card / closure review 索引。

当前下一步以 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 的 `当前 next opening` 为准。

最新 Queue public submit Bool result hardening closure：[P1 internal Queue public submit Bool result hardening closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-internal-queue-public-submit-bool-result-hardening-boundary-closure-review.md) 已完成；当前 recommended next opening 是 `P1 internal Queue public submit Bool result hardening closure / next public submit result-boundary decision`。本轮新增 internal owner `runtime_queue_public_submit_result.cj`，只消费 `CjguiInternalQueueExperimentalSubmitResult`，固定 Bool shell result contract、diagnostic projection、no-stable-compatibility 和 no-real-queue-write guarantee；当前 public symbol allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。继续禁止新增第二个 public symbol、修改 Bool-only 签名、structured public return、`enqueue` 命名、public C ABI、real enqueue、storage write、drain、scheduler / event loop / runtime cycle 和 `runtime_state.cj` 修改。

阶段健康 checkpoint：[P1 runtime progress health checkpoint](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-runtime-progress-health-checkpoint.md) 已记录当前推进节奏与模型债务。它只用于换会话、大方向判断或进入高风险边界前恢复上下文，不是每轮 implementation 必读项。

当前 runtime package / first-compilable source 边界文档：

- [2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md)
- [2026-04-26-p1-first-compilable-runtime-source-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-execution-card.md)
- [2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md)
- [2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)
- [2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md)
- [2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md)
- [2026-04-26-p1-first-internal-runtime-type-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-execution-card.md)
- [2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md)
- [2026-04-26-p1-error-fact-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)
- [2026-04-26-p1-error-fact-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)
- [2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md)
- [2026-04-26-p1-error-taxonomy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-boundary-execution-card.md)
- [2026-04-26-p1-error-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md)
- [2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md)
- [2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-execution-card.md)
- [2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md)
- [2026-04-27-p1-app-lifecycle-no-op-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-no-op-transition-execution-card.md)
- [2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md)
- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md)
- [2026-04-27-p1-app-lifecycle-mini-slice-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-mini-slice-compaction.md)
- [2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-construction-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md)
- [2026-04-27-p1-first-internal-window-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-window-lifecycle-state-execution-card.md)
- [2026-04-27-p1-window-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-state-shape-execution-card.md)
- [2026-04-27-p1-window-lifecycle-construction-no-op-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-construction-no-op-transition-execution-card.md)
- [2026-04-27-p1-window-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-first-state-changing-transition-execution-card.md)
- [2026-04-27-p1-lifecycle-parity-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-lifecycle-parity-compaction.md)
- [2026-04-27-p1-platform-adapter-fact-ingestion-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-ingestion-execution-card.md)
- [2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-execution-card.md)
- [2026-04-27-p1-runtime-internal-concept-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-runtime-internal-concept-compaction.md)
- [2026-04-27-p1-platform-fact-to-lifecycle-ingestion-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-fact-to-lifecycle-ingestion-execution-card.md)
- [2026-04-27-p1-internal-lifecycle-coordination-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-execution-card.md)
- [2026-04-27-p1-internal-lifecycle-coordination-sanity-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-sanity-execution-card.md)

## 当前已确认

### 1. 官方文档可访问

- 官方文档页 `https://cangjie-lang.cn/docs?url=%2F1.1.0%2Fdev-guide%2Fsource_zh_cn%2Ffirst_understanding%2Fbasic.html` 可以访问。
- 页面显示版本为 `1.1.0 STS`。

### 2. 桌面应用现状

- 截至 2026-04-24，仓颉可以构建并运行在 `Linux`、`macOS`、`Windows` 上的原生可执行程序。
- 这意味着命令行工具、本地工具、终端程序、后台服务都是现实可行的。
- 我没有查到成熟的一等公民官方桌面 GUI 方案，暂时还不能把它看成 `Qt`、`Flutter`、`WPF`、`Electron` 这一类成熟路线。
- 当前更明确、也更官方的应用方向仍然是 `HarmonyOS` 应用开发。

### 3. 桌面开发的现实路线

- `CLI/TUI`：当前最稳的路线
- `WebView 壳 + 仓颉逻辑`：适合快速做跨平台 GUI 原型
- `CJQT`：社区路线，更接近传统原生桌面 GUI
- `仓颉核心 + 其他 GUI 壳`：更适合严肃的跨平台产品工程

### 4. 一个关键区分

- “仓颉可以做桌面软件”这件事是成立的。
- “仓颉已经有成熟官方桌面 GUI 方案”这件事目前还不能明确成立。

## 已查过的来源

- https://cangjie-lang.cn/docs?url=%2F1.1.0%2Fdev-guide%2Fsource_zh_cn%2Ffirst_understanding%2Fbasic.html
- https://cangjie-lang.cn/
- https://docs.cangjie-lang.cn/docs/1.0.0/user_manual/source_zh_cn/deploy_and_run/run_cjnative.html
- https://docs.cangjie-lang.cn/docs/1.0.1/user_manual/source_zh_cn/FFI/cangjie-c.html
- https://docs.cangjie-lang.cn/docs/0.53.18/guide/source_zh_cn/%E4%BB%93%E9%A2%89%E9%B8%BF%E8%92%99%E5%BA%94%E7%94%A8%E5%BC%80%E5%8F%91%E5%85%A5%E9%97%A8%E6%8C%87%E5%8D%97.html
- https://github.com/gtn1024/awesome-cangjie
- https://blog.gitcode.com/4586bc120c915768be38192be9374113.html

## 后续待继续追的问题

- 仓颉在真实生产环境里的服务端能力到底成熟到什么程度？
- 仓颉相对 `Go`、`Rust`、`ArkTS` 的语言层优势到底是什么？
- 当前 `C` 互操作在实践里到底完整到什么程度？
- 哪条第三方 GUI 路线长期最可维护？
- 如果认真学仓颉，一条现实的学习路线应该怎么走？

## 新讨论：自己做 GUI 框架

### 初步判断

- 在仓颉之上构建 GUI 框架，技术上是可行的。
- 关键支撑点是 `C` 互操作，而不是仓颉内建 GUI 栈。
- 仓颉可以暴露和调用 `C` ABI 函数、回调、指针、静态库、动态库。
- 这让下面这些事情都变得现实：
  - 给现有原生库或图形库做薄绑定
  - 先做一个小型桌面运行时
  - 在渲染后端之上继续长出自己的组件层

### 现实建议

- 不要一上来就做 `Qt` 级别的大框架。
- 先从一个最窄的目标开始：
  - `窗口 + 事件循环 + 输入 + 绘制`
- 之后再逐步补：
  - 布局
  - 组件树
  - 文本渲染
  - 输入法 / 无障碍
  - 打包和工具链

### 重要工程风险

- 仓颉当前最强的是 `C` 互操作，不是 `C++` 互操作。
- 所以像 `Qt` 这类大型 `C++` GUI 生态，直接绑定会更难，通常需要一层 `C shim`。
- `AppKit`、`Win32`、`GTK` 这些平台之间的桌面差异非常大。
- 真正难的部分通常不是按钮，而是文本 shaping、输入法、无障碍、剪贴板、拖拽、高 DPI 这些系统级能力。

### 如果目标是为爱发电，而不是商业交付

- 那“值不值得”就不再主要由商业效率决定，而要看学习价值、架构美感和个人满足感。
- 在这个前提下，从零做一个 GUI 框架，是一个很合理的长期项目。
- 更推荐的 framing 是：
  - 先做桌面运行时
  - 再做渲染层
  - 再做布局和控件
  - 最后才做声明式 UI 系统

### 个人项目最适合的心态

- 不要试图一开始就和 `Qt`、`Flutter`、`SwiftUI` 竞争。
- 更适合把这个项目当成：
  - 仓颉生态实验
  - 系统编程练习
  - 框架设计实验室
- 成功标准不是功能对标，而是架构是否自洽、可讲清楚、可持续扩展。

### 一个人推进时的路线

- 阶段 1：先只做一个平台
- 阶段 2：先做一个窗口、一条事件循环、一个绘制面
- 阶段 3：再补文本、输入和布局
- 阶段 4：再做少量核心控件
- 阶段 5：再考虑声明式语法和响应式更新
- 阶段 6：最后视情况扩到多平台后端

## 工作约定

- 以后每次继续讨论，都把新确认的结论追加到这里。
- 不确定的地方要明确标出来，不混成既定事实。
- 只要官方资料可用，就优先以官方资料为准。

## 本地文档准备情况

- 仓颉官方文档源已经可以直接通过 Git 仓库下载到本地。
- 文档中心在这里：
  - [docs/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/README.md)
- 本地文档索引在这里：
  - [LOCAL_DOCS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_DOCS.md)
- 本机仓颉工具链配置在这里：
  - [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- 从零构建和灾难恢复手册在这里：
  - [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- 仓颉问题判定、上游倒推与贡献账本在这里：
  - [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- 仓颉调用 C 的最小 smoke test 在这里：
  - [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)
- P0 macOS 桥接运行时 preflight 在这里：
  - [2026-04-25-p0-macos-bridge-runtime-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-runtime-preflight.md)
- P0 macOS 桥接 smoke demo 在这里：
  - [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)
- P0 macOS 桥接 closure review 在这里：
  - [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- P1 AppKit / Metal 桥接边界 preflight 在这里：
  - [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- P1 AppKit / Metal 桥接边界清理 execution card 在这里：
  - [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)
- P1 AppKit / Metal 桥接边界清理 closure review 在这里：
  - [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- P1 主线程 UI message queue preflight 在这里：
  - [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)
- P1 主线程 UI message queue execution card 在这里：
  - [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)
- P1 自动化 GUI 验证 preflight 在这里：
  - [2026-04-25-p1-automated-gui-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-preflight.md)
- P1 自动化 GUI 验证 execution card 在这里：
  - [2026-04-25-p1-automated-gui-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-execution-card.md)
- P1 frame metadata / render stats preflight 在这里：
  - [2026-04-25-p1-frame-metadata-render-stats-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-preflight.md)
- P1 frame metadata / render stats execution card 在这里：
  - [2026-04-25-p1-frame-metadata-render-stats-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-execution-card.md)
- P1 screenshot / Metal readback verification preflight 在这里：
  - [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)
- P1 Metal readback feasibility execution card 在这里：
  - [2026-04-25-p1-metal-readback-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-execution-card.md)
- P1 Metal readback feasibility closure review 在这里：
  - [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- P1 user-visible window verification evidence preflight 在这里：
  - [2026-04-25-p1-user-visible-window-verification-evidence-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-verification-evidence-preflight.md)
- P1 user-visible window screenshot feasibility execution card 在这里：
  - [2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md)
- P1 user-visible window screenshot feasibility closure review 在这里：
  - [2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)
- P1 user-visible window screenshot verification preflight 在这里：
  - [2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md)
- P1 user-visible window screenshot verification execution card 在这里：
  - [2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md)
- P1 screenshot verification artifact retention policy preflight 在这里：
  - [2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md)
- P1 screenshot artifact retention execution card 在这里：
  - [2026-04-25-p1-screenshot-artifact-retention-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-execution-card.md)
- P1 screenshot artifact retention closure review 在这里：
  - [2026-04-25-p1-screenshot-artifact-retention-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)
- P1 pixel diff / frame hash prerequisites preflight 在这里：
  - [2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)
- P1 frame hash feasibility execution card 在这里：
  - [2026-04-25-p1-frame-hash-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-execution-card.md)
- P1 frame hash feasibility closure review 在这里：
  - [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- P1 frame hash evidence review / baseline policy preflight 在这里：
  - [2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)
- P1 frame hash baseline-readiness diagnostics execution card 在这里：
  - [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md)
- P1 frame hash baseline owner / update policy preflight 在这里：
  - [2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md)
- P1 frame hash baseline owner / update policy execution card 在这里：
  - [2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md)
- P1 frame hash baseline owner / update policy closure review 在这里：
  - [2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)
- P1 frame hash source normalization policy preflight 在这里：
  - [2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)
- P1 frame hash source normalization policy execution card 在这里：
  - [2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md)
- P1 frame hash source normalization evidence closure / next-boundary preflight 在这里：
  - [2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md)
- P1 frame hash bounds / crop semantics policy preflight 在这里：
  - [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md)
- P1 frame hash bounds / crop semantics policy execution card 在这里：
  - [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md)
- P1 frame hash bounds / crop semantics readiness diagnostics closure review 在这里：
  - [2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md)
- P1 frame hash verification evidence line closure / runtime pivot preflight 在这里：
  - [2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md)
- P1 smoke-to-runtime boundary preflight 在这里：
  - [2026-04-26-p1-smoke-to-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- P1 minimal app/window lifecycle runtime boundary preflight 在这里：
  - [2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)
- P1 red-team risk intake / runtime guardrails preflight 在这里：
  - [2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- P1 minimal app/window lifecycle runtime execution card 在这里：
  - [2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)
- P1 minimal app/window lifecycle runtime skeleton closure review 在这里：
  - [2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- P1 self-drawn platform reduction / IME / accessibility guardrails preflight 在这里：
  - [2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
- P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight 在这里：
  - [2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md)
- P1 app lifecycle surface boundary preflight 在这里：
  - [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)
- P1 app lifecycle surface execution card 在这里：
  - [2026-04-26-p1-app-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md)
- P1 app lifecycle surface comment-only refinement closure review 在这里：
  - [2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
- P1 first internal app lifecycle state execution card 在这里：
  - [2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md)
- P1 app lifecycle platform readiness state execution card 在这里：
  - [2026-04-28-p1-app-lifecycle-platform-readiness-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-app-lifecycle-platform-readiness-state-execution-card.md)
- P1 window lifecycle platform readiness state execution card 在这里：
  - [2026-04-28-p1-window-lifecycle-platform-readiness-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-window-lifecycle-platform-readiness-state-execution-card.md)
- P1 readiness state helper bundle execution card 在这里：
  - [2026-04-28-p1-readiness-state-helper-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-state-helper-bundle-execution-card.md)
- P1 readiness coordination negative-path bundle execution card 在这里：
  - [2026-04-28-p1-readiness-coordination-negative-path-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-coordination-negative-path-bundle-execution-card.md)
- P1 internal runtime readiness aggregate bundle execution card 在这里：
  - [2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-execution-card.md)
- P1 window lifecycle surface boundary preflight 在这里：
  - [2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)
- P1 window lifecycle surface execution card 在这里：
  - [2026-04-26-p1-window-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-execution-card.md)
- P1 window lifecycle surface comment-only refinement closure review 在这里：
  - [2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)
- P1 platform adapter boundary preflight 在这里：
  - [2026-04-26-p1-platform-adapter-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-preflight.md)
- P1 platform adapter boundary execution card 在这里：
  - [2026-04-26-p1-platform-adapter-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-execution-card.md)
- P1 platform adapter surface comment-only refinement closure review 在这里：
  - [2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)
- P1 platform readiness fact semantics execution card 在这里：
  - [2026-04-28-p1-platform-readiness-fact-semantics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-platform-readiness-fact-semantics-execution-card.md)
- P1 error strategy boundary preflight 在这里：
  - [2026-04-26-p1-error-strategy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md)
- P1 error strategy boundary execution card 在这里：
  - [2026-04-26-p1-error-strategy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-execution-card.md)
- P1 error strategy surface comment-only refinement closure review 在这里：
  - [2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)
- P1 minimal runtime skeleton surface phase closure / compaction preflight 在这里：
  - [2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md)
- P1 runtime build/package boundary preflight 在这里：
  - [2026-04-26-p1-runtime-build-package-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)
- P1 runtime build/package boundary execution card 在这里：
  - [2026-04-26-p1-runtime-build-package-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-execution-card.md)
- GUI 项目的思考框架在这里：
  - [GUI_THINKING_FRAMEWORK.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_THINKING_FRAMEWORK.md)
- GUI 项目的方向说明在这里：
  - [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- AI 原生 UI 语义方向在这里：
  - [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)
- AI Action Router 协议实验归档在这里：
  - [AI_ACTION_PROTOCOL_EXPERIMENT.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_ACTION_PROTOCOL_EXPERIMENT.md)
- GUI 项目的治理总则在这里：
  - [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- GUI 项目的任务账本在这里：
  - [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- GUI 项目的风险账本在这里：
  - [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- 人类协作治理说明在这里：
  - [HUMAN_COLLABORATION_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/HUMAN_COLLABORATION_GOVERNANCE.md)
- `open-nwe` 对未来仓颉 GUI 的产品需求映射在这里：
  - [OPEN_NWE_PRODUCT_DEMAND_MAP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/OPEN_NWE_PRODUCT_DEMAND_MAP.md)
- AI 代码质量治理在这里：
  - [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- AI 开发宪法卡在这里：
  - [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- AI 执行卡模板在这里：
  - [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)
- 当前已本地化的主要文档源包括：
  - `cangjie_docs_1.1`
  - `cangjie_runtime_1.1`
  - `cangjie_stdx_1.1`
  - `docs_cangjie_master`
- 当前已本地化的辅助仓库包括：
  - `CangjieSkills`
  - `DocFlow`
- `CangjieSkills` 当前已接入本机 agents skill 搜索路径：
  - `/Users/jiangxuanyang/.agents/skills/cangjie-lang-features`
  - `/Users/jiangxuanyang/.agents/skills/cangjie-original-docs`
  - `/Users/jiangxuanyang/.agents/skills/cangjie-regulations`
  - `/Users/jiangxuanyang/.agents/skills/cangjie-std`
  - `/Users/jiangxuanyang/.agents/skills/cangjie-stdx`
  - `/Users/jiangxuanyang/.agents/skills/cangjie-toolchains`
- `DocFlow` 当前没有可直接安装的 `SKILL.md`；只保留为 knowledge / tool repo，未来如需接入应另开 wrapper / skillization preflight。
- 当前已本地化的 GUI 参考仓库包括：
  - `wgpui-openagents`
  - `gpui-zed`
  - `flutter`
  - `qt-therecipe`

### 这里的关键结论

- 我们后续不需要只依赖公开网页来查资料。
- 对后续自建 skill 来说，这些 Git 仓库比网页更适合作为长期真相源。

## GUI 参考仓库

- 这些仓库是后续做仓颉 GUI 框架时的重要参考样本。
- 当前统一放在：
  - [reference_repos](/Users/jiangxuanyang/Desktop/cangjie/reference_repos)

### 已准备好的参考仓库

- [wgpui-openagents](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/wgpui-openagents)
  - 对应站点：`https://docs.openagents.com/wgpui`
  - 用途：参考 `WGPUI` 的工程组织、渲染与 UI 设计思路

- [gpui-zed](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/gpui-zed)
  - 对应站点：`https://www.gpui.rs/`
  - 用途：参考 `GPUI` 的事件系统、渲染模型、桌面框架抽象

- [flutter](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/flutter)
  - 源仓库：`https://github.com/flutter/flutter`
  - 用途：参考大规模 UI 框架的工程结构、工具链组织、跨平台经验

- [qt-therecipe](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/qt-therecipe)
  - 源仓库：`https://github.com/therecipe/qt`
  - 用途：参考传统桌面 GUI 生态的封装方式与绑定层设计

## 个人项目方向

### 动机

- 目标不只是“技术上能不能做”。
- 更深层的目标是：给仓颉生态补一块真正有意义的基础设施。
- 你的明确偏好是尽量不依赖重型外部框架，而是做一块自己可掌控的桌面 UI 基座。
- 另一个重要目标，是让以后自己做桌面应用时更轻松。

### 当前设计哲学草稿

- 更偏向小而清楚、自己能讲明白、自己能掌控的基础。
- 接受操作系统原生能力作为最底层。
- 第一阶段避免引入大型 GUI 框架依赖。
- 追求一套个人开发者也能从头理解到尾的教学型架构。

### 当前更准确的 framing

- 这里追求的不是“绝对零依赖”。
- 更准确的说法是：`不依赖 OS 层之上的重型 GUI 框架`。
- 具体来说就是：
  - 允许使用操作系统原生 API
  - 必要时允许手写 `C shim`，但向上接口必须极窄
  - 第一阶段避免 `Qt`、`GTK`、`Electron` 这类重型栈

## 可行性边界：什么叫“纯仓颉从零开始”

### 严格解释

- 如果“纯仓颉”指的是：
  - 不调 OS API
  - 不用 FFI
  - 不写桥接代码
  - 不接任何原生库
- 那么做一个真正的桌面 GUI 框架基本不可行。
- 因为桌面窗口最终一定要通过操作系统的窗口系统创建出来。

### 实际可用解释

- 如果“纯仓颉”指的是：
  - 不依赖第三方 GUI 大框架
  - 框架主体逻辑用仓颉写
  - 最底层只保留最薄的一层原生桥接
- 那么这个项目是可行的，而且非常值得做。

### 当前最好的项目规则

- 上层尽量保持仓颉原生：
  - 事件系统
  - 渲染抽象
  - 场景树
  - 布局
  - 控件
  - 响应式运行时
- 最底层接受一层极薄的平台桥接。

### 当前建议的使命表述

- 做一个“仓颉原生”的 GUI 框架
- 避免依赖重型外部 GUI 框架
- 底层只允许最小程度的操作系统桥接
