---
name: parallel
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies. Ad-hoc parallel dispatch, not plan execution.
---

# Dispatching Parallel Agents

One agent per independent problem domain. Let them work concurrently.

## When to Use

**Use when:**
- 2+ independent problems (test files, subsystems, bugs)
- Each understandable without context from the others
- No shared state between them

**Don't use when:**
- Failures are related (fix one might fix others)
- Agents would interfere (editing same files)
- Exploratory debugging (don't know what's broken yet)
- You have a plan doc → use `snoodles:execute` instead

## The Pattern

### 1. Identify Independent Domains

Group by what's broken. Each domain must be independent — fixing one doesn't affect others.

### 2. Create Focused Agent Tasks

Each agent gets a self-contained packet:
- **Scope:** one test file, one subsystem, one bug
- **Goal:** what success looks like
- **Constraints:** what NOT to change
- **Known facts:** errors, prior findings
- **Expected output:** summary of root cause and fixes

### 3. Dispatch in Parallel

Send all agents in a single message — this is what makes them concurrent.

```
Agent(description: "Fix auth.test.ts failures", isolation: worktree, prompt: ...)
Agent(description: "Fix queue.test.ts failures", isolation: worktree, prompt: ...)
Agent(description: "Fix api.test.ts failures", isolation: worktree, prompt: ...)
```

Use `isolation: "worktree"` when agents may edit overlapping files. Skip isolation for read-only investigation.

### 4. Review and Integrate

- Read each agent's summary
- Check for conflicts (did agents edit same code?)
- Merge worktree branches if used
- Run full test suite
- Spot check — agents can make systematic errors

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Too broad ("fix all tests") | Scope to one file or subsystem per agent |
| No context (just "fix it") | Paste error messages and test names |
| No constraints | "Do NOT change production code" or "Fix tests only" |
| Vague output expected | "Return summary of root cause and changes made" |
| Dispatching related failures | If fix-one-fix-all is possible, investigate sequentially first |
