"""Device-side capture facts, qualified against the original gesture and paint journal.

Exact brackets are sufficient evidence, not a requirement that redraw stop globally.
Changed frames need body/selection/geometry evidence; this module never invents it.
"""
import re
from pathlib import Path

DAY = 86_400_000_000_000
FIELDS = ("session", "ticket", "projection", "paintSeq", "choiceNode",
          "choiceBinding", "choiceOwner", "choiceRevision", "choiceAnchor",
          "choiceFocus", "choiceTargetBinding")
SUFFIXES = ("before", "after", "capture-start", "capture-end",
            "capture-begin-clock", "capture-end-clock")


def clock_ns(row):
    hit = re.match(r"(\d\d-\d\d) (\d\d):(\d\d):(\d\d)\.(\d{3,9})", row)
    if not hit:
        raise ValueError("device clock absent")
    hour, minute, second = map(int, hit.group(2, 3, 4))
    return hit[1], (hour * 3600 + minute * 60 + second) * 10**9 + int(hit[5].ljust(9, "0"))


def frame(row):
    prefix = re.match(r"\d\d-\d\d \d\d:\d\d:\d\d\.\d{3,9}\s+(\d+)\s+\d+\s", row)
    if not prefix or "text feedback " not in row:
        raise ValueError("device paint fact absent")
    stamp = {k: int(v) for k, v in re.findall(r"(\w+)=(-?\d+)", row) if k in FIELDS}
    if set(stamp) != set(FIELDS):
        raise ValueError("device paint identity incomplete")
    basis = re.search(r"choiceBasis=([0-9,]+)(?:\s|$)", row)
    if not basis or len(basis[1].split(",")) != 12:
        raise ValueError("source basis incomplete")
    stamp["choiceBasis"] = basis[1]
    return {"pid": prefix[1], "clock": clock_ns(row), "identity": stamp, "raw": row}


def load_archived_bracket(base):
    return {suffix: Path(str(base) + "." + suffix).read_text().strip() for suffix in SUFFIXES}


def emitted_bracket(text):
    result = {}
    for suffix in SUFFIXES:
        match = re.search(rf"^H_CAPTURE_FIELD {re.escape(suffix)}\n(.*?)^H_CAPTURE_END {re.escape(suffix)}$",
                          text, re.MULTILINE | re.DOTALL)
        if not match:
            raise ValueError(f"device capture field missing: {suffix}")
        result[suffix] = match[1].strip()
    return result


def gesture_interval(rows, pid):
    touches = []
    for row in rows:
        if not re.search(rf"\s{re.escape(str(pid))}\s+\d+\s", row):
            continue
        match = re.search(r"raw touch action=(\d+) x=(-?\d+) y=(-?\d+) ep=(\d+)", row)
        if match:
            date, when = clock_ns(row)
            touches.append((when, int(match[1]), int(match[4]), date))
    touches.sort()
    begin = [t for t in touches if t[1] == 37]
    end = [t for t in touches if t[1] == 39]
    if len(begin) != 1 or len(end) != 1 or len({t[2] for t in touches}) != 1 or len({t[3] for t in touches}) != 1:
        raise ValueError("one original physical BEGIN/UP on one device day required")
    if begin[0][0] >= end[0][0]:
        raise ValueError("physical UP precedes BEGIN")
    return {"pid": str(pid), "day": begin[0][3], "epoch": begin[0][2],
            "begin": begin[0][0], "end": end[0][0]}


