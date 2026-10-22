// Rule-set card content for the public virtual card grid.
//
// The grid adapter owns grouping, responsive columns and stable card slots.
// This renderer owns only the rule-set presentation fields and the existing
// SELECT_RECORD action. It never writes a record, draft or selection.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*

class CjguiRuleSetCardGridRenderer {
    private let domain: CjguiRuleSetEditingDomain
    private var theme: CjguiComposableUiTheme
    private var bodyStyle: CjguiComposableUiStyle

    init(domain: CjguiRuleSetEditingDomain, theme: CjguiComposableUiTheme,
        bodyStyle: CjguiComposableUiStyle) {
        this.domain = domain
        this.theme = theme
        this.bodyStyle = bodyStyle
    }

    public func updatePresentation(theme: CjguiComposableUiTheme,
        bodyStyle: CjguiComposableUiStyle): Unit {
        this.theme = theme
        this.bodyStyle = bodyStyle
    }

    public func build(item: CjguiComposableUiVariableHeightListItem,
        context: CjguiComposableUiCardGridCardContext): CjguiComposableUiNode {
        let selectedBackground = if (context.selected) {
            theme.primaryAction.background
        } else {
            theme.card.background
        }
        let textColor = if (context.selected) {
            theme.primaryAction.textColor
        } else {
            theme.card.textColor
        }
        let border = if (context.focused) {
            theme.primaryAction.background
        } else {
            theme.card.border
        }
        let card = cjguiComposableVertical(-1, "rule-card-${item.key}",
            CjguiComposableUiStyle(fixedWidth: context.cardWidth, fixedHeight: context.cardHeight,
                padding: 8, gap: 4, background: selectedBackground, border: border,
                borderWidth: if (context.focused) { 2 } else { 1 }, textColor: textColor,
                fontFamily: bodyStyle.fontFamily, alignY: CJGUI_COMPOSABLE_UI_ALIGN_START),
            identity: Some(context.identity.local("card")))
        let titleStyle = CjguiComposableUiStyle(fixedHeight: 22, fontSize: 13.5, fontWeight: 1,
            textColor: textColor, fontFamily: bodyStyle.fontFamily, textMaxLines: 1,
            textOverflow: "ellipsis")
        card.add(cjguiComposableText(-1, "rule-card-title-${item.key}", item.title, titleStyle,
            resourceId: item.resourceId, displayValueRole: "applied",
            identity: Some(context.identity.local("title"))))
        let status = cardStatus(item)
        card.add(cjguiComposableText(-1, "rule-card-status-${item.key}", status,
            CjguiComposableUiStyle(fixedHeight: 18, fontSize: 11.0, textColor: textColor,
                fontFamily: bodyStyle.fontFamily, textMaxLines: 1, textOverflow: "ellipsis"),
            identity: Some(context.identity.local("status"))))
        let detail = cardDetail(item)
        card.add(cjguiComposableText(-1, "rule-card-detail-${item.key}", detail,
            CjguiComposableUiStyle(fixedHeight: 18, fontSize: 11.0, textColor: textColor,
                fontFamily: bodyStyle.fontFamily, textMaxLines: 1, textOverflow: "ellipsis"),
            identity: Some(context.identity.local("detail"))))
        if (context.actionName.size > 0 && context.actionResourceId >= 0) {
            let buttonBackground = if (context.selected) {
                theme.card.background
            } else {
                theme.primaryAction.background
            }
            let buttonText = if (context.selected) {
                theme.primaryAction.background
            } else {
                theme.primaryAction.textColor
            }
            card.add(cjguiComposableButton(-1, "rule-card-select-${item.key}", "选择",
                context.actionName, context.actionResourceId,
                CjguiComposableUiStyle(fixedHeight: 26, background: buttonBackground,
                    textColor: buttonText, border: border, fontFamily: bodyStyle.fontFamily),
                operationActionName: context.actionName,
                operationResourceId: context.actionResourceId,
                ownerInteractionState: if (context.selected) {
                    CjguiComposableUiInteractionState.SELECTED
                } else {
                    CjguiComposableUiInteractionState.NONE
                }, identity: Some(context.identity.local("select"))))
        } else {
            card.add(cjguiComposableText(-1, "rule-card-display-${item.key}", "展示项",
                CjguiComposableUiStyle(fixedHeight: 26, fontSize: 11.0, textColor: textColor,
                    fontFamily: bodyStyle.fontFamily),
                identity: Some(context.identity.local("display"))))
        }
        return card
    }

    private func cardStatus(item: CjguiComposableUiVariableHeightListItem): String {
        if (let Some(record) <- domain.appliedRecordForResourceId(item.resourceId)) {
            let enabled = if (record.enabled) { "已启用" } else { "已停用" }
            return "${enabled} · 保留 ${record.retentionCount} 天"
        }
        return "展示项 · 无业务资源"
    }

    private func cardDetail(item: CjguiComposableUiVariableHeightListItem): String {
        if (let Some(record) <- domain.appliedRecordForResourceId(item.resourceId)) {
            return "排除：${record.excludedType}"
        }
        return "—"
    }
}
