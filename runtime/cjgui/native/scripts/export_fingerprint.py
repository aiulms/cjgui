#!/usr/bin/env python3
"""Byte-identity and fingerprint check for the framework preview export.

ONE explicit list drives the per-file comparison, the per-file hash and the
aggregate fingerprint, so the recorded file count is exactly the number of
hashed inputs and no subset can be reported as "the whole SDK fingerprint".

Usage:
    export_fingerprint.py <export-root> <runtime-dir> <repository-root>

Exit 0 prints:
    files=<n> sha256=<aggregate> rewritten=<m>
    file <export-relative> sha256=<per-file> bytes=<size>
    ... one line per hashed input
Non-zero exit prints the concrete mismatch to stderr.

`<runtime-dir>` is the author `runtime/cjgui` checkout; `<repository-root>` is
the checkout root (for the LICENSE/NOTICE copies).
"""
import glob
import hashlib
import os
import sys

# <export-relative dir>|<author root: runtime|repo>|<mirrored author-relative dir>|<file pattern>|<min files>
#
# The export side is the whitelist: for every exported file the SAME relative
# path must exist under the mirrored author directory and be byte-identical.
# Tests and probes the export deliberately omits are therefore not treated as
# missing. The minimum turns a silently-empty pattern into a failure instead of
# a shrinking list.
IDENTICAL_SPECS = [
    ("framework/cjgui/src", "runtime", "src", "*.cj", 10),
    ("framework/cjgui/shared_operation_core/src", "runtime",
     "shared_operation_core/src", "*.cj", 9),
    ("framework/cjgui/shared_operation_core", "runtime",
     "shared_operation_core", "cjpm.toml", 1),
    ("framework/cjgui/shared_operation_core", "runtime",
     "shared_operation_core", "client.py", 1),
    ("framework/cjgui/native", "runtime", "native", "*.m", 3),
    ("framework/cjgui/native", "runtime", "native", "*.h", 2),
    ("framework/cjgui/resources", "runtime", "resources", "*.png", 2),
    ("framework/cjgui/scripts", "runtime", "scripts", "*.sh", 2),
    ("framework/cjgui/templates/macos_application", "runtime",
     "templates/macos_application", "*/*", 6),
    ("framework/cjgui/templates/macos_application", "runtime",
     "templates/macos_application", "*/*/*", 2),
    ("framework/cjgui", "runtime", ".", "README.md", 1),
    ("framework/cjgui", "repo", ".", "LICENSE", 1),
    ("framework/cjgui", "repo", ".", "NOTICE", 1),
    ("framework/cjgui/shared_operation_core", "repo", ".", "LICENSE", 1),
    ("framework/cjgui/shared_operation_core", "repo", ".", "NOTICE", 1),
    ("framework/rule_set_application/src", "runtime",
     "examples/rule_set_application/src", "*.cj", 2),
    ("consumers/tree_outline_consumer/src", "runtime",
     "examples/tree_outline_consumer/src", "*.cj", 2),
    ("consumers/generated_panel_consumer/src", "runtime",
     "examples/generated_panel_consumer/src", "*.cj", 3),
    ("consumers/rule_set_window_app/src", "runtime",
     "examples/rule_set_window_app/src", "*.cj", 6),
]

# Build entries the export deliberately REWRITES (package cjpm.toml dependency
# paths, consumer launchers). They must exist, but they are not byte-identical to
# the author copy, so they are never hashed as if they were.
REWRITTEN_ENTRIES = [
    "framework/rule_set_application/cjpm.toml",
    "consumers/tree_outline_consumer/cjpm.toml",
    "consumers/generated_panel_consumer/cjpm.toml",
    "consumers/rule_set_window_app/cjpm.toml",
    "consumers/tree_outline_consumer/run.sh",
    "consumers/generated_panel_consumer/run.sh",
    "consumers/rule_set_window_app/run.sh",
    "preview-manifest.md",
]


def check(export_root, runtime_dir, repo_dir):
    roots = {"runtime": runtime_dir, "repo": repo_dir}
    total = 0
    digest = hashlib.sha256()
    lines = []
    for export_dir, root_name, author_dir, pattern, minimum in IDENTICAL_SPECS:
        # Only regular files are compared: a template pattern like `*/*` also
        # matches the `src` directory itself.
        export_matches = [path for path in sorted(glob.glob(os.path.join(export_root, export_dir, pattern)))
                          if os.path.isfile(path)]
        if len(export_matches) < minimum:
            raise SystemExit("%s/%s matched %d < %d"
                             % (export_dir, pattern, len(export_matches), minimum))
        for export_file in export_matches:
            relative = os.path.relpath(export_file, os.path.join(export_root, export_dir))
            author_file = os.path.join(roots[root_name], author_dir, relative)
            if not os.path.isfile(author_file):
                raise SystemExit("exported %s has no author original at %s"
                                 % (os.path.join(export_dir, relative), author_file))
            export_bytes = open(export_file, "rb").read()
            author_bytes = open(author_file, "rb").read()
            if export_bytes != author_bytes:
                raise SystemExit("exported %s differs from the author source"
                                 % os.path.join(export_dir, relative))
            export_relative = os.path.relpath(export_file, export_root)
            file_hash = hashlib.sha256(export_bytes).hexdigest()
            lines.append("file %s sha256=%s bytes=%d"
                         % (export_relative, file_hash, len(export_bytes)))
            digest.update(export_relative.encode())
            digest.update(b"\0")
            digest.update(file_hash.encode())
            digest.update(b"\n")
            total += 1
    for relative in REWRITTEN_ENTRIES:
        if not os.path.isfile(os.path.join(export_root, relative)):
            raise SystemExit("rewritten build entry missing from export: %s" % relative)
    print("files=%d sha256=%s rewritten=%d" % (total, digest.hexdigest(), len(REWRITTEN_ENTRIES)))
    for line in lines:
        print(line)


def main():
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    check(sys.argv[1], sys.argv[2], sys.argv[3])


if __name__ == "__main__":
    main()
