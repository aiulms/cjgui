# 通用原型宿主阶段结果（macOS，2026-11-08）

当前结果：已集中交付有明确支持范围的macOS开发候选；**整体成熟首版未完成**。最新指导复核与剩余范围见§44，实际实现与原始交付见§43及其引用；前文保留各轮版本与有效原件，不能把旧通过合成为当前全通过。唯一执行范围为[完整任务](../ai/2026-11-08-prototype-host-blocker-decisions.md)，视觉需求见[HTML对照方案与实际结果](2026-11-08-prototype-host-html-comparison.md)。

## 1 本阶段解决的实际问题与新增能力

- **一个普通 macOS CJGUI 应用作为通用原型宿主**：`runtime/cjgui/examples/prototype_host_app`。
  同一二进制用 `--project <目录>` 打开不同领域的原型项目；字段、数据、动作、界面文件与资源
  全部来自项目声明与数据文件，没有按案例名硬编码整页，也没有为三个案例各造宿主。
- **原型项目声明与 owner**：`prototype.json`（schema `cjgui.prototype-project.v1`）+ `data/*.json`
  + `ui/main.json`（既有 `cjgui.ui-document`）+ `assets/` + `session.json`。宿主从声明构建
  字段/记录/卡片与业务 owner；TEXT/INTEGER/BOOLEAN 与 select 呈现共用同一份声明。
- **运行时生成与编辑入口**：宿主通过既有 `CjguiSharedOperationExternalConnection` +
  `enableGeneratedUiProvider(region)` 发布 descriptor；模型用公开 `cjgui_generated_edit.py`
  发现能力、初始化结构、按 key 编辑、接受/读回、导出 `cjgui.ui-document`。
- **可复用 HIG 主题**：框架新增 `runtime/cjgui/src/composable_ui_hig_theme.cj`，
  `CjguiComposableUiTheme.higLight()/higDark()/hig()`；颜色取自本机 NSColor 语义色实测，
  控件尺寸取自 AppKit `sizeToFit` 实测与 HIG 文本样式，项目决定项逐条标注。
  手写 chrome 与生成式结构使用同一批 `namedStyles()` 角色，亮/暗切换不重新提交结构。
- **原型会话**：`session.json` 复用公共 `CjguiComposableUiWorkSession`（原子写、校验基线），
  只保存草稿/已应用值/选择/列数/外观；重启恢复草稿**不隐式 Apply**。
- **可复用列表/卡片接线**：记录列表复用公共虚拟列表（`cguiComposableVirtualList`，同一
  viewport/state，只为本轮可见窗口建行）；卡片面板复用公共 `Wrap`/图片节点；
  选择、筛选、列数归项目 owner，宿主不写第二套滚动/选择状态机。
- **反馈回接**：4 条观察按既有技能格式记录（见 §7），SDK 副本未改，源码未为观察做未验证修复。

## 2 交付物与路径

| 交付 | 路径 |
| --- | --- |
| 宿主源码/构建入口 | `runtime/cjgui/examples/prototype_host_app/`（`cjpm.toml`、`run.sh`、`src/*.cj`） |
| 本机构建候选 | `runtime/cjgui/examples/prototype_host_app/target/release/CJGUIPrototypeHost.app` |
| 项目 A 桌面设置表单 | `runtime/cjgui/examples/prototype_host_app/projects/settings/` |
| 项目 B 资产列表与详情 | `runtime/cjgui/examples/prototype_host_app/projects/assets/`（200 条确定性记录） |
| 项目 C 素材卡片面板 | `runtime/cjgui/examples/prototype_host_app/projects/materials/`（12 张卡 + 本地 PNG） |
| HIG 主题（框架公共） | `runtime/cjgui/src/composable_ui_hig_theme.cj`；角色说明见 `runtime/cjgui/STYLE_ROLES.md` |
| HIG 取样与基准 | `work/prototype-host-20261108/hig/`（reference.md、hig-tokens.json、取样脚本与原始输出） |
| 共同需求与种子数据 | `work/prototype-host-20261108/cases/`（CASES.md、generate_seed.py、data/、assets/） |
| HTML 对照 | `work/prototype-host-20261108/html/`（三例独立页面、seed.js、截图与说明） |
| 模型消费链证据 | `work/prototype-host-20261108/evidence/model-chain/` |
| 反馈记录 | `work/prototype-host-20261108/evidence/feedback/`（4 个 issue，技能格式） |

三个项目与宿主的关系是**数据**关系：`prototype.json` 的 `view`（form/list/cards）选择宿主提供的
通用浏览面板形态，字段/记录/卡片/动作全部来自声明；宿主源码中没有 `settings`/`assets`/`materials`
分支。

## 3 身份（实际消费）

- 框架来源：checkout `runtime/cjgui`（含本阶段新增 `composable_ui_hig_theme.cj`）；
  `cjgui_shared_operation_core` 同 checkout。`identify.py` 报告见
  `work/prototype-host-20261108/evidence/identify.json`（checkout 无 source-manifest，身份记为 unknown）。
- 构建：`./run.sh --build-only`（框架 macOS runner，`cjpm build --skip-script -i -V`）。
  冷构建首次 58.5s real（含 native 归档与 bundle）；后续源码级重建约 35–60s。
  构建 provenance（原源/快照哈希、native 归档身份、link map）在
  `examples/prototype_host_app/.cjgui/macos-build/build-provenance.json`。
- 运行：本机 `.app` 直接从 bundle 内可执行文件启动（不经编译 runner）；
  descriptor 由应用进程发布，关闭后失效（`CJGUI_PROTOTYPE_HOST_CLOSED endpoint=cleared`）。
- 框架根 `cjpm build --skip-script`：**通过**（exit 0，114 条既有 unused 类警告，无新 error）。

## 4 三例结果（同一二进制）

同一 `CJGUIPrototypeHost.app` 分别以 `--project projects/{settings,assets,materials}` 启动；
三例界面结构均由公开编辑入口生成 → 导出为项目 `ui/main.json` → 重启自动载入
（`CJGUI_PROTOTYPE_HOST_STRUCTURE_ACCEPTED ... document=applied:accepted`）。

### A 桌面设置表单（settings）

- 界面：分组卡片「外观」「通知」、select（外观/强调色）、布尔、整数、文本字段、帮助文本、
  错误文本、右对齐操作行（恢复默认/取消草稿/应用草稿）。
- 已真实执行并录制：清空整数 → 字段错误「需要 1–60 之间的整数」+ 应用按钮禁用 + 已应用值保留；
  真实键盘输入 `30` → 错误消失、可应用；点生成式「应用草稿」→ owner applied 更新为 30；
  签名框真实键盘输入 `周报2026` → 应用后 applied 更新；亮/暗切换；720 宽窄窗。
- 运行时兼容修改：向声明新增字段的代码路径已实现（保留同 id 字段草稿、注册新字段、不重启），
  但本阶段**未取得新字段的可见验收**（见 §8）。
- 证据：`evidence/model-chain/settings-*.png`、`capabilities-settings.txt`、`settings-structure.json`、
  `layout-fix-plan.json`、`action-row-fix.json`。

### B 资产列表与详情（assets）

- 200 条确定性记录；左侧筛选框 + 公共虚拟列表（只物化可见行：首屏 24 行，行高 26+2）；
  右侧生成式详情表单（标题/数量/启用/备注）+ 操作行。
- 已真实执行：点击 `季度报告汇编 011` → 详情 owner 切到该记录（读回 title/quantity 变化）；
  筛选框输入「报告」→ 列表收敛到标题含「报告」的记录；缩窄窗口走宿主窄窗分支（列表可折叠）。
  列表滚动到中部、缩窄/恢复的截图级对照未全部取得（见 §8）。
- 证据：`evidence/model-chain/assets-*.png`、`assets-detail-structure.json`。

### C 素材卡片面板（materials）

- 12 张卡，真实本地 PNG；卡 `card-07` 故意缺图并以红色「图片缺失」占位，不假装加载成功；
  工具栏含筛选、2/3/4 列、清除筛选；下方生成式详情面板（标题/状态/备注 + 操作）。
- 已真实执行：初始 3 列 → 点「4 列」→ 重新换行；点击 `素材卡片 05` → 详情切到该卡
  （读回 status=blocked、note）；缺失图片卡可见；筛选无匹配的空状态路径在代码中按
  「没有匹配的素材」呈现（本阶段仅取得列表筛选收敛的 AX 证据，空态截图未取）。
- 证据：`evidence/model-chain/materials-cards*.png`、`materials-detail-structure.json`。

### HTML 独立对照（同需求、同初始数据、独立实现）

三例 HTML 对照在 `work/prototype-host-20261108/html/`（独立页面、`seed.js` 由脚本从
`cases/data/*.json` 生成，支持 file:// 打开），截图与自检在 `html/shots/` 与
`evidence/html/`。HTML 侧检查结果见其 `README.md`/自检 JSON；两侧共用
`cases/CASES.md` 与确定性数据，未用一侧输出当另一侧期望。

HTML 侧自检：`evidence/html/selftest-latest.json` **39 项 DOM 断言全过、0 失败**（headless Chrome，
真实键盘/点击/滚轮驱动；明确标注「DOM 断言，不是人眼/AX」）；截图 10 张（A 1280/960/720/暗色，
B/C 1280/960/720），元数据在 `html/shots/manifest.json`；HTML 均按 `hig-tokens.json` 取值
（window/control 背景、label/secondary/tertiary、separator、controlAccent、focus indicator、
control_height_large 28、toolbar 44、radius 5/7/10、focus ring 3 等），未采用项见其 README §8。
HTML 侧与 CASES.md 的偏差 13 条由其 README §6 全列（模拟重载钩子、列数响应式上限、localStorage
持久化、B 行高/栏宽等），本报告不替它宣称未取得项。

已核对的可见差异（同状态截图对照，非像素逐点）：

| 维度 | HTML 对照 | CJGUI 宿主 | 判断 |
| --- | --- | --- | --- |
| 设置行布局 | 标签列 + 右侧控件（macOS 系统设置两列行） | 生成式字段是单行「标签 值」内联框 | CJGUI 生成式配方缺少两列行布局（能力/配方请求） |
| 外观/强调色 | segmented + 色板 | select 下拉 | 两实现功能等价，呈现不同；CJGUI 缺 segmented 配方（组件存在但未给字段行配方） |
| 布尔 | 开关（switch） | checkbox | CJGUI 有 switch 能力？本阶段未在生成式字段行使用 |
| 整数/文本 | 步进器 + 字符计数 | 纯输入框 | 计数/步进属宿主未接的呈现能力 |
| 资产列表行 | 主标题 + 次行（id/分组/数量） | 单行标题 | CJGUI 列表行只有标题；次行信息未接（宿主行构建器范围） |
| 详情表单 | 两列行 + 底部动作栏 | 内联字段 + 内容内动作行 | 布局责任不同，皆可用 |
| 卡片面板 | 卡片 + 底部动作栏/弹层 | 卡片 + 下方生成式详情面板 | 皆完成选择/换列/缺失图；CJGUI 详情常驻而非弹层 |
| 空/缺失状态 | 有空态与缺失图占位 | 缺失图占位已验；空态路径在代码中呈现但未取图 | 部分未证 |

这些差异中「两列行布局、segmented 字段行、switch、步进器、字符计数、次行列表」属于
**能力/配方请求**，不是已有 API 的 bug：CJGUI 有分段/开关等组件，但生成式字段行配方未覆盖，
因此本阶段如实记录为未接能力（见 §7 第 5 条反馈），不声称已复刻 macOS 系统设置外观。

## 5 模型公开消费链（本执行者即真实模型）

记录实际条件：**本执行者（DeepSeek Harness 中的模型）通过公开 descriptor 与公开 Python 客户端
完成发现、生成、读回与续改**；上下文包含框架源码（开发者知情条件，不宣称独立新用户盲测）。
脚本回放不计入本链。

1. `python3 cjgui_generated_edit.py DESCRIPTOR capabilities`：读到 15 个组件、5 个字段、
   3 个动作、select 选项（含中文标签）、节点/深度/字符串预算。
2. `init settings-structure.json`：从空区生成 v1（20 节点），accepted + 精确读回。
3. 人类真实键盘输入 → draft 变化；`readback.py`（typed 公共客户端）读回
   draft/applied/fieldVersion/validation。
4. 点生成式 APPLY_DRAFT → owner 写入，读回 applied 变化。
5. `preview` + `apply layout-fix-plan.json`（16 个 set_property）→ accepted v2；
   `action-row-fix.json` → v3；`ui-export` 写项目 `ui/main.json`。
6. 重启宿主 → 启动载入文档（applied:accepted），再读回字段/结构版本一致。

计时原数（同一本机，非稳定性样本）：

| 步骤 | 原数 |
| --- | --- |
| settings init v0→v1 | 见 `settings-structure.json` 对应提交（accepted，精确读回） |
| settings 布局修复提交→接受 | 101.0 ms（readback 30.4 ms，candidate_reads=2） |
| settings 操作行修复提交→接受 | 117.3 ms（readback 29.1 ms） |
| assets init v0→v1 | 62.9 ms（readback 14.2 ms） |
| materials init v0→v1 | 54.7 ms（readback 9.2 ms） |
| 冷构建（首次） | 58.53 s real |
| 模型生成用时 | 未单独计时（同一 agent 会话内生成，含思考与工具往返） |

「提交→接受」不等于「可见」：其中 v2/v3 的可见结果用同状态截图与 accepted 布局诊断分别核对；
`submit_to_visible_ms` 未取得（客户端未发布该字段）。

## 6 HIG 主题与视觉差异

- 颜色：`hig-tokens.json` 记录本机 macOS NSColor 语义色 light/dark 实测（含 alpha 与合成值）、
  AppKit 控件/窗口尺寸实测；HIG 页面（designing-for-macos、layout、sidebars、toolbars、
  typography、color）作为规则依据，访问日期与 URL 见 `hig/reference.md`。
- 落成：亮/暗两套页面/分组表面/输入/主次操作/强调与焦点环；控件高 28pt（AppKit large 实测，
  自绘 + 中文正文选它而非 24pt regular）；正文 13pt、标题 22pt、说明 11pt（HIG 文本样式）；
  间距 4/8/12/16、圆角 7/10 标为 project-decision。
- 未做（如实记为差异）：窗口标题栏跟随系统外观（不调用 NSAppearance）、玻璃/模糊/材质、
  完整 macOS 控件外观（下拉、菜单、弹窗样式不等同原生）、非等比缩放下的像素级对齐。
- 视觉结论指向 `evidence/model-chain/settings-v2/v4/dark/720.png`、
  `assets-v1.png`、`materials-cards3.png`、`materials-4col.png` 与各自的 accepted 布局诊断。

## 6.5 验证证据（按改动范围）

| 检查 | 结果 / 位置 |
| --- | --- |
| 应用针对性测试 | 3/3 通过：`prototypeDeclarationParsesFieldsAndRecords`、`prototypeDeclarationRejectsUnknownSchemaAndBadSelect`、`prototypeSessionPayloadRoundTripsDraftWithoutApply`；日志 `evidence/build/app-tests-*.log` |
| 框架根 `cjpm build --skip-script` | exit 0（114 条既有 unused 类 warning，无 error） |
| 宿主正常构建 | exit 0；最终候选 executable sha256 `f81b30455a3cec6e242906055f770a6347dda392d78ecec670ee3580011984f4` |
| 运行冒烟 | 最终候选启动 → `CJGUI_PROTOTYPE_HOST_READY` + 启动载入 `applied:accepted`；窗口 AX 可访问（980×792，标题「偏好设置」） |
| `git diff --check` | 通过（无空白错误） |
| 受保护路径 | `runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/cjpm.toml`、`cjpm.lock` 未改 |
| 公共声明扫描 | 框架新增公共 API 仅 `CjguiComposableUiTheme.higLight()/higDark()/hig()/higAppearanceName()`（`src/composable_ui_hig_theme.cj`）；未改既有签名 |
| 禁止行为扫描 | 宿主无新增 FFI/子进程/外部 GUI 框架依赖；只 import `cjgui`、`cjgui_shared_operation_core` 与 Cangjie 标准库 |
| 同 target 串行 | 本阶段出现一次并行构建冲突（后台测试与构建同时写同一 target），runner 以“配置未知/非空 target”拒绝并保留旧产物；已按版本文档隔离该应用自有 target 后重建，日志 `evidence/build/concurrent-build-refusal.log`。重试后构建/测试串行通过 |

## 7 反馈与三种修复状态

用技能 `feedback.py` 在 `evidence/feedback/` 建立 4 个 issue（未删失败、未建第二套 issue 系统）：

| issue 主题 | 分类 | triage | source_fix | sdk_inclusion | consumer_verification |
| --- | --- | --- | --- | --- | --- |
| 生成式 action 节点宽度为 0，需 fixedWidth 才可见 | api_usability | needs_evidence | not_needed | not_applicable | settings 生成→点击真实写入 |
| 生成式字段默认像只读文本，需 style=input | documentation_example/api_usability | usability_improvement | not_needed | not_applicable | 三项目同配方，AX 输入与读回一致 |
| 嵌套裁剪超限只回滚为 clip_constraint_capacity，无节点定位 | framework_behavior(诊断) | needs_evidence | not_needed | not_applicable | materials 卡片面板修复后正常 |
| 启动载入票据须 finish 结算后才能保存界面 | documentation_example | usability_improvement | not_needed | not_applicable | 保存界面/重启再载入通过 |
| HIG 表单行配方缺口（两列行/segmented 字段行/开关/步进器/计数/列表次行） | capability_request | pending | not_needed | not_applicable | 三例业务操作可用；视觉形态未实现，不宣称已复刻 |

说明：本阶段**没有把观察直接改写成框架修复**；四条都停在「源码需要或文档需要」的判断上，
按技能约定 source_fix/sdk_inclusion 未冒充完成。观察受限的已知情况：均为同一执行者在开发者
知情条件下产生，不含第二个独立使用者复现。

## 8 未通过 / 未证条件

- **运行时新增字段的可见验收未取得**：`adoptDeclaration` 只实现「注册新字段 + 保留同 id 字段草稿 +
  重接绑定」，未处理界面结构中旧字段节点的重排/新字段节点的自动出现；未在本阶段完成
  「声明加字段 → 不重启 → 界面上出现并可编辑」的端到端证据。
- **有草稿时重排界面的验收**：模型侧 `move` 能力已由公开客户端支持，但本阶段未在设置项目上
  取得「草稿保留 + 重排后继续输入」的完整截图链。
- **清空筛选/空态/缺失资源的截图级对照**：B 的列表滚动到中部、窄窗折叠/恢复，C 的筛选空态，
  只取得部分 AX/结构证据，未全部取图。
- **HTML 对照的逐条同状态视觉核对**：HTML 侧已交付 10 张截图与 39 项 DOM 断言、13 条自列偏差；
  本报告只做了同状态抽看（A/B 1280、C 4 列）与结构性差异归类，**未做逐条像素/人眼比对**，
  也未复核 HTML 侧每一条断言的正确性；该部分按未证记录。
- **人亲自试用、VoiceOver、正式发布/公证/新机器安装**：未做。
- **同 target 并行**：本阶段一次后台测试与构建并行导致 target 配置冲突（已隔离重建）；后续同一应用 build/test 必须串行。
- **普通编辑/空闲/切换后的资源变化**：未测（无 VmRSS/GPU 采样），不宣称。
- **SDK 形态验证**：本阶段只消费 checkout，未导出 SDK、未做包外新机器验证；
  `sdk_inclusion` 全部如实为 not_applicable。

## 9 复现与使用（最短）

```sh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
./run.sh --build-only
APP=target/release/CJGUIPrototypeHost.app/Contents/MacOS/CJGUIPrototypeHost
"$APP" --project "$PWD/projects/settings"      # 或 projects/assets / projects/materials
```

模型侧（另开终端，用启动日志里的 `CJGUI_PROTOTYPE_HOST_DESCRIPTOR` 路径）：

```sh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core
python3 cjgui_generated_edit.py "$DESCRIPTOR" capabilities
python3 cjgui_generated_edit.py "$DESCRIPTOR" show
python3 cjgui_generated_edit.py "$DESCRIPTOR" init /path/to/structure.json
python3 cjgui_generated_edit.py "$DESCRIPTOR" apply /path/to/plan.json
python3 cjgui_generated_edit.py "$DESCRIPTOR" ui-export "$PROJECT/ui/main.json"
```

诊断（只读）：`"$APP" --project ... --diagnose-window` 打印 accepted 节点的
depth/semanticId/bounds/clip（`window.diagnosticSnapshot`，不重放事件、不写 owner）。

## 10 空间账（本阶段）

- 新增（实测 `du`）：宿主源码 148 KiB、三项目 120 KiB、`work/prototype-host-20261108/` 9.1 MiB
  （需求/数据/HTML/截图/HIG 取样/证据/反馈）；构建产物（gitignored、可复用单目录）
  `target/` 151 MiB + `.cjgui/` 36 MiB。合计新增约 **197 MiB**。
- 保留：`runtime/cjgui/examples/prototype_host_app/`（源码 + 单个可复用 target）、
  `work/prototype-host-20261108/`（本阶段原件与证据）。均为单一交付引用，不另生完整导出包。
- 释放：宿主旧模板 bundle `CJGUIUiOnlyStarter.app` 与 `cjgui_ui_only_starter` 构建目录已删除
  （约 20 MiB，属本任务新生成物）；无其他删除。
- 宿主剩余空间：开工 218 GiB，收尾 217 GiB（同一卷），远高于 20 GiB 下限；
  未做 GiB 级夹具，无大日志（单文件均 < 1 MiB）。

---

# 修复轮结果（2026-11-08 白名单，同日）

本文件上一部分是首轮交付。本轮按指导下发的白名单推进：**先为问题保留能证明错误的反例，再做最小修复；每批修改后回到正常原型入口验证，再继续**。未扩大修复范围：框架源码（`runtime/cjgui/src`、`shared_operation_core`）本轮零改动，所有改动在宿主应用、三项目数据/界面结构、文档与证据。

## 11 白名单修复三项

### 11.1 运行时新增字段接入真实 owner（已修复并端到端验证）

**原缺陷**：`PrototypeSession.adoptDeclaration()` 只向能力目录注册新字段，没有同步项目字段、owner 声明与草稿存储，`rebind()` 仍绑定旧对象。

**修复**（`prototype_session.cj` / `prototype_domain.cj` / `prototype_declaration.cj` / `prototype_controller.cj`）：
- 采集新增字段并保持既有字段的稳定 resourceId（新字段从当前最大 resourceId+10 单调分配）；
- 声明兼容性前置校验：只允许新增字段/动作与标题变化；视图/记录集/主题/窗口/分组、既有字段规则、既有动作的变化以具名原因整体拒绝（`view_change_requires_project_switch`、`existing_field_rule_change_unsupported` 等），不部分更新；
- 新字段需要的标准组件（textInput/integerInput/booleanInput/select/radioGroup/segmented）缺失时按既有生成式词表补注册；select 字段注册 choice options 并绑定；
- 所有对象按稳定字段 ID 扩展声明与草稿数组：同 id 同类型保留 draft/applied/fieldVersion，新字段用声明默认值初始化；全部新数组本地构建完成后才整体替换；
- 最后一步才 `catalog.registerField` + owner adopt + `rebind()`；可失败的检查都在变更前完成。

**验证（同进程、不重启、不重编译）**：settings 项目运行时向 `prototype.json` 加 `syncPolicy`（select，3 选项）→ 点「重载声明」→ 状态 `declaration_updated:1（owner/目录/绑定已同步）`；公开 capabilities 从 5 个字段变 6 个并发布新字段 choice options；模型用公开编辑计划插入 `field-syncPolicy` 节点（accepted v2，54.0ms）；人点 segmented/select 交互后 `draft=auto`；点生成式 `APPLY_DRAFT` 后 `applied=auto`（真实 owner 写入）；全程同一 descriptor。证据：`evidence/whitelist/caps-before.txt`、`caps-after-reload.txt`、`add-syncfield-plan.json`、`runtime-new-field.png`、`settings-v3*.png`。
**失败守恒**：把 `syncPolicy` 从声明删除后再点重载 → `field_removal_requires_project_switch:syncPolicy；保留当前项目与已有草稿`，会话未变。
**测试**：`prototypeAdoptDeclarationAddsFieldToOwnerCatalogAndBinding`、`prototypeAdoptDeclarationRejectsExistingFieldRuleChange` 通过。

### 11.2 项目切换同步外部连接与旧状态保护（已修复并验证）

**原缺陷**：`switchProject()` 直接替换 session，外部连接仍指向旧 domain/region；旧 session 在新会话准备完成前就被关闭；未保存状态会被静默丢弃。

**修复**：
- 新增 `PrototypeHostBridge`（`prototype_bridge.cj`）实现 `CjguiSharedOperationDomain & CjguiSharedOperationGeneratedUiProvider`，所有调用转发到**当前** session；外部连接在启动时绑定这个桥，切换项目只调用 `bridge.adopt(newSession)`（generation +1）。窗口内容与外部连接因此始终是同一个新 owner；旧结构候选会被新区域按版本/字段拒绝，旧业务动作只会落到当前 owner。
- `switchProject()` 顺序改为：场景事务空闲检查 → 未保存状态判断 → 加载声明 → 在内存中完整构造新 `PrototypeSession`（声明/owner/目录/工作区/文档会话）→ 成功后才关闭旧会话并 `bridge.adopt` → 初始化工作会话、启动文档载入、刷新。任一步失败保留旧项目。
- 未保存状态（未应用草稿或未保存界面）：第一次点「打开」只提示并记住目标；再点同一项目才作为明确确认放弃，不静默丢弃。

**验证（同进程切换）**：settings（有未应用草稿）→ 输入 assets 路径点「打开」→ 状态提示“当前项目有未应用草稿：再次打开同一项目将放弃…”，capabilities 仍 5 字段；再点「打开」→ 切到资产库（`连接目标第 2 代`），同一 descriptor 读回 4 字段/200 记录，UI 文档 `applied:accepted`；人点资产 `内部交付清单 002`，模型读回 `title='内部交付清单 002'`（人与模型同一 owner）；向旧结构提交候选 → `stale_base_version`；切回 settings 后旧 assets 节点提交 → `unknown_key`（无旧写入）；非法路径 → `项目打开被拒绝…保留当前项目`，会话不变。证据：`evidence/whitelist/switch-to-assets.png`、`caps-after-switch.txt`、`stale-candidate-plan.json`、`stale-assets-candidate-plan.json`。

### 11.3 会话恢复按字段 ID 且整体校验（已修复并验证）

**原缺陷**：保存内容是数组，恢复按位置写入；多对象恢复跳过失败对象仍可能报成功。

**修复**：
- `session.json` 升级为 `cjgui.prototype-host.session.v2`：`declaration.fields[{id,kind}]` + 每个对象 `draft/applied/fieldVersions` **按字段 ID 的 map** + 版本号；恢复前整体校验字段集合/类型/对象集合/版本自洽，全部通过后才发布，失败整体拒绝、不部分写入。
- 旧 v1 文件（无字段身份）不猜测：启动时 `work_session_schema` → 原文件保留为 `session.json.v1.bak`（`session=legacy_preserved`），当前会话用默认值；新保存写 v2。
- 声明变化（新增字段后旧会话缺字段）以 `session_declaration_mismatch:*` 整体拒绝。

**验证**：settings 清空签名输入 `按ID恢复验证` → 保存会话（v2，payload 内含 5 个字段 ID）→ 重启 → `session=restored`，draft 按 ID 恢复、applied 保持旧值（不隐式 Apply）；`session.json.v1.bak` 保留旧格式原件。
**测试**：`prototypeSessionPayloadMatchesFieldsByIdAcrossReorder`（同数量字段重排）、`...RejectsAddedFieldWithoutPartialRestore`（新增字段反例）、`...RejectsObjectMissingOneField`（单对象载荷不合法反例）全过。

## 12 配方与接入改进（已实施）

- **表单行分列**：`cases/generate_structures.py` 生成三项目结构，每个可编辑行 = 横向容器 [标签列 fixedWidth 300：标签 body + 帮助 caption] + [控件列]；分组用 `card` 角色；操作行右对齐。输入/下拉/整数显式 `style: input`，操作按钮显式 `primary_action/secondary_action/quiet_action`（保留显式覆盖，不改全局默认语义）。
- **操作行尺寸责任**：生成式横向行自然宽度不计入固定宽度子项（见 §13.1），操作行本身声明 `fixedWidth=子项和`、`growX=0`，三例操作按钮才稳定可见。
- **资产列表主/次行**：宿主列表行改为两行（标题 + `资产 id · 数量 · 启用/已停用`），行高 42；次行点击按 semanticId 路由到同一次选择（主标题按钮路径已用 AX 点击验证；次行 label 在本构建 AX 中不可直接寻址，见 §15）。
- **segmented 接入尝试（未采用为可编辑控件）**：生成式 segmented 能渲染并暴露 radiobutton，但点击不写 owner（§14.1），因此可编辑字段改用已验可写的 `select`；这一项属于“使用已有生成式 segmented 能力”的受阻事实，不宣称完成。
- **NumericStepper**：`CjguiNumericStepper` 只存在于手写控件层，生成式词表没有步进器呈现；把宿主列数按钮换成步进器会改变 CASES 要求的操作序列，因此在生成式表单里未使用，按 §14 记录为“生成式接入缺口”，不新造组件。
- **回归**：三项目结构重新生成并各自 `init` accepted（settings 35 节点、assets 27、materials 25），`ui-export` 写回各自 `ui/main.json`；重启三项目均 `STRUCTURE_ACCEPTED`（settings/materials `applied:accepted`，assets 采样时 `applied:submitted` 后结算同路径）。
- **HTML 对照**：三页 HTML 仍对应 CASES 原需求（未因本轮配方改动修改）；CJGUI 新版式把原先“逐字段堆叠”改为两列行、列表加次行后，与 HTML 的可见差距缩小到：segmented/开关/步进器/字符计数/列表两行字体密度（HTML 更接近系统设置，CJGUI 用 select/checkbox/两行列表）。差异与未复刻项仍在 §6 表中如实列出，没有用本轮配方宣称“已复刻系统设置”。

## 13 只调查、未修改的反馈

### 13.1 生成式 action 宽度为 0（追加归因，仍不修框架）
保留首轮最小失败结构，并新增归因证据：给 action 自身 fixedWidth 后按钮可见，但**水平行本身仍被测量为 24pt 宽**（子项 96+96+110 溢出窗口右缘），给行加 fixedWidth=318 后一切正常。归因范围缩小为：生成式 `horizontal` 的自然宽度不包含固定宽度子项（action 无内建内容宽度是同一归属问题的表层）。未修改测量/布局机制；应用侧保留行宽配方。反馈已追加到原 issue（events=2）。

### 13.2 嵌套裁剪上限（最小复现，仍不修契约）
源码 `CJGUI_COMPOSABLE_UI_MAX_CLIP_CONSTRAINTS = 4`（`src/composable_ui.cj:391`），布局累计到 4 后再遇 clipsContent/滚动区即置 `clip_constraint_capacity`（`composable_ui.cj:8819`）。新增宿主诊断入口 `--clip-probe N` 复现：N=2 能出首帧；N=3 首帧前整场回滚，stderr 一行 `rollback reason=clip_constraint_capacity`。未提高上限、未改裁剪算法、未通过删裁剪宣称修复；应用侧继续“只在必要节点保留裁剪”。反馈已追加到原 issue（events=2）。

### 13.3 启动文档 finish()（接线确认，不需框架改动）
同版 README/技能文档已写明 `beginStartup` 后由事件循环调用 `finish()`；宿主在空闲边界结算，保存返回 `applied:saved`，未结算时正当 `refused:ui_document_submitted`。本轮确认无需改结算协议。反馈已追加到原 issue（events=2）。

## 14 新发现、只记录未修改的问题

1. **生成式 segmented / radioGroup 选项不写 owner**（`06-segmented-radio-options-not-committing`）：AX 暴露 radiobutton 可点击，AXPress / 物理坐标点击 / 键盘都未改变 draft（fieldVersion 0）；同字段 `select` 下拉正常写入。已改用 select 作为可写呈现，未改框架。
2. **生成式字段空 label 回退声明 label**（`07-generated-empty-label-falls-back`）：外部标签列 + 控件内重复标签；只能传 U+200B 抑制，AX 名不理想。未改框架。
3. **项目切换后窗口标题不变**：窗口标题在启动配置中固定，没有运行期变更 API；切换项目后内容/owner/连接都换了，标题仍是旧项目。本轮未改宿主/框架，只在 README 记为已知边界。
4. **NumericStepper 生成式接入缺口**（§12）：生成式词表没有步进器呈现，手写控件存在但接入属框架公共面，未实施。

以上 1–2 已用技能 `feedback.py` 建 issue 并保留复现；3–4 记在本文件与 README，未改代码。

## 15 未通过 / 未证（本轮）

- **列表次行点击路由**：代码已接（semanticId 前缀 → 同一次选择），但该 label 在本构建 AX 中无 ref、无法直接点击验证；主标题按钮选择已验证。次行点击的物理坐标验证未做，不宣称已验。
- **segmented/radioGroup 只有“点击不写”的失败证据**：未在框架源码定位到事件绑定责任点，也未做最小独立复现；属“记录待指导批准”，不是已修复项。
- **项目切换的“新会话构造失败”分支**只做了非法声明（加载失败）反例；内存构造异常的注入未做。
- **声明扩展只支持新增字段/动作**：规则修改（label/min/max/help/只读等）按设计整体拒绝，未实现增量更新；运行时删除字段同样拒绝。
- **窗口标题、VoiceOver、正式发布/公证、SDK 形态、资源占用（VmRSS/GPU）** 未验；与首轮一致。
- **HTML 对照仍无逐条像素/人眼核对**：只做同状态抽看与结构性差异归类（首轮结论不变）。

## 16 验证与身份（本轮）

| 检查 | 结果 |
| --- | --- |
| 应用针对性测试 | 8/8 通过（含新增会话/声明扩展反例），日志 `evidence/build/app-tests-whitelist.log` |
| 构建 | 宿主 `./run.sh --build-only` exit 0；最终候选 sha256 `afc07d5fc7f01d0e6bab0972b92cb41f966bd250cadd61fd74b17041d97eefb5` |
| 框架源码改动 | 无（本轮仅应用/项目数据/文档/证据；`runtime/cjgui/src`、`shared_operation_core` 未改，无需重跑框架构建作为本轮门禁；首轮已过） |
| 运行冒烟 | 最终候选启动 materials → `READY` + `STRUCTURE_ACCEPTED applied:accepted` |
| 受保护路径 | 未触碰 `runtime_state.cj`、`cjpm.toml`、`cjpm.lock`；未 stage/commit/push |
| 目标平台/身份 | macOS 15.x arm64；Cangjie 1.1.3；CJGUI checkout `runtime/cjgui`；SDK 形态未导出（未知/不适用） |

