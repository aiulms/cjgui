// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental FileBrowser demo API。
// Scope: 暴露非 Bool 的 file browser demo output 领域类型与构造函数，供独立 FileBrowser demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalFileBrowserDemoOutput {
    public let demoName: String
    public let itemCount: Int64
    public let selectedPath: String
    public let selectedKind: String
    public let detailTitle: String
    public let filterText: String
    public let focusedPane: String
    public let expandedPath: String
    public let layoutKind: String
    public let summary: String

    public init(
        demoName: String,
        itemCount: Int64,
        selectedPath: String,
        selectedKind: String,
        detailTitle: String,
        filterText: String,
        focusedPane: String,
        expandedPath: String,
        layoutKind: String,
        summary: String
    ) {
        this.demoName = demoName
        this.itemCount = itemCount
        this.selectedPath = selectedPath
        this.selectedKind = selectedKind
        this.detailTitle = detailTitle
        this.filterText = filterText
        this.focusedPane = focusedPane
        this.expandedPath = expandedPath
        this.layoutKind = layoutKind
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 FileBrowser demo 输入脱水成领域输出对象，不访问真实文件系统，不提交 renderer。
public func cjguiExperimentalBuildFileBrowserDemoOutput(
    itemCount: Int64,
    selectedPath: String,
    selectedKind: String,
    detailTitle: String,
    filterText: String,
    focusedPane: String,
    expandedPath: String,
    layoutKind: String
): CjguiExperimentalFileBrowserDemoOutput {
    let summary = "items=${itemCount};selected=${selectedPath}:${selectedKind};detail=${detailTitle};filter=${filterText};focus=${focusedPane};expanded=${expandedPath};layout=${layoutKind}"
    return CjguiExperimentalFileBrowserDemoOutput(
        "file_browser",
        itemCount,
        selectedPath,
        selectedKind,
        detailTitle,
        filterText,
        focusedPane,
        expandedPath,
        layoutKind,
        summary
    )
}
