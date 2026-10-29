# CodeLattice 缺口清单（从 CJGUI 实际使用反推）

日期：2026-10-23
触发：在 CJGUI 仓库上用 CodeLattice 查"框架有没有 Table / 缺什么能力"，连续三次被误导。
本文只记录**实测可复现**的缺陷，以及对应修法。不含推测。

---

## 一句话结论

**CodeLattice 的底层分析是准的，不准的是它的"路由"和"空结果语义"。**

准确的部分：给死一个根，它扫 550 个 .cj（= `src/` 递归实际文件数，完全对齐）、11,556 个符号、12,108 个节点、22,670 条边，14 秒出结果。这个数字没有虚高，没混进 `artifacts/` 下的 6,808 个历史副本。

不准的部分有两层：
- **根路由**会把 `artifacts/` 下的旧快照当成正式项目，选错根还标 `confidence: "high"`
- **空结果不区分原因**：真的没有 / 这个语言没实现 / 筛错了，三种情况返回完全一样的东西

第三层是它做不到的，但可以明说：**"缺什么"这种全局否定断言，静态工具证明不了。**

> **2026-10-24 更新**：前两层都已修（根路由的 `artifacts`/`evidence` 排除、空结果三态）。
> 落点与实测见 **6.8.1**；同一节还记了一条方法论教训 —— 当时验证用错了二进制，
> 导致「`symbols` 在 ObjC 上不可用」误报了整整一天。

---

## 一、实测基线（可复现）

```bash
# 底层分析：干净、准确
./bin/codelattice analyze --root <cjgui> --language cangjie --profile symbols
# → sourceFileCount: 550, symbolCount: 11556, nodeCount: 12108, edgeCount: 22670

# 对照实际文件数
find src -name "*.cj" | wc -l   # → 550（534 顶层 + 16 子目录）
```

550 = 550，一位不差。**扫描范围没有污染。**

```bash
# 同一份数据加 --public-only
./bin/codelattice analyze --root <cjgui> --language cangjie --profile symbols --public-only
# → "symbolCount": 11556, "symbols": [], "totalItems": 0
#    "filters": { "publicOnly": true }
```

**11,556 个符号，筛出 0 个。不报错、不警告。**

---

## 二、三类缺陷

### 缺陷 A：`visibility` 是逐语言实现的，缺的语言静默返回空

后置过滤器（`crates/cli/src/lib.rs:495`）：

```rust
if options.public_only {
    symbols.retain(|s| {
        let visibility = s["visibility"].as_str().unwrap_or("");
        visibility == "pub" || visibility == "public"
    });
}
```

`unwrap_or("")` —— 字段不存在时当空字符串处理，于是全部被筛掉。

各语言实际产出：

| 语言 | 符号级 visibility | `--public-only` | 证据 |
|---|---|---|---|
| C | ✅ `CVisibility` | 有效 | `crates/c/src/graph.rs:168` |
| C++ | ✅ | 有效 | 递归命中 29 处 |
| Python | ✅ `PythonVisibility` | 有效 | `crates/python/src/graph.rs:165` |
| Rust | ✅ | 有效 | `crates/project-model/src/graph.rs:381` |
| **仓颉** | ❌ 只有 `ImportVisibility`（import 语句用） | **静默空** | `crates/cangjie/src/extractors/symbol.rs:39` struct 无该字段 |
| TypeScript | ❌ | **静默空** | 递归命中 0 |
| JavaScript | ❌ | **静默空** | 递归命中 0 |
| ArkTS | ❌ | **静默空** | 递归命中 0 |

**同一个根缺陷连累三个工具**，因为它们都读 `properties.visibility`：

- `analyze --profile symbols --public-only` → 空
- `codelattice_external_api_surface`（"找 public API 面"）→ 空（`crates/cli/src/mcp_server.rs:18848`）
- `find_public_symbols_in_dir`（通配 import 展开）→ 退化成"假设所有顶层符号都可导入"，注释自己写明的：

```
// Check if symbol has is_public field (added in Slice 14a)
// For now, we'll assume all top-level symbols are importable
```

（`crates/cangjie/src/extractors/references.rs:296-300`）

**危害等级：最高。** 因为它给的是"看起来正常的空结果"。使用者会得出"这个框架没有 public API"的结论，而事实是有 468 个（我用 grep 数出来的）。

---

### 缺陷 B：`modules` profile 对仓颉也是空

