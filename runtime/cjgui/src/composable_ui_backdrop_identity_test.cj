package cjgui

import std.unittest.*
import std.unittest.testmacro.*

// The shared-operation snapshot contract accepts 1..64 ASCII identifier
// characters for a public semantic id. A framework-generated layer backdrop
// must stay inside that bound for any application-declared host/layer pair.

@Test
func boundedLayerBackdropIdentityKeepsShortPairsReadable(): Unit {
    @Assert(cjguiBoundedLayerBackdropSemanticId("settings", "dialog", 0), "settings-backdrop-dialog")
    @Assert(cjguiBoundedLayerBackdropSemanticId("rule-tree", "row-menu", 3), "rule-tree-backdrop-row-menu")
}

@Test
func boundedLayerBackdropIdentityBoundsThePanelHostLayerPair(): Unit {
    let host = "search-panel-settings-commands-host"
    let layer = "search-panel-settings-commands"
    @Assert(host.size, 35)
    @Assert(layer.size, 30)
    let id = cjguiBoundedLayerBackdropSemanticId(host, layer, 0)
    @Assert(id.size <= 64, true)
    @Assert(id.size < 64, true)
    @Assert(id.isAscii(), true)
    @Assert(id.size > 0, true)
    let first = id.toArray()[0]
    @Assert((first >= 65u8 && first <= 90u8) || (first >= 97u8 && first <= 122u8) || first == 95u8, true)
    for (byte in id.toArray()) {
        let valid = (byte >= 65u8 && byte <= 90u8) || (byte >= 97u8 && byte <= 122u8) ||
            (byte >= 48u8 && byte <= 57u8) || byte == 45u8 || byte == 95u8
        @Assert(valid, true)
    }
}

@Test
func boundedLayerBackdropIdentityIsStableAndUniquePerSibling(): Unit {
    let host = "search-panel-settings-commands-host"
    let layer = "search-panel-settings-commands"
    let first = cjguiBoundedLayerBackdropSemanticId(host, layer, 0)
    @Assert(cjguiBoundedLayerBackdropSemanticId(host, layer, 0), first)
    @Assert(first == cjguiBoundedLayerBackdropSemanticId(host, layer, 1), false)
    @Assert(first == cjguiBoundedLayerBackdropSemanticId(host, "${layer}-two", 0), false)
    @Assert(first == cjguiBoundedLayerBackdropSemanticId("${host}-two", layer, 0), false)
}

@Test
func boundedLayerBackdropIdentitySeparatesPairsThatSpellTheSameString(): Unit {
    var a = ""
    for (_ in 0..45) {
        a += "a"
    }
    let hostA = a
    let layerA = "x-backdrop-y"
    let hostB = a + "-backdrop-x"
    let layerB = "y"
    // Plain concatenation cannot tell these two hosts/layers apart.
    @Assert("${hostA}-backdrop-${layerA}", "${hostB}-backdrop-${layerB}")
    let idA = cjguiBoundedLayerBackdropSemanticId(hostA, layerA, 0)
    let idB = cjguiBoundedLayerBackdropSemanticId(hostB, layerB, 0)
    @Assert(idA == idB, false)
    for (id in [idA, idB]) {
        @Assert(id.size <= 64, true)
        @Assert(id.isAscii(), true)
        @Assert(id.size > 0, true)
        let first = id.toArray()[0]
        @Assert((first >= 65u8 && first <= 90u8) || (first >= 97u8 && first <= 122u8) || first == 95u8, true)
    }
    // The same ambiguity exists for pairs short enough to keep a readable id.
    let shortA = cjguiBoundedLayerBackdropSemanticId("a-backdrop-x", "y", 0)
    let shortB = cjguiBoundedLayerBackdropSemanticId("a", "x-backdrop-y", 0)
    @Assert(shortA == shortB, false)
    @Assert(shortA.size <= 64, true)
    @Assert(shortB.size <= 64, true)
}

@Test
func boundedLayerBackdropIdentityReachesTheResolvedModalScene(): Unit {
    let root = cjguiComposableLayerHost(1, "search-panel-settings-commands-host",
        CjguiComposableUiStyle(fixedWidth: 800, fixedHeight: 600))
    root.add(cjguiComposableVertical(2, "search-panel-settings-commands-base",
        CjguiComposableUiStyle(fixedWidth: 800, fixedHeight: 600)))
    let dialog = cjguiComposableDialogLayer(9, "search-panel-settings-commands",
        "search-panel-settings-commands", "search-panel-settings-commands-base", 2,
        CjguiComposableUiStyle(fixedWidth: 500, fixedHeight: 300))
    dialog.add(cjguiComposableText(10, "search-panel-settings-commands-title", "Commands",
        CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 30)))
    root.add(dialog)
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 800, 600), 1)
    @Assert(scene.isValid(), true)
    var backdropCount: Int64 = 0
    for (node in scene.nodes()) {
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_LAYER_BACKDROP) {
            backdropCount += 1
            @Assert(node.semanticId.size <= 64, true)
            @Assert(node.semanticId.size < 64, true)
            @Assert(node.semanticId.isAscii(), true)
            @Assert(node.semanticId,
                cjguiBoundedLayerBackdropSemanticId("search-panel-settings-commands-host",
                    "search-panel-settings-commands", 0))
        }
    }
    @Assert(backdropCount, 1)
}
