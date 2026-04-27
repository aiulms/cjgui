# AI 执行卡模板

用途：后续每次进入非平凡实现前，先填写这一张卡。

执行卡是开工许可证，不是新的 docs-only 循环入口。

如果本卡已经冻结 authority、goal、write set、truth、verification 和 stop-line，下一步默认必须进入 bounded implementation；除非发现新的高风险冲突，否则不得继续创建新的 preflight / execution card 来替代实现。

---

## 0. Architect Sign-off

架构管理师确认：

- 状态：未确认 / 已确认 / 本轮不需要
- 确认者：
- 确认依据：

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：
- 上层尽量仓颉原生：
- 底层只保留必要平台桥接：
- 没有过早抽象跨平台：

## 1. Authority

本轮唯一 authority / owner 判断：

-

## 2. Goal

本轮唯一目标：

-

## 3. Scope

本轮只做：

-

本轮明确不做：

-

## 4. Write Set

本轮允许修改的文件 / 模块：

-

本轮禁止触碰的文件 / 模块：

-

## 5. Truth / Projection

本轮真相层：

-

本轮只是投影 / read surface 的部分：

-

## 6. Invariants

本轮必须守住的 invariant：

-

## 7. Fallout Scan Targets

本轮完成前必须检查的尾部影响：

- 公共 API：
- 事件流：
- 状态流：
- 渲染流：
- 平台桥接：
- 视觉 / 交互：
- 文档 / 示例：
- 测试：

## 8. Verification

本轮计划执行的验证：

-

本轮如果无法完成的验证：

-

对应残留风险：

-

## 8.1 Implementation Exit Check

本卡完成后是否默认进入 bounded implementation：

- 是 / 否

如果否，必须说明阻塞原因：

- 新 HIGH / CRITICAL 风险：
- 代码现实与文档冲突：
- 必须触碰未批准 write set：
- 必须改变 public API / owner / truth：
- 必须新增依赖 / 系统权限 / 迁移 / 平台桥接：

如果以上都不是，则不得拒绝进入实现。

如果本轮是 implementation / first slice / runtime slice，必须产生的真实行为变化：

-

## 9. Stop-Line

本轮 stop-line：

-

## 10. Closure

完成后需要同步的文档或账本：

-

---

最简口令版：

> 先写 architect sign-off、authority、goal、write set、truth、invariants、verification、stop-line，再进入实现；执行卡完成后必须推动代码，不得把执行卡变成下一轮文档循环。
