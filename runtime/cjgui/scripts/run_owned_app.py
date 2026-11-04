#!/usr/bin/env python3
"""One bounded native instance; preserve logs and retire only its own endpoints."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import sys
import time

parser = argparse.ArgumentParser()
parser.add_argument('--output-root', type=Path, required=True, help='Owned evidence root for this run')
parser.add_argument('--timeout-seconds', type=int, default=1800,
                    help='Bound this owned session, including manual acceptance (maximum 7200).')
parser.add_argument('case')
parser.add_argument('executable', type=Path)
parser.add_argument('sdk', type=Path)
parser.add_argument('args', nargs=argparse.REMAINDER)
args = parser.parse_args()
assert re.fullmatch(r'[a-z0-9-]+', args.case), 'A case is a local filename label.'
assert 0 < args.timeout_seconds <= 7200, 'Owned session timeout must be bounded.'
root = args.output_root.resolve()
out = root / 'normal'
out.mkdir(exist_ok=True)
log = out / (args.case + '.log')
result = out / (args.case + '.json')
assert not log.exists() and not result.exists(), 'A case cannot be replayed over its original.'
metadata_runtime = args.sdk / 'framework/cjgui'
if not (metadata_runtime / 'shared_operation_core/client.py').is_file():
    metadata_runtime = args.sdk
assert (metadata_runtime / 'shared_operation_core/client.py').is_file(), 'Runtime metadata client missing.'
sys.path.insert(0, str(metadata_runtime / 'shared_operation_core'))
from client import parse_descriptor

def interrupted(_signum, _frame):
    raise KeyboardInterrupt()

def observe_fallback_diagnostic(line, sessions):
    """Stop an opted-in diagnostic at an observed repeat or trace budget end."""
    if not line.startswith('CJGUI_FALLBACK_DIAG '):
        return None
    facts = dict(re.findall(r'(\w+)=([^ ]+)', line.strip()))
    if facts.get('truncated') == 'true':
        return {'reason': 'bounded_trace_exhausted', 'boundary': facts}
    try:
        session, generation, handoff, preparation, stage, status = (
            int(facts[key]) for key in ('session', 'generation', 'handoff',
                                       'preparation', 'stage', 'status'))
    except (KeyError, ValueError):
        return None
    if not 1 <= session <= 4 or generation <= 0 or handoff <= 0 or preparation <= 0:
        return None  # An unknown handoff is not progress or a new budget.
    previous = sessions.get(session)
    if previous is None or previous['identity'] != (generation, handoff):
        previous = {'identity': (generation, handoff), 'failure': None}
        sessions[session] = previous
    failure = previous['failure']
    if failure is not None and preparation != int(failure['preparation']):
        return {'reason': 'same_handoff_candidate_repeated',
                'first_failure': failure, 'boundary': facts}
    if stage in (22, 24, 25) and status != 0:
        previous['failure'] = facts
    return None

signal.signal(signal.SIGTERM, interrupted)
signal.signal(signal.SIGINT, interrupted)
started = time.time()
record = {'executable': str(args.executable.resolve()),
          'exe_sha256': hashlib.sha256(args.executable.read_bytes()).hexdigest(),
          'args': args.args, 'started': started, 'log': str(log), 'endpoints': [],
          'log_limit_bytes': 64 * 1024 * 1024, 'timeout_seconds': args.timeout_seconds}
record['descriptor_parser_runtime'] = str(metadata_runtime.resolve())
if 'CJGUI_DISPLAY_OPPORTUNITY' in os.environ:
    # This records the requested process environment, not proof of the runtime scheduler path.
    record['requested_scheduler_mode'] = os.environ['CJGUI_DISPLAY_OPPORTUNITY']
record['diagnostic_environment'] = {key: os.environ[key] for key in (
    'CJGUI_INPUT_LINK_TRACE', 'CJGUI_EARLY_KEY_TRACE', 'CJGUI_KEY_ENTRY_TRACE',
    'CJGUI_DISPLAY_OPPORTUNITY',
    'CJGUI_FRAME_CADENCE_TRACE_PATH', 'CJGUI_OWNER_PHASE_TRACE',
    'CJGUI_OWNER_TRACE_LIGHT', 'CJGUI_OWNER_TURN_COST', 'CJGUI_OWNER_WAIT_TRACE',
    'CJGUI_OWNER_TRACE_TARGET_RAW', 'CJGUI_OWNER_TRACE_TARGET_SESSION',
    'CJGUI_OWNER_TRACE_TARGET_GENERATION',
    'CJGUI_OWNER_TRACE_TARGET_EVENT_USERDATA',
    'CJGUI_OWNER_TRACE_TARGET_EVENT_SOURCE_PID',
    'CJGUI_RULE_SET_OWNER_WRITE_DIAGNOSTICS', 'CJGUI_PREPARE_FAILURE_TRACE',
    'CJGUI_CLOSE_LIFECYCLE_TRACE', 'CJGUI_PREPARATION_SOURCE_FIRST_REFUSAL',
    'CJGUI_RULE_SET_ATTRIBUTION_SNAPSHOT', 'CJGUI_FOCUS_SCROLL_TRACE',
    'CJGUI_PREPARATION_PACKET_TRACE') if key in os.environ}
fallback_diagnostic_enabled = os.environ.get('CJGUI_PREPARATION_SOURCE_FIRST_REFUSAL') == '1'
fallback_diagnostic_sessions = {}
child = None
known = {}
def save_record():
    pending = result.with_suffix('.json.pending')
    pending.write_text(json.dumps(record, indent=2) + '\n')
    os.replace(pending, result)

try:
    with log.open('xb') as sink:
        child = subprocess.Popen([str(args.executable), *args.args], stdout=sink,
                                 stderr=subprocess.STDOUT, cwd=args.executable.parent)
        record['pid'] = child.pid
        save_record()
        position, carry = 0, ''
        while True:
            if log.stat().st_size > record['log_limit_bytes']:
                raise RuntimeError('Log exceeded the reserved limit; evidence is not a pass.')
            if time.time() - started > record['timeout_seconds']:
                raise TimeoutError('Owned acceptance instance timed out.')
            with log.open('r', errors='replace') as stream:
                stream.seek(position)
                carry += stream.read()
                position = stream.tell()
            lines = carry.split('\n')
            carry = lines.pop()
            for line in lines:
                if fallback_diagnostic_enabled:
                    boundary = observe_fallback_diagnostic(line, fallback_diagnostic_sessions)
                    if boundary is not None:
                        record['diagnostic_boundary'] = boundary
                        raise RuntimeError('Bounded fallback diagnostic reached ' + boundary['reason'])
                match = re.match(r'^(?:CJGUI_(?:MIXED_FORM|RULE_SET|SHARED_DOCUMENT)_READY|PHAROS_EXTERNAL) DESCRIPTOR_PATH (.+)$', line)
                if not match or match[1] in known:
                    continue
                descriptor = Path(match[1])
                try:
                    info = descriptor.stat()
                    assert info.st_uid == os.getuid() and info.st_mtime >= started - 1
                    data = parse_descriptor(descriptor)
                    known[str(descriptor)] = {
                        'descriptor': str(descriptor), 'socket': str(data['socket_path']),
                        'descriptor_sha256': hashlib.sha256(descriptor.read_bytes()).hexdigest(),
                        'socket_identity': [Path(data['socket_path']).stat().st_dev, Path(data['socket_path']).stat().st_ino]}
                except FileNotFoundError:
                    continue  # The process already removed its private endpoint.
                record['endpoints'] = list(known.values())
                save_record()
            if child.poll() is not None:
                record['exit_code'] = child.returncode
                break
            try:
                child.wait(timeout=1)
            except subprocess.TimeoutExpired:
                pass
except BaseException as error:
    record['failure'] = type(error).__name__ + ': ' + str(error)
finally:
    # An unreaped Popen child cannot be a reused, unrelated PID.
    if child is not None and child.poll() is None:
        child.terminate()
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
        record['forced_exit_code'] = child.returncode
    for endpoint in known.values():
        descriptor, socket = Path(endpoint['descriptor']), Path(endpoint['socket'])
        endpoint['left_after_process'] = [str(p) for p in (descriptor, socket) if p.exists()]
        if (socket.exists() and socket.stat().st_uid == os.getuid() and stat.S_ISSOCK(socket.stat().st_mode)
                and [socket.stat().st_dev, socket.stat().st_ino] == endpoint['socket_identity']):
            socket.unlink()
        if descriptor.exists() and hashlib.sha256(descriptor.read_bytes()).hexdigest() == endpoint['descriptor_sha256']:
            descriptor.unlink()
        for parent in {descriptor.parent, socket.parent}:
            if parent.name.startswith(('cjgui', 'tmpDir')) and parent.is_dir() and not any(parent.iterdir()):
                parent.rmdir()
        endpoint['left_after_cleanup'] = [str(p) for p in (descriptor, socket) if p.exists()]
    record['ended'] = time.time()
    record['log_sha256'] = hashlib.sha256(log.read_bytes()).hexdigest()
    save_record()
    print(json.dumps(record, ensure_ascii=False))
sys.exit(0 if record.get('exit_code') == 0 and 'failure' not in record
         and all(not e.get('left_after_cleanup') for e in known.values()) else 1)