def qualify_capture(bracket, rows, expected, gesture):
    out = {"qualified": False, "exact": False, "held": False, "reasons": []}
    try:
        before, after = frame(bracket["before"]), frame(bracket["after"])
        day, begin = clock_ns(bracket["capture-begin-clock"])
        end_day, end = clock_ns(bracket["capture-end-clock"])
        epoch_begin, epoch_end = map(int, (bracket["capture-start"], bracket["capture-end"]))
        # Resolve the device clock's minute timezone offset using its own epoch,
        # then include the slightly wider physical snapshot timestamps as well.
        offset = round(((begin - epoch_begin % DAY + DAY // 2) % DAY - DAY // 2) / (60 * 10**9)) * 60 * 10**9
        physical_begin, physical_end = (epoch_begin + offset) % DAY, (epoch_end + offset) % DAY
        if not (0 <= begin - physical_begin < 10**9 and 0 <= end - physical_end < 10**9):
            raise ValueError("device epoch/clock pair inconsistent")
        begin, end = min(begin, physical_begin), max(end, physical_end)
        out.update(frame_before=before, frame_after=after, capture_day=day,
                   capture_begin_ns=begin, capture_end_ns=end,
                   snapshot_duration_ns=epoch_end - epoch_begin)
        if day != end_day or begin >= end or epoch_begin >= epoch_end:
            raise ValueError("capture interval invalid")
        out["held"] = bool(gesture.get("end") is not None and day == gesture["day"] and
                           str(expected["pid"]) == gesture["pid"] and
                           gesture["begin"] <= begin < end < gesture["end"])
        if not out["held"]:
            out["reasons"].append("capture-outside-original-BEGIN-UP")
        a, b = before["identity"], after["identity"]
        basis = list(map(int, a["choiceBasis"].split(",")))
        same_source = all(a[key] == b[key] for key in FIELDS if key not in ("ticket", "projection", "paintSeq")) and a["choiceBasis"] == b["choiceBasis"]
        out["exact"] = a == b
        out["frame_status"] = ("exact-device-bracket" if out["exact"] else
                               "source-stable-geometry-unproven" if same_source else
                               "source-changed-during-capture")
        if not out["exact"]:
            out["reasons"].append(out["frame_status"])
        origin_ok = (before["pid"] == after["pid"] == str(expected["pid"]) and
                     a["session"] == b["session"] == expected["session"] and
                     a["choiceNode"] == b["choiceNode"] == expected["node"] and
                     a["choiceBinding"] == b["choiceBinding"] == expected["binding"] and
                     a["choiceTargetBinding"] == b["choiceTargetBinding"] == expected["target_binding"] and
                     a["choiceOwner"] == b["choiceOwner"] == expected["owner"] and
                     basis[:6] == expected["window"] and basis[6:10] ==
                     [a["choiceOwner"], a["choiceRevision"], a["choiceAnchor"], a["choiceFocus"]])
        out["frozen_origin_matches"] = origin_ok
        if not origin_ok:
            out["reasons"].append("frozen-owner-source-target-mismatch")
        paints = []
        for row in rows:
            if "text feedback " not in row or "choiceOwner=" not in row:
                continue
            try:
                fact = frame(row)
            except ValueError:
                continue
            if fact["pid"] == str(expected["pid"]) and fact["clock"][0] == day:
                paints.append(fact)
        def latest(when):
            candidates = [p for p in paints if p["clock"][1] <= when]
            return max(candidates, key=lambda p: (p["clock"][1], p["identity"]["paintSeq"])) if candidates else None
        start_paint, end_paint = latest(begin), latest(end)
        journal_ok = (start_paint is not None and end_paint is not None and
                      start_paint["identity"] == a and end_paint["identity"] == b)
        out["chronological_journal_matches"] = journal_ok
        if not journal_ok:
            out["reasons"].append("device-bracket-not-current-in-original-paint-journal")
        out["qualified"] = not out["reasons"]
    except (ValueError, KeyError, TypeError) as error:
        out["reasons"].append(str(error))
    return out


def causal_pairs(captures, rows, gesture, static_interval):
    start, end = static_interval
    causes = []
    for row in rows:
        if "EDGE_DWELL stage=recomputed" not in row or not re.search(rf"\s{gesture['pid']}\s+\d+\s", row):
            continue
        day, when = clock_ns(row)
        if day != gesture["day"] or not (start[0] + 100) * 10**6 <= when < end[0] * 10**6:
            continue
        fact = {k: int(v) for k, v in re.findall(r"(gesture|binding|scene|node|resource|kind|acceptedOffset|solve|request)=(\d+)", row)}
        basis = re.search(r"choiceBasis=([0-9,]+)", row)
        if basis and fact.get("request", 0) > 0 and fact.get("solve", 0) > 0 and fact.get("gesture") == gesture["epoch"]:
            fact["choiceBasis"] = basis[1]
            causes.append(fact)
    pairs, seen = [], set()
    for index, capture in enumerate(captures):
        if not capture["qualified"] or not start[0] * 10**6 <= capture["capture_begin_ns"] < capture["capture_end_ns"] < end[0] * 10**6:
            continue
        f = capture["frame_before"]["identity"]
        matches = [c for c in causes if c["choiceBasis"] == f["choiceBasis"] and c["node"] == f["choiceNode"] and c["binding"] == f["choiceTargetBinding"] and f["projection"] >= c["scene"]]
        key = (f["session"], f["ticket"], f["paintSeq"], f["choiceRevision"])
        if len(matches) != 1 or key in seen or f["choiceAnchor"] == f["choiceFocus"]:
            continue
        seen.add(key)
        pairs.append({"sample": index, "scroll": matches[0], "frame": f,
                      "range": [f["choiceAnchor"], f["choiceFocus"]]})
    return pairs
