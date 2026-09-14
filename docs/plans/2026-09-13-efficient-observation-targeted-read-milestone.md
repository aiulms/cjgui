# 大阶段：低成本持续观察与真实局部读取

日期：2026-09-13。执行任务01a08f82-b682-73c0-a9b0-25a27bc5ffd8，原目录Terra/xhigh；指导只复核、文档与指派。

## 目标与选择依据

让外部系统持续理解并接手应用，而无需反复构造、编码整个千项列表；人在窗口中的草稿、选择、层和显示进度保持及时可读。这是可供不同应用复用的框架能力，不是规则集专用性能补丁。

前阶段已取得统一5秒预热、两轮60秒正常窗口idle与180秒真实业务负载。指导核对paced JSON的两个bundle SHA256与当前产物一致：规则1081个快照p95 145.653ms，文档1479个p95 24.643ms；前者持续读取CPU显著偏高。旧阶段记录其原始范围，物理IME、人眼呈现、安装发布未完成，不把接续改名当补验。

六条主线中，组件/布局、渲染/GPU与窗口调度已有真实两应用消费及初步成本；现在语义观察在owner上消耗全量数据处理，是有证据的优先瓶颈。文字输入仍保留物理IME欠项；之后优先正常包消费和API组合体验，或测量显示的文字排版瓶颈，不提前重写文字引擎。

依据[设计导航](DESIGN_INTENT_INDEX.md)、[避坑经验](../research/gui-framework-pitfalls-intelligence.md)第3/6/7节：保持状态单一归属、避免API过早固化、避免语义热路径拖慢GUI。自绘/仓颉路线和S表达式候选定位不变。

## 复用与实现范围

复用shared_operation_core既有GET_CHANGES、streamIdentity/resync、GET_CONTEXT授权与目标过滤、READ_RANGE、公开client.py、通用窗口progress和两个领域。现状snapshotPayload无论target都会先domain.contextSnapshot，再构造windowProjection并编码；定向返回不等于定向构造。变化流只列变化标记而非完整新状态，客户端需要按需补读，不能直接当已同步完整内容。

### 本阶段契约选择（执行前）

- 保留 `GET_CONTEXT` 的 wire 语义与全量兼容路径：无 target 仍由领域提供完整快照；显式 target 才可由领域主动选择的只读定向快照替代，未知对象仍明确报错，不能把缺失静默当删除。
- `GET_CHANGES` 仍是带 stream identity 的失效通知；公开客户端在首次全量/定向读、无变化、变更补读、`RESYNC_REQUIRED` 与 endpoint 重启间维护本地的可丢弃投影，绝不把缓存变成业务真相。
- 新增的窄窗口观察只报告会话、场景/提交/完成及交互代际等窗口事实，不携带资源字段、草稿正文、选择内容或领域版本；它独立授权、读操作无刷新副作用，并与领域版本并列而不合并成伪版本。

1. 把对象定向读取落实到真实owner，避免先创建所有对象再过滤。选择最小可选能力接口并保留现有领域兼容路径；规则集和文档两个正常消费者接通。新增、删除、重排、草稿、选择等在原owner维护；索引/缓存只是可失效派生数据，不能独立写入业务真相。对全量快照保留正确性和有界响应，不为改善定向成绩悄悄截断全量。
2. 提供低成本持续观察：优先组合已有变化流、定向读取、范围读取，必要时增加窄的窗口进度读取能力。领域版本、选择/层/草稿和GPU进度不共用一个伪版本；内容未改时也能发现人的交互变化与完成帧。先在本阶段简述方案与兼容语义后自主实现，不为常规选择另求批准。无需先引入长连接推送服务器或Agent runtime。
3. 公开Python客户端形成可实际使用的观察/接续入口，处理首次快照、无变化、增删改、历史溢出resync、stream/session重启、断线/超时和旧版本冲突；整体超时有界，重同步可恢复。没有新变化时不能反复全量编码/布局，重同步要明确发生，不能默默保留过期对象。授权先于读取/输出，窄权限不能通过变化ID、元数据、进度或缓存泄露其他内容；缓存键若存在须包含真实有效的授权与身份边界。
4. 两个应用消费同一通用能力。规则集1001项，外部观察期间屏外100项批量更新，人的对话框草稿/选择/子菜单接续；文档本地编辑、外部range修改、撤销和重新连接都读到一致状态。仅临时数据，不使用用户文件或剪贴板作负载。未验物理IME可择桌面可用时补，不阻塞独立代码。

