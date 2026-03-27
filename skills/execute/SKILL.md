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
- If anything is unclear or unexpected: STOP and report back. Don't guess.

## Report
When done, report:
- Status: DONE | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Verification result (exact output)
- Files changed
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
2. Dispatch code review on the complete implementation (if end-only mode, this is the first review)
3. Fix any issues
4. Present completion summary to user with options:
   - Merge to base branch
   - Create PR
   - Keep branch as-is
   - Discard

## Handling Failures

**Agent reports BLOCKED:** Read the blocker, provide context or answer, re-dispatch.

**Agent reports NEEDS_CONTEXT:** Answer the question, re-dispatch.

**Merge conflict:** Resolve manually, verify, continue.

**Phase verification fails:** Identify which task broke it, fix, re-verify.

**Review finds Critical issues:** Fix before next phase. Re-review after fix.

## Red Flags

- NEVER dispatch Phase N+1 before Phase N is fully merged and verified
- NEVER skip phase verification (build + tests must pass)
- NEVER send an agent the raw plan file — paste the task text
- NEVER proceed with Critical review issues unresolved
- If end-only mode: still run build+tests between phases — just skip code review
