# CJGUI Stage 145–892 归档清单

## 归档原因

CJGUI 历史上累积了大量 stage 审计链文件（stage 145–892）。这些文件是
同构 Bool 审计包装产物：每个 stage 只声明一个前置 write decision 后续
非变更合同，验证脚本只 grep 固定 token 并回显 `production_render_truth=false`。
它们不是 GUI 功能代码、不是 runtime truth、不是 renderer 实现，也不是
未来开发的模板。它们占据了约 278,527 行 / 20M 源码，并产生 668 条
stack frame 警告，严重干扰真实开发。

为推进四周产品目标（在真实 AppKit/Metal 窗口中显示并交互 Todo demo），
需要冻结并退出这批审计证据，把活跃源码树收敛到 357 个非 stage `.cj` 文件。

## Stage 范围

- 编号：145–892（连续，无缺号）
- 源文件数量：748 个 `.cj`
- 验证脚本数量：1410 个 `.sh`

## 修改前 HEAD SHA

```
43e44941f2b230f11942507fb92a728e1f3fdcea
```

分支：`main`

## 原路径模式

源文件：

```
runtime/cjgui/src/runtime_renderer_stage145_*.cj
  ...
runtime/cjgui/src/runtime_renderer_stage892_*.cj
```

验证脚本：

```
runtime/cjgui/native/scripts/verify_renderer_stage*.sh
```

## 如何使用 Git 查看或恢复文件

Git 历史是这些文件的唯一且完整归档。不要把 20MB 源码复制回活跃树。

查看单个文件（不修改工作树）：

```bash
git show 43e44941f2b230f11942507fb92a728e1f3fdcea:runtime/cjgui/src/runtime_renderer_stage145_baseline_semantic_verification_after_write_decision_first_slice.cj
```

列出全部 stage 源文件（在该 SHA 下，预期 748）：

```bash
SHA=43e44941f2b230f11942507fb92a728e1f3fdcea

git ls-tree -r --name-only "$SHA" -- runtime/cjgui/src \
  | rg '^runtime/cjgui/src/runtime_renderer_stage[0-9]+_.*\.cj$'
```

列出全部 stage 验证脚本（在该 SHA 下，预期 1410）：

```bash
SHA=43e44941f2b230f11942507fb92a728e1f3fdcea

git ls-tree -r --name-only "$SHA" -- runtime/cjgui/native/scripts \
  | rg '^runtime/cjgui/native/scripts/verify_renderer_stage.*\.sh$'
```

如需恢复到临时位置做只读考古（不要恢复到活跃 `src`）。该命令会把修改前
HEAD 中的 `src` 和 `native/scripts` 完整恢复到临时目录；stage 子集应分别为
748 和 1410，不会修改当前工作树：

```bash
SHA=43e44941f2b230f11942507fb92a728e1f3fdcea
DEST="$(mktemp -d /tmp/cjgui-stage-archive-probe.XXXXXX)"

git archive "$SHA" runtime/cjgui/src runtime/cjgui/native/scripts \
  | tar -x -C "$DEST"

find "$DEST/runtime/cjgui/src" \
  -type f -name 'runtime_renderer_stage*.cj' | wc -l

find "$DEST/runtime/cjgui/native/scripts" \
  -type f -name 'verify_renderer_stage*.sh' | wc -l
```

## 性质声明

这些文件是**历史审计证据**：

- 不是 GUI 功能；
- 不是 runtime truth；
- 不是 renderer 实现；
- 不是 backend-ready truth；
- 不是 production truth；
- 不是未来开发的模板。

## Experimental public API 退役边界

本次归档同时退役两个由 stage 链声明的 experimental 仓颉 public readiness API：

```cangjie
public func cjguiExperimentalComponentPreviewApiReady(): Bool
public func cjguiExperimentalComponentCommitApiReady(): Bool
```

- 原声明分别位于 stage758 与 stage890；源码注释均明确“不承诺 stable compatibility”。
- 两个函数只投影 stage readiness Bool，不提供真实 preview、commit、render 或 state write 能力。
- 修改前的仓库内消费者全部位于 stage759–891，已随本批 stage 文件一起归档。
- 归档后的 `runtime/cjgui/src`、`runtime/cjgui/demo` 消费扫描为 0；10 个独立 demo 验证均通过。
- 这是有意的 experimental public API breaking removal，不影响 stable public API，也不改变 public C ABI。
- 如需考古或恢复签名，必须使用本清单记录的修改前 HEAD，不得在活跃树中重新创建同名 readiness wrapper。

## 禁止事项

- **明确禁止继续创建 stage 893 或任何新的 stage/audit wrapper。**
- 不要把本批文件复制回活跃源码树、docs 目录或任何活跃源码目录。
- 不要基于同构 Bool 审计包装模式重新引入新的审计链。

## 当前产品目标

四周内，让仓颉 Todo demo 在真实 AppKit/Metal 窗口中：

1. 显示任务列表；
2. 响应至少一次点击；
3. 更新任务状态；
4. 重绘。

下一阶段是把 `labs/macos_bridge_smoke` 提取为极窄 internal renderer，
而非恢复任何 stage 审计链。详见
`runtime/cjgui/ACTIVE_DIRECTION.md`。
