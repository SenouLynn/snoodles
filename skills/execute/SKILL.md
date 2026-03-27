---
name: execute
description: Execute a phased implementation plan using parallel agents in isolated worktrees. Dispatches one agent per task within a phase, merges after each phase completes.
---

# Execute Plan

Dispatch parallel agents to execute a phased plan. Each agent works in an isolated worktree. Phases run sequentially; tasks within a phase run in parallel.

## Before Starting

1. Read the plan doc
2. Verify phases and tasks are clearly defined
3. Ask the user:

> **Validation mode:**
> 1. **Between phases** — code review after each phase merges (catches integration issues early)
> 2. **End only** — code review once after all phases complete (faster, less overhead)

## The Process

```
For each phase:
  1. Dispatch all tasks in parallel (one agent per task, isolation: "worktree")
  2. Collect results — all must complete before proceeding
  3. Merge worktree branches to working branch
  4. Resolve any merge conflicts
  5. Run phase verification (project builds, tests pass)
  6. [If between-phases mode] Dispatch code review on merged phase result
  7. [If issues found] Fix before starting next phase
```

After final phase: run final verification regardless of mode.

## Dispatching Agents

For each task, dispatch using the Agent tool with `isolation: "worktree"`:

```
Agent:
  description: "Task N.M: [task name]"
  isolation: worktree
  prompt: [built from implementer template below]
```

**Dispatch all tasks in a phase in a single message** — this is what makes them parallel.

### Model Selection

| Task type | Model |
|-----------|-------|
| Mechanical, well-specified (rename, move, format) | `haiku` |
| Multi-file coordination, moderate logic | `sonnet` |
| Architecture decisions, complex integration | `opus` |

### Implementer Prompt Template

Build each agent's prompt from this template. Paste the full task text — never tell the agent to read a file.

```
You are implementing Task N.M: [task name]

## Task
[FULL TEXT of task from plan — paste it, don't reference a file]

## Context
[2-3 sentences: where this fits, what phase this is, what other tasks are running in parallel]

## Rules
- Implement exactly what the task specifies. Nothing more.
- Write tests if the task includes them.
- Run the verification command and confirm it passes.
- Commit your work with the specified commit message.
- **Bad work is worse than no work.** If you can't do it right, report BLOCKED — don't produce something wrong.
- If anything is unclear or unexpected: STOP and report back. Don't guess.

## Self-Review Before Reporting
- Did I implement everything in the spec? Missing requirements or edge cases?
- Are names clear and accurate? Is the code clean?
- Did I avoid overbuilding (YAGNI)? Only build what was requested?
- Did I follow existing codebase patterns?
- Do tests verify real behavior (not just mock behavior)?

Fix issues found during self-review before reporting.

## Report
When done, report:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
  - DONE — all requirements met, tests pass
  - DONE_WITH_CONCERNS — requirements met but [specific concern]
  - BLOCKED — cannot proceed because [specific blocker]
  - NEEDS_CONTEXT — need answer to [specific question]
- What you implemented
- Verification result (exact output)
- Files changed
- Self-review findings (if any)
```

## After Each Phase

1. **Merge worktrees.** Each completed agent returns a worktree path and branch. Merge each branch to the working branch.
2. **Handle conflicts.** If two tasks modified adjacent code, resolve and verify.
3. **Phase verification.** Run project-level checks (build, test suite). If failures, fix before proceeding.
4. **Code review** (if between-phases mode). Dispatch the code-reviewer agent on the merged diff:

```
Agent:
  subagent_type: "snoodles:code-reviewer"
  prompt: |
    Review Phase N of [feature name].

    ## What was implemented
    [Summary of tasks in this phase]

    ## Plan requirements
    [Phase description from plan doc]

    ## Review scope
    git diff [pre-phase SHA]..HEAD

    Report: Strengths, Issues (Critical/Important/Minor), Assessment.
    Critical/Important issues must be fixed before next phase.
```

5. **Fix issues** from review before starting next phase.

## After Final Phase

Regardless of validation mode:

1. Run full project verification (build + tests)
2. **Spec compliance review** — dispatch a reviewer agent on the complete implementation against the original plan:

```
Agent:
  description: "Spec compliance review"
  prompt: |
    You are reviewing whether the complete implementation matches its plan.

    ## Plan Requirements
    [FULL plan doc — paste it]

    ## CRITICAL: Do Not Trust Agent Reports
    Verify everything independently by reading the actual code.

    For each plan task, verify:
    - Was it implemented completely?
    - Was anything extra added that wasn't in the plan?
    - Were requirements interpreted correctly?

    Report:
    - ✅ Spec compliant (all tasks match plan)
    - ❌ Issues found: [what's missing or extra, with file:line refs]
```

3. Fix any spec compliance issues
4. Dispatch code review on the complete implementation
5. Fix any code quality issues
6. Invoke `snoodles:finish` to present structured completion options

## Handling Failures

**Agent reports BLOCKED:** Read the blocker, provide context or answer, re-dispatch.

**Agent reports NEEDS_CONTEXT:** Answer the question, re-dispatch.

**Merge conflict:** Resolve manually, verify, continue.

**Phase verification fails:** Identify which task broke it, fix, re-verify.

**Review finds Critical issues:** Fix before next phase. Re-review after fix.

## Red Flags

- NEVER start on main/master without explicit user consent — create a branch first
- NEVER dispatch Phase N+1 before Phase N is fully merged and verified
- NEVER skip phase verification (build + tests must pass)
- NEVER send an agent the raw plan file — paste the task text
- NEVER proceed with Critical review issues unresolved
- **Commit philosophy:** worktree → commit freely; user branch → stage only, prompt user
- If end-only mode: still run build+tests between phases — just skip code review
