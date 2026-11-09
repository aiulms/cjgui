# CJGUI 应用开发 Skill：版本适配与使用反馈方案

更新：2026-11-09。用户要求技能适应框架快速迭代，并在开发使用中记录实际缺陷、使用障碍和改进机会。
**技能、辅助脚本、SDK 配套和本机安装已实现；首版证据见[本次交付](#2026-11-07-实际交付与验证)，当前维护源与本机为 [v7 主动显示质量审查](#2026-11-09-主动显示质量审查v7)，新 [SDK skill-v7 候选](../../work/cjgui-skill-sdk-v7-20261109/) 已同步并完成包外核对；旧 review-2 冻结 SDK 仍为 v4。**

## 范围与既有入口

规划 `cjgui-app-dev`，服务于使用公共 SDK 创建、修改、构建和诊断 CJGUI 应用。
稳定使用方法放在简短的 `SKILL.md`；具体版本的 API、能力、限制和示例由实际依赖的 SDK 提供，按任务加载。
优先复用[创建与升级入口](../../runtime/cjgui/preview/MACOS_DEVELOPER_QUICKSTART.md)、
[布局配方](../../runtime/cjgui/LAYOUT_PRIMITIVES.md)、[主题角色](../../runtime/cjgui/STYLE_ROLES.md)、
[公共能力与诊断](../../runtime/cjgui/README.md)。不在技能中复制一份长期独立维护的 API 手册。

项目开发规则继续由 [AGENTS.md](../../AGENTS.md)、[ACTIVE_DIRECTION.md](../../runtime/cjgui/ACTIVE_DIRECTION.md)
和阶段任务负责；2026-09-11 退役的治理 skill、W0/W1/W2/W3 包装和自动开卡流程不恢复。
本方案不增加逐补丁审批、逐轮无问题声明或全量验证要求，也不因发现问题自动启动框架修改。

## 先识别实际版本，再选择知识

首次处理一个应用时，沿应用及其相关库的依赖定位实际 CJGUI 来源；保留 SDK 的
`source-manifest.json` / `source-lock.json` 身份和平台、工具链信息。已有构建或运行对象时，
再核对应 `build-provenance.json` 和应用/原生归档身份。源码目录、编译输入和当前运行的二进制分别记录；
只有 Git HEAD、修改时间或包的显示名称不足以区分未提交改动、冻结副本及混用旧库。
旧包没有上述文件时，如实标记身份信息不完整，按当前问题核对必要输入，不假造版本或自动升级依赖。

知识选择与核验遵循以下边界：

- 日常用法从**所消费版本随包提供**的公开说明、声明、模板和示例获取。仅为了解可升级能力时才比较新版，
  并明确当前依赖和候选依赖的差异；不能把主树新能力当成旧 SDK 已支持。
- 运行中的应用若已启用公开连接，可复用 `generated-capabilities` 的 `SURFACE`、`SUPPORT`、`EVIDENCE`
  以及现有诊断。它们描述该应用注册/启用的能力及相应证据，不是整个框架的全量能力表；未列出保持 unknown。
  纯 UI 或仅编译任务无需为了使用技能启动连接或模型服务。
- API 存在、可编译、能力已注册、行为已验证和交付已发布分别陈述。旧缺陷记录只有在版本、平台、
  使用路径及触发条件相符时才适用；未覆盖的新版本写“待核对”，不自动推断仍有缺陷或已经修复。
- 只有依赖/构建身份变化、相关路径变化、新失败或证据疑点才触发对应复查；每次先核本次需要的能力，
  不逐操作扫描全仓、不每日全量重跑旧问题。对有实际影响的不确定结论，用有界的最小消费验证区分。

技能本身也有版本和适用范围。技能源、引用文档与可运行示例应随 SDK 一起维护和交付；
本机安装的入口负责发现目标 SDK，不永久硬编码作者机器上的“最新”目录或某一批交付名称。
SDK 改动涉及用法时，在同一交付中更新受影响的配方/引用并验证对应示例；文档缺失或不匹配应明确反馈，
不能通过默认套用其他版本的内部实现补齐。现有冻结 SDK 保留原件，新版采用独立候选。

## 记录使用障碍，分开保留事实与归因

有实际阻碍或可复用教训时记录：无法通过公共入口完成任务、表现违背契约、反复误读同一 API、
示例不可运行、能力/文档难发现，或需要不合理的手工接线。普通一次性拼写错误无需逐笔入账；
同一机制反复误用则是有价值的使用反馈。先查匹配记录，同版本同条件合并证据，新版本关联复查，避免重复报缺陷。

最小记录包含：

| 内容 | 要求 |
| --- | --- |
| 目标和预期 | 开发者想完成什么；预期依据是哪一条公共契约/示例，或明确只是设计期望 |
| 实际观察 | 实际结果、最小相关声明/操作、必要原始报错或画面；避免复制整份业务数据 |
| 身份和范围 | 消费 SDK、构建/运行身份、平台/工具链；未取得的字段明确未知 |
| 复现与处理 | 可复核入口、已尝试方法及结果、临时处理和适用条件；暂不可稳定复现也可保留观察 |
| 原因和使用成本 | 当前分类及依据、仍未区分的假设，以及难发现/易误解/接线重复等独立使用障碍 |
| 后续状态 | 原始证据链接、关联既有问题、已知修复来源与尚待哪一版本/消费者验证 |

允许的归因包括待分类、框架行为缺陷、应用接入错误、文档/示例问题、API 易用性问题、
能力需求以及环境/构建来源问题。分类可修订，同一记录可以同时有接入错误和 API 易用性标签。
**确认是误用不等于反馈无价值**：保留开发者为何形成该理解、公开说明是否容易找到、
合理默认值或更明确的 API 能否避免重犯。建议可以先记录，不把推测写成已确认的框架缺陷。

使用记录先留在当前应用任务已有的结果/证据位置。没有合适入口时，技能实现可提供应用本地
`.cjgui/feedback/` 作为小型观察收件目录；这是待归类证据，不建立第二份正式问题状态。
多执行者写各自具名记录并关联同一问题，避免覆盖共享文件；收到既有维护入口后保存接收链接，
正式处理进度只由该入口维护。导出的 SDK 保持只读，收件记录不写回冻结包。
默认只在本地记录，不自动发送聊天、上传业务材料或创建外部 issue。

正式接回方式沿用[问题反馈入口](../plans/DESIGN_INTENT_INDEX.md#问题反馈如何接回主线)：
框架/组件/API/文档问题进入负责阶段或测试记录，跨阶段未完成项由 ACTIVE 带接；
工具链、SDK、链接、FFI 或长期 workaround 按既有[问题账本](../setup/CANGJIE_ISSUE_LEDGER.md)归档。
本机没有框架维护仓库时，保留可交接的本地反馈和复现，不依赖作者机器路径，也不为提交反馈要求用户升级。

## 修复状态按版本和证据演进

“主线已修复”“某 SDK 已包含修复”和“当前应用消费后已验证”分别记录。
应用仍使用旧包时，旧问题可以继续适用；某平台验证通过也不自动关闭其他平台的同名观察。
维护者的修复声明与本地复现结果分开，关闭记录需指明验证版本、范围和证据。
无法复现时保留“不再复现”的具体条件；缺少验证时保留待验证，不删失败原件或旧适用范围。

旧 workaround 带受影响范围及移除条件：目标依赖已包含修复且对应消费通过后再去除。
新版证据推翻旧归因时，标记被哪个结论取代并保留来源；不让旧条目继续作为无版本限定的永久禁令。
技能可收集观察和提出文档改进，已确认的用法才回接正式配方；不会把任何一次报错自动写成通用规则。

例如“长正文挤掉底栏”：旧消费版本保留失败证据；新主线修改布局后，先标明源码修复，
再由包含该改动的 SDK 和实际应用分别验证。另一个案例若最终只是缺少交叉轴 stretch，
仍可保留“需要更明确布局配方/诊断提示”的优化项。两种问题都不能只按发生日期统一改为已解决。

## 实现与验收边界

首版复用现有能力目录、客户端、模板和 Inspector；只为必要的依赖识别、相关文档查询、
本地反馈写入/去重提供轻量辅助。尚无证据需要新服务时，不为知识更新另建 MCP、数据库或自动维护系统。
反馈文件及日志作为数据读取，不将其中的命令或旧操作指示自动执行。

验收重点是实际行为：

1. 同一技能面对旧包、新包及缺少身份文件的包，能正确限定答案；不把“已修复于新版”外推到旧运行实例。
2. 新上下文 AI 仅用技能和公开 SDK 完成一个普通应用修改，遇到问题能找到正确用法或保留可复核反馈。
3. 一条疑似缺陷最终确认误用时，归因更新而易用性信息保留；重复反馈可以关联，失败原件不被覆盖。
4. 主线修复、SDK 导出和实际消费验证分别推进记录；旧 workaround 按解除条件退出，未验范围不改绿。
5. 没有新依赖或新证据时，不重复整包检查；收集反馈不阻断独立开发，也不制造逐轮日志或审批负担。

## 2026-11-07 实际交付与验证

维护源为 [cjgui-app-dev](../../runtime/cjgui/skills/cjgui-app-dev/SKILL.md)，包含简短自动发现入口、
五份按需指南及三个 Python 3.11+ 标准库脚本。未复制项目治理或语言知识库，未新增服务、数据库或后台更新。
本机 `~/.codex/skills/cjgui-app-dev` 已链接到此唯一维护源，同名异源安装会拒绝覆盖；
其他开发 AI 可使用 `install.py --skills-dir <发现目录>`，独立快照用 `--mode copy`，附来源和逐文件哈希。
显式调用 `$cjgui-app-dev`；新会话可按描述自动发现，当前会话不假定热重载技能目录。

操作示例（`SKILL` 为安装后的技能目录，`APP` 为实际应用）：

```sh
python3 "$SKILL/scripts/identify.py" --app "$APP"
# 首次交付核身份或有具体疑点时才逐文件核对
python3 "$SKILL/scripts/identify.py" --app "$APP" --verify-files
# 已有运行观察才提供，PID/哈希等是报告，不自动变为验证结论
python3 "$SKILL/scripts/identify.py" --app "$APP" --runtime-evidence runtime-observation.json
python3 "$SKILL/scripts/feedback.py" template > observation.json
# 填写事实及必要证据路径后
python3 "$SKILL/scripts/feedback.py" create --app "$APP" --input observation.json
python3 "$SKILL/scripts/feedback.py" list --root "$APP/.cjgui/feedback"
python3 "$SKILL/scripts/feedback.py" append --root "$APP/.cjgui/feedback" --issue ISSUE_ID --input followup.json
```

SDK 使用现有 `export_framework_preview.sh` 的 full/macos-dev 出口，技能位于
`framework/cjgui/skills/cjgui-app-dev`；全部技能文件（含 Markdown/YAML）归 `skill` 类并进入 format 2 闭包锁。
旧冻结包未修改。最终 [SDK 候选](../../work/cjgui-app-dev-20261107/CJGUI%20App%20Dev%20SDK/README.md) 与
[ZIP](../../work/cjgui-app-dev-20261107/CJGUI%20App%20Dev%20SDK.zip) 为 experimental 源码开发包，未作正式发布。
631 个文件、606 个锁定输入；最终锁 SHA256 为
`779d100d8538b69d1a9b80eeb2f21ca0fc59e7c39279d693241658d3c8536e60`。
逐文件核对和 22 个包内链接通过，见 [最终 SDK 身份](../../work/cjgui-app-dev-20261107/evidence/final-sdk-verification.json)。

| 验收问题 | 实际证据与结论 |
| --- | --- |
| 旧包、新包与缺信息包是否区别判断 | 实际 11-06 SDK、试用候选逐文件 SHA 匹配，身份不同；人工构造的缺清单捕获目录保持 unknown。未重建/运行旧包，见[三种来源](../../work/cjgui-app-dev-20261107/evidence/version-matrix-and-links.json)。 |
| 源码、构建、运行是否串绿 | 默认读取实际 build-provenance；recorded_verified 仅转述旧记录，current_verification=not_performed；未给运行观察即 unknown，给 PID 等仅 reported。共享核心独立来源与 mixed 提示已验。 |
| 误用归因修订是否丢掉易用性 | 同 issue 追加 application 分类并显式 supersedes，原怀疑、usability、证据副本仍可读；修复源码、SDK 包含、应用消费三字段独立保留。 |
| 重复/新版本/并行与失败清理 | UUID 事件原子发布，4 个并发追加不覆盖；旧/新版本观察共存。证据大小限制、路径穿越/默认符号链接拒绝、部分失败清理通过。SHA 只检测普通改动，不承诺抗恶意删除或重算哈希。 |
| 包外安装与必要引用 | full/macos-dev 都可复制安装；删除原技能源后安装副本仍能识别应用并写反馈；全部技能内部引用可达，无作者绝对路径依赖。 |
| 普通应用独立 AI 试用 | 6.1 Sol 仅给已安装技能、公开 SDK、双栏小工具需求与工具链，实际创建并修改 ui-only；暖纸角色、常规/640×520 窄窗操作、20 字符 synthetic physical 输入、计数、绝对路径会话保存、独立文件解码及重启恢复通过。详见[独立报告](../../work/cjgui-app-dev-20261107/public-trial/TRIAL_RESULT.md)和[维护复核](../../work/cjgui-app-dev-20261107/public-trial/MAINTAINER_NOTES.md)。 |

13 项辅助行为测试、2 项安装测试、6 项导出测试通过；Python 3.11 与本机 3.14 均验证辅助/安装脚本。
skill-creator 格式检查、`zsh -n`、`git diff --check` 及范围扫描通过；根 `cjpm build --skip-script` 成功（保留既有 warnings）。
格式工具使用一次性 PyYAML 环境，交付的三个辅助脚本没有第三方运行依赖。
不重复根全套、历史性能/IME/其他平台门；本次未改 `.cj`、native、公共 API 或 `cjpm.toml`。
原始 RED/GREEN 与检查日志在 [evidence](../../work/cjgui-app-dev-20261107/evidence/)。

本阶段接回的使用问题：

- **身份定位遗漏真实出口层级**：早期一层夹具不足，实际 SDK/framework/cjgui 的清单在两层外。
  已用真实结构反例修复，另补共享核心混用识别；旧包不需要升级。观察及追加证据保存在
  [本地反馈](../../work/cjgui-app-dev-20261107/feedback/)，正式处理记录即本节，不建立第二份正式状态。
- **公开配方的路径可移植性**：布局文档曾使用作者工具链绝对路径与预先构建的 target；
  已改为调用者工具链、明确 SDK/checkout 消费者位置和同版正常 runner。精简 SDK README 原未携带布局诊断说明，
  本版快速开始补上有界快照入口及其证据边界。导出测试夹具遗漏 STYLE_ROLES 也已补齐，保留原失败。
- **正常 runner 首次失败后的重试成本**：独立应用首次语法错误修正后，非空 target 因无 verified provenance 被拒绝。
  同版公开文档提供了本应用 target 退役方案，试用者已保留原始失败并继续验证。此为 CJGUI 构建入口易用性观察，
  已完成正常构建/窗口短链，并将按同版说明恢复的入口补入技能。未修改 runner 或削弱来源保护；
  后续由该入口维护者评估安全复用与更明确报错。正式状态为**易用性待改进**，不归为编译器缺陷。
  本地 issue `8a8ed38f3f53498abd1b6e419523dfd3` 已追加关联本节。
- **会话相对路径失败**：相对文件名保存返回 `file_write_failed`，owner 保留、dirty close 拒绝；
  改用绝对路径后保存和重启恢复通过。独立报告的“应用误用”判断仅为暂定：公开文档只给绝对路径示例，
  未明确相对路径契约，未隔离路径解析/cwd/文件绑定条件，因此正式归因保持**未决**。
  保留“报错应说明路径/父目录、用法应更明确”的易用性建议，未写成公共永久限制。
  本地 issue `cb7456d7ea8d4524ae2b2facec442e95` 已关联本节；原始失败未删除。

试用 SDK 与最终 SDK 的运行时源码/native/runner/config/assets 内容一致；最终增补仅技能身份识别和文档，
仍分别保留两包身份，见 [逐项比较](../../work/cjgui-app-dev-20261107/evidence/trial-final-source-comparison.json)。
运行证据只对实际试用构建陈述，不声称最终 SDK 已额外独立重建。

试用没有启动协作连接或真实模型服务；未验系统 IME 组字、VoiceOver 全链、最终像素配色及
hover/pressed、其他平台、性能、公证/发行。AX 几何和 synthetic Unicode 输入不冒充这些门。
当前运行实例已正常关闭（最后 PID 48086），保留当前签名 bundle、应用源、实际构建输入/native
归档/provenance、最小会话数据和 RED/GREEN 原件；归档后原临时路径只作历史身份，位置映射见
[归档记录](../../work/cjgui-app-dev-20261107/evidence/trial-archive.json)。

空间收尾见 [实际空间账](../../work/cjgui-app-dev-20261107/evidence/cleanup-space.json)：本轮输出约 **131 MiB**，
连同技能源及复用根 target 的全部现存分配保守计入约 **287 MiB**（根 target 未记录开工增量，不能冒充全量新增）。
已准确删除本轮三份冻结中间树、替换候选、一次性格式环境和归档后的包外临时根，按删除前分配量合计约 **292 MiB**；
试用者另退役首次失败 target 约 **45 MiB**。宿主剩余约 **204 GiB**，卷空闲变化不全部归因本线。
保留当前 SDK 源码/分发 ZIP、唯一实际试用包及当前 bundle、来源/链接/输入证据和本地反馈；
未清理旧冻结 SDK、用户数据、其他任务产物或共享根 target，未 stage/commit/push。

## 2026-11-07 跨工具复用与反馈筛选

用户进一步明确：技能既帮助不同开发 AI 快速定位同版能力、降低试错，也收集有待筛选的使用观察。
按[独立评测](../../work/skill-eval-20261107/SUMMARY.md)和当前需求完成 skill-version 2；维护源仍为同一目录。

- **辅助开发**：新增 `lookup.py`，支持多个独立查询，从应用实际依赖或用户指定包读取文档和声明片段，
  返回路径、行号与文件 SHA；精确符号定义优先。结果只做定位，不冒充语义解析、编译或运行证据；
  没命中不判能力不存在，多依赖不静默选择。修正新应用先建项的顺序、纯本地字段/owner/保存优先 ui-only、
  checkout/SDK 路径与相对路径会话失败的有界恢复指引，后者归因仍未决。
- **跨工具入口**：明确 Python 3.11+，系统 3.9 给出可操作错误；坏应用路径非零退出。
  安装支持 codex/dsh/agents 目录配置、任意目录及 dry-run；无加载器时直接读取完整技能目录，
  无执行工具时按指南查资料并保留未验范围。本机 Codex 与新加的 `~/.agents/skills/cjgui-app-dev`
  链接到同一维护源。安装不证明 DSH 已加载；未操作 DSH 会话或改其配置。
- **观察与筛选**：原有 classification/usability 分别保留原因与使用成本，新增 triage 的 decision/reason：
  pending、needs_evidence、framework_fix、usability_improvement、no_framework_action。
  非 pending 要写依据，后续通过追加事件修订；单次误用无需进入框架待修项，反复误用只是易用性线索，
  不以模型名称或次数判缺陷。list 展示各个未被替代的观察，损坏单项返回 partial/errors 而不遮掉其他问题；
  正式状态仍由维护入口负责，没有自动修改框架、上传或发布功能。

针对性反例与现有回归合计 **31 项通过**，其中新增 10 项覆盖旧 Python、错误路径、安装配置、
异源/实时检索、原源移除后的副本、归因筛选及损坏记录隔离；Python 3.11 的 10 项通过。
官方 skill-creator 格式检查通过；一次性 PyYAML 环境已删除，交付脚本仍只用标准库。
RED/GREEN、实际查询和命令消费证据在[本轮目录](../../work/cjgui-skill-portability-20261107/)。

已从新 SDK 正常创建 ui-only 应用，将技能复制到独立自定义目录，再完成依赖识别、同版查询、
本地反馈与筛选追加，见[命令消费结果](../../work/cjgui-skill-portability-20261107/portable-consumption.json)。
反馈为明确标记的合成夹具，不计作新框架缺陷。本轮未启动 GUI、未重新构建应用或根运行时、
未做新的独立模型冷启动；已有评测的 13 分钟/68 秒结果仍只属于原评测版本。

当前 [SDK ZIP](../../work/cjgui-skill-portability-20261107/CJGUI%20App%20Dev%20SDK.zip) 仍为 experimental；
634 个交付文件逐项哈希与 ZIP 字节核对通过，609 个锁输入；lock SHA 为
`b2074135fbe59538ea63b84615dfa676c879acb019df031adac4102a21123063`。
与首版候选比较，变化只有技能、包根使用说明及来源清单；运行时源码/native/runner/config/assets 均未改。
旧 SDK、原 RED 和评测资料保留，未 stage/commit/push。空间明细见
[本轮空间账](../../work/cjgui-skill-portability-20261107/cleanup-space.json)；只回收本轮未消费中间导出和格式验证环境。

## 2026-11-07 自动触发与检索纠偏

本轮完成 skill-version 3。用户要求其他 agent 不依赖逐次提醒，并核实外部模型提出的脚本问题。
在真实小说工作台上仅运行只读识别/检索，不修改应用、WorkBuddy 配置或其 memory；
问题归入技能工具、文档发现性与 API 易用性，不据此推断 CJGUI 运行时有缺陷。

**默认接入：** 根 AGENTS 增加按消费方任务触发的短入口；macOS 创建器在四种新应用模板中生成
指向所选 SDK 技能的 AGENTS.md。已有项目或尚无 cjpm.toml 的新项目可用
`activate.py --project "$APP"` 接入，`--rules-file` 指向宿主实际读取的项目 Markdown 规则。
已有内容保持字节不变，重复执行幂等，修改过的标记块拒绝覆盖；应用和 SDK 一起搬动后链接仍可达。
触发按任务对象判断，不用 `src/*.cj` 排除应用代码；纯框架内核/native/治理任务继续服从项目规则。
详细接法与验收见[项目触发入口](../../runtime/cjgui/skills/cjgui-app-dev/references/activation.md)。

AGENTS.md 不是所有 agent 必读的标准；安装、清单注入、规则加载、模型实际使用分开判断。
本轮证明了规则生成与链接可达，**尚未验证其他宿主中的模型自动调用**，脚本明确返回
`host_loading: not_verified`。不支持此入口的宿主需要一次规则映射或用户级配置；没有改写宿主缓存，
也没有把项目规则宣称为覆盖所有未来项目的全局设置。

**复核与修复：** 原始结果与[同条件对照](../../work/cjgui-skill-activation-20261107/retrieval-comparison.json)保留。

| 报告项 | 本轮事实与处理 |
| --- | --- |
| workspace 根漏成员 | 真实根路径从 0 个来源变为 1 个，与桌面成员指向同一 deps/cjgui。遍历显式 members，循环/缺失成员有界处理；发现范围不冒充 build-members 选择或成员运行证据，未支持的成员模式明确提示。 |
| 标题压过配方、中文整串匹配 | 改为段落/声明头排序、中文词组加二元切分，允许同文档多个相关片段。grow/交叉轴/stretch 首命中从布局文档第 1 行变为第 92 行实际配方；两种文本输入中文表达均命中正文。此为定位检索，不是语义解析或能力完备证明。 |
| 截断标志不可信 | snippet_truncated 只表示当前段落或声明头超过行数/字符上限；文件还有其他内容用 has_more_context_before/after 表达，snippet_scope 说明片段范围。 |
| 文档缺失静默 | 真实 captured 副本有 3 份 shared-core Markdown，根公开文档为 0，且无模板；并非所有文档都不存在。coverage 区分两者，请求的 FIELD_CONTROLS.md 缺失通过 routes_not_present 和 warning 明示。 |
| 最新分类像最终结论 | feedback list schema 2 改用 latest_classification；事件 classification 保留，各未被替代观察仍分别展示。读取旧顶层字段的消费者需迁移，不能把最后一条当定论。 |
| append 全量重哈希 | 成本随历史证据增长属实；没有本应用延迟数据，不能认定已有性能故障。本轮保留完整校验，列为 needs_evidence；后续需实际负载耗时与保持篡改检测的方案。 |

实际导出还发现一处新入口缺陷：导出器把规则模板中的 Markdown 占位链接当成缺失文档移除。
保留[真实失败原件](../../work/cjgui-skill-activation-20261107/export-activation-red/)，改用纯文本占位符，
在创建应用时生成真实相对链接；缺失/重复占位符报错，不再空链接却返回成功。
未为此修改导出器既有文档处理策略。观察、归因与后续版本交付通过
[本地反馈](../../work/cjgui-skill-activation-20261107/feedback/)追加关联到本节，原事件保留。

[相关回归](../../work/cjgui-skill-activation-20261107/final-tests.log) **51 项通过**；
[Python 3.11](../../work/cjgui-skill-activation-20261107/python311.log) 的识别/检索/接入 **19 项通过**。
最初回归命令写错一个测试模块名产生导入错误，修正命令后上述完整集合通过，保留原命令错误日志；
它不是被忽略的产品失败。格式验证、shell 语法及差异检查通过。
[最终包验收](../../work/cjgui-skill-activation-20261107/sdk-verification.json)覆盖四种正常建项、重复接入、
637 文件逐项哈希、16 个技能锁输入与维护源一致、全部 ZIP 字节核对；闭包锁共 612 输入，SHA 为
`e5cbf98168fd2979c3961b5dc8fc714167ae80d7161ce57f3b25d79b594a9f30`。

当前 [SDK ZIP](../../work/cjgui-skill-activation-20261107/CJGUI%20App%20Dev%20SDK.zip) 仍为 experimental。
相对 v2 只变技能、创建器、包说明与来源清单，运行时源码/native/runner 未改；复用既有构建证据，
本轮未重新构建运行时/应用、启动 GUI 或进行独立模型冷启动，原 GUI/IME/平台/性能边界保持。
旧冻结包保留；只回收本轮中间导出、已替换候选和格式验证环境，
[空间账](../../work/cjgui-skill-activation-20261107/cleanup-space.json)记录保留与实际回收量。
未 stage/commit/push。

## 2026-11-07 检索排序与规则刷新

两份外部复核合并审查后交付 skill-version 4。Sol 6.1 负责检索修复与反例，Luna 核对报告事实，
主执行负责规则刷新、文档及最终包；写集分开。保留外部 agent 已做的空格/中文直读路径和 assets 说明修正。

- **排序缺陷属实：** 重叠中文 bigram 曾各加一次分，使模板清单挤掉事件声明。现每个中文短语按覆盖的字符位置
  归一化，同位置不重复计分；未上调主题路由权重。两种“文本输入事件”问法的首两条均为 TEXT_CHANGED 与
  Controller，布局/stretch 配方及精确符号结果保持。[同版前后对照](../../work/cjgui-skill-activation-20261107/review-2/lookup/RESULT.md)保留原始 JSON。
- **独立缺口提示属实：** 根指南为 0 或模板目录缺失，无需查询触发路由也会提示。
  CjguiTextDocumentFileBinding 的 found 仍只是定位到文本，不能代替指南/模板完整性；没有补造 captured 包缺失的文档。
- **升级和迁移确有接入成本：** 新生成块记录内容校验和模板指纹；`--dry-run` 展示旧/新块、差异、旧链接状态。
  `--refresh` 仅刷新校验匹配的生成块，或完全匹配已知 v3 模板的旧块，保留块外字节和文件权限。
  用户编辑、未知旧块及错误标记继续拒绝覆盖，不靠 mtime 猜归属，也不提供跳过检查的 force。
  模板前导空白曾使生成与读取的校验范围不一致，独立审阅复现后已规范到标记边界并增加反例。
- **路径反馈需要区分使用方式：** 原四个 Consumer 的编码链接解码后均能定位；照抄为字面文件路径则失败。
  保留常规空格/中文原文路径，同时修正外部补丁遗漏的 `#`、`?`、`%` 等保留字符：链接编码，另给文件工具可解析的 JSON 路径。
  创建器指向所选框架的技能；手动 activate 默认指向脚本实际位置，链接安装可能指向 checkout。
  “随应用一起迁移”只在技能源也保留相对位置时成立；文档已说明 `--skill` 的明确选择与刷新入口。

两条旧报告不适用于当前源：feedback 列表早在 v3 已使用 `latest_classification`，事件内部仍保留 classification；
本机技能 `agents/openai.yaml` 确有 `allow_implicit_invocation`，不能据此推导 WorkBuddy 配置或真实触发。
通用指南改为按宿主实际开关核对，并明确可选元数据的归属。WorkBuddy 缓存/新会话状态本轮未复核、未改写；
历史证据全量重哈希保持，尚无实际性能故障证据，不因本轮复核另行改缓存策略。

Python 3.11 的受影响检查共 **33 项通过**：14 项发现/检索、3 项既有检索可移植性，以及
[16 项规则接入](../../work/cjgui-skill-activation-20261107/review-2/activation-python311-final.log)。
保留相关 RED 原件，不重复无关全套构建和窗口验收；格式、链接与差异检查通过。
[最终包验收](../../work/cjgui-skill-activation-20261107/review-2/sdk-verification.json)核对四种正常建项的直接文件路径、
重复接入、637 文件和 ZIP 字节、16 个技能锁输入；闭包锁 612 输入，SHA 为
`da4359886ef5b74677c82f37bbe588e8d57ef4ed071679482ed83a2d3cd3f4b2`。
[旧规则迁移](../../work/cjgui-skill-activation-20261107/review-2/migration-verification.json)在 v3 原件副本中验证：
失效链接可显式刷新，块外字节不变，四个原 Consumer 原件未改。观察通过既有本地反馈追加接到本节。

当前 [v4 SDK ZIP](../../work/cjgui-skill-activation-20261107/review-2/CJGUI%20App%20Dev%20SDK.zip) 仍为 experimental。
相对 v3 仅技能和来源清单变化，runtime/native/runner/创建器未改；未构建或运行 GUI、未验证各宿主模型自动触发。
只清理本轮中间导出和格式验证环境；[空间账](../../work/cjgui-skill-activation-20261107/review-2/cleanup-space.json)记录保留与回收。
旧 SDK 和原始证据保留，未 stage/commit/push。

## 2026-11-08 反馈流程澄清

针对实际开发中先写 note、追问后才补入观察，以及修复状态和手工汇总歧义，交付 skill-version 5。
通用技能的修复记录为 issue `1dcfa02268514e3c8985542c2c9f24f9`，
[原始观察](../../work/cjgui-skill-feedback-20261108/feedback-created.json)与[追加记录](../../work/cjgui-skill-feedback-20261108/feedback-updated.json)关联本节；不代改消费者应用的反馈或框架维护状态。

- **已实现：** SKILL 入口明确首次可复用障碍加载反馈指南，在继续改动前 create/append；允许原因未知和无脚本时的等价记录。位置、原件与观察的关系明确，归因后仍保留 usability。
- **已实现：** 澄清 `not_needed` 不能表示本轮未修，源码修复、SDK 包含和消费验证分别记录；旧值按当时证据解释，用新事件澄清。待补证据写下一项能区分结论的核对；本地链接不自动证明维护者已接单。
- **已实现：** 仅有反馈变化时核对 ID、原件、下一步、维护入口和版本范围；数量来自带目录/时间的 list 结果。`complete` 仅表示读取完整，空目录也可 complete，不能充当反馈覆盖或问题闭环证明。

本轮写集为三份技能文档、版本号及本计划/技能当前摘要；辅助脚本和 schema 未改，
没有给通用技能加入原型宿主专属规则或自动框架修复流程。Terra 只读审阅无阻塞，旧状态解释建议已采纳。

**已验证：** 格式、相关本地链接与差异检查通过；独立安装副本的 16 个文件与维护源一致，
Codex/共享 agents 两入口仍链接同源 v5。空目录实测返回 complete、零 issue，
[验证记录](../../work/cjgui-skill-feedback-20261108/validation.json)及[空目录原始输出](../../work/cjgui-skill-feedback-20261108/empty-list.json)保留。

6.1 Sol 在只给技能副本、普通笔记应用声明、公开布局文档捕获及受控观察的有限上下文中完成试用：
先 create 后修改 stretch，再 append 归因；原件和 usability 保留。
后续接续另一维护记录，纠正旧 not_needed 用法并区分“据报已修／未导出／未验”，保留旧事件字节。
两库共 2 issues / 5 events 的统计仅限[本次试用快照](../../work/cjgui-skill-feedback-20261108/stage2-results.json)。
首轮漏读一份已提供观察日志，定向指出后才追加补核；不宣称首轮全资料处理通过。
identify/lookup 为遵守试用读取边界使用了限制目录外元数据探测的包装；feedback 命令未改。
[试用交接](../../work/cjgui-skill-feedback-20261108/trial-kit/delivery.md)保留实际操作与未验范围。

**交付与边界：** 这是技能反馈流程试用，未编译或运行 GUI，不是新一轮真实 SDK/应用实机验收，也不证明所有宿主都会自动遵循。
既有导出器继续携带维护源快照；[包与安装核对](../../work/cjgui-skill-feedback-20261108/sdk-installation.json)确认冻结 ZIP 中技能仍为 v4，本轮未导出或覆盖 SDK。
必要证据留在 `work/cjgui-skill-feedback-20261108/`，临时格式验证环境已准确回收，
[空间账](../../work/cjgui-skill-feedback-20261108/cleanup-space.json)记录本轮留存与释放量。未 stage/commit/push。

## 2026-11-08 checkout 消费退出条件

复核后续建议时，原型反馈库仍为 10 issues / 22 events，四个 framework_fix 最新事件 links 为空，
SDK 状态仍写 checkout/未导出的 not_applicable；R9 声明的日志不在报告路径或反馈保全原件中，
现存应用测试日志为较早的 8/8 等记录；README 仍保留操作行 fixedWidth 和新增动作的旧说法。
这些属于原执行任务的记录/证据/消费文档收尾，本轮只读核对，不改其正式状态或重跑构建。
相关修复事件时间为 13:26–13:32（上海），早于 v5 入口写入的 14:45；不能据此证明 v5 驱动了这些修复，
也不能把它们当成加载 v5 后仍违反指导的证据。SDK 交付链仍未闭合。
[本轮核对快照](../../work/cjgui-skill-feedback-20261108/checkout-review/audit.json)保留范围和原事件标识。

只修一项实际技能缺口并升为 v6：反馈与升级指南曾把所有 workaround 退出都要求为“对应 SDK 已包含”，
遗漏直接消费 checkout 的应用。现统一为实际构建包含修复且受影响消费通过；checkout 核源码、相关 native
与运行身份即可判断，不必等待导出。SDK 未导出仍为 pending，旧版本和未验实例继续保留原适用条件；
退出时同步本次维护版本的 README/配方。未新增脚本、schema、宿主特例或通用验收门禁。

技能问题 issue `3124c03164b04ff29f093cacf3b7dd0c` 的
[原观察](../../work/cjgui-skill-feedback-20261108/checkout-review/feedback-created.json)与
[修订](../../work/cjgui-skill-feedback-20261108/checkout-review/feedback-updated.json)回链本节。
本轮仅文档语义修正，按影响做差异、本地链接和规则一致性检查；未重跑 v5 独立 AI/GUI/SDK 验收，
不把旧试用写成 v6 的新行为验证。Codex/agents 两个同源链接再次读取即为 v6，既有会话是否重读未验证。

## 2026-11-09 主动显示质量审查（v7）

针对“功能通过、截图已存，但没有实际看画面”的典型漏检，只改技能文档升为 skill-version 7：
主入口增加功能验证后**不可省略**的独立只读显示审查阶段；`diagnostics.md` 增加五步流程
（代表状态选择、实际看图并对应图像身份/区域、按证据类型核对、功能与显示分列、白名单外只记录）；
`layout-theme.md` 增加证据类型判断（裁字=行框/可绘/clip/overflow+像素、对齐=实测按钮盒内左右余量、
留白不按面积比），并明确合理留白、正确左对齐、显式省略、滚动边缘半行不得误报。scripts/schema 未改；
未构建、未运行 GUI、未导出或覆盖 SDK。

**RED/GREEN 盲测：** 同一 kit（13 文件哈希复核一致）与同一读取边界，独立新上下文分别用冻结 v6/v7 快照，
未提前告知答案。RED（v6）命中 2/3：列表次行裁字、夹具内容不可达被发现；动作按钮标签左偏漏检，
且在通过项反向断言“标签居中完整”；正常对照误报 0/4；约 8 分 46 秒。GREEN（v7）命中 3/3：
按钮对齐转为实测左 7.5–9pt vs 右 14–56pt 的命中；正常对照误报 0/4；8/8 图像实际查看；
确认/疑似分列；白名单外只记录；约 10 分 16 秒。两轮均把缺失的行框/clip/overflow 诊断字段记为 unknown，
未自造文字测量算法。小样本按案例计数，不宣称普遍率。

**状态与边界：** 维护源与 Codex/agents 同源链接为 v7；冻结 SDK（review-2，skill-version 4）仍不含 v7，
本轮未导出；E 线候选包内 v6 快照属其自身交付，未改。诊断缺口 issue `a9c7b065…` 已追加
验证事件 `53b8be6d…`；自动裁字检测因公开诊断缺行框/可绘/clip 字段未实现，保留为具名缺口。
报告与原件在 [work/cjgui-skill-visual-review-20261109](../../work/cjgui-skill-visual-review-20261109/)；
工作区约 2.1 MiB，宿主剩余 234 GiB。未 stage/commit/push。

## 2026-11-09 SDK 内置 skill v7 同步

用户授权把维护源 v7 同步进 SDK。为避免混入当前工作区其他框架改动，本轮以 review-2 已核验 ZIP
（SHA256 `3efa79ad…`）为冻结底本，同步完整 16 文件 skill；v4→v7 实际涉及 `SKILL.md` 和
development/diagnostics/feedback/layout-theme/portability 六份文档。同步时重算嵌入的 source-lock、
source-manifest 与闭包身份，不把旧锁原样留在新包中。旧 v4 ZIP 和 E 线候选均未修改。

交付为 [SDK skill-v7 候选](<../../work/cjgui-skill-sdk-v7-20261109/CJGUI App Dev SDK - skill v7.zip>)，
ZIP SHA256 `85e2bf84812a5852aa13b34df07db367c55c4d07d464833fdd46de78ca57c159`，另有同名解压目录可直接消费。
与底本比较仅上述六份 skill 文档及两份身份清单变化，其余 630 个交付文件逐字节不变；框架/runtime/native
没有升级或混入当前工作区修改。

**实际消费核对（Python 3.11.15）：** 四种应用模板均从候选创建成功，AGENTS 链接指向包内 v7；
`identify --verify-files` 核对 637 文件 matched、612 闭包输入，16 个 skill 源与维护源一致；
独立 `--mode copy` 安装 16 文件后再次识别 matched；原有三组 lookup 查询通过，21 个 skill 内部链接可达，
ZIP 逐文件与解压目录一致。详见 [验证记录](../../work/cjgui-skill-sdk-v7-20261109/sdk-verification.json)、
[同步收据](../../work/cjgui-skill-sdk-v7-20261109/sync-receipt.json)。本轮没有框架内容变化，未重建/运行 GUI，
宿主是否重新发现 skill 仍不据此宣称已验。

临时消费者与独立安装副本在结果落盘后回收约 0.72 MiB；保留候选目录、ZIP、锁/清单、复现脚本和必要报告，
当前工作目录约 29.6 MiB，宿主剩余约 234 GiB，详见 [收尾记录](../../work/cjgui-skill-sdk-v7-20261109/cleanup-space.json)。
未 stage/commit/push。

## 仓颉语言技能与历史说明

仓颉语言、标准库、stdx 与工具链知识的当前可选入口是
`/Users/jiangxuanyang/.agents/skills/cangjie-coding`：它来自 CangjieSkills
`cangjie-1.1.3` 的固定提交 `4b844f29e82b32ecf2171c36659b9e8ea9e2f595`，以检索脚本和只读
SQLite 知识库渐进查询。它不取代项目规则；使用时按其 `SKILL.md` 调用 `search_docs.py`，并以当前
1.1.3 工具链的最小编译实验为最终依据。旧六个 Cangjie skill 入口已可恢复地移至
`/Users/jiangxuanyang/.agents/cangjie-legacy-1.1.0-backup-20260913T120000`（活动 skills
根目录之外）；不要同时恢复它们，
以免给同一任务加载冲突版本。

原计划见 [历史快照](../archive/2026-09-11-direction-governance/README.md)。
