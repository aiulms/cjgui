import importlib.util
from dataclasses import dataclass, replace
from pathlib import Path
from types import SimpleNamespace
import sys
import tomllib
import unittest

def locate_shared_operation_core(test_file):
    test_dir = Path(test_file).resolve().parent
    manifest = test_dir / "cjpm.toml"
    if manifest.is_file():
        dependencies = tomllib.loads(manifest.read_text(encoding="utf-8")).get("dependencies", {})
        candidates = []
        app_dependency = dependencies.get("cjgui", {}).get("path")
        if app_dependency and "__CJGUI_FRAMEWORK_RELATIVE_PATH__" not in app_dependency:
            candidates.append((test_dir / app_dependency / "shared_operation_core").resolve())
        core_dependency = dependencies.get("cjgui_shared_operation_core", {}).get("path")
        if core_dependency and "__CJGUI_FRAMEWORK_RELATIVE_PATH__" not in core_dependency:
            candidates.append((test_dir / core_dependency).resolve())
        for candidate in candidates:
            if (candidate / "cjgui_generated_client.py").is_file():
                return candidate

    # Source templates still carry a framework-path placeholder. Find the
    # actual runtime ancestor by its core module, rather than assuming a fixed
    # repository depth or an author's checkout path.
    for ancestor in (test_dir, *test_dir.parents):
        candidate = ancestor / "shared_operation_core"
        if (candidate / "cjgui_generated_client.py").is_file():
            return candidate
    raise RuntimeError(f"cannot locate shared_operation_core for {test_file}")


CORE = locate_shared_operation_core(__file__)
sys.path.insert(0, str(CORE))
SPEC = importlib.util.spec_from_file_location(
    "mixed_form_client", Path(__file__).with_name("client.py"))
CLIENT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CLIENT)


@dataclass(frozen=True)
class Field:
    field_id: str
    resource_id: int
    applied: str
    draft: str
    validation_error: str
    focused: object
    selection_start: object
    selection_end: object
    draft_version: int
    available: bool
    blocked_reason: object
    owner_resource_id: int
    state_version: int
    validation_state: str
    validation_version: int
    field_version: int


@dataclass(frozen=True)
class Action:
    name: str
    available: bool
    blocked_reason: object
    owner_resource_id: int
    state_version: int


@dataclass(frozen=True)
class Invocation:
    action: str
    targets: tuple
    arguments: tuple
    expected_version: int


def owner(owner_id, applied, draft, *, draft_version, applied_version):
    fields = tuple(Field(
        name, resource, old, new, "", None, None, None,
        draft_version, True, None, owner_id, 7, "valid", 7, 3)
        for name, resource, old, new in zip(
            ("jobName", "copies", "duplex"), (6201, 6202, 6203), applied, draft))
    actions = (
        Action("APPLY_DRAFT", True, None, owner_id, 7),
        Action("CANCEL_DRAFT", True, None, owner_id, 7))
    return SimpleNamespace(known=True, consistent=True, owner_resource_id=owner_id,
                           state_version=7, draft_version=draft_version,
                           applied_version=applied_version, fields=fields, actions=actions)


class FakeSession:
    def __init__(self, states):
        self.states = states
        self.calls = []
        self.client = SimpleNamespace(descriptor={
            "endpoint_instance": "new-process-instance",
            "endpoint_bind_generation": 4,
        })

    def form_state(self, *, instance_key):
        return self.states[instance_key]

    def snapshot(self):
        return SimpleNamespace(endpoint=SimpleNamespace(instance="new-process-instance",
                                                        bind_generation=4))

    def invoke_action(self, action, targets, arguments, *, expected_version):
        call = Invocation(action, tuple(targets), tuple(arguments), expected_version)
        self.calls.append(call)
        return call