## 17 空间账（本轮）

- 新增（实测）：三项目结构生成脚本与结构 JSON、白名单证据截图/日志/探针、HTML 未改；`work/prototype-host-20261108` 由 10 MiB 增至 **21 MiB**（本轮 +11 MiB）；宿主 `target` 151 MiB + `.cjgui` 36 MiB（复用单一构建目录），三项目 `ui/main.json` 合计约 16 KiB。
- 清理：临时探针实例全部关闭；测试后 target 已退役重建为生产候选；`/tmp` 中旧 ui 备份与退役 target 由系统临时目录回收（未计入保留）。
- 宿主剩余：本轮收尾约 216 GiB 可用（同一卷），高于 20 GiB 下限；未创建 GiB 级夹具。

## 18 第二轮补证（2026-11-08 收尾）

本轮只补验既定白名单结果，未改框架、未扩大范围。宿主侧另修一处**本轮配方自身的缺陷**：列表行改为两行后，列表节点仍按 26pt 行高布局（子项 42pt 溢出并压到下一行），改为 42pt 并重验（属应用侧新写的配方代码，非既有修复）。

- **草稿重排**（原方案“草稿重排”条件）：settings 键入 `按ID恢复验证·重排`（draft，applied 仍 `团队周报`）→ 模型公开 `move` 把签名行前移再移回（accepted v2/v3）→ 读回 draft 与 fieldVersion 保持、applied 不变；窗口仍可编辑。证据：`evidence/whitelist/reorder-plan.json`、`reorder-back-plan.json`、`reorder-draft2.png`、readback 输出。
- **同尺寸 HTML 对照补图**（内容区宽 1280/960/720，settings 另 1280 暗色）：`evidence/whitelist/cmp-{settings,assets,materials}-{1280,960,720}.png`、`cmp-settings-1280-dark.png`（共 10 张，窗口经 `resize-window` 实测宽高）。同状态抽看结论：设置行两列、列表主/次行、详情两列已与 HTML 结构接近；剩余差异仍是 HTML 的 segmented/开关/步进器/字符计数/底栏，以及 CJGUI 用 select/checkbox/内容内操作行——未做逐像素比对。
- **列表次行点击（未通过）**：代码按 semanticId 前缀路由到同一选择，但物理点击次行（坐标由同排主标题 AX bounds 推算，`(266,660)`）未触发选择；推断普通 label 节点不是指针命中目标，次行只有主标题按钮可点。按“未验/不可达”记录，不宣称整行可点（可改造成可变高度行+整行按钮，属新范围，未做）。
- **字段 AX 命名副作用**（追加证据到 label 回退 issue）：抑制内部标签后，文本字段 AX 名变成零宽空格（`名称='​'`、值可读），按名称定位字段不可用；这只影响可访问性体验，未改框架。
- 复验：应用测试 8/8 仍通过（测试只覆盖声明/会话，不受列表行高影响）；最终候选重建并冒烟（materials `READY` + `applied:accepted`）；`git diff --check` 通过；框架源码仍零改动。
- 空间（第二轮收尾，实测）：`work/prototype-host-20261108` 21→**27 MiB**（新增 10 张同尺寸对照图与重排/行高证据）；宿主 `target` ~151 MiB、`.cjgui` 36 MiB（复用同一构建目录）；测试用 target 已退役删除；宿主剩余 216 GiB。最终候选 sha256 `4e9d2798…eaa832`（重建后覆盖先前 `afc07d5f…`）。

---

# R1–R9 修复轮（2026-11-08 第三轮，指导复核后白名单）

本轮首次修改框架源码（R4–R7、R9 接入），并完成 R1–R3 宿主正确性边界。以下只写实际取得的结果。

## 19.1 R1–R3（旧白名单续修）

- **R1 跨会话请求隔离（已修）**：`PrototypeHostBridge` 增加会话代际观察门：`adopt()` 后代际 +1、观察代际清零；所有公开读（capabilities/fields/accepted/snapshot/…）重新绑定时才会为当前代际“解锁”写；`submitStructure`、`submitUiDocumentHistory`、`executeFromExternal` 在未读新会话时返回具名 `stale_session_generation`，不再仅凭版本/字段兼容把旧请求转给新 owner。反例证据：两个字段相同、版本同为 0 的项目，切换后同一候选 **新 region 本身会接受**（RED 条件），经桥未读则拒绝；读一次 capabilities 后同一候选被正常接受（同 descriptor 继续可用）。业务调用同样有 RED/GREEN 测试。测试：`prototypeBridgeRejectsCrossSessionCandidateUntilRead`、`...BusinessCallUntilRead`。
- **R2 全记录草稿保护（已修）**：新增 `PrototypeDomain.hasAnyDraftChanges()`；`switchProject` 与 `requestWindowClose` 改用项目级检查，并保留未保存界面结构保护（`workspace.closeDecision()`）。反例测试：编辑记录 A、选中干净 B 后 `hasAnyDraftChanges()` 为 true（旧实现只看 active 会丢 A）。
- **R3 声明重载原子性（已修）**：本轮只热更新字段；任何动作声明变化（增/删/改名/强调）以 `action_change_requires_project_switch` 整体拒绝，不再出现“字段已注册、第二个同名动作失败”的部分发布；`prototypeProjectWithFields` 始终携带当前动作声明。反例测试 `prototypeAdoptDeclarationRejectsActionChangesWithoutPartialPublish`：新增字段 + 两个同名新动作 → 拒绝后 catalog 无新字段、无新动作、字段数/草稿不变。字段扩展本身仍先预检后执行，owner/adopt 最后一步。

## 19.2 R4–R7、R9（框架修复/接入，首次改框架源码）

- **R4 segmented/radioGroup 选择写 owner（已修）**：`composable_ui_generated_region.cj` 的 `handleEventIfClaimed` 由 `declaredSelect.select.applyUiEvent` 改为 `declaredSelect.applyUiEvent`，选择行激活经既有 `applyChoiceEvent` + `takeConfirmed`/`commit` 统一入口；未重写三个呈现。真实窗口：settings 的 appearance 用 segmented，点 `深色` → `draft=dark, fieldVersion=1` → 应用草稿 → `applied=dark`；select 仍正常（assets/materials）。
- **R5 水平/普通容器自然宽度（已修）**：`composable_ui.cj` 的 `preferredWidth` 增加 HORIZONTAL 分支（子项和 + gap + padding，受 min/max/fixed 约束），并让普通 VERTICAL 容器按最大子项计算（stepper 根此前落到 24pt 回退）。宿主生成器**已移除操作行 fixedWidth 绕过**；三个操作行仍完整可见、右对齐。既有“三个固定宽度子项撑开父行”反例通过。
- **R6 裁剪容量诊断（已加，契约未变）**：布局记录首个超限节点/深度/上限/裁剪链，经 `CjguiComposableUiScene.layoutDiagnostic()` 与 `window.lastCandidateLayoutDiagnostic()` 只读暴露；`clip_constraint_capacity` 机器 token 与回滚语义不变，未提高上限、未改算法、未删裁剪。`--clip-probe 3` 现在同时输出：`rollback reason=clip_constraint_capacity` + `layoutDiagnostic=node=clip-probe-leaf;depth=5;limit=4;chain=semantic:clip-probe-2 > ... > clip-probe-leaf`；probe 2 仍出首帧。
- **R7 可见标签与可访问名称（已修）**：text/integer/boolean 生成式组件新增 `labelVisible`（默认 true 兼容回退）；`labelVisible=false` 时只隐藏可见 label，声明 label 作为 AX 名称（semanticLabel），bound form field 与 stepper 输入路径同样处理。宿主结构移除 U+200B，改为真实 label + labelVisible=false：两列行不重复显示内部标签，AX 名称为 `签名`/`提醒间隔（分钟）`，输入/校验/Apply 链不变。
- **R9 NumericStepper 生成式接入（已做，边界已验）**：integerInput 组件新增 `stepper` BOOLEAN 属性（默认 false）；true 时复用 `CjguiNumericStepper` 构建输入与 ± 按钮（不新造步进器），输入节点保留字段 writer/owner 路由，按钮动作 `cjgui-step-decrement:<field>` / `cjgui-step-increment:<field>` 由 region 解析：按声明 min/max/step 计算（越界拒绝、不 clamp），经**同一** `binding.applyFieldIntent` 写草稿，与输入/Apply/Cancel 共用路径。settings 的提醒间隔实际消费：点击 + 一次 15→16（fieldVersion +1，重复事件被同刷新代去重），max=16 的临时反例中 16 后再 + 被拒绝（draft 保持 16）。evidence：`evidence/whitelist/r9-settings5.png`、`r9-final-settings.png`。

## 19.3 R8 资产列表整行选择（已修）

次行由普通 label 改为携带同一 `SELECT_RECORD` 与 record resource 的按钮：标题、次行两行都进入既有选择处理器（未新增列表状态机、未把框架 label 全局改成可点击）。真实窗口：点击 `asset-0011 · 数量 78 · 启用` 次行 → 状态“已选 季度报告汇编 011”，模型经同一 descriptor 读回 `title=季度报告汇编 011, quantity=78`。

## 19.4 原型汇合验证（同一候选）

- settings：两列行 + segmented（appearance/accent）+ 整数步进（提醒间隔）+ 错误/禁用 + Apply/Cancel；segmented 与步进均真实写 owner；保存界面 `applied:saved`、保存会话、重启 `session=restored` 且 UI 文档 `applied:accepted`，applied 值恢复、无隐式 Apply。
- assets：200 条记录、筛选、滚动、整行选择、详情修改、切换记录返回；项目切换保护（R1/R2）由单元测试与旧证据覆盖，本轮未重做完整切换矩阵。
- materials：12 张卡、列数调整、选卡、缺图占位、详情两列（select/输入）与操作行；结构重新 init/export（25 节点）。
- 三项目 ui/main.json 已用新结构重导出（settings 33、assets 27、materials 25 节点），重启后均加载该文档。

## 19.5 未通过 / 未证（本轮）

- **stepper 的键盘/输入框直接键入**未取得一致证据：AX type 未改变 draft（可能与 stepper 内输入焦点/事件类型有关），只验证了 ± 按钮、边界拒绝与 Apply；不宣称“输入与步进都可用”。
- **连续快速点击去重**：同一刷新代内重复激活被合并，自动化 44 次快速 + 只前进一步；人工正常节奏可用，但未做长稳定采样，属已知限制。
- R4 只对 segmented 做了真实点验；radioGroup 走同一 `applyChoiceEvent` 分支但未单独点验。
- R5 修复后未重跑全框架测试矩阵（仅根 `cjpm build --skip-script` + 应用 12/12 测试 + 三例运行时）；框架既有相关测试未全部重跑。
- HTML 同条件对照本轮只抽看：既有 HTML 三页（1280/960/720）未改，CJGUI 新截图（settings 1280 等）未逐条比对；B/C 空态截图仍未补。
- R6 的 probe 2 在首帧后另有 `internal_error` 回滚（与容量无关），未定位。
- R1 的“新会话构造异常”注入仍未做；R2 切换时的候选丢弃矩阵未重做。

## 19.6 身份与验证（本轮）

- 源码改动：`runtime/cjgui/src/{composable_ui.cj, composable_ui_generated.cj, composable_ui_generated_form_binding.cj, composable_ui_generated_region.cj, composable_ui_window.cj}`（框架）；宿主 `examples/prototype_host_app/src/{prototype_bridge.cj(新), prototype_controller.cj, prototype_session.cj, prototype_domain.cj, prototype_declaration.cj, main.cj}` 与 `cases/generate_structures.py`、三项目 ui/main.json。
- 框架根 `cjpm build --skip-script`：通过（exit 0）。应用测试 12/12 通过（含 R1×2/R2/R3 新反例），日志 `evidence/build/app-tests-r9-final.log`。宿主 `./run.sh --build-only` 通过。
- 运行：macOS 15.x arm64、Cangjie 1.1.3、checkout `runtime/cjgui`；未导出 SDK（`sdk_inclusion=not_applicable`）；未 stage/commit/push；`git diff --check` 通过。
- 反馈：原 7 issue / 11 事件 → **7 issue / 16 事件**；R5/R4/R7/R6 追加修复证据并把 triage 改为 `framework_fix`（附 consumer_verification 与 workaround 退出说明），20e4 追加部分交付状态；旧事件保留。
- 空间：`work/prototype-host-20261108` 约 30 MiB、宿主 target/.cjgui 约 187 MiB（单目录复用）；测试 target 已退役；宿主剩余空间见收尾读数（≥20 GiB）。

## 20 第二轮补证与缺口记录（同轮收尾）

本轮不扩白名单，只补验 R1–R9 的未证边界、按指令复现/归因新问题、回接 skill。未修任何新问题。

### 20.1 已补齐
- **R4 radioGroup 单点**：settings 插入 radioGroup(accent) 探针 → AX 暴露 蓝/紫/粉/石墨 radiobutton；点 紫 → `draft=purple`（版本+1）→ 应用草稿 → `applied=purple`；随后删除探针恢复交付结构（`radio-probe-r4.json`、`r4-radio.png`）。与 segmented 走同一 `applyChoiceEvent` 分支的结论得到单点支持。
- **R5 反例回归**：`--diagnose-window` 读 accepted bounds：操作行 `component-30-1 = 318x32`（96+96+110+2×8），子项 x=636/740/844，右缘 954 < 区域 960；生成结构无操作行 fixedWidth（`diag-r5.log`、`r9-settings-*.png`）。
- **R9 步进与边界**：± 单击一次一步（15→16，fieldVersion +1，重复事件同刷新代去重）；临时 max=16 反例：16 后再 + 被拒绝（draft/fieldVersion 不变）；应用草稿写入 owner（applied=16）。
- **三项目同条件矩阵**：settings/assets/materials 各 1280/960/720，settings 另暗色；assets 与 materials 各补筛空空态；截图在 `evidence/whitelist/r9-{settings,assets,materials}-*.png`（含 `r9-assets-empty.png`、`r9-materials-empty.png`）。每个尺寸由 `resize-window` 实际设置，截图为窗口原图（非局部裁切）。
- **保存/重开**：settings 保存界面 `applied:saved`、保存会话、重启 `session=restored` + UI 文档 `applied:accepted`，applied 值恢复、无隐式 Apply。
- **反馈回接**：7 issue/16 事件 → **10 issue/22 事件**：R4/R5 追加修复证据，20e4 追加状态；新增 08（720 窄窗详情裁剪，归因宿主窄窗列非 stack）、09（stepper 输入框键入未达 owner）、10（probe 2 首帧后 internal_error）。

### 20.2 复现/归因后未修（按指令只记录）
- **720 宽 assets 详情字段区不显示**（新 issue 08）：复现非采集错误。诊断：`prototype-narrow-body` 高 160（窗口内容 735），`prototype-region-area/scroll` 高 120，region 内容被裁剪。归因：窄窗分支列用普通 vertical（非 STACK），growY 子项未伸展；修正方向为窄窗列改 stack/显式高度责任，待授权。
- **stepper 输入框键入不改草稿**（新 issue 09）：点击/物理点击可聚焦，键入 30 后 draft 仍 16；对照 assets 普通整数输入键入 99 → draft 99。属 R9 接入缺口（裸 integerInput 事件路由或复用 bound 编辑器），未修。
- **probe 2 首帧后 internal_error**（新 issue 10）：layoutDiagnostic 为空，与容量无关，根因未定位，只记录。

### 20.3 HTML 对照（本轮范围）
- 复用既有独立 HTML 三页（未改；1280/960/720 截图与 DOM 自检在 `html/`）。CJGUI 侧新矩阵截图已取得；对照抽看结论：两列表单行、segmented 外观、整数步进、列表主/次行两侧结构已接近；剩余差异仍是 HTML 的开关、字符计数、底部操作栏、强调色色板 vs CJGUI 的 select，以及 CJGUI 窄窗详情裁剪（§20.2）。**HTML 空态截图本轮未补**（HTML 仅在自检中覆盖 empty=1 的 DOM 断言），B/C 空态只取得 CJGUI 截图，不作为逐条对照。

### 20.4 验证与身份（本轮）
- 框架根 `cjpm build --skip-script` 通过；应用测试 12/12（同轮前记录）；`git diff --check` 通过；未 stage/commit/push；未导出 SDK。
- 最终候选仍为本轮构建的 `CJGUIPrototypeHost.app`（sha256 `f1552dc6…1bf826`）；本轮只改生成结构/项目数据/证据/文档，未再改源码，二进制未变。
- 空间：`work/prototype-host-20261108` ≈31 MiB、宿主 target/.cjgui ≈253 MiB（单目录复用）；无新增构建树；宿主剩余 216 GiB；自有实例已关闭。

## 21 HTML 空态/滚动对照与第三轮收尾（2026-11-08）

按本轮要求补齐「既有未取得的 B/C 空态与滚动状态对照」：扩展 HTML 采集脚本（`html/capture_shots.py`，新增 SHOT_PLAN_EXTRA，manifest 记录 URL/action/视口/DPR/sha），在 headless Chrome 下新增 6 张：`b-empty`、`c-empty`、`b-filter-empty`、`c-filter-empty`、`b-scrolled`、`c-scrolled`（1280×820，DPR=1，Chrome 版本见 manifest）。CJGUI 侧同条件补：assets/materials 空筛选（`r9-assets-empty.png`、`r9-materials-empty.png`）与滚动态（`r9-assets-scrolled.png` 滚到 asset-0185…0200；`r9-materials-scrolled.png`）。HTML 侧证据边界：截图 + 页面自身 DOM 状态；CJGUI 侧：真实窗口截图 +（此前的）AX/owner 读回，不是像素比对。

同条件抽看差异（不要求逐像素一致）：

| 状态 | HTML（1280） | CJGUI（1280） | 判断 |
|---|---|---|---|
| B 筛选无结果 | 列表区“没有匹配「zzz」的记录”+ 清除筛选按钮；详情空白显示“未选择记录” | 列表区空白（无空态文案/清除按钮）；状态栏“共 200 条·当前显示 0 条·未选择记录”；详情仍显示上一次选中记录的值 | 差异：CJGUI 缺显式空态与清除入口；筛选清空选择后详情显示旧值（截图时点，未确认是否最终帧）→ 记为观察，不修 |
| B 滚动 | 虚拟化列表滚到中部（asset-0100 附近），行完整 | 滚到末尾（asset-0185…0200），两行行正确、无空白/错行 | 两侧都工作，滚动位置不同（不是缺陷） |
| C 空结果 | 筛选无匹配时显示空态文案与清除按钮 | 筛选 zzz 时网格显示“没有匹配的素材”（代码路径），本轮截图为空态图；实际文案已实现 | CJGUI 有空态文案，但无 HTML 的清除按钮 |
| C 滚动 | 卡片网格滚到中部，卡片完整 | 网格滚动后卡片完整、缺图占位仍真实 | 基本一致，CJGUI 缺列数响应式上限 |

HTML 侧未修改需求、数据与交互；其空态是页面自己实现的状态，CJGUI 未照搬。

第三轮工程收尾：未再改源码（本轮只扩展 HTML 采集脚本、生成结构与项目数据、证据与文档）；应用测试 12/12、框架根 `cjpm build --skip-script` 通过（沿用同轮构建）；`git diff --check` 通过；未 stage/commit/push；未导出 SDK。空间：`work/` ≈32 MiB、宿主 target/.cjgui ≈253 MiB（单目录复用），宿主剩余 216 GiB；自有实例已关闭。

---

# 复核后续修轮（2026-11-08 第四轮，A–F 白名单）

按[复核续修提示词](../ai/2026-11-08-prototype-host-reviewed-continuation-prompt.md)完成 A–F 白名单修复、针对性验证、通用原型宿主消费、HTML 对照与问题回接。**纠正前文表述**：§19.1 的 R1「已修」实为 observedGeneration 观察门（读一次新会话即放行旧请求），本轮才实现真正隔离；§19.5「stepper 键入未取得一致证据」本轮收口；§16/§19.6 引用的 `app-tests-r9-final.log` 在所指路径与全仓均不存在（已按缺失纠正，上轮真实测试日志为 `evidence/build/app-tests-round2.log`/`app-tests-whitelist.log`，本轮为 `evidence/whitelist/app-tests-final.log`）。

## 22.1 A–F 结果与证据

| 项 | 结果 | 实现与验证 |
| --- | --- | --- |
| A·R1 跨会话隔离 | **完成** | 桥改为**会话版本带**：发布版本号加 `sessionVersionBase`，adopt 时新基址=历史发布最大版本+1（`prototype_bridge.cj`）。旧请求的数字永远低于新带，读取新会话前后都拒 `stale_session_generation`；新带请求正常。RED：旧实现下 5 项新测试全败（`evidence/whitelist/red/app-red.log`，含「读后旧候选被接受」原断言场景）；GREEN：app 18/18（全新编译；含界面历史跨会话拒绝测试）。真实链：settings（带 2→3）→UI 切换 assets（第 2 代，带 5）→旧 v2/v3 两次读取后仍拒、v5 新请求接受（`r1-runtime-model-chain.txt`）。负版本（跳过校验）按既有契约透传；结构提交/业务调用一致；界面历史隔离有专项测试：旧会话历史基线在切换+读取后提交仍被拒（prototypeBridgeRejectsCrossSessionHistoryRequestBySessionIdentity）。「新会话构造失败保留旧项目」沿 §11.2 未变，本轮经切换链复验 |
| B·R9 步进器收口 | **完成** | ① 内部输入节点注册进 `nodeIdToKey`/候选表（同 spec key），键入走普通生成式字段路径（此前 `unknown_node`）；② 步进分支只认 `CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE`——实测一次物理按压=FOCUS(31)+ACTIVATE(27) 两事件同携步进 actionName，旧刷新代去重把两事件误合并/误吞独立点击；现与 action 契约一致，每次合法独立点击精确步进；③ 去重按 `inputSessionGeneration+inputSequence` 事件身份（同序列重复投递合并，无身份合成输入不按代合并）。真实窗口：+3 点击=16→19、−2=→17、键入 30→draft=30→Apply→applied=30（模型读回）、99 越界校验、纠正 45、Cancel 回 30。「44 次点击只前进一步」为旧刷新代去重在 AX 连发（同代无刷新推进）下的行为，已在 issue 09 追加说明 |
| C·R7 隐藏可见标签 | **完成** | `cjguiComposableBoundFormField` 新增 `editorLabelVisible`（默认 true 保持回退兼容）；生成绑定分支显式传递；步进器可见标签随 labelVisible。真实窗口签名（labelVisible=false）：AX **description=签名**（可访问名称），行内无重复标签（外部标签列 300pt）；步进器行 AX 名=提醒间隔（分钟）。注意 AX `title` 属性仍是包推导 semanticId（native accessibilityTitle=node.label 通道），AX 名称以 description 为准——未改 native title 语义 |
| D·R6 诊断归属 | **完成** | `syncProjection` 候选尝试边界清空 `lastCandidateLayoutDiagnosticValue`。真实探针对比：`clip-r6-3.log`（旧：internal_error 后仍打印旧裁剪链）→ `clip-r6-3-fixed.log`（新：internal_error 后无诊断行；随后 clip 失败输出自己的新链）。容量上限、回滚 token、只读语义未动。issue 10 的 internal_error 本身未修（见 22.6） |
| E·issue 08 720 窄窗 | **完成** | 归因修正（此前「应改 stack」被指导否定）：`prototype-narrow-body` 在 horizontal 父容器中缺交叉轴 `alignY: STRETCH`；补齐后保持纵向排列。720 实测：region-scroll 700x663，数量/启用/备注/帮助全部可见；显示列表→列表 700x220、点选 asset-0003 详情随动；隐藏列表、恢复 1280（侧栏 280+970x703）。截图 `e08-assets-720-fixed/selected.png`。反馈已追加修正归因事件 |
| F·纵向 splitState 拖动 | **完成** | 主树共同路径：`windowToSplitTrackPointY`（同一次量化）；BEGIN 抓取偏移按声明轴；`applySplitStatePointerDrag` 按轴选 X/Y；捕获记忆/匹配按主轴轨道原点+交叉轴视觉（交叉范围纵向比 width）；UPDATE/END 双坐标。纯逻辑 Y 映射测试过；真实窗口 `--split-demo`（宿主新增最小消费者）：HID 拖动 +66 精确（120→186）、上夹紧 40、下夹紧 665、拖回 196（`f-split-demo-dragged.png`）。键盘 up/down 沿既有实现。**小说工作台回接未验证**（其 deps/cjgui 只读未动；回接条件已写入反馈） |

**A–F 之外的必要改动**：`composable_ui_press_lease_test.cj` 移除与 `composable_ui_collection_view_test.cj` 重复的 foreign 声明（预先存在、自 1443c43 起使整个框架测试包编译失败；最小解阻塞，无行为变化，反馈 39d4382e）；宿主新增 `--split-demo` 模式与 axtool 验证工具（`work/prototype-host-20261108/tools/`）。

## 22.2 验证与身份

| 检查 | 结果 |
| --- | --- |
| app 测试 | **18/18**（全新编译；R1×5 含历史隔离、R9×2、R7×1 新增）：`evidence/whitelist/app-tests-final.log`。注意：中途一次 17/17 读数来自陈旧测试二进制（未含最新两测试），发现后已删缓存强制重编取得本数 |
| RED 证据 | 旧实现下 5 项新测试全败（含 RED 条件测试通过）：`evidence/whitelist/red/app-red.log` |
| 框架根 `cjpm build --skip-script` | exit 0（114 条既有 warning，0 error） |
| testing-link runner 纯逻辑/R7 测试 | 5/5 过（含新纵向 Y 映射）：`evidence/whitelist/framework-green-logic/` |
| 窗口级单测 | **预先存在的环境阻塞**：既有横向 split 窗口测试同样在 `window.refresh()` 失败（metal/窗口创建成功但首场景不接受），非本轮代码回归（`evidence/whitelist/preexisting-window-test-env/` 双向证据）；本轮 7 项窗口级测试保留待环境修复；F/R6 行为由真实窗口替代验证。反馈 8a9a83d1 |
| 运行消费 | 同一候选二进制 `6cd5290f6f8436f15ab3a44b32b7fabe04aa47e59c627c66eb64522458dc5752` |
| `git diff --check` | 通过；受保护路径（runtime_state.cj/cjpm.toml/cjpm.lock）未触碰；未 stage/commit/push |

最短复现：`cd runtime/cjgui/examples/prototype_host_app && ./run.sh --build-only`，`target/release/CJGUIPrototypeHost.app/Contents/MacOS/CJGUIPrototypeHost --project projects/{settings,assets,materials}`（分隔样例加 `--split-demo`）；模型侧用启动日志 `CJGUI_PROTOTYPE_HOST_DESCRIPTOR` + `shared_operation_core` 客户端。

## 22.3 原型汇合（同一候选，真实输入）

- **settings**：两列行标签无重复（R7）；步进器键入 30→draft→Apply→applied=30、±连续精确步进、99 校验/纠正/Cancel（R9）；AX description=签名；保存界面+保存会话→重启 `session=restored`。
- **assets**：200 条→筛选「报告」收敛 25 条→点选 083（HID）→模型读回同 owner→数量 582→99（HID 键入）→Apply→applied=99；720 窄窗详情可见/列表开关/恢复宽窗（E）。
- **materials**：12 卡、4→2 列切换、选卡、详情读回；缺图占位沿上轮证据（本轮 AX 深度未再取，如实注明）。
- **分隔布局**：`--split-demo` 纵向 splitState 上下分区真实拖动（F）。
- **公开模型链**（本轮真实执行）：发现能力→读版本带→提交候选（接受+读回）→UI 切换项目→旧请求永久拒绝+新请求完成（R1 链）；草稿重排/运行时新增字段未重做（沿 §11.1/§18 证据，本轮改动不影响该路径——重载声明不换会话、版本带不变）。

## 22.4 HTML 对照

复用上轮三页矩阵；本轮唯一结构性变化是 **720 详情裁剪已修**（`e08-assets-720-fixed.png` vs HTML b-720：两侧详情字段均可见，差异消除）。其余结论沿 §21：标签重复已修（R7 两列行）、步进/错误态两侧一致可用；剩余差异仍是 CJGUI 无空态文案/清除按钮、无字符计数/开关/底部操作栏、筛选后详情旧值（记录未修）。未逐像素比对（如实保留）。

## 22.5 反馈回接

`evidence/feedback/`：上轮 10 issue/22 事件 → **14 issue/33 事件**（list status complete）。追加：R9 键入收口（df00aec8）、R7 绑定字段+AX 推导（ee2d46d7）、R6 诊断归属（02f37193）、08 归因修正+修复（7ee79583）、issue 10 时序关联（9fd477c8，根因仍未知）、R5 复核保留（0643156b）、HIG 配方状态（20e491c4）。新建：R1 版本带（0858e5dc）、纵向 split 修复+小说工作台 links（a87b4b19）、窗口测试环境阻塞（8a9a83d1）、重复 foreign 声明（39d4382e）。`source_fix` 如实（fixed/pending/not_needed 各归其位）；`sdk_inclusion` 均为 pending:尚未导出；checkout 消费通过未写成 SDK 包含。

## 22.6 只调查未修 / 未证

- **issue 10 probe2 internal_error**：新时序证据（裁剪整场回滚后紧跟 prepareSceneRefresh=false；诊断隔离修复后两者不再串扰）；根因未知，候选假设（回滚未完全复位场景事务 / 启动文档交错）与下一步最小对比实验已写入反馈（9fd477c8）。
- **窗口级框架单测环境阻塞**（8a9a83d1）：既有测试同败证明非本轮回归；归属 runner/测试环境（Sol 线记录过同族问题），本轮不修。
- **probe 2 之后正常入口**：`--clip-probe 2` 本轮未重跑（沿 §13.2 证据）；R6 修复不触碰该路径行为。
- **空态文案/清除入口/筛选后旧详情/窗口标题**：无新证据，沿 §14/§21 记录。
- **小说工作台**：deps 副本只读未动；纵向 split 回接条件已写（a87b4b19 links）；duplicate node id/scrollarea 跟随/退出 provider 无新证据，沿第四节原记录。
- **R5 全框架测试矩阵**：未跑（沿 §19.5 边界；本轮运行时消费未见回归）。
- **VoiceOver/SDK 导出/正式发布**：未做，同前。
- **会话中断事件（环境，非项目缺陷）**：16:53 WindowServer 主线程挂死（watchdog）致图形会话重启，体感如重启；崩溃工件中本任务全部进程为 0 次出现（均已按身份提前关闭），挂死栈在系统 SkyLight 内部、事发时 displayState=OFF。已按事实记录，不构成本轮缺陷证据。

## 22.7 空间账（本轮）

- 新增：`work/prototype-host-20261108` 32→**48MiB**（本轮 +16MiB：RED/GREEN 日志、对照截图、探针对比、r1 链记录）；tools/axtool（114KB）；`target` 213M、`.cjgui` 35M（单一构建目录复用）。
- 释放：`/tmp/prototype-red-fwgraph`（runner 图）、`/tmp/prototype-host-red-backup`（RED 备份）收尾时删除；自有宿主实例全部按身份关闭（事发前）。
- 宿主剩余：**234GiB** 可用（≥20GiB）；无 GiB 级夹具，单文件日志 <1MiB。

<a id="23-指导复核与下一轮接续"></a>
## 23 指导复核与下一轮接续

本节纠正 §22 的“A–F 全部完成”结论，保留原交付报告、测试和截图作为历史原件。指导复核了当前源码、结构化反馈、原始日志和最终截图，并核对候选/构建输入身份；**未修改实现、未构建、未重跑窗口**。以下源码推导不冒充动态 RED。

### 23.1 复核结论

- **A/R1 未收口。** 版本带已经改善显式旧版本的拒绝，但桥的原子快照等载荷仍透传局部版本，正常公开编辑客户端从快照生成 plan 后，与桥入站版本空间不一致；负版本业务请求仍无独立会话归属检查。最终 `app-tests-final.log` 确有全新编译 18/18，但历史测试读取 A/B payload 后未使用其身份，仅提交固定 `surface=0/epoch=0/digest="digest"` 并断言拒绝，不能证明真实历史操作跨会话隔离。R1 原反馈附带的是 17/17 旧日志，本次追加了最终日志，不覆盖旧副本。
- **B/R9 部分完成。** 输入子节点映射与 ACTIVATE/输入序列处理的有效成果保留。生成式绑定分支仍提前返回 stepper，未消费字段 validationError、已解析主题/交互样式，并写死 readOnly=false；步进动作前缀分支绕过当前 accepted 节点身份检查。完整字段语义和旧节点/禁用/只读约束仍待收口。
- **C/R7 未完成最终可见隐藏。** [最终资产截图](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/assets-final-edited.png) 仍显示 `component-10-1`、`component-22-1` 及重复“数量”。窗口将语义名称回填至 native 的可见 label 参数，不能用 AX description 正确代替可见结果；隐藏但未显式填写 label 的字段名称回退也须补齐。
- **D/R6、E/720 保留已取得成果。** 诊断清理、窄窗交叉轴伸展已有实现及对应证据。**F 的轴处理与真实拖动成果保留**，自己的 accepted 重绘、独立绑定/祖先变化取消、非零原点/平移及横向受影响边界仍需按实际证据补验；小说工作台回接未验。
- **窗口单测失败的原因未定。** 既有横向与新增窗口测试都在首场景失败的事实成立，但“旧测试也失败”本身不能证明环境归因或排除本轮回归；撤回 §22 对此的确定性表述，保留 needs_evidence，不据此新增 runner/native 修复授权。

候选 bundle SHA256 仍为 `6cd5290f6f8436f15ab3a44b32b7fabe04aa47e59c627c66eb64522458dc5752`。本次复查 build-provenance：482 个 source_files 中仅 `prototype_bridge_test.cj`、`prototype_stepper_test.cj` 两个后来修改的测试文件不匹配；464 个 prepared_sources、2 个 native_libraries 匹配。没有把历史 verified 当成当前运行实例证明，SDK/运行实例身份边界保持原记录。

### 23.2 已完成的反馈追加

按现有 `cjgui-app-dev` 的 `feedback.py append` 追加 **4 个 event**，未新建 issue，当前为 **14 issue / 37 event**，list 完整性检查通过。每条完整观察含身份、预期/实际、复现/后续验证、归因边界及 source_fix/sdk_inclusion/consumer_verification；用 supersedes 指明被纠正的旧事件，旧事件与证据均保留。

