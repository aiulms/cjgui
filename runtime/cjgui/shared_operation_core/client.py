#!/usr/bin/env python3
"""Generic CJGUI shared-operation v2 client.

It reads only the application-issued private descriptor.  It has no knowledge
of any consumer action or field: action names, parameter kinds, and resource
IDs all come from command-line input and the descriptor/snapshot protocol.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import os
import re
import socket
import sys
import time
from pathlib import Path
from typing import Mapping, Sequence


PROTOCOL = "CJGUI_SHARED_OPERATION/2"
# Matches transport `isSafeIdentifier`: semantic IDs and change streams may
# contain a hyphen after their first ASCII letter/underscore.
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]{0,63}$")
MAX_FRAME_BYTES = 8 * 1024 * 1024
EXIT_CLIENT_ERROR = 2
EXIT_REMOTE_ERROR = 3
EXIT_VERSION_CONFLICT = 4
EXIT_PERMISSION_DENIED = 5
EXIT_CLOSED = 6
EXIT_TIMEOUT = 7


class ConnectionClosedError(ConnectionError):
    """A peer closed an otherwise valid local-socket exchange prematurely."""


@dataclass(frozen=True)
class TextReplacement:
    """One original-version UTF-8 byte range for `REPLACE_RANGES`."""

    start: int
    end: int
    text: str


def encode_text_replacements(replacements: Sequence[TextReplacement]) -> str:
    """Encode a bounded, unambiguous `TEXT_REPLACEMENTS` argument body."""

    if not replacements or len(replacements) > 64:
        fail("TEXT_REPLACEMENTS must contain between one and 64 replacements")
    previous_start = -1
    previous_end = -1
    lines = ["CJGUI_TEXT_REPLACEMENTS/1"]
    for replacement in replacements:
        if (
            not isinstance(replacement.start, int)
            or isinstance(replacement.start, bool)
            or not isinstance(replacement.end, int)
            or isinstance(replacement.end, bool)
            or replacement.start < 0
            or replacement.end < replacement.start
            or not isinstance(replacement.text, str)
        ):
            fail("TEXT_REPLACEMENTS has an invalid range or text")
        if previous_start >= 0 and (
            replacement.start < previous_end
            or (replacement.start == previous_start and replacement.end == previous_end)
        ):
            fail("TEXT_REPLACEMENTS ranges must be ordered and non-overlapping")
        encoded = replacement.text.encode("utf-8")
        if len(encoded) > 64 * 1024:
            fail("TEXT_REPLACEMENTS text is too large")
        lines.append(f"{replacement.start} {replacement.end} {len(encoded)} {encoded.hex().upper() or '-'}")
        previous_start = replacement.start
        previous_end = replacement.end
    payload = "\n".join(lines)
    if len(payload.encode("utf-8")) > 64 * 1024:
        fail("TEXT_REPLACEMENTS encoded payload is too large")
    return payload


def fail(message: str) -> "None":
    raise ValueError(message)


def require_private_file(path: Path) -> None:
    stat = path.stat()
    if not path.is_file():
        fail("descriptor is not a regular file")
    if stat.st_mode & 0o077:
        fail("descriptor is not private (expected mode 0600)")


def decode_text_line(parts: list[str], label: str) -> str:
    if len(parts) != 3 or parts[0] != label:
        fail(f"invalid {label} descriptor line")
    try:
        expected_size = int(parts[1])
        decoded = bytes.fromhex(parts[2]).decode("utf-8")
    except (ValueError, UnicodeError) as exc:
        raise ValueError(f"invalid {label} value") from exc
    if expected_size != len(decoded.encode("utf-8")):
        fail(f"invalid {label} byte count")
    return decoded


def parse_descriptor(path: Path) -> dict[str, object]:
    require_private_file(path)
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) < 5 or lines[0] != f"PROTOCOL {PROTOCOL}" or lines[-1] != "END":
        fail("unsupported or malformed descriptor")
    socket_path = decode_text_line(lines[1].split(" "), "SOCKET_PATH_UTF8_HEX")
    capability = decode_text_line(lines[2].split(" "), "CAPABILITY_UTF8_HEX")
    caller = decode_text_line(lines[3].split(" "), "CALLER_UTF8_HEX")
    if not socket_path or not capability or not caller:
        fail("descriptor has an empty trusted ingress field")
    return {"socket_path": socket_path, "capability": capability, "caller": caller, "lines": lines}


def frame(payload: str) -> bytes:
    encoded = payload.encode("utf-8")
    if not encoded or len(encoded) > MAX_FRAME_BYTES:
        fail("request payload size is invalid")
    return str(len(encoded)).encode("ascii") + b"\n" + encoded


def read_frame(connection: socket.socket) -> str:
    received = bytearray()
    header_end = -1
    expected_size: int | None = None
    while True:
        chunk = connection.recv(4096)
        if not chunk:
            raise ConnectionClosedError("connection closed before a complete response frame")
        received.extend(chunk)
        if len(received) > MAX_FRAME_BYTES + 12:
            fail("response frame is too large")
        if header_end < 0:
            header_end = received.find(b"\n")
            if header_end < 0:
                continue
            try:
                expected_size = int(bytes(received[:header_end]).decode("ascii"))
            except ValueError as exc:
                raise ValueError("response frame header is invalid") from exc
            if expected_size is None or expected_size <= 0 or expected_size > MAX_FRAME_BYTES:
                fail("response frame size is invalid")
        assert expected_size is not None
        frame_end = header_end + 1 + expected_size
        if len(received) < frame_end:
            continue
        if len(received) != frame_end:
            fail("response frame has trailing bytes")
        try:
            return bytes(received[header_end + 1 :]).decode("utf-8")
        except UnicodeDecodeError as exc:
            raise ValueError("response frame is not UTF-8") from exc


def exchange(
    descriptor: dict[str, object],
    payload: str,
    fragment_bytes: int,
    *,
    timeout_seconds: float | None = None,
) -> str:
    socket_path = str(descriptor["socket_path"])
    request = frame(payload)
    effective_timeout = 2.0 if timeout_seconds is None else timeout_seconds
    if effective_timeout <= 0:
        raise TimeoutError("socket exchange deadline expired")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(effective_timeout)
        connection.connect(socket_path)
        if fragment_bytes > 0:
            for start in range(0, len(request), fragment_bytes):
                connection.sendall(request[start : start + fragment_bytes])
        else:
            connection.sendall(request)
        return read_frame(connection)


@dataclass(frozen=True)
class SharedOperationArgument:
    """One dynamically-described action argument.

    The public protocol supports only these three primitive kinds.  Text is
    encoded by this client, so callers never need to quote or hex-encode CJK
    or multiline input themselves.
    """

    name: str
    value_type: str
    value: bool | int | str

    @classmethod
    def boolean(cls, name: str, value: bool) -> "SharedOperationArgument":
        return cls(name, "BOOLEAN", value)

    @classmethod
    def integer(cls, name: str, value: int) -> "SharedOperationArgument":
        return cls(name, "INTEGER", value)

    @classmethod
    def string(cls, name: str, value: str) -> "SharedOperationArgument":
        return cls(name, "STRING", value)

    @classmethod
    def text_replacements(
        cls, name: str, replacements: Sequence[TextReplacement]
    ) -> "SharedOperationArgument":
        return cls(name, "TEXT_REPLACEMENTS", encode_text_replacements(replacements))

    def wire_line(self) -> str:
        if not IDENTIFIER.fullmatch(self.name):
            fail("argument name is not an identifier")
        if self.value_type == "BOOLEAN" and isinstance(self.value, bool):
            return f"ARG {self.name} BOOLEAN {1 if self.value else 0}"
        if self.value_type == "INTEGER" and isinstance(self.value, int) and not isinstance(self.value, bool):
            return f"ARG {self.name} INTEGER {self.value}"
        if self.value_type in ("STRING", "TEXT_REPLACEMENTS") and isinstance(self.value, str):
            data = self.value.encode("utf-8")
            if len(data) > 64 * 1024:
                fail(f"{self.value_type} argument is too large")
            return f"ARG {self.name} {self.value_type} {len(data)} {data.hex().upper() or '-'}"
        fail("argument value does not match BOOLEAN, INTEGER, STRING, or TEXT_REPLACEMENTS")


@dataclass(frozen=True)
class SharedOperationResponse:
    """A lossless, structured response from the shared-operation protocol."""

    protocol: str
    kind: str
    entries: tuple[tuple[str, tuple[str, ...]], ...]
    raw: str

    def values(self, name: str) -> tuple[tuple[str, ...], ...]:
        return tuple(values for label, values in self.entries if label == name)

    def value(self, name: str) -> tuple[str, ...]:
        values = self.values(name)
        if len(values) != 1:
            fail(f"response must contain exactly one {name} line")
        return values[0]

    def integer(self, name: str) -> int:
        values = self.value(name)
        if len(values) != 1:
            fail(f"response {name} is not one integer")
        try:
            return int(values[0])
        except ValueError as exc:
            raise ValueError(f"response {name} is not an integer") from exc

    def boolean(self, name: str) -> bool:
        values = self.value(name)
        if len(values) != 1 or values[0] not in ("0", "1", "true", "false", "TRUE", "FALSE"):
            fail(f"response {name} is not a boolean")
        return values[0].lower() in ("1", "true")

    def text(self, name: str) -> str:
        values = self.value(name)
        if len(values) != 2:
            fail(f"response {name} is not a UTF-8 hex value")
        try:
            expected_size = int(values[0])
            if expected_size == 0 and values[1] == "-":
                return ""
            value = bytes.fromhex(values[1]).decode("utf-8")
        except (ValueError, UnicodeError) as exc:
            raise ValueError(f"response {name} is not valid UTF-8 hex") from exc
        if expected_size != len(value.encode("utf-8")):
            fail(f"response {name} byte count is invalid")
        return value

    def as_json(self) -> dict[str, object]:
        entries: list[dict[str, object]] = []
        for name, values in self.entries:
            item: dict[str, object] = {"name": name, "values": list(values)}
            if name.endswith("_UTF8_HEX") and len(values) == 2:
                item["text"] = self.text(name)
            entries.append(item)
        return {"protocol": self.protocol, "kind": self.kind, "entries": entries}


@dataclass(frozen=True)
class WindowProgressWait:
    """One bounded public observation wait, with no hidden UI refresh."""

    outcome: str  # completed | pending_failure | closed | timeout | remote_error | protocol_error | transport_error
    response: SharedOperationResponse | None
    detail: str = ""


@dataclass(frozen=True)
class SharedOperationObservation:
    """One explicit result of an incremental public observation turn."""

    outcome: str  # initial | no_change | changed | resynced | timeout | remote_error | protocol_error | reconnect_required
    version: int | None
    stream_id: str
    changed_resource_ids: tuple[int, ...] = ()
    detail: str = ""
    wire_bytes: int = 0


def parse_response(payload: str) -> SharedOperationResponse:
    lines = payload.splitlines()
    if len(lines) < 3 or lines[0] != f"PROTOCOL {PROTOCOL}" or lines[-1] != "END":
        fail("unsupported or malformed response")
    kind_line = lines[1].split(" ")
    if len(kind_line) != 2 or kind_line[0] != "KIND" or not IDENTIFIER.fullmatch(kind_line[1]):
        fail("response kind is invalid")
    entries: list[tuple[str, tuple[str, ...]]] = []
    for line in lines[2:-1]:
        parts = line.split(" ")
        if not parts or not IDENTIFIER.fullmatch(parts[0]) or any(part == "" for part in parts):
            fail("response field is malformed")
        entries.append((parts[0], tuple(parts[1:])))
    return SharedOperationResponse(PROTOCOL, kind_line[1], tuple(entries), payload)


def _validate_resource_ids(targets: Sequence[int]) -> None:
    if any(not isinstance(resource_id, int) or isinstance(resource_id, bool) or resource_id < 0 for resource_id in targets):
        fail("resource ids must be non-negative integers")


@dataclass(frozen=True)
class SharedOperationClient:
    """Public, descriptor-gated client for one application-issued endpoint."""

    descriptor: Mapping[str, object]
    fragment_bytes: int = 0

    @classmethod
    def from_descriptor(cls, path: str | Path, *, fragment_bytes: int = 0) -> "SharedOperationClient":
        if fragment_bytes < 0:
            fail("fragment byte count cannot be negative")
        return cls(parse_descriptor(Path(path)), fragment_bytes)

    def request(self, payload: str, *, timeout_seconds: float | None = None) -> SharedOperationResponse:
        return parse_response(
            exchange(
                dict(self.descriptor), payload, self.fragment_bytes,
                timeout_seconds=timeout_seconds,
            )
        )

    def get_context(
        self, targets: Sequence[int] = (), *, timeout_seconds: float | None = None
    ) -> SharedOperationResponse:
        _validate_resource_ids(targets)
        header = [f"PROTOCOL {PROTOCOL}", f"AUTH {self.descriptor['capability']}", f"GET_CONTEXT {len(targets)}"]
        header.extend(f"ID {resource_id}" for resource_id in targets)
        return self.request("\n".join(header), timeout_seconds=timeout_seconds)

    def get_window_progress(
        self, target: str | None = None, *, timeout_seconds: float | None = None
    ) -> SharedOperationResponse:
        """Read compact progress, optionally bound to one exact window target.

        Omitting ``target`` preserves the legacy single-window request.  A
        supplied target is sent on the wire verbatim only after identifier
        validation; callers must enumerate targets first for multi-window
        consumers.
        """
        if target is not None and not IDENTIFIER.fullmatch(target):
            fail("window target is not an identifier")
        command = "GET_WINDOW_PROGRESS" if target is None else f"GET_WINDOW_PROGRESS {target}"
        return self.request(
            "\n".join(
                [
                    f"PROTOCOL {PROTOCOL}",
                    f"AUTH {self.descriptor['capability']}",
                    command,
                ]
            ),
            timeout_seconds=timeout_seconds,
        )

    def get_window_targets(
        self, *, timeout_seconds: float | None = None
    ) -> SharedOperationResponse:
        """Enumerate opaque, currently live window targets granted by the app."""
        return self.request(
            "\n".join(
                [
                    f"PROTOCOL {PROTOCOL}",
                    f"AUTH {self.descriptor['capability']}",
                    "GET_WINDOW_TARGETS",
                ]
            ),
            timeout_seconds=timeout_seconds,
        )

    def get_window_context(
        self, target: str, *, timeout_seconds: float | None = None
    ) -> SharedOperationResponse:
        """Read one exact live window projection; never falls back to a sibling."""
        if not IDENTIFIER.fullmatch(target):
            fail("window target is not an identifier")
        return self.request(
            "\n".join(
                [
                    f"PROTOCOL {PROTOCOL}",
                    f"AUTH {self.descriptor['capability']}",
                    f"GET_WINDOW_CONTEXT {target}",
                ]
            ),
            timeout_seconds=timeout_seconds,
        )

    def get_window_interaction(
        self, target: str | None = None, *, timeout_seconds: float | None = None
    ) -> SharedOperationResponse:
        """Read compact focus/selection/layer facts for one exact target.

        The omitted-target form remains available for the existing
        single-window consumer.  Multi-window callers should pass the target
        returned by :meth:`get_window_targets`; no sibling fallback is
        performed by this client.
        """
        if target is not None and not IDENTIFIER.fullmatch(target):
            fail("window target is not an identifier")
        command = "GET_WINDOW_INTERACTION" if target is None else f"GET_WINDOW_INTERACTION {target}"
        return self.request(
            "\n".join(
                [
                    f"PROTOCOL {PROTOCOL}",
                    f"AUTH {self.descriptor['capability']}",
                    command,
                ]
            ),
            timeout_seconds=timeout_seconds,
        )

    def changes(
        self, since_version: int, targets: Sequence[int] = (), *, stream_id: str = "",
        timeout_seconds: float | None = None,
    ) -> SharedOperationResponse:
        _validate_resource_ids(targets)
        if since_version < 0:
            fail("since version must be non-negative")
        if stream_id and not IDENTIFIER.fullmatch(stream_id):
            fail("stream id is not an identifier")
        header = [f"PROTOCOL {PROTOCOL}", f"AUTH {self.descriptor['capability']}"]
        if stream_id:
            header.append(f"GET_CHANGES {since_version} {stream_id} {len(targets)}")
        else:
            header.append(f"GET_CHANGES {since_version} {len(targets)}")
        header.extend(f"ID {resource_id}" for resource_id in targets)
        return self.request("\n".join(header), timeout_seconds=timeout_seconds)

    def read_range(self, resource_id: int, start: int, end: int, expected_version: int) -> SharedOperationResponse:
        _validate_resource_ids((resource_id,))
        if start < 0 or end < start or expected_version < 0:
            fail("range offsets and expected version must be non-negative with end >= start")
        if end - start > 64 * 1024:
            fail("range exceeds the 64 KiB protocol bound")
        return self.request(
            "\n".join(
                [
                    f"PROTOCOL {PROTOCOL}",
                    f"AUTH {self.descriptor['capability']}",
                    f"READ_RANGE {resource_id} {start} {end} {expected_version}",
                ]
            )
        )

    def invoke(
        self,
        expected_version: int,
        action: str,
        targets: Sequence[int],
        arguments: Sequence[SharedOperationArgument] = (),
    ) -> SharedOperationResponse:
        if expected_version < 0 or not IDENTIFIER.fullmatch(action):
            fail("action and expected version are invalid")
        _validate_resource_ids(targets)
        argument_lines = [argument.wire_line() for argument in arguments]
        header = [
            f"PROTOCOL {PROTOCOL}",
            f"AUTH {self.descriptor['capability']}",
            f"INVOKE {expected_version} {action} {len(targets)} {len(argument_lines)}",
        ]
        header.extend(f"ID {resource_id}" for resource_id in targets)
        header.extend(argument_lines)
        return self.request("\n".join(header))

    def wait_for_window_progress(
        self,
        session_identity: str,
        scene_version: int,
        *,
        target: str | None = None,
        phase: str = "overlay",
        timeout_ms: int = 2_000,
        poll_ms: int = 100,
    ) -> WindowProgressWait:
        """Wait for a stated, observed window milestone without busy polling.

        This performs bounded `GET_WINDOW_PROGRESS` reads and never asks the
        window to rebuild, lay out, submit Metal work, or retry a refresh.
        """
        if not IDENTIFIER.fullmatch(session_identity):
            fail("window session identity is not an identifier")
        if target is not None and not IDENTIFIER.fullmatch(target):
            fail("window target is not an identifier")
        if scene_version <= 0 or timeout_ms < 0 or poll_ms <= 0:
            fail("window wait version, timeout, or poll interval is invalid")
        if phase not in {"accepted", "submitted", "overlay"}:
            fail("window wait phase must be accepted, submitted, or overlay")
        progress_field = {
            "accepted": "WINDOW_ACCEPTED_SCENE_VERSION",
            "submitted": "WINDOW_SUBMITTED_SCENE_VERSION",
            "overlay": "WINDOW_OVERLAY_DRAWN_SCENE_VERSION",
        }[phase]
        deadline = time.monotonic() + timeout_ms / 1_000
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return WindowProgressWait("timeout", None, "window_wait_deadline_expired")
            try:
                response = self.get_window_progress(target, timeout_seconds=remaining)
            except TimeoutError:
                return WindowProgressWait("timeout", None, "window_wait_deadline_expired")
            except OSError as exc:
                return WindowProgressWait("transport_error", None, str(exc))
            except ValueError as exc:
                return WindowProgressWait("protocol_error", None, str(exc))
            if response.kind == "ERROR":
                return WindowProgressWait("remote_error", response, "remote_error_response")
            if response.kind != "WINDOW_PROGRESS":
                return WindowProgressWait("protocol_error", response, "window_wait_expected_progress")
            projection = response.values("WINDOW_PROJECTION")
            if projection == (("NONE",),):
                return WindowProgressWait("closed", response, "window_projection_none")
            if projection != (("ACTIVE",),):
                return WindowProgressWait("protocol_error", response, "window_projection_invalid")
            try:
                observed_identity = response.value("WINDOW_SESSION")
                pending_reason = response.value("WINDOW_REFRESH_PENDING")
                observed_version = response.integer(progress_field)
            except ValueError as exc:
                return WindowProgressWait("protocol_error", response, str(exc))
            if observed_identity != (session_identity,):
                return WindowProgressWait("closed", response, "window_session_replaced")
            if pending_reason != ("none",):
                return WindowProgressWait("pending_failure", response, pending_reason[0])
            if observed_version >= scene_version:
                return WindowProgressWait("completed", response)
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return WindowProgressWait("timeout", response, "window_wait_deadline_expired")
            time.sleep(min(poll_ms / 1_000, remaining))


class SharedOperationObserver:
    """A discardable public projection built from changes plus target rereads.

    The domain stays authoritative.  This object stores only resource IDs and
    the most recent wire snapshot for its explicitly granted target scope; a
    stream replacement or endpoint loss clears that cache before a caller
    supplies a fresh descriptor and resumes observation.
    """

    def __init__(self, operation_client: SharedOperationClient, targets: Sequence[int] = ()) -> None:
        _validate_resource_ids(targets)
        self._client = operation_client
        self._targets = tuple(targets)
        self._version: int | None = None
        self._stream_id = ""
        self._resources: dict[int, SharedOperationResponse] = {}

    def resource_ids(self) -> tuple[int, ...]:
        return tuple(sorted(self._resources))

    def snapshots(self) -> dict[int, SharedOperationResponse]:
        """Return a copy of this turn's coherent, discardable target view.

        The returned responses expose the latest public resource content to a
        consumer.  Mutating the returned mapping cannot change the observer,
        and callers must discard it after any non-successful observation.
        """
        return dict(self._resources)

    def reconnect(self, operation_client: SharedOperationClient) -> None:
        """Adopt an application-issued replacement descriptor after restart."""
        self._client = operation_client
        self._clear_projection()

    def observe_once(self, *, timeout_seconds: float | None = None) -> SharedOperationObservation:
        deadline = self._deadline(timeout_seconds)
        if self._version is None:
            return self._resync("initial", deadline)
        if not self._stream_id:
            # A legacy provider has returned no snapshot identity.  Its
            # context version is useful as a standalone projection, but it
            # cannot safely anchor incremental GET_CHANGES cursors.
            return self._resync("resynced", deadline)
        try:
            changes = self._client.changes(
                self._version, self._targets, stream_id=self._stream_id,
                timeout_seconds=self._remaining(deadline),
            )
        except TimeoutError:
            self._clear_projection()
            return SharedOperationObservation("timeout", self._version, self._stream_id, detail="changes_deadline_expired")
        except (OSError, ConnectionClosedError) as exc:
            self._clear_projection()
            return SharedOperationObservation("reconnect_required", None, "", detail=str(exc))
        except ValueError as exc:
            self._clear_projection()
            return SharedOperationObservation("protocol_error", self._version, self._stream_id, detail=str(exc))
        wire_bytes = len(changes.raw.encode("utf-8"))
        if self._expired(deadline):
            self._clear_projection()
            return SharedOperationObservation("timeout", self._version, self._stream_id, detail="changes_deadline_expired", wire_bytes=wire_bytes)
        if changes.kind == "ERROR":
            self._clear_projection()
            return SharedOperationObservation(
                "remote_error", self._version, self._stream_id,
                detail="changes_error_response", wire_bytes=wire_bytes,
            )
        if changes.kind != "CHANGES":
            self._clear_projection()
            return SharedOperationObservation(
                "protocol_error", self._version, self._stream_id,
                detail="changes_expected_response", wire_bytes=wire_bytes,
            )
        try:
            stream_id = changes.value("STREAM_ID")[0]
            current_version = changes.integer("CURRENT_VERSION")
            requires_resync = changes.boolean("RESYNC_REQUIRED")
            if not IDENTIFIER.fullmatch(stream_id) or current_version < 0:
                fail("changes stream identity or version is invalid")
        except ValueError as exc:
            self._clear_projection()
            return SharedOperationObservation(
                "protocol_error", self._version, self._stream_id, detail=str(exc), wire_bytes=wire_bytes,
            )
        if requires_resync or (self._stream_id and stream_id != self._stream_id):
            # A cursor/stream mismatch invalidates every cached target before
            # any replacement read.  A failed replacement is never published
            # as an old-but-current projection.
            self._clear_projection()
            return self._resync("resynced", deadline, wire_bytes)
        if current_version < self._version:
            self._clear_projection()
            return SharedOperationObservation(
                "protocol_error", None, "",
                detail="changes version moved backwards within one stream", wire_bytes=wire_bytes,
            )
        changed_ids: list[int] = []
        try:
            for values in changes.values("CHANGE"):
                if len(values) != 3:
                    fail("change entry is malformed")
                change_version, resource_id = int(values[0]), int(values[1])
                if change_version <= self._version or change_version > current_version or resource_id < 0:
                    fail("change entry version or resource is invalid")
                if resource_id not in changed_ids:
                    changed_ids.append(resource_id)
        except ValueError as exc:
            self._clear_projection()
            return SharedOperationObservation(
                "protocol_error", self._version, self._stream_id, detail=str(exc), wire_bytes=wire_bytes,
            )
        next_resources = dict(self._resources)
        for resource_id in changed_ids:
            try:
                snapshot = self._client.get_context((resource_id,), timeout_seconds=self._remaining(deadline))
            except TimeoutError:
                self._clear_projection()
                return SharedOperationObservation("timeout", self._version, self._stream_id, detail="target_read_deadline_expired")
            except (OSError, ConnectionClosedError) as exc:
                self._clear_projection()
                return SharedOperationObservation("reconnect_required", None, "", detail=str(exc))
            except ValueError as exc:
                self._clear_projection()
                return SharedOperationObservation(
                    "protocol_error", self._version, self._stream_id, detail=str(exc), wire_bytes=wire_bytes,
                )
            wire_bytes += len(snapshot.raw.encode("utf-8"))
            if self._expired(deadline):
                self._clear_projection()
                return SharedOperationObservation("timeout", self._version, self._stream_id, detail="target_read_deadline_expired", wire_bytes=wire_bytes)
            if snapshot.kind == "SNAPSHOT":
                try:
                    snapshot_stream_id = self._snapshot_stream_id(snapshot)
                    if snapshot.integer("VERSION") != current_version or snapshot_stream_id != stream_id:
                        self._clear_projection()
                        return self._resync("resynced", deadline, wire_bytes)
                except ValueError as exc:
                    self._clear_projection()
                    return SharedOperationObservation(
                        "protocol_error", self._version, self._stream_id, detail=str(exc), wire_bytes=wire_bytes,
                    )
                next_resources[resource_id] = snapshot
                continue
            if snapshot.kind == "ERROR" and snapshot.values("ERROR") == (("unknown_resource",),):
                next_resources.pop(resource_id, None)
                continue
            self._clear_projection()
            return SharedOperationObservation(
                "remote_error", self._version, self._stream_id,
                detail="target_read_error_response", wire_bytes=wire_bytes,
            )
        # Publish every changed target and cursor together.  A timeout,
        # protocol error, authorization error, or later target failure above
        # publishes no mixed intermediate projection and clears the stale
        # cursor before the caller can consume it.
        self._resources = next_resources
        self._version = current_version
        self._stream_id = stream_id
        return SharedOperationObservation(
            "changed" if changed_ids else "no_change", self._version, self._stream_id,
            tuple(changed_ids), wire_bytes=wire_bytes,
        )

    def _resync(
        self, outcome: str, deadline: float | None, wire_bytes: int = 0,
    ) -> SharedOperationObservation:
        try:
            snapshot = self._client.get_context(self._targets, timeout_seconds=self._remaining(deadline))
        except TimeoutError:
            self._clear_projection()
            return SharedOperationObservation("timeout", self._version, self._stream_id, detail="snapshot_deadline_expired")
        except (OSError, ConnectionClosedError) as exc:
            self._clear_projection()
            return SharedOperationObservation("reconnect_required", None, "", detail=str(exc))
        except ValueError as exc:
            self._clear_projection()
            return SharedOperationObservation("protocol_error", self._version, self._stream_id, detail=str(exc))
        wire_bytes += len(snapshot.raw.encode("utf-8"))
        if self._expired(deadline):
            self._clear_projection()
            return SharedOperationObservation("timeout", self._version, self._stream_id, detail="snapshot_deadline_expired", wire_bytes=wire_bytes)
        if snapshot.kind == "ERROR":
            self._clear_projection()
            return SharedOperationObservation(
                "remote_error", self._version, self._stream_id,
                detail="snapshot_error_response", wire_bytes=wire_bytes,
            )
        if snapshot.kind != "SNAPSHOT":
            self._clear_projection()
            return SharedOperationObservation(
                "protocol_error", self._version, self._stream_id,
                detail="snapshot_expected_response", wire_bytes=wire_bytes,
            )
        try:
            version = snapshot.integer("VERSION")
            if version < 0:
                fail("snapshot version is invalid")
            stream_id = self._snapshot_stream_id(snapshot)
            next_resources: dict[int, SharedOperationResponse] = {}
            for values in snapshot.values("RESOURCE"):
                if len(values) != 4:
                    fail("snapshot resource entry is malformed")
                resource_id = int(values[0])
                if resource_id < 0:
                    fail("snapshot resource id is invalid")
                next_resources[resource_id] = snapshot
        except ValueError as exc:
            self._clear_projection()
            return SharedOperationObservation(
                "protocol_error", self._version, self._stream_id, detail=str(exc), wire_bytes=wire_bytes,
            )
        self._resources = next_resources
        self._version = version
        self._stream_id = stream_id
        return SharedOperationObservation(
            outcome, self._version, self._stream_id, tuple(sorted(next_resources)),
            detail="" if stream_id else "snapshot_identity_unavailable", wire_bytes=wire_bytes,
        )

    @staticmethod
    def _snapshot_stream_id(snapshot: SharedOperationResponse) -> str:
        """Return an optional owner-bound snapshot stream identity.

        Older providers did not emit this field.  Callers explicitly degrade
        those snapshots to full resyncs instead of treating them as a proven
        base for a later incremental cursor.
        """
        values = snapshot.values("STREAM_ID")
        if not values:
            return ""
        if len(values) != 1 or len(values[0]) != 1 or not IDENTIFIER.fullmatch(values[0][0]):
            fail("snapshot stream identity is invalid")
        return values[0][0]

    def _clear_projection(self) -> None:
        self._version = None
        self._stream_id = ""
        self._resources = {}

    @staticmethod
    def _deadline(timeout_seconds: float | None) -> float | None:
        if timeout_seconds is None:
            return None
        if timeout_seconds < 0:
            fail("observation timeout cannot be negative")
        return time.monotonic() + timeout_seconds

    @staticmethod
    def _remaining(deadline: float | None) -> float | None:
        if deadline is None:
            return None
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("observation_deadline_expired")
        return remaining

    @staticmethod
    def _expired(deadline: float | None) -> bool:
        return deadline is not None and time.monotonic() >= deadline

def typed_argument(value: str) -> str:
    if "=" not in value or ":" not in value:
        fail("argument must be name=BOOLEAN:0|1, name=INTEGER:number, or name=STRING:text")
    name, encoded = value.split("=", 1)
    value_type, raw = encoded.split(":", 1)
    if not IDENTIFIER.fullmatch(name):
        fail("argument name is not an identifier")
    if value_type == "BOOLEAN":
        if raw in ("1", "true", "TRUE"):
            return SharedOperationArgument.boolean(name, True).wire_line()
        if raw in ("0", "false", "FALSE"):
            return SharedOperationArgument.boolean(name, False).wire_line()
        fail("BOOLEAN argument must be 0, 1, true, or false")
    if value_type == "INTEGER":
        try:
            parsed = int(raw)
        except ValueError as exc:
            raise ValueError("INTEGER argument is invalid") from exc
        return SharedOperationArgument.integer(name, parsed).wire_line()
    if value_type == "STRING":
        return SharedOperationArgument.string(name, raw).wire_line()
    fail("argument type must be BOOLEAN, INTEGER, or STRING")


def body_argument_spec(value: str, source: str) -> tuple[str, str]:
    if "=" not in value:
        fail(f"{source} must be name=path")
    name, location = value.split("=", 1)
    if not IDENTIFIER.fullmatch(name) or not location:
        fail(f"{source} name or path is invalid")
    return name, location


def replacement_file_argument(value: str) -> tuple[str, SharedOperationArgument]:
    """Read one typed batch argument without exposing its wire encoding."""

    name, location = body_argument_spec(value, "--arg-replacements-file")
    path = Path(location)
    if not path.is_file():
        fail("--arg-replacements-file is not a regular file")
    try:
        records = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError("--arg-replacements-file must be valid UTF-8 JSON") from exc
    if not isinstance(records, list):
        fail("--arg-replacements-file JSON must be an array")
    replacements: list[TextReplacement] = []
    for record in records:
        if not isinstance(record, dict) or set(record) != {"start", "end", "text"}:
            fail("each replacement must contain exactly start, end, and text")
        start = record["start"]
        end = record["end"]
        text = record["text"]
        if (
            not isinstance(start, int)
            or isinstance(start, bool)
            or not isinstance(end, int)
            or isinstance(end, bool)
            or not isinstance(text, str)
        ):
            fail("replacement start/end/text types are invalid")
        replacements.append(TextReplacement(start, end, text))
    return name, SharedOperationArgument.text_replacements(name, replacements)


def cli_action_arguments(args: argparse.Namespace) -> list[str]:
    arguments = [typed_argument(item) for item in (args.arg or [])]
    names = {line.split(" ", 2)[1] for line in arguments}
    for value in (args.arg_file or []):
        name, location = body_argument_spec(value, "--arg-file")
        if name in names:
            fail("action argument is repeated")
        path = Path(location)
        if not path.is_file():
            fail("--arg-file is not a regular file")
        arguments.append(SharedOperationArgument.string(name, path.read_text(encoding="utf-8")).wire_line())
        names.add(name)
    for value in (args.arg_replacements_file or []):
        name, argument = replacement_file_argument(value)
        if name in names:
            fail("action argument is repeated")
        arguments.append(argument.wire_line())
        names.add(name)
    stdin_names = args.arg_stdin or []
    if len(stdin_names) > 1:
        fail("only one --arg-stdin is supported")
    if stdin_names:
        name = stdin_names[0]
        if not IDENTIFIER.fullmatch(name):
            fail("--arg-stdin name is not an identifier")
        if name in names:
            fail("action argument is repeated")
        arguments.append(SharedOperationArgument.string(name, sys.stdin.read()).wire_line())
    return arguments


def request_payload(args: argparse.Namespace, descriptor: dict[str, object]) -> str:
    header = [f"PROTOCOL {PROTOCOL}", f"AUTH {descriptor['capability']}"]
    if args.command == "get":
        targets = args.target or []
        header.append(f"GET_CONTEXT {len(targets)}")
        header.extend(f"ID {resource_id}" for resource_id in targets)
        return "\n".join(header)
    if args.command == "generated-capabilities":
        header.append("GET_GENERATED_UI_CAPABILITIES")
        return "\n".join(header)
    if args.command == "generated-structure":
        header.append("GET_GENERATED_UI_STRUCTURE")
        return "\n".join(header)
    if args.command == "generated-fields":
        header.append("GET_GENERATED_UI_FIELDS")
        return "\n".join(header)
    if args.command == "tree-selection":
        header.append("GET_TREE_SELECTION")
        return "\n".join(header)
    if args.command == "tree-select":
        if args.selection_version < 0:
            fail("selection version cannot be negative")
        key = args.key if args.key else "-"
        if key != "-":
            import re as _re
            if not _re.fullmatch(r"[A-Za-z_][A-Za-z0-9_-]{0,63}", key):
                fail("selection key is not a protocol identifier")
        header.append(f"UPDATE_TREE_SELECTION {args.selection_version} {args.selection_command} {key}")
        return "\n".join(header)
    if args.command == "generated-submit":
        if args.structure_version < 0:
            fail("structure version cannot be negative")
        try:
            with open(args.payload_file, "r", encoding="utf-8") as handle:
                candidate = handle.read()
        except OSError as exc:
            fail(f"cannot read candidate payload: {exc}")
        if not candidate:
            fail("candidate payload is empty")
        header.append(f"SUBMIT_GENERATED_UI {args.structure_version}")
        header.append(candidate)
        return "\n".join(header)
    if args.command == "changes":
        targets = args.target or []
        if args.stream_id:
            if not IDENTIFIER.fullmatch(args.stream_id):
                fail("stream id is not an identifier")
            header.append(f"GET_CHANGES {args.since_version} {args.stream_id} {len(targets)}")
        else:
            header.append(f"GET_CHANGES {args.since_version} {len(targets)}")
        header.extend(f"ID {resource_id}" for resource_id in targets)
        return "\n".join(header)
    if args.command == "window-interaction":
        command = "GET_WINDOW_INTERACTION"
        if args.target is not None:
            if not IDENTIFIER.fullmatch(args.target):
                fail("window target is not an identifier")
            command = f"GET_WINDOW_INTERACTION {args.target}"
        header.append(command)
        return "\n".join(header)
    if args.command == "window-progress":
        command = "GET_WINDOW_PROGRESS"
        if args.target is not None:
            if not IDENTIFIER.fullmatch(args.target):
                fail("window target is not an identifier")
            command = f"GET_WINDOW_PROGRESS {args.target}"
        header.append(command)
        return "\n".join(header)
    if args.command == "window-targets":
        header.append("GET_WINDOW_TARGETS")
        return "\n".join(header)
    if args.command == "window-context":
        if not IDENTIFIER.fullmatch(args.target):
            fail("window target is not an identifier")
        header.append(f"GET_WINDOW_CONTEXT {args.target}")
        return "\n".join(header)
    if args.command == "read-range":
        if args.resource_id < 0 or args.start < 0 or args.end < args.start or args.expected_version < 0:
            fail("range resource, offsets, and expected version must be non-negative with end >= start")
        if args.end - args.start > 64 * 1024:
            fail("range exceeds the 64 KiB protocol bound")
        header.append(
            f"READ_RANGE {args.resource_id} {args.start} {args.end} {args.expected_version}"
        )
        return "\n".join(header)
    if args.command == "invoke":
        if not IDENTIFIER.fullmatch(args.action):
            fail("action name is not an identifier")
        targets = args.target or []
        action_arguments = cli_action_arguments(args)
        header.append(f"INVOKE {args.expected_version} {args.action} {len(targets)} {len(action_arguments)}")
        header.extend(f"ID {resource_id}" for resource_id in targets)
        header.extend(action_arguments)
        return "\n".join(header)
    fail("unsupported command")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description="generic CJGUI shared-operation v2 client")
    result.add_argument("descriptor", type=Path)
    result.add_argument("--fragment-bytes", type=int, default=0)
    result.add_argument("--json", action="store_true", help="emit a structured response without consumer-specific parsing")
    commands = result.add_subparsers(dest="command", required=True)
    commands.add_parser("describe", help="print the issued descriptor without interpreting consumer actions")
    get = commands.add_parser("get", help="read all authorized resources or an explicit target set")
    get.add_argument("--target", type=int, action="append")
    changes = commands.add_parser("changes", help="read bounded authorized changes after a context version; reuse STREAM_ID from the prior response")
    changes.add_argument("since_version", type=int)
    changes.add_argument("--stream-id", default="")
    changes.add_argument("--target", type=int, action="append")
    commands.add_parser(
        "window-interaction",
        help="read separately authorized compact window focus, selection, and layer facts",
    ).add_argument("target", nargs="?", help="exact window target; omit for legacy single-window reads")
    window_progress = commands.add_parser(
        "window-progress",
        help="read compact lifecycle/frame progress, optionally for one exact window target",
    )
    window_progress.add_argument("target", nargs="?", help="exact window target; omit for legacy single-window reads")
    commands.add_parser("window-targets", help="enumerate currently live opaque window targets")
    window_context = commands.add_parser("window-context", help="read one exact live window projection")
    window_context.add_argument("target")
    read_range = commands.add_parser("read-range", help="read one authorized UTF-8 byte range at an exact document version")
    read_range.add_argument("resource_id", type=int)
    read_range.add_argument("start", type=int)
    read_range.add_argument("end", type=int)
    read_range.add_argument("expected_version", type=int)
    commands.add_parser("generated-capabilities",
                        help="query the application's runtime-generated-UI capability catalog")
    commands.add_parser("generated-structure",
                        help="read the currently accepted generated structure and its version")
    commands.add_parser("generated-fields",
                        help="read live field projections (draft/applied/validation/focus/selection)")
    commands.add_parser("tree-selection",
                        help="read the shared tree/collection selection snapshot (keys/focus/anchor/versions)")
    tree_select = commands.add_parser("tree-select",
                                      help="update the shared selection through the same handler the window uses")
    tree_select.add_argument("--selection-version", type=int, required=True)
    tree_select.add_argument("--selection-command", dest="selection_command", required=True,
                             choices=["replace", "toggle", "range", "select-all", "clear", "expand", "collapse"])
    tree_select.add_argument("--key", default="-")
    generated_submit = commands.add_parser("generated-submit",
                                           help="submit a generated-UI structure candidate (structure CAS)")
    generated_submit.add_argument("--structure-version", type=int, required=True,
                                  help="structure version the candidate was built against")
    generated_submit.add_argument("--payload-file", required=True,
                                  help="file holding the candidate payload lines")
    invoke = commands.add_parser("invoke", help="invoke a dynamically named action")
    invoke.add_argument("expected_version", type=int)
    invoke.add_argument("action")
    invoke.add_argument("--target", type=int, action="append", required=True)
    invoke.add_argument("--arg", action="append")
    invoke.add_argument("--arg-file", action="append", metavar="NAME=PATH", help="read one UTF-8 STRING argument from a file")
    invoke.add_argument("--arg-replacements-file", action="append", metavar="NAME=PATH", help="read one JSON TEXT_REPLACEMENTS argument from a UTF-8 file")
    invoke.add_argument("--arg-stdin", action="append", metavar="NAME", help="read one UTF-8 STRING argument from standard input")
    wait_window = commands.add_parser("wait-window", help="bounded, read-only wait for one observed window progress milestone")
    wait_window.add_argument("session_identity")
    wait_window.add_argument("scene_version", type=int)
    wait_window.add_argument("--target", help="exact window target for a multi-window progress read")
    wait_window.add_argument("--phase", choices=("accepted", "submitted", "overlay"), default="overlay")
    wait_window.add_argument("--timeout-ms", type=int, default=2_000)
    wait_window.add_argument("--poll-ms", type=int, default=100)
    observe = commands.add_parser("observe", help="run bounded changes plus targeted rereads; resync is explicit")
    observe.add_argument("--target", type=int, action="append")
    observe.add_argument("--turns", type=int, default=2, help="observation turns including initial snapshot")
    observe.add_argument("--interval-ms", type=int, default=100)
    observe.add_argument("--timeout-ms", type=int, default=2_000)
    return result


def response_exit_code(response: SharedOperationResponse) -> int:
    if response.kind == "RESULT":
        if response.boolean("APPLIED"):
            return 0
        if response.boolean("CONFLICT"):
            return EXIT_VERSION_CONFLICT
        reason = response.value("REASON")
        return EXIT_CLOSED if reason == ("document_closed",) else EXIT_REMOTE_ERROR
    if response.kind == "RANGE":
        if response.boolean("CONFLICT"):
            return EXIT_VERSION_CONFLICT
        if response.boolean("AVAILABLE"):
            return 0
        reason = response.value("REASON")
        return EXIT_CLOSED if reason == ("document_closed",) else EXIT_REMOTE_ERROR
    if response.kind == "ERROR":
        reason = response.value("ERROR")
        if reason and reason[0].startswith("unauthorized_"):
            return EXIT_PERMISSION_DENIED
        return EXIT_REMOTE_ERROR
    return 0


def descriptor_json(descriptor: Mapping[str, object]) -> dict[str, object]:
    """A safe description: the capability stays confined to the private file."""

    return {
        "protocol": PROTOCOL,
        "socket_path": descriptor["socket_path"],
        "caller": descriptor["caller"],
        "private_descriptor_required": True,
    }


def main() -> int:
    try:
        args = parser().parse_args()
        if args.fragment_bytes < 0:
            fail("fragment byte count cannot be negative")
        descriptor = parse_descriptor(args.descriptor)
        if args.command == "describe":
            if args.json:
                print(json.dumps(descriptor_json(descriptor), ensure_ascii=False, sort_keys=True))
            else:
                print("\n".join(descriptor["lines"]))
            return 0
        if args.command == "wait-window":
            waiting = SharedOperationClient(descriptor, args.fragment_bytes).wait_for_window_progress(
                args.session_identity,
                args.scene_version,
                target=args.target,
                phase=args.phase,
                timeout_ms=args.timeout_ms,
                poll_ms=args.poll_ms,
            )
            if args.json:
                payload = waiting.response.as_json() if waiting.response is not None else {
                    "protocol": PROTOCOL, "kind": None, "entries": []
                }
                payload["window_wait_outcome"] = waiting.outcome
                if waiting.detail:
                    payload["window_wait_detail"] = waiting.detail
                print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
            else:
                if waiting.response is not None:
                    print(waiting.response.raw)
                print(f"WINDOW_WAIT_OUTCOME {waiting.outcome}")
                if waiting.detail:
                    print(f"WINDOW_WAIT_DETAIL {waiting.detail}")
            if waiting.outcome == "completed":
                return 0
            if waiting.outcome == "closed":
                return EXIT_CLOSED
            if waiting.outcome == "timeout":
                return EXIT_TIMEOUT
            if waiting.outcome == "remote_error" and waiting.response is not None:
                return response_exit_code(waiting.response)
            if waiting.outcome in {"protocol_error", "transport_error"}:
                return EXIT_CLIENT_ERROR
            return EXIT_REMOTE_ERROR
        if args.command == "observe":
            if args.turns <= 0 or args.interval_ms < 0 or args.timeout_ms <= 0:
                fail("observe turns, interval, or timeout is invalid")
            observer = SharedOperationObserver(SharedOperationClient(descriptor, args.fragment_bytes), args.target or ())
            for turn in range(args.turns):
                observed = observer.observe_once(timeout_seconds=args.timeout_ms / 1_000)
                payload = {
                    "outcome": observed.outcome,
                    "version": observed.version,
                    "stream_id": observed.stream_id,
                    "changed_resource_ids": list(observed.changed_resource_ids),
                    "resource_ids": list(observer.resource_ids()),
                    "resources": [
                        {"resource_id": resource_id, "snapshot": snapshot.as_json()}
                        for resource_id, snapshot in sorted(observer.snapshots().items())
                    ],
                    "detail": observed.detail,
                    "wire_bytes": observed.wire_bytes,
                }
                if args.json:
                    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
                else:
                    print(f"OBSERVATION {payload['outcome']} VERSION {payload['version']} STREAM {payload['stream_id']} RESOURCES {payload['resource_ids']}")
                    if observed.detail:
                        print(f"OBSERVATION_DETAIL {observed.detail}")
                if observed.outcome == "reconnect_required":
                    return EXIT_CLOSED
                if observed.outcome == "timeout":
                    return EXIT_TIMEOUT
                if observed.outcome in {"remote_error", "protocol_error"}:
                    return EXIT_REMOTE_ERROR if observed.outcome == "remote_error" else EXIT_CLIENT_ERROR
                if turn + 1 < args.turns and args.interval_ms > 0:
                    time.sleep(args.interval_ms / 1_000)
            return 0
        response = parse_response(exchange(descriptor, request_payload(args, descriptor), args.fragment_bytes))
        if args.json:
            print(json.dumps(response.as_json(), ensure_ascii=False, sort_keys=True))
        else:
            print(response.raw)
        return response_exit_code(response)
    except (OSError, ValueError) as exc:
        print(f"client error: {exc}", file=sys.stderr)
        return EXIT_CLIENT_ERROR


if __name__ == "__main__":
    raise SystemExit(main())
