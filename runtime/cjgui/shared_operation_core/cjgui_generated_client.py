#!/usr/bin/env python3
"""Typed public client for the runtime-generated UI surface.

This module turns the line protocols an application already publishes through
`client.py` into typed objects, so a普通 consumer (or a model-driven bridge) can
discover declared capabilities, read the accepted structure/fields/instances,
build a candidate, submit it and observe acceptance without re-implementing a
regex parser or hard-coding an action name, a field id or a resource id.

It adds no business owner, no model runtime and no second permission system: it
is a thin typed layer over the SAME public connection. Desktop consumers use an
application-issued descriptor; OHOS consumers can name a caller-owned, explicit
target and local TCP forward while retaining the typed session and ticket logic.

What is deliberately NOT here:
  * no UI presentation claim — reading the accepted structure/geometry says what
    the window accepted, not what a GPU displayed;
  * no automatic merge of business conflicts and no automatic replay: a stale
    version, a rejected candidate, a superseded candidate, a closed endpoint and
    a timeout are DIFFERENT results and are reported separately.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterable
import re
import json
import socket
import time

# The fixed-snapshot lease helpers (SnapshotLease / SnapshotRangeRead /
# SnapshotReleaseReceipt and their parsers) are the SAME typed objects as
# `client.py` publishes, re-exported here so a consumer of this typed layer
# reaches them without a second import. They are deliberately not
# re-implemented: one implementation is what keeps the wire line and its
# parsers identical for both consumers.
from client import (
    ConnectionClosedError,
    IDENTIFIER,
    LEASE_TOKEN,
    OPAQUE_IDENTITY,
    PROTOCOL,
    SharedOperationArgument,
    SharedOperationClient,
    SharedOperationResponse,
    SnapshotLease,
    SnapshotRangeRead,
    SnapshotReleaseReceipt,
    _remaining_budget,
    _send_all,
    frame,
    parse_response,
    parse_snapshot_lease,
    parse_snapshot_range,
    parse_snapshot_release,
    read_frame,
    require_lease_token,
    require_opaque_identity,
)


class GeneratedUiError(RuntimeError):
    """A typed validation failure on the generated-UI surface."""


class GeneratedUiHistoryRefusal(GeneratedUiError):
    """A named local refusal: no history mutation request was sent."""

    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


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


# Declared reason tokens the endpoint is known to publish. A code outside this
# set is preserved as an unknown remote error, never rewritten into a known one.
_KNOWN_ERROR_CODES = frozenset({
    "authorization_revoked", "changes_unavailable", "endpoint_replaced",
    "generated_ui_payload_too_large", "generated_ui_unavailable", "invalid_parameters",
    "invalid_request", "invalid_snapshot", "malformed_error_envelope", "owner_busy",
    "range_read_capacity", "range_read_failed", "range_read_unavailable",
    "request_cancelled", "response_too_large", "server_busy", "unauthorized_action",
    "unauthorized_caller", "unauthorized_resource", "unknown_window_target",
})


class GeneratedUiRemoteError(GeneratedUiError):
    """A machine-readable refusal from the endpoint.

    `code` is the declared reason token. `detail`, `versions` and `target` are
    populated only from facts the endpoint actually published; missing facts stay
    empty instead of being inferred. An unrecognised code is preserved with
    `unknown=True` so a newer endpoint is never misreported as a known refusal.
    """

    def __init__(
        self,
        code: str,
        expected_kind: str,
        detail: str = "",
        versions: dict[str, int] | None = None,
        target: str = "",
        raw: tuple[str, ...] = (),
        unknown: bool = False,
    ) -> None:
        self.code = code
        self.expected_kind = expected_kind
        self.detail = detail
        self.versions = dict(versions or {})
        # Named separately so a caller never has to treat a request CAS as the
        # version the owner actually observed. Missing facts remain None.
        self.request_version = self.versions.get("REQUEST_VERSION")
        self.observed_version = self.versions.get("OBSERVED_VERSION")
        self.target = target
        self.raw = tuple(raw)
        self.unknown = unknown
        message = f"endpoint refused {expected_kind}: {code}"
        if detail:
            message += f": {detail}"
        super().__init__(message)


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
            extras: dict[str, str] = {}
            index = 1
            while index < len(tokens):
                if index + 1 >= len(tokens):
                    raise GeneratedUiRemoteError("malformed_error_envelope", expected_kind, raw=tokens)
                extras[tokens[index]] = tokens[index + 1]
                index += 2
            detail = ""
            if "DETAIL_HEX" in extras:
                detail = _hex_text(extras["DETAIL_HEX"], "ERROR DETAIL_HEX")
            versions: dict[str, int] = {}
            for key in ("VERSION", "VERSION_BEFORE", "VERSION_AFTER",
                        "REQUEST_VERSION", "OBSERVED_VERSION"):
                if key in extras:
                    versions[key] = _token_int(extras[key], f"ERROR {key}")
            raise GeneratedUiRemoteError(
                reason, expected_kind, detail, versions, extras.get("TARGET", ""), tokens,
                reason not in _KNOWN_ERROR_CODES)
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


def _decode_text_token(token: str, what: str, max_bytes: int = 4096) -> str:
    """Decode the optional `u8:<hex>` discovery token; plain tokens stay literal.

    The producer encodes only when a literal value would break the line/token
    grammar, so an older reader still sees one opaque token and a current reader
    recovers spaces and non-ASCII text exactly. Budget and control-character
    checks run after decoding, so a plaintext token cannot bypass the same rule
    its encoded form must satisfy.
    """
    if token.startswith("u8:"):
        raw = token[3:]
        if not raw or len(raw) % 2 != 0 or not _HEX.fullmatch(raw):
            raise GeneratedUiError(f"{what} has a malformed u8 token")
        data = bytes.fromhex(raw)
        try:
            value = data.decode("utf-8", "strict")
        except UnicodeDecodeError as exc:
            raise GeneratedUiError(f"{what} is not valid UTF-8") from exc
    else:
        value = token
    if not value:
        raise GeneratedUiError(f"{what} is empty")
    if len(value.encode("utf-8")) > max_bytes:
        raise GeneratedUiError(f"{what} exceeds its byte budget")
    for character in value:
        scalar = ord(character)
        if scalar < 0x20 or scalar == 0x7F:
            raise GeneratedUiError(f"{what} contains a control character")
    return value


def encode_generated_text_token(value: str, max_bytes: int | None = None) -> str:
    """Encode one bounded discovery token exactly like the producer.

    Safe non-empty printable ASCII (no `=`) stays verbatim; everything else is
    carried as `u8:<lowercase UTF-8 hex>`. An empty value is not a token.
    """
    if not value:
        raise GeneratedUiError("text token is empty")
    encoded = value.encode("utf-8")
    if max_bytes is not None and len(encoded) > max_bytes:
        raise GeneratedUiError("text token exceeds its byte budget")
    safe = not value.startswith("u8:") and all(
        0x21 <= ord(character) <= 0x7E and character != "=" for character in value)
    return value if safe else "u8:" + encoded.hex()


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
    # Structured-value discovery, published from the SAME constants acceptance
    # obeys (empty = the token was not published for this property). A reader
    # that only has `capabilities()` can assemble a legal structured value
    # without reading application source:
    #   * `encoding`      the wire grammar (`offX,offY,blur,spread,#RRGGBBAA`);
    #   * `unit`          the unit of a structured/numeric value;
    #   * `value_range`   the accepted domain (`offset:-4096..4096,blur:0..256`);
    #   * `semantics`     what empty/`none`/omitted mean;
    #   * `stability`     the contract stability marker;
    #   * `backend_support` the backend support surface.
    encoding: str = ""
    unit: str = ""
    value_range: str = ""
    semantics: str = ""
    stability: str = ""
    backend_support: str = ""

    def range_entries(self) -> tuple[tuple[str, str, str], ...]:
        """The `range=` token as `(name, low, high)` triples.

        The published grammar is `name:low..high` entries joined by commas (for
        example `offset:-4096..4096,blur:0..256,spread:0..128`). An empty token
        yields no entries; a malformed entry is refused instead of skipped, so a
        reader can never silently lose an upper bound it is about to enforce.
        """
        if not self.value_range:
            return ()
        entries: list[tuple[str, str, str]] = []
        for raw in self.value_range.split(","):
            name, separator, bounds = raw.partition(":")
            low, dots, high = bounds.partition("..")
            if not separator or not dots or not name or not low or not high:
                raise GeneratedUiError(f"property range entry is malformed: {raw!r}")
            entries.append((name, low, high))
        return tuple(entries)


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


CHOICE_FORMAT_FIELDS_V1 = ("fieldId", "key", "value", "enabled", "reason", "label")


@dataclass(frozen=True)
class GeneratedChoiceFormat:
    """The CHOICE_FORMAT declaration published beside the catalog.

    `state` distinguishes a format this client understands (`supported`) from a
    published format it must not guess (`unsupported_by_client`). The latter is
    a client capability statement, never an endpoint capability claim.
    """

    version: int | None
    encoding: str
    fields: tuple[str, ...]
    state: str
    detail: str = ""

    @property
    def supported(self) -> bool:
        return self.state == "supported"


@dataclass(frozen=True)
class GeneratedChoiceOption:
    """One current option of one declared choice field.

    `key` is the stable business key used for routing; `value` is the field's
    business value; `label` is display text only. `disabled_reason` is empty
    only for the reserved `reason=none` token.
    """

    field_id: str
    key: str
    value: str
    enabled: bool
    disabled_reason: str
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
class GeneratedWindowBackgroundSpec:
    """Window-scoped generated declaration, separate from node properties."""

    name: str
    value_type: str
    root_only: bool
    values: tuple[str, ...]
    default: str
    omitted: str
    stability: str
    backend_support: str


@dataclass(frozen=True)
class GeneratedFontResource:
    key: str
    version: int
    state: str
    resolved_family: str
    name: str


_SUPPORT_STATES = frozenset({"available", "fallback", "unavailable", "unverified"})
_EVIDENCE_STATES = frozenset({"verified", "unverified"})

# Wire compatibility is checked from the SURFACE declaration itself. An absent
# SURFACE line is a legacy producer and stays readable; a declared surface that
# this client cannot read is refused by name instead of being parsed as if it
# had published less.
SUPPORTED_SURFACE_MAJOR = 1
SUPPORTED_SURFACE_PROTOCOLS = frozenset({"2"})
SUPPORTED_SURFACE_COMPATIBILITY = frozenset({"additive_only"})


def _require_compatible_surface(surface: GeneratedSurface) -> None:
    major_text = surface.version.split(".", 1)[0]
    if not major_text.isdigit():
        raise GeneratedUiError(f"capability SURFACE version {surface.version} is malformed")
    if int(major_text) != SUPPORTED_SURFACE_MAJOR:
        raise GeneratedUiError(
            f"capability SURFACE version {surface.version} is not supported "
            f"(supported major {SUPPORTED_SURFACE_MAJOR})")
    if surface.protocol not in SUPPORTED_SURFACE_PROTOCOLS:
        supported = ",".join(sorted(SUPPORTED_SURFACE_PROTOCOLS))
        raise GeneratedUiError(
            f"capability SURFACE protocol {surface.protocol} is not supported (supported {supported})")
    if surface.compatibility not in SUPPORTED_SURFACE_COMPATIBILITY:
        supported = ",".join(sorted(SUPPORTED_SURFACE_COMPATIBILITY))
        raise GeneratedUiError(
            f"capability SURFACE compatibility {surface.compatibility} is not supported "
            f"(supported {supported})")



@dataclass(frozen=True)
class GeneratedSurface:
    """The first public surface declaration carried by the same payload.

    `compatibility` is the published rule (currently `additive_only`): new
    optional lines/keys may appear, existing meanings are not renamed. Unknown
    value tokens are preserved in `extra` so a forward-compatible reader does
    not silently drop them.
    """

    version: str
    stability: str
    compatibility: str
    protocol: str
    subset: tuple[str, ...]
    extra: tuple[tuple[str, str], ...] = ()


@dataclass(frozen=True)
class GeneratedSupportFact:
    """A registered capability and the admission source that accepts it."""

    kind: str
    item: str
    state: str
    reason: str
    source: str


@dataclass(frozen=True)
class GeneratedDeliveryEvidence:
    """Delivery evidence for one item; unverified is a first-class state."""

    item: str
    state: str
    reason: str


@dataclass(frozen=True)
class GeneratedCompositionBudget:
    """One candidate's published composition capacity.

    `definitions == 1` is the legacy endpoint that never advertised the fact:
    such an endpoint cannot receive a multi-definition batch, so the client
    keeps the old one-definition behaviour instead of optimistically splitting.
    """

    definitions: int = 1
    elements: int = 24
    template_nodes: int = 64
    bytes: int = 262144


@dataclass(frozen=True)
class GeneratedUiHistorySupport:
    version: int | None
    supported: bool | None
    stability: str
    scope: str
    extra: tuple[tuple[str, str], ...] = ()


@dataclass(frozen=True)
class GeneratedUiHistoryState:
    format_version: int | None = None
    supported: bool | None = None
    enabled: bool | None = None
    surface_identity: int | None = None
    accepted_version: int | None = None
    accepted_digest: str | None = None
    history_epoch: int | None = None
    head_version: int | None = None
    can_undo: bool | None = None
    can_redo: bool | None = None
    undo_depth: int | None = None
    redo_depth: int | None = None
    retained_serialized_bytes: int | None = None
    maximum_transactions: int | None = None
    maximum_serialized_bytes: int | None = None
    pending_action: str | None = None
    pending_token: int | None = None
    undo_reason: str | None = None
    redo_reason: str | None = None
    boundary_reason: str | None = None
    endpoint_identity: GeneratedEndpointIdentity | None = None
    extra: tuple[tuple[str, str], ...] = ()


def history_state_from_dict(value: Any) -> GeneratedUiHistoryState:
    """A saved CAS observation, not persisted undo history or a fresh read."""
    if not isinstance(value, dict):
        raise GeneratedUiHistoryRefusal("ui_document_history_baseline_invalid")
    names = GeneratedUiHistoryState.__dataclass_fields__
    kwargs = {key: val for key, val in value.items() if key in names}
    endpoint = kwargs.get("endpoint_identity")
    if endpoint is not None:
        if not isinstance(endpoint, dict) or set(endpoint) != {"instance", "bind_generation"}:
            raise GeneratedUiHistoryRefusal("ui_document_history_baseline_invalid")
        if (not isinstance(endpoint["instance"], str) or not endpoint["instance"] or
                type(endpoint["bind_generation"]) is not int or endpoint["bind_generation"] <= 0):
            raise GeneratedUiHistoryRefusal("ui_document_history_baseline_invalid")
        kwargs["endpoint_identity"] = GeneratedEndpointIdentity(**endpoint)
    extra = kwargs.get("extra", ())
    if (not isinstance(extra, (list, tuple)) or any(
            not isinstance(item, (list, tuple)) or len(item) != 2 or
            not all(isinstance(part, str) for part in item) for item in extra)):
        raise GeneratedUiHistoryRefusal("ui_document_history_baseline_invalid")
    extra = list(extra)
    for key, val in value.items():
        if key not in names:
            extra.append((key, json.dumps(val, ensure_ascii=False)))
    kwargs["extra"] = tuple(tuple(item) for item in extra)
    return GeneratedUiHistoryState(**kwargs)


def parse_generated_history(response: SharedOperationResponse) -> GeneratedUiHistoryState:
    values = _result_values(response, "GENERATED_UI_HISTORY")
    endpoint = _endpoint_identity_from(values, "history reply")
    raw: dict[str, str] = {}
    for label, tokens in response.entries:
        if label == "END":
            continue
        if label in raw:
            raise GeneratedUiError("history reply repeats " + label)
        raw[label] = " ".join(tokens)
    version = _token_int(raw["UI_DOCUMENT_HISTORY"], "history format") if "UI_DOCUMENT_HISTORY" in raw else None
    if version not in (None, 1):
        return GeneratedUiHistoryState(format_version=version, endpoint_identity=endpoint,
                                       extra=tuple(raw.items()))
    names = {
        "surface_identity": "SURFACE_ID", "accepted_version": "ACCEPTED_VERSION",
        "history_epoch": "HISTORY_EPOCH", "head_version": "HEAD_VERSION",
        "undo_depth": "UNDO_DEPTH", "redo_depth": "REDO_DEPTH",
        "retained_serialized_bytes": "RETAINED_BYTES", "maximum_transactions": "TRANSACTION_LIMIT",
        "maximum_serialized_bytes": "BYTE_LIMIT", "pending_token": "PENDING_TOKEN"}
    facts = {name: _token_int(raw[key], "history " + key) if key in raw else None
             for name, key in names.items()}
    bool_names = {"supported": "SUPPORTED", "enabled": "ENABLED", "can_undo": "CAN_UNDO", "can_redo": "CAN_REDO"}
    facts.update({name: _token_bool(raw[key], "history " + key) if key in raw else None
                  for name, key in bool_names.items()})
    reason_names = {"undo_reason": "UNDO_REASON_HEX", "redo_reason": "REDO_REASON_HEX",
                    "boundary_reason": "BOUNDARY_REASON_HEX"}
    facts.update({name: ("" if raw[key] == "-" else _hex_text(raw[key], "history " + key)) if key in raw else None
                  for name, key in reason_names.items()})
    digest = raw.get("ACCEPTED_DIGEST")
    if digest == "-":
        digest = None
    if digest is not None and not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise GeneratedUiError("history accepted digest is malformed")
    pending_action = raw.get("PENDING_ACTION")
    if pending_action == "none":
        pending_action = ""
    ignored = {"PROTOCOL", "KIND", "PAYLOAD_LENGTH", "ENDPOINT_EPOCH", "ENDPOINT_INSTANCE",
               "ENDPOINT_BIND_GENERATION", "UI_DOCUMENT_HISTORY", "ACCEPTED_DIGEST", "PENDING_ACTION"}
    known = ignored | set(names.values()) | set(bool_names.values()) | set(reason_names.values())
    return GeneratedUiHistoryState(format_version=version, accepted_digest=digest,
        pending_action=pending_action, endpoint_identity=endpoint,
        extra=tuple((key, value) for key, value in raw.items() if key not in known), **facts)


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
    window_background: GeneratedWindowBackgroundSpec | None = None
    font_resources: tuple[GeneratedFontResource, ...] = ()
    surface: GeneratedSurface | None = None
    support: tuple[GeneratedSupportFact, ...] = ()
    evidence: tuple[GeneratedDeliveryEvidence, ...] = ()
    choice_format: GeneratedChoiceFormat | None = None
    choice_options: tuple[GeneratedChoiceOption, ...] = ()
    composition_budget: GeneratedCompositionBudget = GeneratedCompositionBudget()
    ui_document_history: GeneratedUiHistorySupport | None = None

    def support_for(self, kind: str, item: str) -> GeneratedSupportFact | None:
        for fact in self.support:
            if fact.kind == kind and fact.item == item:
                return fact
        return None

    def evidence_for(self, item: str) -> GeneratedDeliveryEvidence | None:
        for fact in self.evidence:
            if fact.item == item:
                return fact
        return None

    def font_resource(self, key: str, version: int) -> GeneratedFontResource | None:
        return next((font for font in self.font_resources if font.key == key and font.version == version), None)

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

    def choice_fields(self) -> tuple[str, ...]:
        """Distinct choice field ids in published option order."""
        seen: list[str] = []
        for option in self.choice_options:
            if option.field_id not in seen:
                seen.append(option.field_id)
        return tuple(seen)

    def choice_options_for(self, field_id: str) -> tuple[GeneratedChoiceOption, ...]:
        """Current options for one field, in the published order; never labels."""
        return tuple(option for option in self.choice_options if option.field_id == field_id)


# The trailing `key=value` tokens a capability PROPERTY line may publish. The
# tokenizer below reads a value as everything up to the NEXT ` <known>=`
# boundary, so a value may contain spaces, commas and `=` without changing the
# single-line protocol (for example the framework's own
# `semantics=none_or_empty=clear,absent=inherit`). A token whose name is not in
# this set is refused - never skipped - so a newer framework cannot be read as if
# it had published less than it did.
_PROPERTY_EXTRA_KEYS = frozenset({
    "values", "default", "encoding", "unit", "range", "semantics", "stability", "support",
})
_PROPERTY_EXTRA_KEY = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)=")


def _parse_property_extras(extras: str) -> dict[str, str]:
    """Split the trailing `key=value` tokens of one capability PROPERTY line.

    `extras` is everything after the eight fixed columns. Each value runs up to
    the next ` <known>=` boundary, so a value that itself contains spaces (or
    `=`, as `semantics=none_or_empty=clear,absent=inherit` does) is preserved
    losslessly. An unknown key or a tail that does not start with a known key is
    a protocol error, because dropping it would hide a token the publisher sent.
    """
    tokens: dict[str, str] = {}
    index = 0
    length = len(extras)
    while index < length:
        match = _PROPERTY_EXTRA_KEY.match(extras, index)
        if match is None or match.group(1) not in _PROPERTY_EXTRA_KEYS:
            raise GeneratedUiError("capability PROPERTY line has an unknown token")
        key = match.group(1)
        value_start = match.end()
        value_end = length
        probe = value_start
        while True:
            space = extras.find(" ", probe)
            if space < 0:
                break
            boundary = _PROPERTY_EXTRA_KEY.match(extras, space + 1)
            if boundary is not None and boundary.group(1) in _PROPERTY_EXTRA_KEYS:
                value_end = space
                break
            probe = space + 1
        tokens[key] = extras[value_start:value_end]
        index = value_end + 1 if value_end < length else length
    return tokens


def _key_value_tokens(parts: list[str], context: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for token in parts:
        key, separator, value = token.partition("=")
        if not separator or not key or not value or key in values:
            raise GeneratedUiError(f"{context} has a malformed token")
        values[key] = value
    return values


def parse_generated_capabilities(response: SharedOperationResponse) -> GeneratedCapabilities:
    _result_values(response, "GENERATED_UI_CAPABILITIES")
    components: dict[str, list[GeneratedPropertySpec]] = {}
    component_children: dict[str, tuple[bool, int]] = {}
    composites: list[GeneratedCompositeSpec] = []
    elements: list[GeneratedElementSpec] = []
    actions: list[GeneratedActionSpec] = []
    fields: list[GeneratedFieldSpec] = []
    image_resources: list[GeneratedImageResource] = []
    font_resources: list[GeneratedFontResource] = []
    window_background: GeneratedWindowBackgroundSpec | None = None
    surface: GeneratedSurface | None = None
    support: list[GeneratedSupportFact] = []
    evidence: list[GeneratedDeliveryEvidence] = []
    support_keys: set[tuple[str, str]] = set()
    evidence_items: set[str] = set()
    choice_format: GeneratedChoiceFormat | None = None
    choice_format_seen = False
    choice_format_supported = False
    choice_options: list[GeneratedChoiceOption] = []
    choice_keys: set[tuple[str, str]] = set()
    composition_budget: GeneratedCompositionBudget | None = None
    ui_document_history: GeneratedUiHistorySupport | None = None
    max_depth = max_nodes = max_properties = max_string = 0
    for line in _payload_lines(response):
        if line.startswith("UI_DOCUMENT_HISTORY "):
            tokens = _key_value_tokens(line.split(" ")[1:], "UI_DOCUMENT_HISTORY")
            if ui_document_history is not None or not {"version", "supported", "stability", "scope"} <= tokens.keys():
                raise GeneratedUiError("capability UI_DOCUMENT_HISTORY is malformed")
            version = _token_int(tokens["version"], "history capability version")
            ui_document_history = GeneratedUiHistorySupport(version,
                _token_bool(tokens["supported"], "history supported") if version == 1 else None,
                tokens["stability"], tokens["scope"],
                tuple((key, value) for key, value in tokens.items()
                      if key not in {"version", "supported", "stability", "scope"}))
            continue
        if line.startswith("COMPOSITION_BUDGET "):
            values = _key_value_tokens(line.split(" ")[1:], "capability COMPOSITION_BUDGET")
            expected = {"version", "definitions", "elements", "template_nodes", "bytes"}
            if composition_budget is not None or set(values) != expected or \
                    values["version"] != "1":
                raise GeneratedUiError("capability COMPOSITION_BUDGET line is malformed")
            budget = GeneratedCompositionBudget(
                _token_int(values["definitions"], "COMPOSITION_BUDGET definitions"),
                _token_int(values["elements"], "COMPOSITION_BUDGET elements"),
                _token_int(values["template_nodes"], "COMPOSITION_BUDGET template nodes"),
                _token_int(values["bytes"], "COMPOSITION_BUDGET bytes"))
            if budget.definitions < 1 or budget.elements < 1 or \
                    budget.template_nodes < 1 or budget.bytes < 1:
                raise GeneratedUiError("capability COMPOSITION_BUDGET bounds are malformed")
            composition_budget = budget
            continue
        if line.startswith("CHOICE_FORMAT "):
            if choice_format_seen:
                raise GeneratedUiError("capability CHOICE_FORMAT appears more than once")
            values = _key_value_tokens(line.split(" ")[1:], "capability CHOICE_FORMAT")
            if not {"version", "encoding", "fields"} <= values.keys():
                raise GeneratedUiError("capability CHOICE_FORMAT line is malformed")
            raw_version = values["version"]
            try:
                version = int(raw_version)
            except ValueError:
                version = None
            choice_field_names = tuple(values["fields"].split(",")) if values["fields"] else ()
            supported = (set(values) == {"version", "encoding", "fields"} and
                         version == 1 and values["encoding"] == "token" and
                         choice_field_names == CHOICE_FORMAT_FIELDS_V1)
            detail = "" if supported else (
                f"version={raw_version!r} encoding={values['encoding']!r} "
                f"fields={values['fields']!r}")
            choice_format = GeneratedChoiceFormat(
                version, values["encoding"], choice_field_names,
                "supported" if supported else "unsupported_by_client", detail)
            choice_format_seen = True
            choice_format_supported = supported
            continue
        if line.startswith("CHOICE "):
            if not choice_format_seen:
                raise GeneratedUiError("capability CHOICE line appears before CHOICE_FORMAT")
            if not choice_format_supported:
                # An unknown format is not interpreted as an empty/partial
                # option list; the format declaration carries that state.
                continue
            parts = line.split(" ")
            if len(parts) != 7 or not IDENTIFIER.fullmatch(parts[1]):
                raise GeneratedUiError("capability CHOICE line is malformed")
            tokens = _key_value_tokens(parts[2:], "capability CHOICE")
            if set(tokens) != {"key", "value", "enabled", "reason", "label"} or \
                    tokens["enabled"] not in ("0", "1"):
                raise GeneratedUiError("capability CHOICE line has an unknown or missing token")
            option_key = _decode_text_token(tokens["key"], "CHOICE key", 256)
            identity = (parts[1], option_key)
            if identity in choice_keys:
                raise GeneratedUiError(
                    f"capability CHOICE repeats key {option_key!r} on field {parts[1]!r}")
            choice_keys.add(identity)
            reason = "" if tokens["reason"] == "none" else \
                _decode_text_token(tokens["reason"], "CHOICE reason", 512)
            choice_options.append(GeneratedChoiceOption(
                parts[1], option_key,
                _decode_text_token(tokens["value"], "CHOICE value", 256),
                tokens["enabled"] == "1", reason,
                _decode_text_token(tokens["label"], "CHOICE label", 1024)))
            continue
        if line.startswith("SURFACE "):
            values = _key_value_tokens(line.split(" ")[1:], "capability SURFACE")
            required = {"version", "stability", "compatibility", "protocol", "subset"}
            if surface is not None or not required <= values.keys() or not values["version"]:
                raise GeneratedUiError("capability SURFACE line is malformed")
            subset = tuple(values["subset"].split(","))
            if any(not item for item in subset):
                raise GeneratedUiError("capability SURFACE subset is malformed")
            extra = tuple(sorted((key, value) for key, value in values.items() if key not in required))
            surface = GeneratedSurface(values["version"], values["stability"], values["compatibility"],
                                       values["protocol"], subset, extra)
        elif line.startswith("SUPPORT "):
            parts = line.split(" ")
            if len(parts) < 4 or not parts[1] or not parts[2]:
                raise GeneratedUiError("capability SUPPORT line is malformed")
            values = _key_value_tokens(parts[3:], "capability SUPPORT")
            state, source = values.get("state", ""), values.get("source", "")
            if state not in _SUPPORT_STATES or "reason" not in values or not source:
                raise GeneratedUiError("capability SUPPORT line has an unknown state or missing fact")
            item = _decode_text_token(parts[2], "capability SUPPORT item", 128)
            reason = _decode_text_token(values["reason"], "capability SUPPORT reason", 512)
            key = (parts[1], item)
            if key in support_keys:
                raise GeneratedUiError(
                    f"capability SUPPORT repeats {parts[1]}:{item}; one effective fact is required")
            support_keys.add(key)
            support.append(GeneratedSupportFact(parts[1], item, state, reason, source))
        elif line.startswith("EVIDENCE "):
            parts = line.split(" ")
            if len(parts) < 3 or not parts[1]:
                raise GeneratedUiError("capability EVIDENCE line is malformed")
            values = _key_value_tokens(parts[2:], "capability EVIDENCE")
            state = values.get("state", "")
            if state not in _EVIDENCE_STATES or "reason" not in values:
                raise GeneratedUiError("capability EVIDENCE line has an unknown state or missing reason")
            item = _decode_text_token(parts[1], "capability EVIDENCE item", 192)
            reason = _decode_text_token(values["reason"], "capability EVIDENCE reason", 512)
            if item in evidence_items:
                raise GeneratedUiError(f"capability EVIDENCE repeats {item}")
            evidence_items.add(item)
            evidence.append(GeneratedDeliveryEvidence(item, state, reason))
        elif line.startswith("BOUNDS "):
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
            # Split only the eight fixed columns; the remainder is the optional
            # trailing token tail, whose values may contain spaces.
            parts = line.split(" ", 8)
            if len(parts) < 8:
                raise GeneratedUiError("capability PROPERTY line is malformed")
            extras = _parse_property_extras(parts[8]) if len(parts) > 8 else {}
            raw_values = extras.get("values", "")
            values: tuple[str, ...] = tuple(raw_values.split(",")) if raw_values else ()
            components.setdefault(parts[1], []).append(GeneratedPropertySpec(
                parts[2], parts[3], _token_bool(parts[4], "PROPERTY required"),
                _token_int(parts[5], "PROPERTY minimum"), _token_int(parts[6], "PROPERTY maximum"),
                _token_int(parts[7], "PROPERTY max length"), values, extras.get("default", ""),
                encoding=extras.get("encoding", ""), unit=extras.get("unit", ""),
                value_range=extras.get("range", ""), semantics=extras.get("semantics", ""),
                stability=extras.get("stability", ""), backend_support=extras.get("support", "")))
        elif line.startswith("WINDOW_BACKGROUND_PROPERTY "):
            parts = line.split(" ")
            if len(parts) != 9 or window_background is not None:
                raise GeneratedUiError("capability WINDOW_BACKGROUND_PROPERTY line is malformed")
            tokens: dict[str, str] = {}
            expected = {"root_only", "encoding", "default", "omitted", "stability", "support"}
            for part in parts[3:]:
                key, separator, value = part.partition("=")
                if not separator or not value or key not in expected or key in tokens:
                    raise GeneratedUiError("capability WINDOW_BACKGROUND_PROPERTY has an unknown token")
                tokens[key] = value
            if set(tokens) != expected or parts[1] != "windowBackground" or parts[2] != "STRING":
                raise GeneratedUiError("capability WINDOW_BACKGROUND_PROPERTY line is malformed")
            values = tuple(tokens["encoding"].split("|"))
            if (len(values) < 2 or any(not value for value in values) or
                    tokens["default"] not in values or tokens["omitted"] not in values):
                raise GeneratedUiError("capability WINDOW_BACKGROUND_PROPERTY encoding is malformed")
            window_background = GeneratedWindowBackgroundSpec(
                parts[1], parts[2], _token_bool(tokens["root_only"], "WINDOW_BACKGROUND_PROPERTY root_only"),
                values, tokens["default"], tokens["omitted"], tokens["stability"], tokens["support"])
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
        elif line.startswith("FONT_RESOURCE "):
            parts = line.split(" ", 4)
            states = {"ready", "fallback_missing_family", "fallback_missing_file", "fallback_invalid_font",
                      "fallback_capacity", "fallback_backend_failure", "unsupported_fallback", "withdrawn"}
            if len(parts) != 5 or parts[3] not in states or "|" not in parts[4]:
                raise GeneratedUiError("capability FONT_RESOURCE line is malformed")
            resolved_family, name = parts[4].split("|", 1)
            if resolved_family.startswith("u8:"):
                resolved_family = _hex_text(resolved_family[3:], "FONT_RESOURCE family")
            if name.startswith("u8:"):
                name = _hex_text(name[3:], "FONT_RESOURCE name")
            version = _token_int(parts[2], "FONT_RESOURCE version")
            if not parts[1] or version < 1 or not resolved_family or not name:
                raise GeneratedUiError("capability FONT_RESOURCE identity is malformed")
            font_resources.append(GeneratedFontResource(parts[1], version, parts[3], resolved_family, name))
        elif line.startswith("IMAGE_RESOURCE "):
            parts = line.split(" ")
            if len(parts) < 4:
                raise GeneratedUiError("capability IMAGE_RESOURCE line is malformed")
            # The human label is the (possibly multi-word) tail; the protocol's
            # identity fields are the fixed first four tokens.
            label = " ".join(parts[4:]) if len(parts) > 4 else ""
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
    if surface is not None:
        _require_compatible_surface(surface)
    published_fields = {field.field_id for field in fields}
    unknown_choice_fields = sorted({option.field_id for option in choice_options}
                                   - published_fields)
    if unknown_choice_fields:
        raise GeneratedUiError(
            "capability CHOICE names an unpublished field: " + ",".join(unknown_choice_fields))
    return GeneratedCapabilities(max_depth, max_nodes, max_properties, max_string, built,
                                 tuple(composites), tuple(elements), tuple(actions), tuple(fields),
                                 tuple(image_resources), window_background, tuple(font_resources),
                                 surface, tuple(support), tuple(evidence),
                                 choice_format=choice_format,
                                 choice_options=tuple(choice_options),
                                 composition_budget=composition_budget or
                                 GeneratedCompositionBudget(), ui_document_history=ui_document_history)


# --- structure objects -------------------------------------------------------

# The accepted-structure protocol carries an empty property value as an explicit
# non-empty token, because the transport rejects an empty field on any response
# line (`client.parse_response` -> "response field is malformed"). A value that
# already begins with a backslash is escaped so the mapping is reversible. The
# application's encoder (`CjguiGeneratedUiEncoding.encodePropertyValue`) uses the
# SAME convention, so `none`, `""` and an absent property stay distinguishable.
_EMPTY_VALUE_TOKEN = "\\e"


def _encode_property_value(value: str) -> str:
    if value == "":
        return _EMPTY_VALUE_TOKEN
    if value.startswith("\\"):
        return "\\" + value
    return value


def _decode_property_value(token: str) -> str:
    if token == _EMPTY_VALUE_TOKEN:
        return ""
    if token.startswith("\\"):
        return token[1:]
    return token


@dataclass(frozen=True)
class GeneratedProperty:
    name: str
    value: str


@dataclass(frozen=True)
class GeneratedTextStyleRun:
    """Experimental UTF-8 byte range; fonts use application key/version."""
    start: int
    end: int
    font_size: float = 0
    font_weight: int = -1
    font_resource: str | None = None
    font_version: int = 0
    color: str | None = None


def _validate_text_style_run(text: str, run: GeneratedTextStyleRun) -> None:
    import math
    import re
    try:
        body = text.encode("utf-8")
    except UnicodeError as error:
        raise GeneratedUiError("text runs require valid UTF-8") from error
    if len(body) > 65536 or b"\0" in body:
        raise GeneratedUiError("text runs text budget or encoding invalid")
    if (type(run.start) is not int or type(run.end) is not int or
        run.start < 0 or run.end <= run.start or run.end > len(body) or
        (run.start < len(body) and body[run.start] & 0xC0 == 0x80) or
        (run.end < len(body) and body[run.end] & 0xC0 == 0x80)):
        raise GeneratedUiError("text run UTF-8 byte range invalid")
    if (not isinstance(run.font_size, (float, int)) or isinstance(run.font_size, bool) or
        not math.isfinite(run.font_size) or not 0 <= run.font_size <= 144 or
        type(run.font_weight) is not int or not -1 <= run.font_weight <= 1000):
        raise GeneratedUiError("text run font attributes invalid")
    if type(run.font_version) is not int:
        raise GeneratedUiError("text run font version invalid")
    if run.font_resource is None:
        if run.font_version != 0:
            raise GeneratedUiError("text run font reference incomplete")
    elif (not isinstance(run.font_resource, str) or
          not re.fullmatch(r"[A-Za-z0-9_.-]{1,64}", run.font_resource) or
          not 1 <= run.font_version <= 1000000):
        raise GeneratedUiError("text run registered font key/version invalid")
    if run.color is not None and (not isinstance(run.color, str) or
        not re.fullmatch(r"#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?", run.color)):
        raise GeneratedUiError("text run color invalid")


def styled_text_runs_property(text: str, runs: Iterable[GeneratedTextStyleRun]) -> GeneratedProperty:
    """Build textRuns v1; business text is preserved in its original property."""
    items = tuple(runs)
    if len(items) > 64:
        raise GeneratedUiError("text run count exceeds 64")
    encoded = []
    for run in items:
        _validate_text_style_run(text, run)
        encoded.append(f"{run.start}:{run.end}:{run.font_size}:{run.font_weight}:"
                       f"{run.font_resource or 'base'}:{run.font_version}:{run.color or 'inherit'}")
    value = ";".join(encoded)
    if len(value.encode()) > 16384:
        raise GeneratedUiError("text runs wire budget exceeded")
    return GeneratedProperty("textRuns", value)


def parse_text_style_runs(text: str, wire: str) -> tuple[GeneratedTextStyleRun, ...]:
    if len(wire.encode()) > 16384:
        raise GeneratedUiError("text runs wire budget exceeded")
    if not wire:
        return ()
    items = wire.split(";")
    if len(items) > 64:
        raise GeneratedUiError("text run count exceeds 64")
    result = []
    for item in items:
        parts = item.split(":")
        if len(parts) != 7 or any(part != part.strip() for part in parts):
            raise GeneratedUiError("text runs encoding invalid")
        try:
            version = int(parts[5])
            base = parts[4] == "base" and version == 0
            run = GeneratedTextStyleRun(int(parts[0]), int(parts[1]), float(parts[2]), int(parts[3]),
                None if base else parts[4], version, None if parts[6] == "inherit" else parts[6])
        except (ValueError, OverflowError) as error:
            raise GeneratedUiError("text runs attribute encoding invalid") from error
        _validate_text_style_run(text, run)
        result.append(run)
    return tuple(result)


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
class GeneratedCompositionParameter:
    name: str
    value_type: str
    required: bool
    minimum: int
    maximum: int
    max_length: int
    default: str


@dataclass(frozen=True)
class GeneratedCompositionElement:
    key: str
    role: str
    field_id: str = ""
    argument: str = ""
    action: str = ""
    source: str = ""
    preset: str = ""
    label: str = ""


@dataclass(frozen=True)
class GeneratedCompositionTemplateNode:
    depth: int
    key: str
    kind: str
    element_key: str = ""
    compose_name: str = ""
    presentation: str = ""
    text: str = ""
    style_name: str = ""
    gap: int = -1
    padding: int = -1
    fixed_height: int = -1
    grow: int = -1
    axis: str = ""
    first_size: int = 240
    min_first: int = 120
    min_second: int = 120
    children: tuple["GeneratedCompositionTemplateNode", ...] = ()


@dataclass(frozen=True)
class GeneratedRuntimeComposition:
    name: str
    expanded_node_limit: int
    expanded_depth_limit: int
    parameters: tuple[GeneratedCompositionParameter, ...]
    elements: tuple[GeneratedCompositionElement, ...]
    template: GeneratedCompositionTemplateNode


@dataclass(frozen=True)
class GeneratedStructureDocument:
    """One candidate structure: optional definitions plus instance nodes.

    `lossless` is False when the source carried content this client did not
    understand (unknown element/template tokens or declaration lines). Such a
    document is readable for display but must not be re-encoded or treated as
    the complete document; `source_text` preserves the original lines.
    """

    format_version: int
    compositions: tuple[GeneratedRuntimeComposition, ...]
    nodes: tuple[GeneratedNode, ...]
    #: Explicit `COMPOSITION_REMOVE` names carried by ONE candidate document.
    #: An accepted snapshot never carries removals: they are already applied.
    removals: tuple[str, ...] = ()
    source_text: str = field(default="", compare=False)
    lossless: bool = True


@dataclass(frozen=True)
class GeneratedStructure:
    version: int
    candidate_version: int
    scene_state: str
    nodes: tuple[GeneratedNode, ...]
    format_version: int = 1
    compositions: tuple[GeneratedRuntimeComposition, ...] = ()
    source_text: str = field(default="", compare=False)
    lossless: bool = True


_COMPOSITION_PREFIXES = ("COMPOSITION ", "CPARAM ", "CELEMENT ", "CTEMPLATE ",
                         "COMPOSITION_END ", "COMPOSITION_REMOVE ")
_COMPOSITION_MAX_PARAMETERS = 8
_COMPOSITION_MAX_ELEMENTS = 24
_COMPOSITION_MAX_TEMPLATE_NODES = 64
_COMPOSITION_MAX_TEMPLATE_DEPTH = 8
_COMPOSITION_TYPES = frozenset({"STRING", "INTEGER", "BOOLEAN"})
_COMPOSITION_ROLES = frozenset({"field", "action", "preset", "projection"})
_COMPOSITION_TEMPLATE_KINDS = frozenset({
    "vertical", "horizontal", "wrap", "label", "spacer", "split", "element", "children",
    "composition",
})
_COMPOSITION_PRESENTATIONS = frozenset({"text", "select", "radio", "segmented"})
_COMPOSITION_ELEMENT_TOKENS = frozenset({
    "field", "argument", "action", "source", "preset",
})
_COMPOSITION_TEMPLATE_TOKENS = frozenset({
    "element", "presentation", "style", "gap", "padding", "height", "grow",
    "axis", "first", "minfirst", "minsecond", "compose",
})


def _composition_token_value(value: str, what: str) -> str:
    """One positional composition field that the line grammar cannot split.

    Spaces (and other whitespace/control characters) terminate or corrupt the
    token on the wire; the producer has no escape for this position, so the
    client refuses instead of inventing one. `=` is allowed here because these
    fields are positional and a later `name=value` partition keeps it intact.
    """
    if not value:
        raise GeneratedUiError(f"composition_token_empty:{what}")
    for character in value:
        if character.isspace() or ord(character) < 0x20 or ord(character) == 0x7F:
            raise GeneratedUiError(f"composition_token_not_single:{what}")
    return value


def _composition_trailing_value(value: str, what: str) -> str:
    if "\n" in value or "\r" in value or "\0" in value:
        raise GeneratedUiError(f"composition_trailing_value_invalid:{what}")
    return value


def _split_trailing_value(line: str, marker: str) -> tuple[list[str], str]:
    token = " " + marker
    index = line.find(token)
    if index < 0:
        return line.split(" "), ""
    return line[:index].split(" "), line[index + len(token):]


def _composition_token(parts: list[str], prefix: str, default: str = "") -> str:
    for part in parts:
        if part.startswith(prefix):
            return part[len(prefix):]
    return default


def _composition_int(parts: list[str], prefix: str, default: int) -> int:
    raw = _composition_token(parts, prefix, "")
    return default if raw == "" else _token_int(raw, f"composition {prefix[:-1]}")


def _composition_template_count(node: "GeneratedCompositionTemplateNode") -> int:
    return 1 + sum(_composition_template_count(child) for child in node.children)


def _validate_composition_template_shape(root: GeneratedCompositionTemplateNode,
                                        elements: "Sequence[GeneratedCompositionElement]") -> None:
    """The producer's structural rules that this client can check locally."""
    element_roles = {element.key: element.role for element in elements}
    seen: set[str] = set()
    compose_targets: set[str] = set()

    def walk(node: GeneratedCompositionTemplateNode, depth: int) -> None:
        if node.depth != depth:
            raise GeneratedUiError("composition template depth is malformed")
        if node.key in seen:
            raise GeneratedUiError(f"composition_duplicate_template:{node.key}")
        seen.add(node.key)
        if node.kind == "split" and len(node.children) != 2:
            raise GeneratedUiError(f"composition_split_children:{node.key}")
        if node.kind in ("label", "spacer", "element", "composition") and node.children:
            raise GeneratedUiError(f"composition_leaf_children:{node.key}")
        if node.kind == "composition":
            if not node.compose_name:
                raise GeneratedUiError(f"composition_compose_missing:{node.key}")
            compose_targets.add(node.compose_name)
        if node.kind == "element":
            if not node.element_key:
                raise GeneratedUiError(f"composition_element_missing:{node.key}")
            if node.element_key not in element_roles:
                raise GeneratedUiError(
                    f"composition_unknown_element:{node.element_key}")
            if node.presentation == "select" and element_roles[node.element_key] != "field":
                raise GeneratedUiError(
                    f"composition_select_needs_field:{node.element_key}")
        for child in node.children:
            walk(child, depth + 1)

    walk(root, 0)


