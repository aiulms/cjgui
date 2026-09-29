#!/usr/bin/env python3
"""Real socket acceptance for the fixed-snapshot lease (E1).

The built second consumer is launched with a control/events file channel and a
short lease TTL; every assertion below is produced by the real app process over
its real local socket. There are no mocks and no reach into framework
internals: requests are 3-line payloads sent through the public client's
generic `request` method, and each numbered group prints one PASS line with the
observed numbers so the log is usable as evidence.
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parent
CORE = ROOT.parents[1] / "shared_operation_core"
CONSUMER = ROOT / "target/release/bin/main"

sys.path.insert(0, str(CORE))
# Only pre-existing public names are used; the parallel typed snapshot helpers
# are deliberately not required by this acceptance.
import client as operation_client  # noqa: E402


PROTOCOL = operation_client.PROTOCOL
PRIMARY = 8101
SECONDARY = 8102
ARCHIVE = 8199
# Fixtures as declared by src/main.cj.
PRIMARY_TEXT = "第一行：在场值班员\n第二行：等待复核🙂"
SECONDARY_TEXT = "这是独立无界面消费者创建的第二份文档。"
POST_EDIT_TEXT = "第一行：现场已交接✅\n第二行：等待复核🙂\n第三行：新增备注🚧"
LEASE_TTL_MS = 1500
PAGE_BYTES = 20


class AcceptanceFailure(Exception):
    """One failed assertion; `main` reports it and exits non-zero."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AcceptanceFailure(message)


def passed(group: str, detail: str) -> None:
    print(f"PASS {group} {detail}", flush=True)


def utf8(text: str) -> bytes:
    return text.encode("utf-8")


class StreamCollector(threading.Thread):
    """Drains a child pipe so the app can never block on its own stdout."""

    def __init__(self, stream) -> None:
        super().__init__(daemon=True)
        self._stream = stream
        self._lines: list[str] = []
        self._lock = threading.Lock()

    def run(self) -> None:
        for line in self._stream:
            with self._lock:
                self._lines.append(line.rstrip("\r\n"))

    def lines(self) -> list[str]:
        with self._lock:
            return list(self._lines)

    def wait_for_prefix(self, prefix: str, timeout: float) -> str:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            for line in self.lines():
                if line.startswith(prefix):
                    return line
            time.sleep(0.02)
        raise AcceptanceFailure(
            f"stdout produced no line starting with {prefix!r} within {timeout}s; observed: {self.lines()!r}"
        )


class ControlChannel:
    """Append-only command log plus its receipt log, as the app consumes it."""

    def __init__(self, control_path: Path, events_path: Path) -> None:
        self.control_path = control_path
        self.events_path = events_path

    def send(self, command: str) -> None:
        self.send_partial(command + "\n")

    def send_partial(self, text: str) -> None:
        """Append bytes verbatim, which is what a writer mid-line looks like."""

        with open(self.control_path, "a", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())

    def events(self) -> list[str]:
        try:
            data = self.events_path.read_text(encoding="utf-8")
        except OSError:
            return []
        if data == "":
            return []
        lines = data.split("\n")
        # The trailing element is either the empty remainder of a complete
        # line or a partially written receipt; neither is an event yet.
        lines.pop()
        return lines

    def wait_event(self, command: str, timeout: float = 5.0) -> str:
        prefix = f"EVENT control {command} "
        deadline = time.monotonic() + timeout
        observed: list[str] = []
        while time.monotonic() < deadline:
            observed = self.events()
            for line in observed:
                if line.startswith(prefix):
                    return line[len(prefix):]
            time.sleep(0.02)
        raise AcceptanceFailure(
            f"control command {command!r} produced no {prefix!r} receipt within {timeout}s; observed: {observed!r}"
        )


class SnapshotProtocol:
    """Thin wrapper over the public client's generic request method."""

    def __init__(self, client, capability: str, endpoint_instance: str, bind_generation: int) -> None:
        self.client = client
        self.capability = capability
        self.endpoint_instance = endpoint_instance
        self.bind_generation = bind_generation

    def _request(self, command: str):
        return self.client.request("\n".join([f"PROTOCOL {PROTOCOL}", f"AUTH {self.capability}", command]))

    def acquire(self, resource: int, *, request_id: str = "-", instance: str = "-",
                version: str = "ANY", ttl_ms: int = 0, endpoint_instance: str | None = None,
                bind_generation: int | None = None):
        endpoint = self.endpoint_instance if endpoint_instance is None else endpoint_instance
        bind = self.bind_generation if bind_generation is None else bind_generation
        command = " ".join([
            "SNAPSHOT_ACQUIRE", endpoint, str(bind), request_id, str(resource),
            instance, str(version), str(ttl_ms),
        ])
        return self._request(command)

    def read(self, token: str, start: int, end: int):
        return self._request(f"SNAPSHOT_READ {token} {start} {end}")

    def release(self, token: str):
        return self._request(f"SNAPSHOT_RELEASE {token}")

    def invoke_replace_range(self, resource: int, start: int, end: int, text: str,
                             expected_version: int):
        arguments = [
            operation_client.SharedOperationArgument.integer("start", start),
            operation_client.SharedOperationArgument.integer("end", end),
            operation_client.SharedOperationArgument.string("text", text),
        ]
        lines = [
            f"PROTOCOL {PROTOCOL}",
            f"AUTH {self.capability}",
            f"INVOKE {expected_version} REPLACE_RANGE 1 {len(arguments)}",
            f"ID {resource}",
        ]
        lines.extend(argument.wire_line() for argument in arguments)
        return self.client.request("\n".join(lines))


