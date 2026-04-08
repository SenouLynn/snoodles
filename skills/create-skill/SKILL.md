---
name: create-skill
description: Use when creating a new skill, editing an existing skill, or verifying a skill works before deployment.
---

# Create Skill

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Writing skills IS TDD applied to process documentation. If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

## When to Use

**Create when:** technique wasn't intuitively obvious, you'd reference it again, pattern applies broadly.

**Don't create for:** one-off solutions, standard practices, project-specific conventions (use CLAUDE.md), mechanically enforceable rules (automate instead).

## The Process

1. **Gather** — name, purpose, skill type
2. **Scaffold** — create directory and template SKILL.md
3. **RED** — run pressure scenarios WITHOUT skill, document failures verbatim
4. **GREEN** — write skill addressing specific failures, verify compliance
5. **REFACTOR** — close loopholes, add counters, re-test until bulletproof
6. **Register** — add to entry/SKILL.md routing table

**STOP after each skill.** Do NOT batch-create without testing each.

## Step 1: Gather

Ask the user:
- **Name:** letters, numbers, hyphens only
- **Purpose:** what problem does this skill solve?
- **Type:** determines persuasion approach (see table below)

| Type | Description | Persuasion |
|------|-------------|------------|
| **Discipline** | Enforces rules under pressure (TDD, verification) | Authority + Commitment + Social Proof |
| **Technique** | Concrete method with steps (debugging, refactoring) | Moderate Authority + Unity |
| **Collaborative** | Shared workflow between agents or agent+human | Unity + Commitment |
| **Reference** | API docs, syntax guides, tool documentation | Clarity only — no persuasion |

## Step 2: Scaffold

Create:
```
skills/
  <skill-name>/
    SKILL.md              # Required
    references/           # Only if heavy reference (100+ lines)
```

### SKILL.md Template

```yaml
---
name: <skill-name>
description: Use when [triggering conditions only — NEVER summarize workflow]
---
```

```markdown
# Skill Title

[Core principle — 1-2 sentences, imperative]

## When to Use
[Symptoms, use cases, when NOT to use]

## [Main Sections]
[Address specific baseline failures from RED phase]
[Use tables for quick reference, code blocks for emphasis]
[Decision trees only for non-obvious branching logic]

## Red Flags — STOP
[Explicit list of rationalization symptoms]

## Quick Reference
[Scanning table: situation → action]
```

### Claude Search Optimization (CSO)

**Description MUST use triggering conditions only.** Descriptions summarizing workflow cause Claude to follow the description instead of reading the full skill.

```yaml
# BAD: Summarizes workflow — Claude shortcuts this
description: Dispatches subagent per task with code review between tasks

# GOOD: Triggering conditions only
description: Use when executing implementation plans with independent tasks
```

**Rules:**
- Start with "Use when..."
- Third person, max 1024 chars
- Include search keywords: error messages, symptoms, tool names
- Add violation symptoms for discipline skills: "Use when tempted to skip X"

**Token targets:** Getting-started <150 words, frequently-loaded <200 words, other <500 words.

### Persuasion Techniques

Apply based on skill type. These double compliance rates (33% → 72%, Meincke et al. 2025).

| Technique | How | When |
|-----------|-----|------|
| **Authority** | "YOU MUST", "NEVER", "No exceptions" | Discipline skills — eliminates rationalization |
| **Commitment** | Force explicit choices, require announcements | Multi-step processes, accountability |
| **Scarcity** | "IMMEDIATELY after X", "BEFORE proceeding" | Time-sensitive, prevents "I'll do it later" |
| **Social Proof** | "Every time", "X without Y = failure" | Establishing norms, warning about failures |
| **Unity** | "We're colleagues", shared goals | Collaborative workflows |

**NEVER use Liking** (creates sycophancy) or **Reciprocity** (rarely needed).

**Bright-line rules > soft guidance:** "Write code before test? Delete it." beats "Consider writing tests first."