def _parse_composition_lines(lines: "list[str]", *, allow_removals: bool) -> tuple[
        tuple[GeneratedRuntimeComposition, ...], tuple[str, ...], tuple[str, ...]]:
    compositions: list[GeneratedRuntimeComposition] = []
    removals: list[str] = []
    unknown: list[str] = []
    seen_names: set[str] = set()
    state: dict | None = None

    def finish() -> None:
        nonlocal state
        assert state is not None
        if not state["elements"]:
            raise GeneratedUiError("composition definition has no elements")
        if state["root_index"] is None:
            raise GeneratedUiError("composition definition has no template root")
        specs = state["specs"]
        child_indices = state["child_indices"]

        def build(index: int) -> GeneratedCompositionTemplateNode:
            spec = specs[index]
            return GeneratedCompositionTemplateNode(
                spec["depth"], spec["key"], spec["kind"],
                compose_name=spec["compose"],
                element_key=spec["element"],
                presentation=spec["presentation"], text=spec["text"],
                style_name=spec["style"], gap=spec["gap"],
                padding=spec["padding"], fixed_height=spec["height"],
                grow=spec["grow"], axis=spec["axis"],
                first_size=spec["first"], min_first=spec["minfirst"],
                min_second=spec["minsecond"],
                children=tuple(build(child) for child in child_indices[index]))

        template = build(state["root_index"])
        _validate_composition_template_shape(template, state["elements"])
        header = state["header"]
        name = header[0]
        if name in seen_names:
            raise GeneratedUiError(f"composition_duplicate:{name}")
        seen_names.add(name)
        compositions.append(GeneratedRuntimeComposition(
            name, header[1], header[2], tuple(state["parameters"]),
            tuple(state["elements"]), template))
        state = None

    for line in lines:
        if line == "":
            continue
        parts = line.split(" ")
        kind = parts[0]
        if kind == "COMPOSITION":
            if state is not None and not state["closed"]:
                raise GeneratedUiError(
                    f"composition_end_missing:{state['header'][0]}")
            if state is not None and state["closed"]:
                finish()
            if len(parts) < 4 or not parts[1]:
                raise GeneratedUiError("composition header is malformed")
            _composition_token_value(parts[1], "composition name")
            if len(parts) > 4:
                unknown.append("COMPOSITION " + parts[1] + " " +
                               ",".join(parts[4:]))
            node_limit = _token_int(parts[2], "composition node limit")
            depth_limit = _token_int(parts[3], "composition depth limit")
            if node_limit <= 0 or depth_limit <= 0:
                raise GeneratedUiError("composition limits must be positive")
            state = {"header": (parts[1], node_limit, depth_limit),
                     "parameters": [], "elements": [], "specs": [],
                     "child_indices": [], "last_at_depth": {},
                     "root_index": None, "closed": False}
        elif kind in ("CPARAM", "CELEMENT", "CTEMPLATE"):
            if state is None:
                raise GeneratedUiError(
                    f"composition {kind.lower()} appears before the header")
            if state["closed"]:
                raise GeneratedUiError(
                    f"composition_content_after_end:{state['header'][0]}")
            header = state["header"]
            parameters = state["parameters"]
            elements = state["elements"]
            specs = state["specs"]
            child_indices = state["child_indices"]
            last_at_depth = state["last_at_depth"]
            if kind == "CPARAM":
                if len(parameters) >= _COMPOSITION_MAX_PARAMETERS or len(parts) < 8:
                    raise GeneratedUiError("composition parameter is malformed or over budget")
                _composition_token_value(parts[1], f"parameter name {parts[1]}")
                if len(parts) > 8:
                    extras = parts[8:]
                    if any("=" in token for token in extras):
                        unknown.append("CPARAM " + parts[1] + " " +
                                       ",".join(extras))
                    else:
                        raise GeneratedUiError(
                            f"composition_token_not_single:parameter default {parts[1]}")
                if parts[2] not in _COMPOSITION_TYPES:
                    raise GeneratedUiError(
                        f"composition parameter type {parts[2]!r} is not supported")
                minimum = _token_int(parts[4], "composition parameter minimum")
                maximum = _token_int(parts[5], "composition parameter maximum")
                max_length = _token_int(parts[6], "composition parameter max length")
                if parts[3] not in ("0", "1") or minimum < 0 or maximum < minimum or max_length <= 0:
                    raise GeneratedUiError("composition parameter bounds are malformed")
                _composition_token_value(parts[7], f"parameter default {parts[1]}")
                parameters.append(GeneratedCompositionParameter(
                    parts[1], parts[2], parts[3] == "1", minimum, maximum, max_length,
                    _decode_property_value(parts[7])))
            elif kind == "CELEMENT":
                if len(elements) >= _COMPOSITION_MAX_ELEMENTS:
                    raise GeneratedUiError("composition element budget exceeded")
                head, label = _split_label(line)
                if len(head) < 3 or not head[1] or not head[2]:
                    raise GeneratedUiError("composition element is malformed")
                _composition_token_value(head[1], "element key")
                if head[2] not in _COMPOSITION_ROLES:
                    raise GeneratedUiError(
                        f"composition element role {head[2]!r} is not supported")
                tokens = _key_value_tokens(head[3:], "composition element")
                unknown_fields = set(tokens) - _COMPOSITION_ELEMENT_TOKENS
                if unknown_fields:
                    unknown.append("CELEMENT " + head[1] + " " +
                                   ",".join(sorted(unknown_fields)))
                for name in _COMPOSITION_ELEMENT_TOKENS & set(tokens):
                    _composition_token_value(tokens[name], f"element {name}")
                _composition_trailing_value(label, "element label")
                elements.append(GeneratedCompositionElement(
                    head[1], head[2], tokens.get("field", ""), tokens.get("argument", ""),
                    tokens.get("action", ""), tokens.get("source", ""),
                    tokens.get("preset", ""), label))
            else:
                head, text = _split_trailing_value(line, "text=")
                if len(head) < 4 or not head[2] or not head[3]:
                    raise GeneratedUiError("composition template is malformed")
                _composition_token_value(head[2], "template key")
                if head[3] not in _COMPOSITION_TEMPLATE_KINDS:
                    raise GeneratedUiError(
                        f"composition template kind {head[3]!r} is not supported")
                depth = _token_int(head[1], "composition template depth")
                if depth < 0 or depth > _COMPOSITION_MAX_TEMPLATE_DEPTH:
                    raise GeneratedUiError("composition template depth is out of range")
                if len(specs) >= _COMPOSITION_MAX_TEMPLATE_NODES or \
                        len(specs) >= header[1]:
                    raise GeneratedUiError("composition template node budget exceeded")
                tokens = _key_value_tokens(head[4:], "composition template")
                unknown_fields = set(tokens) - _COMPOSITION_TEMPLATE_TOKENS
                if unknown_fields:
                    unknown.append("CTEMPLATE " + head[2] + " " +
                                   ",".join(sorted(unknown_fields)))
                for name in _COMPOSITION_TEMPLATE_TOKENS & set(tokens):
                    _composition_token_value(tokens[name], f"template {name}")
                if tokens.get("presentation", "") not in ("",) + tuple(_COMPOSITION_PRESENTATIONS):
                    raise GeneratedUiError(
                        f"composition presentation {tokens['presentation']!r} is not supported")
                if tokens.get("axis", "") not in ("", "horizontal", "vertical"):
                    raise GeneratedUiError(
                        f"composition template axis {tokens.get('axis')!r} is not supported")
                _composition_trailing_value(text, "template text")
                index = len(specs)
                if depth == 0:
                    if state["root_index"] is not None:
                        raise GeneratedUiError("composition template has multiple roots")
                    state["root_index"] = index
                else:
                    parent = last_at_depth.get(depth - 1)
                    if parent is None:
                        raise GeneratedUiError("composition template has an orphan node")
                    child_indices[parent].append(index)
                compose = tokens.get("compose", "")
                if head[3] == "composition" and not compose:
                    compose = head[3]
                if head[3] != "composition" and compose:
                    raise GeneratedUiError(
                        f"composition_compose_on_plain_node:{head[2]}")
                if compose and head[3] == "composition" and tokens.get("element", ""):
                    raise GeneratedUiError(
                        f"composition_compose_and_element:{head[2]}")
                specs.append({
                    "depth": depth, "key": head[2], "kind": head[3],
                    "compose": compose,
                    "element": tokens.get("element", ""),
                    "presentation": tokens.get("presentation", ""),
                    "text": text, "style": tokens.get("style", ""),
                    "gap": _composition_int(head[4:], "gap=", -1),
                    "padding": _composition_int(head[4:], "padding=", -1),
                    "height": _composition_int(head[4:], "height=", -1),
                    "grow": _composition_int(head[4:], "grow=", -1),
                    "axis": tokens.get("axis", ""),
                    "first": _composition_int(head[4:], "first=", 240),
                    "minfirst": _composition_int(head[4:], "minfirst=", 120),
                    "minsecond": _composition_int(head[4:], "minsecond=", 120),
                })
                child_indices.append([])
                last_at_depth[depth] = index
                for closed in [item for item in last_at_depth if item > depth]:
                    del last_at_depth[closed]
        elif kind == "COMPOSITION_END":
            if state is None:
                raise GeneratedUiError("composition_end_without_header")
            if state["closed"]:
                raise GeneratedUiError(
                    f"composition_end_duplicate:{state['header'][0]}")
            if len(parts) != 2 or not parts[1]:
                raise GeneratedUiError("composition end is malformed")
            if parts[1] != state["header"][0]:
                raise GeneratedUiError(
                    f"composition_end_name_mismatch:{parts[1]}:{state['header'][0]}")
            finish()
        elif kind == "COMPOSITION_REMOVE":
            if not allow_removals:
                unknown.append(line)
                continue
            if state is not None and not state["closed"]:
                raise GeneratedUiError(
                    f"composition_end_missing:{state['header'][0]}")
            if state is not None:
                finish()
            if len(parts) != 2 or not parts[1]:
                raise GeneratedUiError("composition removal is malformed")
            _composition_token_value(parts[1], "composition removal name")
            if parts[1] in removals:
                raise GeneratedUiError(f"composition_remove_duplicate:{parts[1]}")
            removals.append(parts[1])
        else:
            unknown.append(line)
    if state is not None:
        # Legacy single-definition candidate/snapshot without COMPOSITION_END:
        # the definition ends where its declaration lines stop. Once another
        # section has been completed, an unclosed final section is ambiguous
        # and is refused, matching the producer decoder.
        if not state["closed"] and compositions:
            raise GeneratedUiError(
                f"composition_end_missing:{state['header'][0]}")
        finish()
    return tuple(compositions), tuple(removals), tuple(unknown)


