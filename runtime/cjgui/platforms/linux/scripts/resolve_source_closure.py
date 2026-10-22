#!/usr/bin/env python3
"""Explicit, single-build closure diagnostic using the isolated application runner.

Use the same required --app/--framework/--toolchain/--output arguments as build,
optionally --framework-sources. It reports compiler undeclared symbols and source
suggestions, and returns the actual build result, including non-declaration errors.
It never mutates the framework, deletes its target, admits suggestions or retries.
"""
import sys
from linux_application import main

if __name__ == "__main__":
    raise SystemExit(main(["diagnose", *sys.argv[1:]]))
