# C FFI Smoke Test

最后更新：2026-04-25

用途：

- 验证仓颉能调用本地 C 函数。
- 验证 `cjc` 可以链接本地 C 静态库。
- 验证本机 `SDKROOT` 和仓颉 SDK 环境脚本可以支撑后续平台桥接实验。

## 结构

- `scripts/env.sh`：统一设置仓颉 SDK、`SDKROOT` 和 `libffi` 相关环境变量。
- `native/c_math_smoke.c`：一个最小 C 函数。
- `src/main.cj`：仓颉 `foreign` 声明和调用。
- `scripts/build_and_run.sh`：编译 C 静态库，编译仓颉程序并运行。

## 运行

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke/scripts/build_and_run.sh
```

期望输出：

```text
C FFI result: 42
```

## 当前结论

仓颉调用 C 的最小链路已通过。

后续可以在这个基础上继续验证：

- C 回调仓颉函数
- C/Objective-C shim
- AppKit 窗口桥接
- Metal 绘制桥接
