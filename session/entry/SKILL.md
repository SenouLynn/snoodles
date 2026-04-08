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
| `snoodles:parallel` | 2+ independent problems — ad-hoc parallel dispatch, not plan execution |
| `snoodles:debug` | Any bug, test failure, or unexpected behavior — before proposing fixes |
| `snoodles:tdd` | Implementing any feature or bugfix — before writing implementation code |
| `snoodles:finish` | Implementation complete, tests pass — merge, PR, keep, or discard |
| `snoodles:verify` | Before claiming work is complete — evidence before assertions |
| `snoodles:create-skill` | Creating a new skill or editing an existing skill |

### Routing Rules

1. **Skills before action.** Check for a matching skill before responding — including clarifying questions.
2. **Process before implementation.** If multiple skills match, invoke process skills first.
3. **User instructions say WHAT, not HOW.** "Add X" or "Fix Y" doesn't mean skip skill routing.
4. **Plan mode triggers the planning flow.** Use `/snoodles:plan <task>` or invoke `snoodles:derive-prompt` → `snoodles:brainstorm` → `snoodles:execute` manually.
