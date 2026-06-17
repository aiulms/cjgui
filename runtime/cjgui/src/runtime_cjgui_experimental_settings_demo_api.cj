// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental Settings demo API。
// Scope: 暴露非 Bool 的 settings demo output 领域类型与构造函数，供独立 Settings demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalSettingsDemoOutput {
    public let demoName: String
    public let sectionCount: Int64
    public let layoutKind: String
    public let themeName: String
    public let autoSaveEnabled: Bool
    public let selectedTheme: String
    public let usernameValue: String
    public let focusTarget: String
    public let summary: String

    public init(
        demoName: String,
        sectionCount: Int64,
        layoutKind: String,
        themeName: String,
        autoSaveEnabled: Bool,
        selectedTheme: String,
        usernameValue: String,
        focusTarget: String,
        summary: String
    ) {
        this.demoName = demoName
        this.sectionCount = sectionCount
        this.layoutKind = layoutKind
        this.themeName = themeName
        this.autoSaveEnabled = autoSaveEnabled
        this.selectedTheme = selectedTheme
        this.usernameValue = usernameValue
        this.focusTarget = focusTarget
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 Settings demo 输入脱水成领域输出对象，不提交 owner acceptance，不写全局状态。
public func cjguiExperimentalBuildSettingsDemoOutput(
    layoutKind: String,
    themeName: String,
    autoSaveEnabled: Bool,
    selectedTheme: String,
    usernameValue: String,
    focusTarget: String
): CjguiExperimentalSettingsDemoOutput {
    let sectionCount: Int64 = 3
    let summary = "layout=${layoutKind};theme=${themeName};autosave=${autoSaveEnabled};selected=${selectedTheme};username=${usernameValue};focus=${focusTarget}"
    return CjguiExperimentalSettingsDemoOutput(
        "settings",
        sectionCount,
        layoutKind,
        themeName,
        autoSaveEnabled,
        selectedTheme,
        usernameValue,
        focusTarget,
        summary
    )
}
