---
name: brainstorm
description: Explores requirements and design, then produces an actionable plan doc. Receives a refined prompt from derive-prompt during plan mode. Use before any creative work.
---

# Brainstorming Ideas Into Plans

Bridge the gap between intent and execution. Take the refined prompt from derive-prompt, gather context, make design decisions, and produce a plan doc that a fresh Claude can execute task-by-task without re-reading anything.

<HARD-GATE>
Do NOT write any code, scaffold any project, or take any implementation action until you have produced a plan and the user has approved it.
</HARD-GATE>

## Checklist

Complete in order:

1. **Explore project context** — inherit intent dimensions from derive-prompt (task, constraints, success criteria, context). Do NOT re-gather these. Fill only the **codebase-grounded** dimensions below with concrete file:line refs, then stop.
   - **Reusable patterns** — file:line refs to existing code worth following or extending
   - **Dependencies** — call chain, execution order between components
   - **Data flows** — input → output mappings traced to concrete locations
   - **Open questions** — unresolved items requiring user input or further investigation
   - **Confidence** — verified from source vs inferred
   - Skip dimensions that don't apply
   - **Stop when:** open questions list is empty OR all remaining questions require user input
   - **Budget:** Exploration should take ≤15 tool uses. If you can't fill a dimension in that budget, mark it as an open question and move on.
   - **Output:** compressed findings table — refs not summaries
   - **Never re-read what an agent already verified.** If an Explore agent returned a finding with "Verified" confidence, trust it. Do not re-read those files to double-check.
   - When launching Explore agents, **dispatch in parallel** where scopes don't overlap (e.g., one agent for `src/auth/`, another for `src/api/`). Send all in a single message.
     - State which dimensions the agent should fill
     - Set a scope boundary (e.g., "search src/auth/ for patterns related to JWT")
     - Require output as a compressed findings table
   - Format:
     ```
     ## Exploration Findings
     Inherited from derive-prompt: [task], [constraints], [success criteria]

     | Dimension | Finding | Source | Confidence |
     |-----------|---------|--------|------------|
     | Reusable patterns | `processQueue()` at src/worker.ts:45 | Read file | Verified |
     | Dependencies | worker → queue → db | Traced calls | Verified |
     | Data flows | HTTP request → validate → enqueue → response | Traced calls | Verified |
     | Open questions | None | — | — |
     ```
2. **Assess scope** — if the request describes multiple independent subsystems, flag immediately for decomposition. Don't refine details of a project that needs to be split first.
3. **Ask design-scoped clarifying questions** — one at a time, multiple choice preferred. The refined prompt already locked: purpose, task, constraints, success criteria. Ask ONLY about:
   - Technology/library choices
   - Integration points with existing code
   - Architecture decisions (patterns, data flow)
   - Deployment/environment constraints
   - Performance requirements and trade-offs
4. **Propose approaches** — max 3 with trade-offs, lead with your recommendation
5. **Write plan doc** — the deliverable. Get user approval.

If user rejects at step 5, revise and re-present.

## Plan Doc Format

The plan doc must be executable by a fresh Claude with zero project memory.

### Header

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence — from derive-prompt intent]
**Constraints:** [From derive-prompt intent]
**Success criteria:** [From derive-prompt intent]
**Approach:** [2-3 sentences — the chosen approach from step 4]
**Tech:** [Key technologies/libraries]

## Exploration Findings
[The codebase-grounded dimensions table from step 1]
```

### Phase & Task Structure

Group tasks into **phases** by dependency order. Tasks within a phase have no dependencies on each other and can execute in parallel. Phase N+1 depends on Phase N completing.

**Granularity target:** Each task should be 2-5 minutes of work — one-shottable by a fresh agent in an isolated worktree. If a task requires holding multiple files in context simultaneously or has ambiguous completion criteria, it's too big — split it.

````markdown
## Phase 1: [Description — what this phase establishes]

### Task 1.1: [Specific Action]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Steps:**
1. [Exact action with exact code or change description]
2. [Next action]

**Done when:** [observable outcome — what the code does, what the UI shows, what the API returns. Not a command to run.]

### Task 1.2: [Specific Action]
...

## Phase 2: [Description — what this phase builds on Phase 1]

### Task 2.1: [Specific Action]
...
````

### Task Rules

- **Exact file paths always.** No "the relevant file" or "the handler."
- **Complete code in plan.** Not "add validation" — show what validation.
- **Completion criteria per task.** Every task has an observable outcome — what the code does, what the UI shows, what the API returns. Not a build command.
- **No vague verbs.** Not "handle", "support", "wire up" — say what happens.
- **No restating context.** Each task inherits the header. Don't repeat the goal.
- **Tasks within a phase must be independent.** No task in Phase N may depend on another task in Phase N. If two tasks touch the same file, they belong in different phases.

### Self-Check

Before presenting, verify:
- [ ] Every file reference points to a real path found during exploration
- [ ] Each task is independently one-shottable with clear completion criteria
- [ ] Each "Done when" describes an observable outcome, not a command to run
- [ ] No TODOs, placeholders, or "figure out later"
- [ ] YAGNI — nothing beyond what the intent requires

Save to `docs/plans/YYYY-MM-DD-<topic>.md`.

## Working in Existing Codebases

- Follow patterns already captured in the exploration findings. Do not re-read to discover new ones.
- Where existing code has problems that affect the work, include targeted improvements in the plan.
- Don't plan unrelated refactoring. Stay focused on the goal.

## Key Principles

- **One question at a time** — don't overwhelm
- **YAGNI ruthlessly** — remove unnecessary features
- **Scope check** — flag multi-system requests for decomposition
- **Refs not summaries** — file:line references eliminate re-reads downstream
- **One-shottable tasks** — each task is small, clear, and independently verifiable
