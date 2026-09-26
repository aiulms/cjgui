#!/usr/bin/env python3
"""Typed public client for the runtime-generated UI surface.

This module turns the line protocols an application already publishes through
`client.py` into typed objects, so a普通 consumer (or a model-driven bridge) can
discover declared capabilities, read the accepted structure/fields/instances,
build a candidate, submit it and observe acceptance without re-implementing a
regex parser or hard-coding an action name, a field id or a resource id.

It adds no business owner, no model runtime and no second permission system: it
is a thin typed layer over the SAME descriptor-gated public connection.

What is deliberately NOT here:
  * no UI presentation claim — reading the accepted structure/geometry says what
    the window accepted, not what a GPU displayed;
  * no automatic merge of business conflicts and no automatic replay: a stale
    version, a rejected candidate, a superseded candidate, a closed endpoint and
    a timeout are DIFFERENT results and are reported separately.
"""

from __future__ import annotations

from dataclasses import dataclass
import re
import time

from client import (
    ConnectionClosedError,
    IDENTIFIER,
    PROTOCOL,
    SharedOperationArgument,
    SharedOperationClient,
    SharedOperationResponse,
)


class GeneratedUiError(RuntimeError):
    """A typed validation failure on the generated-UI surface."""


# The exact declared value types the transport accepts for action parameters
# (`shared_operation_transport.cj:isSupportedValueType`). A STRING declaration
# must never accept an INTEGER argument, or the reverse.
_SUPPORTED_VALUE_TYPES = ("STRING", "INTEGER", "BOOLEAN", "TEXT_REPLACEMENTS")


class GeneratedUiEndpointError(GeneratedUiError):
    """The endpoint itself failed; this is NOT a business rejection.

    A closed socket, a missing descriptor and a replaced endpoint are reported
    here so a caller can never mistake "I could not ask" for "my candidate was
    refused". `code` is `endpoint_unavailable` or `endpoint_replaced`.
    """

    def __init__(self, code: str, detail: str = ""):
        self.code = code
        self.detail = detail
        super().__init__(f"{code}: {detail}" if detail else code)


class GeneratedUiDeadlineExceeded(GeneratedUiError):
    """The LOCAL monotonic budget expired before a valid observation existed.

    It is deliberately distinct from an endpoint failure: a slow endpoint did not
    disappear, and a late answer must never be published as an on-time success.
    """


class GeneratedUiProtocolError(GeneratedUiError):
    """A well-formed envelope that violates its OWN declared contract.

    The endpoint answered a parseable reply whose declared cursor range or change
    category cannot be true, so the increment cannot be stitched into local state.
    The round is refused instead: a partially delivered or unknown increment must
    never advance the anchor past content that was never read. `code` is
    machine-readable, for example `empty_changes_current_moved`,
    `change_tail_not_current` or `unknown_change_category`.
    """

    def __init__(self, code: str, detail: str = "") -> None:
        self.code = code
        self.detail = detail
        super().__init__(f"{code}: {detail}" if detail else code)


@dataclass(frozen=True)
class GeneratedEndpointIdentity:
    """Opaque identity of ONE endpoint instance: the instance nonce plus the
    current bind generation. It is not an authorization credential and is never
    compared as "both non-zero": a missing or malformed identity in a generated
    response is a protocol error.
    """

    instance: str
    bind_generation: int

    def describe(self) -> str:
        return f"{self.instance}-{self.bind_generation}"


def _endpoint_identity_from(values: dict[str, str], context: str) -> GeneratedEndpointIdentity:
    instance = values.get("ENDPOINT_INSTANCE", "")
    if not instance:
        raise GeneratedUiError(f"{context} is missing ENDPOINT_INSTANCE")
    raw_bind = values.get("ENDPOINT_BIND_GENERATION", "")
    if not raw_bind.isdigit():
        raise GeneratedUiError(f"{context} has a malformed ENDPOINT_BIND_GENERATION")
    return GeneratedEndpointIdentity(instance, int(raw_bind))


def _result_values(response: SharedOperationResponse, expected_kind: str) -> dict[str, str]:
    """Reject a transport error instead of parsing it as a state.

    An ERROR envelope is a machine-readable refusal from the endpoint (for
    example `endpoint_replaced`); it must never be read as an empty or unknown
    business state.
    """
    values: dict[str, str] = {}
    for label, tokens in response.entries:
        if label == "ERROR" and tokens:
            reason = tokens[0]
            if reason == "endpoint_replaced":
                raise GeneratedUiEndpointError("endpoint_replaced", reason)
            raise GeneratedUiError(f"endpoint refused {expected_kind}: {reason}")
        if tokens:
            values[label] = tokens[0]
    if response.kind != expected_kind:
        raise GeneratedUiError(f"expected {expected_kind}, got {response.kind}")
    return values


class GeneratedUiArgumentValidationError(GeneratedUiError):
    """A structured, fail-fast failure of `invoke_action`'s local checks.

    It carries the exact machine code plus the offending action/name and the
    declared vs. supplied types, so a caller never has to parse a message.
    These checks only project the published signature; transport and owner stay
    the final authority for authorization, target scope and business ranges.
    """

    def __init__(
        self,
        code: str,
        action: str,
        name: str = "",
        expected_type: str = "",
        actual_type: str = "",
        detail: str = "",
    ) -> None:
        self.code = code
        self.action = action
        self.name = name
        self.expected_type = expected_type
        self.actual_type = actual_type
        self.detail = detail
        message = f"{code}: action {action}"
        if name:
            message += f" argument {name}"
        if expected_type or actual_type:
            message += f" (expected {expected_type or '-'}, actual {actual_type or '-'})"
        if detail:
            message += f" {detail}"
        super().__init__(message)


_HEX = re.compile(r"^[0-9A-Fa-f]*$")


def _hex_text(token: str, what: str) -> str:
    if token == "-":
        return ""
    if len(token) % 2 != 0 or not _HEX.fullmatch(token):
        raise GeneratedUiError(f"{what} is not a UTF-8 hex value")
    return bytes.fromhex(token).decode("utf-8", "replace")


def _token_int(token: str, what: str) -> int:
    try:
        return int(token)
    except ValueError as exc:
        raise GeneratedUiError(f"{what} is not an integer") from exc


def _token_bool(token: str, what: str) -> bool:
    if token in ("1", "true", "TRUE"):
        return True
    if token in ("0", "false", "FALSE"):
        return False
    raise GeneratedUiError(f"{what} is not a boolean")


def _optional(token: str) -> str | None:
    return None if token == "-" else token


def _split_label(line: str) -> tuple[list[str], str]:
    """Split one protocol line, keeping the human label (last token) intact."""
    marker = " label="
    if marker in line:
        head, label = line.split(marker, 1)
        return head.split(" "), label
    return line.split(" "), ""


def _payload_lines(response: SharedOperationResponse) -> list[str]:
    """The provider payload lines of a capabilities/instances response."""
    lines = response.raw.split("\n")
    body: list[str] = []
    started = False
    for line in lines:
        if line.startswith("PAYLOAD_LENGTH ") or line.startswith("INSTANCE_LENGTH ") or \
           line.startswith("STRUCTURE_LENGTH "):
            started = True
            continue
        if not started:
            continue
        if line == "END":
            break
        if line == "":
            continue
        body.append(line)
    return body


# --- capability objects ------------------------------------------------------

@dataclass(frozen=True)
class GeneratedPropertySpec:
    name: str
    value_type: str
    required: bool
    minimum: int
    maximum: int
    max_length: int
    # Optional trailing description tokens: the enumerated value vocabulary and
    # the effective default the framework applies when the description omits the
    # property. Both are optional in the protocol.
    values: tuple[str, ...] = ()
    default: str = ""


@dataclass(frozen=True)
class GeneratedComponentSpec:
    kind: str
    allows_children: bool
    child_limit: int
    properties: tuple[GeneratedPropertySpec, ...]


@dataclass(frozen=True)
class GeneratedCompositeSpec:
    kind: str
    children: bool
    child_limit: int
    expanded_nodes: int
    expanded_depth: int


@dataclass(frozen=True)
class GeneratedElementSpec:
    kind: str
    element_key: str
    role: str
    parent: str
    field_id: str | None
    argument: str | None
    preset: str | None
    action: str | None
    label: str


@dataclass(frozen=True)
class GeneratedActionSpec:
    """One action as the capability description publishes it.

    `arguments` are the declared ARGUMENT NAMES; their types/required flags are
    NOT in this description (a comma-separated name list must never be presented
    as a typed signature). Use `action_signatures()` from the domain snapshot for
    the typed form.
    """

    name: str
    label: str
    arguments: tuple[str, ...]


