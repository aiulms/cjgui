# macOS 同源回归证据（2026-09-25）

应用：examples/settings_counter_window_app（与鸿蒙同一份 settings_counter_application
domain/controller 源码；AppKit/Metal 宿主差异只在 main.cj 的 CjguiMacosApplicationHost）。

启动日志（/tmp/cjgui_macos_sc3.log）：
- CJGUI_SETTINGS_COUNTER_READY DESCRIPTOR_PATH /private/tmp/tmpDirVM2tpS/connection.cjgui
- CJGUI_SETTINGS_COUNTER_READY PROTOCOL CJGUI_SHARED_OPERATION/2

外部操作（shared_operation_core/client.py，官方 unix socket + 描述符通道）：

1. invoke 0 INCREMENT --target 9700
   → APPLIED true / VERSION_BEFORE 0 / VERSION_AFTER 1 / REASON counter_changed
2. get → VERSION 1, FIELD 9700 count INTEGER 11, enabled BOOLEAN 1
3. invoke 1 INCREMENT --target 9700（旧版本反例）
   → APPLIED false / REASON version_conflict

与鸿蒙侧（external_chain_evidence.json）同语义：同 owner、同授权、同版本契约、
同拒绝原因码。视觉：screenshots/e1_macos_same_source_app.png（同源自绘场景，
截图时为该实例初值状态；外部修改后的读回以本文件协议文本为准）。
