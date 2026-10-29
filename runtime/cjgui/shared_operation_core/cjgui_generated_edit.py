#!/usr/bin/env python3
"""Key-addressed editing for the runtime-generated UI structure.

This module is a thin editing layer over the SAME typed public client
(`cjgui_generated_client.py`): it decodes an accepted `GeneratedStructure` into
a tree keyed by the application's stable node keys, applies a local edit plan,
prints a readable diff, and submits the resulting complete structure through the
existing structure CAS.  It adds no transport, no owner, no interpreter and no
second permission system.

Boundaries this module keeps on purpose:

* A **preview** is LOCAL.  It shows what a candidate *would* contain and which
  accepted version it targets; it never claims that the framework accepted or
  displayed it.  Acceptance is decided by the endpoint, by the ownership ticket
  of the exact submission, and by reading the accepted structure back.
* An edit plan names a `base_version`.  If the accepted structure moved, the
  plan is stale: it is refused locally and never replayed onto a newer tree.
* Structure submission never invokes a domain action, applies a draft or writes
  business state.  The only requests sent are structure reads and the existing
  `SUBMIT_GENERATED_UI` command.
* Local preflight checks are a fail-fast projection of the published catalog
  (bounds, kinds, properties, bindings).  The endpoint remains the final
  authority; a local pass is not an acceptance claim.

CLI (same file, importable API below):

    python3 cjgui_generated_edit.py DESCRIPTOR capabilities [--json]
    python3 cjgui_generated_edit.py DESCRIPTOR show [--json]
    python3 cjgui_generated_edit.py DESCRIPTOR preview PLAN.json [--json]
    python3 cjgui_generated_edit.py DESCRIPTOR apply PLAN.json [--json] \
        [--timeout-ms 5000] [--poll-ms 25]

See GENERATED_EDITING.md for the plan JSON schema, exit codes and limits.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import re
import sys
import time
from dataclasses import asdict, dataclass, field, replace
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence

from cjgui_generated_client import (
    GeneratedCapabilities,
    GeneratedCandidateState,
    GeneratedCandidateTicket,
    GeneratedCompositionElement,
    GeneratedCompositionParameter,
    GeneratedCompositionTemplateNode,
    GeneratedEndpointIdentity,
    GeneratedInstances,
    GeneratedNode,
    GeneratedProperty,
    GeneratedRuntimeComposition,
    GeneratedSnapshot,
    GeneratedStructure,
    GeneratedStructureDocument,
    GeneratedUiDeadlineExceeded,
    GeneratedUiEndpointError,
    GeneratedUiError,
    GeneratedUiHistoryRefusal,
    GeneratedUiRemoteError,
    GeneratedUiSession,
    history_state_from_dict,
    IDENTIFIER,
    SharedOperationResponse,
    encode_generated_structure,
    encode_generated_structure_document,
    parse_generated_structure,
    parse_generated_instances,
    same_structure,
)

# Exit codes are a stable CLI contract (documented in GENERATED_EDITING.md).
EXIT_ACCEPTED = 0
EXIT_USAGE = 2
EXIT_INVALID_PLAN = 3
EXIT_STALE = 4
EXIT_REJECTED = 5
EXIT_TIMEOUT = 6
EXIT_ENDPOINT = 7
EXIT_PROTOCOL = 8
# A candidate whose ticket says UNKNOWN is not a rejection: the client does
# not know whether it will apply, so it must not be folded into exit 5.
EXIT_UNKNOWN = 9

_INT64_MIN = -(2 ** 63)
_INT64_MAX = 2 ** 63 - 1
_INTEGER_WIRE = re.compile(r"^-?[0-9]+$")

# Properties the framework accepts on any registered kind (or on the root) in
# addition to the component's own published property list.  These are handled
# by dedicated framework rules that are not repeated here; a local preflight
# must not report a legal accepted property as unknown.
_COMMON_PROPERTY_NAMES = frozenset({
    "windowBackground", "semanticRole", "semanticSelected", "semanticExpandable",
    "semanticExpanded", "semanticLevel", "semanticRowKey", "semanticParentKey",
    "semanticLabel", "disabled", "textRuns",
})


class GeneratedEditError(ValueError):
    """A local plan/preflight refusal with a stable reason token."""

    def __init__(self, code: str, detail: str, *, operation_index: int | None = None,
                 key: str | None = None) -> None:
        self.code = code
        self.detail = detail
        self.operation_index = operation_index
        self.key = key
        where = ""
        if operation_index is not None:
            where = f" operation[{operation_index}]"
        if key is not None:
            where += f" key={key}"
        super().__init__(f"{code}{where}: {detail}")


def _endpoint_dict(endpoint: GeneratedEndpointIdentity | None) -> dict[str, Any] | None:
    if endpoint is None:
        return None
    return {"instance": endpoint.instance, "bind_generation": endpoint.bind_generation}


def _endpoint_from_json(value: Any, what: str) -> GeneratedEndpointIdentity:
    if not isinstance(value, Mapping):
        raise GeneratedEditError("invalid_saved_plan", f"{what}.endpoint must be an object")
    _strict_keys(value, {"instance", "bind_generation"}, f"{what}.endpoint")
    _require_keys(value, {"instance", "bind_generation"}, f"{what}.endpoint")
    instance = value["instance"]
    bind = value["bind_generation"]
    if not isinstance(instance, str) or not instance:
        raise GeneratedEditError("invalid_saved_plan", f"{what}.endpoint.instance is empty")
    if not isinstance(bind, int) or isinstance(bind, bool) or bind < 0:
        raise GeneratedEditError("invalid_saved_plan",
                                 f"{what}.endpoint.bind_generation is not a non-negative integer")
    return GeneratedEndpointIdentity(instance, bind)


def structure_digest(nodes: Sequence[GeneratedNode]) -> str:
    """Reproducible digest of exactly the structure bytes a submit would send."""
    payload = encode_generated_structure(nodes)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def structure_document(structure: GeneratedStructure) -> GeneratedStructureDocument:
    return GeneratedStructureDocument(structure.format_version, structure.compositions,
                                      structure.nodes, source_text=structure.source_text,
                                      lossless=structure.lossless)


def structure_document_digest(structure: GeneratedStructure) -> str:
    """Digest of the complete document, definitions included.

    For a format-1 node-only structure this is byte-identical to
    `structure_digest(structure.nodes)`, so earlier saved-plan digests remain
    valid.  A format-2 document is never reduced to its NODE lines here, and a
    lossy document is refused instead of hashing a pruned body.  Known producer
    defaults are canonicalized, so an explicit horizontal axis and an omitted
    axis produce the same digest.
    """
    if not structure.lossless:
        raise GeneratedEditError(
            "composition_document_not_lossless",
            "the accepted document contains content this client did not understand; "
            "its digest is not the digest of the complete document")
    payload = encode_generated_structure_document(_canonical_document(structure),
                                                  allow_multiple=True)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def _canonical_template(node: GeneratedCompositionTemplateNode) \
        -> GeneratedCompositionTemplateNode:
    axis = "" if node.axis in ("", "horizontal") else node.axis
    return replace(node, axis=axis,
                   children=tuple(_canonical_template(child) for child in node.children))


def _canonical_composition(composition: GeneratedRuntimeComposition) \
        -> GeneratedRuntimeComposition:
    return replace(composition, template=_canonical_template(composition.template))


def _canonical_document(structure: GeneratedStructure) -> GeneratedStructureDocument:
    document = structure_document(structure)
    return replace(document,
                   compositions=tuple(sorted(map(_canonical_composition,
                                                 document.compositions),
                                            key=lambda item: item.name)),
                   removals=tuple(sorted(document.removals)))


def same_document(left: GeneratedStructure, right: GeneratedStructure) -> bool:
    """Whether two complete parsed documents describe the same content.

    Read-only comparison, not an admission claim: format, accepted definitions
    (parameters, elements, templates) and nodes must all agree. A document with
    unknown content has no complete model and never matches. The producer's
    default horizontal axis is canonicalized to the omitted spelling; all other
    fields are compared as parsed, ignoring token order and omitted-versus-
    explicit defaults that parse to the same model. Definitions are compared by
    NAME, not acceptance order.
    """
    if not left.lossless or not right.lossless:
        return False
    if left.format_version != right.format_version:
        return False
    if tuple(sorted(map(_canonical_composition, left.compositions),
                    key=lambda item: item.name)) != \
            tuple(sorted(map(_canonical_composition, right.compositions),
                         key=lambda item: item.name)):
        return False
    return same_structure(left.nodes, right.nodes)


def _parse_structure_text(text: str) -> GeneratedStructure:
    """Decode an encoded structure section, adding the standalone length line."""
    lines = text.splitlines()
    if not any(line.startswith("STRUCTURE_LENGTH ") for line in lines):
        lines.insert(1, f"STRUCTURE_LENGTH {len(text.encode('utf-8'))}")
    framed = "\n".join(lines)
    response = SharedOperationResponse(
        protocol="section", kind="GENERATED_UI_STRUCTURE",
        entries=(("GENERATED_UI_STRUCTURE", ("1",)),), raw=framed)
    return parse_generated_structure(response)


def structure_from_snapshot(snapshot: GeneratedSnapshot) -> GeneratedStructure:
    """The structure section of ONE atomic generated snapshot.

    The snapshot is the existing public read that carries the endpoint identity
    and the structure text in the same provider call.  `parse_generated_structure`
    is reused for the section; version/candidate/scene facts come from the
    snapshot's own cursor, not from a second query.
    """
    text = snapshot.structure_text.strip()
    if not text:
        return GeneratedStructure(snapshot.accepted_structure_version,
                                  snapshot.candidate_token, snapshot.candidate_state, ())
    parsed = _parse_structure_text(text)
    return GeneratedStructure(snapshot.accepted_structure_version,
                              snapshot.candidate_token, snapshot.candidate_state,
                              parsed.nodes, format_version=parsed.format_version,
                              compositions=parsed.compositions,
                              source_text=text, lossless=parsed.lossless)


def instances_from_snapshot(snapshot: GeneratedSnapshot) -> GeneratedInstances:
    """The instance section of the SAME atomic snapshot, parsed without framing.

    The snapshot provider carries bare `INSTANCE ...` lines. This adds only the
    local section framing the typed parser already expects; no second request is
    made, so structure and per-instance owners share one cursor.
    """
    text = snapshot.instances_text.strip()
    if not text:
        return GeneratedInstances(snapshot.accepted_structure_version,
                                  snapshot.candidate_token, snapshot.candidate_state, ())
    lines = text.splitlines()
    if not any(line.startswith("INSTANCE_LENGTH ") for line in lines):
        lines.insert(0, f"INSTANCE_LENGTH {len(text.encode('utf-8'))}")
    if not any(line == "END" for line in lines):
        lines.append("END")
    response = SharedOperationResponse(
        protocol="section", kind="GENERATED_UI_INSTANCES",
        entries=(("GENERATED_UI_INSTANCES", ("1",)),), raw="\n".join(lines))
    parsed = parse_generated_instances(response)
    # The bare instance section carries no cursor of its own. It belongs to the
    # SAME atomic snapshot, so it inherits that snapshot's version/state instead
    # of reporting a fresh v0/none.
    return replace(parsed,
                   structure_version=snapshot.accepted_structure_version,
                   candidate_version=snapshot.candidate_token,
                   scene_state=snapshot.candidate_state)


def instance_facts(instances: GeneratedInstances) -> dict[str, Any]:
    """Read-only A/B facts from the accepted instance section.

    Two different questions are kept apart:

    * `sha256` is the STABLE BINDING digest over instance key, element, role,
      layout id, kind, field/action and owner target. It answers "is this the
      same binding?", so scrolling a card out of view or disabling a control
      does not read as a rebind.
    * `presentation_sha256`, `visible` and `enabled` are the CURRENT
      presentation/availability facts at the same sample. A control that moves
      with layout or is blocked/disappears is reported here, not folded into
      the binding digest.

    `owners` maps an instance key to its single published owner target; a key
    with conflicting owners is reported separately instead of being folded into
    one value.
    """
    owners: dict[str, int] = {}
    conflicts: dict[str, list[int]] = {}
    binding_rows: list[tuple[Any, ...]] = []
    presentation_rows: list[tuple[Any, ...]] = []
    visible: dict[str, bool] = {}
    enabled: dict[str, bool] = {}
    for instance in instances.instances:
        binding_rows.append((instance.key, instance.element_key or "", instance.role or "",
                             instance.node_id, instance.kind, instance.field_id or "",
                             instance.action or "", instance.owner_resource_id))
        presentation_rows.append((instance.key, instance.element_key or "",
                                   instance.node_id, instance.control_enabled,
                                   instance.visible))
        label = f"{instance.key}/{instance.element_key or ''}"
        visible[label] = instance.visible
        enabled[label] = instance.control_enabled
        if instance.owner_resource_id < 0:
            continue
        if instance.key not in owners:
            owners[instance.key] = instance.owner_resource_id
        elif owners[instance.key] != instance.owner_resource_id:
            conflicts.setdefault(instance.key, [owners[instance.key]])
            if instance.owner_resource_id not in conflicts[instance.key]:
                conflicts[instance.key].append(instance.owner_resource_id)
    binding = json.dumps(sorted(binding_rows), ensure_ascii=False, separators=(",", ":"))
    presentation = json.dumps(sorted(presentation_rows), ensure_ascii=False,
                              separators=(",", ":"))
    return {
        "count": len(instances.instances),
        "keys": sorted({instance.key for instance in instances.instances}),
        "owners": dict(sorted(owners.items())),
        "owner_conflicts": dict(sorted(conflicts.items())),
        "sha256": hashlib.sha256(binding.encode("utf-8")).hexdigest(),
        "presentation_sha256": hashlib.sha256(
            presentation.encode("utf-8")).hexdigest(),
        "visible": dict(sorted(visible.items())),
        "enabled": dict(sorted(enabled.items())),
    }


def _exact_document_readback(nodes: Sequence[GeneratedNode],
                             compositions: Sequence[GeneratedRuntimeComposition],
                             structure: GeneratedStructure) -> bool:
    """Whether the accepted snapshot is EXACTLY the expected complete state.

    The submitted candidate may omit definitions (they are retained) or carry
    one replacement; the accepted snapshot must therefore be compared with the
    full expected catalog, not with the candidate delta. Definitions compare by
    name; node order and content compare exactly. Unknown content is never
    accepted as exact.
    """
    if not structure.lossless:
        return False
    if tuple(sorted(map(_canonical_composition, compositions), key=lambda item: item.name)) != \
            tuple(sorted(map(_canonical_composition, structure.compositions),
                         key=lambda item: item.name)):
        return False
    return same_structure(nodes, structure.nodes)


def _exact_node_readback(nodes: Sequence[GeneratedNode],
                         structure: GeneratedStructure) -> bool:
    """Legacy node-only check (no definitions expected)."""
    return _exact_document_readback(nodes, (), structure)

# --- tree model --------------------------------------------------------------

@dataclass(frozen=True)
class EditNode:
    """One structure node, addressed by its stable application key.

    `properties`, `field_id` and `action` are carried verbatim so an edit keeps
    every untouched declaration and binding exactly as the application accepted
    it.  Children are kept in accepted order.
    """

    key: str
    kind: str
    field_id: str | None = None
    action: str | None = None
    properties: tuple[GeneratedProperty, ...] = ()
    children: tuple["EditNode", ...] = ()

    def property(self, name: str) -> str:
        for prop in self.properties:
            if prop.name == name:
                return prop.value
        return ""

    def to_generated_nodes(self, depth: int = 0) -> tuple[GeneratedNode, ...]:
        out: list[GeneratedNode] = []
        _append_generated_nodes(self, depth, out)
        return tuple(out)

    def to_dict(self) -> dict[str, Any]:
        value: dict[str, Any] = {
            "key": self.key,
            "kind": self.kind,
            "properties": {prop.name: prop.value for prop in self.properties},
        }
        if self.field_id:
            value["field"] = self.field_id
        if self.action:
            value["action"] = self.action
        if self.children:
            value["children"] = [child.to_dict() for child in self.children]
        return value


def _append_generated_nodes(node: EditNode, depth: int, out: list[GeneratedNode]) -> None:
    out.append(GeneratedNode(depth, node.key, node.kind, node.field_id, node.action,
                             node.properties))
    for child in node.children:
        _append_generated_nodes(child, depth + 1, out)


def generated_nodes_of(root: EditNode) -> tuple[GeneratedNode, ...]:
    """Flatten a tree to the exact pre-order depth list the protocol carries."""
    return root.to_generated_nodes()


def structure_tree(structure: GeneratedStructure) -> EditNode:
    return tree_from_nodes(structure.nodes)


def tree_from_nodes(nodes: Sequence[GeneratedNode]) -> EditNode:
    """Build the key-addressed tree from an accepted flat depth list.

    The flat protocol admits one root, requires every parent level to exist and
    forbids duplicate keys.  Those are checked here instead of being inferred
    from array positions: a malformed description must not produce an editable
    tree whose keys silently point at another node.
    """
    if not nodes:
        raise GeneratedEditError("malformed_structure", "structure declares no nodes")
    for node in nodes:
        if not IDENTIFIER.fullmatch(node.key) or not IDENTIFIER.fullmatch(node.kind):
            raise GeneratedEditError(
                "malformed_structure",
                f"node key/kind is not a protocol identifier: {node.key!r}/{node.kind!r}")
        if node.depth < 0:
            raise GeneratedEditError("malformed_structure", f"negative depth on {node.key}")
    if nodes[0].depth != 0:
        raise GeneratedEditError("malformed_structure", "structure does not start at depth 0")

    def build(position: int, depth: int) -> tuple[EditNode, int]:
        node = nodes[position]
        if node.depth != depth:
            raise GeneratedEditError(
                "malformed_structure",
                f"node {node.key!r} is at depth {node.depth}; expected {depth}")
        children: list[EditNode] = []
        cursor = position + 1
        while cursor < len(nodes) and nodes[cursor].depth > depth:
            if nodes[cursor].depth != depth + 1:
                raise GeneratedEditError(
                    "malformed_structure", f"skipped depth level below {node.key!r}")
            child, cursor = build(cursor, depth + 1)
            children.append(child)
        return EditNode(node.key, node.kind, node.field_id, node.action, node.properties,
                        tuple(children)), cursor

    root, consumed = build(0, 0)
    if consumed != len(nodes):
        raise GeneratedEditError(
            "malformed_structure",
            f"structure has trailing nodes after the root subtree (position {consumed})")
    seen: set[str] = set()
    for node in generated_nodes_of(root):
        if node.key in seen:
            raise GeneratedEditError("malformed_structure", f"duplicate node key {node.key}")
        seen.add(node.key)
    return root


# --- edit plan ---------------------------------------------------------------

@dataclass(frozen=True)
class SetProperty:
    key: str
    name: str
    value: str


@dataclass(frozen=True)
class RemoveProperty:
    key: str
    name: str


@dataclass(frozen=True)
class InsertNode:
    parent: str
    index: int
    node: EditNode


@dataclass(frozen=True)
class DeleteNode:
    key: str


@dataclass(frozen=True)
class MoveNode:
    key: str
    parent: str
    index: int


class _Unchanged:
    def __repr__(self) -> str:
        return "UNCHANGED"


UNCHANGED = _Unchanged()


@dataclass(frozen=True)
class SetDeclaration:
    """Change a node's kind/field/action while keeping everything else.

    `UNCHANGED` (the default) leaves a declaration as accepted; an explicit
    `None` clears a field/action binding.  Properties and children are preserved
    verbatim; the catalog preflight runs over the resulting node.
    """

    key: str
    kind: str | None | _Unchanged = UNCHANGED
    field: str | None | _Unchanged = UNCHANGED
    action: str | None | _Unchanged = UNCHANGED


EditOperation = (SetProperty | RemoveProperty | InsertNode | DeleteNode | MoveNode |
                 SetDeclaration)


@dataclass(frozen=True)
class SetComposition:
    """Add or replace ONE runtime composition definition by its stable name."""

    composition: GeneratedRuntimeComposition


@dataclass(frozen=True)
class RemoveComposition:
    """The explicit `COMPOSITION_REMOVE <name>` deletion for this candidate."""

    name: str


@dataclass(frozen=True)
class SetCompositionLimits:
    composition: str
    expanded_node_limit: int | None = None
    expanded_depth_limit: int | None = None


@dataclass(frozen=True)
class SetCompositionParameter:
    composition: str
    name: str
    value_type: str | None = None
    required: bool | None = None
    minimum: int | None = None
    maximum: int | None = None
    max_length: int | None = None
    default: str | None = None


@dataclass(frozen=True)
class SetCompositionElement:
    composition: str
    key: str
    role: str | None = None
    field: str | None = None
    argument: str | None = None
    action: str | None = None
    source: str | None = None
    preset: str | None = None
    label: str | None = None


@dataclass(frozen=True)
class SetCompositionTemplate:
    composition: str
    key: str
    kind: str | None = None
    element: str | None = None
    presentation: str | None = None
    text: str | None = None
    style: str | None = None
    gap: int | None = None
    padding: int | None = None
    height: int | None = None
    grow: int | None = None
    axis: str | None = None
    first: int | None = None
    minfirst: int | None = None
    minsecond: int | None = None


@dataclass(frozen=True)
class GeneratedEditPlan:
    """A local batch against ONE accepted structure version."""

    base_version: int
    operations: tuple[EditOperation, ...]

    def describe(self) -> tuple[str, ...]:
        return tuple(_describe_operation(index, op)
                     for index, op in enumerate(self.operations))

    def to_dict(self) -> dict[str, Any]:
        return {
            "base_version": self.base_version,
            "operations": [_operation_dict(operation, index)
                           for index, operation in enumerate(self.operations)],
        }


def _wire_scalar(value: Any, what: str, *, operation_index: int | None = None) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        return value
    raise GeneratedEditError(
        "invalid_plan", f"{what} must be a string, integer or boolean",
        operation_index=operation_index)


def _strict_int(value: Any, what: str, *, operation_index: int | None = None) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise GeneratedEditError("invalid_plan", f"{what} must be an integer",
                                 operation_index=operation_index)
    return value


def _require_str(value: Any, what: str, *, operation_index: int | None = None) -> str:
    if not isinstance(value, str) or not value:
        raise GeneratedEditError("invalid_plan", f"{what} must be a non-empty string",
                                 operation_index=operation_index)
    return value


def _strict_keys(value: Mapping[str, Any], allowed: set[str], what: str,
                 *, operation_index: int | None = None) -> None:
    unknown = sorted(set(value) - allowed)
    if unknown:
        raise GeneratedEditError("invalid_plan", f"{what} has unknown field(s): {', '.join(unknown)}",
                                 operation_index=operation_index)


def _require_keys(value: Mapping[str, Any], required: set[str], what: str,
                  *, operation_index: int | None = None) -> None:
    missing = sorted(required - set(value))
    if missing:
        raise GeneratedEditError("invalid_plan", f"{what} is missing: {', '.join(missing)}",
                                 operation_index=operation_index)


def edit_node_from_dict(value: Mapping[str, Any], *, operation_index: int | None = None) -> EditNode:
    if not isinstance(value, Mapping):
        raise GeneratedEditError("invalid_plan", "node must be an object",
                                 operation_index=operation_index)
    _strict_keys(value, {"key", "kind", "field", "action", "properties", "children"},
                 "node", operation_index=operation_index)
    _require_keys(value, {"key", "kind"}, "node", operation_index=operation_index)
    key = _require_str(value.get("key"), "node.key", operation_index=operation_index)
    kind = _require_str(value.get("kind"), "node.kind", operation_index=operation_index)
    if not IDENTIFIER.fullmatch(key):
        raise GeneratedEditError("invalid_plan", f"node.key is not a protocol identifier: {key!r}",
                                 operation_index=operation_index)
    if not IDENTIFIER.fullmatch(kind):
        raise GeneratedEditError("invalid_plan", f"node.kind is not a protocol identifier: {kind!r}",
                                 operation_index=operation_index)
    field = value.get("field")
    action = value.get("action")
    if field is not None and not isinstance(field, str):
        raise GeneratedEditError("invalid_plan", "node.field must be a string or null",
                                 operation_index=operation_index)
    if action is not None and not isinstance(action, str):
        raise GeneratedEditError("invalid_plan", "node.action must be a string or null",
                                 operation_index=operation_index)
    raw_properties = value.get("properties", {})
    if not isinstance(raw_properties, Mapping):
        raise GeneratedEditError("invalid_plan", "node.properties must be an object",
                                 operation_index=operation_index)
    properties: list[GeneratedProperty] = []
    for name, raw in raw_properties.items():
        if not isinstance(name, str) or not name:
            raise GeneratedEditError("invalid_plan", "property name must be a non-empty string",
                                     operation_index=operation_index)
        properties.append(GeneratedProperty(
            name, _wire_scalar(raw, f"node.properties.{name}", operation_index=operation_index)))
    raw_children = value.get("children", [])
    if not isinstance(raw_children, list):
        raise GeneratedEditError("invalid_plan", "node.children must be an array",
                                 operation_index=operation_index)
    children = tuple(edit_node_from_dict(child, operation_index=operation_index)
                     for child in raw_children)
    return EditNode(key, kind, field or None, action or None, tuple(properties), children)


_COMPOSITION_TYPES = frozenset({"STRING", "INTEGER", "BOOLEAN"})
_COMPOSITION_ROLES = frozenset({"field", "action", "preset", "projection"})
_COMPOSITION_KINDS = frozenset({
    "vertical", "horizontal", "wrap", "label", "spacer", "split", "element", "children",
})
_COMPOSITION_PRESENTATIONS = frozenset({"text", "select", "radio", "segmented"})
_COMPOSITION_MAX_PARAMETERS = 8
_COMPOSITION_MAX_ELEMENTS = 24
_COMPOSITION_MAX_TEMPLATE_NODES = 64
_COMPOSITION_MAX_TEMPLATE_DEPTH = 8


def _single_token(raw: Any, what: str, index: int) -> str:
    if not isinstance(raw, str) or not raw:
        raise GeneratedEditError("invalid_plan", f"{what} must be a non-empty string",
                                 operation_index=index)
    if any(character.isspace() or ord(character) < 0x20 or ord(character) == 0x7F
           for character in raw):
        raise GeneratedEditError(
            "composition_token_not_single", f"{what} cannot carry spaces/control characters",
            operation_index=index)
    return raw


def _trailing_text(raw: Any, what: str, index: int) -> str:
    if not isinstance(raw, str):
        raise GeneratedEditError("invalid_plan", f"{what} must be a string",
                                 operation_index=index)
    if "\n" in raw or "\r" in raw or "\0" in raw:
        raise GeneratedEditError("composition_trailing_value_invalid", what,
                                 operation_index=index)
    return raw


def _composition_template_from_dict(value: Any, index: int) -> GeneratedCompositionTemplateNode:
    if not isinstance(value, Mapping):
        raise GeneratedEditError("invalid_plan", "composition.template must be an object",
                                 operation_index=index)
    _strict_keys(value, {"depth", "key", "kind", "element", "presentation", "text",
                         "style", "gap", "padding", "height", "grow", "axis", "first",
                         "minfirst", "minsecond", "children"}, "composition.template",
                 operation_index=index)
    _require_keys(value, {"depth", "key", "kind"}, "composition.template",
                  operation_index=index)
    depth = _strict_int(value["depth"], "composition.template.depth", operation_index=index)
    key = _single_token(value["key"], "composition.template.key", index)
    kind = _single_token(value["kind"], "composition.template.kind", index)
    if kind not in _COMPOSITION_KINDS:
        raise GeneratedEditError("invalid_plan",
                                 f"composition template kind {kind!r} is not supported",
                                 operation_index=index, key=key)
    children = value.get("children", [])
    if not isinstance(children, list):
        raise GeneratedEditError("invalid_plan", "composition.template.children must be an array",
                                 operation_index=index)
    return GeneratedCompositionTemplateNode(
        depth, key, kind,
        _single_token(value.get("element", ""), "composition.template.element", index)
        if value.get("element", "") else "",
        "",
        _single_token(value.get("presentation", ""), "composition.template.presentation", index)
        if value.get("presentation", "") else "",
        _trailing_text(value.get("text", ""), "composition.template.text", index),
        _single_token(value.get("style", ""), "composition.template.style", index)
        if value.get("style", "") else "",
        _strict_int(value.get("gap", -1), "composition.template.gap", operation_index=index),
        _strict_int(value.get("padding", -1), "composition.template.padding",
                    operation_index=index),
        _strict_int(value.get("height", -1), "composition.template.height",
                    operation_index=index),
        _strict_int(value.get("grow", -1), "composition.template.grow", operation_index=index),
        _single_token(value.get("axis", ""), "composition.template.axis", index)
        if value.get("axis", "") else "",
        _strict_int(value.get("first", 240), "composition.template.first",
                    operation_index=index),
        _strict_int(value.get("minfirst", 120), "composition.template.minfirst",
                    operation_index=index),
        _strict_int(value.get("minsecond", 120), "composition.template.minsecond",
                    operation_index=index),
        tuple(_composition_template_from_dict(child, index) for child in children))


def _composition_from_dict(value: Any, index: int) -> GeneratedRuntimeComposition:
    if not isinstance(value, Mapping):
        raise GeneratedEditError("invalid_plan", "composition must be an object",
                                 operation_index=index)
    _strict_keys(value, {"name", "expanded_node_limit", "expanded_depth_limit",
                         "parameters", "elements", "template"}, "composition",
                 operation_index=index)
    _require_keys(value, {"name", "expanded_node_limit", "expanded_depth_limit",
                          "parameters", "elements", "template"}, "composition",
                  operation_index=index)
    name = _single_token(value["name"], "composition.name", index)
    if not IDENTIFIER.fullmatch(name):
        raise GeneratedEditError("invalid_plan",
                                 f"composition name {name!r} is not a protocol identifier",
                                 operation_index=index)
    raw_parameters = value["parameters"]
    raw_elements = value["elements"]
    if not isinstance(raw_parameters, list) or not isinstance(raw_elements, list):
        raise GeneratedEditError("invalid_plan",
                                 "composition.parameters/elements must be arrays",
                                 operation_index=index)
    parameters: list[GeneratedCompositionParameter] = []
    for item in raw_parameters:
        if not isinstance(item, Mapping):
            raise GeneratedEditError("invalid_plan", "composition parameter must be an object",
                                     operation_index=index)
        _strict_keys(item, {"name", "type", "required", "min", "max", "max_length",
                            "default"}, "composition parameter", operation_index=index)
        _require_keys(item, {"name", "type", "required", "min", "max", "max_length",
                             "default"}, "composition parameter", operation_index=index)
        required = item["required"]
        if not isinstance(required, bool):
            raise GeneratedEditError("invalid_plan", "parameter.required must be boolean",
                                     operation_index=index)
        parameters.append(GeneratedCompositionParameter(
            _single_token(item["name"], "composition parameter name", index),
            _single_token(item["type"], "composition parameter type", index),
            required,
            _strict_int(item["min"], "composition parameter min", operation_index=index),
            _strict_int(item["max"], "composition parameter max", operation_index=index),
            _strict_int(item["max_length"], "composition parameter max_length",
                        operation_index=index),
            _single_token(item["default"], "composition parameter default", index)
            if item["default"] else ""))
    elements: list[GeneratedCompositionElement] = []
    for item in raw_elements:
        if not isinstance(item, Mapping):
            raise GeneratedEditError("invalid_plan", "composition element must be an object",
                                     operation_index=index)
        _strict_keys(item, {"key", "role", "field", "argument", "action", "source",
                            "preset", "label"}, "composition element",
                     operation_index=index)
        _require_keys(item, {"key", "role"}, "composition element", operation_index=index)
        elements.append(GeneratedCompositionElement(
            _single_token(item["key"], "composition element key", index),
            _single_token(item["role"], "composition element role", index),
            _single_token(item.get("field", ""), "composition element field", index)
            if item.get("field", "") else "",
            _single_token(item.get("argument", ""), "composition element argument", index)
            if item.get("argument", "") else "",
            _single_token(item.get("action", ""), "composition element action", index)
            if item.get("action", "") else "",
            _single_token(item.get("source", ""), "composition element source", index)
            if item.get("source", "") else "",
            _single_token(item.get("preset", ""), "composition element preset", index)
            if item.get("preset", "") else "",
            _trailing_text(item.get("label", ""), "composition element label", index)))
    return GeneratedRuntimeComposition(
        name,
        _strict_int(value["expanded_node_limit"], "composition.expanded_node_limit",
                    operation_index=index),
        _strict_int(value["expanded_depth_limit"], "composition.expanded_depth_limit",
                    operation_index=index),
        tuple(parameters), tuple(elements),
        _composition_template_from_dict(value["template"], index))


def _operation_from_dict(value: Mapping[str, Any], index: int) -> EditOperation:
    if not isinstance(value, Mapping):
        raise GeneratedEditError("invalid_plan", "operation must be an object",
                                 operation_index=index)
    op = value.get("op")
    if not isinstance(op, str):
        raise GeneratedEditError("invalid_plan", "operation.op must be a string",
                                 operation_index=index)
    if op == "set_property":
        _strict_keys(value, {"op", "key", "name", "value"}, "set_property", operation_index=index)
        _require_keys(value, {"op", "key", "name", "value"}, "set_property", operation_index=index)
        return SetProperty(_require_str(value["key"], "key", operation_index=index),
                           _require_str(value["name"], "name", operation_index=index),
                           _wire_scalar(value["value"], "value", operation_index=index))
    if op == "remove_property":
        _strict_keys(value, {"op", "key", "name"}, "remove_property", operation_index=index)
        _require_keys(value, {"op", "key", "name"}, "remove_property", operation_index=index)
        return RemoveProperty(_require_str(value["key"], "key", operation_index=index),
                              _require_str(value["name"], "name", operation_index=index))
    if op == "insert":
        _strict_keys(value, {"op", "parent", "index", "node"}, "insert", operation_index=index)
        _require_keys(value, {"op", "parent", "index", "node"}, "insert", operation_index=index)
        return InsertNode(_require_str(value["parent"], "parent", operation_index=index),
                          _strict_int(value["index"], "index", operation_index=index),
                          edit_node_from_dict(value["node"], operation_index=index))
    if op == "delete":
        _strict_keys(value, {"op", "key"}, "delete", operation_index=index)
        _require_keys(value, {"op", "key"}, "delete", operation_index=index)
        return DeleteNode(_require_str(value["key"], "key", operation_index=index))
    if op == "move":
        _strict_keys(value, {"op", "key", "parent", "index"}, "move", operation_index=index)
        _require_keys(value, {"op", "key", "parent", "index"}, "move", operation_index=index)
        return MoveNode(_require_str(value["key"], "key", operation_index=index),
                        _require_str(value["parent"], "parent", operation_index=index),
                        _strict_int(value["index"], "index", operation_index=index))
    if op == "set_declaration":
        _strict_keys(value, {"op", "key", "kind", "field", "action"},
                     "set_declaration", operation_index=index)
        _require_keys(value, {"op", "key"}, "set_declaration", operation_index=index)
        if not any(name in value for name in ("kind", "field", "action")):
            raise GeneratedEditError(
                "invalid_plan", "set_declaration must change kind, field or action",
                operation_index=index)
        kind = _require_str(value["kind"], "kind", operation_index=index) \
            if "kind" in value else UNCHANGED
        field = value.get("field", UNCHANGED)
        if field is not UNCHANGED:
            if field is not None and (not isinstance(field, str) or not field):
                raise GeneratedEditError(
                    "invalid_plan", "field must be a non-empty string or null",
                    operation_index=index)
        action = value.get("action", UNCHANGED)
        if action is not UNCHANGED:
            if action is not None and (not isinstance(action, str) or not action):
                raise GeneratedEditError(
                    "invalid_plan", "action must be a non-empty string or null",
                    operation_index=index)
        return SetDeclaration(_require_str(value["key"], "key", operation_index=index),
                              kind, field, action)
    if op == "set_composition":
        _strict_keys(value, {"op", "composition"}, "set_composition", operation_index=index)
        _require_keys(value, {"op", "composition"}, "set_composition", operation_index=index)
        return SetComposition(_composition_from_dict(value["composition"], index))
    if op == "remove_composition":
        _strict_keys(value, {"op", "name"}, "remove_composition", operation_index=index)
        _require_keys(value, {"op", "name"}, "remove_composition", operation_index=index)
        return RemoveComposition(_require_str(value["name"], "name", operation_index=index))
    if op == "set_composition_limits":
        _strict_keys(value, {"op", "composition", "expanded_node_limit",
                             "expanded_depth_limit"}, "set_composition_limits",
                     operation_index=index)
        _require_keys(value, {"op", "composition"}, "set_composition_limits",
                      operation_index=index)
        if "expanded_node_limit" not in value and "expanded_depth_limit" not in value:
            raise GeneratedEditError(
                "invalid_plan", "set_composition_limits must change at least one limit",
                operation_index=index)
        return SetCompositionLimits(
            _require_str(value["composition"], "composition", operation_index=index),
            _strict_int(value["expanded_node_limit"], "expanded_node_limit",
                        operation_index=index)
            if "expanded_node_limit" in value else None,
            _strict_int(value["expanded_depth_limit"], "expanded_depth_limit",
                        operation_index=index)
            if "expanded_depth_limit" in value else None)
    if op == "set_composition_parameter":
        allowed = {"op", "composition", "name", "type", "required", "min", "max",
                   "max_length", "default"}
        _strict_keys(value, allowed, "set_composition_parameter", operation_index=index)
        _require_keys(value, {"op", "composition", "name"}, "set_composition_parameter",
                      operation_index=index)
        if not any(key in value for key in allowed - {"op", "composition", "name"}):
            raise GeneratedEditError(
                "invalid_plan", "set_composition_parameter must change a field",
                operation_index=index)
        required = value.get("required")
        if required is not None and not isinstance(required, bool):
            raise GeneratedEditError("invalid_plan", "required must be boolean",
                                     operation_index=index)
        default = value.get("default")
        if default is not None:
            default = _trailing_text(default, "default", index)
            if default and any(character.isspace() or ord(character) < 0x20
                               for character in default):
                raise GeneratedEditError(
                    "composition_token_not_single", "default cannot carry spaces",
                    operation_index=index)
        return SetCompositionParameter(
            _require_str(value["composition"], "composition", operation_index=index),
            _require_str(value["name"], "name", operation_index=index),
            _single_token(value["type"], "type", index) if "type" in value else None,
            required,
            _strict_int(value["min"], "min", operation_index=index) if "min" in value else None,
            _strict_int(value["max"], "max", operation_index=index) if "max" in value else None,
            _strict_int(value["max_length"], "max_length", operation_index=index)
            if "max_length" in value else None,
            default)
    if op == "set_composition_element":
        allowed = {"op", "composition", "key", "role", "field", "argument", "action",
                   "source", "preset", "label"}
        _strict_keys(value, allowed, "set_composition_element", operation_index=index)
        _require_keys(value, {"op", "composition", "key"}, "set_composition_element",
                      operation_index=index)
        if not any(key in value for key in allowed - {"op", "composition", "key"}):
            raise GeneratedEditError(
                "invalid_plan", "set_composition_element must change a field",
                operation_index=index)
        optional: dict[str, str | None] = {}
        for name in ("role", "field", "argument", "action", "source", "preset"):
            if name not in value:
                optional[name] = None
            elif value[name] == "":
                optional[name] = ""
            else:
                optional[name] = _single_token(value[name], name, index)
        label = None
        if "label" in value:
            label = _trailing_text(value["label"], "label", index)
        return SetCompositionElement(
            _require_str(value["composition"], "composition", operation_index=index),
            _require_str(value["key"], "key", operation_index=index),
            optional["role"], optional["field"], optional["argument"], optional["action"],
            optional["source"], optional["preset"], label)
    if op == "set_composition_template":
        allowed = {"op", "composition", "key", "kind", "element", "presentation", "text",
                   "style", "gap", "padding", "height", "grow", "axis", "first",
                   "minfirst", "minsecond"}
        _strict_keys(value, allowed, "set_composition_template", operation_index=index)
        _require_keys(value, {"op", "composition", "key"}, "set_composition_template",
                      operation_index=index)
        if not any(key in value for key in allowed - {"op", "composition", "key"}):
            raise GeneratedEditError(
                "invalid_plan", "set_composition_template must change a field",
                operation_index=index)
        strings: dict[str, str | None] = {}
        for name in ("kind", "element", "presentation", "style", "axis"):
            if name not in value:
                strings[name] = None
            elif value[name] == "":
                strings[name] = ""
            else:
                strings[name] = _single_token(value[name], name, index)
        text = None
        if "text" in value:
            text = _trailing_text(value["text"], "text", index)
        numbers: dict[str, int | None] = {}
        for name in ("gap", "padding", "height", "grow", "first", "minfirst", "minsecond"):
            numbers[name] = _strict_int(value[name], name, operation_index=index) \
                if name in value else None
        return SetCompositionTemplate(
            _require_str(value["composition"], "composition", operation_index=index),
            _require_str(value["key"], "key", operation_index=index),
            strings["kind"], strings["element"], strings["presentation"], text,
            strings["style"], numbers["gap"], numbers["padding"], numbers["height"],
            numbers["grow"], strings["axis"], numbers["first"], numbers["minfirst"],
            numbers["minsecond"])
    raise GeneratedEditError("invalid_plan", f"unknown operation {op!r}", operation_index=index)


def edit_plan_from_dict(value: Mapping[str, Any]) -> GeneratedEditPlan:
    if not isinstance(value, Mapping):
        raise GeneratedEditError("invalid_plan", "plan must be an object")
    _strict_keys(value, {"base_version", "operations"}, "plan")
    _require_keys(value, {"base_version", "operations"}, "plan")
    base_version = _strict_int(value["base_version"], "base_version")
    if base_version < 0:
        raise GeneratedEditError("invalid_plan", "base_version cannot be negative")
    raw_operations = value["operations"]
    if not isinstance(raw_operations, list) or not raw_operations:
        raise GeneratedEditError("invalid_plan", "operations must be a non-empty array")
    return GeneratedEditPlan(base_version,
                             tuple(_operation_from_dict(op, index)
                                   for index, op in enumerate(raw_operations)))


def edit_plan_from_text(text: str) -> GeneratedEditPlan:
    try:
        value = json.loads(text)
    except json.JSONDecodeError as error:
        raise GeneratedEditError("invalid_plan", f"plan is not valid JSON: {error}") from error
    return edit_plan_from_dict(value)


# --- local application -------------------------------------------------------

class _MutableNode:
    __slots__ = ("key", "kind", "field_id", "action", "properties", "children")

    def __init__(self, key: str, kind: str, field_id: str | None, action: str | None,
                 properties: list[GeneratedProperty], children: list["_MutableNode"]) -> None:
        self.key = key
        self.kind = kind
        self.field_id = field_id
        self.action = action
        self.properties = properties
        self.children = children


def _mutable(node: EditNode) -> _MutableNode:
    return _MutableNode(node.key, node.kind, node.field_id, node.action,
                        list(node.properties), [_mutable(child) for child in node.children])


def _immutable(node: _MutableNode) -> EditNode:
    return EditNode(node.key, node.kind, node.field_id, node.action, tuple(node.properties),
                    tuple(_immutable(child) for child in node.children))


# --- composition model -------------------------------------------------------

def _composition_token(value: str, what: str, index: int) -> str:
    return _single_token(value, what, index)


def _validate_composition_model(composition: GeneratedRuntimeComposition, index: int) -> None:
    name = _composition_token(composition.name, "composition name", index)
    if not IDENTIFIER.fullmatch(name):
        raise GeneratedEditError("invalid_plan",
                                 f"composition name {name!r} is not a protocol identifier",
                                 operation_index=index)
    if composition.expanded_node_limit <= 0 or composition.expanded_depth_limit <= 0:
        raise GeneratedEditError("invalid_plan", "composition limits must be positive",
                                 operation_index=index)
    if not composition.elements:
        raise GeneratedEditError("invalid_plan", "composition has no elements",
                                 operation_index=index)
    if len(composition.parameters) > _COMPOSITION_MAX_PARAMETERS:
        raise GeneratedEditError("composition_parameter_budget", "parameter budget exceeded",
                                 operation_index=index)
    if len(composition.elements) > _COMPOSITION_MAX_ELEMENTS:
        raise GeneratedEditError("composition_element_budget", "element budget exceeded",
                                 operation_index=index)
    parameter_names: set[str] = set()
    for parameter in composition.parameters:
        _composition_token(parameter.name, "composition parameter name", index)
        if parameter.name in parameter_names:
            raise GeneratedEditError("composition_duplicate_parameter", parameter.name,
                                     operation_index=index)
        parameter_names.add(parameter.name)
        if parameter.value_type not in _COMPOSITION_TYPES:
            raise GeneratedEditError("invalid_plan",
                                     f"parameter type {parameter.value_type!r} is not supported",
                                     operation_index=index)
        if parameter.minimum < 0 or parameter.maximum < parameter.minimum or \
                parameter.max_length <= 0:
            raise GeneratedEditError("invalid_plan", "parameter bounds are malformed",
                                     operation_index=index)
        if parameter.default:
            _composition_token(parameter.default, "parameter default", index)
    element_keys: set[str] = set()
    for element in composition.elements:
        _composition_token(element.key, "composition element key", index)
        if element.key in element_keys:
            raise GeneratedEditError("composition_duplicate_element", element.key,
                                     operation_index=index)
        element_keys.add(element.key)
        if element.role not in _COMPOSITION_ROLES:
            raise GeneratedEditError("invalid_plan",
                                     f"element role {element.role!r} is not supported",
                                     operation_index=index)
        for value, what in ((element.field_id, "element field"),
                            (element.argument, "element argument"),
                            (element.action, "element action"),
                            (element.source, "element source"),
                            (element.preset, "element preset")):
            if value:
                _composition_token(value, what, index)
        if "\n" in element.label or "\r" in element.label or "\0" in element.label:
            raise GeneratedEditError("invalid_plan", "element label cannot carry newlines",
                                     operation_index=index)
    template_keys: set[str] = set()
    count = 0

    def walk(node: GeneratedCompositionTemplateNode, depth: int) -> None:
        nonlocal count
        count += 1
        if count > _COMPOSITION_MAX_TEMPLATE_NODES or \
                count > composition.expanded_node_limit:
            raise GeneratedEditError("composition_template_budget",
                                     "template node budget exceeded", operation_index=index)
        if depth > _COMPOSITION_MAX_TEMPLATE_DEPTH or node.depth != depth:
            raise GeneratedEditError("invalid_plan", "template depth is malformed",
                                     operation_index=index)
        _composition_token(node.key, "template key", index)
        if node.key in template_keys:
            raise GeneratedEditError("composition_duplicate_template", node.key,
                                     operation_index=index)
        template_keys.add(node.key)
        if node.kind not in _COMPOSITION_KINDS:
            raise GeneratedEditError("invalid_plan",
                                     f"template kind {node.kind!r} is not supported",
                                     operation_index=index)
        if node.presentation and node.presentation not in _COMPOSITION_PRESENTATIONS:
            raise GeneratedEditError("invalid_plan",
                                     f"presentation {node.presentation!r} is not supported",
                                     operation_index=index)
        if node.kind == "split" and len(node.children) != 2:
            raise GeneratedEditError("composition_split_children", node.key,
                                     operation_index=index)
        if node.kind in ("label", "spacer", "element") and node.children:
            raise GeneratedEditError("composition_leaf_children", node.key,
                                     operation_index=index)
        if node.kind == "element":
            if not node.element_key:
                raise GeneratedEditError("composition_element_missing", node.key,
                                         operation_index=index)
            if node.element_key not in element_keys:
                raise GeneratedEditError("composition_unknown_element", node.element_key,
                                         operation_index=index)
            if node.presentation == "select" and \
                    next(item.role for item in composition.elements
                         if item.key == node.element_key) != "field":
                raise GeneratedEditError("composition_select_needs_field",
                                         node.element_key, operation_index=index)
        for child in node.children:
            walk(child, depth + 1)

    walk(composition.template, 0)


def _find_template(root: GeneratedCompositionTemplateNode,
                   key: str) -> GeneratedCompositionTemplateNode | None:
    if root.key == key:
        return root
    for child in root.children:
        found = _find_template(child, key)
        if found is not None:
            return found
    return None


def _replace_template(root: GeneratedCompositionTemplateNode, key: str,
                      replacement: GeneratedCompositionTemplateNode) \
        -> GeneratedCompositionTemplateNode:
    if root.key == key:
        return replacement
    return replace(root, children=tuple(
        _replace_template(child, key, replacement) for child in root.children))


def _apply_composition_operation(
        current: dict[str, GeneratedRuntimeComposition], order: list[str],
        removals: list[str], operation: EditOperation, index: int) -> None:
    if isinstance(operation, SetComposition):
        composition = operation.composition
        _validate_composition_model(composition, index)
        if composition.name not in current:
            order.append(composition.name)
        current[composition.name] = composition
        return
    if isinstance(operation, RemoveComposition):
        name = _composition_token(operation.name, "composition removal name", index)
        if name not in current:
            raise GeneratedEditError("composition_remove_unknown", name,
                                     operation_index=index, key=name)
        if name in removals:
            raise GeneratedEditError("composition_remove_duplicate", name,
                                     operation_index=index, key=name)
        removals.append(name)
        return
    name = _composition_token(operation.composition, "composition name", index)
    composition = current.get(name)
    if composition is None:
        raise GeneratedEditError("composition_unknown", name,
                                 operation_index=index, key=name)
    if isinstance(operation, SetCompositionLimits):
        node_limit = composition.expanded_node_limit if operation.expanded_node_limit is None \
            else operation.expanded_node_limit
        depth_limit = composition.expanded_depth_limit \
            if operation.expanded_depth_limit is None else operation.expanded_depth_limit
        if node_limit <= 0 or depth_limit <= 0:
            raise GeneratedEditError("invalid_plan", "composition limits must be positive",
                                     operation_index=index)
        current[name] = replace(composition, expanded_node_limit=node_limit,
                                expanded_depth_limit=depth_limit)
        return
    if isinstance(operation, SetCompositionParameter):
        parameters = list(composition.parameters)
        found = next((position for position, item in enumerate(parameters)
                      if item.name == operation.name), None)
        if found is None:
            raise GeneratedEditError("composition_unknown_parameter", operation.name,
                                     operation_index=index, key=operation.name)
        old = parameters[found]
        value_type = old.value_type if operation.value_type is None else operation.value_type
        required = old.required if operation.required is None else operation.required
        minimum = old.minimum if operation.minimum is None else operation.minimum
        maximum = old.maximum if operation.maximum is None else operation.maximum
        max_length = old.max_length if operation.max_length is None else operation.max_length
        default = old.default if operation.default is None else operation.default
        parameters[found] = GeneratedCompositionParameter(
            old.name, value_type, required, minimum, maximum, max_length, default)
        current[name] = replace(composition, parameters=tuple(parameters))
        _validate_composition_model(current[name], index)
        return
    if isinstance(operation, SetCompositionElement):
        elements = list(composition.elements)
        found = next((position for position, item in enumerate(elements)
                      if item.key == operation.key), None)
        if found is None:
            raise GeneratedEditError("composition_unknown_element_key", operation.key,
                                     operation_index=index, key=operation.key)
        old = elements[found]
        role = old.role if operation.role is None else operation.role
        if role not in _COMPOSITION_ROLES:
            raise GeneratedEditError("invalid_plan",
                                     f"element role {role!r} is not supported",
                                     operation_index=index)
        elements[found] = GeneratedCompositionElement(
            old.key, role,
            old.field_id if operation.field is None else operation.field,
            old.argument if operation.argument is None else operation.argument,
            old.action if operation.action is None else operation.action,
            old.source if operation.source is None else operation.source,
            old.preset if operation.preset is None else operation.preset,
            old.label if operation.label is None else operation.label)
        current[name] = replace(composition, elements=tuple(elements))
        _validate_composition_model(current[name], index)
        return
    if isinstance(operation, SetCompositionTemplate):
        found = _find_template(composition.template, operation.key)
        if found is None:
            raise GeneratedEditError("composition_unknown_template", operation.key,
                                     operation_index=index, key=operation.key)
        numbers = {}
        for field in ("gap", "padding", "height", "grow", "first", "minfirst",
                      "minsecond"):
            numbers[field] = getattr(found, {
                "height": "fixed_height", "first": "first_size",
                "minfirst": "min_first", "minsecond": "min_second"}.get(field, field))
        for field in ("gap", "padding", "height", "grow", "first", "minfirst",
                      "minsecond"):
            supplied = getattr(operation, field)
            if supplied is not None:
                numbers[field] = supplied
        if numbers["gap"] < -1 or numbers["padding"] < -1 or numbers["height"] < -1 or \
                numbers["grow"] < -1 or numbers["first"] < 0 or \
                numbers["minfirst"] < 0 or numbers["minsecond"] < 0:
            raise GeneratedEditError("invalid_plan", "template geometry is out of range",
                                     operation_index=index)
        kind = found.kind if operation.kind is None else operation.kind
        if kind not in _COMPOSITION_KINDS:
            raise GeneratedEditError("invalid_plan",
                                     f"template kind {kind!r} is not supported",
                                     operation_index=index)
        replacement = GeneratedCompositionTemplateNode(
            found.depth, found.key, kind,
            found.element_key if operation.element is None else operation.element,
            found.compose_name if operation.kind is None else
                (found.compose_name if kind == "composition" else ""),
            found.presentation if operation.presentation is None else operation.presentation,
            found.text if operation.text is None else operation.text,
            found.style_name if operation.style is None else operation.style,
            numbers["gap"], numbers["padding"], numbers["height"], numbers["grow"],
            found.axis if operation.axis is None else operation.axis,
            numbers["first"], numbers["minfirst"], numbers["minsecond"],
            found.children)
        current[name] = replace(composition, template=_replace_template(
            composition.template, operation.key, replacement))
        _validate_composition_model(current[name], index)
        return
    raise GeneratedEditError("invalid_plan", "operation is not a composition change",
                             operation_index=index)


def _composition_operations(operations: Sequence[EditOperation]) -> bool:
    return any(isinstance(operation, (SetComposition, RemoveComposition,
                                      SetCompositionLimits, SetCompositionParameter,
                                      SetCompositionElement, SetCompositionTemplate))
               for operation in operations)


def _expected_compositions(baseline: Sequence[GeneratedRuntimeComposition],
                           plan_operations: Sequence[EditOperation]) -> tuple[
        tuple[GeneratedRuntimeComposition, ...], tuple[str, ...],
        tuple[GeneratedRuntimeComposition, ...]]:
    """Apply composition operations to the ACCEPTED catalog.

    Returns the full expected accepted catalog, the explicit removals and EVERY
    changed definition. They all travel in ONE candidate document, so a batch is
    atomic; the endpoint's published budget decides whether the count is
    accepted. Definitions are normalized by stable name order.
    """
    mapping: dict[str, GeneratedRuntimeComposition] = {
        composition.name: composition for composition in baseline}
    order = [composition.name for composition in baseline]
    if len(order) != len(set(order)):
        raise GeneratedEditError("composition_duplicate", "accepted catalog repeats a name")
    removals: list[str] = []
    touched: list[str] = []
    for index, operation in enumerate(plan_operations):
        if not isinstance(operation, (SetComposition, RemoveComposition,
                                      SetCompositionLimits, SetCompositionParameter,
                                      SetCompositionElement, SetCompositionTemplate)):
            continue
        if isinstance(operation, SetComposition):
            has_change = mapping.get(operation.composition.name) != operation.composition
            _apply_composition_operation(mapping, order, removals, operation, index)
            if has_change and operation.composition.name not in touched:
                touched.append(operation.composition.name)
            continue
        prior = {name: mapping[name] for name in mapping}
        _apply_composition_operation(mapping, order, removals, operation, index)
        name = operation.name if isinstance(operation, RemoveComposition) \
            else operation.composition
        if not isinstance(operation, RemoveComposition) and prior.get(name) != mapping.get(name) \
                and name not in touched:
            touched.append(name)
    effective = [name for name in touched if name not in removals]
    for name in removals:
        if name in touched:
            raise GeneratedEditError("composition_update_and_remove", name)
    expected = tuple(mapping[name] for name in order if name in mapping and name not in removals)
    candidates = tuple(mapping[name] for name in sorted(effective))
    return expected, tuple(removals), candidates


def _locate(root: _MutableNode, key: str) -> tuple[_MutableNode, _MutableNode | None, int]:
    def walk(node: _MutableNode, parent: _MutableNode | None) -> tuple[_MutableNode, _MutableNode | None, int] | None:
        if node.key == key:
            return node, parent, 0
        for index, child in enumerate(node.children):
            if child.key == key:
                return child, node, index
            found = walk(child, node)
            if found is not None:
                return found
        return None

    found = walk(root, None)
    if found is None:
        raise GeneratedEditError("unknown_key", f"the accepted structure has no node {key!r}", key=key)
    return found


def _keys_of(node: _MutableNode) -> set[str]:
    out: set[str] = set()

    def walk(item: _MutableNode) -> None:
        out.add(item.key)
        for child in item.children:
            walk(child)

    walk(node)
    return out


def _check_new_keys(node: EditNode, existing: set[str]) -> None:
    def walk(item: EditNode) -> None:
        if item.key in existing:
            raise GeneratedEditError("duplicate_key", f"node key {item.key!r} already exists",
                                     key=item.key)
        existing.add(item.key)
        for child in item.children:
            walk(child)

    walk(node)


def _apply_operation(root: _MutableNode, operation: EditOperation, index: int) -> None:
    if isinstance(operation, SetProperty):
        node, _, _ = _locate(root, operation.key)
        for position, prop in enumerate(node.properties):
            if prop.name == operation.name:
                node.properties[position] = GeneratedProperty(prop.name, operation.value)
                return
        node.properties.append(GeneratedProperty(operation.name, operation.value))
        return
    if isinstance(operation, RemoveProperty):
        node, _, _ = _locate(root, operation.key)
        for position, prop in enumerate(node.properties):
            if prop.name == operation.name:
                del node.properties[position]
                return
        raise GeneratedEditError(
            "property_not_present", f"node {operation.key!r} has no property {operation.name!r}",
            operation_index=index, key=operation.key)
    if isinstance(operation, InsertNode):
        parent, _, _ = _locate(root, operation.parent)
        if operation.index < 0 or operation.index > len(parent.children):
            raise GeneratedEditError(
                "index_out_of_range",
                f"parent {operation.parent!r} accepts index 0..{len(parent.children)}",
                operation_index=index, key=operation.parent)
        existing = _keys_of(root)
        _check_new_keys(operation.node, existing)
        parent.children.insert(operation.index, _mutable(operation.node))
        return
    if isinstance(operation, DeleteNode):
        node, parent, position = _locate(root, operation.key)
        if parent is None:
            raise GeneratedEditError("root_delete", "the root node cannot be deleted",
                                     operation_index=index, key=operation.key)
        del parent.children[position]
        return
    if isinstance(operation, MoveNode):
        node, parent, position = _locate(root, operation.key)
        if parent is None:
            raise GeneratedEditError("root_move", "the root node cannot be moved",
                                     operation_index=index, key=operation.key)
        if operation.parent in _keys_of(node):
            raise GeneratedEditError(
                "cycle", f"cannot move {operation.key!r} under its own descendant {operation.parent!r}",
                operation_index=index, key=operation.key)
        del parent.children[position]
        target, _, _ = _locate(root, operation.parent)
        if operation.index < 0 or operation.index > len(target.children):
            raise GeneratedEditError(
                "index_out_of_range",
                f"parent {operation.parent!r} accepts index 0..{len(target.children)} after the move",
                operation_index=index, key=operation.parent)
        target.children.insert(operation.index, node)
        return
    if isinstance(operation, SetDeclaration):
        node, _, _ = _locate(root, operation.key)
        if operation.kind is UNCHANGED and operation.field is UNCHANGED and \
                operation.action is UNCHANGED:
            raise GeneratedEditError(
                "invalid_plan", "set_declaration changes nothing",
                operation_index=index, key=operation.key)
        if operation.kind is not UNCHANGED:
            node.kind = operation.kind
        if operation.field is not UNCHANGED:
            node.field_id = operation.field
        if operation.action is not UNCHANGED:
            node.action = operation.action
        return
    raise GeneratedEditError("invalid_plan", f"unsupported operation {type(operation).__name__}",
                             operation_index=index)


def _describe_operation(index: int, operation: EditOperation) -> str:
    if isinstance(operation, SetProperty):
        return f"[{index}] set_property {operation.key}.{operation.name} = {operation.value!r}"
    if isinstance(operation, RemoveProperty):
        return f"[{index}] remove_property {operation.key}.{operation.name}"
    if isinstance(operation, InsertNode):
        return f"[{index}] insert {operation.node.key!r} ({operation.node.kind}) under " \
               f"{operation.parent!r} at {operation.index}"
    if isinstance(operation, DeleteNode):
        return f"[{index}] delete {operation.key!r}"
    if isinstance(operation, SetDeclaration):
        parts = []
        if operation.kind is not UNCHANGED:
            parts.append(f"kind={operation.kind!r}")
        if operation.field is not UNCHANGED:
            parts.append(f"field={operation.field!r}")
        if operation.action is not UNCHANGED:
            parts.append(f"action={operation.action!r}")
        return f"[{index}] set_declaration {operation.key!r} " + " ".join(parts)
    if isinstance(operation, SetComposition):
        composition = operation.composition
        return (f"[{index}] set_composition {composition.name!r} "
                f"({len(composition.parameters)} params, {len(composition.elements)} elements)")
    if isinstance(operation, RemoveComposition):
        return f"[{index}] remove_composition {operation.name!r}"
    if isinstance(operation, SetCompositionLimits):
        return (f"[{index}] set_composition_limits {operation.composition!r} "
                f"nodes={operation.expanded_node_limit} depth={operation.expanded_depth_limit}")
    if isinstance(operation, SetCompositionParameter):
        return f"[{index}] set_composition_parameter {operation.composition!r} " \
               f"{operation.name!r}"
    if isinstance(operation, SetCompositionElement):
        return f"[{index}] set_composition_element {operation.composition!r} " \
               f"{operation.key!r}"
    if isinstance(operation, SetCompositionTemplate):
        return f"[{index}] set_composition_template {operation.composition!r} " \
               f"{operation.key!r}"
    return f"[{index}] move {operation.key!r} under {operation.parent!r} at {operation.index}"


def _operation_dict(operation: EditOperation, index: int) -> dict[str, Any]:
    if isinstance(operation, SetProperty):
        return {"op": "set_property", "key": operation.key, "name": operation.name,
                "value": operation.value}
    if isinstance(operation, RemoveProperty):
        return {"op": "remove_property", "key": operation.key, "name": operation.name}
    if isinstance(operation, InsertNode):
        return {"op": "insert", "parent": operation.parent, "index": operation.index,
                "node": operation.node.to_dict()}
    if isinstance(operation, DeleteNode):
        return {"op": "delete", "key": operation.key}
    if isinstance(operation, MoveNode):
        return {"op": "move", "key": operation.key, "parent": operation.parent,
                "index": operation.index}
    if isinstance(operation, SetDeclaration):
        value: dict[str, Any] = {"op": "set_declaration", "key": operation.key}
        if operation.kind is not UNCHANGED:
            value["kind"] = operation.kind
        if operation.field is not UNCHANGED:
            value["field"] = operation.field
        if operation.action is not UNCHANGED:
            value["action"] = operation.action
        return value
    if isinstance(operation, SetComposition):
        return {"op": "set_composition", "composition": _composition_dict(operation.composition)}
    if isinstance(operation, RemoveComposition):
        return {"op": "remove_composition", "name": operation.name}
    if isinstance(operation, SetCompositionLimits):
        value = {"op": "set_composition_limits", "composition": operation.composition}
        if operation.expanded_node_limit is not None:
            value["expanded_node_limit"] = operation.expanded_node_limit
        if operation.expanded_depth_limit is not None:
            value["expanded_depth_limit"] = operation.expanded_depth_limit
        return value
    if isinstance(operation, SetCompositionParameter):
        value = {"op": "set_composition_parameter", "composition": operation.composition,
                 "name": operation.name}
        for name in ("value_type", "required", "minimum", "maximum", "max_length", "default"):
            item = getattr(operation, name)
            if item is not None:
                wire = {"value_type": "type", "minimum": "min", "maximum": "max",
                        "max_length": "max_length"}.get(name, name)
                value[wire] = item
        return value
    if isinstance(operation, SetCompositionElement):
        value = {"op": "set_composition_element", "composition": operation.composition,
                 "key": operation.key}
        for name in ("role", "field", "argument", "action", "source", "preset", "label"):
            item = getattr(operation, name)
            if item is not None:
                value[name] = item
        return value
    if isinstance(operation, SetCompositionTemplate):
        value = {"op": "set_composition_template", "composition": operation.composition,
                 "key": operation.key}
        for name in ("kind", "element", "presentation", "text", "style", "gap", "padding",
                     "height", "grow", "axis", "first", "minfirst", "minsecond"):
            item = getattr(operation, name)
            if item is not None:
                value[name] = item
        return value
    raise GeneratedEditError("invalid_plan",
                             f"operation[{index}] has an unsupported type")


# --- preflight ---------------------------------------------------------------

def _utf8_length(value: str) -> int:
    return len(value.encode("utf-8"))


def _property_spec(capabilities: GeneratedCapabilities, kind: str, name: str):
    component = capabilities.component(kind)
    if component is None:
        return None
    return next((prop for prop in component.properties if prop.name == name), None)


def _check_property_value(spec, name: str, value: str, path: str) -> None:
    if spec.value_type == "STRING":
        if spec.max_length > 0 and _utf8_length(value) > spec.max_length:
            raise GeneratedEditError(
                "property_too_long",
                f"{path} is {_utf8_length(value)} bytes; the catalog allows {spec.max_length}")
        if not spec.encoding and spec.values and value not in spec.values:
            raise GeneratedEditError(
                "property_value_not_allowed",
                f"{path} must be one of {', '.join(spec.values)}")
        return
    if spec.value_type == "BOOLEAN":
        if value not in ("true", "false"):
            raise GeneratedEditError("property_not_boolean", f"{path} must be true or false")
        return
    if spec.value_type == "INTEGER":
        if not _INTEGER_WIRE.fullmatch(value):
            raise GeneratedEditError("property_not_integer", f"{path} must be a decimal integer")
        number = int(value)
        if not _INT64_MIN <= number <= _INT64_MAX:
            raise GeneratedEditError("property_not_integer", f"{path} does not fit Int64")
        if spec.maximum > spec.minimum and not (spec.minimum <= number <= spec.maximum):
            raise GeneratedEditError(
                "property_out_of_range",
                f"{path} must be in {spec.minimum}..{spec.maximum}")
        return
    # An unpublished value type is the endpoint's refusal to make; do not guess.


def _validate_tree(root: EditNode, capabilities: GeneratedCapabilities | None,
                   runtime_kinds: frozenset[str] = frozenset()) -> None:
    if capabilities is None:
        return
    nodes = root.to_generated_nodes()
    max_depth = max((node.depth for node in nodes), default=0)
    if capabilities.max_depth > 0 and max_depth > capabilities.max_depth:
        raise GeneratedEditError(
            "max_depth_exceeded", f"structure depth {max_depth} exceeds {capabilities.max_depth}")
    if capabilities.max_nodes > 0 and len(nodes) > capabilities.max_nodes:
        raise GeneratedEditError(
            "max_nodes_exceeded", f"structure has {len(nodes)} nodes; the catalog allows {capabilities.max_nodes}")

    def walk(node: EditNode) -> None:
        component = capabilities.component(node.kind)
        if component is None:
            if node.kind in runtime_kinds:
                # A runtime-composition instance is expanded by the producer;
                # its declaration is the definition, not a catalog component.
                for child in node.children:
                    walk(child)
                return
            raise GeneratedEditError("unknown_kind", f"component kind {node.kind!r} is not published",
                                     key=node.key)
        if capabilities.max_properties_per_node > 0 and \
                len(node.properties) > capabilities.max_properties_per_node:
            raise GeneratedEditError(
                "too_many_properties",
                f"{node.key!r} has {len(node.properties)} properties; the catalog allows "
                f"{capabilities.max_properties_per_node}", key=node.key)
        seen_names: set[str] = set()
        declared = {prop.name for prop in component.properties}
        for prop in node.properties:
            if prop.name in seen_names:
                raise GeneratedEditError("duplicate_property",
                                         f"{node.key!r} declares {prop.name!r} twice", key=node.key)
            seen_names.add(prop.name)
            if prop.name not in declared and prop.name not in _COMMON_PROPERTY_NAMES:
                raise GeneratedEditError(
                    "unknown_property",
                    f"component {node.kind!r} does not publish {prop.name!r}", key=node.key)
            spec = next((item for item in component.properties if item.name == prop.name), None)
            if spec is not None:
                _check_property_value(spec, prop.name, prop.value, f"{node.key}.{prop.name}")
        for spec in component.properties:
            if spec.required and spec.name not in seen_names:
                raise GeneratedEditError(
                    "missing_required_property",
                    f"{node.key!r} ({node.kind}) is missing required {spec.name!r}", key=node.key)
        if node.field_id and capabilities.field(node.field_id) is None:
            raise GeneratedEditError(
                "unknown_field", f"{node.key!r} binds unpublished field {node.field_id!r}",
                key=node.key)
        if node.action and capabilities.action(node.action) is None:
            raise GeneratedEditError(
                "unknown_action", f"{node.key!r} binds unpublished action {node.action!r}",
                key=node.key)
        if not component.allows_children and node.children:
            raise GeneratedEditError(
                "children_not_allowed", f"component {node.kind!r} does not allow children",
                key=node.key)
        if component.child_limit > 0 and len(node.children) > component.child_limit:
            raise GeneratedEditError(
                "child_limit_exceeded",
                f"{node.key!r} has {len(node.children)} children; the catalog allows "
                f"{component.child_limit}", key=node.key)
        for child in node.children:
            walk(child)

    walk(root)


# --- readable diff -----------------------------------------------------------

@dataclass(frozen=True)
class PropertyChange:
    key: str
    name: str
    old: str | None
    new: str | None


@dataclass(frozen=True)
class DeclarationChange:
    key: str
    old_kind: str
    new_kind: str
    old_field: str | None
    new_field: str | None
    old_action: str | None
    new_action: str | None


@dataclass(frozen=True)
class GeneratedEditDiff:
    added: tuple[str, ...]
    removed: tuple[str, ...]
    moved: tuple[tuple[str, str | None, str | None], ...]
    reordered_parents: tuple[str, ...]
    property_changes: tuple[PropertyChange, ...]
    binding_changes: tuple[str, ...]
    lines: tuple[str, ...]
    declaration_changes: tuple[DeclarationChange, ...] = ()

    def to_text(self) -> str:
        return "\n".join(self.lines) if self.lines else "(no structural changes)"

    def to_dict(self) -> dict[str, Any]:
        result = {
            "added": list(self.added),
            "removed": list(self.removed),
            "moved": [{"key": key, "from": old, "to": new}
                      for key, old, new in self.moved],
            "reordered_parents": list(self.reordered_parents),
            "property_changes": [{"key": change.key, "name": change.name,
                                  "old": change.old, "new": change.new}
                                 for change in self.property_changes],
            "binding_changes": list(self.binding_changes),
            "lines": list(self.lines),
        }
        if self.declaration_changes:
            result["declaration_changes"] = [
                {"key": change.key,
                 "kind": {"old": change.old_kind, "new": change.new_kind},
                 "field": {"old": change.old_field, "new": change.new_field},
                 "action": {"old": change.old_action, "new": change.new_action}}
                for change in self.declaration_changes]
        return result


def _map_nodes(root: EditNode) -> dict[str, tuple[EditNode, str | None, int]]:
    out: dict[str, tuple[EditNode, str | None, int]] = {}

    def walk(node: EditNode, parent: str | None, index: int) -> None:
        out[node.key] = (node, parent, index)
        for position, child in enumerate(node.children):
            walk(child, node.key, position)

    walk(root, None, 0)
    return out


def edit_diff(before: EditNode | None, after: EditNode) -> GeneratedEditDiff:
    before_map = _map_nodes(before) if before is not None else {}
    after_map = _map_nodes(after)

    added_roots: list[str] = []
    if before is None:
        added_roots.append(after.key)
    for key, (_, parent, _) in after_map.items():
        if key not in before_map and (parent is not None and parent in before_map):
            added_roots.append(key)
    removed_roots: list[str] = []
    for key, (_, parent, _) in before_map.items():
        if key not in after_map and (parent is not None and parent in after_map):
            removed_roots.append(key)

    moved: list[tuple[str, str | None, str | None]] = []
    for key, (_, parent, _) in after_map.items():
        if key in before_map and before_map[key][1] != parent:
            moved.append((key, before_map[key][1], parent))

    reordered: list[str] = []
    # after_map is inserted by the accepted tree walk; iterating a set here made
    # saved-plan previews depend on the process hash seed.
    for parent in after_map:
        before_children = [key for key in _child_order(before, parent) if key in after_map]
        after_children = [key for key in _child_order(after, parent) if key in before_map]
        if before_children != after_children:
            reordered.append(parent if parent is not None else "$root")

    property_changes: list[PropertyChange] = []
    binding_changes: list[str] = []
    declaration_changes: list[DeclarationChange] = []
    for key, (after_node, _, _) in after_map.items():
        if key not in before_map:
            continue
        before_node = before_map[key][0]
        old_props = {prop.name: prop.value for prop in before_node.properties}
        new_props = {prop.name: prop.value for prop in after_node.properties}
        for name in new_props:
            if name not in old_props:
                property_changes.append(PropertyChange(key, name, None, new_props[name]))
            elif old_props[name] != new_props[name]:
                property_changes.append(PropertyChange(key, name, old_props[name], new_props[name]))
        for name in old_props:
            if name not in new_props:
                property_changes.append(PropertyChange(key, name, old_props[name], None))
        if (before_node.kind, before_node.field_id, before_node.action) != \
                (after_node.kind, after_node.field_id, after_node.action):
            binding_changes.append(key)
            declaration_changes.append(DeclarationChange(
                key, before_node.kind, after_node.kind,
                before_node.field_id, after_node.field_id,
                before_node.action, after_node.action))

    # Deterministic readable order: accepted traversal of the result, then removals.
    order = list(after_map)
    lines: list[str] = []
    for change in sorted(property_changes, key=lambda item: order.index(item.key)):
        if change.old is None:
            lines.append(f"~ {change.key}.{change.name}: set to {change.new!r}")
        elif change.new is None:
            lines.append(f"~ {change.key}.{change.name}: unset (was {change.old!r})")
        else:
            lines.append(f"~ {change.key}.{change.name}: {change.old!r} -> {change.new!r}")
    for key in added_roots:
        node = after_map[key][0]
        count = len(node.to_generated_nodes())
        parent = after_map[key][1]
        position = after_map[key][2]
        suffix = f" (+{count} nodes)" if count > 1 else ""
        lines.append(f"+ {key} ({node.kind}) under {parent or '$root'} at {position}{suffix}")
    for key, old_parent, new_parent in moved:
        lines.append(f"> {key}: {old_parent or '$root'} -> {new_parent or '$root'}")
    for parent in reordered:
        node = _find_node(after, parent)
        if node is None:
            node = after
        lines.append(f"< {parent}: child order now {[child.key for child in node.children]}")
    for key in removed_roots:
        node = before_map[key][0]
        count = len(node.to_generated_nodes())
        suffix = f" (-{count} nodes)" if count > 1 else ""
        lines.append(f"- {key} ({node.kind}){suffix}")
    for change in declaration_changes:
        if change.old_kind != change.new_kind:
            lines.append(f"! {change.key}.kind: {change.old_kind!r} -> {change.new_kind!r}")
        if change.old_field != change.new_field:
            lines.append(f"! {change.key}.field: {change.old_field!r} -> {change.new_field!r}")
        if change.old_action != change.new_action:
            lines.append(f"! {change.key}.action: {change.old_action!r} -> {change.new_action!r}")

    return GeneratedEditDiff(tuple(added_roots), tuple(removed_roots), tuple(moved),
                             tuple(reordered), tuple(property_changes),
                             tuple(binding_changes), tuple(lines),
                             tuple(declaration_changes))


def _child_order(root: EditNode | None, parent: str | None) -> list[str]:
    if root is None or parent is None:
        return []
    def walk(node: EditNode) -> list[str] | None:
        if node.key == parent:
            return [child.key for child in node.children]
        for child in node.children:
            found = walk(child)
            if found is not None:
                return found
        return None
    found = walk(root)
    return found or []


def _find_node(root: EditNode, key: str) -> EditNode | None:
    def walk(node: EditNode) -> EditNode | None:
        if node.key == key:
            return node
        for child in node.children:
            found = walk(child)
            if found is not None:
                return found
        return None
    return walk(root)


# --- preview -----------------------------------------------------------------

@dataclass(frozen=True)
class GeneratedEditPreview:
    """A local candidate description.  `local_only` is always true.

    It is deliberately not called an accepted structure: nothing here has been
    sent to the application yet.  `nodes` is the complete structure that
    `submit_preview` would send with `base_version` as its CAS expectation.

    `endpoint` and `base_structure_sha256` bind a saved plan to the exact
    endpoint instance and baseline it was previewed against.  They are
    consistency facts, never authorization.
    """

    base_version: int
    accepted_candidate_version: int
    scene_state: str
    root: EditNode
    nodes: tuple[GeneratedNode, ...]
    diff: GeneratedEditDiff
    operations: tuple[str, ...]
    local_only: bool = True
    endpoint: GeneratedEndpointIdentity | None = None
    base_structure_sha256: str = ""
    #: The exact candidate document (definitions/removals + nodes) to submit.
    document: GeneratedStructureDocument | None = None
    #: The FULL accepted catalog this candidate is expected to produce. A
    #: node-only candidate against a definition-bearing region keeps every
    #: accepted definition here even though its candidate body omits them.
    expected_compositions: tuple[GeneratedRuntimeComposition, ...] = ()
    candidate_compositions: tuple[GeneratedRuntimeComposition, ...] = ()
    removals: tuple[str, ...] = ()
    submitted_sha256: str = ""
    expected_structure_sha256: str = ""
    expected_format_version: int = 1
    #: Digest of the imported `cjgui.ui-document` when this preview came from
    #: one; empty for ordinary plan previews.
    import_document_sha256: str = ""
    #: The exact merge/replace policy this preview was built with. A saved plan
    #: is refused when a caller pairs it with a different policy.
    replace_definitions: bool = False

    def to_text(self) -> str:
        lines = [
            "LOCAL PREVIEW (not submitted; the application decides acceptance)",
            f"BASE_VERSION {self.base_version} "
            f"ACCEPTED_CANDIDATE_VERSION {self.accepted_candidate_version} "
            f"SCENE_STATE {self.scene_state}",
            f"ENDPOINT {self.endpoint.describe() if self.endpoint else 'unknown'} "
            f"BASE_STRUCTURE_SHA256 {self.base_structure_sha256 or 'unknown'}",
            f"CANDIDATE_FORMAT {self.document.format_version if self.document else 1} "
            f"CANDIDATE_DEFINITIONS "
            f"{','.join(item.name for item in self.candidate_compositions) or '-'} "
            f"CANDIDATE_REMOVALS {','.join(self.removals) or '-'}",
            f"SUBMITTED_SHA256 {self.submitted_sha256 or 'unknown'} "
            f"(candidate delta)",
            f"EXPECTED_FORMAT {self.expected_format_version} "
            f"EXPECTED_DEFINITIONS "
            f"{','.join(item.name for item in self.expected_compositions) or '-'}",
            f"EXPECTED_STRUCTURE_SHA256 {self.expected_structure_sha256 or 'unknown'} "
            f"(complete accepted state)",
            f"IMPORT_DOCUMENT_SHA256 {self.import_document_sha256 or '-'}",
            f"NODES {len(self.nodes)}",
            "OPERATIONS",
            *(f"  {line}" for line in self.operations),
            "DIFF",
            *(f"  {line}" for line in self.diff.lines),
        ]
        if not self.diff.lines:
            lines.append("  (no structural changes)")
        lines.append("END_PREVIEW")
        return "\n".join(lines)

    def to_dict(self) -> dict[str, Any]:
        return {
            "local_only": True,
            "base_version": self.base_version,
            "accepted_candidate_version": self.accepted_candidate_version,
            "scene_state": self.scene_state,
            "endpoint": _endpoint_dict(self.endpoint),
            "base_structure_sha256": self.base_structure_sha256,
            "expected_format_version": self.expected_format_version,
            "expected_structure_sha256": self.expected_structure_sha256,
            "submitted_sha256": self.submitted_sha256,
            "import_document_sha256": self.import_document_sha256,
            "candidate_compositions": [_composition_dict(item)
                                       for item in self.candidate_compositions],
            "removals": list(self.removals),
            "compositions": [_composition_dict(item) for item in self.expected_compositions],
            "operations": list(self.operations),
            "diff": self.diff.to_dict(),
            "nodes": [_node_dict(node) for node in generated_nodes_of(self.root)],
        }


def composition_template_node_count(node: Any) -> int:
    return 1 + sum(composition_template_node_count(child) for child in node.children)


def _check_candidate_budget(capabilities: GeneratedCapabilities | None,
                            candidates: Sequence[GeneratedRuntimeComposition],
                            payload_bytes: int = 0) -> None:
    """Refuse a batch the endpoint has not published capacity for.

    A legacy endpoint without `COMPOSITION_BUDGET` keeps the one-definition
    behaviour. The preview is the only place that can turn a local plan into a
    batch, so this check runs before any submission.
    """
    if not candidates:
        return
    budget = capabilities.composition_budget if capabilities is not None else None
    limit = budget.definitions if budget is not None else 1
    if len(candidates) > limit:
        source = "published COMPOSITION_BUDGET" if budget is not None \
            else "no published multi-definition capacity"
        raise GeneratedEditError(
            "composition_batch_unsupported",
            f"this plan changes {len(candidates)} definitions but the endpoint allows "
            f"{limit} per candidate ({source}); refusing to split an atomic batch")
    if budget is None:
        return
    elements = sum(len(composition.elements) for composition in candidates)
    if elements > budget.elements:
        raise GeneratedEditError(
            "composition_batch_budget",
            f"the batch declares {elements} elements; the endpoint allows {budget.elements}")
    nodes = sum(composition_template_node_count(composition.template)
                for composition in candidates)
    if nodes > budget.template_nodes:
        raise GeneratedEditError(
            "composition_batch_budget",
            f"the batch declares {nodes} template nodes; the endpoint allows "
            f"{budget.template_nodes}")
    if payload_bytes > budget.bytes:
        raise GeneratedEditError(
            "composition_batch_budget",
            f"the candidate is {payload_bytes} bytes; the endpoint allows {budget.bytes}")


def preview_plan(structure: GeneratedStructure, plan: GeneratedEditPlan,
                 capabilities: GeneratedCapabilities | None = None, *,
                 endpoint: GeneratedEndpointIdentity | None = None) -> GeneratedEditPreview:
    """Apply `plan` to `structure` locally and describe the complete result.

    Node operations and ONE definition change are applied to the SAME candidate
    document. A node-only plan against a definition-bearing region keeps the
    accepted definitions (format 2 with an omitted definition section). The
    preview always carries two different digests: the candidate delta that
    would be sent and the COMPLETE accepted state it is expected to produce.

    Raises `GeneratedEditError("stale_base_version")` when the plan was built
    for another accepted version: key addresses are only meaningful against the
    baseline the plan was written for, so a rebase is never guessed.
    """
    if plan.base_version != structure.version:
        raise GeneratedEditError(
            "stale_base_version",
            f"plan targets accepted version {plan.base_version}; the application answered "
            f"{structure.version}")
    if not structure.lossless:
        raise GeneratedEditError(
            "composition_document_not_lossless",
            "the accepted document contains fields or lines this client did not "
            "understand; editing or re-encoding it would silently drop them")
    if structure.format_version not in (1, 2):
        raise GeneratedEditError(
            "structure_format_unsupported",
            f"accepted structure format {structure.format_version} is not edited by this "
            f"client")
    before = tree_from_nodes(structure.nodes)
    working = _mutable(before)
    for index, operation in enumerate(plan.operations):
        if isinstance(operation, (SetComposition, RemoveComposition, SetCompositionLimits,
                                  SetCompositionParameter, SetCompositionElement,
                                  SetCompositionTemplate)):
            continue
        try:
            _apply_operation(working, operation, index)
        except GeneratedEditError as error:
            if error.operation_index is None:
                raise GeneratedEditError(error.code, error.detail,
                                         operation_index=index, key=error.key) from None
            raise
    after = _immutable(working)
    expected_compositions, removals, candidate_compositions = _expected_compositions(
        structure.compositions, plan.operations)
    _check_candidate_budget(capabilities, candidate_compositions)
    runtime_kinds = frozenset({composition.name for composition in structure.compositions} |
                              {composition.name for composition in expected_compositions})
    _validate_tree(after, capabilities, runtime_kinds)
    node_kinds = {node.kind for node in after.to_generated_nodes()}
    for name in removals:
        if name in node_kinds:
            raise GeneratedEditError(
                "composition_remove_still_referenced", name, key=name)
    diff = edit_diff(before, after)
    nodes = generated_nodes_of(after)
    node_changed = not same_structure(structure.nodes, nodes)
    if not node_changed and not removals and \
            tuple(expected_compositions) == tuple(structure.compositions):
        raise GeneratedEditError(
            "no_changes", "the plan leaves the accepted structure unchanged; refusing a "
                          "pointless version bump")
    format_version = 2 if (structure.format_version == 2 or candidate_compositions or
                           removals) else 1
    document = GeneratedStructureDocument(format_version, candidate_compositions, nodes,
                                          removals=removals)
    expected_format = 2 if expected_compositions else 1
    expected_structure = GeneratedStructure(
        structure.version + 1, structure.candidate_version, structure.scene_state, nodes,
        format_version=expected_format, compositions=expected_compositions)
    try:
        submitted_payload = encode_generated_structure_document(document)
    except GeneratedUiError as error:
        raise GeneratedEditError(
            "wire_encoding", str(error),
            operation_index=getattr(error, "operation_index", None)) from error
    _check_candidate_budget(capabilities, candidate_compositions,
                            len(submitted_payload.encode("utf-8")))
    base_digest = structure_document_digest(structure)
    normalized_expected = structure_document_digest(expected_structure)
    return GeneratedEditPreview(
        structure.version, structure.candidate_version, structure.scene_state,
        after, nodes, diff, plan.describe(), endpoint=endpoint,
        base_structure_sha256=base_digest, document=document,
        expected_compositions=expected_compositions,
        candidate_compositions=candidate_compositions, removals=removals,
        submitted_sha256=hashlib.sha256(submitted_payload.encode("utf-8")).hexdigest(),
        expected_structure_sha256=normalized_expected,
        expected_format_version=expected_format)


def preview_snapshot(snapshot: GeneratedSnapshot, plan: GeneratedEditPlan,
                     capabilities: GeneratedCapabilities | None = None) -> GeneratedEditPreview:
    """Preview against the structure section of ONE atomic snapshot."""
    return preview_plan(structure_from_snapshot(snapshot), plan, capabilities,
                        endpoint=snapshot.endpoint)


def preview_document(structure: GeneratedStructure,
                     document: GeneratedStructureDocument,
                     capabilities: GeneratedCapabilities | None,
                     *, endpoint: GeneratedEndpointIdentity | None = None,
                     replace_definitions: bool = False,
                     document_sha256: str = "") -> GeneratedEditPreview:
    """Apply a COMPLETE document to one accepted region.

    The document's node tree replaces this region's tree. Accepted definitions
    the document does not mention are retained by default; an explicit
    `replace_definitions` additionally removes every accepted definition the
    document omits, and the preview lists those removals. Nothing here touches
    an owner value, draft, focus or selection: only the accepted structure and
    definition directory are candidates for replacement.
    """
    if not structure.lossless or not document.lossless:
        raise GeneratedEditError(
            "composition_document_not_lossless",
            "the accepted or imported document contains unknown content; refusing to "
            "replace it with a pruned tree")
    if structure.format_version not in (1, 2) or document.format_version not in (1, 2):
        raise GeneratedEditError(
            "structure_format_unsupported",
            "document import supports structure formats 1 and 2")
    # A freshly accepted generated region has `STRUCTURE 0`: no node owns a
    # root yet, so importing the first document is a legal whole-tree add.
    before = tree_from_nodes(structure.nodes) if structure.nodes else None
    after = tree_from_nodes(document.nodes)
    accepted_names = [composition.name for composition in structure.compositions]
    accepted = {composition.name: composition for composition in structure.compositions}
    if len(accepted) != len(accepted_names):
        raise GeneratedEditError("composition_duplicate", "accepted catalog repeats a name")

    operations: list[str] = []
    candidates: list[GeneratedRuntimeComposition] = []
    merged: list[GeneratedRuntimeComposition] = list(structure.compositions)
    for composition in document.compositions:
        current = accepted.get(composition.name)
        if current is None:
            merged.append(composition)
            candidates.append(composition)
            operations.append(f"add definition {composition.name}")
        elif _canonical_composition(current) != _canonical_composition(composition):
            position = next(index for index, item in enumerate(merged)
                            if item.name == composition.name)
            merged[position] = composition
            candidates.append(composition)
            operations.append(f"replace definition {composition.name}")
        else:
            operations.append(f"retain definition {composition.name}")
    document_names = {composition.name for composition in document.compositions}
    removals = tuple(sorted(set(accepted_names) - document_names)) \
        if replace_definitions else ()
    if replace_definitions:
        merged = [composition for composition in merged if composition.name in document_names]
        candidates = [composition for composition in document.compositions]
        for name in removals:
            operations.append(f"remove definition {name}")
    candidates = tuple(sorted(candidates, key=lambda item: item.name))
    _check_candidate_budget(capabilities, candidates)

    runtime_kinds = frozenset(accepted_names) | document_names
    _validate_tree(after, capabilities, runtime_kinds)
    node_kinds = {node.kind for node in after.to_generated_nodes()}
    for name in removals:
        if name in node_kinds:
            raise GeneratedEditError("composition_remove_still_referenced", name, key=name)
    nodes = generated_nodes_of(after)
    if same_structure(structure.nodes, nodes) and not removals and not candidates:
        raise GeneratedEditError(
            "no_changes", "the imported document leaves the accepted structure unchanged")
    retained = len({node.key for node in structure.nodes} &
                   {node.key for node in nodes})
    operations.insert(
        0, f"import ui-document: replace region nodes ({len(nodes)} nodes, "
           f"{retained} stable keys retained)")
    format_version = 2 if (structure.format_version == 2 or document.format_version == 2 or
                           merged or removals) else 1
    candidate_document = GeneratedStructureDocument(
        format_version, candidates, nodes, removals=removals)
    expected_format = 2 if merged else 1
    expected_structure = GeneratedStructure(
        structure.version + 1, structure.candidate_version, structure.scene_state, nodes,
        format_version=expected_format, compositions=tuple(merged))
    try:
        submitted_payload = encode_generated_structure_document(candidate_document)
    except GeneratedUiError as error:
        raise GeneratedEditError("wire_encoding", str(error)) from error
    _check_candidate_budget(capabilities, candidates,
                            len(submitted_payload.encode("utf-8")))
    return GeneratedEditPreview(
        structure.version, structure.candidate_version, structure.scene_state,
        after, nodes, edit_diff(before, after), tuple(operations), endpoint=endpoint,
        base_structure_sha256=structure_document_digest(structure),
        document=candidate_document, expected_compositions=tuple(merged),
        candidate_compositions=candidates, removals=removals,
        submitted_sha256=hashlib.sha256(submitted_payload.encode("utf-8")).hexdigest(),
        expected_structure_sha256=structure_document_digest(expected_structure),
        expected_format_version=expected_format,
        import_document_sha256=document_sha256,
        replace_definitions=replace_definitions)


def _node_dict(node: GeneratedNode) -> dict[str, Any]:
    return {
        "depth": node.depth,
        "key": node.key,
        "kind": node.kind,
        "field": node.field_id,
        "action": node.action,
        "properties": {prop.name: prop.value for prop in node.properties},
    }


def _composition_template_dict(node: Any) -> dict[str, Any]:
    return {
        "depth": node.depth,
        "key": node.key,
        "kind": node.kind,
        "element": node.element_key,
        "presentation": node.presentation,
        "text": node.text,
        "style": node.style_name,
        "gap": node.gap,
        "padding": node.padding,
        "height": node.fixed_height,
        "grow": node.grow,
        "axis": node.axis,
        "first": node.first_size,
        "minfirst": node.min_first,
        "minsecond": node.min_second,
        "children": [_composition_template_dict(child) for child in node.children],
    }


def _composition_dict(composition: Any) -> dict[str, Any]:
    return {
        "name": composition.name,
        "expanded_node_limit": composition.expanded_node_limit,
        "expanded_depth_limit": composition.expanded_depth_limit,
        "parameters": [
            {"name": item.name, "type": item.value_type,
             "required": item.required, "min": item.minimum, "max": item.maximum,
             "max_length": item.max_length, "default": item.default}
            for item in composition.parameters
        ],
        "elements": [
            {"key": item.key, "role": item.role, "field": item.field_id,
             "argument": item.argument, "action": item.action,
             "source": item.source, "preset": item.preset, "label": item.label}
            for item in composition.elements
        ],
        "template": _composition_template_dict(composition.template),
    }


# --- submission --------------------------------------------------------------

@dataclass(frozen=True)
class GeneratedEditOutcome:
    """What the endpoint actually did with ONE submission.

    `outcome` is one of: accepted, stale, rejected, superseded, unknown,
    timeout, endpoint_replaced, endpoint_unavailable, refused, protocol_error,
    replaced_after_accept, readback_mismatch.  Only `accepted` means the atomic
    snapshot belongs to the ticket's endpoint, agrees with its version and
    exactly matches the submitted nodes.
    """

    outcome: str
    detail: str
    base_version: int
    preview: GeneratedEditPreview | None
    token: int = 0
    receipt: str = "none"
    terminal_state: str = "UNKNOWN"
    reason: str = "none"
    path: str = "none"
    accepted_version: int | None = None
    current_version: int | None = None
    exact_readback: bool = False
    submit_to_accepted_ms: float | None = None
    readback_ms: float | None = None
    candidate_reads: int = 0
    accepted_structure: GeneratedStructure | None = None
    endpoint: GeneratedEndpointIdentity | None = None
    ticket: GeneratedCandidateTicket | None = None
    submitted_sha256: str = ""
    expected_structure_sha256: str = ""
    instances_sha256: str = ""
    instance_owners: dict[str, int] = field(default_factory=dict)
    instance_owner_conflicts: dict[str, list[int]] = field(default_factory=dict)
    instance_keys: tuple[str, ...] = ()
    phase: str = "submit"

    def succeeded(self) -> bool:
        return self.outcome == "accepted" and self.exact_readback

    def to_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "outcome": self.outcome,
            "detail": self.detail,
            "phase": self.phase,
            "base_version": self.base_version,
            "token": self.token,
            "receipt": self.receipt,
            "terminal_state": self.terminal_state,
            "reason": self.reason,
            "path": self.path,
            "accepted_version": self.accepted_version,
            "current_version": self.current_version,
            "exact_readback": self.exact_readback,
            "submit_to_accepted_ms": self.submit_to_accepted_ms,
            "readback_ms": self.readback_ms,
            "candidate_reads": self.candidate_reads,
            "endpoint": _endpoint_dict(self.endpoint),
            "ticket": None if self.ticket is None else {
                "token": self.ticket.token,
                "receipt": self.ticket.receipt,
                "endpoint": _endpoint_dict(self.ticket.endpoint),
                "base_version": self.ticket.base_version,
                "candidate_version": self.ticket.candidate_version,
            },
            "submitted_sha256": self.submitted_sha256,
            "expected_structure_sha256": self.expected_structure_sha256,
            "instances_sha256": self.instances_sha256,
            "instance_owners": dict(sorted(self.instance_owners.items())),
            "instance_owner_conflicts": dict(sorted(self.instance_owner_conflicts.items())),
            "instance_keys": list(self.instance_keys),
        }
        if self.preview is not None:
            result["preview"] = self.preview.to_dict()
        if self.accepted_structure is not None:
            result["accepted_structure"] = {
                "version": self.accepted_structure.version,
                "candidate_version": self.accepted_structure.candidate_version,
                "scene_state": self.accepted_structure.scene_state,
                "compositions": [_composition_dict(item)
                                 for item in self.accepted_structure.compositions],
                "nodes": [_node_dict(node) for node in self.accepted_structure.nodes],
            }
        return result


def _endpoint_outcome(preview: GeneratedEditPreview, code: str, detail: str,
                      *, ticket: GeneratedCandidateTicket | None = None,
                      state: GeneratedCandidateState | None = None,
                      phase: str | None = None,
                      submit_to_accepted_ms: float | None = None,
                      readback_ms: float | None = None,
                      reads: int = 0) -> GeneratedEditOutcome:
    return GeneratedEditOutcome(
        "endpoint_replaced" if code == "endpoint_replaced" else "endpoint_unavailable",
        detail, preview.base_version, preview,
        token=ticket.token if ticket else 0,
        receipt=ticket.receipt if ticket else "none",
        terminal_state=state.terminal_state if state is not None else "UNKNOWN",
        reason=state.reason if state is not None else "none",
        path=state.path if state is not None else "none",
        accepted_version=state.accepted_version if state is not None else None,
        submit_to_accepted_ms=submit_to_accepted_ms, readback_ms=readback_ms,
        candidate_reads=reads,
        endpoint=ticket.endpoint if ticket else preview.endpoint,
        ticket=ticket, submitted_sha256=preview.submitted_sha256
        or structure_digest(preview.nodes),
        phase=phase or ("readback" if ticket else "submit"))


def _snapshot_failure(base_version: int, error: BaseException) -> GeneratedEditOutcome:
    """Classify a failure of the initial atomic snapshot.

    A deadline is a timeout whether the transport raises the builtin
    TimeoutError or the typed client's GeneratedUiDeadlineExceeded; no ticket
    exists yet, so this must never look like a submitted-but-unknown candidate.
    """
    if isinstance(error, (TimeoutError, GeneratedUiDeadlineExceeded)):
        return GeneratedEditOutcome("timeout", f"atomic snapshot: {error}", base_version, None,
                                    phase="snapshot")
    if isinstance(error, GeneratedUiEndpointError):
        return GeneratedEditOutcome(
            "endpoint_replaced" if error.code == "endpoint_replaced"
            else "endpoint_unavailable", str(error), base_version, None, phase="snapshot")
    if isinstance(error, (ConnectionError, OSError)):
        return GeneratedEditOutcome("endpoint_unavailable", str(error), base_version, None,
                                    phase="snapshot")
    return GeneratedEditOutcome("protocol_error", str(error), base_version, None,
                                phase="snapshot")


def _read_snapshot(session: GeneratedUiSession, base_version: int,
                   deadline: float | None) -> tuple[GeneratedSnapshot | None,
                                                    GeneratedEditOutcome | None]:
    try:
        snapshot = session.snapshot() if deadline is None \
            else session.snapshot(deadline_monotonic=deadline)
    except (TimeoutError, GeneratedUiDeadlineExceeded, GeneratedUiEndpointError,
            ConnectionError, OSError, GeneratedUiError) as error:
        return None, _snapshot_failure(base_version, error)
    return snapshot, None


def _remaining_total_ms(deadline: float | None) -> int | None:
    if deadline is None:
        return None
    return max(0, int((deadline - time.monotonic()) * 1000))


def submit_preview(session: GeneratedUiSession, preview: GeneratedEditPreview, *,
                   timeout_ms: int = 5_000, poll_ms: int = 25,
                   total_timeout_ms: int | None = None) -> GeneratedEditOutcome:
    """Submit exactly one local preview and report the endpoint's real result.

    `timeout_ms` keeps its old meaning: one budget for candidate settlement.
    `total_timeout_ms`, when supplied, is a SEPARATE overall budget covering the
    submit request, the candidate wait and the atomic readback; it is not a
    silent reinterpretation of the old option.  There is no automatic retry and
    no rebase.  UNKNOWN stays unknown, a deadline stays a timeout, and
    `accepted` requires the ticket's endpoint, the ticket's accepted version and
    the exact submitted nodes in ONE atomic generated snapshot.
    """
    if timeout_ms < 0 or poll_ms <= 0 or (total_timeout_ms is not None and total_timeout_ms < 0):
        raise ValueError("wait bounds are invalid")
    started = time.monotonic()
    deadline = None if total_timeout_ms is None else started + total_timeout_ms / 1000.0
    if preview.document is None:
        raise GeneratedEditError("missing_document",
                                 "preview carries no candidate document")
    submitted_sha256 = preview.submitted_sha256 or hashlib.sha256(
        encode_generated_structure_document(preview.document).encode("utf-8")).hexdigest()

    def timeout_outcome(detail: str, *, phase: str,
                        ticket: GeneratedCandidateTicket | None = None,
                        state: GeneratedCandidateState | None = None,
                        reads: int = 0) -> GeneratedEditOutcome:
        return GeneratedEditOutcome(
            "timeout", detail, preview.base_version, preview,
            token=ticket.token if ticket else 0,
            receipt=ticket.receipt if ticket else "none",
            terminal_state=state.terminal_state if state else "UNKNOWN",
            reason=state.reason if state else "none", path=state.path if state else "none",
            accepted_version=state.accepted_version if state else None,
            current_version=state.accepted_version if state else None,
            candidate_reads=reads, endpoint=ticket.endpoint if ticket else preview.endpoint,
            ticket=ticket, submitted_sha256=submitted_sha256, phase=phase)

    if deadline is not None and deadline - time.monotonic() <= 0:
        return timeout_outcome("total budget expired before submit", phase="submit")
    try:
        reply = session.submit_document(preview.document, preview.base_version,
                                        deadline_monotonic=deadline)
    except GeneratedUiRemoteError as error:
        if error.code == "structure_version_conflict":
            return GeneratedEditOutcome("stale", error.code, preview.base_version, preview,
                                        reason=error.code,
                                        current_version=error.observed_version,
                                        endpoint=preview.endpoint,
                                        submitted_sha256=submitted_sha256)
        return GeneratedEditOutcome("refused", error.code, preview.base_version, preview,
                                    reason=error.code, current_version=error.observed_version,
                                    endpoint=preview.endpoint,
                                    submitted_sha256=submitted_sha256)
    except (TimeoutError, GeneratedUiDeadlineExceeded) as error:
        # The request may or may not have been processed; never retry it.
        return GeneratedEditOutcome("timeout", str(error), preview.base_version, preview,
                                    endpoint=preview.endpoint,
                                    submitted_sha256=submitted_sha256, phase="submit")
    except GeneratedUiEndpointError as error:
        return _endpoint_outcome(preview, error.code, str(error))
    except (ConnectionError, OSError) as error:
        return _endpoint_outcome(preview, "endpoint_unavailable", str(error))
    except GeneratedUiError as error:
        return GeneratedEditOutcome("protocol_error", str(error), preview.base_version, preview,
                                    endpoint=preview.endpoint,
                                    submitted_sha256=submitted_sha256, phase="submit")

    ticket: GeneratedCandidateTicket | None = None
    try:
        ticket = reply.ticket()
    except GeneratedUiError:
        ticket = None

    if not reply.candidate_accepted:
        if reply.reason == "structure_version_conflict":
            outcome = "stale"
        else:
            outcome = "refused" if reply.reason == "none" else "rejected"
        # A synchronous refusal still allocated an attempt.  Read that ticket
        # (bounded, once) so the report is backed by the holder's record rather
        # than only by the submit envelope; the submit reason stays authoritative
        # for what was refused.  UNKNOWN from that ticket is preserved, not
        # rewritten into REJECTED.
        terminal = "UNKNOWN"
        reason = reply.reason
        path = reply.path
        reads = 0
        if ticket is not None and (deadline is None or deadline - time.monotonic() > 0):
            wait_budget = min(timeout_ms, 1_000)
            if deadline is not None:
                wait_budget = min(wait_budget, max(0, int((deadline - time.monotonic()) * 1000)))
            wait = session.wait_for_candidate_result(
                ticket, timeout_ms=wait_budget, poll_ms=poll_ms)
            reads = wait.attempted
            if wait.outcome in ("endpoint_replaced", "endpoint_unavailable"):
                return _endpoint_outcome(preview, wait.outcome,
                                         "candidate wait lost its endpoint",
                                         ticket=ticket, state=wait.last_state,
                                         phase="candidate_wait", reads=wait.attempted)
            if wait.last_state is not None:
                terminal = wait.last_state.terminal_state
                if wait.last_state.reason != "none":
                    reason = wait.last_state.reason
                if wait.last_state.path != "none":
                    path = wait.last_state.path
        return GeneratedEditOutcome(outcome, reply.describe(), preview.base_version, preview,
                                    token=reply.candidate_token, receipt=reply.receipt,
                                    terminal_state=terminal, reason=reason, path=path,
                                    current_version=reply.version_after,
                                    candidate_reads=reads,
                                    endpoint=reply.endpoint_identity or preview.endpoint,
                                    ticket=ticket, submitted_sha256=submitted_sha256,
                                    phase="submit")
    if reply.candidate_token <= 0:
        return GeneratedEditOutcome("refused", "submit reply carried no candidate ticket",
                                    preview.base_version, preview, receipt=reply.receipt,
                                    current_version=reply.version_after,
                                    endpoint=reply.endpoint_identity or preview.endpoint,
                                    submitted_sha256=submitted_sha256, phase="submit")
    if ticket is None:
        return GeneratedEditOutcome("refused", "submit reply carried no endpoint identity",
                                    preview.base_version, preview, token=reply.candidate_token,
                                    receipt=reply.receipt,
                                    endpoint=preview.endpoint,
                                    submitted_sha256=submitted_sha256, phase="submit")

    wait_budget = timeout_ms
    if deadline is not None:
        wait_budget = min(wait_budget, max(0, int((deadline - time.monotonic()) * 1000)))
    wait = session.wait_for_candidate_result(ticket, timeout_ms=wait_budget, poll_ms=poll_ms)
    accepted_at = time.monotonic()
    if wait.outcome in ("endpoint_replaced", "endpoint_unavailable"):
        return _endpoint_outcome(preview, wait.outcome, "candidate wait lost its endpoint",
                                 ticket=ticket, state=wait.last_state,
                                 phase="candidate_wait", reads=wait.attempted)
    if wait.outcome in ("timeout", "timeout_without_observation"):
        state = wait.last_state
        return timeout_outcome(
            f"candidate did not settle within {timeout_ms}ms (total budget "
            f"{total_timeout_ms}ms)" if total_timeout_ms is not None
            else f"candidate did not settle within {timeout_ms}ms",
            phase="candidate_wait", ticket=ticket, state=state, reads=wait.attempted)

    state = wait.last_state
    if state is None:
        return GeneratedEditOutcome("protocol_error", "terminal wait carried no state",
                                    preview.base_version, preview, token=ticket.token,
                                    receipt=ticket.receipt, candidate_reads=wait.attempted,
                                    endpoint=ticket.endpoint, ticket=ticket,
                                    submitted_sha256=submitted_sha256,
                                    phase="candidate_wait")
    if state.terminal_state == "SUPERSEDED":
        return GeneratedEditOutcome("superseded", "candidate was replaced before it settled",
                                    preview.base_version, preview, token=ticket.token,
                                    receipt=ticket.receipt, terminal_state=state.terminal_state,
                                    reason=state.reason, path=state.path,
                                    accepted_version=state.accepted_version,
                                    candidate_reads=wait.attempted, endpoint=ticket.endpoint,
                                    ticket=ticket, submitted_sha256=submitted_sha256,
                                    phase="candidate_wait")
    if state.terminal_state == "UNKNOWN":
        # The holder does not know whether this attempt will apply.  Do not
        # call it rejected and do not suggest that a replay is safe.
        return GeneratedEditOutcome(
            "unknown", "candidate ticket settled UNKNOWN; acceptance is not established",
            preview.base_version, preview, token=ticket.token, receipt=ticket.receipt,
            terminal_state=state.terminal_state, reason=state.reason, path=state.path,
            accepted_version=state.accepted_version, candidate_reads=wait.attempted,
            endpoint=ticket.endpoint, ticket=ticket, submitted_sha256=submitted_sha256,
            phase="candidate_wait")
    if state.terminal_state != "ACCEPTED":
        return GeneratedEditOutcome("rejected", f"candidate settled as {state.terminal_state}",
                                    preview.base_version, preview, token=ticket.token,
                                    receipt=ticket.receipt, terminal_state=state.terminal_state,
                                    reason=state.reason, path=state.path,
                                    accepted_version=state.accepted_version,
                                    candidate_reads=wait.attempted, endpoint=ticket.endpoint,
                                    ticket=ticket, submitted_sha256=submitted_sha256,
                                    phase="candidate_wait")

    submit_to_accepted = (accepted_at - started) * 1000.0
    readback_started = time.monotonic()
    try:
        snapshot = session.snapshot(deadline_monotonic=deadline)
    except (TimeoutError, GeneratedUiDeadlineExceeded) as error:
        return timeout_outcome(f"accepted ticket, but atomic readback did not complete: {error}",
                               phase="readback", ticket=ticket, state=state,
                               reads=wait.attempted)
    except GeneratedUiEndpointError as error:
        return _endpoint_outcome(preview, error.code, f"readback: {error}",
                                 ticket=ticket, state=state, phase="readback",
                                 submit_to_accepted_ms=submit_to_accepted,
                                 reads=wait.attempted)
    except (ConnectionError, OSError) as error:
        return _endpoint_outcome(preview, "endpoint_unavailable", f"readback: {error}",
                                 ticket=ticket, state=state, phase="readback",
                                 submit_to_accepted_ms=submit_to_accepted,
                                 reads=wait.attempted)
    except GeneratedUiError as error:
        return GeneratedEditOutcome("protocol_error", f"readback failed: {error}",
                                    preview.base_version, preview, token=ticket.token,
                                    receipt=ticket.receipt, terminal_state=state.terminal_state,
                                    accepted_version=state.accepted_version,
                                    submit_to_accepted_ms=submit_to_accepted,
                                    candidate_reads=wait.attempted, endpoint=ticket.endpoint,
                                    ticket=ticket, submitted_sha256=submitted_sha256,
                                    phase="readback")
    readback_ms = (time.monotonic() - readback_started) * 1000.0

    if snapshot.endpoint != ticket.endpoint:
        return GeneratedEditOutcome(
            "endpoint_replaced",
            f"accepted ticket endpoint {ticket.endpoint.describe()}, atomic readback "
            f"endpoint {snapshot.endpoint.describe()}",
            preview.base_version, preview, token=ticket.token, receipt=ticket.receipt,
            terminal_state=state.terminal_state, reason=state.reason, path=state.path,
            accepted_version=state.accepted_version,
            current_version=snapshot.accepted_structure_version,
            submit_to_accepted_ms=submit_to_accepted, readback_ms=readback_ms,
            candidate_reads=wait.attempted, endpoint=ticket.endpoint, ticket=ticket,
            submitted_sha256=submitted_sha256, phase="readback")

    accepted_structure = structure_from_snapshot(snapshot)
    try:
        accepted_instances = instances_from_snapshot(snapshot)
        facts = instance_facts(accepted_instances)
        instances_sha256 = facts["sha256"]
        instance_owners = facts["owners"]
        instance_conflicts = facts["owner_conflicts"]
        instance_keys = tuple(facts["keys"])
    except GeneratedUiError as error:
        return GeneratedEditOutcome(
            "protocol_error", f"accepted instances could not be read: {error}",
            preview.base_version, preview, token=ticket.token, receipt=ticket.receipt,
            terminal_state=state.terminal_state, reason=state.reason, path=state.path,
            accepted_version=state.accepted_version,
            current_version=accepted_structure.version,
            submit_to_accepted_ms=submit_to_accepted, readback_ms=readback_ms,
            candidate_reads=wait.attempted, endpoint=ticket.endpoint, ticket=ticket,
            submitted_sha256=submitted_sha256,
            expected_structure_sha256=preview.expected_structure_sha256,
            phase="readback")
    exact = _exact_document_readback(preview.nodes, preview.expected_compositions,
                                     accepted_structure)
    version_mismatch = None
    if state.accepted_version > 0 and snapshot.accepted_structure_version != state.accepted_version:
        version_mismatch = (f"ticket accepted version {state.accepted_version}, atomic snapshot "
                            f"accepted version {snapshot.accepted_structure_version}")
    if reply.candidate_version > 0 and state.accepted_version > 0 and \
            reply.candidate_version != state.accepted_version:
        version_mismatch = (f"submit promised candidate version {reply.candidate_version}, "
                            f"ticket accepted version {state.accepted_version}")
    if state.accepted_then_replaced:
        return GeneratedEditOutcome(
            "replaced_after_accept",
            "the candidate was accepted and then replaced by a later structure",
            preview.base_version, preview, token=ticket.token, receipt=ticket.receipt,
            terminal_state=state.terminal_state, reason=state.reason, path=state.path,
            accepted_version=state.accepted_version, current_version=accepted_structure.version,
            exact_readback=exact, submit_to_accepted_ms=submit_to_accepted,
            readback_ms=readback_ms, candidate_reads=wait.attempted,
            accepted_structure=accepted_structure, endpoint=ticket.endpoint, ticket=ticket,
            submitted_sha256=submitted_sha256,
            expected_structure_sha256=preview.expected_structure_sha256,
            instances_sha256=instances_sha256, instance_owners=instance_owners,
            instance_owner_conflicts=instance_conflicts, instance_keys=instance_keys,
            phase="readback")
    if not exact or version_mismatch is not None:
        return GeneratedEditOutcome(
            "readback_mismatch",
            version_mismatch or "atomic snapshot structure does not match the expected "
                                "complete accepted state",
            preview.base_version, preview, token=ticket.token, receipt=ticket.receipt,
            terminal_state=state.terminal_state, reason=state.reason, path=state.path,
            accepted_version=state.accepted_version, current_version=accepted_structure.version,
            exact_readback=exact, submit_to_accepted_ms=submit_to_accepted,
            readback_ms=readback_ms, candidate_reads=wait.attempted,
            accepted_structure=accepted_structure, endpoint=ticket.endpoint, ticket=ticket,
            submitted_sha256=submitted_sha256,
            expected_structure_sha256=preview.expected_structure_sha256,
            instances_sha256=instances_sha256, instance_owners=instance_owners,
            instance_owner_conflicts=instance_conflicts, instance_keys=instance_keys,
            phase="readback")
    return GeneratedEditOutcome(
        "accepted", f"accepted v{preview.base_version}->v{accepted_structure.version} and "
                    f"read back atomically and exactly", preview.base_version, preview,
        token=ticket.token, receipt=ticket.receipt, terminal_state=state.terminal_state,
        reason=state.reason, path=state.path,
        accepted_version=state.accepted_version or accepted_structure.version,
        current_version=accepted_structure.version, exact_readback=True,
        submit_to_accepted_ms=submit_to_accepted, readback_ms=readback_ms,
        candidate_reads=wait.attempted, accepted_structure=accepted_structure,
        endpoint=ticket.endpoint, ticket=ticket, submitted_sha256=submitted_sha256,
        expected_structure_sha256=preview.expected_structure_sha256,
        instances_sha256=instances_sha256, instance_owners=instance_owners,
        instance_owner_conflicts=instance_conflicts, instance_keys=instance_keys,
        phase="readback")


def submit_plan(session: GeneratedUiSession, plan: GeneratedEditPlan, *,
                capabilities: GeneratedCapabilities | None = None,
                timeout_ms: int = 5_000, poll_ms: int = 25,
                total_timeout_ms: int | None = None) -> GeneratedEditOutcome:
    """Read ONE atomic snapshot, preview locally, then submit that preview.

    `total_timeout_ms`, when supplied, starts before the initial snapshot and is
    the only budget shared by snapshot, submit, candidate wait and readback.
    `timeout_ms` keeps its original candidate-wait meaning.
    """
    started = time.monotonic()
    deadline = None if total_timeout_ms is None else started + total_timeout_ms / 1000.0
    snapshot, failure = _read_snapshot(session, plan.base_version, deadline)
    if failure is not None:
        return failure
    structure = structure_from_snapshot(snapshot)
    try:
        preview = preview_plan(structure, plan, capabilities, endpoint=snapshot.endpoint)
    except GeneratedEditError as error:
        if error.code == "stale_base_version":
            return GeneratedEditOutcome("stale", error.detail, plan.base_version, None,
                                        current_version=structure.version,
                                        endpoint=snapshot.endpoint)
        raise
    return submit_preview(session, preview, timeout_ms=timeout_ms, poll_ms=poll_ms,
                          total_timeout_ms=_remaining_total_ms(deadline))


SAVED_PLAN_FORMAT = "cjgui.generated-edit.plan"
SAVED_RECEIPT_FORMAT = "cjgui.generated-edit.receipt"
SAVED_FORMAT_VERSION = 1


@dataclass(frozen=True)
class SavedEditPlan:
    """A versioned, file-safe plan bound to one endpoint and baseline.

    The digest is a consistency check, not authorization.  No credential or
    token is stored: the descriptor remains the caller's endpoint input.
    """

    endpoint: GeneratedEndpointIdentity
    base_version: int
    base_structure_sha256: str
    plan: GeneratedEditPlan
    preview: Mapping[str, Any]
    expected_structure_sha256: str = ""
    submitted_sha256: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "format": SAVED_PLAN_FORMAT,
            "format_version": SAVED_FORMAT_VERSION,
            "endpoint": _endpoint_dict(self.endpoint),
            "base_version": self.base_version,
            "base_structure_sha256": self.base_structure_sha256,
            "expected_structure_sha256": self.expected_structure_sha256,
            "submitted_sha256": self.submitted_sha256,
            "plan": self.plan.to_dict(),
            "preview": dict(self.preview),
        }


def _json_object(text: str, what: str) -> Mapping[str, Any]:
    try:
        value = json.loads(text)
    except json.JSONDecodeError as error:
        raise GeneratedEditError("invalid_plan", f"{what} is not valid JSON: {error}") from error
    if not isinstance(value, Mapping):
        raise GeneratedEditError("invalid_plan", f"{what} must be a JSON object")
    return value


def saved_plan_from_preview(plan: GeneratedEditPlan,
                            preview: GeneratedEditPreview) -> SavedEditPlan:
    if preview.endpoint is None:
        raise GeneratedEditError(
            "missing_endpoint", "a saved plan requires an atomic snapshot endpoint identity")
    return SavedEditPlan(preview.endpoint, preview.base_version,
                         preview.base_structure_sha256, plan, preview.to_dict(),
                         expected_structure_sha256=preview.expected_structure_sha256,
                         submitted_sha256=preview.submitted_sha256)


def _parse_saved_plan(value: Mapping[str, Any]) -> SavedEditPlan:
    required = {"format", "format_version", "endpoint", "base_version",
                "base_structure_sha256", "plan", "preview"}
    allowed = required | {"expected_structure_sha256", "submitted_sha256"}
    _strict_keys(value, allowed, "saved plan")
    _require_keys(value, required, "saved plan")
    if value["format"] != SAVED_PLAN_FORMAT:
        raise GeneratedEditError("invalid_saved_plan",
                                 f"unknown saved plan format {value['format']!r}")
    if value["format_version"] != SAVED_FORMAT_VERSION or isinstance(value["format_version"], bool):
        raise GeneratedEditError("invalid_saved_plan",
                                 f"unsupported saved plan version {value['format_version']!r}")
    endpoint = _endpoint_from_json(value["endpoint"], "saved plan")
    base_version = _strict_int(value["base_version"], "saved plan.base_version")
    if base_version < 0:
        raise GeneratedEditError("invalid_saved_plan", "saved plan.base_version is negative")
    digest = value["base_structure_sha256"]
    if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise GeneratedEditError("invalid_saved_plan",
                                 "saved plan.base_structure_sha256 is not a sha256 hex digest")

    def optional_digest(name: str) -> str:
        raw = value.get(name, "")
        if raw != "" and (not isinstance(raw, str) or
                          not re.fullmatch(r"[0-9a-f]{64}", raw)):
            raise GeneratedEditError("invalid_saved_plan",
                                     f"saved plan.{name} is not a sha256 hex digest")
        return raw

    expected_digest = optional_digest("expected_structure_sha256")
    submitted_digest = optional_digest("submitted_sha256")
    plan = edit_plan_from_dict(value["plan"])
    if plan.base_version != base_version:
        raise GeneratedEditError("invalid_saved_plan",
                                 "saved plan base_version and embedded plan disagree")
    preview = value["preview"]
    if not isinstance(preview, Mapping):
        raise GeneratedEditError("invalid_saved_plan", "saved plan.preview must be an object")
    for key in ("local_only", "base_version", "endpoint", "base_structure_sha256",
                "operations", "diff", "nodes"):
        if key not in preview:
            raise GeneratedEditError("invalid_saved_plan",
                                     f"saved plan.preview is missing {key}")
    if preview["local_only"] is not True:
        raise GeneratedEditError("invalid_saved_plan", "saved plan preview must be local_only")
    if preview["base_version"] != base_version:
        raise GeneratedEditError("invalid_saved_plan",
                                 "saved plan preview base_version disagrees")
    if preview["base_structure_sha256"] != digest:
        raise GeneratedEditError("invalid_saved_plan",
                                 "saved plan preview digest disagrees")
    preview_endpoint = _endpoint_from_json(preview["endpoint"], "saved plan.preview")
    if preview_endpoint != endpoint:
        raise GeneratedEditError("invalid_saved_plan",
                                 "saved plan preview endpoint disagrees")
    if expected_digest and preview.get("expected_structure_sha256") != expected_digest:
        raise GeneratedEditError("invalid_saved_plan",
                                 "saved plan expected state digest disagrees with preview")
    if submitted_digest and preview.get("submitted_sha256") != submitted_digest:
        raise GeneratedEditError("invalid_saved_plan",
                                 "saved plan candidate digest disagrees with preview")
    return SavedEditPlan(endpoint, base_version, digest, plan, preview,
                         expected_structure_sha256=expected_digest,
                         submitted_sha256=submitted_digest)


def load_plan_document(text: str) -> tuple[GeneratedEditPlan, SavedEditPlan | None]:
    """Load either the original raw plan or the versioned saved-plan document."""
    value = _json_object(text, "plan")
    if value.get("format") == SAVED_PLAN_FORMAT:
        saved = _parse_saved_plan(value)
        return saved.plan, saved
    if "format" in value:
        raise GeneratedEditError("invalid_saved_plan",
                                 f"unknown plan format {value.get('format')!r}")
    return edit_plan_from_dict(value), None


def _canonical_diff(value: Any) -> dict[str, Any] | None:
    """Order-insensitive diff view for saved-plan comparison.

    Saved v1 plans may carry diff lists in the older hash-seed order. Ordering
    is not semantic for this readable diff, so both sides are sorted; the items
    themselves must still match exactly, and unknown keys are not ignored.
    """
    if not isinstance(value, Mapping):
        return None
    string_lists = ("added", "removed", "reordered_parents", "binding_changes", "lines")
    object_lists = ("moved", "property_changes", "declaration_changes")
    known = set(string_lists) | set(object_lists)
    normalized: dict[str, Any] = {}
    try:
        for name in string_lists:
            items = value.get(name, [])
            if not isinstance(items, list) or any(not isinstance(item, str) for item in items):
                return None
            normalized[name] = sorted(items)
        for name in object_lists:
            items = value.get(name, [])
            if not isinstance(items, list):
                return None
            normalized[name] = sorted(
                items, key=lambda item: json.dumps(item, ensure_ascii=False,
                                                  sort_keys=True, default=str))
        extra = set(value) - known
        if extra:
            normalized["$extra"] = sorted(extra)
    except (TypeError, ValueError):
        return None
    return normalized


def _verify_saved_plan(saved: SavedEditPlan, snapshot: GeneratedSnapshot,
                       capabilities: GeneratedCapabilities | None) -> GeneratedEditPreview:
    if snapshot.endpoint != saved.endpoint:
        raise GeneratedEditError(
            "endpoint_replaced",
            f"saved plan endpoint {saved.endpoint.describe()}, current snapshot "
            f"{snapshot.endpoint.describe()}")
    structure = structure_from_snapshot(snapshot)
    digest = structure_document_digest(structure)
    if structure.version != saved.base_version or digest != saved.base_structure_sha256:
        raise GeneratedEditError(
            "stale_base_version",
            f"saved plan expects v{saved.base_version} {saved.base_structure_sha256[:12]}..., "
            f"current is v{structure.version} {digest[:12]}...")
    preview = preview_plan(structure, saved.plan, capabilities, endpoint=snapshot.endpoint)
    expected_nodes = [_node_dict(node) for node in preview.nodes]
    saved_diff = _canonical_diff(saved.preview.get("diff"))
    current_diff = _canonical_diff(preview.diff.to_dict())
    expected_compositions = [_composition_dict(item) for item in preview.expected_compositions]
    expected_candidates = [_composition_dict(item) for item in preview.candidate_compositions]
    full_state_mismatch = (
        ("compositions" in saved.preview and
         saved.preview.get("compositions") != expected_compositions) or
        ("candidate_compositions" in saved.preview and
         saved.preview.get("candidate_compositions") != expected_candidates) or
        ("removals" in saved.preview and
         saved.preview.get("removals") != list(preview.removals)) or
        ("expected_format_version" in saved.preview and
         saved.preview.get("expected_format_version") != preview.expected_format_version) or
        (saved.expected_structure_sha256 != "" and
         saved.expected_structure_sha256 != preview.expected_structure_sha256) or
        (saved.submitted_sha256 != "" and
         saved.submitted_sha256 != preview.submitted_sha256))
    if saved.preview.get("nodes") != expected_nodes or \
            saved.preview.get("operations") != list(preview.operations) or \
            saved_diff is None or saved_diff != current_diff or \
            full_state_mismatch or \
            saved.preview.get("endpoint") != _endpoint_dict(snapshot.endpoint):
        raise GeneratedEditError(
            "saved_preview_mismatch",
            "the saved preview is not the preview of this plan against the saved baseline, "
            "or its complete expected state/digests disagree")
    return preview


def preview_saved_plan(session: GeneratedUiSession, saved: SavedEditPlan,
                       capabilities: GeneratedCapabilities | None = None, *,
                       total_timeout_ms: int | None = None) -> GeneratedEditPreview:
    """Public local preview of a saved plan against the CURRENT endpoint.

    The endpoint identity, baseline version/digest and stored preview are all
    checked; callers do not need `_verify_saved_plan`.  A snapshot deadline is
    reported as `timeout`, never as an endpoint or protocol failure.
    """
    if total_timeout_ms is not None and total_timeout_ms < 0:
        raise ValueError("total_timeout_ms must be >= 0")
    deadline = None if total_timeout_ms is None \
        else time.monotonic() + total_timeout_ms / 1000.0
    snapshot, failure = _read_snapshot(session, saved.base_version, deadline)
    if failure is not None:
        raise GeneratedEditError(failure.outcome, failure.detail)
    return _verify_saved_plan(saved, snapshot, capabilities)


def apply_saved_plan(session: GeneratedUiSession, saved: SavedEditPlan,
                     capabilities: GeneratedCapabilities | None = None, *,
                     timeout_ms: int = 5_000, poll_ms: int = 25,
                     total_timeout_ms: int | None = None) -> GeneratedEditOutcome:
    """One public execution path for a saved plan, guards included.

    The initial snapshot is part of `total_timeout_ms`; `timeout_ms` remains the
    candidate-wait budget.  A changed endpoint/baseline is reported, not rebased
    or replayed, and no private helper is required from the caller.
    """
    if timeout_ms < 0 or poll_ms <= 0 or (total_timeout_ms is not None and total_timeout_ms < 0):
        raise ValueError("wait bounds are invalid")
    started = time.monotonic()
    deadline = None if total_timeout_ms is None else started + total_timeout_ms / 1000.0
    snapshot, failure = _read_snapshot(session, saved.base_version, deadline)
    if failure is not None:
        return failure
    try:
        preview = _verify_saved_plan(saved, snapshot, capabilities)
    except GeneratedEditError as error:
        if error.code == "endpoint_replaced":
            return GeneratedEditOutcome(
                "endpoint_replaced", error.detail, saved.base_version, None,
                current_version=snapshot.accepted_structure_version,
                endpoint=snapshot.endpoint, phase="snapshot")
        if error.code == "stale_base_version":
            return GeneratedEditOutcome(
                "stale", error.detail, saved.base_version, None,
                current_version=snapshot.accepted_structure_version,
                endpoint=snapshot.endpoint, phase="snapshot")
        raise
    return submit_preview(session, preview, timeout_ms=timeout_ms, poll_ms=poll_ms,
                          total_timeout_ms=_remaining_total_ms(deadline))


def apply_saved_plan_document(session: GeneratedUiSession, text: str,
                              capabilities: GeneratedCapabilities | None = None, *,
                              timeout_ms: int = 5_000, poll_ms: int = 25,
                              total_timeout_ms: int | None = None) -> GeneratedEditOutcome:
    """Load a versioned saved-plan document and execute it via `apply_saved_plan`."""
    _plan, saved = load_plan_document(text)
    if saved is None:
        raise GeneratedEditError("invalid_saved_plan",
                                 "this document is a raw plan, not a saved plan")
    return apply_saved_plan(session, saved, capabilities, timeout_ms=timeout_ms,
                            poll_ms=poll_ms, total_timeout_ms=total_timeout_ms)


def write_json_file(path: str | Path, value: Mapping[str, Any]) -> None:
    target = Path(path)
    target.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                      encoding="utf-8")


@dataclass(frozen=True)
class SavedEditReceipt:
    endpoint: GeneratedEndpointIdentity
    ticket: GeneratedCandidateTicket
    submitted_structure: str
    submitted_sha256: str
    base_version: int
    expected_structure_sha256: str = ""


def receipt_from_outcome(outcome: GeneratedEditOutcome) -> dict[str, Any] | None:
    """A complete ticket plus the exact submitted payload, or None before a ticket.

    The endpoint identity is an opaque instance label, not an auth credential;
    no key, bearer token or bearer secret is written.
    """
    if outcome.ticket is None or outcome.preview is None or outcome.preview.document is None:
        return None
    payload = encode_generated_structure_document(outcome.preview.document)
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    return {
        "format": SAVED_RECEIPT_FORMAT,
        "format_version": SAVED_FORMAT_VERSION,
        "endpoint": _endpoint_dict(outcome.ticket.endpoint),
        "ticket": {
            "token": outcome.ticket.token,
            "receipt": outcome.ticket.receipt,
            "endpoint": _endpoint_dict(outcome.ticket.endpoint),
            "base_version": outcome.ticket.base_version,
            "candidate_version": outcome.ticket.candidate_version,
        },
        "base_version": outcome.base_version,
        "submitted_structure": payload,
        "submitted_sha256": digest,
        "expected_structure_sha256": (outcome.expected_structure_sha256
                                      or outcome.preview.expected_structure_sha256),
        "last": {
            "outcome": outcome.outcome,
            "terminal_state": outcome.terminal_state,
            "reason": outcome.reason,
            "path": outcome.path,
            "accepted_version": outcome.accepted_version,
            "exact_readback": outcome.exact_readback,
            "phase": outcome.phase,
        },
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }


def _parse_receipt(value: Mapping[str, Any]) -> SavedEditReceipt:
    allowed = {"format", "format_version", "endpoint", "ticket", "base_version",
               "submitted_structure", "submitted_sha256", "expected_structure_sha256",
               "last", "created_at"}
    _strict_keys(value, allowed, "receipt")
    _require_keys(value, {"format", "format_version", "endpoint", "ticket", "base_version",
                          "submitted_structure", "submitted_sha256"}, "receipt")
    if value["format"] != SAVED_RECEIPT_FORMAT or \
            value["format_version"] != SAVED_FORMAT_VERSION or \
            isinstance(value["format_version"], bool):
        raise GeneratedEditError("invalid_receipt", "receipt format/version is not supported")
    endpoint = _endpoint_from_json(value["endpoint"], "receipt")
    ticket = value["ticket"]
    if not isinstance(ticket, Mapping):
        raise GeneratedEditError("invalid_receipt", "receipt.ticket must be an object")
    _strict_keys(ticket, {"token", "receipt", "endpoint", "base_version", "candidate_version"},
                 "receipt.ticket")
    _require_keys(ticket, {"token", "receipt", "endpoint", "base_version",
                           "candidate_version"}, "receipt.ticket")
    token = _strict_int(ticket["token"], "receipt.ticket.token")
    if token <= 0:
        raise GeneratedEditError("invalid_receipt", "receipt.ticket.token must be positive")
    receipt_text = ticket["receipt"]
    if not isinstance(receipt_text, str) or not receipt_text or receipt_text == "none":
        raise GeneratedEditError("invalid_receipt", "receipt.ticket.receipt is missing")
    ticket_endpoint = _endpoint_from_json(ticket["endpoint"], "receipt.ticket")
    if ticket_endpoint != endpoint:
        raise GeneratedEditError("invalid_receipt", "receipt ticket endpoint disagrees")
    base_version = _strict_int(ticket["base_version"], "receipt.ticket.base_version")
    candidate_version = _strict_int(ticket["candidate_version"],
                                    "receipt.ticket.candidate_version")
    if base_version < 0 or candidate_version < 0:
        raise GeneratedEditError("invalid_receipt", "receipt ticket versions are negative")
    if value["base_version"] != base_version:
        raise GeneratedEditError("invalid_receipt", "receipt base_version disagrees")
    payload = value["submitted_structure"]
    if not isinstance(payload, str) or not payload:
        raise GeneratedEditError("invalid_receipt", "receipt.submitted_structure is missing")
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    if value["submitted_sha256"] != digest:
        raise GeneratedEditError("invalid_receipt", "receipt submitted digest disagrees")
    expected = value.get("expected_structure_sha256", "")
    if expected != "" and (not isinstance(expected, str) or
                           not re.fullmatch(r"[0-9a-f]{64}", expected)):
        raise GeneratedEditError("invalid_receipt",
                                 "receipt expected_structure_sha256 is not a sha256 digest")
    return SavedEditReceipt(endpoint, GeneratedCandidateTicket(
        token, receipt_text, ticket_endpoint, base_version, candidate_version),
        payload, digest, base_version, expected_structure_sha256=expected)


def load_receipt_document(text: str) -> SavedEditReceipt:
    return _parse_receipt(_json_object(text, "receipt"))


def _receipt_nodes(saved: SavedEditReceipt) -> tuple[GeneratedNode, ...]:
    return _parse_structure_text(saved.submitted_structure).nodes


@dataclass(frozen=True)
class GeneratedEditQuery:
    """Read-only status/resume result for an already submitted ticket."""

    mode: str
    outcome: str
    detail: str
    terminal_state: str
    reason: str = "none"
    path: str = "none"
    accepted_version: int | None = None
    current_version: int | None = None
    exact_readback: bool = False
    endpoint: GeneratedEndpointIdentity | None = None
    submitted_sha256: str = ""
    expected_structure_sha256: str = ""
    instances_sha256: str = ""
    instance_owners: dict[str, int] = field(default_factory=dict)
    instance_owner_conflicts: dict[str, list[int]] = field(default_factory=dict)
    instance_keys: tuple[str, ...] = ()
    accepted_structure: GeneratedStructure | None = None
    elapsed_ms: float | None = None

    def to_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "mode": self.mode,
            "outcome": self.outcome,
            "detail": self.detail,
            "terminal_state": self.terminal_state,
            "reason": self.reason,
            "path": self.path,
            "accepted_version": self.accepted_version,
            "current_version": self.current_version,
            "exact_readback": self.exact_readback,
            "endpoint": _endpoint_dict(self.endpoint),
            "submitted_sha256": self.submitted_sha256,
            "expected_structure_sha256": self.expected_structure_sha256,
            "instances_sha256": self.instances_sha256,
            "instance_owners": dict(sorted(self.instance_owners.items())),
            "instance_owner_conflicts": dict(sorted(self.instance_owner_conflicts.items())),
            "instance_keys": list(self.instance_keys),
            "elapsed_ms": self.elapsed_ms,
        }
        if self.accepted_structure is not None:
            result["accepted_structure"] = {
                "version": self.accepted_structure.version,
                "candidate_version": self.accepted_structure.candidate_version,
                "scene_state": self.accepted_structure.scene_state,
                "compositions": [_composition_dict(item)
                                 for item in self.accepted_structure.compositions],
                "nodes": [_node_dict(node) for node in self.accepted_structure.nodes],
            }
        return result


def _query_from_state(session: GeneratedUiSession, saved: SavedEditReceipt,
                      state: GeneratedCandidateState, *, mode: str,
                      deadline: float | None, started: float) -> GeneratedEditQuery:
    accepted_version = state.accepted_version or None
    elapsed = (time.monotonic() - started) * 1000.0
    if state.terminal_state != "ACCEPTED":
        outcome = {"REJECTED": "rejected", "SUPERSEDED": "superseded",
                   "UNKNOWN": "unknown", "PENDING": "pending"}.get(
                       state.terminal_state, "protocol_error")
        return GeneratedEditQuery(mode, outcome, f"candidate state {state.terminal_state}",
                                  state.terminal_state, state.reason, state.path,
                                  accepted_version=accepted_version,
                                  endpoint=saved.endpoint,
                                  submitted_sha256=saved.submitted_sha256,
                                  elapsed_ms=elapsed)
    try:
        snapshot = session.snapshot(deadline_monotonic=deadline)
    except (TimeoutError, GeneratedUiDeadlineExceeded) as error:
        return GeneratedEditQuery(mode, "timeout", f"atomic readback: {error}",
                                  state.terminal_state, state.reason, state.path,
                                  accepted_version=accepted_version,
                                  endpoint=saved.endpoint,
                                  submitted_sha256=saved.submitted_sha256,
                                  elapsed_ms=elapsed)
    except GeneratedUiEndpointError as error:
        return GeneratedEditQuery(
            mode, "endpoint_replaced" if error.code == "endpoint_replaced"
            else "endpoint_unavailable", str(error), state.terminal_state,
            state.reason, state.path, accepted_version=accepted_version,
            endpoint=saved.endpoint, submitted_sha256=saved.submitted_sha256,
            elapsed_ms=elapsed)
    except (ConnectionError, OSError) as error:
        return GeneratedEditQuery(mode, "endpoint_unavailable", str(error),
                                  state.terminal_state, state.reason, state.path,
                                  accepted_version=accepted_version,
                                  endpoint=saved.endpoint,
                                  submitted_sha256=saved.submitted_sha256,
                                  elapsed_ms=elapsed)
    except GeneratedUiError as error:
        return GeneratedEditQuery(mode, "protocol_error", str(error),
                                  state.terminal_state, state.reason, state.path,
                                  accepted_version=accepted_version,
                                  endpoint=saved.endpoint,
                                  submitted_sha256=saved.submitted_sha256,
                                  elapsed_ms=elapsed)
    if snapshot.endpoint != saved.endpoint:
        return GeneratedEditQuery(
            mode, "endpoint_replaced",
            f"ticket endpoint {saved.endpoint.describe()}, snapshot "
            f"{snapshot.endpoint.describe()}", state.terminal_state, state.reason,
            state.path, accepted_version=accepted_version,
            current_version=snapshot.accepted_structure_version,
            endpoint=saved.endpoint, submitted_sha256=saved.submitted_sha256,
            elapsed_ms=elapsed)
    structure = structure_from_snapshot(snapshot)
    expected_digest = saved.expected_structure_sha256 or saved.submitted_sha256
    exact = False
    if structure.lossless:
        try:
            exact = structure_document_digest(structure) == expected_digest
        except GeneratedEditError:
            exact = False
    try:
        facts = instance_facts(instances_from_snapshot(snapshot))
    except GeneratedUiError as error:
        # The ticket is already ACCEPTED; the atomic snapshot's instance section
        # is unreadable. That is a named protocol failure, not an empty catalog:
        # keep the observed ticket state/version and never re-submit.
        return GeneratedEditQuery(
            mode, "protocol_error",
            f"accepted instances could not be read: {error}",
            state.terminal_state, state.reason, state.path,
            accepted_version=accepted_version,
            current_version=snapshot.accepted_structure_version,
            exact_readback=False, endpoint=saved.endpoint,
            submitted_sha256=saved.submitted_sha256,
            expected_structure_sha256=expected_digest,
            accepted_structure=structure, elapsed_ms=elapsed)
    mismatch = None
    if state.accepted_version > 0 and snapshot.accepted_structure_version != state.accepted_version:
        mismatch = (f"ticket accepted version {state.accepted_version}, snapshot "
                    f"accepted version {snapshot.accepted_structure_version}")
    if saved.ticket.candidate_version > 0 and state.accepted_version > 0 and \
            saved.ticket.candidate_version != state.accepted_version:
        mismatch = (f"ticket candidate version {saved.ticket.candidate_version}, "
                    f"ticket accepted version {state.accepted_version}")
    common = dict(
        expected_structure_sha256=expected_digest,
        instances_sha256=facts["sha256"],
        instance_owners=facts["owners"],
        instance_owner_conflicts=facts["owner_conflicts"],
        instance_keys=tuple(facts["keys"]))
    if state.accepted_then_replaced:
        return GeneratedEditQuery(
            mode, "replaced_after_accept",
            "the candidate was accepted and then replaced by a later structure",
            state.terminal_state, state.reason, state.path,
            accepted_version=accepted_version, current_version=structure.version,
            exact_readback=exact, endpoint=saved.endpoint,
            submitted_sha256=saved.submitted_sha256,
            accepted_structure=structure, elapsed_ms=elapsed, **common)
    if not exact or mismatch is not None:
        return GeneratedEditQuery(
            mode, "readback_mismatch",
            mismatch or "atomic snapshot does not match the expected complete accepted state",
            state.terminal_state, state.reason, state.path,
            accepted_version=accepted_version, current_version=structure.version,
            exact_readback=exact, endpoint=saved.endpoint,
            submitted_sha256=saved.submitted_sha256,
            accepted_structure=structure, elapsed_ms=elapsed, **common)
    return GeneratedEditQuery(
        mode, "accepted", f"ticket and atomic snapshot agree at v{structure.version}",
        state.terminal_state, state.reason, state.path,
        accepted_version=accepted_version or structure.version,
        current_version=structure.version, exact_readback=True,
        endpoint=saved.endpoint, submitted_sha256=saved.submitted_sha256,
        accepted_structure=structure, elapsed_ms=elapsed, **common)


def query_receipt(session: GeneratedUiSession, saved: SavedEditReceipt, *,
                  mode: str = "status", timeout_ms: int = 1_000, poll_ms: int = 25,
                  total_timeout_ms: int | None = None) -> GeneratedEditQuery:
    """Query the ORIGINAL ticket.  Never calls submit.

    `status` performs one bounded candidate read.  `resume` waits on the same
    ticket; neither mode replays the request.  An accepted answer is verified
    against the receipt's exact submitted structure in one atomic snapshot.
    """
    if mode not in ("status", "resume"):
        raise ValueError("query mode must be status or resume")
    if timeout_ms < 0 or poll_ms <= 0 or (total_timeout_ms is not None and total_timeout_ms < 0):
        raise ValueError("query wait bounds are invalid")
    started = time.monotonic()
    deadline = None if total_timeout_ms is None else started + total_timeout_ms / 1000.0

    def elapsed() -> float:
        return (time.monotonic() - started) * 1000.0

    if deadline is not None and deadline - time.monotonic() <= 0:
        return GeneratedEditQuery(mode, "timeout", "total budget expired before the query",
                                  "UNKNOWN", endpoint=saved.endpoint,
                                  submitted_sha256=saved.submitted_sha256, elapsed_ms=elapsed())
    if mode == "status":
        try:
            state = session.candidate_state(saved.ticket.token, endpoint=saved.ticket.endpoint,
                                            deadline_monotonic=deadline)
        except (TimeoutError, GeneratedUiDeadlineExceeded) as error:
            return GeneratedEditQuery(mode, "timeout", str(error), "UNKNOWN",
                                      endpoint=saved.endpoint,
                                      submitted_sha256=saved.submitted_sha256,
                                      elapsed_ms=elapsed())
        except GeneratedUiEndpointError as error:
            return GeneratedEditQuery(
                mode, "endpoint_replaced" if error.code == "endpoint_replaced"
                else "endpoint_unavailable", str(error), "UNKNOWN",
                endpoint=saved.endpoint, submitted_sha256=saved.submitted_sha256,
                elapsed_ms=elapsed())
        except (ConnectionError, OSError) as error:
            return GeneratedEditQuery(mode, "endpoint_unavailable", str(error), "UNKNOWN",
                                      endpoint=saved.endpoint,
                                      submitted_sha256=saved.submitted_sha256,
                                      elapsed_ms=elapsed())
        except GeneratedUiError as error:
            return GeneratedEditQuery(mode, "protocol_error", str(error), "UNKNOWN",
                                      endpoint=saved.endpoint,
                                      submitted_sha256=saved.submitted_sha256,
                                      elapsed_ms=elapsed())
        return _query_from_state(session, saved, state, mode=mode, deadline=deadline,
                                 started=started)

    wait_budget = timeout_ms
    if deadline is not None:
        wait_budget = min(wait_budget, max(0, int((deadline - time.monotonic()) * 1000)))
    wait = session.wait_for_candidate_result(saved.ticket, timeout_ms=wait_budget,
                                             poll_ms=poll_ms)
    if wait.outcome in ("endpoint_replaced", "endpoint_unavailable"):
        return GeneratedEditQuery(mode, wait.outcome, "candidate wait lost its endpoint",
                                  "UNKNOWN", endpoint=saved.endpoint,
                                  submitted_sha256=saved.submitted_sha256,
                                  elapsed_ms=elapsed())
    if wait.outcome in ("timeout", "timeout_without_observation"):
        state = wait.last_state
        return GeneratedEditQuery(
            mode, "timeout", f"candidate did not settle within {timeout_ms}ms",
            state.terminal_state if state is not None else "UNKNOWN",
            state.reason if state is not None else "none",
            state.path if state is not None else "none",
            accepted_version=state.accepted_version if state is not None and state.accepted_version else None,
            endpoint=saved.endpoint, submitted_sha256=saved.submitted_sha256,
            elapsed_ms=elapsed())
    state = wait.last_state
    if state is None:
        return GeneratedEditQuery(mode, "protocol_error", "terminal wait carried no state",
                                  "UNKNOWN", endpoint=saved.endpoint,
                                  submitted_sha256=saved.submitted_sha256,
                                  elapsed_ms=elapsed())
    return _query_from_state(session, saved, state, mode=mode, deadline=deadline,
                             started=started)


def query_exit_code(query: GeneratedEditQuery) -> int:
    return {
        "accepted": EXIT_ACCEPTED,
        "pending": EXIT_ACCEPTED,
        "rejected": EXIT_REJECTED,
        "superseded": EXIT_REJECTED,
        "replaced_after_accept": EXIT_REJECTED,
        "unknown": EXIT_UNKNOWN,
        "timeout": EXIT_TIMEOUT,
        "endpoint_replaced": EXIT_ENDPOINT,
        "endpoint_unavailable": EXIT_ENDPOINT,
        "readback_mismatch": EXIT_PROTOCOL,
        "protocol_error": EXIT_PROTOCOL,
    }.get(query.outcome, EXIT_PROTOCOL)


def _initial_diff(root: EditNode) -> GeneratedEditDiff:
    nodes = root.to_generated_nodes()
    lines = tuple(f"+ {node.key} ({node.kind}) at depth {node.depth}" for node in nodes)
    return GeneratedEditDiff(tuple(node.key for node in nodes), (), (), (), (), (), lines)


def initialize_preview(snapshot: GeneratedSnapshot,
                       root_or_nodes: EditNode | Sequence[GeneratedNode],
                       capabilities: GeneratedCapabilities | None = None) -> GeneratedEditPreview:
    """Preview the FIRST structure of an empty generated region.

    Only a genuinely empty accepted region (v0, no nodes) is initialized; an
    existing structure is never overwritten implicitly and must be edited by
    key through a normal plan.
    """
    structure = structure_from_snapshot(snapshot)
    if structure.nodes or structure.version != 0:
        raise GeneratedEditError(
            "structure_not_empty",
            f"generated region is not empty (v{structure.version}, "
            f"{len(structure.nodes)} nodes); edit it by key instead of initializing")
    if not structure.lossless:
        raise GeneratedEditError(
            "composition_document_not_lossless",
            "the empty snapshot already carries content this client did not understand; "
            "initializing would replace it with a pruned document")
    if structure.format_version not in (1, 2):
        raise GeneratedEditError(
            "structure_format_unsupported",
            f"accepted structure format {structure.format_version} is not initialized by "
            f"this client")
    root = root_or_nodes if isinstance(root_or_nodes, EditNode) \
        else tree_from_nodes(tuple(root_or_nodes))
    runtime_kinds = frozenset(composition.name for composition in structure.compositions)
    _validate_tree(root, capabilities, runtime_kinds)
    nodes = generated_nodes_of(root)
    expected_compositions = structure.compositions
    expected_format = 2 if expected_compositions else 1
    format_version = 2 if structure.format_version == 2 else 1
    document = GeneratedStructureDocument(format_version, (), nodes)
    try:
        submitted_payload = encode_generated_structure_document(document)
    except GeneratedUiError as error:
        raise GeneratedEditError("wire_encoding", str(error)) from error
    expected_structure = GeneratedStructure(
        structure.version + 1, structure.candidate_version, structure.scene_state, nodes,
        format_version=expected_format, compositions=expected_compositions)
    return GeneratedEditPreview(
        structure.version, structure.candidate_version, structure.scene_state,
        root, nodes, _initial_diff(root),
        (f"initialize {root.key} ({root.kind}) with {len(nodes)} nodes",),
        endpoint=snapshot.endpoint,
        base_structure_sha256=structure_document_digest(structure),
        document=document, expected_compositions=expected_compositions,
        candidate_compositions=(), removals=(),
        submitted_sha256=hashlib.sha256(submitted_payload.encode("utf-8")).hexdigest(),
        expected_structure_sha256=structure_document_digest(expected_structure),
        expected_format_version=expected_format)


def initialize_structure(session: GeneratedUiSession,
                         root_or_nodes: EditNode | Sequence[GeneratedNode],
                         capabilities: GeneratedCapabilities | None = None, *,
                         timeout_ms: int = 5_000, poll_ms: int = 25,
                         total_timeout_ms: int | None = None) -> GeneratedEditOutcome:
    """Initialize an empty generated region through the same submit path."""
    if timeout_ms < 0 or poll_ms <= 0 or (total_timeout_ms is not None and total_timeout_ms < 0):
        raise ValueError("wait bounds are invalid")
    started = time.monotonic()
    deadline = None if total_timeout_ms is None else started + total_timeout_ms / 1000.0
    snapshot, failure = _read_snapshot(session, 0, deadline)
    if failure is not None:
        return failure
    preview = initialize_preview(snapshot, root_or_nodes, capabilities)
    return submit_preview(session, preview, timeout_ms=timeout_ms, poll_ms=poll_ms,
                          total_timeout_ms=_remaining_total_ms(deadline))


def initialize_root_from_document(text: str) -> EditNode:
    value = _json_object(text, "initialization")
    _strict_keys(value, {"node"}, "initialization")
    _require_keys(value, {"node"}, "initialization")
    return edit_node_from_dict(value["node"])


def outcome_exit_code(outcome: GeneratedEditOutcome) -> int:
    return {
        "accepted": EXIT_ACCEPTED,
        "stale": EXIT_STALE,
        "rejected": EXIT_REJECTED,
        "superseded": EXIT_REJECTED,
        "replaced_after_accept": EXIT_REJECTED,
        "unknown": EXIT_UNKNOWN,
        "refused": EXIT_REJECTED,
        "timeout": EXIT_TIMEOUT,
        "endpoint_replaced": EXIT_ENDPOINT,
        "endpoint_unavailable": EXIT_ENDPOINT,
        "readback_mismatch": EXIT_PROTOCOL,
        "protocol_error": EXIT_PROTOCOL,
    }.get(outcome.outcome, EXIT_PROTOCOL)


# --- CLI ---------------------------------------------------------------------

def _read_text(path: str, what: str) -> str:
    if path == "-":
        return sys.stdin.read()
    try:
        return Path(path).read_text(encoding="utf-8")
    except OSError as error:
        raise GeneratedEditError("invalid_plan", f"cannot read {what} {path}: {error}") from error


def _edit_error_exit(error: GeneratedEditError) -> int:
    return {
        "stale_base_version": EXIT_STALE,
        "stale_base_structure": EXIT_STALE,
        "endpoint_replaced": EXIT_ENDPOINT,
        "endpoint_unavailable": EXIT_ENDPOINT,
        "timeout": EXIT_TIMEOUT,
        "snapshot_timeout": EXIT_TIMEOUT,
        "structure_not_empty": EXIT_INVALID_PLAN,
        "saved_preview_mismatch": EXIT_INVALID_PLAN,
        "invalid_saved_plan": EXIT_INVALID_PLAN,
        "invalid_receipt": EXIT_INVALID_PLAN,
        "missing_endpoint": EXIT_INVALID_PLAN,
    }.get(error.code, EXIT_INVALID_PLAN)


def _print_outcome(outcome: GeneratedEditOutcome, as_json: bool) -> None:
    if as_json:
        print(json.dumps(outcome.to_dict(), ensure_ascii=False, indent=2, sort_keys=True))
        return
    print(f"SUBMIT outcome={outcome.outcome} phase={outcome.phase} "
          f"base_version={outcome.base_version} accepted_version={outcome.accepted_version} "
          f"token={outcome.token} terminal={outcome.terminal_state} "
          f"reason={outcome.reason} exact_readback={int(outcome.exact_readback)} "
          f"endpoint={outcome.endpoint.describe() if outcome.endpoint else 'unknown'}")
    if outcome.submit_to_accepted_ms is not None:
        print(f"TIMING submit_to_accepted_ms={outcome.submit_to_accepted_ms:.1f} "
              f"readback_ms={outcome.readback_ms or 0:.1f} "
              f"candidate_reads={outcome.candidate_reads}")
    if outcome.outcome != "accepted":
        print(f"DETAIL {outcome.detail}")


def _print_query(query: GeneratedEditQuery, as_json: bool) -> None:
    if as_json:
        print(json.dumps(query.to_dict(), ensure_ascii=False, indent=2, sort_keys=True))
        return
    print(f"QUERY mode={query.mode} outcome={query.outcome} "
          f"terminal={query.terminal_state} reason={query.reason} "
          f"accepted_version={query.accepted_version} current_version={query.current_version} "
          f"exact_readback={int(query.exact_readback)} "
          f"endpoint={query.endpoint.describe() if query.endpoint else 'unknown'} "
          f"submitted_sha256={query.submitted_sha256}")
    if query.elapsed_ms is not None:
        print(f"TIMING query_ms={query.elapsed_ms:.1f}")
    if query.outcome != "accepted":
        print(f"DETAIL {query.detail}")


def client_format_support() -> dict[str, Any]:
    """Formats understood by THIS client, distinct from endpoint capabilities.

    This is a local product statement, not a fact published by the application.
    An endpoint that does not publish CHOICE or runtime-composite facts keeps
    them absent from its capability projection rather than being labeled through
    this client's development state.
    """
    return {
        "source": "cjgui_generated_edit",
        "structure_editing": "supported_format_1_and_2",
        "choice_discovery": "supported_v1",
        "runtime_composite_input": "supported_v2_definitions_instances_end_remove",
        "runtime_composite_losslessness": "lossless_or_named_refusal",
        "runtime_composite_editing":
            "supported_stable_keys_batch_per_published_budget_nested_compose",
        "runtime_composite_readback": "supported_complete_accepted_catalog_atomic_snapshot",
        "runtime_composite_instances": "supported_read_only_atomic_owner_facts",
        "ui_document_history": "optional_v1_session_bounded_cas_no_text_undo",
        "note": ("CHOICE v1 rows are parsed as published current facts; unknown "
                 "versions/encodings stay unsupported_by_client and are never turned "
                 "into options. An accepted snapshot may hold several definitions; a "
                 "candidate may update as many definitions as the endpoint's published "
                 "COMPOSITION_BUDGET allows and/or list explicit removals, plus any "
                 "number of node edits. Definitions may reference each other through "
                 "bounded acyclic compose= nodes; unknown/cyclic references and "
                 "still-referenced removals are named refusals. A node-only candidate "
                 "against a format-2 region omits definitions and keeps the accepted "
                 "catalog. The preview keeps the complete expected catalog and its "
                 "normalized digest separate from the candidate delta digest."),
    }


def _capabilities_dict(capabilities: GeneratedCapabilities) -> dict[str, Any]:
    """Lossless projection of the typed capability discovery.

    Every field is copied from `GeneratedCapabilities` and its dataclasses; no
    constraint, encoding, element, resource or support fact is inferred or
    dropped.  A fact the endpoint did not publish stays absent/empty.  The
    separate `client` section comes from this tool, not from the endpoint.
    """
    return {
        "client": client_format_support(),
        "ui_document_history": (asdict(capabilities.ui_document_history)
                                if capabilities.ui_document_history is not None else None),
        "bounds": {
            "max_depth": capabilities.max_depth,
            "max_nodes": capabilities.max_nodes,
            "max_properties_per_node": capabilities.max_properties_per_node,
            "max_string_length": capabilities.max_string_length,
        },
        "components": [
            {
                "kind": component.kind,
                "allows_children": component.allows_children,
                "child_limit": component.child_limit,
                "properties": [
                    {"name": prop.name, "type": prop.value_type, "required": prop.required,
                     "min": prop.minimum, "max": prop.maximum, "max_length": prop.max_length,
                     "values": list(prop.values), "default": prop.default,
                     "encoding": prop.encoding, "unit": prop.unit,
                     "value_range": prop.value_range, "semantics": prop.semantics,
                     "stability": prop.stability, "backend_support": prop.backend_support}
                    for prop in component.properties
                ],
            }
            for component in capabilities.components
        ],
        "composites": [
            {"kind": composite.kind, "children": composite.children,
             "child_limit": composite.child_limit, "expanded_nodes": composite.expanded_nodes,
             "expanded_depth": composite.expanded_depth}
            for composite in capabilities.composites
        ],
        "elements": [
            {"kind": element.kind, "element_key": element.element_key,
             "role": element.role, "parent": element.parent,
             "field_id": element.field_id, "argument": element.argument,
             "preset": element.preset, "action": element.action, "label": element.label}
            for element in capabilities.elements
        ],
        "actions": [
            {"name": action.name, "label": action.label,
             "arguments": list(action.arguments)}
            for action in capabilities.actions
        ],
        "fields": [
            {"field_id": field.field_id, "editor_kind": field.editor_kind,
             "resource_id": field.resource_id, "writer": field.writer,
             "required": field.required, "min": field.minimum, "max": field.maximum,
             "max_length": field.max_length, "callable": field.callable,
             "argument": field.argument, "input_kind": field.input_kind,
             "label": field.label}
            for field in capabilities.fields
        ],
        "choice_format": None if capabilities.choice_format is None else {
            "version": capabilities.choice_format.version,
            "encoding": capabilities.choice_format.encoding,
            "fields": list(capabilities.choice_format.fields),
            "state": capabilities.choice_format.state,
            "detail": capabilities.choice_format.detail,
        },
        "choice_options": [
            {"field_id": option.field_id, "key": option.key, "value": option.value,
             "enabled": option.enabled, "disabled_reason": option.disabled_reason,
             "label": option.label}
            for option in capabilities.choice_options
        ],
        "image_resources": [
            {"key": resource.key, "content_type": resource.content_type,
             "version": resource.version, "name": resource.name}
            for resource in capabilities.image_resources
        ],
        "window_background": None if capabilities.window_background is None else {
            "name": capabilities.window_background.name,
            "type": capabilities.window_background.value_type,
            "root_only": capabilities.window_background.root_only,
            "values": list(capabilities.window_background.values),
            "default": capabilities.window_background.default,
            "omitted": capabilities.window_background.omitted,
            "stability": capabilities.window_background.stability,
            "backend_support": capabilities.window_background.backend_support,
        },
        "font_resources": [
            {"key": resource.key, "version": resource.version,
             "state": resource.state, "resolved_family": resource.resolved_family,
             "name": resource.name}
            for resource in capabilities.font_resources
        ],
        "surface": None if capabilities.surface is None else {
            "version": capabilities.surface.version,
            "stability": capabilities.surface.stability,
            "compatibility": capabilities.surface.compatibility,
            "protocol": capabilities.surface.protocol,
            "subset": list(capabilities.surface.subset),
            "extra": [{"name": name, "value": value}
                      for name, value in capabilities.surface.extra],
        },
        "support": [
            {"kind": fact.kind, "item": fact.item, "state": fact.state,
             "reason": fact.reason, "source": fact.source}
            for fact in capabilities.support
        ],
        "evidence": [
            {"item": fact.item, "state": fact.state, "reason": fact.reason}
            for fact in capabilities.evidence
        ],
    }


def _capabilities_text(capabilities: GeneratedCapabilities) -> str:
    """Text view of the SAME projection as `--json` (one fact set, two views)."""
    data = _capabilities_dict(capabilities)
    bounds = data["bounds"]
    lines = [
        f"BOUNDS depth={bounds['max_depth']} nodes={bounds['max_nodes']} "
        f"properties={bounds['max_properties_per_node']} "
        f"stringLength={bounds['max_string_length']}",
        f"COMPONENTS {len(data['components'])} FIELDS {len(data['fields'])} "
        f"ACTIONS {len(data['actions'])} COMPOSITES {len(data['composites'])} "
        f"ELEMENTS {len(data['elements'])} IMAGES {len(data['image_resources'])} "
        f"FONTS {len(data['font_resources'])} SUPPORT {len(data['support'])} "
        f"EVIDENCE {len(data['evidence'])}",
    ]
    if data["surface"] is not None:
        lines.append("SURFACE " + json.dumps(data["surface"], ensure_ascii=False,
                                               sort_keys=True, separators=(",", ":")))
    lines.append("CLIENT_FORMATS " + json.dumps(
        data["client"], ensure_ascii=False, sort_keys=True,
        separators=(",", ":")))
    if data["choice_format"] is None:
        lines.append("CHOICE_FORMAT absent")
    else:
        lines.append("CHOICE_FORMAT " + json.dumps(
            data["choice_format"], ensure_ascii=False, sort_keys=True,
            separators=(",", ":")))
    for option in data["choice_options"]:
        lines.append("CHOICE_OPTION " + json.dumps(
            option, ensure_ascii=False, sort_keys=True, separators=(",", ":")))
    for component in data["components"]:
        base = {key: component[key] for key in ("kind", "allows_children", "child_limit")}
        lines.append("COMPONENT " + json.dumps(base, ensure_ascii=False, sort_keys=True,
                                               separators=(",", ":")))
        for prop in component["properties"]:
            lines.append(f"PROPERTY {component['kind']} " +
                         json.dumps(prop, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":")))
    for composite in data["composites"]:
        lines.append("COMPOSITE " + json.dumps(composite, ensure_ascii=False, sort_keys=True,
                                               separators=(",", ":")))
    for element in data["elements"]:
        lines.append("ELEMENT " + json.dumps(element, ensure_ascii=False, sort_keys=True,
                                             separators=(",", ":")))
    for field in data["fields"]:
        lines.append("FIELD " + json.dumps(field, ensure_ascii=False, sort_keys=True,
                                           separators=(",", ":")))
    for action in data["actions"]:
        lines.append("ACTION " + json.dumps(action, ensure_ascii=False, sort_keys=True,
                                            separators=(",", ":")))
    for resource in data["image_resources"]:
        lines.append("IMAGE " + json.dumps(resource, ensure_ascii=False, sort_keys=True,
                                           separators=(",", ":")))
    if data["window_background"] is not None:
        lines.append("WINDOW_BACKGROUND " + json.dumps(
            data["window_background"], ensure_ascii=False, sort_keys=True,
            separators=(",", ":")))
    for resource in data["font_resources"]:
        lines.append("FONT " + json.dumps(resource, ensure_ascii=False, sort_keys=True,
                                          separators=(",", ":")))
    for fact in data["support"]:
        lines.append("SUPPORT " + json.dumps(fact, ensure_ascii=False, sort_keys=True,
                                             separators=(",", ":")))
    for fact in data["evidence"]:
        lines.append("EVIDENCE " + json.dumps(fact, ensure_ascii=False, sort_keys=True,
                                              separators=(",", ":")))
    return "\n".join(lines)


def _print_error(error: GeneratedEditError, as_json: bool) -> None:
    if as_json:
        print(json.dumps({"outcome": "invalid_plan", "code": error.code,
                          "detail": error.detail}, ensure_ascii=False, sort_keys=True))
    print(f"ERROR {error.code}: {error}", file=sys.stderr)


def _print_snapshot_failure(outcome: GeneratedEditOutcome, as_json: bool) -> None:
    if as_json:
        print(json.dumps({"outcome": outcome.outcome, "code": outcome.outcome,
                          "detail": outcome.detail}, ensure_ascii=False, sort_keys=True))
    print(f"ERROR {outcome.outcome}: {outcome.detail}", file=sys.stderr)


def run_cli(argv: Sequence[str], *, session_factory=GeneratedUiSession.connect) -> int:
    parser = argparse.ArgumentParser(
        prog="cjgui_generated_edit.py",
        description="Read, preview, save, submit and query key-addressed edits of the "
                    "accepted runtime-generated UI structure.")
    parser.add_argument("descriptor", help="application-issued shared operation descriptor")
    parser.add_argument("command", choices=("capabilities", "show", "preview", "apply",
                                            "init", "status", "resume", "ui-export",
                                            "ui-import", "ui-apply", "ui-history", "ui-undo", "ui-redo"))
    parser.add_argument("input", nargs="?",
                        help="plan/init JSON (or - for stdin) or a saved receipt")
    parser.add_argument("--json", action="store_true", help="machine-readable output")
    parser.add_argument("--timeout-ms", type=int, default=5_000,
                        help="candidate settlement/query budget (default 5000; total is separate)")
    parser.add_argument("--total-timeout-ms", type=int, default=None,
                        help="optional overall budget for apply/init/status/resume")
    parser.add_argument("--poll-ms", type=int, default=25,
                        help="candidate poll interval (default 25)")
    parser.add_argument("--save-plan", metavar="PATH",
                        help="write the versioned plan with endpoint, baseline digest and preview")
    parser.add_argument("--save-receipt", metavar="PATH",
                        help="write the complete candidate ticket and submitted structure")
    parser.add_argument("--replace-definitions", action="store_true",
                        help="ui-import: also remove accepted definitions the document omits")
    parser.add_argument("--apply", action="store_true",
                        help="ui-import: submit the previewed import instead of stopping at preview")
    parser.add_argument("--save-import-plan", metavar="PATH",
                        help="ui-import: save the endpoint/baseline-bound import plan")
    try:
        args = parser.parse_args(list(argv))
    except SystemExit as error:
        return int(error.code or EXIT_USAGE)
    if args.command in ("preview", "apply", "init", "status", "resume", "ui-export",
                        "ui-import", "ui-apply", "ui-undo", "ui-redo") and not args.input:
        print(f"usage: {parser.prog} DESCRIPTOR {args.command} INPUT.json", file=sys.stderr)
        return EXIT_USAGE
    if args.replace_definitions and args.command not in ("ui-import", "ui-apply"):
        print("--replace-definitions is supported by ui-import and ui-apply", file=sys.stderr)
        return EXIT_USAGE
    if args.apply and args.command != "ui-import":
        print("--apply is supported by ui-import", file=sys.stderr)
        return EXIT_USAGE
    if args.save_import_plan and args.command not in ("ui-import", "ui-apply"):
        print("--save-import-plan is supported by ui-import and ui-apply", file=sys.stderr)
        return EXIT_USAGE
    if args.timeout_ms < 0 or args.poll_ms <= 0 or \
            (args.total_timeout_ms is not None and args.total_timeout_ms < 0):
        print("timeout-ms/total-timeout-ms must be >= 0 and poll-ms must be > 0",
              file=sys.stderr)
        return EXIT_USAGE
    if args.save_plan and args.command not in ("preview", "apply"):
        print("--save-plan is supported by preview and apply", file=sys.stderr)
        return EXIT_USAGE
    if args.save_receipt and args.command not in ("apply", "init", "ui-import", "ui-apply"):
        print("--save-receipt is supported by apply, init, ui-import and ui-apply",
              file=sys.stderr)
        return EXIT_USAGE

    try:
        session = session_factory(args.descriptor)
    except (GeneratedUiError, OSError) as error:
        print(f"ERROR connect: {error}", file=sys.stderr)
        return EXIT_ENDPOINT

    try:
        if args.command in ("ui-history", "ui-undo", "ui-redo"):
            if args.command == "ui-history":
                result = asdict(session.history_state())
                code = EXIT_ACCEPTED
            else:
                # Use the caller's saved observation verbatim; never refresh
                # its CAS into a different operation or replay a refusal.
                baseline_text = sys.stdin.read() if args.input == "-" else Path(args.input).read_text()
                try:
                    baseline_value = json.loads(baseline_text)
                except json.JSONDecodeError as error:
                    raise GeneratedUiHistoryRefusal("ui_document_history_baseline_invalid") from error
                baseline = history_state_from_dict(baseline_value)
                submitted = session.history_action(args.command[3:], baseline)
                result = {"baseline": asdict(baseline), "submit": asdict(submitted),
                          "phase": "candidate_pending" if submitted.candidate_accepted else "refused",
                          "accepted": False, "presented": None}
                code = EXIT_UNKNOWN if submitted.candidate_accepted else EXIT_REJECTED
            if args.json:
                print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
            else:
                print(json.dumps(result, ensure_ascii=False))
            return code

        if args.command == "capabilities":
            capabilities = session.capabilities()
            if args.json:
                print(json.dumps(_capabilities_dict(capabilities), ensure_ascii=False,
                                 indent=2, sort_keys=True))
            else:
                print(_capabilities_text(capabilities))
            return EXIT_ACCEPTED

        if args.command == "show":
            snapshot, failure = _read_snapshot(session, 0, None)
            if failure is not None:
                _print_snapshot_failure(failure, args.json)
                return outcome_exit_code(failure)
            structure = structure_from_snapshot(snapshot)
            if structure.lossless:
                digest = structure_document_digest(structure)
                document = encode_generated_structure_document(
                    structure_document(structure), allow_multiple=True)
            else:
                # Read-only display of the original body; no digest is claimed
                # for a document this client could not parse completely.
                digest = None
                document = structure.source_text
            if args.json:
                print(json.dumps({
                    "endpoint": _endpoint_dict(snapshot.endpoint),
                    "version": structure.version,
                    "candidate_version": structure.candidate_version,
                    "scene_state": structure.scene_state,
                    "format_version": structure.format_version,
                    "lossless": structure.lossless,
                    "base_structure_sha256": digest,
                    "composition_readback": (
                        "lossy_unknown_content" if not structure.lossless
                        else "supported" if structure.compositions
                        else "not_present"),
                    "compositions": [_composition_dict(item)
                                     for item in structure.compositions],
                    "nodes": [_node_dict(node) for node in structure.nodes],
                    "document": document,
                }, ensure_ascii=False, indent=2, sort_keys=True))
            else:
                print(f"ENDPOINT {snapshot.endpoint.describe()}")
                print(f"STRUCTURE_VERSION {structure.version}")
                print(f"CANDIDATE_VERSION {structure.candidate_version}")
                print(f"SCENE_STATE {structure.scene_state}")
                print(f"STRUCTURE_FORMAT {structure.format_version}")
                print(f"DOCUMENT_LOSSLESS {1 if structure.lossless else 0}")
                print("COMPOSITION_READBACK "
                      + ("lossy_unknown_content" if not structure.lossless
                         else "supported" if structure.compositions
                         else "not_present"))
                print(f"COMPOSITIONS {len(structure.compositions)}")
                print("BASE_STRUCTURE_SHA256 "
                      + (digest if digest is not None else "unavailable_not_lossless"))
                print(document)
            return EXIT_ACCEPTED

        if args.command in ("ui-export", "ui-import", "ui-apply"):
            # Imported lazily: the file wrapper depends on this module's typed
            # plan/preview API, and this CLI only needs it for these commands.
            import cjgui_ui_document as ui

            if args.command == "ui-export":
                snapshot, failure = _read_snapshot(session, 0, None)
                if failure is not None:
                    _print_snapshot_failure(failure, args.json)
                    return outcome_exit_code(failure)
                document = ui.ui_document_from_snapshot(snapshot)
                ui.write_ui_document(args.input, document)
                if args.json:
                    print(json.dumps({
                        "document": str(args.input),
                        "format": ui.UI_DOCUMENT_FORMAT,
                        "format_version": ui.UI_DOCUMENT_VERSION,
                        "structure_sha256": document.structure_sha256,
                        "compositions": list(document.requirements.runtime_compositions),
                        "nodes": len(document.structure_document().nodes),
                    }, ensure_ascii=False, indent=2, sort_keys=True))
                else:
                    print(f"UI_DOCUMENT {args.input}")
                    print(f"FORMAT {ui.UI_DOCUMENT_FORMAT} v{ui.UI_DOCUMENT_VERSION}")
                    print(f"STRUCTURE_SHA256 {document.structure_sha256}")
                    print("COMPOSITIONS "
                          + (",".join(document.requirements.runtime_compositions) or "-"))
                    print(f"NODES {len(document.structure_document().nodes)}")
                return EXIT_ACCEPTED

            capabilities = session.capabilities()
            snapshot, failure = _read_snapshot(session, 0, None)
            if failure is not None:
                _print_snapshot_failure(failure, args.json)
                return outcome_exit_code(failure)
            if args.command == "ui-apply":
                import_plan = ui.parse_saved_ui_import_plan(
                    _read_text(args.input, "import plan"))
                preview = ui.apply_saved_ui_import(snapshot, import_plan, capabilities)
                document = import_plan.document
                replace_definitions = import_plan.replace_definitions
            else:
                document = ui.read_ui_document(args.input)
                replace_definitions = args.replace_definitions
                preview = ui.preview_ui_import(
                    snapshot, document, capabilities,
                    replace_definitions=replace_definitions)
            if not args.json:
                print(preview.to_text())
            else:
                print(json.dumps(preview.to_dict(), ensure_ascii=False, indent=2,
                                 sort_keys=True))
            if args.save_import_plan:
                write_json_file(args.save_import_plan, ui.saved_ui_import_plan(
                    preview, document, replace_definitions=replace_definitions).to_dict())
                if not args.json:
                    print(f"SAVED_IMPORT_PLAN {args.save_import_plan}")
            if args.command == "ui-import" and not args.apply:
                return EXIT_ACCEPTED
            outcome = submit_preview(session, preview, timeout_ms=args.timeout_ms,
                                     poll_ms=args.poll_ms,
                                     total_timeout_ms=args.total_timeout_ms)
            _print_outcome(outcome, args.json)
            if args.save_receipt:
                receipt = receipt_from_outcome(outcome)
                if receipt is None:
                    print("RECEIPT unavailable: no candidate ticket was allocated",
                          file=sys.stderr)
                else:
                    write_json_file(args.save_receipt, receipt)
                    if not args.json:
                        print(f"SAVED_RECEIPT {args.save_receipt} token={outcome.token} "
                              f"sha256={outcome.submitted_sha256}")
            return outcome_exit_code(outcome)

        if args.command in ("status", "resume"):
            receipt = load_receipt_document(_read_text(args.input, "receipt"))
            query = query_receipt(session, receipt, mode=args.command,
                                  timeout_ms=args.timeout_ms, poll_ms=args.poll_ms,
                                  total_timeout_ms=args.total_timeout_ms)
            _print_query(query, args.json)
            return query_exit_code(query)

        capabilities = session.capabilities()
        if args.command == "init":
            root = initialize_root_from_document(_read_text(args.input, "init plan"))
            outcome = initialize_structure(session, root, capabilities=capabilities,
                                           timeout_ms=args.timeout_ms, poll_ms=args.poll_ms,
                                           total_timeout_ms=args.total_timeout_ms)
            preview = outcome.preview
        else:
            plan, saved = load_plan_document(_read_text(args.input, "plan"))
            if args.command == "preview":
                if saved is not None:
                    preview = preview_saved_plan(
                        session, saved, capabilities,
                        total_timeout_ms=args.total_timeout_ms)
                else:
                    snapshot, failure = _read_snapshot(session, plan.base_version, None)
                    if failure is not None:
                        _print_snapshot_failure(failure, args.json)
                        return outcome_exit_code(failure)
                    preview = preview_plan(structure_from_snapshot(snapshot), plan,
                                           capabilities, endpoint=snapshot.endpoint)
                if not args.json:
                    print(preview.to_text())
                else:
                    print(json.dumps(preview.to_dict(), ensure_ascii=False, indent=2,
                                     sort_keys=True))
                if args.save_plan:
                    write_json_file(args.save_plan,
                                    saved_plan_from_preview(plan, preview).to_dict())
                    if not args.json:
                        print(f"SAVED_PLAN {args.save_plan}")
                return EXIT_ACCEPTED
            if saved is not None:
                outcome = apply_saved_plan(session, saved, capabilities=capabilities,
                                           timeout_ms=args.timeout_ms, poll_ms=args.poll_ms,
                                           total_timeout_ms=args.total_timeout_ms)
            else:
                outcome = submit_plan(session, plan, capabilities=capabilities,
                                      timeout_ms=args.timeout_ms, poll_ms=args.poll_ms,
                                      total_timeout_ms=args.total_timeout_ms)
            preview = outcome.preview
            if preview is not None and args.save_plan:
                write_json_file(args.save_plan,
                                saved_plan_from_preview(plan, preview).to_dict())
                if not args.json:
                    print(f"SAVED_PLAN {args.save_plan}")

        if preview is not None and not args.json:
            print(preview.to_text())
        _print_outcome(outcome, args.json)
        if outcome.outcome == "stale":
            print(f"ERROR stale_base_version: {outcome.detail}", file=sys.stderr)
        if args.save_receipt:
            receipt = receipt_from_outcome(outcome)
            if receipt is None:
                print("RECEIPT unavailable: no candidate ticket was allocated",
                      file=sys.stderr)
            else:
                write_json_file(args.save_receipt, receipt)
                if not args.json:
                    print(f"SAVED_RECEIPT {args.save_receipt} "
                          f"token={outcome.token} sha256={outcome.submitted_sha256}")
        return outcome_exit_code(outcome)
    except GeneratedUiHistoryRefusal as error:
        result = {"phase": "refused", "reason": error.code, "submitted": False,
                  "accepted": False, "presented": None}
        print(json.dumps(result, ensure_ascii=False, indent=2 if args.json else None))
        return EXIT_REJECTED
    except GeneratedEditError as error:
        _print_error(error, args.json)
        return _edit_error_exit(error)
    except GeneratedUiEndpointError as error:
        if args.json and args.command in ("ui-history", "ui-undo", "ui-redo"):
            print(json.dumps({"phase": "unknown", "reason": error.code, "detail": str(error),
                              "submitted": None, "accepted": None, "presented": None}))
        else:
            print(f"ERROR endpoint {error.code}: {error}", file=sys.stderr)
        return EXIT_ENDPOINT
    except (ConnectionError, OSError) as error:
        if args.json and args.command in ("ui-history", "ui-undo", "ui-redo"):
            print(json.dumps({"phase": "unknown", "reason": "endpoint_unavailable", "detail": str(error),
                              "submitted": None, "accepted": None, "presented": None}))
        else:
            print(f"ERROR endpoint unavailable: {error}", file=sys.stderr)
        return EXIT_ENDPOINT
    except GeneratedUiError as error:
        if args.json and args.command in ("ui-history", "ui-undo", "ui-redo"):
            print(json.dumps({"phase": "unknown", "reason": getattr(error, "code", "history_protocol_unknown"),
                              "detail": str(error), "submitted": None, "accepted": None, "presented": None}))
        else:
            print(f"ERROR protocol: {error}", file=sys.stderr)
        return EXIT_PROTOCOL
    finally:
        close = getattr(session, "close", None)
        if callable(close):
            close()


def main(argv: Sequence[str] | None = None) -> int:
    return run_cli(sys.argv[1:] if argv is None else argv)


if __name__ == "__main__":
    sys.exit(main())
