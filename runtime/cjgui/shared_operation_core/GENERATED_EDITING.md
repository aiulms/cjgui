# Runtime generated-UI editing

Status: DS group, 2026-10-23 (DS48 package). Accepts the DS46 handoff:
`COMPOSITION_END`/`COMPOSITION_REMOVE`, a complete accepted definition catalog
in the same atomic snapshot as NODE/PROPERTY and INSTANCE rows, per-instance
owner facts, and `presentation=select`. A candidate may carry SEVERAL complete
definitions (bounded by the published `COMPOSITION_BUDGET`) plus an explicit
removal list and arbitrary node edits; a node-only candidate against a format-2
region omits definitions and retains the accepted catalog. The same package adds
the portable `cjgui.ui-document` v1 file and its export/import/apply commands.
The preview keeps the candidate delta digest separate from the complete
expected accepted-state digest; saved plans and receipts carry both. Composition
editing, A/B instance edits, cross-process plan apply, rejection-keeps-old,
legal continuation and read-only status/resume were exercised against a live
mixed app built from the frozen DS46 SDK. The sixth package's lossless
boundaries, single-token validator and named pre-send refusals are retained;
its "composition editing refused" limitation is gone, not hidden. Previous
mixed/rules acceptance, declaration editing, deterministic saved plans and
restore evidence is retained.

This is a key-addressed editing layer over the existing generated-UI protocol.
It does not define a second protocol, owner, interpreter or visual editor: a
plan becomes the complete node list that `cjgui_generated_client.py` already
submits, and the application's framework still decides acceptance through its
real candidate ticket.

The readback examples preserve the existing typed FIELD facts, including each
owner, draft/applied text, field/draft/state versions and availability/refusal/
validation reasons. Field ids alone are not unique across owners. Use a declared
instance or owner selector; do not infer an owner or a version from a different
aggregate header. An absent FIELD text/version is None (JSON null); an explicit
empty value or zero is retained. The legacy unpublished owner marker remains -1.
A missing coherent FORMSTATE is still marked unknown by its existing known flag;
the examples do not invent a new snapshot protocol or issue a business edit to
obtain readback.

Files:

- `cjgui_generated_edit.py` — importable API and CLI
- `test_generated_edit.py` — 121 targeted tests (`python3 -m unittest test_generated_edit -v`)
- `example_generated_edit.py` — live invocation against a real descriptor
- `GENERATED_EDITING.md` — this document

## Public editing API

```python
from cjgui_generated_client import GeneratedProperty, GeneratedUiSession
from cjgui_generated_edit import (
    EditNode, GeneratedEditPlan, InsertNode, MoveNode, SetDeclaration, SetProperty,
    apply_saved_plan, preview_plan, submit_preview, structure_from_snapshot,
)

session = GeneratedUiSession.connect(descriptor_path)
capabilities = session.capabilities()
snapshot = session.snapshot()
structure = structure_from_snapshot(snapshot)

plan = GeneratedEditPlan(
    base_version=structure.version,
    operations=(
        SetDeclaration("title", kind="select", field="duplex"),
        SetProperty("title", "placeholder", "Single / duplex"),
        SetProperty("title", "label", "Duplex printing"),
        InsertNode("panel", 1, EditNode("hint", "label", properties=(
            GeneratedProperty("text", "Edited at runtime"),))),
        MoveNode("hint", "panel", 0),
    ),
)
preview = preview_plan(structure, plan, capabilities,
                       endpoint=snapshot.endpoint)   # local only
outcome = submit_preview(session, preview)            # one real submission
if outcome.succeeded():                               # accepted + exact readback
    print(outcome.accepted_version, outcome.submit_to_accepted_ms)
```

`GeneratedEditPlan` is built against exactly one accepted version. Addresses are
the application's stable node keys, the same keys the accepted structure already
carries; there is no index- or path-based identity.

Supported operations (applied in list order, so a batch is one candidate and
one version step):

| JSON `op` | Fields | Meaning |
| --- | --- | --- |
| `set_property` | `key`, `name`, `value` | Replace or append one property on a node |
| `remove_property` | `key`, `name` | Remove an existing property |
| `set_declaration` | `key`, optional `kind`, `field`, `action` | Change the component kind and/or its field/action binding |
| `insert` | `parent`, `index`, `node` | Insert a whole subtree; index `0..len(children)` |
| `delete` | `key` | Remove a subtree; the root is refused |
| `move` | `key`, `parent`, `index` | Reorder/reparent; index is evaluated after removal |

`set_declaration` addresses the existing node by stable key and changes only the
declaration it names: an absent key means "keep", `null` for `field`/`action`
clears the binding, and `kind` must be a published component. Properties that are
not mentioned are preserved byte for byte, so a declaration change can be
combined with the property changes it requires in one candidate and one version
step. The preflight validates the new kind's properties against the catalog but
does not invent or execute field/action semantics; the framework owns rebinding
and retirement. The diff reports each difference, for example
`! title.kind: 'label' -> 'select'` and `! title.field: None -> 'duplex'`, and
also lists them structurally under `declaration_changes`. A declaration change
that alters nothing is refused as `invalid_plan` rather than spending a version.

A raw plan file is JSON with exactly two fields:

```json
{
  "base_version": 9,
  "operations": [
    {"op": "set_property", "key": "seed-root", "name": "gap", "value": "4"},
    {"op": "insert", "parent": "seed-root", "index": 1,
     "node": {"key": "hint", "kind": "label",
              "properties": {"text": "Edited at runtime"}}},
    {"op": "move", "key": "hint", "parent": "seed-root", "index": 0}
  ]
}
```

Node objects accept `key`, `kind`, optional `field`, optional `action`,
`properties` (object of strings/numbers/booleans) and `children`. Unknown
fields, missing fields, non-identifier keys and wrong scalar types are refused
rather than ignored.

### Initializing an empty generated region

```python
outcome = initialize_structure(session, EditNode(
    "root", "vertical",
    children=(EditNode("title", "label", properties=(
        GeneratedProperty("text", "First structure"),)),)))
```