## 性能与验收

先保留原全量读取路径作为对照，在相同1001项、预热、节奏、二进制身份与180秒负载下比较全量、定向及推荐观察路径；包含无变化、稀疏变化和批次变化。报告业务owner耗时/构造或编码工作量、字节量、CPU/RSS、外部延迟及本地事件处理/提交；不能只减少请求次数就声称内部算法改善。至少证明定向构造不随未请求对象数线性增长，无变化持续观察不再反复构造完整快照，两个应用真实状态/结果一致。若无法做到，给明确瓶颈与证据，不包装成功。

相关测试覆盖未知/删除对象、交错更新、权限过滤、断线与重启、窗口进度变化但领域版本不变、缓存失效以及全量兼容。沿现有真实入口测，不增加Bool审计层。性能诊断可关闭且自身成本可说明。

安排一个无实现上下文的独立Luna/Terra验收者，仅给公开README、入口、自然语言目标和其临时应用descriptor，动态发现并观察、修改、处理冲突/重同步、读回；不能只让实现者手写脚本再称独立Agent。保留既有黑盒证据，不要求所有旧测试重做。

完成相关core/客户端/两领域测试、native若改则探针、正常app构建及可用时实际窗口接续，root build --skip-script、diff与公共声明检查；指导复核源码/证据不代跑开发。不要做一个接口就停工，完整交付包含能力、两应用消费、性能对照和独立公开使用。

## 执行与回报

遵循AGENTS.md；原目录、不切分支/worktree、不stage/commit/push。公共契约跨模块按实际CodeLattice/GitNexus入口看影响，索引UNKNOWN用源码/测试补证。两次实际修复失败调用Kimi Code CLI kimi-code/k3只读讨论，两轮仍失败立即回报指导给方法，次数跨阶段累计。锁屏只跳过具体GUI，继续独立工作；不索取或记录密码。完成或实质升级回报指导01a08f0f-e1ce-71c1-9a6e-4eee08308d61，更新ACTIVE与本页交付区。

## 交付区

已完成本阶段实现与当前机验收（2026-09-13）：

- `CjguiSharedOperationTargetedContextDomain` 使显式 `GET_CONTEXT` target
  由实际 owner 构造；无 target 的完整快照 wire 语义未变。规则集用
  owner-local `recordsById` 派生索引只物化请求规则，文档工作区同样只
  物化请求的打开文档；未知或已关闭对象返回明确错误。
- 新增独立授权的 `GET_WINDOW_PROGRESS`：只返回 window/session/scene/frame
  及 interaction revision、焦点、可选 UTF-16 选区坐标和顶层 layer identity，
  不读取领域资源、选择文本、草稿或完整 window projection。两正常 window app
  均启用；`wait-window` 改用此窄端点。
- 公共 Python `SharedOperationObserver` 以首次 target snapshot、
  `GET_CHANGES`、变化 target 重读和显式 resync 组成可丢弃本地投影；端点
  丢失清空缓存并要求 fresh descriptor。修正 Python 标识符规则以接受与
  transport 一致的连字符 stream ID，黑盒首次暴露的实际回归已有失败测试。
  接续实现把一次调用的 monotonic deadline 传到 changes、每个补读及 resync，
  失败即清空，多个 target 仅在全部校验相同版本后整体发布。snapshot 不含
  `STREAM_ID`，所以 initial/resynced 快照明确返回空 stream，下一次 changes 才
  学习可使用的 cursor；目标补读跨版本会丢弃暂存结果并重新同步。
