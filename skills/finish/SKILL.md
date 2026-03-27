---
name: finish
description: Use when implementation is complete and all tests pass — presents structured options for merge, PR, keep, or discard.
---

# Finishing a Development Branch

**Prerequisite:** Verification must have passed (tests green, build clean) before invoking this skill.

## The Process

### Step 1: Verify Tests

Run project test suite. If tests fail → show failures and STOP. Cannot proceed until tests pass.

### Step 2: Determine Base Branch

Check common base branches (main/master) or ask user to confirm.

### Step 3: Present Options

Present exactly these 4 options:

1. **Merge** back to `<base-branch>` locally
2. **Push and create a Pull Request**
3. **Keep** the branch as-is (I'll handle it later)
4. **Discard** this work

### Step 4: Execute Choice

| Option | Actions | Cleanup worktree? |
|--------|---------|-------------------|
| **1. Merge** | Switch to base → pull latest → merge → verify tests → delete feature branch | Yes |
| **2. PR** | Push with `-u` → `gh pr create` | No (preserve for review) |
| **3. Keep** | Report branch name and worktree path | No |
| **4. Discard** | **Confirm first** — list branch, commits, path. Wait for typed "discard". Then checkout base → force-delete branch | Yes |

### Step 5: Cleanup Worktree

For Options 1 and 4 only: check `git worktree list`, remove if in worktree.

## Red Flags

- NEVER skip test verification before offering options
- NEVER force-push without explicit request
- NEVER auto-cleanup for Option 3 (Keep)
- NEVER delete work without typed "discard" confirmation
- NEVER proceed with failing tests