`initialize_preview` / `initialize_structure` accept a root node or a flat node
sequence, run the same catalog validation, wire encoding and candidate
submission as every edit, and refuse with `structure_not_empty` unless the
atomic snapshot is v0 with no nodes. An existing structure is never overwritten
implicitly; continue with a normal key-addressed plan. The CLI form reads
`{"node": {...}}`.

### Preflight versus authority

`preview_plan` checks what the published catalog and the protocol make checkable
locally:

- base version equals the accepted version (otherwise `stale_base_version`);
- every addressed key exists, new subtrees do not duplicate keys, insert/move
  indices are in range, root delete/move is refused, and a move under the
  node's own descendant is refused as a cycle;
- kind is published; properties are published for that kind (plus the
  framework's common semantic/window properties); required properties are
  present; no duplicate property names;
- value type, integer range, UTF-8 length and enumerations follow the catalog;
- field and action bindings are published; children are allowed and within the
  child limit; depth/node/property budgets hold;
- the result encodes with the existing encoder, and a plan that changes nothing
  is refused (`no_changes`) instead of burning a version.

This is a *preflight*, not acceptance. The application remains the authority:
its framework can reject a plan for rules not expressible in the catalog, its
catalog can change between read and submit, and the editor cannot widen the
authorization scope the application published. `GeneratedEditPreview` is always
`local_only=True`; its text begins with
`LOCAL PREVIEW (not submitted; the application decides acceptance)`.

The preview carries the snapshot endpoint identity, `base_version`, the base
structure SHA-256 (of the encoded complete structure), accepted candidate
version, scene state, flattened node list, operations and a readable diff
(`+` added, `-` removed, `~` changed, moved/reordered markers).

### Submission, atomic readback and the only success rule

`submit_preview` performs exactly one `session.submit(nodes, base_version)` and
reads the real candidate ticket. There is no automatic retry, replay after a
timeout or guessed rebase. `timeout_ms` is the candidate settlement budget;
`total_timeout_ms` optionally bounds the whole call and starts before the first
atomic snapshot, so setup time is charged against the same budget.

Once a ticket has been allocated, a later endpoint disconnect or replacement
still reports the real `endpoint_unavailable`/`endpoint_replaced` error, but the
outcome keeps the ticket, the submitted nodes/digest, the phase that was being
executed (`candidate_wait` or `readback`), and any terminal `ACCEPTED` state and
version already observed. The request is never redirected to the new endpoint
or resubmitted; the saved receipt remains traceable. This preserves facts; it
does not promise that the old endpoint recovers or that the ticket is usable
elsewhere. A failure before a ticket exists does not fabricate one.

A first snapshot that hits `TimeoutError` or `GeneratedUiDeadlineExceeded` is
`timeout` (exit 6) with phase `snapshot`, in the API and the CLI, including
`initialize_structure`; it is not reported as an unreachable endpoint or a
protocol error. `timeout_ms` keeps its existing meaning: candidate-wait budget.

`accepted` is returned only when all of the following hold:

1. the ticket settles as `ACCEPTED`;
2. the ticket's accepted version agrees with the submit reply;
3. the ticket endpoint, the atomic snapshot endpoint and the submitted endpoint
   are the same instance and bind generation;
4. the snapshot's accepted structure version is that accepted version;
5. the snapshot is a lossless format-1 document with no composition
   definitions and its nodes exactly equal the submitted nodes
   (`same_structure`, not a count or version comparison). Matching NODE lines
   inside a definition-bearing or partially understood document are not the v1
   document this editor submitted.

The readback uses `session.snapshot()`, the existing atomic generated snapshot
that carries endpoint identity together with the accepted structure. It is not
an independent identity query and not just a version/body comparison. A
readback deadline is reported as `timeout`, never as `rejected` or
`protocol_error`. A version increase alone is never treated as success. If the
candidate was accepted and then replaced, the outcome is
`replaced_after_accept`; if the atomic structure differs, `readback_mismatch`
with the actual structure attached.

Outcomes and CLI exit codes:

| Outcome | Meaning | Exit |
| --- | --- | --- |
| `accepted` | Ticket ACCEPTED and exact atomic readback | 0 |
| `stale` | Base version is no longer accepted; old structure untouched | 4 |
| `rejected` | Ticket settled as REJECTED, or synchronous named refusal | 5 |
| `superseded` | Candidate was replaced before it settled | 5 |
| `replaced_after_accept` | This candidate was accepted, then replaced | 5 |
| `refused` | Submit refused without a usable ticket | 5 |
| `timeout` | No settlement within budget; result remains unknown | 6 |
| `endpoint_replaced` | The descriptor now names another endpoint | 7 |
| `endpoint_unavailable` | Connection lost or endpoint not reachable | 7 |
| `protocol_error` | Malformed reply | 8 |
| `readback_mismatch` | Accepted structure did not match the submission | 8 |
| `unknown` | Candidate state is genuinely UNKNOWN | 9 |

`UNKNOWN` stays `unknown`; it is never folded into `rejected`, and neither is a
timeout. A timeout is explicitly not success: the request may still be applied
later, so use the saved receipt and query it; the API never resends it.

Structure edits only change the generated-UI structure. They do not invoke an
action, do not submit field drafts and do not call any business endpoint.

`submit_plan` is the one-call convenience: read snapshot, preflight, submit.

### Saved plans, receipts and read-only queries

A saved plan is versioned JSON (`cjgui.generated-edit.plan`, version 1) with:

- the endpoint instance and bind generation;
- the baseline accepted structure version and SHA-256;
- the key-addressed operations;
- the exact preview produced against that baseline (nodes, operations, diff,
  endpoint, digest).

`apply` of a saved plan first takes an atomic snapshot and checks the endpoint,
then the baseline version and digest. If either changed, it refuses with
`stale_base_version` or `endpoint_replaced`; it does not rebase, redirect or
replay. It also recomputes the preview and refuses if the saved preview differs.
The digest is a consistency check, not authorization: no credential or token
is stored, and the descriptor remains the caller's input.

Preview verification still checks the endpoint, baseline version/digest, the
complete node list, the ordered operations and the readable diff. The diff is
compared as a semantic set: its internal list order is sorted before comparison,
because older v1 plans were written while `reordered_parents` and its lines came
from a hash-ordered set. A saved v1 plan that differs only in that ordering is
accepted; a changed key, value, kind, binding, child order, node, operation or
unknown extra diff field is still `saved_preview_mismatch`. New plans use stable
tree-traversal order for `reordered_parents` and lines, so two processes reading
the same baseline produce the same document without a fixed `PYTHONHASHSEED`.

The same guarantees are public, so callers never need the private
`_verify_saved_plan` and never bypass the endpoint/digest guards:

```python
from cjgui_generated_edit import (
    apply_saved_plan, apply_saved_plan_document, preview_saved_plan,
)

preview = preview_saved_plan(session, saved)          # guards + local preview
outcome = apply_saved_plan(session, saved)            # guards + one submission
outcome = apply_saved_plan_document(session, text)    # load then apply
```

`preview_saved_plan` returns the stored exact preview only after the endpoint
and baseline checks pass; it still does not submit. `apply_saved_plan` performs
those checks, then exactly one submit and the normal atomic readback.
`stale`, `endpoint_replaced`, `timeout` (including a first-snapshot deadline)
and all submission outcomes are returned in the same `GeneratedEditOutcome`
type as the CLI. An initial snapshot taken inside either function is charged to
`total_timeout_ms` when supplied.

After a submission that allocated a ticket, `receipt_from_outcome` writes
(`cjgui.generated-edit.receipt`, version 1):

- the complete ticket (token, receipt id, endpoint, base and candidate version);
- the exact submitted structure and its SHA-256;
- the last observed outcome/terminal state and creation time.

`status` performs one `candidate_state` read; `resume` waits for the ticket to
settle. Both are read-only: they call `candidate_state`/`snapshot` and never
`submit`. When accepted, they cross-check the ticket against the atomic snapshot
with the same consistency rule as the submit path: endpoint, accepted version,
the ticket's own candidate version (when the saved receipt has one), and the
exact submitted nodes. A mismatch is `readback_mismatch`, not `accepted`.
A malformed or truncated instance section is a named `protocol_error` (with
`exact_readback=False`) that still reports the terminal state and accepted
version observed for the ticket; it is never retried and never presented as an
empty successful catalog. Neither command resubmits a timed-out request.

The client-side baseline check is a consistency guard, not a server-side atomic
guarantee. A concurrent writer can still change the structure between the client
read and the submit; the server's CAS (`structure_version_conflict`, reported as
`stale`) remains the authority. No protocol change was needed for this package.

