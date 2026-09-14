# CJGUI local framework source preview

This is an experimental source preview, not a released SDK or ABI promise.
It contains only the five Cangjie files that implement the current public
composable-window surface, the seven shared-operation core files needed by
the optional connection, the narrow macOS native sources, two bundled raster
resources, the normal runner, and small application templates.

Excluded: repository examples, probes, native verification scripts, build
outputs, workspace locks, history, and user data. The consumer path-depends on
`framework/cjgui`; it neither needs nor names the source workspace.

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
