// Lightweight status, content-state and progress projections.
//
// These builders return ordinary composable nodes. They never execute a
// request, retry an operation, clear a selection/draft, start a timer or own a
// task. The application supplies the text, numeric values and action identity;
// the caller also decides whether a content state replaces or sits beside the
// retained content.
package cjgui

import std.collection.*
import std.math.numeric.*
import std.overflow.*

public let CJGUI_STATUS_INFO: String = "info"
public let CJGUI_STATUS_SUCCESS: String = "success"
public let CJGUI_STATUS_WARNING: String = "warning"
public let CJGUI_STATUS_ERROR: String = "error"

public let CJGUI_CONTENT_LOADING: String = "loading"
public let CJGUI_CONTENT_EMPTY: String = "empty"
public let CJGUI_CONTENT_ERROR: String = "error"
public let CJGUI_CONTENT_READY: String = "ready"

public let CJGUI_EMPTY_NO_DATA: String = "no_data"
public let CJGUI_EMPTY_NO_MATCH: String = "no_match"

public class CjguiStatusMessageSpec {
    public let kind: String
    public let text: String
    public let actionLabel: String
    public let actionName: String
    public let actionEnabled: Bool

    public init(kind: String, text: String, actionLabel!: String = "", actionName!: String = "",
                actionEnabled!: Bool = true) {
        this.kind = kind
        this.text = text
        this.actionLabel = actionLabel
        this.actionName = actionName
        this.actionEnabled = actionEnabled
    }
}

public class CjguiStatusMessageStyle {
    public let container: CjguiComposableUiStyle
    public let chip: CjguiComposableUiStyle
    public let text: CjguiComposableUiStyle
    public let action: CjguiComposableUiStyle
    public let actionInteraction: CjguiComposableUiInteractionStyle
    public let gap: Int64
    public let rowGap: Int64

    public init(container!: CjguiComposableUiStyle = CjguiComposableUiStyle(padding: 4, gap: 4),
                chip!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedWidth: 52, fixedHeight: 20,
                    fontSize: 10.5),
                text!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 11.0),
                action!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 24),
                actionInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
                gap!: Int64 = 4, rowGap!: Int64 = 4) {
        this.container = container
        this.chip = chip
        this.text = text
        this.action = action
        this.actionInteraction = actionInteraction
        this.gap = if (gap > 0) { gap } else { 4 }
        this.rowGap = if (rowGap > 0) { rowGap } else { 4 }
    }
}

public class CjguiStatusFeedback {
    public static func kindLabel(kind: String): String {
        if (kind == CJGUI_STATUS_SUCCESS) { return "成功" }
        if (kind == CJGUI_STATUS_WARNING) { return "警告" }
        if (kind == CJGUI_STATUS_ERROR) { return "错误" }
        return "信息"
    }

    /// Status is rendered with a textual kind marker, not colour alone. The
    /// wrap lets a long message or a narrow window move the action to a new row.
    public static func buildMessage(nodeId: Int64, semanticId: String, chipNodeId: Int64, textNodeId: Int64,
        actionNodeId: Int64, spec: CjguiStatusMessageSpec,
        style!: CjguiStatusMessageStyle = CjguiStatusMessageStyle()): CjguiComposableUiNode {
        let root = cjguiComposableWrap(nodeId, semanticId, style.container, rowGap: style.rowGap)
        root.add(cjguiComposableText(chipNodeId, "${semanticId}-kind", "[${kindLabel(spec.kind)}]",
            style.chip))
        root.add(cjguiComposableText(textNodeId, "${semanticId}-text", spec.text, style.text))
        if (spec.actionLabel.size > 0 && spec.actionName.size > 0 && actionNodeId > 0) {
            root.add(cjguiComposableButton(actionNodeId, "${semanticId}-action", spec.actionLabel,
                spec.actionName, -1, style.action, enabled: spec.actionEnabled,
                interactionStyle: style.actionInteraction))
        }
        return root
    }
}

public class CjguiContentStateSpec {
    public let kind: String
    public let emptyReason: String
    public let title: String
    public let detail: String
    public let actionLabel: String
    public let actionName: String
    public let actionEnabled: Bool

    public init(kind: String, emptyReason!: String = CJGUI_EMPTY_NO_DATA, title!: String = "",
                detail!: String = "", actionLabel!: String = "", actionName!: String = "",
                actionEnabled!: Bool = true) {
        this.kind = kind
        this.emptyReason = emptyReason
        this.title = title
        this.detail = detail
        this.actionLabel = actionLabel
        this.actionName = actionName
        this.actionEnabled = actionEnabled
    }
}

public class CjguiContentStateStyle {
    public let container: CjguiComposableUiStyle
    public let title: CjguiComposableUiStyle
    public let detail: CjguiComposableUiStyle
    public let action: CjguiComposableUiStyle
    public let actionInteraction: CjguiComposableUiInteractionStyle
    public let gap: Int64