```bash
./bin/codelattice analyze --root <cjgui> --language cangjie --profile modules
# → { "moduleCount": 0, "sourceFileCount": 550, "symbolCount": 11556 }
```

550 个文件、11,556 个符号，模块数是 0。**同一个模式：profile 存在，对该语言无实现，返回空而不声明。**

`check_language_feature`（`mcp_server.rs:4341`）只检查编译特性开关（`tree-sitter-cangjie` 有没有编进去），不检查 profile 级能力。所以它挡不住这个。

---

### 缺陷 C：根路由越界，把快照目录当项目

`codelattice_symbol(root=<cjgui>, query="Table")` 的实际返回：

```json
"rootRouter": {
  "selectedRoot": ".../artifacts/ds41f-components-sdk-20261021/sdk-old/consumers/rule_set_window_app",
  "confidence": "high"
}
```

30 个 Table 符号**全部来自 `artifacts/` 下的旧 SDK 副本**，主树 `src/` 一个都没查。

根因链：

1. `inspect` 的输出已经把原因摊开了 —— 主项目 `relativePath: "."`，紧接着就是
   `relativePath: "artifacts/ds41f-command-semantics-20261021/multi-object/application"`。
   **`artifacts/` 下每个快照都被当成独立项目。**
2. 目录排除是硬编码最小集：`["node_modules", ".git", "target", "fixtures"]`
   （`crates/project-model/src/manifest.rs:481`、`:602`）。
   **不含 `artifacts`，也不读 `.gitignore`。**
3. 该仓库有 207 个 `cjpm.toml`（非 artifacts 54 + artifacts 153），候选池因此被快照淹没。
4. 打分时 query 符号命中 +100（`mcp_server.rs:26390` 附近），任何项目只要命中就压过其它信号。
5. `confident` 判据是 `best_matches > 0`（`:26434`），所以命中即 `high`。

**危害：它给出带行号、带符号 ID、带 `confidence: high` 的错误答案。** 比查不到危险得多 —— 查不到会重试，查错了不会。

---

## 三、修复清单

### P0-1　仓颉符号级 visibility

| 项 | 内容 |
|---|---|
| 文件 | `crates/cangjie/src/extractors/symbol.rs` |
| 改动 | `SYMBOL_QUERY` 增加 `modifier` 捕获；`CangjieSymbol` 加 `visibility` 字段；`graph.rs:177` 的 `properties` 写入 |
| 成本 | 小。tree-sitter-cangjie 语法树里本就有 modifier 节点，只是 query 没捕获 |
| 连带修复 | `--public-only`、`external_api_surface`、通配 import 展开，三处同时活 |
| 验收 | `analyze --public-only` 对 cjgui 返回非空，且条数与 `grep -c "^public"` 同量级 |

TS / JS / ArkTS 同理，可另开一项。但**对 CJGUI 这条线，仓颉一项就够了**。

---

### P0-2　空结果必须区分三态（**最高性价比**）

现在三种情况返回同一种东西：

| 情况 | 现在 | 应该 |
|---|---|---|
| 确实一个都没有 | `totalItems: 0` | `totalItems: 0, capability: "supported"` |
| 这个语言没实现 | `totalItems: 0` | `totalItems: 0, capability: "unsupported_for_language", warning: "..."` |
| 筛选条件过严 | `totalItems: 0` | `totalItems: 0, capability: "supported", hint: "0/N matched"` |

| 项 | 内容 |
|---|---|
| 文件 | `crates/cli/src/lib.rs:495`（filter_analyze_profile）+ 各 MCP handler |
| 改动 | 输出加 `capability` 字段；`public_only && filtered == 0 && total > 0` 时强制带 `warning` |
| 成本 | 极小 |
| 为什么优先 | 它把"静默错误"变成"明确声明"。改动最小，但它挡住的是最危险的失败模式 |

**这一条不只修 `--public-only`，它是一条原则：不存在 ≠ 空集。**

`generatedFrom.runtimeVerified: false` 已经体现了这个精神（区分静态推断与运行验证）。`capability` 是同一精神的下一个维度：区分"有 0 个"和"查不了"。

---

### P0-3　目录排除读 `.gitignore`

