#!/usr/bin/env bash
set -euo pipefail

# Structural validation for snoodles plugin
# Catches broken cross-references, stale routing, and missing files
# Run: bash tests/validate-structure.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PLUGIN_DIR"

PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

echo "========================================"
echo " Snoodles Structural Validation"
echo "========================================"
echo ""

# --- 1. Skill directory structure ---
echo "=== 1. Skill Directory Structure ==="

for dir in skills/*/; do
    skill_name=$(basename "$dir")
    if [ -f "$dir/SKILL.md" ]; then
        pass "$skill_name has SKILL.md"
    else
        fail "$skill_name missing SKILL.md"
    fi
done

echo ""

# --- 2. Frontmatter validation ---
echo "=== 2. Frontmatter Validation ==="

for skill_file in skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_file")")

    if head -10 "$skill_file" | grep -q "^name:"; then
        pass "$skill_name has name in frontmatter"
    else
        fail "$skill_name missing name in frontmatter"
    fi

    if head -10 "$skill_file" | grep -q "^description:"; then
        pass "$skill_name has description in frontmatter"
    else
        fail "$skill_name missing description in frontmatter"
    fi

    # version is NOT a supported frontmatter attribute
    if head -10 "$skill_file" | grep -q "^version:"; then
        fail "$skill_name has unsupported 'version' in frontmatter"
    else
        pass "$skill_name no unsupported frontmatter fields"
    fi
done

echo ""

# --- 3. Cross-reference validation ---
echo "=== 3. Cross-Reference Validation ==="

REFERENCED=$(grep -roh 'snoodles:[a-z-]*' skills/ commands/ 2>/dev/null | sed 's/snoodles://' | sort -u)

for ref in $REFERENCED; do
    if [ -d "skills/$ref" ]; then
        pass "snoodles:$ref → skills/$ref/ exists"
    elif [ -f "commands/$ref.md" ]; then
        pass "snoodles:$ref → commands/$ref.md exists (command)"
    elif [ -f "agents/$ref.md" ]; then
        pass "snoodles:$ref → agents/$ref.md exists (agent)"
    else
        fail "snoodles:$ref referenced but not found in skills/, commands/, or agents/"
    fi
done

echo ""

# --- 4. Command routing ---
echo "=== 4. Command Routing ==="

for cmd_file in commands/*.md; do
    cmd_name=$(basename "$cmd_file" .md)

    if grep -q "snoodles:" "$cmd_file" || grep -q "Invoke" "$cmd_file"; then
        target=$(grep -oh 'snoodles:[a-z-]*' "$cmd_file" | head -1 | sed 's/snoodles://')
        if [ -n "$target" ] && [ -d "skills/$target" ]; then
            pass "/snoodles:$cmd_name → snoodles:$target (exists)"
        elif [ -n "$target" ]; then
            fail "/snoodles:$cmd_name → snoodles:$target (MISSING)"
        else
            pass "/snoodles:$cmd_name has invocation instruction"
        fi
    else
        warn "/snoodles:$cmd_name has no skill reference"
    fi
done

echo ""

# --- 5. Reference file validation ---
echo "=== 5. Reference File Validation ==="

for skill_file in skills/*/SKILL.md; do
    skill_dir=$(dirname "$skill_file")
    skill_name=$(basename "$skill_dir")

    refs=$(grep -oh 'references/[a-z-]*.md' "$skill_file" 2>/dev/null | sort -u || true)
    for ref in $refs; do
        if [ -f "$skill_dir/$ref" ]; then
            pass "$skill_name → $ref exists"
        else
            fail "$skill_name → $ref MISSING"
        fi
    done
done

echo ""

# --- 6. Inventory counts ---
echo "=== 6. Inventory Counts ==="