class WorkSessionReadbackTests(unittest.TestCase):
    def test_readback_reports_both_owner_baselines_versions_dirty_and_endpoint(self):
        session = FakeSession({
            "cardA": owner(6301, ("资料 A", "4", "false"), ("A 草稿", "4", "false"),
                           draft_version=8, applied_version=7),
            "cardB": owner(6302, ("B 已应用", "2", "true"), ("B 已应用", "2", "true"),
                           draft_version=5, applied_version=5),
        })

        result = CLIENT.work_session_owner_readback(session)

        self.assertEqual(result["endpoint"], {
            "instance": "new-process-instance", "bind_generation": 4})
        self.assertEqual(result["owners"]["cardA"]["owner_resource_id"], 6301)
        self.assertEqual(result["owners"]["cardA"]["draft_version"], 8)
        self.assertEqual(result["owners"]["cardA"]["applied_version"], 7)
        self.assertTrue(result["owners"]["cardA"]["dirty"])
        self.assertEqual(result["owners"]["cardA"]["fields"][0]["applied"], "资料 A")
        self.assertEqual(result["owners"]["cardA"]["fields"][0]["draft"], "A 草稿")
        self.assertFalse(result["owners"]["cardB"]["dirty"])

    def test_readback_preserves_collection_actions_without_binding_them_to_card_owner(self):
        card_a = owner(6301, ("资料 A", "4", "false"), ("A 草稿", "4", "false"),
                       draft_version=8, applied_version=7)
        collection_actions = (
            Action("SELECT_CARD", True, None, -1, 0),
            Action("ADD_CARD", True, None, -1, 0),
            Action("DELETE_CARD", False, "minimum_cards", -1, 0),
            Action("FUTURE_COLLECTION_ACTION", True, None, -1, 0),
        )
        card_a = SimpleNamespace(**{
            **vars(card_a), "actions": card_a.actions + collection_actions})
        card_b = owner(6302, ("B 已应用", "2", "true"), ("B 已应用", "2", "true"),
                       draft_version=5, applied_version=5)

        result = CLIENT.work_session_owner_readback(FakeSession({
            "cardA": card_a, "cardB": card_b}))

        actions = result["owners"]["cardA"]["actions"]
        self.assertEqual([action["name"] for action in actions], [
            "APPLY_DRAFT", "CANCEL_DRAFT", "SELECT_CARD", "ADD_CARD", "DELETE_CARD",
            "FUTURE_COLLECTION_ACTION"])
        self.assertTrue(all(action["owner_resource_id"] == -1 for action in actions[2:]))
        self.assertTrue(all(action["state_version"] == 0 for action in actions[2:]))

        bad_apply = replace(card_a.actions[0], owner_resource_id=6302)
        bad_card_a = SimpleNamespace(**{
            **vars(card_a), "actions": (bad_apply,) + card_a.actions[1:]})
        with self.assertRaises(AssertionError):
            CLIENT.work_session_owner_readback(FakeSession({
                "cardA": bad_card_a, "cardB": card_b}))

    def test_readback_refuses_incomplete_or_misidentified_owner_state(self):
        incomplete = owner(6301, ("资料 A", "4", "false"), ("A 草稿", "4", "false"),
                           draft_version=8, applied_version=7)
        incomplete = SimpleNamespace(**{**vars(incomplete), "consistent": False})
        session = FakeSession({"cardA": incomplete, "cardB": incomplete})
        with self.assertRaises(AssertionError):
            CLIENT.work_session_owner_readback(session)

        valid = owner(6301, ("资料 A", "4", "false"), ("A 草稿", "4", "false"),
                      draft_version=8, applied_version=7)
        mismatched_field = replace(valid.fields[0], owner_resource_id=6302)
        mismatched = SimpleNamespace(**{
            **vars(valid), "fields": (mismatched_field,) + valid.fields[1:]})
        with self.assertRaises(AssertionError):
            CLIENT.work_session_owner_readback(FakeSession({"cardA": mismatched,
                                                           "cardB": valid}))

    def test_public_client_continues_with_owner_cas_then_apply_and_cancel(self):
        state = owner(6301, ("资料 A", "4", "false"), ("恢复草稿", "7", "true"),
                      draft_version=8, applied_version=7)
        session = FakeSession({"cardA": state})
        capabilities = SimpleNamespace(fields=(SimpleNamespace(
            field_id="jobName", writer="EDIT_DRAFT_TEXT", editor_kind="TEXT", argument="text"),))

        CLIENT.execute_work_session_card_action(
            session, capabilities, "cardA", "card-set", field_id="jobName", value="继续编辑")
        CLIENT.execute_work_session_card_action(session, capabilities, "cardA", "card-apply")
        CLIENT.execute_work_session_card_action(session, capabilities, "cardA", "card-cancel")

        self.assertEqual([call.action for call in session.calls],
                         ["EDIT_DRAFT_TEXT", "APPLY_DRAFT", "CANCEL_DRAFT"])
        self.assertEqual([call.targets for call in session.calls], [(6301,), (6301,), (6301,)])
        self.assertTrue(all(call.expected_version == 7 for call in session.calls))
        self.assertEqual(session.calls[0].arguments[0].value, 8)
        self.assertEqual(session.calls[0].arguments[1].value, "jobName")
        self.assertEqual(session.calls[0].arguments[2].value, "继续编辑")


if __name__ == "__main__":
    unittest.main()