| 项 | 内容 |
|---|---|
| 文件 | `crates/project-model/src/manifest.rs:481`、`:602` |
| 改动 | 用 `ignore` crate（或等价实现）替代硬编码 `skip_dirs`；保留原集合作为兜底 |
| 连带修复 | `inspect`、`workspace`、`workspace_graph`、rootRouter 全部 |
| 验收 | `inspect --root <cjgui>` 的 `projects[]` 里不再出现 `artifacts/` 路径 |

只加 `"artifacts"` 到 `skip_dirs` 也能止血，但那只是给这一个仓库打补丁。**`artifacts` 不是通用目录名，`.gitignore` 才是通用规则。**

---

### P1-1　显式 root 不路由（止血）

| 项 | 内容 |
|---|---|
| 文件 | `crates/cli/src/mcp_server.rs:26341` 附近（路由入口） |
| 改动 | root 自身含 manifest（`cjpm.toml` / `Cargo.toml` / `package.json` / `pyproject.toml`）时直接走 `unrouted`，不进候选池 |
| 理由 | 用户指到单项目根，就已经给出了边界。router 的存在意义是"只给了 workspace 根，我帮你找" |

`mcp_facade.rs:76` 里 `unrouted()` 分支本来就有，reason 写的是
`"root already targets a single project or no workspace routing was needed"` —— 设计意图正确，只是判断条件被 153 个快照目录 cjpm.toml 骗了。

**P0-3 是根治，P1-1 是止血。两条都做。**

---

### P1-2　CLI 补符号查询

现状：CLI 只有 8 个命令（`analyze` / `quality` / `summary` / `detect-changes` / `inspect` / `workspace` / `analyze-workspace` / `mcp`），**没有符号查询**。符号查询只在 MCP 层（`codelattice_symbol` / `symbol_search` / `symbol_context`），而 MCP 层有路由问题。

| 项 | 内容 |
|---|---|
| 改动 | `codelattice symbol --root <root> --language <lang> --query <q> [--kind] [--public-only]` |
| 价值 | 可锁根、可脚本化、可 diff、可进 CI。也是绕过 rootRouter 最直接的一条路 |

---

### P2-1　字面量索引

查"哪个函数体里出现字符串 `collection`"，现在只能靠 grep。而这类查询在 CJGUI 上很关键：生成式组件的 `kind` 是**字符串**，不是符号。

| 项 | 内容 |
|---|---|
| 现状 | 零。`literal` 在 `analysis-engine` / `project-model` 只出现在两条注释里 |
| 改动 | 符号提取时顺带记录字符串字面量及其所属函数 |
| 查询 | `codelattice literal --query "collection"` → 返回 `(文件, 函数, 行号)` |

---

### P2-2　跨语言边

CJGUI 是三层：仓颉 `src/` → C ABI（`native/*.h` + `.m`）→ Python 客户端（`shared_operation_core/`）。现在只能各查各的。

| 项 | 内容 |
|---|---|
| 现状 | `cross_language` / `interop` / `ffi_edge` 在 `analysis-engine` 零命中 |
| 改动 | 建立 `@C` / `extern` / C 头文件声明 与 实现 的边 |
| 价值 | 回答"这个 ABI 符号三个后端各实现了没有"这类问题，现在全靠裸 grep |

---

### 不做但该写明

在 `detailHint` 里加一句固定说明：

> 本工具只能证明"存在"，不能证明"不存在"。返回 0 条不等于缺失，可能是命名不同、在别处、或该语言未实现。全局性结论请用全集减法。

理由：工具已经会标 `generatedFrom.staticAnalysis: true, runtimeVerified: false`，说明它已经在区分"证据强度"。**"存在性证明的不对称"是同一个维度上的下一格**，补上就完整了。

这条不花什么成本，但它防的正是我这次犯的错：把 `grep` 返回 0 当成"没有"。

---

## 四、补不了的边界

| 问题 | 为什么补不了 |
|---|---|
| "这个框架缺什么" | 静态工具只能证明"有"。全集减法仍要人先定义全集（对 CJGUI 是 468 个 public 声明那层） |
| 文档声明 vs 实际语义 | `BOUNDS 12 64 8 256` 到底限制什么，只能读实现。索引看不出"这个数字在哪儿被消费" |
| 性能 / 运行时行为 | 需要跑，不是静态分析的事。工具自己也标了 `runtimeVerified: false` |

---

## 五、一个附带发现（口径不一致）

`inspect` 报主项目 `sourceFileCount: 477`，`analyze` 报 `550`。