- 当前机三组同条件正常 rule-set window 180 s 报告：
  `/tmp/cjgui-rule-read-comparison-180s.json`。1,001 条临时规则、100 目标
  批量、旧版本冲突、目标读回、稀疏目标变更和后续 Metal 完成帧三组均通过。
  全量 / 单目标 / 观察的 p95 延迟分别为 151.974 / 24.784 / 43.956 ms，p95
  wire bytes 为 318,472 / 6,515 / 712；观察还明确记录一次 history resync
  和一次 changed。观察器在应用正常关端点的尾端还记录一次
  `ConnectionRefusedError`（应用进程仍 exit 0，业务与读回均已完成）；这是
  shutdown race，不把它藏成零错误。三者均为本机 bundle 测量，不是跨机器
  性能承诺。
- 验证：core `cjpm test --timeout-each 30s` 36/36，Python client 14/14，
  rule owner test 15/15，窗口性能单元5/5和实际 bundle workload 单测1/1通过；
  两个 normal app 已重新构建并本地临时签名运行，root
  `cjpm build --skip-script` 通过。Cangjie `chmod` 与 native
  `allowedFileTypes` deprecation 警告仍存在，未在本阶段掩盖。一次 root
  `cjpm test` 的旧 viewport test 在 `window.start()` 失败（3/4），不把它
  误记为本轮全绿。
- 独立 source-blind 黑盒仅使用 README、临时 descriptor 和公开 CLI：实测
  `GET_WINDOW_PROGRESS`、`initial → no_change → changed → no_change`、目标
  读回及 version conflict。它未覆盖重启后的旧 descriptor；物理 IME、
  人眼呈现、安装和发布同样未运行。


### 指导复核与完整接续

指导静态审阅client观察实现和定向owner路径，认可36/36与当前机三组性能报告的范围，未重跑开发测试。阶段仍需完成原定持续观察语义，不把性能改善当接续完整。

- `observe_once`给changes、每个target读取、resync分别传同一完整timeout；目标多时可累加成N倍等待。建立一次调用的monotonic总deadline，每步传剩余预算，含重同步；用多目标延迟与后段超时验证，不能仅测单次exchange。
- 检测stream改变/RESYNC_REQUIRED后，`_resync`读取失败仍保留旧resources/version；与类说明不符。明确旧投影失效，原子构造替代结果，失败后不可继续被当成当前内容。变化target循环也是逐项直接写缓存，后项失败会留下部分新数据；选择可解释的原子发布或明确部分状态契约，不让旧version对应混合缓存却无提示。补授权失效/协议错误/超时后的缓存状态验证。
- 初次snapshot没有同时绑定stream identity，随后无stream的changes可能遇到相同endpoint更换stream且版本不减；验证此种竞态以及变更发生在changes和target读取之间的版本语义，不能把多时刻读取宣称一致快照。沿现有owner/stream设计选择最小补充，不新增独立业务状态机。
- 原目标含人侧选区、焦点、草稿、层变化。GET_WINDOW_PROGRESS刻意只有scalar不包含这些，而Observer只看领域changes；补领域版本不变但人侧状态变化的实际接续验证及所需窄接口/版本信号。复用已有UI身份与语义投影，授权前置；不退回每轮全量GET，不为每次局部焦点事件复制领域。区分内容观察和交互观察，公开API明确能力范围。
- 完成实际旧descriptor失效、fresh descriptor重连、stream替换、历史溢出、删除对象、窄权限观察的独立公开黑盒；原阶段已授权，不因尚未安排而留not_run。两个应用的本地编辑/外部更新接续都应覆盖，而非只验证规则目标变更。
- CPU/RSS和owner构造工作量保留同条件证据；多个目标变化的观察延迟包含所有补读。验证修复后的必要场景，不机械重跑全部180秒，除非性能路径发生变化。公开观察结果应能让消费者取到可解释的最新内容与状态，不能只有resource_ids及藏在私有成员里的快照。

本轮是原完整阶段接续：可靠观察/重同步、人侧状态与可消费结果一起交付，不按单个问题停工。两次失败/K3累计规则与原目录Terra/xhigh保持，完成或实质升级回报指导。物理IME、人眼呈现和安装发布仍各自保留。

### 指导复核后的接续交付（2026-09-13）

本节完成上列复核项；上面的“指导复核与完整接续”保留为当时的
验收要求，而不是当前未完成清单。

