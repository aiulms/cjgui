# E/第六次复核第 5 项：恒温独立消费者 人→外→人 连续链证据

日期：2026-09-26。产物：`labs/ohos_thermo_app`（bundle `com.example.cjguithermo`，
与主应用不同的独立身份），verify-transport+test-gates 变体（run/thermo_build8）。
探针：`verify_thermo_continuity.py` → **PASS（failures=0）**（原始帧
`thermo_raw.json`、断言 `thermo_continuity_evidence.json`）。

## 独立性（与设置计数示例逐项对照）
| 维度 | 设置计数 | 恒温消费者 |
| --- | --- | --- |
| bundle | com.example.cjguiapp | com.example.cjguithermo |
| 领域字段 | count/enabled/name/alias | targetTemp(16-30)/eco/note(**可空**) |
| resourceId | 9700 | 9801 |
| 外部授权 | cjgui-settings-counter-agent-20260925 | cjgui-thermo-agent-20260926 |
| 传输端口 | 7856 | 7857 |
| 应用包名接线 | settings_counter_application（默认） | thermostat_application（公共脚本经 CJGUI_APP_SRC/DIR_NAME/PKG_NAME 参数化，不再写死示例私有包名） |

## 连续链（同实例，逐腿精确读回，owner 版本单调）
1. **人改**：注入点击「升温」→ targetTemp 22→23，v0→v1。
2. **公开 owner 读**：GET_CONTEXT 逐字段读回（targetTemp=23）。
3. **外部改**：SET_NOTE `外部备注🚰`（含 emoji）→ APPLIED → 读回逐码元精确，v2。
4. **画面投影**：渲染器 accepted 日志出现外部写入后的 owner 值（目标温度：23℃）。
5. **旧输入拒绝**：stale expectedVersion 的 TEMP_UP → version_conflict，版本不变。
6. **人续写**：新版本上再点升温 → 24，精确读回。
7. **可空规则**：SET_NOTE 空串 → 合法应用并精确读回（与设置计数「非空」规则相反，
   领域差异的实证）。
8. **越界拒绝**：外部连升至 30 后再一次 → temp_out_of_range，版本不变（16-30 界）。

## 过程中修复的公共基础设施
- `build_and_run.sh`：devecocli 返回时大 HAP 尚未落盘 → 有界等待（实测竞态）。
- `sync_platform.sh`：应用目录名/包名参数化（CJGUI_APP_DIR_NAME/PKG_NAME）。
- `verify_hap_closure.sh`：应用包库必需项参数化（CJGUI_APP_PKG_LIB）+
  libnative_window.so 打包契约断言（真机禁带/模拟器必带）。
