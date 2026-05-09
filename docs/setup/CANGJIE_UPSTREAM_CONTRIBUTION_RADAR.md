# 仓颉上游贡献雷达

最后更新：2026-05-09

性质：docs-only / upstream contribution radar / sidecar work queue  
状态：生效中  
范围：登记 CJGUI 开发过程中沉淀出的仓颉上游 issue、文档、样例、包和工具候选。

## 1. 用途

CJGUI 是仓颉 GUI runtime / framework 实验项目，同时也是仓颉语言、`cjpm`、`stdx`、FFI、工具链和文档的长期压力测试场。

本雷达用于把主线开发中沉淀出的“可以反哺上游或社区”的资产轻量登记下来。它不是 issue tracker，不是发布计划，也不是 runtime execution card。

核心目标：

- 不让可贡献资产散落在 closure、聊天记录和临时 smoke 里。
- 不让上游贡献副线打断 CJGUI runtime / renderer 主线。
- 给 sidecar AI 留出后续整理 issue、doc、example、package、tool 的入口。

## 2. 分工原则

- 上游贡献由 sidecar AI 承接。
- 主线 AI 只负责发现信号、登记建议和提供最小证据。
- sidecar AI 负责后续整理 issue、文档建议、最小样例、可发布包或独立工具候选。
- 上游贡献副线默认不阻塞 CJGUI 主线。
- 没有最小复现或稳定证据前，不把问题定性为仓颉上游 bug。
- 不把 CJGUI 实验能力写成仓颉稳定能力、官方能力或可发布承诺。
- 任何发布、远程提交、issue 创建、PR 创建、包发布都必须另行授权；本雷达只登记候选。

## 3. 候选分类

### 3.1 `issue`

适用：

- 仓颉语言、`cjc`、`cjpm`、`stdx`、FFI、工具链或官方文档缺口。
- 与官方文档或合理语义不一致的稳定行为。
- CJGUI 不得不引入 workaround 才能继续推进的工具链问题。

常见输出：

- 上游 issue 草稿。
- 最小复现路径。
- 版本、平台、命令和错误输出。

### 3.2 `doc`

适用：

- 可反哺官方文档、社区教程或实践说明的经验。
- FFI、`cjpm`、SDK、平台桥接、构建参数、错误排查等长期可复用知识。

常见输出：

- 文档修正建议。
- FAQ / cookbook 片段。
- “从现象到正确用法”的说明。

### 3.3 `example`

适用：

- 离开 CJGUI 也能独立运行的最小样例。
- 能展示语言、FFI、工具链、平台桥接或构建链一个明确能力点。

常见输出：

- 独立 example 目录。
- 最小 `cjpm` 项目。
- README、构建命令和验证命令。

### 3.4 `package`

适用：

- 未来可发布到中心仓或独立仓库的仓颉模块。
- 必须具备稳定 public API、许可证、版本策略和最小测试。

常见输出：

- 包边界说明。
- API 稳定性说明。
- 发布前 checklist。

### 3.5 `tool`

适用：

- 可独立使用的工程治理、验证、文档、lint、manifest 或 stop-line 检查工具。
- 不依赖 CJGUI runtime 内部实现才能解释。

常见输出：

- CLI / script 候选。
- 规则说明。
- 输入 / 输出 / 失败码定义。

## 4. 候选门禁

进入本雷达的候选至少要满足：

- 离开 CJGUI 也能独立解释。
- 有最小可复现路径，或能说明当前缺口是什么。
- 依赖和平台要求清楚。
- 许可证和来源清楚。
- 不把实验能力写成稳定能力。
- 有最小验证命令或验证记录。
- 能说清楚是 `issue`、`doc`、`example`、`package` 还是 `tool`。
- 不要求主线 AI 暂停 runtime / renderer implementation。
- 涉及中心仓发布或依赖验证时，必须先说明是否需要 `cangjie-repo.toml`；默认不修改主线仓库配置，不提交 token，不让 `runtime/cjgui` 因中心仓实验新增依赖。

不满足门禁时，只能记为 `观察中`，不能升级为上游贡献项。

## 5. 主线最小登记模板

主线 AI 发现候选时，只需补最小信息：