@dataclass(frozen=True)
class GeneratedFieldSpec:
    field_id: str
    editor_kind: str
    resource_id: int
    writer: str
    required: bool
    minimum: int
    maximum: int
    max_length: int
    callable: bool
    argument: str | None
    input_kind: str
    label: str


@dataclass(frozen=True)
class GeneratedImageResource:
    """One image resource the APPLICATION registered.

    Discovery carries the logical key, the supported type, the version and the
    human name; the raster path is deliberately absent. An external caller
    references the key plus the exact version, and the application resolves it.
    """

    key: str
    content_type: str
    version: int
    name: str


@dataclass(frozen=True)
class GeneratedCapabilities:
    max_depth: int
    max_nodes: int
    max_properties_per_node: int
    max_string_length: int
    components: tuple[GeneratedComponentSpec, ...]
    composites: tuple[GeneratedCompositeSpec, ...]
    elements: tuple[GeneratedElementSpec, ...]
    actions: tuple[GeneratedActionSpec, ...]
    fields: tuple[GeneratedFieldSpec, ...]
    image_resources: tuple[GeneratedImageResource, ...] = ()

    def image_resource(self, key: str, version: int) -> GeneratedImageResource | None:
        for resource in self.image_resources:
            if resource.key == key and resource.version == version:
                return resource
        return None

    def component(self, kind: str) -> GeneratedComponentSpec | None:
        for component in self.components:
            if component.kind == kind:
                return component
        return None

    def field(self, field_id: str) -> GeneratedFieldSpec | None:
        for field in self.fields:
            if field.field_id == field_id:
                return field
        return None

    def action(self, name: str) -> GeneratedActionSpec | None:
        for action in self.actions:
            if action.name == name:
                return action
        return None

    def elements_of(self, kind: str) -> tuple[GeneratedElementSpec, ...]:
        return tuple(element for element in self.elements if element.kind == kind)


def parse_generated_capabilities(response: SharedOperationResponse) -> GeneratedCapabilities:
    components: dict[str, list[GeneratedPropertySpec]] = {}
    component_children: dict[str, tuple[bool, int]] = {}
    composites: list[GeneratedCompositeSpec] = []
    elements: list[GeneratedElementSpec] = []
    actions: list[GeneratedActionSpec] = []
    fields: list[GeneratedFieldSpec] = []
    image_resources: list[GeneratedImageResource] = []
    max_depth = max_nodes = max_properties = max_string = 0
    for line in _payload_lines(response):
        if line.startswith("BOUNDS "):
            parts = line.split(" ")
            if len(parts) != 5:
                raise GeneratedUiError("capability BOUNDS line is malformed")
            max_depth, max_nodes = _token_int(parts[1], "BOUNDS depth"), _token_int(parts[2], "BOUNDS nodes")
            max_properties = _token_int(parts[3], "BOUNDS properties")
            max_string = _token_int(parts[4], "BOUNDS string length")
        elif line.startswith("COMPONENT "):
            parts = line.split(" ")
            if len(parts) != 4:
                raise GeneratedUiError("capability COMPONENT line is malformed")
            components.setdefault(parts[1], [])
            component_children[parts[1]] = (_token_bool(parts[2], "COMPONENT children"),
                                            _token_int(parts[3], "COMPONENT child limit"))
        elif line.startswith("PROPERTY "):
            parts = line.split(" ")
            if len(parts) < 8:
                raise GeneratedUiError("capability PROPERTY line is malformed")
            values: tuple[str, ...] = ()
            default = ""
            for token in parts[8:]:
                if token.startswith("values="):
                    raw = token.split("=", 1)[1]
                    values = tuple(raw.split(",")) if raw else ()
                elif token.startswith("default="):
                    default = token.split("=", 1)[1]
                else:
                    raise GeneratedUiError("capability PROPERTY line has an unknown token")
            components.setdefault(parts[1], []).append(GeneratedPropertySpec(
                parts[2], parts[3], _token_bool(parts[4], "PROPERTY required"),
                _token_int(parts[5], "PROPERTY minimum"), _token_int(parts[6], "PROPERTY maximum"),
                _token_int(parts[7], "PROPERTY max length"), values, default))
        elif line.startswith("COMPOSITE "):
            parts, _label = _split_label(line)
            values = {}
            for token in parts[2:]:
                if "=" not in token:
                    raise GeneratedUiError("capability COMPOSITE line is malformed")
                name, value = token.split("=", 1)
                values[name] = value
            composites.append(GeneratedCompositeSpec(parts[1],
                _token_bool(values.get("children", "0"), "COMPOSITE children"),
                _token_int(values.get("child_limit", "0"), "COMPOSITE child limit"),
                _token_int(values.get("expanded_nodes", "0"), "COMPOSITE expanded nodes"),
                _token_int(values.get("expanded_depth", "0"), "COMPOSITE expanded depth")))
        elif line.startswith("ELEMENT "):
            parts, label = _split_label(line)
            if len(parts) < 4:
                raise GeneratedUiError("capability ELEMENT line is malformed")
            values = {}
            for token in parts[4:]:
                if "=" not in token:
                    raise GeneratedUiError("capability ELEMENT line is malformed")
                name, value = token.split("=", 1)
                values[name] = value
            elements.append(GeneratedElementSpec(parts[1], parts[2], parts[3],
                values.get("parent", "root") or "root", _optional(values.get("field", "-")),
                _optional(values.get("argument", "-")), _optional(values.get("preset", "-")),
                _optional(values.get("action", "-")), label))
        elif line.startswith("ACTION "):
            parts, label = _split_label(line)
            arguments: tuple[str, ...] = ()
            for token in parts[2:]:
                if token.startswith("argument="):
                    raw = token.split("=", 1)[1]
                    arguments = () if raw == "none" else tuple(raw.split(","))
            actions.append(GeneratedActionSpec(parts[1], label, arguments))
        elif line.startswith("IMAGE_RESOURCE "):
            parts, label = _split_label(line)
            if len(parts) != 5:
                raise GeneratedUiError("capability IMAGE_RESOURCE line is malformed")
            image_resources.append(GeneratedImageResource(
                parts[1], parts[2], _token_int(parts[3], "IMAGE_RESOURCE version"), label))
        elif line.startswith("FIELD "):
            parts, label = _split_label(line)
            if len(parts) < 3:
                raise GeneratedUiError("capability FIELD line is malformed")
            values = {}
            for token in parts[3:]:
                if "=" not in token:
                    raise GeneratedUiError("capability FIELD line is malformed")
                name, value = token.split("=", 1)
                values[name] = value
            fields.append(GeneratedFieldSpec(parts[1], parts[2],
                _token_int(values.get("resource", "-1"), "FIELD resource"),
                values.get("writer", "none"), _token_bool(values.get("required", "0"), "FIELD required"),
                _token_int(values.get("min", "0"), "FIELD minimum"),
                _token_int(values.get("max", "0"), "FIELD maximum"),
                _token_int(values.get("maxlen", "0"), "FIELD max length"),
                _token_bool(values.get("callable", "0"), "FIELD callable"),
                _optional(values.get("argument", "-")), values.get("input", ""), label))
    built = tuple(GeneratedComponentSpec(kind, component_children.get(kind, (False, 0))[0],
                                         component_children.get(kind, (False, 0))[1],
                                         tuple(components.get(kind, [])))
                  for kind in components)
    return GeneratedCapabilities(max_depth, max_nodes, max_properties, max_string, built,
                                 tuple(composites), tuple(elements), tuple(actions), tuple(fields),
                                 tuple(image_resources))


# --- structure objects -------------------------------------------------------

@dataclass(frozen=True)
class GeneratedProperty:
    name: str
    value: str


@dataclass(frozen=True)
class GeneratedNode:
    depth: int
    key: str
    kind: str
    field_id: str | None
    action: str | None
    properties: tuple[GeneratedProperty, ...] = ()

    def property(self, name: str) -> str:
        for prop in self.properties:
            if prop.name == name:
                return prop.value
        return ""


@dataclass(frozen=True)
class GeneratedStructure:
    version: int
    candidate_version: int
    scene_state: str
    nodes: tuple[GeneratedNode, ...]