实际 `src` 递归是 550。所以 **`inspect` 的计数口径与 `analyze` 不同**（可能只数顶层、或按 manifest 声明范围）。两者都"对"，但放在一起会让人怀疑哪个可信。

建议统一口径，或在 `inspect` 里标清它数的是什么。

---

## 六、ObjC 支持：补不补、补多少（2026-10-23 实测）

CodeLattice 支持 8 种语言（cangjie / arkts / ts / js / c / cpp / python / shell），
CJGUI 用到的语言里**只漏 Objective-C**。这一节是"如果要补，成本到底多少"的实测，
不是估算。

### 6.1 被测规模

| 项 | 数字 |
|---|---|
| `.m` 文件 | **158 个 / 99,402 行** |
| `.h` 文件 | 33 个 / 14,471 行（其中含 `@interface`/`@protocol`/`@property` 的只有 **2 个**） |
| `class_interface` | 115 |
| `class_implementation` | 113 |
| `method_definition` | **591** |
| `method_declaration` | 195 |
| `property_declaration` | 1,539 |
| `function_definition` | **2,636** |
| `message_expression` | **8,381** |
| `type_definition` | 90 |
| `protocol_declaration` | 1 |

**这张表里最重要的一行是 `function_definition` 2,636 对 `method_definition` 591。**
macOS 后端主体是 **C 函数**，ObjC 只是一层壳（窗口、视图、事件转发）。
所以"补 ObjC"的真实收益不是那 591 个方法，是让 2,636 个 C 函数从"看不见"变成"看得见"。

`.h` 只有 2 个含 ObjC 语法 → **`.h` 不必从 C 手里抢走**，ObjC 适配器只吃 `.m` 即可。
这条消掉了本来最麻烦的归属冲突。

### 6.2 grammar 实测：能不能直接用现成的

`tree-sitter-objc` 3.0.2（`tree-sitter-grammars` 组织维护，MIT，**ABI 14**，
**无 scanner.c**，纯 generated `parser.c` 5.4 MB）。用 tree-sitter **0.26** 加载成功 ——
和 CodeLattice 现有版本同号，不需要动依赖。

同样 158 个 `.m`，分别用 C 和 ObjC 两个 grammar 解析：

| grammar | 无 ERROR 的文件 | ERROR 节点 | MISSING 节点 | `function_definition` | `method_definition` |
|---|---|---|---|---|---|
| `tree-sitter-c` | **7 / 158（4.4%）** | **35,082** | 2,781 | 2,525 | 0 |
| `tree-sitter-objc` | **150 / 158（94.9%）** | **62** | 344 | 2,636 | 591 |

结论两条：

1. **"把 `.m` 塞进 C 的扩展名列表"这条捷径不能用。** 它确实还能摸到 2,525 个函数名
   （占 96%），但 95.6% 的文件有 ERROR，位置范围不可信 —— 输出的是**看起来正常的假数据**，
   正是这份文档开头那三次误导的同一个病。
2. **ObjC 语法层几乎是白送的。** 94.9% 干净，剩下 62 个 ERROR 全部落在 C 宏上，
   不是 ObjC 语法问题：`typedef NS_ENUM(uint8_t,X){...}`、`_Atomic(bool)`、
   `#ifdef` 夹在参数表里。`tree-sitter-c` 遇到这些一样会错。
   **这部分是 C-family 通病，不该记在 ObjC 头上。**

唯一的头部集中：`native/cjgui_internal_renderer.m`（50,675 行）一个文件占掉
62 个 ERROR 里的 49 个、344 个 MISSING 里的 330 个。ERROR 只落在 **0.10% 的行**上。

### 6.3 工作量分解

**A. 语言 crate 本体（照 `crates/cpp` 的模板写）**

| 文件 | 估行数 | 说明 |
|---|---|---|
| `Cargo.toml` | ~20 | `tree-sitter` 0.26 optional |
| `build.rs` | ~15 | `cc` 编 vendor 的 `parser.c`（无 scanner，比 cangjie 简单一半） |
| `vendor/tree-sitter-objc/src/parser.c` | 现成 | 0 工作量 |
| `src/lib.rs` | ~50 | |
| `src/extractors/symbol.rs` | ~800-1,000 | 类/方法/属性/函数/typedef；**含 selector 重建** |
| `src/extractors/call.rs` | ~250 | `message_expression` → CALLS |
| `src/extractors/include.rs` | ~100 | `#import` / `#include` |
| `src/project.rs` | ~200 | 根探测（`.m` 分布 / Xcode `project.pbxproj` / Makefile） |
| `src/graph.rs` | ~300 | 图输出 |
| `tests/` | ~150 | |

