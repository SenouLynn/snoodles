#!/usr/bin/env bash
# Unit tests for hooks/commit-guard
# Main worktree = real temp git repo; linked worktree = PATH-stubbed git mock

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$PLUGIN_DIR/hooks/commit-guard"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

# Set up temp git repo (simulates main worktree — git-dir ends in /.git, no /worktrees/)
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

cd "$TMPDIR"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "init" > README.md
git add README.md
git commit -q -m "init"

echo "=== commit-guard tests ==="
echo ""

# 1. git commit in main worktree → blocked
echo '{"tool_input":{"command":"git commit -m '\''test'\''"}}' | bash "$HOOK" > /dev/null 2>&1
[ $? -eq 1 ] && pass "blocks git commit in main worktree" || fail "should block git commit in main worktree"

# 2. git commit --amend in main worktree → blocked
echo '{"tool_input":{"command":"git commit --amend --no-edit"}}' | bash "$HOOK" > /dev/null 2>&1
[ $? -eq 1 ] && pass "blocks git commit --amend in main worktree" || fail "should block git commit --amend in main worktree"

# 3. compound command with git commit in main worktree → blocked
echo '{"tool_input":{"command":"git add . && git commit -m '\''foo'\''"}}' | bash "$HOOK" > /dev/null 2>&1
[ $? -eq 1 ] && pass "blocks compound command containing git commit" || fail "should block compound git commit"

# 4. git commit on feature branch (still main worktree) → blocked
git checkout -q -b feature/test-branch
echo '{"tool_input":{"command":"git commit -m '\''test'\''"}}' | bash "$HOOK" > /dev/null 2>&1
[ $? -eq 1 ] && pass "blocks git commit on feature branch (main worktree)" || fail "should block git commit on feature branch"
git checkout -q - 2>/dev/null

# 5. non-commit git command in main worktree → allowed
echo '{"tool_input":{"command":"git status"}}' | bash "$HOOK" > /dev/null 2>&1
[ $? -eq 0 ] && pass "allows non-commit commands" || fail "should allow non-commit commands"

# 6. git commit in linked worktree (PATH-mocked git) → allowed
MOCKDIR=$(mktemp -d)
cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
echo "/fake/repo/.git/worktrees/agent-branch-abc123"
EOF
chmod +x "$MOCKDIR/git"
PATH="$MOCKDIR:$PATH" bash -c "echo '{\"tool_input\":{\"command\":\"git commit -m test\"}}' | bash '$HOOK'" > /dev/null 2>&1
[ $? -eq 0 ] && pass "allows git commit in linked worktree" || fail "should allow git commit in linked worktree"
rm -rf "$MOCKDIR"

# 7. blocked output contains guidance
output=$(echo '{"tool_input":{"command":"git commit -m '\''test'\''"}}' | bash "$HOOK" 2>&1)
echo "$output" | grep -q "COMMIT GUARD" \
  && pass "blocked output contains COMMIT GUARD message" \
  || fail "blocked output should contain COMMIT GUARD message"

# 8. empty command → allowed (graceful)
echo '{"tool_input":{"command":""}}' | bash "$HOOK" > /dev/null 2>&1
[ $? -eq 0 ] && pass "handles empty command gracefully" || fail "should handle empty command gracefully"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ $FAIL -eq 0 ] && exit 0 || exit 1
