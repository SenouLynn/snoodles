# How Snoodles Works

## The Basics

Snoodles is a Claude Code plugin that loads behavioral rules and skill routing into every session. You don't invoke most of it — it runs automatically.

When a session starts, two things get injected into Claude's context before you say anything:

1. **Entry** — a routing table that tells Claude which skills exist and when to use them
2. **Insights** — behavioral correction rules that address recurring failure modes (hallucination, over-engineering, sycophancy, re-reading files unnecessarily)

Everything else is invoked on demand, either by you or by the routing table.

## Starting a Project

```
/snoodles:plan I want to build a webhook relay service that forwards GitHub events to Slack and Discord
```

This triggers a three-stage pipeline:

1. **derive-prompt** sharpens your description — extracts the actual task, constraints, success criteria. May ask up to 3 clarifying questions.
2. **brainstorm** explores the codebase, asks design questions one at a time, proposes approaches, and writes a phased plan document with concrete file paths and verification steps.
3. **execute** asks you to choose a validation mode (review between phases or at the end), then dispatches parallel agents to implement the plan.

Each stage hands off to the next automatically. You approve at two points: the plan doc and the final result.

## How Plan Execution Works

Plans are organized into phases. Tasks within a phase are independent — they don't depend on each other. Tasks in Phase 2 depend on Phase 1 being complete.

When execute runs a phase, it dispatches one agent per task, all in a single message so they run concurrently. Each agent works in an isolated git worktree so they can't interfere with each other.

After all agents in a phase complete, their worktree branches get merged to the working branch. Then the test suite runs. If you chose between-phases validation, a code review also runs. Only after everything passes does the next phase start.

After the final phase, a spec compliance review checks the entire implementation against the original plan. Then a code quality review runs. Then you get four options: merge, create PR, keep the branch, or discard.

## How Language Validation Works

Three PostToolUse hooks run after every file edit. They work the same way:

1. Check if the edited file matches their language (`.ts`/`.tsx`, `.py`, `.go`)
2. If not, exit silently — zero cost
3. If yes, look for a project marker by walking up the directory tree (`tsconfig.json`, `pyproject.toml`/`setup.py`, `go.mod`)
4. If no marker found, exit silently — zero cost
5. If found, run the language's type checker (`tsc --noEmit`, `pyright`/`mypy`, `go vet`)
6. If the check passes, exit silently — Claude never sees anything, zero tokens consumed
7. If the check fails, inject the first 20 lines of errors into Claude's context

This means type errors get caught immediately after the edit that introduced them, without Claude spending tokens to run the check. Claude only pays attention when something breaks.

The hooks auto-detect the package manager for TypeScript projects (bun → pnpm → npm → global tsc) and prefer pyright over mypy for Python. None of this requires configuration — if the project has the right files, the hooks activate.

**Important:** these hooks replace manual build/typecheck commands. The insights rule "hooks handle build validation" tells Claude not to run `tsc`, `pyright`, or `go vet` itself. Only test suites need to be run explicitly, because test output requires Claude to understand what failed and why.

## The Behavioral Rules

The insights file loads every session and corrects patterns where Claude consistently gets things wrong:

- **Epistemic honesty** — admit gaps, cite sources, quote before summarizing. Reduces hallucination and paraphrase drift.
- **Over-engineering** — simplest approach first, abstractions must be earned through repetition, prefer standard library over new dependencies.
- **Bias toward action** — start editing instead of deliberating, trust what agents already verified (don't re-read), and ask the user for a file path after 5 failed search attempts instead of thrashing.
- **Receiving feedback** — verify review feedback against the codebase before implementing, push back if wrong, no performative agreement ("great point!", "you're absolutely right").
- **Verify edits** — use LSP and local tooling, don't run build commands the hooks already handle.

These are not suggestions. They're correction rules derived from observed failure patterns.

## Using Individual Skills

You don't have to use the full pipeline. Each skill works standalone:

- **`/snoodles:debug`** — before proposing a fix for any bug. Enforces root cause investigation: read errors, reproduce, trace data flow, form a single hypothesis, test minimally. Prevents the "just try changing X and see" pattern.
- **`/snoodles:tdd`** — before writing implementation code. Red-green-refactor. If code was written before the test, delete it and start over.
- **`/snoodles:parallel`** — when multiple independent things are broken. Groups problems by domain, dispatches one agent per domain concurrently. Not for planned work (use execute for that).
- **`/snoodles:verify`** — before claiming anything is done. Requires running the verification command and showing the output. "Should work now" is not verification.
- **`/snoodles:finish`** — after tests pass. Presents four options: merge, PR, keep, discard. Requires test verification before offering options.

## Updating the Plugin

The plugin caches files at install time. When you edit skill files, the cache is stale. To refresh:

```bash
# Bump version in .claude-plugin/plugin.json and .claude-plugin/marketplace.json
claude plugin uninstall snoodles@snoodles && claude plugin install snoodles
```

During active development, you'll do this frequently. The structural tests (`bash tests/validate-structure.sh`) validate the source files directly — they don't need a cache refresh.

## When Things Go Wrong

If Claude ignores the routing table and doesn't invoke skills, use the explicit command (`/snoodles:plan`, `/snoodles:debug`, etc.) instead of relying on automatic routing. The commands contain direct instructions that don't depend on Claude choosing to follow injected context.

If exploration takes too long (>15 tool uses) or Claude is re-reading files it already knows about, the insights rules should catch this. If they don't, interrupt and remind it: "you already have that in context" or "ask me where it is."

If a PostToolUse hook times out (30 second limit), the edit still succeeds — the hook failure doesn't block Claude's work. Check that the language tool is installed and the project marker exists.