## Capability discovery

`capabilities` (API: `session.capabilities()`, or the CLI command) preserves the
old typed client's full published facts. The JSON and text forms are derived
from the same projection and include:

- surface protocol/version/subset/extra, compatibility and stability;
- components with child allowance, child limit and every property fact:
  type, required, default, min/max, max length, encoding, values, unit, value
  range, semantics, stability and backend support;
- composites with fields/nested kind facts as published;
- elements and their parent/child-kind constraints;
- fields with kind, label, callable, required, min/max, max length, argument;
- actions with label; image and font resources with their published facts;
- window background and support/evidence records;
- the CHOICE format declaration and every current option (`fieldId`, `key`,
  `value`, `enabled`, `reason`, `label`).

Facts the endpoint did not publish stay empty/absent; they are not inferred, and
this is not a second simplified catalog or a complete framework validator.

The projection has a separate `client` section (text line `CLIENT_FORMATS`)
that states what THIS tool version understands: format-1 node structures and
the handed-off CHOICE v1 / `GENERATED_UI_STRUCTURE 2` grammars (definitions,
`COMPOSITION_END`, `COMPOSITION_REMOVE`, `presentation=select`, complete
accepted catalogs in one atomic snapshot, read-only instance owner facts) are
supported, with multiple definitions per candidate (bounded by the endpoint's
published `COMPOSITION_BUDGET`), stable keys and — since DS51 §16 — nested
composition references (`CTEMPLATE ... composition compose=<name>`, bounded
acyclic, resolved against the whole effective definition set). This is a client
product fact, not an endpoint capability and not a claim that the application
cannot support them. Endpoint facts remain only those actually published in
`GeneratedCapabilities`; a fact the endpoint did not publish stays absent. The
internal handoff status of the DS/C teams is not emitted as an endpoint state.

## CHOICE discovery (v1)

The typed client now parses the only format DS handed off:

```
CHOICE_FORMAT version=1 encoding=token fields=fieldId,key,value,enabled,reason,label
CHOICE <fieldId> key=<token> value=<token> enabled=0|1 reason=<token|none> label=<token>
```

- `GeneratedChoiceFormat` records version, encoding, field table, and a
  client-side `state`: `supported` only for the exact line above, otherwise
  `unsupported_by_client`. The latter is never rewritten as an endpoint
  capability; rows of an unknown format are not interpreted, so the client
  cannot present guessed options.
- `GeneratedChoiceOption` keeps `field_id`, `key`, `value`, `enabled`,
  `disabled_reason` and `label`. `key` is the routing identity; `label` is
  display text only. `GeneratedCapabilities.choice_options`,
  `choice_fields()` and `choice_options_for(field_id)` expose the current
  publish without writing anything back to the application.
- A missing `CHOICE_FORMAT` leaves `choice_format=None` and an empty option
  tuple; it is not converted into "no choices". A `CHOICE` row before the
  format, a repeated `(field, key)`, a malformed `enabled`, unknown or missing
  tokens, invalid `u8:` hex/UTF-8, or an option on an unpublished field is
  refused.
- Tokens follow the producer rule: non-empty printable ASCII `0x21..0x7E`
  without `=` stays literal, everything else is `u8:<UTF-8 hex>`. The producer
  emits uppercase hex; the parser accepts either case and re-emits uppercase
  when comparing. `reason=none` means an empty reason; a non-empty reason whose
  text is literally `none` is carried as `u8:6E6F6E65`, so the two stay
  distinct. The sixth-package ambiguity is closed by the DS46 correction.
- `encode_generated_text_token` implements the same encoding for tests and
  future callers; it does not publish anything.

## Runtime composition (v2: definitions, END/REMOVE, Select)

The client parses and encodes the DS46 definition section of
`GENERATED_UI_STRUCTURE 2` without adding a second protocol:

