#!/usr/bin/env python3
"""Small consumer example for the public fixed-workspace document client."""
import argparse
import json
from pathlib import Path
import sys


MAX_RANGE_BYTES = 64 * 1024


def _shared_core(sdk_root):
    if sdk_root is None:
        # The exporter rewrites this path to the SDK's framework directory.
        core = Path(__file__).resolve().parents[2] / "shared_operation_core"
    else:
        core = Path(sdk_root).expanduser().resolve() / "framework/cjgui/shared_operation_core"
    if not (core / "client.py").is_file() or not (core / "cjgui_document_client.py").is_file():
        raise FileNotFoundError(f"shared-operation SDK sources not found under {core}")
    return core


def open_document_client(descriptor, sdk_root=None):
    core = str(_shared_core(sdk_root))
    if core not in sys.path:
        sys.path.insert(0, core)
    from client import SharedOperationClient
    from cjgui_document_client import DocumentClient

    transport = SharedOperationClient.from_descriptor(descriptor)
    return DocumentClient(transport, binding_contract="fixed_text_document_workspace")


def read_short_document(api, resource_id):
    target = api.target(resource_id)
    if target.byte_length > MAX_RANGE_BYTES:
        raise ValueError("this example reads one range; document exceeds the 64 KiB range bound")
    result = api.read(target, 0, target.byte_length)
    if not result.available or result.conflict or result.content is None:
        raise ValueError(f"document read unavailable: {result.reason}")
    if result.version != target.document_version:
        raise ValueError("range version does not match the captured document target")
    if len(result.content.encode("utf-8")) != target.byte_length:
        raise ValueError("range byte length does not match the captured target")
    return target, result.content


def replace_once(api, target, start, end, text):
    """Apply once against the supplied target; the caller handles every outcome."""
    return api.replace(target, start, end, text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--descriptor", required=True, type=Path,
                        help="descriptor issued by the running application")
    parser.add_argument("--resource-id", required=True, type=int,
                        help="actual text_document id discovered from the app context")
    parser.add_argument("--sdk-root", type=Path,
                        help="exported SDK root; needed when this caller is outside the SDK")
    parser.add_argument("--start", type=int, help="UTF-8 byte start for one explicit replacement")
    parser.add_argument("--end", type=int, help="UTF-8 byte end for one explicit replacement")
    parser.add_argument("--text", help="replacement text; requires --start and --end")
    parser.add_argument("--show-text", action="store_true", help="include the read document in stdout")
    args = parser.parse_args()
    replacement_values = (args.start, args.end, args.text)
    if any(value is not None for value in replacement_values) and any(
        value is None for value in replacement_values
    ):
        parser.error("--start, --end, and --text must be supplied together")

    try:
        api = open_document_client(args.descriptor, args.sdk_root)
        target, content = read_short_document(api, args.resource_id)
        exit_status = 0
        output = {
            "resource_id": target.resource_id,
            "document_version": target.document_version,
            "aggregate_version": target.aggregate_version,
            "byte_length": target.byte_length,
            "readback_bytes": len(content.encode("utf-8")),
        }
        if args.show_text:
            output["content"] = content
        if args.start is not None:
            mutation = replace_once(api, target, args.start, args.end, args.text)
            output["mutation"] = {
                "outcome": mutation.outcome,
                "reason": mutation.reason,
                "version_before": mutation.version_before,
                "version_after": mutation.version_after,
                "version_domain": mutation.version_domain,
            }
            if mutation.outcome == "unknown":
                exit_status = 3
            elif mutation.outcome in ("conflict", "rejected"):
                exit_status = 2
        print(json.dumps(output, ensure_ascii=False, sort_keys=True))
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    return exit_status


if __name__ == "__main__":
    raise SystemExit(main())
