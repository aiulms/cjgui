// Optional public registration of the workspace containers a normal generated
// region commonly needs. Each kind reuses the presentation's OWN properties;
// this helper only decides which already-supported kinds a catalog publishes.
// An application opts in, so a plain form keeps its small vocabulary.
package cjgui

import std.collection.*

public class CjguiGeneratedUiWorkspaceCatalog {
    /// Registers tabs/tabPage, scrollArea and split (and optionally the built-in
    /// image kind) into an existing catalog. Returns "" on success, otherwise a
    /// stable `workspace_registration:<reason>` token; the caller still owns the
    /// catalog and its field/action/choice/resource declarations.
    public static func registerInto(catalog: CjguiGeneratedUiCapabilityCatalog,
        includeImage!: Bool = false, tabsChildLimit!: Int64 = 3,
        scrollChildLimit!: Int64 = 1, splitChildLimit!: Int64 = 2): String {
        let pageProperties = CjguiGeneratedUiPresentation.tabPageContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            pageProperties.add(property)
        }
        if (!catalog.registerComponent(CjguiGeneratedUiComponentSpec("tabPage", pageProperties, true,
            childLimit: scrollChildLimit))) {
            return "workspace_registration:${catalog.registrationIssue()}"
        }
        let tabsProperties = CjguiGeneratedUiPresentation.tabsContentProperties()
        for (property in CjguiGeneratedUiPresentation.containerStyleProperties()) {
            tabsProperties.add(property)
        }
        if (!catalog.registerComponent(CjguiGeneratedUiComponentSpec("tabs", tabsProperties, true,
            childLimit: tabsChildLimit))) {
            return "workspace_registration:${catalog.registrationIssue()}"
        }
        let scrollProperties = CjguiGeneratedUiPresentation.scrollContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            scrollProperties.add(property)
        }
        if (!catalog.registerComponent(CjguiGeneratedUiComponentSpec("scrollArea", scrollProperties, true,
            childLimit: scrollChildLimit))) {
            return "workspace_registration:${catalog.registrationIssue()}"
        }
        let splitProperties = CjguiGeneratedUiPresentation.splitContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            splitProperties.add(property)
        }
        if (!catalog.registerComponent(CjguiGeneratedUiComponentSpec("split", splitProperties, true,
            childLimit: splitChildLimit))) {
            return "workspace_registration:${catalog.registrationIssue()}"
        }
        if (includeImage) {
            let imageProperties = CjguiGeneratedUiPresentation.imageContentProperties()
            for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
                imageProperties.add(property)
            }
            if (!catalog.registerComponent(CjguiGeneratedUiComponentSpec("image",
                imageProperties, false))) {
                return "workspace_registration:${catalog.registrationIssue()}"
            }
        }
        return ""
    }
}
