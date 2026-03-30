# Snoodles

Derive intent, brainstorm, create plan, execute. 

## Core Heuristics
- Minimize corrective loops; sacrifice *some* time to extract intent and decompose tasks for better initial results. 
- Scope & re-use core context building artefacts.  
- User owns git history. Nothing auto-commits onto user branches.

**Intended Flow**: 
```bash
/snoodles:plan <task> # runs the full pipeline: intent extraction → exploration + phased plan → parallel agent execution in worktrees.
```

See [docs/overview.md](docs/overview.md) for detailed usage. See [docs/flows.md](docs/flows.md) for execution flow diagrams.

## Setup

```bash
claude plugin marketplace add snoodles /path/to/snoodles
claude plugin install snoodles
```

After editing plugin files, bump version in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, then:

```bash
claude plugin uninstall snoodles@snoodles && claude plugin install snoodles
```

## Architecture

Two files are injected into every session via the `SessionStart` hook:

- **`entry`** — skill routing table, planning flow, HARD-GATE for plan mode
- **`insights`** — behavioral correction rules (epistemic honesty, anti-overengineering, anti-sycophancy)

All other skills are invoked on demand via the `Skill` tool or slash commands.

PostToolUse hooks run language-specific validation after every Edit/Write. Zero tokens on success.

## Commands

| Command | Purpose |
|---------|---------|
| `/snoodles:plan <task>` | Full pipeline: derive-prompt → brainstorm → execute |
| `/snoodles:debug` | Systematic debugging — root cause before fixes |
| `/snoodles:tdd` | Test-driven development — red-green-refactor |
| `/snoodles:parallel` | Ad-hoc parallel dispatch for independent problems |
| `/snoodles:finish` | Complete a branch — merge, PR, keep, or discard |
| `/snoodles:verify` | Evidence before completion claims |
| `/snoodles:insights` | Review or update behavioral rules mid-session |

## Skills

| Skill | Loaded | Purpose |
|-------|--------|---------|
| `entry` | Session start (injected) | Routing table, planning flow, HARD-GATE |
| `insights` | Session start (injected) | Behavioral correction rules |
| `derive-prompt` | On demand | Intent extraction, prompt optimization (for any AI tool) |
| `brainstorm` | On demand | Exploration → design → phased plan doc |
| `execute` | On demand | Parallel agents per phase, worktree isolation, spec + code review |
| `parallel` | On demand | Ad-hoc parallel dispatch for independent problems |
| `debug` | On demand | 4-phase systematic debugging (root cause → pattern → hypothesis → fix) |
| `tdd` | On demand | Red-green-refactor cycle |
| `finish` | On demand | Branch completion (merge/PR/keep/discard) |
| `verify` | On demand | Verification gate — no claims without evidence |

## Agents

| Agent | Dispatched by | Purpose |
|-------|---------------|---------|
| `code-reviewer` | `execute` | Plan alignment + code quality review at phase boundaries |

## Hooks

| Hook | Event | Triggers on | Purpose |
|------|-------|-------------|---------|
| `session-start` | SessionStart | Every session | Injects `entry` + `insights` |
| `typecheck-on-edit` | PostToolUse | `.ts`/`.tsx` edits (needs `tsconfig.json`) | `tsc --noEmit` — silent on success |
| `pycheck-on-edit` | PostToolUse | `.py` edits (needs `pyproject.toml`/`setup.py`) | `pyright` or `mypy` — silent on success |
| `govet-on-edit` | PostToolUse | `.go` edits (needs `go.mod`) | `go vet` — silent on success |

