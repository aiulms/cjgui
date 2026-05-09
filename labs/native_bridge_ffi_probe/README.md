# native bridge FFI 语法与链接探针

状态：isolated lab / no runtime truth

## 文件定位

本探针只验证 production native bridge skeleton 中 no-resource callable 是否能被仓颉 `foreign` 声明、链接并调用。

它不是 `runtime/cjgui` 主包的一部分，不修改 `runtime/cjgui/cjpm.toml`，不新增 runtime `.cj` FFI declaration，不扩 public API，也不创建 native object、native handle、raw pointer、Metal / AppKit resource、renderer state write 或 backend-ready truth。

## 验证范围

- 编译 `runtime/cjgui/native/cjgui_native_bridge.m` 到 `/tmp/cjgui-native-bridge-ffi-probe-*` 下的临时 object。
- 打包临时 `libcjgui_native_bridge_probe.a`。
- 使用仓颉 `foreign func` 声明 no-resource callable。
- 通过 `cjc -L ... -l ...` 链接并运行 isolated executable。
- 输出 dehydrated summary。

## 允许 callable

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`
- `cjgui_native_bridge_is_main_thread`

## 停止线

- 不调用 resource callable。
- 不创建 / destroy native object。
- 不返回 native pointer。
- 不导入 Cocoa / Metal / QuartzCore。
- 不调用 AppKit / Metal。
- 不接入 runtime package。
- 不修改 production native source。
- 不修改 smoke native files。
- 不扩 public API。

## 运行方式

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/native_bridge_ffi_probe/scripts/build_and_run.sh
```
