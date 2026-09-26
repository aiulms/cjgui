# C selection/组合态 真实键盘人工核验证据

日期：2026-09-26。核验人：用户（真实鼠标 + Mac 物理键盘操作模拟器窗口）。
产物：verify-transport 变体，run_id=`selection_redraw_fix`（hap sha256 见 run 目录）。
结论：**人工核验通过**——自绘字段上的真实点击、真实键盘键入、系统选区 UI、
选区高亮、失焦结算与 owner 读回全部成立。
本 WIP 仓库快照不收录人工截图；可复核的协议与事件记录见下表及同目录日志。

## 1. 本轮人工链路（2026-09-26 17:5x，PID 6524）

| 步骤 | 用户动作 | 服务端证据（selection_manual_runlog.txt） |
| --- | --- | --- |
| 点击自绘名称字段 | 真实鼠标点击 | `ime focus payload={"action":"focus",...}` → `ime proxy mounted ctx=1` |
| 代理获得焦点 | — | `ime requestFocus threw attempt=0` → `sent attempt=1` → `ime proxy FOCUSED`（重试链命中） |
| 输入法会话附加 | — | `ime showTextInput ok field=counter-name` |
| 系统选区 UI | 长按出现剪切/复制/粘贴菜单与选择手柄（人工观察） | `ime select [2,2)/[1,1)/[0,0)...`（系统手柄移动逐帧上报） |
| 全选 | 系统全选（鼠标拖动手柄不精确，用户改用全选） | `ime select [0,4) rc=0`——真实非空选区到达渲染器 |
| 选区高亮 | **自绘场景中「我的设备」整段蓝色高亮可见**（人工观察） | `ime select [0,4) rc=0` 仅证明选区事件到达；本快照不附视觉图像 |
| 失焦结算 | 点击字段外 | `ime blur settle ctx=1 settled=1 node=24 text=我的设备` |
| owner 读回 | 外部通道 GET | `name=我的设备 version=2`（human_external_human_probe.py read） |

## 2. 真实键盘组合态（同日早前会话，PID 5346/14181）

- 键入逐字符到达代理：`ime proxy onChange len=2→3→4→6...`（增量预览）。
- 组合态含 emoji 提交：`ime commit len=16 ctx=2`（显式提交 rc=0）；
  失焦结算 `测试😆设备`（emoji 进 owner 值并渲染）。
- 再聚焦缓冲正确：`ime proxy mounted ctx=3 ... text=测试😆设备`（初值来自 owner）。

## 3. 修复根因（本轮核验过程中发现并交付）

1. **键盘输入不生效**：requestFocus 首次（50ms）在控件挂载完成前抛异常且无重试、
   无日志；且只设 ArkUI 焦点不附加输入法会话，模拟器键盘键入无法路由。
   修复：Index.ets 焦点重试链（100–500ms）+ `showTextInput()` 显式附加会话 +
   onFocus 用户可见状态信号。日志实锤：`attempt=0 threw → attempt=1 FOCUSED`。
2. **选区高亮不出现**：`ohos_renderer_ime_set_selection_ctx` 与长按全选只写会话
   状态、不请求重绘（选区是纯视觉投影，不 bump 场景版本 → 无新帧）。
   修复：两处补 `g_render.post(RedrawJob)`（与预览路径同机制，change-gated）。
3. **T4 断言契约过时**：onSubmit 走注册表路径（`commit reason=submit ctx rc`），
   脚本仍断言页面级 `ime commit ... len=`。更新为：注册表 rc=0 + onChange len=8
   + 外部通道 owner 值精确读回（`我的设备回车提交`）。

## 4. 机器验证配套（同一构建）

- `verify_ime_proxy_chain.sh` T0–T6：**PASS（failures=0）**，含 T4 新契约三断言。
- `verify_selection_probe.py`：选区事件到达渲染器 OK；**选区高亮像素可见 OK**；
  2 项 FAIL 为已知自动化边界（uitest 无法驱动 0.01 透明代理的系统选区拖拽
  与替换输入）——该边界正是本人工核验存在的理由。
- T5/T6 负对照（迟到提交 rc=1、结束后无活会话）：OK。

## 5. 已知边界（如实记录）

- 用户以鼠标操作选择手柄不够精确，最终经系统「全选」完成——手柄拖拽的
  精细操作属系统输入法 UI 能力，框架侧选区同步（逐帧 rc=0）已贯通。
- 自动化注入不达隐藏代理的组合态（opacity 0.01），真实键盘路径只能人工核验；
  本文件即该单次人工核验的归档。
