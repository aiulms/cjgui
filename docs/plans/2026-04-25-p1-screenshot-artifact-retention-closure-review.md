# P1 Screenshot Artifact Retention Closure Review

日期：2026-04-25

状态：完成

类型：bounded implementation closure review

本轮 execution card：

- [2026-04-25-p1-screenshot-artifact-retention-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-execution-card.md)

## 1. 本轮目标

本轮只围绕现有 screenshot verification harness 的 artifact retention / cleanup policy 做极窄调整：

- 成功 artifact 继续默认删除。
- 失败 artifact 只允许短期、受控、可解释地保留。
- 启动时清理历史 `/tmp/cjgui-p1-screenshot-verification.*` 残留目录。
- 清理必须限定 pattern 和 24 小时 TTL。
- 清理不得删除任意 `/tmp` 内容，不得跟随 symlink，不得删除当前运行实例临时目录。

本轮不改变 runtime、native bridge、仓颉入口或构建脚本。

## 2. 实际 Write Set

本轮实际修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [2026-04-25-p1-screenshot-artifact-retention-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

本轮未修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`

## 3. Landed Code Reality

`verify_user_visible_window_screenshot_verification.sh` 现在在启动 smoke 前输出并执行历史 artifact cleanup：

```text
cjgui screenshot verification: cleanup_requested=true
cjgui screenshot verification: cleanup_pattern=/tmp/cjgui-p1-screenshot-verification.*
cjgui screenshot verification: cleanup_ttl_hours=24
cjgui screenshot verification: cleanup_deleted_count=<n>
```

清理规则：

- 只扫描 shell glob `/tmp/cjgui-p1-screenshot-verification.*`。
- 只删除目录。
- 跳过 symlink。
- 跳过当前运行实例临时目录。
- 只删除 mtime 超过 24 小时的目录。
- 不扫描或删除任意其他 `/tmp` 内容。

成功路径仍然删除本次 artifact，并输出：

```text
cjgui screenshot verification: artifact_deleted=true
cjgui screenshot verification: artifact_retention_reason=none
cjgui screenshot verification: artifact_retention_failure_classification=none
cjgui screenshot verification: artifact_retention_path=none
cjgui screenshot verification: artifact_retention_ttl_hours=24
cjgui screenshot verification: artifact_delete_strategy=none
cjgui screenshot verification: artifact_retained=false
```

失败且 artifact 已创建时，harness 会保留 artifact 并输出：

```text
cjgui screenshot verification: artifact_deleted=false
cjgui screenshot verification: artifact_retention_reason=failure_diagnostic
cjgui screenshot verification: artifact_retention_failure_classification=<classification>
cjgui screenshot verification: artifact_retention_path=/tmp/cjgui-p1-screenshot-verification.*/target-window.png
cjgui screenshot verification: artifact_retention_ttl_hours=24
cjgui screenshot verification: artifact_retained=true
cjgui screenshot verification: artifact_delete_strategy=manual rm -rf /tmp/cjgui-p1-screenshot-verification.*
```

## 4. 验证记录

### 4.1 Forbidden 文件 Hash Baseline

已在实现前生成 forbidden 文件 hash baseline：

```bash
shasum \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh
```

baseline 输出保存到：

```text
/tmp/cjgui-p1-artifact-retention-forbidden-before.sha1
```

### 4.2 Red Check

实现前创建了受控旧目录：

```text
/tmp/cjgui-p1-screenshot-verification.stale-test-red.B6EHiv
```

旧 harness 运行退出码为 `0`，但该 stale 目录仍存在，因此确认 cleanup policy 尚未实现。该 red-check 目录随后手动删除。

### 4.3 Shell 语法检查

命令：

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：退出码 `0`。

### 4.4 Stale Cleanup 与 Screenshot Verification Harness

创建受控旧目录：

```text
/tmp/cjgui-p1-screenshot-verification.stale-test.RAc5Nb
```

运行命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：

- harness 退出码：`0`
- 日志路径：`/tmp/cjgui-p1-user-visible-window-screenshot-verification.log`
- stale 目录清理结果：`stale_dir_cleaned=true`
- cleanup summary：`cleanup_requested=true`、`cleanup_pattern=/tmp/cjgui-p1-screenshot-verification.*`、`cleanup_ttl_hours=24`、`cleanup_deleted_count=1`
- 成功路径 artifact 结果：`artifact_deleted=true`、`artifact_retained=false`
- retention summary：`artifact_retention_reason=none`、`artifact_retention_failure_classification=none`、`artifact_retention_path=none`、`artifact_retention_ttl_hours=24`、`artifact_delete_strategy=none`
- 最终分类：`success=true reason=none`

### 4.5 Auto-close Harness 回归

命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- 退出码：`0`
- 原有 auto-close / capability / frame metadata / Metal readback summary needle 仍通过。
- 日志仍明确：`cjgui verify: this is not user-visible window verification`。

### 4.6 Forbidden 文件 Hash 复核

实现后再次生成 forbidden 文件 hash，并与 `/tmp/cjgui-p1-artifact-retention-forbidden-before.sha1` 比对。

命令：

```bash
shasum \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh
diff -u \
  /tmp/cjgui-p1-artifact-retention-forbidden-before.sha1 \
  /tmp/cjgui-p1-artifact-retention-forbidden-after.sha1
```

结果：退出码 `0`，无 diff。

确认：

- `cjgui_macos.m` 未变化。
- `cjgui_macos.h` 未变化。
- `src/main.cj` 未变化。
- `build_and_run.sh` 未变化。
- `verify_auto_close.sh` 未变化。
- `verify_user_visible_window_screenshot_feasibility.sh` 未变化。

### 4.7 链接检查与 Diff Check

closure review 链接检查：

```bash
rg -n "2026-04-25-p1-screenshot-artifact-retention-closure-review\\.md" \
  /Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md \
  /Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md
```

结果：退出码 `0`，closure review 可从 `GUI_TASK_TRACKER.md` 和 `docs/plans/README.md` 找到。

diff whitespace 检查：

```bash
git diff --check
```

结果：退出码 `0`。

## 5. Stop-line 复核

本轮守住：

- 未修改 native bridge。
- 未修改仓颉入口。
- 未修改 build script。
- 未修改 auto-close harness。
- 未修改 screenshot feasibility harness。
- 未新增 public C ABI / runtime API。
- 未保存成功 screenshot artifact。
- 未提交任何 screenshot artifact。
- 未建立 baseline / golden image。
- 未做 pixel diff。
- 未做 frame hash。
- 未做 offscreen renderer。
- 未读取整图像素。
- 未输出 raw bytes。
- 未设计 Renderer / Scene / Widget / Layout / DSL。
- 未把 smoke demo 宣称为正式 GUI runtime。

## 6. Residual Risk

本轮仍不证明：

- full GUI verification。
- screenshot artifact 可作为长期证据。
- pixel diff / frame hash 可用。
- CI / headless 可复核。
- 用户桌面隐私风险已经完整解决。
- 多显示器、遮挡、Space / Mission Control、frontmost app、timing 的稳定性。
- Renderer / Scene / Widget / Layout 设计已经开启。

## 7. Next Opening

本轮完成后建议下一步仍为 docs-only：

> `P1 pixel diff / frame hash prerequisites preflight`

原因：

- artifact retention / cleanup policy 已有 first slice。
- 但 baseline / golden image、pixel diff、frame hash、阈值、隐私、CI / headless 和 artifact 证据生命周期仍未冻结。
- 不能直接进入 pixel diff / frame hash 实现。