- `GeneratedCompositionParameter`, `GeneratedCompositionElement`,
  `GeneratedCompositionTemplateNode` and `GeneratedRuntimeComposition` carry
  the published definition; `GeneratedStructureDocument` is the complete
  definition-plus-node document and also carries `removals`.
  `GeneratedStructure` carries `format_version` and `compositions`.
- Grammar: `COMPOSITION <name> <nodeLimit> <depthLimit>`, `CPARAM`, `CELEMENT`,
  `CTEMPLATE`, `COMPOSITION_END <name>`, `COMPOSITION_REMOVE <name>`,
  `NODE`/`PROPERTY`, `END`. A candidate definition ends with
  `COMPOSITION_END`; `COMPOSITION_REMOVE` is a candidate-only instruction and
  is never parsed out of an accepted catalog.
- An accepted catalog may hold several definitions. ONE candidate may carry
  several complete definitions plus an explicit removal list and any number of
  node edits. Each section ends with its own `COMPOSITION_END`; duplicate
  definitions/removals, defining and removing the same name, a missing END, and
  aggregate element/template-node/byte overruns are named refusals. A candidate
  that is not accepted publishes nothing: a bad later section cannot commit an
  earlier one. Endpoints that do not publish the budget are treated as
  one-definition endpoints (no optimistic split, no silent batching).
- A node-only candidate against a format-2 region emits
  `GENERATED_UI_STRUCTURE 2` with no definition section; accepted definitions
  are retained. A same-name definition replaces the whole definition; removal
  is explicit and is refused locally when the same candidate still references
  the name.
- `presentation=select|radio|segmented` is accepted for a field-role element;
  the endpoint requires a declared option source for that field. Instances
  built from a select element publish an action-kind toggle for each instance.
- Structural checks mirror the handed-off rules where the client can decide
  them: split has exactly two children, leaf templates have no children,
  element references exist, no recursion/nested compositions, and parameter /
  element / template / depth budgets. Unknown content still makes the document
  read-only rather than pruned.
- `u8:` tokens: the producer emits uppercase hex; parsing is case-insensitive
  and re-emission is uppercase. `reason=none` is the empty reason; literal text
  `none` is `u8:6E6F6E65`.
- Instances are read from the SAME atomic snapshot: `instances_from_snapshot`
  frames the bare `INSTANCE` rows with `INSTANCE_LENGTH`/`END` and reuses
  `parse_generated_instances`; no second request is made. The bare section has
  no cursor of its own, so its parsed rows inherit that snapshot's
  `accepted_structure_version`, `candidate_token` and `candidate_state` instead
  of reporting a fresh v0/none. A malformed row is a named protocol failure
  from the same snapshot; it is never dropped into an empty instance list.
- `instance_facts` separates two digests. `sha256` is the stable binding
  digest over key/element/role/id/kind/field/action/owner; `presentation_sha256`
  covers only `enabled`/`visible`. Bounds are excluded from both because they
  move with layout/scene. Consequently a visibility-only change keeps `sha256`
  and changes `presentation_sha256`, while `owners`/`owner_conflicts` name the
  write targets. Instance `key` is the identity, `owner` the write target, `id`
  the layout identity and `semantic` the visual/accessibility identity.
- `show` and readback use only the accepted snapshot. A submitted candidate is
  never assembled into an accepted state; a rejected candidate leaves
  definitions, instances, values and public discovery unchanged.

### Editing an accepted composition

`preview` carries two different digests:

- `submitted_sha256` — the candidate delta actually sent (definition + nodes
  when present);
- `expected_structure_sha256` — the COMPLETE expected accepted state (full
  catalog + nodes). Acceptance is exact only when the atomic snapshot's digest
  equals this value.

Plan operations (stable keys only):

```
{"op":"set_composition","composition":{...full definition...}}
{"op":"remove_composition","name":"..."}
{"op":"set_composition_limits","composition":"...","expanded_node_limit":48}
{"op":"set_composition_parameter","composition":"...","name":"title","max":60,"max_length":60}
{"op":"set_composition_element","composition":"...","key":"copies","field":"jobName","argument":"text"}
{"op":"set_composition_template","composition":"...","key":"duplex","presentation":"select"}
```

Optional fields left out mean "unchanged"; an explicit empty string clears the
field. How many definitions one plan may touch follows the endpoint's
published `COMPOSITION_BUDGET` (legacy endpoints without the line keep the
one-definition behaviour); a removal may accompany the batch. A duplicate
removal, an unknown removal, a granular operation after removal, or an
update+remove of one name is refused with a named code.

A saved plan stores endpoint, baseline version/digest, the complete expected
catalog, candidate compositions, removals and nodes. A new process may apply it
only while the accepted baseline still matches; otherwise it is refused with
`stale_base_version` (exit 4) and never replayed onto a newer tree. The saved
receipt stores the candidate token/receipt, submitted and expected digests.
`status`/`resume` read the ticket and snapshot without submitting: `accepted`
only when the current complete state equals the expected digest,
`replaced_after_accept` when a later structure superseded it, and the original
stable reason for rejected tickets.

### Public example: build, save, apply, query

`example_generated_edit.py DESCRIPTOR` still runs the node-only chain. The
same file now drives runtime compositions through the public API only:

```
python3 example_generated_edit.py DESC --inspect
python3 example_generated_edit.py DESC --composition-spec spec.json --save-plan plan.json
python3 example_generated_edit.py DESC --apply-saved-plan plan.json --save-receipt receipt.json
python3 example_generated_edit.py DESC --status-receipt receipt.json
python3 example_generated_edit.py DESC --resume-receipt receipt.json
python3 example_generated_edit.py DESC --remove-spec removal.json --save-plan removal-plan.json
```

The spec names only facts the caller chose; the example validates them against
the published catalog and never invents a business mapping:

```
{"name":"runtimePresetCard",
 "parameters":[{"name":"title","type":"STRING","required":false,"min":0,
                "max":40,"max_length":40,"default":""}],
 "elements":[{"key":"name","role":"field","field":"jobName","argument":"text"}],
 "reuse_nodes":[{"key":"cardA","properties":{"title":"card A"}}],
 "new_instances":[{"key":"card03","parent":"preset-layout",
                   "properties":{"title":"card 03"}}],
 "template":{"kind":"vertical","gap":6,"padding":6}}
```

