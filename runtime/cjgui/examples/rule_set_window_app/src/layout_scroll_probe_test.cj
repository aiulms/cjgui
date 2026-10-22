// Layout and root-scroll probes for the ordinary window. These use the real
// controller tree and the canonical layout engine, not a second composition.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func layoutProbeScene(controller: CjguiRuleSetComposableController, width: Int64,
    height: Int64, version: Int64): CjguiComposableUiScene {
    let root = controller.buildUi()
    let rect = CjguiComposableUiRect(0, 0, width, height)
    let registry = CjguiComposableUiIdentityRegistry()
    if (!registry.beginCandidate()) {
        return CjguiComposableUiLayoutEngine.layout(root, rect, version)
    }
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    let _ = registry.prepareCandidate()
    return scene
}

private func layoutProbeNode(scene: CjguiComposableUiScene, semanticId: String): ?CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.semanticId == semanticId) {
            return Some(node)
        }
    }
    return None
}

@Test
func layoutProbe620PrintsRanges(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("探针规则", true, 7, "cache", "layout-probe-create").applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    let scene = layoutProbeScene(controller, 620, 885, 1)
    layoutProbePrintRange(scene, "620")
    let wideScene = layoutProbeScene(controller, 980, 885, 1)
    layoutProbePrintRange(wideScene, "980")
    @Assert(scene.layoutError(), "")
}

private func layoutProbePrintRange(scene: CjguiComposableUiScene, label: String): Unit {
    for (semantic in ["rule-set-header", "rule-set-actions", "rule-list-filter-row",
        "rule-list-filter", "rule-batch-row", "rule-set-content", "rule-list-scroll",
        "rule-detail", "rule-detail-standard", "field-label", "field-enabled",
        "field-retentionCount", "field-excludedType", "rule-tree-section",
        "rule-generated-section", "rule-set-root", "rule-set-scroll"]) {
        if (let Some(node) <- layoutProbeNode(scene, semantic)) {
            println("PROBE ${label} ${semantic} id=${node.nodeId} x=${node.bounds.x} y=${node.bounds.y} " +
                "w=${node.bounds.width} h=${node.bounds.height}")
        } else {
            println("PROBE ${label} ${semantic} MISSING")
        }
    }
    let scroll = scene.nodeForId(480)
    if (let Some(viewport) <- scroll.scrollViewport) {
        println("PROBE ${label} viewport content=${viewport.contentExtent()} viewport=${viewport.viewportExtent()} " +
            "max=${viewport.maximumOffset()} offset=${viewport.offset()}")
    }
    for (node in scene.nodes()) {
        if (node.semanticId == "rule-list-scroll" || node.semanticId == "rule-detail") {
            for (clip in node.clipConstraints()) {
                println("PROBE ${label} clip-of-${node.semanticId} owner=${clip.ownerIdentity} " +
                    "rect=${clip.rect.x},${clip.rect.y},${clip.rect.width},${clip.rect.height}")
            }
        }
    }
    @Assert(scene.layoutError(), "")
}

private let LAYOUT_PROBE_GENERATED: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 probeRoot vertical
PROPERTY 0 probeRoot gap 4
NODE 1 probeProgress ruleProgress
PROPERTY 1 probeProgress value 0
PROPERTY 1 probeProgress total 100
PROPERTY 1 probeProgress label 外部进度 0 / 100
PROPERTY 1 probeProgress trackWidth 260
NODE 1 probeStatus ruleStatus
PROPERTY 1 probeStatus kind error
PROPERTY 1 probeStatus text 外部写入失败：保存通道暂时不可用，请稍后重试，当前草稿仍保留在编辑器中
NODE 1 probeContent ruleContentState
PROPERTY 1 probeContent kind empty
PROPERTY 1 probeContent title 当前筛选范围没有可显示的规则记录，请调整关键词后再试
PROPERTY 1 probeContent detail 这是默认内容状态详情在窄窗口下的自然换行检查，正文不应被固定高度裁切。
NODE 1 probeName textInput field=label
PROPERTY 1 probeName label 规则名称（生成）
NODE 1 probeNote label
PROPERTY 1 probeNote text 生成区域最末行的可见说明
NODE 1 probeAction action action=APPLY_DRAFT
PROPERTY 1 probeAction label 应用生成草稿
END
"""

private func layoutProbePrintGenerated(scene: CjguiComposableUiScene, label: String): Unit {
    for (semantic in ["rule-generated-section", "rule-generated-status", "rule-set-root"]) {
        if (let Some(node) <- layoutProbeNode(scene, semantic)) {
            println("PROBE ${label} ${semantic} x=${node.bounds.x} y=${node.bounds.y} " +
                "w=${node.bounds.width} h=${node.bounds.height}")
        }
    }
    for (node in scene.nodes()) {
        if (node.semanticId.contains("probe") || node.value.contains("外部进度") ||
            node.value.contains("外部写入失败") || node.value.contains("当前筛选范围")) {
            println("PROBE ${label} gen-node id=${node.nodeId} kind=${node.nodeKind} " +
                "semantic=${node.semanticId} x=${node.bounds.x} y=${node.bounds.y} " +
                "w=${node.bounds.width} h=${node.bounds.height} value=${node.value}")
        }
    }
}

@Test
func layoutProbeGeneratedContentContributesToRootRange(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("生成探针", true, 7, "cache", "layout-probe-gen").applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    let region = controller.generatedUiRegion()
    @Assert(region.submitStructure(LAYOUT_PROBE_GENERATED, 0).candidateAccepted, true)
    @Assert(controller.beginSceneRefresh(), true)
    let candidateScene = layoutProbeScene(controller, 620, 885, controller.uiSceneVersion())
    @Assert(candidateScene.layoutError(), "")
    @Assert(controller.prepareSceneRefresh(), true)
    controller.commitSceneRefresh()
    @Assert(region.acceptedStructureVersion(), 1)
    let acceptedScene = layoutProbeScene(controller, 620, 885, controller.uiSceneVersion())
    layoutProbePrintGenerated(candidateScene, "candidate")
    layoutProbePrintGenerated(acceptedScene, "accepted")
    @Assert(acceptedScene.layoutError(), "")
}
