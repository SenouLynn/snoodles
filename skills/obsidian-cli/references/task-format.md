# Task Format & Insertion Rules

Rules for creating, inserting, and managing tasks in the Obsidian vault. Read `config.json` at the plugin root for vault path and directory configuration.

---

## Project Tasks

### Format

```
- [ ] JIRA:MF-[NUMBER] [start:: YYYY-MM-DD]
- [ ] Description here JIRA:MF-[NUMBER] [start:: YYYY-MM-DD]
```

- Bare Jira code — no backticks, no markdown formatting
- Start date uses dataview inline metadata: `[start:: YYYY-MM-DD]` (space after `::`)
- Completed tasks: `- [x] JIRA:MF-4979 ✅ 2026-02-26`
- The `obsidian-jira-issue` plugin renders Jira details inline from the `JIRA:` pattern

### Insertion Point

Each project file has a `## Todo` section with a `---` delimiter. New tasks go **immediately after** the delimiter (and after `BUTTON[create-task]` if present on the next line). This puts new tasks at the **top** of the list.

```markdown
## Todo
---
BUTTON[create-task]
- [ ] JIRA:MF-1234 [start:: 2026-04-01]    ← INSERT HERE
- [ ] JIRA:MF-1200 [start:: 2026-03-15]
- [x] JIRA:MF-1100 ✅ 2026-03-10
```

### Required Fields

| Field | Required | Notes |
|-------|----------|-------|
| Project | Yes | Maps to a file in the projects directory |
| Jira code | Yes | `JIRA:MF-[NUMBER]` |
| Start date | Yes | When to begin work; suggest a reasonable date if user is vague |
| Description | Optional | Free text before the Jira code |

### How to Insert

1. Use `obsidian read path="Projects/..."` to read the project file
2. Use the `Edit` tool to insert the new task line after the delimiter
3. Do **NOT** use MCP `create_task` — it appends to end of file, not the Todo section
4. Do **NOT** use `obsidian append` — same problem

---

## Retroactive Task Logging

When the user wants to log a task they already completed but forgot to track, insert it as already done:

```
- [x] JIRA:MF-[NUMBER] [start:: YYYY-MM-DD] [due:: YYYY-MM-DD] [completion:: YYYY-MM-DD]
```

- Mark `[x]` immediately — the task is already finished
- Include `[start::]`, `[due::]`, and `[completion::]` so the work is properly tabulated
- The user will provide all dates (start, due, completed) since this is historical
- Same insertion point rules apply — insert after the `## Todo` / `---` delimiter

---

## Event Tasks (Personal / Non-Project)

Target file: the events file from config (default `Planner/Events.md`).

### Format

```
- [ ] Description [scheduled:: YYYY-MM-DD HH:mm] [due:: YYYY-MM-DD HH:mm]
```

- No Jira code, no project needed
- `scheduled` and `due` get the same date & time value (unless a range is given)
- Time uses 24h format: `HH:mm` (e.g., `08:00`, `14:30`)
- If user gives a time range (e.g., "1:30-2:15"), use start as `scheduled` and end as `due`
- Add `[tags:: #tagname]` only if user specifies
- Add `[priority:: level]` only if user specifies

### Insertion Point

Same pattern as project tasks — `## Events` section with `---` delimiter, insert after it.

---

## Task Status Marks

| Mark | Status |
|------|--------|
| ` ` (space) | Not Started |
| `/` | In Progress |
| `x` | Completed |
| `-` | Abandoned |
| `?` | Planned |

---

## Quick-Add Flow

When the user says "add a task":

1. **If missing context** — ask: "What project, what's the Jira code, and when do you want to start?"
2. **Match project name** to a file in the projects directory (fuzzy match OK)
3. **Read the project file** to find the insertion point
4. **Insert the task** using the Edit tool

When the user says "add an event" or describes a personal/non-project task:

1. **If missing context** — ask: "What's the event and when is it? (date & time)"
2. **Read the events file** to find the insertion point
3. **Insert the event** using the Edit tool
