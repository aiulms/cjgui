#!/usr/bin/env python3
"""Consistent-snapshot and change-cursor tests over a REAL AF_UNIX server.

These pin the observation seam the exported public client uses:

* one atomic snapshot carries the separated owner/scene facts and the
  field/structure/instance sections of a SINGLE provider call;
* an unchanged round costs ONE small `GET_GENERATED_UI_CHANGES` and does NOT
  re-read the tree, with the measured reply sizes reported (never extrapolated);
* a draft-only change and a resize are reported as different categories even
  though the structure version is unchanged;
* a truncated history / replaced stream asks for a resync and the poller takes a
  fresh snapshot;
* a changed endpoint INSTANCE is an `endpoint_replaced` endpoint error,
  not a business change.
"""

from __future__ import annotations

import os
import socket
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

MODULE_DIR = Path(__file__).resolve().parent
if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import client  # noqa: E402
import cjgui_generated_client as generated  # noqa: E402
from test_generated_client_ticket import candidate_reply  # noqa: E402


def read_framed(connection: socket.socket) -> str:
    received = bytearray()
    while b"\n" not in received:
        chunk = connection.recv(4096)
        if not chunk:
            raise ConnectionError("peer closed before the request header")
        received.extend(chunk)
    header, payload = bytes(received).split(b"\n", 1)
    expected = int(header)
    while len(payload) < expected:
        chunk = connection.recv(4096)
        if not chunk:
            raise ConnectionError("peer closed before the request payload")
        payload += chunk
    return payload.decode("utf-8")


def write_descriptor(directory: Path, socket_path: Path, endpoint_epoch: int) -> Path:
    descriptor_path = directory / "connection.cjgui"
    descriptor = "\n".join(
        [
            f"PROTOCOL {client.PROTOCOL}",
            f"SOCKET_PATH_UTF8_HEX {len(os.fsencode(socket_path))} {os.fsencode(socket_path).hex().upper()}",
            "CAPABILITY_UTF8_HEX 5 746F6B656E",
            "CALLER_UTF8_HEX 6 7075626C6963",
            f"ENDPOINT_EPOCH {endpoint_epoch}",
            "ENDPOINT_INSTANCE test-endpoint",
            f"ENDPOINT_BIND_GENERATION {endpoint_epoch}",
            "END",
        ]
    )
    descriptor_path.write_text(descriptor, encoding="utf-8")
    descriptor_path.chmod(0o600)
    return descriptor_path


def snapshot_body(*, cursor: int = 0, stream_epoch: int = 1, endpoint_epoch: int = 7,
                  owner_revision: int = 12, draft_revision: int = 3, binding_revision: int = 21,
                  structure_version: int = 4, candidate_token: int = 0,
                  candidate_state: str = "none", scene_version: int = 44,
                  geometry_revision: int = 55, interaction_revision: int = 66,
                  instance_revision: int = 77, owner_pending_scene: int = 0,
                  style_revision: int = 0, tree_nodes: int = 40) -> str:
    lines = [
        f"PROTOCOL {client.PROTOCOL}",
        "KIND GENERATED_UI_SNAPSHOT",
        f"ENDPOINT_EPOCH {endpoint_epoch}",
        "ENDPOINT_INSTANCE test-endpoint",
        f"ENDPOINT_BIND_GENERATION {endpoint_epoch}",
        f"STREAM_EPOCH {stream_epoch}",
        "STREAM_IDENTITY session-1",
        f"CURSOR {cursor}",
        f"OWNER_FIELD_REVISION {owner_revision}",
        f"OWNER_DRAFT_REVISION {draft_revision}",
        f"BINDING_REVISION {binding_revision}",
        f"ACCEPTED_STRUCTURE_VERSION {structure_version}",
        f"CANDIDATE_TOKEN {candidate_token}",
        f"CANDIDATE_STATE {candidate_state}",
        f"WINDOW_ACCEPTED_SCENE_VERSION {scene_version}",
        f"WINDOW_GEOMETRY_REVISION {geometry_revision}",
        f"WINDOW_INTERACTION_REVISION {interaction_revision}",
        f"INSTANCE_REVISION {instance_revision}",
        f"STYLE_REVISION {style_revision}",
        f"OWNER_PENDING_SCENE {owner_pending_scene}",
        "SNAPSHOT_FIELD FIELD label 81001 DRAFT_HEX 41 VERSION 3",
        "SNAPSHOT_FIELD END",
        "SNAPSHOT_STRUCTURE GENERATED_UI_STRUCTURE 1",
    ]
    for index in range(tree_nodes):
        lines.append(f"SNAPSHOT_STRUCTURE NODE 1 tree{index} label")
        lines.append(f"SNAPSHOT_STRUCTURE PROPERTY 1 tree{index} text node{index}")
    lines.append("SNAPSHOT_STRUCTURE END")
    lines.append("SNAPSHOT_INSTANCE INSTANCE edit element=root role=field id=812001 kind=textInput "
                 "semantic=edit field=label action=- visible=1 bounds=0,0,10,10 label_hex=41")
    lines.append("SNAPSHOT_STYLE STYLE panel_accent background=#e63333ff")
    lines.append("END")
    return "\n".join(lines)