def _parse_node_lines(lines: "list[str]", nodes: list[GeneratedNode]) -> tuple[str, ...]:
    unknown: list[str] = []
    for line in lines:
        if line.startswith("NODE "):
            parts = line.split(" ")
            if len(parts) < 4:
                raise GeneratedUiError("structure NODE line is malformed")
            tokens = _key_value_tokens(parts[4:], "structure NODE") if parts[4:] else {}
            unknown_fields = set(tokens) - {"field", "action"}
            if unknown_fields:
                unknown.append("NODE " + parts[2] + " " +
                               ",".join(sorted(unknown_fields)))
            field_id = tokens.get("field") or None
            action = tokens.get("action") or None
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
            value = _decode_property_value(parts[4])
            if depth != nodes[-1].depth or key != nodes[-1].key:
                raise GeneratedUiError("structure PROPERTY does not follow its NODE")
            node = nodes[-1]
            nodes[-1] = GeneratedNode(node.depth, node.key, node.kind, node.field_id, node.action,
                                      node.properties + (GeneratedProperty(name, value),))
    return tuple(unknown)


def parse_generated_structure(response: SharedOperationResponse) -> GeneratedStructure:
    _result_values(response, "GENERATED_UI_STRUCTURE")
    lines = response.raw.split("\n")
    version = 0
    candidate = 0
    scene = "none"
    format_version = 0
    for line in lines:
        if line.startswith("GENERATED_UI_STRUCTURE "):
            parts = line.split(" ")
            if len(parts) == 2:
                format_version = _token_int(parts[1], "GENERATED_UI_STRUCTURE version")
            break
    nodes: list[GeneratedNode] = []
    composition_lines: list[str] = []
    unknown_lines: list[str] = []
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
        elif line.startswith("GENERATED_UI_STRUCTURE "):
            started = True
        else:
            if not started:
                if line.startswith(_COMPOSITION_PREFIXES) or \
                        line.startswith(("NODE ", "PROPERTY ")):
                    started = True
                else:
                    continue
            if line == "END":
                break
            if line == "":
                continue
            if line.startswith(_COMPOSITION_PREFIXES):
                composition_lines.append(line)
            elif line.startswith(("NODE ", "PROPERTY ")):
                unknown_lines.extend(_parse_node_lines([line], nodes))
            else:
                unknown_lines.append(line)
    if format_version not in (0, 1, 2):
        raise GeneratedUiError(f"structure format version {format_version} is not supported")
    if format_version == 0:
        format_version = 2 if composition_lines else 1
    if format_version == 1 and composition_lines:
        raise GeneratedUiError("structure format 1 cannot carry composition definitions")
    if composition_lines:
        compositions, _removals, unknown_fields = _parse_composition_lines(
            composition_lines, allow_removals=False)
    else:
        compositions, unknown_fields = (), ()
    unknown = tuple(unknown_lines) + unknown_fields
    return GeneratedStructure(version, candidate, scene, tuple(nodes),
                              format_version=format_version,
                              compositions=compositions,
                              source_text=response.raw,
                              lossless=not unknown)


