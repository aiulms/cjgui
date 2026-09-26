# CJGUI 鸿蒙后端第一阶段 — 验证总清单（2026-09-25）

环境：DevEco Studio 26.0.0 / HarmonyOS 6.1.1(24) 模拟器 Pura 90 (arm64) /
仓颉 SDK harmonyos-cangjie-26.0.0.105（cjc 1.2.0-beta.rc3）/ macOS 仓颉 1.1.3。
源码基线：runtime/cjgui 快照指纹 `94dd3833…`（FINGERPRINT.txt，
含 cjgui_internal_renderer.h `10db8ed2…`），manifest：
`labs/ohos_cjgui_app/entry/cjgui_sync_<fp12>.manifest`（逐文件 sha256）。

## 集中验收六项

1. **核心真运行 ✅ 已验证**
   - HAP 内 `libs/arm64-v8a/libcjgui.so`(11.2MB)+libcjgui_app.so+libcjgui_shared_operation_core.so
     为 ELF aarch64；官方 loader 日志 `LoadCJLibrary InitCJLibrary: libcjgui_app.so`。
   - 双路调用探针：官方互操作 `official=30/1129465333`（托管 canary+中文串+计数一致）；
     原始 @C `raw=4848766241776599041`（=0x434A4735_00000001 精确往返）`heap=6083`
     （GC 分配+UTF-8 字节精确）。证据：screenshots/a1_first_screen.jpeg、run/a1_load_probe_evidence.log。

2. **画面真消费 ✅ 已验证**
   - 核心场景（10 节点）驱动 OH_Drawing on-screen GPU surface 自绘：
     中文标题、混排样例、计数值、增减按钮（填充+描边）、布尔开关、状态行。
   - 增量提交修复后 rebuild 全场景保留（b7 截图）。
   - 证据：screenshots/b1_scene_presented.jpeg、b7_increment_fixed.jpeg、d1/d3。

3. **双入口同内容 ✅ 已验证**
   - 人：uinput 点击 增加 → ACTIVATE(27) → owner INCREMENT → 新场景（b5/b6/b7）。
   - 外部：hdc fport + python 客户端 GET_CONTEXT / INVOKE（应用内 TCP→
     `connection.dispatchPayload` 桥，模拟器开发通道）→ 同 owner 同规则。
   - 人接续：外部改至 v9/count15 → 人点击 → count16@v10 外部读回。
   - 拒绝反例（内容与版本保持，随后合法请求成功）：旧版本 version_conflict、
     伪造授权 unauthorized_caller、未知动作 invalid/unauthorized_action、
     停用后 counter_disabled、恢复后正常。
   - 证据：verification/external_chain_evidence.json（两次完整 C1–C7 run）。

4. **生命周期可恢复 ✅ 已验证**
   - 两轮 XComponent 条件挂载/卸载 ×10：10 次销毁 + 11 个创建代际；
     owner 计数/版本零丢失，场景重建后可继续点击（第二轮循环后 tap count 12→13 v5）。
   - cycle 后首击命中重提交窗口被按契约拒绝（无部分写入），随后合法输入恢复——
     保留为契约行为证据（d1 截图状态行）。
   - 空闲：30s 0 次 present 提交；唤醒源=宿主循环 pump_event bounded-sleep ≤62.5Hz。
   - 证据：verification/lifecycle_cycles.log、screenshots/d1/d3。

5. **平台可复用 ✅ 已交付**
   - 框架入口：runtime/cjgui/platforms/ohos/README.md（装载模型/构建入口/
     避坑清单/生命周期契约/能力矩阵）。
   - 独立示例：runtime/cjgui/examples/settings_counter_application（共享 owner）
     + settings_counter_window_app（macOS 入口）。
   - 可复现 HAP：labs/ohos_cjgui_app/scripts/build_and_run.sh 一键全链。

6. **工具有实际参与 ✅**
   - Laya：开工两问（HTTP 200，model=laya-rl-agent，choice 合法），
     load_model=insufficient 采纳、render_route=insufficient 部分采纳，
     采纳理由落档 laya/kickoff-adoption.md。
   - Astra（gpt-6-astra/max，exit=0）：五点修正全部采纳；
     `consultations/platform-contract/{request,answer,adoption}.md`。
   - 落实后验证：本清单全部条目即为咨询结论的实施验证
     （Hybrid 装载、渲染线程、增量事务、resizeVersion、空配置语义、
     dispatchPayload 预案等）。

## macOS 同源回归 ✅

同一份 domain/controller（examples/settings_counter_application）在 macOS
（AppKit/Metal 宿主）编译运行：`client.py get` → count 10 v0；`invoke 0 INCREMENT
9700` → APPLIED true v1 count 11；stale v1 DECREMENT → version_conflict。
证据：screenshots/e1_macos_same_source_app.png（同源自绘场景）。

## 分类收口

- **已验证**：上表 1–6 与 macOS 回归。
- **已实现未验（标记边界）**：显示器实际呈现以模拟器截图为准（未做仪器测量）；
  resize 只验证同尺寸重建代际推进，未做尺寸连续变化扫描。
- **环境阻塞（已绕行，非产品失败）**：escape SDK 不打包运行时库（闭包脚本补齐）；
  沙箱 /tmp 不可写（unix 传输不可用 → dispatchPayload TCP 桥，fport 标记
  模拟器开发通道）；hvigor 不感知 .a 变化（构建脚本强制重链）。
- **下一阶段**：系统可编辑文本/IME、范围文本、图片资源、非空命令菜单/数据传输、
  悬停/按压视觉层、普通已安装应用的沙箱外连接、真机与性能基线。

## 诚实边界声明

- 「提交成功」= OH_Drawing_SurfaceFlush 成功；GPU 完成观察在 OHOS 路径不可得，
  display progress 的 observedMetalCompletion 恒为 0/‑1（不伪造）。
- 截图为模拟器 framebuffer 证据，不等同真机呈现。
- 悬停/按压视觉层未实现（不影响业务正确性）。
- 阶段内曾出现两类崩溃（hilog 隐私掩码期的一次首启 SIGABRT、
  __dynamic_cast 符号冲突 SIGSEGV），均已定位修复并在最终构建上复验通过。
