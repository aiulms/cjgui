#!/usr/bin/env python3
"""Independent public client; no model service. See README.md for commands."""
from pathlib import Path
from dataclasses import asdict, replace
import argparse
import json
import sys

framework = (Path(__file__).resolve().parent / "__CJGUI_FRAMEWORK_RELATIVE_PATH__").resolve()
sys.path.insert(0, str(framework / "shared_operation_core"))
from cjgui_generated_client import GeneratedNode, GeneratedProperty, GeneratedUiSession, GeneratedUiError, same_structure, GeneratedTextStyleRun, styled_text_runs_property, parse_text_style_runs
from client import SharedOperationArgument as Argument, SharedOperationClient


def props(**values):
    return tuple(GeneratedProperty(key, str(value)) for key, value in values.items())


def generate(capabilities, cards=None):
    font = next((item for item in capabilities.font_resources if item.key == "preview-mono" and item.state == "ready"), None)
    font_props = (props(fontResource=font.key, fontVersion=font.version) if font else ())
    nodes = [GeneratedNode(0, "preset-layout", "vertical", None, None, props(gap=8, growX=1)),
             GeneratedNode(1, "preset-note", "label", None, None,
                           props(text="独立客户端生成 · 同一预设草稿", fixedHeight=28,
                                 fontSize=14, textColor="#E5EDFF", background="#203454",
                                 textMaxLines=1, textOverflow="ellipsis",
                                 letterSpacing="0.25", lineHeight="18"))]
    if capabilities.component("presetCardList"):
        # One ordinary object collection over the same preset objects. The
        # description chooses only the registered collection reference and the
        # list/table presentation; data, selection and sort stay application-owned.
        nodes.append(GeneratedNode(1, "preset-card-list", "presetCardList", None, None,
                                   props(collection="presetCards", presentation="list", growX=1,
                                         fixedHeight=150)))
    if capabilities.component("presetCard"):
        labels = {field.field_id: field.label for field in capabilities.fields}
        # Each card declares FIVE children in this order: title, note and the
        # three per-field labels. They are ordinary read-only generated nodes, so
        # their identity, style reference, overflow and theme paint all come from
        # the framework's own path; the card factory only places them. The order
        # is the application's declared contract (see preset_cards.cj).
        # The DESCRIPTION chooses which objects get a detail card: the caller may
        # name them (e.g. after an object was added), otherwise the seeded pair.
        card_entries = ([(key, f"卡片 {key[-1]}") for key in cards]
                        if cards else [("cardA", "卡片 A"), ("cardB", "卡片 B")])
        for key, title in card_entries:
            nodes.append(GeneratedNode(1, key, "presetCard", None, None, props(title=title)))
            nodes.append(GeneratedNode(2, f"{key}-title", "label", None, None,
                                       props(text=title, style="preset-card-title", growX=1,
                                             textMaxLines=1, textOverflow="ellipsis")))
            nodes.append(GeneratedNode(2, f"{key}-note", "label", None, None,
                                       props(text="编辑后点击应用；锁定/错误由业务对象决定",
                                             style="preset-card-note", growX=1,
                                             textMaxLines=2, textOverflow="ellipsis")))
            for field_id in ("jobName", "copies", "duplex"):
                nodes.append(GeneratedNode(2, f"{key}-{field_id}-label", "label", None, None,
                                           props(text=labels.get(field_id, field_id),
                                                 style="preset-card-field-label", growX=1,
                                                 textMaxLines=1, textOverflow="ellipsis")))
    for field in capabilities.fields:
        if field.callable and capabilities.component(field.input_kind):
            nodes.append(GeneratedNode(1, f"edit-{field.field_id}", field.input_kind, field.field_id, None,
                                       props(label=field.label, fixedHeight=40, fontSize=15,
                                             background="#F7F9FF", textColor="#17283F", border="#A9B9D2")))
            if field.input_kind == "integerInput" and capabilities.component("slider"):
                nodes.append(GeneratedNode(1, f"range-{field.field_id}", "slider", field.field_id, None,
                                           props(label=field.label, fixedHeight=30, step=1)))
    if capabilities.component("image") and capabilities.image_resources:
        image = capabilities.image_resources[0]
        nodes.append(GeneratedNode(1, "preset-beacon", "image", None, None,
                                   props(resource=image.key, resourceVersion=image.version,
                                         fixedHeight=48, contentMode="fit")))
    nodes.append(GeneratedNode(1, "preset-actions", "horizontal", None, None, props(gap=8)))
    for action in capabilities.actions:
        nodes.append(GeneratedNode(2, f"do-{action.name}", "action", None, action.name,
                                   props(label=action.label, fixedWidth=150, fixedHeight=36,
                                         fontSize=14, background="#3974CB", textColor="#FFFFFF")))
    if font_props:
        nodes = [GeneratedNode(n.depth, n.key, n.kind, n.field_id, n.action,
                 n.properties + tuple(font_props) if n.kind in ("textInput", "label") else n.properties) for n in nodes]
    return nodes


