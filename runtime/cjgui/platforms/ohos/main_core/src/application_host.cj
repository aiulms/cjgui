package cjgui

import cjgui_shared_operation_core.*

/// 正常应用宿主的最小公共面。产品与普通消费者只依赖这一份接口：macOS、Windows
/// 与 Linux 的宿主各自实现它，消费者的主流程因此不再按平台分叉，也不复制任何
/// 平台逻辑。接口只包含“启动、跑一轮、是否还开着、关闭、取窗口、接入外部连接”；
/// 平台特有的主题/标题等仍留在各自宿主上，不经这份最小面暴露。
public interface CjguiApplicationHost {
    func window(): CjguiComposableUiWindow
    func attachExternalConnection(connection: CjguiSharedOperationExternalConnection): Bool
    func start(): Bool
    func pumpOneTurn(): Bool
    func isOpen(): Bool
    func close(): Unit
}

/// 按平台创建宿主。消费者只写这一行，不 import 任何平台宿主类型；宿主差异
/// （渲染器、事件泵、帧提交）留在各平台实现内。
@When[os == "macOS"]
public func cjguiCreatePlatformApplicationHost(controller: CjguiComposableUiController,
    configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()): CjguiApplicationHost {
    return CjguiMacosApplicationHost(controller, configuration: configuration)
}

@When[os == "Windows"]
public func cjguiCreatePlatformApplicationHost(controller: CjguiComposableUiController,
    configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()): CjguiApplicationHost {
    return CjguiWindowsApplicationHost(controller, configuration: configuration)
}

@When[os == "Linux"]
public func cjguiCreatePlatformApplicationHost(controller: CjguiComposableUiController,
    configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()): CjguiApplicationHost {
    return CjguiLinuxApplicationHost(controller, configuration: configuration)
}

@When[os == "macOS"]
extend CjguiMacosApplicationHost <: CjguiApplicationHost {}

@When[os == "Windows"]
extend CjguiWindowsApplicationHost <: CjguiApplicationHost {}

@When[os == "Linux"]
extend CjguiLinuxApplicationHost <: CjguiApplicationHost {}

/// 停止应用循环的平台入口。静态方法不能经接口调用，所以单独给一个同名的
/// 包级入口，让消费者用同一行代码结束各平台的应用循环。
@When[os == "macOS"]
public func cjguiStopApplicationLoop(): Unit {
    CjguiMacosApplicationHost.stopApplicationLoop()
}

@When[os == "Windows"]
public func cjguiStopApplicationLoop(): Unit {
    CjguiWindowsApplicationHost.stopApplicationLoop()
}

@When[os == "Linux"]
public func cjguiStopApplicationLoop(): Unit {
    CjguiLinuxApplicationHost.stopApplicationLoop()
}