| issue | 指导复核 event | 本次动作 |
| --- | --- | --- |
| `0858e5dc1ed5466a897dbbe3601c4062` | `83f3c777edca4af1b5eb2584141d9b76` | 追加版本消费、无身份写入、历史测试缺口及最终 18/18 日志；修正完成结论 |
| `df00aec86b6e43c98a1da865b5721438` | `8f00f1ae03d14f859673984741242dfb` | 保留键入/点击成果，追加字段呈现与事件身份遗漏 |
| `ee2d46d74301434cb27be11e0d288489` | `a13aa4024fa4432ca3eaaebb8ebf81b6` | 保全最终截图与源码通道证据，纠正“可见标签已隐藏” |
| `8a9a83d150d44e4fa0b2437b1fa6c094` | `4590250f0f8347f9a07903e690c679ed` | 原因改为未确定；保留窗口失败事实，不宣称非回归已证 |

原件、完整观察和脚本回执见 [review-followup](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup)，正式维护入口仍为本阶段与 ACTIVE，不新增第二套台账。技能实现/规则未改，未对外发送消息或 issue。

### 23.3 下一轮接续与本次边界

已编写 [完整的新实施提示词](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/2026-11-08-prototype-host-abc-closure-prompt.md)，供用户下发执行：A/B/C 白名单收口、真实历史与公开客户端验证、F 补证，再回到同一二进制的三原型连续消费及 HTML 对照。D/E 复用；issue 10、R5 额外测量、滚动末尾跟随、空态等仍只调查/记录。此次仅完成反馈与文档交接，没有启动这些代码修复，也没有自动升级小说工作台或导出 SDK。

本次新增保留约 **1.1MiB**（提示词、复核观察、带 SHA 源码片段、必要日志/截图保全副本及未改源码核对清单）；实际释放 **0**，没有新增构建树或验收实例，既有产物保持。宿主可用约 **233.8GiB**。本次在用新增输出为上述提示词、review-followup 和原反馈库中的 4 个新事件及证据；保留用于下一轮复现与验收。

## 24 A/B/C 收口轮（2026-11-08 第五轮，进行中）

本轮按 `docs/ai/2026-11-08-prototype-host-abc-closure-prompt.md` 执行，白名单 A/R1、B/R9、C/R7 + F 补证。**本轮未完成整包**，以下为已取得的实际进展与阻塞点，不冒充完成。

- **A/R1（已实现、未完成验证）**：`prototype_bridge.cj` 新增结构作用域的版本带消费：`snapshotPayload` 中 `ACCEPTED_STRUCTURE_VERSION` 与 `SNAPSHOT_STRUCTURE STRUCTURE <n>` 行改写为 banded 值、`acceptedStructurePayload` 首行 `STRUCTURE <n>` 改为 banded、候选回执 `ACCEPTED_VERSION` 改为 banded；负版本（无身份）外部业务请求在会话切换后返回新具名原因 `session_identity_required`（切换前保持既有负版本语义）。owner 版本、游标、历史版本未改写（作用域不同）。应用构建通过。**未完成**：真实客户端 B 快照→plan→submit→续改链未跑；历史身份用例未跑；单测未更新。
- **B/R9（未推进）**：绑定分支仍为 `readOnly:false`、步进事件仍只按 actionName 前缀写入；本轮未实施 accepted 节点身份核对、validation/theme/readOnly 事实接线。
- **C/R7（部分实现、可见结果仍未通过）**：窗口两处 native staging 已改为“可见 label = node.label，不再回退 semanticLabel/semanticId”，生成绑定/非绑定/stepper 分支为空 label 时补字段声明 fallback；框架与应用重新编译后**截图仍显示 `component-10-1`/`component-29-1` 等内部 ID 与可见值同排**（settings 签名框 `component-29-1 按ID恢复验证`，assets 详情三字段同类）。结论：可见文字不是来自已修改的 Cangjie staging label 回退，仍有未定位通道（候选：bound form field 的 editorLabel/导入场景 node.label 实际值；需用运行期打印或 native 侧 stage 输入核对）。未改 native 语义，未用 sentinel；`labelVisible`/U+200B 的旧结论不撤销。
- **F（未推进）**：未补本轮要求的轴/捕获边界验证。
- 原型连续消费、HTML 对照、反馈回接本轮均未进行；`work/` 未新增大型产物（仅本轮诊断截图 c1/c2/c3）。
- 下一步（未授权，仅计划）：定位 C 的可见 ID 写入通道（Cangjie 场景 node.label 实际值 vs bound 字段导入路径），再做 A 的真实客户端链与历史用例，最后 B/R9 收口与原型/HTML/反馈。

## 25 A/B/C 收口轮进展（2026-11-08 第六轮，进行中）

按 `docs/ai/2026-11-08-prototype-host-abc-closure-prompt.md` 执行；**未完成整包**，以下为实际取得。

- **C/R7 已修复并验证（完成）**：根因不是 staging 局部变量，而是 **prepared candidate packet 的 label 通道**（async freeze 路径）在 `node.label` 为空时回填 `semanticId` 并作为 native 可见 label。修复：该通道 `label = node.label`（不回退）；窗口两处 staging 同步改为 `visibleLabel = node.label`；生成绑定/非绑定/stepper 的隐藏 label 语义名 fallback 字段声明。验证：settings 截图签名框仅值、无 `component-N`；assets 截图三个字段仅值、无内部 ID；AX name=标题/数量/备注（description/semanticLabel 通道）；U+200B 未使用、native 语义未删。证据 `c5-settings-label.png`、`c6-assets-final.png`。
- **A/R1 版本带消费（实现+单测+真实链，未含历史）**：桥新增结构作用域 banded 消费（snapshot 的 `ACCEPTED_STRUCTURE_VERSION` 与 `SNAPSHOT_STRUCTURE STRUCTURE`、accepted structure 首行 `STRUCTURE`、候选回执 `ACCEPTED_VERSION`），owner/游标/历史不改写；无身份负版本外部业务写在切换后返回 `session_identity_required`。单测 2 项新增（snapshot band + 旧请求拒绝 + 新请求接受；身份门 + B 带版本写入读回）。真实链：settings show base=1 → apply accepted 2 → UI 切 assets → assets show band 4 → 重投旧 base 1 `stale` → B plan base 4 accepted 5 → 续改 base 5 accepted 6（同一 descriptor、公开客户端）。**未完成**：真实可撤销历史的跨会话隔离运行用例；最终运行日志尚未作为独立原件归档。
- **B/R9 身份与校验（部分完成）**：步进事件新增 accepted 身份核对（节点 id 映射回 accepted spec key、kind/field/stepper 属性、字段资源/owner target/enabled/availability；步进按钮 id 注册同一 spec key）；绑定分支传 validationError。真实窗口：键入 1630→draft 且 validation=`需要 1–60 之间的整数`、applied 保 16；清空键入 30→Apply→applied=30。**未完成**：已解析主题/交互样式与 readOnly 事实仍未接到 stepper（`readOnly:false` 仍在），故 B 未收口。
- **F**：本轮未补轴/捕获边界验证。
- **原型连续消费、HTML 对照、skill 清单剩余动作**：未进行（仅完成 R1/R7/R9 三条 append 到指导指定 issue）。反馈库事件数见 list（本轮 +3）。
- 验证：框架根 `cjpm build --skip-script` 通过；应用 20/20 测试通过（全新编译含新增反例）；`git diff --check` 通过；未 stage/commit/push；未导出 SDK；未改 skill。
- 身份：应用候选 `CJGUIPrototypeHost.app`（本轮重新编译，框架强制重建）；源码改动 `prototype_bridge.cj`、`prototype_session.cj`（启用文档历史）、`composable_ui_window.cj`、`composable_ui_generated.cj`、`composable_ui_generated_region.cj`。
- 下一步（未获授权）：B 的 theme/readOnly 接线；A 历史运行用例；F 补证；三原型/HTML 汇合；最终身份/空间与报告。

### 25.1 本轮追加（B/R9 呈现与校验接线）

- stepper 构造改为接收已解析 `editorStyle` 与 `editorInteraction`：输入使用字段解析样式，± 按钮使用同主题高度/交互；`feedbackNodeId` 接线后字段 `validationError` 在 stepper 下可见。真实窗口：清空键入 99 → draft=99、`validation='需要 1–60 之间的整数'`、applied 保持 16（截图 `r9-stepper-validation.png`）；清空键入 30 → Apply → applied=30（上轮记录）。
- 仍未完成：`readOnly` 事实在既有公开契约（descriptor/projection/availability）中**不存在**——stepper 仍传 `readOnly:false`，也未把只读接到控件；要收口需要指导决定是否新增该字段事实（属公开契约变更）。B 因此仍未整体收口。
- 应用 20/20 测试通过；框架根构建通过；未提交。

### 25.2 本轮追加（B 呈现完成度、A 历史调查）

- **B/R9 呈现接线（完成）**：stepper 构造接收已解析 `editorStyle`、`editorInteraction`，输入使用字段解析样式、± 按钮使用同主题高度/交互；`feedbackNodeId` 接线后 `validationError` 在 stepper 下可见。真实窗口：清空键入 99 → draft=99、`validation='需要 1–60 之间的整数'`、applied 保 16（`r9-stepper-validation.png`）；清空键入 30 → Apply → applied=30。`readOnly` 事实在既有公开契约（descriptor/projection/availability）中不存在，仍传 false，未擅自新增契约字段 → **B 的只读项仍未收口，需指导决定契约方案**。
- **A/R1 真实历史隔离（未完成，已定位阻塞）**：宿主已启用文档历史（`ui-history` 返回 enabled=true、surface_identity=1、epoch、accepted_version/accepted_digest）。用公开 `ui-import --apply` 将改过内容的合法 ui-document 连续导入（重新计算 structure_sha256），B 侧 accepted_version 3、history_epoch 5，但 `can_undo=false`、`boundary_reason='ui_document_history_unobserved_change'`：外部导入产生的 accepted 变更未被历史观察路径记录，因此无法构造“A 的真实可撤销事务”。**结论**：历史跨会话用例需先解决“外部导入被历史观察”的接线（或走工作区内部保存路径构造），属未授权范围，交指导决定；跨会话身份拒绝本次未取得运行证据。
- 应用 20/20、框架根构建通过；未提交；未新增其他源码改动。

### 25.3 本轮追加（A 历史路径定位、F 测试环境阻塞、B 只读边界）

- **A/R1 历史路径定位**：历史记录在文档会话 `finish` 中按 `operationPath == pathValue` 走 `observe`，路径变化走 `reset`。此前用 `/tmp/doc-hist-*.json` 通过 `ui-import --apply` 导入，因路径不等于项目保存路径而触发 `reset`（`ui_document_history_unobserved_change`），故无 undo。结论：可撤销历史必须由**同一保存路径**的保存操作产生（如窗口保存界面）；跨会话历史请求的运行用例据此应改用“同一路径保存两次”构造，而不需改框架历史机制。该用例本轮未重做（时间/上下文所限，且未修改历史实现）。
- **F 补证（未完成，环境阻塞）**：尝试运行框架 `cjpm test --filter '*translation*'`，链接阶段失败（`ld64.lld ... too many errors`），与已知 issue `8a9a83d1…`（窗口级单测首场景失败/环境归因未证）一致；按提示词 §7 不据此新增 runner/native 修复授权，也不把旧测试名失败当作非回归证据。F 的新边界（不同位置按下不跳变、非零原点/平移映射、跨自身重绘拖动、绑定/祖先变化取消捕获）本轮未取得新运行证据；既有 `--split-demo` 成果保留。
- **B/R9 只读边界**：`readOnly` 在 descriptor/projection/availability 中均无字段事实；stepper 仍传 `false`。若要收口需指导决定是否新增公开契约字段（或在既有 availability 语义内明确“不可编辑”表达），本轮只记录不擅自扩契约。
- 工程状态：框架根构建通过；应用 20/20；未提交；本轮未新增源码改动（除上轮已记录的 stepper 样式/校验接线）。

### 25.4 本轮追加（A 历史可撤销性调查）

按“同一保存路径保存两次”构造可撤销历史：settings 上做两次结构修改，每次点击窗口“保存界面”（写回 `projects/settings/ui/main.json` 同一路径）；`ui-history` 结果为 `accepted_version=3`、`history_epoch=5`、`accepted_digest` 为最新文档、**`can_undo=false`、`undo_depth=0`、`undo_reason=ui_document_nothing_to_undo`**。说明宿主的“保存界面”直存路径没有把 accepted 文档变更记成可撤销事务（或历史在读到未观察变更时被 reset），因此仍无法构造“A 的真实可撤销事务”来验证跨会话历史身份。

结论：A/R1 的历史隔离运行用例仍被阻塞，阻塞点在**文档会话历史与宿主保存路径的观察接线**（不是桥的版本带）。这是白名单 A 范围内的接线问题，但需要指导确认“保存界面应产生历史事务”还是“历史只覆盖 import/workspace 操作”；本轮只记录，未改历史机制或宿主保存流程。证据：命令与输出见本轮会话；history probe 脚本在 `evidence/model-chain/history_probe.py`。

本轮未新增源码改动；未提交。

### 25.5 A 历史构造尝试记录（两路均未产生 undo 事务）

- 同路径“保存界面”两次：accepted v3、epoch 5、can_undo=false。
- 先“保存界面”一次（设置 pathValue）后，用公开 `ui-import --apply` 对**项目同路径**连续导入两份真正不同的合法文档（重算 structure_sha256）：accepted v5、epoch 6、can_undo=false、undo_depth=0。
- 结论：在当前宿主接线下，公开保存/导入路径都没有把文档变更记成可撤销事务；`ui-history` 始终 `ui_document_nothing_to_undo`。A 的历史隔离运行用例仍被“历史事务产生路径”阻塞，不是版本带/桥本身。本轮只记录，未改历史机制、未改宿主保存流程；项目 ui/main.json 已恢复原样。

## 26 收口轮非阻塞汇合（2026-11-08 第七/八轮）

在 A 历史与 B 只读仍待指导决定的情况下，完成剩余非阻塞验证与交付：

- **三原型同候选连续消费**（同一 `CJGUIPrototypeHost` 二进制，`target/release/CJGUIPrototypeHost.app`）：
  - settings：READY fields=5、启动载入 UI 文档 `applied:accepted`；截图 `final-settings-1280.png`（两列行、segmented 外观、select 强调色、stepper、操作行；无内部 ID、无重复标签）。
  - assets：READY fields=4 records=200、文档 `applied:submitted`（结算同路径）；截图 `final-assets-1280.png`。
  - materials：READY fields=3 records=12、文档 `applied:accepted`；截图 `final-materials-1280.png`。
  - 720 窄窗 assets：`final-assets-720.png` 中标题/数量/启用/备注/帮助全部可见；模型经同一 descriptor 读回 title/quantity（`归档会议纪要 001`/`8`）。E/720 修复在此候选上复验通过。
- **C/R7 最终效果**：settings/assets 截图均无 `component-N` 内部 ID、无控件内重复标签；AX name=字段声明名（签名/提醒间隔（分钟）/标题/数量/备注）。证据 `c5-settings-label.png`、`c6-assets-final.png`、`final-*-1280.png`。
- **HTML 对照（复用既有独立三页与截图，不新增降负载）**：HTML 1280/960/720、空态、滚动态截图与自检在 `work/prototype-host-20261108/html/`；CJGUI 与 HTML 剩余差异为：开关 vs checkbox、字符计数无、底部操作栏 vs 内容内操作行、强调色色板 vs select、整数普通字段无 stepper（仅 settings 提醒间隔使用）、HTML 列表行内边距/字体密度略不同于 CJGUI；两列表单、segmented 外观、主/次行列表、空态文案、缺图占位两侧结构已接近。未做逐像素比对。
- **验证/身份**：候选 sha256 `a863ba95…39a36a1`；框架根 `cjpm build --skip-script` 通过；应用 20/20；`git diff --check` 通过；未 stage/commit/push；未导出 SDK；未改 skill。
- **仍阻塞（需指导决定）**：A 历史事务产生路径（同路径保存/导入均未产生 undo 事务，`ui_document_nothing_to_undo`）；B 只读事实缺公开契约字段；F 窗口单测环境问题 `8a9a83d1…`（未新增 runner/native 修复）。
- **空间**：`work/` 55 MiB、宿主 target 213 MiB + `.cjgui` 40 MiB（单目录复用）；宿主剩余 **234 GiB**（≥20 GiB）；无自有实例残留。

## 27 A/R1 历史隔离运行验证（2026-11-08 第八轮）

在真实宿主上验证跨会话历史身份（同一 descriptor、公开 typed client / history probe）：

1. **A 的真实可撤销历史**：settings 上做一次结构修改（accepted v2、历史 `can_undo=true`、`undo_depth=1`），记录 A 真实基线：`surface=1, epoch=5, accepted_version=2, accepted_digest=e77584c5…`，并保存 `hist-A-baseline.json`。
2. **切 B 并读取**：UI 切 assets（同一进程），`show` 读 B（banded STRUCTURE_VERSION=4），B 上做一次结构修改（accepted v2、`surface=6, epoch=11`、`can_undo=true`），保存 B 基线。
3. **A 请求回放到 B**：用 A 的真实基线调用 `UI_DOC_UNDO` → 应用返回 **`ui_document_surface_mismatch`**（applied=false、version 不变）；随后读 B 历史：`accepted_version=2`、digest 与 B 编辑后一致、B 文档未变。**A 旧请求被身份拒绝、B 文档不变** 已证。
4. **B 自己的合法 undo**：用 B 真实基线提交 `UI_DOC_UNDO` → `candidate_accepted=true, applied=true`（候选已接受），但 session 进入 `ui_document_operation_pending`，未在观测窗口内完成场景结算；因此 **B 的 undo→redo 成功闭环本轮未完整取证**（未改机制、未等待更多轮）。
5. 记录：`evidence/whitelist/hist-A-baseline.json`、`hist-B-baseline.json`（会话实际文件名见本轮命令），探针 `evidence/model-chain/history_probe.py`（本轮修正 close 兼容与 submit 结果字段）。

结论：A 的“旧请求拒绝 + B 不变”已验；B 自身的 undo/redo 结算需下一轮延长等待或通过窗口刷新触发后再验，不作为通过。

## 28 A 历史结算阻塞证据与决定请求（2026-11-08 第九轮）

- 真实宿主上，B 自己合法 `UI_DOC_UNDO` 提交后返回 `candidate_accepted=true`（版本 before/after 记录、候选已接受），但随后 **session 永久停在 `ui_document_operation_pending`**：等待 2s/3s/4s、窗口交互（诊断按钮）、窗口 resize、以及“保存界面”（其入口先 settleDocument）后，`ui-history` 仍是 `accepted_version=3, can_undo=false, can_redo=false, undo_reason=ui_document_operation_pending`，redo 被同一 pending 拒绝。
- 说明：**宿主当前没有结算 UI 文档历史候选**（结构编辑候选能正常结算，历史候选不能），因此“B 真实基线合法 undo/redo 成功”无法闭环；A 的“旧请求被身份拒绝、B 文档不变”已在前轮验证。
- 该问题属 A 白名单内的历史验收阻塞，但修复会触及文档会话/宿主帧刷新结算接线；按提示词“若既有实现正确，只修错误的测试和验收结论，不为补证重造历史机制”，本轮先记录并请求指导决定，不猜改。
- 请求决定：(1) 是否授权修复“宿主结算 UI 文档历史候选”的接线；(2) 若历史结算不在本轮范围，A 验收口径是否改为“身份拒绝 + B 不变”即可。

<a id="29-三处阻塞的指导结论"></a>

## 29 三处阻塞的指导结论（2026-11-08，待接续实施）

指导已核对源码、结构化反馈与现有原件，并查看最终 settings/assets 截图。当前候选完整 SHA256 为 `a863ba958c149e6e93c4a412112efa30058b1a97ce0201f2eb263e06539a36a1`；构建记录的 482 个 source_files、464 个 prepared_sources、2 个 native_libraries 全部匹配。所查画面不再出现内部 ID/重复标签，保留 C/R7 成果。本次没有重跑构建、测试或窗口，不把静态定位写成动态修复完成。

**A：修普通回合的结算接线，不降低合法 undo/redo 验收。** 主循环每轮已调用 `controller.settleDocument()`，但该函数在 `documentSettlePending=false` 时提前返回；只有启动 `beginStartup(...).submitted` 设置该标志。后续公开历史候选因此无法进入既有 `workspace.finish()` → `finishReload()` 结算及历史观察路径。允许在原 A 范围内补齐普通回合接线，保留事务/票据/终态规则、避免空闲刷新，不重造历史协议、不手工清 pending。取得 B 合法 undo/redo 的终态、版本/digest/画面证据，并保留旧 A 请求拒绝且 B 不变。§25 的临时历史归因与§27“继续等待”建议不再作为实施方向；保存/导入如何记入历史沿现有契约。

**B：批准最小公开 readOnly 事实与 owner 接线。** 项目字段已有 `readonly`，但 `prototypeFormBinding` 未传递，共享 `CjguiSharedFormFieldDescriptor` 缺少对应事实。优先增加默认 false 的参数/字段，保留构造兼容；由既有项目声明派生，经共享描述、生成消费和 owner 写入检查到达普通输入与 stepper。`availability` 是当前写入许可，可由只读派生具名拒绝，但不能把所有不可用等同只读。核对公开事实、正常只读交互与 owner 拒绝，保留可写字段原能力；不扩成新权限系统。

**F：允许既有隔离测试入口与正常窗口消费者补证。** 新报告是链接阶段失败，旧 `8a9a83d1…` 是已链接窗口的首场景失败，§25.3“与已知 issue 一致”的归因不成立；目前任务证据中未找到此次完整链接日志。先保全命令及首错，使用已有 `native/scripts/verify_cjpm_mac_testing_link.py` 的 testing archive 和准确过滤器，有界调查，不猜改未知 runner/native。独立的 `--split-demo`/最小公开消费者继续覆盖 grab offset、非零原点/平移、跨自身重绘拖动、独立绑定/祖先变化取消捕获及横向回归。运行探针不冒充单测通过。

唯一执行入口：[通用原型宿主完整实施提示词](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/2026-11-08-prototype-host-blocker-decisions.md)。按用户要求已在同一路径合并原阶段全部目标、剩余工作与 A/B/F 新决定；它独立包含原型推进、公开模型、HTML 对照、反馈和集中交付，不再要求保留或拼接旧提示词，也不另建“增补目标”。白名单边界不扩张，其他新问题只调查记录，skill 优化不在本轮，小说工作台依赖不升级。本次仅校正交付文档，未将执行目标状态或代码改成完成。

反馈原为 14 issue / 41 event；本次在原 issue 各追加一条决策观察，现为 **14 issue / 44 event**：A `e3c3bd0170b841178261a45414e9d336`、B `f4684a2710c44a8e8bd38a88f73f0b1a`、F `6c240a5eb1cb4b0bba5d7802b7caccca`。源码片段、观察输入及回执在 [review-followup](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup)。R9 执行事件中的“theme 未接”须随后追加已完成证据；A 执行事件当前只附 A 基线，后续须补 B 基线和真实 pending/终态原件，不能用聊天叙述替代。原事件保留，决策事件不冒充修复事件。

此前三条决策回接时的检查：反馈 list 完整且无错误，三条新 event 均读回；当时 17 个本地链接/锚点有效，ACTIVE 段 491 字符，`git diff --check` 通过；当次复核前后 1533 个框架/native/共享核心/宿主源码/仓库 skill 文件哈希无变化、无新增代码路径。当次新增保留文档及证据约 0.4MiB，无新增构建树、无删除释放，宿主可用 235GiB；原件继续保留于上述 review-followup、反馈库和阶段文档。

完整提示词校正：已在原路径写入唯一总目标和全部执行要求，移除对旧提示词的依赖；旧 A/B/C 提示词标为历史归档。完整文档 30 个本地链接/锚点检查通过，ACTIVE 当前段 486 字符；本次只整理这几份文档，没有新增反馈事件、实现改动、构建或窗口操作。

## 29 决策后收口轮（2026-11-08 第十轮，A/B/F）

按 `docs/ai/2026-11-08-prototype-host-blocker-decisions.md` 执行。三处决定已落实；其他新发现只记录。

### 29.1 A：普通回合结算接线（RED→GREEN）
- 修复：`prototype_controller.cj settleDocument()` 不再仅启动载入时结算；每空闲回合消费既有 `workspace.finish()`。无提交时直接返回、不 refresh/不覆盖状态；`pending_ticket` 保留标记下回合再消费；终态才更新状态并 refresh；项目切换/旧会话晚到由当前 session/workspace 承担，未手工清 pending、未改 mode、未重写 finishReload。
- RED 原件：`evidence/whitelist/a-settle/red-*`（修前 B 基线 undo 后永久 `ui_document_operation_pending`）。
- GREEN：真机 undo → `accepted_version=3, can_redo=true`，文档内文回退，窗口画面回退；redo → `accepted_version=4, can_undo=true`，内文重放（`green-*`）。跨会话：A 真实基线回放 B → `ui_document_surface_mismatch`，B 版本/digest/文档不变；B 自己 undo/redo 成功（`cross-*`）。空闲 CPU 1.6–1.8%，无忙循环。
- 回归：settings 结构编辑→保存→重启会话仍正常；assets 列表/筛选/详情链未受影响（final2 截图）。

### 29.2 B：只读公开事实与消费（完成）
- 公共契约：`CjguiSharedFormFieldDescriptor` 新增默认 false `readOnly`；`CjguiGeneratedUiFieldSpec` 新增 `readOnly`，从 binding 派生；宿主 `prototypeFormBinding` 直接用既有 `PrototypeFieldDeclaration.readonly`；`fieldsPayload` 每题 FIELD 行发布 `READONLY 0/1`（旧客户端忽略未知键，向后兼容）。
- 呈现/防护：BoundFormField、普通 text/integer/boolean、stepper 接线 readOnly；region 对字段编辑与步进先拒；owner `editTextFromHuman`/`editBooleanFromHuman` 返回 `field_read_only`。AI 生成结构不可改写该事实（候选带 `readOnly` 属性被拒，见测试）。
- 验证：应用测试 **23/23**（新增只读事实传播、owner 拒绝、生成消费键入/± 拒绝、可写对照、结构覆盖拒绝）。真机 readonly-demo（同一最终二进制）：只读文本键入后 draft 仍 `A-001`；只读 stepper + 后 quota 仍 `10`；可写 title 键入草稿变化；可写 stepper `8→9`；Apply 后只读 applied 不变、可写 applied 更新；AX 名=字段标签、值可见。证据 `evidence/whitelist/b-readonly/*`（`readonly-demo-after-apply.png`、`after-*.txt`、`ax-textfields.txt`）。说明：本宿主没有对外“字段写”RPC，外部写入面即生成事件/结构候选；前者被 region+owner 拒绝，后者无法改声明。

### 29.3 F：链接与首帧归因、真实窗口补证（部分）
- 用既有 `verify_cjpm_mac_testing_link.py`（独立 testing archive、受控输出/证据目录）执行：`*split*` 2 passed；`*fPositionVerticalSplit*` 6 项全部失败于 **`window.start()`/`window.refresh()==true` 首个断言**，构建/链接成功（首错 `f-link2/cjpm-test-0.log`）。此前普通根 target `ld64.lld ... too many errors` 是链接阶段失败，二者已分开记录；仍未定位根因，未改 runner/native。
- 真实窗口 `--split-demo` 补证（`f-runtime/probes.log`）：分隔条上按下不移动即释放不跳变；带内偏移 grab 拖 +30 精确；1200ms 多步连续拖动 +60 精确且 accepted 逐回合推进；窗口移到非零原点后 +40 精确。拖动中 resize 祖先几何的“取消捕获”未取得稳定可判定证据，记为未验（未改 F 代码）。
- F 轴映射/捕获本轮未新增修复；既有 `--split-demo` 成果保留。

### 29.4 汇合、反馈、身份、空间
- 三原型同最终二进制：settings/assets/materials 1280 启动与文档结算正常（`final2/*`）；assets 720 详情可见并读回 title/quantity（`final2/assets-720.png`）；另加最小只读运行消费者 readonly-demo（同二进制，未改动三例需求/HTML 对照）。
- HTML 对照：复用既有独立页与截图；本轮修改只影响只读状态（新增 readonly-demo 画面）与历史前后（A 截图），未改三例 HTML；剩余差异沿 §26。
- 反馈：A/B/R9/F 共追加 4 事件（A `371e25b175a7440f8fb83de9bd2d3d7b`，B `655d5548be2d45209efb6d95b82144e3`，R9 `f1a052712a9540368ac4e4b7c2c149b1`，F `a17ea164c1ac47e5aa81fc0d50cc3941`）；`list` 实测 **14 issue / 48 event**，errors 空。R9 旧“theme 未接”已按实现/消费结果更正（supersedes 8f00f1ae）。
- 身份：最终候选 sha256 见本轮报告/实际二进制；应用 23/23；框架根 `cjpm build --skip-script` 通过；`git diff --check` 通过。未 stage/commit/push；未导出 SDK；未改 skill；未调用外部顾问；自有实例已关闭。
- 空间：`work/prototype-host-20261108` 68 MiB（含 RED/GREEN、f-link2 证据、readonly demo 与截图）；宿主 target 213 MiB + `.cjgui` 40 MiB 复用；宿主剩余 236 GiB；无 GiB 级夹具。
- 剩余：F 窗口测试首帧 `window.start/refresh=false` 根因未定（需另立调查/授权）；拖动中祖先 resize 取消捕获未证；无其他新增修复授权。

## 30 决策后补充轮（F 横向/祖先变化、最终汇合）

### 30.1 F：横向轴与祖先变化补证
- 复用 `--split-demo`，新增仅服务边界的演示状态：`--split-demo-axis horizontal`（同一公开 `scopedSplitView`、无私有拖动入口；状态文本增加 `axis=` 与 accepted/track）。宿主 app 演示代码，不改框架契约。
- 横向真机（`evidence/whitelist/f-runtime/probes-horizontal.log`）：firstSize=120 上点击不动即释放不变；拖 +40→160；1200ms 连续拖 +60→220；窗口移到 (420,250) 后 +30→250；均精确且 accepted 同步。
- 祖先变化取消捕获：垂直 demo 拖动中 resize（166→240 后冻结）/窗口移动（0.4s 122→移动后 180 后冻结）。两次都出现一次跳变后才停止，不能判定“取消前未应用旧映射”，与窗口测试期望（取消不跳变）存在疑点；受 HID 注入时序与采样干扰，记为**可疑未证**，本轮未改 F/捕获代码。
- 测试入口仍为 `f-link2`：*split* 2 passed；6 个 fPositionVerticalSplit* 首错 `window.start()/refresh()==false` 未变（与 lld 链接失败分开）。

### 30.2 汇合与身份
- 最终二进制 `1313c936aa6edc86d904d2ce5a827c923c22bbac41108d61f4d091ac73302e97` 上重新消费 settings/assets/materials + readonly-demo：均 READY、字段/记录数正确、文档结算正常；截图 `evidence/whitelist/final3/*`（120 秒内四次启动）。
- 应用 **23/23** 测试通过（含只读事实/消费/结构覆盖拒绝）；框架根构建此前通过；`git diff --check` 通过；未 stage/commit/push；未导出 SDK；未改 skill。
- 反馈：追加 F 横向/取消事件 `6b64cf4aea1b48edbb7537dbd3d5d76b`；`list` 实测 **14 issue / 49 event**，errors 空。
- 空间：`work/prototype-host-20261108` 约 70 MiB；宿主 target 213 MiB + `.cjgui` 40 MiB 复用；宿主剩余 **236 GiB**；无自有实例残留。
- 未验/未修：F 首帧测试失败根因、祖先变化取消的精确语义（需定向窗口测试或 HID 时序控制）；issue 10、R5 额外测量、滚动末尾跟随等只调查记录；三例 HTML 沿用既有证据（本轮只新增 readonly-demo 画面与横向 demo，非三例需求）。

<a id="31-指导复核与首版候选范围"></a>

## 31 指导复核与首版候选范围（2026-11-08，继续同一目标）

本次指导核对当前源码、构建输入、原始 JSON/log/截图和反馈事件，未重建、重跑测试或操作新窗口。宿主 SHA256 `1313c936aa6edc86d904d2ce5a827c923c22bbac41108d61f4d091ac73302e97` 与报告一致，482 个 source_files、464 个 prepared_sources、2 个 native_libraries 全匹配。原件与逐文件哈希见 [maturity-review-source](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/maturity-review-source.txt)及[身份/SDK核对](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/maturity-review-identity.json)。

### 31.1 本轮交付的复核结论

**A 的门控修复及现有消费原件认可，保留实现。** 普通空闲回合已调用 workspace.finish；green 原件为 undo 后 v3/can_redo=true、redo 后 v4/digest 恢复。跨会话旧请求 surface_mismatch，B 基线/回放后的版本与 digest 相同、show 字节相同；B 自身 undo/redo 有原件。指导不将这些旧捕获写成自己对最终二进制新跑的窗口验收。报告中的 A event `371e25…` 实际属于 R9 主题观察，并与 `f1a052…` 重复，A 原 issue 未收到该修复；已追加正确 A 回接，原 R9 事件保留不删除。

**B 只能认部分完成，四处只读接线遗漏成立。**

- [generatedIntegerStepperNode](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_generated.cj:5149) 接收 readOnly，却在 NumericStepperBinding 中仍传 false；实际输入只读标志和 ± 可交互状态因此未接通。owner 拒绝保住数据，不等于 UI 只读完成。
- [BoundFormField](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui.cj:6227) 仅使用独立 readOnly 默认 false，未继承 descriptor.readOnly，手写入口仍须重复接线。
- [fieldAvailabilityForSnapshot](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_generated_form_binding.cj:261) 对已知字段无条件 allowed；readonly quota 的真实日志仍是 available=True，和 owner 的 field_read_only 矛盾。capabilities 的 callable 也只看 writer 是否存在；不得通过全局改变 isWritable 破坏只读字段的组合注册。
- [公开客户端](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core/cjgui_generated_client.py:2095) 的 GeneratedFieldValue/parse_generated_fields 未返回新增 READONLY 事实。旧读者可忽略新增键与新客户端能消费该事实是两件事。

