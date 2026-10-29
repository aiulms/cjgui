#!/usr/bin/env python3
"""A portable `cjgui.ui-document` file: a complete runtime interface description.

The document is deliberately NOT a saved plan and NOT a receipt:

* a saved plan is bound to one endpoint instance and one baseline version and is
  refused after either changes;
* a receipt describes what one real ticket did and is query-only;
* this document describes layout, runtime composition definitions and the
  declarations they reference. Importing it discovers the CURRENT endpoint,
  validates against its current catalog, and builds a NEW plan on the current
  accepted baseline.

It carries no endpoint/socket, ticket, structure version, native node id,
incarnation, selection, focus, draft/applied value, authorization token or
absolute temporary path. Stable instance keys, field/action names and resource
keys are declarations and are preserved.

File IO is bounded and atomic: a failed write keeps the previous file, and an
unknown/lossy body is readable but never silently pruned into an executable
document.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import stat
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from cjgui_generated_client import (
    GeneratedEndpointIdentity,
    GeneratedSnapshot,
    GeneratedStructure,
    GeneratedStructureDocument,
    GeneratedUiError,
    encode_generated_structure_document,
    parse_generated_structure_document,
)
from cjgui_generated_edit import (
    GeneratedEditError,
    GeneratedEditPreview,
    preview_document,
    structure_document_digest,
    structure_from_snapshot,
)

UI_DOCUMENT_FORMAT = "cjgui.ui-document"
UI_DOCUMENT_VERSION = 1
UI_DOCUMENT_MAX_BYTES = 4 * 1024 * 1024
#: The Cangjie structure decoder refuses a candidate larger than this, so an
#: exported document that carries more could never be started by the window.
#: Keep both ends on ONE limit instead of accepting a file the runtime rejects.
UI_DOCUMENT_STRUCTURE_MAX_BYTES = 256 * 1024
UI_DOCUMENT_KEYS = frozenset({
    "format", "format_version", "structure_format", "structure_sha256",
    "structure", "requirements",
})
REQUIREMENT_KEYS = frozenset({
    "components", "fields", "actions", "styles", "image_resources",
    "fonts", "runtime_compositions",
})
_SHA256_HEX = re.compile(r"^[0-9a-f]{64}$")


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _sha256_text(value: Any, what: str, code: str) -> str:
    if not isinstance(value, str) or _SHA256_HEX.fullmatch(value) is None:
        raise GeneratedEditError(code, f"{what} must be a lowercase sha256 hex digest")
    return value


def _object_without_duplicates(pairs: list[tuple[str, Any]], code: str) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise GeneratedEditError(code, f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def _json_object(text: str, what: str, code: str) -> Mapping[str, Any]:
    try:
        value = json.loads(
            text, object_pairs_hook=lambda pairs: _object_without_duplicates(pairs, code))
    except json.JSONDecodeError as error:
        raise GeneratedEditError(code, f"{what} is not valid JSON: {error}") from error
    if not isinstance(value, Mapping):
        raise GeneratedEditError(code, f"{what} must be an object")
    return value


def _utf8_length(value: str, what: str) -> int:
    try:
        return len(value.encode("utf-8"))
    except UnicodeEncodeError as error:
        raise GeneratedEditError("invalid_ui_document",
                                 f"{what} is not valid UTF-8") from error


def _text_list(value: Any, what: str) -> tuple[str, ...]:
    if not isinstance(value, list) or any(not isinstance(item, str) or not item
                                           for item in value):
        raise GeneratedEditError("invalid_ui_document",
                                 f"requirements.{what} must be a list of non-empty strings")
    return tuple(value)


@dataclass(frozen=True)
class UIDocumentRequirements:
    """Declarations derived from the actual references in the document.

    This is a discovery aid, never an authorization claim: import re-discovers
    the current endpoint catalog and refuses a missing declaration instead of
    trusting this list.
    """

    components: tuple[str, ...] = ()
    fields: tuple[str, ...] = ()
    actions: tuple[str, ...] = ()
    styles: tuple[str, ...] = ()
    image_resources: tuple[tuple[str, int], ...] = ()
    fonts: tuple[tuple[str, int], ...] = ()
    runtime_compositions: tuple[str, ...] = ()

    def to_dict(self) -> dict[str, Any]:
        return {
            "components": list(self.components),
            "fields": list(self.fields),
            "actions": list(self.actions),
            "styles": list(self.styles),
            "image_resources": [list(item) for item in self.image_resources],
            "fonts": [list(item) for item in self.fonts],
            "runtime_compositions": list(self.runtime_compositions),
        }

    def canonical(self) -> tuple[Any, ...]:
        """Order/duplicate-insensitive facts used to compare derived values."""
        return (
            tuple(sorted(set(self.components))),
            tuple(sorted(set(self.fields))),
            tuple(sorted(set(self.actions))),
            tuple(sorted(set(self.styles))),
            tuple(sorted(set(self.image_resources))),
            tuple(sorted(set(self.fonts))),
            tuple(sorted(set(self.runtime_compositions))),
        )

    @classmethod
    def from_dict(cls, value: Any) -> "UIDocumentRequirements":
        if not isinstance(value, Mapping) or set(value) != REQUIREMENT_KEYS:
            raise GeneratedEditError("invalid_ui_document",
                                     "requirements has an unknown or missing field")
        def resources(name: str) -> tuple[tuple[str, int], ...]:
            raw = value[name]
            if not isinstance(raw, list):
                raise GeneratedEditError("invalid_ui_document",
                                         f"requirements.{name} must be a list")
            entries: list[tuple[str, int]] = []
            for item in raw:
                if not isinstance(item, list) or len(item) != 2 or \
                        not isinstance(item[0], str) or not item[0] or \
                        not _is_int(item[1]) or item[1] < 0:
                    raise GeneratedEditError(
                        "invalid_ui_document",
                        f"requirements.{name} entries must be [key, non-negative integer]")
                entries.append((item[0], item[1]))
            return tuple(entries)

        return cls(
            components=_text_list(value["components"], "components"),
            fields=_text_list(value["fields"], "fields"),
            actions=_text_list(value["actions"], "actions"),
            styles=_text_list(value["styles"], "styles"),
            image_resources=resources("image_resources"),
            fonts=resources("fonts"),
            runtime_compositions=_text_list(value["runtime_compositions"],
                                            "runtime_compositions"))


@dataclass(frozen=True)
class UIDocument:
    structure_format: int
    structure_text: str
    structure_sha256: str
    requirements: UIDocumentRequirements

    def structure_document(self) -> GeneratedStructureDocument:
        return parse_generated_structure_document(self.structure_text)

    def to_dict(self) -> dict[str, Any]:
        return {
            "format": UI_DOCUMENT_FORMAT,
            "format_version": UI_DOCUMENT_VERSION,
            "structure_format": self.structure_format,
            "structure_sha256": self.structure_sha256,
            "structure": self.structure_text,
            "requirements": self.requirements.to_dict(),
        }

    def to_text(self) -> str:
        return json.dumps(self.to_dict(), ensure_ascii=False, indent=2,
                          sort_keys=True) + "\n"


def _template_styles(node: Any, names: set[str]) -> None:
    if node.style_name:
        names.add(node.style_name)
    for child in node.children:
        _template_styles(child, names)


def requirements_from_structure(structure: GeneratedStructure) -> UIDocumentRequirements:
    components: set[str] = set()
    fields: set[str] = set()
    actions: set[str] = set()
    styles: set[str] = set()
    images: set[tuple[str, int]] = set()
    fonts: set[tuple[str, int]] = set()
    for node in structure.nodes:
        components.add(node.kind)
        if node.field_id:
            fields.add(node.field_id)
        if node.action:
            actions.add(node.action)
        resource = ""
        resource_version = 0
        font_resource = ""
        font_version = 1
        for prop in node.properties:
            if prop.name == "resource":
                resource = prop.value
            elif prop.name == "resourceVersion":
                try:
                    resource_version = int(prop.value)
                except ValueError:
                    resource_version = 0
            elif prop.name == "fontResource":
                font_resource = prop.value
            elif prop.name == "fontVersion":
                try:
                    parsed_version = int(prop.value)
                except ValueError:
                    parsed_version = 0
                if parsed_version > 0:
                    font_version = parsed_version
        if resource and resource_version > 0:
            images.add((resource, resource_version))
        if font_resource:
            fonts.add((font_resource, font_version))
    for composition in structure.compositions:
        components.add(composition.name)
        for element in composition.elements:
            if element.field_id:
                fields.add(element.field_id)
            if element.action:
                actions.add(element.action)
        _template_styles(composition.template, styles)
    return UIDocumentRequirements(
        components=tuple(sorted(components)),
        fields=tuple(sorted(fields)),
        actions=tuple(sorted(actions)),
        styles=tuple(sorted(styles)),
        image_resources=tuple(sorted(images)),
        fonts=tuple(sorted(fonts)),
        runtime_compositions=tuple(sorted(item.name for item in structure.compositions)))


def _canonical_structure_text(structure: GeneratedStructure) -> tuple[int, str]:
    if not structure.lossless:
        raise GeneratedEditError(
            "ui_document_lossy",
            "the accepted structure contains unknown content; a lossless document "
            "cannot be exported from it")
    if structure.format_version not in (1, 2):
        raise GeneratedEditError(
            "structure_format_unsupported",
            f"structure format {structure.format_version} is not exported")
    if structure.format_version == 1 and structure.compositions:
        raise GeneratedEditError("structure_format_unsupported",
                                 "a format 1 structure cannot carry definitions")
    document = GeneratedStructureDocument(
        structure.format_version, structure.compositions, structure.nodes)
    text = encode_generated_structure_document(document)
    if _utf8_length(text, "structure text") > UI_DOCUMENT_STRUCTURE_MAX_BYTES:
        raise GeneratedEditError(
            "structure_too_large",
            f"the structure is larger than {UI_DOCUMENT_STRUCTURE_MAX_BYTES} bytes; "
            "the window structure decoder would refuse it")
    return structure.format_version, text


def ui_document_from_structure(structure: GeneratedStructure) -> UIDocument:
    """Export the accepted structure as ONE self-contained interface document."""
    structure_format, text = _canonical_structure_text(structure)
    return UIDocument(
        structure_format, text,
        hashlib.sha256(text.encode("utf-8")).hexdigest(),
        requirements_from_structure(structure))


def ui_document_from_snapshot(snapshot: GeneratedSnapshot) -> UIDocument:
    return ui_document_from_structure(structure_from_snapshot(snapshot))


def write_ui_document(path: str | os.PathLike[str], document: UIDocument) -> None:
    """Write the document atomically; a failure keeps the previous file."""
    target = Path(path)
    directory = target.parent if str(target.parent) else Path(".")
    if not directory.is_dir():
        raise GeneratedEditError("ui_document_path",
                                 f"directory does not exist: {directory}")
    text = document.to_text()
    descriptor = -1
    temporary = ""
    try:
        descriptor, temporary = tempfile.mkstemp(
            prefix=f".{target.name}.", suffix=".tmp", dir=str(directory))
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            descriptor = -1
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, target)
        temporary = ""
    finally:
        if descriptor >= 0:
            os.close(descriptor)
        if temporary:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass


def parse_ui_document(text: str, *, allow_lossy: bool = False) -> UIDocument:
    """Validate format, digest, structure and derived requirements.

    `allow_lossy=True` is ONLY for read-only display: the returned document must
    not be imported or re-written, and `import_ui_document` still refuses it.
    Requirements are compared with the values derived from the structure text;
    a file that declares different components/fields/actions/resources than it
    references is refused instead of letting two descriptions disagree.
    """
    if _utf8_length(text, "document") > UI_DOCUMENT_MAX_BYTES:
        raise GeneratedEditError("ui_document_too_large",
                                 f"document exceeds {UI_DOCUMENT_MAX_BYTES} bytes")
    value = _json_object(text, "document", "invalid_ui_document")
    unknown = set(value) - UI_DOCUMENT_KEYS
    missing = UI_DOCUMENT_KEYS - set(value)
    if unknown or missing:
        raise GeneratedEditError(
            "invalid_ui_document",
            f"document keys differ from {UI_DOCUMENT_FORMAT} v{UI_DOCUMENT_VERSION}: "
            f"unknown={sorted(unknown)} missing={sorted(missing)}")
    if value["format"] != UI_DOCUMENT_FORMAT or \
            not _is_int(value["format_version"]) or \
            value["format_version"] != UI_DOCUMENT_VERSION:
        raise GeneratedEditError(
            "ui_document_version",
            f"expected {UI_DOCUMENT_FORMAT} v{UI_DOCUMENT_VERSION}, got "
            f"{value['format']!r} v{value['format_version']!r}")
    if not _is_int(value["structure_format"]) or \
            value["structure_format"] not in (1, 2) or \
            not isinstance(value["structure"], str):
        raise GeneratedEditError("invalid_ui_document",
                                 "structure fields are malformed")
    declared_digest = _sha256_text(value["structure_sha256"], "structure_sha256",
                                   "invalid_ui_document")
    structure_bytes = _utf8_length(value["structure"], "structure")
    if structure_bytes > UI_DOCUMENT_STRUCTURE_MAX_BYTES:
        raise GeneratedEditError(
            "structure_too_large",
            f"the structure is {structure_bytes} bytes; the limit is "
            f"{UI_DOCUMENT_STRUCTURE_MAX_BYTES}")
    digest = hashlib.sha256(value["structure"].encode("utf-8")).hexdigest()
    if digest != declared_digest:
        raise GeneratedEditError("ui_document_digest_mismatch",
                                 "structure text does not match its sha256")
    try:
        structure_document = parse_generated_structure_document(value["structure"])
    except GeneratedUiError as error:
        raise GeneratedEditError("invalid_ui_document", str(error)) from error
    if structure_document.format_version != value["structure_format"]:
        raise GeneratedEditError("invalid_ui_document",
                                 "structure format token disagrees with its header")
    if structure_document.removals:
        raise GeneratedEditError(
            "ui_document_delta_content",
            "a complete interface document cannot carry COMPOSITION_REMOVE; "
            f"removals={list(structure_document.removals)}")
    requirements = UIDocumentRequirements.from_dict(value["requirements"])
    if not structure_document.lossless:
        if not allow_lossy:
            raise GeneratedEditError(
                "ui_document_lossy",
                "the document contains content this client does not understand; it is "
                "readable for display but cannot be imported or re-written")
    else:
        derived = requirements_from_structure(
            structure_from_document(structure_document))
        if requirements.canonical() != derived.canonical():
            raise GeneratedEditError(
                "ui_document_requirements_mismatch",
                "requirements disagree with the structure references; expected "
                f"{derived.to_dict()}, declared {requirements.to_dict()}")
    return UIDocument(structure_document.format_version, value["structure"],
                      digest, requirements)


def structure_from_document(document: GeneratedStructureDocument) -> GeneratedStructure:
    """Wrap a complete document as the structure its derived facts describe."""
    return GeneratedStructure(0, 0, "", document.nodes,
                              format_version=document.format_version,
                              compositions=document.compositions)


def read_ui_document(path: str | os.PathLike[str], *,
                     allow_lossy: bool = False) -> UIDocument:
    """Read at most one bounded UTF-8 document from a regular file.

    The check and the read use ONE descriptor, so a file that grows after the
    size check cannot make this function allocate more than the limit, and a
    FIFO/device/short read is refused instead of being read without a bound.
    """
    target = Path(path)
    try:
        # O_NONBLOCK only affects special files: opening a FIFO for reading
        # would otherwise wait for a writer before the regular-file check.
        descriptor = os.open(target, os.O_RDONLY | os.O_NONBLOCK)
    except OSError as error:
        raise GeneratedEditError("ui_document_path",
                                 f"cannot read {target}: {error}") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode):
            raise GeneratedEditError("ui_document_path",
                                     f"{target} is not a regular file")
        if info.st_size > UI_DOCUMENT_MAX_BYTES:
            raise GeneratedEditError(
                "ui_document_too_large",
                f"{target} is {info.st_size} bytes; limit is {UI_DOCUMENT_MAX_BYTES}")
        remaining = UI_DOCUMENT_MAX_BYTES + 1
        chunks: list[bytes] = []
        while remaining > 0:
            chunk = os.read(descriptor, remaining)
            if not chunk:
                break
            chunks.append(chunk)
            remaining -= len(chunk)
        payload = b"".join(chunks)
    except OSError as error:
        raise GeneratedEditError("ui_document_path",
                                 f"cannot read {target}: {error}") from error
    finally:
        os.close(descriptor)
    if len(payload) > UI_DOCUMENT_MAX_BYTES:
        raise GeneratedEditError(
            "ui_document_too_large",
            f"{target} grew beyond the {UI_DOCUMENT_MAX_BYTES} byte limit")
    try:
        text = payload.decode("utf-8", "strict")
    except UnicodeDecodeError as error:
        raise GeneratedEditError("invalid_ui_document",
                                 f"{target} is not valid UTF-8: {error}") from error
    return parse_ui_document(text, allow_lossy=allow_lossy)


def _missing_declarations(document: GeneratedStructureDocument,
                          capabilities: Any) -> list[str]:
    if capabilities is None:
        return []
    issues: list[str] = []
    runtime = {composition.name for composition in document.compositions}
    for node in document.nodes:
        if node.kind not in runtime and capabilities.component(node.kind) is None:
            issues.append(f"component:{node.kind}")
        if node.field_id and capabilities.field(node.field_id) is None:
            issues.append(f"field:{node.field_id}")
        if node.action and capabilities.action(node.action) is None:
            issues.append(f"action:{node.action}")
        resource = version = None
        for prop in node.properties:
            if prop.name == "resource":
                resource = prop.value
            elif prop.name == "resourceVersion":
                try:
                    version = int(prop.value)
                except ValueError:
                    version = None
        if resource and version is not None and \
                capabilities.image_resource(resource, version) is None:
            issues.append(f"image:{resource}@{version}")
        for prop in node.properties:
            if prop.name == "fontResource":
                font_version = 1
                for candidate in node.properties:
                    if candidate.name == "fontVersion":
                        try:
                            font_version = int(candidate.value)
                        except ValueError:
                            font_version = 1
                if capabilities.font_resource(prop.value, font_version) is None:
                    issues.append(f"font:{prop.value}@{font_version}")
    for composition in document.compositions:
        for element in composition.elements:
            if element.field_id and capabilities.field(element.field_id) is None:
                issues.append(f"field:{element.field_id}")
            if element.action and capabilities.action(element.action) is None:
                issues.append(f"action:{element.action}")
    return sorted(set(issues))


def preview_ui_import(snapshot: GeneratedSnapshot, document: UIDocument,
                      capabilities: Any, *,
                      replace_definitions: bool = False) -> GeneratedEditPreview:
    """Rebind ONE interface document to the current endpoint and baseline.

    The document is re-parsed here (not trusted from the caller), the current
    catalog is checked for every declaration it references, and a NEW plan is
    built on the accepted baseline in the same snapshot. A missing declaration
    or a stale baseline is a refusal, never a silent partial import.
    """
    parsed = parse_ui_document(document.to_text())
    structure = structure_from_snapshot(snapshot)
    if not structure.lossless:
        raise GeneratedEditError(
            "composition_document_not_lossless",
            "the current accepted structure contains unknown content; importing "
            "would replace it with a pruned tree")
    declaration_issues = _missing_declarations(parsed.structure_document(), capabilities)
    if declaration_issues:
        raise GeneratedEditError(
            "ui_document_missing_declaration",
            "the current endpoint does not declare: " + ",".join(declaration_issues))
    return preview_document(
        structure, parsed.structure_document(), capabilities,
        endpoint=snapshot.endpoint, replace_definitions=replace_definitions,
        document_sha256=parsed.structure_sha256)


UI_IMPORT_PLAN_FORMAT = "cjgui.ui-import-plan"
UI_IMPORT_PLAN_VERSION = 2
UI_IMPORT_PLAN_VERSIONS = (1, 2)


@dataclass(frozen=True)
class SavedUIImportPlan:
    """A document bound to one endpoint/baseline for a later process to apply.

    Applying it re-discovers the current endpoint, re-checks the baseline digest
    and creates a NEW preview; a changed endpoint or baseline is refused rather
    than replayed against a different interface. Version 2 additionally records
    the candidate and expected digests of the approved preview, so the rebuilt
    preview must be the SAME operation the user approved, not merely one built
    from the same document.
    """

    endpoint: Any
    base_version: int
    base_structure_sha256: str
    document: UIDocument
    replace_definitions: bool = False
    document_sha256: str = ""
    expected_structure_sha256: str = ""
    submitted_sha256: str = ""
    removals: tuple[str, ...] = ()
    # The version this plan was READ as. A v2 plan states the removals fact
    # explicitly, including an empty tuple; a v1 plan omits the field and can
    # only rely on the candidate/expected digest guards.
    format_version: int = UI_IMPORT_PLAN_VERSION

    def to_dict(self) -> dict[str, Any]:
        return {
            "format": UI_IMPORT_PLAN_FORMAT,
            "format_version": self.format_version,
            "endpoint": {
                "instance": self.endpoint.instance,
                "bind_generation": self.endpoint.bind_generation,
            } if self.endpoint is not None else None,
            "base_version": self.base_version,
            "base_structure_sha256": self.base_structure_sha256,
            "replace_definitions": self.replace_definitions,
            "document_sha256": self.document_sha256,
            "expected_structure_sha256": self.expected_structure_sha256,
            "submitted_sha256": self.submitted_sha256,
            "removals": list(self.removals),
            "document": self.document.to_dict(),
        }

    def to_text(self) -> str:
        return json.dumps(self.to_dict(), ensure_ascii=False, indent=2,
                          sort_keys=True) + "\n"


def saved_ui_import_plan(preview: GeneratedEditPreview,
                         document: UIDocument, *,
                         replace_definitions: bool = False) -> SavedUIImportPlan:
    """Bind the APPROVED preview and its exact document into one saved plan.

    A caller cannot pair an arbitrary preview with another document or policy:
    the preview must have been built from this document digest with the same
    merge/replace decision, and it must carry the candidate/expected facts the
    later apply checks.
    """
    if preview.endpoint is None:
        raise GeneratedEditError(
            "missing_endpoint", "a saved import plan requires a snapshot endpoint")
    if preview.import_document_sha256 != document.structure_sha256:
        raise GeneratedEditError(
            "import_plan_document_mismatch",
            "the preview was not built from this document")
    if preview.replace_definitions != bool(replace_definitions):
        raise GeneratedEditError(
            "import_plan_replace_mismatch",
            "the preview used a different definition merge/replace policy")
    if not preview.expected_structure_sha256 or not preview.submitted_sha256:
        raise GeneratedEditError(
            "invalid_saved_import_plan",
            "the preview does not carry candidate/expected digests")
    return SavedUIImportPlan(
        preview.endpoint, preview.base_version, preview.base_structure_sha256,
        document, replace_definitions=preview.replace_definitions,
        document_sha256=document.structure_sha256,
        expected_structure_sha256=preview.expected_structure_sha256,
        submitted_sha256=preview.submitted_sha256,
        removals=preview.removals)


_PLAN_BASE_KEYS = frozenset({
    "format", "format_version", "endpoint", "base_version",
    "base_structure_sha256", "replace_definitions", "document_sha256",
    "expected_structure_sha256", "document",
})
_PLAN_V2_KEYS = _PLAN_BASE_KEYS | {"submitted_sha256", "removals"}


def parse_saved_ui_import_plan(text: str) -> SavedUIImportPlan:
    """Validate a saved plan with exact JSON types; no bool/str/int coercion."""
    code = "invalid_saved_import_plan"
    value = _json_object(text, "import plan", code)
    if not _is_int(value.get("format_version")) or \
            value["format_version"] not in UI_IMPORT_PLAN_VERSIONS:
        raise GeneratedEditError(code, "import plan format/version is not supported")
    version = value["format_version"]
    expected_keys = _PLAN_BASE_KEYS if version == 1 else _PLAN_V2_KEYS
    if set(value) != expected_keys:
        raise GeneratedEditError(code,
                                 f"import plan keys are malformed for v{version}")
    if value["format"] != UI_IMPORT_PLAN_FORMAT:
        raise GeneratedEditError(code, "import plan format is not supported")
    if not _is_int(value["base_version"]) or value["base_version"] < 0:
        raise GeneratedEditError(code, "base_version must be a non-negative integer")
    base_digest = _sha256_text(value["base_structure_sha256"],
                               "base_structure_sha256", code)
    if not isinstance(value["replace_definitions"], bool):
        raise GeneratedEditError(code, "replace_definitions must be a JSON boolean")
    document_digest = _sha256_text(value["document_sha256"], "document_sha256", code)
    expected_digest = _sha256_text(value["expected_structure_sha256"],
                                   "expected_structure_sha256", code)
    if not isinstance(value["document"], Mapping):
        raise GeneratedEditError(code, "import plan document must be an object")
    document = parse_ui_document(json.dumps(value["document"], ensure_ascii=False))
    if document_digest != document.structure_sha256:
        raise GeneratedEditError(code, "import plan document digest disagrees")
    endpoint_value = value["endpoint"]
    if not isinstance(endpoint_value, Mapping) or \
            set(endpoint_value) != {"instance", "bind_generation"}:
        raise GeneratedEditError(code, "import plan endpoint is malformed")
    instance = endpoint_value["instance"]
    bind_generation = endpoint_value["bind_generation"]
    if not isinstance(instance, str) or not instance:
        raise GeneratedEditError(code, "endpoint.instance must be a non-empty string")
    if not _is_int(bind_generation) or bind_generation < 0:
        raise GeneratedEditError(code, "endpoint.bind_generation must be a non-negative integer")
    submitted_digest = ""
    removals: tuple[str, ...] = ()
    if version >= 2:
        submitted_digest = _sha256_text(value["submitted_sha256"],
                                        "submitted_sha256", code)
        raw_removals = value["removals"]
        if not isinstance(raw_removals, list) or \
                any(not isinstance(item, str) or not item for item in raw_removals) or \
                len(set(raw_removals)) != len(raw_removals):
            raise GeneratedEditError(code, "removals must be unique non-empty strings")
        removals = tuple(raw_removals)
    endpoint = GeneratedEndpointIdentity(instance, bind_generation)
    return SavedUIImportPlan(
        endpoint, value["base_version"], base_digest,
        document, replace_definitions=value["replace_definitions"],
        document_sha256=document_digest,
        expected_structure_sha256=expected_digest,
        submitted_sha256=submitted_digest, removals=removals,
        format_version=version)


def apply_saved_ui_import(snapshot: GeneratedSnapshot,
                          saved: SavedUIImportPlan,
                          capabilities: Any) -> GeneratedEditPreview:
    """Re-check endpoint/baseline, rebuild, then prove it is the approved plan."""
    current = structure_from_snapshot(snapshot)
    if snapshot.endpoint != saved.endpoint:
        raise GeneratedEditError(
            "endpoint_replaced",
            f"import plan targets {saved.endpoint.describe()}; current endpoint is "
            f"{snapshot.endpoint.describe()}")
    if current.version != saved.base_version:
        raise GeneratedEditError(
            "stale_base_version",
            f"import plan targets accepted version {saved.base_version}; the "
            f"application answered {current.version}")
    if structure_document_digest(current) != saved.base_structure_sha256:
        raise GeneratedEditError(
            "stale_base_structure",
            "the accepted structure digest changed since the import preview")
    rebuilt = preview_ui_import(snapshot, saved.document, capabilities,
                                replace_definitions=saved.replace_definitions)
    # The saved expected digest is the operation the user approved. A tampered
    # policy or a changed catalog that now produces another final structure is a
    # refusal here, before any submit, not a silent new preview.
    if rebuilt.expected_structure_sha256 != saved.expected_structure_sha256:
        raise GeneratedEditError(
            "saved_import_plan_mismatch",
            "the rebuilt preview would produce a different accepted structure")
    if saved.submitted_sha256 and \
            rebuilt.submitted_sha256 != saved.submitted_sha256:
        raise GeneratedEditError(
            "saved_import_plan_mismatch",
            "the rebuilt candidate differs from the approved candidate")
    # A v2 plan records the removals list explicitly. An empty list means "the
    # approved operation removes nothing", not "do not check": otherwise a
    # replace plan whose removals were tampered to [] would be accepted and
    # rebuilt a removal the user never approved. A v1 plan has no such field.
    if saved.format_version >= 2 and rebuilt.removals != saved.removals:
        raise GeneratedEditError(
            "saved_import_plan_mismatch",
            "the rebuilt removals differ from the approved preview")
    return rebuilt
