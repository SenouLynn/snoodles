---
name: verify
description: Use before claiming work is complete, fixed, or passing. Requires running verification commands and confirming output before any success claims. Evidence before assertions.
---

# Verification Before Completion

No completion claims without fresh verification evidence.

## The Gate

Before claiming ANY status (pass, fixed, complete, ready):

1. **Identify** — what command proves this claim?
2. **Run** — execute the full command, fresh
3. **Read** — full output, check exit code
4. **Confirm** — output supports the claim? State it WITH evidence. Doesn't? State actual status.

Skip any step = the claim is unverified.

## What Requires Evidence

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test output: 0 failures | Previous run, "should pass" |
| Build succeeds | Build command: exit 0 | Linter passing |
| Bug fixed | Original symptom resolved | Code changed, assumed fixed |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags — STOP

- "Should work now" → run the verification
- "I'm confident" → confidence is not evidence
- About to commit/PR without verification → stop
- Trusting agent success reports → verify independently
