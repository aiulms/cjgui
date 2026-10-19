#!/usr/bin/env python3
"""Replay the original device capture; never send a second physical gesture."""
import argparse
import copy
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--original", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--legacy", action="store_true")
    args = parser.parse_args()
    original = args.original
    samples = json.loads((original / "samples.json").read_text())
    result = json.loads((original / "result.json").read_text())
    cases = []
    if args.legacy:
        for index in (8, 16):
            cases.append({"case": f"device-held-{index}",
                          "ok": samples[index]["capture_held"],
                          "expected": True,
                          "scope": "Original host-ring-last-row held decision"})
    else:
        from h_capture_frame_evidence import (
            load_archived_bracket, qualify_capture, gesture_interval, causal_pairs,
        )
        rows = (original / "dwell-hilog.txt").read_text().splitlines()
        gesture = gesture_interval(rows, result["pid"])
        root, = (original / "device-capture-originals").iterdir()
        expected = {"pid": result["pid"], "node": result["actual_note_node"],
                    "session": 1, "binding": 1, "target_binding": 1,
                    "owner": result["after"]["version"] - 1,
                    "window": [1, 2, 1, 1, 0, 61]}
        captures = []
        for index in range(len(samples)):
            bracket = load_archived_bracket(root / f'{result["pid"]}-gesture-{index:02d}')
            captures.append(qualify_capture(bracket, rows, expected, gesture))
        for index in (8, 16):
            cases.append({"case": f"device-held-and-exact-{index}",
                          "ok": captures[index]["held"] and captures[index]["exact"],
                          "expected": True})
        mutations = []
        bracket = load_archived_bracket(root / f'{result["pid"]}-gesture-08')
        for key, value in (("pid", "5693"), ("node", 26), ("owner", 2),
                           ("binding", 2), ("target_binding", 2),
                           ("window", [1, 2, 2, 1, 0, 61])):
            wrong = copy.deepcopy(expected)
            wrong[key] = value
            mutations.append((f"reject-wrong-{key}", bracket, wrong, gesture))
        old = copy.deepcopy(bracket)
        old["before"] = samples[8]["frame_before"]["raw"]
        mutations.append(("reject-stale-host-before-paint", old, expected, gesture))
        no_up = copy.deepcopy(gesture)
        no_up["end"] = None
        mutations.append(("reject-missing-original-UP", bracket, expected, no_up))
        for name, changed, identity, interval in mutations:
            q = qualify_capture(changed, rows, identity, interval)
            cases.append({"case": name, "ok": not q["qualified"], "expected": True,
                          "reasons": q["reasons"]})
        cases.append({"case": "after-UP-cannot-be-held", "ok": not captures[17]["held"],
                      "expected": True})
        pairs = causal_pairs(captures, rows, gesture, result["static_intervals"][0])
        cases.append({"case": "first-static-gate-still-RED", "ok": len(pairs) < 3,
                      "expected": True})
        args.out.parent.mkdir(parents=True, exist_ok=True)
        replay = {"original_result_ok": result["ok"], "original_strict_pairs":
                  len(result["static_causal_frame_pairs"]), "gesture": gesture,
                  "captures": captures, "first_static_pairs": pairs,
                  "picture_gate_passed": len({tuple(p["range"]) for p in pairs}) >= 3,
                  "scope": "Archived original device brackets; no new pixels, SDK run or input"}
        args.out.with_name(args.out.stem + "-replay.json").write_text(json.dumps(replay, indent=2))
    passed = all(case["ok"] == case["expected"] for case in cases)
    args.out.write_text(json.dumps({"ok": passed, "cases": cases}, indent=2))
    print(json.dumps({"ok": passed, "cases": len(cases), "legacy": args.legacy}))
    return 0 if passed else 2


if __name__ == "__main__":
    raise SystemExit(main())