def lease_of(response, context: str) -> dict[str, object]:
    require(
        response.kind == "SNAPSHOT_LEASE",
        f"{context}: expected KIND SNAPSHOT_LEASE, observed KIND {response.kind}: {response.raw!r}",
    )
    return {
        "token": response.value("TOKEN")[0],
        "endpoint": response.value("ENDPOINT_INSTANCE")[0],
        "bind": response.integer("ENDPOINT_BIND_GENERATION"),
        "resource": response.integer("RESOURCE"),
        "instance": response.value("RESOURCE_INSTANCE")[0],
        "version": response.integer("VERSION"),
        "byte_length": response.integer("BYTE_LENGTH"),
        "ttl_ms": response.integer("TTL_MS"),
        "remaining_ms": response.integer("REMAINING_MS"),
        "max_read_bytes": response.integer("MAX_READ_BYTES"),
    }


def error_of(response, context: str) -> str:
    require(
        response.kind == "ERROR",
        f"{context}: expected KIND ERROR, observed KIND {response.kind}: {response.raw!r}",
    )
    return response.value("ERROR")[0]


def terminal_read_reason(response, context: str) -> str:
    require(
        response.kind == "RANGE",
        f"{context}: expected KIND RANGE, observed KIND {response.kind}: {response.raw!r}",
    )
    require(
        response.boolean("AVAILABLE") is False,
        f"{context}: expected AVAILABLE false, observed {response.raw!r}",
    )
    return response.value("REASON")[0]


def read_frozen_text(protocol: SnapshotProtocol, token: str, expected_version: int,
                     expected_bytes: int) -> tuple[str, int, int]:
    """Read a frozen lease in pages, aligning any rejected page end.

    Returns (text, page_count, boundary_alignments). A page end the server
    rejects with `invalid_text_boundary` is moved forward one byte at a time and
    re-read, so the concatenation is exact even when the page size lands inside
    a UTF-8 cluster.
    """

    parts: list[str] = []
    offset = 0
    pages = 0
    alignments = 0
    while offset < expected_bytes:
        end = min(offset + PAGE_BYTES, expected_bytes)
        requested_end = end
        while True:
            response = protocol.read(token, offset, end)
            require(
                response.kind == "RANGE",
                f"snapshot page [{offset},{end}): expected KIND RANGE, observed KIND {response.kind}: {response.raw!r}",
            )
            if response.boolean("AVAILABLE"):
                break
            reason = response.value("REASON")[0]
            require(
                reason == "invalid_text_boundary",
                f"snapshot page [{offset},{end}): expected an available page, "
                f"observed AVAILABLE false REASON {reason}",
            )
            require(
                end - requested_end <= 8,
                f"snapshot page [{offset},{end}): no accepted boundary within 8 bytes of the requested end {requested_end}",
            )
            alignments += 1
            end += 1
        version = response.integer("VERSION")
        require(
            version == expected_version,
            f"snapshot page [{offset},{end}): expected VERSION {expected_version}, observed {version}",
        )
        chunk = response.text("CONTENT_UTF8_HEX")
        require(
            len(utf8(chunk)) == end - offset,
            f"snapshot page [{offset},{end}): expected {end - offset} bytes, observed {len(utf8(chunk))}",
        )
        parts.append(chunk)
        offset = end
        pages += 1
    return "".join(parts), pages, alignments


def assert_frozen_read(protocol: SnapshotProtocol, token: str, expected_version: int,
                       expected_text: str, context: str) -> tuple[int, int]:
    text, pages, alignments = read_frozen_text(protocol, token, expected_version, len(utf8(expected_text)))
    require(
        text == expected_text,
        f"{context}: frozen bytes differ from the expected text; "
        f"expected {len(utf8(expected_text))} bytes, observed {len(utf8(text))} bytes",
    )
    return pages, alignments