    public init(container!: CjguiComposableUiStyle = CjguiComposableUiStyle(padding: 8, gap: 4),
                title!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 12.0),
                detail!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 10.5),
                action!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 24),
                actionInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
                gap!: Int64 = 4) {
        this.container = container
        this.title = title
        this.detail = detail
        this.action = action
        this.actionInteraction = actionInteraction
        this.gap = if (gap > 0) { gap } else { 4 }
    }
}

public class CjguiContentFeedback {
    /// Empty reasons are deliberately separate strings; a filtered empty result
    /// is not presented as "there is no data".
    public static func titleFor(spec: CjguiContentStateSpec): String {
        if (spec.title.size > 0) { return spec.title }
        if (spec.kind == CJGUI_CONTENT_LOADING) { return "正在加载" }
        if (spec.kind == CJGUI_CONTENT_ERROR) { return "加载失败" }
        if (spec.kind == CJGUI_CONTENT_EMPTY) {
            return if (spec.emptyReason == CJGUI_EMPTY_NO_MATCH) { "没有匹配结果" } else { "暂无数据" }
        }
        return ""
    }

    public static func detailFor(spec: CjguiContentStateSpec): String {
        if (spec.detail.size > 0) { return spec.detail }
        if (spec.kind == CJGUI_CONTENT_LOADING) { return "请稍候" }
        if (spec.kind == CJGUI_CONTENT_ERROR) { return "请重试或检查后继续" }
        if (spec.kind == CJGUI_CONTENT_EMPTY) {
            return if (spec.emptyReason == CJGUI_EMPTY_NO_MATCH) {
                "当前筛选条件下没有结果"
            } else {
                "还没有可显示的内容"
            }
        }
        return ""
    }

    /// Build a placeholder node. READY is intentionally not rendered here: a
    /// consumer that has ready content should place that content itself.
    public static func build(nodeId: Int64, semanticId: String, titleNodeId: Int64, detailNodeId: Int64,
        actionNodeId: Int64, spec: CjguiContentStateSpec,
        style!: CjguiContentStateStyle = CjguiContentStateStyle()): CjguiComposableUiNode {
        let root = cjguiComposableVertical(nodeId, semanticId, style.container)
        let title = titleFor(spec)
        if (title.size > 0) {
            root.add(cjguiComposableText(titleNodeId, "${semanticId}-title", title, style.title))
        } else {
            root.add(cjguiComposableVertical(titleNodeId, "${semanticId}-title-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
        }
        let detail = detailFor(spec)
        if (detail.size > 0) {
            root.add(cjguiComposableText(detailNodeId, "${semanticId}-detail", detail, style.detail))
        } else {
            root.add(cjguiComposableVertical(detailNodeId, "${semanticId}-detail-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
        }
        if (spec.actionLabel.size > 0 && spec.actionName.size > 0 && actionNodeId > 0) {
            root.add(cjguiComposableButton(actionNodeId, "${semanticId}-action", spec.actionLabel,
                spec.actionName, -1, style.action, enabled: spec.actionEnabled,
                interactionStyle: style.actionInteraction))
        }
        return root
    }
}

public class CjguiProgressSpec {
    public let busy: Bool
    public let value: Int64
    public let total: Int64
    public let label: String
    public let busyLabel: String
    public let trackWidth: Int64

    public init(busy: Bool, value!: Int64 = 0, total!: Int64 = 0, label!: String = "",
                busyLabel!: String = "忙碌中…", trackWidth!: Int64 = 160) {
        this.busy = busy
        this.value = value
        this.total = total
        this.label = label
        this.busyLabel = busyLabel
        this.trackWidth = trackWidth
    }

    /// Empty means valid. A determinate value must be within 0..total; this
    /// builder never fabricates a percentage by clamping an invalid value.
    public func issue(): String {
        if (busy) { return "" }
        if (total <= 0) { return "progress_total_required" }
        if (value < 0) { return "progress_value_negative" }
        if (value > total) { return "progress_value_above_total" }
        if (trackWidth <= 0) { return "progress_track_width_required" }
        return ""
    }
}

public class CjguiProgressStyle {
    public let container: CjguiComposableUiStyle
    public let label: CjguiComposableUiStyle
    public let track: CjguiComposableUiStyle
    public let fill: CjguiComposableUiStyle
    public let busy: CjguiComposableUiStyle
    public let issue: CjguiComposableUiStyle
    public let gap: Int64

    public init(container!: CjguiComposableUiStyle = CjguiComposableUiStyle(gap: 3),
                label!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 18, fontSize: 10.5),
                track!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 8, cornerRadius: 4,
                    background: CjguiComposableUiColor(0.84, 0.86, 0.90, 1.0)),
                fill!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 8, cornerRadius: 4,
                    background: CjguiComposableUiColor(0.22, 0.45, 0.82, 1.0)),
                busy!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 18, fontSize: 10.5),
                issue!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 18, fontSize: 10.5),
                gap!: Int64 = 3) {
        this.container = container
        this.label = label
        this.track = track
        this.fill = fill
        this.busy = busy
        this.issue = issue
        this.gap = if (gap > 0) { gap } else { 3 }
    }
}