## Step 3: RED — Baseline Test

**Goal:** Watch an agent fail WITHOUT the skill. Document exact failures.

Run 3+ pressure scenarios combining multiple pressures:

| Pressure | Example |
|----------|---------|
| Time | Emergency, deadline, deploy window |
| Sunk cost | Hours of work, "waste" to delete |
| Authority | Senior says skip it |
| Exhaustion | End of day, tired |
| Pragmatic | "Being pragmatic vs dogmatic" |

### Scenario Template

```markdown
IMPORTANT: This is a real scenario. Choose and act.

[Concrete situation with 3+ combined pressures]
[Real file paths, specific times, actual consequences]

Options:
A) [Correct but costly option]
B) [Tempting shortcut]
C) [Compromise that still violates]

Choose A, B, or C.
```

**Capture verbatim:** exact choice, exact rationalization. These become the skill's targets.

**Skip RED for Reference skills** — they have no rules to violate. Test retrieval instead.

## Step 4: GREEN — Write Skill

Address the **specific rationalizations** from RED. Don't add content for hypothetical cases.

Run same scenarios WITH skill. Agent should comply.

If agent still fails: skill is unclear. Revise and re-test.

## Step 5: REFACTOR — Bulletproof

Agent found a new rationalization? Plug it:

1. **Explicit negation** — "Don't keep as reference. Don't adapt it. Delete means delete."
2. **Rationalization table entry** — `| "Keep as reference" | You'll adapt it. That's testing after. |`
3. **Red flag entry** — add to the STOP list
4. **Update description** — add violation symptoms

**Re-test until bulletproof.** Signs of bulletproof:
- Agent chooses correct option under maximum pressure
- Agent cites skill sections as justification
- Agent acknowledges temptation but follows rule
- Meta-test: "skill was clear, I should follow it"

### Meta-Testing (when GREEN fails)

Ask after wrong choice:
```
How could this skill have been written differently to make
it clear that [correct option] was the only acceptable answer?
```

Three responses: (1) "Skill was clear, I ignored it" → stronger foundational principle, (2) "Should have said X" → add verbatim, (3) "Didn't see section Y" → make more prominent.

## Step 6: Register

Add entry to `session/entry/SKILL.md` routing table:

```markdown
| `snoodles:create-skill` | Creating a new skill or editing an existing skill |
```

## Testing by Skill Type

| Type | Test With | Success Criteria |
|------|-----------|------------------|
| **Discipline** | Pressure scenarios (3+ pressures) | Follows rule under maximum pressure |
| **Technique** | Application + variation scenarios | Applies technique to new scenario |
| **Collaborative** | Multi-agent coordination scenarios | Workflow completes correctly |
| **Reference** | Retrieval + application scenarios | Finds and applies info correctly |

## Red Flags — STOP

- Writing skill before baseline testing (skipping RED)
- "Skill is obviously clear" → clear to you ≠ clear to agents
- "Testing is overkill" → untested skills always have gaps
- Academic tests only (no pressure) → agents resist single pressure, break under multiple
- "I'll test if problems emerge" → test BEFORE deploying
- Vague fixes ("don't cheat") → explicit negations ("don't keep as reference")
- Stopping after first GREEN → continue REFACTOR until no new rationalizations
- Description summarizes workflow → triggering conditions ONLY

## Quality Checklist

- [ ] Name: letters, numbers, hyphens only
- [ ] Frontmatter: name + description, "Use when..." triggers only
- [ ] Core principle in first 30% of file
- [ ] Baseline tested (RED) — failures documented
- [ ] Skill addresses specific failures (GREEN)
- [ ] Loopholes closed (REFACTOR)
- [ ] Rationalization table (discipline skills)
- [ ] Red flags list
- [ ] Quick reference table
- [ ] No narrative — tables, imperatives, code blocks
- [ ] Token budget met (<500 words for most skills)
- [ ] Registered in entry/SKILL.md
