只读聚焦咨询：最终 normal HAP 验收如何有判别力覆盖真实非空选择拒绝/恢复，避免人为放宽或重试直到绿。不要写代码、构建、操作设备。请质疑我的“Agent同值换版后下一笔应拒绝”归因。
框架 /Users/jiangxuanyang/Desktop/cangjie；冻结最终 /Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/frozen/framework/runtime/cjgui。
normal r8 SHA e6ab68aa7587881014c734312bc1123fd382eb38d215d4047db2599e0ce8884d，PID25227。
事实：真实长按 beta 选区11:15，owner v2，正文 前行保留\nalpha beta😆 gamma\n末行保留。Agent一次REPLACE_RANGE同值前字 v2->v3，旧v2请求APPLIED false CONFLICT true REASON version_conflict。观察脚本把正常拒绝回包误判为ERROR导致中断，未注入人输入。约1秒后native req1 ctx2 v3 selection11:15实际proxy正文和getter安装成功，窗口PHAROS_OHOS_RESTORE_ADOPTED count=1 failed=1 pending=false。随后57秒才一次人输入拒绝输入，正确接受为 v4 alpha 拒绝输入😆 gamma，实际不是拒绝。这是观察缺口，不是产品恢复错误。之前r6旧normal有selection_version_stale的人输入被拒后实际安装和采纳，然后一次成功替换，原日志完整保留。
当前r8改动仅privateOHOS真实painted词选择/拖动两端/防旧echo，不改text_session或恢复协议。新final须同HAP一次 人->Agent->人，非空选择恢复后下一笔替换准确，拒绝不写owner，失败超时终态保留之前同源测试反例。不能用verification seam冒充normal，不能通过不断竞速重试得到拒绝。
请给：1)当前机制是否应在自动恢复已完成后接受下一笔；2)无需生产seam/概率竞速的normal合法拒绝触发是否存在，有则具体公开行为与预期；3)若平台事件无法确定性交错，怎样严谨区分同版本生产接缝反例与final normal消费者证据，哪些必做仍未完成。根因依据来自下列局部文件，禁止全仓盘点：
- frozen/framework/runtime/cjgui/platforms/ohos/snapshot/src/text_session.cj 650-825
- frozen/framework/runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj 5790-6025,6250-6415
- frozen/framework/runtime/cjgui/platforms/ohos/scripts/fixtures/window_restore_adoption_snapshot_test.cj 275-350
- docs/plans/2026-09-26-harmonyos-executor-handoff.md 309-334,385-393
以上相对冻结路径均基于master artifacts/h-overnight-final-20260930。