- `SharedOperationObserver.observe_once` 现在建立一次 monotonic deadline，
  把剩余预算传给 changes、每个 target reread 与 resync。协议/授权/超时、
  endpoint 丢失或替代读取失败均清除旧投影；多 target 在暂存映射中验证后才
  同时发布。Python 14/14 包括总 deadline、后段 target timeout、部分 target
  失败、resync 失败、删除对象与目标读取跨版本的回归。
- `GET_CONTEXT` wire 没有 `STREAM_ID`，因而不能证明其快照与前一个
  `GET_CHANGES` stream 原子绑定。initial/resynced 公开返回空 stream；后一次
  changes 才获得当前 stream。目标 reread 返回不同 `VERSION` 时不发布混合投影，
  而是丢弃并 resync。公开 CLI JSON 的 `resources` 和 import API
  `observer.snapshots()` 都暴露最新可读 snapshot，消费者无需窥探私有缓存。
- `GET_WINDOW_PROGRESS` 加入独立 interaction revision、焦点、顶层 layer 与
  可选 UTF-16 selection 坐标，仍不携带文本/资源/领域版本。先由 source-blind
  黑盒发现 active 响应漏 `WINDOW_PROJECTION`，核心红测失败后修复。实际带
  descriptor 的文档窗口中，菜单操作令 interaction `0 → 3`、scene `1 → 2`，
  报告 menu trigger 与 `shared-document-menu`；随后真实文本控件焦点产生
  interaction `4`、`WINDOW_SELECTION shared-document-editor 57 57`。两次
  `GET_CONTEXT --target 7101` 的内容 `VERSION` 均为0，故未把人侧菜单/焦点
  伪装为内容修改。
- 重启/权限黑盒不读取源码、测试、计划或 Git，也未编辑文件或泄露 descriptor：
  有限文档窗口的旧 descriptor 关闭后公开 `get` 退出2；新 descriptor 的
  `observe --target 7101 --turns 1` 与 `wait-window` 都退出0，后者含
  `WINDOW_PROJECTION ACTIVE`。对未授权 7199 的 `READ_RANGE` 退出5且没有
  内容字段。该文档 descriptor 的 `GET_CONTEXT` 是 `ALL` scope，故没有将它
  错报成 target 隔离验证。
- 第二个正常规则集窗口的独立黑盒动态发现 `CREATE_RECORD`/`DELETE_RECORD`：
  创建 rule 1 后 `observe --target 1` 读到 label、enabled、retention 与
  excludedType 的实际内容；删除后根投影为 `recordCount=0` 且没有 rule-1，
  已删 target 的 fresh observe 返回 remote error 并保持空资源列表。另一窗口
  从 v2 连续公开创建256条临时规则，`observe --target 8000 --turns 2` 从
  initial v2 明确返回 resynced v258，且快照读到256条记录；两窗均未保存，
  关闭时按 README 丢弃临时内存内容。
- 本轮验证为 core 36/36、Python 14/14、规则 owner 15/15、性能辅助5/5、
  workload1/1、两 normal app 重建及 root build 通过。一次 root test 的旧
  viewport `window.start()` 失败（3/4）保留为红证据，未归因给本轮。180秒
  性能报告保留原始 owner/CPU/RSS/字节结论；本轮只改变观察器语义和窄进度固定
  标量，不重跑它来制造不必要的数字对比。

未运行或不能由上述结果推出的仍是物理 IME、人眼已见像素、稳定公共 API、
安装/发布和多平台；窗口仍诚实报告 `WINDOW_PRESENTATION_STATE=unavailable`。


### 指导诊断：观察身份和新增交互授权收尾

认可deadline、缓存整体发布、可消费快照、两应用交互及独立删除/重启/溢出证据。还有两个公共正确性边界与一个未归因红测，继续同阶段完成，不另开孤立修复任务。

