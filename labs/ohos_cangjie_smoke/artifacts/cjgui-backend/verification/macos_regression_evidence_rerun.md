# macOS 同源回归复跑（2026-09-26，第六轮）
应用：settings_counter_window_app（同源 settings_counter_application + 共享核心含 A1 全部改动重建）

INCREMENT v0→v1 APPLIED true；旧版本 v0 重放 → APPLIED false/CONFLICT true/version_conflict（拒绝）；
EDIT_NAME emoji（设备🚀名称 16 UTF-8 字节）→ APPLIED true/name_changed → 读回 32 hex 精确；
调试期间误写 hex 字面文本与 '00'（探针笔误，均被 owner 如实接受并精确读回——额外证明了任意 UTF-8 值的写读一致性），最终恢复 '我的设备' → APPLIED true/精确读回。
截图核对更正：`macos_regression_screen.png` 实际截到微信前台，不能证明 CJGUI 窗口画面；该图不纳入仓库快照。此轮保留 READY/descriptor 与公开协议的写入、冲突拒绝和精确读回证据，当前版本的窗口视觉反馈待重新截取并核验。descriptor=/private/tmp/tmpDirZviM6T/connection.cjgui

## alias 字段核验（同轮补）

EDIT_ALIAS "别名A"（3 UTF-16 码元，≤8 上限）→ APPLIED true / v5→6 → 读回 alias
STRING 7 E588ABE5908D41 = "别名A" 逐字节精确。alias 读写核验完成。