这些明确纳入原 B 白名单修复；保留 descriptor/spec/owner、主题/校验/输入的有效成果。现有测试只证明值未被写坏，缺最终节点 isReadOnly、按钮 enabled、手写继承和客户端事实断言；应补可区分 RED。当前任务证据及宿主 .cjgui 中未定位报告所称23/23原日志，已有 app-tests-final.log 是18/18；不直接否定执行者运行报告，但不得拿旧日志证明新数字。本次修复后的受影响测试保存真实输入与日志即可，不为补数字重跑全框架。

**F 部分边界通过，取消时序未证，保留演示入口。** f-link2 确为构建/链接成功、6项首个 start/refresh 断言失败，根因仍未定位。正常窗口原件支持横纵基本拖动等范围；166→240 的采样跨并发输入与 resize，未提供 accepted 时序和无手势 resize 对照，不能确认旧映射在取消之后仍被应用。已有测试明确布局祖先独立变化接受后取消旧捕获，无需另定“是否取消”规则；OS 窗口原点移动不等同布局祖先 translate，合法夹紧也需单独区分。继续原 F 范围的可判定验证，未知 runner/native 不猜改。readonly-demo 与 horizontal demo 均是有用的正常消费者，不删除。

### 31.2 用户所列成熟度缺口：核实与本包取舍

| 项 | 核实后的事实 | 本包决定 |
| --- | --- | --- |
| 公共 API / 最新 SDK | 当前公开面明确 experimental/additive_only；冻结包 `3efa79ad…` 内 skill=v4、共享 descriptor 无新 readOnly，维护源 skill=v6。实验等级是现状，不是靠改标签就能修的 bug | 明确首版候选公共子集/兼容边界，修复后导出最新本地 SDK；不宣布 stable API/ABI，不对外发布 |
| 真实 VoiceOver | 旧冻结包 MACOS-CANDIDATE 已记 Rules 的真实导航/读出/激活，涉及版本/实例和辅助聚焦边界；最新候选完整连续链仍缺 | 纳入一条固定组件范围的真实 VO 链；实际读出/导航/激活/reveal/选区/重排接续逐项留证，不用 AX 代替 |
| 性能/资源 | 已有 normal window/transport 基线脚本与历史结果，不能说没有测量体系；当前宿主候选缺同负载端到端、CPU/GPU、RSS/峰值与驻留变化证据 | 纳入固定普通负载、先定预算/观测边界的有限测量，关联原 Metal 增长；不直接新增脏矩形/partial present/未知资源重构 |
| 运行时声明演进 | 宿主当前明确拒绝既有字段规则变更/删除；不能由该消费限制推出全框架没有动态业务规则能力，也不能把 UI 节点删除与业务字段迁移混同 | 后置统一迁移机制；本包保留具名拒绝/保旧，不无限扩展 schema 演进 |
| 手写/生成一致性和配方 | B 的只读一致性确有具体缺陷；其他 HTML 视觉差异不都属于框架缺陷，已有控件/布局不应重造 | 修 B，整理本包真实复用的公共用法；开关/字符计数/底栏等不自动新增组件任务 |
| 独立消费 | 三项目同宿主只证明声明复用；仓库已有历史包外 mixed/Rules，缺的是这次新公共面的同包独立消费 | 用新 SDK 在仓库外建一个有自己 owner/入口的正常应用；不能复制 Prototype 私有类。模型消费与独立开发者/真人试用分别标明 |

取舍沿首版方向：优先把已存在能力变成可独立使用的交付。SDK、有限 VO 链与普通负载测量能和本包共用同一候选、正常消费者及原件，纳入同一个目标；动态迁移、全套配方、全平台追平和极端编辑后置。VO/性能若发现新框架缺陷仍只记录并交指导，不因新增验收自动授权修复。未取得这些门时可以交付明确边界的开发候选，不能称整个成熟首版完成。

### 31.3 完整任务与反馈

唯一入口仍为[完整实施提示词](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/2026-11-08-prototype-host-blocker-decisions.md)，已直接合并本次所有要求：B 续修、F 可区分验证、原三个原型和 HTML、新 SDK/包外消费、VO/普通负载、反馈和集中交付。无需旧提示词，不另建增补目标。此前“不导出 SDK”在本包已被明确新增的本地候选导出授权替代；不修改 skill 本身。

在原14 issue/49 event上，指导用既有 feedback.py 追加3条：A `e1c2d872634b45e281bf78612b8389ad`、B `b0fae66e47434702b077838f16b99900`、F `7db404a962a54537beb22592db07a70e`；B纠正同候选 `655d…` 的整体完成结论，保留有效部分。追加后14 issue/52 event，完整性与原件再读回核对。此次指导只更新文档和反馈，没有实施代码、SDK导出或窗口操作。

收尾核对：feedback list 完整、errors 空，三条 event 在正确 issue 下读回；47 个本地链接/锚点有效，ACTIVE 段512字符，`git diff --check` 通过。候选482/464/2输入哈希再次匹配。本次新增保留文档与反馈原件约0.2MiB，无新增构建树、无删除释放；宿主可用236.2GiB。原件留在既有review-followup/反馈库，完整任务仍复用原路径。

## 32 当前候选整包接续（2026-11-08）

继续唯一完整提示词；先修 B 四处接线并保存可区分 RED/GREEN，再补 F accepted 顺序与首帧有界调查，汇合三个原型/真实公开模型/HTML，冻结公共子集并导出同源 SDK，包外独立消费、真实 VO 固定链和普通负载测量，反馈集中回接。A/C/D/E 的未受影响证据沿 §31 复用，新发现只记录。

开工：宿主可用约236GiB，既有 work 69.5MiB、宿主约254MiB。复用原消费者构建目录；预计新 SDK/包外构建/测试峰值 <4GiB，新增保留预算≤10GiB、峰后≥20GiB；测试驱动 finally 退役临时图，必要失败原件保留。证据集中在 `work/prototype-host-20261108/evidence/candidate/`，不另建执行卡或目标。当前源码/身份基线见该目录 `start.json`。

本包已收束到以下集中结果。root负责B/F、实际公开链、桌面/VO、测量与交付；按用户授权复用一名Sol完成公共子集/包外消费者及只读测量和R5汇总，没有新增用户线程或外部顾问。未过门按原要求保留，不把新发现加入修复白名单。

### 32.1 验证计划与普通负载预算（采集前固定）

机器：MacBook Pro Mac17,9，Apple M5 Pro 18核、48GB；macOS26.6/25G72；Cangjie1.1.3。候选身份将在首个测量前以实际二进制/构建provenance写入原件。正常候选仍使用同一宿主二进制，私有项目工作副本保持settings原字段规模、assets200条、materials12卡；窗口1280×820，assets滚动固定顶部→末部→顶部，materials保持12卡且4→2→4列。包外应用两个owner及24条对其的记录投影，名称/整数与同一生成区更新。

一次有限混合宿主测量目标约10分钟：5轮同顺序项目/滚动/输入/公开更新，含最终至少60秒静置与正常关闭；外部消费者另记其实际时长及5轮更新。CPU/RSS/线程每秒采样，句柄每10秒；复用window_perf_baseline.process_sample，原始stdout/stderr各≤64MiB，合计≤512MiB。公共diagnosticSnapshot取有界节点/每秒一次，采GPU完成时间、文本纹理存活/峰值、reusable/effect/in-flight与提交/完成帧；无真实present时间即保留缺项，截图仅证明采样时画面可见。

本包观察目标预先固定：小型普通表单首次交互就绪≤2秒；输入回调内owner处理p95≤16ms；输入/公开提交到accepted可观测边界p95≤100ms（含运输的指标单列）；可见反馈若只有工具/截图上界则目标≤1秒且不能代替16/32ms原门。依据是本包小数据普通交互应在一帧预算内处理owner，接受投影需在100ms普通反馈量级，工具采样仅提供粗上界。正确性零丢输入、owner/版本一致、票据完成；不允许靠重投刷绿。资源观察目标：最后四轮同端点RSS相对首个完整轮末不超32MiB+15%，线程/打开文件不持续单调增长，60秒静置平均CPU≤5%（ps单核口径），effect in-flight在静置/关闭结算；首次缓存与峰值单列。上述是本次有限负载的预定观察预算，不改变原严格16/32ms未过门，也不证明长期稳定。预计新增原件<100MiB、总峰值<4GiB；关闭按准确PID/端点核对，不影响用户实例。

### 32.2 包外/VoiceOver固定链（启用前）

包外独立应用选择 `InspectionCandidate` 两owner8201/8202、serial只读文本/cycles只读stepper、name/quantity可写、24行记录投影。生成文档固定A。真实VO链固定为：启动并启用VO → 读A编号/名称/额定周期与只读语义 → VO导航编辑name → Apply与Cancel各一次并owner读回 → 导航到起始屏外第24记录并reveal → name文本选区与owner同值 → 公开模型重排edit-name后VO继续同字段 → 保存界面并正常退出。遇失败仍保留第24记录等原环节，标明部分；不改成AX链通过。真实字幕或音频必须保留，AX/工具键盘/Unicode合成/辅助聚焦分别标记。

启用前通过NSWorkspace.isVoiceOverEnabled核为false。agent-desktop能识别该bundle进程却漏列窗口；PID72329的独立AX helper和CGWindow1695 onscreen=1均证窗口存在，CUA按bundle路径能取得完整AX树，故采用该工具进行本段UI。未改应用/SDK/native，未将工具匹配问题误归App显示。字幕面板启用后的初态会另外记录，只恢复本轮变更。


### 32.3 实际交付与未过门

本包解决的是B只读事实跨手写/生成/owner/客户端不一致，以及F窗口测试使用错误owner/回合推进方式导致的首错；保留A结算、C标签、D诊断、E窄窗成果。可用交付包括同一最终二进制的settings/assets200/materials12、正常公开模型与工具输入链、兼容字段新增/草稿保存重开、最新同源SDK和有自己owner的包外应用。

**不称整体成熟首版完成。** 以下门仍失败或未验：真实VO固定链仅取得窗口/场景分组读出；materials静置持续提交、CPU和第4轮RSS超预算；深色只读演示中的部分enabled按钮不可辨；保存insert-plan往返被拒。首个真实交互就绪、输入到新accepted与physical present定时也未取得。新发现已结构化反馈，没有自动改未知native、布局/渲染/调度机制，没有新增迁移/控件库或修改skill。

| 项 | 本次结果与原件 | 范围/保留边界 |
| --- | --- | --- |
| B四处遗漏 | bound stepper传真实readOnly；手写helper用descriptor.readOnly OR收紧参数；标准availability具名拒绝且callable一致；typed read_only返回true/false/None并拒非法token | `isWritable()`仍表示writer路由存在，未全局改false；readonly输入可查看/选择，±/选择写入禁用，owner防线保留 |
| B可区分验证 | [RED](../../work/prototype-host-20261108/evidence/candidate/b-red/result.json)3项窗口构造失败、[Python RED](../../work/prototype-host-20261108/evidence/candidate/client-red.log)2项；最终[26/26](../../work/prototype-host-20261108/evidence/candidate/b-verified/cjpm-test-0.log)、[52/52](../../work/prototype-host-20261108/evidence/candidate/client-green.log) | 初次GREEN25/26揭露readonly输入被整体禁用，原件保留；最小修正公共stepper的查看语义后通过。不是只断言owner没写坏 |
| A | 保留正常空闲workspace.finish结算；最终host真实旧A历史拒绝且B show不变，B合法续改/undo/redo终态；包外同SDK历史/重开见32.6 | 未伪造surface/epoch/digest；新会话构造失败注入仍未验，旧不受影响反例按原身份复用 |
| C/D | 当前字段/新增字段画面、AX名称和值能对应；C标签通道修复保留。D候选尝试边界清理诊断的旧原件保留 | 没有为新轮重复全裁剪矩阵；没有扩裁剪上限或重写提交；AX不代替VO |
| E | [720详情](../../work/prototype-host-20261108/evidence/candidate/integration/assets-720.png)、[第二条owner3001](../../work/prototype-host-20261108/evidence/candidate/integration/assets-720-selected-fields.json)、[恢复1280](../../work/prototype-host-20261108/evidence/candidate/integration/assets-restore-1280.png) | 200条未缩减；列表开关、meta行选择、筛选25条/恢复200正常；960/空态旧证据没有伪称新跑 |
| F | [8项窗口测试](../../work/prototype-host-20261108/evidence/candidate/f-owner-turns/result.json)通过；[有序正常窗口结果](../../work/prototype-host-20261108/evidence/candidate/F-RESULT.md)与[事件顺序](../../work/prototype-host-20261108/evidence/candidate/f-ordered-events.json) | 未改生产映射/捕获或runner/native；fixture纠正AppKit owner并按既有owner-turn budget等待accepted，保留原首错与仅加owner仍失败的原件 |
| R5 | [有界必要性/影响](../../work/prototype-host-20261108/evidence/candidate/r5-scope-evidence.md)：本冻结候选保留VERTICAL分支 | 横排父→stepper竖根→内部水平row的源级反事实支持其关联；无二进制A/B，撤回“所有R9必要性/全面无回归已证”的强结论，普通stretch路径不泛化 |

F正常窗口先以非零容器/窗口原点建立真实捕获，再暂停、请求祖先translate/换绑、确认accepted，才发旧手势剩余移动/释放；旧捕获没有再写，重新捕获可继续，自身拖动accepted重绘保持连续，横纵与无手势几何对照分开。F运行二进制是加入测量前的`a39843c7…`，该部分生产机制未变；最终候选只再加有限测量与参数白名单，未把旧二进制叫成最终SHA。旧“120→180精确+30”文案修正为150→180，原probes未改。

### 32.4 当前源码、构建、测试和运行身份

最终[身份核对](../../work/prototype-host-20261108/evidence/candidate/final-identities.json)再次逐文件核对：宿主482 source_files、464 prepared_sources、2 native_libraries全匹配；包外458/440/2全匹配；双方testing=false。编译器原始可执行文件与调整rpath/签名后的bundle文件分别记录，不能混用SHA。

| 产物 | 完整SHA256 |
| --- | --- |
| 实际运行宿主bundle executable | `2464c814feeb58aea1fde60273c123f87c114fb3f55a452cc71ee723a9b38b82` |
| 宿主compiler原始executable | `a25ece0512726e927e61a263e6cd1377cc64a76e3cd2fd2b6faeb8da64b753a8` |
| 宿主build-provenance | `a68eeb99f35165869fcb2dc68a38e92ab880fcc9a8d4c11021fa122c36796d3d` |
| 包外实际运行bundle executable | `1235e4eae1de837f6e97686b06b5765057d5ddd3d85a5775d207914ffe402dd1` |
| 包外compiler原始executable | `a52583849b2e4a37a858d48d03dc4df929a87d7e6a4d13dec29bb05303c92e81` |
| 宿主生产renderer archive | `d47e147bd7032b23934393352e0d401d1a6a19050496f8605bc83d50cdbf3d17` |
| 包外生产renderer archive | `55719e576d60a1c018169a1eedf3da7b263ba830ce2a63ecf237018ef4e8e334` |

两处native是各自正常runner从明确源构建的生产archive，不要求不同建项路径的archive字节相同；launcher及全部实际路径/哈希见身份JSON和各自provenance。testing archive仅用于单测，不进入SDK或正式运行链接。

测试证据：B26/26、Python52/52、导出器文档/skill原样快照[6/6](../../work/prototype-host-20261108/evidence/candidate/export-skill-green.log)、F8/8、包外领域1/1。每套输入与测试native身份分别保留在result/source-inputs；B之后的测量观测代码不拿旧测试冒充最终bundle已全量重测，最终正常窗口补受影响链。框架根[cjpm build --skip-script](../../work/prototype-host-20261108/evidence/candidate/root-build.log)成功，没有无变化重跑全框架。

旧23/23原日志本轮仍未定位；已有app-tests-final.log实为18/18，按旧范围保留，**本次真实26/26另有原始日志与输入锁**。原失败、慢样本、编译首错和busy拒绝均未删。最终`git diff --check`通过。本包新增/变更本地链接有效；全文件扫描另检出ACTIVE中不属E写集的W历史产物链接缺失1处，未改其他执行线。CodeGraph对本次CJ/工作目录覆盖不足（明确未匹配文件），CodeLattice路由未给有效影响结论，改用直接源码/同源测试/正常消费补证，不把0 affected当无风险。`runtime_state.cj`与框架`cjpm.toml`没有本次diff，生产native源码未改；测试生成指纹不算生产native修复。

### 32.5 唯一SDK候选与公共子集

交付[SDK ZIP](../../work/prototype-host-20261108/CJGUI-macOS-Candidate.zip)和[导出目录](../../work/prototype-host-20261108/CJGUI-macOS-Candidate)，包外实际解压同一ZIP。冻结后未原位改SDK/ZIP。

| 身份 | 值 |
| --- | --- |
| ZIP大小 / SHA256 | 6,449,910字节 / `49c5997d063c6138c798e1432eb0d5909aabb1107f07ef4b72ed520fd3a293cd` |
| source-manifest SHA256 | `fbebc13c9da1b7afc8037c01599de4d10cf4f7e1bbb22a1dee70d6db00e0b6f0` |
| source-lock SHA256 | `08268a6fb8e15451cb64b5dc07739617751d787ddfb57e57c7c3123eb4cd721f` |
| delivery closure | 613输入 / `5e0c159bc0e61e1ffa1e48ff57365f3c9ea6105c0aa83e0f5232cac4e9dc23fa` |
| 文件核对 | 导出SDK与包外SDK各640/640 matched；无testing archive、target/cache或作者绝对路径配置依赖 |
| skill | 维护源v6全部16文件原样字节快照，未修改skill实现/规则 |

