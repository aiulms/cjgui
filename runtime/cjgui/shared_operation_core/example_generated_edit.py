#!/usr/bin/env python3
"""Run public runtime-edit chains against a live application endpoint.

Default (no flags) keeps the original node chain: layout property, insert,
reorder, stale CAS refusal, restore, owner check.

Composition mode (all targets are caller-supplied; nothing business-specific is
built into this file):

  1. `--composition-spec spec.json --save-plan plan.json` discovers the
     published component/field/action/choice facts and the current accepted
     definitions + instance owners, validates the spec against them, builds ONE
     candidate (one definition + node/instance edits) through
     `edit.preview_plan`, and saves the versioned plan with both digests.
  2. `--apply-saved-plan plan.json --save-receipt receipt.json` applies that
     plan from a NEW process through `edit.apply_saved_plan`; the endpoint still
     decides acceptance and the exact readback.
  3. `--status-receipt receipt.json` / `--resume-receipt receipt.json` query
     the ORIGINAL ticket without resubmitting.
  4. `--remove-spec spec.json --save-plan plan.json` builds an explicit
     `COMPOSITION_REMOVE` + node-deletion candidate.

Spec example (fields/actions/instances are data, not hard-coded here):

    {
      "name": "runtimePresetCard",
      "parameters": [{"name": "title", "type": "STRING", "required": false,
                      "min": 0, "max": 40, "max_length": 40, "default": ""}],
      "elements": [
        {"key": "name", "role": "field", "field": "jobName", "argument": "text"},
        {"key": "duplex", "role": "field", "field": "duplex", "presentation": "select"},
        {"key": "apply", "role": "action", "action": "APPLY_DRAFT", "label": "应用"}
      ],
      "reuse_nodes": [{"key": "cardA", "properties": {"title": "卡片 A"}}],
      "new_instances": [{"key": "card03", "parent": "preset-layout",
                         "properties": {"title": "卡片 03"}}]
    }

Removal spec: `{"definitions": ["runtimeAltCard"], "nodes": ["card03"]}`.

Every local preview is explicitly local until the ownership ticket says the
endpoint accepted it. No private validator, owner copy or second plan protocol
is used here.

Usage:
    python3 example_generated_edit.py DESCRIPTOR [--json] [--skip-owner-check]
    python3 example_generated_edit.py DESCRIPTOR --inspect [--json]
    python3 example_generated_edit.py DESCRIPTOR --composition-spec SPEC.json \
        [--save-plan PLAN.json] [--json]
    python3 example_generated_edit.py DESCRIPTOR --remove-spec SPEC.json \
        [--save-plan PLAN.json] [--json]
    python3 example_generated_edit.py DESCRIPTOR --apply-saved-plan PLAN.json \
        [--save-receipt RECEIPT.json] [--json]
    python3 example_generated_edit.py DESCRIPTOR --status-receipt RECEIPT.json [--json]
    python3 example_generated_edit.py DESCRIPTOR --resume-receipt RECEIPT.json [--json]
"""

from __future__ import annotations

from dataclasses import asdict

import json
import sys
from pathlib import Path

from cjgui_generated_client import (
    GeneratedNode,
    GeneratedProperty,
    GeneratedUiError,
    GeneratedUiSession,
    same_structure,
)
import cjgui_generated_edit as edit

_LAYOUT_PROPERTIES = ("gap", "padding", "spacing", "contentGap", "spacingX", "spacingY")
_SAMPLE_TEXT = "运行时编辑示例"


