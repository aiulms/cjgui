#!/usr/bin/env python3
"""W1 无泄漏执行器：一次 exec 启动 worker，worker 一次性执行全部任务后回传。

为什么这样设计
--------------
实测：每次 `prlctl exec` 会在客户机内新建约 2-3 个进程，并让
`prl_tools_service` 的 Terminal 窗口 +1，且不回收。
执行 495 条命令 → 495 个 Terminal 窗口、482 个可见窗口。

因此本脚本：
  1. 只调用 1 次 prlctl exec 来启动 worker；
  2. worker 通过 TCP 把**整批任务**拉走，在客户机内依次执行；
  3. 全部结果一次性回传，连接关闭。

用法：
    python3 w1run.py <任务目录>      # 执行目录内所有 *.ps1（按名排序）
    python3 w1run.py <单个.ps1>
"""
import base64
import argparse
import datetime
import hashlib
import glob
import http.server
import json
import math
import os
import re
import socket
import subprocess
import sys
import threading
import time
import urllib.parse
import uuid
from pathlib import Path

VM_UUID = "{9e5dedb2-90f8-4d21-80f0-41e194407fab}"
MAC_IP = "10.211.55.2"
PORT = int(os.environ.get("W1_PORT", "8801"))
MAX_REQUEST_BYTES = 4 * 1024 * 1024
MAX_RESULT_BYTES = 16 * 1024 * 1024
MAX_OUTPUT_BYTES = 256 * 1024
MAX_JOB_TIMEOUT_MS = 7200000
BATCH_RESULT_MARGIN_SECONDS = 300
EXIT_LINE = re.compile(r"\[exit=(-?(?:0|[1-9][0-9]*))\]\Z")
VM_UUID = "{9e5dedb2-90f8-4d21-80f0-41e194407fab}"
GUEST_WORKER_PATH = r"C:\cjgui-windows-w1\worker_run.ps1"
GUEST_HOME = r"C:\cjgui-windows-w1"
GUEST_HOST_IP = "10.211.55.2"
GUEST_CONTROL_PORT = 8802
GUEST_BOOTSTRAP_HTTP_PORT = 8792


def start_worker():
    """用一次 exec 启动客户机 worker，返回本次 exec 的 stdout。"""
    cmd = ("Start-Process powershell.exe -ArgumentList "
           "'-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden',"
           "'-File','C:\\cjgui-windows-w1\\worker_run.ps1' -WindowStyle Hidden; 'LAUNCHED'")
    for _ in range(4):
        p = subprocess.run(["prlctl", "exec", VM_UUID, "--current-user",
                            "powershell.exe", "-NoLogo", "-NoProfile",
                            "-ExecutionPolicy", "Bypass", "-Command", cmd],
                           capture_output=True, timeout=300)
        out = p.stdout.decode("utf-8", "replace").strip()
        err = p.stderr.decode("utf-8", "replace")
        if "LAUNCHED" in out:
            return out
        if "Unable to open new session" in err or "PrlJob" in err:
            time.sleep(2)
            continue
        return out or err
    return "LAUNCH_FAILED"


def run_batch(scripts, timeout=1800):
    """监听一个连接，把任务批次交给客户机 worker，收集结果。"""
    results = {}

    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", PORT))
    srv.listen(1)
    srv.settimeout(timeout)

    # 启动 worker（本次唯一一次 exec）
    t = threading.Thread(target=start_worker, daemon=True)
    t.start()

    try:
        conn, addr = srv.accept()
    except socket.timeout:
        srv.close()
        return None, "等待 worker 连接超时"

    conn.settimeout(1.0)
    buf = b""
    deadline = time.monotonic() + timeout
    done = False

    def read_line():
        nonlocal buf
        while b"\n" not in buf:
            if time.monotonic() >= deadline:
                raise TimeoutError("batch deadline expired while reading a line")
            try:
                c = conn.recv(4096)
            except socket.timeout:
                continue
            if not c:
                return None
            buf += c
        line, _, buf = buf.partition(b"\n")
        return line.decode("utf-8", "replace")

    def read_exact(n):
        nonlocal buf
        if n < 0 or n > MAX_RESULT_BYTES:
            raise ValueError("frame length out of bounds: %d" % n)
        while len(buf) < n:
            if time.monotonic() >= deadline:
                raise TimeoutError("batch deadline expired while reading a frame")
            try:
                c = conn.recv(65536)
            except socket.timeout:
                continue
            if not c:
                return None
            buf += c
        data, buf = buf[:n], buf[n:]
        return data

    try:
        hello = read_line()
        if hello is None or not hello.startswith("HELLO "):
            raise ConnectionError("missing worker HELLO")
        payload = json.dumps(scripts).encode("utf-8")
        conn.sendall(b"BATCH %d\n" % len(payload))
        conn.sendall(payload + b"\n")

        while True:
            line = read_line()
            if line is None:
                raise ConnectionError("worker closed before DONE")
            if line.startswith("DONE"):
                done = True
                break
            if line.startswith("RES "):
                parts = line.split(None, 2)
                if len(parts) != 3:
                    raise ValueError("malformed RES header")
                name = parts[1]
                blen = int(parts[2])
                if name not in scripts:
                    raise ValueError("unexpected result name: %s" % name)
                if name in results:
                    raise ValueError("duplicate result name: %s" % name)
                body = read_exact(blen)
                if body is None:
                    raise ConnectionError("truncated result body: %s" % name)
                results[name] = body.decode("utf-8", "replace")
                if read_line() != "":
                    raise ValueError("missing result frame terminator: %s" % name)
                conn.sendall(b"ACK\n")
                continue
            raise ValueError("unexpected worker frame: %s" % line[:80])

        missing = set(scripts) - set(results)
        if missing:
            raise ConnectionError("DONE with missing results: %s" % ", ".join(sorted(missing)))
        if not done:
            raise ConnectionError("missing DONE")
        # A complete batch ends with DONE followed by a clean peer close.
        if read_line() is not None:
            raise ValueError("data received after DONE")
    except Exception as exc:  # noqa: BLE001
        return results, "transport_failed: %s" % exc
    finally:
        try:
            conn.close()
        except Exception:
            pass
        srv.close()

    return results, "OK"


