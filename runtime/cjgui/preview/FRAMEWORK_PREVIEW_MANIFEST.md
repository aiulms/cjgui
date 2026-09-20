# CJGUI local framework source preview

This is an experimental source preview, not a released SDK or ABI promise.
It contains exactly what `scripts/export_framework_preview.sh` copies, and the
same list the export chain compares against the author checkout:

- `framework/cjgui/src/`: **10** Cangjie files implementing the current public
  composable-window surface;
- `framework/cjgui/shared_operation_core/src/`: **9** Cangjie files plus its
  `cjpm.toml` and `client.py` for the optional descriptor-gated connection;
- `framework/cjgui/native/`: **5** macOS sources (`cjgui_internal_renderer.m`/
  `.h`, `cjgui_native_bridge.m`/`.h`, `cjgui_macos_application_launcher.m`);
- `framework/cjgui/resources/`: 2 bundled raster resources;
- `framework/cjgui/scripts/`: the normal runner and application creator;
- `framework/cjgui/templates/macos_application/`: the small application
  templates;
- `framework/rule_set_application/` and `consumers/`: the rule-set application
  package plus the three public consumers (`tree_outline_consumer`,
  `generated_panel_consumer`, `rule_set_window_app`), copied with their `src/`
  trees and rewritten `cjpm.toml`/launcher paths so the export root builds and
  runs by itself;
- the repository-root `LICENSE`/`NOTICE` text copied to the preview root,
  `framework/cjgui` and `framework/cjgui/shared_operation_core`.

Excluded: framework probes and test files, native verification scripts, build
outputs, per-round native caches, workspace locks, history, and user data. The
consumer path-depends on `framework/cjgui`; it neither needs nor names the
source workspace.

The exact byte-identical comparison set, its per-file hashes and the aggregate
fingerprint are printed by the export chain (`step1b source_fingerprint_match`
plus one `file ... sha256=...` line per input). Files the export deliberately
rewrites (package `cjpm.toml` dependency paths and the consumer launchers) are
recorded separately and are never hashed as author-identical sources.

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
