"""Runner contracts with fake compilers; these do not claim Linux GUI coverage."""
from contextlib import redirect_stderr, redirect_stdout
import fcntl
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "linux_application.py"
spec = importlib.util.spec_from_file_location("linux_application", SCRIPT)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class LinuxApplicationContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="CJGUI Linux paths with spaces ")
        self.root = Path(self.temp.name)
        self.framework = self.root / "framework"
        self.application = self.root / "ordinary app"
        self.output = self.application / ".cjgui/linux"
        self.tools = self.root / "tool chain"
        self.tools.mkdir()
        self.write(self.framework / "cjpm.toml", '''[package]
name="cjgui"
version="0.0.0"
output-type="static"
src-dir="src"
link-option="-framework AppKit -lobjc"
[dependencies]
cjgui_shared_operation_core={path="shared_operation_core"}
[ffi.c]
cjgui_internal_renderer={path="native/lib"}
''')
        self.write(self.framework / "src/core.cj", "package cjgui\npublic let fixture = 1\n")
        self.write(self.framework / "src/core_test.cj", "not a production input")
        self.write(self.framework / "shared_operation_core/cjpm.toml", '''[package]
name="cjgui_shared_operation_core"
version="0.0.0"
output-type="static"
src-dir="src"
''')
        self.write(self.framework / "shared_operation_core/src/core.cj", "package cjgui_shared_operation_core\n")
        self.write(self.framework / "native/cjgui_internal_renderer.h", "/* header v1 */\n")
        self.write(self.framework / "platforms/linux/native/part.c", "int fixture(void){return 1;}\n")
        self.write(self.framework / "platforms/linux/native/part.h", "/* companion header */\n")
        self.write(self.application / "cjpm.toml", '''[package]
name="ordinary_consumer"
version="0.0.0"
output-type="executable"
src-dir="src"
link-option="-framework AppKit -lobjc"
[dependencies]
cjgui={path="../framework"}
cjgui_shared_operation_core={path="../framework/shared_operation_core"}
[ffi.c]
cjgui_internal_renderer={path=".cjgui/native/lib"}
cjgui_macos_application_launcher={path=".cjgui/native/lib"}
''')
        self.write(self.application / "src/main.cj", "package ordinary_consumer\nmain(): Int64 {return 0}\n")
        self.write(self.framework / "native/lib/keep", "other consumer's archive")
        self.env_file = self.tools / "envsetup.sh"
        self.write(self.env_file, 'export PATH=' + runner.shlex.quote(str(self.tools)) + ':"$PATH"\n')
        self.executable("pkg-config", "print('-I/fixture/include' if '--cflags' in sys.argv else '-lfixture')")
        self.executable("cc", '''
if '--version' in sys.argv: print('fake cc 1'); sys.exit(0)
if '-print-libgcc-file-name' in sys.argv: print('/fixture/gcc/libgcc.a'); sys.exit(0)
Path(sys.argv[sys.argv.index('-o')+1]).write_bytes(b'object')
p=Path(os.environ['CC_COUNT']); p.write_text(p.read_text()+'x' if p.exists() else 'x')
''')
        self.executable("ar", "Path(sys.argv[2]).write_bytes(b'archive')")
        # Native flock is exercised on Linux. Host-only fake-tool tests still
        # use the real fcntl output lock, including the busy preparation case.
        if shutil.which("flock") is None:
            self.executable("flock", "sys.exit(0)")
        self.executable("cjpm", '''
if '--version' in sys.argv: print('fake cjpm 1.1.3'); sys.exit(0)
if os.environ.get('FAKE_CJPM_SLEEP'):
    open(os.environ['FAKE_CJPM_PID'],'w').write(str(os.getpid()))
    if os.environ.get('FAKE_CJPM_IGNORE_TERM'):
        import signal; signal.signal(signal.SIGTERM, signal.SIG_IGN)
    import time; time.sleep(60); sys.exit(0)
if os.environ.get('FAKE_EOF_SLEEP'):
    open(os.environ['FAKE_EOF_PID'],'w').write(str(os.getpid()))
    os.close(1)
    import time; time.sleep(60); sys.exit(0)
if os.environ.get('FAKE_BUILD_FAIL'): print('link failed without undeclared symbols'); sys.exit(23)
if os.environ.get('FAKE_NO_BINARY'): sys.exit(0)
if os.environ.get('FAKE_LEADER_PID'): open(os.environ['FAKE_LEADER_PID'],'w').write(str(os.getpid()))
if os.environ.get('FAKE_GRANDCHILD'):
    import subprocess, time
    subprocess.Popen([sys.executable, '-c',
        'import os,signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); '
        'open(os.environ["FAKE_GRANDCHILD_PID"],"w").write(str(os.getpid())); time.sleep(60)'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(200):
        if os.path.exists(os.environ['FAKE_GRANDCHILD_PID']): break
        time.sleep(0.01)
import tomllib
d=tomllib.loads(Path('cjpm.toml').read_text()); p=Path(d['package']['target-dir'])/'release/bin/main'
p.parent.mkdir(parents=True,exist_ok=True)
p.write_text('#!'+sys.executable+"""
import os, signal, sys, time
if os.environ.get('FAKE_CHILD_PID'): open(os.environ['FAKE_CHILD_PID'],'w').write(str(os.getpid()))
if os.environ.get('FAKE_IGNORE_TERM'): signal.signal(signal.SIGTERM, signal.SIG_IGN)
if os.environ.get('FAKE_SLEEP'): time.sleep(60)
print("fresh compiled ordinary consumer")
sys.exit(17)
"""); p.chmod(0o755)
''')
        self.environment = patch.dict(os.environ, {"CJGUI_LINUX_CC": str(self.tools / "cc"),
            "CJGUI_LINUX_AR": str(self.tools / "ar"), "CC_COUNT": str(self.root / "cc-count")})
        self.environment.start()
        self.system = patch.object(runner.platform, "system", return_value="Linux")
        self.system.start()

    def tearDown(self):
        self.system.stop()
        self.environment.stop()
        self.temp.cleanup()

    def write(self, path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def executable(self, name, code):
        path = self.tools / name
        self.write(path, "#!" + sys.executable + "\nimport sys,os\nfrom pathlib import Path\n" + code + "\n")
        path.chmod(0o755)

    def invoke(self, action, *extra, app=None, output=None):
        args = [action, "--output", str(output or self.output)]
        if action in ("build", "diagnose"):
            args += ["--app", str(app or self.application), "--framework", str(self.framework),
                     "--toolchain", str(self.env_file)]
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            return runner.main(args + list(extra))

    def wait_for_pid(self, path, timeout=10):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if path.exists():
                text = path.read_text().strip()
                if text: return int(text)
            time.sleep(0.05)
        self.fail(f"pid file was not written: {path}")

    def assert_process_gone(self, pid):
        for _ in range(60):
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                return
            time.sleep(0.05)
        self.fail(f"child process still alive: {pid}")

    def assert_lock_free(self, output=None):
        with (Path(output or self.output) / ".lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            fcntl.flock(lock, fcntl.LOCK_UN)

    def test_explicit_build_isolated_paths_and_true_run_exit(self):
        before = {p: p.read_bytes() for p in [self.framework / "cjpm.toml", self.application / "cjpm.toml",
                                             self.framework / "native/lib/keep"]}
        self.assertEqual(self.invoke("build"), 0)
        receipt = json.loads((self.output / "build-receipt.json").read_text())
        self.assertEqual(receipt["application"], str(self.application.resolve()))
        self.assertEqual(self.invoke("run"), 17)
        self.assertTrue((self.output / "native/lib/libcjgui_internal_renderer.a").exists())
        for path, data in before.items(): self.assertEqual(path.read_bytes(), data)
        for path in (self.output / "inputs").rglob("cjpm.toml"):
            self.assertNotIn("-framework", path.read_text())
            self.assertNotIn("cjgui_macos_application_launcher", path.read_text())
        self.assertFalse(list((self.output / "inputs").rglob("*_test.cj")))

    def test_failed_build_invalidates_old_run_even_without_undeclared_errors(self):
        self.assertEqual(self.invoke("build"), 0)
        with patch.dict(os.environ, {"FAKE_BUILD_FAIL": "1"}):
            self.assertEqual(self.invoke("diagnose"), 23)
        self.assertFalse((self.output / "build-receipt.json").exists())
        self.assertNotEqual(self.invoke("run"), 0)
        diagnostic = json.loads((self.output / "closure-diagnostic.json").read_text())
        self.assertEqual(diagnostic["exit_code"], 23)
        self.assertEqual(diagnostic["undeclared"], [])
        self.assertFalse(diagnostic["build_succeeded"])

    def test_zero_exit_without_fresh_binary_is_not_success(self):
        self.assertEqual(self.invoke("build"), 0)
        with patch.dict(os.environ, {"FAKE_NO_BINARY": "1"}):
            self.assertNotEqual(self.invoke("build"), 0)
        self.assertNotEqual(self.invoke("run"), 0)

    def test_build_stops_ignoring_grandchild_before_releasing_lock(self):
        leader_file, pid_file = self.root / "leader.pid", self.root / "grandchild.pid"
        result = {}
        with patch.dict(os.environ, {"FAKE_GRANDCHILD": "1", "FAKE_LEADER_PID": str(leader_file),
                                     "FAKE_GRANDCHILD_PID": str(pid_file)}):
            thread = threading.Thread(target=lambda: result.setdefault("code", self.invoke("build")))
            thread.start()
            leader = self.wait_for_pid(leader_file)
            grandchild = self.wait_for_pid(pid_file)
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                try:
                    os.kill(leader, 0)
                except ProcessLookupError:
                    break
                time.sleep(0.05)
            else:
                self.fail("compiler leader did not exit")
            # The leader is gone while its TERM-ignoring descendant still lives;
            # the runner must keep the output lock until the whole group is gone.
            os.kill(grandchild, 0)
            with (self.output / ".lock").open("a") as lock:
                with self.assertRaises(BlockingIOError):
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            thread.join(20)
            self.assertFalse(thread.is_alive())
        self.assertEqual(result.get("code"), 0)
        self.assert_process_gone(grandchild)
        self.assert_lock_free()

    def test_lock_covers_preparation_and_keeps_receipt_when_busy(self):
        self.assertEqual(self.invoke("build"), 0)
        before = (self.output / "build-receipt.json").read_bytes()
        with (self.output / ".lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertNotEqual(self.invoke("build"), 0)
        self.assertEqual((self.output / "build-receipt.json").read_bytes(), before)

    def test_two_apps_do_not_share_native_or_target_and_header_content_invalidates(self):
        self.assertEqual(self.invoke("build"), 0)
        count = (self.root / "cc-count").read_text()
        self.assertEqual(self.invoke("build"), 0)
        self.assertEqual((self.root / "cc-count").read_text(), count)
        header = self.framework / "platforms/linux/native/part.h"
        old_stat = header.stat(); header.write_text("/* changed same mtime */\n")
        os.utime(header, ns=(old_stat.st_atime_ns, old_stat.st_mtime_ns))
        self.assertEqual(self.invoke("build"), 0)
        self.assertGreater(len((self.root / "cc-count").read_text()), len(count))
        other = self.root / "second app"
        self.write(other / "cjpm.toml", (self.application / "cjpm.toml").read_text())
        self.write(other / "src/main.cj", (self.application / "src/main.cj").read_text())
        other_output = other / ".cjgui/linux"
        self.assertEqual(self.invoke("build", app=other, output=other_output), 0)
        self.assertNotEqual((self.output / "native/lib").resolve(), (other_output / "native/lib").resolve())
        self.assertTrue((self.output / "target/release/bin/main").exists())
        self.assertTrue((other_output / "target/release/bin/main").exists())

    def test_source_change_refuses_stale_run_and_clean_preserves_usable_binary(self):
        self.assertEqual(self.invoke("build"), 0)
        self.assertEqual(self.invoke("clean"), 0)
        self.assertFalse((self.output / "target").exists())
        self.assertEqual(self.invoke("run"), 17)
        self.write(self.application / "src/main.cj", "changed input")
        self.assertNotEqual(self.invoke("run"), 0)

    def test_unknown_output_is_not_deleted_and_invalid_toolchain_revokes_receipt(self):
        self.output.mkdir(parents=True)
        keep = self.output / "user-file"; keep.write_text("keep")
        self.assertNotEqual(self.invoke("build"), 0)
        self.assertEqual(keep.read_text(), "keep")
        keep.unlink()
        self.assertEqual(self.invoke("build"), 0)
        self.env_file.unlink()
        self.assertNotEqual(self.invoke("build"), 0)
        self.assertNotEqual(self.invoke("run"), 0)

    def test_unindexed_source_cannot_sneak_into_compilation(self):
        self.assertEqual(self.invoke("build"), 0)
        self.write(self.output / "inputs/packages/framework/src/foreign.cj", "unowned input")
        self.assertNotEqual(self.invoke("build"), 0)
        self.assertNotEqual(self.invoke("run"), 0)

    def test_optional_ssh_quotes_paths_and_returns_real_remote_exit(self):
        args = ["--guest", "user@example.test", "--", "build", "--app", "/app with spaces/$literal", "--output", "/output"]
        with patch.object(runner.subprocess, "run") as process:
            process.return_value.returncode = 29
            self.assertEqual(runner.ssh_transport(args), 29)
            call = process.call_args
            self.assertIn("'/app with spaces/$literal'", call.args[0][-1])
            self.assertIsInstance(call.kwargs["input"], bytes)

    def test_run_sigterm_waits_for_child_before_unlocking(self):
        self.assertEqual(self.invoke("build"), 0)
        pid_file = self.root / "child.pid"
        environment = {"FAKE_SLEEP": "1", "FAKE_CHILD_PID": str(pid_file), "FAKE_IGNORE_TERM": "1"}
        process = subprocess.Popen([sys.executable, str(SCRIPT), "run", "--output", str(self.output)],
                                   env=dict(os.environ, **environment),
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        child_pid = None
        try:
            child_pid = self.wait_for_pid(pid_file)
            process.send_signal(signal.SIGTERM)
            time.sleep(0.6)
            # The runner is waiting for the SIGTERM-ignoring child: its lock
            # must still be held, not released at signal delivery.
            with self.assertRaises(BlockingIOError):
                with (self.output / ".lock").open("a") as lock:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertEqual(process.wait(timeout=20), 143)
            self.assert_process_gone(child_pid)
            result = json.loads((self.output / "run-result.json").read_text())
            self.assertEqual(result["exit_code"], 137)
            self.assertEqual(result["interrupted"], signal.SIGTERM)
            self.assert_lock_free()
        finally:
            if process.poll() is None: process.kill(); process.wait()
            if child_pid is not None:
                try: os.kill(child_pid, signal.SIGKILL)
                except ProcessLookupError: pass

    def test_run_sighup_stops_child_and_returns_129(self):
        self.assertEqual(self.invoke("build"), 0)
        pid_file = self.root / "child.pid"
        environment = {"FAKE_SLEEP": "1", "FAKE_CHILD_PID": str(pid_file)}
        process = subprocess.Popen([sys.executable, str(SCRIPT), "run", "--output", str(self.output)],
                                   env=dict(os.environ, **environment),
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        child_pid = None
        try:
            child_pid = self.wait_for_pid(pid_file)
            process.send_signal(signal.SIGHUP)
            self.assertEqual(process.wait(timeout=20), 129)
            self.assert_process_gone(child_pid)
            result = json.loads((self.output / "run-result.json").read_text())
            self.assertEqual(result["exit_code"], 143)
            self.assertEqual(result["interrupted"], signal.SIGHUP)
            self.assert_lock_free()
        finally:
            if process.poll() is None: process.kill(); process.wait()
            if child_pid is not None:
                try: os.kill(child_pid, signal.SIGKILL)
                except ProcessLookupError: pass

    def test_run_cleanup_survives_repeated_term_and_hup(self):
        self.assertEqual(self.invoke("build"), 0)
        pid_file = self.root / "child.pid"
        environment = {"FAKE_SLEEP": "1", "FAKE_CHILD_PID": str(pid_file), "FAKE_IGNORE_TERM": "1"}
        process = subprocess.Popen([sys.executable, str(SCRIPT), "run", "--output", str(self.output)],
                                   env=dict(os.environ, **environment),
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        child_pid = None
        try:
            child_pid = self.wait_for_pid(pid_file)
            process.send_signal(signal.SIGTERM)
            for signum in (signal.SIGTERM, signal.SIGHUP, signal.SIGTERM, signal.SIGHUP):
                time.sleep(0.15)
                if process.poll() is None: process.send_signal(signum)
            # The child ignores TERM, so run cleanup is still reaping its group.
            # Repeated signals must not release the output lock in that window.
            with (self.output / ".lock").open("a") as lock:
                with self.assertRaises(BlockingIOError):
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertEqual(process.wait(timeout=20), 143)
            self.assert_process_gone(child_pid)
            self.assert_lock_free()
            self.assertFalse((self.output / "logs/residual-process-group.json").exists())
            result = json.loads((self.output / "run-result.json").read_text())
            self.assertEqual(result["exit_code"], 137)
            self.assertEqual(result["interrupted"], signal.SIGTERM)
        finally:
            if process.poll() is None: process.kill(); process.wait()
            if child_pid is not None:
                try: os.kill(child_pid, signal.SIGKILL)
                except ProcessLookupError: pass

    def test_run_residual_marker_blocks_reuse_until_group_is_gone(self):
        self.assertEqual(self.invoke("build"), 0)
        real_stop = runner.stop_process_group
        def stop_then_claim_alive(child, grace=5.0):
            real_stop(child, grace)
            raise RuntimeError(f"process_group_still_alive: {child.pid}")
        with patch.object(runner, "stop_process_group", side_effect=stop_then_claim_alive), \
             patch.dict(os.environ, {"FAKE_SLEEP": "1"}):
            self.assertEqual(self.invoke("run"), 2)
        marker = runner.residual_marker(self.output)
        self.assertTrue(marker.exists())
        self.assert_lock_free()
        result = json.loads((self.output / "run-result.json").read_text())
        self.assertEqual(result["exit_code"], 2)
        self.assertIn("process_group_still_alive", result["error"])
        self.assertIn("residual_process_group", result)
        with patch.object(runner, "group_alive", return_value=True):
            self.assertEqual(self.invoke("build"), 2)
            self.assertEqual(self.invoke("clean"), 2)
            self.assertTrue(marker.exists())
        self.assertEqual(self.invoke("build"), 0)
        self.assertFalse(marker.exists())

    def test_run_receipt_write_failure_stops_child_and_returns_2(self):
        self.assertEqual(self.invoke("build"), 0)
        pid_file = self.root / "child.pid"
        real_save = runner.save
        def failing_save(path, value):
            if Path(path).name == "run-result.json":
                deadline = time.monotonic() + 10
                while not pid_file.exists() and time.monotonic() < deadline:
                    time.sleep(0.05)
                if not pid_file.exists(): raise AssertionError("child never started")
                raise OSError("receipt write failed")
            return real_save(path, value)
        child_pid = None
        try:
            with patch.dict(os.environ, {"FAKE_SLEEP": "1", "FAKE_CHILD_PID": str(pid_file)}), \
                 patch.object(runner, "save", side_effect=failing_save):
                self.assertEqual(self.invoke("run"), 2)
            child_pid = int(pid_file.read_text())
            self.assert_process_gone(child_pid)
            self.assert_lock_free()
        finally:
            if child_pid is not None:
                try: os.kill(child_pid, signal.SIGKILL)
                except ProcessLookupError: pass

    def test_build_sigterm_kills_compiler_group_and_returns_143(self):
        pid_file = self.root / "cjpm.pid"
        output = self.root / "interrupted output"
        done = threading.Event()
        def interrupt():
            while not done.wait(0.05):
                if pid_file.exists() and pid_file.read_text().strip():
                    if not done.is_set(): os.kill(os.getpid(), signal.SIGTERM)
                    return
        thread = threading.Thread(target=interrupt)
        thread.start()
        cjpm_pid = None
        try:
            with patch.dict(os.environ, {"FAKE_CJPM_SLEEP": "1", "FAKE_CJPM_PID": str(pid_file),
                                         "FAKE_CJPM_IGNORE_TERM": "1"}):
                code = self.invoke("build", output=output)
            done.set(); thread.join(timeout=5)
            self.assertEqual(code, 143)
            cjpm_pid = int(pid_file.read_text())
            self.assert_process_gone(cjpm_pid)
            last = json.loads((output / "last-build.json").read_text())
            self.assertEqual(last["exit_code"], 143)
            self.assertEqual(last["interrupted"], signal.SIGTERM)
            self.assert_lock_free(output)
        finally:
            done.set(); thread.join(timeout=1)
            if cjpm_pid is not None:
                try: os.kill(cjpm_pid, signal.SIGKILL)
                except ProcessLookupError: pass

    def test_stdout_eof_wait_stays_inside_step_deadline(self):
        pid_file = self.root / "eof.pid"
        started = time.monotonic()
        with patch.dict(os.environ, {"FAKE_EOF_SLEEP": "1", "FAKE_EOF_PID": str(pid_file)}):
            code = self.invoke("build", "--timeout", "5")
        self.assertEqual(code, 124)
        self.assertLess(time.monotonic() - started, 20)
        self.assertTrue(pid_file.exists(), f"cjpm never started: {pid_file}")
        self.assert_process_gone(int(pid_file.read_text()))
        last = json.loads((self.output / "last-build.json").read_text())
        self.assertEqual(last["exit_code"], 124)
        self.assertIn("build_timeout", last["error"])

    def test_build_cleanup_survives_repeated_term_and_hup(self):
        pid_file = self.root / "cjpm.pid"
        output = self.root / "signal cleanup"
        environment = {"FAKE_CJPM_SLEEP": "1", "FAKE_CJPM_PID": str(pid_file),
                       "FAKE_CJPM_IGNORE_TERM": "1"}
        # A subprocess is needed to deliver real signals; the wrapper keeps the
        # Linux build contract enabled on a macOS test host, like invoke() does.
        wrapper = ("import importlib.util,sys;"
                   f"spec=importlib.util.spec_from_file_location('r',{str(SCRIPT)!r});"
                   "r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r);"
                   "r.platform.system=lambda:'Linux';raise SystemExit(r.main(sys.argv[1:]))")
        process = subprocess.Popen(
            [sys.executable, "-c", wrapper, "build", "--output", str(output),
             "--app", str(self.application), "--framework", str(self.framework),
             "--toolchain", str(self.env_file)],
            env=dict(os.environ, **environment), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        cjpm_pid = None
        try:
            cjpm_pid = self.wait_for_pid(pid_file)
            process.send_signal(signal.SIGTERM)
            for signum in (signal.SIGTERM, signal.SIGHUP, signal.SIGTERM, signal.SIGHUP):
                time.sleep(0.15)
                if process.poll() is None: process.send_signal(signum)
            # cjpm ignores TERM, so cleanup is still in its grace period. The
            # repeated signals must not release the output lock early.
            with (output / ".lock").open("a") as lock:
                with self.assertRaises(BlockingIOError):
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertEqual(process.wait(timeout=20), 143)
            self.assert_process_gone(cjpm_pid)
            self.assert_lock_free(output)
            self.assertFalse((output / "logs/residual-process-group.json").exists())
        finally:
            if process.poll() is None: process.kill(); process.wait()
            if cjpm_pid is not None:
                try: os.kill(cjpm_pid, signal.SIGKILL)
                except ProcessLookupError: pass

    def test_residual_group_marker_blocks_reuse_until_group_is_gone(self):
        real_stop = runner.stop_process_group
        def stop_then_claim_alive(child, grace=5.0):
            real_stop(child, grace)
            raise RuntimeError(f"process_group_still_alive: {child.pid}")
        with patch.object(runner, "stop_process_group", side_effect=stop_then_claim_alive):
            self.assertEqual(self.invoke("build"), 2)
        marker = runner.residual_marker(self.output)
        self.assertTrue(marker.exists())
        # The exception did not keep the lock: the next entry is refused by the
        # persisted residue, not by a lock the dead process still holds.
        self.assert_lock_free()
        with patch.object(runner, "group_alive", return_value=True):
            self.assertEqual(self.invoke("build"), 2)
            self.assertEqual(self.invoke("clean"), 2)
            self.assertTrue(marker.exists())
        self.assertEqual(self.invoke("build"), 0)
        self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