1. 当前_resync将stream留空，下一changes直接绑定；若snapshot A后切到stream B且版本相同/更大，没有匹配变化项便会把A缓存报告no_change。单独说明unbound不解决第二次误绑定。指导建议由实际领域owner在同一锁/读取边界返回snapshot内容、version和streamIdentity，作为可选向后兼容能力/字段供Observer校验；不要在transport分两次取值假装原子。旧不支持身份的provider明确能力降级，不能冒充可靠增量。验证initial和resync之间流更换且version相同、增加、降低，以及changes与target补读间更换。当前代码先拒current_version低于旧版本，再处理requiresResync/stream更换；新stream版本重置是合法重同步条件，不应直接判损坏协议。目标快照也必须与changes身份核对。这个问题先前仅作unbound说明的方案不算修复完成；若实际修复验证累计两次失败按K3规则处理。
2. GET_WINDOW_PROGRESS从仅显示标量扩大到focus/control ID/selection/layer，目前只检查permitsAction。不能默认旧显示进度授权同时允许读取新交互信息。明确进度与交互授权分工：优先分开独立授权的窄交互入口或显式能力，保留已有显示等待消费者；有资源范围时按真实关系过滤或不输出不具备权限的交互。不用“没有正文”解释标识符和选区泄露。补仅进度授权、单资源授权、完整交互授权的真实外部测试，与两应用公开README一致。
3. 对旧viewport window.start失败做一次确切复现和对照，记录native status/环境/入口与当前变更关系。只有确实的环境条件才标环境未验；若是生命周期/首次提交回归则修复。不要恢复旧治理禁令，也不机械全仓重跑或跳过。保留原失败。

收尾交付同时验证Observer可靠身份、人侧交互低成本入口与两正常应用接续，必要黑盒从公开契约动态发现新授权；保留已有性能成绩，若变化影响热点再针对性复测。结束时给清楚能力边界与后续正常包消费建议。原目录Terra/xhigh、K3累计和无Git写入不变。

### 指导诊断收尾交付（2026-09-13）

- `CjguiSharedOperationContextSnapshot` 增加可选 `streamIdentity`。规则集与文档 owner 均在已有同步边界内把内容、version 与 stream identity 一起构造；传输层只序列化 owner 已给出的 `STREAM_ID`。因此初始/重同步映射有可核对的身份，transport 不会用两次读取伪造原子快照。
- 公开 observer 把 snapshot identity 与 `GET_CHANGES`、target 补读的 identity 一并校验：先处理 stream 更换或 `RESYNC_REQUIRED`，再做版本回退判定；target 不是同一 stream 即清空并 resync。缺少 snapshot identity 的旧 provider 保持 wire 兼容，但每轮完整 resync，公开 detail 标记 `snapshot_identity_unavailable`，不宣称可靠增量 `no_change`。
- `GET_WINDOW_PROGRESS` 仅返回显示进度；新增 `GET_WINDOW_INTERACTION` 的 action discovery、传输分派与客户端命令。该入口要求 `ALL` 资源授权；`IDS` 作用域返回无交互字段的 `unauthorized_resource`，而 `ALL` 返回焦点、layer 与可用 selection。两正常应用的 README 明确分别声明两种 scope。
- 旧 root viewport 红测已两次复现和记录：直接从 `cjpm test` 的 Cangjie worker 调 `window.start()` 会得到 `CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD`（status `1`）。它是 AppKit 入口环境限制，非本阶段 viewport/layout 回归；测试改为 owner 无关的映射单测。规则与文档正常 AppKit 主线程 launcher 均实际创建 native window、提交首帧并获得 Metal readback 后退出 0。
- 先红后绿证据：Python 观察身份与 CLI 测试从 3 个失败到 18/18；core 授权/投影测试从 2 个失败到 37/37；规则 owner 15/15、root viewport 4/4 和 root `cjpm build --skip-script` 通过。两份 fresh normal bundle 的 source-blind 黑盒仅凭公开 README、descriptor 与 `client.py` 动态执行 `get`、`wait-window`、`window-interaction`、两轮 `observe --target`，均 exit 0、stream 稳定且进度端点不泄露交互字段。第一次针对旧 bundle 的失败作为 bundle 陈旧性证据保留，不把它与重建验收混同。
- 既有 180 秒性能工件未机械重跑：本收尾不改 owner 的 full/target snapshot 构造和布局热路径。未由本阶段验收的仍是物理 IME、人眼像素、安装/发布、稳定公共 API 与多平台。
