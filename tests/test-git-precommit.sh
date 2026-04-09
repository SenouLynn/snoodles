#!/usr/bin/env bash
# Tests for git pre-commit hook that blocks commits outside linked worktrees
# This replaces the Claude-level commit-guard with git-level enforcement

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_SRC="$PLUGIN_DIR/hooks/git-precommit"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== git pre-commit hook tests ==="
echo ""

# --- Setup: real temp git repo ---
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

cd "$TMPDIR"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "init" > README.md
git add README.md
git commit -q -m "init"

# Install the hook as both pre-commit and pre-merge-commit
# pre-commit catches: git commit, git cherry-pick
# pre-merge-commit catches: git merge (non-squash)
cp "$HOOK_SRC" .git/hooks/pre-commit
cp "$HOOK_SRC" .git/hooks/pre-merge-commit
chmod +x .git/hooks/pre-commit .git/hooks/pre-merge-commit

# --- Tests ---

# 1. git commit in main worktree → blocked
echo "change" >> README.md
git add README.md
git commit -m "should fail" > /dev/null 2>&1
[ $? -ne 0 ] && pass "blocks git commit in main worktree" || fail "should block git commit in main worktree"
git reset -q HEAD -- README.md 2>/dev/null; git checkout -q -- README.md 2>/dev/null

# 2. git merge (non-squash) in main worktree → blocked (merge calls pre-commit for merge commits)
git checkout -q -b side-branch
echo "side" > side.txt
git add side.txt
# Temporarily disable hooks for setup commits
mv .git/hooks/pre-commit .git/hooks/pre-commit.bak
mv .git/hooks/pre-merge-commit .git/hooks/pre-merge-commit.bak
git commit -q -m "side commit"
git checkout -q main 2>/dev/null || git checkout -q master 2>/dev/null
# Force a merge commit (no fast-forward)
echo "main-change" >> README.md
git add README.md
git commit -q -m "diverge main"
mv .git/hooks/pre-commit.bak .git/hooks/pre-commit
mv .git/hooks/pre-merge-commit.bak .git/hooks/pre-merge-commit
git merge --no-ff side-branch -m "merge" > /dev/null 2>&1
[ $? -ne 0 ] && pass "blocks git merge --no-ff in main worktree" || fail "should block merge commit in main worktree"
git merge --abort 2>/dev/null

# 3. git merge --squash → allowed (no commit created)
git merge --squash side-branch > /dev/null 2>&1
[ $? -eq 0 ] && pass "allows git merge --squash (no commit)" || fail "should allow git merge --squash"
git reset -q HEAD 2>/dev/null

# 4. git commit in linked worktree → allowed
WORKTREE_DIR="$TMPDIR/worktree-test"
git worktree add -q "$WORKTREE_DIR" -b worktree-branch 2>/dev/null
# The hook must be in the linked worktree's hook path too — git shares hooks from main
cd "$WORKTREE_DIR"
echo "wt-change" > wt-file.txt
git add wt-file.txt
git commit -m "worktree commit" > /dev/null 2>&1
[ $? -eq 0 ] && pass "allows git commit in linked worktree" || fail "should allow git commit in linked worktree"
cd "$TMPDIR"

# 5. hook source file exists and is executable
[ -x "$HOOK_SRC" ] && pass "hooks/git-precommit exists and is executable" || fail "hooks/git-precommit missing or not executable"

# 6. Claude-level commit-guard removed from hooks.json
if python3 -c "
import json, sys
hooks = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
for h in hooks.get('hooks', {}).get('PreToolUse', []):
    for hook in h.get('hooks', []):
        if 'commit-guard' in hook.get('command', ''):
            sys.exit(1)
sys.exit(0)
" 2>/dev/null; then
    pass "commit-guard removed from hooks.json PreToolUse"
else
    fail "commit-guard still in hooks.json (should be removed)"
fi

# --- Summary ---
echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ $FAIL -eq 0 ] && exit 0 || exit 1
