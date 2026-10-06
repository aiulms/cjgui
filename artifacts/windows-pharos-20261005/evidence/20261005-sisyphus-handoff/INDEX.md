# Windows Pharos 接续证据索引（2026-10-05，Sisyphus 执行轮）

目标：现有 Pharos 在 Windows 完成打开→编辑→预览→选区→替换→Undo/Redo→Agent→保存→重开。
VM：`{9e5dedb2-90f8-4d21-80f0-41e194407fab}`（运行中），SDK 来宾 `C:\Users\jiangxuanyang\AppData\Local\Programs\Cangjie` 1.1.3（`bin\cjc.exe` + `tools\bin\cjpm.exe`），target `x86_64-w64-mingw32`，ARM64 来宾（x64 模拟）。

## 本轮结论速览

- 正式同步→构建→闭包链已收敛可用；六个依赖包干净重建全绿。
- 三个输入接缝：RED 复现 → 最小修复 → GREEN（`WINDOWS_INSTALL_CONTRACT PASS`）。
- 产品包：前端已出 `.cjo`，`llc` 单模块在模拟 x64 上不收敛（3 轮 45/117/125 分钟预算耗尽；simple 对照同样爬行）。阻塞验收二进制。
- E 并行 churn 导致 4 次撕裂快照（均已定位，非 Windows 特有；E 的 mac 侧同日撞上同样两处）。

## 原始证据（本仓 artifacts 内）

- 源码装配：`staging/pharos-windows-source/source-manifest.json`（115 项，`guest-transfer/pharos-windows-source.zip`）。
- 框架探针包：`guest-transfer/cjgui-windows-source.zip`（53 项，含新安装契约探针）。
- RED 基线包：`guest-transfer/cjgui-windows-source-red-seams.zip`（`4c88bf6e…`，行为回退、计数保留）。
- 咨询：`consultations/pharos-package-source-discovery/request.md`（沿用）；`consultations/app-llc-time/{request,answer}.md`（Pi→GLM5.3 已答复，M0–M7）。
- 探针源码：`renderer-contract/cjgui_windows_source_install_contract.c`（新）；`renderer-contract/cjgui_windows_input_contract.c`（复用）。
- 运行批次：`runner/batches/build/pharos-windows-prepare-source.ps1`（增量跳过+应用原生库）；
  `runner/batches/diagnostics/windows-source-install-contract.ps1`（新）；
  `runner/batches/acceptance/pharos-writing-chain-acceptance.ps1`（新，v1 待二进制）。
- 运行原件：各 `runner-sessions/<id>/`（session.json + results），输入探针日志见 `runner-sessions/*/guest-results/input-contract/`。

## 运行结果原数

- RED：`WINDOWS_INSTALL_RED gate_leak range=1 nav=2 gated=0`（exit 16）。
- GREEN：`WINDOWS_INSTALL_CONTRACT PASS gate=3 install=0:5 first=X stale_refused recover_refused continue=Y`（exit 0，53/53 校验）。
- 旧输入契约（已修 renderer 回归）：`WINDOWS_INPUT_CONTRACT PASS ...`（exit 0）。
- 六包构建：shared_operation_core / document_core / markdown_engine / app_services / editor_surface / cjgui 均为 `cjpm build success`。
- `.bc` 体量：27,803,512 B（单模块，`runPharosApplication` 3742 行单函数为主因之一）。
- llc 曲线：约 500 CPU-s/10 min 墙钟，工作集 4.8→7.5 GiB（12 GiB 来宾），三次预算内无产出、无断点续跑。

## 本轮源码改动（均未 stage/commit/push）

cangjie 仓：
- `runtime/cjgui/platforms/windows/native/pharos_windows_app_support.c`（新，47 个 pharos_*/kill 外调：Agent 通道 TCP 回环/计时/进程/kill/深色标题栏真实实现，其余具名拒绝；MinGW 编译 0 警告）。
- `runtime/cjgui/platforms/windows/native/cjgui_windows_renderer.c`（未跟踪目录；三接缝修复＋async 诚实桩）。
- `runtime/cjgui/native/cjgui_internal_renderer.h`（+3 行：gated 计数器声明）。
- `runtime/cjgui/src/windows_application_host.cj`（未跟踪；`@When` 小写→`Windows` 1 行）。
- `artifacts/windows-pharos-20261005/`（未跟踪；stage/prepare/批次/探针/证据）。
Pharos Mark 仓：
- `apps/pharos_mark/src/main.cj`（E 在途大改中的 2 行 `@When` 同上修正；其余均为 E 改动）。

## 真实剩余项与归属

1. E：`runPharosApplication` 3742 行单函数致 llc 不收敛（或给同步回退/拆分，或确认 mac 原生耗时量级）；`async_multiline_measure.cj` 的 Windows 语义裁定（当前为诚实失败桩，命中即大声失败）。
2. W：app 单元 `.obj`/`.exe`（待 1 解决后一次 2h 窗口收敛）；随后跑 `pharos-writing-chain-acceptance.ps1`（v1 已就绪，预览/IME/20 笔负载在首轮观测后补）。
3. 本轮未动：预览往返、系统 IME、PNG/设备恢复门（均需二进制）。