```md
### 候选标题

- 分类：`issue | doc | example | package | tool`
- 当前状态：`观察中 | 可整理 | 后置 | 不建议`
- 来源路径：
- 最小证据：
- 验证命令或记录：
- 平台 / 依赖：
- 许可证 / 来源：
- 为什么不阻塞主线：
- sidecar 后续动作：
```

## 6. 初始候选登记

### 6.1 `labs/cffi_smoke`

- 分类：`example` / `doc`
- 当前状态：`可整理`
- 来源路径：`/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke`
- 候选说明：仓颉调用 C 的最小 FFI smoke，可整理为仓颉 C FFI 最小样例或文档经验。
- 最小证据：已有本地 smoke，曾验证 C FFI 返回值链路。
- 验证命令或记录：以该目录 README / scripts 中的构建运行命令为准；整理前需要 sidecar 重新跑一次。
- 平台 / 依赖：当前以本机仓颉 SDK、C 编译工具链和 macOS 环境为主；整理为上游样例前需明确 Linux / Windows 是否适用。
- 许可证 / 来源：来源为 CJGUI 本地实验目录；对外整理前需确认仓库许可证和样例代码版权头。
- 为什么不阻塞主线：它是已完成 smoke 资产，不要求 runtime 主线改代码。
- sidecar 后续动作：抽出最小 README、命令、预期输出和常见错误说明。

### 6.2 `labs/native_bridge_ffi_probe`

- 分类：`example` / `doc`
- 当前状态：`可整理`
- 来源路径：`/Users/jiangxuanyang/Desktop/cangjie/labs/native_bridge_ffi_probe`
- 候选说明：native bridge / FFI 探针，可作为仓颉与本地 native callable 连接的最小样例候选。
- 最小证据：目录已存在，包含 probe 源码和脚本。
- 验证命令或记录：整理前由 sidecar 读取目录脚本并重新验证。
- 平台 / 依赖：可能依赖本机 SDK、C toolchain、`cjpm` 和当前平台链接规则；整理前必须写清楚。
- 许可证 / 来源：来源为 CJGUI 本地实验目录；对外整理前需确认可独立发布边界。
- 为什么不阻塞主线：只登记为样例 / 文档候选，不要求 renderer native bridge 主线降速。
- sidecar 后续动作：确认它是否能离开 CJGUI 独立运行，并压缩成单一能力点。

### 6.3 `labs/macos_bridge_smoke`