SKILL_COUNT=$(find skills -maxdepth 2 -name "SKILL.md" | wc -l | tr -d ' ')
CMD_COUNT=$(find commands -name "*.md" | wc -l | tr -d ' ')
AGENT_COUNT=$(find agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

echo "  Skills: $SKILL_COUNT"
echo "  Commands: $CMD_COUNT"
echo "  Agents: $AGENT_COUNT"

# Expected counts — update these as skills are ported
if [ "$SKILL_COUNT" -eq 10 ]; then
    pass "Skill count: $SKILL_COUNT (expected 10: entry, insights, derive-prompt, brainstorm, execute, parallel, verify, debug, tdd, finish)"
else
    fail "Skill count: $SKILL_COUNT (expected 10)"
fi

if [ "$CMD_COUNT" -eq 7 ]; then
    pass "Command count: $CMD_COUNT (expected 7: debug, finish, insights, parallel, plan, tdd, verify)"
else
    fail "Command count: $CMD_COUNT (expected 7)"
fi

if [ "$AGENT_COUNT" -eq 1 ]; then
    pass "Agent count: $AGENT_COUNT (expected 1: code-reviewer)"
else
    fail "Agent count: $AGENT_COUNT (expected 1)"
fi

echo ""

# --- 7. Enforcement language ---
echo "=== 7. Enforcement Language ==="

HARD_GATE=$(grep -r "HARD-GATE" --include="*.md" skills/ | wc -l | tr -d ' ')
NEVER_COUNT=$(grep -r "NEVER" --include="*.md" skills/ | wc -l | tr -d ' ')

if [ "$HARD_GATE" -ge 1 ]; then
    pass "HARD-GATE blocks present ($HARD_GATE occurrences)"
else
    fail "HARD-GATE blocks missing"
fi

if [ "$NEVER_COUNT" -ge 5 ]; then
    pass "NEVER constraints present ($NEVER_COUNT occurrences)"
else
    warn "NEVER constraints may be thin ($NEVER_COUNT, expected ≥5)"
fi

echo ""

# --- 8. Pipeline continuity ---
echo "=== 8. Pipeline Continuity ==="

# entry must reference all available skills
for skill in derive-prompt brainstorm execute parallel verify debug tdd finish insights; do
    if grep -q "snoodles:$skill" skills/entry/SKILL.md; then
        pass "entry routes to snoodles:$skill"
    else
        fail "entry missing route to snoodles:$skill"
    fi
done

# entry planning flow must be in correct order
if grep -A5 "Planning Flow" skills/entry/SKILL.md | grep -q "derive-prompt"; then
    pass "planning flow starts with derive-prompt"
else
    fail "planning flow missing derive-prompt as first step"
fi

# brainstorm must NOT reference derive-intent (snood artifact)
if grep -q "derive-intent" skills/brainstorm/SKILL.md 2>/dev/null; then
    fail "brainstorm references snood's derive-intent (should use derive-prompt)"
else
    pass "brainstorm does not reference stale derive-intent"
fi

# brainstorm must produce phased plan
if grep -q "Phase" skills/brainstorm/SKILL.md; then
    pass "brainstorm produces phased plan"
else
    fail "brainstorm missing phase structure"
fi

# execute must reference worktree isolation
if grep -qi "worktree" skills/execute/SKILL.md; then
    pass "execute references worktree isolation"
else
    fail "execute missing worktree isolation"
fi

# execute must reference code-reviewer
if grep -qi "code-review" skills/execute/SKILL.md; then
    pass "execute references code review"
else
    fail "execute missing code review reference"
fi

# execute must reference finish skill
if grep -q "snoodles:finish" skills/execute/SKILL.md; then
    pass "execute → finish (completion flow)"
else
    fail "execute missing finish reference"
fi

# debug must enforce root cause before fixes
if grep -q "Root Cause" skills/debug/SKILL.md; then
    pass "debug enforces root cause investigation"
else
    fail "debug missing root cause enforcement"
fi

# tdd must enforce test-before-code
if grep -q "FAILING TEST FIRST" skills/tdd/SKILL.md; then
    pass "tdd enforces test-first"
else
    fail "tdd missing test-first enforcement"
fi

echo ""

# --- 9. No duplicate content ---
echo "=== 9. No Duplicate Content ==="

# Intent extraction should NOT be in brainstorm (it's in derive-prompt)
if grep -q "Intent Extraction" skills/brainstorm/SKILL.md 2>/dev/null; then
    fail "Intent Extraction duplicated in brainstorm (should be in derive-prompt only)"
else
    pass "Intent Extraction not duplicated in brainstorm"
fi

# Tool routing should NOT be in derive-prompt SKILL.md (moved to references)
if grep -q "^\\*\\*Claude Code\\*\\*" skills/derive-prompt/SKILL.md 2>/dev/null; then
    fail "Tool routing still inline in derive-prompt (should be in references/tool-routing.md)"
else
    pass "Tool routing not inline in derive-prompt"
fi

# Epistemic honesty should NOT be in entry (it's in insights, injected alongside)
if grep -q "Epistemic" skills/entry/SKILL.md 2>/dev/null; then
    fail "Epistemic honesty duplicated in entry (should be in insights only)"
else
    pass "Epistemic honesty not duplicated in entry"
fi

echo ""

# --- 10. Session injection validation ---
echo "=== 10. Session Injection ==="

# Hook must exist and be executable
if [ -x "hooks/session-start" ]; then
    pass "hooks/session-start is executable"
else
    fail "hooks/session-start missing or not executable"
fi

if [ -f "hooks/hooks.json" ]; then
    pass "hooks/hooks.json exists"
else
    fail "hooks/hooks.json missing"
fi

# Hook must read both entry and insights
if grep -q "entry/SKILL.md" hooks/session-start; then
    pass "session-start reads entry skill"
else
    fail "session-start doesn't read entry skill"
fi

if grep -q "insights/SKILL.md" hooks/session-start; then
    pass "session-start reads insights skill"
else
    fail "session-start doesn't read insights skill"
fi

# Hook must produce valid JSON
if bash hooks/session-start 2>&1 | python3 -m json.tool > /dev/null 2>&1; then
    pass "session-start produces valid JSON"
else
    fail "session-start produces invalid JSON"
fi

echo ""

# --- 11. Plan doc format validation ---
echo "=== 11. Plan Doc Format ==="

# brainstorm must have task rules
BRAINSTORM="skills/brainstorm/SKILL.md"
for field in "Exact file paths" "Complete code" "Verification" "No vague verbs"; do
    if grep -qi "$field" "$BRAINSTORM"; then
        pass "brainstorm task rules: $field"
    else
        fail "brainstorm missing task rule: $field"
    fi
done

# brainstorm must enforce phase independence
if grep -qi "independent" "$BRAINSTORM"; then
    pass "brainstorm enforces task independence within phases"
else
    fail "brainstorm missing phase independence rule"
fi

echo ""

# --- 12. Word count targets ---
echo "=== 12. Word Count Targets ==="

check_word_count() {
    local file="$1"
    local name="$2"
    local max="$3"
    local count=$(wc -w < "$file" | tr -d ' ')
    if [ "$count" -le "$max" ]; then
        pass "$name: $count words (target ≤$max)"
    else
        warn "$name: $count words (target ≤$max, over by $((count - max)))"
    fi
}

# Session-injected skills must be lean
check_word_count "skills/entry/SKILL.md" "entry (session-injected)" 400
check_word_count "skills/insights/SKILL.md" "insights (session-injected)" 300

# Other skills can be larger but still bounded
check_word_count "skills/brainstorm/SKILL.md" "brainstorm" 900
check_word_count "skills/execute/SKILL.md" "execute" 1000
check_word_count "skills/verify/SKILL.md" "verify" 300
check_word_count "skills/debug/SKILL.md" "debug" 700
check_word_count "skills/tdd/SKILL.md" "tdd" 700
check_word_count "skills/finish/SKILL.md" "finish" 300

echo ""

# --- Summary ---
echo "========================================"
echo " Summary"
echo "========================================"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: ALL CHECKS PASSED"
    exit 0
else
    echo "STATUS: $FAIL FAILURE(S) DETECTED"
    exit 1
fi
