同一问题的一次新证据追问，只读，不写、不构建、不操作桌面。
请先看本目录answer.md与implementation-decision.json。已实施私有native原子validate/replace，仍沿原FIFO owner。之所以保留原子guard：公开Agent修改在Cangjie host线程和accepted/native同步上执行，不在ArkTS事件循环；JavaScript check+assign独占假设不成立。实现同时onMenuInstalled把native当前文本同步到同一m.draft/this.imeText，故你提醒的“native-only旧正文覆写”已有明确同步。
但真实新反例：r14b PID22173 normal HAP d6eb83f0…8965d，剪切alpha range5:10，owner正确删5:10。native目标caret5，程序this.imeText更新TextArea后，早于实际onChange的30ms重装被下一帧末尾reset覆盖：
18:33:17.937 native replace accepted, range5:10；17.974菜单cut accepted；18.005 caret install getter[5,5)；18.067 menu install getter[5,5)；18.070实际TextArea onChange len23，之后onTextSelectionChange[23,23)正常流forward到native。下一次真实PasteButton SUCCESS、18:33:19.764原子replace捕获23:23合法，在文末粘贴alpha（owner完整为'前行保留\n beta😆 gamma\n末行保留alpha'，不是目标）。原始失败保留：
/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/91-final-normal-clipboard-r14b/menu-failure.hilog.txt
重点onChange/onTextSelectionChange与onMenuInstalled：/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets
框架模板：/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/arkts/cjgui-text-menu.ets 与 cjgui-text-proxy.ets
拟修：框架共有短期MenuInstall任务，捕获同一mount+targetText+targetSelection，实际目标全文onChange回声到来之前不提前收口；收到确切回声后下一帧复用armProxySelection/installProxySelection实际getter安装。此程序安装期间所有selection事件仅做安装观测，只有文本已实际观测+getter/selection报告等于目标才forward并释放；迟到程序文末reset不作为人的导航。2.5s有界deadline终态日志，隐藏菜单直到实际安装收口。若真人value不同/onWillInsert/onWillDelete先到，显式supersede而不吞真人输入；上下文换版/卸载旧mount取消，不能用旧task阻挡新owner。单独投影任务不借恢复request/ACK票据，不造业务owner或新编辑协议。
质疑此方案与回调顺序，给最小可靠修法、能够判别“getter先到但onChange后reset”反例。是否更可靠使用TextAreaController.setText能带selection参数？请核本机对应SDK而非猜其他平台。原生按钮复制/剪切未触发blur，PasteButton本轮SUCCESS也未触发blur，焦点风险在本机这轮未重现。