def styled_description(capabilities, *, alternate=False, large=False):
    # One application-owned file also read by the Cangjie handwritten view.
    lines = (Path(__file__).resolve().parent / "assets/styled-description.tsv").read_text().splitlines()
    text, runs = lines[0], []
    for line in lines[1:]:
        if not line:
            continue
        start, end, size, font_key, color = line.split("\t")
        font = next(font for font in capabilities.font_resources if font.key == font_key and font.state != "withdrawn")
        runs.append(GeneratedTextStyleRun(int(start), int(end),
            42 if large and float(size) == 36 else float(size), 0, font.key, font.version,
            "#40CCF2" if alternate else color))
    return text, styled_text_runs_property(text, runs)


def styled_nodes(capabilities):
    text, spans = styled_description(capabilities)
    serif = next(font for font in capabilities.font_resources if font.key == "preview-serif")
    result = []
    for node in generate(capabilities):
        if node.key == "preset-note":
            properties = props(text=text, growX=1, fontSize=14, textColor="#E5EDFF", letterSpacing="0.25",
                               fontResource=serif.key, fontVersion=serif.version) + (spans,)
            result.append(replace(node, properties=properties))
            # Same declaration, separately limited; neither gets a fixed height.
            result.append(GeneratedNode(1, "preset-note-limited", "label", None, None,
                properties + props(textMaxLines=2, textOverflow="ellipsis")))
        elif node.key == "preset-actions":
            result.append(replace(node, kind="vertical"))
        else:
            result.append(node)
    return result


def update_styled_nodes(nodes, capabilities, operation):
    result = []
    for node in nodes:
        values = node.properties
        text = node.property("text")
        if node.property("textRuns"):
            runs = parse_text_style_runs(text, node.property("textRuns"))
            if operation == "styled-color":
                runs = tuple(replace(run, color="#40CCF2") for run in runs)
            elif operation == "styled-size":
                runs = tuple(replace(run, font_size=42) if run.start == 7 and run.end == 10 else run for run in runs)
            elif operation == "styled-font-current":
                runs = tuple(replace(run, font_version=next(font.version for font in capabilities.font_resources
                    if font.key == run.font_resource and font.state != "withdrawn"))
                    if run.font_resource else run for run in runs)
            values = tuple(p for p in values if p.name != "textRuns") + (styled_text_runs_property(text, runs),)
        if operation == "styled-font-current" and node.property("fontResource"):
            current = next(font for font in capabilities.font_resources if font.key == node.property("fontResource")
                           and font.state != "withdrawn")
            values = tuple(p for p in values if p.name != "fontVersion") + props(fontVersion=current.version)
        result.append(replace(node, properties=values, kind="vertical" if node.key == "preset-actions" else node.kind))
    return result