def parse_generated_structure_document(text: str) -> GeneratedStructureDocument:
    """Parse ONE candidate document, including definitions and removals.

    A candidate may declare several complete definition sections plus an
    explicit removal list; the endpoint's published `COMPOSITION_BUDGET` decides
    how many it will accept, and that check runs before submission. The parser
    therefore keeps every section and never silently drops one. `COMPOSITION_END`
    is optional only for a single legacy definition (the old no-END spelling);
    two definitions, or content after an END, require the explicit boundary.
    """
    lines = text.splitlines()
    nonempty = [index for index, line in enumerate(lines) if line != ""]
    if not nonempty or not lines[nonempty[0]].startswith("GENERATED_UI_STRUCTURE "):
        raise GeneratedUiError("candidate document has no GENERATED_UI_STRUCTURE header")
    header = lines[nonempty[0]].split(" ")
    if len(header) != 2:
        raise GeneratedUiError("candidate document header is malformed")
    version = _token_int(header[1], "candidate structure version")
    if version not in (1, 2):
        raise GeneratedUiError(f"structure format version {version} is not supported")
    first_end = next((index for index in nonempty if lines[index] == "END"), None)
    if first_end is None or first_end != nonempty[-1]:
        raise GeneratedUiError("candidate document must end at its first END")
    composition_lines: list[str] = []
    node_lines: list[str] = []
    unknown_lines: list[str] = []
    for line in lines[nonempty[0] + 1:first_end]:
        if line == "":
            continue
        if line.startswith(_COMPOSITION_PREFIXES):
            composition_lines.append(line)
        elif line.startswith(("NODE ", "PROPERTY ")):
            node_lines.append(line)
        else:
            unknown_lines.append(line)
    compositions, removals, composition_unknown = _parse_composition_lines(
        composition_lines, allow_removals=True)
    if version == 1 and (compositions or removals):
        raise GeneratedUiError("structure format 1 cannot carry composition definitions")
    for name in removals:
        if any(composition.name == name for composition in compositions):
            raise GeneratedUiError(
                f"composition_update_and_remove:{name}")
    nodes: list[GeneratedNode] = []
    node_unknown = _parse_node_lines(node_lines, nodes)
    unknown = tuple(unknown_lines) + composition_unknown + node_unknown
    format_version = 2 if (compositions or removals or version == 2) else 1
    return GeneratedStructureDocument(format_version, compositions, tuple(nodes),
                                      removals=removals, source_text=text,
                                      lossless=not unknown)