def parse_generated_structure(response: SharedOperationResponse) -> GeneratedStructure:
    lines = response.raw.split("\n")
    version = 0
    candidate = 0
    scene = "none"
    nodes: list[GeneratedNode] = []
    started = False
    for line in lines:
        if line.startswith("STRUCTURE_VERSION "):
            version = _token_int(line.split(" ")[1], "STRUCTURE_VERSION")
        elif line.startswith("CANDIDATE_VERSION "):
            candidate = _token_int(line.split(" ")[1], "CANDIDATE_VERSION")
        elif line.startswith("SCENE_STATE "):
            scene = line.split(" ")[1]
        elif line.startswith("STRUCTURE_LENGTH "):
            started = True
        elif started:
            if line == "END":
                break
            if line == "":
                continue
            if line.startswith("NODE "):
                parts = line.split(" ")
                if len(parts) < 4:
                    raise GeneratedUiError("structure NODE line is malformed")
                field_id = None
                action = None
                for token in parts[4:]:
                    if token.startswith("field=") and len(token) > 6:
                        field_id = token[6:]
                    elif token.startswith("action=") and len(token) > 7:
                        action = token[7:]
                nodes.append(GeneratedNode(_token_int(parts[1], "NODE depth"), parts[2], parts[3],
                                           field_id, action, ()))
            elif line.startswith("PROPERTY "):
                if not nodes:
                    raise GeneratedUiError("structure PROPERTY has no preceding NODE")
                parts = line.split(" ", 4)
                if len(parts) < 5:
                    raise GeneratedUiError("structure PROPERTY line is malformed")
                depth = _token_int(parts[1], "PROPERTY depth")
                key = parts[2]
                name = parts[3]
                value = parts[4]
                if depth != nodes[-1].depth or key != nodes[-1].key:
                    raise GeneratedUiError("structure PROPERTY does not follow its NODE")
                node = nodes[-1]
                nodes[-1] = GeneratedNode(node.depth, node.key, node.kind, node.field_id, node.action,
                                          node.properties + (GeneratedProperty(name, value),))
    return GeneratedStructure(version, candidate, scene, tuple(nodes))


def encode_generated_structure(nodes: "Sequence[GeneratedNode]") -> str:
    """Encode typed nodes exactly the way the decoder reads them.

    A value that cannot be represented on one protocol line (a newline) is
    rejected here instead of being silently truncated.
    """
    lines = ["GENERATED_UI_STRUCTURE 1"]
    for node in nodes:
        if not IDENTIFIER.fullmatch(node.key) or not IDENTIFIER.fullmatch(node.kind):
            raise GeneratedUiError(f"node key/kind is not a protocol identifier: {node.key}/{node.kind}")
        if node.depth < 0:
            raise GeneratedUiError("node depth cannot be negative")
        line = f"NODE {node.depth} {node.key} {node.kind}"
        if node.field_id:
            line += f" field={node.field_id}"
        if node.action:
            line += f" action={node.action}"
        lines.append(line)
        seen = set()
        for prop in node.properties:
            if prop.name in seen:
                raise GeneratedUiError(f"property {prop.name} is declared twice on {node.key}")
            seen.add(prop.name)
            if "\n" in prop.value or "\r" in prop.value:
                raise GeneratedUiError("property values cannot contain a newline")
            lines.append(f"PROPERTY {node.depth} {node.key} {prop.name} {prop.value}")
    lines.append("END")
    return "\n".join(lines)


def same_structure(left: "Sequence[GeneratedNode]", right: "Sequence[GeneratedNode]") -> bool:
    """Whether two node lists are the SAME normalized description.

    The client uses this to decide that the structure it reads back really is the
    candidate it submitted, instead of assuming that a version increment means
    its own candidate is displayed.
    """
    if len(left) != len(right):
        return False
    for a, b in zip(left, right):
        if (a.depth, a.key, a.kind, a.field_id, a.action) != (b.depth, b.key, b.kind, b.field_id, b.action):
            return False
        if sorted((p.name, p.value) for p in a.properties) != sorted((p.name, p.value) for p in b.properties):
            return False
    return True


# --- field / instance / submit objects --------------------------------------

@dataclass(frozen=True)
class GeneratedFieldValue:
    field_id: str
    resource_id: int
    draft: str
    applied: str
    validation_error: str
    #: True/False when the producer could confirm the fact, None when it said the
    #: focus is UNKNOWN. A producer must not answer 0 or 1 for a fact it cannot
    #: confirm, so the absence of knowledge is preserved instead of collapsing
    #: into "not focused".
    focused: bool | None
    selection_start: int | None
    selection_end: int | None
    draft_version: int
    #: CURRENT owner availability ("may this be edited right now"), from the same
    #: condition the owner enforces on write. None when the producer said the
    #: condition cannot be evaluated; never inferred from the draft value.
    available: bool | None
    #: The owner's own reason when blocked (None when available/unknown).
    blocked_reason: str | None
    #: Owner/target the decision applies to and the revision it was evaluated at.
    owner_resource_id: int
    state_version: int


def _parse_field_focus(token: tuple[str, ...] | None) -> bool | None:
    """`FOCUS 0|1|unknown` -> bool | None.

    A producer that cannot confirm whether a control currently holds the focus
    says `unknown`; the client keeps that as None instead of turning an absent
    fact into a confirmed `False`.
    """
    if token is None or token[0] == "unknown":
        return None
    if token[0] == "1":
        return True
    if token[0] == "0":
        return False
    raise GeneratedUiError(f"FIELD FOCUS carries unsupported value {token[0]!r}")


def parse_generated_fields(response: SharedOperationResponse) -> tuple[GeneratedFieldValue, ...]:
    values: list[GeneratedFieldValue] = []
    for line in _payload_lines(response):
        if not line.startswith("FIELD "):
            continue
        parts = line.split(" ")
        tokens: dict[str, tuple[str, ...]] = {}
        index = 3
        while index < len(parts):
            key = parts[index]
            if key == "SELECTION":
                if index + 2 >= len(parts):
                    raise GeneratedUiError("FIELD SELECTION is malformed")
                tokens["SELECTION"] = (parts[index + 1], parts[index + 2])
                index += 3
                continue
            if index + 1 >= len(parts):
                raise GeneratedUiError(f"FIELD {key} has no value")
            tokens[key] = (parts[index + 1],)
            index += 2
        selection = tokens.get("SELECTION")
        available_token = tokens.get("AVAILABLE", ("unknown",))[0]
        if available_token == "unknown":
            available: bool | None = None
        elif available_token == "1":
            available = True
        elif available_token == "0":
            available = False
        else:
            raise GeneratedUiError(
                f"FIELD AVAILABLE carries unsupported value {available_token!r}")
        blocked_reason = None if tokens.get("REASON_HEX", ("-",))[0] == "-" else _hex_text(
            tokens.get("REASON_HEX", ("-",))[0], "FIELD REASON_HEX")
        values.append(GeneratedFieldValue(
            parts[1], _token_int(parts[2], "FIELD resource"),
            _hex_text(tokens.get("DRAFT_HEX", ("-",))[0], "FIELD DRAFT_HEX"),
            _hex_text(tokens.get("APPLIED_HEX", ("-",))[0], "FIELD APPLIED_HEX"),
            tokens.get("ERROR", ("none",))[0],
            _parse_field_focus(tokens.get("FOCUS")),
            None if selection is None else _token_int(selection[0], "FIELD selection start"),
            None if selection is None else _token_int(selection[1], "FIELD selection end"),
            _token_int(tokens.get("VERSION", ("0",))[0], "FIELD draft version"),
            available,
            blocked_reason,
            _token_int(tokens.get("TARGET", ("-1",))[0], "FIELD TARGET"),
            _token_int(tokens.get("STATE_VERSION", ("0",))[0], "FIELD STATE_VERSION")))
    return tuple(values)


@dataclass(frozen=True)
class GeneratedInstance:
    key: str
    element_key: str | None
    role: str | None
    node_id: int
    kind: str
    semantic_id: str
    field_id: str | None
    action: str | None
    visible: bool
    bounds: tuple[int, int, int, int]
    label: str
    # Logical image resource this accepted instance references ("" when none)
    # plus the exact accepted version. The path stays inside the application.
    resource: str = ""
    resource_version: int = 0


@dataclass(frozen=True)
class GeneratedInstances:
    structure_version: int
    candidate_version: int
    scene_state: str
    instances: tuple[GeneratedInstance, ...]

    def instance(self, key: str, element_key: str | None = None) -> GeneratedInstance | None:
        for instance in self.instances:
            if instance.key == key and (element_key is None or instance.element_key == element_key):
                return instance
        return None