def _seed_initial_structure(session, capabilities):
    """Create the first accepted structure through the public edit API.

    The same encoding, validation and candidate submission as every other edit
    are used.  An already accepted structure is never overwritten: this returns
    it untouched and the chain continues by stable key.
    """
    snapshot = session.snapshot()
    structure = edit.structure_from_snapshot(snapshot)
    if structure.nodes:
        return structure, False
    root_kind = "vertical" if capabilities.component("vertical") else next(
        (component.kind for component in capabilities.components if component.allows_children), None)
    _require(root_kind is not None, "the application publishes no container component")
    root_component = capabilities.component(root_kind)
    root_props = {}
    for name in _LAYOUT_PROPERTIES:
        spec = next((prop for prop in root_component.properties if prop.name == name), None)
        if spec is not None and spec.value_type == "INTEGER" and (
                spec.maximum <= spec.minimum or spec.minimum <= 4 <= spec.maximum):
            root_props[name] = "4"
            break

    leaf = _find_leaf(capabilities)
    _require(leaf is not None, "the application publishes no plain text leaf kind")
    nodes = [GeneratedNode(0, "seed-root", root_kind, None, None,
                           tuple(GeneratedProperty(name, value)
                                 for name, value in root_props.items()))]
    nodes.append(GeneratedNode(1, "seed-title", leaf[1], None, None,
                               (GeneratedProperty("text", leaf[2]),)))
    for field in capabilities.fields:
        if field.callable and capabilities.component(field.input_kind):
            label = next((prop for prop in capabilities.component(field.input_kind).properties
                          if prop.name == "label"), None)
            properties = (() if label is None else
                          (GeneratedProperty("label", field.label),))
            nodes.append(GeneratedNode(1, f"seed-field-{field.field_id}", field.input_kind,
                                       field.field_id, None, properties))
            break
    if capabilities.component("action"):
        for action in capabilities.actions:
            label = next((prop for prop in capabilities.component("action").properties
                          if prop.name == "label"), None)
            properties = (() if label is None else
                          (GeneratedProperty("label", action.label or action.name),))
            nodes.append(GeneratedNode(1, "seed-action", "action", None, action.name,
                                       properties))
            break
    nodes.append(GeneratedNode(1, "seed-note", leaf[1], None, None,
                               (GeneratedProperty("text", "Seed note"),)))

    outcome = edit.initialize_structure(session, nodes, capabilities)
    _require(outcome.outcome == "accepted" and outcome.exact_readback and
             outcome.accepted_structure is not None,
             f"initial structure was refused: {outcome.outcome} {outcome.detail}")
    return outcome.accepted_structure, True


def _find_property(capabilities, root):
    """Pick one optional integer layout property that can move by one."""
    component = capabilities.component(root.kind)
    if component is None:
        return None
    ordered = sorted(component.properties,
                     key=lambda prop: (_LAYOUT_PROPERTIES.index(prop.name)
                                       if prop.name in _LAYOUT_PROPERTIES else 99, prop.name))
    for prop in ordered:
        if prop.required or prop.value_type != "INTEGER":
            continue
        current = root.property(prop.name)
        if current == "":
            continue
        try:
            value = int(current)
        except ValueError:
            continue
        bounded = prop.maximum > prop.minimum
        if bounded and not (prop.minimum <= value <= prop.maximum):
            continue
        new_value = value + 1 if not bounded or value + 1 <= prop.maximum else value - 1
        if bounded and not (prop.minimum <= new_value <= prop.maximum):
            continue
        return prop.name, current, str(new_value)
    return None


def _find_leaf(capabilities):
    """A published leaf kind we can fill from its own declarations alone."""
    candidates = []
    for component in capabilities.components:
        if component.allows_children:
            continue
        text = next((prop for prop in component.properties if prop.name == "text"), None)
        if text is None or text.value_type != "STRING" or text.encoding or text.values:
            continue
        if any(prop.required and prop.name != "text" for prop in component.properties):
            continue
        if "input" in component.kind.lower() or component.kind.lower() == "action":
            continue
        sample = _SAMPLE_TEXT
        if text.max_length > 0 and len(sample.encode("utf-8")) > text.max_length:
            sample = "Edit"
        if text.max_length > 0 and len(sample.encode("utf-8")) > text.max_length:
            sample = "A"
        if text.max_length > 0 and len(sample.encode("utf-8")) > text.max_length:
            continue
        rank = 0 if component.kind == "label" else 1
        candidates.append((rank, component.kind, sample))
    return min(candidates) if candidates else None


def _choose_parent(capabilities, root):
    """Insert under the root when it has room; otherwise the first container with room."""
    queue = [root]
    while queue:
        node = queue.pop(0)
        component = capabilities.component(node.kind)
        if component is not None and component.allows_children:
            limit = component.child_limit
            if limit == 0 or len(node.children) < limit:
                return node
        queue.extend(node.children)
    return None


def _choose_reorder(parent, inserted_key):
    """Return (key, current_index, target_index) for one visible reorder."""
    children = [child.key for child in parent.children]
    for index, key in enumerate(children):
        if key == inserted_key or len(children) < 2:
            continue
        target = 0 if index != 0 else 1
        return key, index, target
    return None


def _owner_snapshot(session):
    """Business state the structure edit must not touch; None when unpublished."""
    try:
        state = session.form_state()
    except GeneratedUiError:
        return None
    # Keep every typed field fact. Equal field names on different owners are
    # separate rows; an unknown aggregate header must not erase those owners.
    return {**asdict(state), "fields": [asdict(field) for field in state.fields]}


def _require(condition, message):
    if not condition:
        raise AssertionError(message)