def _append_encoded_nodes(lines: list[str], nodes: "Sequence[GeneratedNode]") -> None:
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
            if prop.value and (prop.value[0] == " " or prop.value[-1] == " "):
                raise GeneratedUiError("property values cannot begin or end with a space")
            lines.append(f"PROPERTY {node.depth} {node.key} {prop.name} {_encode_property_value(prop.value)}")


def encode_generated_structure(nodes: "Sequence[GeneratedNode]") -> str:
    """Encode typed nodes exactly the way the decoder reads them.

    A value that cannot be represented on one protocol line is rejected here
    instead of being silently truncated: a newline breaks the framing, and a
    leading/trailing space would produce an empty token the transport refuses.
    The EMPTY value is representable through the shared `\\e` token, so the
    "empty clears" contract still round-trips.
    """
    lines = ["GENERATED_UI_STRUCTURE 1"]
    _append_encoded_nodes(lines, nodes)
    lines.append("END")
    return "\n".join(lines)


def _append_composition(lines: list[str], composition: GeneratedRuntimeComposition) -> None:
    _composition_token_value(composition.name, "composition name")
    if not IDENTIFIER.fullmatch(composition.name):
        raise GeneratedUiError("composition name is not a protocol identifier")
    if composition.expanded_node_limit <= 0 or composition.expanded_depth_limit <= 0:
        raise GeneratedUiError("composition limits must be positive")
    if len(composition.parameters) > _COMPOSITION_MAX_PARAMETERS:
        raise GeneratedUiError("composition parameter budget exceeded")
    if not composition.elements:
        raise GeneratedUiError("composition definition has no elements")
    if len(composition.elements) > _COMPOSITION_MAX_ELEMENTS:
        raise GeneratedUiError("composition element budget exceeded")
    lines.append(f"COMPOSITION {composition.name} {composition.expanded_node_limit} "
                 f"{composition.expanded_depth_limit}")
    for parameter in composition.parameters:
        _composition_token_value(parameter.name, f"parameter name {parameter.name}")
        if parameter.value_type not in _COMPOSITION_TYPES:
            raise GeneratedUiError(f"composition parameter type {parameter.value_type!r} is not supported")
        if parameter.minimum < 0 or parameter.maximum < parameter.minimum or parameter.max_length <= 0:
            raise GeneratedUiError("composition parameter bounds are malformed")
        default = _encode_property_value(parameter.default)
        # The default is one positional token.  A space here is not escaped by
        # the official grammar (the producer would silently keep the first
        # part), so refuse before any submission instead of inventing one.
        _composition_token_value(default, f"parameter default {parameter.name}")
        lines.append(f"CPARAM {parameter.name} {parameter.value_type} "
                     f"{1 if parameter.required else 0} {parameter.minimum} "
                     f"{parameter.maximum} {parameter.max_length} {default}")
    for element in composition.elements:
        _composition_token_value(element.key, "element key")
        if element.role not in _COMPOSITION_ROLES:
            raise GeneratedUiError(f"composition element role {element.role!r} is not supported")
        line = f"CELEMENT {element.key} {element.role}"
        for name, value in (("field", element.field_id), ("argument", element.argument),
                            ("action", element.action), ("source", element.source),
                            ("preset", element.preset)):
            if value:
                line += f" {name}={_composition_token_value(value, f'element {name}')}"
        _composition_trailing_value(element.label, "element label")
        if element.label:
            line += " label=" + element.label
        lines.append(line)

    emitted = 0

    def emit(node: GeneratedCompositionTemplateNode, depth: int) -> None:
        nonlocal emitted
        emitted += 1
        if emitted > _COMPOSITION_MAX_TEMPLATE_NODES or emitted > composition.expanded_node_limit:
            raise GeneratedUiError("composition template node budget exceeded")
        if depth != node.depth or depth > _COMPOSITION_MAX_TEMPLATE_DEPTH:
            raise GeneratedUiError("composition template depth is malformed")
        _composition_token_value(node.key, "template key")
        if node.kind not in _COMPOSITION_TEMPLATE_KINDS:
            raise GeneratedUiError(f"composition template kind {node.kind!r} is not supported")
        if node.presentation and node.presentation not in _COMPOSITION_PRESENTATIONS:
            raise GeneratedUiError(f"composition presentation {node.presentation!r} is not supported")
        line = f"CTEMPLATE {depth} {node.key} {node.kind}"
        if node.kind == "composition":
            if not node.compose_name:
                raise GeneratedUiError(f"composition_compose_missing:{node.key}")
            if node.element_key:
                raise GeneratedUiError(f"composition_compose_and_element:{node.key}")
            if node.children:
                raise GeneratedUiError(f"composition_leaf_children:{node.key}")
            line += f" compose={_composition_token_value(node.compose_name, 'template compose')}"
        if node.element_key:
            line += f" element={_composition_token_value(node.element_key, 'template element')}"
        if node.presentation:
            line += f" presentation={node.presentation}"
        if node.style_name:
            line += f" style={_composition_token_value(node.style_name, 'template style')}"
        for name, value in (("gap", node.gap), ("padding", node.padding),
                            ("height", node.fixed_height), ("grow", node.grow)):
            if value >= 0:
                line += f" {name}={value}"
        if node.axis:
            if node.axis not in ("horizontal", "vertical"):
                raise GeneratedUiError(f"composition template axis {node.axis!r} is not supported")
            line += f" axis={node.axis}"
        if node.first_size != 240:
            line += f" first={node.first_size}"
        if node.min_first != 120:
            line += f" minfirst={node.min_first}"
        if node.min_second != 120:
            line += f" minsecond={node.min_second}"
        _composition_trailing_value(node.text, "template text")
        if node.text:
            line += " text=" + node.text
        lines.append(line)
        for child in node.children:
            emit(child, depth + 1)

    emit(composition.template, 0)
    _validate_composition_template_shape(composition.template, composition.elements)