def parse_generated_instances(response: SharedOperationResponse) -> GeneratedInstances:
    version = 0
    candidate = 0
    scene = "none"
    instances: list[GeneratedInstance] = []
    started = False
    for line in response.raw.split("\n"):
        if line.startswith("STRUCTURE_VERSION "):
            version = _token_int(line.split(" ")[1], "STRUCTURE_VERSION")
        elif line.startswith("CANDIDATE_VERSION "):
            candidate = _token_int(line.split(" ")[1], "CANDIDATE_VERSION")
        elif line.startswith("SCENE_STATE "):
            scene = line.split(" ")[1]
        elif line.startswith("INSTANCE_LENGTH "):
            started = True
        elif started:
            if line == "END":
                break
            if line == "":
                continue
            if not line.startswith("INSTANCE "):
                raise GeneratedUiError("instance line is malformed")
            parts = line.split(" ")
            values = {}
            for token in parts[2:]:
                if "=" not in token:
                    raise GeneratedUiError("instance token is malformed")
                name, value = token.split("=", 1)
                values[name] = value
            bounds_parts = values.get("bounds", "0,0,0,0").split(",")
            if len(bounds_parts) != 4:
                raise GeneratedUiError("instance bounds are malformed")
            instances.append(GeneratedInstance(parts[1], _optional(values.get("element", "-")),
                _optional(values.get("role", "-")), _token_int(values.get("id", "-1"), "instance id"),
                values.get("kind", "unknown"), values.get("semantic", ""),
                _optional(values.get("field", "-")), _optional(values.get("action", "-")),
                _token_bool(values.get("visible", "0"), "instance visible"),
                tuple(_token_int(part, "instance bound") for part in bounds_parts),
                _hex_text(values.get("label_hex", "-"), "instance label"),
                values.get("resource", "-") if values.get("resource", "-") != "-" else "",
                _token_int(values.get("resource_version", "0"), "instance resource version")))
    return GeneratedInstances(version, candidate, scene, tuple(instances))


@dataclass(frozen=True)
class GeneratedCandidateTicket:
    """Ownership of ONE submission attempt.

    `token` is allocated by the structure holder before the candidate is looked
    at, so it also identifies a malformed or version-conflicting submit. Two
    submitters that share a base version still get different tokens and
    different receipts; a version number alone could not tell them apart.
    """

    token: int
    receipt: str
    endpoint: GeneratedEndpointIdentity
    base_version: int
    candidate_version: int

    @property
    def endpoint_epoch(self) -> int:
        """Deprecated alias of the bind generation (kept for older callers)."""
        return self.endpoint.bind_generation


@dataclass(frozen=True)
class GeneratedCandidateState:
    """Terminal read for one ticket, as the holder really reported it.

    `terminal_state` is PENDING | ACCEPTED | SUPERSEDED | REJECTED | UNKNOWN.
    `scene_state` is deliberately separate: `candidate_received`/`scene_pending`
    is "not shown yet", which is not a failure. `accepted_then_replaced` is an
    extra observation for a ticket that WAS accepted and whose structure a later
    candidate replaced; it never rewrites ACCEPTED back to SUPERSEDED.
    """

    terminal_state: str
    scene_state: str
    reason: str
    path: str
    accepted_version: int
    current_accepted_token: int
    pending_token: int
    endpoint: GeneratedEndpointIdentity
    accepted_then_replaced: bool = False

    @property
    def endpoint_epoch(self) -> int:
        return self.endpoint.bind_generation

    def settled(self) -> bool:
        return self.terminal_state in ("ACCEPTED", "SUPERSEDED", "REJECTED", "UNKNOWN")


@dataclass(frozen=True)
class GeneratedSubmitResult:
    applied: bool
    reason: str
    path: str
    version_before: int
    version_after: int
    candidate_accepted: bool
    scene_accepted: bool
    candidate_version: int
    candidate_token: int = 0
    receipt: str = "none"
    endpoint_identity: GeneratedEndpointIdentity | None = None

    @property
    def endpoint_epoch(self) -> int:
        return self.endpoint_identity.bind_generation if self.endpoint_identity else 0

    def ticket(self) -> GeneratedCandidateTicket:
        if self.endpoint_identity is None:
            raise GeneratedUiError("submit reply carried no endpoint identity")
        return GeneratedCandidateTicket(
            self.candidate_token, self.receipt, self.endpoint_identity,
            self.version_before, self.candidate_version)

    def describe(self) -> str:
        if self.applied:
            return (f"accepted v{self.version_before}->v{self.version_after} "
                    f"token={self.candidate_token}")
        return (f"refused reason={self.reason} v{self.version_before}->v{self.version_after} "
                f"token={self.candidate_token}")


def parse_generated_submit(response: SharedOperationResponse) -> GeneratedSubmitResult:
    values = {}
    for label, tokens in response.entries:
        if tokens:
            values[label] = tokens[0]
    endpoint = _endpoint_identity_from(values, "submit reply")
    return GeneratedSubmitResult(
        _token_bool(values.get("APPLIED", "false"), "submit APPLIED"),
        values.get("REASON", "none"), values.get("PATH", "none"),
        _token_int(values.get("VERSION_BEFORE", "0"), "VERSION_BEFORE"),
        _token_int(values.get("VERSION_AFTER", "0"), "VERSION_AFTER"),
        _token_bool(values.get("CANDIDATE_ACCEPTED", "false"), "CANDIDATE_ACCEPTED"),
        _token_bool(values.get("SCENE_ACCEPTED", "false"), "SCENE_ACCEPTED"),
        _token_int(values.get("CANDIDATE_VERSION", "0"), "CANDIDATE_VERSION"),
        _token_int(values.get("CANDIDATE_TOKEN", "0"), "CANDIDATE_TOKEN"),
        values.get("RECEIPT", "none"),
        endpoint)


def parse_generated_candidate_state(response: SharedOperationResponse) -> GeneratedCandidateState:
    values = {}
    for label, tokens in response.entries:
        if tokens:
            values[label] = tokens[0]
    terminal = values.get("TERMINAL_STATE", "UNKNOWN")
    if terminal not in ("PENDING", "ACCEPTED", "SUPERSEDED", "REJECTED", "UNKNOWN"):
        raise GeneratedUiError(f"unknown candidate terminal state {terminal!r}")
    endpoint = _endpoint_identity_from(values, "candidate state")
    current_accepted = _token_int(values.get("CURRENT_ACCEPTED_TOKEN", "0"), "CURRENT_ACCEPTED_TOKEN")
    token = _token_int(values.get("CANDIDATE_TOKEN", "0"), "CANDIDATE_TOKEN")
    return GeneratedCandidateState(
        terminal, values.get("SCENE_STATE", "none"), values.get("REASON", "none"),
        values.get("PATH", "none"),
        _token_int(values.get("ACCEPTED_VERSION", "0"), "ACCEPTED_VERSION"),
        current_accepted, _token_int(values.get("PENDING_TOKEN", "0"), "PENDING_TOKEN"),
        endpoint,
        terminal == "ACCEPTED" and current_accepted != 0 and current_accepted != token)


@dataclass(frozen=True)
class GeneratedSnapshot:
    """ONE atomic generated-UI snapshot.

    The owner and scene facts stay separate: `owner_field_revision` may have
    moved while `window_accepted_scene_version` has not, and
    `owner_pending_scene` says so instead of pretending the change is visible.
    The three section texts were read in the SAME provider call, so they belong
    to one cursor.
    """

    stream_epoch: int
    stream_identity: str
    cursor: int
    endpoint: GeneratedEndpointIdentity
    owner_field_revision: int
    owner_draft_revision: int
    binding_revision: int
    accepted_structure_version: int
    candidate_token: int
    candidate_state: str
    window_accepted_scene_version: int
    window_geometry_revision: int
    window_interaction_revision: int
    instance_revision: int
    resource_revision: int
    style_revision: int
    owner_pending_scene: bool
    structure_candidate_pending: bool
    fields_text: str

    @property
    def endpoint_epoch(self) -> int:
        return self.endpoint.bind_generation
    structure_text: str
    instances_text: str
    styles_text: str


@dataclass(frozen=True)
class GeneratedChange:
    cursor: int
    category: str
    detail: str


@dataclass(frozen=True)
class GeneratedChanges:
    """Bounded change read: categories only, no tree/fields/geometry."""

    stream_epoch: int
    stream_identity: str
    endpoint: GeneratedEndpointIdentity
    since: int
    current: int
    resync_required: bool
    changes: tuple[GeneratedChange, ...]


@dataclass(frozen=True)
class GeneratedSection:
    """ONE snapshot section read at a guarded cursor.

    `revision_changed` means the caller's cursor no longer describes the current
    state: there is deliberately NO section content, and the caller must take a
    fresh snapshot instead of stitching this response into older state.
    """

    section: str
    cursor: int
    endpoint: GeneratedEndpointIdentity
    stream_epoch: int
    stream_identity: str
    revision_changed: bool
    text: str


@dataclass(frozen=True)
class GeneratedObservationAnchor:
    """Everything a cursor is only valid WITH.

    A cursor number alone cannot prove it belongs to the same endpoint or the
    same observation stream; the anchor carries the endpoint identity and the
    stream identity/epoch that produced it, and `seed_anchor` refuses to seed an
    anchor that does not belong to the session's endpoint.
    """

    endpoint: GeneratedEndpointIdentity
    stream_epoch: int
    stream_identity: str
    cursor: int


