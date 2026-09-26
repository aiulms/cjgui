#!/usr/bin/env python3
"""Public client contract tests.

The fixture is deliberately a tiny wire-compatible peer instead of an
application object.  It verifies the public Python entry point performs the
same framed exchange a developer will use through an issued descriptor.
"""

from __future__ import annotations

import importlib.util
import os
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock
from pathlib import Path


CLIENT_PATH = Path(__file__).with_name("client.py")
SPEC = importlib.util.spec_from_file_location("cjgui_shared_operation_client", CLIENT_PATH)
assert SPEC and SPEC.loader
client = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = client
SPEC.loader.exec_module(client)


def framed(payload: str) -> bytes:
    encoded = payload.encode("utf-8")
    return f"{len(encoded)}\n".encode("ascii") + encoded


def read_framed(connection: socket.socket) -> str:
    received = bytearray()
    while b"\n" not in received:
        received.extend(connection.recv(4096))
    header, payload = bytes(received).split(b"\n", 1)
    expected = int(header)
    while len(payload) < expected:
        payload += connection.recv(4096)
    return payload.decode("utf-8")


def write_descriptor(directory: Path, socket_path: Path) -> Path:
    descriptor_path = directory / "connection.cjgui"
    descriptor = "\n".join(
        [
            f"PROTOCOL {client.PROTOCOL}",
            f"SOCKET_PATH_UTF8_HEX {len(os.fsencode(socket_path))} {os.fsencode(socket_path).hex().upper()}",
            "CAPABILITY_UTF8_HEX 5 746F6B656E",
            "CALLER_UTF8_HEX 6 7075626C6963",
            "END",
        ]
    )
    descriptor_path.write_text(descriptor, encoding="utf-8")
    descriptor_path.chmod(0o600)
    return descriptor_path


def window_snapshot(
    *,
    projection: str = "ACTIVE",
    session: str = "cjgui_window_test",
    accepted: int = 4,
    submitted: int = 4,
    overlay: int = 4,
    pending: str = "none",
    kind: str = "WINDOW_PROGRESS",
) -> object:
    lines = [
        f"PROTOCOL {client.PROTOCOL}",
        f"KIND {kind}",
    ]
    if kind == "WINDOW_PROGRESS":
        lines.append(f"WINDOW_PROJECTION {projection}")
        if projection == "ACTIVE":
            lines.extend(
                [
                    f"WINDOW_SESSION {session}",
                    f"WINDOW_ACCEPTED_SCENE_VERSION {accepted}",
                    f"WINDOW_SUBMITTED_SCENE_VERSION {submitted}",
                    f"WINDOW_OVERLAY_DRAWN_SCENE_VERSION {overlay}",
                    f"WINDOW_REFRESH_PENDING {pending}",
                ]
            )
    elif kind == "ERROR":
        lines.append("ERROR unauthorized_capability")
    lines.append("END")
    return client.parse_response("\n".join(lines))