`reuse_nodes` converts already accepted nodes by stable key to the new
definition (their existing key keeps the application's object binding);
`new_instances` inserts under a named published container. Definition names,
field/action ids, choice values and property types all come from
`capabilities`; an unpublished name fails locally before submit. A removal spec
is `{"definitions":["..."],"nodes":["..."]}`. The saved plan records the
baseline digest and is re-checked in the applying process: `stale` (exit 4)
means the endpoint moved and nothing was submitted; accepted+exact is exit 0.
Apply/query return the core's own `outcome_exit_code`/`query_exit_code`
(stale 4, rejected 5, timeout 6, endpoint 7, protocol 8, unknown 9). Whenever
the core allocated a ticket, `--apply-saved-plan --save-receipt` writes it —
including `timeout`, `endpoint_unavailable` and `unknown`; without a ticket
(e.g. `stale`) the summary says no receipt exists, and `saved_receipt` is
reported only after the file was actually written.

### Lossless boundaries

- One validator (`_composition_token_value`) is shared by parse and encode for
  positional tokens: composition/parameter names, element/template keys and
  `name=value` fields. It refuses empty/whitespace/control content with
  `composition_token_empty:<what>` or `composition_token_not_single:<what>`.
  Chinese and `=` stay valid where the grammar has one token position. Trailing
  `label=`/`text=` positions keep spaces and Chinese; only newline/CR/NUL are
  refused.
- A `CPARAM` default is one positional token. The official grammar has no escape
  for a space there (the producer would read only the first part), so the client
  refuses before submission with
  `composition_token_not_single:parameter default <name>` instead of inventing
  an encoding. Parsing the same over-split line refuses with the same code.
  `\e`/empty, `=` and backslash values still round-trip.
- Unknown content is not discarded. Unknown `key=value` tokens on COMPOSITION,
  CPARAM, CELEMENT, CTEMPLATE and NODE, and unknown declaration lines, set
  `GeneratedStructureDocument.lossless=False` (also on `GeneratedStructure`).
  The original body is kept in `source_text`. Re-encoding, digests and editing
  refuse with `composition_document_not_lossless`; `show` prints the original
  body with `DOCUMENT_LOSSLESS 0`, labels it
  `COMPOSITION_READBACK lossy_unknown_content` and claims no digest. The parsed
  known projection is still shown for inspection but is explicitly incomplete.
- Exact readback compares the complete accepted catalog by name and the exact
  nodes, and requires `lossless=True`. Equal NODE lines with a changed or
  missing definition are `readback_mismatch`, never `accepted`.
- `same_document(left, right)` compares two complete parsed structures as
  models: format, definitions (parameters, elements, templates) and nodes. It
  returns `False` when either side carries unknown content, and canonicalizes
  the producer's default horizontal `axis` to the omitted spelling for both the
  comparison and the complete-document digest. This is a read-only comparison;
  it does not replace endpoint admission or the ticket/snapshot exactness.

## CLI

```sh
cd runtime/cjgui/shared_operation_core

python3 cjgui_generated_edit.py DESCRIPTOR capabilities [--json]
python3 cjgui_generated_edit.py DESCRIPTOR show [--json]
python3 cjgui_generated_edit.py DESCRIPTOR preview plan.json \
    [--json] [--save-plan plan.saved.json]
python3 cjgui_generated_edit.py DESCRIPTOR apply plan-or-saved-plan.json \
    [--json] [--save-plan plan.saved.json] [--save-receipt receipt.json] \
    [--timeout-ms 5000] [--total-timeout-ms N] [--poll-ms 25]
python3 cjgui_generated_edit.py DESCRIPTOR init init.json \
    [--json] [--save-receipt receipt.json]
python3 cjgui_generated_edit.py DESCRIPTOR status receipt.json \
    [--json] [--timeout-ms 5000] [--total-timeout-ms N]
python3 cjgui_generated_edit.py DESCRIPTOR resume receipt.json \
    [--json] [--timeout-ms 5000] [--total-timeout-ms N]
python3 cjgui_generated_edit.py DESCRIPTOR ui-export PATH [--json]
python3 cjgui_generated_edit.py DESCRIPTOR ui-import PATH [--json] \
    [--replace-definitions] [--save-import-plan plan.json]
python3 cjgui_generated_edit.py DESCRIPTOR ui-apply SAVED-PLAN.json [--json] \
    [--save-receipt receipt.json] [--timeout-ms 5000] [--total-timeout-ms N]
```

`ui-export` writes the accepted interface as `cjgui.ui-document` v1 (atomic
same-directory replace; a failed write leaves the previous file). `ui-import`
re-discovers the CURRENT endpoint, checks the document digest and every declared
component/field/action/style/resource, and prints a plan; `--save-import-plan`
saves it bound to the endpoint, baseline version and both digests. `ui-apply`
executes exactly such a saved plan from this or a new process through the
ordinary candidate ticket. The default merges definitions and replaces the
region's node tree; `--replace-definitions` computes explicit REMOVEs from the
current accepted baseline and shows them in the preview. A stale baseline is
refused; re-preview instead of rebasing automatically. A generated region that
has not accepted any node yet (`STRUCTURE 0`) is a valid import baseline: the
first document adds the whole tree, and owner drafts/applied values stay
untouched (verified live on the rules application).

`DESCRIPTOR` is the application-issued shared operation descriptor (the app
prints its path, e.g. `CJGUI_MIXED_FORM_READY DESCRIPTOR_PATH ...`). A plan or
receipt may be `-` to read stdin. `preview` never submits; `apply`/`init` cover
the full submit path; `status`/`resume` never submit. `--json` prints only
machine-readable output on stdout in every command, including when a receipt is
saved. Local refusal details go to stderr as `ERROR <code>: ...` (and, with
`--json`, also as a JSON object).

Exit codes: the outcome table above; usage `2`; invalid local plan/init document
`3`; saved-plan baseline mismatch `4`; endpoint issues `7`.

### Saved-plan parsing (2026-10-24)

`parse_saved_ui_import_plan` and `apply_saved_ui_import` now re-establish the
preview from the CURRENT endpoint and accepted snapshot before executing it,
then require the saved candidate, expected digest/version and diff facts to
match the newly built preview. JSON types are exact: booleans only accept
`true`/`false`, version/generation fields only accept integers (never booleans,
numeric strings or floats), digests must be 64 lowercase hex characters, and
unknown keys or a different endpoint identity are refused with a named public
error. `replace_definitions` is never inferred from `bool(value)`; changing the
merge policy means building a new preview/plan. A refusal performs no submit.
The stored plan remains compatible for valid v1 plans; it gains no execution
meaning that differs from the preview the user approved.

## 窗口内界面文档会话（experimental）

`runtime/cjgui/src/composable_ui_ui_document_session.cj` adds a thin,
application-opt-in workflow over an accepted generated region. An application
that already exposes `acceptedUiDocument()` / `submitUiDocument(candidate,
expectedVersion)` only has to construct `CjguiGeneratedUiDocumentSession(
path: ...)` and route five ordinary commands:

| Action | Behavior |
| --- | --- |
| save | Export the CURRENT accepted structure and write `cjgui.ui-document` v1 with a same-directory temporary file + atomic rename. A failed write leaves the old file and the saved digest unchanged. |
| preview | Re-read the file, re-validate it through the current catalog, compute the candidate against the accepted baseline, and keep only that preview + file digest. Nothing is submitted. |
| confirm | Re-read the file, require its digest to equal the preview's file digest AND the accepted baseline version/digest to be unchanged, then submit exactly the previewed candidate through the normal CAS ticket path. A changed file/baseline returns `ui_document_file_changed`/`ui_document_baseline_changed`; the user previews again. |
| cancel | Drop the pending preview. It never writes the region or the file. |
| restore | Re-read the SAVED file and build a fresh plan against the current endpoint; it never replays an old ticket and never touches business drafts. If the file already equals the accepted structure it reports `ui_document_no_changes`. |

The session keeps only the path, the last saved document digest, the accepted
baseline and the last operation result. The live interface is always read from
the region; no second mutable node tree, ticket or business draft is stored.
Ordinary business edits do not mark the UI document dirty. The API is
experimental and does not add file watching, automatic save, persistent
history, or arbitrary code loading. Optional session-local UI history is described below. `statusText()`/`previewText()` are the
same facts an application may render as visible text; refusal reasons are
returned by the operation result, not swallowed.

Both reference consumers render these commands in their normal window
(`mixed_form` and `rule_set_window_app`) and share the same Python document
format. Rules' generated surface is empty until its dialog is opened, so the
saved document legitimately contains no nodes; its startup treats that as an
already-accepted empty surface (`empty=true`) instead of reporting a refusal.

## Live chain (2026-10-23, third package)

Candidate: `artifacts/ds43-select-search-generated-20261023/candidate/CJGUIMixedFormStarter.app`,
EXE SHA-256 `e368d32bd8056a6e6ef5f0b464fe9388f0e50e2ef561c452980ffdd50a909226`,
launched once with `--collaboration` (empty generated region); no build and no
restart followed. Each step ran in a separate Python process; the endpoint is
`3b110e6534a460a50000000000000001-1`.

1. `init` created the seed structure v0→v1; base digest `d0e8cefd...`; receipt
   saved. The seed is a label `c-edit-title` plus a text field, an integer field,
   an action node and a note.
2. `preview --save-plan` composed one candidate: `set_declaration`
   `c-edit-title` label→select bound to field `duplex`, remove its `text`,
   set `label`/`placeholder`, and adjust the root `gap`. The diff printed
   `! c-edit-title.kind: 'label' -> 'select'` and
   `! c-edit-title.field: None -> 'duplex'`.
3. A new process applied the saved plan: v1→v2 exact atomic readback in
   4.4 ms (token 2, digest `79be1b77...`); receipt saved.
4. A new-process `status` read the ticket at v2: accepted, exact readback, no
   submit.
5. A locally invalid plan (`kind not_a_component`) was refused with
   `invalid_plan` (exit 3); v2 stayed intact.
6. The v1 saved plan was replayed: refused `stale_base_version` (exit 4,
   current v2 `79be1b77...`), v2 stayed intact.
7. A saved revert plan advanced v2→v3 to the exact v1 digest `d0e8cefd...` in
   6.1 ms (token 3) with full readback; `show` confirmed v3, six nodes, original
   declarations; owner field/draft snapshot unchanged.
8. The app was closed through its window close control: `destroy complete` /
   `CJGUI_MIXED_FORM_CLOSED endpoint=cleared`, no internal-error line.

Evidence: `runtime/cjgui/artifacts/c-runtime-edit-20261023/evidence/live-20261023c/`
(`chain-*` plans, saved plans, receipts, apply/status/illegal/stale/show/owner
and `app-chain.log`). The second-package chain in `evidence/live-20261023b/`
and prior mixed/rules evidence remain valid for their recorded scope.

## Live chain (2026-10-23, fourth package: deterministic multi-parent plan)

Same accepted candidate and launch mode; a new instance, endpoint
`38eb289a62f9acfc0000000000000001-1`, started with an empty generated region.
The save process ran with `PYTHONHASHSEED=1`, every read/apply process with
`PYTHONHASHSEED=2`. Every step below was a separate Python process.

1. `capabilities --json` showed the client section (`structure_editing:
   supported`, `choice_discovery/runtime_composite_definitions:
   not_supported_by_this_client`) and no endpoint-side
   `runtime_composition` fact.
2. `init` created a nested seed v0→v1 (29.6 ms): root with `panel-a` (A1, A2),
   `panel-b` (B1) and an action; digest `dd0e0381...`.
3. `preview --save-plan` saved one batch that moves A1 to panel-b and B1 to
   panel-a, then reorders panel-a. `reordered_parents` was
   `["c-det-panel-a", "c-det-panel-b"]` in tree order; the saved document
   contained that same order and lines.
4. A new process applied the saved plan: v1→v2 exact atomic readback in 3.1 ms
   (token 2, digest `b3f7e2cd...`). This is the case that the archived RED
   rejected as `saved_preview_mismatch` under the old hash-ordered diff.
5. New-process `status` read the ticket at v2: accepted, exact, no submit.
6. A local unknown-kind declaration was refused `unknown_kind`/3 and the v1
   saved plan was then refused `stale_base_version`/4; `show` still reported v2
   with digest `b3f7e2cd...`.
7. A legal restore batch advanced v2→v3 in 33.1 ms (token 3) with exact
   readback; its digest `dd0e0381...` equals v1 and `show` reports the original
   seven-node nested tree.
8. The app was closed through its window close control: `destroy complete` /
   `CJGUI_MIXED_FORM_CLOSED endpoint=cleared`, no internal-error line.

The controlled cross-process reproduction (save seed 1, inspect/apply seed 2,
old-v1 ordering, tampered line) is
`evidence/guidance-determinism-green-20261023.json`; its four checks are true
and the archived RED is unchanged. Live evidence:
`evidence/live-20261023d/`.

## Live chain (2026-10-23, seventh package: composition transaction)

App: mixed-form created from the frozen DS46 SDK
(`artifacts/ds46-composition-transaction-select-20261023/sdk/`), built once in
`/private/tmp/c-composition-work/sdk-mixed`; `renderer_link=verified`, native
archive SHA-256 `2c6d52b6…`. One launch with `--collaboration` (empty generated
region), endpoint `9d0245a020cb27de0000000000000001-1`; no restart inside the
chain. Every C step below was a separate Python process. The DS public client
seeded the ordinary structure and performed the field write, so the chain also
shows C and DS work on the same window.

1. DS `client.py generate` created v1 (candidate token 1, `scene_accepted`),
   digest `69941e24…`.
2. C `preview --save-plan` composed ONE candidate: definition
   `runtimePresetCard` (title parameter, six elements), a `deck`, instances
   `compCardA`/`compCardB` and a footer label under the human-authored
   `preset-layout`. Candidate delta `cfd86789…`, complete expected state
   `b1d1a7f7…`. A NEW process applied it: v1→v2 accepted in 60.8 ms, token 2,
   exact readback; `show` and the atomic instance probe both returned
   `b1d1a7f7…`. The probe showed separate instances with owners
   `compCardA/compCardB=6200`, `cardA=6301`, `cardB=6302`.
3. DS `client.py set --field copies --value 6` wrote the human draft; the
   structure stayed v2 and the accepted composition/instances stayed intact.
4. C plan with `expanded_node_limit=80` was refused by the endpoint:
   `composition_rejected:composition_node_limit:runtimePresetCard` (exit 5,
   token 3). `show` still returned the old digest, limit 64, `duplex`
   `presentation=text` and title `卡片 A`; `status`/`resume` read the rejected
   ticket without replay (exit 5).
5. Legal re-edit (new process): limit 48, `title` max/max_length 60, `copies`
   rebound to `jobName`, `duplex` `presentation=select`, root `gap` 10, and
   instance properties. v2→v3 accepted in 99.3 ms, token 4, exact readback,
   digest `12b9cf77…`. `show` reported the new definition and `select`;
   the instance probe showed `duplex` as an action-kind select toggle per
   instance; the DS `read` still returned the human draft `copies=6` and the
   same v3 structure. A window capture shows the hand-written pane, the DS note
   and the C footer text (`window-v3.png`).
6. Node-only candidate (omit definitions) against format 2: candidate had NO
   `COMPOSITION` section, expected catalog still held `runtimePresetCard`.
   v3→v4 accepted in 75.2 ms, token 5, digest `b628720f…`; the definition and
   both instances were retained.
7. Explicit removal candidate: `COMPOSITION_REMOVE runtimePresetCard` plus
   deletion of `deck`. v4→v5 accepted in 59.0 ms, token 6, digest `d972190f…`;
   `show` reported format 1, zero definitions, no `compCard*` instances, while
   the human nodes and `copies=6` remained.
8. `status`/`resume` for the v4 receipt reported `replaced_after_accept`
   (current v5); for the v5 receipt both reported `accepted`, exact readback,
   in new processes. Replaying the v2 saved plan was refused locally with
   `stale_base_version` (exit 4) and submitted nothing.
9. The app was closed through its real window close button (`user close
   deferred to collection domain`, `destroy complete`,
   `CJGUI_MIXED_FORM_CLOSED endpoint=cleared`).

Evidence: `runtime/cjgui/artifacts/c-runtime-edit-20261023/evidence/live-20261023e/`
(plans, saved plans, receipts, capabilities/show/status/resume, probe, app log
and window capture).

### Separate framework-side finding (outside C write set)

A control run submitted a declaration change that the application rejected for
a framework rule not expressible in the catalog (`field='jobName'` on a select:
`select_options_missing`). The client correctly reported `rejected` (exit 5)
and the accepted v2 stayed intact (`apply-invalid.json`). After that rejected
candidate, closing the app logged:

```
CJGUI_REFRESH_INTERNAL_ERROR startup_phase=participant_prepare prepared=false static=false
CJGUI_SCENE_REJECTED reason=internal_error
```

An otherwise identical run whose declaration candidate was accepted closed
cleanly, and the clean chain above has no such line. This points at framework
candidate-rejection cleanup in the generated/window path, which belongs to DS
and Sol, not the C client; it is reported for their attribution and is not
worked around or hidden here.

## Scope and open dependencies

- Existing structures are edited only by stable key; initialization only
  applies to a genuinely empty v0 region. A declaration change keeps the key but
  does not promise an unchanged editing identity: the framework owns rebinding
  and retirement.
- Human continuation in the seventh-package chain was a field write through
  the DS public client, not typed keys, and the window capture was taken
  without scrolling the runtime pane. The screenshot shows the human pane, the
  DS note and the C footer text; the expanded cards' internals were not legible
  at that window width, while their accepted bounds/owners are in the instance
  evidence. Real keyboard typing into the window and the Select popup
  query/highlight path remain DS evidence; C does not claim them.
- The endpoint remains the acceptance authority. `preview` does not duplicate
  every endpoint budget check; the live 80-node definition was previewed
  locally and refused by the endpoint with
  `composition_rejected:composition_node_limit:runtimePresetCard`. The client
  reports that stable reason and keeps the old state.
- One candidate may carry multiple definitions plus an explicit removal list;
  the endpoint's published `COMPOSITION_BUDGET` decides the count and the
  aggregate element/template-node/byte budgets. A plan that changes more
  definitions than the endpoint allows is refused as
  `composition_batch_unsupported` instead of being split. Nested composition
  references (`compose=<name>`) are bounded and acyclic: unknown targets,
  direct/indirect cycles and deletions still referenced by a remaining
  definition are refused with stable named reasons.
- The rules consumer from the previous package was not rebuilt in this package;
  its empty-v0 → accepted → stale-preserved → restored evidence is retained.
- Endpoint replacement, endpoint loss after a ticket, and first-snapshot
  deadlines are covered by targeted unit tests; no real endpoint swap was
  performed live. Ticket preservation is traceability, not a guarantee that the
  old endpoint recovers.
- The example was not changed or rerun here; it already uses only public APIs.
  The live chains exercise the public saved-plan execution API through the CLI.
- The DS46 handoff's atomic snapshot (accepted definitions + instances in one
  read) is what makes composition editing safe here. The seventh-package chain
  exercised it on a live mixed app; the unique SDK remains frozen by DS and was
  not modified by C. Linux and `.cj` consumers were not run in this package.
