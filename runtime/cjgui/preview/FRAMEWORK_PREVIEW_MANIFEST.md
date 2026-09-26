# CJGUI local framework source preview

This is an experimental source preview, not a released SDK or ABI promise.
It contains exactly what `scripts/export_framework_preview.sh` copies, and the
same list the export chain compares against the author checkout:

- `framework/cjgui/src/`: **11** Cangjie files implementing the current public
  composable-window surface, plus the package `cjpm.toml`;
- `framework/cjgui/shared_operation_core/src/`: **9** Cangjie files plus its
  `cjpm.toml` and the public Python surface: the descriptor-gated `client.py`,
  the typed generated-UI layer `cjgui_generated_client.py` and the runnable
  public examples `example_generated_consumption.py` (discover/build/submit/
  wait/ticket), `example_generated_observation.py` (atomic snapshot + guarded
  section re-read + bounded change cursor) and
  `example_generated_candidate_race.py` (two independent clients against one
  base version);
- `framework/cjgui/native/`: **5** macOS sources (`cjgui_internal_renderer.m`/
  `.h`, `cjgui_native_bridge.m`/`.h`, `cjgui_macos_application_launcher.m`);
- `framework/cjgui/resources/`: 2 bundled raster resources;
- `framework/cjgui/scripts/`: the normal runner and application creator;
- `framework/cjgui/templates/macos_application/`: the small application
  templates;
- `framework/rule_set_application/` and `consumers/`: the rule-set application
  package plus the three public consumers (`tree_outline_consumer`,
  `generated_panel_consumer`, `rule_set_window_app`), copied with their whole
  `src/` trees and rewritten `cjpm.toml`/launcher paths so the export root builds
  and runs by itself. Unlike the framework package, these consumer trees are
  copied wholesale, so the **9** consumer test files they carry are part of the
  payload: `rule_set_application/src/rule_set_editing_test.cj` (1),
  `tree_outline_consumer/src/catalog_content_update_test.cj` and
  `shared_definitions_consumption_test.cj` (2),
  `generated_panel_consumer/src/generated_editor_test.cj`,
  `task_edit_card_test.cj` and `generated_tabs_pages_test.cj` (3), and
  `rule_set_window_app/src/`
  `candidate_rejection_observability_test.cj`,
  `rule_set_tree_row_identity_test.cj`,
  `rule_set_tabs_workspace_test.cj`,
  `variable_height_consumer_test.cj` (4);
- the repository-root `LICENSE`/`NOTICE` text copied to the preview root,
  `framework/cjgui` and `framework/cjgui/shared_operation_core`, and the exported
  rule-set application's `cjpm.lock` (kept so the exported graph builds
  reproducibly; it contains no absolute path).

Excluded: framework probes and the framework package's own `*_test.cj` files,
native verification scripts, build outputs, per-round native caches (including the
`framework/cjgui/native/lib` artifacts a build inside the export root creates),
history, and user data. The consumer path-depends on `framework/cjgui`; it neither
needs nor names the source workspace.

The exact comparison set, its per-file hashes and the aggregate fingerprint are
printed by the export chain (`step1b source_fingerprint_match` plus one
`file ... sha256=... origin=...` line per input). Both categories are hashed by
FINAL exported content and export-relative path, so the `files=` count is exactly
the number of hashed inputs and the aggregate covers the whole payload. The checker
also reconciles the WHOLE export tree as a set: every file that exists must be
either a hashed payload input or a known generated artifact (`target/`, `.cjgui/`,
`native/lib/`, `*.log`, `.DS_Store`); any other file fails the check, so a newly
exported file that nobody declared cannot silently change the payload:

- `origin=identical`: exported bytes must equal the author original (framework
  sources and `cjpm.toml`, shared-core sources/`cjpm.toml`/`client.py`, native
  sources, resources, scripts, templates, the consumer `cjgui_macos_app.sh`
  launchers, and the copied licences);
- `origin=rewritten`: exists and is hashed as exported, with no byte-identity
  claim (package `cjpm.toml` dependency paths, consumer `run.sh` launchers, and
  this manifest).

`framework/cjgui/shared_operation_core/client.py` is the optional generic
descriptor-gated local client. It discovers actions, typed parameters and
resource IDs from the application-issued descriptor/snapshot; it is not an
Agent or model runtime. The collaboration starter deliberately exposes one
shared resource for its task title and state, rather than a controller draft
next to a separately mutable record.

The runner records actual `source_origin` and `resource_origin` lines. To
validate an independent preview build, clear inherited
`CJGUI_NATIVE_SOURCE_DIR` for that one command and assert those lines name
this preview. The variable remains a supported explicit developer override.

Source origin: `runtime/cjgui` in the exporting checkout. This checkout does
provide `LICENSE` and `NOTICE` at the repository root. The exporter copies
their unchanged text to the preview root, `framework/cjgui`, and
`framework/cjgui/shared_operation_core` so either package remains accompanied
by the source project's Apache-2.0 terms when copied independently.