def _read_json_object(path):
    try:
        value = json.loads(sys.stdin.read() if path == "-" else
                           Path(path).read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise AssertionError(f"{path} is not a readable JSON object: {error}") from error
    _require(isinstance(value, dict), f"{path} must contain a JSON object")
    return value


def _write_json(path, value):
    text = json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if path == "-":
        sys.stdout.write(text)
    else:
        Path(path).write_text(text)


def _walk_tree(node):
    yield node
    for child in node.children:
        yield from _walk_tree(child)


def _spec_keys(value, allowed, what):
    unknown = sorted(set(value) - set(allowed))
    _require(not unknown, f"{what} has unknown field(s): {', '.join(unknown)}")
    return value


def _definition_from_spec(capabilities, spec):
    """Build the v2 definition purely from caller data + published facts."""
    import re
    identifier = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\Z")
    _spec_keys(spec, {"name", "parameters", "elements", "reuse_nodes",
                      "new_instances", "template"}, "composition spec")
    name = spec.get("name")
    _require(isinstance(name, str) and identifier.fullmatch(name),
             "composition spec.name must be a protocol identifier")

    parameters = []
    for item in spec.get("parameters", []):
        _spec_keys(item, {"name", "type", "required", "min", "max", "max_length",
                          "default"}, "parameter")
        _require(isinstance(item.get("name"), str) and identifier.fullmatch(item["name"]),
                 "parameter.name must be a protocol identifier")
        value_type = item.get("type", "STRING")
        _require(value_type in ("STRING", "INTEGER", "BOOLEAN"),
                 f"parameter {item['name']} type is not STRING/INTEGER/BOOLEAN")
        default = item.get("default", "")
        _require(isinstance(default, str) and not any(
            character.isspace() or ord(character) < 0x20 for character in default),
            f"parameter {item['name']} default must be one non-space token")
        parameters.append({
            "name": item["name"], "type": value_type,
            "required": bool(item.get("required", False)),
            "min": int(item.get("min", 0)), "max": int(item.get("max", 0)),
            "max_length": int(item.get("max_length", 0)),
            "default": default,
        })

    elements = []
    template_children = []
    for item in spec.get("elements", []):
        _spec_keys(item, {"key", "role", "field", "argument", "action", "source",
                          "preset", "label", "presentation"}, "element")
        key = item.get("key")
        _require(isinstance(key, str) and identifier.fullmatch(key),
                 "element.key must be a protocol identifier")
        role = item.get("role")
        _require(role in ("field", "action", "preset", "projection"),
                 f"element {key} role is not field/action/preset/projection")
        field_id = item.get("field", "")
        action = item.get("action", "")
        if role in ("field", "preset", "projection"):
            _require(isinstance(field_id, str) and capabilities.field(field_id) is not None,
                     f"element {key} names unpublished field {field_id!r}")
        if role == "action":
            _require(isinstance(action, str) and capabilities.action(action) is not None,
                     f"element {key} names unpublished action {action!r}")
        presentation = item.get("presentation", "text")
        if presentation in ("select", "radio", "segmented"):
            _require(role == "field", f"element {key} choice presentation needs role field")
            _require(capabilities.choice_options_for(field_id),
                     f"element {key} choice presentation needs published options for {field_id}")
        element = {"key": key, "role": role}
        for source_name, target in (("field", "field"), ("argument", "argument"),
                                    ("action", "action"), ("source", "source"),
                                    ("preset", "preset"), ("label", "label")):
            text = item.get(source_name, "")
            if text:
                element[target] = text
        elements.append(element)
        template_children.append({"depth": 1, "key": key, "kind": "element",
                                  "element": key, "presentation": presentation})
    _require(elements, "composition spec needs at least one element")

    children = [{"depth": 1, "key": f"p-{item['name']}", "kind": "label",
                 "text": "${" + item["name"] + "}"} for item in parameters]
    children.extend(template_children)
    template_spec = spec.get("template", {})
    _spec_keys(template_spec, {"kind", "gap", "padding"}, "template")
    template = {"depth": 0, "key": "root", "kind": template_spec.get("kind", "vertical"),
                "gap": int(template_spec.get("gap", 4)),
                "padding": int(template_spec.get("padding", 0)),
                "children": children}
    node_limit = min(64, capabilities.max_nodes) if capabilities.max_nodes > 0 else 64
    depth_limit = min(8, capabilities.max_depth) if capabilities.max_depth > 0 else 8
    _require(depth_limit >= 2, "the catalog depth limit cannot carry a definition root")
    return {
        "name": name,
        "expanded_node_limit": node_limit,
        "expanded_depth_limit": depth_limit,
        "parameters": parameters,
        "elements": elements,
        "template": template,
    }


def _instance_ops(capabilities, structure, definition, spec):
    """Convert caller-named existing nodes or insert caller-named new ones."""
    root = edit.structure_tree(structure)
    by_key = {node.key: node for node in _walk_tree(root)}
    name = definition["name"]
    operations = []
    appended = {}

    def convert(node, properties):
        if node.kind != name:
            operations.append({"op": "set_declaration", "key": node.key, "kind": name})
        for child in node.children:
            operations.append({"op": "delete", "key": child.key})
        for property_name, value in properties.items():
            if node.property(property_name) != str(value):
                operations.append({"op": "set_property", "key": node.key,
                                   "name": property_name, "value": value})

    reuse = spec.get("reuse_nodes", [])
    for item in reuse:
        _spec_keys(item, {"key", "properties"}, "reuse_nodes entry")
        key = item.get("key")
        _require(key in by_key, f"reuse node {key!r} is not in the accepted structure")
        convert(by_key[key], item.get("properties", {}))
    for item in spec.get("new_instances", []):
        _spec_keys(item, {"key", "parent", "properties"}, "new_instances entry")
        key = item.get("key")
        parent_key = item.get("parent")
        properties = item.get("properties", {})
        if key in by_key:
            convert(by_key[key], properties)
            continue
        _require(parent_key in by_key,
                 f"new instance {key!r} names unknown parent {parent_key!r}")
        parent = by_key[parent_key]
        component = capabilities.component(parent.kind)
        _require(component is not None and component.allows_children,
                 f"parent {parent_key!r} is not a published container")
        index = len(parent.children) + appended.get(parent_key, 0)
        appended[parent_key] = appended.get(parent_key, 0) + 1
        node = {"key": key, "kind": name,
                "properties": {str(name): str(value)
                               for name, value in properties.items()}}
        operations.append({"op": "insert", "parent": parent_key, "index": index,
                           "node": node})
    return operations


def build_composition_plan(capabilities, structure, spec):
    """Return a plan document for ONE definition plus caller-named instances."""
    definition = _definition_from_spec(capabilities, spec)
    operations = [{"op": "set_composition", "composition": definition}]
    operations.extend(_instance_ops(capabilities, structure, definition, spec))
    return {"base_version": structure.version, "operations": operations}


def build_removal_plan(structure, spec):
    _spec_keys(spec, {"definitions", "nodes"}, "removal spec")
    operations = [{"op": "remove_composition", "name": name}
                  for name in spec.get("definitions", [])]
    operations.extend({"op": "delete", "key": key} for key in spec.get("nodes", []))
    _require(operations, "removal spec is empty")
    return {"base_version": structure.version, "operations": operations}


def _discovery(snapshot, capabilities):
    structure = edit.structure_from_snapshot(snapshot)
    facts = edit.instance_facts(edit.instances_from_snapshot(snapshot))
    return {
        "structure_version": structure.version,
        "format_version": structure.format_version,
        "definitions": [item.name for item in structure.compositions],
        "fields": [item.field_id for item in capabilities.fields],
        "actions": [item.name for item in capabilities.actions],
        "choice_fields": list(capabilities.choice_fields()),
        "instance_owners": facts["owners"],
        "instance_owner_conflicts": facts["owner_conflicts"],
        "instance_binding_sha256": facts["sha256"],
        "instance_presentation_sha256": facts["presentation_sha256"],
        "visible": facts["visible"],
        "enabled": facts["enabled"],
    }


def _print_preview(title, preview, saved_path):
    print(title)
    print(f"BASE_VERSION {preview.base_version}")
    print(f"CANDIDATE_SHA256 {preview.submitted_sha256}")
    print(f"EXPECTED_STRUCTURE_SHA256 {preview.expected_structure_sha256}")
    print(f"EXPECTED_DEFINITIONS "
          f"{','.join(item.name for item in preview.expected_compositions) or '-'}")
    print(f"REMOVALS {','.join(preview.removals) or '-'}")
    for line in preview.diff.lines:
        print(f"DIFF {line}")
    if saved_path:
        print(f"SAVED_PLAN {saved_path}")


def run_composition(descriptor, spec_path, save_plan, json_output=False):
    session = GeneratedUiSession.connect(descriptor)
    capabilities = session.capabilities()
    snapshot = session.snapshot()
    structure = edit.structure_from_snapshot(snapshot)
    _require(structure.nodes,
             "composition mode needs an accepted node structure; seed the application first")
    spec = _read_json_object(spec_path)
    plan_document = build_composition_plan(capabilities, structure, spec)
    plan = edit.edit_plan_from_dict(plan_document)
    preview = edit.preview_plan(structure, plan, capabilities,
                                endpoint=snapshot.endpoint)
    if save_plan:
        _write_json(save_plan, edit.saved_plan_from_preview(plan, preview).to_dict())
    summary = {"mode": "composition",
               "discovery": _discovery(snapshot, capabilities),
               "plan": plan_document,
               "base_version": preview.base_version,
               "submitted_sha256": preview.submitted_sha256,
               "expected_structure_sha256": preview.expected_structure_sha256,
               "expected_definitions": [item.name
                                        for item in preview.expected_compositions],
               "removals": list(preview.removals),
               "saved_plan": save_plan}
    if json_output:
        print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        facts = summary["discovery"]
        print(f"DISCOVERY v{facts['structure_version']} fields="
              f"{','.join(facts['fields']) or '-'} actions="
              f"{','.join(facts['actions']) or '-'} choices="
              f"{','.join(facts['choice_fields']) or '-'} definitions="
              f"{','.join(facts['definitions']) or '-'} owners="
              f"{json.dumps(facts['instance_owners'], sort_keys=True)}")
        print(f"PLAN_COMPOSITION {plan_document['operations'][0]['composition']['name']} "
              f"elements={len(plan_document['operations'][0]['composition']['elements'])} "
              f"operations={len(plan_document['operations'])}")
        print(f"BASE_VERSION {preview.base_version}")
        print(f"CANDIDATE_SHA256 {preview.submitted_sha256}")
        print(f"EXPECTED_STRUCTURE_SHA256 {preview.expected_structure_sha256}")
        print(f"EXPECTED_DEFINITIONS "
              f"{','.join(summary['expected_definitions']) or '-'}")
        print(f"REMOVALS {','.join(summary['removals']) or '-'}")
        for line in preview.diff.lines:
            print(f"DIFF {line}")
        if save_plan:
            print(f"SAVED_PLAN {save_plan}")
        print("PREVIEW_LOCAL_ONLY 1")
    return 0


def run_removal(descriptor, spec_path, save_plan, json_output=False):
    session = GeneratedUiSession.connect(descriptor)
    capabilities = session.capabilities()
    snapshot = session.snapshot()
    structure = edit.structure_from_snapshot(snapshot)
    spec = _read_json_object(spec_path)
    plan_document = build_removal_plan(structure, spec)
    plan = edit.edit_plan_from_dict(plan_document)
    preview = edit.preview_plan(structure, plan, capabilities,
                                endpoint=snapshot.endpoint)
    if save_plan:
        _write_json(save_plan, edit.saved_plan_from_preview(plan, preview).to_dict())
    summary = {"mode": "removal", "plan": plan_document,
               "base_version": preview.base_version,
               "submitted_sha256": preview.submitted_sha256,
               "expected_structure_sha256": preview.expected_structure_sha256,
               "expected_definitions": [item.name
                                        for item in preview.expected_compositions],
               "removals": list(preview.removals), "saved_plan": save_plan}
    if json_output:
        print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(f"PLAN_REMOVAL definitions="
              f"{','.join(spec.get('definitions', [])) or '-'} nodes="
              f"{','.join(spec.get('nodes', [])) or '-'}")
        _print_preview("PREVIEW", preview, save_plan)
        print("PREVIEW_LOCAL_ONLY 1")
    return 0


def _outcome_summary(outcome):
    return {
        "outcome": outcome.outcome, "detail": outcome.detail,
        "base_version": outcome.base_version,
        "accepted_version": outcome.accepted_version,
        "token": outcome.token,
        "exact_readback": outcome.exact_readback,
        "submitted_sha256": outcome.submitted_sha256,
        "expected_structure_sha256": outcome.expected_structure_sha256,
        "instance_binding_sha256": outcome.instances_sha256,
        "instance_owners": outcome.instance_owners,
        "instance_owner_conflicts": outcome.instance_owner_conflicts,
    }


def run_apply(descriptor, plan_path, receipt_path, json_output=False):
    session = GeneratedUiSession.connect(descriptor)
    capabilities = session.capabilities()
    text = sys.stdin.read() if plan_path == "-" else \
        Path(plan_path).read_text()
    _, saved = edit.load_plan_document(text)
    _require(saved is not None, "apply needs a saved plan, not a bare preview")
    outcome = edit.apply_saved_plan(session, saved, capabilities=capabilities)
    receipt = edit.receipt_from_outcome(outcome)
    saved_receipt = None
    if receipt is not None and receipt_path:
        _write_json(receipt_path, receipt)
        saved_receipt = receipt_path
    summary = _outcome_summary(outcome)
    summary["receipt_available"] = receipt is not None
    summary["saved_receipt"] = saved_receipt
    if receipt is None:
        summary["receipt_note"] = "no ticket was allocated; there is no receipt to save"
    elif saved_receipt is None:
        summary["receipt_note"] = "a receipt is available; pass --save-receipt to write it"
    if json_output:
        print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(f"SUBMIT outcome={outcome.outcome} base={outcome.base_version} "
              f"accepted={outcome.accepted_version} token={outcome.token} "
              f"exact={int(outcome.exact_readback)}")
        print(f"SUBMITTED_SHA256 {outcome.submitted_sha256}")
        print(f"EXPECTED_STRUCTURE_SHA256 {outcome.expected_structure_sha256}")
        print(f"INSTANCE_BINDINGS {outcome.instances_sha256} OWNERS "
              f"{json.dumps(outcome.instance_owners, sort_keys=True)}")
        if saved_receipt is not None:
            print(f"SAVED_RECEIPT {saved_receipt}")
        elif receipt is None:
            print("RECEIPT unavailable: no ticket was allocated")
        else:
            print("RECEIPT available; pass --save-receipt to write it")
    return edit.outcome_exit_code(outcome)


def run_query(descriptor, receipt_path, mode, json_output=False):
    session = GeneratedUiSession.connect(descriptor)
    text = sys.stdin.read() if receipt_path == "-" else \
        Path(receipt_path).read_text()
    receipt = edit.load_receipt_document(text)
    query = edit.query_receipt(session, receipt, mode=mode)
    summary = {
        "mode": mode, "outcome": query.outcome, "detail": query.detail,
        "terminal_state": query.terminal_state, "reason": query.reason,
        "accepted_version": query.accepted_version,
        "current_version": query.current_version,
        "exact_readback": query.exact_readback,
        "submitted_sha256": query.submitted_sha256,
        "expected_structure_sha256": query.expected_structure_sha256,
        "instance_binding_sha256": query.instances_sha256,
        "instance_owners": query.instance_owners,
        "instance_owner_conflicts": query.instance_owner_conflicts,
    }
    if json_output:
        print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(f"QUERY mode={mode} outcome={query.outcome} "
              f"terminal={query.terminal_state} accepted={query.accepted_version} "
              f"current={query.current_version} exact={int(query.exact_readback)}")
        print(f"EXPECTED_STRUCTURE_SHA256 {query.expected_structure_sha256}")
        print(f"INSTANCE_BINDINGS {query.instances_sha256} OWNERS "
              f"{json.dumps(query.instance_owners, sort_keys=True)}")
        if query.detail:
            print(f"DETAIL {query.detail}")
    return edit.query_exit_code(query)


def run_inspect(descriptor, json_output=False):
    session = GeneratedUiSession.connect(descriptor)
    capabilities = session.capabilities()
    snapshot = session.snapshot()
    facts = _discovery(snapshot, capabilities)
    facts["choices"] = [{"field": option.field_id, "key": option.key,
                         "value": option.value, "enabled": option.enabled,
                         "label": option.label}
                        for option in capabilities.choice_options]
    if json_output:
        print(json.dumps(facts, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(f"DISCOVERY v{facts['structure_version']} format={facts['format_version']} "
              f"definitions={','.join(facts['definitions']) or '-'}")
        print(f"FIELDS {','.join(facts['fields']) or '-'}")
        print(f"ACTIONS {','.join(facts['actions']) or '-'}")
        print(f"CHOICE_FIELDS {','.join(facts['choice_fields']) or '-'}")
        print(f"INSTANCE_OWNERS {json.dumps(facts['instance_owners'], sort_keys=True)}")
        print(f"INSTANCE_BINDING_SHA256 {facts['instance_binding_sha256']}")
        print(f"INSTANCE_PRESENTATION_SHA256 {facts['instance_presentation_sha256']}")
        print(f"VISIBLE {json.dumps(facts['visible'], sort_keys=True)}")
        print(f"ENABLED {json.dumps(facts['enabled'], sort_keys=True)}")
    return 0


def run(descriptor: str, *, json_output: bool = False, owner_check: bool = True) -> int:
    session = GeneratedUiSession.connect(descriptor)
    summary = {"chain": "generated-edit", "steps": []}
    try:
        capabilities = session.capabilities()
        original, seeded = _seed_initial_structure(session, capabilities)
        owner_before = _owner_snapshot(session) if owner_check else None
        summary["steps"].append({"step": "seed_initial_structure", "seeded": seeded,
                                 "version": original.version})
        root = edit.structure_tree(original)

        selected = _find_property(capabilities, root)
        _require(selected is not None,
                 "the application publishes no optional integer layout property on the root")
        property_name, original_value, new_value = selected

        leaf = _find_leaf(capabilities)
        _require(leaf is not None,
                 "the application publishes no leaf kind with a plain text property")
        leaf_kind, sample_text = leaf[1], leaf[2]
        parent = _choose_parent(capabilities, root)
        _require(parent is not None, "no published container accepts another child")
        inserted_key = "cgui-edit-example"
        _require(all(node.key != inserted_key for node in edit.generated_nodes_of(root)),
                 "the example key already exists; choose another application")

        # Discover a legal reorder against the post-insert tree, not a guess.
        insert_operation = {
            "op": "insert", "parent": parent.key,
            "index": min(1, len(parent.children)),
            "node": {"key": inserted_key, "kind": leaf_kind,
                     "properties": {"text": sample_text}},
        }
        draft = edit.preview_plan(original, edit.edit_plan_from_dict({
            "base_version": original.version, "operations": [insert_operation]}), capabilities)
        parent_after = edit._find_node(draft.root, parent.key)
        reorder = _choose_reorder(parent_after, inserted_key)
        original_index = None
        if reorder is not None:
            original_parent = edit._find_node(root, parent.key)
            original_index = next(index for index, child in enumerate(original_parent.children)
                                  if child.key == reorder[0])

        operations = [{"op": "set_property", "key": root.key,
                       "name": property_name, "value": new_value}, insert_operation]
        if reorder is not None:
            operations.append({"op": "move", "key": reorder[0],
                               "parent": parent.key, "index": reorder[2]})
        batch = edit.edit_plan_from_dict({"base_version": original.version,
                                          "operations": operations})
        preview = edit.preview_plan(original, batch, capabilities)
        summary["property_edit"] = {"key": root.key, "name": property_name,
                                    "from": original_value, "to": new_value}
        summary["inserted"] = {"key": inserted_key, "kind": leaf_kind, "parent": parent.key}
        summary["reordered"] = None if reorder is None else {
            "key": reorder[0], "from_index": original_index, "to_index": reorder[2]}
        summary["steps"].append({"step": "batch_preview", "local_only": True,
                                 "base_version": preview.base_version,
                                 "diff": preview.diff.lines})
        first = edit.submit_preview(session, preview)
        summary["steps"].append({"step": "batch_submit", **first.to_dict()})
        _require(first.outcome == "accepted" and first.exact_readback,
                 f"batch was not accepted with an exact readback: {first.outcome} "
                 f"{first.detail}")
        _require(first.accepted_structure is not None, "accepted outcome carried no structure")

        # A candidate built against the OLD baseline must be refused by the real
        # CAS and must leave the structure accepted above untouched.
        stale_plan = edit.edit_plan_from_dict({
            "base_version": original.version,
            "operations": [{"op": "set_property", "key": root.key, "name": property_name,
                            "value": new_value}]})
        stale_preview = edit.preview_plan(original, stale_plan, capabilities)
        stale = edit.submit_preview(session, stale_preview)
        preserved = edit.structure_from_snapshot(session.snapshot())
        summary["steps"].append({"step": "stale_submit", **stale.to_dict()})
        _require(stale.outcome in ("stale", "rejected"),
                 f"a stale candidate unexpectedly settled as {stale.outcome}")
        _require(same_structure(preserved.nodes, first.accepted_structure.nodes),
                 "the stale/refused candidate changed the previously accepted structure")

        # Fresh preview against the version the endpoint really holds now.
        current = edit.structure_from_snapshot(session.snapshot())
        restore = [{"op": "delete", "key": inserted_key},
                   {"op": "set_property", "key": root.key, "name": property_name,
                    "value": original_value}]
        if reorder is not None:
            restore.append({"op": "move", "key": reorder[0], "parent": parent.key,
                            "index": original_index})
        restore_plan = edit.edit_plan_from_dict({"base_version": current.version,
                                                 "operations": restore})
        restore_preview = edit.preview_plan(current, restore_plan, capabilities)
        second = edit.submit_preview(session, restore_preview)
        summary["steps"].append({"step": "restore_submit", **second.to_dict()})
        _require(second.outcome == "accepted" and second.exact_readback,
                 f"the follow-up legal edit was not accepted: {second.outcome} {second.detail}")
        _require(same_structure(second.accepted_structure.nodes, original.nodes),
                 "the restore edit did not return the original accepted structure")

        if owner_check:
            owner_after = _owner_snapshot(session)
            summary["owner_before"] = owner_before
            summary["owner_after"] = owner_after
            if owner_before is not None and owner_after is not None:
                _require(owner_before == owner_after,
                         "structure editing changed business state/drafts (owner snapshot differs)")
                summary["owner_unchanged"] = True
            else:
                summary["owner_unchanged"] = None
        summary["outcome"] = "PASSED"
        summary["builds"] = 0
        summary["restarts"] = 0
        summary["submit_to_accepted_ms"] = {
            "batch": first.submit_to_accepted_ms,
            "restore": second.submit_to_accepted_ms,
        }
        if json_output:
            print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
        else:
            print("CHAIN property_edit="
                  f"{root.key}.{property_name} {original_value}->{new_value} "
                  f"insert={inserted_key} reorder={summary['reordered']}")
            for step, outcome in (("batch", first), ("stale", stale), ("restore", second)):
                print(f"STEP {step} outcome={outcome.outcome} base={outcome.base_version} "
                      f"accepted={outcome.accepted_version} token={outcome.token} "
                      f"exact={int(outcome.exact_readback)} "
                      f"submit_to_accepted_ms={outcome.submit_to_accepted_ms}")
            print(f"STALE_KEPT_OLD_STRUCTURE "
                  f"{int(same_structure(preserved.nodes, first.accepted_structure.nodes))}")
            print(f"RESTORED_ORIGINAL_STRUCTURE "
                  f"{int(same_structure(second.accepted_structure.nodes, original.nodes))}")
            print(f"OWNER_UNCHANGED {summary.get('owner_unchanged')}")
            print(f"BUILDS {summary['builds']} RESTARTS {summary['restarts']}")
            print("PASSED generated edit chain")
        return 0
    except (edit.GeneratedEditError, GeneratedUiError, AssertionError) as error:
        summary["outcome"] = "FAILED"
        summary["error"] = str(error)
        if json_output:
            print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
        else:
            print(f"FAILED generated edit chain: {error}", file=sys.stderr)
        return 1


def main(argv: list[str]) -> int:
    args = list(argv)
    json_output = "--json" in args
    owner_check = "--skip-owner-check" not in args
    inspect = "--inspect" in args
    args = [arg for arg in args if arg not in ("--json", "--skip-owner-check", "--inspect")]

    def take(flag):
        if flag not in args:
            return None
        index = args.index(flag)
        if index + 1 >= len(args):
            raise ValueError(f"{flag} requires a value")
        value = args[index + 1]
        del args[index:index + 2]
        return value

    try:
        composition_spec = take("--composition-spec")
        removal_spec = take("--remove-spec")
        save_plan = take("--save-plan")
        apply_plan = take("--apply-saved-plan")
        save_receipt = take("--save-receipt")
        status_receipt = take("--status-receipt")
        resume_receipt = take("--resume-receipt")
    except ValueError as error:
        print(f"usage: {error}", file=sys.stderr)
        return 2
    modes = sum(value is not None for value in (
        composition_spec, removal_spec, apply_plan, status_receipt,
        resume_receipt)) + int(inspect)
    if modes > 1 or len(args) != 1:
        print(__doc__)
        return 2
    if save_plan is not None and composition_spec is None and removal_spec is None:
        print("usage: --save-plan belongs to a composition/removal build", file=sys.stderr)
        return 2
    if save_receipt is not None and apply_plan is None:
        print("usage: --save-receipt belongs to --apply-saved-plan", file=sys.stderr)
        return 2
    descriptor = args[0]
    if inspect:
        return run_inspect(descriptor, json_output=json_output)
    if composition_spec is not None:
        return run_composition(descriptor, composition_spec, save_plan,
                               json_output=json_output)
    if removal_spec is not None:
        return run_removal(descriptor, removal_spec, save_plan,
                           json_output=json_output)
    if apply_plan is not None:
        return run_apply(descriptor, apply_plan, save_receipt,
                         json_output=json_output)
    if status_receipt is not None:
        return run_query(descriptor, status_receipt, "status",
                         json_output=json_output)
    if resume_receipt is not None:
        return run_query(descriptor, resume_receipt, "resume",
                         json_output=json_output)
    return run(descriptor, json_output=json_output, owner_check=owner_check)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
