---
name: tdd
description: Use when implementing any feature or bugfix, before writing implementation code. Red-green-refactor cycle.
---

# Test-Driven Development

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over. Don't keep it as "reference."

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## Red-Green-Refactor

### RED — Write Failing Test

One minimal test showing what should happen. Clear name, tests real behavior, one thing.

```
Good: test('retries failed operations 3 times', ...) — specific, behavioral
Bad:  test('retry works', ...) — vague, tests mock not code
```

**Requirements:** One behavior. Clear name. Real code (no mocks unless unavoidable).

### Verify RED — Watch It Fail

**MANDATORY. Never skip.**

Confirm: test fails (not errors), failure message expected, fails because feature missing (not typos).

- Test passes immediately? You're testing existing behavior. Fix test.
- Test errors? Fix error, re-run until it fails correctly.

### GREEN — Minimal Code

Simplest code to pass the test. Don't add features, refactor other code, or "improve" beyond the test.

```
Good: Just enough to pass — hardcoded values are fine if only one test
Bad:  Options object, backoff strategies, callbacks — YAGNI
```

### Verify GREEN — Watch It Pass

**MANDATORY.** Confirm: test passes, other tests still pass, output pristine.

- Test fails? Fix code, not test.
- Other tests fail? Fix now.

### REFACTOR — Clean Up

After green only: remove duplication, improve names, extract helpers. Keep tests green. Don't add behavior.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Real** | Tests real code | Tests mock behavior |

## Bug Fix Flow

1. **RED:** Write test reproducing the bug
2. **Verify RED:** Fails for the right reason
3. **GREEN:** Minimal fix
4. **Verify GREEN:** Passes, no regressions
5. **REFACTOR:** Clean up if needed

## Red Flags — Delete Code and Start Over

- Code before test
- Test passes immediately
- Can't explain why test failed
- "I'll add tests later"
- "Keep as reference" or "adapt existing code"
- "Too simple to test" (simple code breaks, test takes 30 seconds)
- "TDD slows me down" (TDD is faster than debugging)

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Assertion first. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Verification Checklist

Before marking complete:
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass, output pristine
- [ ] Tests use real code (mocks only if unavoidable)