def parse_exit_code(name, body):
    """Accept one exact terminal exit record, never a substring from stdout."""
    if not isinstance(body, str):
        raise ValueError("result_body_missing")
    lines = body.splitlines()
    matches = [(index, EXIT_LINE.fullmatch(line)) for index, line in enumerate(lines)]
    matches = [(index, match) for index, match in matches if match is not None]
    if len(matches) != 1:
        raise ValueError("exit_record_count=%d" % len(matches))
    index, match = matches[0]
    if index != len(lines) - 1:
        raise ValueError("exit_record_not_terminal")
    try:
        code = int(match.group(1), 10)
    except (ValueError, OverflowError) as exc:
        raise ValueError("exit_record_invalid") from exc
    if code < -(2 ** 31) or code > (2 ** 31) - 1:
        raise ValueError("exit_code_out_of_int32_range")
    return code


def validate_batch_results(requested, results, status):
    """Return ordered (name, code) records or raise a named contract failure."""
    if status != "OK":
        raise ValueError("transport_not_complete: %s" % status)
    requested_names = list(requested)
    if len(set(requested_names)) != len(requested_names):
        raise ValueError("duplicate_requested_name")
    if not isinstance(results, dict):
        raise ValueError("results_not_a_mapping")
    requested_set = set(requested_names)
    received_set = set(results)
    missing = requested_set - received_set
    extra = received_set - requested_set
    if missing:
        raise ValueError("missing_results: %s" % ", ".join(sorted(missing)))
    if extra:
        raise ValueError("unexpected_results: %s" % ", ".join(sorted(extra)))
    return [(name, parse_exit_code(name, results[name])) for name in requested_names]


