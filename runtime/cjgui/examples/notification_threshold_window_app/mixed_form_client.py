#!/usr/bin/env python3
"""Public example: inspect/create/reorder/read/reject one running mixed form.

python3 mixed_form_client.py DESCRIPTOR create
Edit the window, then run read, reorder, and finally reject. All operations use
the existing typed public client; no model, private window command or owner copy.
"""
from __future__ import annotations

import argparse
from dataclasses import asdict, replace
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "shared_operation_core"))
from cjgui_generated_client import GeneratedNode, GeneratedProperty, GeneratedUiSession, same_structure


def props(**values):
    return tuple(GeneratedProperty(k, str(v)) for k, v in values.items())


def create_nodes(capabilities):
    nodes = [GeneratedNode(0, "form-root", "vertical", None, None, props(gap=6, growX=1)),
             GeneratedNode(1, "form-note", "label", None, None,
                           props(text="公开客户端提交的区域：直接编辑原通知草稿", fixedHeight=24,
                                 fontSize=15, textColor="#DDE9FF", textMaxLines=1, textOverflow="ellipsis"))]
    for index, field in enumerate(capabilities.fields):
        if not field.callable or capabilities.component(field.input_kind) is None:
            continue
        nodes.append(GeneratedNode(1, f"field-{index}", field.input_kind, field.field_id, None,
                                   props(label=field.label, fixedHeight=36, fontSize=15,
                                         background="#F7F9FF", textColor="#17283F", border="#A9B9D2")))
    nodes.append(GeneratedNode(1, "form-actions", "horizontal", None, None, props(gap=8)))
    for index, action in enumerate(capabilities.actions):
        nodes.append(GeneratedNode(2, f"action-{index}", "action", None, action.name,
                                   props(label=action.label, fixedWidth=160, fixedHeight=34,
                                         fontSize=14, background="#3974CB", textColor="#FFFFFF")))
    return nodes


def reorder_nodes(nodes):
    # Transform the actual accepted tree. No application page selector or
    # second prewritten UI: preserve every key/binding and move one subtree.
    groups, group = [], []
    for node in nodes[1:]:
        if node.depth == 1 and group:
            groups.append(group)
            group = []
        if node.key == "form-note":
            node = replace(node, properties=tuple(
                GeneratedProperty(p.name, "公开客户端已重排：同一草稿与编辑位置保留") if p.name == "text" else p
                for p in node.properties))
        group.append(node)
    if group:
        groups.append(group)
    editable = next(i for i, g in enumerate(groups) if g[0].kind == "textInput")
    moved = groups.pop(editable)
    before_actions = next((i for i, g in enumerate(groups) if g[0].key == "form-actions"), len(groups))
    groups.insert(before_actions, moved)
    return [nodes[0]] + [node for group in groups for node in group]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("descriptor")
    parser.add_argument("operation", choices=("inspect", "create", "read", "reorder", "reject"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    session = GeneratedUiSession.connect(args.descriptor)
    before = session.structure()
    fields_before = tuple(session.fields())
    result = {"operation": args.operation, "before": asdict(before)}
    if args.operation == "inspect":
        result["capabilities"] = asdict(session.capabilities())
    elif args.operation in ("create", "reorder", "reject"):
        nodes = create_nodes(session.capabilities()) if args.operation == "create" else reorder_nodes(list(before.nodes))
        if args.operation == "reject":
            index = next(i for i, node in enumerate(nodes) if node.field_id)
            nodes[index] = replace(nodes[index], field_id="notPublished")
        reply = session.submit(nodes, before.version)
        result["submit"] = asdict(reply)
        if args.operation == "reject":
            assert not reply.candidate_accepted
            unchanged = session.structure()
            assert unchanged.version == before.version and same_structure(before.nodes, unchanged.nodes)
            assert [(f.field_id, f.draft, f.applied, f.draft_version) for f in session.fields()] == [
                (f.field_id, f.draft, f.applied, f.draft_version) for f in fields_before]
            result["refused_without_structure_or_business_change"] = True
        else:
            assert reply.candidate_accepted
            terminal = session.wait_for_candidate(reply.ticket(), timeout_ms=5000)
            assert terminal.terminal_state == "ACCEPTED", terminal
            current = session.structure()
            assert same_structure(nodes, current.nodes)
            result["terminal"] = asdict(terminal)
    result["structure"] = asdict(session.structure())
    result["fields"] = [asdict(field) for field in session.fields()]
    result["instances"] = asdict(session.instances())
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(rendered)
    print(rendered)


if __name__ == "__main__":
    main()
