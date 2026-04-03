# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This repo is a Claude Code plugin. Every file here — skills, hooks, behavioral rules — is injected into Claude sessions. You are editing your own instruction set. Optimize all work for token efficiency and behavioral precision.

## Validate

```bash
bash tests/validate-structure.sh
```

Run after any structural change.

## Principles

- Every token in a skill file costs context in every session that loads it. Cut ruthlessly. Prefer precise enforcement language over explanation.
- Behavioral patterns (`HARD-GATE`, `NEVER`, enforcement blocks) exist to correct observed failure modes. Never dilute, rephrase to sound softer, or remove without explicit user instruction.
- Session-injected files (`entry`, `insights`) have hard word limits enforced by the test suite: entry ≤400, insights ≤300. All other skills load on demand and have softer budgets.

## Structural Rules

- Version numbers auto-bump via pre-commit hook. Never edit them.
- Skill frontmatter: `name` and `description` only. No other fields.
- Every `snoodles:<name>` reference must resolve to `skills/<name>/`, `commands/<name>.md`, or `agents/<name>.md`.
- Commands in `commands/` must reference their target skill via `snoodles:<name>`.
