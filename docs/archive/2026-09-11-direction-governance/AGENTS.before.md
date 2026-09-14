# Cangjie Live Code Intelligence Rules

This workspace uses CodeLattice as the primary code-intelligence path for
Cangjie/CJGUI development. GitNexus remains available as a secondary
cross-checking tool, but it is not a per-symbol editing gate for ordinary
internal owner, demo, probe, or documentation work.

The goal of these rules is to help agents move the project forward with good
evidence, not to turn tool checks into safety theater.

## Primary: CodeLattice

Prefer CodeLattice for day-to-day Cangjie development:

- `project_overview`
- `symbol_search`
- `symbol_context`
- `production_assist`
- `cache_prewarm`
- `graph_overview`

Use it for:

- understanding existing owners, probes, demos, and runtime paths;
- finding related symbols and nearby patterns;
- shaping implementation plans;
- checking broad module relationships;
- reviewing Cangjie-specific development risks.

## Secondary: GitNexus

Use the GitNexus registry entry `cangjie-live-codelattice` when GitNexus is
useful. Do not use bare `cjgui`; multiple legacy entries make that name
ambiguous. Do not use `npx gitnexus` for production commands.

Use the Tool CLI absolute path:

```bash
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js <command>
```

Recommended commands:

```bash
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js context init --repo cangjie-live-codelattice
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js impact <symbol> --repo cangjie-live-codelattice
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js detect-changes --repo cangjie-live-codelattice --scope all
/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --status
```

For CLI impact, the current Tool syntax uses a positional target:

```bash
impact <symbol> --repo cangjie-live-codelattice
```

Do not use `impact --target <symbol>`; that flag is rejected by the current
Tool CLI.

## When Impact Analysis Matters

Do not require GitNexus impact before every ordinary internal edit. For
routine internal owner, demo, focused probe, suite, and documentation updates,
source reading plus focused verification is enough.

Prefer CodeLattice and, when useful, GitNexus impact/context for higher-risk
changes:

- adding or changing public API;
- changing public C ABI or native bridge code;
- changing `runtime/cjgui/src/runtime_state.cj`;
- changing `runtime/cjgui/cjpm.toml`;
- changing renderer submission, runtime state write, backend-ready truth, or
  production truth paths;
- broad shared executor, manager, resolver, or demo runtime changes that affect
  several demos or runtime paths;
- cross-module refactors, renames, or file moves.

If GitNexus returns `UNKNOWN`, `not found`, `0 affected`, or otherwise misses a
fresh Cangjie symbol, treat that as graph non-coverage. It is neither a safety
proof nor an automatic blocker. Fall back to source reading, focused probes,
builds, scans, and report the graph gap.

If impact analysis reports HIGH or CRITICAL risk for a broad production change,
stop and summarize the risk before proceeding.

## Verification Before Finishing

For code or script changes, run verification appropriate to the risk. At
minimum for CJGUI runtime/native/script work:

- related focused probes or suites;
- `cjpm build --skip-script`;
- `git diff --check`;
- public/protected/forbidden scans.

If `cjpm` is not in `PATH`, source the Cangjie toolchain first:

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
```

For public API changes, also report:

- API signature;
- stability level;
- demo proof or consumption path;
- public declaration scan result.

For owner-local commit/write work, also report:

- write scope;
- before/after state;
- readback evidence;
- rollback or not-published boundary;
- whether `runtime_state` and `renderer_state` stayed unwritten.

## Safety Lines

Default behavior:

- do not stage, commit, or push unless the user explicitly asks;
- do not treat isolated probe evidence as production truth;
- do not make unverified `runtime_state` or `renderer_state` writes;
- do not make unverified production truth or backend-ready truth upgrades;
- do not expand public C ABI casually;
- do not modify `runtime/cjgui/src/runtime_state.cj` or
  `runtime/cjgui/cjpm.toml` unless the task clearly requires it, and then keep
  the change minimal and fully verified.

Tool results are supporting evidence. Final safety and progress conclusions
should come from code understanding, focused probes, builds, scans, and clear
handoff notes.
