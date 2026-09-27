#!/usr/bin/env python3
"""Byte-identity, payload hash and fingerprint check for the framework preview export.

ONE explicit list drives the per-file comparison, the per-file hash and the
aggregate fingerprint. Both categories are hashed by FINAL exported content and
relative path, so the aggregate covers the whole exported payload instead of an
author-identical subset:

  * author-identical files, whose exported bytes must equal the author original;
  * deliberately rewritten entries (package cjpm.toml dependency paths, consumer
    launchers, the preview manifest), which must exist and are hashed as
    exported; no byte-identity claim is made for them, because the payload copy
    is not supposed to equal the author file.

Usage:
    export_fingerprint.py <export-root> <runtime-dir> <repository-root>

Exit 0 prints:
    files=<n> identical=<i> rewritten=<m> sha256=<aggregate>
    file <export-relative> sha256=<per-file> bytes=<size> origin=<identical|rewritten>
    ... one line per hashed input, sorted by export-relative path
Non-zero exit prints the concrete mismatch to stderr.

`<runtime-dir>` is the author `runtime/cjgui` checkout; `<repository-root>` is
the checkout root (for the LICENSE/NOTICE copies).
"""
import glob
import hashlib
import os
import subprocess
import sys

# <export-relative dir>|<author root: runtime|repo>|<mirrored author-relative dir>|<file pattern>|<min files>
#
# The export side is the whitelist: for every exported file the SAME relative
# path must exist under the mirrored author directory and be byte-identical.
# Tests and probes the export deliberately omits are therefore not treated as
# missing. The minimum turns a silently-empty pattern into a failure instead of
# a shrinking list; it is set to the count this export currently ships, so a
# dropped file fails here rather than quietly shrinking the payload.
IDENTICAL_SPECS = [
    ("framework/cjgui/src", "runtime", "src", "@framework-source-set", 0),
    ("framework/cjgui/shared_operation_core/src", "runtime",
     "shared_operation_core/src", "*.cj", 9),
    ("framework/cjgui/shared_operation_core", "runtime",
     "shared_operation_core", "cjpm.toml", 1),
    ("framework/cjgui/shared_operation_core", "runtime",
     "shared_operation_core", "client.py", 1),
    ("framework/cjgui/shared_operation_core", "runtime",
     "shared_operation_core", "cjgui_generated_client.py", 1),
    ("framework/cjgui/shared_operation_core", "runtime",
     "shared_operation_core", "example_generated_consumption.py", 1),
    ("framework/cjgui/shared_operation_core", "runtime",
     "shared_operation_core", "example_generated_observation.py", 1),
    ("framework/cjgui/shared_operation_core", "runtime",
     "shared_operation_core", "example_generated_candidate_race.py", 1),
    ("framework/cjgui/native", "runtime", "native", "*.m", 3),
    ("framework/cjgui/native", "runtime", "native", "*.h", 2),
    ("framework/cjgui/resources", "runtime", "resources", "*.png", 2),
    ("framework/cjgui/scripts", "runtime", "scripts", "*.sh", 2),
    ("framework/cjgui/templates/macos_application", "runtime",
     "templates/macos_application", "*/*", 6),
    ("framework/cjgui/templates/macos_application", "runtime",
     "templates/macos_application", "*/*/*", 2),
    ("framework/cjgui", "runtime", ".", "README.md", 1),
    # The application-host quick start travels with the README so the README's
    # primary onboarding pointer resolves inside the export.
    ("framework/cjgui", "runtime", ".", "MACOS_APPLICATION_HOST.md", 1),
    # The framework package manifest is copied verbatim; it is part of the payload.
    ("framework/cjgui", "runtime", ".", "cjpm.toml", 1),
    ("framework/cjgui", "repo", ".", "LICENSE", 1),
    ("framework/cjgui", "repo", ".", "NOTICE", 1),
    # The preview ROOT carries the same licence text, and the exported
    # rule-set application keeps its lock so the exported graph builds
    # reproducibly; both are part of the immutable payload.
    (".", "repo", ".", "LICENSE", 1),
    (".", "repo", ".", "NOTICE", 1),
    ("framework/rule_set_application", "runtime",
     "examples/rule_set_application", "cjpm.lock", 1),
    ("framework/cjgui/shared_operation_core", "repo", ".", "LICENSE", 1),
    ("framework/cjgui/shared_operation_core", "repo", ".", "NOTICE", 1),
    ("framework/rule_set_application/src", "runtime",
     "examples/rule_set_application/src", "*.cj", 2),
    ("consumers/tree_outline_consumer/src", "runtime",
     "examples/tree_outline_consumer/src", "*.cj", 2),
    ("consumers/generated_panel_consumer/src", "runtime",
     "examples/generated_panel_consumer/src", "*.cj", 4),
    ("consumers/rule_set_window_app/src", "runtime",
     "examples/rule_set_window_app/src", "*.cj", 7),
    # Consumer launchers are copied verbatim (only run.sh is path-rewritten).
    ("consumers/tree_outline_consumer", "runtime",
     "examples/tree_outline_consumer", "cjgui_macos_app.sh", 1),
    ("consumers/generated_panel_consumer", "runtime",
     "examples/generated_panel_consumer", "cjgui_macos_app.sh", 1),
    ("consumers/generated_panel_consumer", "runtime",
     "examples/generated_panel_consumer", "verify_generated_effect_candidates.py", 1),
    ("consumers/generated_panel_consumer", "runtime",
     "examples/generated_panel_consumer", "verify_public_effect_observation.py", 1),
    ("consumers/generated_panel_consumer", "runtime",
     "examples/generated_panel_consumer", "verify_public_window_material.py", 1),
    ("consumers/rule_set_window_app", "runtime",
     "examples/rule_set_window_app", "cjgui_macos_app.sh", 1),
    # The UI-only consumer ships in the preview too (see PREVIEW_CONSUMERS in
    # export_framework_preview.sh): its source and launcher are byte-identical,
    # while its cjpm.toml/run.sh are path-rewritten build entries.
    ("consumers/adaptive_layout_public_consumer/src", "runtime",
     "examples/adaptive_layout_public_consumer/src", "*.cj", 1),
    ("consumers/adaptive_layout_public_consumer", "runtime",
     "examples/adaptive_layout_public_consumer", "cjgui_macos_app.sh", 1),
]