class PublicClientTest(unittest.TestCase):
    def test_public_client_encodes_targeted_window_progress_and_interaction_reads(self) -> None:
        operation = client.SharedOperationClient({"capability": "token"})

        with mock.patch.object(client.SharedOperationClient, "request", autospec=True) as request:
            operation.get_window_progress("app_window_7")
            operation.get_window_interaction("app_window_7")

        self.assertEqual(request.call_args_list[0].args[1],
                         f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_WINDOW_PROGRESS app_window_7")
        self.assertEqual(request.call_args_list[1].args[1],
                         f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_WINDOW_INTERACTION app_window_7")

    def test_public_client_keeps_legacy_unqualified_window_reads(self) -> None:
        operation = client.SharedOperationClient({"capability": "token"})

        with mock.patch.object(client.SharedOperationClient, "request", autospec=True) as request:
            operation.get_window_progress()
            operation.get_window_interaction()

        self.assertEqual(request.call_args_list[0].args[1],
                         f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_WINDOW_PROGRESS")
        self.assertEqual(request.call_args_list[1].args[1],
                         f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_WINDOW_INTERACTION")

    def test_public_client_rejects_non_identifier_targeted_window_reads(self) -> None:
        operation = client.SharedOperationClient({"capability": "token"})
        for method in (operation.get_window_progress, operation.get_window_interaction):
            with self.subTest(method=method.__name__):
                with self.assertRaisesRegex(ValueError, "window target is not an identifier"):
                    method("bad target")

    def test_public_client_encodes_targeted_window_read_commands(self) -> None:
        for command, expected in (
            ("window-progress", "GET_WINDOW_PROGRESS app_window_7"),
            ("window-interaction", "GET_WINDOW_INTERACTION app_window_7"),
        ):
            with self.subTest(command=command):
                args = client.parser().parse_args(["descriptor.cjgui", command, "app_window_7"])
                payload = client.request_payload(args, {"capability": "token"})
                self.assertEqual(payload, f"PROTOCOL {client.PROTOCOL}\nAUTH token\n{expected}")

    def test_public_client_encodes_separately_authorized_window_interaction_read(self) -> None:
        args = client.parser().parse_args(["descriptor.cjgui", "window-interaction"])
        payload = client.request_payload(args, {"capability": "token"})
        self.assertEqual(
            payload,
            f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_WINDOW_INTERACTION",
        )

    def test_public_client_encodes_enumerated_and_exact_window_projection_reads(self) -> None:
        targets = client.parser().parse_args(["descriptor.cjgui", "window-targets"])
        target_payload = client.request_payload(targets, {"capability": "token"})
        self.assertEqual(
            target_payload,
            f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_WINDOW_TARGETS",
        )

        exact = client.parser().parse_args(["descriptor.cjgui", "window-context", "app_window_7"])
        exact_payload = client.request_payload(exact, {"capability": "token"})
        self.assertEqual(
            exact_payload,
            f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_WINDOW_CONTEXT app_window_7",
        )

    def test_public_client_rejects_non_identifier_window_target(self) -> None:
        args = client.parser().parse_args(["descriptor.cjgui", "window-context", "bad target"])
        with self.assertRaisesRegex(ValueError, "window target is not an identifier"):
            client.request_payload(args, {"capability": "token"})

    def test_observer_resyncs_when_same_version_snapshot_stream_is_replaced(self) -> None:
        def snapshot(version: int, stream_id: str, label: str) -> object:
            return client.parse_response(
                "\n".join(
                    [
                        f"PROTOCOL {client.PROTOCOL}", "KIND SNAPSHOT", f"VERSION {version}",
                        f"STREAM_ID {stream_id}", "RESOURCES 1",
                        f"RESOURCE 42 {len(label.encode('utf-8'))} {label.encode('utf-8').hex().upper()} 0", "END",
                    ]
                )
            )

        def changes(since: int, current: int, stream_id: str) -> object:
            return client.parse_response(
                "\n".join(
                    [
                        f"PROTOCOL {client.PROTOCOL}", "KIND CHANGES", f"STREAM_ID {stream_id}",
                        f"SINCE_VERSION {since}", f"CURRENT_VERSION {current}",
                        "RESYNC_REQUIRED false", "CHANGES 0", "END",
                    ]
                )
            )

        operation = client.SharedOperationClient({"capability": "token"})
        observer = client.SharedOperationObserver(operation, (42,))
        with mock.patch.object(
            client.SharedOperationClient, "get_context", autospec=True,
            side_effect=[snapshot(7, "stream_a", "old"), snapshot(0, "stream_b", "new")],
        ), mock.patch.object(
            client.SharedOperationClient, "changes", autospec=True,
            return_value=changes(7, 7, "stream_b"),
        ):
            initial = observer.observe_once()
            resynced = observer.observe_once()

        self.assertEqual(initial.stream_id, "stream_a")
        self.assertEqual(resynced.outcome, "resynced")
        self.assertEqual(resynced.version, 0)
        self.assertEqual(resynced.stream_id, "stream_b")
        self.assertEqual(observer.snapshots()[42].values("RESOURCE")[0][2], "6E6577")

    def test_observer_resyncs_instead_of_publishing_target_from_another_stream(self) -> None:
        def snapshot(version: int, stream_id: str, label: str) -> object:
            return client.parse_response(
                "\n".join(
                    [
                        f"PROTOCOL {client.PROTOCOL}", "KIND SNAPSHOT", f"VERSION {version}",
                        f"STREAM_ID {stream_id}", "RESOURCES 1",
                        f"RESOURCE 42 {len(label.encode('utf-8'))} {label.encode('utf-8').hex().upper()} 0", "END",
                    ]
                )
            )

        changed = client.parse_response(
            "\n".join(
                [
                    f"PROTOCOL {client.PROTOCOL}", "KIND CHANGES", "STREAM_ID stream_a",
                    "SINCE_VERSION 1", "CURRENT_VERSION 2", "RESYNC_REQUIRED false",
                    "CHANGES 1", "CHANGE 2 42 updated", "END",
                ]
            )
        )
        operation = client.SharedOperationClient({"capability": "token"})
        observer = client.SharedOperationObserver(operation, (42,))
        with mock.patch.object(
            client.SharedOperationClient, "get_context", autospec=True,
            side_effect=[
                snapshot(1, "stream_a", "old"),
                snapshot(2, "stream_b", "raced-target"),
                snapshot(0, "stream_b", "resynced"),
            ],
        ), mock.patch.object(client.SharedOperationClient, "changes", autospec=True, return_value=changed):
            self.assertEqual(observer.observe_once().outcome, "initial")
            resynced = observer.observe_once()

        self.assertEqual(resynced.outcome, "resynced")
        self.assertEqual(resynced.version, 0)
        self.assertEqual(resynced.stream_id, "stream_b")
        self.assertEqual(observer.snapshots()[42].values("RESOURCE")[0][2], "726573796E636564")

    def test_observer_downgrades_old_snapshot_providers_to_full_resyncs(self) -> None:
        def snapshot(version: int, label: str) -> object:
            return client.parse_response(
                "\n".join(
                    [
                        f"PROTOCOL {client.PROTOCOL}", "KIND SNAPSHOT", f"VERSION {version}",
                        "RESOURCES 1",
                        f"RESOURCE 42 {len(label.encode('utf-8'))} {label.encode('utf-8').hex().upper()} 0", "END",
                    ]
                )
            )

        operation = client.SharedOperationClient({"capability": "token"})
        observer = client.SharedOperationObserver(operation, (42,))
        with mock.patch.object(
            client.SharedOperationClient, "get_context", autospec=True,
            side_effect=[snapshot(1, "old"), snapshot(2, "fresh")],
        ) as get_context, mock.patch.object(client.SharedOperationClient, "changes", autospec=True) as get_changes:
            initial = observer.observe_once()
            resynced = observer.observe_once()

        self.assertEqual(initial.outcome, "initial")
        self.assertEqual(initial.stream_id, "")
        self.assertEqual(resynced.outcome, "resynced")
        self.assertEqual(resynced.version, 2)
        self.assertEqual(resynced.detail, "snapshot_identity_unavailable")
        self.assertEqual(get_context.call_count, 2)
        get_changes.assert_not_called()

    def test_observer_publishes_multiple_target_changes_atomically_and_discards_stale_cache_on_resync_failure(self) -> None:
        def snapshot(version: int, *resource_ids: int) -> object:
            lines = [f"PROTOCOL {client.PROTOCOL}", "KIND SNAPSHOT", f"VERSION {version}", "STREAM_ID stream_1", f"RESOURCES {len(resource_ids)}"]
            lines.extend(f"RESOURCE {resource_id} 1 78 0" for resource_id in resource_ids)
            lines.append("END")
            return client.parse_response("\n".join(lines))

        def changes(version: int, *, resync: bool, entries: list[tuple[int, int]]) -> object:
            lines = [
                f"PROTOCOL {client.PROTOCOL}", "KIND CHANGES", "STREAM_ID stream_1",
                "SINCE_VERSION 1", f"CURRENT_VERSION {version}",
                f"RESYNC_REQUIRED {str(resync).lower()}", f"CHANGES {len(entries)}",
            ]
            lines.extend(f"CHANGE {entry_version} {resource_id} updated" for entry_version, resource_id in entries)
            lines.append("END")
            return client.parse_response("\n".join(lines))

        error = client.parse_response(
            "\n".join([f"PROTOCOL {client.PROTOCOL}", "KIND ERROR", "ERROR invalid_request", "END"])
        )
        operation = client.SharedOperationClient({"capability": "token"})
        observer = client.SharedOperationObserver(operation)
        with mock.patch.object(
            client.SharedOperationClient, "get_context", autospec=True,
            side_effect=[snapshot(1, 41, 42), snapshot(2, 42), error, error],
        ), mock.patch.object(
            client.SharedOperationClient, "changes", autospec=True,
            side_effect=[changes(2, resync=False, entries=[(2, 42), (2, 43)]), changes(2, resync=True, entries=[])],
        ):
            initial = observer.observe_once()
            partial_failure = observer.observe_once()
            resources_after_partial_failure = observer.resource_ids()
            resync_failure = observer.observe_once()

        self.assertEqual(initial.outcome, "initial")
        self.assertEqual(partial_failure.outcome, "remote_error")
        self.assertEqual(resources_after_partial_failure, ())
        self.assertEqual(resync_failure.outcome, "remote_error")
        self.assertEqual(observer.resource_ids(), ())

    def test_observer_uses_one_deadline_across_changes_and_target_reread(self) -> None:
        def snapshot(version: int) -> object:
            return client.parse_response(
                "\n".join(
                    [f"PROTOCOL {client.PROTOCOL}", "KIND SNAPSHOT", f"VERSION {version}", "STREAM_ID stream_1", "RESOURCES 1", "RESOURCE 42 1 78 0", "END"]
                )
            )

        change_response = client.parse_response(
            "\n".join(
                [
                    f"PROTOCOL {client.PROTOCOL}", "KIND CHANGES", "STREAM_ID stream_1",
                    "SINCE_VERSION 1", "CURRENT_VERSION 2", "RESYNC_REQUIRED false",
                    "CHANGES 1", "CHANGE 2 42 updated", "END",
                ]
            )
        )
        operation = client.SharedOperationClient({"capability": "token"})
        observer = client.SharedOperationObserver(operation, (42,))
        target_budgets: list[float] = []

        def get_context(_self: object, _targets: object, *, timeout_seconds: float | None = None) -> object:
            if not target_budgets:
                target_budgets.append(-1.0)
                return snapshot(1)
            assert timeout_seconds is not None
            target_budgets.append(timeout_seconds)
            raise TimeoutError("target_read_deadline_expired")

        def changes(_self: object, *_args: object, **_kwargs: object) -> object:
            time.sleep(0.055)
            return change_response

        with mock.patch.object(client.SharedOperationClient, "get_context", autospec=True, side_effect=get_context), \
             mock.patch.object(client.SharedOperationClient, "changes", autospec=True, side_effect=changes):
            self.assertEqual(observer.observe_once(timeout_seconds=0.08).outcome, "initial")
            expired = observer.observe_once(timeout_seconds=0.08)

        self.assertEqual(expired.outcome, "timeout")
        self.assertLess(target_budgets[1], 0.05)
        self.assertEqual(observer.resource_ids(), ())

    def test_observer_clears_its_projection_on_endpoint_loss_before_fresh_descriptor_resync(self) -> None:
        def snapshot(version: int) -> object:
            return client.parse_response(
                "\n".join(
                    [
                        f"PROTOCOL {client.PROTOCOL}", "KIND SNAPSHOT", f"VERSION {version}", "STREAM_ID stream_1",
                        "RESOURCES 1", "RESOURCE 42 1 78 0", "END",
                    ]
                )
            )

        first_client = client.SharedOperationClient({"capability": "first"})
        replacement_client = client.SharedOperationClient({"capability": "replacement"})
        observer = client.SharedOperationObserver(first_client, (42,))
        with mock.patch.object(
            client.SharedOperationClient, "get_context", autospec=True,
            side_effect=[snapshot(1), snapshot(2)],
        ), mock.patch.object(
            client.SharedOperationClient, "changes", autospec=True,
            side_effect=OSError("endpoint_closed"),
        ):
            initial = observer.observe_once()
            disconnected = observer.observe_once()
            observer.reconnect(replacement_client)
            resumed = observer.observe_once()

        self.assertEqual(initial.outcome, "initial")
        self.assertEqual(disconnected.outcome, "reconnect_required")
        self.assertEqual(observer.resource_ids(), (42,))
        self.assertEqual(resumed.outcome, "initial")

    def test_observer_uses_changes_for_idle_and_resyncs_on_stream_replacement(self) -> None:
        def snapshot(version: int, resource_id: int, stream: str) -> object:
            return client.parse_response(
                "\n".join(
                    [
                        f"PROTOCOL {client.PROTOCOL}",
                        "KIND SNAPSHOT",
                        f"VERSION {version}",
                        f"STREAM_ID {stream}",
                        "RESOURCES 1",
                        f"RESOURCE {resource_id} 1 78 0",
                        "END",
                    ]
                )
            )

        def changes(since: int, current: int, stream: str, resync: bool, entries: list[tuple[int, int, str]]) -> object:
            lines = [
                f"PROTOCOL {client.PROTOCOL}", "KIND CHANGES", f"STREAM_ID {stream}",
                f"SINCE_VERSION {since}", f"CURRENT_VERSION {current}",
                f"RESYNC_REQUIRED {str(resync).lower()}", f"CHANGES {len(entries)}",
            ]
            lines.extend(f"CHANGE {version} {resource_id} {kind}" for version, resource_id, kind in entries)
            lines.append("END")
            return client.parse_response("\n".join(lines))

        operation_client = client.SharedOperationClient({"capability": "token"})
        observer = client.SharedOperationObserver(operation_client)
        with mock.patch.object(
            client.SharedOperationClient, "get_context", autospec=True,
            side_effect=[
                snapshot(1, 42, "text-document-123"),
                snapshot(2, 42, "text-document-123"),
                snapshot(4, 42, "text-document-456"),
            ],
        ) as get_context, mock.patch.object(
            client.SharedOperationClient, "changes", autospec=True,
            side_effect=[
                changes(1, 1, "text-document-123", False, []),
                changes(1, 2, "text-document-123", False, [(2, 42, "updated")]),
                changes(2, 4, "text-document-456", True, []),
            ],
        ):
            initial = observer.observe_once()
            idle = observer.observe_once()
            changed = observer.observe_once()
            resynced = observer.observe_once()

        self.assertEqual(initial.outcome, "initial")
        self.assertEqual(idle.outcome, "no_change")
        self.assertEqual(changed.outcome, "changed")
        self.assertEqual(changed.changed_resource_ids, (42,))
        self.assertEqual(resynced.outcome, "resynced")
        self.assertEqual(resynced.stream_id, "text-document-456")
        self.assertEqual(observer.resource_ids(), (42,))
        self.assertEqual(get_context.call_count, 3)

    def test_observer_binds_a_resync_snapshot_stream_before_the_next_changes_read(self) -> None:
        def snapshot(version: int, stream: str) -> object:
            return client.parse_response(
                "\n".join(
                    [
                        f"PROTOCOL {client.PROTOCOL}", "KIND SNAPSHOT", f"VERSION {version}", f"STREAM_ID {stream}",
                        "RESOURCES 1", "RESOURCE 42 1 78 0", "END",
                    ]
                )
            )

        def changes(since: int, current: int, stream: str, entries: list[tuple[int, int]]) -> object:
            lines = [
                f"PROTOCOL {client.PROTOCOL}", "KIND CHANGES", f"STREAM_ID {stream}",
                f"SINCE_VERSION {since}", f"CURRENT_VERSION {current}", "RESYNC_REQUIRED false",
                f"CHANGES {len(entries)}",
            ]
            lines.extend(f"CHANGE {version} {resource_id} updated" for version, resource_id in entries)
            lines.append("END")
            return client.parse_response("\n".join(lines))

        operation_client = client.SharedOperationClient({"capability": "token"})
        observer = client.SharedOperationObserver(operation_client, (42,))
        with mock.patch.object(
            client.SharedOperationClient, "get_context", autospec=True,
            # The target reread races past CURRENT_VERSION=2. The observer
            # discards it, then binds the replacement v3 snapshot to the
            # owner stream that produced that snapshot.
            side_effect=[snapshot(1, "stream_2"), snapshot(3, "stream_2"), snapshot(3, "stream_3")],
        ), mock.patch.object(
            client.SharedOperationClient, "changes", autospec=True,
            side_effect=[
                changes(1, 2, "stream_2", [(2, 42)]),
                changes(3, 3, "stream_3", []),
            ],
        ) as get_changes:
            self.assertEqual(observer.observe_once().outcome, "initial")
            resynced = observer.observe_once()
            cursor_bound = observer.observe_once()

        self.assertEqual(resynced.outcome, "resynced")
        self.assertEqual(resynced.version, 3)
        self.assertEqual(resynced.stream_id, "stream_3")
        self.assertEqual(observer.snapshots()[42].integer("VERSION"), 3)
        self.assertEqual(cursor_bound.outcome, "no_change")
        self.assertEqual(cursor_bound.stream_id, "stream_3")
        self.assertEqual(get_changes.call_args_list[1].kwargs["stream_id"], "stream_3")

    def test_observer_removes_a_deleted_target_from_its_public_projection(self) -> None:
        def snapshot(version: int, *resource_ids: int) -> object:
            lines = [f"PROTOCOL {client.PROTOCOL}", "KIND SNAPSHOT", f"VERSION {version}", "STREAM_ID stream_1", f"RESOURCES {len(resource_ids)}"]
            lines.extend(f"RESOURCE {resource_id} 1 78 0" for resource_id in resource_ids)
            lines.append("END")
            return client.parse_response("\n".join(lines))

        change_response = client.parse_response(
            "\n".join(
                [
                    f"PROTOCOL {client.PROTOCOL}", "KIND CHANGES", "STREAM_ID stream_1",
                    "SINCE_VERSION 1", "CURRENT_VERSION 2", "RESYNC_REQUIRED false",
                    "CHANGES 1", "CHANGE 2 43 deleted", "END",
                ]
            )
        )
        unknown_resource = client.parse_response(
            "\n".join([f"PROTOCOL {client.PROTOCOL}", "KIND ERROR", "ERROR unknown_resource", "END"])
        )
        operation_client = client.SharedOperationClient({"capability": "token"})
        observer = client.SharedOperationObserver(operation_client, (42, 43))
        with mock.patch.object(
            client.SharedOperationClient, "get_context", autospec=True,
            side_effect=[snapshot(1, 42, 43), unknown_resource],
        ), mock.patch.object(
            client.SharedOperationClient, "changes", autospec=True, return_value=change_response,
        ):
            self.assertEqual(observer.observe_once().outcome, "initial")
            deleted = observer.observe_once()

        self.assertEqual(deleted.outcome, "changed")
        self.assertEqual(deleted.changed_resource_ids, (43,))
        self.assertEqual(deleted.version, 2)
        self.assertEqual(observer.resource_ids(), (42,))
        self.assertNotIn(43, observer.snapshots())

    def test_window_wait_is_bounded_read_only_and_distinguishes_completion(self) -> None:
        def snapshot(overlay_version: int, pending: str = "none") -> object:
            return client.parse_response(
                "\n".join(
                    [
                        f"PROTOCOL {client.PROTOCOL}",
                        "KIND WINDOW_PROGRESS",
                        "WINDOW_PROJECTION ACTIVE",
                        "WINDOW_SESSION cjgui_window_1",
                        "WINDOW_ACCEPTED_SCENE_VERSION 4",
                        "WINDOW_SUBMITTED_SCENE_VERSION 4",
                        f"WINDOW_OVERLAY_DRAWN_SCENE_VERSION {overlay_version}",
                        f"WINDOW_REFRESH_PENDING {pending}",
                        "END",
                    ]
                )
            )

        operation_client = client.SharedOperationClient({"capability": "token"})
        responses = iter([snapshot(3), snapshot(4)])
        with mock.patch.object(client.SharedOperationClient, "get_window_progress", autospec=True,
                               side_effect=lambda _self, _targets=(), *, timeout_seconds=None: next(responses)), \
             mock.patch.object(client.time, "sleep") as sleep:
            waited = operation_client.wait_for_window_progress(
                "cjgui_window_1", 4, phase="overlay", timeout_ms=200, poll_ms=25
            )
        self.assertEqual(waited.outcome, "completed")
        self.assertEqual(waited.response.integer("WINDOW_OVERLAY_DRAWN_SCENE_VERSION"), 4)
        sleep.assert_called_once_with(0.025)

        with mock.patch.object(client.SharedOperationClient, "get_window_progress", autospec=True,
                               return_value=snapshot(3, "refresh_internal_error")):
            failed = operation_client.wait_for_window_progress(
                "cjgui_window_1", 4, phase="overlay", timeout_ms=200, poll_ms=25
            )
        self.assertEqual(failed.outcome, "pending_failure")

    def test_window_wait_does_not_mislabel_protocol_or_remote_failures_as_closed(self) -> None:
        operation_client = client.SharedOperationClient({"capability": "token"})
        with mock.patch.object(
            client.SharedOperationClient, "get_window_progress", autospec=True,
            return_value=window_snapshot(kind="ERROR"),
        ):
            remote = operation_client.wait_for_window_progress(
                "cjgui_window_test", 4, phase="accepted", timeout_ms=200
            )
        self.assertEqual(remote.outcome, "remote_error")

        with mock.patch.object(
            client.SharedOperationClient, "get_window_progress", autospec=True,
            return_value=window_snapshot(kind="RESULT"),
        ):
            malformed = operation_client.wait_for_window_progress(
                "cjgui_window_test", 4, phase="accepted", timeout_ms=200
            )
        self.assertEqual(malformed.outcome, "protocol_error")

        with mock.patch.object(
            client.SharedOperationClient, "get_window_progress", autospec=True,
            return_value=window_snapshot(projection="NONE"),
        ):
            closed = operation_client.wait_for_window_progress(
                "cjgui_window_test", 4, phase="accepted", timeout_ms=200
            )
        self.assertEqual(closed.outcome, "closed")

        # A semantic-only hierarchy update reaches accepted without a native
        # frame. Callers that require a Metal/overlay fact must explicitly ask
        # for submitted/overlay instead of treating all scene versions alike.
        with mock.patch.object(
            client.SharedOperationClient, "get_window_progress", autospec=True,
            return_value=window_snapshot(accepted=4, submitted=3, overlay=3),
        ):
            accepted = operation_client.wait_for_window_progress(
                "cjgui_window_test", 4, phase="accepted", timeout_ms=200
            )
        self.assertEqual(accepted.outcome, "completed")

    def test_window_wait_forwards_exact_target_without_falling_back(self) -> None:
        operation_client = client.SharedOperationClient({"capability": "token"})
        response = window_snapshot(overlay=4, session="cjgui_window_2")
        with mock.patch.object(
            client.SharedOperationClient, "get_window_progress", autospec=True,
            return_value=response,
        ) as get_progress:
            waited = operation_client.wait_for_window_progress(
                "cjgui_window_2", 4, target="app_window_7", phase="overlay", timeout_ms=200
            )
        self.assertEqual(waited.outcome, "completed")
        self.assertEqual(get_progress.call_args.args[1], "app_window_7")

    def test_window_wait_enforces_its_total_timeout_during_socket_read(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)
            ready = threading.Event()

            def delay_response() -> None:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                    listener.bind(os.fspath(socket_path))
                    listener.listen(1)
                    ready.set()
                    connection, _ = listener.accept()
                    with connection:
                        read_framed(connection)
                        # Longer than the caller's whole deadline; the old
                        # fixed two-second socket timeout waited here.
                        time.sleep(0.150)

            thread = threading.Thread(target=delay_response)
            thread.start()
            self.assertTrue(ready.wait(1))
            started = time.monotonic()
            waited = client.SharedOperationClient.from_descriptor(descriptor_path).wait_for_window_progress(
                "cjgui_window_test", 4, phase="accepted", timeout_ms=30, poll_ms=5
            )
            elapsed = time.monotonic() - started
            thread.join(1)
            self.assertEqual(waited.outcome, "timeout")
            self.assertIsNone(waited.response)
            self.assertLess(elapsed, 0.125)

    def test_empty_utf8_uses_a_nonempty_wire_token(self) -> None:
        self.assertEqual(
            client.SharedOperationArgument.string("empty", "").wire_line(),
            "ARG empty STRING 0 -",
        )
        self.assertEqual(
            client.encode_text_replacements([client.TextReplacement(3, 6, "")]),
            "CJGUI_TEXT_REPLACEMENTS/1\n3 6 0 -",
        )
        response = client.parse_response(
            "\n".join(
                [
                    f"PROTOCOL {client.PROTOCOL}",
                    "KIND RANGE",
                    "CONTENT_UTF8_HEX 0 -",
                    "END",
                ]
            )
        )
        self.assertEqual(response.text("CONTENT_UTF8_HEX"), "")

    def test_imported_client_reads_utf8_range_as_structured_result(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)

            ready = threading.Event()
            failure: list[BaseException] = []

            def serve_once() -> None:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                        listener.bind(os.fspath(socket_path))
                        listener.listen(1)
                        ready.set()
                        connection, _ = listener.accept()
                        with connection:
                            self.assertIn(b"READ_RANGE 42 0 3 7", connection.recv(4096))
                            response = "\n".join(
                                [
                                    f"PROTOCOL {client.PROTOCOL}",
                                    "KIND RANGE",
                                    "AVAILABLE true",
                                    "CONFLICT false",
                                    "RESOURCE 42",
                                    "VERSION 7",
                                    "RANGE 0 3",
                                    "REASON available",
                                    "CONTENT_UTF8_HEX 3 E7ACAC",
                                    "END",
                                ]
                            )
                            connection.sendall(framed(response))
                except BaseException as exc:  # deliver server assertions to the test thread
                    failure.append(exc)

            thread = threading.Thread(target=serve_once)
            thread.start()
            self.assertTrue(ready.wait(1))
            response = client.SharedOperationClient.from_descriptor(descriptor_path).read_range(42, 0, 3, 7)
            thread.join(1)
            if failure:
                raise failure[0]

            self.assertEqual(response.kind, "RANGE")
            self.assertEqual(response.integer("RESOURCE"), 42)
            self.assertEqual(response.text("CONTENT_UTF8_HEX"), "第")

    def test_cli_reads_multiline_utf8_from_stdin_and_emits_structured_conflict(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)
            ready = threading.Event()
            failure: list[BaseException] = []

            def serve_once() -> None:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                        listener.bind(os.fspath(socket_path))
                        listener.listen(1)
                        ready.set()
                        connection, _ = listener.accept()
                        with connection:
                            request = read_framed(connection)
                            self.assertIn("INVOKE 7 REPLACE_RANGE 1 3", request)
                            self.assertIn("ARG start INTEGER 0", request)
                            self.assertIn("ARG end INTEGER 3", request)
                            encoded = "第一行\n第二行🙂".encode("utf-8")
                            self.assertIn(f"ARG text STRING {len(encoded)} {encoded.hex().upper()}", request)
                            response = "\n".join(
                                [
                                    f"PROTOCOL {client.PROTOCOL}",
                                    "KIND RESULT",
                                    "APPLIED false",
                                    "CONFLICT true",
                                    "VERSION_BEFORE 8",
                                    "VERSION_AFTER 8",
                                    "REASON version_conflict",
                                    "END",
                                ]
                            )
                            connection.sendall(framed(response))
                except BaseException as exc:
                    failure.append(exc)

            thread = threading.Thread(target=serve_once)
            thread.start()
            self.assertTrue(ready.wait(1))
            completed = subprocess.run(
                [
                    sys.executable,
                    os.fspath(CLIENT_PATH),
                    os.fspath(descriptor_path),
                    "--json",
                    "invoke",
                    "7",
                    "REPLACE_RANGE",
                    "--target",
                    "42",
                    "--arg",
                    "start=INTEGER:0",
                    "--arg",
                    "end=INTEGER:3",
                    "--arg-stdin",
                    "text",
                ],
                input="第一行\n第二行🙂",
                text=True,
                capture_output=True,
                check=False,
            )
            thread.join(1)
            if failure:
                raise failure[0]

            self.assertEqual(completed.returncode, client.EXIT_VERSION_CONFLICT, completed.stderr)
            output = __import__("json").loads(completed.stdout)
            self.assertEqual(output["kind"], "RESULT")
            self.assertEqual(output["entries"][1], {"name": "CONFLICT", "values": ["true"]})

    def test_imported_client_encodes_multi_range_text_without_manual_escaping(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)
            ready = threading.Event()
            failure: list[BaseException] = []

            def serve_once() -> None:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                        listener.bind(os.fspath(socket_path))
                        listener.listen(1)
                        ready.set()
                        connection, _ = listener.accept()
                        with connection:
                            request = read_framed(connection)
                            batch = "CJGUI_TEXT_REPLACEMENTS/1\n3 6 1 41\n9 12 6 E4B881E4B881"
                            encoded = batch.encode("utf-8")
                            self.assertIn("INVOKE 7 REPLACE_RANGES 1 1", request)
                            self.assertIn(
                                f"ARG replacements TEXT_REPLACEMENTS {len(encoded)} {encoded.hex().upper()}",
                                request,
                            )
                            response = "\n".join(
                                [
                                    f"PROTOCOL {client.PROTOCOL}",
                                    "KIND RESULT",
                                    "APPLIED true",
                                    "CONFLICT false",
                                    "VERSION_BEFORE 7",
                                    "VERSION_AFTER 8",
                                    "REASON applied",
                                    "END",
                                ]
                            )
                            connection.sendall(framed(response))
                except BaseException as exc:
                    failure.append(exc)

            thread = threading.Thread(target=serve_once)
            thread.start()
            self.assertTrue(ready.wait(1))
            response = client.SharedOperationClient.from_descriptor(descriptor_path).invoke(
                7,
                "REPLACE_RANGES",
                [42],
                [
                    client.SharedOperationArgument.text_replacements(
                        "replacements",
                        [client.TextReplacement(3, 6, "A"), client.TextReplacement(9, 12, "丁丁")],
                    )
                ],
            )
            thread.join(1)
            if failure:
                raise failure[0]
            self.assertEqual(response.integer("VERSION_AFTER"), 8)

    def test_cli_reads_structured_replacements_from_utf8_json_file(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)
            replacements_path = directory / "replacements.json"
            replacements_path.write_text(
                '[{"start": 3, "end": 6, "text": "A"}, {"start": 9, "end": 12, "text": "丁丁"}]',
                encoding="utf-8",
            )
            ready = threading.Event()
            failure: list[BaseException] = []

            def serve_once() -> None:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                        listener.bind(os.fspath(socket_path))
                        listener.listen(1)
                        ready.set()
                        connection, _ = listener.accept()
                        with connection:
                            request = read_framed(connection)
                            batch = "CJGUI_TEXT_REPLACEMENTS/1\n3 6 1 41\n9 12 6 E4B881E4B881"
                            encoded = batch.encode("utf-8")
                            self.assertIn("INVOKE 7 REPLACE_RANGES 1 1", request)
                            self.assertIn(
                                f"ARG replacements TEXT_REPLACEMENTS {len(encoded)} {encoded.hex().upper()}",
                                request,
                            )
                            response = "\n".join(
                                [
                                    f"PROTOCOL {client.PROTOCOL}",
                                    "KIND RESULT",
                                    "APPLIED true",
                                    "CONFLICT false",
                                    "VERSION_BEFORE 7",
                                    "VERSION_AFTER 8",
                                    "REASON applied",
                                    "END",
                                ]
                            )
                            connection.sendall(framed(response))
                except BaseException as exc:
                    failure.append(exc)

            thread = threading.Thread(target=serve_once)
            thread.start()
            self.assertTrue(ready.wait(1))
            completed = subprocess.run(
                [
                    sys.executable,
                    os.fspath(CLIENT_PATH),
                    os.fspath(descriptor_path),
                    "--json",
                    "invoke",
                    "7",
                    "REPLACE_RANGES",
                    "--target",
                    "42",
                    "--arg-replacements-file",
                    f"replacements={replacements_path}",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            thread.join(1)
            if failure:
                raise failure[0]
            self.assertEqual(completed.returncode, 0, completed.stderr)


if __name__ == "__main__":
    unittest.main()