- Saved v1 plans are accepted when only diff list order differs; endpoint,
  baseline version/digest, complete nodes, ordered operations and every diff
  item must still match, and unknown diff fields are refused. A real endpoint
  swap is still covered only by targeted tests.
- A separate control found that closing the app after a framework-rejected
  declaration candidate logs `CJGUI_REFRESH_INTERNAL_ERROR` and
  `CJGUI_SCENE_REJECTED reason=internal_error`. Accepted-only runs and the clean
  chain close normally. Attribution is with DS/Sol's generated/window path; it
  is not fixed or masked in the C client.
- The CLI is a Python tool over the accepted Python client in this directory.
  It exports no second SDK.

## Optional UI-document undo/redo (experimental)

`CjguiGeneratedUiDocumentSession(historyPolicy: Some(CjguiUiDocumentHistoryPolicy()))`
opts one document session into immutable accepted-UI history. The default policy
retains at most 32 complete accepted semantic snapshots (including the current
anchor) and 2 MiB of their serialized UTF-8 bytes. Rules opts into 16/1 MiB;
the mixed template's main surface uses the default, while its summary surface
stays off. A policy omitted by an existing consumer performs no history polling
or document serialization in ordinary turns. Limits must be positive. Eviction
removes whole oldest transactions; an oversize current entry creates a visible
`ui_document_history_entry_too_large` boundary, never a truncated snapshot.