def validate_worker_batch(requested, response, expected_nonce, transport_status="OK"):
    """Validate one structured, bounded worker response and decode its streams."""
    if transport_status != "OK":
        raise ValueError("transport_failed: %s" % transport_status)
    if not isinstance(response, dict):
        raise ValueError("worker_response_not_an_object")
    if response.get("nonce") != expected_nonce:
        raise ValueError("nonce_mismatch")
    if response.get("state") != "complete":
        raise ValueError("worker_not_complete")

    requested_names = list(requested)
    if len(set(requested_names)) != len(requested_names):
        raise ValueError("duplicate_requested_name")
    raw_records = response.get("results")
    if not isinstance(raw_records, list):
        raise ValueError("results_not_a_list")

    records = {}
    for record in raw_records:
        if not isinstance(record, dict):
            raise ValueError("result_record_not_an_object")
        name = record.get("name")
        if not isinstance(name, str) or not name:
            raise ValueError("result_name_invalid")
        if name in records:
            raise ValueError("duplicate_result: %s" % name)
        records[name] = record

    requested_set = set(requested_names)
    received_set = set(records)
    missing = requested_set - received_set
    extra = received_set - requested_set
    if missing:
        raise ValueError("missing_results: %s" % ", ".join(sorted(missing)))
    if extra:
        raise ValueError("unexpected_results: %s" % ", ".join(sorted(extra)))

    validated = []
    for name in requested_names:
        record = records[name]
        cancelled = record.get("cancelled", False)
        if cancelled not in (True, False):
            raise ValueError("cancelled_flag_invalid: %s" % name)
        if cancelled is True and record.get("timed_out") is True:
            raise ValueError("cancelled_and_timed_out: %s" % name)
        if record.get("timed_out") is True:
            raise ValueError("task_timeout: %s" % name)
        if record.get("timed_out") is not False:
            raise ValueError("timed_out_flag_invalid: %s" % name)
        if record.get("stdout_truncated") is not False or record.get("stderr_truncated") is not False:
            raise ValueError("output_truncated: %s" % name)
        if record.get("error") not in ("", None):
            raise ValueError("task_error: %s: %s" % (name, record.get("error")))

        code = record.get("exit_code")
        if type(code) is not int:
            raise ValueError("exit_code_type: %s" % name)
        if code < -(2 ** 31) or code > (2 ** 31) - 1:
            raise ValueError("exit_code_out_of_int32_range: %s" % name)

        elapsed = record.get("elapsed_ms")
        if isinstance(elapsed, bool) or not isinstance(elapsed, (int, float)) or elapsed < 0:
            raise ValueError("elapsed_ms_invalid: %s" % name)

        for field in ("stdout_b64", "stderr_b64"):
            encoded = record.get(field)
            if not isinstance(encoded, str):
                raise ValueError("%s_missing: %s" % (field, name))
            if len(encoded) > ((MAX_OUTPUT_BYTES + 2) // 3) * 4:
                raise ValueError("output_truncated: %s" % name)
            try:
                raw = base64.b64decode(encoded, validate=True)
            except (ValueError, base64.binascii.Error) as exc:
                raise ValueError("%s_invalid: %s" % (field, name)) from exc
            if len(raw) > MAX_OUTPUT_BYTES:
                raise ValueError("output_truncated: %s" % name)
            record[field.removesuffix("_b64")] = raw
        validated.append(record)

    return validated


def minimum_batch_timeout_seconds(configured_timeout_seconds, task_timeouts_ms):
    """Cover sequential task budgets and leave time to reap and return results."""
    timeouts = list(task_timeouts_ms)
    if not timeouts or any(type(value) is not int or value < 1 or value > MAX_JOB_TIMEOUT_MS
                           for value in timeouts):
        raise ValueError("task_timeout_out_of_bounds")
    required = math.ceil(sum(timeouts) / 1000.0 + BATCH_RESULT_MARGIN_SECONDS)
    return max(float(configured_timeout_seconds), required)


def _write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def _safe_print(*values, sep=" ", end="\n", file=None, flush=True):
    target = file or sys.stdout
    try:
        print(*values, sep=sep, end=end, file=target, flush=flush)
    except (BlockingIOError, BrokenPipeError, OSError):
        # The raw batch evidence is persisted first; a full terminal cannot tear down the worker.
        pass


def _resolve_script_path(root, value):
    candidate = Path(value)
    if not candidate.is_absolute():
        candidate = root / candidate
    resolved = candidate.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError("script_path_outside_root")
    return resolved


def _load_script_batch(root, value, is_directory):
    candidate = _resolve_script_path(root, value)
    if is_directory:
        if not candidate.is_dir():
            raise ValueError("job_directory_missing: %s" % candidate)
        paths = sorted(candidate.glob("*.ps1"))
    else:
        if not candidate.is_file() or candidate.suffix.lower() != ".ps1":
            raise ValueError("job_script_missing_or_not_ps1: %s" % candidate)
        paths = [candidate]
    if not paths:
        raise ValueError("job_batch_empty")
    return {path.name: path.read_text(encoding="utf-8-sig") for path in paths}


def _report_batch(session, scripts, nonce, response, status, display_output_bytes=0):
    result_path = session.session_dir / "results" / (nonce + ".json")
    _write_json(result_path, {
        "nonce": nonce,
        "transport_status": status,
        "requested_names": list(scripts),
        "response": response,
    })
    if status != "OK":
        raise ValueError("transport_failed: %s" % status)
    records = validate_worker_batch(list(scripts), response, nonce, status)
    max_code = 0
    for record in records:
        if display_output_bytes > 0:
            for label, raw, target in (("stdout", record["stdout"], sys.stdout), ("stderr", record["stderr"], sys.stderr)):
                if not raw:
                    continue
                shown = raw[:display_output_bytes].decode("utf-8", "replace")
                _safe_print("TASK_%s name=%s preview_bytes=%d" % (label.upper(), record["name"], min(len(raw), display_output_bytes)), file=target)
                _safe_print(shown, file=target, end="" if shown.endswith("\n") else "\n")
        code = record["exit_code"]
        _safe_print("TASK_RESULT name=%s exit=%d elapsed_ms=%s stdout_bytes=%d stderr_bytes=%d cancelled=%s" % (
            record["name"], code, record["elapsed_ms"], len(record["stdout"]), len(record["stderr"]),
            bool(record.get("cancelled", False))))
        if code != 0:
            max_code = code if max_code == 0 else max_code
    _safe_print("BATCH_RESULT nonce=%s jobs=%d status=%s raw=%s" % (
        nonce, len(records), "ok" if max_code == 0 else "nonzero_exit", result_path))
    return max_code


def interactive_main(argv=None):
    parser = argparse.ArgumentParser(description="Run bounded PowerShell batches through one Pharos Windows guest worker.")
    parser.add_argument("--worker-script", default=str(Path(__file__).with_name("worker_run.ps1")))
    parser.add_argument("--artifact-root", default=str(Path(__file__).resolve().parents[1]))
    parser.add_argument("--root", default=str(Path.cwd()), help="local root that contains submitted .ps1 jobs")
    parser.add_argument("--guest-working-directory", default=GUEST_HOME)
    parser.add_argument("--task-timeout-ms", type=int, default=300000)
    parser.add_argument("--batch-timeout-seconds", type=int, default=1800)
    parser.add_argument("--connect-timeout-seconds", type=int, default=60)
    parser.add_argument("--host-ip", default=GUEST_HOST_IP)
    parser.add_argument("--control-port", type=int, default=GUEST_CONTROL_PORT)
    parser.add_argument("--http-port", type=int, default=GUEST_BOOTSTRAP_HTTP_PORT)
    parser.add_argument("--command-file", help="append commands here to keep one guest worker alive between batches")
    parser.add_argument("--display-output-bytes", type=int, default=0, help="per-stream preview limit; raw output always stays in the session JSON")
    args = parser.parse_args(argv)
    local_root = Path(args.root).resolve()
    session = WindowsWorkerSession(
        args.worker_script, args.artifact_root, host_ip=args.host_ip,
        control_port=args.control_port, http_port=args.http_port,
        connect_timeout=args.connect_timeout_seconds,
    )
    failures = 0
    _safe_print("WORKER_READY pid=%s arch=%s path=%s sha256=%s session=%s" % (
        session.worker["pid"], session.worker.get("process_architecture", "unknown"),
        session.worker["worker_path"], session.worker["worker_sha256"], session.session_id), flush=True)
    _safe_print("Commands: run <file.ps1>, batch <directory>, run-timeout <ms> <file.ps1>, status, exit")
    def command_stream():
        if not args.command_file:
            yield from sys.stdin
            return
        command_path = Path(args.command_file).resolve()
        command_path.parent.mkdir(parents=True, exist_ok=True)
        command_path.touch(exist_ok=True)
        _safe_print("COMMAND_FILE_READY %s" % command_path)
        offset = 0
        idle_deadline = time.monotonic() + 1800
        while time.monotonic() < idle_deadline:
            with command_path.open("r", encoding="utf-8") as stream:
                stream.seek(offset)
                raw = stream.readline()
                if raw:
                    offset = stream.tell()
                    idle_deadline = time.monotonic() + 1800
            if raw:
                yield raw
            else:
                time.sleep(0.1)
    try:
        for raw in command_stream():
            command = raw.strip()
            if not command:
                continue
            if command in ("exit", "shutdown"):
                break
            if command == "status":
                _safe_print("WORKER_STATUS pid=%s batches=%d session=%s" % (
                    session.worker["pid"], session.batch_count, session.session_id))
                continue
            task_timeout_ms = args.task_timeout_ms
            is_directory = False
            if command.startswith("run-timeout "):
                _, timeout_text, value = command.split(" ", 2)
                task_timeout_ms = int(timeout_text)
                is_directory = False
            elif command.startswith("run "):
                value = command[4:].strip()
            elif command.startswith("batch "):
                value = command[6:].strip()
                is_directory = True
            else:
                _safe_print("RUNNER_FAIL unknown_command", file=sys.stderr)
                failures += 1
                continue
            batch_transport_failed = False
            try:
                scripts = _load_script_batch(local_root, value, is_directory)
                nonce, response, status = session.run_batch(
                    scripts, timeout=args.batch_timeout_seconds,
                    task_timeout_ms=task_timeout_ms,
                    guest_working_directory=args.guest_working_directory,
                )
                batch_transport_failed = status != "OK"
                result_code = _report_batch(session, scripts, nonce, response, status, args.display_output_bytes)
                if result_code != 0:
                    failures += 1
            except Exception as exc:
                _safe_print("RUNNER_FAIL %s" % exc, file=sys.stderr)
                failures += 1
            if batch_transport_failed:
                break
            sys.stdout.flush()
            sys.stderr.flush()
    finally:
        try:
            shutdown_status = session.shutdown()
        except Exception as exc:
            shutdown_status = "shutdown_failed: %s" % exc
        _safe_print("WORKER_SHUTDOWN %s" % shutdown_status)
        if shutdown_status != "BYE_AND_SOCKET_CLOSED":
            failures += 1
            _safe_print("RUNNER_FAIL %s" % shutdown_status, file=sys.stderr)
    return 1 if failures else 0


class WorkerProtocolError(RuntimeError):
    pass


class WindowsWorkerSession:
    """One identity-bound guest worker and one bounded, reusable TCP session."""

    def __init__(self, worker_script, artifact_root, host_ip=GUEST_HOST_IP,
                 control_port=GUEST_CONTROL_PORT, http_port=GUEST_BOOTSTRAP_HTTP_PORT,
                 vm_uuid=VM_UUID, connect_timeout=60):
        self.worker_script = Path(worker_script).resolve()
        self.worker_bytes = self.worker_script.read_bytes()
        self.worker_sha = hashlib.sha256(self.worker_bytes).hexdigest()
        self.artifact_root = Path(artifact_root).resolve()
        self.session_id = uuid.uuid4().hex
        self.session_dir = self.artifact_root / "runner-sessions" / self.session_id
        self.session_dir.mkdir(parents=True, exist_ok=False)
        self.host_ip = host_ip
        self.control_port = int(control_port)
        self.http_port = int(http_port)
        self.vm_uuid = vm_uuid
        self.socket = None
        self.protocol_state = "starting"
        self.transport_status = "not_started"
        self.transport_failure = None
        self.worker = None
        self.current_nonce = None
        self.httpd = None
        self.http_thread = None
        self.listener = None
        self.buffer = bytearray()
        self.batch_count = 0
        self.started_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
        self.stopped_at = None
        self.stop_status = "not_requested"
        self.bootstrap = {}
        self._start(connect_timeout)

    @staticmethod
    def _now():
        return datetime.datetime.now(datetime.timezone.utc).isoformat()

    def _start_file_server(self):
        session = self
        transfer_root = session.artifact_root / "guest-transfer"
        transfer_root.mkdir(parents=True, exist_ok=True)

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                parsed = urllib.parse.urlsplit(self.path)
                if parsed.path == "/worker_run.ps1":
                    payload = session.worker_bytes
                    name = "worker_run.ps1"
                elif parsed.path.startswith("/files/"):
                    parts = parsed.path.split("/", 3)
                    if len(parts) != 4 or parts[2] != session.session_id:
                        self.send_error(403, "invalid transfer session")
                        return
                    relative = urllib.parse.unquote(parts[3])
                    candidate = (transfer_root / relative).resolve()
                    if not candidate.is_relative_to(transfer_root.resolve()) or not candidate.is_file():
                        self.send_error(404, "transfer file missing")
                        return
                    payload = candidate.read_bytes()
                    name = candidate.name
                else:
                    self.send_error(404)
                    return
                digest = hashlib.sha256(payload).hexdigest()
                self.send_response(200)
                self.send_header("Content-Type", "application/octet-stream")
                self.send_header("Content-Length", str(len(payload)))
                self.send_header("X-Content-SHA256", digest)
                self.send_header("Content-Disposition", 'attachment; filename="%s"' % name)
                self.end_headers()
                self.wfile.write(payload)

            def do_POST(self):
                parsed = urllib.parse.urlsplit(self.path)
                if not parsed.path.startswith("/results/") or self.headers.get("X-Pharos-Session") != session.session_id:
                    self.send_error(403, "invalid result session")
                    return
                relative = urllib.parse.unquote(parsed.path[len("/results/"):])
                result_root = session.session_dir / "guest-results"
                candidate = (result_root / relative).resolve()
                if not candidate.is_relative_to(result_root.resolve()):
                    self.send_error(400, "invalid result path")
                    return
                try:
                    length = int(self.headers.get("Content-Length", "-1"))
                except ValueError:
                    length = -1
                if length < 0 or length > 512 * 1024 * 1024:
                    self.send_error(413, "result length out of bounds")
                    return
                candidate.parent.mkdir(parents=True, exist_ok=True)
                temporary = candidate.with_suffix(candidate.suffix + ".partial")
                digest = hashlib.sha256()
                remaining = length
                try:
                    with temporary.open("wb") as output:
                        while remaining:
                            block = self.rfile.read(min(1024 * 1024, remaining))
                            if not block:
                                raise ConnectionError("truncated upload")
                            output.write(block)
                            digest.update(block)
                            remaining -= len(block)
                    temporary.replace(candidate)
                except Exception:
                    temporary.unlink(missing_ok=True)
                    self.send_error(400, "upload failed")
                    return
                body = json.dumps({"path": str(candidate), "bytes": length,
                                   "sha256": digest.hexdigest()}, ensure_ascii=False).encode("utf-8")
                self.send_response(201)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, fmt, *args):
                with (session.session_dir / "bootstrap-http.log").open("a", encoding="utf-8") as fh:
                    fh.write((fmt % args) + "\n")

        self.httpd = http.server.ThreadingHTTPServer(("0.0.0.0", self.http_port), Handler)
        self.httpd.daemon_threads = True
        self.http_thread = threading.Thread(target=self.httpd.serve_forever, name="pharos-worker-http", daemon=True)
        self.http_thread.start()

    def _start_listener(self):
        self.listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.listener.bind(("0.0.0.0", self.control_port))
        self.listener.listen(4)
        self.listener.settimeout(0.5)

    def _bootstrap_command(self):
        remote = GUEST_WORKER_PATH
        session = self.session_id
        url = "http://%s:%d/worker_run.ps1" % (self.host_ip, self.http_port)
        # Keep this one bootstrap command well below the empirically verified
        # Parallels exec command-line ceiling. All later work uses the worker.
        command = (
            "$ErrorActionPreference='Stop';"
            "$p='%s';$sid='%s';$u='%s';$tmp=$p+'.new';"
            "if(Test-Path -LiteralPath $p){$b=[IO.File]::ReadAllBytes($p);"
            "Write-Output ('OLD_SCRIPT_SHA='+(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant());"
            "Write-Output ('OLD_SCRIPT_BYTES='+$b.Length);"
            "if($b.Length -le 131072){Write-Output ('OLD_SCRIPT_B64='+[Convert]::ToBase64String($b))}"
            "else{Write-Output 'OLD_SCRIPT_B64=too_large'}}"
            "else{Write-Output 'OLD_SCRIPT_SHA=missing'};"
            "Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $tmp;"
            "$h=(Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash.ToLowerInvariant();"
            "if($h -ne '%s'){throw ('WORKER_HASH_MISMATCH '+$h)};"
            "if(Test-Path -LiteralPath $p){Move-Item -LiteralPath $p -Destination ($p+'.before-'+$sid)};"
            "Move-Item -LiteralPath $tmp -Destination $p;"
            "$w=Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru "
            "-ArgumentList @('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass',"
            "'-File',$p,'-HostIp','%s','-Port','%d','-SessionId',$sid,'-TransferBase','http://%s:%d');"
            "Write-Output ('BOOTSTRAPPED_PID='+$w.Id)"
        ) % (remote, session, url, self.worker_sha, self.host_ip, self.control_port, self.host_ip, self.http_port)
        if len(command) > 1500:
            raise WorkerProtocolError("bootstrap_command_exceeds_verified_exec_limit: %d" % len(command))
        return command

    def _bootstrap_guest(self):
        self._start_file_server()
        self._start_listener()
        command = self._bootstrap_command()
        started = time.monotonic()
        proc = subprocess.run(
            ["prlctl", "exec", self.vm_uuid, "--current-user", "powershell.exe",
             "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
             "-Command", command],
            capture_output=True, timeout=120,
        )
        output = proc.stdout.decode("utf-8", "replace")
        error = proc.stderr.decode("utf-8", "replace")
        self.bootstrap = {
            "exit_code": proc.returncode,
            "stdout": output,
            "stderr": error,
            "command_chars": len(command),
            "elapsed_seconds": time.monotonic() - started,
            "http_port": self.http_port,
            "control_port": self.control_port,
        }
        (self.session_dir / "bootstrap.json").write_text(
            json.dumps(self.bootstrap, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        if proc.returncode != 0 or "BOOTSTRAPPED_PID=" not in output:
            raise WorkerProtocolError("guest_worker_bootstrap_failed: rc=%d %s" % (proc.returncode, error.strip()))
        self._save_prior_worker(output)

    def _save_prior_worker(self, output):
        old_sha = None
        old_bytes = None
        old_b64 = None
        for line in output.splitlines():
            if line.startswith("OLD_SCRIPT_SHA="):
                old_sha = line.split("=", 1)[1]
            elif line.startswith("OLD_SCRIPT_BYTES="):
                try:
                    old_bytes = int(line.split("=", 1)[1])
                except ValueError:
                    old_bytes = None
            elif line.startswith("OLD_SCRIPT_B64="):
                old_b64 = line.split("=", 1)[1]
        self.bootstrap["prior_worker_path"] = GUEST_WORKER_PATH
        self.bootstrap["prior_worker_sha256"] = old_sha
        self.bootstrap["prior_worker_bytes"] = old_bytes
        if old_b64 and old_b64 != "too_large":
            try:
                raw = base64.b64decode(old_b64, validate=True)
                if old_bytes == len(raw) and (old_sha == "missing" or hashlib.sha256(raw).hexdigest() == old_sha):
                    (self.session_dir / "worker_run-before.ps1").write_bytes(raw)
                    self.bootstrap["prior_worker_source_saved"] = True
                else:
                    self.bootstrap["prior_worker_source_saved"] = False
            except (ValueError, base64.binascii.Error):
                self.bootstrap["prior_worker_source_saved"] = False
        (self.session_dir / "bootstrap.json").write_text(
            json.dumps(self.bootstrap, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        self._write_session_manifest()

    def _accept_worker(self, timeout):
        deadline = time.monotonic() + timeout
        last_error = None
        while time.monotonic() < deadline:
            try:
                conn, address = self.listener.accept()
            except socket.timeout:
                continue
            conn.settimeout(0.5)
            try:
                line = self._read_line_from(conn, time.monotonic() + 5, byte_limit=8192)
                if line is None or not line.startswith("HELLO "):
                    raise WorkerProtocolError("worker_missing_hello")
                hello = json.loads(line[6:])
                if hello.get("session_id") != self.session_id:
                    raise WorkerProtocolError("stale_worker_session")
                if hello.get("worker_path") != GUEST_WORKER_PATH:
                    raise WorkerProtocolError("worker_path_mismatch")
                if hello.get("worker_sha256") != self.worker_sha:
                    raise WorkerProtocolError("worker_sha256_mismatch")
                if type(hello.get("pid")) is not int or hello["pid"] <= 0:
                    raise WorkerProtocolError("worker_pid_invalid")
                conn.sendall(("ACK %s\n" % self.session_id).encode("utf-8"))
                self.socket = conn
                self.worker = hello
                self.worker["guest_address"] = address[0]
                self.worker["accepted_at"] = self._now()
                self.protocol_state = "connected"
                self.transport_status = "connected"
                self._write_session_manifest()
                return
            except Exception as exc:
                last_error = exc
                try:
                    conn.sendall(b"REJECT\n")
                except OSError:
                    pass
                conn.close()
        raise WorkerProtocolError("worker_connect_timeout: %s" % last_error)

    @staticmethod
    def _read_line_from(conn, deadline, byte_limit=65536):
        data = bytearray()
        while time.monotonic() < deadline:
            try:
                chunk = conn.recv(1)
            except socket.timeout:
                continue
            if not chunk:
                if data:
                    raise WorkerProtocolError(
                        "incomplete_protocol_line_eof: bytes=%d" % len(data))
                return None
            if chunk == b"\n":
                try:
                    return bytes(data).decode("utf-8", "strict")
                except UnicodeDecodeError as exc:
                    raise WorkerProtocolError("protocol_line_invalid_utf8") from exc
            data.extend(chunk)
            if len(data) > byte_limit:
                raise WorkerProtocolError("line_too_large")
        raise TimeoutError("line_deadline_expired")

    @staticmethod
    def _read_exact_from(conn, length, deadline, byte_limit=MAX_RESULT_BYTES):
        if length < 0 or length > byte_limit:
            raise WorkerProtocolError("frame_length_out_of_bounds: %d" % length)
        chunks = []
        remaining = length
        while remaining:
            if time.monotonic() >= deadline:
                raise TimeoutError("frame_deadline_expired")
            try:
                part = conn.recv(min(65536, remaining))
            except socket.timeout:
                continue
            if not part:
                raise WorkerProtocolError("frame_truncated: wanted=%d got=%d" % (length, length - remaining))
            chunks.append(part)
            remaining -= len(part)
        return b"".join(chunks)

    def _send_line(self, line):
        self.socket.sendall(line.encode("utf-8") + b"\n")

    def _retire_protocol_session(self, reason):
        self.transport_failure = str(reason)
        self.transport_status = "transport_failed: %s" % self.transport_failure
        self.protocol_state = "retired"
        connection = self.socket
        self.socket = None
        if connection is not None:
            try:
                connection.close()
            except OSError:
                pass

    def _start(self, connect_timeout):
        try:
            self._bootstrap_guest()
            self._accept_worker(connect_timeout)
        except Exception:
            self._stop_servers()
            raise

    def run_batch(self, scripts, timeout=1800, task_timeout_ms=300000, guest_working_directory=GUEST_HOME):
        if getattr(self, "protocol_state", "connected") == "retired":
            raise WorkerProtocolError("worker_session_retired: %s" % self.transport_failure)
        if not self.socket or not self.worker:
            raise WorkerProtocolError("worker_session_not_connected")
        if not scripts or len(scripts) > 16:
            raise WorkerProtocolError("batch_job_count_out_of_range")
        if len(set(scripts)) != len(scripts):
            raise WorkerProtocolError("duplicate_job_name")
        try:
            task_timeout_ms = int(task_timeout_ms)
        except (TypeError, ValueError, OverflowError) as exc:
            raise WorkerProtocolError("task_timeout_invalid") from exc
        if task_timeout_ms < 1 or task_timeout_ms > MAX_JOB_TIMEOUT_MS:
            raise WorkerProtocolError("task_timeout_out_of_bounds")
        nonce = uuid.uuid4().hex
        jobs = []
        for name, source in scripts.items():
            if not isinstance(name, str) or not name or "\n" in name:
                raise WorkerProtocolError("invalid_job_name")
            if not isinstance(source, str):
                raise WorkerProtocolError("job_source_must_be_text: %s" % name)
            jobs.append({
                "name": name,
                "script": source,
                "timeout_ms": int(task_timeout_ms),
                "working_directory": guest_working_directory,
            })
        request = json.dumps({"nonce": nonce, "jobs": jobs}, ensure_ascii=False,
                             separators=(",", ":")).encode("utf-8")
        if len(request) > MAX_REQUEST_BYTES:
            raise WorkerProtocolError("batch_request_too_large")
        self.current_nonce = nonce
        timeout = minimum_batch_timeout_seconds(
            timeout, [task_timeout_ms] * len(jobs))
        deadline = time.monotonic() + timeout
        try:
            self._send_line("BATCH %d %s" % (len(request), nonce))
            self.socket.sendall(request + b"\n")
            header = self._read_line_from(self.socket, deadline, byte_limit=8192)
            if header is None:
                raise WorkerProtocolError("worker_closed_before_results")
            parts = header.split()
            if len(parts) != 3 or parts[0] != "RESULTS":
                raise WorkerProtocolError("unexpected_results_header: %s" % header[:120])
            if parts[2] != nonce:
                raise WorkerProtocolError("response_nonce_mismatch")
            try:
                length = int(parts[1])
            except ValueError as exc:
                raise WorkerProtocolError("results_length_invalid") from exc
            body = self._read_exact_from(self.socket, length, deadline)
            if self._read_line_from(self.socket, deadline, byte_limit=1) != "":
                raise WorkerProtocolError("results_frame_terminator_missing")
            response = json.loads(body.decode("utf-8", "strict"))
            self._send_line("ACK %s" % nonce)
            done = self._read_line_from(self.socket, deadline, byte_limit=8192)
            if done != "DONE %s" % nonce:
                raise WorkerProtocolError("batch_terminal_mismatch: %s" % (done or "EOF"))
            self.batch_count += 1
            self.transport_status = "OK"
            return nonce, response, "OK"
        except Exception as exc:
            status = "transport_failed: %s" % exc
            self._retire_protocol_session(exc)
            return nonce, None, status

    def request_cancel(self):
        """Ask the active batch to stop its running task with a named CANCEL.

        The worker only accepts the CANCEL whose nonce matches the batch it is
        currently executing, so a stale cancel can never stop an unrelated
        task. Returns True when the frame was sent.
        """
        if not self.socket or not self.current_nonce:
            return False
        try:
            self._send_line("CANCEL %s" % self.current_nonce)
            return True
        except OSError:
            return False

    def shutdown(self, timeout=5):
        if self.protocol_state == "retired":
            if self.stop_status == "not_requested":
                self.stop_status = "shutdown_unavailable_after_transport_failure: %s" % (
                    self.transport_failure or "protocol_session_retired")
                self.stopped_at = self._now()
                try:
                    self._write_session_manifest()
                finally:
                    self._stop_servers()
            return self.stop_status
        if self.socket is None:
            return self.stop_status
        connection = self.socket
        deadline = time.monotonic() + timeout
        try:
            self._send_line("STOP %s" % self.session_id)
            line = self._read_line_from(connection, deadline, byte_limit=8192)
            if line != "BYE %s %s" % (self.worker["pid"], self.session_id):
                raise WorkerProtocolError("shutdown_ack_mismatch: %s" % (line or "EOF"))
            eof = self._read_line_from(connection, deadline, byte_limit=8192)
            if eof is not None:
                raise WorkerProtocolError("worker_sent_data_after_bye")
            self.stop_status = "BYE_AND_SOCKET_CLOSED"
        except Exception as exc:
            self.stop_status = "shutdown_failed: %s" % exc
        finally:
            self.socket = None
            try:
                connection.close()
            except OSError:
                pass
            self.protocol_state = "closed" if self.stop_status == "BYE_AND_SOCKET_CLOSED" else "shutdown_failed"
            self.stopped_at = self._now()
            try:
                self._write_session_manifest()
            finally:
                self._stop_servers()
        return self.stop_status

    def _write_session_manifest(self):
        data = {
            "session_id": self.session_id,
            "vm_uuid": self.vm_uuid,
            "guest_worker_path": GUEST_WORKER_PATH,
            "local_worker_path": str(self.worker_script),
            "worker_sha256": self.worker_sha,
            "started_at": self.started_at,
            "worker": self.worker,
            "batch_count": self.batch_count,
            "protocol_state": self.protocol_state,
            "transport_status": self.transport_status,
            "transport_failure": self.transport_failure,
            "stop_status": self.stop_status,
            "stopped_at": self.stopped_at,
            "bootstrap": self.bootstrap,
        }
        (self.session_dir / "session.json").write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def _stop_servers(self):
        if self.listener is not None:
            try:
                self.listener.close()
            except OSError:
                pass
            self.listener = None
        if self.httpd is not None:
            try:
                self.httpd.shutdown()
                self.httpd.server_close()
            except Exception:
                pass
            self.httpd = None
        if self.http_thread is not None:
            self.http_thread.join(timeout=2)
            self.http_thread = None


def legacy_main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    arg = sys.argv[1]
    if os.path.isdir(arg):
        paths = sorted(glob.glob(os.path.join(arg, "*.ps1")))
    else:
        paths = [arg]

    scripts = {}
    for p in paths:
        with open(p, "r", encoding="utf-8") as fh:
            scripts[os.path.basename(p)] = fh.read()
    print("准备执行 %d 个任务: %s" % (len(scripts), ", ".join(scripts)))

    results, status = run_batch(scripts)
    print("状态: %s" % status)
    if results is None:
        return 1

    try:
        codes = validate_batch_results(scripts, results, status)
    except ValueError as exc:
        print("RUNNER_FAIL %s" % exc, file=sys.stderr)
        for name, body in results.items():
            print("\n########## partial %s ##########" % name)
            sys.stdout.write(body)
        return 1

    rc = 0
    for name, code in codes:
        body = results[name]
        print("\n########## %s ##########" % name)
        sys.stdout.write(body)
        if code != 0:
            rc = code
    return rc


if __name__ == "__main__":
    sys.exit(interactive_main())