def changes_body(*, stream_epoch: int = 1, endpoint_epoch: int = 7, since: int = 0, current: int = 0,
                 resync: bool = False, changes: tuple[tuple[int, str], ...] = ()) -> str:
    lines = [
        f"PROTOCOL {client.PROTOCOL}",
        "KIND GENERATED_UI_CHANGES",
        f"ENDPOINT_EPOCH {endpoint_epoch}",
        "ENDPOINT_INSTANCE test-endpoint",
        f"ENDPOINT_BIND_GENERATION {endpoint_epoch}",
        f"STREAM_EPOCH {stream_epoch}",
        "STREAM_IDENTITY session-1",
        f"SINCE {since}",
        f"CURRENT {current}",
        f"RESYNC_REQUIRED {1 if resync else 0}",
    ]
    for cursor, category in changes:
        lines.append(f"CHANGE {cursor} {category} detail")
    lines.append("END")
    return "\n".join(lines)


def section_body(section: str, *, cursor: int = 0, endpoint_epoch: int = 7,
                 revision_changed: bool = False) -> str:
    lines = [
        f"PROTOCOL {client.PROTOCOL}",
        "KIND GENERATED_UI_SECTION",
        f"ENDPOINT_EPOCH {endpoint_epoch}",
        "ENDPOINT_INSTANCE test-endpoint",
        f"ENDPOINT_BIND_GENERATION {endpoint_epoch}",
        f"SECTION {section}",
        "STREAM_EPOCH 1",
        "STREAM_IDENTITY session-1",
        f"CURSOR {cursor}",
        f"SNAPSHOT_REVISION_CHANGED {1 if revision_changed else 0}",
    ]
    if not revision_changed:
        if section == "FIELDS":
            lines.append("SNAPSHOT_FIELD FIELD label 81001 DRAFT_HEX 41 VERSION 9")
            lines.append("SNAPSHOT_FIELD END")
        elif section == "STRUCTURE":
            lines.append("SNAPSHOT_STRUCTURE NODE 0 root vertical")
            lines.append("SNAPSHOT_STRUCTURE END")
        elif section == "STYLES":
            lines.append("SNAPSHOT_STYLE STYLE panel_accent background=#e63333ff")
        else:
            lines.append("SNAPSHOT_INSTANCE INSTANCE edit element=root role=field id=812001")
    lines.append("END")
    return "\n".join(lines)