- 分类：`example` / `doc`
- 当前状态：`后置`
- 来源路径：`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke`
- 候选说明：macOS AppKit / Metal smoke，可作为平台桥接、窗口 lifecycle、自动关闭验证、截图 / hash 经验的后置样例或文档素材。
- 最小证据：已有长期 smoke / harness 记录，路径与验证链路在项目文档中多次引用。
- 验证命令或记录：`labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 是当前主线 smoke guard；对外整理前不得默认它是通用 GUI 测试框架。
- 平台 / 依赖：强 macOS / AppKit / Metal / Xcode Command Line Tools 耦合。
- 许可证 / 来源：来源为 CJGUI 本地实验目录；对外整理前需拆除或标注 CJGUI 专用假设。
- 为什么不阻塞主线：平台耦合强，且当前 runtime / renderer 主线仍在 internal-only 阶段。
- sidecar 后续动作：后置整理为“macOS 平台桥接 smoke 经验”，不要提前发布为稳定框架能力。

### 6.4 stop-line / owner header / manifest checker

- 分类：`tool`
- 当前状态：`观察中`
- 来源路径：CJGUI 文档治理、owner 文件头、topic manifest、closure / manifest 稳定化流程。
- 候选说明：未来可拆成独立工程治理工具，用于检查 stop-line、Owner / Truth / Stop-line 头、Same-shape Boundary Brake、manifest 入口和文档链接。
- 最小证据：当前项目已经有大量文档和 owner header 约束，但工具尚未独立化。
- 验证命令或记录：当前没有独立命令；未来应定义输入路径、检查规则、失败码和忽略规则。
- 平台 / 依赖：应尽量做成语言无关工具；不得依赖 CJGUI runtime 编译。
- 许可证 / 来源：规则来源于 CJGUI 治理经验；对外发布前需写清楚适用边界和许可证。
- 为什么不阻塞主线：当前只登记，不要求主线补工具实现。
- sidecar 后续动作：先写规则清单，再决定脚本、CLI 或 lint 形态。

### 6.5 `runtime/cjgui` 主包

- 分类：`package`
- 当前状态：`后置`
- 来源路径：`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`
- 候选说明：长期可能成为可发布的仓颉 GUI runtime / framework 包。
- 最小证据：当前已经有 internal package、owner files 和大量 readiness / admission / renderer shell facts。
- 验证命令或记录：主线每轮使用 `cjpm build --target-dir <tmp> --skip-script` 等命令验证；发布前需要稳定测试矩阵。
- 平台 / 依赖：当前仍与 macOS / native bridge / renderer runway 关系密切，且大量能力仍为 internal-only。
- 许可证 / 来源：来源为 CJGUI 主项目；发布前必须确认项目许可证、依赖许可证和中心仓要求。
- 为什么不发布：仍 internal-only，不提供稳定 public API，不提供稳定 public C ABI，不具备 toolkit surface。
- sidecar 后续动作：长期跟踪 public API readiness、包边界、版本策略、许可证和示例矩阵。

### 6.6 CJGUI 治理经验

- 分类：`doc`
- 当前状态：`可整理`
- 来源路径：`GUI_GOVERNANCE.md`、`GUI_RISK_LEDGER.md`、`docs/plans/*`、topic manifests、owner file header 约束。
- 候选说明：owner / truth / stop-line / Same-shape Boundary Brake / Tail Endpoint Exit Gate / sidecar 分工等经验，可未来提炼成 AI 协作治理文档。
- 最小证据：CJGUI 已在 runtime / renderer 主线中长期使用这些规则，并通过 closure / manifest 形成可追踪记录。
- 验证命令或记录：不是代码验证型候选；需要案例索引、反例和适用边界。
- 平台 / 依赖：不依赖仓颉 SDK；依赖 AI 协作流程和 Git 文档工作流。
- 许可证 / 来源：来源为 CJGUI 项目治理实践；对外整理前需确认可公开范围。
- 为什么不阻塞主线：治理经验可以由 sidecar 提炼，主线只继续按当前规则执行。
- sidecar 后续动作：先整理短文，不写长论文；优先提炼“什么场景有效、什么场景会反噬”。

## 7. 中心仓客户端配置备注

中心仓客户端能力由 `cjpm` 承载，配置入口为 `cangjie-repo.toml`。当前 CJGUI 主线不配置、不安装、不拉取中心仓依赖、不发布 package。

仅当 sidecar AI 执行以下任务时再按需配置：

- 验证中心仓 package install / publish 流程。
- 准备发布独立 package。
- 调试中心仓依赖解析。
- 复现中心仓相关问题。

执行边界：

- `token` 只用于发布，不得提交到仓库。
- 不得把用户级 token 或本机私有路径写入仓库级配置。
- 默认不修改 `runtime/cjgui/cjpm.toml`。
- 默认不新增仓库级 `cangjie-repo.toml`。
- 默认不让中心仓实验改变 CJGUI 主线依赖、构建路径或 runtime / renderer opening。
- 如 sidecar 需要配置中心仓，必须先说明配置范围、文件路径、是否包含 token、是否会影响主线构建。

## 8. 当前明确不做

- 不创建上游 issue。
- 不创建 PR。
- 不发布 package。
- 不安装或配置中心仓客户端。
- 不访问远程写接口。
- 不把 `runtime/cjgui` 宣称为可用 GUI framework。
- 不把 `labs/macos_bridge_smoke` 宣称为通用 GUI runtime 测试框架。
- 不要求主线 AI 为整理上游贡献暂停当前 runtime / renderer opening。

## 9. 与其他文档的关系

- 疑似仓颉 bug、工具链问题和 workaround 仍进入 [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)。
- 本文只登记“未来可贡献资产”，不替代 issue 归因账本。
- runtime / renderer 主线仍以 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)、当前 execution card、topic manifest 和 closure review 为准。