小计 **~2,000-2,300 行 Rust**。对照：`crates/cpp` 2,908 行，`crates/c` 1,721 行，
`crates/cangjie` 7,339 行（cangjie 多是因为自带 manifest 解析 + diagnostics 子进程）。

**B. cli 注册层（真正的隐形成本）**

`"cpp"` 字面量在 `crates/cli/src/` 里出现 **79 处**，分布：

| 文件 | 处数 |
|---|---|
| `mcp_server.rs` | **54** |
| `lib.rs` | 9 |
| `engine_bridge.rs` | 6 |
| `ai_runtime.rs` | 4 |
| `mcp_facade.rs` | 2 |
| 其余 4 个文件 | 各 1 |

其中约 85% 是 JSON schema 里的 `"enum": ["rust","cangjie",...,"shell"]` 列表 —— 机械替换，
**但漏一处就是"用户传 objc 直接报语言不支持"**。这 54 处集中在 26,000 行的
`mcp_server.rs` 里，靠人眼过一遍不可靠，得靠脚本 + 一次全量 smoke。

真正要动脑的只有：`DetectedLanguage` 加 `Objc` 成员、`engine_bridge.rs` 加一个
`ProjectOnceBridgeAdapter`（~8 行）、`language_detect.rs` 的识别规则。

### 6.4 两个必须提前知道的坑

1. **selector 重建不是读字段**。`- (void)handleKey:(unsigned short)code flags:(NSUInteger)f`
   在 AST 里是：
   ```
   method_definition
     '-'  method_type  identifier 'handleKey'
     method_parameter ':(unsigned short)code'
     identifier 'flags'          ← 裸 identifier，不在 method_parameter 里
     method_parameter ':(NSUInteger)f'
   ```
   第一段名字和后续段名字**在不同层级**，得按兄弟顺序扫、数 `:` 的个数，拼成
   `handleKey:flags:`。约 100-150 行专用逻辑，写错了会导致方法名对不上、调用边全断。

2. **`message_expression` 的 receiver 类型静态不可知**。`[self.delegate viewNeedsPaint:self]`
   里的 `self.delegate` 声明成 `id<CJViewDelegate>`，实现是谁要跨文件推。
   → CALLS 边只能先记 **selector 名**，会有一批 dangling。
   `message_expression` 共 8,381 个，这是 ObjC 调用图精度的天花板，不是实现问题。

### 6.5 分档与工时（单人，熟悉本仓库的前提下）

| 档 | 内容 | 累计工时 |
|---|---|---|
| **A 最小可用** | grammar 接入 + 类/函数/方法/属性符号 + 定义位置 | **1.5 - 2 天** |
| B 结构完整 | + category / protocol / typedef / enum / selector 重建 | 3.5 天 |
| C 调用边 | + `message_expression` → CALLS（精度受 6.4-2 限制） | 5.5 天 |
| D cli 全打通 | + 79 处注册点 + smoke + golden fixture | 7.5 天 |
| E 工程化 | + Xcode/CMake 根探测 + 文档 + 边界说明 | 9.5 天 |

**A 档 2 天，就能让 CodeLattice 在 `.m` 上不再瞎。** 后面每一档都是增量，随时可停。

### 6.6 建议

按 D 档（7.5 天）一次做完再上 CJGUI，理由：

- A 档单独上线没有意义 —— `mcp_server.rs` 那 54 处 schema 没改，MCP 侧传 `objc`
  仍然报错，只有 CLI 能用。
- 但**不要先做 E**。Xcode 根探测对 CJGUI 没用（它没有 `.xcodeproj`，靠 `Makefile` +
  `clang` 直编），等真接了 Xcode 项目再说。

### 6.7 一条不推荐但该知道的备选

Clang 本来就在机器上，`clang -Xclang -ast-dump=json` 能给出**宏已展开**的完整 AST，
质量高于 tree-sitter。但代价是要能跑通编译命令（SDK 头文件路径、`-fobjc-arc` 等），
且解析 JSON AST 的体积是 tree-sitter 的几十倍。

