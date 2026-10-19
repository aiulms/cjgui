"""Bounded output and owned collector lifetime for the normal H device drivers.

No old output, package, fixture, userdata or other process is removed here.
The caller creates its exclusive output directory and owns its device/forward.
"""
import hashlib
import json
import os
import re
from pathlib import Path
import subprocess
import threading
import time

GIB = 1024 ** 3
MIB = 1024 ** 2


def allocated(path):
    total = 0
    seen = set()
    for base, dirs, files in os.walk(path, followlinks=False):
        dirs[:] = [d for d in dirs if not (Path(base) / d).is_symlink()]
        for name in files:
            stat = (Path(base) / name).lstat()
            key = (stat.st_dev, stat.st_ino)
            if key not in seen:
                seen.add(key)
                total += stat.st_blocks * 512
    return total


class OutputBudget:
    def __init__(self, out, bridge, peak=4 * GIB, guest_peak=0):
        self.out = Path(out).resolve()
        self.round_root = Path(os.environ.get('CJGUI_H_OUTPUT_ROOT', self.out)).resolve()
        if not self.out.is_relative_to(self.round_root):
            raise RuntimeError('output is outside this owned round')
        if 'CJGUI_H_OUTPUT_ROOT' in os.environ and not (self.round_root / 'space-before.json').is_file():
            raise RuntimeError('owned round has no recorded startup budget')
        self.bridge = bridge
        self.before = self.free()
        self.peak = peak
        self.guest_before = None
        self.closed_collectors = []
        self.retired_remote = []
        if self.before - peak < int(33.6 * GIB):
            raise RuntimeError('H output peak would breach SDK/host reserve; no intent sent')
        if guest_peak:
            raw = bridge.hdc('shell', 'df', '-k', '/data')
            if raw.returncode != 0:
                raise RuntimeError('guest capacity unavailable; no intent sent')
            self.guest_before = int(raw.stdout.splitlines()[-1].split()[3]) * 1024
            if self.guest_before < guest_peak + GIB:
                raise RuntimeError('guest output peak would breach reserve; no intent sent')
        self.write('started')

    def free(self):
        stat = os.statvfs(self.out)
        return stat.f_bavail * stat.f_frsize

    def check(self):
        if self.free() < int(33.6 * GIB):
            raise RuntimeError('H host reserve exhausted; stop new intents')
        if allocated(self.round_root) > 10 * GIB:
            raise RuntimeError('H new retained output exceeds 10GiB; stop new intents')
        logs = [p for p in self.round_root.rglob('*')
                if p.is_file() and not p.is_symlink() and p.suffix in ('.txt', '.log')]
        if any(p.stat().st_size > 64 * MIB for p in logs):
            raise RuntimeError('H single log exceeds 64MiB; evidence incomplete')
        if sum(p.stat().st_size for p in logs) > 512 * MIB:
            raise RuntimeError('H round logs exceed 512MiB; evidence incomplete')

    def write(self, status, error=None):
        result = dict(status=status, timestamp=time.time(), output=str(self.out),
                      host_before_bytes=self.before, host_now_bytes=self.free(),
                      planned_peak_bytes=self.peak, host_reserve_GiB=33.6,
                      retained_limit_bytes=10 * GIB, allocated_bytes=allocated(self.out),
                      round_root=str(self.round_root), round_allocated_bytes=allocated(self.round_root),
                      guest_before_bytes=self.guest_before, error=error,
                      closed_collectors=self.closed_collectors,
                      retired_remote=self.retired_remote,
                      old_outputs_removed=False)
        (self.out / 'output-space.json').write_text(json.dumps(result, indent=2) + '\n')

    def retire_layout(self, remote, local):
        """Retire this invocation's unique layout only after exact transfer verification."""
        if not re.fullmatch(r'/data/local/tmp/h-owned-layout-[0-9a-f]{32}\.json', remote):
            raise RuntimeError('unowned remote layout')
        local = Path(local)
        transfer = self.bridge.hdc('file', 'recv', remote, str(local), timeout=10)
        if transfer.returncode != 0 or not local.is_file():
            self.retired_remote.append(dict(path=remote, retired=False, reason='transfer unavailable'))
            return
        digest = hashlib.sha256(local.read_bytes()).hexdigest()
        response = self.bridge.hdc('shell', 'sha256sum', remote, timeout=10)
        if response.returncode != 0 or not response.stdout.startswith(digest + ' '):
            self.retired_remote.append(dict(path=remote, retired=False, reason='hash not confirmed'))
            return
        deleted = self.bridge.hdc('shell', 'rm', remote, timeout=10)
        # HDC can report exit 0 for a failing remote command. Confirm actual absence.
        absence = self.bridge.hdc('shell', 'if test -e ' + remote +
                                  '; then echo PRESENT; else echo ABSENT; fi', timeout=10)
        self.retired_remote.append(dict(path=remote, retired=deleted.returncode == 0 and
                                        absence.stdout.strip() == 'ABSENT',
                                        host_copy=str(local), sha256=digest))