def encode_generated_structure_document(document: GeneratedStructureDocument, *,
                                        allow_multiple: bool = True) -> str:
    """Encode one document with the handed-off v2 input grammar.

    Several definition sections are legal in one candidate; the endpoint's
    published budget and the editor preview enforce the actual count. The
    aggregate budgets below mirror the producer's decoder so a document that
    could not be decoded is refused before it reaches the wire.
    """
    if not document.lossless:
        raise GeneratedUiError(
            "composition_document_not_lossless: the source contains fields or lines "
            "this client did not understand; refuse to emit a pruned document")
    if document.format_version not in (1, 2):
        raise GeneratedUiError(f"structure format version {document.format_version} is not supported")
    if document.format_version == 1 and (document.compositions or document.removals):
        raise GeneratedUiError("structure format 1 cannot carry composition definitions")
    if len(document.compositions) > 1 and not allow_multiple:
        raise GeneratedUiError("one candidate document may declare one composition")
    if len(document.compositions) > 8:
        raise GeneratedUiError("composition definition budget exceeded")
    total_elements = sum(len(composition.elements) for composition in document.compositions)
    if total_elements > 96:
        raise GeneratedUiError("composition element budget exceeded")
    total_nodes = sum(_composition_template_count(composition.template)
                      for composition in document.compositions)
    if total_nodes > 256:
        raise GeneratedUiError("composition template node budget exceeded")
    if len({composition.name for composition in document.compositions}) != \
            len(document.compositions):
        raise GeneratedUiError("composition definition appears more than once")
    if len(set(document.removals)) != len(document.removals):
        raise GeneratedUiError("composition removal appears more than once")
    for name in document.removals:
        _composition_token_value(name, "composition removal name")
        if any(composition.name == name for composition in document.compositions):
            raise GeneratedUiError(f"composition_update_and_remove:{name}")
    lines = [f"GENERATED_UI_STRUCTURE {document.format_version}"]
    for composition in document.compositions:
        _append_composition(lines, composition)
        lines.append(f"COMPOSITION_END {composition.name}")
    for name in document.removals:
        lines.append(f"COMPOSITION_REMOVE {name}")
    _append_encoded_nodes(lines, document.nodes)
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
    draft: str | None
    applied: str | None
    validation_error: str
    #: True/False when the producer could confirm the fact, None when it said the
    #: focus is UNKNOWN. A producer must not answer 0 or 1 for a fact it cannot
    #: confirm, so the absence of knowledge is preserved instead of collapsing
    #: into "not focused".
    focused: bool | None
    selection_start: int | None
    selection_end: int | None
    draft_version: int | None
    #: CURRENT owner availability ("may this be edited right now"), from the same
    #: condition the owner enforces on write. None when the producer said the
    #: condition cannot be evaluated; never inferred from the draft value.
    available: bool | None
    #: The owner's own reason when blocked (None when available/unknown).
    blocked_reason: str | None
    #: Owner/target the decision applies to and the revision it was evaluated at.
    owner_resource_id: int
    state_version: int | None
    #: Validation is independent of edit availability. Legacy ERROR none does
    #: not establish a successful validation; an opt-in owner must confirm it.
    validation_state: str = "unknown"
    validation_version: int | None = None
    field_version: int | None = None


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
    _result_values(response, "GENERATED_UI_FIELDS")
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
        validation = tokens.get("VALIDATION_STATE", ("unknown",))[0]
        if validation not in ("valid", "invalid", "unknown"):
            raise GeneratedUiError(f"FIELD VALIDATION_STATE carries unsupported value {validation!r}")
        message = _hex_text(tokens.get("VALIDATION_MESSAGE_HEX", ("-",))[0],
                            "FIELD VALIDATION_MESSAGE_HEX")
        if validation == "invalid" and not message:
            raise GeneratedUiError("invalid FIELD has no validation message")
        if validation == "valid" and message:
            raise GeneratedUiError("valid FIELD carries a validation error")
        validation_version = _token_int(tokens.get("VALIDATION_VERSION", ("-1",))[0], "FIELD validation version")
        field_version = _token_int(tokens.get("FIELD_VERSION", ("-1",))[0], "FIELD input version")
        values.append(GeneratedFieldValue(
            parts[1], _token_int(parts[2], "FIELD resource"),
            _hex_text(tokens["DRAFT_HEX"][0], "FIELD DRAFT_HEX") if "DRAFT_HEX" in tokens else None,
            _hex_text(tokens["APPLIED_HEX"][0], "FIELD APPLIED_HEX") if "APPLIED_HEX" in tokens else None,
            message if validation != "unknown" else tokens.get("ERROR", ("none",))[0],
            _parse_field_focus(tokens.get("FOCUS")),
            None if selection is None else _token_int(selection[0], "FIELD selection start"),
            None if selection is None else _token_int(selection[1], "FIELD selection end"),
            _token_int(tokens["VERSION"][0], "FIELD draft version") if "VERSION" in tokens else None,
            available,
            blocked_reason,
            _token_int(tokens.get("TARGET", ("-1",))[0], "FIELD TARGET"),
            _token_int(tokens["STATE_VERSION"][0], "FIELD STATE_VERSION") if "STATE_VERSION" in tokens else None,
            validation,
            None if validation_version < 0 else validation_version,
            None if field_version < 0 else field_version))
    return tuple(values)