CodeLattice 的 `crates/cpp` 已经有 `compile_commands.rs` 这条路，思路一致。
**如果将来 C 宏导致的 62 个 ERROR 变成真实障碍，再升级到 clang AST；现在不值得。**

### 6.8 落地实测（2026-10-23 21:30，ObjC 已实现）

`crates/objc` 已落地：**7,603 行**（源码 2,986 + 测试 4,617），比 6.3 估的 2,000-2,300 多一倍，
多出来的主要在 `resolve.rs`（880 行，符号消解）和 6 个测试文件。
grammar 直接用 crates.io 的 `tree-sitter-objc = "=3.0.2"`，**不需要 vendor + build.rs**（比 cangjie 简单）。

编译（46 秒）：

```bash
cargo build --release -p gitnexus-rust-core-cli \
  --features tree-sitter-cangjie,tree-sitter-objc,tree-sitter-c,tree-sitter-cpp,tree-sitter-python
```

#### 与 6.1 基线交叉验证

| 指标 | 我用 tree-sitter 直测（6.1） | CodeLattice 实测 | 结论 |
|---|---|---|---|
| `cjgui_internal_renderer.m` ERROR | **49** | **49** | 一位不差 |
| 同文件 MISSING | **330** | **330** | 一位不差 |
| 全量 ERROR / MISSING | 62 / 344（158 文件） | 63 / 347（154 文件，含 5 个 .h） | 同一解析器，差异来自口径 |
| clean 文件 | 150 / 158 | 134 clean + 20 recovered = 154 | 口径一致 |

**同一个 grammar、同一个错误计数逻辑，两套独立测量结果吻合。** 这证明 6.1 那张表可信。

#### 输出准确的直接证据

`analyze --root runtime/cjgui/native --language objc` 报出的三条边，逐条回源核对：

| 工具报的 | 源码实际 |
|---|---|
| `currentBackingScale` 定义在 **L3044** | L3044 正是 `- (CGFloat)currentBackingScale {` ✅ |
| `updateDrawableSize` 定义在 **L3157-3169** | L3157 正是 `- (void)updateDrawableSize {` ✅ |
| L3078 `[self currentBackingScale]` | L3078 正是 `self.metalLayer.contentsScale = [self currentBackingScale];` ✅ |
| L3080 / L3088 `[self updateDrawableSize]` | 两行源码均为 `[self updateDrawableSize];` ✅ |

**selector 重建也正确**：`initWithFrame:device:commandQueue:` 三段、`setFrameSize:` 单段，全部拼对。
6.4 提的两个坑，实现侧都处理了。

符号统计（干净根 `native/`，154 文件）：

| kind | 数量 | 对照 6.1 |
|---|---|---|
| function | 3,369 | 2,636 定义 + 719 头文件声明 → 对得上 |
| property | 1,552 | 1,539 → 对得上 |
| method | 789 | 591 定义 + 195 声明 → 对得上 |
| class | 263 | 115 interface + 113 implementation + category → 对得上 |
| category / protocol | 3 / 1 | 新增 category 维度 |

#### 调用边：宁可不出，也不瞎出

12,169 条 CALLS，每条带 `resolutionRule` 与 `confidence`：

| 规则 | 条数 | 含义 |
|---|---|---|
| same-file | 8,093 | 同文件 C 函数 |
| header-declared | 2,465 | 头声明 + 实现 |
| **self-message** | **867** | `[self foo]`，确定 |
| **typed-variable** | **587** | 有类型声明的 receiver |
| name-only-unique | 135 | 全局唯一名 |
| class-message / super-message / same-file-declaration | 16 / 2 / 4 | |

**全部有依据，没有一条靠猜。** 代价是 6.4-2 说的精度上限：
`messagesTotal 8,292` → `messagesResolved 1,472`（**17.8%**），其余 6,820 条消息不产边，
统一进 `unresolvedCalls: 20,341` 供复核。这个取舍是对的：**错的边比没有边更坏。**

#### 顺带修掉的老缺陷（对照第三节）

| 缺陷 | 修前 | 修后 |
|---|---|---|
| P0-1 仓颉 `--public-only` 返回 0 | **0** | **1,455**（beforeFilters 6,759） |
| P0-2 空结果不分三态 | 静默返回空 | `capability.status=unsupported` + `reason=objc-visibility-not-modeled` |
| `modules` 仓颉 `moduleCount: 0` | **0** | **272**（按文件分组，带 `publicSymbolCount` / `riskHints`） |
| `sourceFileCount` 口径不一 | inspect 477 / analyze 550 | 统一 **553**（= `find src -name "*.cj"` 实数） |
| P1-2 CLI 补符号查询 | 无 | `codelattice symbols` 子命令已加 |
| `.cjgui` 副本 | 1,771 个混进索引 | 已排除（`.gitignore:55` 生效，仓颉只报 553 而非 2,324） |