def reorder(nodes):
    # Move one actual accepted subtree while preserving keys and bindings.
    groups = []
    for node in nodes[1:]:
        if node.depth == 1:
            groups.append([])
        groups[-1].append(node)
    index = next(i for i, group in enumerate(groups) if group[0].kind == "textInput")
    moved = groups.pop(index)
    actions = next(i for i, group in enumerate(groups) if group[0].key == "preset-actions")
    groups.insert(actions, moved)
    return [nodes[0]] + [node for group in groups for node in group]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("descriptor")
    parser.add_argument("operation", choices=("inspect", "generate", "reorder", "read", "set", "apply", "cancel", "check-refusal", "font-switch", "styled-generate", "styled-color", "styled-size", "styled-font-current", "card-read", "card-set", "card-apply", "card-cancel", "card-rebind", "stale-write", "lock", "unlock",
                        "select-card", "add-card", "delete-card", "filter-cards", "sort-cards"))
    parser.add_argument("--instance")
    parser.add_argument("--owner", type=int)
    parser.add_argument("--new-owner", type=int)
    parser.add_argument("--field")
    parser.add_argument("--font-resource", default="preview-serif")
    parser.add_argument("--value")
    parser.add_argument("--expected-draft-version", type=int,
                        help="explicit draft CAS, for stale-request handling")
    parser.add_argument("--expected-version", type=int,
                        help="explicit domain CAS; defaults to the public client's current version")
    parser.add_argument("--cards", default=None,
                        help="comma-separated card keys to render details for")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    card_keys = args.cards.split(",") if args.cards else None
    session = GeneratedUiSession.connect(args.descriptor)
    capabilities = session.capabilities()
    result = {"operation": args.operation}
    if args.operation == "inspect":
        result["capabilities"] = asdict(capabilities)
    elif args.operation == "check-refusal":
        # An actual refused READ against this endpoint. No capability/token is
        # printed; a typed ERROR must not become an empty successful snapshot.
        before = session.form_state()
        descriptor = dict(session.client.descriptor)
        descriptor["capability"] = "mixed-form-invalid-capability"
        refused = GeneratedUiSession(SharedOperationClient(descriptor))
        try:
            refused.fields()
        except GeneratedUiError as error:
            result["refused"] = str(error)
        else:
            raise AssertionError("typed fields read swallowed refusal")
        after = session.form_state()
        assert before == after, "refused read changed owner state"
        result["owner_unchanged"] = True
    elif args.operation in ("generate", "reorder", "font-switch", "styled-generate", "styled-color", "styled-size", "styled-font-current"):
        before = session.structure()
        if args.operation == "styled-generate":
            nodes = styled_nodes(capabilities)
        elif args.operation in ("styled-color", "styled-size", "styled-font-current"):
            nodes = update_styled_nodes(list(before.nodes), capabilities, args.operation)
        elif args.operation == "font-switch":
            font = next((font for font in capabilities.font_resources if font.key == args.font_resource
                         and font.state != "withdrawn"), None)
            if font is None:
                parser.error("--font-resource must name an application-published font")
            nodes = [GeneratedNode(n.depth, n.key, n.kind, n.field_id, n.action,
                tuple(p for p in n.properties if p.name not in ("fontResource", "fontVersion")) +
                tuple(props(fontResource=font.key, fontVersion=font.version))
                if n.kind in ("textInput", "label") else n.properties) for n in before.nodes]
        else:
            nodes = generate(capabilities, card_keys) if args.operation == "generate" else reorder(list(before.nodes))
        reply = session.submit(nodes, before.version)
        result["submit"] = asdict(reply)
        if reply.candidate_accepted:
            result["terminal"] = asdict(session.wait_for_candidate(reply.ticket(), timeout_ms=5000))
            assert result["terminal"]["terminal_state"] == "ACCEPTED", result["terminal"]
            assert same_structure(nodes, session.structure().nodes)
    elif args.operation in ("lock", "unlock"):
        # Owner-level lock through the SAME declared action; the target is the
        # handwritten preset or one card.
        if args.instance is not None:
            state = session.form_state(instance_key=args.instance)
            target = state.owner_resource_id
        else:
            state = session.form_state()
            target = state.owner_resource_id
        result["lock_target"] = target
        result["lock_action"] = asdict(session.invoke_action(
            "SET_LOCK", [target],
            [Argument.boolean("locked", args.operation == "lock")],
            expected_version=state.state_version))
        if args.instance is not None:
            result["lock_after"] = [asdict(field) for field in
                                    session.form_state(instance_key=args.instance).fields]
        else:
            result["lock_after"] = [asdict(field) for field in session.form_state().fields]
        result["lock_actions"] = [asdict(a) for a in
                                  (session.form_state(instance_key=args.instance).actions
                                   if args.instance is not None else session.form_state().actions)]
    elif args.operation == "card-rebind":
        # Explicit rebind through the SAME declared vocabulary. The accepted
        # scene only follows after a candidate containing the key is accepted,
        # so this call reports the mapping change, not a new accepted owner.
        if args.instance is None or args.new_owner is None:
            parser.error("card-rebind requires --instance and --new-owner")
        card = session.form_state(instance_key=args.instance)
        result["card_owner_before"] = card.owner_resource_id
        result["card_action"] = asdict(session.invoke_action(
            "REBIND_CARD", [card.owner_resource_id],
            [Argument.string("cardKey", args.instance), Argument.integer("newOwner", args.new_owner)],
            expected_version=card.state_version))
    elif args.operation == "stale-write":
        # An operation addressed to a RETIRED owner id: the domain must refuse
        # it by name instead of resolving the key to the new object.
        if args.owner is None or args.field is None or args.value is None:
            parser.error("stale-write requires --owner, --field and --value")
        result["stale_owner"] = args.owner
        result["stale_action"] = asdict(session.invoke_action(
            "EDIT_DRAFT_TEXT", [args.owner],
            [Argument.string("fieldId", args.field), Argument.string("text", args.value),
             Argument.integer("expectedDraftVersion", 0)]))
    elif args.operation in ("card-read", "card-set", "card-apply", "card-cancel"):
        # The card owner is named explicitly; a stale/unknown instance is
        # refused by the endpoint instead of answered with another object.
        if args.instance is None:
            parser.error("card operations require --instance cardA|cardB")
        card = session.form_state(instance_key=args.instance)
        result["card_instance"] = args.instance
        result["card_owner"] = card.owner_resource_id
        result["card_fields"] = [asdict(field) for field in card.fields]
        result["card_actions"] = [asdict(action) for action in card.actions]
        if args.operation != "card-read":
            action = "APPLY_DRAFT" if args.operation == "card-apply" else "CANCEL_DRAFT"
            arguments = [Argument.integer("expectedDraftVersion", card.draft_version)]
            if args.operation == "card-set":
                spec = next((item for item in capabilities.fields if item.field_id == args.field), None)
                if spec is None or args.value is None:
                    parser.error("card-set requires a published --field and --value")
                action = spec.writer
                arguments.append(Argument.string("fieldId", spec.field_id))
                if spec.editor_kind == "BOOLEAN":
                    if args.value not in ("true", "false"):
                        parser.error("boolean --value must be true or false")
                    arguments.append(Argument.boolean(spec.argument, args.value == "true"))
                else:
                    arguments.append(Argument.string(spec.argument, args.value))
            result["card_action"] = asdict(session.invoke_action(
                action, [card.owner_resource_id], arguments,
                expected_version=card.state_version))
            result["card_after"] = [asdict(field) for field in session.form_state(
                instance_key=args.instance).fields]
    elif args.operation in ("select-card", "add-card", "delete-card", "filter-cards",
                            "sort-cards"):
        state = session.form_state()
        if not state.known or not state.consistent:
            parser.error("owner form feedback is unknown; cannot choose a CAS version")
        action = {"select-card": "SELECT_CARD", "add-card": "ADD_CARD",
                  "delete-card": "DELETE_CARD", "filter-cards": "FILTER_CARDS",
                  "sort-cards": "SORT_CARDS"}[args.operation]
        argument_name = {"select-card": "cardKey", "add-card": "title",
                         "delete-card": "cardKey", "filter-cards": "query",
                         "sort-cards": "column"}[args.operation]
        value = args.instance if args.operation in ("select-card", "delete-card") else args.value
        if value is None:
            parser.error(f"{args.operation} requires " +
                         ("--instance" if args.operation in ("select-card", "delete-card") else "--value"))
        result["collection_action"] = asdict(session.invoke_action(
            action, [state.owner_resource_id], [Argument.string(argument_name, value)],
            expected_version=state.state_version))
    elif args.operation in ("set", "apply", "cancel"):
        state = session.form_state()
        if not state.known or not state.consistent:
            parser.error("owner form feedback is unknown; cannot choose a draft CAS")
        expected_draft = (state.draft_version if args.expected_draft_version is None
                          else args.expected_draft_version)
        arguments = [Argument.integer("expectedDraftVersion", expected_draft)]
        action = "CANCEL_DRAFT" if args.operation == "cancel" else "APPLY_DRAFT"
        if args.operation == "set":
            spec = next((spec for spec in capabilities.fields if spec.field_id == args.field), None)
            if spec is None or args.value is None:
                parser.error("set requires a published --field and --value")
            action = spec.writer
            arguments.append(Argument.string("fieldId", spec.field_id))
            if spec.editor_kind == "BOOLEAN":
                if args.value not in ("true", "false"):
                    parser.error("boolean --value must be true or false")
                arguments.append(Argument.boolean(spec.argument, args.value == "true"))
            else:
                arguments.append(Argument.string(spec.argument, args.value))
        result["action"] = asdict(session.invoke_action(
            action, [state.owner_resource_id], arguments,
            expected_version=state.state_version if args.expected_version is None else args.expected_version))
    result["structure"] = asdict(session.structure())
    state = session.form_state()
    result["form_state"] = asdict(state)
    result["fields"] = [asdict(field) for field in state.fields]
    result["actions"] = [asdict(action) for action in state.actions]
    result["instances"] = asdict(session.instances())
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(rendered)
    print(rendered)


if __name__ == "__main__":
    main()
