// Rule-set column declarations for the public table projection.
//
// Each column names the owner field it projects; values still come from the
// rule-set owner through `appliedRecordForResourceId`, and sorting only compares
// the displayed projection. Widths and the flexible column live here once and
// are consumed by both the header and the body through the public table source.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import std.collection.*

public class CjguiRuleSetTableColumns {
    public static let sortNameAction: String = "TABLE_SORT_NAME"
    public static let sortEnabledAction: String = "TABLE_SORT_ENABLED"
    public static let sortRetentionAction: String = "TABLE_SORT_RETENTION"
    public static let sortExcludedAction: String = "TABLE_SORT_EXCLUDED"

    public static func create(domain: CjguiRuleSetEditingDomain): Array<CjguiComposableUiTableColumn> {
        let columns = ArrayList<CjguiComposableUiTableColumn>()
        // The name owns the remaining width; the three status columns are
        // fixed and share the same width contract with their headers.
        columns.add(CjguiComposableUiTableColumn("name", "规则名称", "label", 0, sortNameAction,
            { item => item.title },
            { left, right => compareText(left.title, right.title) }))
        columns.add(CjguiComposableUiTableColumn("enabled", "启用状态", "enabled", 68, sortEnabledAction,
            { item =>
                if (let Some(record) <- domain.appliedRecordForResourceId(item.resourceId)) {
                    if (record.enabled) { "启用" } else { "停用" }
                } else {
                    "—"
                }
            },
            { left, right => compareInt64(enabledRank(domain, left), enabledRank(domain, right)) }))
        columns.add(CjguiComposableUiTableColumn("retention", "保留天数", "retentionCount", 78,
            sortRetentionAction,
            { item =>
                if (let Some(record) <- domain.appliedRecordForResourceId(item.resourceId)) {
                    record.retentionCount.toString()
                } else {
                    "—"
                }
            },
            { left, right => compareInt64(retentionValue(domain, left), retentionValue(domain, right)) }))
        columns.add(CjguiComposableUiTableColumn("excluded", "排除类型", "excludedType", 96,
            sortExcludedAction,
            { item =>
                if (let Some(record) <- domain.appliedRecordForResourceId(item.resourceId)) {
                    record.excludedType
                } else {
                    "—"
                }
            },
            { left, right => compareText(excludedValue(domain, left), excludedValue(domain, right)) }))
        return columns.toArray()
    }

    public static func style(theme: CjguiComposableUiTheme,
        bodyStyle: CjguiComposableUiStyle): CjguiComposableUiTableStyle {
        return CjguiComposableUiTableStyle(
            30,
            30,
            6,
            11.5,
            bodyStyle.fontFamily,
            theme.card.background,
            theme.primaryAction.background,
            theme.card.background,
            theme.card.border,
            bodyStyle.textColor,
            theme.primaryAction.textColor,
            theme.card.textColor,
            theme.primaryAction.background)
    }

    private static func enabledRank(domain: CjguiRuleSetEditingDomain,
        item: CjguiComposableUiVariableHeightListItem): Int64 {
        if (let Some(record) <- domain.appliedRecordForResourceId(item.resourceId)) {
            if (record.enabled) { 1 } else { 0 }
        } else {
            2
        }
    }

    private static func retentionValue(domain: CjguiRuleSetEditingDomain,
        item: CjguiComposableUiVariableHeightListItem): Int64 {
        if (let Some(record) <- domain.appliedRecordForResourceId(item.resourceId)) {
            record.retentionCount
        } else {
            9223372036854775807
        }
    }

    private static func excludedValue(domain: CjguiRuleSetEditingDomain,
        item: CjguiComposableUiVariableHeightListItem): String {
        if (let Some(record) <- domain.appliedRecordForResourceId(item.resourceId)) {
            record.excludedType
        } else {
            ""
        }
    }

    // UTF-8 preserves code-point order, so comparing raw bytes gives a stable,
    // locale-independent text order without parsing numbers as strings.
    private static func compareText(left: String, right: String): Int64 {
        let leftBytes = left.toArray()
        let rightBytes = right.toArray()
        var index: Int64 = 0
        while (index < leftBytes.size && index < rightBytes.size) {
            if (leftBytes[index] < rightBytes[index]) {
                return -1
            }
            if (leftBytes[index] > rightBytes[index]) {
                return 1
            }
            index += 1
        }
        return compareInt64(leftBytes.size, rightBytes.size)
    }

    private static func compareInt64(left: Int64, right: Int64): Int64 {
        if (left < right) {
            return -1
        }
        if (left > right) {
            return 1
        }
        return 0
    }
}
