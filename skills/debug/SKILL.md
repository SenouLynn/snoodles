---
name: debug
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes. Systematic root cause investigation first.
---

# Systematic Debugging

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you MUST NOT propose fixes.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

## When to Use

ANY technical issue: test failures, bugs, unexpected behavior, performance problems, build failures.

**Use ESPECIALLY when** under time pressure, "just one quick fix" seems obvious, you've already tried multiple fixes, or you don't fully understand the issue.

## The Four Phases

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read error messages carefully** — full stack traces, line numbers, error codes. Don't skip past errors.
2. **Reproduce consistently** — exact steps to trigger. If not reproducible → gather more data, don't guess.
3. **Check recent changes** — git diff, recent commits, new dependencies, config changes.
4. **Gather evidence at component boundaries** — log what enters and exits each layer. Run once → evidence shows WHERE it breaks → investigate that component.
5. **Trace data flow backward** — where does the bad value originate? Keep tracing up the call chain until you find the source. Fix at source, not symptom.

### Phase 2: Pattern Analysis

1. **Find working examples** — similar working code in same codebase
2. **Compare against references** — read completely, don't skim
3. **Identify differences** — list every difference, however small
4. **Understand dependencies** — components, config, environment needed

### Phase 3: Hypothesis and Testing

1. **Form single hypothesis** — "I think X is the root cause because Y"
2. **Test minimally** — smallest possible change to test hypothesis. One variable at a time.
3. **Verify** — worked → Phase 4. Didn't work → new hypothesis. Don't stack fixes.

### Phase 4: Implementation

1. **Write failing test** reproducing the bug
2. **Implement single fix** — address root cause. ONE change. No "while I'm here" improvements.
3. **Verify** — test passes, no other tests broken, issue actually resolved
4. **If fix doesn't work** — < 3 attempts: return to Phase 1. **≥ 3 attempts: STOP and question the architecture.** Each fix revealing new coupling = architectural problem. Discuss before attempting more fixes.

## Red Flags — STOP and Return to Phase 1

- "Quick fix for now, investigate later"
- "Just try changing X and see"
- Proposing solutions before tracing data flow
- "One more fix attempt" (when already tried 2+)
- Each fix reveals new problem in different place

## Quick Reference

| Phase | Key Activities | Gate |
|-------|---------------|------|
| **1. Root Cause** | Read errors, reproduce, trace data flow | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## Reference Techniques

### Root Cause Tracing

Trace backward through the call chain until you find the original trigger:

```
Symptom → immediate cause → what called this? → what value was passed? → where did it come from?
```

Keep going until you find the source. Fix at source, add validation at each layer.

### Condition-Based Waiting (for flaky tests)

Replace arbitrary delays with condition polling:

```
❌ await sleep(50); expect(result).toBeDefined()
✅ await waitFor(() => getResult() !== undefined); expect(result).toBeDefined()
```

Use when: tests have arbitrary sleeps, tests are flaky, waiting for async operations.