class BoundedCollector:
    def __init__(self, command, path, budget, limit=64 * MIB):
        self.budget = budget
        self.limit = limit
        self.received = 0
        self.error = None
        self.file = Path(path).open('xb', buffering=0)
        try:
            self.process = subprocess.Popen(command, stdout=subprocess.PIPE,
                                            stderr=subprocess.STDOUT)
        except BaseException:
            self.file.close()
            raise
        self.thread = threading.Thread(target=self.read, daemon=True)
        self.thread.start()

    def read(self):
        try:
            while True:
                block = os.read(self.process.stdout.fileno(), 65536)
                if not block:
                    break
                if self.received + len(block) > self.limit:
                    self.error = 'log evidence exceeds 64MiB; incomplete evidence, no green'
                    self.process.terminate()
                    break
                self.file.write(block)
                self.received += len(block)
        except BaseException as error:
            self.error = repr(error)

    def check(self):
        self.budget.check()
        if self.error:
            raise RuntimeError(self.error)

    def close(self):
        if self.process.poll() is None:
            self.process.terminate()
        try:
            self.process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            self.process.kill()  # Only this newly spawned collector, never the app or VM.
            self.process.wait(timeout=3)
        self.thread.join(timeout=3)
        if self.thread.is_alive():
            self.error = 'collector reader did not finish; evidence incomplete'
        self.process.stdout.close()
        self.file.close()
        self.budget.closed_collectors.append(dict(pid=self.process.pid,
                                                  exit=self.process.returncode,
                                                  bytes=self.received, error=self.error))


def retire_capture_directory(budget, remote, local):
    """Copy and verify this invocation's finite capture files before retirement."""
    if not re.fullmatch(r'/data/local/tmp/h-owned-capture-[0-9a-f]{32}', remote):
        raise RuntimeError('unowned capture directory')
    response = budget.bridge.hdc('shell', 'sha256sum ' + remote + '/*', timeout=15)
    manifest = {}
    for line in response.stdout.splitlines():
        match = re.fullmatch(r'([0-9a-f]{64})  ' + re.escape(remote) + r'/([^/]+)', line)
        if not match or not re.fullmatch(r'capture\.sh|[0-9]+-(?:gesture|marker)-[0-9]+\.[a-z-]+', match[2]):
            raise RuntimeError('capture hash manifest is incomplete or has an unowned file')
        manifest[match[2]] = match[1]
    if not 1 <= len(manifest) <= 600:
        raise RuntimeError('capture file count is outside its finite budget')
    local = Path(local)
    local.mkdir(exist_ok=False)
    (budget.out / 'capture-sha256-before.txt').write_text(response.stdout)
    response = budget.bridge.hdc('file', 'recv', remote, str(local), timeout=30)
    candidates = [local, local / Path(remote).name]
    archive = next((p for p in candidates if (p / 'capture.sh').is_file()), None)
    if response.returncode != 0 or archive is None:
        raise RuntimeError('capture archive transfer failed; remote originals retained')
    files = {p.name: p for p in archive.iterdir()}
    if files.keys() != manifest.keys():
        raise RuntimeError('capture archive file set differs; remote originals retained')
    total = 0
    for name, digest in manifest.items():
        path = files[name]
        if path.is_symlink() or not path.is_file() or path.stat().st_size > 16 * MIB:
            raise RuntimeError('capture archive has an invalid file')
        if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise RuntimeError('capture archive bytes differ; remote originals retained')
        total += path.stat().st_size
    names = list(manifest)
    for offset in range(0, len(names), 30):
        budget.bridge.hdc('shell', 'rm', *[remote + '/' + n for n in names[offset:offset + 30]], timeout=15)
    budget.bridge.hdc('shell', 'rmdir', remote, timeout=10)
    absence = budget.bridge.hdc('shell', 'if test -e ' + remote +
                                '; then echo PRESENT; else echo ABSENT; fi', timeout=10)
    retired = absence.stdout.strip() == 'ABSENT'
    budget.retired_remote.append(dict(path=remote, retired=retired, host_copy=str(archive),
                                      files=len(manifest), logical_bytes=total))
    if not retired:
        raise RuntimeError('capture directory retirement was not confirmed')