class ScriptedServer:
    def __init__(self, replies: list, endpoint_epoch: int = 7) -> None:
        self.replies = list(replies)
        self.requests: list[str] = []
        self.reply_bytes: list[int] = []
        self.reply_texts: list[str] = []
        self._directory = tempfile.TemporaryDirectory()
        directory = Path(self._directory.name)
        self.socket_path = directory / "operation.sock"
        self.descriptor_path = write_descriptor(directory, self.socket_path, endpoint_epoch)
        self._ready = threading.Event()
        self._stop = threading.Event()
        self._failures: list[BaseException] = []
        self._thread = threading.Thread(target=self._serve)
        self._thread.start()
        self._ready.wait(2.0)

    def _serve(self) -> None:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                listener.bind(os.fspath(self.socket_path))
                listener.listen(8)
                listener.settimeout(0.2)
                self._ready.set()
                while not self._stop.is_set():
                    try:
                        connection, _ = listener.accept()
                    except socket.timeout:
                        continue
                    with connection:
                        payload = read_framed(connection)
                        self.requests.append(payload)
                        reply = self.replies.pop(0) if self.replies else self.replies_last
                        if reply is None:
                            # Close the connection without answering: a real
                            # mid-read disconnect.
                            self.reply_bytes.append(0)
                            self.reply_texts.append("")
                            continue
                        if isinstance(reply, tuple):
                            reply, delay = reply
                            time.sleep(delay)
                        body = reply.encode("utf-8")
                        self.reply_bytes.append(len(body))
                        self.reply_texts.append(reply)
                        try:
                            connection.sendall(f"{len(body)}\n".encode("ascii") + body)
                        except (BrokenPipeError, ConnectionResetError):
                            # The client may legitimately have timed out on its own
                            # budget before this reply; that is the scenario under
                            # test, not a server failure.
                            pass
        except BaseException as exc:
            self._failures.append(exc)

    replies_last = changes_body()

    def close(self) -> None:
        self._stop.set()
        self._thread.join(2.0)
        self._directory.cleanup()
        if self._failures:
            raise self._failures[0]


