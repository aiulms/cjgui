#!/usr/bin/env python3
"""Explicit Linux application builds. Generated inputs are not editable source.

One output root owns its source snapshot, native archive, target and receipt.
The output lock covers preparation, compilation and the complete running child.
SSH transports these tools only; application/framework paths belong to Linux.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import platform
import re
import selectors
import shlex
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
import uuid

if sys.version_info < (3, 11):
    raise SystemExit("CJGUI Linux application tools require Python 3.11+")
import tomllib

HERE = Path(__file__).resolve().parent
MAX_LOG = 64 * 1024 * 1024


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=".cjgui-write-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
        os.replace(name, path)
    finally:
        if os.path.exists(name): os.unlink(name)


def manifest(root):
    data = tomllib.loads((root / "cjpm.toml").read_text())
    if "workspace" in data or not isinstance(data.get("package"), dict):
        raise ValueError(f"single-package cjpm.toml required: {root}")
    return data


def toml_value(value):
    if isinstance(value, str): return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool): return "true" if value else "false"
    if isinstance(value, (int, float)): return repr(value)
    if isinstance(value, list): return "[" + ", ".join(toml_value(v) for v in value) + "]"
    raise ValueError(f"unsupported TOML value: {value!r}")


def write_manifest(path, data):
    lines = ["# Generated Linux build configuration; edit the original package."]
    def section(table, keys=()):
        if keys: lines.append("[" + ".".join(toml_value(k) for k in keys) + "]")
        for key, value in table.items():
            if not isinstance(value, dict): lines.append(toml_value(key) + " = " + toml_value(value))
        for key, value in table.items():
            if isinstance(value, dict): section(value, keys + (key,))
    section(data)
    text = "\n".join(lines) + "\n"
    if tomllib.loads(text) != data: raise ValueError("generated TOML did not round-trip")
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_text() != text: path.write_text(text)


def residual_marker(output):
    return output / "logs/residual-process-group.json"


def refuse_live_residual(output):
    """A group that outlived its runner blocks reuse until it is really gone."""
    marker = residual_marker(output)
    if not marker.exists(): return
    try:
        record = json.loads(marker.read_text())
        pgid = record["pgid"]
        if not isinstance(pgid, int): raise ValueError("pgid")
    except (OSError, ValueError, KeyError, TypeError):
        raise ValueError(f"residual_process_group_marker_invalid: {marker}")
    if group_alive(pgid):
        raise ValueError(f"residual_process_group: pgid {pgid} still alive; refusing {output}")
    marker.unlink(missing_ok=True)


@contextmanager
def output_lock(output, application=None):
    if output.is_symlink(): raise ValueError("output root must not be a symlink")
    output.mkdir(parents=True, exist_ok=True)
    with (output / ".lock").open("a") as lock:
        try: fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError: raise ValueError(f"output_busy: {output}")
        refuse_live_residual(output)
        marker = output / "output-owner.json"
        if marker.exists():
            owner = json.loads(marker.read_text())
            if owner.get("format") != 1 or owner.get("output") != str(output):
                raise ValueError("unrecognized output ownership")
            if application is not None and owner["application"] != str(application):
                raise ValueError("output belongs to another application")
        else:
            if application is None: raise ValueError("no owned build output")
            if any(p.name != ".lock" for p in output.iterdir()):
                raise ValueError("nonempty unowned output; choose a new application output root")
            save(marker, {"format": 1, "output": str(output), "application": str(application)})
        yield


def toolchain_environment(path):
    source = path / "envsetup.sh" if path.is_dir() else path
    if not source.is_file(): raise ValueError(f"toolchain envsetup.sh missing: {source}")
    result = subprocess.run(["bash", "-c", 'set -e; source "$1" >/dev/null; env -0',
                             "cjgui-toolchain", str(source)], capture_output=True, check=True)
    env = dict(item.decode(errors="surrogateescape").split("=", 1)
               for item in result.stdout.split(b"\0") if b"=" in item)
    if not shutil.which("cjpm", path=env.get("PATH")): raise ValueError("cjpm missing from explicit toolchain")
    return env, source


class StepFailure(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = 128 - code if code < 0 else code if 0 < code < 256 else 1


def group_alive(pgid):
    try:
        os.killpg(pgid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def stop_process_group(child, grace=5.0):
    """Stop the whole own process group, not only its exited leader.

    A compiler may exit while a descendant that ignores SIGTERM keeps running.
    The output lock must stay held until that descendant is gone too.
    """
    pgid = child.pid
    if child.poll() is None or group_alive(pgid):
        try: os.killpg(pgid, signal.SIGTERM)
        except ProcessLookupError: pass
        deadline = time.monotonic() + grace
        while time.monotonic() < deadline:
            if child.poll() is None:
                try: child.wait(timeout=0.05)
                except subprocess.TimeoutExpired: pass
            if not group_alive(pgid): break
            time.sleep(0.05)
        if group_alive(pgid):
            try: os.killpg(pgid, signal.SIGKILL)
            except ProcessLookupError: pass
        deadline = time.monotonic() + grace
        while group_alive(pgid) and time.monotonic() < deadline:
            time.sleep(0.05)
    try: child.wait(timeout=grace)
    except subprocess.TimeoutExpired: pass
    if group_alive(pgid):
        raise RuntimeError(f"process_group_still_alive: {pgid}")
    return exit_status(child.returncode)


class Interrupted(Exception):
    def __init__(self, signum):
        super().__init__(f"interrupted by signal {signum}")
        self.signum = signum
        self.code = 128 + signum


def exit_status(code):
    return 128 - code if code is not None and code < 0 else code


@contextmanager
def interrupt_guard():
    """Turn termination into an unwind so every finally can stop children."""
    installed = []
    def handle(signum, frame):
        raise Interrupted(signum)
    try:
        for signum in (signal.SIGTERM, signal.SIGHUP):
            previous = signal.getsignal(signum)
            try:
                signal.signal(signum, handle)
            except ValueError:
                break
            installed.append((signum, previous))
        yield
    finally:
        for signum, previous in installed:
            signal.signal(signum, previous)


@contextmanager
def deferred_termination():
    """Repeated TERM/HUP must not interrupt process-group reclamation.

    A signal that arrives while the group is being stopped is ignored until
    the finally that owns cleanup has finished; the already-running unwind
    (or the normal result) is preserved instead of releasing the lock early.
    """
    previous = {}
    def ignore(signum, frame):
        pass
    try:
        for signum in (signal.SIGTERM, signal.SIGHUP):
            try:
                handler = signal.getsignal(signum)
                signal.signal(signum, ignore)
            except (ValueError, OSError):
                continue
            previous[signum] = handler
        yield
    finally:
        for signum, handler in previous.items():
            signal.signal(signum, handler)


def step(command, cwd, env, log, timeout):
    """Keep the real process result and a bounded original combined log."""
    log.parent.mkdir(parents=True, exist_ok=True)
    child = subprocess.Popen(command, cwd=cwd, env=env, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, start_new_session=True)
    selector = selectors.DefaultSelector()
    selector.register(child.stdout, selectors.EVENT_READ)
    started, count = time.monotonic(), 0
    deadline = started + timeout
    try:
        with log.open("wb") as stream:
            while True:
                remaining = deadline - time.monotonic()
                if remaining <= 0: raise StepFailure(124, "build_timeout")
                if not selector.select(min(0.5, remaining)): continue
                chunk = os.read(child.stdout.fileno(), 65536)
                if not chunk: break
                if count + len(chunk) > MAX_LOG: raise StepFailure(125, "log_budget_exceeded")
                stream.write(chunk); count += len(chunk)
        # EOF means stdout is closed, not that the leader exited. The wait is
        # still bounded by whatever remains of this step's deadline.
        remaining = deadline - time.monotonic()
        if remaining <= 0: raise StepFailure(124, "build_timeout")
        try:
            code = child.wait(timeout=remaining)
        except subprocess.TimeoutExpired:
            raise StepFailure(124, "build_timeout")
        if code: raise StepFailure(code, f"command_failed: {command[0]} (see {log})")
    finally:
        selector.close()
        child.stdout.close()
        # Marker persistence is part of the protected span: a repeated
        # TERM/HUP must not interrupt it after the group check failed.
        with deferred_termination():
            try:
                stop_process_group(child)
            except RuntimeError as error:
                # The lock is about to be released; persist the residue so the
                # next build/clean refuses to reuse this output until the group
                # is gone.
                try:
                    save(log.parent / "residual-process-group.json",
                         {"format": 1, "pgid": child.pid, "command": command,
                          "log": str(log), "error": str(error)})
                except OSError as marker_error:
                    raise StepFailure(2, f"{error}; residual marker unwritable: {marker_error}")
                raise StepFailure(2, str(error))


def snapshot_file(source, destination, originals, prepared):
    if source.is_symlink(): raise ValueError(f"source symlink is not a frozen input: {source}")
    expected = digest(source)
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.is_symlink(): raise ValueError(f"generated input symlink: {destination}")
    if not destination.exists() or digest(destination) != expected:
        fd, name = tempfile.mkstemp(prefix=".input-", dir=destination.parent)
        os.close(fd)
        try:
            shutil.copyfile(source, name)
            if digest(name) != expected: raise ValueError(f"source changed during snapshot: {source}")
            os.chmod(name, 0o444); os.replace(name, destination)
        finally:
            if os.path.exists(name): os.unlink(name)
    originals[str(source)] = expected
    prepared[str(destination)] = expected


def prepare(args, env, output):
    app, framework = args.app, args.framework
    if output == app or output == framework or output in app.parents or output in framework.parents:
        raise ValueError("output must not contain the source roots")
    originals, prepared, generated, visited = {}, {}, {}, {}
    previous_path = output / "input-index.json"
    previous = json.loads(previous_path.read_text()) if previous_path.exists() else {}
    allowed = None
    if args.framework_sources:
        originals[str(args.framework_sources)] = digest(args.framework_sources)
        allowed = set(args.framework_sources.read_text().splitlines())
        if any(not s.endswith(".cj") or Path(s).is_absolute() or ".." in Path(s).parts for s in allowed):
            raise ValueError("framework source list needs relative .cj paths within src/")
    native_root = output / "inputs/native"
    native_files = list((framework / "platforms/linux/native").glob("*"))
    native_files = [p for p in native_files if p.suffix in (".c", ".h")]
    native_files += [framework / "native/cjgui_internal_renderer.h"]
    if not any(p.suffix == ".c" for p in native_files): raise ValueError("Linux native source missing")
    for source in native_files:
        snapshot_file(source, native_root / source.relative_to(framework), originals, prepared)
    cc = env.get("CJGUI_LINUX_CC", "cc")
    if args.gcc_lib_dir:
        gcc_dir = args.gcc_lib_dir
    else:
        result = subprocess.run([cc, "-print-libgcc-file-name"], env=env, text=True,
                                capture_output=True, check=True)
        libgcc = Path(result.stdout.strip())
        if not libgcc.is_absolute(): raise ValueError("compiler did not locate libgcc; specify --gcc-lib-dir")
        gcc_dir = libgcc.parent
    pkg = subprocess.run(["pkg-config", "--libs", "vulkan", "xcb", "x11", "x11-xcb", "xkbcommon",
                          "freetype2", "harfbuzz", "fontconfig", "libpng"], env=env, capture_output=True, text=True, check=True)
    link = " ".join(["--gc-sections", "-L" + shlex.quote(str(gcc_dir)), pkg.stdout.strip(),
                     "-lm -lpthread -ldl", args.link_option])
    def visit(root):
        root = root.resolve()
        if root in visited: return visited[root]
        data = manifest(root)
        key = "application" if root == app else "framework" if root == framework else hashlib.sha256(str(root).encode()).hexdigest()[:16]
        destination = output / "inputs/packages" / key
        visited[root] = destination
        originals[str(root / "cjpm.toml")] = digest(root / "cjpm.toml")
        source_dir = (root / data["package"].get("src-dir", "src")).resolve()
        selected = allowed if root == framework else None
        sources = [p for p in sorted(source_dir.rglob("*.cj")) if not p.name.endswith("_test.cj")
                   and (selected is None or p.relative_to(source_dir).as_posix() in selected)]
        if selected is not None and {p.relative_to(source_dir).as_posix() for p in sources} != selected:
            raise ValueError("framework source list contains missing inputs")
        if not sources: raise ValueError(f"package has no production .cj inputs: {root}")
        for source in sources:
            snapshot_file(source, destination / "src" / source.relative_to(source_dir), originals, prepared)
        for name, dependency in data.get("dependencies", {}).items():
            if not isinstance(dependency, dict): continue
            if name == "cjgui": dependency["path"] = str(visit(framework))
            elif name == "cjgui_shared_operation_core": dependency["path"] = str(visit(framework / "shared_operation_core"))
            elif "path" in dependency: dependency["path"] = str(visit((root / dependency["path"]).resolve()))
            else: raise ValueError(f"this entry requires local dependency paths: {name}")
        data["package"]["src-dir"] = "src"
        data["package"]["target-dir"] = str(output / "target")
        data["package"]["link-option"] = link
        ffi = data.setdefault("ffi", {}).setdefault("c", {})
        ffi.pop("cjgui_macos_application_launcher", None)
        for name, library in ffi.items():
            if name != "cjgui_internal_renderer" and "path" in library:
                library["path"] = str((root / library["path"]).resolve())
        # cjpm merges the dependency declaration first: pin every generated
        # occurrence to this application's same private native archive.
        ffi["cjgui_internal_renderer"] = {"path": str(output / "native/lib")}
        config = destination / "cjpm.toml"
        write_manifest(config, data); generated[str(config)] = digest(config)
        return destination
    app_input = visit(app)
    if framework not in visited: raise ValueError("application must consume the selected cjgui framework")
    # Retire only previously indexed generated inputs, never an unowned file.
    for name in previous:
        if name not in prepared and name not in generated:
            path = Path(name)
            if not path.is_relative_to(output / "inputs"): raise ValueError("invalid old input ownership index")
            if path.exists(): path.unlink()
    for path in (output / "inputs").rglob("*.cj"):
        if str(path) not in prepared:
            raise ValueError(f"unindexed generated source; inspect before building: {path}")
    save(previous_path, prepared | generated)
    return app_input, originals, prepared, generated, native_root


def diagnose(args, output, code):
    log = output / "logs/build.log"
    text = log.read_text(errors="replace") if log.exists() else ""
    symbols = sorted(set(re.findall(r"undeclared (?:type name|identifier|type|name) '([\w.]+)'", text)))
    suggestions = {}
    for symbol in symbols[:60]:
        declaration = re.compile(r"\b(?:class|struct|interface|enum|func|let|var|const|type)\s+" + re.escape(symbol.split('.')[0]) + r"\b")
        suggestions[symbol] = [p.relative_to(args.framework / "src").as_posix()
                               for p in sorted((args.framework / "src").rglob("*.cj"))
                               if not p.name.endswith("_test.cj") and declaration.search(p.read_text())]
    save(output / "closure-diagnostic.json", {"exit_code": code, "build_succeeded": code == 0,
         "undeclared": symbols, "suggested_sources": suggestions,
         "note": "One explicit build; suggestions are not admitted inputs. No automatic retry or target deletion."})


def build(args):
    if platform.system() != "Linux": raise ValueError("build on Linux; use ssh only as optional transport")
    output = args.output
    with output_lock(output, args.app):
        # Revoke success before *any* preparation. A failed build may leave
        # debugging objects, but can never authorize running an older binary.
        (output / "build-receipt.json").unlink(missing_ok=True)
        code, record = 1, {"format": 1, "build_id": uuid.uuid4().hex, "application": str(args.app),
                           "framework": str(args.framework), "output": str(output)}
        try:
            env, env_file = toolchain_environment(args.toolchain)
            app_input, originals, prepared, generated, native_root = prepare(args, env, output)
            originals[str(env_file)] = digest(env_file)
            binary = output / "target/release/bin/main"
            binary.unlink(missing_ok=True)
            step(["bash", str(HERE / "build_sidecar.sh"), "--framework", str(native_root),
                  "--output-dir", str(output / "native/lib")], output, env,
                 output / "logs/native.log", args.timeout)
            cjpm = shutil.which("cjpm", path=env["PATH"])
            step([cjpm, "build", "--skip-script", "-j" + str(args.jobs)], app_input, env,
                 output / "logs/build.log", args.timeout)
            if not binary.is_file(): raise ValueError("compiler_output_missing: no fresh target/release/bin/main")
            for name, sha in originals.items():
                if digest(name) != sha: raise ValueError(f"source changed during build: {name}")
            promoted = output / "bin/main"
            promoted.parent.mkdir(exist_ok=True)
            shutil.copyfile(binary, promoted); promoted.chmod(0o755)
            archive = output / "native/lib/libcjgui_internal_renderer.a"
            record.update(source_files=originals, prepared_sources=prepared, generated_manifests=generated,
                          native_archive=str(archive), native_sha256=digest(archive), executable=str(promoted),
                          executable_sha256=digest(promoted), compiler_executable=str(binary),
                          cjpm=cjpm, toolchain_environment=str(env_file), link_configuration=str(app_input / "cjpm.toml"))
            save(output / "build-receipt.json", record)
            code = 0
            print(f"CJGUI_LINUX_BUILD id={record['build_id']} executable={promoted} sha256={record['executable_sha256']}")
        except Interrupted as error:
            code = error.code; record["error"] = str(error); record["interrupted"] = error.signum
        except StepFailure as error:
            code = error.code; record["error"] = str(error)
        except subprocess.CalledProcessError as error:
            code = error.returncode if error.returncode > 0 else 128 - error.returncode
            record["error"] = str(error)
        except (OSError, ValueError) as error:
            code = 2; record["error"] = str(error)
        finally:
            record["exit_code"] = code
            try:
                save(output / "last-build.json", record)
            except OSError:
                if code == 0: raise
            if args.action == "diagnose" and "interrupted" not in record: diagnose(args, output, code)
        if code: print(record.get("error", "build failed"), file=sys.stderr)
        return code


def run(args):
    with output_lock(args.output):
        receipt_path = args.output / "build-receipt.json"
        if not receipt_path.exists(): raise ValueError("no successful build receipt; explicitly build first")
        receipt = json.loads(receipt_path.read_text())
        paths = receipt["source_files"] | receipt["prepared_sources"] | receipt["generated_manifests"]
        paths[receipt["native_archive"]] = receipt["native_sha256"]
        paths[receipt["executable"]] = receipt["executable_sha256"]
        for name, expected in paths.items():
            if not Path(name).is_file() or digest(name) != expected: raise ValueError(f"build_input_changed: {name}")
        child, record = None, None
        try:
            env, _ = toolchain_environment(Path(receipt["toolchain_environment"]))
            # Fontconfig initialisation on the normal Linux entry needs a deeper
            # main-thread stack than the runtime default. An explicit user value
            # wins; 4 MiB is an operating condition, not a root-cause claim for
            # every historical teardown crash.
            env.setdefault("cjStackSize", "4mb")
            command = [receipt["executable"], *args.arguments]
            # The app owns its own process group so a descendant that ignores
            # TERM cannot outlive the runner while the output lock is released.
            child = subprocess.Popen(command, cwd=receipt["application"], env=env, start_new_session=True)
            record = {"build_id": receipt["build_id"], "executable": receipt["executable"],
                      "executable_sha256": receipt["executable_sha256"], "pid": child.pid,
                      "arguments": args.arguments}
            save(args.output / "run-result.json", record)
            print("CJGUI_LINUX_RUN " + json.dumps(record, ensure_ascii=False), flush=True)
            code = exit_status(child.wait())
            record["exit_code"] = code
            return code
        finally:
            # The output lock is released by the enclosing context only after
            # this child's whole group has been stopped and reaped, or an
            # explicit residual marker has been persisted. Repeated TERM/HUP
            # during that span must not interrupt either step.
            active = sys.exc_info()[1]
            if child is not None:
                cleanup_error = None
                residual_persisted = False
                with deferred_termination():
                    try:
                        code = stop_process_group(child)
                    except RuntimeError as error:
                        try:
                            save(residual_marker(args.output),
                                 {"format": 1, "pgid": child.pid, "executable": receipt["executable"],
                                  "error": str(error)})
                            residual_persisted = True
                        except OSError as marker_error:
                            error = RuntimeError(f"{error}; residual marker unwritable: {marker_error}")
                        cleanup_error = error
                        code = 2
                if record is not None:
                    record["exit_code"] = code
                    if isinstance(active, Interrupted):
                        record["interrupted"] = active.signum
                        record["error"] = str(active)
                    elif active is not None:
                        record.setdefault("error", str(active))
                    if cleanup_error is not None:
                        record["error"] = str(cleanup_error)
                        if residual_persisted:
                            record["residual_process_group"] = child.pid
                    try:
                        save(args.output / "run-result.json", record)
                    except OSError:
                        if active is None and cleanup_error is None: raise
                if cleanup_error is not None:
                    raise StepFailure(2, str(cleanup_error))


def clean(args):
    with output_lock(args.output):
        target = args.output / "target"
        if target.is_symlink(): raise ValueError("target symlink refused")
        if target.exists(): shutil.rmtree(target)
        print("CJGUI_LINUX_CLEAN target retired; source inputs, native cache, binary and receipts retained")
    return 0


RESOURCE_SUFFIXES = {".png", ".jpg", ".jpeg", ".ttf", ".otf", ".ttc"}


def linked_libraries(binary, env):
    result = subprocess.run(["ldd", str(binary)], env=env, capture_output=True, text=True)
    if result.returncode != 0:
        raise ValueError(f"ldd failed for {binary}: {result.stderr.strip()}")
    missing, resolved = [], []
    for line in result.stdout.splitlines():
        line = line.strip()
        if "=>" in line:
            name, target = (part.strip() for part in line.split("=>", 1))
            name = name.split()[0]
            if target.startswith("not found"): missing.append(name)
            else: resolved.append({"name": name, "path": re.sub(r"\s+\(0x[0-9a-f]+\)$", "", target)})
        elif line.startswith("/"):
            path = re.sub(r"\s+\(0x[0-9a-f]+\)$", "", line)
            resolved.append({"name": Path(path).name, "path": path})
    return missing, resolved


def application_resources(application):
    files = []
    for entry in sorted(application.iterdir()):
        if entry.is_file() and not entry.is_symlink() and entry.suffix.lower() in RESOURCE_SUFFIXES:
            files.append(entry)
    resources = application / "resources"
    if resources.is_dir() and not resources.is_symlink():
        for entry in sorted(resources.rglob("*")):
            if entry.is_file() and not entry.is_symlink() and entry.suffix.lower() in RESOURCE_SUFFIXES:
                files.append(entry)
    return files


def package(args):
    output = args.output
    with output_lock(output):
        receipt_path = output / "build-receipt.json"
        if not receipt_path.exists(): raise ValueError("no successful build receipt; explicitly build first")
        receipt = json.loads(receipt_path.read_text())
        binary = Path(receipt["executable"])
        if not binary.is_file() or digest(binary) != receipt["executable_sha256"]:
            raise ValueError(f"build_input_changed: {binary}")
        attributes = receipt.get("source_files", {}) | receipt.get("prepared_sources", {}) | \
            receipt.get("generated_manifests", {})
        for name, expected in attributes.items():
            if not Path(name).is_file() or digest(name) != expected:
                raise ValueError(f"build_input_changed: {name}")
        destination = args.destination.absolute()
        if destination.is_symlink() or destination.exists():
            raise ValueError(f"preview destination already exists: {destination}")
        if not destination.name.endswith((".tar.gz", ".tgz")):
            raise ValueError("preview destination must end with .tar.gz or .tgz")
        parent = destination.parent
        if not parent.is_dir(): raise ValueError(f"preview destination parent is unavailable: {parent}")
        name = args.name or Path(receipt["application"].rstrip("/")).name
        name = re.sub(r"[^A-Za-z0-9._-]+", "-", name).strip("-") or "cjgui-preview"
        env, _ = toolchain_environment(Path(receipt["toolchain_environment"]))
        stage = Path(tempfile.mkdtemp(prefix=".cjgui-preview-", dir=parent))
        temporary_archive = parent / f".{destination.name}.{uuid.uuid4().hex}.part"
        try:
            root = stage / name
            (root / "bin").mkdir(parents=True)
            (root / "lib").mkdir()
            shutil.copy2(binary, root / "bin/main")
            (root / "bin/main").chmod(0o755)
            copied_resources = []
            for resource in application_resources(Path(receipt["application"])):
                relative = resource.relative_to(Path(receipt["application"]))
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(resource, target)
                copied_resources.append({"path": str(relative), "sha256": digest(resource)})
            # Judge the package against a plain system, not the author's
            # toolchain search path or embedded RUNPATH: every resolved
            # library outside standard system directories must travel in lib/.
            system_prefixes = ("/lib/", "/lib64/", "/usr/lib/", "/usr/lib64/")
            target_env = dict(env)
            target_env.pop("LD_LIBRARY_PATH", None)
            missing, resolved = linked_libraries(binary, target_env)
            search = [Path(item) for item in env.get("LD_LIBRARY_PATH", "").split(":") if item]
            bundled, bundled_names = [], set()
            for _ in range(8):
                external = {item["name"]: item["path"] for item in resolved
                            if not item["path"].startswith(system_prefixes)
                            and not item["path"].startswith(str(root / "lib") + "/")}
                if not missing and not external: break
                progress = False
                for library, origin in external.items():
                    if library in bundled_names: continue
                    shutil.copy2(origin, root / "lib" / library)
                    bundled.append({"name": library, "sha256": digest(origin), "origin": origin})
                    bundled_names.add(library)
                    progress = True
                for library in missing:
                    if library in bundled_names: continue
                    origin = next((directory / library for directory in search
                                   if (directory / library).is_file()), None)
                    if origin is None:
                        raise ValueError(f"runtime_library_not_found: {library} (searched {':'.join(map(str, search))})")
                    shutil.copy2(origin, root / "lib" / library)
                    bundled.append({"name": library, "sha256": digest(origin), "origin": str(origin)})
                    bundled_names.add(library)
                    progress = True
                if not progress: break
                target_env["LD_LIBRARY_PATH"] = str(root / "lib")
                missing, resolved = linked_libraries(binary, target_env)
            if missing or any(not (item["path"].startswith(system_prefixes)
                                    or item["path"].startswith(str(root / "lib") + "/"))
                              for item in resolved):
                raise ValueError("runtime_library_not_bundled: " + ", ".join(
                    sorted(set(missing) | {item["name"] for item in resolved
                                           if not (item["path"].startswith(system_prefixes)
                                                   or item["path"].startswith(str(root / "lib") + "/"))})))
            system = [item for item in resolved if item["path"].startswith(system_prefixes)]
            (root / "identity").mkdir()
            shutil.copy2(receipt_path, root / "identity/build-receipt.json")
            manifest_value = {
                "format": 1, "kind": "cjgui-linux-preview", "name": name,
                "binary": {"path": "bin/main", "sha256": digest(binary), "build_id": receipt["build_id"]},
                "source_identity": {"application": receipt["application"], "framework": receipt["framework"],
                                    "build_receipt": "identity/build-receipt.json",
                                    "build_receipt_sha256": digest(receipt_path),
                                    "verified_input_files": len(attributes)},
                "resources": copied_resources,
                "runtime_dependencies": {
                    "library_path": "lib",
                    "bundled": bundled,
                    "system": sorted(system, key=lambda item: item["name"]),
                },
                "runtime_environment": {
                    "cjStackSize": {"default": "4mb", "override": "preserved",
                                    "reason": "Fontconfig initialisation on the normal Linux entry"},
                },
                "launch": "./run.sh",
            }
            save(root / "manifest.json", manifest_value)
            (root / "run.sh").write_text(
                "#!/usr/bin/env bash\n"
                "set -euo pipefail\n"
                'HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\n'
                'cd "$HERE"\n'
                'LD_LIBRARY_PATH="$HERE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\n'
                "export LD_LIBRARY_PATH\n"
                'export cjStackSize="${cjStackSize:-4mb}"\n'
                'if [[ -z "${DISPLAY:-}" ]]; then\n'
                '  echo "CJGUI_PREVIEW no DISPLAY; start this script inside an X11 desktop session" >&2\n'
                "  exit 2\n"
                "fi\n"
                'missing="$(ldd "$HERE/bin/main" | awk \'/not found/ {print $1}\')"\n'
                'if [[ -n "$missing" ]]; then\n'
                '  printf \'CJGUI_PREVIEW missing runtime libraries:\\n%s\\n\' "$missing" >&2\n'
                "  exit 2\n"
                "fi\n"
                'exec "$HERE/bin/main" "$@"\n')
            (root / "run.sh").chmod(0o755)
            system_names = ", ".join(item["name"] for item in manifest_value["runtime_dependencies"]["system"])
            bundled_names = ", ".join(item["name"] for item in bundled) or "none"
            (root / "README.md").write_text(
                f"# {name} · CJGUI Linux 预览\n\n"
                "这是已构建应用的直接运行包，不包含仓颉 SDK 或安装器；资源按相对路径随包携带，\n"
                "启动不依赖原工作区、构建输出或缓存。\n\n"
                "## 启动\n\n"
                "在 Linux 桌面会话中执行：\n\n"
                "```bash\n./run.sh\n```\n\n"
                f"- 随包运行库：{bundled_names}（位于 `lib/`，启动脚本设置相对 `LD_LIBRARY_PATH`）。\n"
                f"- 需由系统提供的运行库：{system_names}。缺少时启动脚本列出具体名称并以 2 退出。\n"
                "- 启动脚本默认 `cjStackSize=4mb`（Fontconfig 初始化条件）；显式设置的 `cjStackSize` 优先。\n"
                "- 二进制、资源与构建回执身份见 `manifest.json`；原始回执在 `identity/build-receipt.json`。\n"
                "- 该包只覆盖当前 Linux X11 会话；Wayland 与跨发行版未声明。\n")
            (root / "identity/REPRODUCE.md").write_text(
                "# 复现\n\n"
                "本包由同一 Linux 构建输出打包，二进制与回执哈希见 `manifest.json`。\n"
                "在原工作区重新构建并打包：\n\n"
                "```bash\n"
                f"platforms/linux/scripts/run_linux_application.sh build --app {receipt['application']} "
                f"--framework {receipt['framework']} --toolchain {receipt['toolchain_environment']} "
                f"--output {receipt['output']}\n"
                f"platforms/linux/scripts/run_linux_application.sh package --output {receipt['output']} "
                f"--destination {destination}\n"
                "```\n")
            with tarfile.open(temporary_archive, "w:gz") as bundle:
                def normalized(info):
                    info.uid = info.gid = 0
                    info.uname = info.gname = ""
                    return info
                bundle.add(root, arcname=name, filter=normalized)
            os.replace(temporary_archive, destination)
            print("CJGUI_LINUX_PREVIEW " + json.dumps({
                "name": name, "archive": str(destination), "sha256": digest(destination),
                "bytes": destination.stat().st_size, "binary_sha256": digest(binary),
                "bundled_libraries": [item["name"] for item in bundled]}, ensure_ascii=False))
        finally:
            shutil.rmtree(stage, ignore_errors=True)
            temporary_archive.unlink(missing_ok=True)
    return 0


def ssh_transport(arguments):
    parser = argparse.ArgumentParser(description="Optional SSH tool transport; all build paths are Linux paths")
    parser.add_argument("--guest", default=os.environ.get("CJGUI_LINUX_GUEST"))
    parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args(arguments)
    if not args.guest or args.guest.startswith("-") or not re.fullmatch(r"[\w.@:\[\]-]+", args.guest):
        raise ValueError("explicit --guest user@host or CJGUI_LINUX_GUEST required")
    forwarded = args.arguments[1:] if args.arguments[:1] == ["--"] else args.arguments
    if not forwarded or forwarded[0] not in ("build", "run", "clean", "diagnose", "package"):
        raise ValueError("SSH requires an explicit build/run/clean/diagnose/package command after --")
    stream = io.BytesIO()
    with tarfile.open(fileobj=stream, mode="w") as bundle:
        def tool_metadata(info):
            # Transport needs bytes, not the author's clock/uid. Guests with a
            # different clock must not get future-mtime build inputs.
            info.mtime = 0; info.uid = 0; info.gid = 0
            info.uname = ""; info.gname = ""
            return info
        for name in ["linux_application.py", "build_sidecar.sh"]:
            bundle.add(HERE / name, arcname=name, filter=tool_metadata)
    remote = 'set -e; task_dir=$(mktemp -d "${TMPDIR:-/tmp}/cjgui-linux-tools.XXXXXX"); ' \
             'trap \'rm -rf -- "$task_dir"\' EXIT; tar -xf - -C "$task_dir"; ' \
             'python3 "$task_dir/linux_application.py" ' + shlex.join(forwarded)
    return subprocess.run(["ssh", "-T", "-o", "BatchMode=yes", "--", args.guest,
                           "bash -c " + shlex.quote(remote)], input=stream.getvalue()).returncode


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    try:
        if argv[:1] == ["ssh"]: return ssh_transport(argv[1:])
        with interrupt_guard():
            parser = argparse.ArgumentParser(description=__doc__)
            commands = parser.add_subparsers(dest="action", required=True)
            for name in ["build", "diagnose", "run", "clean", "package"]:
                command = commands.add_parser(name)
                command.add_argument("--output", type=Path, required=True)
                if name in ("build", "diagnose"):
                    command.add_argument("--app", type=Path, required=True)
                    command.add_argument("--framework", type=Path, required=True)
                    command.add_argument("--toolchain", type=Path, required=True)
                    command.add_argument("--framework-sources", type=Path)
                    command.add_argument("--gcc-lib-dir", type=Path)
                    command.add_argument("--link-option", default="")
                    command.add_argument("--jobs", type=int, default=4)
                    command.add_argument("--timeout", type=int, default=900)
                elif name == "run": command.add_argument("arguments", nargs=argparse.REMAINDER)
                elif name == "package":
                    command.add_argument("--destination", type=Path, required=True)
                    command.add_argument("--name")
            args = parser.parse_args(argv)
            for key in ["output", "app", "framework", "toolchain", "framework_sources", "gcc_lib_dir"]:
                value = getattr(args, key, None)
                if value is not None:
                    if key == "output" and value.is_symlink(): raise ValueError("output root must not be a symlink")
                    setattr(args, key, value.resolve())
            if args.action == "run" and args.arguments[:1] == ["--"]: args.arguments = args.arguments[1:]
            if args.action in ("build", "diagnose"):
                if args.jobs < 1 or args.timeout < 1: raise ValueError("jobs and timeout must be positive")
                return build(args)
            if args.action == "package": return package(args)
            return run(args) if args.action == "run" else clean(args)
    except Interrupted as error:
        print(f"cjgui Linux application: {error}", file=sys.stderr)
        return error.code
    except StepFailure as error:
        print(f"cjgui Linux application: {error}", file=sys.stderr)
        return error.code
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"cjgui Linux application: {error}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
