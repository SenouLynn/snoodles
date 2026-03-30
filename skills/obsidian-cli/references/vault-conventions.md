# Vault Conventions

Structural conventions for the Obsidian vault. All paths below are relative to the vault root defined in `config.json`.

---

## Directory Layout

| Path | Purpose |
|------|---------|
| `Projects/` | One file per project (~22 files). Each has frontmatter + Todo section |
| `Planner/Daily/` | Daily notes: `YYYY-MM-DD (Daily).md` |
| `Planner/Weekly/` | Weekly notes: `YYYY-MM-W[NUM] (Weekly).md` |
| `Planner/Events.md` | Personal/auxiliary tasks and events |
| `Planner/QuickCapture.md` | Quick capture inbox |
| `_archive/Planner/` | Auto-archived daily (2d) and weekly (9d) notes |

## Project File Structure

Each file in `Projects/` follows this layout:

```markdown
---
status: active
tags:
  - project
prioritize: true
id: unique-id
project: Project Name
---

## Todo
---
BUTTON[create-task]
- [ ] JIRA:MF-1234 [start:: 2026-04-01]
- [ ] JIRA:MF-1200 [start:: 2026-03-15]
- [x] JIRA:MF-1100 ✅ 2026-03-10

## Notes
Description and context here...
```

## Project Name Mappings

Common shorthand → actual filename:

| User says | File |
|-----------|------|
| "bugs" | `Bugs & One-Offs.md` |
| "admin" | `Admin.md` |
| "tech debt" | `Front-End Tech & Design Debt.md` |
| "trade desk" | Check multiple Trade Desk files (ClientUnit, Minor Updates, Notifications) |
| "compliance" | Check Compliance files (Reviews, Actions Enhancements) |
| "intake" / "leads" | `Intake & Lead Flow.md` |
| "attribution" | `Lead Attribution.md` |
| "reports" | `Reports.md` |
| "contacts" | `Contacts Page Editing.md` |
| "account" | `Account Updates.md` |

When in doubt, list the projects directory to find the best match.

## Daily Notes

- Path pattern: `Planner/Daily/YYYY-MM-DD (Daily).md`
- Do NOT use `obsidian daily:read` without verifying the path — the daily notes plugin may use a different default. Use `obsidian read path="Planner/Daily/..."` with an explicit path instead.

## MCP vs CLI

| Operation | Use |
|-----------|-----|
| Task queries (by project, status, date) | MCP `query_project_tasks`, `query_tasks`, `search_tasks` |
| Task creation in project files | CLI `read` + Edit tool (MCP appends to wrong location) |
| Task status updates | MCP `update_task_status` |
| Batch task operations | MCP `batch_create_tasks`, `batch_update_task_status` |
| File read/write/search | CLI |
| Properties/frontmatter | CLI |
| Daily/weekly note operations | CLI with explicit paths |