@dataclass(frozen=True)
class GeneratedCandidateWait:
    """Explicit outcome of one bounded candidate wait.

    `outcome` is terminal | timeout | timeout_without_observation |
    endpoint_unavailable | endpoint_replaced. `last_state` is the most recent
    in-budget observation (None only for a zero-budget wait), and it is NEVER
    rewritten from a late answer.
    """

    outcome: str
    last_state: GeneratedCandidateState | None
    attempted: int


@dataclass(frozen=True)
class GeneratedObservation:
    """One `observe_once` result: what the poller had to do and what moved."""

    kind: str  # snapshot | changes | none
    snapshot: GeneratedSnapshot | None
    changes: GeneratedChanges | None
    # On kind="changes", exactly the affected sections re-read at the change
    # cursor; None on any other kind.
    sections: dict[str, str] | None = None


# Which snapshot sections a change category makes stale. A structure change
# re-creates the accepted instances; a binding change is visible through the
# accepted-instance semantics; a candidate change is answered by its ticket
# read, so it needs no section.
_SECTIONS_BY_CATEGORY = {
    "STRUCTURE": ("STRUCTURE", "INSTANCES"),
    "INSTANCES": ("INSTANCES",),
    "SCENE": ("INSTANCES",),
    "BINDINGS": ("INSTANCES",),
    "FIELDS": ("FIELDS",),
    # A resource declaration change is visible through the accepted instances'
    # resource references, so the instances section is the one that goes stale.
    "RESOURCES": ("INSTANCES",),
    # A named-style directory change re-reads the style DEFINITIONS: the accepted
    # structure is untouched, so no tree/instance section goes stale.
    "STYLES": ("STYLES",),
    "CANDIDATE": (),
}

_GENERATED_SECTION_NAMES = ("FIELDS", "STRUCTURE", "INSTANCES", "STYLES")


def parse_generated_section(response: SharedOperationResponse, section: str) -> GeneratedSection:
    values = {}
    lines: list[str] = []
    prefix = {"FIELDS": "SNAPSHOT_FIELD", "STRUCTURE": "SNAPSHOT_STRUCTURE",
              "INSTANCES": "SNAPSHOT_INSTANCE", "STYLES": "SNAPSHOT_STYLE"}[section]
    for label, tokens in response.entries:
        if label == prefix:
            lines.append(" ".join(tokens))
        elif tokens:
            values[label] = tokens[0]
    if "CURSOR" not in values or "SNAPSHOT_REVISION_CHANGED" not in values:
        raise GeneratedUiError("section reply is missing its cursor or revision flag")
    if values.get("SECTION", section) != section:
        raise GeneratedUiError("section reply carries another section name")
    return GeneratedSection(
        section, _token_int(values["CURSOR"], "CURSOR"),
        _endpoint_identity_from(values, "section"),
        _token_int(values.get("STREAM_EPOCH", "0"), "STREAM_EPOCH"),
        values.get("STREAM_IDENTITY", "none"),
        _token_bool(values["SNAPSHOT_REVISION_CHANGED"], "SNAPSHOT_REVISION_CHANGED"),
        "\n".join(lines))


def parse_generated_snapshot(response: SharedOperationResponse) -> GeneratedSnapshot:
    values = {}
    fields_lines: list[str] = []
    structure_lines: list[str] = []
    instances_lines: list[str] = []
    styles_lines: list[str] = []
    for label, tokens in response.entries:
        if label == "SNAPSHOT_FIELD":
            fields_lines.append(" ".join(tokens))
        elif label == "SNAPSHOT_STRUCTURE":
            structure_lines.append(" ".join(tokens))
        elif label == "SNAPSHOT_INSTANCE":
            instances_lines.append(" ".join(tokens))
        elif label == "SNAPSHOT_STYLE":
            styles_lines.append(" ".join(tokens))
        elif tokens:
            values[label] = tokens[0]
    if "STREAM_EPOCH" not in values or "CURSOR" not in values:
        raise GeneratedUiError("snapshot is missing its stream identity or cursor")
    return GeneratedSnapshot(
        _token_int(values["STREAM_EPOCH"], "STREAM_EPOCH"),
        values.get("STREAM_IDENTITY", "none"),
        _token_int(values["CURSOR"], "CURSOR"),
        _endpoint_identity_from(values, "snapshot"),
        _token_int(values.get("OWNER_FIELD_REVISION", "0"), "OWNER_FIELD_REVISION"),
        _token_int(values.get("OWNER_DRAFT_REVISION", "0"), "OWNER_DRAFT_REVISION"),
        _token_int(values.get("BINDING_REVISION", "0"), "BINDING_REVISION"),
        _token_int(values.get("ACCEPTED_STRUCTURE_VERSION", "0"), "ACCEPTED_STRUCTURE_VERSION"),
        _token_int(values.get("CANDIDATE_TOKEN", "0"), "CANDIDATE_TOKEN"),
        values.get("CANDIDATE_STATE", "none"),
        _token_int(values.get("WINDOW_ACCEPTED_SCENE_VERSION", "0"), "WINDOW_ACCEPTED_SCENE_VERSION"),
        _token_int(values.get("WINDOW_GEOMETRY_REVISION", "0"), "WINDOW_GEOMETRY_REVISION"),
        _token_int(values.get("WINDOW_INTERACTION_REVISION", "0"), "WINDOW_INTERACTION_REVISION"),
        _token_int(values.get("INSTANCE_REVISION", "0"), "INSTANCE_REVISION"),
        _token_int(values.get("RESOURCE_REVISION", "0"), "RESOURCE_REVISION"),
        _token_int(values.get("STYLE_REVISION", "0"), "STYLE_REVISION"),
        _token_bool(values.get("OWNER_PENDING_SCENE", "0"), "OWNER_PENDING_SCENE"),
        _token_bool(values.get("STRUCTURE_CANDIDATE_PENDING", "0"), "STRUCTURE_CANDIDATE_PENDING"),
        "\n".join(fields_lines), "\n".join(structure_lines), "\n".join(instances_lines),
        "\n".join(styles_lines))


def parse_generated_changes(response: SharedOperationResponse) -> GeneratedChanges:
    values = {}
    changes: list[GeneratedChange] = []
    for label, tokens in response.entries:
        if label == "CHANGE" and len(tokens) >= 2:
            changes.append(GeneratedChange(_token_int(tokens[0], "CHANGE cursor"), tokens[1],
                                           " ".join(tokens[2:])))
        elif tokens:
            values[label] = tokens[0]
    if "STREAM_EPOCH" not in values or "CURRENT" not in values:
        raise GeneratedUiError("changes reply is missing its stream identity or cursor")
    return GeneratedChanges(
        _token_int(values["STREAM_EPOCH"], "STREAM_EPOCH"),
        values.get("STREAM_IDENTITY", "none"),
        _endpoint_identity_from(values, "changes"),
        _token_int(values.get("SINCE", "0"), "SINCE"),
        _token_int(values["CURRENT"], "CURRENT"),
        _token_bool(values.get("RESYNC_REQUIRED", "1"), "RESYNC_REQUIRED"),
        tuple(changes))


@dataclass(frozen=True)
class GeneratedStructureWait:
    outcome: str  # reached | timeout
    structure: GeneratedStructure | None


# --- typed domain actions (from the descriptor/snapshot, not from commas) ----

@dataclass(frozen=True)
class ActionParameterSpec:
    name: str
    value_type: str
    required: bool


@dataclass(frozen=True)
class TypedActionSpec:
    name: str
    display_name: str
    parameters: tuple[ActionParameterSpec, ...]
    minimum_targets: int
    maximum_targets: int


def parse_action_signatures(response: SharedOperationResponse) -> tuple[TypedActionSpec, ...]:
    """Typed action signatures from the domain snapshot (`get`).

    They come from the SAME public descriptor the app already publishes, so a
    client gets real value types / required flags / target bounds instead of the
    comma-separated name list the generated description carries.
    """
    heads: dict[str, tuple[int, int]] = {}
    names: dict[str, str] = {}
    parameters: dict[str, list[ActionParameterSpec]] = {}
    order: list[str] = []
    for label, tokens in response.entries:
        if label == "ACTION" and len(tokens) == 6 and tokens[1] == "PARAMETERS" and tokens[3] == "TARGETS":
            # ACTION <name> PARAMETERS <n> TARGETS <min> <max>
            heads[tokens[0]] = (_token_int(tokens[4], "action minimum targets"),
                                _token_int(tokens[5], "action maximum targets"))
            if tokens[0] not in order:
                order.append(tokens[0])
        elif label == "ACTION_DISPLAY_NAME_UTF8_HEX" and len(tokens) == 3:
            names[tokens[0]] = _hex_text(tokens[2], "action display name")
        elif label == "PARAMETER" and len(tokens) == 4:
            parameters.setdefault(tokens[0], []).append(
                ActionParameterSpec(tokens[1], tokens[2], tokens[3] == "REQUIRED"))
    result = []
    for name in order:
        minimum, maximum = heads.get(name, (0, 0))
        result.append(TypedActionSpec(name, names.get(name, name), tuple(parameters.get(name, [])),
                                      minimum, maximum))
    return tuple(result)