def framework_source_names(runtime_dir):
    """Read the same ordered source set used by standalone probes and export."""
    helper = os.path.join(runtime_dir, "native", "scripts", "lib_cjgui_source_set.sh")
    result = subprocess.run(
        ["zsh", "-c", 'source "$1"; cjgui_framework_source_names true',
         "cjgui-source-set", helper],
        check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    names = result.stdout.splitlines()
    if not names or len(names) != len(set(names)) or any(
            os.path.basename(name) != name or not name.endswith(".cj") for name in names):
        raise SystemExit("framework source-set helper returned an invalid or duplicate source name")
    return names

# Build entries the export deliberately REWRITES (package cjpm.toml dependency
# paths, consumer run.sh launchers, the preview manifest). They must exist and
# are hashed as exported content, but they are never compared byte-for-byte with
# an author copy.
REWRITTEN_ENTRIES = [
    "framework/rule_set_application/cjpm.toml",
    "consumers/tree_outline_consumer/cjpm.toml",
    "consumers/generated_panel_consumer/cjpm.toml",
    "consumers/rule_set_window_app/cjpm.toml",
    "consumers/adaptive_layout_public_consumer/cjpm.toml",
    "consumers/tree_outline_consumer/run.sh",
    "consumers/generated_panel_consumer/run.sh",
    "consumers/rule_set_window_app/run.sh",
    "consumers/adaptive_layout_public_consumer/run.sh",
    "preview-manifest.md",
]


def is_generated_artifact(relative):
    """Files that legitimately appear only after the export root is built or run.

    Everything else in the export tree must be a declared payload input, so an
    unexplained file is reported instead of silently ignored. The author's own
    files are never touched: these paths exist inside the EXPORT COPY.
    """
    normalized = "/" + relative.replace(os.sep, "/")
    # The two-consumer verifier writes its own result after the export is
    # built. cjpm likewise writes consumer lock files during that build; the
    # preview exporter does not copy those files as payload inputs.
    if relative == "CONSUMER_FINGERPRINTS.txt":
        return True
    if relative.startswith("consumers/") and os.path.basename(relative) == "cjpm.lock":
        return True
    for marker in ("/target/", "/.cjgui/", "/native/lib/", "/__pycache__/"):
        if marker in normalized:
            return True
    name = os.path.basename(relative)
    return (name.endswith(".log") or name.endswith(".pyc") or name == ".DS_Store")


def check(export_root, runtime_dir, repo_dir):
    roots = {"runtime": runtime_dir, "repo": repo_dir}
    entries = []
    source_names = None
    for export_dir, root_name, author_dir, pattern, minimum in IDENTICAL_SPECS:
        # Only regular files are compared: a template pattern like `*/*` also
        # matches the `src` directory itself.
        if pattern == "@framework-source-set":
            if source_names is None:
                source_names = framework_source_names(runtime_dir)
            source_dir = os.path.join(export_root, export_dir)
            export_matches = [os.path.join(source_dir, name) for name in source_names]
            actual_sources = {os.path.basename(path) for path in glob.glob(os.path.join(source_dir, "*.cj"))
                              if os.path.isfile(path)}
            if actual_sources != set(source_names):
                missing = sorted(set(source_names) - actual_sources)
                extra = sorted(actual_sources - set(source_names))
                raise SystemExit("exported framework source set differs from the shared manifest "
                                 "(missing=%s extra=%s)" % (missing, extra))
        else:
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
            with open(export_file, "rb") as handle:
                export_bytes = handle.read()
            with open(author_file, "rb") as handle:
                author_bytes = handle.read()
            if export_bytes != author_bytes:
                raise SystemExit("exported %s differs from the author source"
                                 % os.path.join(export_dir, relative))
            entries.append((os.path.relpath(export_file, export_root), export_bytes, "identical"))
    for relative in REWRITTEN_ENTRIES:
        export_file = os.path.join(export_root, relative)
        if not os.path.isfile(export_file):
            raise SystemExit("rewritten build entry missing from export: %s" % relative)
        with open(export_file, "rb") as handle:
            entries.append((relative, handle.read(), "rewritten"))

    # Set reconciliation instead of a growing fixed count: every file that really
    # exists in the export tree must be either a hashed payload input or a known
    # generated artifact. A new exported file that nobody added to the lists is
    # therefore a failure, which fixed-count checks cannot catch.
    hashed = set(relative for relative, _data, _origin in entries)
    unexplained = []
    for dirpath, _dirnames, filenames in os.walk(export_root):
        for name in filenames:
            relative = os.path.relpath(os.path.join(dirpath, name), export_root)
            if relative in hashed or is_generated_artifact(relative):
                continue
            unexplained.append(relative)
    if unexplained:
        raise SystemExit("exported file(s) are neither declared payload inputs nor known "
                         "generated artifacts: " + ", ".join(sorted(unexplained)))

    # Hash the FINAL exported content keyed by relative path, sorted so the
    # digest does not depend on the order of the spec lists above.
    entries.sort(key=lambda entry: entry[0])
    digest = hashlib.sha256()
    lines = []
    for relative, data, origin in entries:
        file_hash = hashlib.sha256(data).hexdigest()
        lines.append("file %s sha256=%s bytes=%d origin=%s"
                     % (relative, file_hash, len(data), origin))
        digest.update(relative.encode())
        digest.update(b"\0")
        digest.update(file_hash.encode())
        digest.update(b"\n")
    identical = sum(1 for entry in entries if entry[2] == "identical")
    rewritten = len(entries) - identical
    print("files=%d identical=%d rewritten=%d sha256=%s"
          % (len(entries), identical, rewritten, digest.hexdigest()))
    for line in lines:
        print(line)


def main():
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    check(sys.argv[1], sys.argv[2], sys.argv[3])


if __name__ == "__main__":
    main()