#### 还剩两个问题（**当时**判定，结论已被 6.8.1 修正）

> ⚠️ 读这一节前先看 6.8.1。当时用的是 `target/release/codelattice`
> （SHA `9f977a1e…`），与安装版（SHA `deff17bf…`）**不是同一个二进制**。
> 问题 1 在安装版上已不成立；问题 2 当时成立，现已修。

**问题 1：CLI `symbols` 子命令在 ObjC 上不可用。**

```bash
$ codelattice symbols --root runtime/cjgui/native --language objc --query updateDrawableSize
{ "match": { "status": "not_run",
             "reason": "workspace root needs explicit project selection" },
  "effectiveLanguage": null, "symbols": [] }
```

即使显式传了 `--language objc` 也被忽略。根因：`symbols` 走 workspace 项目选择，
而 workspace 只认清单文件（`cjpm.toml` / `package.json` / `CMakeLists`）；
ObjC 项目靠 `.m` 存在性识别（`objc/src/project.rs:254`），不在清单表里。
CJGUI 没有 `.xcodeproj` 也没有 `Makefile`，于是选不出项目。

状态写得清楚（`not_run` + 明确原因，不是假成功），但**功能不可用**。

绕法两条，都已实测：
- `analyze --profile symbols --profile-page-size 0` → 5,977 个符号，含 selector / owner / lineStart
- **MCP `codelattice_symbol` 反而能用** —— 它走 engine 后台 job（`job_engine_00000001`），
  1.5 秒完成，`status: succeeded`，与 CLI 那条路不是同一实现

**问题 2：`artifacts/` 污染没治，且这次影响很大。**

`objc/src/project.rs` 里没有任何目录排除逻辑（只有 `.mm` 跳过）。
把根指到 `runtime/cjgui` 而不是 `native/` 时：

| 指标 | 值 |
|---|---|
| `sourceFileCount` | 244（真实 191，多 53 个副本） |
| 符号总数 | **85,134** |
| 其中在 `artifacts/` 下 | **79,015（92.8%）** |

`cjgui_internal_renderer.m` 在 artifacts 里有 **17 份副本**，每份约 1,500 个符号。
所以查一个方法会返回十几条，14 条来自同一个旧文件的不同拷贝 —— 和第二节「缺陷 C」是同一个病。

`.gitignore:33` 已写 `/runtime/cjgui/artifacts/`，但只有在**根正好是仓库根**时才可能靠 .gitignore 生效；
根指到 `runtime/cjgui` 时排不掉。`objc` 适配器需要自己的目录排除表。

**修法（1 天）**：`discover_objc_project` 的 `walk_dir_tracked` 加一份排除表
（`artifacts` / `.cjgui` / `evidence` / `node_modules` / `target` / `build-script-cache`），
并读 `.gitignore`。或者退一步：至少在 `capability` 里报出"扫描含 artifacts，结果可能重复"。

#### 6.8.1 两个问题的终态（2026-10-24 复测）

**先纠正一个方法论错误：验证前没确认二进制。**

| 路径 | SHA-256（前 16） | mtime |
|---|---|---|
| `~/Desktop/CodeLattice-Tool/bin/codelattice`（**安装版 / MCP 实际用的**） | `deff17bfa07b44d2` | 10-23 21:42 |
| `~/Desktop/codelattice/target/release/codelattice`（构建产物） | `9f977a1e70997057` | 10-23 21:42 |

两个文件时间戳相同、内容不同。6.8 的报告用的是后者，所以下面的问题 1 是**旧结论**。
**以后验证一律先 `shasum -a 256` 对 manifest.json 的 `binarySha256`。**

**问题 1 终态：已修（安装版）。**

`workspace-model` 的 `SOURCE_EXTENSIONS`（`crates/workspace-model/src/lib.rs:363`）已含
`(".m", "objc")` / `(".mm", "objc")`；加上 Review5 R6 的「显式 root + 显式 language 直连」兜底
（`crates/cli/src/lib.rs:1252` 起）。实测：