@dataclass(frozen=True)
class GeneratedActionState:
    name: str
    available: bool | None
    blocked_reason: str | None
    owner_resource_id: int
    state_version: int


@dataclass(frozen=True)
class GeneratedFormState:
    """One GET_GENERATED_UI_FIELDS read, never a join of live owner reads.

    known=False preserves legacy/missing owner feedback. consistent=False
    means a producer could not obtain a coherent read and published no values.
    """
    known: bool
    consistent: bool
    state_version: int | None
    draft_version: int | None
    applied_version: int | None
    can_apply: bool | None
    message: str | None
    owner_resource_id: int
    fields: tuple[GeneratedFieldValue, ...]
    actions: tuple[GeneratedActionState, ...]


def _state_tokens(parts: list[str], start: int, context: str) -> dict[str, str]:
    if (len(parts) - start) % 2:
        raise GeneratedUiError(f"{context} has an incomplete token")
    tokens: dict[str, str] = {}
    for index in range(start, len(parts), 2):
        if parts[index] in tokens:
            raise GeneratedUiError(f"{context} repeats {parts[index]}")
        tokens[parts[index]] = parts[index + 1]
    return tokens


def _state_bool(value: str, context: str) -> bool | None:
    if value == "unknown":
        return None
    if value in ("0", "1"):
        return value == "1"
    raise GeneratedUiError(f"{context} carries unsupported value {value!r}")


def parse_generated_form_state(response: SharedOperationResponse) -> GeneratedFormState:
    fields = parse_generated_fields(response)
    header: dict[str, str] | None = None
    actions: list[GeneratedActionState] = []
    for line in _payload_lines(response):
        parts = line.split(" ")
        if parts[0] == "FORM_STATE":
            if header is not None:
                raise GeneratedUiError("repeated FORM_STATE")
            header = _state_tokens(parts, 1, "FORM_STATE")
        elif parts[0] == "ACTION_STATE":
            if len(parts) < 2 or any(action.name == parts[1] for action in actions):
                raise GeneratedUiError("missing or repeated ACTION_STATE name")
            tokens = _state_tokens(parts, 2, "ACTION_STATE")
            available = _state_bool(tokens.get("AVAILABLE", "unknown"), "ACTION_STATE AVAILABLE")
            reason = _hex_text(tokens.get("REASON_HEX", "-"), "ACTION_STATE REASON_HEX")
            actions.append(GeneratedActionState(
                parts[1], available, reason or None,
                _token_int(tokens.get("TARGET", "-1"), "ACTION_STATE TARGET"),
                _token_int(tokens.get("STATE_VERSION", "-1"), "ACTION_STATE STATE_VERSION")))
    if header is None:
        return GeneratedFormState(False, False, None, None, None, None, None, -1, fields, tuple(actions))
    known = _state_bool(header.get("KNOWN", "unknown"), "FORM_STATE KNOWN")
    consistent = _state_bool(header.get("CONSISTENT", "unknown"), "FORM_STATE CONSISTENT")
    if known is None or consistent is None:
        raise GeneratedUiError("FORM_STATE must confirm KNOWN and CONSISTENT flags")
    versions = [_token_int(header.get(key, "-1"), f"FORM_STATE {key}")
                for key in ("VERSION", "DRAFT_VERSION", "APPLIED_VERSION")]
    owner = _token_int(header.get("TARGET", "-1"), "FORM_STATE TARGET")
    can_apply = _state_bool(header.get("CAN_APPLY", "unknown"), "FORM_STATE CAN_APPLY")
    if not consistent and (known or fields or actions):
        raise GeneratedUiError("inconsistent FORM_STATE must not publish mixed values")
    if known:
        if not consistent or min(versions) < 0 or owner < 0 or can_apply is None:
            raise GeneratedUiError("known FORM_STATE lacks an owner decision/version")
        for field in fields:
            if field.validation_state != "unknown" and (
                    field.validation_version != versions[0] or field.draft_version != versions[1]
                    or field.field_version is None):
                raise GeneratedUiError("FIELD validation does not belong to FORM_STATE version")
            if field.available is not None and (field.state_version != versions[0]
                                                or field.owner_resource_id != owner):
                raise GeneratedUiError("FIELD availability does not belong to FORM_STATE owner/version")
        for action in actions:
            if action.available is not None and (action.state_version != versions[0]
                                                 or action.owner_resource_id != owner):
                raise GeneratedUiError("ACTION_STATE does not belong to FORM_STATE owner/version")
    return GeneratedFormState(known, consistent, *[None if value < 0 else value for value in versions],
                              can_apply, _hex_text(header.get("MESSAGE_HEX", "-"), "FORM_STATE MESSAGE_HEX") or None,
                              owner, fields, tuple(actions))


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
    # Renderer preparation state of this exact accepted image binding. Empty
    # for a non-image instance; the public frame never includes a raster path.
    resource_state: str = ""
    control_role: str = "none"
    control_selected: bool = False
    control_expandable: bool = False
    control_expanded: bool = False
    control_enabled: bool = True
    control_level: int = 0
    control_row_key: str = ""
    control_parent_key: str = ""
    #: Owner target this accepted element is bound to; -1 when the producer did
    #: not publish one. Use it with invoke/read to address the same object.
    owner_resource_id: int = -1


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
    _result_values(response, "GENERATED_UI_INSTANCES")
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
                _token_int(values.get("resource_version", "0"), "instance resource version"),
                values.get("resource_state", "-") if values.get("resource_state", "-") != "-" else "",
                values.get("control_role", "none"),
                _token_bool(values.get("selected", "0"), "instance selected"),
                _token_bool(values.get("expandable", "0"), "instance expandable"),
                _token_bool(values.get("expanded", "0"), "instance expanded"),
                _token_bool(values.get("enabled", "1"), "instance enabled"),
                _token_int(values.get("level", "0"), "instance level"),
                _optional(values.get("row_key", "-")) or "",
                _optional(values.get("parent_key", "-")) or "",
                _token_int(values.get("owner", "-1"), "instance owner")))
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
    _result_values(response, "GENERATED_UI_SUBMIT")
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
    _result_values(response, "GENERATED_UI_CANDIDATE")
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
    effects_text: str = ""
    platform_text: str = ""


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
    # Actual renderer effect status is independent of the accepted generated
    # tree and is refreshed through its own bounded section.
    "EFFECTS": ("EFFECTS",),
    "PLATFORM": ("PLATFORM",),
    "CANDIDATE": (),
}

_GENERATED_SECTION_NAMES = ("FIELDS", "STRUCTURE", "INSTANCES", "STYLES", "EFFECTS", "PLATFORM")


