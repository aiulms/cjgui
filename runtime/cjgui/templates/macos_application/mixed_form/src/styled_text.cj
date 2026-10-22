package cjgui_mixed_form_starter

import cjgui.*
import std.collection.*
import std.convert.*
import std.env.*
import std.fs.*

// Application resource owner shared by its ordinary windows. It owns no input
// or generated state; the existing form remains the only business writer.
class PrintPresetFontResources {
    public let registry = CjguiFontResourceRegistry()
    public var serif: ?CjguiFontResourceReference = None
    public var mono: ?CjguiFontResourceReference = None
    public var revision: Int64 = 0
    public var alternateColor = false
    public var largeType = false
    public var closed = false
    public let description: ?PrintPresetStyledDescription
    init(enabled: Bool, styled!: Bool = false) {
        description = if (styled) { Some(PrintPresetStyledDescription()) } else { None }
        if (enabled) {
            serif = Some(registry.register(CjguiFontResourceSpec.systemFamily("preview-serif", 1,
                "Georgia", name: "系统衬线")))
            mono = Some(registry.register(CjguiFontResourceSpec.file("preview-mono", 1,
                "Lilex-Regular.ttf", name: "包内等宽")))
        }
    }
    public func replace(): CjguiFontResourceReference {
        let old = mono.getOrThrow()
        let next = old.version + 1
        let value = registry.replace(CjguiFontResourceSpec.file(old.key, next,
            if (next % 2 == 0) { "missing-preview-font.ttf" } else { "Lilex-Regular.ttf" }, name: "包内等宽"))
        mono = Some(value)
        revision += 1
        return value
    }
    public func close(): Bool {
        if (closed) { return false }
        closed = true
        registry.close()
        return true
    }
}

class PrintPresetStyledDescription {
    public let text: String
    public let spans: ArrayList<Array<String>> = ArrayList<Array<String>>()
    init() {
        let path = getVariable("CJGUI_PRINT_PRESET_DESCRIPTION") ??
            Path(getCommand()).parent.parent.join("Resources/styled-description.tsv").toString()
        let lines = String.fromUtf8(File.readFrom(path)).split("\n")
        text = lines[0]
        for (index in 1..lines.size) {
            if (!lines[index].isEmpty()) { spans.add(lines[index].split("\t")) }
        }
    }
    public func runs(fonts: PrintPresetFontResources): Array<CjguiComposableUiTextStyleRun> {
        let result = ArrayList<CjguiComposableUiTextStyleRun>()
        for (span in spans) {
            let color = if (fonts.alternateColor) { CjguiComposableUiColor(0.25, 0.8, 0.95, 1.0) }
                else { cjguiComposableUiParseColorToken(span[4]).getOrThrow() }
            let family = if (span[3] == "preview-mono") { fonts.mono.getOrThrow() }
                else { fonts.serif.getOrThrow() }
            let size = Float64.tryParse(span[2]).getOrThrow()
            result.add(CjguiComposableUiTextStyleRun(Int64.tryParse(span[0]).getOrThrow(),
                Int64.tryParse(span[1]).getOrThrow(), if (fonts.largeType && size == 36.0) { 42.0 } else { size },
                0, family.fontFamily, color.red, color.green, color.blue, color.alpha))
        }
        return result.toArray()
    }
}

class StyledFontLifetimeSummary <: CjguiComposableUiController {
    private var revision: Int64 = 0
    private var message = "字体窗口与注册 owner 已结束。点击查看真实资源结果；此窗口只用系统字体。"
    public func rejectUiEvent(kind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "font-lifetime-summary",
            CjguiComposableUiStyle(padding: 18, gap: 14, growX: 1))
        root.add(cjguiComposableText(2, "font-lifetime-message", message,
            CjguiComposableUiStyle(fontSize: 16.0, growX: 1)))
        root.add(cjguiComposableButton(3, "font-lifetime-read", "查看资源结果", "READ", 0,
            CjguiComposableUiStyle(fixedHeight: 40, fontSize: 16.0)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE || event.node.actionName != "READ") { return CjguiComposableUiDispatchResult(false) }
        let values = cjguiFontResourceDiagnostics()
        message = "活动注册=${values[0]}；存活代=${values[1]}；字体文件字节=${values[2]}"
        println("CJGUI_STYLED_LIFETIME_READ active=${values[0]} leased=${values[1]} bytes=${values[2]}")
        getStdOut().flush()
        revision += 1
        return CjguiComposableUiDispatchResult(true)
    }
}