| 根 | 结果 |
|---|---|
| `/tmp/objc-multi-test`（2 个 `.m`，单层，无清单） | `status: ok`、`scope: single-project`、`match: matches`、命中 2 条（L2985 / L3157）✅ |
| `runtime/cjgui/native` | 仍 `needs_project_selection` ❌ |

`native/` 失败的原因不是没修，而是兜底条件 `candidates.is_empty()` 不满足 —— 扫描出 **3 个 source-only area**
（`native`、`native/scripts`、`native/tests`），reason 写的是
`3 source-only areas and no manifest-backed project; selection is ambiguous.`

**这是真实的多根歧义保护，不是回归。** 对 CJGUI 的实用结论：
- 查单层目录可以，查 `native/` 不行；
- **日常直接用 `analyze --profile symbols --profile-page-size 0`**，它不受根歧义影响，且返回字段一样全。

**问题 2 终态：已修，且改的是三处而不是一处。**

`crates/objc/src/project.rs:28` 的 `EXCLUDE_DIRS` 与 `crates/cli/src/mcp_server.rs:2460` 的
`IGNORED_DIR_NAMES` 各加了 `artifacts`、`evidence`。两处都改是必要的：前者管全量 discovery 与头文件候选池，
后者管 mtime / delta —— **只改前者，增量扫描会把全量已排除的副本重新带回图**。点前缀目录（`.cjgui`）另有隐藏目录规则兜住。

RED 固化为 `crates/objc/tests/root_boundary.rs:272`
`snapshot_and_evidence_dirs_are_excluded_from_discovery`（构造 `src/Real.m` + `artifacts/snap-20261001/` +
`evidence/` + `.cjgui/` 各一份副本，断言只留 `src/Real.m`）。

根指到 `runtime/cjgui` 的修前 / 修后：

| 指标 | 修前（6.8 实测） | 修后（安装版实测） |
|---|---|---|
| `sourceFileCount` | 244 | **159** |
| 符号总数 | **85,134** | **6,120** |
| 其中 `artifacts/` 下 | **79,015（92.8%）** | **0** |
| 其中 `evidence/` 下 | 未单列 | **0** |
| 出现在符号里的路径 | 含 17 份 `cjgui_internal_renderer.m` 副本 | 0 份副本；`native` 5,978 / `probe` 136 / `examples` 6 |

**仍未做**：`.gitignore` 解析。根不在仓库根时 ignore 语义没设计，属单独包；静态排除表已覆盖 CJGUI 实际场景。
另有一处口径小差：`sourceFileCount: 159`，但符号里出现的不同路径有 **164** 个（`.h` 计入口径不同），
不影响结论，记录备查。

### 6.9 修正 6.5 的工时估算

实际落地 7,603 行 ≈ **D 档（7.5 天）的量**，和估算同一量级，但成分不同：

- 估少了的：`resolve.rs` 的符号消解（880 行）+ 6 个测试文件（2,700 行）—— 没算测试
- 估多了的：不需要 vendor grammar + build.rs（crates.io 直接依赖）
- 没预料到的：CLI `symbols` 子命令与 MCP `codelattice_symbol` **是两套实现**，
  前者依赖 workspace 项目选择，后者走 engine job。加新语言时要各修一次。

---

## 附：这份清单的来源

不是读文档推的，是三次被误导之后反查的：

1. 查 `Table` → 返回 30 个符号，**全来自 `artifacts/` 旧副本**（缺陷 C）
2. 想拿"public 声明全集" → `--public-only` 返回 0（缺陷 A）
3. 想按模块看规模 → `moduleCount: 0`（缺陷 B）

三次都"返回了看起来正常的结果"。**这就是为什么这些缺陷比"功能缺失"更该先修。**

### 附：第六节的复现方式

```bash
# 1. 取 grammar（无 scanner，直接编）
curl -sL https://registry.npmjs.org/tree-sitter-objc/-/tree-sitter-objc-3.0.2.tgz | tar xz
cc -shared -fPIC -O1 -I package/src package/src/parser.c -o objc.dylib

# 2. tree-sitter (Python) 0.26，版本与 CodeLattice 一致
pip install tree-sitter==0.26.0

# 3. 用 ctypes 拿 tree_sitter_objc() 的指针过给 Language()
#    直接 Language(path) 会报 "an integer is required"（0.26 移除了 .so 路径加载）
```
