#!/usr/bin/env python3
"""离线验证真实设备待验入口；所有设备、构建和探针命令均由替身接管。"""

import json
import os
import pathlib
import shutil
import socket
import subprocess
import tempfile
import textwrap
import threading
import unittest


SCRIPTS = pathlib.Path(__file__).resolve().parent


def serve_forward_mapping(state, ready, bind_error, events, stop):
    """受控本机服务只在 fake HDC 建立本轮 fport 映射后监听。"""
    while not stop.is_set() and not state.exists():
        stop.wait(0.01)
    if stop.is_set():
        return
    try:
        mapping = json.loads(state.read_text())
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
            listener.bind(("127.0.0.1", mapping["local_port"]))
            listener.listen(2)
            listener.settimeout(0.1)
            ready.write_text("listening\n")
            while not stop.is_set() and state.exists():
                try:
                    connection, _ = listener.accept()
                except socket.timeout:
                    continue
                with connection:
                    connection.settimeout(2)
                    request = connection.recv(80).decode("ascii").strip()
                    if not request:
                        # 入口先做 TCP 可达性检查，再由两个探针走协议往返。
                        continue
                    if request not in ("PING lifecycle", "PING clipping"):
                        raise AssertionError(f"unexpected probe request: {request!r}")
                    kind = request.split()[1]
                    reply = (f"CJGUI-FPORT target={mapping['target']} "
                             f"device={mapping['device_port']} "
                             f"local={mapping['local_port']} kind={kind}\n")
                    with events.open("a") as out:
                        out.write(f"socket:{kind}:{mapping['local_port']}\n")
                    connection.sendall(reply.encode("ascii"))
    except Exception as exc:
        bind_error.write_text(f"{type(exc).__name__}: {exc}\n")


