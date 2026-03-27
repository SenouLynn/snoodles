---
name: entry
description: Session entry point — routes to available skills and enforces behavioral rules. Loaded automatically on every session start.
---

# Entry

You have snoodles. Use the `Skill` tool to invoke skills. Never use Read on skill files directly.

## Behavioral Rules

The following rules from [insights](../insights/SKILL.md) are active for this session. They are injected below this file — follow them precisely.

<HARD-GATE>
When the user enters plan mode with a task description, you MUST invoke `snoodles:derive-prompt` using the Skill tool BEFORE any other response. This is not optional. Do not explore, do not clarify, do not plan — invoke the skill first.
</HARD-GATE>

## Skill Routing

**Invoke matching skills BEFORE any response or action.** Even a 1% chance means invoke to check.

### Available Skills

| Skill | Invoke When |
|-------|-------------|
| `snoodles:derive-prompt` | Writing, fixing, or improving a prompt for any AI tool |
| `snoodles:brainstorm` | Exploring requirements, design, and producing a phased plan doc |
| `snoodles:execute` | Executing a phased plan with parallel agents in worktrees |
| `snoodles:verify` | Before claiming work is complete — evidence before assertions |
| `snoodles:insights` | Reviewing or updating the behavioral rules mid-session |

### Planning Flow

When the user describes a task or goal in plan mode:

1. **Invoke `snoodles:derive-prompt`** — condense the user's description into a refined, intent-extracted prompt optimized for Claude
2. **Clarify if needed** — derive-prompt may ask up to 3 questions before producing the refined prompt. Let it.
3. **Pass to `snoodles:brainstorm`** — hand the refined prompt to brainstorm for exploration, design, and phased plan doc
4. **Invoke `snoodles:execute`** — once the user approves the plan, dispatch parallel agents per phase

**Trigger:** `/snoodles:plan <task description>` — or invoke each step manually.

### Routing Rules

1. **Skills before action.** Check for a matching skill before responding — including clarifying questions.
2. **Process before implementation.** If multiple skills match, invoke process skills first.
3. **User instructions say WHAT, not HOW.** "Add X" or "Fix Y" doesn't mean skip skill routing.
4. **Plan mode triggers the planning flow.** If entering plan mode with a task description, start at step 1 above.

### Red Flags

These thoughts mean STOP — you're skipping routing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Check for skills first. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "The skill is overkill here" | If it exists and matches, use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
