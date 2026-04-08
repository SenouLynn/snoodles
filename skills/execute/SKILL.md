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
  0. Record pre_phase_sha=$(git rev-parse HEAD) before dispatching
  1. Dispatch all tasks in parallel (one agent per task, isolation: "worktree")
  2. Collect results — all must complete before proceeding
  3. Apply each worktree branch: git merge --squash <worktree-branch> (staged, never committed)
  4. Resolve any conflicts
  5. Confirm hook feedback is clean after applying changes
  6. [If between-phases mode] Dispatch code review using pre_phase_sha
  7. [If issues found] Fix before starting next phase
```

After final phase: verify hook feedback is clean regardless of mode.

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
- Do NOT run test suites, build commands, typecheck, or lint (tsc, pyright, go vet, pytest, npm test, etc.) — PostToolUse hooks verify automatically after every edit. Trust them.
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
  - DONE — all requirements met, hooks clean
  - DONE_WITH_CONCERNS — requirements met but [specific concern]
  - BLOCKED — cannot proceed because [specific blocker]
  - NEEDS_CONTEXT — need answer to [specific question]
- What you implemented
- Hook feedback (any errors reported)
- Files changed
- Self-review findings (if any)
```

## After Each Phase

1. **Apply worktree changes.** For each completed agent, run `git merge --squash <worktree-branch>`. This stages all changes without committing. NEVER auto-commit onto the working branch.
2. **Handle conflicts.** If two tasks modified adjacent code, resolve and verify.
3. **Phase verification.** Confirm hook feedback is clean. If errors, fix before proceeding.
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
    git diff <pre_phase_sha>..HEAD  (pre_phase_sha recorded before this phase dispatched)

    Report: Strengths, Issues (Critical/Important/Minor), Assessment.
    Critical/Important issues must be fixed before next phase.
```

5. **Fix issues** from review before starting next phase.

## After Final Phase

Regardless of validation mode:

1. Confirm hook feedback is clean
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

**Apply conflict:** Resolve manually, verify, continue.

**Phase verification fails:** Identify which task broke it, fix, re-verify.

**Review finds Critical issues:** Fix before next phase. Re-review after fix.

## Red Flags

- NEVER start on main/master without explicit user consent — create a branch first
- NEVER dispatch Phase N+1 before Phase N is fully applied and verified
- NEVER skip phase verification (hook feedback must be clean)
- NEVER send an agent the raw plan file — paste the task text
- NEVER proceed with Critical review issues unresolved
- **Commit philosophy:** worktree → commit freely; working branch → NEVER auto-commit. All worktree results land as uncommitted/staged changes. User commits when ready.
- If end-only mode: still verify hook feedback between phases — just skip code review
