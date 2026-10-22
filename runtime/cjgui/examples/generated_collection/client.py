#!/usr/bin/env python3
"""Public collection discovery and layout client. Uses the existing protocol."""
from pathlib import Path
from dataclasses import asdict
import argparse
import json
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "shared_operation_core"))
from cjgui_generated_client import GeneratedUiSession, GeneratedNode, GeneratedProperty


def properties(**values):
    return tuple(GeneratedProperty(name, str(value)) for name, value in values.items())


def layout(presentation="list", horizontal=False, reference="rules"):
    return [GeneratedNode(0, "collection-shell", "horizontal" if horizontal else "vertical", None, None,
                          properties(growX=1, gap=8)),
            GeneratedNode(1, "records", "ruleCollection", None, None,
                          properties(collection=reference, presentation=presentation,
                                     fixedHeight=360, growX=1)),
            GeneratedNode(1, "view-note", "label", None, None,
                          properties(text="同一 rules 集合与草稿", fixedHeight=32,
                                     textColor="#D6E4FF", textMaxLines=1, textOverflow="ellipsis"))]


def keyboard_layout(rearranged=False, remove_editor=False):
    """Ordinary fields use the registered form owner, including after reorder."""
    records = GeneratedNode(1, "records", "ruleCollection", None, None,
                            properties(collection="rules", presentation="list",
                                       fixedHeight=270, growX=1))
    name = GeneratedNode(1, "generated-name", "textInput", "label", None,
                         properties(label="生成名称", fixedHeight=42, growX=1,
                                    background="#F4F7FF", border="#7893BC", textColor="#172B46"))
    enabled = GeneratedNode(1, "generated-enabled", "booleanInput", "enabled", None,
                            properties(label="生成启用", fixedHeight=42, growX=1,
                                       background="#F4F7FF", border="#7893BC", textColor="#172B46"))
    children = [enabled, name, records] if rearranged else [records, name, enabled]
    if remove_editor:
        children = [node for node in children if node.key != "generated-name"]
    return [GeneratedNode(0, "collection-shell", "vertical", None, None,
                          properties(growX=1, gap=8)), *children]


def slider_layout():
    return [GeneratedNode(0, "slider-shell", "vertical", None, None, properties(gap=12, growX=1)),
            GeneratedNode(1, "slider-heading", "label", None, None,
                          properties(text="生成保留天数 · 与右侧共用字段", fixedHeight=30, textColor="#D6E4FF")),
            GeneratedNode(1, "generated-retention-slider", "slider", "retentionCount", None,
                          properties(label="生成保留天数", fixedHeight=36, growX=1, step=1)),
            GeneratedNode(1, "retention-draft-editor", "integerInput", "retentionCount", None,
                          properties(label="原始整数草稿", fixedHeight=42, growX=1,
                                     background="#F4F7FF", border="#7893BC", textColor="#172B46")),
            GeneratedNode(1, "records", "ruleCollection", None, None,
                          properties(collection="rules", presentation="list", fixedHeight=240, growX=1))]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("operation", choices=["inspect", "list", "table", "rearrange", "reject", "read",
                                             "keyboard", "keyboard-rearrange", "keyboard-remove", "sliders"])
    parser.add_argument("--descriptor", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    session = GeneratedUiSession.connect(args.descriptor)
    result = {"operation": args.operation, "before": asdict(session.structure())}
    if args.operation == "inspect":
        result["capabilities"] = asdict(session.capabilities())
    elif args.operation in ("list", "table", "rearrange", "reject",
                             "keyboard", "keyboard-rearrange", "keyboard-remove", "sliders"):
        caps = session.capabilities()
        component = caps.component("ruleCollection")
        if component is None:
            raise RuntimeError("application has not registered the collection")
        wanted = layout("table" if args.operation in ("table", "rearrange") else "list",
                        horizontal=args.operation == "rearrange",
                        reference="unregistered" if args.operation == "reject" else "rules")
        if args.operation.startswith("keyboard"):
            wanted = keyboard_layout(args.operation != "keyboard", args.operation == "keyboard-remove")
        if args.operation == "sliders":
            wanted = slider_layout()
        # submit_text exercises the server's own rejection for an unregistered
        # reference; the regular typed submit validates against the same catalog.
        if args.operation == "reject":
            from cjgui_generated_client import encode_generated_structure
            reply = session.submit_text(encode_generated_structure(wanted), result["before"]["version"])
        else:
            reply = session.submit(wanted, result["before"]["version"])
        result["submit"] = asdict(reply)
        if reply.candidate_accepted:
            result["terminal"] = asdict(session.wait_for_candidate(reply.ticket(), timeout_ms=5000))
            assert result["terminal"]["terminal_state"] == "ACCEPTED", result["terminal"]
        else:
            assert args.operation == "reject", result["submit"]
    result["structure"] = asdict(session.structure())
    result["form"] = asdict(session.form_state())
    result["instances"] = asdict(session.instances())
    if args.operation == "reject":
        assert result["before"] == result["structure"], result
    text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(text)
    else:
        print(text)


if __name__ == "__main__":
    main()
