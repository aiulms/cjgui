#!/usr/bin/env python3
"""Install this skill as a source link or a traceable, independent snapshot.

Existing destinations are never replaced. No dependency/network installation.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil


RECEIPT = ".cjgui-skill-install.json"


def inventory(source):
    files = {}
    for directory, folders, names in os.walk(source, followlinks=False):
        folders[:] = sorted(n for n in folders if n not in {"__pycache__", ".git"})
        for name in folders + sorted(names):
            path = Path(directory) / name
            if path.is_symlink():
                raise ValueError(f"skill payload contains symlink: {path}")
        for name in sorted(names):
            path = Path(directory) / name
            if name == RECEIPT or name.endswith(".pyc"):
                continue
            files[path.relative_to(source).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    if "SKILL.md" not in files:
        raise ValueError("source has no SKILL.md")
    return files


def install(source, skills_dir, mode):
    source = source.resolve()
    skills_dir = skills_dir.expanduser().resolve()
    destination = skills_dir / "cjgui-app-dev"
    files = inventory(source)
    if destination.is_symlink() and destination.resolve() == source:
        return {"status": "already-linked", "destination": str(destination), "source": str(source)}
    if destination.exists() or destination.is_symlink():
        raise ValueError(f"destination already exists; compare its source and local edits first: {destination}")
    if skills_dir == source or source in skills_dir.parents:
        raise ValueError("installation directory must be outside the skill source")
    skills_dir.mkdir(parents=True, exist_ok=True)
    if mode == "link":
        destination.symlink_to(source, target_is_directory=True)
    else:
        # Reserve the exact destination atomically. A competing installer never
        # writes into it; on failure remove only the directory we just reserved.
        destination.mkdir()
        try:
            for relative in files:
                target = destination / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source / relative, target)
            if inventory(destination) != files or inventory(source) != files:
                raise ValueError("skill source changed during installation")
            receipt = {"format": 1, "source": str(source), "mode": "copy", "files": files}
            (destination / RECEIPT).write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + "\n")
        except BaseException:
            shutil.rmtree(destination)
            raise
    return {"status": "installed", "mode": mode, "destination": str(destination),
            "source": str(source), "file_count": len(files)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    target = parser.add_mutually_exclusive_group()
    target.add_argument("--host", choices=("codex", "dsh", "agents"),
                        help="directory profile only; default is codex, not automatic host detection")
    target.add_argument("--skills-dir", type=Path, help="explicit discovery directory for any host")
    parser.add_argument("--mode", choices=("link", "copy"), default="link")
    parser.add_argument("--dry-run", action="store_true", help="show target without writing or checking host discovery")
    args = parser.parse_args()
    profiles = {
        "codex": Path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex"))) / "skills",
        "dsh": Path.home() / ".dsh" / "skills",
        "agents": Path.home() / ".agents" / "skills",
    }
    directory = args.skills_dir if args.skills_dir is not None else profiles[args.host or "codex"]
    source = Path(__file__).resolve().parents[1]
    try:
        if args.dry_run:
            result = {"status": "planned", "mode": args.mode, "source": str(source),
                      "destination": str(directory.expanduser().resolve() / "cjgui-app-dev")}
        else:
            result = install(source, directory, args.mode)
    except (ValueError, OSError) as error:
        parser.exit(2, f"cjgui skill install: {error}\n")
    result.update(host_profile=args.host or ('custom' if args.skills_dir is not None else 'codex'),
                  discovery='not_checked')
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