def acceptance(process: subprocess.Popen, stdout: StreamCollector, stderr: StreamCollector,
               control: ControlChannel) -> None:
    descriptor_prefix = "CJGUI_SHARED_DOCUMENT_READY DESCRIPTOR_PATH "
    ready = stdout.wait_for_prefix(descriptor_prefix, 15.0)
    descriptor = Path(ready[len(descriptor_prefix):])
    protocol_prefix = "CJGUI_SHARED_DOCUMENT_READY PROTOCOL "
    protocol_line = stdout.wait_for_prefix(protocol_prefix, 5.0)
    require(
        protocol_line[len(protocol_prefix):] == PROTOCOL,
        f"ready protocol: expected {PROTOCOL}, observed {protocol_line!r}",
    )
    stdout.wait_for_prefix("CJGUI_SHARED_DOCUMENT_READY ACTION_COUNT ", 5.0)
    require(descriptor.exists(), f"consumer did not issue its descriptor at {descriptor}")

    client = operation_client.SharedOperationClient.from_descriptor(descriptor)
    descriptor_lines = client.descriptor["lines"]
    endpoint_instance = str(client.descriptor["endpoint_instance"])
    bind_generation = client.descriptor["endpoint_bind_generation"]
    require(
        endpoint_instance != "" and isinstance(bind_generation, int),
        f"descriptor must carry the endpoint identity leases echo, observed {client.descriptor!r}",
    )
    initial_capability = str(client.descriptor["capability"])
    protocol = SnapshotProtocol(client, initial_capability,
                                endpoint_instance, int(bind_generation))

    discovered = "\n".join(descriptor_lines)
    for action, parameters in (("SNAPSHOT_ACQUIRE", 2), ("SNAPSHOT_READ", 2), ("SNAPSHOT_RELEASE", 1)):
        require(
            f"ACTION {action} PARAMETERS {parameters} TARGETS 1 1" in discovered,
            f"provider installation: descriptor does not declare ACTION {action} "
            f"PARAMETERS {parameters} TARGETS 1 1; observed {descriptor_lines!r}",
        )
    for action in ("SNAPSHOT_ACQUIRE", "SNAPSHOT_READ", "SNAPSHOT_RELEASE"):
        require(
            f"SCOPE_RESOURCE_ID {action} {ARCHIVE}" not in discovered,
            f"snapshot scope {action} must not include the read-only archive {ARCHIVE}",
        )
        for resource in (PRIMARY, SECONDARY):
            require(
                f"SCOPE_RESOURCE_ID {action} {resource}" in discovered,
                f"snapshot scope {action} must include content document {resource}; "
                f"observed {descriptor_lines!r}",
            )
    passed("1.0 installed", f"provider declared over ids {PRIMARY},{SECONDARY}; archive {ARCHIVE} outside every snapshot scope")

    # ---- 1. acquire ANY on 8101 ------------------------------------------
    expected_primary_bytes = len(utf8(PRIMARY_TEXT))
    lease_1 = lease_of(protocol.acquire(PRIMARY, request_id="req-1"), "group 1 acquire ANY")
    require(lease_1["resource"] == PRIMARY, f"group 1: expected RESOURCE {PRIMARY}, observed {lease_1['resource']}")
    require(lease_1["token"].startswith("s1_"), f"group 1: expected a lease token, observed {lease_1['token']!r}")
    require(lease_1["instance"] != "-", f"group 1: expected a RESOURCE_INSTANCE, observed {lease_1['instance']!r}")
    require(
        lease_1["byte_length"] == expected_primary_bytes,
        f"group 1: expected BYTE_LENGTH {expected_primary_bytes} (real UTF-8 length of the fixture), "
        f"observed {lease_1['byte_length']}",
    )
    require(
        lease_1["ttl_ms"] == LEASE_TTL_MS and lease_1["max_read_bytes"] == 64 * 1024,
        f"group 1: expected TTL_MS {LEASE_TTL_MS} and MAX_READ_BYTES 65536 from --lease-ttl-ms, "
        f"observed TTL_MS {lease_1['ttl_ms']} MAX_READ_BYTES {lease_1['max_read_bytes']}",
    )
    require(
        lease_1["version"] == 0,
        f"group 1: fresh fixture 8101 must be at VERSION 0, observed {lease_1['version']}",
    )
    passed("1.1 acquire", f"resource={PRIMARY} version={lease_1['version']} byte_length={lease_1['byte_length']} "
                          f"ttl_ms={lease_1['ttl_ms']} remaining_ms={lease_1['remaining_ms']} "
                          f"instance={lease_1['instance']}")

    # Protocol observation, deliberately NOT an assertion: the transport
    # documents `-` as the "absent" sentinel only for resourceInstanceId, and
    # passes requestId through literally. Two identical acquires that use the
    # conventional `-` placeholder therefore prove whichever semantics the
    # endpoint actually implements.
    dash_first = protocol.acquire(PRIMARY, request_id="-")
    dash_second = protocol.acquire(PRIMARY, request_id="-")
    if dash_first.kind == "SNAPSHOT_LEASE" and dash_second.kind == "SNAPSHOT_LEASE":
        dash_tokens = [dash_first.value("TOKEN")[0], dash_second.value("TOKEN")[0]]
        if dash_tokens[0] == dash_tokens[1]:
            print("NOTE requestId '-' is a literal idempotency key, not a wildcard: two identical acquires "
                  f"returned one token {dash_tokens[0]}", flush=True)
        else:
            print("NOTE requestId '-' was treated as absent: two identical acquires minted "
                  f"{dash_tokens[0]} and {dash_tokens[1]}", flush=True)
        for dash_token in dash_tokens:
            protocol.release(dash_token)
    else:
        print(f"NOTE requestId '-' answered KIND {dash_first.kind} then KIND {dash_second.kind}: "
              f"{dash_second.raw!r}", flush=True)

    # ---- 2. paged frozen read of a moving document -----------------------
    frozen_started = time.monotonic()
    pages, alignments = assert_frozen_read(protocol, str(lease_1["token"]), 0, PRIMARY_TEXT, "group 2 initial lease")
    require(pages >= 3, f"group 2: expected at least 3 pages, observed {pages}")
    edit = protocol.invoke_replace_range(PRIMARY, 0, expected_primary_bytes, POST_EDIT_TEXT, 0)
    require(
        edit.kind == "RESULT" and edit.boolean("APPLIED") is True,
        f"group 2: expected the external REPLACE_RANGE to apply, observed {edit.raw!r}",
    )
    after_version = edit.integer("VERSION_AFTER")
    require(
        after_version == 1,
        f"group 2: expected VERSION_AFTER 1 after one external edit, observed {after_version}",
    )
    old_pages, old_alignments = assert_frozen_read(
        protocol, str(lease_1["token"]), 0, PRIMARY_TEXT, "group 2 same lease after the edit")
    expected_post_bytes = len(utf8(POST_EDIT_TEXT))
    lease_2 = lease_of(protocol.acquire(PRIMARY, request_id="req-2"), "group 2 new acquire after the edit")
    require(
        lease_2["version"] == after_version,
        f"group 2: a new acquire must see VERSION {after_version}, observed {lease_2['version']}",
    )
    require(
        lease_2["token"] != lease_1["token"],
        f"group 2: a new acquire must mint a new token, observed {lease_2['token']!r}",
    )
    require(
        lease_2["byte_length"] == expected_post_bytes,
        f"group 2: expected post-edit BYTE_LENGTH {expected_post_bytes}, observed {lease_2['byte_length']}",
    )
    require(
        lease_2["instance"] == lease_1["instance"],
        f"group 2: an edit must not replace the resource instance, "
        f"observed {lease_2['instance']!r} vs {lease_1['instance']!r}",
    )
    new_pages, new_alignments = assert_frozen_read(
        protocol, str(lease_2["token"]), after_version, POST_EDIT_TEXT, "group 2 new lease")
    passed("2.1 frozen reads",
           f"old_lease pages={pages} boundary_alignments={alignments} bytes={expected_primary_bytes} exact=true; "
           f"old_lease_after_edit pages={old_pages} boundary_alignments={old_alignments} "
           f"bytes={expected_primary_bytes} version=0 exact=true")
    passed("2.2 moving document",
           f"edit VERSION_AFTER={after_version} new_lease pages={new_pages} boundary_alignments={new_alignments} "
           f"bytes={expected_post_bytes} version={lease_2['version']} exact=true; old_token stayed frozen; "
           f"old_lease_lifetime_ms={int((time.monotonic() - frozen_started) * 1000)} of ttl_ms={LEASE_TTL_MS}")

    # ---- 3. idempotent acquire -------------------------------------------
    request_id = "req-idem-1"
    idem_first = lease_of(protocol.acquire(PRIMARY, request_id=request_id), "group 3 first acquire")
    idem_replay = lease_of(protocol.acquire(PRIMARY, request_id=request_id), "group 3 replay")
    require(
        idem_replay["token"] == idem_first["token"],
        f"group 3: a replay must return the same token (proof the provider was not asked again); "
        f"expected {idem_first['token']!r}, observed {idem_replay['token']!r}",
    )
    require(
        idem_replay["version"] == idem_first["version"],
        f"group 3: replay version: expected {idem_first['version']}, observed {idem_replay['version']}",
    )
    require(
        idem_replay["remaining_ms"] <= idem_first["remaining_ms"] and idem_replay["remaining_ms"] > 0,
        f"group 3: replay REMAINING_MS must not reset upward; "
        f"observed first={idem_first['remaining_ms']} replay={idem_replay['remaining_ms']}",
    )
    require(
        idem_replay["ttl_ms"] == idem_first["ttl_ms"],
        f"group 3: replay TTL_MS: expected {idem_first['ttl_ms']}, observed {idem_replay['ttl_ms']}",
    )
    conflict = protocol.acquire(PRIMARY, request_id=request_id, ttl_ms=LEASE_TTL_MS - 300)
    conflict_reason = error_of(conflict, "group 3 same requestId with different arguments")
    require(
        conflict_reason == "snapshot_request_conflict",
        f"group 3: expected ERROR snapshot_request_conflict, observed ERROR {conflict_reason}",
    )
    passed("3. idempotent acquire",
           f"request_id={request_id} token_stable=true version={idem_replay['version']} "
           f"remaining_ms {idem_first['remaining_ms']}->{idem_replay['remaining_ms']} (no second provider acquire); "
           f"same request_id with ttl_ms={LEASE_TTL_MS - 300} -> snapshot_request_conflict")

    # ---- 4. instance pinning ---------------------------------------------
    pinned = lease_of(protocol.acquire(PRIMARY, request_id="req-4-pin", instance=str(lease_1["instance"])), "group 4 pinned acquire")
    require(
        pinned["instance"] == lease_1["instance"],
        f"group 4: pinned acquire must keep the instance; "
        f"expected {lease_1['instance']!r}, observed {pinned['instance']!r}",
    )
    bogus = "td00000000000000000000000000000000_%d" % PRIMARY
    bogus_reason = error_of(protocol.acquire(PRIMARY, request_id="req-4-bogus", instance=bogus), "group 4 bogus instance")
    require(
        bogus_reason == "snapshot_instance_mismatch",
        f"group 4: expected ERROR snapshot_instance_mismatch for a bogus instance, observed ERROR {bogus_reason}",
    )
    version_reason = error_of(protocol.acquire(PRIMARY, request_id="req-4-version", version=str(after_version + 98)),
                              "group 4 wrong expectedVersion")
    require(
        version_reason == "version_conflict",
        f"group 4: expected ERROR version_conflict, observed ERROR {version_reason}",
    )
    passed("4. instance pinning",
           f"pinned instance={pinned['instance']} granted version={pinned['version']}; "
           f"bogus instance -> snapshot_instance_mismatch; expectedVersion {after_version + 98} -> version_conflict")

    # ---- 5. release and terminal reads -----------------------------------
    release_lease = lease_of(protocol.acquire(PRIMARY, request_id="req-5-release"), "group 5 acquire")
    release_token = str(release_lease["token"])
    first_release = protocol.release(release_token)
    require(
        first_release.kind == "SNAPSHOT_RELEASE",
        f"group 5: expected KIND SNAPSHOT_RELEASE, observed KIND {first_release.kind}: {first_release.raw!r}",
    )
    release_reason = first_release.value("REASON")[0]
    require(
        release_reason == "snapshot_released",
        f"group 5: expected REASON snapshot_released, observed {release_reason}",
    )
    terminal_reason = terminal_read_reason(protocol.read(release_token, 0, 1), "group 5 read after release")
    require(
        terminal_reason == "snapshot_released",
        f"group 5: expected REASON snapshot_released after release, observed {terminal_reason}",
    )
    second_release = protocol.release(release_token)
    require(
        second_release.kind == "SNAPSHOT_RELEASE",
        f"group 5: a second release must not be an error, observed KIND {second_release.kind}: {second_release.raw!r}",
    )
    second_reason = second_release.value("REASON")[0]
    require(
        second_reason == release_reason,
        f"group 5: second release reason: expected {release_reason}, observed {second_reason}",
    )
    unknown_token = "s1_not_issued_00000000"
    unknown_reason = error_of(protocol.release(unknown_token), "group 5 never-issued token")
    require(
        unknown_reason == "snapshot_unknown",
        f"group 5: expected ERROR snapshot_unknown for a never-issued token, observed ERROR {unknown_reason}",
    )
    passed("5. release",
           f"kind=SNAPSHOT_RELEASE reason={release_reason} release_idempotent_reason={second_reason}; "
           f"read_after_release={terminal_reason}; never-issued token -> snapshot_unknown")

    # ---- 6. no-traffic expiry --------------------------------------------
    expiring = lease_of(protocol.acquire(PRIMARY, request_id="req-6-expiry", ttl_ms=LEASE_TTL_MS), "group 6 acquire")
    require(
        expiring["ttl_ms"] == LEASE_TTL_MS,
        f"group 6: expected TTL_MS {LEASE_TTL_MS}, observed {expiring['ttl_ms']}",
    )
    started = time.monotonic()
    time.sleep(LEASE_TTL_MS / 1000.0 + 0.35)  # idle window: no request is sent
    expired_reason = terminal_read_reason(protocol.read(str(expiring["token"]), 0, 1), "group 6 read after idle wait")
    elapsed_ms = int((time.monotonic() - started) * 1000)
    require(
        expired_reason == "snapshot_expired",
        f"group 6: expected REASON snapshot_expired after a {LEASE_TTL_MS} ms idle wait, "
        f"observed {expired_reason}",
    )
    passed("6. no-traffic expiry",
           f"ttl_ms={LEASE_TTL_MS} idle_wait_ms={elapsed_ms} first_traffic_after_wait=READ -> {expired_reason}")

    # ---- 7. foreign endpoint instance ------------------------------------
    foreign = "ep0000000000000000"
    foreign_reason = error_of(protocol.acquire(PRIMARY, request_id="req-7-foreign", endpoint_instance=foreign),
                              "group 7 foreign endpoint instance")
    require(
        foreign_reason == "snapshot_endpoint_changed",
        f"group 7: expected ERROR snapshot_endpoint_changed, observed ERROR {foreign_reason}",
    )
    still_alive = lease_of(protocol.acquire(PRIMARY, request_id="req-7-live"), "group 7 liveness re-acquire")
    passed("7. foreign endpoint",
           f"endpoint_instance={foreign} -> snapshot_endpoint_changed; endpoint still grants "
           f"token={still_alive['token']} (any leak would surface as live handles at exit)")

    # ---- 8. lifecycle through the control file ---------------------------
    close_lease = lease_of(protocol.acquire(SECONDARY, request_id="req-8-close"), "group 8 acquire 8102")
    require(
        close_lease["byte_length"] == len(utf8(SECONDARY_TEXT)),
        f"group 8: expected 8102 BYTE_LENGTH {len(utf8(SECONDARY_TEXT))}, observed {close_lease['byte_length']}",
    )
    control.send("close 999999")
    refused_close = control.wait_event("close 999999")
    require(
        refused_close == "unknown_document",
        f"group 8: a close of an unknown document must report the API refusal verbatim; "
        f"expected unknown_document, observed {refused_close!r}",
    )
    # A partial line must not be parsed: half a command is written, the app gets
    # a full poll cycle to ignore it, then the line is completed.
    partial_text = f"close {SECONDARY}"[:-1]
    completion_text = f"close {SECONDARY}"[-1]
    receipts_before = len(control.events())
    control.send_partial(partial_text)
    time.sleep(0.25)
    require(
        len(control.events()) == receipts_before,
        f"group 8: a partial control line produced a receipt: {control.events()!r}",
    )
    control.send_partial(completion_text + "\n")
    close_receipt = control.wait_event(f"close {SECONDARY}")
    require(
        close_receipt == "ok",
        f"group 8: expected ok for close {SECONDARY}, observed {close_receipt!r}",
    )
    passed("8.0 partial line", f"partial receipt count stayed {receipts_before} while only {partial_text!r} was written")
    closed_reason = terminal_read_reason(protocol.read(str(close_lease["token"]), 0, 1),
                                         "group 8 held lease after close")
    require(
        closed_reason == "snapshot_resource_closed",
        f"group 8: expected REASON snapshot_resource_closed for the held lease, observed {closed_reason}",
    )
    reopen_reason = error_of(protocol.acquire(SECONDARY, request_id="req-8-refuse"), "group 8 acquire on a closed document")
    require(
        reopen_reason == "snapshot_resource_closed",
        f"group 8: expected ERROR snapshot_resource_closed on a closed document, observed ERROR {reopen_reason}",
    )
    unaffected = lease_of(protocol.acquire(PRIMARY, request_id="req-8-unaffected"), "group 8 acquire 8101 while 8102 is closed")
    require(
        unaffected["version"] == after_version,
        f"group 8: expected 8101 to stay at VERSION {after_version}, observed {unaffected['version']}",
    )
    control.send("revoke")
    revoke_receipt = control.wait_event("revoke")
    require(revoke_receipt == "ok", f"group 8: expected ok for revoke, observed {revoke_receipt!r}")
    # The new contract, not a looser one: a revoked authorization is refused at
    # the dispatch gate for EVERY verb, so the held lease's read is an ERROR
    # (unnamed-token reads never reach the table at all), not a terminal RANGE.
    revoked_reason = error_of(protocol.read(str(unaffected["token"]), 0, 1),
                              "group 8 held lease after revoke")
    require(
        revoked_reason == "authorization_revoked",
        f"group 8: expected ERROR authorization_revoked, observed ERROR {revoked_reason}",
    )
    passed("8.1 document close",
           f"close {SECONDARY} -> ok; held lease -> snapshot_resource_closed; new acquire -> "
           f"snapshot_resource_closed; 8101 still grants version={unaffected['version']}")
    passed("8.2 authorization revoke",
           f"revoke -> ok; held lease -> ERROR authorization_revoked; unknown close receipt={refused_close}")

    # ---- 8b. multi-round reconnect through the host lifecycle ------------
    # A revoke is DEAD, not paused: the old credential must not acquire anything
    # again on this connection. The only way back is the host's own regrant
    # lifecycle, which stops the endpoint, installs a NEW credential, reinstalls
    # the provider and republishes the descriptor.
    revoked_error = error_of(protocol.acquire(PRIMARY, request_id="req-8b-post-revoke"),
                             "group 8b acquire with the revoked credential")
    require(
        revoked_error == "authorization_revoked",
        f"group 8b: the revoked credential must be refused by name, observed ERROR {revoked_error}",
    )
    control.send("regrant cjgui-shared-document-second-consumer-20260912 旧的A")
    recycled = control.wait_event("regrant cjgui-shared-document-second-consumer-20260912 旧的A")
    require(
        recycled == "authorization_credential_recycled",
        f"group 8b: re-granting the revoked credential must be refused by name, observed {recycled!r}",
    )
    refused_line = stdout.wait_for_prefix("CJGUI_SHARED_DOCUMENT_REGRANT REFUSED ", 5.0)
    require(
        refused_line.endswith("authorization_credential_recycled"),
        f"group 8b: expected the host to report the named refusal, observed {refused_line!r}",
    )
    # A regrant cannot be applied while the endpoint is bound, so the host stops
    # it first; a refused regrant therefore leaves NO endpoint rather than a
    # half-authorized one. The observable end state is the old descriptor being
    # withdrawn and the old socket no longer serving anything -- never a live
    # endpoint that still answers the revoked credential.
    require(
        not descriptor.exists(),
        f"group 8b: the old descriptor {descriptor} must be withdrawn with its endpoint",
    )
    old_endpoint_stopped = False
    try:
        protocol.read(str(unaffected["token"]), 0, 1)
    except OSError:
        old_endpoint_stopped = True
    require(
        old_endpoint_stopped,
        "group 8b: the stopped endpoint must not serve the revoked credential any more",
    )
    passed("8.3 revoked credential stays dead",
           f"acquire -> ERROR {revoked_error}; regrant with the revoked capability -> {recycled}; "
           f"descriptor withdrawn; old socket stopped")

    # The replacement credential goes through the same host lifecycle and
    # republishes a descriptor; a holder reconnects from THAT publication.
    new_capability = "cjgui-shared-document-second-consumer-20260929-b"
    control.send(f"regrant {new_capability} 新的B")
    grant_receipt = control.wait_event(f"regrant {new_capability} 新的B")
    require(
        grant_receipt == "ok",
        f"group 8c: expected ok for the replacement credential, observed {grant_receipt!r}",
    )
    republished = stdout.wait_for_prefix("CJGUI_SHARED_DOCUMENT_REGRANT DESCRIPTOR_PATH ", 10.0)
    new_descriptor = Path(republished[len("CJGUI_SHARED_DOCUMENT_REGRANT DESCRIPTOR_PATH "):])
    require(
        new_descriptor.exists() and new_descriptor != descriptor,
        f"group 8c: expected a NEW descriptor, observed {new_descriptor} (old {descriptor})",
    )
    require(
        not descriptor.exists(),
        f"group 8c: the old descriptor {descriptor} must be gone after the endpoint stopped",
    )
    new_client = operation_client.SharedOperationClient.from_descriptor(new_descriptor)
    new_protocol = SnapshotProtocol(new_client, str(new_client.descriptor["capability"]),
                                    str(new_client.descriptor["endpoint_instance"]),
                                    int(new_client.descriptor["endpoint_bind_generation"]))
    require(
        new_protocol.capability == new_capability,
        f"group 8c: the republished descriptor must carry the replacement credential, "
        f"observed {new_protocol.capability!r}",
    )
    # The OLD credential is refused on the republished endpoint, and the OLD
    # token never revives: the provider's lease table was replaced, so it is
    # unknown there rather than silently readable. The stale credential is sent
    # over the NEW socket, which is the only way to prove the republished
    # endpoint does not accept it.
    stale_protocol = SnapshotProtocol(new_client, initial_capability,
                                      str(new_client.descriptor["endpoint_instance"]),
                                      int(new_client.descriptor["endpoint_bind_generation"]))
    old_auth_error = error_of(stale_protocol._request("GET_CONTEXT -"),
                              "group 8c GET_CONTEXT with the revoked credential")
    require(
        old_auth_error == "unauthorized_caller",
        f"group 8c: the revoked credential must not match the new authorization, observed ERROR {old_auth_error}",
    )
    stale = terminal_read_reason(new_protocol.read(str(unaffected["token"]), 0, 1),
                                 "group 8c read of the pre-regrant token")
    require(
        stale == "snapshot_unknown",
        f"group 8c: a token of the previous grant must not become readable again, observed REASON {stale}",
    )
    # The replacement credential reads and writes the live document over the
    # real socket, and the frozen-version promise is re-established by the new
    # table: a fresh acquire pins the version the document is at NOW.
    appended = "！"
    written = new_protocol.invoke_replace_range(PRIMARY, len(utf8(POST_EDIT_TEXT)),
                                                len(utf8(POST_EDIT_TEXT)), appended, after_version)
    require(
        written.kind == "RESULT" and written.boolean("APPLIED") is True,
        f"group 8c: the replacement credential must be able to write, observed {written.raw!r}",
    )
    version_after_write = written.integer("VERSION_AFTER")
    lease_b = lease_of(new_protocol.acquire(PRIMARY, request_id="req-8c-b"), "group 8c acquire with the replacement credential")
    require(
        lease_b["version"] == version_after_write,
        f"group 8c: expected the new grant to pin VERSION {version_after_write}, "
        f"observed {lease_b['version']}",
    )
    text_b, pages_b, _ = read_frozen_text(new_protocol, str(lease_b["token"]), lease_b["version"],
                                          lease_b["byte_length"])
    require(
        text_b == POST_EDIT_TEXT + appended,
        f"group 8c: the replacement grant must read the live text, observed {text_b!r}",
    )
    passed("8.4 replacement credential over the republished endpoint",
           f"regrant {new_capability} -> ok; old credential -> ERROR {old_auth_error}; "
           f"pre-regrant token -> {stale}; new lease version={lease_b['version']} pages={pages_b} "
           f"bytes={lease_b['byte_length']}")

    # ---- 8d. workspace invalidation (the remaining control command) ------
    control.send("workspace")
    workspace_receipt = control.wait_event("workspace")
    require(
        workspace_receipt == "ok",
        f"group 8d: expected ok for workspace, observed {workspace_receipt!r}",
    )
    workspace_reason = terminal_read_reason(new_protocol.read(str(lease_b["token"]), 0, 1),
                                            "group 8d held lease after workspace")
    require(
        workspace_reason == "snapshot_workspace_changed",
        f"group 8d: expected REASON snapshot_workspace_changed, observed {workspace_reason}",
    )
    passed("8.5 workspace invalidation",
           f"post-regrant acquire granted token={lease_b['token']}; workspace -> ok; "
           f"held lease -> {workspace_reason}")

    # ---- 9. clean shutdown ------------------------------------------------
    control.send("exit")
    return_code = process.wait(timeout=15)
    require(return_code == 0, f"group 9: expected exit code 0, observed {return_code}")
    diag_prefix = "CJGUI_SHARED_DOCUMENT_LEASE_DIAG "
    handles_prefix = "CJGUI_SHARED_DOCUMENT_HANDLES "
    diag_line = stdout.wait_for_prefix(diag_prefix, 5.0)
    handles_line = stdout.wait_for_prefix(handles_prefix, 5.0)
    diagnostics = diag_line[len(diag_prefix):]
    require(
        "active=0" in diagnostics,
        f"group 9: expected active=0 in the lease diagnostics, observed {diagnostics!r}",
    )
    require(
        "cleanup_pending=0" in diagnostics,
        f"group 9: expected cleanup_pending=0 in the lease diagnostics, observed {diagnostics!r}",
    )
    handles = handles_line[len(handles_prefix):]
    require(
        handles == "0",
        f"group 9: expected CJGUI_SHARED_DOCUMENT_HANDLES 0 (every handle converged), observed {handles!r}",
    )
    receipts = control.events()
    expected_receipts = [
        "EVENT control close 999999 unknown_document",
        f"EVENT control close {SECONDARY} ok",
        "EVENT control revoke ok",
        "EVENT control regrant cjgui-shared-document-second-consumer-20260912 旧的A "
        "authorization_credential_recycled",
        f"EVENT control regrant {new_capability} 新的B ok",
        "EVENT control workspace ok",
        "EVENT control exit ok",
    ]
    for receipt in expected_receipts:
        require(
            receipt in receipts,
            f"group 9: expected receipt {receipt!r}; observed {receipts!r}",
        )

    require(
        not descriptor.exists(),
        f"group 9: descriptor {descriptor} survived consumer cleanup",
    )
    stderr_lines = stderr.lines()
    require(
        not [line for line in stderr_lines if "shared document second consumer" in line],
        f"group 9: unexpected consumer diagnostics on stderr: {stderr_lines!r}",
    )
    passed("9. clean shutdown",
           f"exit_code={return_code} diag={diagnostics} handles={handles} "
           f"descriptor_removed={not descriptor.exists()} receipts={len(receipts)}")


