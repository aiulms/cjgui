package cjgui_mixed_form_starter

import cjgui.*
import cjgui_shared_operation_core.*

// Same-binary, no-window check of the opt-in composition seam. GUI acceptance
// still runs separately through the ordinary application entry.
func checkMixedComposition(): Int64 {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain, commandSurfaces: true)
    var initialApply = false
    for (command in controller.candidateSceneCommands()) {
        if (command.id == "preset.APPLY_DRAFT") { initialApply = command.isEnabled }
    }
    let edit = domain.editTextFromHuman(6201, "", 0, 0)
    var refusedApply = false
    for (command in controller.candidateSceneCommands()) {
        if (command.id == "preset.APPLY_DRAFT") { refusedApply = !command.isEnabled }
    }
    let snapshot = domain.formSnapshot()
    let field = snapshot.fieldForResourceId(6201)
    let defaultCommands = MixedFormController(PrintPresetDomain()).candidateSceneCommands().size
    let ok = initialApply && edit.applied && refusedApply && !snapshot.canApply &&
        field.draftText.isEmpty() && field.appliedValue.displayText() == "资料" && defaultCommands == 2
    // The readable card is ONE registered composite over the SAME declarations.
    // Its description publishes the declared children and every projection
    // source, so an external author can compose it from discovery alone; the
    // named styles the children reference are registered from the same theme.
    let theme = CjguiComposableUiTheme.beaconDark()
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    let catalog = form.capabilityCatalog(maxNodes: 96)
    let registered = registerPresetCardComposite(catalog, { => theme }) &&
        syncPresetCardNamedStyles(catalog, theme)
    let described = CjguiGeneratedUiEncoding.describe(catalog)
    let readable = registered && described.contains("COMPOSITE presetCard children=1") &&
        described.contains("ELEMENT presetCard nameError projection") &&
        described.contains("source=field_error") &&
        described.contains("source=action_reason") &&
        described.contains("COMPOSITE presetCard") && described.contains("expanded_nodes=22")
    println("MIXED_COMPOSITION_CHECK owner_apply_and_refusal=${ok} default_commands=${defaultCommands} " +
        "readable_card=${readable}")
    return if (ok && readable) { 0 } else { 1 }
}
