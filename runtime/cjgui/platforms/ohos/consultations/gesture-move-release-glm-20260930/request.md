只读聚焦咨询。当前 normal thermo HAP sha93bebe227ccf4d96af7c9c48476e2318fdb15ce8d06dd811177cd932d90e8f92、PID5552、surface377x487逻辑vp，真实uitest拖动，host已声明experimental_exponential。请质疑我的归因，不修改/构建/操作桌面。
事实：native终态多次 velocity约0.05 px/ms (>0.01阈值)，drag -100，完整公共WINDOW_VIEWPORT最终accepted增量严格100，无尾部位移；generated拖动-40、窗口最终offset=40也无尾部。原件 normal_terminal.raw.txt、本次run下hand_interleaving_r1/result.json和generated_interleaving_r1/result.json。
怀疑：native BEGIN发takeover:或POINTER_BEGIN，窗口发scrollReleaseTicket=epoch；每个相同epoch MOVE kind30 by:<dy>又无条件takeOverScrollActivity清零该票；END fling:<velocity>因此拒绝。现存确定性test把带8的by:40当作“显式定位”并要求清零，未覆盖正常BEGIN→MOVE→END。积分保持原Astra裁决，不重写。
只查以下关键文件相关符号：
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj：applyViewportScrollStep, kind30 gestureBindingReady/takeover路由、dispatchPointerEvent BEGIN、takeOverScrollActivity、stepWindowActivities。
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp：raw BEGIN/MOVE/END与fling文本发送、gesture identities。
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts/fixtures/scroll_activity_snapshot_test.cj
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts/test_scroll_activity_snapshot_cjpm.py（生产摘录）
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/macos_application_host.cj（activity调度）
要求：区分证据/推断，检查上述实际时序是否充分解释无惯性。给最小机制修复，区分native同手势MOVE（非零精确票）与epoch0的滚轮/显式step；旧MOVE、旧END、同值reveal、成功END是否要一次消费票据，各自为何。不得以放宽旧END判据、跳过MOVE或另造活动协议绕过问题。给生产摘录反例和normal拖动→惯性→触摸停止→reveal→输入/公开写入验收建议。主树macOS applyViewportScrollStep没有releaseTicket/fling族，E线正在修改，勿建议整文件覆盖。
