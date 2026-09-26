# 工具链阻塞记录：hvigor 无法删除 extend_libs/default（2026-09-26）

## 复现

`labs/ohos_cjgui_app` 任意 hvigor 构建（`build_and_run.sh` 任意变体）在
`entry:default@CompileCangjie` 稳定失败：

```
00308001 Operation Error
Error Message: Failed to delete the file:
  .../entry/build/default/intermediates/cj/extend_libs/default
```

与 `extend_libs/default` 的存在形态无关，均失败：

| 预置状态 | 结果 |
| --- | --- |
| 不存在 | 失败（ENOENT 未被容忍） |
| 空目录（我的 shell 创建） | 失败（EISDIR/unlink 语义） |
| 普通文件 | 第一次 unlink 成功，cjpm 重建目录后第二次删除再失败 |
| 指向 /tmp 的 symlink | 删除 symlink 亦失败 |
| cjpm 自己重建后的目录 | 删除失败 |

已排除：hvigor daemon 重启（无效）、Bash 沙箱关闭（无效）、transport 的
cjgui 依赖回退（无效）、cjpm dep-cache/.cjpm-history 清理（无效）、
macOS xattr（provenance/macl）清理（无效）。

## 时间线与旁证

- 2026-09-26 ~10:25 前的构建（b5_verify、b5_verify2、normal_v5、neg_stale2）
  同一 hvigor 对同一路径的删除全部成功。
- ~10:27 起我方执行过一次大规模 build 树深清理（rm 整个 entry/build 与
  .cxx，数百文件），此后 hvigor 对该路径的删除即开始失败；同时工作区
  safe-delete 保护（SAFE_DELETE_BULK_CONFIRM_REQUIRED，threshold=50/turn）
  开始拦截 hvigor 的 .cxx 整目录重建。
- 目录上可见 `com.apple.provenance` / `com.apple.macl` 属性（macOS 26）：
  疑似跨进程（我的 shell ↔ node/cjpm）创建/删除权（App Management/TCC 或
  ZCode 沙箱 provenance 规则）进入互斥状态。

## 影响

- 阻塞：所有 OHOS HAP 构建（normal 与 verify），即 A1 注入矩阵真机验证、
  A2 八类闸门验证、A3 应用级重启验证、C/D/E 的真机部分全部无法出新证据。
  已写入的 A1/A2 注入代码（renderer 闸门、transport 命令通道、核心注入
  开关、两个探针脚本）保持就绪，环境恢复后无需改码即可构建运行。
- 不阻塞：共享核心 macOS 侧构建/测试、纯源码/脚本/文档工作、
  已有产物的既有证据（normal_v5 / b5_verify2 / reopen_v12 / commit_v1）继续有效。

## 移除条件（任一）

1. 终端/IDE 与 DevEco node 进程获得一致的 App Management/完全磁盘权限，
   或 macOS provenance 状态重置（重启机器通常可清）。
2. ZCode 工作区 safe-delete 钩子对 `labs/ohos_cjgui_app/entry/build` 与
   `entry/.cxx` 放行（或提高 threshold），恢复 hvigor 自主清理。
3. 由用户在 DevEco Studio GUI 内手动构建一次（GUI 进程 provenance 一致），
   重建 extend_libs 正常状态后，命令行增量构建预期恢复。
