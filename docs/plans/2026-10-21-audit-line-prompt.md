# 阶段任务：CJGUI 框架能力审计（体检线）

你是这条线唯一的执行者。任务不是改代码，是用源码事实把「框架现在到底有什么」查清楚，产出一份别人可以直接拿来用的账本。全程零构建、零改动。

## 0. 先读什么

只读这些，不要遍历全仓：

1. AGENTS.md 的两节：搜 id="shared-implementation" 和 id="artifact-space-budget"，只读这两节
2. runtime/cjgui/ACTIVE_DIRECTION.md（看当前三条线在写什么，避开它们的写集）
3. 本任务
4. 审计需要的源码（锚点见各任务包）

不要逐个读 docs/plans/（那里有 2092 个文件）。只读 docs/plans/2026-09-26-framework-capability-roadmap.md 一份。

## 1. 硬边界（越界即任务失败）

- 不运行 cjpm build / cjpm test / 任何编译、链接、启动应用的命令。三条并行线正在构建，同一个 target 抢构建锁会把所有人拖慢。本任务纯静态。
- 不修改、不删除任何已有文件。只新增 runtime/cjgui/audit/ 下的文件。
- 不碰 runtime/cjgui/src/、runtime/cjgui/native/、runtime/cjgui/platforms/、runtime/cjgui/examples/、.workbuddy/。
- 不执行任何 git 写操作（不 add / commit / push / checkout / stash / reset）。
- 不把文档里的结论当事实抄。每个判定必须能指到 文件:行。docs/ 里写的完成度、artifacts/ 里的验收报告，都只是「某次跑过」，不等于「能力在」。
- 用 Grep / rg 检索，不要整文件 cat 大文件（native/*.m 单文件几万行）。
- 本轮新增文件控制在 6 个左右，不要顺手扩张。

## 2. 关键路径事实（先记住，别按对称性猜）

各平台原生代码位置不对称：

| 平台 | 原生代码位置 | 规模 |
|---|---|---|
| macOS | runtime/cjgui/native/*.m（5 个文件，头文件同目录） | 约 98,000 行 |
| Windows | runtime/cjgui/platforms/windows/native | 约 19,800 行 |
| OHOS | runtime/cjgui/platforms/ohos | 约 28,900 行 |
| Linux | runtime/cjgui/platforms/linux/native | 约 16,700 行 |

macOS 不在 platforms/ 下。按 platforms/macos 去找会找不到，不要因此判定「macOS 没接」。

C ABI 头文件：runtime/cjgui/native/cjgui_internal_renderer.h。macOS 侧 cjgui_internal_renderer_ 前缀的符号约 413 个（去重后）。

### 数据快照（开工第一件事，必须先记下来）

工作区当前有未提交改动（其他并行线的在途工作）。所以审计反映的是「此刻的树」，不是某个干净 commit。记下这三个值，后面写进 audit/README.md：

    git rev-parse --short HEAD        # 基线 commit
    git status --short | wc -l        # 未提交改动条数
    date -u +%Y-%m-%dT%H:%M:%SZ       # 快照时间

报告里要写明「本审计基于 X 条未提交改动的工作区」，否则等这批改动提交后数字会对不上，别人会以为你算错了。

## 3. 任务包

### 包 A：@When 全量清单（原料，先做完这个再做 B）

扫 runtime/cjgui/src/*.cj 里所有 @When[...] 条件编译，逐条记录。

基线（我实测过，用来交叉核对，不是让你凑数）：

- 代码里的 @When 共 458 处
- 分布在 24 个文件
- 共 11 种不同条件形态

已知的 11 种形态和计数（确认是否还有别的）：

    os == "macOS"                                        206
    os != "macOS"                                        105
    os == "Windows"                                       40
    os != "Windows"                                       24
    os != "macOS" && os != "Windows" && os != "Linux"     22
    os == "macOS" || os == "Windows" || os == "Linux"     19
    os == "Linux"                                         18
    os == "macOS" || os == "Windows"                       9
    os == "Windows" || os == "Linux"                       7
    os != "macOS" && os != "Linux"                         7
    os != "Windows" && os != "Linux"                       1

注意：如果你用 grep 数 @When 数出 459，多出来的那 1 处是 runtime/cjgui/src/runtime_renderer_session.cj 第 2664 行的注释文字，不算代码，排除掉。

你测到的数字如果与基线一致，在报告里写明核对通过；如果不一致，照实报你测到的数字并解释差异来源。

输出 runtime/cjgui/audit/evidence/when-inventory.tsv，制表符分隔，列：文件 / 行号 / 条件原文 / 所在函数名 / 该分支返回什么。

「返回什么」要写实际情况：具体常量、委托给某个函数、真实逻辑（一句话概括）、或空操作。

重要区别：别把 os != "macOS" 当成「Windows + Linux + OHOS 都实现了」。它只说明「不是 macOS」，里面可能只对 Windows 写了逻辑，Linux 落进去拿到的也是空值。这是本任务的核心。

### 包 B：静默 fallback 审计

从包 A 的清单里筛出「该平台落进去不报错、只丢功能」的位置。判定标准：

- 分支体只 return 一个常量（0u32、false、空字符串、空数组、空集合）
- 或只调用一个空实现、直接 return 不做事
- 或返回默认构造的值，调用方无从得知「本平台不支持」

重点查这三类：

1. os != "macOS" && os != "Windows" && os != "Linux" —— 22 处，OHOS 专属。集中在 src/runtime_renderer_session.cj（13 处）、src/owner_turn_budget.cj（8 处）、src/composable_ui_mac_retirement.cj（1 处）。这类是历史上修过的同一类坑，确认现在还有没有同样性质的。
2. os != "macOS" —— 105 处。查有没有「只写了 Windows 分支、Linux 落进去拿空值」的情况。
3. os == "Linux" —— 18 处。查它对应的「非 Linux」分支是不是静默默认值。

输出 runtime/cjgui/audit/silent-fallback-audit.md，每条按这个格式：

    文件:行 — 条件
      返回：具体内容
      消费者会看到什么后果：用大白话，比如「选区底色永远是透明」「指针队列恒空」
      严重度：影响可见功能 / 影响诊断 / 仅影响极端路径

这一条最重要：后果必须写人话。写不出后果的，说明你还没弄清它干什么，标「待确认」别硬填。

### 包 C：跨平台能力矩阵（主交付）

行从三个来源取并集，不要自己发明维度：

1. docs/plans/2026-09-26-framework-capability-roadmap.md 里的 E1–E6、F1–F11 条目
2. runtime/cjgui/src/*.cj 里所有组件类 public func 工厂（约 89 个，名字含 Composable / TextView / Button / Label / Input 等关键字。src/ 下 public func 总共 2120 个，大部分是内部工具函数，不在本轮范围）
3. 四个平台 native 侧导出的能力符号（cjgui_internal_renderer_ 前缀一类，按功能分组）

列：macOS / Windows / OHOS / Linux

每格三态，判定规则写死：

- 真实现 —— 该平台分支有实际逻辑，且 native 侧能找到对应实现。两个来源都支持才能给这个状态。
- 静默空壳 —— 仓颉侧有该平台分支，但只返回常量或空值（包 B 查出来的）。
- 没接 —— @When 里没有该平台分支，或 native 侧无对应符号。

每格必须附 文件:行：判「真实现」的给仓颉侧加 native 侧各一条；判「没接」的给仓颉侧反证一条。

输出 runtime/cjgui/audit/capability-matrix.md：主表格，加每个「非真实现」格下面一行后果说明。

判定只看源码事实。不看 docs/ 声称的完成度，也不看 artifacts/ 里的验收报告。「源码存在 / 有测试 / 有真实消费者验证」是三种不同状态，别混成一个「有」。

顺带产出一节「文档落后于代码」清单：如果 roadmap 或某个 docs/ 页说某能力缺失或待做，但你查源码发现已经有了（例如布局原语 Stack、Wrap、AspectRatio、Spacer 近期已在 src/composable_ui.cj 里新增），把它列出来，带 文件:行 和原文档位置。这类条目对定「首个成熟版本」的边界最有用，别漏。

### 包 D：公共 API 面清单

约 89 个 public func 组件工厂，逐个记录：函数名、参数列表、返回类型、有无文档注释、src/ 下有无对应 *_test.cj、examples/ 下有无真实消费者调用（给出消费者目录名）。

输出 runtime/cjgui/audit/public-api-surface.md（表格）加 runtime/cjgui/audit/evidence/public-api-surface.tsv（机器可读）。

## 4. 索引与报告

runtime/cjgui/audit/README.md：这份审计是什么、四个文件各管什么、怎么用。必须写明数据快照三个值（HEAD 短哈希、未提交改动条数、快照时间），以及一句「本审计基于未提交改动的工作区，提交后数字会变」。

报告直接在对话里给，不要另存文件，按这个顺序：

1. 做了什么，产出哪几个文件
2. 数字对账：包 A 测到的总数、形态数、文件数 vs 我给的基线，一致或差异原因
3. 包 B 查出多少条静默 fallback，按严重度分组计数
4. 包 C 矩阵行数，四平台各自「真实现 / 静默空壳 / 没接」的计数
5. 「文档落后于代码」查出多少条，各是哪份文档说的
6. 抽样自检：从矩阵里随机挑 10 格，逐格回源码确认判定对不对，贴核对结果
7. 你拿不准的判定（宁可标「待确认」，也不要硬判）
8. 空间账：本轮新增多少 MiB（预计不到 10 MiB）

## 5. 验收（我会这样查你）

1. 随机抽 10 格矩阵，回源码看 文件:行 对不对得上。有一格对不上，整包退回。
2. 抽 5 条静默 fallback，核实「消费者会看到什么后果」是不是真的成立。
3. 看包 A 的数字与我给的基线是否对得上，差异有没有解释。
4. git status 里除了 runtime/cjgui/audit/ 之外没有别的改动。
5. 没有任何构建产物、没有新建 artifacts/ 目录。

## 6. 遇到问题怎么处理

- grep 漏了、判错了，自己补，不用报。
- 同一条卡两次以上还搞不清的，标「待确认」写清卡在哪，继续做别的，别在一个点上反复猜。
- 整包做完集中报一次，不要每做完一包就停一次等人确认。
- 不确定的判定宁可标「待确认」，也不要为了表格填满而猜。

## 7. 容量

纯文本产出，预计新增不到 10 MiB。不要为审计创建构建目录、不要复制源码树、不要生成截图。