def parse_generated_section(response: SharedOperationResponse, section: str) -> GeneratedSection:
    _result_values(response, "GENERATED_UI_SECTION")
    values = {}
    lines: list[str] = []
    prefix = {"FIELDS": "SNAPSHOT_FIELD", "STRUCTURE": "SNAPSHOT_STRUCTURE",
              "INSTANCES": "SNAPSHOT_INSTANCE", "STYLES": "SNAPSHOT_STYLE",
              "EFFECTS": "SNAPSHOT_EFFECT", "PLATFORM": "SNAPSHOT_PLATFORM"}[section]
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
    _result_values(response, "GENERATED_UI_SNAPSHOT")
    values = {}
    fields_lines: list[str] = []
    structure_lines: list[str] = []
    instances_lines: list[str] = []
    styles_lines: list[str] = []
    effects_lines: list[str] = []
    platform_lines: list[str] = []
    for label, tokens in response.entries:
        if label == "SNAPSHOT_FIELD":
            fields_lines.append(" ".join(tokens))
        elif label == "SNAPSHOT_STRUCTURE":
            structure_lines.append(" ".join(tokens))
        elif label == "SNAPSHOT_INSTANCE":
            instances_lines.append(" ".join(tokens))
        elif label == "SNAPSHOT_STYLE":
            styles_lines.append(" ".join(tokens))
        elif label == "SNAPSHOT_EFFECT":
            effects_lines.append(" ".join(tokens))
        elif label == "SNAPSHOT_PLATFORM":
            platform_lines.append(" ".join(tokens))
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
        "\n".join(styles_lines), "\n".join(effects_lines), "\n".join(platform_lines))


def parse_generated_changes(response: SharedOperationResponse) -> GeneratedChanges:
    _result_values(response, "GENERATED_UI_CHANGES")
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
    _result_values(response, "SNAPSHOT")
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

@dataclass(frozen=True)
class ForwardedTcpSharedOperationClient(SharedOperationClient):
    """Public protocol client over one caller-owned, target-bound local forward.

    `target` and `device_port` record the hdc mapping the caller verified and
    owns. This adapter connects only to the local loopback port; it neither
    creates nor removes a forward. Generated candidate replies still carry the
    endpoint instance and bind generation checked by GeneratedUiSession.
    """

    target: str = ""
    device_port: int = 0
    local_port: int = 0

    def request(self, payload: str, *, timeout_seconds: float | None = None,
                deadline_monotonic: float | None = None) -> SharedOperationResponse:
        request_bytes = frame(payload)
        if deadline_monotonic is None:
            effective_timeout = 2.0 if timeout_seconds is None else timeout_seconds
            if effective_timeout <= 0:
                raise TimeoutError("socket exchange deadline expired")
            deadline_monotonic = time.monotonic() + effective_timeout
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as connection:
            connection.settimeout(_remaining_budget(deadline_monotonic))
            connection.connect(("127.0.0.1", self.local_port))
            fragments = (
                request_bytes[start:start + self.fragment_bytes]
                for start in range(0, len(request_bytes), self.fragment_bytes)
            ) if self.fragment_bytes > 0 else (request_bytes,)
            for fragment in fragments:
                _send_all(connection, fragment, deadline_monotonic)
            return parse_response(read_frame(connection, deadline_monotonic))


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

    @classmethod
    def connect_forwarded_tcp(cls, *, target: str, local_port: int, device_port: int,
                              capability: str, caller: str, fragment_bytes: int = 0) -> "GeneratedUiSession":
        """Use the same typed session over an explicitly identified hdc forward.

        The caller must verify the live `target tcp:local_port -> tcp:device_port`
        mapping and its successful creation receipt before calling this method.
        Only the local loopback endpoint is contacted; target is not a claim
        that this process independently verified hdc ownership.
        """
        if (not target or any(ord(char) <= 32 or ord(char) >= 127 for char in target)):
            raise ValueError("target must be an explicit printable hdc identity")
        if (not isinstance(local_port, int) or isinstance(local_port, bool) or
                not isinstance(device_port, int) or isinstance(device_port, bool) or
                not (1 <= local_port <= 65535) or not (1 <= device_port <= 65535)):
            raise ValueError("forward ports must be in 1..65535")
        if (not capability or any(char in capability for char in "\r\n") or
                not caller or any(char in caller for char in "\r\n")):
            raise ValueError("forward capability and caller must be nonempty single lines")
        if not isinstance(fragment_bytes, int) or isinstance(fragment_bytes, bool) or fragment_bytes < 0:
            raise ValueError("fragment byte count cannot be negative")
        return cls(ForwardedTcpSharedOperationClient(
            {"capability": capability, "caller": caller, "target": target,
             "device_port": device_port, "local_port": local_port},
            fragment_bytes=fragment_bytes, target=target,
            device_port=device_port, local_port=local_port))

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
            self._capabilities = None
            self._capabilities = parse_generated_capabilities(
                self._read("GET_GENERATED_UI_CAPABILITIES", "GENERATED_UI_CAPABILITIES",
                                    deadline_monotonic))
        return self._capabilities

    def structure(self, *, deadline_monotonic: float | None = None) -> GeneratedStructure:
        return parse_generated_structure(
            self._read("GET_GENERATED_UI_STRUCTURE", "GENERATED_UI_STRUCTURE",
                                deadline_monotonic))

    @staticmethod
    def _fields_command(instance_key: str | None, owner_resource_id: int | None) -> str:
        """Same endpoint, compatible target argument. Exactly one target can
        be named; no target keeps the legacy whole-projection read."""
        if instance_key is not None and owner_resource_id is not None:
            raise ValueError("name an instance key OR an owner id, not both")
        if instance_key is not None:
            if (not isinstance(instance_key, str) or not instance_key or len(instance_key) > 128
                    or any(ord(char) <= 32 or ord(char) >= 127 for char in instance_key)):
                raise ValueError("instance key must be a bounded printable token")
            return f"GET_GENERATED_UI_FIELDS INSTANCE {instance_key}"
        if owner_resource_id is not None:
            if (not isinstance(owner_resource_id, int) or isinstance(owner_resource_id, bool)
                    or owner_resource_id < 0):
                raise ValueError("owner resource id cannot be negative")
            return f"GET_GENERATED_UI_FIELDS OWNER {owner_resource_id}"
        return "GET_GENERATED_UI_FIELDS"

    def fields(self, *, instance_key: str | None = None, owner_resource_id: int | None = None,
               deadline_monotonic: float | None = None) -> tuple[GeneratedFieldValue, ...]:
        return parse_generated_fields(
            self._read(self._fields_command(instance_key, owner_resource_id), "GENERATED_UI_FIELDS",
                                deadline_monotonic))

    def form_state(self, *, instance_key: str | None = None, owner_resource_id: int | None = None,
                   deadline_monotonic: float | None = None) -> GeneratedFormState:
        """Read values, validation and action conditions in one owner projection.

        An accepted composite instance can be named by its declared key or by
        its owner resource id; every returned field/action belongs to that
        object's own snapshot. An unknown/stale target is refused by the
        endpoint instead of being answered with another live object.
        """
        return parse_generated_form_state(
            self._read(self._fields_command(instance_key, owner_resource_id), "GENERATED_UI_FIELDS",
                                deadline_monotonic))

    def instances(self, *, deadline_monotonic: float | None = None) -> GeneratedInstances:
        return parse_generated_instances(
            self._read("GET_GENERATED_UI_INSTANCES", "GENERATED_UI_INSTANCES",
                                deadline_monotonic))

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
        if part.cursor != expected_cursor and not part.revision_changed:
            # A moved cursor WITH the provider's revision flag is the normal
            # guarded-section race: observe_once takes a fresh atomic snapshot.
            # Without the flag it is a protocol violation, never stitchable.
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

    def history_state(self, *, deadline_monotonic: float | None = None) -> GeneratedUiHistoryState:
        """Read optional history facts; absent versions and flags stay unknown."""
        return parse_generated_history(self._read("GET_GENERATED_UI_HISTORY", "GENERATED_UI_HISTORY",
                                                  deadline_monotonic))

    def history_action(self, action: str, baseline: GeneratedUiHistoryState, *,
                       deadline_monotonic: float | None = None) -> GeneratedSubmitResult:
        """ONE CAS request; its real candidate ticket still needs settlement."""
        action = {"undo": "UI_DOC_UNDO", "redo": "UI_DOC_REDO"}.get(action, action)
        if action not in ("UI_DOC_UNDO", "UI_DOC_REDO"):
            raise GeneratedUiHistoryRefusal("ui_document_history_unknown_action")
        if not isinstance(baseline, GeneratedUiHistoryState):
            raise GeneratedUiHistoryRefusal("ui_document_history_baseline_invalid")
        if baseline.supported is False:
            raise GeneratedUiHistoryRefusal("ui_document_history_unsupported")
        if baseline.enabled is False:
            raise GeneratedUiHistoryRefusal("ui_document_history_disabled")
        if (type(baseline.format_version) is not int or baseline.format_version != 1 or
                baseline.supported is not True or baseline.enabled is not True or
                type(baseline.accepted_version) is not int or baseline.accepted_version < 0 or
                not isinstance(baseline.accepted_digest, str) or
                not re.fullmatch(r"[0-9a-f]{64}", baseline.accepted_digest) or
                type(baseline.surface_identity) is not int or baseline.surface_identity <= 0 or
                type(baseline.history_epoch) is not int or baseline.history_epoch <= 0 or baseline.endpoint_identity is None):
            raise GeneratedUiHistoryRefusal("ui_document_history_baseline_incomplete")
        endpoint = baseline.endpoint_identity
        if (not isinstance(endpoint.instance, str) or not endpoint.instance or
                any(ch.isspace() or ord(ch) < 32 for ch in endpoint.instance) or
                type(endpoint.bind_generation) is not int or endpoint.bind_generation <= 0):
            raise GeneratedUiHistoryRefusal("ui_document_history_baseline_invalid")
        command = (f"APPLY_GENERATED_UI_HISTORY {action} {baseline.accepted_version} "
                   f"{baseline.accepted_digest} {baseline.surface_identity} {baseline.history_epoch} "
                   f"{endpoint.instance} {endpoint.bind_generation}")
        response = self.client.request(self._query(command), deadline_monotonic=deadline_monotonic)
        facts = _result_values(response, "GENERATED_UI_SUBMIT")
        required = {"APPLIED", "REASON", "VERSION_BEFORE", "VERSION_AFTER", "CANDIDATE_ACCEPTED",
                    "SCENE_ACCEPTED", "CANDIDATE_VERSION", "CANDIDATE_TOKEN"}
        if not required <= facts.keys():
            raise GeneratedUiError("history submit reply is incomplete")
        result = parse_generated_submit(response)
        if result.endpoint_identity != endpoint:
            raise GeneratedUiEndpointError("endpoint_replaced", "history reply belongs to another endpoint")
        return result

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

    def submit_document(self, document: GeneratedStructureDocument,
                        expected_version: int, *,
                        deadline_monotonic: float | None = None) -> GeneratedSubmitResult:
        return self.submit_text(encode_generated_structure_document(document),
                                 expected_version,
                                 deadline_monotonic=deadline_monotonic)

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
            except (TimeoutError, GeneratedUiDeadlineExceeded):
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
    _result_values(response, "SNAPSHOT")
    for label, tokens in response.entries:
        if label == "VERSION" and tokens:
            return _token_int(tokens[0], "domain VERSION")
    return -1
