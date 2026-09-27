# macOS 同源回归——覆盖 settings_counter.cj 共享夹具改动（2026-09-26）

范围：本轮鸿蒙 D 夹具改动（新增节点 44=d-clip-btn-box/45=裁剪按钮/46=d-noclip-btn-box/47=不裁按钮、
节点 43 专属文字色、applyUiEvent 对 nodeId 45/47 的 INCREMENT 分发）编入同源
`runtime/cjgui/examples/settings_counter_application`，macOS `settings_counter_window_app`
以 path 依赖消费同一控制器源码。

## 结果
1. **构建**：`cjpm build` success（共享夹具代码对 macOS 目标编译通过）。
2. **启动**：窗口应用启动（Metal device/command queue OK），descriptor
   `/private/tmp/tmpDiragB4GR/connection.cjgui`，pump 循环服务外部协议。
3. **协议核验（官方 client）**：
   - GET_CONTEXT：域字段不变（count/enabled/name/alias——夹具节点不影响公开字段）
   - INCREMENT v0→v1 APPLIED true（counter_changed）
   - 旧版本 v0 重放 → APPLIED false/CONFLICT true/version_conflict（拒绝）
   - EDIT_NAME `设备🚀名称`（printf 无换行 16 UTF-8 字节）→ APPLIED v4 → 读回
     16 字节逐字节精确
   - EDIT_ALIAS `别名A` → APPLIED v3；恢复 `我的设备` → APPLIED v5 精确读回
4. **新增节点不破坏既有场景**：buildUi/投影/owner 应用全程无错，协议行为与
   改动前一致（含中文与 emoji 混排）。

结论：共享夹具改动对 macOS 同源消费者无破坏，回归通过。应用已正常关闭。

## 原始输出关联
- 构建/启动 stdout：`macos_regression_build_stdout.log`（Metal capability、bridge init、descriptor 输出）
- 客户端协议原始回执：`macos_regression_client_raw.log`（INCREMENT/冲突/EDIT_NAME 16 字节/恢复/alias）