`UI_DOC_UNDO` / `UI_DOC_REDO` are explicit workspace commands/buttons. They do
not claim text-editor or business Cmd-Z. The live region remains authoritative;
only accepted complete UI definitions, parameters, node ordering/properties,
bindings and resource references are retained. No widget, native object,
business draft/applied configuration, selection or authorization is restored.
Undo/redo builds a fresh REPLACE candidate, including explicit definition removals,
through the same current catalog/owner/field/slot validation. Versions increase;
old snapshot versions are never installed as current versions. The cursor moves
only after this exact token's accepted terminal, expected version AND current
full digest agree. UNKNOWN stays pending. Rejected/superseded, accepted-then-changed,
closed/replaced session and new-instance boundaries cannot promote an old result.

Adjacent accepted UI changes from human and public callers are observed at the
existing workspace completion turn. A new change after undo drops redo. If
accepted versions were missed, or a same-version digest changed, the session
invalidates the affected past with a named boundary; it cannot silently overwrite
an unobserved external edit. `workspace.resetHistory(version, digest)` explicitly
rebases to current accepted facts and discards the old chain. Save uses the real
accepted digest and keeps session history; new/open/startup adoption/Save As path
change rebase it, and actual close/reopen resets it. Nothing persists undo history
to the document file or resurrects retired range sessions.