[公共候选子集](../../runtime/cjgui/preview/MACOS_CANDIDATE_SUBSET.md)与[字段配方](../../runtime/cjgui/FIELD_CONTROLS.md#共同字段只读声明本候选experimental)说明macOS/仓颉1.1.3、host/window、已支持布局/主题、字段与命令/owner身份、手写/生成/混合绑定、受限组合、文档工作区和公开客户端；保留experimental/additive_only、surface1.0的真实等级，未承诺stable API/ABI。

B是增量事实：descriptor默认false保持旧构造兼容；helper只可收紧；新producer显式READONLY0/1；新typed客户端缺token保留None、非法具名拒绝。writer路由存在与当前写许可分别表达。标准只读输入保留查看/选区，不因available=false一概禁用查看。

导出器本次仅增加子集说明和skill原样携带例外：首次预检发现通用Markdown重定位改变skill链接括号，拒绝包原件保留，未消费/发布；修正导出器后重导唯一最终包。未改维护skill，未重建分发系统。旧冻结包及其v4/旧readOnly状态保留原版本，不能一并标已修。

### 32.6 同一宿主与包外正常连续消费

宿主以同一最终SHA在一个正常进程中切settings/assets/materials，项目来自本包私有副本，负载不变；补充冷启动与readonly/E720复核另有正常生命周期。

- settings：公开能力/原子show→正常preview/saved plan→apply终态与exact readback→第二次续改；工具键入的签名实际为`团队周报候选未应用草稿`（不是最初预期的纯替换文本），模型读同一owner2000，applied仍`团队周报`。有草稿重排、保存UI/会话后[真实冷启动恢复](../../work/prototype-host-20261108/evidence/candidate/integration/cold-reopen-fields.json)，未隐式Apply。项目切换是新建领域，不等于冷启动恢复，最初混淆这一点的驱动失败保留。
- 兼容新增字段：正常重载按钮使candidateMemo进入capabilities/fields且owner2000，原始plan公开插入正常节点v1→v2 exact；工具键入`New memo by input`，applied仍`新增字段初值`，[输入读回](../../work/prototype-host-20261108/evidence/candidate/integration/added-field-after-input.json)。保存insert-plan后apply却报invalid_plan，保旧原件见32.9；没有手改版本或专用成功客户端。删字段/既有规则变更继续具名拒绝，不实现迁移。
- 跨项目A/B：读取B后，旧A真实结构plan仍拒绝；[旧历史请求](../../work/prototype-host-20261108/evidence/candidate/integration/old-a-history-in-b.json)使用真实surface/epoch/digest，surface_mismatch且B show前后字节不变。B用新快照连续改动，合法undo/redo取得候选终态，pending结清。
- assets：200条顶部/末部滚动、meta行选择199、数量Apply读回owner3198；补720点选第二条公开读回owner3001，筛选25条后恢复200与1280，主操作可见。非当前记录草稿保护等未受影响组合复用旧身份证据。
- materials：12卡、2→4列、选02/owner3001、缺图07占位均由项目/公共能力消费，[实际画面](../../work/prototype-host-20261108/evidence/candidate/integration/materials-1280.png)。普通负载下3次scene_transaction_busy拒绝未重投；持续提交风险单列，不能写成所有公开更新均通过。

包外根为[/Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer](</Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer>)，公开创建器mixed-form建项，自己的manifest/入口/owner/布局，不import任何Prototype私有类、不指作者checkout。`inspectionFields()`唯一四字段及上限60，`inspectionFormLayout()`唯一gap9；两个owner8201/8202、24行只是它们的记录投影。生成文档固定A，B走精确GET_CONTEXT/公开业务dispatch，不冒称B是typed生成区。

[正常消费原件](../../work/prototype-host-20261108/evidence/candidate/external-runtime/normal-observation.json)：手写/生成serial与cycles键入不变、readonly ±禁用；name正常工具键入，公开reorder前后草稿相等、applied未变；生成Apply/Cancel后手写与生成同值；readonly写拒绝、stale_draft拒绝、99草稿Apply拒绝/Cancel恢复、旧结构plan stale。五轮A/B数量更新均有APPLIED/真实读回，五个生成标题修改ACCEPTED/exact。

包外真正UI history基线v7→undo8 ACCEPTED/can_redo→redo9 ACCEPTED，digest恢复`d3dff915…`。UI保存后正常关闭0、descriptor清理；带相同UI文件路径重开恢复布局/标题，业务按该应用声明重新初始化默认值，旧端点plan endpoint_replaced，新快照续改v1→v2 exact并保存、再关闭0。UI保存和历史不冒充业务持久化/回滚。

实际接入成本/首错/target门、生产源码592行+测试29行+客户端128行与最短使用步骤见[包外README](</Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer/App/README.md>)及[构建RESULT](</Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer/evidence/RESULT.md>)。这是模型在开发者知情条件下的真实公开消费，加明确标记的工具输入/AX与脚本回放；未取得真人或独立开发者试用，不主动对外征集。导出、包外编译、正常运行、独立应用消费与真人反馈分开判定。

### 32.7 HTML对照与可见结果

[HTML实际补采与差异](2026-11-08-prototype-host-html-comparison.md#10-最新候选的受影响对照与使用成本)保留旧1280/960/720、空/筛选/滚动态原件，只补本轮受影响状态。原页面、资源与数据需求未改；新的匹配逻辑内容高度788、DPR/浏览器版本、过渡帧保留与settled重采均有清单。

当前字段标签/AX/输入能对应、720详情可见；HTML switch/色点/字符计数/固定底栏与CJGUI checkbox/select/水平±/宿主工具栏仍有设计/配方差异。materials同12卡4列选02，HTML浮层、CJGUI固定详情区，缺图07均明确。readonly-demo深色的enabled按钮不可辨是新的实际失败观察，不能归为纯审美差异。换项目后窗口装饰旧标题、筛选后旧详情策略也仅记录，未据此误判owner写错。

连续修改不需要每次编译/重启，但公开请求用时只代表该操作：9个宿主成功apply内部p95=53.118ms、完整CLI p95=164.730ms；3次拒绝另列。没有以单次耗时宣称比HTML开发更快。

### 32.8 真实VoiceOver固定链：部分，未通过

在最终SDK包外App固定serial/cycles/name、record24等环节后才启用VO；原状态VO=false、字幕面板=false。真实System Settings开VO、实际VO字幕CGWindow1758、VO命令与原件在[voiceover](../../work/prototype-host-20261108/evidence/candidate/voiceover)。实际读出了独立应用窗口和`CJGUI composable scene`分组。

| 固定环节 | 实际结果 |
| --- | --- |
| 启动、启用真实VO、取得实际字幕 | 取得；不是只有服务启动或AX查询 |
| 字段名/值/只读状态实际读出 | 未取得对应证据；AX存在/只读标记不能替代 |
| VO编辑name并Apply/Cancel/owner读回 | 未完成VO链；后续普通工具输入链通过，单独保留 |
| 初始屏外record24导航/reveal | 未完成VO；普通滚动/AX选择24确实对应owner8202，不能改名VO reveal |
| 文本选区与owner、公开reorder后VO接续 | 未取得VO证据；辅助AX聚焦与真正VO游标分开记录 |
| VO保存与正常退出 | 早期VO取证到1200秒上限被自有采集器SIGTERM，exit-15，不算正常关闭；后续非VO正常链另验exit0 |

工具前台/WindowSharingSessionButton/Quickstart影响与应用AX导航边界尚未分离。全物理修饰键转换的HID helper使真实VO识别了命令/项目选择器，但不足以证明字段链；没有猜改native。后来发现CLI应显式选择主窗口，66×20的CUA共享辅助窗口会误导旧firstWindow helper，因此那批axtool tree不作字段证据，使用CUA实际树/精确窗口agent-desktop与画面。该新线索也未冒充完整VO链补验。

恢复[VO/字幕状态](../../work/prototype-host-20261108/evidence/candidate/voiceover/state-restored.json)为false/false，welcome勾选和AppleScript控制设置未变，System Settings回原General；最终NSWorkspace再次读false，VO/Utility/Quickstart及本任务App无残留进程。没有改安全/锁屏设置。完整链仍是后续需要解决的门，不把旧Rules或普通AX通过合成当前通过。

### 32.9 普通负载、资源和新问题回接

预定预算保持32.1不后改；完整[原数/方法/结果](../../work/prototype-host-20261108/evidence/candidate/performance/MEASUREMENT.md)与[统计JSON](../../work/prototype-host-20261108/evidence/candidate/performance/measurement-summary.json)。固定业务负载共5轮，未缩减200/12；首轮手工编排、后四轮脚本，初始列数切换/轮间驻留与调查等待有差异，不宣称逐步完全同序或等时A/B。输入链诊断4096条后自身truncated，独立后续进程/成本采样完整，不宣称全程输入链无缺口。

| 指标 | 宿主PID52736 | 包外正常PID99748 |
| --- | --- | --- |
| 实际时长/进程样本 | 956.956s / 937 | 611.940s / 599，含长设置/空闲和约8秒五轮更新 |
| 最终静置 | 142.271s，CPU均89.641%（单核口径），约119.971场景/秒仍提交/完成，**失败** | 66.344s，CPU均0.028788%，accepted147/frame205/completed205固定，所采范围内 |
| RSS轮末/峰值 | 209.20/256.17/262.77/279.50/257.31MiB，预定上限272.584，第4轮超6.916；峰315.828MiB | 五轮151.86→154.03MiB，峰187.609；最终静置146.05→146.89MiB |
| 线程/FD端点 | 124→131后稳定，FD11；线程峰166 | 五轮117，静置回110，FD11；线程峰124 |
| owner回调 | 10个applied回调p95=0.035ms；仅此样本满足16ms | 未有App owner回调定时，不用客户端时间倒推 |
| 公开UI更新 | 12次有计时apply：9接受内部p9553.118ms，完整CLI p95164.730ms；3材料busy拒绝 | 5次接受/exact，内部p9531.593ms，完整CLI p95100.191ms，100ms容差未后改；另20次业务set/Apply真实完成 |
| GPU/纹理 | 最近完成帧快照p955455µs；静置text_live4.594MiB固定，峰5.549，candidate高水位9.457；effect快照0 | 快照p952987µs；静置text_live/reusable5.428MiB固定，candidate高水位9.649；effect快照0 |
| 关闭 | 正常exit0，端点清理 | 正常exit0、endpoint_cleared；保存重开实例另有exit0 |

GPU数据是1Hz“最近完成帧”采样，不是所有帧的p95或physical present。宿主末快照submitted46117/completed46116尚差1帧，effect in-flight=0不能证明全部GPU在途为0；failed=-1是未知。纹理静置稳定、RSS有限回落也不能证明长期稳定或直接判泄漏。启动到READY宿主146.220ms/包外214.787ms只是初始化边界；首交互/首实际显示未定时。即时读取当前accepted与新输入没有因果ticket/scene绑定，不能拿0.026ms读数判输入到accepted100ms通过。原严格16/32ms门不改判。

feedback最终[list](../../work/prototype-host-20261108/evidence/candidate/feedback-final-list.json)为**17 issue/65 event，status complete、errors空**；9个本次相关issue逐个show读回。complete只表示库读取完整，不表示问题全解决。A从正确0858…回接，未再拿371e25…当A事件。source_fix/sdk_inclusion/consumer_verification在每条完整观察分别写入。

| 问题 | issue / 本次集中event | 进展范围 |
| --- | --- | --- |
| B只读 | `df00aec86b6e43c98a1da865b5721438` / `4d15cd870b94408ca5d4e1077d4cde63` | source fixed / 本SDKincluded / host与包外正常消费verified；其他旧ZIP不改判 |
| A结算 | `0858e5dc1ed5466a897dbbe3601c4062` / `ff75e6ee66c44a9d991899cb7280ab06` | 旧源码修复保留 / included / 正常历史与重开已验 |
| F | `8a9a83d150d44e4fa0b2437b1fa6c094` / `2cd15e3f9f344ef4be3454a6e362ea48` | fixture修正，生产捕获未改；SDK含同源，包外巡检App未验split |
| E720 | `7ee79583a07f4e6591bfc23eba48a0e9` / `f5c4f4afffd54031bca7621e34fb282e` | 保留既有修复，最终host定域回归通过 |
| R5建议 | `0643156b635e41bfade6d5b2874bca22` / `0974168dddde4903987036630338ccff` | 保留分支、缩窄结论；supersedes旧强结论3b4c6e52…，非新引擎修改 |
| 深色可辨识 | `20e491c49ad045cab72d4c7ba8cedca6` / `53a87b4a2e054d5cad4d91759e510f77` | 新观察，仅记录；主题/配方/渲染归属待分离，未修 |
| VO固定链 | `e855e4908dc44be1bf33ae6283fde687` / `98f2b2b28a2c4102a92ff95f6e7d7049` | 本SDK实际读出部分；整链未过，无native修复 |
| materials静置成本 | `62eff39434e841619307c9b30cf835cc` / `5678be7aa6164677b046fada2d94e3b0` | 新发现/未修；正常包外不同负载没有重现不等于修复；关联旧Metal原件但不武断同因 |
| saved insert-plan | `a967f979813d48038e3fac47f0586175` / `6e16d35115bb4b628a96ed81dd55ffdb` | preview保存后apply invalid_plan，原始plan正常路径成功；仅记录，不静默篡改保存计划 |

暂缓项保持原边界：issue10 participant_prepare/裁剪回滚未定因；重复foreign旧删除只按原编译范围；小说工作台末尾跟随/duplicate-node/退出provider不改外部应用；运行时删字段/改规则/迁移、完整控件与全平台同版未实施。没有把反馈库当自动修复清单。

### 32.10 资源收尾与空间账

最终自有宿主/包外实例正常退出，早期VO超时实例仍保留forced/exit-15原件。CUA关闭后getAXState曾自动重开无参数实例PID13180，已单独关闭，未合入测量。正常两次包外退出与宿主补验均exit0，准确descriptor消失。5个由本包日志宣布的连接最后均不存在，见[端点终审](../../work/prototype-host-20261108/evidence/candidate/endpoint-final-after-cleanup.json)。未关闭用户或不明进程。

收尾发现早期强停实例72329留`connection.cjgui/shared-operation.sock`。核PID已退出、scratch所有权和lsof无打开文件后只删除这两项/空父目录；没有通配清理/tmp。实际采集驱动finally已补同样的有界清理，活进程/符号链接拒绝、保留不相关兄弟文件的[探针](../../work/prototype-host-20261108/evidence/candidate/collector-cleanup-verification.json)通过。改动仅工作目录采集脚本，不动SDK/框架；采样使用的[旧驱动](../../work/prototype-host-20261108/evidence/candidate/collector-as-measured.py)原样保留，不能把新清理逻辑说成旧超时运行当时已有。

[空间原数](../../work/prototype-host-20261108/evidence/candidate/space-final.json)：可归属工作目录比开工增长约78.3MiB，包外消费者保留约183.2MiB。将复用宿主约248.7MiB、根框架target约155.5MiB、testing约10.5MiB也按全量保守计入，已知受控输出合计约745.7MiB，远低于10GiB；不声称这些全是本轮新增。实际删除的临时测试图/被预检拒绝SDK捕获等，删除前实分配累计1.206GiB，另退役包外首轮失败target约45MiB；这不是宿主free净增加量。宿主最终可用约235.5GiB，超过20GiB余量。普通日志逐文件/合计预算未超；没有录屏/HAR新增。

保留理由：唯一SDK目录/ZIP用于分发与复算，包外解压SDK是独立消费者实际依赖；宿主/包外各一个正常构建目录供试用，原始RED/GREEN、超时/拒绝、输入身份和画面供复核。原库其他线存量、用户数据与旧可用交付未清理；没有stage/commit/push、切分支或对外发布。

### 32.11 最短使用与集中结论

1. [打开宿主app](../../runtime/cjgui/examples/prototype_host_app/target/release/CJGUIPrototypeHost.app)，用“项目”输入本机原型目录；或终端直接运行其Contents/MacOS/CJGUIPrototypeHost并传`--project`到[settings](../../runtime/cjgui/examples/prototype_host_app/projects/settings)、[assets](../../runtime/cjgui/examples/prototype_host_app/projects/assets)、[materials](../../runtime/cjgui/examples/prototype_host_app/projects/materials)。当前二进制可复用，不需为换项目重编译。
2. 新SDK消费从[ZIP](../../work/prototype-host-20261108/CJGUI-macOS-Candidate.zip)解压，沿包内[MACOS_DEVELOPER_QUICKSTART](../../work/prototype-host-20261108/CJGUI-macOS-Candidate/framework/cjgui/preview/MACOS_DEVELOPER_QUICKSTART.md)、公开创建器和v6应用技能。工具链为仓颉1.1.3；支持/拒绝语义以公共候选子集为准。
3. [包外巡检app](</Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer/App/target/release/CJGUIInspectionCandidate.app>)可直接本机启动；最短公开generate/read/reorder与UI保存重开命令见[README](</Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer/App/README.md>)。UI文件默认/指定路径保留；业务owner是内存样例，重启恢复默认，这是已声明的应用边界。

本次交付可复用的只读公共契约、可包外接入的SDK、正常原型/独立应用消费与可复核失败证据。尚未通过的VO、普通负载、深色可辨识及saved insert-plan门须在后续明确归因/授权中处理；本包没有借候选交付宣布高性能、长期稳定、完整无障碍或正式成熟版本。

## 33 交付后独立复核（2026-11-09，本轮）

对 §32 的最终候选做只读身份/可运行性复核，不改代码、不重跑完整链：

- **身份**：宿主二进制 sha256 `2464c814feeb58aea1fde60273c123f87c114fb3f55a452cc71ee723a9b38b82`；SDK ZIP sha256 `49c5997d063c6138c798e1432eb0d5909aabb1107f07ef4b72ed520fd3a293cd`（6,449,910 字节，571 个 `framework/cjgui/` 文件，含 v6 skill）；包外 app `.../CJGUI Prototype Candidate Consumer/App/target/release/CJGUIInspectionCandidate.app/Contents/MacOS/CJGUIInspectionCandidate` 存在。
- **宿主 smoke**：`settings` 项目启动输出 `READY project=settings fields=5 … session=restored` 与 `STRUCTURE_ACCEPTED version=1 document=applied:accepted`；按项目目录启动正常。终止后自有 `/private/tmp/tmpDir*` 端点目录（4 个，PID 已退出、无 lsof 打开）已按准确路径清理；未动其他归属不明的旧连接目录。
- **反馈库**：`feedback.py list` 返回 17 issue / 65 event、status complete、errors 空，与 ACTIVE/§32 一致。
- **检查**：`git diff --check` 通过；未 stage/commit/push；宿主剩余 236 GiB；无本任务宿主/包外/VO 采集器进程残留。观察到系统 `VoiceOver Quickstart` 进程（PID 86725，起于 23:44，本轮开始前）不属于本任务启动，未终止。
- **未改变结论**：§32.3/§32.9 的未过门仍成立（完整真实 VO 链、materials 静置成本/RSS、深色只读按钮可辨、saved insert-plan、首个交互/物理 present 定时）。另做了一次外部工具上界探索（`evidence/candidate/perf-supplement/`），因工具延迟与跨快照 ref 失效不可归因，未用于门判定，已写明局限。
- 本轮新增保留约 5.7 MiB（复核记录、探索原件与清理记录），无新增构建树；完整源/构建/native/运行身份沿用 §32 原件。


## 34 指导复核与下一步完整范围（2026-11-09）

指导读取当前源码、实际交付文件、原始测试/测量/图像和skill反馈，并离线复算；本次没有重新构建、启动窗口或修改产品/skill代码。当前候选与报告的宿主、包外应用及ZIP完整SHA一致；当前provenance宿主482/464/2、包外458/440/2全部匹配。B的四处接线已在当前源与SDK，26/26及52/52有原始日志；F owner/owner-turn fixture和原行为断言、有序正常窗口证据支持其报告范围，认可保留，不能再把旧首错当当前阻塞。

[复核原件](../../work/prototype-host-20261108/evidence/whitelist/review-followup/candidate-review-20261109.json)和[复算脚本](../../work/prototype-host-20261108/evidence/whitelist/review-followup/candidate-review-20261109.py)保留身份、原件重算和具体源码片段。不是新真机验收，也不代替执行者的RED/GREEN。

| 问题 | 本次直接核对 | 指导决定 |
| --- | --- | --- |
| materials静置过量工作 | 原始进程样本141条/142.271秒均值CPU89.64113475%；同一静置段accepted/submitted/completed约119.9712723次/秒 | 确认候选缺陷，批准定向归因和既有契约内修复；先分离测量影响与实际失效来源，不预判Metal泄漏或旧问题同因 |
| 深色stepper | 原图确实不可辨；generatedIntegerStepperNode按钮base只给尺寸，命名input角色的themeRoleInteraction正常态依赖base，未补回主题常态色 | 批准正常构造RED后接通base与interaction；不硬编码颜色或改全局级联 |
| 深色底部动作 | readonly-demo三个action未声明style | 应用配方遗漏，用现有动作角色修正，与stepper框架接线分开 |
| 保存insert-plan | 用before-show原始document复算，原始plan与记录preview所有字段完全相同；保存重载后只两个摘要不同。insert属性由label/fixedHeight/growX变为fixedHeight/growX/label，sort_keys与顺序敏感编码冲突 | 批准公开客户端往返一致性修复；保留preview/摘要/endpoint/base保护，说明旧格式/旧文件兼容，禁止自动rebase或忽略摘要 |
| VoiceOver | 真实字段链未完成；commands原件已包含进入分组命令。主窗口/前台/VO游标/工具与AX层级未分离 | 继续固定链定向诊断与消费/工具接线；未认定框架native缺陷，不批准猜改 |
| 延迟/呈现 | 已有READY、回调、内部submit与CLI耗时各有范围；仍缺输入与对应新accepted的因果绑定及真实显示/present定时 | 补最少观测和固定样本，不拿旧快照/工具等待当端到端或physical present |

已将这些结论及授权完整写回[唯一实施提示词](../ai/2026-11-08-prototype-host-blocker-decisions.md)，保留原同一目标、已绿成果、三原型/HTML、SDK/包外消费、VO/性能、结构化反馈及容量收尾。执行者从未完成处接续，不再拼接旧提示词或从头重开A–F。只处理本次三个批准问题及直接回归；新发现仍只记录，实质契约/资源所有权风险集中交指导。最新SDK/包外接入已交付，不再列为“尚未导出”的旧缺口；整体成熟首版仍未完成。

反馈通过现有feedback.py向原issue追加4条，实际list为**17 issue / 69 event，complete、errors空**。追加的是指导观察与范围，不是源码修复完成：

| issue | 指导event |
| --- | --- |
| 62eff39434e841619307c9b30cf835cc | e4594d1241994367bd8dd4b9513861ed |
| 20e491c49ad045cab72d4c7ba8cedca6 | 314a6c4885b448b890435e69b4254e13 |
| a967f979813d48038e3fac47f0586175 | acce6e44a0f94c888c9ef7b02d5a62e6 |
| e855e4908dc44be1bf33ae6283fde687 | 54313cd8eb464d9398c334fac597f09a |

[回执](../../work/prototype-host-20261108/evidence/whitelist/review-followup/candidate-review-feedback-receipts-20261109.json)与[list读回](../../work/prototype-host-20261108/evidence/whitelist/review-followup/candidate-review-feedback-list-20261109.json)保留。source_fix未做、旧SDK仍受影响、消费者仅复核旧原件均明确分开。旧外部应用、平台、ZIP不改判；skill本身未修改。

本次新增复核及4条反馈/证据副本实分配约272KiB（另有小型文档及检查记录），无新构建树、SDK副本或桌面实例；宿主可用约236GiB。原候选和复判证据保留，未清理既有产物（释放0），未stage/commit/push或发布。git diff --check及31个本次本地链接检查通过，当前源码/prepared/native与开头身份仍一致；[检查记录](../../work/prototype-host-20261108/evidence/whitelist/review-followup/candidate-review-checks-20261109.json)。

## 35 2026-11-09 白名单实施轮（进行中）

按 2026-11-09 更新后的唯一提示词处理三个批准问题；A–F 已验行为未重开。

### 35.1 深色生成控件与动作配方（已修并验证）
- 根因：`generatedIntegerStepperNode` 的按钮 base 只有尺寸，input 角色的 normal 为空；readonly-demo 三个 action 未声明 style。
- 修复：生成式 stepper 从 catalog 命名样式 `secondary_action` 取 base+interaction，再只覆写几何；readonly-demo ui-document 补 `primary_action`/`secondary_action`/`quiet_action`。
- 真机（同一二进制 980×720）：深色下 readonly quota 的 ± 与底部动作均可辨、可写 quantity 8→9 精确、只读 quota + 不变、AX/值正常；浅色截图另存。RED 旧图 `integration/readonly-dark.png` 保留。证据：`evidence/candidate/b-theme/{readonly-dark-fixed,readonly-light-fixed}.png`。

### 35.2 保存 insert-plan 往返（已修并验证）
- 根因：`write_json_file` 用 `sort_keys=True`，把 insert 节点 properties 重排；结构编码/摘要保序，重载后摘要不一致。
- 修复：保存 plan/receipt/import 默认保序（显示场景可显式 sort）；新增 `test_saved_plan_order.py`（2 项通过）。
- 真机 CLI：insert 多属性计划 preview→save→load→apply accepted 且版本+1；set_property 保存计划往返仍 accepted；旧排序格式文件仍以 `saved_preview_mismatch` 具名拒绝（不静默重算）。证据：`evidence/candidate/insert-plan/*`。

### 35.3 materials 静置持续提交（定位中，未修）
- 复现：候选 settings→materials，保存 UI 后切走再切回即 120 accepted/s、CPU≈90%，持续不收敛。
- 证据链：gate 诊断显示 declared/last 不变但 `refresh=true`、`resourceCompletionVersion` 每帧+1；Cangjie 采样 11 张卡图均 `ready`，但 accepted 节点 `contentKey` 空、无 texture；`CJGUI_IMAGE_REBIND_TRACE` 每帧 11 张 rebind mismatch；staging 准备态 trace 为 `Loading`。临时尝试 prepare 时保护场景引用（prune YES）无效，已回退。
- 当前保留 env-gated 诊断（`CJGUI_REFRESH_DIAG_TRACE`、`CJGUI_IMAGE_REBIND_TRACE`、CLI image-state）与 app 构建计数，修复前必须移除；未猜改其余 native 机制。根因方向：图像资源完成/重绑与 8 项纹理复用缓存（11 可见图）交互导致的帧循环，待下一轮闭合。

### 35.4 本轮状态
- 构建/测试：框架根 `cjpm build --skip-script` 通过；python 单测新增 2 项通过；应用重建通过（含临时诊断）。
- 反馈：追加 3 条（深色 `e0c1290524544c20bc68d629574c3a5a`、保存计划 `b6fefaf966164c0f9be2324282aa6fc3`、materials 根因 `775ea44b534e47daaf0d76d622cc1865`）；`list` 实测 17 issue / 72 event、errors 空。
- 未做：最终 SDK 导出/包外受影响验证、VO、性能重跑、三原型/HTML 汇合、修复后集中交付；这些依赖 materials 闭合后同候选执行。
- 未 stage/commit/push；未改 skill；无外部发布。

## 36 三白名单问题闭合、同源 SDK 与 fixed-load 验证（2026-11-09）

### 36.1 materials 静置持续提交：根因与修复
- **根因**：图像资源状态机在纹理已不可达时仍返回 `Ready`（8 项纹理复用缓存淘汰，或借用会话纹理消失）。accepted 节点因此 `contentKey` 为空，`CjguiRestoreAcceptedComposableImageDemand` 每帧重新 arm 完成版本；窗口 Refresh 看到 `resourceCompletionVersion` 每帧 +1，触发整场重建 → 120 accepted/s、约 90% 单核 CPU。诊断原件：`evidence/candidate/materials-idle/loop-{rebind2,diag2,detail}.log`。
- **修复**：`CjguiPrepareComposableImageResourceOnMain` 中，Ready 但无 textureCache/resource.texture/DomainBoundTexture 的资源回到 `Unrequested` 并以同一 key 重新请求（不造纹理、不改状态语义、不加 sleep/限帧/重投）。临时 env-gated 诊断（native rebind/prune、window REFRESH_DIAG、app build/image trace）已全部移除；修复保留。
- **验证**：原复现序列（保存 UI 后切走再切回）不再循环（rebind=0，计数冻结，CPU 1.6–1.8%）；`load5-fixed`：5 轮 settings+assets200+materials12 全部公开更新 `accepted`（此前 materials 的 busy 拒绝不再出现），65 秒静置 CPU 均 **1.575%**（≤5% 预算），accepted `2396→2396` 收敛，RSS 轮末 238.4/218.1MiB ≤ 预算 253.3MiB，静置 RSS 196.8→159.2MiB。原件 `evidence/candidate/load5-fixed/measurement-fixed.json`。边界：physical present 与首交互定时仍未测，本结果只证明该有限负载。

### 36.2 新 SDK 候选与包外消费
- 诊断清理后宿主 sha256 `f512df0863a775db33b93491fdccd7b1b8c70b3fbfba5c40221b02c1a8b00f87`；应用 26/26 测试通过；框架根构建通过。
- 新 SDK：`work/prototype-host-20261108/CJGUI-macOS-Candidate.zip`，sha256 `a4ba0acb170f014394042b3e3a4cbd3472f5b4449a47acd0dd93ab54de2f7315`，6,431,964 字节，639 文件，source-lock 613 输入、profile=macos-dev、skill=v6；source/exported content hash 见 `evidence/candidate/sdk-identity-final-20261109.json`。旧 `49c5997d…` 保留为 `CJGUI-macOS-Candidate-49c5997d.zip` 回退基线。
- 包外 InspectionCandidate 换新 SDK 重建：可执行 sha256 `d6d91d06d1c8ed6fba220cbabb70465b3f5b9432150151712afa8a825a4028d6`；只读 serial/cycles 读回 `read_only=true, available=false, blocked_reason=field_read_only`，只读写入 `APPLIED=false REASON=field_read_only`，可写 name set/Apply 成功；保存 insert-plan 在包外 `preview→save→load→apply` accepted、`exact_readback=true`（版本 2）。原件 `evidence/candidate/external-20261109/`（旧 SDK 目录保留为 `CJGUI-macOS-Candidate-49c5997d`）。
- 旧 `integration/readonly-dark.png` 仍是深色 RED；修复后亮/暗截图在 `evidence/candidate/b-theme/`。

### 36.3 反馈与状态
- 反馈追加 3 条完成事件：materials `6acf513ed89846d1a462b75c81b6cb51`、深色 `83e173d04cd44f8c8d46182523e61582`、保存计划 `6011d54ebf6e40ef9a2db28ab0568382`；`list` 实测 **17 issue / 75 event**、errors 空。
- 未 stage/commit/push；未改 skill；未对外发布。临时实例全部关闭，14 个本轮自有 `/private/tmp/tmpDir*` 端点目录按准确路径清理；宿主剩余约 236GiB。
- **仍未完成**：真实 VO 固定链（当前仍只有窗口/分组读出）、首交互/物理 present 定时、修复后三原型与 HTML 受影响汇合、最终集中交付报告；这些在后续轮继续，同候选用同一 SDK/宿主。

## 37 本轮收口汇总与剩余门（2026-11-09）

### 37.1 三项批准修复与验证
- **materials 静置持续提交**：根因/修复见 §36.1；fixed-load 5 轮全 accepted，65s 静置 CPU 均 1.575%（≤5%）、accepted 2396→2396 收敛、RSS 端点过预算。原件 `evidence/candidate/load5-fixed/measurement-fixed.json`。
- **深色生成控件/动作配方**：命名 `secondary_action` base+interaction + readonly-demo 动作 style；亮/暗、只读/可写、±/Apply 真机通过，旧 RED 保留。
- **保存 insert-plan**：公开客户端保序；宿主与包外 InspectionCandidate 的 preview→save→load→apply 均 accepted/exact，旧排序文件仍具名拒绝。

### 37.2 同源候选与受影响消费
- 宿主 `f512df0863a775db33b93491fdccd7b1b8c70b3fbfba5c40221b02c1a8b00f87`（诊断清理后），26/26、框架根构建通过。
- SDK `a4ba0acb170f014394042b3e3a4cbd3472f5b4449a47acd0dd93ab54de2f7315`（639 文件、source-lock 613、v6 skill）；旧 `49c5997d…` 保留回退基线。
- 包外 InspectionCandidate 新 SDK 重建 `d6d91d06…`：只读/可写、Apply、保存 insert-plan 往返、正常端点清理通过；未重跑不受影响的完整 UI 历史/恢复旧链，旧证据按版本保留。
- 三原型最终二进制：settings/assets/materials 1280 与 assets 720 通过（`evidence/candidate/final-prototypes/`）；materials 修复后 4s 静置 CPU 增量约 0.06s、图片正常。
- HTML：页面/需求未改，§11 只补亮暗只读、三原型 1280、720 受影响状态；首交互仅有工具含开销上界（2.54–2.66s，`latency-first/*.json`），physical present 未测。

### 37.3 仍失败/未完成门（整体成熟首版未完成）
- **真实 VoiceOver 固定链仍未通过**：仅有窗口/“CJGUI composable scene”分组真实读出，字段/编辑/Apply/reveal/选区/重排接续未取得；本轮未重开 VO（AX/语义路径未被本轮 image/style/plan 修复改变，旧 `evidence/candidate/voiceover/` 原件保留并保持原版本边界），不把 AX/工具输入/旧包结果当 VO。
- 首交互/首实际显示/present 无物理定时；仅工具上界，不能与 16/32ms 原门或 HTML 比性能。
- HTML 未重跑全尺寸矩阵（复用旧正常/空态/滚动证据），未做逐像素或完整 HIG 认证。
- 旧 SDK/其他平台/小说工作台不改判；review-followup 的 R5 结论维持缩窄版。

### 37.4 收尾
反馈 **17 issue / 75 event**（`6acf513e…`/`83e173d0…`/`6011d54e…` 为三项闭合事件），errors 空；未 stage/commit/push、未改 skill、未对外发布。自有实例与端点关闭；`work` 约 240MiB，宿主剩余约 236GiB。所有身份与原件均在上列路径，候选可交付但须按 §37.3 标注未过门，不称整体成熟首版完成。

<a id="38-指导复核修复验收与剩余工作2026-11-09"></a>
## 38 指导复核：修复验收与剩余工作（2026-11-09）

本节校正§35–37的验收结论，保留历史原件。指导实际核对当前源码、构建provenance、ZIP内容、原始截图/日志和结构化反馈，并用真实历史baseline/多属性insert做保存重载复算、运行4个既有saved-plan保护测试。没有新GUI操作、仓颉构建或产品/skill代码修改。继续使用[同一份完整提示词](../ai/2026-11-08-prototype-host-blocker-decisions.md)，不新增目标或要求拼接旧指令。[审阅原件](../../work/prototype-host-20261108/evidence/whitelist/review-followup/closure-review-20261109.json)保留哈希、原数、源码片段与检查范围。

### 38.1 认可范围与待收尾

| 事项 | 指导结论 |
| --- | --- |
| 深色控件/动作 | 认可本项修复：stepper复用命名base+interaction，readonly-demo补公开动作style；原始新图可辨，相关源码确在新SDK中。保留原真实输入证据，不重开旧矩阵。 |
| 保存计划 | 认可：当前writer保序，经真实旧文档/insert离线保存重载后preview一致；旧排序文件仍不一致；4个既有保护测试通过。宿主/包外accepted与exact原件保留。 |
| materials | 静置改善成立：host.log在85.908752–151.640352秒，accepted/submitted/completed固定2396，持续65.7316秒。但新代码连续调用两次CjguiStartNextComposableImageLoads，第二次未在报告解释；其尾部会promote Busy需求，不能直接认定无效并盲删。仅在原批准问题内有界区分必要性，保留Ready无可达纹理时重请求的修复。 |
| SDK源码锁 | 确认遗漏：a4ba0acb包没有source-lock.json，manifest.source_lock为mode=none、空hash、inputs=0，包外解压根也没有。613实际是delivery_closure.inputs。证据目录中的锁hash正确，不等于已按锁导出/交付。已有导出器支持--source-lock并携带文件；批准修导出调用及核验，不改框架API、不重造打包机制。 |

宿主 `f512df08…`、SDK `a4ba0acb…`、包外 `d6d91d06…` 完整哈希与报告一致；宿主482/464/2、包外458/440/2的source/prepared/native输入均匹配，testing=false，生产renderer源码指纹一致。ZIP内native、generated构造与公开客户端的相关源码字节也匹配。源码已包含修复与源码锁交付完整性须分开，不能相互替代。

### 38.2 性能统计校正

现存summary最后65个进程样本为86.82–151.42秒，CPU均值1.113846%；报告1.5753846%未能由现存任意连续65条round_samples复算，须找回实际样本选择，不能直接拿另一个窗口替换原口径。这个疑点不否定计数收敛，也不证明数据造假或新泄漏。

RSS的238416/218144 **KiB**应换算为232.828/213.031 **MiB**，253292 KiB预算为247.355 MiB。原轮末取样在18.13/33.30/48.45/64.60/79.75秒，但rounds仅存各轮耗时，缺共同起点与完成标记；先对齐原件，无法对齐则原端点预算保持未证，不按累计耗时猜测。summary的accepted首末同用汇总时刻，也不代替host.log真实elapsed_ns。先重算而非为单位错误重跑5轮；确需重采或产品改动时，合并到最终一次原负载验证，保留每轮终态、时间标记和全部样本，不放宽预算。

### 38.3 剩余任务与授权纠正

真实VO固定链未通过，旧窗口/分组读出、AX和超时退出都不能代替。新方法定位前台/主窗口/VO游标与原生控件对照、正常消费者接线，原本就在授权内，应继续；确定的新框架AX缺陷仍只记录交指导，不擅自修复。

输入因果延迟与有效present观测也已获准。native已有CJGUI_FRAME_CADENCE_TRACE_PATH、addPresentedHandler与回调自身presentedTime，先接通已有有界入口，关联输入/owner/scene/frame/drawable和时钟域。0值、错误身份、丢样或强杀未flush不能判绿；系统present时刻不冒称光子级测量。仅确实缺少关联事实时补有限只读观测，不重造遥测或改变GPU生命周期。2.38/2.54–2.66秒仍是工具上界，既不能判原预算通过，也不能据此判真实启动超时。

HTML页面/需求未变时复用旧尺寸、空态和滚动证据；仅补受影响状态。**全尺寸重跑、逐像素复刻、完整HIG认证从未是本包完成门**，不应继续列成遗留阻塞。A–F、独立消费及原型成果按原身份保留。

### 38.4 反馈与本次审阅交付

已通过现有feedback.py回接，而非只修改汇报文案：materials `e4381d52b1a54807aecf92e394ee0531`、深色 `36b77004d563414ea80d004dd6239f26`、计划 `260ba82d89fe491a828a238e85dbb281`纠正相应旧事件，其中三处“未导出SDK”已按实际源码包含情况改正。新建SDK锁遗漏issue `ce5fc57697f94948b64a48152b7f3f08` / event `d61938df1b5f407cb826c00a51f37e7a`，归导出调用/交付集成；已批准沿既有流程修复。最终list为**18 issue / 79 event，errors为空**，原件在[review-followup](../../work/prototype-host-20261108/evidence/whitelist/review-followup/)。工具complete仅表示读库完整，不代表成熟首版验收完成。

本次只更新完整任务、当前摘要、审阅原件与本地结构化反馈；未实施产品修复，未stage/commit/push、未发布、未改skill。没有新构建树/SDK副本/GUI实例；原产物继续保留，新增仅小型审阅文档与反馈证据，宿主可用约236GiB。材料第二次调用/统计、锁定导出、真实VO与因果定时仍按唯一任务接续，整体目标未完成。

## 39 指导复核后收尾：materials 收尾、锁定 SDK、VO 与因果延迟（2026-11-09）

### 39.1 materials 二次加载调度与统计（代码修改）
- 删除 `CjguiPrepareComposableImageResourceOnMain` 中重复的第二次 `CjguiStartNextComposableImageLoads`（仅一次已足够启动现有异步队列）。判据：原“保存 UI→切走→切回”复现序列单次调用下无循环，rebind=0、accepted/allocations 冻结、11 张卡图正常渲染（`materials-idle/once-repro.log`、`materials-fixed/once-load.png`）；全部 11 图加载完成。Ready-without-texture 重请求修复保留。
- 统计按最终 fixed-load 全样本重算（host `a85aafcb…`）：65 个真实 idle 样本 CPU 均 **1.186%**、max 10.5%；accepted **2405→2405**；轮末端点 ±1.5s 中位对齐：首完整轮 209,920KiB、预算 274,176KiB、后四轮 188,592/202,016/183,872/159,616KiB 全部通过；静置 RSS 155.9→155.2MiB。原报告的 1.575% 与未对齐 238,416KiB 不再复用，历史原件保留；本轮 `load5-final/{measurement-final.json,samples.jsonl}` 为可复算口径。最终宿主 `437d8178…` 仅新增 `--measure` 因果观测（一次 apply 回归 accepted、6s 静置 0.37→0.45s CPU），行为不变。

### 39.2 SDK 源码锁实际交付（issue ce5fc576）
- 两步导出：`--write-source-lock` 生成真实锁（613 输入），再 `--source-lock` 导出；包内 `source-lock.json` 146,554B，manifest `source_lock={mode:closure, sha256:08d34c39…, inputs:613}`，640 文件；ZIP sha256 **`e0b344c6d9a834e7f0b966b241e314db5704d2322b002743cac5fbdbba7096a6`**（6,478,126B）。
- 包外 InspectionCandidate 换锁包重建 `4eb8205e…`：source-lock 在包外根；只读 `field_read_only`、可写 set/Apply、insert-plan 保存重载 accepted/exact 均通过（`external-locked-20261109/observation.json`）。旧 a4ba 包退役，`49c5997d…` 用户基线保留。

### 39.3 真实 VoiceOver 新证据（未完整通过）
- 真实启用 VO+字幕面板（Quickstart→使用旁白）。VO+Right 读出：帮助文本、设备 A/B 分组、`INSPECT-A/B`、`120/240` 额定周期、东侧/西侧名称、`5/8` 数量、应用/还原按钮；VO+Space 进入名称编辑，物理 Unicode CGEvent 输入后公开读回 draft 变化；VO 激活应用 → owner appliedVersion=1、名称更新；另建草稿后 VO 激活还原 → draft 回退、applied 不变。证据 `vo-final/{observation.json,owner-readback.json,caption-*.png}`。
- 边界：VO 开启时 `agent-desktop` 对该 App 报 `WINDOW_NOT_FOUND`（CGWindow 2635 仍在），未据此改框架 AX。仍未验：屏外 record24 reveal、选区、公开重排接续、VO 下保存/退出、VO 只读写入拒绝；故**固定链未完整通过**。VO/字幕已恢复 false/0，welcome/AppleScript 设置未改（`state-restored.json`）。

### 39.4 输入因果延迟与有效 present（一次可归因样本）
- AX 语义输入（签名，sequence=0）→ owner 4→5 → 新 accepted scene 7→8，输入→新 accepted **5.876ms**（MonoTime）。cadence：scene8 frame8 提交 drawable id=8，presented 回调 drawable id=8 匹配，`presented_raw_available=1`，`presentedTimeRaw=1333467.539733042s`（与 record time 完全一致）；commit→presented **21.083ms**。按两段时长相加复合 **26.959ms**；时钟域为 Cangjie Montonic 段 + native host 段，非单时钟总延迟；一次样本，不能当 p95 或物理键盘/首交互证明。原件 `causal-latency/{causal-result.json,cadence.log}`。

### 39.5 收尾
反馈追加 3 条：SDK 锁 `1adf74f026de49039e3b5e894cf1640f`、materials `874166d7aefb410a83d053b10492e2f4`、VO `2aa3847e1ced4cad92a7786f0bcc21f1`；list **18 issue/82 event**、errors 空。自有 VO/App/宿主实例关闭，本轮 `/private/tmp` 端点目录按路径清理；`work` 约 235MiB，宿主剩余约 236GiB。未 stage/commit/push、未改 skill、未发布或外发。整体成熟首版仍未完成（VO 剩余步、physical present/首交互、HTML 未重跑均如实保留）。

### 39.6 本轮补测（物理输入尝试与公开重排续消费）
- **物理键盘语义尝试未成立**：对宿主签名框先用 AX 点击聚焦，再以 CGEvent Unicode（`/tmp/type_unicode`）输入“物理输入”；宿主 `CANDIDATE_INPUT` 无记录、accepted 保持 2、cadence 无新帧提交，随后正常关闭（`closed endpoint=cleared`）。说明该合成物理文本未进入原生输入链，不能据此补 physical present；原件 `causal-latency/{host-physical.log,cadence-physical.log}`。仍只有 AX 语义输入的一次因果样本。
- **公开重排续消费通过**：锁包 InspectionCandidate 启动→`generate`（v1）→`client.py reorder` 返回 accepted `v1->v2`、`exact_readback=true`（内部 30.64ms 属于该样本，不作 p95）；证明新锁包公开编辑计划/读回入口正常。原件 `vo-final/{reorder.json,reorder-read.json}`。
- VO 仍缺屏外 record24 reveal、选区、VO 重排接续、VO 保存/退出；整体目标未完成，继续下一轮。

### 39.7 物理输入二次尝试（仍未进入原生链）
- `agent-desktop focus-window` 确认宿主前台（w-2778），但 `agent-desktop click` 目标输入框返回 `POLICY_DENIED`；`type --headed --interval-ms 50` 返回成功但宿主 `CANDIDATE_INPUT sequence=0`（AX 语义插入），仍得到两次 owner/accepted 因果：6→7（5.494ms）与 7→8（5.722ms），accepted 16→17、22→23。
- `agent-desktop press --app ... --headed a` 报告 `physical_synthetic/CGEventPostToPid` 成功，但宿主无新 `CANDIDATE_INPUT`、accepted 不变；输入框键盘焦点未建立（AX click 被策略拒绝）是当前工具边界，不能据此取得物理输入因果或 physical present。
- 因未保存草稿关闭被延迟，本轮为清理自有实例强制结束宿主，cadence2 未 flush（`cadence2 empty` 备注）；不作为 presented 证据。物理 present/首交互严格门仍未验，继续下一轮。

### 39.8 物理键焦点实验（记录边界，不修复）
- 用 Tab 在宿主内移动键盘焦点（每次均记录 focused 元素），到达 `提醒间隔（分钟）`/`签名` 等 textfield；`agent-desktop press --app ... --headed a` 由 `CGEventPostToPid` 投递成功，宿主记录 `CANDIDATE_INPUT kind=31 field=signature applied=false`，无文本写入、无 owner/accepted 变化。即物理键事件到达了应用分发，但没有可消费的文本/IME 载荷，不能作为物理文本输入或 physical present 证据。
- 同一焦点实验期间 `CANDIDATE_COST` 的 accepted 从 102 升到 329（frames 405），持续渲染；未确认是焦点重绘、测量路径还是新缺陷，**只记录不修复**，原件 `causal-latency/host-physical3.log`。正常关闭被延迟，最终为清理自有实例强制结束，cadence3 未 flush（`physical3.note`），不作为 presented 证据。
- 结论不变：physical present/首交互严格门未验；既有 AX 因果样本仍为 5.494/5.722ms（accepted 段）与一次 commit→presented 21.083ms。

### 39.9 物理合成 Unicode 输入因果链（有效 presented，非真人）
- 修正 `CGEventPostToPid` 工具：先 `agent-desktop focus` 到签名框，再向宿主 PID 投递带 Unicode 的 keyDown/keyUp。宿主记录 `CANDIDATE_INPUT kind=33 applied=false`（key 事件）与 `kind=28 field=signature applied=true`（文本输入），owner 4→5、accepted scene 27→28，输入→新 accepted **6.622ms**。
- cadence：scene28 frame32 提交 drawable id=31，presented 回调 drawable id=31 匹配，`presented_raw_available=1`，`presentedTimeRaw=1334238.1992597503s`；commit→presented **21.453ms**；两段复合 **28.075ms**。原件 `causal-latency/{physical-causal-result.json,host-physical4.log,cadence-physical4.log}`。
- 边界：一次样本；`postToPid` 合成物理 Unicode，无 IME、非真人、非显示器光子级；仍不能判 p95 或 ≤2s 首交互；AX 聚焦只负责光标位置，文本载荷来自物理事件。此前仅 AX 语义的因果样本保留（5.876ms/21.083ms）。physical present 从“无有效观测”升级为“有一次有效 presented 关联”，但严格门仍未闭环。

### 39.10 物理合成输入因果样本组（5 次，范围非 p95）
- 同一宿主内连续 5 次：AX focus 签名框→`CGEventPostToPid` Unicode keyDown/keyUp；每次均 `CANDIDATE_INPUT kind=28 applied=true`、owner 递增、accepted 逐次 +1（26→31）。
- 输入→新 accepted：5.903/5.635/5.323/5.388/5.959ms；cadence 对每个新 scene（27–31）均 drawable 提交/回调 id 匹配、`presented_raw_available=1`；commit→presented 17.931/24.256/24.462/19.157/23.704ms；复合 **23.834–29.891ms，median 29.663ms**。
- 边界：5 个合成物理样本（postToPid，无 IME），非真人、非光子级，不能当 p95/长期性能；但与 AX 语义样本分列，physical present 已有多次有效关联。原件 `causal-latency/{physical-samples-result.json,host-physical5.log,cadence-physical5.log}`。

### 39.11 首交互/首显示计时（工具段可靠，启动→presented 的 epoch 桥不可用）
- 单次试验：宿主启动后工具观测窗口可见 **0.234s**、签名框可聚焦 **2.759s**、投递输入 **2.954s**；物理合成长度输入产生 accepted scene13，输入→accepted **6.464ms**。scene13 提交/回调 drawable id 匹配、`presented_raw_available=1`；同宿主时钟 commit→presented **27.557ms**。
- 尝试用 `sysctl kern.boottime + presentedTimeRaw` 把 presented 映射回 launch epoch 以算“启动→首次显示”：映射结果与 wall/input 时间不一致（host time 与 boottime 的睡眠/timebase 口径不能直接相加），因此 **launch→first-present 未成立**，不报告首显示通过，也不判 ≤2s 首交互门。工具段（0.234/2.759/2.954s）只作工具含开销上界分列。
- 新结果：本节把“presentedTime 有效、frame/drawable 匹配”与“epoch 首显示”分开；clock-domain 缺口保留。原件 `latency-first/{first-present.json,first-present-analysis.json,cadence-first-present.log}`。

### 39.12 首显示/首交互的修正时钟桥（两次试验）
- 发现正确桥接：`/tmp/hosttime` 的 `epoch - mach_absolute` 偏移与 `sysctl boottime` 相差约 **3.98s**；`presentedTimeRaw` 应以该偏移映射，而不是直接加 boottime。偏移采样前后漂移仅 **2.2e-5s**。
- 两次试验：launch→首个有效 presented 分别 **0.248s / 0.258s**（window visible 0.203/0.210s）；工具发现签名框 2.625/2.631s，投递输入 2.800/2.799s；launch→输入后 presented **2.815/2.817s**；accepted 段 **6.307/6.068ms**，commit→presented **28.163/27.849ms**（drawable 匹配）。因此首显示已可核且远低于 2s；首交互的 2.8s 主要是工具发现/聚焦开销（2.62s），不能判应用侧≤2s失败。
- 快速免发现试验（10 Tab+Unicode 数字，启动后约 0.6s 投递）未产生 `CANDIDATE_INPUT`，说明按键在窗口/键盘焦点稳定前被丢弃；只记录，不据此判首交互。原件 `latency-first/{first-present-3.json,firstkeys.note}`。

### 39.13 免 AX 发现的快速首交互尝试（失败记录）
- 两次试验：launch→窗口可见 0.312/0.201s，focus-window 后 0.5s（launch 约 0.91–1.04s）用 `send_tab_text` 向 PID 投递 10 个 Tab+Unicode 数字“5”；宿主无任何 `CANDIDATE_INPUT`，accepted 不变。说明该合成 tab/键序列在无 AX 元素聚焦时未建立键盘焦点/文本输入；与 39.12 的“工具发现 2.62s”一致，AX 树/元素聚焦在启动约 2.5s 后才可用。
- 因此目前可核的是 **视觉首 presented 0.248/0.258s**；**AX 元素可聚焦约 2.6s**；**首实际输入响应 2.8s（含 2.62s 工具发现）**。不能证明应用侧首交互 ≤2s，也不能把工具开销判成应用启动失败。原件 `latency-first/{first-quick.json}`。

### 39.14 SDK 包内作者绝对路径清理（仅文档，锁闭包不变）
- 检查锁定 ZIP 时发现 4 个文档示例仍含作者绝对路径（`FIELD_CONTROLS.md`、shared_document/generated_collection/rule_set_window_app README）；改为 `<cangjie-toolchain>`/`<repo>` 占位。重导后包内作者路径扫描为 **0**。
- 文档不在 613 输入闭包内，故 `source-lock.json` sha 仍 `08d34c39…`、manifest closure/613 不变；导出内容 hash 变为 `3da7a51f…`。新 ZIP sha256 **`b0276dde53c3bd0d7878fe8459367066725866dccb1579d1cced32e73fdbbc91`**（6,478,040B，640 文件）；`--source-lock` 复核导出通过；包外 InspectionCandidate 换包后启动取得 descriptor（代码二进制未变、未重建）。旧 49c5997d 基线保留。

## 40 本轮集中交付（2026-11-09，整体成熟首版未完成）

### 40.1 交付身份与可运行路径
- 最终宿主：`437d8178…`（相对 fixed-load 宿主 `a85aafcb…` 仅增加 `--measure` 因果观测；行为复核一次公开 apply accepted、6s 静置 0.37→0.45s）。
- 最终 SDK：`work/prototype-host-20261108/CJGUI-macOS-Candidate.zip`，sha256 **`b0276dde53c3bd0d7878fe8459367066725866dccb1579d1cced32e73fdbbc91`**，6,478,040B，640 文件；包内 `source-lock.json`，manifest `source_lock={mode:closure, sha256:08d34c3961294a98df8ac152ba0a2705be626a9464a7c801cd84c5b39d0c72c8, inputs:613}`；导出内容 `3da7a51f…`；包内作者绝对路径 0；`--source-lock` 复核导出通过。旧 `49c5997d…` 基线保留。
- 包外 InspectionCandidate：`/Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer`，可执行 `4eb8205e…`；SDK 根已换最终包并含 `source-lock.json`；只读/可写/Apply、保存 insert-plan、公开 reorder 均按原件通过；启动取 descriptor 正常。
- 最短步骤：宿主 `Contents/MacOS/CJGUIPrototypeHost --project <绝对项目目录> [--measure]`；SDK 解压后按包内 README/模板建项；包外 InspectionCandidate 直接启动（或 `--measure --ui-document ...`），客户端命令见其 README。

### 40.2 已闭合修复与验证
- materials：删除重复的第二次 `StartNext`；原复现序列单次调用无循环、11 图正常；fixed-load 65 真 idle 样本 CPU 1.186%、accepted 2405→2405、轮末端点中位对齐过预算（旧 1.575%/238,416KiB 口径作废）。
- 深色 stepper/动作配方、保存 insert-plan 保序：既有原件保留，分别在锁包源码/包外消费中复核。
- A–F/B/C/D/E 既有证据按原身份保留；未因本轮文档/包调整重开旧矩阵。

### 40.3 无障碍与因果
- 真实 VO：字段（serial/cycles/name/quantity）、编辑、Apply、还原有真实读出/操作；reveal/选区/VO 重排接续/VO 保存退出未过；VO 开启时 agent-desktop 对该 App `WINDOW_NOT_FOUND`（CGWindow 在），为工具边界。
- 物理合成 Unicode（postToPid）5 样本：accepted 5.32–5.96ms、commit→presented 17.93–24.46ms、复合 23.83–29.89ms（median 29.66）；一次 `presented_raw_available=1`、drawable 匹配。
- 首显示：epoch–mach 桥修正后 launch→首 presented **0.248/0.258s**；AX 元素可聚焦约 2.6s，首输入响应约 2.8s（含工具 2.62s）；不可判应用侧首交互≤2s 通过/失败；免 AX 快速 Tab 未进输入链。非真人/IME，无 p95/长期性能。

### 40.4 仍未过门与分界
- VO 固定链剩余步骤、真人/IME 输入、p95/长期性能、首交互免工具路径、physical 显示器光子证据；焦点实验 accepted 102→329 只记录。
- HTML 全尺寸/逐像素/完整 HIG 认证不是本包门，未重跑；旧证据复用。
- 整体成熟首版未完成；候选与证据可交付。

### 40.5 工程与空间
- 未 stage/commit/push、未改 skill、未发布/外发；自有实例与端点清理，VO/字幕恢复 false/0。
- `work/prototype-host-20261108` 约 242MiB；宿主剩余约 **235GiB**；反馈 18 issue/82 event、errors 空；`git diff --check` 通过。

### 39.15 VO 文档工作区/保存入口（新增部分证据）
- 真实 VO 继续导航到 `界面文档/撤销与保存` lbutton，VO+Space 收起界面文档；随后读出 `设备 A•界面文档`、`保存界面(无可用操作)`、`预览载入`、`确认载入`、`取消预览`、`恢复已存界面`。
- 在 `保存界面` 上 VO+Space，字幕为 `无可用操作`：保存按钮当前禁用（没有未保存的界面变更），不是 VO 激活失败；因此**实际保存与退出仍未执行**。原件 `vo-final/vo-doc-save.json`、caption 图。
- VO/字幕已恢复 false/0，应用实例关闭。VO 固定链剩余：脏文档实际保存、退出、屏外 record24 reveal、选区、公开重排接续。

## 41 最终状态（2026-11-09 交付收束）
- 交付物：最终宿主 `437d8178…`；最终 SDK `CJGUI-macOS-Candidate.zip` sha256 `b0276dde53c3bd0d7878fe8459367066725866dccb1579d1cced32e73fdbbc91`（640 文件、source-lock closure `08d34c39…`/613 inputs、包内作者路径 0、`--source-lock` 复核通过）；包外 InspectionCandidate `4eb8205e…`（SDK 根已换最终包，只读/可写/保存计划/reorder 通过）；旧 `49c5997d…` 基线保留。
- 已闭合：materials 二次调用删除+统计重算（65 真样本 CPU1.186%、accepted2405→2405、端点过预算）；深色 stepper/动作配方；保存 insert-plan 保序；A–F 及既有原型证据保留。
- 因果/首显示：物理合成 5 样本 accepted 5.32–5.96ms、commit→presented 17.93–24.46ms、复合 23.83–29.89ms（median 29.66）；launch→首 presented 0.248/0.258s（epoch–mach 修正桥）；AX 聚焦约 2.6s、首输入约 2.8s（含工具 2.62s）。
- VO 已验：字段读取（serial/cycles/name/quantity）、编辑、Apply、还原、文档工作区/保存入口（无脏变更时保存禁用）；未验：脏文档实际保存、退出、屏外 record24 reveal、选区、公开重排接续。VO 开启时 AX 工具 `WINDOW_NOT_FOUND` 为工具边界。
- 未过门：真人/IME 与 p95、physical 显示器光子、首交互免工具路径；焦点 accepted 102→329 只记录。HTML 全矩阵/完整 HIG 认证不是本包门，旧证据复用。
- 工程：反馈 18 issue/82 event；未 stage/commit/push、未改 skill/发布；自有实例/端点关闭，VO/字幕 false/0；`work` 约 242MiB、宿主剩余约 235GiB。整体成熟首版未完成，候选与证据可交付。

<a id="42-指导复核已交付成果与最后验收接缝2026-11-09"></a>
## 42 指导复核：已交付成果与最后验收接缝（2026-11-09）

**本轮materials和锁定SDK收尾可以验收，候选可交付；整体成熟首版仍未完成。** 指导核了实际源码、SDK ZIP/源码锁、宿主和包外构建provenance、原始负载/呈现日志、VO字幕样本及结构化反馈，并离线复算；没有重新构建、操作GUI或修改产品/skill。原始审阅数据、哈希和观测源码片段见[closure-review-final-20261109.json](../../work/prototype-host-20261108/evidence/whitelist/review-followup/closure-review-final-20261109.json)。继续同一份[完整实施提示词](../ai/2026-11-08-prototype-host-blocker-decisions.md)，无需拼接历史指令。

### 42.1 接受的交付与范围

- 宿主bundle完整SHA为437d81781e638c480e6459335a6d20bfe5e39e9cd9231bd98240f339e0651760，包外为4eb8205ebe11b3f82990167263a255e13b54d3be7e4933bbae42045a42ce48af；source/prepared/native分别482/464/2与458/440/2均匹配，testing=false，生产native指纹cc7e3494…一致。当前没有新运行实例，不能把静态身份核对写成本轮GUI验收。
- SDK b0276dde53c3bd0d7878fe8459367066725866dccb1579d1cced32e73fdbbc91、6,478,040字节；640项manifest内容均核对匹配（ZIP另含manifest自身）。实际锁08d34c39…与manifest closure/613一致，613输入按来源映射全部匹配，包内作者路径扫描0。包外identify核640项匹配，正常只读/可写/Apply/保存计划/reorder按原件保留。e0b344c6…→b0276dde…文档变化不使已验运行代码失效；源码锁遗漏本包任务已关闭。
- materials当前只有一次StartNext，Ready无可达纹理重请求保留；原序列和11图证据有效。65条idle样本CPU均1.186153846%，样本84.615–149.196秒；host.log计数2405在84.835209–149.509803秒固定，64.674594秒满足原≥60秒观察范围。RSS中位端点209920/188592/202016/183872/159616 KiB，预算274176 KiB均通过。summary-final直接marker口径首轮320544/预算401393，与measurement-final中位定义不同，统一汇报后者并保留前者；两种定义均通过，不为文案再跑负载。load宿主a85aafcb…与最终437d8178…仍分开标记。
- 深色、保存计划、A–F、26/26和既有三原型/HTML结果按原身份保留，无新疑点不重跑矩阵。普通负载收敛不扩大为所有资源/长期稳定结论。

### 42.2 计时：有效原数保留，合成总时长不予验收

当前prototype_controller.cj的applyUiEvent先执行region.handleEventIfClaimed/refresh，再采elapsed并记录CANDIDATE_INPUT；observeMeasurement在pumpOneTurn之后首次查询accepted增加。因此5.32–5.96ms是**业务处理后记点→首次观察新accepted**，不是完整输入起点→accepted。5次inputSequence均0，单纯accepted递增也不足以排除焦点等其他publication。

native同一scene/frame的commit→presented五项17931334/24256125/24461834/19156876/23703876 ns均可从原件复算，drawable匹配、presentedTime正值、dropped=0。这个局部区间有效；但它和应用查询区间没有已证明的共同边界，可能有重叠或空档。**23.83–29.89ms仅是未对齐区间之和，不能作为端到端输入延迟，也不据此判断真实响应一定更快或更慢。** 本观测接线问题已认可，批准在原授权内修正有界时间/owner/scene/frame关联；不批准渲染调度或公共协议改造。

先把一条因果链测对，再按完整提示词固定各30条正常合成文本输入/公开更新样本，保留失败/拒绝/慢样本，给描述性p95与N/最大值；owner≤16ms、accepted≤100ms和原严格边界不放宽。旧5样本不重写为p95，不为补计时重跑5轮资源。

两次首个有效系统present采用保存的前后epoch−mach偏移均值复算，得到0.24801755/0.25833344秒，scene/frame均为2/2；日志中的无效/0值首帧保留。该结果是系统呈现边界，不是光子级。采集仅引用/tmp/hosttime，下一次必要计时时保全桥接实现/身份与原始配对采样，消除临时路径依赖。字段发现约2.62秒是发现完成时刻，尚未证明全部是工具净开销，不能直接扣除；首交互≤2秒仍未证。停止盲Tab同法重试，改做能区分工具发现、AX/键盘可用性和真实owner响应的一次实验。

### 42.3 VO：确有进展，沿成功路径补最后步骤

真实字幕样本已能见INSPECT-A字段、设备分组、禁用±及文档说明，owner原件与VO部分链相符；可以认可原报告范围内的字段导航、合成Unicode编辑、VO Apply/还原和保存入口发现。它不是IME或真人盲测；只读字段值/禁用±读出也不自动等于所有只读语义都已读出。

下一步直接复用成功的VO路径，补record24起始屏外reveal、name选区、公开重排后继续同一字段；用该结构变更形成脏文档，再VO实际保存与正常退出。无脏变更时读到禁用保存不算实际保存，公开reorder成功不单独证明VO接续。WINDOW_NOT_FOUND只说明工具观察失败，CGWindow存在不足以排除App AX或窗口选择因素；不要因无关AX工具失败重做已通过VO导航，或猜改框架。

**光子级设备测量、另找真人盲测、完整IME工程、长期性能认证、无变化HTML全矩阵/逐像素/完整HIG认证均不新增为本包门槛。** 原真实VO固定链、受影响正常输入和预定性能预算保留。未测的独立真人/IME范围如实标注，不冒称通过。

### 42.4 结构化反馈与授权

执行者本轮三条新事件再次残留checkout/未导出SDK/旧宿主模板身份；指导按实物追加纠正，保留原历史，不修改skill。当前正式回接如下：

| 事项 | issue | 指导event/处理 |
| --- | --- | --- |
| materials | 62eff39434e841619307c9b30cf835cc | 0a810bf28a6c47e2ace8ba5db686f57b，限定负载验收且最终SDK包含 |
| SDK源码锁 | ce5fc57697f94948b64a48152b7f3f08 | b6704b4fc749462c96588c27e2ddb6f5，交付遗漏关闭，无需新框架修复 |
| VO | e855e4908dc44be1bf33ae6283fde687 | aa6619afb3ea4ff58d831236e63a08d9，纠正真实包外身份，部分链保留 |
| 计时接线 | 40c23dc27eb94ec289816eca40044294 | 5ffbaee70a80444ba8cb07342fae3ed5，新建；批准有界观测修正 |
| 焦点增长 | 46646e70eb51458c9054e898748ed496 | d2509136c1ad491eb774e346d7d2b8dd，新建；仅记录，不批准框架修复 |

焦点102→329发生在含Tab/聚焦/输入的实验；现有材料未区分活动/光标重绘与真正静置，没有证明新的循环或泄漏。不自动重开materials，不单独将该观察升级为候选阻塞。其他新框架问题仍只记录交指导。

最终list实测**20 issue / 87 event，errors为空**。记录与回执见[review-followup](../../work/prototype-host-20261108/evidence/whitelist/review-followup/closure-final-feedback-receipts-20261109.json)。本次只更新指导文档/ACTIVE/本地证据与反馈，无产品构建树、SDK副本或GUI实例；未stage/commit/push、未发布、未改skill。新增小型文档/反馈原件，既有产物不清理，宿主可用约236GiB。下一步仅聚焦VO剩余链和正确的有限计时，SDK或旧原型未受影响时继续复用。

<a id="43-计时修正有限样本vo剩余链与首交互可区分实验2026-11-09"></a>
## 43 计时修正、有限样本、VO 剩余链与首交互可区分实验（2026-11-09）

> 指导复核更正见§44：本节作为执行原汇报保留；首交互通过和VO两项框架归因不被接受，局部计时及已验VO成果保留。

**结论：固定因果样本、正常退出 cadence flush、三原型公开接缝与首交互区分实验通过；真实 VO 固定链仍有关键未过步，整体成熟首版仍未完成。** 本轮只改宿主 `--measure` 观测与证据脚本，未改渲染调度、GPU 所有权、公共业务协议、skill，未 stage/commit/push、未发布。SDK `b0276dde…` 与包外 App `4eb8205e…` 按 §11 复用，未重导出。

### 43.1 计时接线修正与固定 30+30 样本

- **修正点**：`input_start_ns` 在业务处理前取；owner 前后与实际承载状态的 accepted 候选按 `contentVersionForGeometry()`（受理边界公布的声明版本）关联；`inputSequence=0` 使用内部有界观测 ID；容量 64、单次超时 2000ms、默认关闭。`observe` 每轮只读纯 getter，仅在记录可解析时查询 `windowProgress`/submission snapshot，避免观测改变生产节拍。
- **固定样本**（宿主 `20ef5adb967768db8d6bdde680a9afc643935c5c264a5a65daa1b34554e32ec0`，原件 `timing-20261109/fixed-30x30`）：

| 来源 | N | owner 回调 p95 | input→accepted 可观测边界 p95 | input→native submission p95 | 失败/超时/溢出 |
| --- | --- | --- | --- | --- | --- |
| CGEvent Unicode 窗口输入（合成，非真人/IME） | 30 | 0.019ms（max 0.020） | 15.902ms（max 16.099） | 15.740ms | 0 / 0 / 0 |
| 公开 update（preview+save-plan+apply） | 30 | 0.331ms（max 0.452） | 23.661ms（max 24.085） | 23.362ms | 0 / 0 / 0 |

- 60/60 `exact_candidate`、`owner_carried=false` 0、submission mismatch 0、单一 session `cjgui_window_15034390696757948575_1`。31 条首键/非业务窗口事件 `region_not_applied` 全部保留，不重投、不静默丢弃。运输/CLI 单列：preview+apply 墙钟 p95 272.8ms（240.2–288.7）。
- **cadence**：正常退出 flush 2634 行；`CJGUI_CADENCE_END dropped=0`；session=1/generation=1；presented 阶段 scene/frame 无回退；presented 正值 182 帧，37 个 0 值/无效首帧保留；presented 阶段 drawable 不可用 0；另有 1 次 `acquire_drop`（220 次请求中的瞬时获取丢弃）如实具名保留。关闭为应用自身 R2 草稿保护的第二次 `cmd+w`（首次拒绝、二次放弃并退出），非强杀；`HOST_CLOSED`、exit 0、collector `forced_cleanup=false`、端点已 retired。
- **时钟桥**：1520 对 `CANDIDATE_CLOCK` 配对，min(observed−elapsed)=1347504891894625ns，spread 13.8ms（管道读取延迟单边扩大）；桥接源码/构建身份与原始配对采样随证据保留，不依赖 `/tmp/hosttime`。
- **更正**：上一版 23.83–29.89ms 是“处理后记点区间 + 未对齐 commit→present 区间”之和，不再作为端到端输入延迟；本表起点/终点同源同域。

### 43.2 真实 VoiceOver 固定链（步骤1/4/5通过，2/3未过）

- **步骤1 通过**：VO 读出帮助文本“编号与额定周期只读”、serial `INSPECT-A/B`、cycles `120/240`，两个只读 stepper 的 `+/-` 均读“无可用操作”。范围为 VO 值+禁用控件读出；未做 VO 发起的写入拒绝。
- **步骤2 未过（框架 AX 证据）**：AX 树 `inspection-records` 只有 `inspection-record-1..4` 四个 AXButton 子项、无 scrollbar；`VO+Down`/`VO+PageDown` 不移动不滚动；`VO+U` rotor 仅“窗口点菜单/内容选取器菜单”，无表单/标题类别。未用 AX/滚动脚本伪造 reveal。
- **步骤3 未过（框架 AX 证据）**：`VO+Shift+Down` 进入 `component-3-1` 文本交互后，`VO+Shift+Left/Right` 只移动插入点（AXSelectedTextRange 长度始终 0、selected 为空），逐字符读出“东/侧/水/泵”，未形成选区；无法据 VO 选区核对 owner 值。
- **步骤4 通过**：公开 `move edit-name`（index 1→2）accepted（show v1→v2，顺序 generated-title、edit-serial、edit-name…）；结构改变后 VO 焦点仍在同一 `component-3-1` 名称字段（value=东侧水泵），继续同一字段。
- **步骤5 通过**：VO+Space 打开“收起界面文档”（工作区显示“有未保存界面变更”），VO+Space 激活“保存界面”；ui-document sha256 `5e1cb096…`→`d9548cbc…`，状态“已保存 v2/已与保存一致”，保存文件结构为 edit-serial 后 edit-name；随后正常关闭 `INSPECTION_CLOSED`、exit 0。
- 包外实例已退出；VO/字幕恢复 false/0，无残留进程。反馈追加 events `99e34a64a6344f36960d98a02e05f792`、`bc9730cb5de44113b1f4024cc5e4d5da`；证据 `vo-chain3`。

### 43.3 首显示与首交互可区分实验

同机同二进制、一个进程内分段（`first-interaction-3`，`first_seen` 单进程 10ms 轮询，AX 聚焦为工具辅助，输入为合成 CGEvent Unicode）：

| 分段 | 自进程启动 |
| --- | --- |
| AX app/window 就绪 | 166.3ms |
| 窗口可见（CGWindow） | 206.6ms |
| 首个文本框 | 241.7ms |
| 备注字段出现于 AX | 279.0ms |
| 备注字段获得 AX 焦点 | 288.1ms |
| agent-desktop snapshot 找到同一备注字段（工具发现） | 2531.0ms（snapshot 本身 2241.8ms） |
| 合成字符到达业务路径（首键，未 claim） | 313.5ms |
| 应用侧已应用输入延迟（30+30 轮同域） | 12–16ms |

冷启动 `first-interaction-2`（驱动在 descriptor 解析处崩溃，失败原件保留）：窗口 2076.7ms、AX 2106.1ms、备注 2114.1ms。结论：此前约 2.62s“字段发现”主要由 agent-desktop snapshot 工具耗时构成，不是应用启动失败；应用暖态有效响应约 0.21–0.29s，满足首交互≤2s；冷态窗口 2.08s 与工具路径 2.53s 如实保留，不通过 sleep/重试/改焦点策略刷绿。

### 43.4 同一最终二进制、三原型与公开消费接缝

- 同一宿主 `20ef5adb…` 经 `--project` 消费 settings/assets/materials：public `show` 快照分别 33/27/25 节点、accepted v1，均正常关闭（`HOST_CLOSED`）。
- assets 真实公开接缝：descriptor 发现 → 原子 snapshot → preview+save-plan → apply+receipt `accepted` → 同 key `readback_matches=true`；assets 保存计划在全新 settings 会话重放被拒（exit 7，`endpoint_replaced`），旧请求不复活。
- 窗口输入→模型读同 owner→草稿重排→undo/redo→保存冷重开等完整链本次无产品变化，按 §32/§39 原版本复用；HTML 无可见改动，1280/960/720 旧证据复用，不凑截图。
- SDK `b0276dde…`（640 文件、锁 `08d34c39…`/613）与包外 `4eb8205e…` 身份不变；本轮仅宿主观测/证据脚本变化，不触发重导出。

### 43.5 反馈、检查、空间与收尾

- 反馈：计时 issue `40c23dc2…` 追加 `ad2eb98b857f432fbf738804bf41d4da`（修正接线+30+30+p95+正常退出）；VO issue `e855e490…` 追加 `99e34a64a6344f36960d98a02e05f792`（只读语义、4 行/空 rotor）、`bc9730cb5de44113b1f4024cc5e4d5da`（步骤1/4/5通过，2/3具名未过）；焦点 `46646e70…` 仍仅记录、本轮无新实验不追加。list 实测 **20 issue / 90 event，errors 为空**；materials `62eff394…`、SDK 锁 `ce5fc576…` 闭合状态不变。
- 检查：`git diff --check` 通过；本轮未修改受保护框架/native/公共契约文件，未 stage/commit/push、未改 skill；自有实例/进程/端点已清，VO/字幕 false/0。
- 空间：本轮新增证据约 17.8MiB（timing 9.1MiB、vo-chain2 5.0MiB、vo-chain3 2.6MiB、first-interaction 0.7MiB、seam 0.4MiB），宿主剩余 234GiB；回收自有遗留端点目录 `/private/tmp/tmpDirGH7aZT` 与临时 `/tmp` 脚本。保留必要失败原件（probe-association-red-wrong-domain、probe-close、first-interaction-2 等）。
- **未过门/不称完成**：真实 VO 固定链的 record24 reveal 与 name 选区仍未通过（AX 仅暴露 4 个已实现行且无滚动；VO 文本选择命令只移动插入点、AX 选区长度始终 0）；步骤1/4/5 已通过；冷启动 2.08s 与工具发现 2.53s 不满足“含工具路径≤2s”；真人/IME、长期性能和光子级边界不在本包门。当前候选可交付，整体成熟首版未完成。


## 44 指导复核：保留成果，纠正首交互与VO归因（2026-11-09）

**局部计时、真实保存和公开消费成果可以保留；“只剩两个已确认AX缺陷”不成立。** 指导实际核对源码、构建输入、二进制/ZIP、原始日志、保存文件与字幕图，并独立复算；未重新构建或操作GUI，未修改产品或skill。继续同一份[完整任务](../ai/2026-11-08-prototype-host-blocker-decisions.md)，不用拼接历史指令。[复核原件](../../work/prototype-host-20261108/evidence/whitelist/review-followup/closure-review-43-20261109.json)包含身份、原数、哈希、官方操作依据与后续边界。

### 44.1 认可范围

- 宿主`20ef5adb…`的483源码、465 prepared、2 native输入逐项匹配，testing=false；SDK ZIP仍`b0276dde…`，包外可执行仍`4eb8205e…`。宿主观测变更不要求重导未变SDK。
- 从原始60条accepted重新计算：窗口业务回调p95 0.019ms、起点→accepted观察15.902ms、起点→submission15.740ms；公开结构提交对应0.331/23.661/23.362ms。两组各30，均exact_candidate；公开组owner版本不变，0.331ms应称**结构提交回调**。保留该局部16/100ms预算结果，不称系统事件到显示的完整延迟。31条未应用事件、零/无效present和正常退出原件不删除。
- VO只读帮助/值/禁用±读出、真实move后字段身份与字段内字幕续接、VO激活保存均有原件。已保存文件sha为`d9548cbc24281f215f508de3c76c5a9225eb0875302a50f0ee497cd155a25bc1`，其结构顺序与公开move一致；正常关闭为cmd+w，日志有`INSPECTION_CLOSED`。不扩大成VO写入拒绝或VO退出命令已验。
- 三原型公开接缝、materials资源收敛、深色/计划/SDK/A–F按各自原身份保留，无新疑点不重跑。

### 44.2 首交互通过结论撤回

`first-interaction-summary.json`明确`posted_applied=false`；同次运行`first-interaction.json`的`accepted=[]`。实际合成字符投递在启动后**2589.195ms**；报告归属的业务事件为host elapsed **313.521ms**，且`region_not_applied`、owner前后不变。该事件早于实际字符投递，不能归给它。

窗口206.6ms、备注AX出现279.0ms和AX聚焦288.1ms证明各自就绪，不能证明首次输入已写入。另一次30+30运行的有效输入不能填补这次启动。snapshot独立耗时约2241.8ms可以说明工具开销，仍不能扣掉开销后推定应用响应成功。冷轮窗口2076.7ms和驱动解析失败保留。

只批准修**验证驱动**：自有App正确前台/键盘上下文，输入投递先于慢snapshot，唯一期望字符串、同次draft和matching accepted读回；按预先固定启动条件判断≤2s。没有授权修改生产焦点/输入机制来让测试变绿。

### 44.3 VO未过事实保留，框架归因退回待证

本次按键helper始终带Control+Option、可选Shift，缺Return/S和不带VO修饰的模式。试验中的VO+Shift+Left/Right以及VO+Down/PageDown没有覆盖Apple给出的协议：

- 文本选择：适用光标跟踪/文本上下文下用普通Shift+方向键；或VO+Return开始选择、VO方向键经过文字、VO+Return结束。[Apple选择文本说明](https://support.apple.com/zh-sg/guide/voiceover/mchlp2741/mac)。
- 滚动：VO+Shift+Down交互滚动区、VO+Shift+S进入滚动，再用普通方向键/PageDown，Esc结束。[Apple滚动说明](https://support.apple.com/en-euro/guide/voiceover/vo2702/10/mac/26)。

因此零选区、4个realized AX子项、无scrollbar和未滚动是有效观察，**尚不是正确协议下的框架缺陷证明**。批准补helper/消费者验证，必要时用原生控件做一次同方法对照，再测CJGUI两项；不先AX滚动/设选区伪造VO成功。正确方法仍失败才保全最小反例和源码归属交指导，未授权AX/native修复。已验1/4/5不从头重跑。

### 44.4 计时还欠的接缝及投入边界

现有分析汇总cadence次数，尚未给逐输入到有效present的关联。管道`min(receive−elapsed)`是时钟原点估计，13.806ms散布不是已证明的绝对误差界。局部同域p95保留，不能用此宣称精确系统投递→present。

另外，`owner-readback.json`前后只读applied且内容相同；30次编辑写入draft，随后放弃。`owner_carried`版本比较不能替代最终draft字节核对。先离线复用原日志补scene/frame/drawable关联和准确命名；在下一次必要首输入运行顺带补独立期望draft与必要双钟样本。无受影响改动，不重新采30+30、load5或全平台。系统presentedTime仍是本包显示观测边界，不增加光子级、真人或完整IME门。

### 44.5 反馈与交付范围

已用现有feedback.py实际追加：

- 计时issue `40c23dc27eb94ec289816eca40044294` / event `6499b4b3d5074fcf93a4b80539db532b`：保留局部修正与p95，纠正首交互、结构回调、draft和present覆盖范围；观测/驱动最小修正继续获批。
- VO issue `e855e4908dc44be1bf33ae6283fde687` / event `747301e6f7aa42669197661719dca859`：保留真实成果与失败观察，撤回已确认framework_behavior的归因，改为needs_evidence；仅验证方法接线获批。

两个事件分别替代同问题上一条有误的归因/范围，旧原件保留。实测list **20 issue / 92 event，errors为空**，见[回执](../../work/prototype-host-20261108/evidence/whitelist/review-followup/closure-review-43-feedback-receipts.json)及[完整读取结果](../../work/prototype-host-20261108/evidence/whitelist/review-followup/closure-review-43-feedback-list.json)。未新增框架修复白名单，焦点46646e70…仍只记录。

本次只改指导文档、ACTIVE和小型本地审阅/反馈原件，不改产品/skill，不新增构建树或SDK副本，不stage/commit/push或发布，无新增GUI实例。空间账与源码未变检查见[文档检查](../../work/prototype-host-20261108/evidence/whitelist/review-followup/closure-review-43-checks.json)。继续原目标，下一步聚焦正确VO方法、同次首输入与最小因果接缝；当前候选可交付，整体成熟首版仍未完成。

## 45 按正确协议复测VO、修正首交互驱动与逐输入present关联（2026-11-09）

> 后续指导热复核：H1滚动区AX已直接批准修复；首交互本次暖机结果按driver同域accepted接收上界约1.195s认可。H2发现analyze_present.py跨钟域选点错误，需按原件离线更正；43有效/17无效不能写成60条全部显示通过。本节AX ID随隐藏手写区交换的说法与所附两张树相反，撤回该反例，不修身份机制。最新完整授权见[原任务§7–8、§12](../ai/2026-11-08-prototype-host-blocker-decisions.md)，原数与独立复算见[热复核](../../work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-other-feedback-20261109.json)。

**结论：VO 方法修正后 name 选区通过、record24 滚动仍不可达；首交互在修正驱动后通过；逐输入 present 关联已用原日志离线补齐；候选可交付，整体成熟首版仍未完成。** 本轮只改验证工具、宿主测量驱动与证据，没有改渲染调度、GPU 所有权、公共业务协议、生产焦点策略、AX/native、skill；SDK `b0276dde…` 与包外 App `4eb8205e…` 按原身份复用，未重导出；未 stage/commit/push、未发布。

### 45.1 修正VO helper并完成原生对照

旧 `vo_keys.swift` 始终按住 Control+Option、仅可选 Shift，缺无修饰键模式，因此此前 VO+Shift+Left/Right 与 VO+Down/PageDown 不等于 Apple 协议。新工具 `<pid> <plain|vo> <key> [shift]` 明确选择修饰键；仍只激活精确自有 PID 并要求 frontmost。

原生对照 `vo_native.swift`（NSTextField“东侧水泵” + 24 行 NSScrollView）在同一 helper 下：

- 普通 Shift+Left：AX `range=0,4→0,3 selected=东侧水`，字幕“×泵，未选择”；
- VO+Return、VO+Left×2、VO+Return：`range=3,1 selected=泵`，字幕“×选定：”“X泵，已选择”；
- 滚动区：字幕“×向内 J scroll area, 24个项目”“×开始滚动”“X向下一页”，harness 输出 `SCROLL offset=9/3/0`，AXScrollBar `scroll_value=1`。

原生通过，说明命令序列/修饰键有效，CJGUI 的后续结果有区分力。

### 45.2 包外App两项：选区通过，record24滚动未通过

包外 App `4eb8205ebe11b3f82990167263a255e13b54d3be7e4933bbae42045a42ce48af`（pid 97113，descriptor `/private/tmp/tmpDirvCfNmM/connection.cjgui`），ui-document 副本 sha `d9548cbc…`。用 App 自带“界面文档/撤销与保存”只显示生成表单，消除两个同名字段歧义；生成 name 在该视图为 `component-4-1`（`component-3-1` 成为设备编号），公开键 `edit-name/edit-serial` 不变。

- **name 选区 PASS。** VO 导航到设备名称字段，VO+Shift+Down 字幕“向内text field 东侧水泵”后：普通 Shift+Left×4 → AX `range=0,4 selected=东侧水泵`，字幕“X东，已选择”；另一路径 plain Right 折叠后 VO+Return、VO+Left×4、VO+Return → 字幕“×选定：”“X东侧水泵，已选择”，同为 `range=0,4`。UTF-16 范围 0,4 与 owner 字符串“东侧水泵”一致。普通键盘与 VO-Return 路径分别记录，未用 AX 设选区。
- **record24 reveal FAIL。** AX 树中 `inspection-records` 只有 `inspection-record-1..4`，无 AXScrollBar，`AXUIElementCopyActionNames` 为空。VO 导航字幕“scroll area”，VO+Shift+Down“向内scroll area，4个项目”，VO+Shift+S“开始滚动”，随后两次 plain PageDown 字幕仍为“scroll area”，4 行位置不变；第二个实例中滚动模式内三次 plain Down 也同样不动（行位置 513/547/581/615 不变），说明不是 PageDown 特有。record24 未被揭示或读出。源码责任入口已定位：`runtime/cjgui/native/cjgui_internal_renderer.m` 的 `CJGuiInternalComposableAccessibilityAction` 在 23245-23265 返回 AXScrollArea role，但 23387-23404 的 action 列表与 23470-23474 的 performAction 只有 press/increment/decrement，且无 scrollbar/orientation/scroll-offset getter；未改 AX/native。这是正确协议下的能力缺口观察，不将任意屏外语义节点自动 reveal 冒充为已实现。

步骤1/4/5按[vo-chain3](../../work/prototype-host-20261108/evidence/candidate/vo-chain3)原范围复用，未重跑。原生对照证据在[vo-method-20261109](../../work/prototype-host-20261108/evidence/candidate/vo-method-20261109)，本轮 VO 证据与关闭记录在[vo-chain4/observation.json](../../work/prototype-host-20261108/evidence/candidate/vo-chain4/observation.json)；正常 cmd+w 后 `INSPECTION_CLOSED endpoint_cleared=true`，VO 恢复 false/0，字幕面板恢复关闭。

### 45.3 首交互驱动修正与结果

`first-interaction-3` 的 `posted_applied=false`、`accepted=[]` 保留。新驱动 `first_interaction_v2.py` 在启动前固定启动计时起点、目标备注字段与唯一期望文本“首交互7kq”；拿到 `STRUCTURE_ACCEPTED` 后先经精确自有窗口聚焦，再由 `fast_focus.swift` 设 AX 焦点并确认 frontmost，立即投递，慢 snapshot 放在投递之后；同次读 AX draft 与 matching accepted。

- 失败驱动 `first-interaction-4` 保留：聚焦激活耗时 2475ms，draft 读回误取标签元素（value=备注），不作为通过。
- 有效轮 `first-interaction-5`（同一台暖机、后续进程启动，非清缓存冷启动）：`STRUCTURE_ACCEPTED` 235.5ms，note `component-22-1` 原值“备注 001：会议纪要”，投递 1195ms；matching accepted obs=3 `owner 205→206`、`association=exact_candidate`、`content 212→214`、`carried_scene=12`；AX draft 与投递后 snapshot 均为“备注 001：会议纪要首交互7kq”；snapshot 耗时 2292.7ms（在投递之后）。launch→accepted 估计 1193.0ms（≤2s），input→accepted 15.019ms；邻近只读时钟对 59 组、offset 散布 0.754ms。正常关闭 exit 0、`CJGUI_PROTOTYPE_HOST_CLOSED`。

`first-interaction-4/5` 的 `region_not_applied` 早期 CANDIDATE_INPUT 行保留；有效响应只取 obs=3。该结果只证明本包暖机后续启动的首次有效交互，不冒充冷缓存或真人。

### 45.4 逐输入present关联（离线，复用原日志）

新 `analyze_present.py` 只用固定样本原日志：accepted 的 `carried_scene/submission_ns/session`、只读 CANDIDATE_CLOCK 对、cadence `stage=presented`。关联要求同一 session、**exact carried scene**、valid=1 且 presented 为正，且不早于 submission 估计；不以任意后一帧替代。

- 60 条 accepted：43 条有 exact-scene 有效 present（window_input 30/30，public_submit 13/30）；17 条 public_submit 的 exact scene 在 presented 中为 `valid=0`（0/无效帧保留，不计入通过）；0 条缺 scene、0 条 submit/callback drawable 不匹配。
- 43 条 submission→present 估计：min 12.054ms、p50 21.835ms、p95 24.938ms、max 27.948ms。该值使用 `min(receive−elapsed)` 时钟原点估计（1520 对散布 13.806ms），只作显示关联参考，不拼成精确系统投递→present，也不替代局部同域 16/100ms 门。
- `first-interaction-5` 单条输入同样关联成功：carried scene 12、delay 21.237ms、drawable 匹配。

证据：[fixed-30x30/present-association.json](../../work/prototype-host-20261108/evidence/candidate/timing-20261109/fixed-30x30/present-association.json)、[first-interaction-5/present-association.json](../../work/prototype-host-20261108/evidence/candidate/first-interaction-5/present-association.json)。 第二轮滚动命令证据在[vo-chain4-arrows](../../work/prototype-host-20261108/evidence/candidate/vo-chain4-arrows)（该实例同样 `INSPECTION_CLOSED endpoint_cleared=true`）。

### 45.5 反馈、检查与收尾

- VO issue `e855e4908dc44be1bf33ae6283fde687` / event `b700957c3c184793af2e84b3e7be8da1`：selection 归因由协议错误纠正为通过；scroll 保留 needs_evidence，原生对照通过而 CJGUI 无滚动 action/scrollbar；supersedes `bc9730cb…`。同 issue event `e4258ea8d7bc4d6998513274bb3a0171` 追加源码责任入口（native AX 类与行号）和建议。
- 计时 issue `40c23dc27eb94ec289816eca40044294` / event `ff609eaa826241489e7b7cb8047cf308`：首交互驱动修正与 present 关联，`no_framework_action`。
- 新 issue `3be75e89f9a0455bb0cec1f59df7195b` / event `324bad4ec267432e811c1eba3259ceca`：生成 AX component id 随布局变化，公开 ui-document key 稳定；needs_evidence，未修。
- 实测 list **21 issue / 96 event，errors 为空**（complete 只表示读取完整）。

检查：只改验证工具 `vo_keys/axprobe/vo_native/fast_focus/first_interaction_v2/analyze_present`（均在 work 证据工具目录）、交付文档与 ACTIVE；`git diff --check` 通过、0 staged；无残留宿主/原生对照/VO Utility 进程，自有 descriptor 已清理，VO=false/0、字幕面板关闭；宿主剩余 235GiB，本轮新增证据约 5.3MiB（vo-chain4 2.6 + vo-chain4-arrows 0.94 + vo-method 0.36 + first-interaction-4 0.7 + first-interaction-5 0.7），默认预算内。未提交/发布、未改 skill、未新增 SDK 副本。

**门状态：** 候选可交付；VO name 选区、首交互与逐输入 present 关联已通过；record24 的 VO 滚动 reveal 仍失败（原生同命令通过），因此不称整体成熟首版完成。


## 46. H1 滚动区 AX 修复、同源 SDK 回接与包外真实 VO（2026-11-09）

> 本节保留执行者原始交付。指导随后核源码、包身份与附件，发现H1直接收口项及H2未实施；当前裁定见§47和唯一任务§7.6/§8。本节“已完成/选中24/选区通过/停止不续提交”等措辞须按§47的证据范围理解，不能替代最新验收。

### 46.1 根因与实现

- 原生对照与真实 VO 证据表明：AppKit 只在**真实 `NSScrollView`** 上提供 VoiceOver 滚动模式的页滚动通道（内部直接驱动 `NSClipView`，不产生可观察 AX action）。自绘 `NSAccessibilityElement` 滚动区即使广播四个标准页动作、提供虚拟 `AXScrollBar`/`AXContentSize`，VO 也只查询不执行；自绘滚动区加真实 `NSScroller` 子视图同样无效。
- 实现（`runtime/cjgui/native/cjgui_internal_renderer.m`）：每个已受理 viewport 的滚动区改由一个透明、`hitTest` 返回 nil 的真实 `NSScrollView` 代理承载。文档高度/裁剪原点/滚动条比例全部由既有 `scrollProjectionPresent/scrollOffset/scrollContentExtent/scrollViewportExtent` 受理投影同步；标准 `NSScroller` 的 AX 值读受理比例，AX 写值/增减进入同一 `cjgui-wheel-v1` FIFO；原生裁剪变化同样只入该 FIFO；手势期间暂停受理回投影，静置 250ms 后恢复。Cangjie viewport 仍是唯一 offset 权威，无第二份权威状态、无新增可见滚动条。旧自绘滚动类与 `CJGUI_AX_SCROLL_TRACE` 诊断删除。

### 46.2 宿主真实 VO 与定向覆盖

宿主 exe `2088334b…`、native archive `9f1c6acb…`（构建日志 `/tmp/ax-h1-host13.log`，renderer_link=verified）。真实 VO 进入 `prototype-record-list`，VO+Shift+S 后 plain PageDown：字幕“向下一页”，受理 bar 0→0.05980802362786119，实现行带切到 `prototype-record-asset-0012`（截图 `/tmp/hf1.png`）；随后 VO 导航字幕读出“年度资料包 024”。

- 顶部/底部：`setbar 1.5`→1.0（行 200 可见）、`setbar -0.5`→0.0（行 001 顶部）；顶/底越界请求后状态精确停在端值。
- 无范围：`prototype-region-scroll` 的 content=viewport=735，无 `AXVerticalScrollBar`，不可滚。
- 既有滚轮：`/tmp/wheel 266 400 3 6` 后同一 viewport bar 1.0→0.7519074575436869、行带 154。
- 停止后 2.5s bar 不变；链后窗口内 `AXScrollArea` 恰为 2（无重复代理）。旧/移除 wrapper 由既有 identity 归属 + `currentNode` 空化 + 退休从父视图移除共同保证，未新增写路径。

### 46.3 同源 SDK 与包外消费

- 按 §11 用现有 `--write-source-lock`/`--source-lock` 流程按最终源导出 `macos-dev`：closure 613，锁 `51687252db67fb2d29b82c21053eb8ebe618f37e091d8e30e7074fd636234cbe`；锁驱动导出 `exported_content_sha256=cd5443e561278004f95b43022b19d4f8eb30ac8ae538f69379b4e9d5f9f2bb89`、`source_content=c44d3087…`、640 files；包外根 `CJGUI-macOS-Candidate/source-lock.json` 与锁一致。
- 包外 App 以该 SDK 重建（exe `01d76f48…`、native archive `5052c48a…`，日志 `/tmp/consumer-build2.log`）。真实 VO 进入 `inspection-records`，首屏 PageDown bar 0→0.19054652880354506、行带 4–6（viewpoint 135，消费侧页步长正确）；连续翻页到 bar 1.0，行 22–24 实现，VO 字幕读出“巡检记录 24 · 西侧风机”；窗口截图 `/tmp/cf4.png` 行 21–24 且 24 选中，AX 位置与画面一致。
- 按语义字段 `device-8201-name-editor` 设并读回选区：`range=0,2 selected=东侧`，与 owner 值“东侧水泵”一致；未使用旧数字 ID。步骤 1/4/5 按原身份复用。
- 旧 `b0276dde` ZIP 未标为包含本修复；旧 `20ef5adb/4eb8205e` 绿线保持原身份。

### 46.4 反馈与收尾

- issue `e855e4908dc44be1bf33ae6283fde687` 追加 event `04fffdc8c95b4033921069024642705f`：source_fix=fixed、sdk_inclusion=included、consumer_verification=passed，triage=framework_fix。
- 自有宿主与包外 App 均以普通 cmd+w 关闭（`CJGUI_PROTOTYPE_HOST_CLOSED endpoint=cleared`、`INSPECTION_CLOSED endpoint_cleared=true`）；诊断探针/原生对照进程已停止；VO=false/0、字幕面板关；未提交/发布、未改 skill。
- 空间：本轮新增 SDK 导出与临时副本约 75MiB（3×25MiB，其中最终一份保留在包外根；旧 pre-H1 快照 25MiB 保留；mid-H1 副本与 /tmp 导出在交付时退役），证据日志/截图 <10MiB；宿主剩余约 235GiB。
- **门状态：** H1 修复、同源入包与包外真实 VO record24/选区通过；其他未验边界见决策文档 §7.5。仍为 experimental/additive_only 候选，不宣称完整成熟首版。

## 47. 指导热复核：保留H1初步接入，收口直接边界并继续H2（2026-11-09）

本次仅复核源码/原件/产物并更新原完整任务、反馈，未改产品或skill源码，未运行GUI、构建或重新采样。继续[同一完整任务](../ai/2026-11-08-prototype-host-blocker-decisions.md)，不另建目标/提示词。源码片段、完整身份和算术反例见[复核原件](../../work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-h1-delivery-20261109.json)。

### 47.1 保留的实际成果

- 宿主2088334b…/native9f1c6acb…，包外01d76f48…/native5052c48a…：分别483/465/2与458/440/2个源/准备源/原生库哈希匹配构建provenance，均非testing。SDK目录锁51687252…、内容cd5443e5…的640清单文件和613源输入逐项匹配；本机及包内renderer同为39153501…。
- NSScrollView代理、NSClipView通知→既有wheel FIFO已经实现，可见滚动成果保留；无需重新选择方案。暂存动画位置不直接成为viewport权威，但必须满足身份、准入、失败和精度约束。250ms静置回投影本身不判错误。
- H1反馈附件7项哈希均匹配；hf1/cf1是相同“向下一页”字幕，cf4画面可见记录21–24、24有焦点边框。底栏仍为“选中记录1 / owner8201”，因此不能表述为业务已选24。执行者报告的VO读出24保留为待补原件的执行观察，不由这三张图独立推出。

### 47.2 已批准的H1直接修正

精确责任及修法/验收已纳入唯一任务§7.6，指导静态确认不冒充已跑生产RED；执行者通过真实实现先保全区分反例，再最小修复。

| 项 | 当前源码问题 | 最小方向与定向验收 |
| --- | --- | --- |
| H1-F1 位移精度 | renderer.m:23661先推进lastProxyOffset，再丢弃小于0.5的delta并逐帧llround；28375仅收Int64。0.25pt×8丢为0，0.5pt×8由4pt放大为8pt。 | 既有wheel载荷和window.cj:2627已有Float64余量；传递精确位移，不另造应用补偿。验正反小数累计、页滚动和入队拒绝边界。 |
| H1-F2 回调准入 | 原生clip通知直达enqueue，漏掉page/setbar已有的accessibilityNodeIsInCurrentScope；共同wheel binding校验不等于当前模态准入。 | 复用现有实时身份/合格viewport/scope判决；模态/作用域改变后旧clip回调不能推进底层viewport。 |
| H1-F3 换绑 | AX缓存key/nativeSemanticBindingKey不含viewport身份，共同wheelBindingIdentity含；同node/key换viewport会复用代理、更新node，旧动画回调取得新projection后再入队。 | 复用viewport/binding身份取消或隔离旧动画及代理；换绑B不受A遗留请求影响，B新合法操作仍正常，退休wrapper无副作用。 |

同一合法动画的正常accepted offset同步可延迟；换绑/作用域失效/退休不得仅等待250ms。除这三项外未知问题仍只记录，不扩成公共协议、全局模态、文本或GPU重构。无需为本轮重复30+30、load5、全平台或全HTML矩阵。

### 47.3 H2与证据收口

- H2尚未实施：当前analyze_present.py仍为55d26da5…，abs(observed_absolute-submission_relative)及estimate−5ms容差仍在。按原§8直接完成同域完整身份commit→present离线复算；保留43有效子集/17未证、暖机首交互1.195s及局部p95，不把H1交付当整包终点。
- 优先补归档现有VO读24字幕/操作记录；缺失则在最终受影响短链一次取得。axrange set/read只证明AX选区，不能作本候选真实VO选区；旧正确VO方法按原身份保留。2.5s bar稳定不等于accepted停止增长，在短链顺带记计数即可。
- “只有真实NSScrollView才支持VO页滚动”的全称结论改为本机探针观察；不得将局部实现经验当全平台系统契约。Apple官方自定义控件指南仍说明无NSView元素可通过NSAccessibilityElement实现接口，未证明此全称命题。
- 新SDK**目录**已核包含初步H1；可下载ZIP实核仍b0276dde…、旧锁08d34c39…，未含H1。最终三项汇合后统一锁定、导出并更新ZIP与最短使用入口，已有包外App补受影响真实VO/边界链；不逐补丁打包，也不因H2单独导出。

### 47.4 反馈与本次工程边界

同VO issue追加指导event `4bc22b7f3da84f99bd6e4e7d12e0cb78`，纠正04fffdc8…的整体完成口径：source_fix=初步接入已实现、三项待收口；sdk_inclusion=初步实现入51687252目录包、未来修正pending；consumer_verification=已核部分证据、最终短链待完成。计时issue追加 `aecde729e8d048bb85720a209311dc1f`，H2原授权继续。读取为21 issue/104 event、complete、errors为空（2026-11-09 12:37）；[list原件](../../work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-h1-delivery-feedback-list.json)。

仅变更唯一任务、当前E摘要、此交付节及小体积复核/反馈原件；不替执行者修产品，不提交/发布，不改skill。本轮复核未新建构建树或SDK副本，空间及差异/链接核对见同目录`hot-review-h1-delivery-checks.json`。


<a id="48"></a>
## 48. H1三项收口、H2离线更正与最终候选续交（2026-11-09）

按[唯一完整任务](../ai/2026-11-08-prototype-host-blocker-decisions.md)完成既有授权的H1-F1/F2/F3、H2及受影响消费；不另开阶段。仍是 **experimental / additive_only 候选**，不是整体成熟首版、稳定ABI、完整VO/IME或长期性能认证。§46原汇报、§47指导修正及各版本旧绿线保留原身份。本节是执行结果，未代替指导对新增问题作修复授权。

### 48.1 实际修复与有区分力的证据

| 项 | 实际修改 | RED / GREEN |
| --- | --- | --- |
| H1-F1 | native enqueue保留double；clip位移不逐帧丢弃/llround，余量仍归共同CjguiPreciseWheelState。FIFO拒绝时取消瞬态并恢复accepted投影。 | 实际NSClipView回调中±0.25×8原为0、±0.5×8原被放大为8；修后对应±2/±4。队列满后last/clip保持accepted=20，未消费被拒位移。 |
| H1-F2 | clip、page、scroller请求共用实时live node、合格viewport、scope和session准入；sync在作用域失效时立即取消动画，不能被250ms等待短路。 | 受控实际回调探针中模态scope切换后原仍入队1项；修后0项、gesture=false、accepted=20；合法scope仍可滚动。 |
| H1-F3 | nativeSemanticBindingKey纳入viewport.viewStateIdentity；sameLayoutNode复用判定也核viewport身份，保证几何不变时仍运输新绑定；退休代理取消旧动画。 | 公共ScrollArea同node由A换B，旧动画/引用原使B=5。仅改key仍失败的原件保留；补通复用判定后旧回调不改B、B合法新滚动=10，移除后旧引用仍无副作用。 |

原始[实现级RED](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/native-red.log)、[native GREEN](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/native-green.log)、[公共消费RED](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/red4/cjpm-test-0.log)、[key-only失败](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/green/cjpm-test-0.log)、[最终2/2定向测试](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/green2/result.json)及[本轮相对开工源码差异](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/closure-source.patch)可复判。native探针还核顶部/底部、页步长和无范围。保留原NSScrollView窄适配；注释已改为本机探针观察，不作“所有macOS只有真实NSScrollView才可滚动”的全称保证。

`red`、`red2`、`red3`分别保留新增夹具的声明顺序/依赖声明、首场景未收敛等首错，不当产品RED；第一轮源码漂移guard记录也保留，之后冻结源串行运行。没有删断言或重投刷绿；无用的red3夹具失败二进制在源码与原日志保全、lsof确认无人打开后回收，两个有效实现失败二进制保留。

### 48.2 最终宿主与包外真实VO

| 实例 | 真实VO / accepted投影 / AX / 画面 |
| --- | --- |
| 宿主93562f03，PID25684 | VO导航到ScrollArea，VO+Shift+Down进入、VO+Shift+S、plain PageDown；退出滚动后VO逐项导航并读出“年度资料包024”。[字幕原件](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/host-read24_24.png)、[操作序列](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/host-read24.log)、[AX](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/host-record24-ax.txt)、[画面](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/host-record24-window.png)。内容8798、viewport672、max8126，accepted bar=0.05980802362786119对应offset486；record24实际y716与声明独立核算一致。 |
| 包外a6aa5d4f，PID37060 | 同样的真实VO协议，6次PageDown到bar=1，导航读出“巡检记录24·西侧风机”。[字幕原件](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-read24_3.png)、[操作序列](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-read24.log)、[AX](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-record24-ax.txt)、[画面](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-record24-window.png)。内容812、viewport135、max677，record24实际y619与offset677一致。 |

[独立viewport/AX核算](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/viewport-ax-correspondence.json)使用公共消费者的记录数、固定行高/间隔和原始AX位置；没有把native动画位置当accepted offset。以上是工具合成HID驱动**实际系统VoiceOver**，不是独立真人试用，也没有AX预滚动补造VO成功。

VO焦点不等于业务选择。包外底栏仍选记录1，公开[滚动前owner字段](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-owner-before.json)/[滚动后字段](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-owner-after-record24.json)均为owner8201，draft/applied/只读事实未变。宿主的旧恢复提示199与可见详情001另记§48.6，未把VO焦点24写成业务选择24，也未把结构`show`误写成typed owner读回。

当前字段选择重新按语义“设备名称”定位：VO进入字段后plain Shift+Left，实际[范围3,1、所选“泵”](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-name-selection-after.txt)、[VO“泵，已选择”字幕](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-name-selected-vo.png)，与[owner8201字符串“东侧水泵”](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-owner-after-selection.json)的UTF-16片段一致。没有AX设选区；§46的AX设值证据仍只算旧AX回归。只读帮助/值/禁用±、公开move续接、脏文档保存及正常cmd+w旧链按原版本复用；本轮也读到只读serial/cycles与禁用±，未重复写入矩阵。

短静置按实际提交相关计数核：宿主约3.2秒内accepted/submitted scene/submittedFrameIndex均254→254，pending=0；包外accepted/submitted scene340→340，submittedFrameIndex344→344。原始[COST窗口一](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/host-short-idle.json)/[窗口二](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-short-idle.json)保留。native cadence文件未得到commit记录，未用“0→0”充当收敛证明，也未重跑load5。

普通滚轮在VO关闭后进入同一包外viewport，bar1→0.7031019202363368；[合成HID](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-wheel-off-hid.log)、[前](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-wheel-off-before.txt)/[后](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-wheel-off-after.txt)分开保留。VO开启时较早的一次轮事件没有观察到推进，不算通过。随后[AX端值请求](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/consumer-boundary-ax.json)1.5→1、-0.5→0；这些是VO成功**之后**的AX边界回归，未冒充VO动作。agent-desktop对透明proxy的物理命中证明失败及包外窗口枚举限制保留，改用已观察的Swift AX与精确CGWindowID取图，未为工具扩修框架。

四个自有正常实例（assets/settings/materials/包外）均exit0、forced=false，端点由应用清除；[生命周期核对](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/closure-checks.json)。VO=false、字幕关闭、临时打开的系统设置窗口关闭；Quick Nav、系统输入法及剪贴板未修改，原有vo_native/教程等归属不明实例保留。

### 48.3 H2：同域完整身份离线复算

只改`work/prototype-host-20261108/tools/analyze_present.py`与其离线测试/说明，不改渲染调度、GPU归属或公共业务协议。停止使用`abs(observed_absolute-submission_relative)`与`estimate−5ms`；不再给跨域“input→present”估计。使用同一原cadence中`session/generation/scene/frame`的present_enqueued、commit、presented，实际检查drawable request/layer/size/format、submit/callback ID及可用标记、正值raw presentedTime和时间顺序。

窗口公开session标识与native token是独立分配器，不能以数字后缀相等作映射。本原件实际检查为一个run-owned公开窗口与一个native stream；限定此单窗口关联，存在多stream/generation时拒绝不明映射。重复帧只在**同一carried scene**内取最早有效presentedTime，保留全部重复/无效行；不取其他scene补绿，也不取最短延迟挑样本。

| 原60项 | 更正结果 |
| --- | --- |
| 窗口有效30 | native commit→exact-scene present p95=25.667125ms |
| 公开有效13 | 同域p95=29.235459ms，仅13条子集 |
| 合计有效43 | p95=26.193501ms，max=29.235459ms |
| 其余公开17 | exact-scene present为0/invalid，仍未证，未批准GPU修复 |

[更正输出及逐项身份](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/h2-corrected.json)、[原数据/旧分析身份清单](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/h2-inputs.json)、[5项离线RED](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/h2-red.log)/[GREEN](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/h2-green.log)保留；原错误`present-association.json`未覆盖。旧24.938ms跨域估计撤回。43子集不等于全60或系统投递端到端p95，不判严格16/32ms门。

首交互first-interaction-5约1.195s同域accepted接收上界与唯一draft、本轮之前30+30局部p95、load5和材料/深色/保存计划/A–F已闭合成果均按原身份复用，未重新采集。旧失败、冷缓存/真人/完整IME/光子级与长期稳定未证边界保持。

### 48.4 最终源码、SDK、ZIP与实际构建身份

| 产物 | 实核身份 |
| --- | --- |
| native源码 | `afb1beaa1dbce6b6403a175df3e58f368f66572be33a7cde77191a4042753f28` |
| common window源码 | `abe4ee8b699dcfc08b8f74c61621816f1969afc4a672276e52926d559f80972e` |
| 宿主签名后bundle可执行文件 | `93562f0305ef6c4a512b93580346ee703225a1dc38154367e4a549efe6922444`；native `4f53174c6f3f2d0a6aceab7530ace0b0acd8deba785eee82d3e785f984bbfeaf` |
| 包外签名后bundle可执行文件 | `a6aa5d4fe71ad4ec360bbb2ca620f41f9c3b0a50e6416933a298d5ac2e3ae938`；native `4c251896cc497f8151bbfd2fb1ed96f178aae4d8ef59dc9faca089b7efea1172` |
| 实际交付ZIP | **`156c30604a69953a275a75710c90494750a6131565548204e57d7fc75324f06f`**，6,455,934字节；[下载本地ZIP](../../work/prototype-host-20261108/CJGUI-macOS-Candidate.zip) |
| source-lock | `9345b9f1fbf14edad7d4168e6d753022a7adc8e46d9ed35d2159f66eb2a78588`，closure/613 inputs |
| exported content | `9feb19cbede8ae65c18f1d765400b39350ed39df4b87a376d64d79b4d618e9da`，640清单文件 |
| source content | `38eb5e8ddb18f626258899ac821dd921a0255772be64afda7a2fa2b221a71e47` |

[最终构建身份](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/final-build-identities.json)：宿主483源/465准备源/2 native、包外458/440/2全部当前哈希匹配，testing=false，签名校验通过。[导出身份及命令](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/sdk-final-identity.json)和[临时目录finally回收](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/sdk-export-cleanup.json)独立保留。实际ZIP640文件、当前源613输入、包外从该ZIP安装的640文件再次核对通过；包外framework路径为自己的SDK根，未指回checkout。保留旧b0276dde ZIP为`CJGUI-macOS-Candidate-b0276dde.zip`（不含H1）；旧49c5997d因既有消费者/复判用途继续保留。

根`cjpm build --skip-script`、宿主与包外构建通过；`git diff --check`、public声明、native头、受保护路径/禁止行为范围核对通过。runtime_state.cj与根cjpm.toml未改，无新公开ABI或外部GUI依赖；新增测试hook在两个production archive中均不存在。图工具覆盖未能定位这些目标，以源码/真实回调/公共消费者及构建补证，没有把UNKNOWN当图验收通过。未改skill、未stage/commit/push或发布。

最短打开（工具链未在PATH时先source AGENTS所列envsetup）：

```sh
cd /Users/jiangxuanyang/Desktop/cangjie
./runtime/cjgui/examples/prototype_host_app/run.sh --project "$PWD/work/prototype-host-20261108/evidence/candidate/projects/settings"
```

同一最终宿主还实际打开assets和materials，经正常公开客户端读回：settings5字段/owner2000、materials3字段/owner3000，均正常关闭；[同二进制三原型](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/three-prototype-final.json)。原有完整preview/save/load/apply/exact、正常输入/模型同owner、有草稿重排、切项目旧请求拒绝、新快照续改、undo/redo和保存重开按未变版本范围复用。只补受影响的滚动/AX/绑定及公开发现读回，没有重开全矩阵。

包外现有应用入口：`/Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer/App/run.sh`；本轮使用私有`consumer-work.cjgui-ui`，未覆盖用户文档。SDK独立建项/支持范围沿包内公开说明与既有创建器，不新建第二个消费者。

### 48.5 HTML与反馈回接

本轮不改HTML/CSS/数据要求；新HTML viewport1280×820对应实际宿主drawable2560×1640/DPR2的逻辑内容区，外窗高度852。原788高补图保留为先前尺寸条件，不冒充匹配尺寸。记录24可见、详情仍显示001的受影响滚动态，见[对照新增§12](2026-11-08-prototype-host-html-comparison.md#html-h1-scroll-20261109)。原1280/960/720、亮暗、空态与未变原型链按原版本复用，不作像素级或速度优劣结论。

| issue | 本次event / 三状态 |
| --- | --- |
| H1 `e855e4908dc44be1bf33ae6283fde687` | `6d972056e3714f87bb900520ebdf9bcd`；source_fix=fixed，sdk_inclusion=included，consumer_verification=本节真实消费通过，[show](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/feedback-h1-show.json) |
| H2 `40c23dc27eb94ec289816eca40044294` | `387e6a6d29714896bb1a6c0523423ca5`；分析工具fixed，SDK not_applicable，同原日志offline verified，[show](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/feedback-h2-show.json) |
| 新观察 `0708aba456e24778902df9cf4b6639eb` | `ba6d0d565f8f4f3894a876ba59f369f8`；source_fix/sdk_inclusion均unknown，observed_only/needs_evidence，[show](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/feedback-new-show.json) |

2026-11-09T14:23:30.109111+08:00实际list为 **22 issue/107 event，errors为空**（[原件](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/feedback-final-list.json)）；complete只表示读取完整，不是全部已修。

### 48.6 未证项、新观察与空间账

新恢复观察只记录不修：[原件](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/host-restored-selection-facts.json)表明复用session保存`selected=asset-0199`及title199/quantity42，而宿主初始和VO后生成详情显示001/8。关闭前没有取得typed owner映射，不能凭结构show或画面认定框架写错owner；已保存文档固定owner、会话恢复与应用接线尚未区分。该项不在H1/H2新增修复白名单，交指导后续热复核，不自行扩修，也不把HTML业务选择状态称完全等价。

17个invalid present、旧probe2/participant_prepare、焦点计数增长归因、完整IME/真人、冷首次输入、长期资源及其他平台仍保持既有未证/未修边界；本轮不新增这些工程。实际通过范围不等于整体成熟首版通过。

空间（[原账](../../work/prototype-host-20261108/evidence/candidate/h1-h2-closure/space-final.json)）：本轮新证据留存约 **128.4MiB**，新增反馈事件约 **0.7MiB**；替换后的当前SDK约25.1MiB、ZIP约6.16MiB（替换量不冒充净新增）。复用两个应用构建目录及native输出；测试图、SDK导出/安装临时副本和冗余夹具二进制累计实际回收约 **1016.9MiB**。宿主剩余约 **234.76GiB**，低于10GiB新增保留预算且峰后远高于20GiB余量。保留有效RED/GREEN原件、最终SDK/ZIP、两个正常消费者当前构建、最近b027基线和原有49c复判交付；没有清理其他线/用户存量。

## 49. 指导验收§48并热复核恢复绑定观察（2026-11-09）

**H1/H2及最终SDK在已交付范围内验收通过。** 本次指导核源码差异、原始RED/GREEN、真实VO字幕/操作记录、短静置计数和当前产物，并独立离线复算；未新运行GUI、产品构建或修改产品代码。[复核原件](../../work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-48-20261109.json)保存身份与精确源码片段。

- H1：double位移、统一AX准入、viewport identity及sameLayoutNode复用修正与测试相符；保留key-only失败证据。宿主与包外的record24字幕原件确实读出目标；“泵，已选择”和range3,1与owner字符串一致。提交相关计数254/344均稳定，未拿缺失cadence的0→0替代。
- H2：原数据哈希保持，指导不调用被测analyze()作为期望，独立同域关联得到43有效/17未证，p95=26.193501ms、max29.235459ms。认可脚本更正；仍是有效子集的native commit→present，不是全60或输入端到端p95。
- 实际ZIP156c3060…的640文件、锁9345b9f1…的613来源与包外安装目录一致；宿主93562f03、包外a6aa5d4f的源/准备源/native与provenance匹配。H1/H2和SDK不再作为待办，不重复导出或整矩阵验证。

**新观察0708aba4归宿主恢复接线，批准H3最小应用修正。** PrototypeSession先构造PrototypeRegionBinding，current FormBinding捕获初始001；controller随后恢复session，domain.restoreSessionState选择199，但prototypeRestoreSessionPayload在成功后仅setDark，没有rebind。详情字段/操作owner/Apply/Cancel仍委托旧current，而正常SELECT_RECORD已经用同一个rebind完成切换。实际ui/main.json只有字段引用，没有固定owner属性，故本样本“文档故意固定001”归因不成立。`currentOwner()`又直接读domain，单看它会掩盖内部current未换绑。

精确入口：prototype_session.cj:20/263，prototype_controller.cj:72/681，prototype_runtime.cj:435，prototype_domain.cj:872，公共FormBinding的fieldOperationResourceId/draftText。已有画面与session观察证明差异，源码解释漏接；指导未新取得typed写入链，不据此宣称曾发生跨owner写入。执行者按[同一完整任务§9.1](../ai/2026-11-08-prototype-host-blocker-decisions.md#91-h3已批准恢复选中对象后同步详情绑定)先保全实际恢复入口RED，再在整体恢复成功、启动文档/公开消费前复用现有rebind，正常重启验证选择/详情/typed owner一致，编辑/Cancel/Apply只写199、001及其他草稿保留，非法恢复保持旧绑定。不清空session、不人工补点选、不修改UI文件掩盖、不改框架或新增公共协议。

该宿主不在SDK613输入闭包，H3只更新宿主候选与应用验收，不触发SDK重导、包外重建、VO/30+30/load5/全HTML重跑。完成此已认可应用问题后集中交付，其他未知问题仍只记录；不自动把17未证present或旧probe2/焦点问题扩为新工程。

反馈已追加H1指导验收`c61bfc52db614f0086f3f52757f5422c`、H2`3baf07a43c654e46822dfcd41185fc70`、H3归因/授权`ce21c230f7984dda9386de5f82cd346c`。H3的no_framework_action表示不改框架内核，宿主修正明确获批；source_fix=应用待修、sdk_inclusion=not_applicable、consumer_verification=旧观察与源码已归因/修后待验。list为22 issue/110 event、complete、errors为空（14:50）；[原件](../../work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-48-feedback-list.json)。文档/链接、产品源码未变和本次小体积证据空间见`hot-review-48-checks.json`。

## 50. H3恢复绑定宿主修正、冷重开与全对象状态保全（2026-11-09）

**准据与范围。** 按[§9.1](../ai/2026-11-08-prototype-host-blocker-decisions.md#91-h3已批准恢复选中对象后同步详情绑定)与§49裁定，本项只修宿主应用恢复接线：不改框架/native/公共协议/SDK，不重导SDK、不重建包外应用、不重跑VO/性能/全平台矩阵；不清空session、不改写UI文件、不人工补点选择。

**根因与最小修改。** `PrototypeSession`构造`PrototypeRegionBinding`时`current` FormBinding捕获初始001；`prototypeRestoreSessionPayload`在`domain.restoreSessionState`成功后只`setDark`，未换绑，详情字段/操作owner/Apply/Cancel仍委托旧current，而正常SELECT_RECORD已用同一`rebind`。修正在[prototype_runtime.cj:447](../../runtime/cjgui/examples/prototype_host_app/src/prototype_runtime.cj#L447)：整体恢复成功后、`setDark`前调用既有`session.binding.rebind()`，仅此调用与一行注释；失败路径与旧domain/旧绑定不变。新增[prototype_restore_binding_test.cj](../../runtime/cjgui/examples/prototype_host_app/src/prototype_restore_binding_test.cj#L40)两例：实际恢复入口的owner/字段操作owner/草稿/已应用/全对象版本与逐字节重存；非法payload拒绝后保旧选择、草稿、版本与绑定。

**定向RED/GREEN。** 首次RED因fixture插值转义编译失败，完整原件保留但不计有效RED；修正fixture后同一实际入口取得有效RED：[red-runtime日志](../../work/prototype-host-20261108/evidence/candidate/h3-restore-binding/red-runtime/cjpm-test-0.log)打印`H3_RESTORE domain=3198 binding=3000 detail=draft-0`，换绑用例失败于`3000 != 3198`，拒绝恢复用例已通过。修正后[green-final日志](../../work/prototype-host-20261108/evidence/candidate/h3-restore-binding/green-final/cjpm-test-0.log)为`domain=3198 binding=3198 detail=draft-198`，H3 2/2通过；[会话载荷过滤](../../work/prototype-host-20261108/evidence/candidate/h3-restore-binding/green-final/cjpm-test-1.log)4/4通过，失败0。GREEN源码快照与测试文件哈希见`source-inputs.json`（测试文件`53e3701e…`，当前一致）。RED保留测试二进制`8513340f…`，普通native归档前后`397c80d4…`未变。

**正常窗口与公开消费。** 新宿主`edd9b765…`（39,227,712字节，编译器`bin/main` `259d08f1…`、native `4f53174c…`、build key `c54d52c1…`）经`run.sh --project`私有200记录项目正常入口打开；原会话selected=asset-0199、UI文档不改，冷重开不补点选择，状态为“已恢复原型会话”，公开typed快照与AX画面owner均为3198。恢复后立即保存与恢复前会话逐字节相同（200对象无差异，未隐式Apply）；生成区Cancel与Apply各只改变asset-0199，其余199对象`draft/applied/fieldVersions/draftVersion/appliedVersion`全等；asset-0001/0050草稿与版本保留（draftVersion 2、appliedVersion 0），asset-0199 Apply后8/8。最终保存再冷重开仍为3198且再保存逐字节相同。输入为`agent-desktop --headed`按PID物理合成键入与生成动作/保存的AXPress，非真人/IME/VO。

**本轮独立复算。** 直接解码五份`.cjgui`会话快照逐对象比较：seed→恢复后重存0差异且字节相同；恢复→Cancel仅asset-0199；Cancel→Apply仅asset-0199；Apply→最终重存0差异且字节相同；001/050仍为未应用草稿，结论与执行证据一致。[verification.json](../../work/prototype-host-20261108/evidence/candidate/h3-restore-binding/verification.json)与[final-identities.json](../../work/prototype-host-20261108/evidence/candidate/h3-restore-binding/final-identities.json)保留原始身份、生命周期与边界。

**反馈与复用边界。** 同一issue `0708aba4…`追加event `0f0864…`：`source_fix=fixed`（宿主应用，仅`prototype_runtime.cj`）、`sdk_inclusion=not_applicable`（`prototype_host_app`不在613输入闭包，ZIP156c3060、锁9345b9f1、包外a6aa5d4f均未变）、`consumer_verification=passed within H3`；triage仍为`no_framework_action`，其含义是不改框架内核而非“不修宿主”。真实输入与公开读回原件见[observation](../../work/prototype-host-20261108/evidence/candidate/h3-restore-binding/h3-feedback-observation.json)。另记独立观察issue `e42ea6a4…`/event `2d3eabd5…`（列表/状态投影策略）仅记录未修。H1/H2、SDK、包外应用与旧VO/性能/HTML原件按原身份复用。

**未证边界。** 本项不是真人/IME/VO/性能新验收；H2的17个present未证样本、旧probe2/焦点计数、完整IME/长期资源及其他平台保持原边界。H3快照之后并行H4线继续修改宿主布局（main/controller/runtime），不属于H3产物；H3身份以GREEN归档、`host-baseline`副本与上述哈希为准，不将后续构建冒充H3结果。

**空间与收尾。** [空间账](../../work/prototype-host-20261108/evidence/candidate/h3-restore-binding/space-account.json)：新增留存约64.7MiB（证据、反馈事件、测试控制文件），复用宿主target 225.2MB与准备源37.7MB；red/red-runtime/green/green-final四个临时测试图已finally退役（累计回收656,928,768字节分配空间，非净增/非APFS差值）；宿主各运行实例exit 0、descriptor已退役、无残留宿主进程，SDK/包外/其他线未触碰；当时宿主剩余251,958,460,416字节（约234.7GiB），满足原10GiB/20GiB规则。`h3-test-work`仅留owner/prepared/build.lock控制数据；`host-baseline`保留H3候选`edd9b765…`副本以备复判。

## 51. H4整窗工作区与默认承载配方（2026-11-09）

**准据、归属与改前事实。** 按[§15](../ai/2026-11-08-prototype-host-blocker-decisions.md#15-h4新增授权整窗布局与默认原型配方)与用户改前[截图](../../work/prototype-host-20261108/evidence/whitelist/review-followup/layout-whitespace-before.png)/[UI快照](../../work/prototype-host-20261108/evidence/whitelist/review-followup/layout-whitespace-before.ui.json)：`buildUiInner`已给工作区`growY`，侧栏/详情已有交叉轴STRETCH；`buildRegionArea`统一把生成内容包进外层ScrollArea，而生成根/card只声明`growX`，因此按自然高度组织，底部留白来自缺少有界工作区配方，不是布局引擎违反自然高度契约。本项按宿主布局选择与生成配方易用性处理，未虚构“旧引擎算错高度”的RED，也未改框架测量、滚动契约或全局主题。

**实现。** [buildRegionArea](../../runtime/cjgui/examples/prototype_host_app/src/prototype_controller.cj#L470)读取生成根既有`style.growY`：`>0`时把根直接放进有界剩余区域（填充工作区），由文档内部单一`growY` ScrollArea增高、操作行作为其普通兄弟；`=0`时保留原外层ScrollArea自然高度承载，旧项目缺省不变。默认assets配方在[ui/main.json](../../runtime/cjgui/examples/prototype_host_app/projects/assets/ui/main.json)声明root/card`growY`、`asset-detail-scroll` `growY`、form `maxWidth=680`/`alignX=stretch`、动作行`fixedWidth=318`；[README](../../runtime/cjgui/examples/prototype_host_app/README.md#L110)给出“内容自适应/填充工作区”的选择规则与结构，settings/materials保留各自自然高度。未改框架、native、公共协议或SDK。

**有限验收。** 同一宿主实例（H4构建：native `4f53174c…/50cbd4ea…`，PID 89290，window `w-6013`）按实际contentBounds/节点几何读取：

| 窗口 | 内容区 | 详情滚动区 | 操作区 | 底栏 |
| --- | --- | --- | --- | --- |
| 1280×660 | 1280×628 | 938×425（y183），侧栏列表256×452 | 应用/还原y620，110×32在窗内 | y676 |
| 1280×877 | 1280×845 | 938×642，侧栏列表256×669 | y837，110×32在窗内 | y893 |
| 720×850 | 720×818 | 668×575（列表以“显示列表”切换） | y810，110×32在窗内 | y866 |

[短窗](../../work/prototype-host-20261108/evidence/candidate/h4-workspace-layout/wide-short.png)、[高窗](../../work/prototype-host-20261108/evidence/candidate/h4-workspace-layout/wide-tall.png)、[窄窗](../../work/prototype-host-20261108/evidence/candidate/h4-workspace-layout/narrow-720.png)、[亮色200列表](../../work/prototype-host-20261108/evidence/candidate/h4-workspace-layout/verify-20261109/light-1280x660-list200.png)、[暗色代表](../../work/prototype-host-20261108/evidence/candidate/h4-workspace-layout/verify-20261109/dark-1280x660-list200.png)为实际画面；短内容筛选199与清筛选200条滚动分开检查，列表/详情独立滚动，选中199保留。公开模型入口`set_property asset-detail-form.maxWidth=680`被接受为v2、`exact_readback=true`，baseline `a43f25ee…`→submitted `1d65001b…`；[receipt](../../work/prototype-host-20261108/evidence/candidate/h4-workspace-layout/verify-20261109/model-receipt.json)、[apply](../../work/prototype-host-20261108/evidence/candidate/h4-workspace-layout/verify-20261109/model-apply.json)与导出/保存/冷重开布局一致，未隐式Apply。

**身份更正。** 上表三尺寸来自H4构建；最终候选`d3b6bc10…`（native `8b28c285…`）包含相同宿主布局并叠加H5行尺寸/主题色，在1280×877重跑画面与操作区一致，660/720未在该二进制重测。该区分已追加[H4反馈事件](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/h4-identity-correction.json)（`004f56dd…`），不把最终候选倒写成三尺寸测量来源。1280×877的请求高度940因窗口工具回TIMEOUT/`delivered_unverified`，实际窗口按画面877记录，未把未验证的resize结果当通过。

**反馈。** issue `cf62b02be7c343519a20c6faec7f4994`：create `61e468be45fc403b9f8c95b4013f011a`（改前事实与责任），closure `5e8c29b233dd40b3872bb5341ccc8457`（实现与有限验收），identity correction `004f56ddbbce4f40809fd071008061d1`；`source_fix=fixed(宿主)`、`sdk_inclusion=not_applicable(prototype_host_app不在613闭包)`、`consumer_verification=passed(实际窗口+公开模型入口)`，triage为`usability_improvement`。

**边界。** 短内容允许合理留白；未做像素级HTML复刻，未重拍全尺寸全主题矩阵；主题/控件高度未改；H1/H2、SDK、包外及性能矩阵按原身份复用。

## 52. H5列表行尺寸、按钮内容对齐、深色行色与同源SDK重导（2026-11-09）

### 52.1 H5-A：列表两行使用真实按钮行框

**责任与修改。** BUTTON文字上下各有6pt内部留量，旧配方外行42/标题22/次行16使11pt次行仅余4pt文字框，截图为半截次行；`style.padding=2`不改变这段内部几何。宿主在[prototype_session.cj:11](../../runtime/cjgui/examples/prototype_host_app/src/prototype_session.cj#L11)统一`TITLE=28/META=26/ROW=58`，[虚拟列表行步长](../../runtime/cjgui/examples/prototype_host_app/src/prototype_controller.cj#L468)复用同一`PROTOTYPE_RECORD_ROW_HEIGHT`；标题与次行仍是同一`SELECT_RECORD`和record resourceId的BUTTON，整行可点，未退回label、未缩字体、未全局改按钮内边距。

**验收。** 筛选199单条记录与清除筛选后200条滚动列表的完整可见行均完整显示标题/次行，视口边缘只出现自然部分行；[筛选199](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/filter199-dark-1280x877.png)、[滚动200](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/list-scrolled-dark-1280x877.png)为实际画面；分别点标题/次行均经公开状态读回选中同一对象（197/198），底部“已选”同步，AX完整名称保留，长内容仍省略。最终候选AX树另存[final-host-ax.json](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/final-host-ax.json)。反馈issue `46afd5f28b7e4f5db94af8818ab810c4`/event `10701f141f8547468b5fdfb1cbc3ae7f`；`source_fix=fixed(宿主)`、SDK not_applicable、consumer passed。

### 52.2 H5-B：普通按钮内容对齐的最小公共事实

**指导复核更正（2026-11-09，详见§53）：以下保留执行者当时报告；“宿主/包外均居中”“换对齐不会复用旧位置”的结论未通过复核。SDK来源、字段运输与region测试证据继续按实际范围保留，H5-B须继续收口。**

**公共事实。** `CjguiComposableUiStyle`新增`contentAlignX/contentAlignY`（[composable_ui.cj:976](../../runtime/cjgui/src/composable_ui.cj#L976)，默认START，只接受START/CENTER/END），语义是控件**内容**对齐，区别于定位整个节点的`alignX/alignY`。命名样式转发、主题动作配方、生成样式重建、三处节点投影、Cangjie/native镜像与尾部ABI全部贯通：[named_style](../../runtime/cjgui/src/composable_ui_named_style.cj#L60)、[theme roles](../../runtime/cjgui/src/composable_ui_theme_roles.cj#L139)、[generated](../../runtime/cjgui/src/composable_ui_generated.cj#L7023)、[projection](../../runtime/cjgui/src/composable_ui_window.cj#L11584)、[renderer session](../../runtime/cjgui/src/runtime_renderer_session.cj#L752)、[header](../../runtime/cjgui/native/cjgui_internal_renderer.h#L847)。ObjC侧按`contentAlignX`设置段落对齐、单行BUTTON按真实行框在内容区垂直居中，并在文字属性冻结/绘制/fallback共用同一事实（[renderer.m:12542](../../runtime/cjgui/native/cjgui_internal_renderer.m#L12542)、[14921](../../runtime/cjgui/native/cjgui_internal_renderer.m#L14921)、[14980](../../runtime/cjgui/native/cjgui_internal_renderer.m#L14980)）。

**默认与缓存。** HIG primary/secondary/quiet动作配方明确CENTER/CENTER，列表行、标签和输入保持START，手写与生成动作默认得到居中；未声明样式保持旧行为。区域缓存签名、`sameStyle`、`scrollOriginTextStyleMatches`、生成style继承均包含新事实，换值/换尺寸不会复用旧位置。[定向测试](../../runtime/cjgui/src/composable_ui_declaration_completeness_test.cj#L418)以结构化签名缓存构造“复用非0、改对齐后复用0”反例，经[testing-link runner](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/content-align-cache-test-2/cjpm-test-0.log)通过（PASSED 1）；首版keyed-region写法因该路径不扫描后代声明而失败，保留为方法更正说明。

**实际消费与画面。** 宿主“深色”短中文、长中文动作、生成英文/数字动作“Reset 42”均居中无裁字，列表保持左对齐、输入不变；[亮色动作行](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/light-after-row-color-fix-1280x877.png)、[暗色生成动作](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/dark-generated-english-action-1280x877.png)；点击生成动作与主人读回成立，公开模型入口accepted v2 `exact_readback=1`（[plan](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/model-plan-english.json)）。反馈issue `8dca7fed997b494ea0c29516126f326c`：create `3526a78c2b5a40829025ce679d95576e`、SDK/包外 `622417fb4315418d87b8547c603476ad`。

### 52.3 深色列表行文字颜色（用户复核后新增）

**事实与修复。** 用户暗色截图红框指出列表行文字异常。旧`buildRow`把未选中标题写死黑色、选中标题写死深蓝、次行写死55%黑、选中底写死14%蓝；在`#2D2D2D`卡片上对比度仅约1.52:1/1.34:1，暗色下近黑文字几乎不可读。修正为完全由主题角色派生（[prototype_session.cj:219](../../runtime/cjgui/examples/prototype_host_app/src/prototype_session.cj#L219)）：标题用`body.textColor`、选中标题用`heading.textColor`、次行用surface与正文75%混合、选中底用surface与primaryAction 14%混合；不改框架、默认主题或列表选择语义。

**验证。** 用户原图与修复前后对照：[暗色改前](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/dark-1280x877.png)、[改后](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/dark-after-row-color-fix-clean-1280x877.png)、[选中行](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/dark-selected-row-after-fix-1280x877.png)、[亮色回归](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/light-after-row-color-fix-1280x877.png)；暗/亮实际窗口下标题与次行清晰，点击行仍选中并公开读回，详情/按钮未受影响。反馈issue `6871ed70e0dc460491ce0d69c4c433ac`/event `7835a08c78e44943b21c5598e3b43b73`；`source_fix=fixed(宿主)`、SDK not_applicable、consumer passed。该缺陷由用户复核发现并明确授权修掉，未扩大为全局配色改造。

### 52.4 同源SDK重导与包外消费

H5-B进入SDK输入，按§11统一导出，未逐补丁导出：

| 产物 | 实核身份 |
| --- | --- |
| 新交付ZIP `CJGUI-macOS-Candidate-h5.zip` | **`8f24128363ded994b2870d69cbb43aa1a45e710783af6a1b83fd9a673928dddb`**，6,497,131字节；680条目=641文件+39目录，manifest 640文件+根source-lock |
| source-lock | `e17b4228c9d21795f448acfc81ec0e3abbcaed31c9860dc89f6d04d82ff3c217`，closure 613、drift none |
| exported content | `ab9a3cc83a9b9c72dc49efa8cf570211889eed6566faecd6e0dc29dbf8b1a8ee` |
| 最终宿主bundle | `d3b6bc10d5fdf0f715742ed6c586ad55aaf47f3903c5ecc168b496746c1ef9f1`；native `8b28c28563d51ef18e2be490920e1e0e02409e0a4eaf1785d28b04a66b297f85` |
| 包外InspectionCandidate | `f31309765978cbf84d98171eff12c1cd942eb0ada5aafa30c63e704905be8c2c`；native `ca735e65df6807e98c5765a117d3260aed45be0dab9ab20c65c1831d7918042b` |

[首次导出](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/sdk-export.log)为无锁中间导出（639文件），[锁定导出](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/sdk-export-locked.log)从同一source-lock重放为640文件/closure 613；交付ZIP取自锁定目录，旧未锁目录仅保留lock后退役。包外应用从新SDK重建并实际消费普通动作：`main.cj`改用`theme.actionStyle(primary: true).boundStyle()`/`actionStyle().boundStyle()`，按钮文字居中、点击“应用”写入owner；[构建日志](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/ext/build2.log)、[改前](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/ext/consumer-before.png)、[应用后](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/ext/consumer-after-apply.png)、[动作样式](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/ext/consumer-actionstyle-applied.png)。包外framework路径为自己的SDK根，未指回checkout；`156c3060`与包外`a6aa5d4f`只作旧基线保留，不标为含H5-B。H5-A/H4/行色为宿主变更，不进入SDK闭包。

### 52.5 反馈、未证边界与空间

本轮四个issue/七个事件：H4 `cf62…`(`61e468be…`/`5e8c29b2…`/`004f56dd…`)、H5-A `46af…`(`10701f14…`)、H5-B `8dca…`(`3526a78c…`/`622417fb…`)、深色行色 `6871…`(`7835a08c…`)。追加后实际`list`为**28 issue/120 event、status complete、errors为空**（[原件](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/feedback-h5-final-list.json)；读取完整不等于全部已修）。H1/H2、VO record24、30+30/load5、旧SDK/包外及未变HTML按原身份复用，未重跑。H5-B只改macOS共享实现/当前SDK，OHOS/Windows/Linux适配副本未动；测试是结构化签名缓存反例，不声称覆盖所有region路径。包外窗口无法经agent-desktop AX枚举，改用System Events与精确CGWindowID取图，未据此扩修框架。候选仍experimental/additive_only；未提交/发布、未改skill。

**口径更正（2026-11-09，见§53.1）。** 本节保留执行当时报告与旧图，不改写旧证据。§52.2/§52.4依据当时构建曾写“宿主/包外按钮已居中、换对齐不会复用旧位置”，复核发现旧宿主/旧SDK实际仍靠左，native纹理key与持留布局也未携带对齐；这些结论不成立，实际修复与证据见§53.1。§52.5所列四个issue实为7个事件（H4三、H5-A一、H5-B二、深色行色一），此前若引用为“4 issue/6 event”应更正为7；指导复核追加后为29 issue/122 event，本次追加修复与ZIP打包更正事件后为29 issue/125 event。

[空间账](../../work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/space-account.json)：本轮新增留存H4证据6.2MiB、H5证据45.6MiB（锁定SDK、ZIP、测试源快照与画面）、四个反馈issue约19.0MiB，合计约70.8MiB；无锁首次SDK导出副本25MiB在ZIP/manifest/lock核验一致后退役（保留`source-lock.json`）；用宿主/包外构建target与H1/H2/H3证据，不重复计入。宿主剩余234.2GiB，新增远低于10GiB预算且峰后远高于20GiB余量；自有宿主PID 37595、包外PID 48146在证据保存后正常退出，descriptor随应用退役；PID 94798为先前归属不明实例，未触碰。

<a id="53"></a>
## 53. 指导集中复核：保留H4/H5-A，H5-B继续收口（2026-11-09）

本次只做同版源码、产物身份、原图与结构化反馈复核，未启动GUI、重建产品、修改产品源码或skill。完整实施入口仍是[唯一任务§17](../ai/2026-11-08-prototype-host-blocker-decisions.md#17)，§3.1的目标内自主修复规则不变；没有新增逐项批准门。

**已核实。** SDK ZIP `8f241283…`及锁`e17b4228…`与§52相符，ZIP/导出目录/包外安装目录的640个manifest文件逐项匹配。宿主484源/466准备源/2原生库及包外458/440/2的当前哈希均匹配各自构建记录，testing=false；bundle分别为`d3b6bc10…`与`f3130976…`。源闭包613项中610项与当前checkout一致，差异仅skill的入口、diagnostics、layout-theme三个文件；这不否定已冻结包的内部一致性，但不能把旧锁写成当前源零漂移。其他任务的skill改动不得回滚，下一次导出冻结真实输入。详见[复核原件（含源码片段/哈希）](../../work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-h5-delivery-20261109.json)。

H4承载/配方及H5-A行高、列表主题色按原身份保留：实际查看H4宽短窗及H5亮暗原图，列表行内裁字与暗色可读性确有改善。H4三尺寸不是最终宿主三尺寸重验；H5部分图使用旧私有UI自然高度，不能替代新H4默认配方结果。

**H5-B未通过整体收口。** 指导实际看过§52引用的宿主亮暗图、生成“Reset 42”和包外`consumer-actionstyle-applied.png`，短按钮文字仍明显靠左。`cjguiComposableUiStyleWithPaint`、`cjguiComposableUiStyleWithTranslation`重建时遗漏`contentAlignX/Y`；normal交互resolve也走前者，确定会将CENTER恢复为START。另有公开纵向END被接受但native只处理CENTER；native纹理key/持留布局复用没有新对齐事实，需定向反例确认实际失效，现有region缓存PASSED 1不能代替。`!prepared`分支的对齐消费亦需核可达性。具体源码责任、反例和有限验收已写§17，修复应落共用归属，不让每个应用绕开交互样式。

**新显示观察。** `dark-selected-row-after-fix-1280x877.png`里列表已可读，但详情checkbox/“启用”仍接近背景；公开assets和验收私有UI均未声明该booleanInput的命名style。尚须区分实际enabled/availability与主题默认/应用配方责任，已交执行者按§3.1自行核实修复，不预判框架硬缺陷。

**反馈回接。** H5-B issue `8dca7fed997b494ea0c29516126f326c`追加`ad4c05b4d6134c28aef9f2b857fea102`，更正`622417fb…`的居中通过结论；包来源与旧动作写入证据继续保留。暗色详情新issue `3915db8a6ad04e5a84aae18aa824adc0` / event `50fde7426e294851a828b05ce8eeafd6`，needs_evidence仅表示归属待核，不要求再批准。实际[list](../../work/prototype-host-20261108/evidence/whitelist/review-followup/feedback-after-h5-review-20261109.json)为**29 issue/122 event，complete，errors空**。§52.5所列4个issue实际含7个事件，原“6个”计数应更正。H5-B本次新修正尚未实施/入包/消费；三种状态按此记录，不能沿用旧fixed/passed覆盖新反例。

**接续与空间。** 继续同一个目标：修复制保真/END语义，核native缓存边界，处理暗色详情，统一同源SDK和包外受影响消费，实际看图后集中交付。不重开未受影响的VO、性能或全尺寸HTML矩阵。指导新增两条反馈（含原图独立保全）约1.29MiB，另有小型JSON/文档，合计不足2MiB；释放0，无新增构建树/SDK副本/进程，宿主实测余234.33GiB。未stage/commit/push、未发布；候选仍experimental，H5-B未完成。

### 53.1 执行接续：H5-B闭合、暗色启用与同源SDK（2026-11-09）

本节执行交付已由§53.2指导复核接受；native红对照的计数与性质以§53.2及原始日志为准。

**源码修复。** [composable_ui.cj:1393](../../runtime/cjgui/src/composable_ui.cj#L1393)与[:1417](../../runtime/cjgui/src/composable_ui.cj#L1417)的paint/translation复制入口转发`contentAlignX/Y`；normal交互resolve经同一入口，不再把CENTER/END静默退回START。native在[renderer.m:12564](../../runtime/cjgui/native/cjgui_internal_renderer.m#L12564)新增`CjguiComposableContentTextRect`，prepared layout、fallback段落与raster credential共用同一inset/行框：CENTER垂直居中、END贴内容框底且行高不变；[纹理key](../../runtime/cjgui/native/cjgui_internal_renderer.m#L12746)追加`contentAlignX/Y`，[credential](../../runtime/cjgui/native/cjgui_internal_renderer.m#L13528)与[retained检查](../../runtime/cjgui/native/cjgui_internal_renderer.m#L13684)携带并对齐`textRect`，仅改对齐即失效重排。未全局禁用缓存，未让宿主绕开交互样式。

**确定性RED/GREEN。** public复制RED在`overlay.contentAlignX == CENTER`失败（[RED日志](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/red-style-copy/cjpm-test-0.log)）；修复后同一测试PASSED 1/SKIPPED 1176（[GREEN日志](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/green-style-copy/cjpm-test-0.log)）。native新增[14项定向断言](../../runtime/cjgui/native/tests/composable_text_content_alignment_test.m)：140x32“Reset 42”的CENTER/END行框次序、END与START共享底边、行框高度、usedRect、水平CENTER/START字形起点、仅改垂直/水平对齐时key变化、同对齐retained可用、改垂直/水平对齐后拒绝；当前renderer 14/14 PASS（[日志](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/native-alignment/run.log)）。以当前源码做故障注入（END改成CENTER、key移除content、retained移除对齐核对），该对照12项断言得5 PASS/7 FAIL、exit 1；不是完整旧版renderer重跑（[RED原件](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/native-alignment/red/run.log)）。

**实际画面与操作。** 宿主`fefd5b72…`/native`9a4b8c57…`正常assets入口：暗色短中文、“Reset 42”、[取消草稿]、[应用草稿]均位于内容框中心，[暗色动作](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/dark-actions-final.png)、[亮色动作](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/light-actions-final.png)；列表仍左对齐、输入未变。生成恢复动作用公开模型入口改为“Reset 42”，`SUBMITTED_SHA256`与`EXPECTED_STRUCTURE_SHA256`同为`9ebce9e6…`，accepted v1→v2 `exact_readback=1`（[预览](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/model-apply.json)）。包外消费者用同源SDK重建`70bf07ad…`：手写[应用]/[还原]文字居中（[画面](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/external-consumer-applied.png)），AXPress“应用”后owner 8201 `draftVersion/appliedVersion` 0→1，状态“设备草稿已应用”，Cmd+W正常关闭`INSPECTION_CLOSED endpoint_cleared=true`（[身份与读回](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/external-identity.json)）。默认入口未带ui-document时“公开生成”面板为空，与旧图相同，未据此评生成面板视觉。

**暗色“启用”。** 归属为宿主生成UI文档漏给booleanInput命名style；无style时按公开模型使用缺省黑色文字，框架无需为此改动。[assets UI](../../runtime/cjgui/examples/prototype_host_app/projects/assets/ui/main.json)的`field-enabled`与[settings UI](../../runtime/cjgui/examples/prototype_host_app/projects/settings/ui/main.json)的`field-notificationSound`补`style body`后，[暗色](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/dark-align.png)/[亮色](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/light-actions-final.png)均清晰，checkbox仍可点；应用后会话解码`asset-0001`、`applied.enabled=false`、`fieldVersions.enabled=1`、`appliedVersion=1`（[验证记录](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/dark-enabled-verification.json)）。

**同源SDK与包外身份。**

| 产物 | 实核身份 |
| --- | --- |
| 新交付ZIP `CJGUI-macOS-Candidate-h5b.zip` | **`ec9237f666721a86e8328295fc24b520bcd9d0f5eeb62b94906d75f56550980f`**，6,464,594字节；680条目=641文件+39目录，无AppleDouble |
| source-lock | `a630a7e6cfe849dc71f7a30064799dd2a440845b2480feac7497012d2c456880`，closure 613 |
| manifest | `3edd2cee011a6526328da560fd3347c82b48c16bcc44afc99cec40396b8e4896`，640文件 |
| exported/source content | `272599b3…` / `4faf6d65…` |
| 同源宿主bundle | `fefd5b72d0b3b44969188ca7d4c079d321036ab4ffba2f0bcbb30cff4f082bd5`；native `9a4b8c57b2ed8099ecbc4721bd5761999e6f3fdd482591d9a7e01fd79c2af431` |
| 包外InspectionCandidate | `70bf07ade61cdd4d631d65031c3e5c2701598d63a9d2c9b57469b2b03c231080`；native `4ace6502…` |

[生成锁日志](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/sdk-lock-gen.log)先按当前实际输入写新锁，[锁定导出](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/sdk-lock-export.log)再以同一锁重放为640文件/closure 613；未修改skill，3个skill文件按交付后现状冻结，不把新锁写成与旧锁`e17b4228…`相同。旧宿主`d3b6bc10…`/旧SDK`8f241283…`仅作回退基线，不标为含本修复。

**反馈。** H5-B issue `8dca7fed997b494ea0c29516126f326c`追加`f7bc9264cb30464fb2b7524a7ffeeb23`：`source_fix=fixed`、`sdk_inclusion=included`、`consumer_verification=passed`；再追加`6fdda62b72354854922ce9fd0486f55c`更正ZIP打包身份（先前ditto档案`e5f29719…`含719个AppleDouble条目，非交付档案；同源`zip -X`重打包为`ec9237f6…`，包内容与锁未变）。暗色issue `3915db8a6ad04e5a84aae18aa824adc0`追加`72993c8105d84fb18bed01c8f8492dd0`：classification=application_integration（框架无待修项；triage按默认pending），宿主文档fixed、SDK not_applicable、宿主消费passed。实际[list](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/feedback-after-h5b-fix.json)为**29 issue/125 event、complete、errors空**。

**边界与空间。** 未重跑VO/性能/全平台矩阵；native测试为定向14项，不声称覆盖全部绘制路径；只改macOS共享实现与当前SDK，OHOS/Windows/Linux适配副本未动；候选仍experimental/additive_only，未stage/commit/push、未发布、未改skill。[空间账](../../work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/space-account.json)：本轮留存h5b证据58MiB（含同源SDK目录25MiB与ZIP）、包外SDK入口25MiB、反馈约3MiB；旧包外SDK 25MiB移至draft保留回退；冗余预检导出25MiB已退役；宿主与包外构建复用既有target。宿主余234GiB，远低于10GiB预算且高于20GiB余量；自有宿主PID 13173、包外PID 23664均经Cmd+W正常退出，descriptor清空，未触碰其他实例。


<a id="532"></a>
### 53.2 指导验收：本轮收口，候选边界保留（2026-11-09）

**结论。** 接受§53.1的有限交付。指导实际查看宿主亮暗、包外最终图：短中文、Reset 42及操作按钮居中，列表保持左对齐，暗色“启用”可辨；源码修复落在共用paint/translation复制、native内容矩形与缓存身份，宿主没有绕开交互样式。暗色checkbox归属应用UI漏命名角色，已消费既有body样式，暂无此项框架待修要求。指导只核源码、原图、记录和哈希，没有新运行GUI/构建/测试。

**证据与身份。** [复核原件](../../work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-h5b-closure-20261109.json)：ZIP `ec9237f6…`共680条目/641文件，无AppleDouble；其640个manifest文件与导出目录、包外安装目录逐项一致；锁`a630a7e6…`的613项当前源输入全部匹配。宿主484源/466准备源/2库，包外458/440/2，及raw/bundle可执行哈希均匹配各自production构建记录，宿主bundle`fefd5b72…`、包外`70bf07ad…`。公开模型原始输出确有accepted v1→v2/exact_readback=1；包外owner 8201版本0→1来自同端点前后读回；宿主会话原件PAYLOAD长度/哈希核对后，asset-0001的applied.enabled=false、字段及应用版本1成立。两条业务对象证据不混用。

**测试口径更正。** public复制测试有真实旧实现RED及修后GREEN（PASSED 1）；native当前日志为14项PASS。native红样本是当前源码删除保护后的故障注入：实际12项断言中5 PASS/7 FAIL；§53.1原“6 FAIL”已更正，不能描述成完整旧SDK renderer回放。定向测试、当前源码与正常消费证据足以支撑本轮结论，不据此扩大成全部native路径、VO、性能或其他平台通过。

**反馈与后续。** H5-B issue `8dca7fed…`追加指导事件`ef0914c06ad641ed92141e4227c40b67`；暗色issue `3915db8a…`追加`c5d136fb1ba94b5daca2761097d0c878`（application_integration / no_framework_action，应用配方已修）。source_fix/sdk_inclusion/consumer_verification分别按真实范围填写；旧版本失败和原件保留。执行入口[§17.6](../ai/2026-11-08-prototype-host-blocker-decisions.md#176)与ACTIVE已更新，当前反馈实核29 issue/127 event、complete、errors空。不要求执行者再回传同义确认或重跑已绿矩阵。本轮完成不等于成熟首版/stable/正式发布；原未证范围继续按各自记录保留，后续真实消费的新问题沿§3.1自主修复和反馈。

**指导收尾。** 仅文档、反馈和小型核验JSON新增，未改产品或skill，未stage/commit/push、未发布，无新增构建树或自有窗口/进程，无删除；新增不足0.1MiB，空间实测见本次核验摘要。