class HandoverEntryTest(unittest.TestCase):
    def exercise(self, mode="success", legacy_no_forward=False):
        with tempfile.TemporaryDirectory(prefix="cjgui-realref-offline-") as tmp:
            root = pathlib.Path(tmp)
            scripts = root / "runtime/cjgui/platforms/ohos/scripts"
            scripts.mkdir(parents=True)
            lab = root / "labs/ohos_cjgui_app"
            (lab / "scripts").mkdir(parents=True)
            (lab / "entry/build/default/outputs/default").mkdir(parents=True)
            (root / "labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run").mkdir(parents=True)
            elsewhere = root / "other-working-directory"
            elsewhere.mkdir()

            shutil.copy2(SCRIPTS / "run_pending_real_device_checks.sh",
                         scripts / "run_pending_real_device_checks.sh")
            if legacy_no_forward:
                # 旧入口只传 HDC target，不创建 TCP 映射；用控制变异证明本机
                # socket 探针会拒绝该实现，不能只检查替身打印的 PASS。
                entry = scripts / "run_pending_real_device_checks.sh"
                old = entry.read_text()
                start = old.index("# 每轮独立端口")
                end = old.index("probe_result() {", start)
                legacy = (old[:start] +
                          'export CJGUI_OHOS_HOST=127.0.0.1 '\
                          'CJGUI_OHOS_PORT="$CJGUI_REAL_DEVICE_LOCAL_PORT"\n\n' +
                          old[end:])
                legacy = legacy.replace("verify_forward_current lifecycle\n", "")
                legacy = legacy.replace("verify_forward_current clipping\n", "")
                entry.write_text(legacy)
            # 历史 RED 已由错误仓库根和旧入口采证顺序复现；当前 checker 无设备调用。
            shutil.copy2(SCRIPTS / "check_real_ref_capability.sh",
                         scripts / "check_real_ref_capability.sh")
            (scripts / "verify_probe_op_coverage.py").write_text("print('coverage PASS')\n")

            hdc = root / "fake-hdc"
            hdc.write_text(textwrap.dedent("""\
                #!/usr/bin/env python3
                import json, os, pathlib, signal, sys, time
                args = sys.argv[1:]
                with open(os.environ['STUB_HDC_CALLS'], 'a') as out:
                    out.write(json.dumps(args) + '\\n')
                if args[:2] == ['-t', 'fake-device']:
                    args = args[2:]
                state = pathlib.Path(os.environ['STUB_FPORT_STATE'])
                ready = pathlib.Path(os.environ['STUB_FPORT_READY'])
                bind_error = pathlib.Path(os.environ['STUB_FPORT_BIND_ERROR'])
                if args[:2] == ['list', 'targets']:
                    if os.environ['STUB_MODE'] == 'hdc_error':
                        sys.exit(9)
                    print('fake-device\\tdevice')
                elif args[:2] == ['fport', 'ls']:
                    if os.environ['STUB_MODE'] == 'old_mapping':
                        print('other-device tcp:' + os.environ['STUB_EXPECTED_PORT'] +
                              ' tcp:9999 [Forward]')
                    if os.environ['STUB_MODE'] == 'old_mapping_abstract':
                        print('other-device tcp:' + os.environ['STUB_EXPECTED_PORT'] +
                              ' localabstract:old-app [Forward]')
                    if state.exists():
                        mapping = json.loads(state.read_text())
                        listed_target = ('other-device' if
                            os.environ['STUB_MODE'] == 'wrong_mapping_after_create'
                            else mapping['target'])
                        print('%s tcp:%s tcp:%s [Forward]' %
                              (listed_target, mapping['local_port'],
                               mapping['device_port']))
                elif args and args[0] == 'fport' and len(args) == 4 and args[1] == 'rm':
                    if not state.exists(): sys.exit(41)
                    mapping = json.loads(state.read_text())
                    if args[2:] != ['tcp:%s' % mapping['local_port'],
                                    'tcp:%s' % mapping['device_port']]:
                        sys.exit(42)
                    (state.parent / 'removed-owner.json').write_text(json.dumps(mapping))
                    state.unlink()
                    print('forward removed')
                elif args and args[0] == 'fport' and len(args) == 3:
                    if os.environ['STUB_MODE'] == 'same_tuple_race':
                        mapping = {'target': 'fake-device',
                                   'local_port': int(args[1].split(':', 1)[1]),
                                   'device_port': 7856,
                                   'owner': 'foreign-process-after-precheck'}
                        state.write_text(json.dumps(mapping))
                        (state.parent / 'foreign-created.json').write_text(json.dumps(mapping))
                        for _ in range(200):
                            if ready.exists():
                                print('[Fail] Forwardport task already exists', file=sys.stderr)
                                sys.exit(32)
                            if bind_error.exists():
                                print(bind_error.read_text(), file=sys.stderr)
                                sys.exit(34)
                            time.sleep(0.01)
                        sys.exit(35)
                    if os.environ['STUB_MODE'] == 'forward_fail': sys.exit(31)
                    if state.exists() or os.environ['STUB_MODE'] in (
                            'old_mapping', 'old_mapping_abstract'):
                        sys.exit(32)
                    if not args[1].startswith('tcp:') or args[2] != 'tcp:7856':
                        sys.exit(33)
                    local_port = int(args[1].split(':', 1)[1])
                    mapping = {'target': 'fake-device', 'local_port': local_port,
                               'device_port': 7856}
                    state.write_text(json.dumps(mapping))
                    for _ in range(200):
                        if ready.exists():
                            if os.environ['STUB_MODE'] in (
                                    'signal_during_create',
                                    'signal_during_create_confirmed'):
                                os.kill(int(os.environ['CJGUI_FORWARD_ENTRY_PID']), signal.SIGTERM)
                                time.sleep(0.2)
                                if os.environ['STUB_MODE'] == 'signal_during_create':
                                    sys.exit(143)
                            if os.environ['STUB_MODE'] == 'create_supervisor_killed':
                                os.kill(os.getppid(), signal.SIGKILL)
                                time.sleep(0.05)
                                sys.exit(0)
                            if os.environ['STUB_MODE'] == 'create_child_signaled':
                                os.kill(os.getpid(), signal.SIGTERM)
                            if os.environ['STUB_MODE'] == 'create_no_success_receipt':
                                print('Forwardport result:pending')
                            else:
                                print('Forwardport result:OK')
                            break
                        if bind_error.exists():
                            print(bind_error.read_text(), file=sys.stderr)
                            state.unlink(missing_ok=True)
                            sys.exit(34)
                        time.sleep(0.01)
                    else:
                        state.unlink(missing_ok=True)
                        sys.exit(35)
                elif args and args[0] == 'install':
                    if os.environ['STUB_MODE'] == 'deploy_fail': sys.exit(17)
                elif args and args[0] == 'shell':
                    cmd = ' '.join(args[1:])
                    if 'aa start' in cmd and os.environ['STUB_MODE'] == 'startup_fail':
                        sys.exit(18)
                    if 'grep -a' in cmd and 'ref capability decided' in cmd:
                        print('09-27 00:00:00.000 1234 1234 I CjguiHost: ref capability decided: capability=VerifiedNativeRef')
                    elif 'grep -a' in cmd and 'surface created' in cmd:
                        print('09-27 00:00:00.001 1234 1234 I CjguiHost: surface created gen=1 published=1')
                    elif 'pidof' in cmd:
                        print('1234')
                """))
            hdc.chmod(0o755)

            build = root / "fake-build.sh"
            build.write_text(textwrap.dedent("""\
                #!/usr/bin/env bash
                set -euo pipefail
                LAB="$1"
                shift
                RID=""
                while [ "$#" -gt 0 ]; do
                  if [ "$1" = "--run-id" ]; then RID="$2"; shift; fi
                  shift
                done
                [ -n "$RID" ] || exit 90
                echo "build:$LAB:$RID" >> "$STUB_EVENTS"
                BASE="$(cd "$LAB/../.." && pwd)"
                RUN="$BASE/labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/$RID"
                HAP="$LAB/entry/build/default/outputs/default/entry-default-unsigned.hap"
                mkdir -p "$RUN"
                printf 'current-HAP:%s\\n' "$RID" > "$HAP"
                "$HDC" install -r "$HAP"
                if [ "$STUB_MODE" != "missing_install_receipt" ]; then
                  if [ "$STUB_MODE" = "old_install_receipt" ]; then RECEIPT_HAP=/old/entry.hap
                  else RECEIPT_HAP="$HAP"; fi
                  printf '[Info]App install path:%s msg:install bundle successfully.\\n' \\
                    "$RECEIPT_HAP" > "$RUN/install_$RID.txt"
                fi
                "$HDC" shell 'aa start -a EntryAbility -b com.example.cjguiapp'
                SHA="$(shasum -a 256 "$HAP" | cut -d' ' -f1)"
                echo "$SHA" > "$RUN/hap_sha256.txt"
                PID=1234
                if [ "$STUB_MODE" = "old_capability" ]; then LOG_PID=9999; else LOG_PID=$PID; fi
                if [ "$STUB_MODE" = "known_shim" ]; then
                  CAP=KnownShimNoRef; PUB=0
                else
                  CAP=VerifiedNativeRef; PUB=1
                fi
                if [ "$STUB_MODE" != "missing_capability" ]; then
                  printf '09-27 00:00:00.000 %s %s I CjguiHost: ref capability decided: capability=%s\\n' "$LOG_PID" "$LOG_PID" "$CAP" > "$RUN/runlog_$RID.txt"
                  printf '09-27 00:00:00.001 %s %s I CjguiHost: surface created gen=1 published=%s\\n' "$LOG_PID" "$LOG_PID" "$PUB" >> "$RUN/runlog_$RID.txt"
                else
                  echo 'unrelated log' > "$RUN/runlog_$RID.txt"
                fi
                printf '09-27 00:00:00.002 %s %s I CjguiHost: verify seam armed token=launch-token\\n' \
                  "$PID" "$PID" >> "$RUN/runlog_$RID.txt"
                printf 'run_id=%s\\nhap_sha256=%s\\nbuild_variant=verify-transport+test-gates\\nlog_cleared=ok\\nlaunch_pid=%s\\nlaunch_id=launch-%s\\nlaunch_ts=2026-09-27T00:00:00+0800\\n' \\
                  "$RID" "$SHA" "$PID" "$RID" > "$RUN/startup_assert_$RID.txt"
                if [ "$STUB_MODE" = "wrong_hap" ]; then
                  sed -i '' 's/hap_sha256=.*/hap_sha256=wrong/' "$RUN/startup_assert_$RID.txt"
                fi
                if [ "$STUB_MODE" = "create_spawn_failed" ]; then
                  rm "$HDC"
                fi
                """))
            build.chmod(0o755)
            shutil.copy2(build, lab / "scripts/build_and_run.sh")

            for kind in ("lifecycle", "clipping"):
                probe = root / f"fake-{kind}.py"
                probe.write_text(textwrap.dedent(f"""\
                    import json, os, pathlib, signal, socket, sys, time
                    kind = {kind!r}
                    mode = os.environ['STUB_MODE']
                    directory = pathlib.Path(os.environ['CJGUI_OHOS_VERIFICATION_DIR'])
                    directory.mkdir(parents=True, exist_ok=True)
                    host = os.environ['CJGUI_OHOS_HOST']
                    port = int(os.environ['CJGUI_OHOS_PORT'])
                    with socket.create_connection((host, port), timeout=2) as channel:
                        channel.settimeout(2)
                        channel.sendall(('PING ' + kind + '\\n').encode('ascii'))
                        response = channel.recv(160).decode('ascii').strip()
                    expected = ('CJGUI-FPORT target=fake-device device=7856 '
                                'local=' + str(port) + ' kind=' + kind)
                    if response != expected:
                        print('incorrect endpoint response: ' + repr(response), file=sys.stderr)
                        sys.exit(29)
                    with open(os.environ['STUB_EVENTS'], 'a') as out:
                        out.write(kind + ':fake-device endpoint=' + host + ':' + str(port) + '\\n')
                    pid = '2234' if kind == 'lifecycle' else '3234'
                    if mode == 'stale_launch_pid' and kind == 'lifecycle':
                        pid = '1234'
                    if mode == 'reused_probe_pid' and kind == 'clipping':
                        pid = '2234'
                    token = 'fresh-' + kind
                    if mode == 'stale_launch_token' and kind == 'lifecycle':
                        token = 'launch-token'
                    if mode == 'reused_probe_token' and kind == 'clipping':
                        token = 'fresh-lifecycle'
                    print('PROBE_INSTANCE run_id=' + os.environ['CJGUI_OHOS_RUN_ID'] +
                          ' target=fake-device pid=' + pid + ' token=' + token)
                    print('PROBE_ENDPOINT host=' + host + ' port=' + str(port))
                    if mode == 'signal_during_probe' and kind == 'lifecycle':
                        sys.stdout.flush()
                        os.kill(os.getppid(), signal.SIGTERM)
                        time.sleep(0.2)
                        sys.exit(7)
                    print(kind + ' stderr marker', file=sys.stderr)
                    if kind == 'lifecycle':
                        name = 'surface_lifecycle'
                        evidence = {{'checks': [{{'status': 'PASS', 'pass': True}}]}}
                    else:
                        name = 'clipping'
                        evidence = [{{'check': 'clip', 'pass': True}}]
                    if mode == kind + '_fail':
                        if kind == 'lifecycle': evidence['checks'][0] = {{'status':'FAIL','pass':False}}
                        else: evidence[0]['pass'] = False
                    if mode == 'mixed' and kind == 'lifecycle':
                        evidence['checks'][0] = {{'status':'BLOCKED','reason':'pending'}}
                    if mode == 'mixed' and kind == 'clipping': evidence[0]['pass'] = False
                    if mode != 'missing_evidence' or kind != 'clipping':
                        e = directory / (name + '_evidence.json')
                        e.write_text(json.dumps(evidence))
                        r = directory / (name + '_raw.json')
                        r.write_text(json.dumps([{{'dir':'send', 'raw':kind}}]))
                        if mode == 'stale_evidence' and kind == 'clipping':
                            os.utime(e, (1, 1)); os.utime(r, (1, 1))
                    if mode == kind + '_fail' or (mode == 'mixed' and kind == 'clipping'):
                        sys.exit(7)
                    """))

            calls = root / "hdc-calls.jsonl"
            events = root / "events.txt"
            fport_state = root / "fport-current.json"
            fport_ready = root / "fport-listening.txt"
            fport_bind_error = root / "fport-bind-error.txt"
            reservation = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            reservation.bind(("127.0.0.1", 0))
            local_port = reservation.getsockname()[1]
            if mode == "occupied_port":
                reservation.listen(1)
            else:
                reservation.close()
            server_stop = threading.Event()
            server = threading.Thread(
                target=serve_forward_mapping,
                args=(fport_state, fport_ready, fport_bind_error, events, server_stop),
                daemon=True)
            server.start()
            env = os.environ.copy()
            env.update({
                "STUB_MODE": mode,
                "STUB_HDC_CALLS": str(calls),
                "STUB_EVENTS": str(events),
                "STUB_FPORT_STATE": str(fport_state),
                "STUB_FPORT_READY": str(fport_ready),
                "STUB_FPORT_BIND_ERROR": str(fport_bind_error),
                "STUB_EXPECTED_PORT": str(local_port),
                "CJGUI_REAL_DEVICE_LOCAL_PORT": str(local_port),
                "CJGUI_REAL_DEVICE_HDC_BINARY": str(hdc),
                "CJGUI_REAL_DEVICE_BUILD_SCRIPT": str(build),
                "CJGUI_REAL_DEVICE_LIFECYCLE_PROBE": str(root / "fake-lifecycle.py"),
                "CJGUI_REAL_DEVICE_CLIPPING_PROBE": str(root / "fake-clipping.py"),
            })
            try:
                run = subprocess.run(
                    ["bash", str(scripts / "run_pending_real_device_checks.sh"),
                     "--target", "fake-device", "--run-id", "offline-case"],
                    cwd=elsewhere, env=env, capture_output=True, text=True,
                    errors="replace", timeout=30)
                dest = root / "labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/offline-case"
                files = {p.relative_to(dest).as_posix(): p.read_text(errors="replace")
                         for p in dest.rglob("*") if p.is_file()} if dest.exists() else {}
                if mode in ("same_tuple_race", "signal_during_create",
                            "create_no_success_receipt", "create_supervisor_killed",
                            "create_child_signaled"):
                    files["audit.mapping-survived.txt"] = str(fport_state.exists())
                if mode == "same_tuple_race":
                    files["audit.foreign-created.json"] = (
                        root / "foreign-created.json").read_text()
                    files["audit.removed-owner.json"] = (
                        (root / "removed-owner.json").read_text()
                        if (root / "removed-owner.json").exists() else "<not removed>")
                return run, files, calls.read_text() if calls.exists() else "", \
                    events.read_text() if events.exists() else ""
            finally:
                server_stop.set()
                server.join(timeout=3)
                if mode == "occupied_port":
                    reservation.close()
                if server.is_alive():
                    self.fail("fake forwarding listener did not stop")
                if mode == "wrong_mapping_after_create":
                    if not fport_state.exists():
                        self.fail("foreign mapping was incorrectly removed")
                    fport_state.unlink()
                elif mode in ("same_tuple_race", "signal_during_create",
                              "create_no_success_receipt", "create_supervisor_killed",
                              "create_child_signaled"):
                    fport_state.unlink(missing_ok=True)
                elif fport_state.exists():
                    self.fail("this run's fake HDC forwarding map leaked: " +
                              files.get("forward.cleanup.status", "missing cleanup status") +
                              " calls=" + (calls.read_text() if calls.exists() else "none"))
                try:
                    with socket.create_connection(("127.0.0.1", local_port), timeout=0.2):
                        self.fail("fake forwarding listener leaked")
                except ConnectionRefusedError:
                    pass

    def test_success_from_arbitrary_cwd_has_current_identity_and_both_archives(self):
        run, files, calls, events = self.exercise()
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertIn("RESULT=PASS", files["result.txt"])
        self.assertIn("target=fake-device", files["run_identity.txt"])
        self.assertIn("launch_id=launch-offline-case", files["run_identity.txt"])
        self.assertIn("hap_sha256=", files["run_identity.txt"])
        for name in ("surface_lifecycle", "clipping"):
            self.assertIn(f"verification/{name}_evidence.json", files)
            self.assertIn(f"verification/{name}_raw.json", files)
        for name in ("lifecycle", "clipping"):
            self.assertIn(f"{name}.stdout.log", files)
            self.assertIn(f"{name}.stderr.log", files)
        self.assertIn('"-t", "fake-device"', calls)
        self.assertNotIn('"uninstall"', calls)
        self.assertEqual(calls.count('"install"'), 1)
        self.assertEqual(calls.count('aa start'), 1)
        self.assertTrue(all(call[:2] == ["-t", "fake-device"]
                            for call in map(json.loads, calls.splitlines())
                            if call[:2] not in (["list", "targets"], ["fport", "ls"])))
        self.assertEqual(events.count("build:"), 1)
        self.assertLess(events.index("build:"), events.index("lifecycle:"))
        forward = files["forward_identity.txt"]
        self.assertIn("target=fake-device", forward)
        self.assertIn("host=127.0.0.1", forward)
        self.assertIn("device_port=7856", forward)
        self.assertIn("create_result=confirmed", forward)
        local_port = int(next(line.split("=", 1)[1] for line in forward.splitlines()
                              if line.startswith("local_port=")))
        self.assertNotEqual(local_port, 17856)
        self.assertIn(f"endpoint=127.0.0.1:{local_port}", events)
        self.assertIn(f"socket:lifecycle:{local_port}", events)
        self.assertIn(f"socket:clipping:{local_port}", events)
        self.assertIn(f"PROBE_ENDPOINT host=127.0.0.1 port={local_port}",
                      files["lifecycle.stdout.log"])
        self.assertIn(f"PROBE_ENDPOINT host=127.0.0.1 port={local_port}",
                      files["clipping.stdout.log"])
        self.assertIn("pid=2234 token=fresh-lifecycle", files["lifecycle.stdout.log"])
        self.assertIn("pid=3234 token=fresh-clipping", files["clipping.stdout.log"])
        self.assertIn("forward.cleanup.status", files)
        self.assertIn("remove_exitcode=0", files["forward.cleanup.status"])
        self.assertIn("forward.create.stdout.log", files)
        self.assertIn("forward.create.stderr.log", files)
        self.assertIn("forward.create.exitcode", files)
        hdc_calls = [json.loads(line) for line in calls.splitlines()]
        self.assertIn(["-t", "fake-device", "fport", f"tcp:{local_port}",
                       "tcp:7856"], hdc_calls)
        self.assertEqual(hdc_calls.count(["-t", "fake-device", "fport", "rm",
                                          f"tcp:{local_port}", "tcp:7856"]), 1)

    def test_historical_no_forward_mutation_fails_the_socket_contract(self):
        run, files, calls, events = self.exercise(legacy_no_forward=True)
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertNotIn('"fport"', calls)
        self.assertNotIn("socket:", events)
        self.assertIn("ConnectionRefusedError", files["lifecycle.stderr.log"])
        self.assertIn("ConnectionRefusedError", files["clipping.stderr.log"])

    def test_forward_creation_failure_is_named_and_does_not_run_probes(self):
        run, files, calls, events = self.exercise("forward_fail")
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("forward", files["result.txt"].lower())
        self.assertNotIn("lifecycle:", events)
        self.assertNotIn("socket:", events)
        self.assertIn('"fport"', calls)
        self.assertNotIn('"rm"', calls)
        self.assertEqual(files["forward.create.exitcode"].strip(), "31")

    def test_foreign_exact_mapping_created_after_precheck_survives_failed_create(self):
        run, files, calls, events = self.exercise("same_tuple_race")
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("reason=forward_create_failed", files["result.txt"])
        self.assertEqual(files["forward.before.assessment.log"].strip(),
                         "local_port_unmapped")
        self.assertEqual(files["forward.create.exitcode"].strip(), "32")
        foreign = json.loads(files["audit.foreign-created.json"])
        self.assertEqual(foreign["owner"], "foreign-process-after-precheck")
        self.assertEqual(files["audit.mapping-survived.txt"], "True")
        self.assertEqual(files["audit.removed-owner.json"], "<not removed>")
        self.assertEqual(calls.count('"fport", "rm"'), 0)
        self.assertNotIn("socket:", events)

    def test_create_without_success_receipt_leaves_uncertain_mapping(self):
        run, files, calls, events = self.exercise("create_no_success_receipt")
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("reason=forward_create_unconfirmed", files["result.txt"])
        self.assertEqual(files["forward.create.exitcode"].strip(), "0")
        self.assertIn("Forwardport result:pending", files["forward.create.stdout.log"])
        self.assertEqual(files["audit.mapping-survived.txt"], "True")
        self.assertEqual(calls.count('"fport", "rm"'), 0)
        self.assertNotIn("socket:", events)

    def test_supervisor_dies_after_mapping_creation_leaves_unknown_mapping(self):
        run, files, calls, events = self.exercise("create_supervisor_killed")
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("reason=forward_create_result_unknown", files["result.txt"])
        self.assertIn("create_result=result_unknown", files["forward_identity.txt"])
        self.assertEqual(files["forward.create.exitcode"].strip(), "unknown")
        self.assertEqual(files["audit.mapping-survived.txt"], "True")
        self.assertEqual(calls.count('"fport", "rm"'), 0)
        self.assertNotIn("socket:", events)

    def test_child_terminated_by_signal_is_confirmed_failure_not_unknown(self):
        run, files, calls, events = self.exercise("create_child_signaled")
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("reason=forward_create_failed", files["result.txt"])
        self.assertIn("create_result=failed_exit_-15", files["forward_identity.txt"])
        self.assertEqual(files["forward.create.exitcode"].strip(), "-15")
        self.assertEqual(files["audit.mapping-survived.txt"], "True")
        self.assertEqual(calls.count('"fport", "rm"'), 0)
        self.assertNotIn("socket:", events)

    def test_forward_wrapper_missing_at_spawn_is_named_tool_failure(self):
        run, files, calls, events = self.exercise("create_spawn_failed")
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("reason=forward_create_spawn_failed", files["result.txt"])
        self.assertIn("state=spawn_failed", files["forward.create.supervisor.log"])
        self.assertEqual(calls.count('"fport", "rm"'), 0)
        self.assertNotIn("lifecycle:", events)
        self.assertNotIn("socket:", events)

    def test_occupied_or_old_forward_is_not_reused_or_removed(self):
        for mode in ("occupied_port", "old_mapping", "old_mapping_abstract"):
            with self.subTest(mode=mode):
                run, files, calls, events = self.exercise(mode)
                self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
                self.assertIn("RESULT=FAIL", files["result.txt"])
                self.assertTrue(any(word in files["result.txt"].lower()
                                    for word in ("port", "forward", "mapping")))
                self.assertNotIn("lifecycle:", events)
                self.assertNotIn("socket:", events)
                hdc_calls = [json.loads(line) for line in calls.splitlines()]
                self.assertFalse(any(args[2:4] == ["fport", "rm"]
                                     for args in hdc_calls))
                self.assertNotIn("create_result=confirmed",
                                 files.get("forward_identity.txt", ""))
                if mode.startswith("old_mapping"):
                    self.assertIn("reason=forward_old_mapping", files["result.txt"])

    def test_mapping_changed_to_other_target_is_named_and_not_removed(self):
        run, files, calls, events = self.exercise("wrong_mapping_after_create")
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("reason=forward_mapping_mismatch", files["result.txt"])
        self.assertIn("mapping_mismatch", files["forward.after.assessment.log"])
        self.assertEqual(files["forward.create.exitcode"].strip(), "0")
        self.assertIn("create_result=", files["forward_identity.txt"])
        self.assertNotIn("lifecycle:", events)
        self.assertNotIn("socket:", events)
        self.assertEqual(calls.count('"fport", "rm"'), 0)

    def test_probe_restart_requires_new_pid_and_token_from_each_instance(self):
        for mode in ("stale_launch_token", "reused_probe_token",
                     "stale_launch_pid", "reused_probe_pid"):
            with self.subTest(mode=mode):
                run, files, calls, events = self.exercise(mode)
                self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
                self.assertIn("RESULT=FAIL", files["result.txt"])
                self.assertIn("reused_or_missing_instance_pid_or_token",
                              files["lifecycle.assessment.log"] if mode.startswith("stale_launch")
                              else files["clipping.assessment.log"])
                self.assertIn("socket:lifecycle:", events)
                self.assertIn("socket:clipping:", events)
                self.assertEqual(calls.count('"fport", "rm"'), 1)
                self.assertIn("remove_exitcode=0", files["forward.cleanup.status"])

    def test_signal_exit_removes_only_this_runs_forward(self):
        run, files, calls, events = self.exercise("signal_during_probe")
        self.assertNotEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("socket:lifecycle:", events)
        self.assertNotIn("clipping:", events)
        self.assertEqual(calls.count('"fport", "rm"'), 1)
        self.assertIn("remove_exitcode=0", files["forward.cleanup.status"])

    def test_signal_during_create_without_success_receipt_keeps_uncertain_mapping(self):
        run, files, calls, events = self.exercise("signal_during_create")
        self.assertNotEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertNotIn("lifecycle:", events)
        self.assertNotIn("socket:", events)
        self.assertEqual(files["audit.mapping-survived.txt"], "True")
        self.assertEqual(calls.count('"fport", "rm"'), 0)
        self.assertIn("create_result=", files["forward_identity.txt"])
        self.assertIn("forward.create.exitcode", files)

    def test_signal_during_create_with_success_receipt_cleans_owned_mapping(self):
        run, files, calls, events = self.exercise("signal_during_create_confirmed")
        self.assertNotEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("Forwardport result:OK", files["forward.create.stdout.log"])
        self.assertEqual(files["forward.create.exitcode"].strip(), "0")
        self.assertNotIn("lifecycle:", events)
        self.assertNotIn("socket:", events)
        self.assertEqual(calls.count('"fport", "rm"'), 1)
        self.assertIn("remove_exitcode=0", files["forward.cleanup.status"])

    def test_deployment_startup_and_tool_errors_are_failures(self):
        for mode in ("hdc_error", "deploy_fail", "startup_fail", "wrong_hap",
                     "missing_install_receipt", "old_install_receipt"):
            with self.subTest(mode=mode):
                run, files, _, events = self.exercise(mode)
                self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
                self.assertIn("RESULT=FAIL", files["result.txt"])
                self.assertNotIn("KnownShimNoRef", files["result.txt"])
                self.assertNotIn("lifecycle:", events)
                self.assertIn("requested_identity.txt", files)
                if mode in ("wrong_hap", "missing_install_receipt", "old_install_receipt"):
                    self.assertEqual(files["build.exitcode"].strip(), "0")
                elif mode == "deploy_fail":
                    self.assertEqual(files["build.exitcode"].strip(), "17")
                elif mode == "startup_fail":
                    self.assertEqual(files["build.exitcode"].strip(), "18")

    def test_only_current_known_shim_is_capability_blocked(self):
        run, files, _, events = self.exercise("known_shim")
        self.assertEqual(run.returncode, 42, run.stdout + run.stderr)
        self.assertIn("RESULT=BLOCKED", files["result.txt"])
        self.assertIn("KnownShimNoRef", files["result.txt"])
        self.assertNotIn("lifecycle:", events)

    def test_missing_or_old_capability_does_not_classify_device(self):
        for mode in ("missing_capability", "old_capability"):
            with self.subTest(mode=mode):
                run, files, _, events = self.exercise(mode)
                self.assertEqual(run.returncode, 42, run.stdout + run.stderr)
                self.assertIn("RESULT=BLOCKED", files["result.txt"])
                self.assertNotIn("KnownShimNoRef", files["result.txt"])
                self.assertNotIn("lifecycle:", events)

    def test_probe_failures_are_not_swallowed_and_both_probes_archive(self):
        for mode in ("lifecycle_fail", "clipping_fail"):
            with self.subTest(mode=mode):
                run, files, calls, events = self.exercise(mode)
                self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
                self.assertIn("RESULT=FAIL", files["result.txt"])
                self.assertIn("lifecycle:", events)
                self.assertIn("clipping:", events)
                self.assertIn("socket:lifecycle:", events)
                self.assertIn("socket:clipping:", events)
                for name in ("surface_lifecycle", "clipping"):
                    self.assertIn(f"verification/{name}_evidence.json", files)
                    self.assertIn(f"verification/{name}_raw.json", files)
                self.assertIn("stderr marker", files["lifecycle.stderr.log"])
                self.assertIn("stderr marker", files["clipping.stderr.log"])
                self.assertIn("remove_exitcode=0", files["forward.cleanup.status"])
                self.assertEqual(calls.count('"fport", "rm"'), 1)

    def test_missing_or_stale_probe_evidence_cannot_pass(self):
        for mode in ("missing_evidence", "stale_evidence"):
            with self.subTest(mode=mode):
                run, files, calls, events = self.exercise(mode)
                self.assertEqual(run.returncode, 42, run.stdout + run.stderr)
                self.assertIn("RESULT=BLOCKED", files["result.txt"])
                self.assertNotIn("KnownShimNoRef", files["result.txt"])
                self.assertIn("lifecycle:", events)
                self.assertIn("clipping:", events)
                self.assertIn("remove_exitcode=0", files["forward.cleanup.status"])
                self.assertEqual(calls.count('"fport", "rm"'), 1)

    def test_fail_takes_priority_over_blocked(self):
        run, files, _, events = self.exercise("mixed")
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("RESULT=FAIL", files["result.txt"])
        self.assertIn("lifecycle=42", files["probe_exit_summary.txt"])
        self.assertIn("clipping=1", files["probe_exit_summary.txt"])
        self.assertIn("lifecycle:", events)
        self.assertIn("clipping:", events)


if __name__ == "__main__":
    unittest.main()