def main() -> int:
    if not CONSUMER.exists():
        print(f"FAIL build the consumer before this acceptance: {CONSUMER}", file=sys.stderr, flush=True)
        return 2
    environment = dict(os.environ)
    runtime = Path(environment.get("CANGJIE_HOME", "/Users/jiangxuanyang/cangjie-toolchains/cangjie")) / "runtime/lib/darwin_aarch64_cjnative"
    if not runtime.exists():
        print(f"FAIL Cangjie runtime is unavailable: {runtime}", file=sys.stderr, flush=True)
        return 2
    existing = environment.get("DYLD_LIBRARY_PATH")
    environment["DYLD_LIBRARY_PATH"] = f"{runtime}:{existing}" if existing else str(runtime)

    with tempfile.TemporaryDirectory(prefix="cjgui-snapshot-lease-") as temporary:
        home = Path(temporary)
        control_path = home / "control.txt"
        events_path = home / "events.txt"
        control_path.write_text("", encoding="utf-8")
        events_path.write_text("", encoding="utf-8")
        control = ControlChannel(control_path, events_path)
        process = subprocess.Popen(
            [str(CONSUMER), "--lease-ttl-ms", str(LEASE_TTL_MS),
             "--control", str(control_path), "--events", str(events_path)],
            cwd=ROOT, env=environment, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=1,
        )
        assert process.stdout is not None and process.stderr is not None
        stdout = StreamCollector(process.stdout)
        stderr = StreamCollector(process.stderr)
        stdout.start()
        stderr.start()
        try:
            acceptance(process, stdout, stderr, control)
        except AcceptanceFailure as failure:
            print(f"FAIL {failure}", file=sys.stderr, flush=True)
            return 1
        except BaseException as unexpected:  # transport/protocol errors keep their own name
            print(f"FAIL unexpected {type(unexpected).__name__}: {unexpected}", file=sys.stderr, flush=True)
            return 1
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)
        print("shared_document_snapshot_lease acceptance passed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