# --- the session wrapper -----------------------------------------------------

@dataclass
class GeneratedUiSession:
    """A small typed session over one public endpoint.

    Capabilities are cached (they change only with the application's
    registration). Structure/fields/instances are read on demand, so a caller
    decides when to re-read; nothing here polls in the background or calls a
    model.
    """

    client: SharedOperationClient
    _capabilities: GeneratedCapabilities | None = None
    # The poller cache: stream epoch + cursor + the last full snapshot. It is
    # discardable by design - a resync or a replaced stream clears it.
    _observation_anchor: GeneratedObservationAnchor | None = None
    _observation_snapshot: GeneratedSnapshot | None = None
    _endpoint_identity: GeneratedEndpointIdentity | None = None
    # Response payload size (UTF-8 text) of the most recent snapshot/change read.
    # It exists so a measurement is taken from the real endpoint instead of being
    # extrapolated from a section's length.
    _last_response_bytes: int = 0

    @classmethod
    def connect(cls, descriptor_path: str) -> "GeneratedUiSession":
        return cls(SharedOperationClient.from_descriptor(descriptor_path))

    def reconnect(self, descriptor_path: str) -> None:
        """Replace the endpoint and drop EVERY cached projection.

        A restarted application is a different endpoint instance: its descriptor,
        capability cache, observation anchor and ticket identities must all be
        discarded together, or a coincidentally equal token/cursor would be read
        as the old endpoint's state.
        """
        self.client = SharedOperationClient.from_descriptor(descriptor_path)
        self._capabilities = None
        self._observation_anchor = None
        self._observation_snapshot = None
        self._endpoint_identity = None
        self._last_response_bytes = 0

    def capabilities(self, *, refresh: bool = False,
                     deadline_monotonic: float | None = None) -> GeneratedCapabilities:
        if self._capabilities is None or refresh:
            self._capabilities = parse_generated_capabilities(
                self.client.request(self._query("GET_GENERATED_UI_CAPABILITIES"),
                                    deadline_monotonic=deadline_monotonic))
        return self._capabilities

    def structure(self, *, deadline_monotonic: float | None = None) -> GeneratedStructure:
        return parse_generated_structure(
            self.client.request(self._query("GET_GENERATED_UI_STRUCTURE"),
                                deadline_monotonic=deadline_monotonic))

    def fields(self, *, deadline_monotonic: float | None = None) -> tuple[GeneratedFieldValue, ...]:
        return parse_generated_fields(
            self.client.request(self._query("GET_GENERATED_UI_FIELDS"),
                                deadline_monotonic=deadline_monotonic))

    def instances(self, *, deadline_monotonic: float | None = None) -> GeneratedInstances:
        return parse_generated_instances(
            self.client.request(self._query("GET_GENERATED_UI_INSTANCES"),
                                deadline_monotonic=deadline_monotonic))

    def snapshot(self, *, deadline_monotonic: float | None = None) -> GeneratedSnapshot:
        """ONE atomic snapshot: cursor/stream identity, separated owner/scene
        facts and the field/structure/instance sections of the SAME provider
        call. Reading it does not build, layout or submit anything.

        The endpoint identity is remembered, so a later ticket/cursor that does
        not belong to this instance is refused instead of being compared as
        "both non-zero".
        """
        response = self._read("GET_GENERATED_UI_SNAPSHOT", "GENERATED_UI_SNAPSHOT", deadline_monotonic)
        snapshot = parse_generated_snapshot(response)
        self._endpoint_identity = snapshot.endpoint
        self._observation_anchor = GeneratedObservationAnchor(
            snapshot.endpoint, snapshot.stream_epoch, snapshot.stream_identity, snapshot.cursor)
        self._observation_snapshot = snapshot
        return snapshot

    def changes(self, stream_epoch: int, cursor: int, *,
                deadline_monotonic: float | None = None) -> GeneratedChanges:
        """Bounded change read at one cursor: categories only, never the tree.

        A `resync_required` answer means the increment cannot be proven
        continuous (truncated history, replaced stream, cursor from the future);
        the caller takes a fresh `snapshot()` instead of stitching sections."""
        if stream_epoch < 0 or cursor < 0:
            raise GeneratedUiError("change cursor bounds are invalid")
        response = self._read(f"GET_GENERATED_UI_CHANGES {stream_epoch} {cursor}",
                              "GENERATED_UI_CHANGES", deadline_monotonic)
        changes = parse_generated_changes(response)
        if self._endpoint_identity is not None and changes.endpoint != self._endpoint_identity:
            raise GeneratedUiEndpointError(
                "endpoint_replaced",
                f"changes endpoint {changes.endpoint.describe()}, session {self._endpoint_identity.describe()}")
        if changes.since != cursor:
            raise GeneratedUiError(
                f"changes answered for cursor {changes.since}, requested {cursor}")
        if not changes.resync_required:
            if changes.current < changes.since:
                raise GeneratedUiError("changes current cursor is behind the requested cursor")
            previous = changes.since
            for change in changes.changes:
                if change.cursor <= previous or change.cursor > changes.current:
                    raise GeneratedUiError("changes cursors are not strictly increasing in range")
                previous = change.cursor
            if not changes.changes:
                # An empty increment is honest only when the declared cursor did
                # not move; otherwise the content in (since, current] was dropped.
                if changes.current != changes.since:
                    raise GeneratedUiProtocolError(
                        "empty_changes_current_moved",
                        f"no changes but CURRENT {changes.current} differs from SINCE {changes.since}")
            else:
                # The tail change must BE the declared CURRENT: a list that stops
                # short has silently dropped every cursor after its last entry.
                tail = changes.changes[-1]
                if tail.cursor != changes.current:
                    raise GeneratedUiProtocolError(
                        "change_tail_not_current",
                        f"last change cursor {tail.cursor} differs from CURRENT {changes.current}")
            for change in changes.changes:
                if change.category not in _SECTIONS_BY_CATEGORY:
                    raise GeneratedUiProtocolError(
                        "unknown_change_category",
                        f"change cursor {change.cursor} carries unknown category {change.category!r}")
        return changes

    def _read(self, command: str, kind: str,
              deadline_monotonic: float | None) -> SharedOperationResponse:
        try:
            response = self.client.request(self._query(command),
                                           deadline_monotonic=deadline_monotonic)
        except TimeoutError as exc:
            raise GeneratedUiDeadlineExceeded(str(exc)) from exc
        except ConnectionClosedError as exc:
            raise GeneratedUiEndpointError("endpoint_unavailable", str(exc)) from exc
        except (OSError, ConnectionError) as exc:
            raise GeneratedUiEndpointError("endpoint_unavailable", str(exc)) from exc
        self._last_response_bytes = len(response.raw)
        _result_values(response, kind)
        return response

    def section(self, section: str, expected_cursor: int, *,
                deadline_monotonic: float | None = None) -> GeneratedSection:
        """ONE snapshot section, guarded by the cursor the caller holds.

        A moved cursor answers `revision_changed` with no content; the caller
        discards its local state and takes a fresh snapshot. Sections can
        therefore never be stitched into a stale full state.
        """
        if section not in _GENERATED_SECTION_NAMES:
            raise GeneratedUiError(f"unknown generated-UI section {section!r}")
        if expected_cursor < 0:
            raise GeneratedUiError("section cursor cannot be negative")
        response = self._read(f"GET_GENERATED_UI_SECTION {section} {expected_cursor}",
                              "GENERATED_UI_SECTION", deadline_monotonic)
        part = parse_generated_section(response, section)
        if self._endpoint_identity is not None and part.endpoint != self._endpoint_identity:
            raise GeneratedUiEndpointError(
                "endpoint_replaced",
                f"section endpoint {part.endpoint.describe()}, session {self._endpoint_identity.describe()}")
        if part.cursor != expected_cursor:
            # An unrequested cursor is a protocol violation even if the provider
            # did not set the revision flag: the content cannot be stitched.
            raise GeneratedUiError(
                f"section cursor {part.cursor} differs from requested {expected_cursor}")
        if self._observation_anchor is not None:
            expected_epoch = self._observation_anchor.stream_epoch
            expected_identity = self._observation_anchor.stream_identity
            # An anchor seeded without a stream identity adopts the one the
            # server reports; every other mismatch is a real stream change.
            if part.stream_epoch != expected_epoch or (
                    expected_identity != "" and part.stream_identity != expected_identity):
                raise GeneratedUiError("section belongs to another observation stream")
        return part

    def seed_anchor(self, anchor: GeneratedObservationAnchor) -> None:
        """Seeds the poller with a cursor observed earlier (for example in a
        previous process).

        The ANCHOR is stored, not a bare number: its endpoint identity must match
        this session's endpoint, so a cursor minted by another endpoint instance
        can never be replayed against this one. A stream replacement or a resync
        answer still clears it.
        """
        if anchor.cursor < 0 or anchor.stream_epoch < 0:
            raise GeneratedUiError("observation anchor bounds are invalid")
        if self._endpoint_identity is not None and anchor.endpoint != self._endpoint_identity:
            raise GeneratedUiEndpointError(
                "endpoint_replaced",
                f"anchor endpoint {anchor.endpoint.describe()}, session {self._endpoint_identity.describe()}")
        self._endpoint_identity = anchor.endpoint
        self._observation_anchor = anchor
        self._observation_snapshot = None

    def seed_cursor(self, stream_epoch: int, cursor: int) -> None:
        """Compatibility wrapper: seeds a cursor for THIS session's endpoint.

        The endpoint half of the anchor comes from the live session (descriptor),
        not from the caller, so a bare pair of integers can only ever belong to
        the endpoint this session is already talking to.
        """
        endpoint = self._require_endpoint_identity()
        self.seed_anchor(GeneratedObservationAnchor(endpoint, stream_epoch, "", cursor))

    def _require_endpoint_identity(self) -> GeneratedEndpointIdentity:
        if self._endpoint_identity is not None:
            return self._endpoint_identity
        instance = str(self.client.descriptor.get("endpoint_instance", "") or "")
        generation = self.client.descriptor.get("endpoint_bind_generation")
        if not instance or not isinstance(generation, int):
            raise GeneratedUiError(
                "the descriptor carries no endpoint identity; take a snapshot before seeding")
        identity = GeneratedEndpointIdentity(instance, generation)
        self._endpoint_identity = identity
        return identity

    def observe_once(self, *, deadline_monotonic: float | None = None) -> GeneratedObservation:
        """The ONE public poller: snapshot once, then bounded changes.

        The cache is per session and discardable. A stream replacement or a
        `resync_required` answer clears it and takes a fresh snapshot; an
        unchanged round answers `kind="none"` WITHOUT re-reading the tree. It
        never fabricates section content from a change cursor: call
        `snapshot()` when the full state is needed.
        """
        if self._observation_anchor is None:
            snapshot = self.snapshot(deadline_monotonic=deadline_monotonic)
            return GeneratedObservation("snapshot", snapshot, None)
        anchor = self._observation_anchor
        changes = self.changes(anchor.stream_epoch, anchor.cursor,
                               deadline_monotonic=deadline_monotonic)
        stream_mismatch = changes.stream_epoch != anchor.stream_epoch or (
            anchor.stream_identity != "" and changes.stream_identity != anchor.stream_identity)
        if changes.resync_required or stream_mismatch:
            snapshot = self.snapshot(deadline_monotonic=deadline_monotonic)
            return GeneratedObservation("snapshot", snapshot, changes)
        if not changes.changes:
            # A verified no-change round: nothing to read, and the cursor advance
            # is safe because the endpoint/stream/range were all checked.
            self._observation_anchor = GeneratedObservationAnchor(
                changes.endpoint, changes.stream_epoch, changes.stream_identity, changes.current)
            return GeneratedObservation("none", None, changes)
        # Collect the affected sections into LOCAL variables. The new anchor is
        # committed only when every section has been read and validated: a
        # timeout, a disconnect or a mismatched section must leave the old anchor
        # in place so the next round re-reads the same increment instead of
        # reporting a bogus "no change".
        wanted: list[str] = []
        for change in changes.changes:
            for name in _SECTIONS_BY_CATEGORY.get(change.category, ()):
                if name not in wanted:
                    wanted.append(name)
        sections: dict[str, str] = {}
        for name in wanted:
            part = self.section(name, changes.current, deadline_monotonic=deadline_monotonic)
            if part.revision_changed:
                snapshot = self.snapshot(deadline_monotonic=deadline_monotonic)
                return GeneratedObservation("snapshot", snapshot, changes, None)
            if part.stream_epoch != changes.stream_epoch or \
                    part.stream_identity != changes.stream_identity:
                raise GeneratedUiError("section stream differs from the change stream")
            sections[name] = part.text
        self._observation_anchor = GeneratedObservationAnchor(
            changes.endpoint, changes.stream_epoch, changes.stream_identity, changes.current)
        return GeneratedObservation("changes", None, changes, sections or None)

    def last_response_bytes(self) -> int:
        """Payload bytes (UTF-8 text) of the most recent snapshot/change read."""
        return self._last_response_bytes

    def observation_anchor(self) -> GeneratedObservationAnchor | None:
        """The anchor the poller will resume from (None before a snapshot)."""
        return self._observation_anchor

    def action_signatures(self, *, deadline_monotonic: float | None = None) -> tuple[TypedActionSpec, ...]:
        return parse_action_signatures(
            self.client.get_context(deadline_monotonic=deadline_monotonic))

    def submit(self, nodes: "Sequence[GeneratedNode]", expected_version: int, *,
               deadline_monotonic: float | None = None) -> GeneratedSubmitResult:
        payload = encode_generated_structure(nodes)
        return parse_generated_submit(
            self.client.request(self._submit_payload(payload, expected_version),
                                deadline_monotonic=deadline_monotonic))

    def submit_text(self, payload: str, expected_version: int, *,
                    deadline_monotonic: float | None = None) -> GeneratedSubmitResult:
        return parse_generated_submit(
            self.client.request(self._submit_payload(payload, expected_version),
                                deadline_monotonic=deadline_monotonic))

    def wait_for_structure(self, expected_version: int, *, timeout_ms: int = 5_000,
                           poll_ms: int = 100) -> GeneratedStructureWait:
        """Bounded wait for the ACCEPTED structure to reach `expected_version`.

        ONE monotonic deadline covers the initial read, every later read and
        every sleep, and is passed to each read as an absolute deadline. A zero
        budget returns before issuing any request; an observation that finishes
        after the deadline is not published. On timeout the most recent valid
        in-budget observation is returned, or None if even the first read timed
        out; nothing is replayed.
        """
        if expected_version < 0 or timeout_ms < 0 or poll_ms <= 0:
            raise GeneratedUiError("wait bounds are invalid")
        deadline = time.monotonic() + timeout_ms / 1000.0
        last: GeneratedStructure | None = None
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return GeneratedStructureWait("timeout", last)
            try:
                observed = self.structure(deadline_monotonic=deadline)
            except TimeoutError:
                return GeneratedStructureWait("timeout", last)
            if time.monotonic() > deadline:
                # The read returned after the budget; never publish it.
                return GeneratedStructureWait("timeout", last)
            last = observed
            if observed.version >= expected_version:
                return GeneratedStructureWait("reached", observed)
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return GeneratedStructureWait("timeout", last)
            time.sleep(min(poll_ms / 1000.0, remaining))

    def candidate_state(self, token: int, *,
                        endpoint: GeneratedEndpointIdentity | None = None,
                        deadline_monotonic: float | None = None) -> GeneratedCandidateState:
        """Terminal read for ONE submission token.

        When `endpoint` is supplied the command carries the endpoint INSTANCE and
        bind generation, so the transport answers `endpoint_replaced` BEFORE it
        reads the holder's token table: a restarted endpoint cannot satisfy an old
        ticket with a coincidentally equal token. A local deadline expiry raises
        `GeneratedUiDeadlineExceeded`; a real connection failure raises
        `endpoint_unavailable`. The server's terminal state is never rewritten.
        """
        if token <= 0:
            raise GeneratedUiError("candidate token must be positive")
        command = f"GET_GENERATED_UI_CANDIDATE {token}"
        if endpoint is not None:
            command = f"{command} {endpoint.instance} {endpoint.bind_generation}"
        try:
            response = self.client.request(self._query(command),
                                           deadline_monotonic=deadline_monotonic)
        except TimeoutError as exc:
            # The local budget expired: the endpoint did not disappear.
            raise GeneratedUiDeadlineExceeded(str(exc)) from exc
        except (OSError, ConnectionError) as exc:
            raise GeneratedUiEndpointError("endpoint_unavailable", str(exc)) from exc
        self._last_response_bytes = len(response.raw)
        values = _result_values(response, "GENERATED_UI_CANDIDATE")
        state = parse_generated_candidate_state(response)
        expected = endpoint if endpoint is not None else self._endpoint_identity
        if expected is not None and state.endpoint != expected:
            raise GeneratedUiEndpointError(
                "endpoint_replaced",
                f"ticket endpoint {expected.describe()}, answer {state.endpoint.describe()}")
        if endpoint is None and self._endpoint_identity is None and not values:
            raise GeneratedUiError("candidate answer carried no endpoint identity")
        return state

    def candidate_state_current(self, token: int, *,
                                deadline_monotonic: float | None = None) -> GeneratedCandidateState:
        """Bare-token read: ONLY the endpoint this session is talking to.

        It makes no claim about any other endpoint instance, so a persisted bare
        token must be re-attributed through a full ticket instead.
        """
        return self.candidate_state(token, deadline_monotonic=deadline_monotonic)

    def wait_for_candidate_result(self, ticket: GeneratedCandidateTicket | int, *,
                                  timeout_ms: int = 5_000, poll_ms: int = 50) -> GeneratedCandidateWait:
        """Bounded wait with an EXPLICIT outcome.

        One monotonic deadline covers the initial read, every later read and the
        sleep. Outcomes: `terminal` (the server really settled the attempt),
        `timeout` (last in-budget observation returned), `timeout_without_observation`
        (zero/expired budget before any read), `endpoint_unavailable` and
        `endpoint_replaced`. A late answer is never published as an on-time
        success, and a local timeout is never reported as a rejected candidate.
        """
        if isinstance(ticket, GeneratedCandidateTicket):
            token = ticket.token
            endpoint = ticket.endpoint
        else:
            token = int(ticket)
            endpoint = None
        if token <= 0 or timeout_ms < 0 or poll_ms <= 0:
            raise GeneratedUiError("wait bounds are invalid")
        if timeout_ms == 0:
            return GeneratedCandidateWait("timeout_without_observation", None, 0)
        deadline = time.monotonic() + timeout_ms / 1000.0
        last: GeneratedCandidateState | None = None
        attempted = 0
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return GeneratedCandidateWait(
                    "timeout" if last is not None else "timeout_without_observation", last, attempted)
            attempted += 1
            try:
                state = self.candidate_state(token, endpoint=endpoint,
                                             deadline_monotonic=deadline)
            except GeneratedUiDeadlineExceeded:
                return GeneratedCandidateWait(
                    "timeout" if last is not None else "timeout_without_observation", last, attempted)
            except GeneratedUiEndpointError as exc:
                outcome = "endpoint_replaced" if exc.code == "endpoint_replaced" else "endpoint_unavailable"
                return GeneratedCandidateWait(outcome, last, attempted)
            if time.monotonic() > deadline:
                # The answer arrived after the budget: it is a timeout, not an
                # on-time terminal result.
                return GeneratedCandidateWait("timeout", last, attempted)
            last = state
            if state.settled():
                return GeneratedCandidateWait("terminal", state, attempted)
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return GeneratedCandidateWait("timeout", state, attempted)
            time.sleep(min(poll_ms / 1000.0, remaining))

    def wait_for_candidate(self, ticket: GeneratedCandidateTicket | int, *,
                           timeout_ms: int = 5_000, poll_ms: int = 50) -> GeneratedCandidateState:
        """Convenience wrapper over `wait_for_candidate_result`.

        Returns the last in-budget observation on a timeout; raises
        `GeneratedUiDeadlineExceeded` when the budget expired before ANY
        observation. Endpoint failures keep their own types.
        """
        result = self.wait_for_candidate_result(ticket, timeout_ms=timeout_ms, poll_ms=poll_ms)
        if result.outcome in ("endpoint_replaced", "endpoint_unavailable"):
            # The endpoint failed: never report it as a deadline or a state.
            raise GeneratedUiEndpointError(result.outcome, "candidate wait ended on an endpoint failure")
        if result.last_state is None:
            raise GeneratedUiDeadlineExceeded(
                f"candidate wait produced no observation ({result.outcome})")
        return result.last_state

    def invoke_action(self, action: str, targets: "Sequence[int]",
                      arguments: "Sequence[SharedOperationArgument]" = (),
                      *, expected_version: int | None = None,
                      deadline_monotonic: float | None = None) -> SharedOperationResponse:
        """Invoke a DOMAIN action with typed arguments validated against the
        published signature (name/type/required/target bounds).

        Local validation is a fail-fast projection of the published signature,
        in this order: unknown action, target count, duplicate name, unknown
        name, declared type, missing required. The declared metadata itself is
        checked first so an unusable signature never produces a misleading
        code. No request is sent once one of these fails, and no business range
        or authorization rule is duplicated here: transport and owner stay the
        final authority.
        """
        try:
            signatures = self.action_signatures(deadline_monotonic=deadline_monotonic)
        except GeneratedUiError as exc:
            raise GeneratedUiArgumentValidationError(
                "invalid_action_metadata", action, detail=str(exc)) from exc
        signature = None
        for candidate in signatures:
            if candidate.name == action:
                signature = candidate
                break
        if signature is None:
            raise GeneratedUiArgumentValidationError("unknown_action", action)
        if (signature.minimum_targets < 0
                or signature.maximum_targets < signature.minimum_targets):
            raise GeneratedUiArgumentValidationError(
                "invalid_action_metadata", action,
                detail="declared target bounds are invalid")
        for parameter in signature.parameters:
            if not IDENTIFIER.fullmatch(parameter.name):
                raise GeneratedUiArgumentValidationError(
                    "invalid_action_metadata", action, name=parameter.name,
                    detail="declared parameter name is not an identifier")
            if parameter.value_type not in _SUPPORTED_VALUE_TYPES:
                raise GeneratedUiArgumentValidationError(
                    "invalid_action_metadata", action, name=parameter.name,
                    expected_type="|".join(_SUPPORTED_VALUE_TYPES),
                    actual_type=parameter.value_type,
                    detail="declared parameter type is not supported")
        if not (signature.minimum_targets <= len(targets) <= signature.maximum_targets):
            raise GeneratedUiArgumentValidationError(
                "target_count_out_of_range", action,
                detail=f"accepts {signature.minimum_targets}..{signature.maximum_targets} targets")
        declared = {parameter.name: parameter for parameter in signature.parameters}
        seen: set[str] = set()
        for argument in arguments:
            if argument.name in seen:
                raise GeneratedUiArgumentValidationError(
                    "duplicate_argument", action, name=argument.name,
                    actual_type=argument.value_type)
            seen.add(argument.name)
        for argument in arguments:
            if argument.name not in declared:
                raise GeneratedUiArgumentValidationError(
                    "unknown_argument", action, name=argument.name,
                    actual_type=argument.value_type)
        for argument in arguments:
            expected_type = declared[argument.name].value_type
            if argument.value_type != expected_type:
                raise GeneratedUiArgumentValidationError(
                    "argument_type_mismatch", action, name=argument.name,
                    expected_type=expected_type, actual_type=argument.value_type)
        for parameter in signature.parameters:
            if parameter.required and parameter.name not in seen:
                raise GeneratedUiArgumentValidationError(
                    "missing_required_argument", action, name=parameter.name,
                    expected_type=parameter.value_type)
        version = expected_version
        if version is None:
            version = parse_domain_version(
                self.client.get_context(deadline_monotonic=deadline_monotonic))
        return self.client.invoke(version, action, targets, arguments,
                                  deadline_monotonic=deadline_monotonic)

    def _query(self, command: str) -> str:
        return "\n".join([f"PROTOCOL {PROTOCOL}", f"AUTH {self.client.descriptor['capability']}", command])

    def _submit_payload(self, payload: str, expected_version: int) -> str:
        if expected_version < 0:
            raise GeneratedUiError("expected structure version cannot be negative")
        if not payload or "GENERATED_UI_STRUCTURE" not in payload or not payload.rstrip("\n").endswith("END"):
            raise GeneratedUiError("candidate payload must be a complete GENERATED_UI_STRUCTURE ending with END")
        return "\n".join([f"PROTOCOL {PROTOCOL}", f"AUTH {self.client.descriptor['capability']}",
                          f"SUBMIT_GENERATED_UI {expected_version}", payload])


def parse_domain_version(response: SharedOperationResponse) -> int:
    for label, tokens in response.entries:
        if label == "VERSION" and tokens:
            return _token_int(tokens[0], "domain VERSION")
    return -1