class ObservationTests(unittest.TestCase):
    def test_snapshot_is_one_atomic_read(self) -> None:
        server = ScriptedServer([snapshot_body()])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            snapshot = session.snapshot()
            self.assertEqual(snapshot.stream_epoch, 1)
            self.assertEqual(snapshot.cursor, 0)
            self.assertEqual(snapshot.endpoint_epoch, 7)
            self.assertEqual(snapshot.owner_field_revision, 12)
            self.assertEqual(snapshot.owner_draft_revision, 3)
            self.assertEqual(snapshot.binding_revision, 21)
            self.assertEqual(snapshot.accepted_structure_version, 4)
            self.assertEqual(snapshot.window_accepted_scene_version, 44)
            self.assertEqual(snapshot.window_geometry_revision, 55)
            self.assertEqual(snapshot.window_interaction_revision, 66)
            self.assertFalse(snapshot.owner_pending_scene)
            self.assertIn("FIELD label 81001", snapshot.fields_text)
            self.assertIn("GENERATED_UI_STRUCTURE 1", snapshot.structure_text)
            self.assertIn("NODE 1 tree39 label", snapshot.structure_text)
            self.assertIn("INSTANCE edit", snapshot.instances_text)
            self.assertEqual(len(server.requests), 1)
            self.assertEqual(server.requests[0].split("\n")[2], "GET_GENERATED_UI_SNAPSHOT")
        finally:
            server.close()

    def test_unchanged_round_does_not_resend_the_tree(self) -> None:
        snapshot = snapshot_body(tree_nodes=200)
        server = ScriptedServer([snapshot, changes_body(since=0, current=0)])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            first = session.observe_once()
            second = session.observe_once()
            self.assertEqual(first.kind, "snapshot")
            self.assertEqual(second.kind, "none")
            self.assertIsNone(second.snapshot)
            self.assertFalse(second.changes.resync_required)
            self.assertEqual(len(server.requests), 2)
            self.assertEqual(server.requests[1].split("\n")[2], "GET_GENERATED_UI_CHANGES 1 0")
            # Measured, not extrapolated: the unchanged round's reply is much
            # smaller than the full snapshot's.
            self.assertLess(server.reply_bytes[1], server.reply_bytes[0] // 4)
            print(f"MEASURED snapshot_bytes={server.reply_bytes[0]} "
                  f"unchanged_round_bytes={server.reply_bytes[1]} "
                  f"tree_nodes=200")
        finally:
            server.close()

    def test_categories_separate_draft_and_resize_from_structure(self) -> None:
        server = ScriptedServer([
            snapshot_body(),
            changes_body(since=0, current=2, changes=((1, "FIELDS"), (2, "SCENE"))),
            section_body("FIELDS", cursor=2),
            section_body("INSTANCES", cursor=2),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            observed = session.observe_once()
            self.assertEqual(observed.kind, "changes")
            self.assertEqual([change.category for change in observed.changes.changes],
                             ["FIELDS", "SCENE"])
            self.assertEqual(observed.changes.current, 2)
            # The change reply never contains the tree.
            self.assertNotIn("NODE", server.reply_texts[1])
            self.assertIn("CHANGE 1 FIELDS", server.reply_texts[1])
        finally:
            server.close()

    def test_resync_takes_a_fresh_snapshot(self) -> None:
        server = ScriptedServer([
            snapshot_body(cursor=0),
            changes_body(since=0, current=9, resync=True),
            snapshot_body(cursor=9, structure_version=5, tree_nodes=3),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            resynced = session.observe_once()
            self.assertEqual(resynced.kind, "snapshot")
            self.assertEqual(resynced.snapshot.cursor, 9)
            self.assertEqual(resynced.snapshot.accepted_structure_version, 5)
            self.assertTrue(resynced.changes.resync_required)
            self.assertEqual(len(server.requests), 3)
            self.assertEqual(server.requests[2].split("\n")[2], "GET_GENERATED_UI_SNAPSHOT")
        finally:
            server.close()

    def test_replaced_stream_epoch_takes_a_fresh_snapshot(self) -> None:
        server = ScriptedServer([
            snapshot_body(stream_epoch=1),
            changes_body(stream_epoch=2, since=0, current=0),
            snapshot_body(stream_epoch=2, cursor=0, tree_nodes=2),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            observed = session.observe_once()
            self.assertEqual(observed.kind, "snapshot")
            self.assertEqual(observed.snapshot.stream_epoch, 2)
        finally:
            server.close()

    def test_changed_round_rereads_only_the_affected_sections(self) -> None:
        server = ScriptedServer([
            snapshot_body(cursor=0),
            changes_body(since=0, current=2, changes=((1, "FIELDS"), (2, "SCENE"))),
            section_body("FIELDS", cursor=2),
            section_body("INSTANCES", cursor=2),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            observed = session.observe_once()
            self.assertEqual(observed.kind, "changes")
            self.assertIsNone(observed.snapshot)
            self.assertEqual(sorted(observed.sections), ["FIELDS", "INSTANCES"])
            self.assertIn("FIELD label 81001", observed.sections["FIELDS"])
            self.assertIn("INSTANCE edit", observed.sections["INSTANCES"])
            # The structure was NOT re-read: only the affected sections were.
            request_lines = [payload.split("\n")[2] for payload in server.requests]
            self.assertEqual(request_lines, [
                "GET_GENERATED_UI_SNAPSHOT",
                "GET_GENERATED_UI_CHANGES 1 0",
                "GET_GENERATED_UI_SECTION FIELDS 2",
                "GET_GENERATED_UI_SECTION INSTANCES 2",
            ])
            for text in server.reply_texts[1:]:
                self.assertNotIn("SNAPSHOT_STRUCTURE", text)
            print(f"MEASURED changed_round_bytes={server.reply_bytes[1]} "
                  f"section_bytes={server.reply_bytes[2]} + {server.reply_bytes[3]} "
                  f"snapshot_bytes={server.reply_bytes[0]}")
        finally:
            server.close()

    def test_style_directory_change_rereads_only_style_definitions(self) -> None:
        server = ScriptedServer([
            snapshot_body(cursor=0, style_revision=0),
            changes_body(since=0, current=1, changes=((1, "STYLES"),)),
            section_body("STYLES", cursor=1),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            first = session.observe_once()
            self.assertIsNotNone(first.snapshot)
            self.assertEqual(first.snapshot.style_revision, 0)
            self.assertIn("STYLE panel_accent", first.snapshot.styles_text)
            observed = session.observe_once()
            self.assertEqual(observed.kind, "changes")
            # A style-directory change invalidates ONLY the definitions; the tree
            # and instances the client already holds are still current.
            self.assertEqual(sorted(observed.sections), ["STYLES"])
            self.assertIn("STYLE panel_accent", observed.sections["STYLES"])
            request_lines = [payload.split("\n")[2] for payload in server.requests]
            self.assertEqual(request_lines, [
                "GET_GENERATED_UI_SNAPSHOT",
                "GET_GENERATED_UI_CHANGES 1 0",
                "GET_GENERATED_UI_SECTION STYLES 1",
            ])
            for text in server.reply_texts[1:]:
                self.assertNotIn("SNAPSHOT_STRUCTURE", text)
        finally:
            server.close()

    def test_seeded_cursor_skips_the_snapshot_read(self) -> None:
        server = ScriptedServer([
            changes_body(since=0, current=1, changes=((1, "FIELDS"),)),
            section_body("FIELDS", cursor=1),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            # A cursor observed in an earlier session/process: the poller reads
            # only the increment, never another full snapshot.
            session.seed_cursor(1, 0)
            observed = session.observe_once()
            self.assertEqual(observed.kind, "changes")
            self.assertEqual(observed.changes.current, 1)
            self.assertIn("FIELD label 81001", observed.sections["FIELDS"])
            self.assertEqual([payload.split("\n")[2] for payload in server.requests],
                             ["GET_GENERATED_UI_CHANGES 1 0", "GET_GENERATED_UI_SECTION FIELDS 1"])
        finally:
            server.close()

    def test_moved_section_cursor_forces_a_fresh_snapshot(self) -> None:
        server = ScriptedServer([
            snapshot_body(cursor=0),
            changes_body(since=0, current=2, changes=((1, "FIELDS"), (2, "FIELDS"))),
            section_body("FIELDS", cursor=2, revision_changed=True),
            snapshot_body(cursor=2, structure_version=4, tree_nodes=3),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            observed = session.observe_once()
            # A section that moved invalidates the whole local stitch: the poller
            # takes a fresh snapshot instead of mixing cursors.
            self.assertEqual(observed.kind, "snapshot")
            self.assertEqual(observed.snapshot.cursor, 2)
            self.assertIsNone(observed.sections)
            self.assertEqual(len(server.requests), 4)
            self.assertEqual(server.requests[3].split("\n")[2], "GET_GENERATED_UI_SNAPSHOT")
        finally:
            server.close()

    def test_unknown_section_is_refused_locally(self) -> None:
        server = ScriptedServer([])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            with self.assertRaises(generated.GeneratedUiError):
                session.section("SECRETS", 0)
            # The refusal is local: no request reached the endpoint.
            self.assertEqual(server.requests, [])
        finally:
            server.close()

    def test_changed_endpoint_epoch_is_an_endpoint_error(self) -> None:
        server = ScriptedServer([
            snapshot_body(endpoint_epoch=7),
            changes_body(endpoint_epoch=8, since=0, current=0),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            with self.assertRaises(generated.GeneratedUiEndpointError) as raised:
                session.observe_once()
            self.assertEqual(raised.exception.code, "endpoint_replaced")
        finally:
            server.close()


class PartialReadTests(unittest.TestCase):
    def test_partial_section_failure_keeps_the_anchor_and_recovers(self) -> None:
        # FIELDS is delivered, then the socket closes on the INSTANCES read. The
        # anchor must stay at 0, and the retry must return the SAME increment
        # with BOTH sections instead of reporting "no change".
        server = ScriptedServer([
            snapshot_body(cursor=0),
            changes_body(since=0, current=3, changes=((1, "FIELDS"), (3, "SCENE"))),
            section_body("FIELDS", cursor=3),
            None,
            changes_body(since=0, current=3, changes=((1, "FIELDS"), (3, "SCENE"))),
            section_body("FIELDS", cursor=3),
            section_body("INSTANCES", cursor=3),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            self.assertEqual(session.observation_anchor().cursor, 0)
            with self.assertRaises(generated.GeneratedUiEndpointError):
                session.observe_once()
            # The failed round must not have advanced the anchor.
            self.assertEqual(session.observation_anchor().cursor, 0)
            recovered = session.observe_once()
            self.assertEqual(recovered.kind, "changes")
            self.assertEqual(session.observation_anchor().cursor, 3)
            self.assertEqual(sorted(recovered.sections), ["FIELDS", "INSTANCES"])
            self.assertIn("FIELD label", recovered.sections["FIELDS"])
            self.assertIn("INSTANCE edit", recovered.sections["INSTANCES"])
            # The retry re-read the same increment from the SAME cursor.
            self.assertEqual(server.requests[4].split("\n")[2], "GET_GENERATED_UI_CHANGES 1 0")
        finally:
            server.close()

    def test_section_for_another_stream_is_rejected(self) -> None:
        server = ScriptedServer([
            snapshot_body(cursor=0),
            changes_body(since=0, current=1, changes=((1, "FIELDS"),)),
            section_body("FIELDS", cursor=1),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            # A section that reports another stream epoch is not stitched even if
            # the revision flag stayed 0.
            bad = section_body("FIELDS", cursor=1).replace("STREAM_EPOCH 1", "STREAM_EPOCH 99")
            server.replies.insert(0, bad)
            with self.assertRaises(generated.GeneratedUiError):
                session.observe_once()
            self.assertEqual(session.observation_anchor().cursor, 0)
        finally:
            server.close()


class ChangeContinuityTests(unittest.TestCase):
    """A non-resync increment must be continuous against its OWN declared cursor.

    A reply that declares CURRENT has advanced but omits changes, or carries an
    unknown category, is refused: the anchor must not advance past content that
    was never delivered, so a retry re-reads the SAME increment.
    """

    def test_missing_tail_change_is_refused_and_anchor_stays(self) -> None:
        # CURRENT is 2 but the only change stops at 1: the change for cursor 2
        # was dropped. The round must be refused, not committed as "moved to 2".
        server = ScriptedServer([
            snapshot_body(cursor=0),
            changes_body(since=0, current=2, changes=((1, "FIELDS"),)),
            changes_body(since=0, current=2, changes=((1, "FIELDS"), (2, "SCENE"))),
            section_body("FIELDS", cursor=2),
            section_body("INSTANCES", cursor=2),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            self.assertEqual(session.observation_anchor().cursor, 0)
            with self.assertRaises(generated.GeneratedUiProtocolError) as raised:
                session.observe_once()
            self.assertEqual(raised.exception.code, "change_tail_not_current")
            # The refusal must not advance the anchor, so the retry re-reads from
            # the same cursor and this time receives the complete increment.
            self.assertEqual(session.observation_anchor().cursor, 0)
            recovered = session.observe_once()
            self.assertEqual(recovered.kind, "changes")
            self.assertEqual([change.category for change in recovered.changes.changes],
                             ["FIELDS", "SCENE"])
            self.assertEqual(session.observation_anchor().cursor, 2)
            self.assertEqual(server.requests[1].split("\n")[2], "GET_GENERATED_UI_CHANGES 1 0")
            self.assertEqual(server.requests[2].split("\n")[2], "GET_GENERATED_UI_CHANGES 1 0")
        finally:
            server.close()

    def test_empty_changes_with_moved_current_is_refused(self) -> None:
        # An empty increment is honest only when CURRENT did not move; here the
        # declared cursor jumped from 0 to 5 with no change to justify it.
        server = ScriptedServer([
            snapshot_body(cursor=0),
            changes_body(since=0, current=5, changes=()),
            changes_body(since=0, current=0),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            with self.assertRaises(generated.GeneratedUiProtocolError) as raised:
                session.observe_once()
            self.assertEqual(raised.exception.code, "empty_changes_current_moved")
            self.assertEqual(session.observation_anchor().cursor, 0)
            # The retry re-reads the SAME cursor and reports an honest no-change.
            unchanged = session.observe_once()
            self.assertEqual(unchanged.kind, "none")
            self.assertEqual(session.observation_anchor().cursor, 0)
            self.assertEqual(server.requests[1].split("\n")[2], "GET_GENERATED_UI_CHANGES 1 0")
            self.assertEqual(server.requests[2].split("\n")[2], "GET_GENERATED_UI_CHANGES 1 0")
        finally:
            server.close()

    def test_unknown_change_category_is_refused_then_recovers(self) -> None:
        # A category the client cannot map to a section must never be silently
        # skipped while the anchor advances; the round is refused instead.
        server = ScriptedServer([
            snapshot_body(cursor=0),
            changes_body(since=0, current=1, changes=((1, "TELEPORT"),)),
            changes_body(since=0, current=1, changes=((1, "FIELDS"),)),
            section_body("FIELDS", cursor=1),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            session.observe_once()
            with self.assertRaises(generated.GeneratedUiProtocolError) as raised:
                session.observe_once()
            self.assertEqual(raised.exception.code, "unknown_change_category")
            self.assertEqual(session.observation_anchor().cursor, 0)
            # A subsequent valid round recovers exactly at the same cursor.
            recovered = session.observe_once()
            self.assertEqual(recovered.kind, "changes")
            self.assertEqual([change.category for change in recovered.changes.changes], ["FIELDS"])
            self.assertIn("FIELD label 81001", recovered.sections["FIELDS"])
            self.assertEqual(session.observation_anchor().cursor, 1)
            self.assertEqual(server.requests[1].split("\n")[2], "GET_GENERATED_UI_CHANGES 1 0")
            self.assertEqual(server.requests[2].split("\n")[2], "GET_GENERATED_UI_CHANGES 1 0")
        finally:
            server.close()


class CandidateWaitTypologyTests(unittest.TestCase):
    def _ticket(self) -> "generated.GeneratedCandidateTicket":
        return generated.GeneratedCandidateTicket(
            4, "generated-ui-candidate-4",
            generated.GeneratedEndpointIdentity("test-endpoint", 7), 3, 4)

    def test_zero_budget_makes_no_request(self) -> None:
        server = ScriptedServer([])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            result = session.wait_for_candidate_result(self._ticket(), timeout_ms=0)
            self.assertEqual(result.outcome, "timeout_without_observation")
            self.assertIsNone(result.last_state)
            self.assertEqual(result.attempted, 0)
            self.assertEqual(server.requests, [])
        finally:
            server.close()

    def test_pending_then_deadline_returns_last_pending(self) -> None:
        pending = candidate_reply(4, terminal="PENDING", scene="candidate_received", pending=4)
        server = ScriptedServer([pending] * 50)
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            result = session.wait_for_candidate_result(self._ticket(), timeout_ms=150, poll_ms=20)
            self.assertEqual(result.outcome, "timeout")
            self.assertIsNotNone(result.last_state)
            self.assertEqual(result.last_state.terminal_state, "PENDING")
            self.assertGreaterEqual(result.attempted, 1)
        finally:
            server.close()

    def test_late_terminal_answer_is_still_a_timeout(self) -> None:
        pending = candidate_reply(4, terminal="PENDING", scene="candidate_received", pending=4)
        accepted = candidate_reply(4, terminal="ACCEPTED", scene="scene_accepted",
                                   accepted_version=4, current_accepted=4)
        # PENDING arrives in budget; the terminal ACCEPTED arrives only AFTER the
        # budget. The wait reports a timeout with the last PENDING and must not
        # publish the late ACCEPTED as an on-time terminal result.
        server = ScriptedServer([pending, (accepted, 0.8)])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            result = session.wait_for_candidate_result(self._ticket(), timeout_ms=250, poll_ms=20)
            self.assertEqual(result.outcome, "timeout")
            self.assertIsNotNone(result.last_state)
            self.assertEqual(result.last_state.terminal_state, "PENDING")
        finally:
            server.close()

    def test_ticket_from_another_endpoint_is_refused(self) -> None:
        server = ScriptedServer([
            snapshot_body(),
            candidate_reply(4, terminal="ACCEPTED", scene="scene_accepted",
                            accepted_version=4, current_accepted=4, endpoint_epoch=9),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            # Learn the session's endpoint identity from a snapshot first.
            session.snapshot()
            result = session.wait_for_candidate_result(self._ticket(), timeout_ms=500, poll_ms=10)
            self.assertEqual(result.outcome, "endpoint_replaced")
            self.assertIsNone(result.last_state)
        finally:
            server.close()

    def test_rejected_terminal_keeps_its_reason(self) -> None:
        rejected = candidate_reply(4, terminal="REJECTED", scene="candidate_rejected",
                                   reason="structure_version_conflict")
        server = ScriptedServer([rejected])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            result = session.wait_for_candidate_result(self._ticket(), timeout_ms=500, poll_ms=10)
            self.assertEqual(result.outcome, "terminal")
            self.assertEqual(result.last_state.terminal_state, "REJECTED")
            self.assertEqual(result.last_state.reason, "structure_version_conflict")
        finally:
            server.close()


if __name__ == "__main__":
    unittest.main()