public class CjguiProgressFeedback {
    /// 0 stays 0; a positive fraction below one point becomes one point so a
    /// visible track still shows that progress moved. The intermediate product
    /// falls back to exact wide arithmetic instead of wrapping or saturating.
    private static func fillWidth(trackWidth: Int64, value: Int64, total: Int64): Int64 {
        if (value <= 0) { return 0 }
        if (value >= total) { return trackWidth }
        let scaled = match (trackWidth.checkedMul(value)) {
            case Some(product) => product / total
            case None => (BigInt(trackWidth) * BigInt(value) / BigInt(total)).toInt64(
                overflowHandling: Saturating)
        }
        if (scaled >= trackWidth) { return trackWidth }
        return if (scaled > 0) { scaled } else { 1 }
    }

    /// A determinate track is an ordinary fixed-width ordinary row; the fill is
    /// a child whose width comes from the caller's value. Busy is a static
    /// marker/text, not a timer. No native progress type is introduced.
    public static func build(nodeId: Int64, semanticId: String, labelNodeId: Int64, trackNodeId: Int64,
        fillNodeId: Int64, busyNodeId: Int64, issueNodeId: Int64, spec: CjguiProgressSpec,
        style!: CjguiProgressStyle = CjguiProgressStyle()): CjguiComposableUiNode {
        let root = cjguiComposableVertical(nodeId, semanticId, style.container)
        let progressIssue = spec.issue()
        if (spec.busy) {
            if (spec.label.size > 0) {
                root.add(cjguiComposableText(labelNodeId, "${semanticId}-label", spec.label, style.label))
            } else {
                root.add(cjguiComposableVertical(labelNodeId, "${semanticId}-label-empty",
                    CjguiComposableUiStyle(fixedHeight: 0)))
            }
            root.add(cjguiComposableText(busyNodeId, "${semanticId}-busy", spec.busyLabel, style.busy))
            root.add(cjguiComposableVertical(trackNodeId, "${semanticId}-track-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
            root.add(cjguiComposableVertical(fillNodeId, "${semanticId}-fill-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
            root.add(cjguiComposableVertical(issueNodeId, "${semanticId}-issue-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
            return root
        }
        if (progressIssue.size > 0) {
            root.add(cjguiComposableText(issueNodeId, "${semanticId}-issue",
                "进度值无效：${progressIssue}", style.issue))
            root.add(cjguiComposableVertical(labelNodeId, "${semanticId}-label-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
            root.add(cjguiComposableVertical(trackNodeId, "${semanticId}-track-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
            root.add(cjguiComposableVertical(fillNodeId, "${semanticId}-fill-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
            root.add(cjguiComposableVertical(busyNodeId, "${semanticId}-busy-empty",
                CjguiComposableUiStyle(fixedHeight: 0)))
            return root
        }
        let label = if (spec.label.size > 0) {
            spec.label
        } else {
            "${spec.value} / ${spec.total}"
        }
        root.add(cjguiComposableText(labelNodeId, "${semanticId}-label", label, style.label))
        let track = cjguiComposableHorizontal(trackNodeId, "${semanticId}-track",
            CjguiComposableUiStyle(fixedWidth: spec.trackWidth, fixedHeight: style.track.fixedHeight,
                background: style.track.background, border: style.track.border,
                borderWidth: style.track.borderWidth, cornerRadius: style.track.cornerRadius,
                clipsContent: true))
        let computedFillWidth = fillWidth(spec.trackWidth, spec.value, spec.total)
        if (computedFillWidth > 0) {
            track.add(cjguiComposableHorizontal(fillNodeId, "${semanticId}-fill",
                CjguiComposableUiStyle(fixedWidth: computedFillWidth, fixedHeight: style.track.fixedHeight,
                    background: style.fill.background, border: style.fill.border,
                    borderWidth: style.fill.borderWidth, cornerRadius: style.fill.cornerRadius)))
        } else {
            // An empty STACK measures to zero width. `fixedWidth: 0` on an
            // ordinary container is the auto-intrinsic declaration and would
            // expand this invisible fill to its 24pt default width.
            track.add(cjguiComposableStack(fillNodeId, "${semanticId}-fill",
                CjguiComposableUiStyle(fixedHeight: style.track.fixedHeight,
                    background: style.fill.background, border: style.fill.border,
                    borderWidth: style.fill.borderWidth, cornerRadius: style.fill.cornerRadius)))
        }
        root.add(track)
        root.add(cjguiComposableVertical(busyNodeId, "${semanticId}-busy-empty",
            CjguiComposableUiStyle(fixedHeight: 0)))
        root.add(cjguiComposableVertical(issueNodeId, "${semanticId}-issue-empty",
            CjguiComposableUiStyle(fixedHeight: 0)))
        return root
    }
}
