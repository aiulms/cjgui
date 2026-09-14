# Cangjie Live Code Intelligence Rules (Phase B)

This live workspace uses the CodeLattice-backed GitNexus registry entry
`cangjie-live-codelattice` for production code intelligence.

Default rules for all new Cangjie live production tasks:

- Use `cangjie-live-codelattice` for GitNexus `context`, `impact`, and
  `detect-changes`.
- Do not use bare `cjgui`. The registry currently has multiple legacy `cjgui`
  entries, so that name is deprecated and ambiguous.
- Do not use `npx gitnexus` for production commands. Use the Tool CLI absolute
  path:
  `node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js <command>`.
- For CLI impact, the current Tool syntax uses a positional target:
  `impact <symbol> --repo cangjie-live-codelattice`. Do not use
  `impact --target <symbol>`; this flag is rejected by the current Tool CLI.
- If `context`, `impact`, or `detect-changes` returns `UNKNOWN`, `0`, or cannot
  find the target, do not treat that as safe. Fall back to source reading,
  build/probe scripts, forbidden scans, and manifest/docs checks, then report
  that the graph did not cover the target.
- CodeLattice MCP is available as a sidecar for Cangjie/Rust language
  intelligence (`project_overview`, `symbol_search`, `symbol_context`,
  `production_assist`, `cache_prewarm`, `graph_overview`). It does not replace
  the global GitNexus-RC MCP.

Recommended commands:

```bash
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js context init --repo cangjie-live-codelattice
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js impact init --repo cangjie-live-codelattice
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js detect-changes --repo cangjie-live-codelattice --scope all
/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --status
```

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed for live production use as **cangjie-live-codelattice**. Legacy `cangjie` / bare `cjgui` registry names are deprecated for new tasks. Use the GitNexus MCP tools to understand code, assess impact, and navigate safely, but prefer the registry entry `cangjie-live-codelattice`.

> If any GitNexus tool warns the index is stale, refresh the CodeLattice-backed live entry with `/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --full`, or use the Tool CLI absolute path shown above. Do not use `npx gitnexus`.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## When Debugging

1. `gitnexus_query({query: "<error or symptom>"})` — find execution flows related to the issue
2. `gitnexus_context({name: "<suspect function>"})` — see all callers, callees, and process participation
3. `READ gitnexus://repo/cangjie-live-codelattice/process/{processName}` — trace the full execution flow step by step
4. For regressions: `gitnexus_detect_changes({scope: "compare", base_ref: "main"})` — see what your branch changed

## When Refactoring

- **Renaming**: MUST use `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` first. Review the preview — graph edits are safe, text_search edits need manual review. Then run with `dry_run: false`.
- **Extracting/Splitting**: MUST run `gitnexus_context({name: "target"})` to see all incoming/outgoing refs, then `gitnexus_impact({target: "target", direction: "upstream"})` to find all external callers before moving code.
- After any refactor: run `gitnexus_detect_changes({scope: "all"})` to verify only expected files changed.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Tools Quick Reference

| Tool | When to use | Command |
|------|-------------|---------|
| `query` | Find code by concept | `gitnexus_query({query: "auth validation"})` |
| `context` | 360-degree view of one symbol | `gitnexus_context({name: "validateUser"})` |
| `impact` | Blast radius before editing | `gitnexus_impact({target: "X", direction: "upstream"})` |
| `detect_changes` | Pre-commit scope check | `gitnexus_detect_changes({scope: "staged"})` |
| `rename` | Safe multi-file rename | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |
| `cypher` | Custom graph queries | `gitnexus_cypher({query: "MATCH ..."})` |

## Impact Risk Levels

| Depth | Meaning | Action |
|-------|---------|--------|
| d=1 | WILL BREAK — direct callers/importers | MUST update these |
| d=2 | LIKELY AFFECTED — indirect deps | Should test |
| d=3 | MAY NEED TESTING — transitive | Test if critical path |

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/cangjie-live-codelattice/context` | Codebase overview, check index freshness |
| `gitnexus://repo/cangjie-live-codelattice/clusters` | All functional areas |
| `gitnexus://repo/cangjie-live-codelattice/processes` | All execution flows |
| `gitnexus://repo/cangjie-live-codelattice/process/{name}` | Step-by-step execution trace |

## Self-Check Before Finishing

Before completing any code modification task, verify:
1. `gitnexus_impact` was run for all modified symbols
2. No HIGH/CRITICAL risk warnings were ignored
3. `gitnexus_detect_changes()` confirms changes match expected scope
4. All d=1 (WILL BREAK) dependents were updated

## Keeping the Index Fresh

After committing code changes, the GitNexus index can become stale. Refresh the CodeLattice-backed live entry with:

```bash
/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --full
```

For direct Tool CLI checks, use:

```bash
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js impact <target-symbol> --repo cangjie-live-codelattice
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js detect-changes --repo cangjie-live-codelattice --scope all
```

Do not refresh or query production state through bare `cjgui`; it is deprecated
because multiple legacy registry entries share that name.
Do not use `impact --target`; the current CLI expects the target as a positional
argument.

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
