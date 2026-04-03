# Obsidian Setup

Snoodles integrates with Obsidian via the [official Obsidian CLI](https://obsidian.md/download) (v1.12+), which communicates with a running Obsidian desktop instance over IPC. Once configured, the `session-start` hook injects your vault path into every session automatically — no manual path lookup needed.

## Prerequisites

| Requirement | Details |
|---|---|
| Obsidian Desktop | **v1.12.0+** |
| CLI enabled | Settings → Command line interface → Toggle ON |
| Obsidian running | Desktop app must be running for CLI commands to work |

## Configuration

Copy `config.example.json` to `config.json` (or `config.local.json` for machine-specific overrides) and fill in your values:

```bash
cp config.example.json config.json
```

```json
{
  "vault_path": "/path/to/your/obsidian/vault",
  "projects_dir": "Projects",
  "daily_notes_dir": "Planner/Daily",
  "daily_notes_format": "YYYY-MM-DD (Daily)",
  "weekly_notes_dir": "Planner/Weekly",
  "weekly_notes_format": "YYYY-MM-W[NUM] (Weekly)",
  "events_file": "Planner/Events.md",
  "quick_capture_file": "Planner/QuickCapture.md",
  "mcp_server_name": "your-mcp-server-name",
  "mcp_url": "http://127.0.0.1:7777/mcp"
}
```

| Field | Description |
|---|---|
| `vault_path` | Absolute path to your Obsidian vault root |
| `projects_dir` | Vault-relative path to your projects folder |
| `daily_notes_dir` | Vault-relative path to daily notes |
| `daily_notes_format` | Daily note filename format (matches your Obsidian Daily Notes plugin setting) |
| `weekly_notes_dir` | Vault-relative path to weekly notes |
| `weekly_notes_format` | Weekly note filename format |
| `events_file` | Vault-relative path to your events file |
| `quick_capture_file` | Vault-relative path to your quick capture inbox |
| `mcp_server_name` | Name of your Obsidian MCP server (if using MCP integration) |
| `mcp_url` | Local URL of your Obsidian MCP server |

### config.json vs config.local.json

`config.json` is gitignored — it holds your personal vault paths and is never committed. `config.local.json` is also gitignored and takes precedence over `config.json` if both exist. Use `config.local.json` when you want machine-specific overrides without touching your base config.

## How It Works

The `session-start` hook reads `config.local.json` (if present) or `config.json` and injects your vault path into the session context as:

```
Obsidian vault path: /your/vault/path
```

This means the `obsidian-cli` skill receives your vault path automatically at session start — you do not need to specify it in every request.

## MCP Integration

If you run an Obsidian MCP server alongside the CLI, set `mcp_server_name` and `mcp_url` to point at it. The `obsidian-cli` skill will prefer MCP for operations that benefit from it (e.g. Bases queries) and fall back to CLI otherwise. See `skills/obsidian-cli/references/vault-conventions.md` for guidance on when to use each.

## Usage

Once configured, ask Claude to interact with your vault naturally:

```
read today's daily note
append "- [ ] Follow up with team" to my daily note
search my vault for "project alpha"
list all open tasks
```

The `snoodles:obsidian-cli` skill loads automatically when vault operations are requested.
