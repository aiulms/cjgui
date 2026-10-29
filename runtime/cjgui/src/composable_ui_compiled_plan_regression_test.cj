package cjgui

import std.unittest.*
import std.unittest.testmacro.*

@Test
func compositionPlanCompiledFactoryIsNotAnUnknownRuntimeDefinition(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("compiledCard"), factory), true)
    let plan = cjguiCompositionExpansionPlan(catalog, "compiledCard", 8, 8)
    @Assert(plan.issue, "")
    @Assert(plan.nodes, 1)
    @Assert(plan.maxDepth, 1)
    @Assert(plan.occurrences.size, 4)
    @Assert(factory.buildCount, 0)
    // Opaque application factories still require a root allocation and the
    // real subtree is checked by the existing post-build composite audit.
    @Assert(cjguiCompositionExpansionPlan(catalog, "compiledCard", 0, 8).issue,
        "composite_expansion_node_limit")
    @Assert(cjguiCompositionExpansionPlan(catalog, "compiledCard", 8, 0).issue,
        "composite_expansion_depth_limit")
    @Assert(cjguiCompositionExpansionPlan(catalog, "notRegistered", 8, 8).issue,
        "composite_not_registered")
}