The standard generated region and custom Rules region use the same
`CjguiUiDocumentHistoryAccess` adapter to attach/detach the existing workspace,
read facts and submit its existing commands. Custom surfaces that expose the
provider use this adapter, not a second UI tree, command router or ticket pump.
Close the workspace history in actual window disposal, not in a speculative
can-close query that business policy can still refuse.

Protocol remains `CJGUI_SHARED_OPERATION/2` and surface format remains 1.0. An
optional `UI_DOCUMENT_HISTORY version=1 supported=1 stability=experimental scope=session`
capability and `GET_GENERATED_UI_HISTORY` report support, policy, surface identity,
current accepted version/digest, opaque epoch, undo/redo availability/reasons,
retained quantities and pending action/token. Old/missing facts remain `None` in
`GeneratedUiHistoryState`; absence does not mean false or enabled. The typed
`GeneratedUiSession.history_state()` and `.history_action("undo"|"redo", baseline)`
use the same descriptor, GET/SUBMIT generated-UI permissions and existing transport.
A mutation carries exact version/digest/surface/epoch plus endpoint instance/bind
generation. Endpoint replacement is rejected before any holder lookup. Epochs
are opaque observations, not counters clients increment. No automatic refresh,
rebase, replay or retry is performed.

```sh
python3 cjgui_generated_edit.py DESCRIPTOR ui-history --json > observed.json
python3 cjgui_generated_edit.py DESCRIPTOR ui-undo observed.json --json
# Exit 9 means candidate_pending, not completed. Preserve the returned token.
```

A successful submit returns the ordinary candidate receipt. Observe it using
`session.candidate_state(token, endpoint=baseline.endpoint_identity)` or the
existing ticket waiter; terminal acceptance is distinct from GPU presentation
and from a still-current UI. Re-read current history facts after settlement
before a new action. The CLI emits named local refusals with exit 5 and no
request; lost/malformed endpoint replies retain unknown submitted/accepted/
presented facts. `--json` does not turn a pending/unknown operation into success.
The template `client.py` delegates these three commands to this same CLI.
These additive experimental source APIs require a matching rebuilt SDK; no
cross-version binary ABI guarantee or stable promotion is implied.
