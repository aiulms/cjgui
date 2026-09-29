// 设置与计数：macOS 宿主入口（与鸿蒙宿主共用同一份领域/控制器源码）。
// 宿主差异只在本文件：AppKit/Metal 由 CjguiMacosApplicationHost 承担。
//
// 外部客户端通过连接描述符（stdout 输出）以 GET_CONTEXT / INVOKE 与
// 人类操作同一 owner。

package cjgui_settings_counter_window_app

import cjgui.*
import cjgui_settings_counter_application.*
import cjgui_shared_operation_core.*
import std.env.*
import std.collection.*

private func runSettingsCounterWindow(): Int32 {
    let domain = CjguiSettingsCounterDomain()
    let controller = CjguiSettingsCounterController(domain)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("设置与计数", 760u32, 560u32)
    )
    let window = host.window()
    controller.generatedUiRegion().attachWindow(window)
    let connection = CjguiSharedOperationExternalConnection(domain, settingsCounterAuthorization(), domain, window)
    if (!connection.enableWindowProgressReads(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_SETTINGS_COUNTER_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("CJGUI_SETTINGS_COUNTER_READY PROTOCOL ${info.protocol}")
        output.flush()
    }
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
        // C（第二次触摸复核）：与 OHOS 宿主循环同一接法——控制器挂起的语义
        // 焦点请求（「定位滚动备注」导航按钮）经窗口公共
        // focusAcceptedSemanticNode 提交（reveal→新 accepted→平台聚焦）。
        if (let Some(semantic) <- controller.takePendingFocusRequest()) {
            let focused = window.focusAcceptedSemanticNode(semantic)
            let output = getStdOut()
            output.writeln("CJGUI_NAV_FOCUS ${semantic} ${focused}")
            output.flush()
        }
    }
    host.close()
    return 0
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { getStdErr().writeln("usage: CjguiSettingsCounter"); return 2 }
    return Int64(runSettingsCounterWindow())
}