## 追补（2026-10-06 凌晨）：llc 墙根因与 relay 构建管线

### 根因（有原生对照与采样证据）
- Mac 原生 `cjpm build`（/tmp/mac-llc-ctrl 隔离树）全绿 **64.11s / 64.73s**（两次），产出 arm64 main 37MB → 代码形状无问题。
- `sample` 抓取 guest 同源 bitcode 的原生 llc 进程：**78% 时间耗在 `llvm::CJStackPointerInserter::runOnMachineFunction`**（内部 `SetVector<SPType*>`/DenseSet 反复增删 + `StackPointerAnalysis::transferSPData`）。该 pass 仅 Windows 目标触发；单模块 27.8MB bitcode 原生跑一次 ≈ **1724.69s（28.7 分钟）**，guest x64 模拟下 2 小时未收敛。
- 变体对照：`--cj-safepoint-outline`、`--spp-counted-loop-trip-width=1` 均无效（同 pass 同耗时）；`--cj-stack-check=false` 不识别。
- 结论：**不是前端/代码形状问题，是 Windows-target SPP pass 在 `runPharosApplication`（3742 行单函数）上的病态开销 × 模拟放大**。根治（拆函数）归 E。

### relay 管线（本轮实际使用，含验证）
1. guest 前端+opt 产出 `pharos_mark.opt.bc`（同一快照两次构建 sha 一致，确定性成立）。
2. `build-bc-captured.bc` 上传 Mac；Mac llc 用**与 guest 完全相同的 flags**（`--cangjie-pipeline ... --mtriple=x86_64-w64-mingw32 -O0 --filetype=obj`）产出 `pharos_mark.o`（Intel amd64 COFF，5,371,607B，sha 463f0e79…）。
3. guest 安装 llc wrapper（`llc.exe` 换为注入器，原版保留为 `llc-real.exe`；wrapper 仅对 `pharos_mark.opt.bc` 注入预编译 obj，同时把当次 bitcode 抄到 `build-bc-captured.bc` 供校验；其他模块转发原版）。
4. guest `cjpm build`：wrapper 注入（`inject.log: INJECTED`）→ cjc 正常链接。
5. **校验**：注入构建的 `BUILD_BC_SHA` 必须等于 relay 输入 bc 的 sha；不等即视为无效注入。

### 链接缺口闭合（两轮）
- 第 1 轮：20 个 `cjgui_internal_renderer_*` 未定义（`apps/pharos_mark` 链接时）→ 在 `cjgui_windows_renderer.c` 补齐：6 个真实实现（指针取消×2、显示进度、退出生命周期×2、……见文件注释）、7 个有界接受（菜单声明 3 + 数据转移 4 类 getter/声明，均带与 macOS 同口径的边界校验）、7 个具名拒绝（context-menu 守卫、共享集合表单/过滤、测试缝×2、OHOS 手势键、DT 期望版本）。
- 第 2 轮：系统库未传到最终链接 → app manifest `link-option` 补 `-ld3d11 -ld3dcompiler -ldxgi -ldxguid -ldwrite -limm32 -luuid -luser32 -lgdi32 -ladvapi32 -lole32 -lwindowscodecs -lws2_32 -lpsapi -ldwmapi`（正典：`stage_pharos_windows.py`）。
- 第 3 轮：`fsync/pread/renameat` 缺 POSIX 垫片 → 新增 `cjgui_windows_posix_compat.c`（CRT/MoveFileEx 最小转换），随框架原生库编译（prepare/light 同步更新）。

### 冻结快照身份（guest 侧，relay 输入）
- `pharos_mark.opt.bc` sha `3e07fee2d0ab3f87a91db867371938f92410d0f39aa4991dad40755d1c8408f3`（27,915,188B）
- `main.cj` sha `45c862b0a55f3a5383055a2a9343ebb42e9ad09522535d71a068f797fc9beba8`（822,394B）
- `composable_ui_window.cj` sha `e46d44294f1a424a0040ac412820ff8003e5c25166418595e49c820e0e43e277`（982,523B）
- `cjgui_windows_renderer.c` sha `73aaddbb2152db92badf29492dec74c1638cd92071631c8430dd492ad6e85ffd`（320,500B，== 正典当前）
- 上传原件：`runner-sessions/9f6a4b8071794ad0869bb855194e7f83/guest-results/llc-relay2/pharos_mark_snapshot.bc`

### 取消通道（已验收）
- `worker_run.ps1` + `windows_runner.py`：同 batch nonce 的 `CANCEL` 帧 → 任务进程树回收、记录 `cancelled=true/exit_code=125`；陈旧/异 nonce 不生效；会话可复用。
- guest 真机原件：`cancel-channel-verified.log`（CANCEL 4.3s 回收，REUSE PASS），host 单测 9/9。
