只读追问；本题唯一一次新证据追问，沿原裁决。不要修改/构建/操作桌面，只查列出文件。
新事实：独立真实 TextArea HAP com.pharos.mark.hdeleteprobe20260930：
1. onWillDelete backward offset=2，deleteValue=重音U+0301，实际selection2:2；返回false后正文仍e+重音，取消有效。
2. 放行时 willDelete→willChange(old=e+重音,new=e,rangeBefore1:2,After1:1)→didDelete offset=1→onChange e→selection1:1。Will与Did offset不同。
3. 在onWillDelete内同步controller.deleteText({start:0,end:2})然后returnfalse：实际onChange空串，selection0:0，159ms后单次输入X得到X。无第二笔DidDelete。
4. 在onWillChange中才deleteText全簇然后returnfalse，反而正文保留旧e+重音，接续得到Xe+重音，失败；不采用。
证据路径 artifacts/h-overnight-final-20260930/platform-delete-probe/callbacks-01、callbacks-02、callbacks-03（result及hilog）；平台源app/entry/src/main/ets/pages/Index.ets当前是失败的WillChange实验版。
5. ICU shell CLI ubrk_open返回缺rules data错误2；同一服务在普通HAP root locale成功，e+重音/家庭/肤色/旗帜/中文/CRLF全部真实边界正确。initial.hilog.txt有原数。
6. 已按你认可的ABI实现ohos_renderer.cpp OHOS_GRAPHEME_SERVICE_BEGIN/END的纯ICU服务、状态24，宿主提取真实代码2/2测试，目标HAP还未测此生产ABI。

提出替代以避免新异步owner删除事务：仅onWillDelete真实方向删除回调（不从keycode/值差分猜），冻结当前mount、实际draft、controller.getSelection、preview状态，共同registry/native纯查询ICU相邻簇。非空明确选区/多簇删除/preview照原精确路径，不提升；partial scalar删范围只在collapsed真实删除、offset公式和substring完全匹配时，由同一回调同步controller.deleteText全簇，确认selection结果后returnfalse取消原操作。真实onChange全值回传原native kind51→唯一owner机制，原editingText实际跟随平台，无异步恢复间隙，无新owner写入ABI。产品仅挂钩+getSelection/deleteRange，算法归CJGUI。原路径owner版本守卫仍会拒绝外部换版；拒绝N1恢复。
请质疑该方案：同步deleteText是否可以通过严格guard在本阶段实现，还是必须原异步request+receipt方案？如何处理onWillDelete无法预知compound replace、回调重入、实际selection观测版本、程序deleteText无onWillDelete、服务不可用、owner换版以及恢复中输入？给最小可实现公共contract和有判别力验收；不要再扩大扫描范围。只拿实际平台证据判断，不能认定未测的candidate路径已经绿。
