package cjgui

/// 正常应用宿主的最小公共面。产品与普通消费者只依赖这一份接口：macOS 与
/// Windows 的宿主各自实现它，消费者的主流程因此不再按平台分叉，也不复制任何
/// 平台逻辑。接口只包含“启动、跑一轮、是否还开着、关闭、取窗口”这五件事；
/// 平台特有的主题/连接/标题等仍留在各自宿主上，不经这份最小面暴露。
public interface CjguiApplicationHost {
    func window(): CjguiComposableUiWindow
    func start(): Bool
    func pumpOneTurn(): Bool
    func isOpen(): Bool
    func close(): Unit
}

@When[os == "macOS"]
extend CjguiMacosApplicationHost <: CjguiApplicationHost {}

@When[os == "Windows"]
extend CjguiWindowsApplicationHost <: CjguiApplicationHost {}

/// 停止应用循环的平台入口。静态方法不能经接口调用，所以单独给一个同名的
/// 包级入口，让消费者用同一行代码结束两个平台的应用循环。
@When[os == "macOS"]
public func cjguiStopApplicationLoop(): Unit {
    CjguiMacosApplicationHost.stopApplicationLoop()
}

@When[os == "Windows"]
public func cjguiStopApplicationLoop(): Unit {
    CjguiWindowsApplicationHost.stopApplicationLoop()
}
