#!/bin/bash
set -e

# npm-toolkit v2.0.0 Red Team Acceptance Tests
# Tests Progressive Disclosure upgrade based on design doc only

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$PLUGIN_ROOT/../.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file_exists() {
  if [ -f "$1" ]; then
    pass "$2"
  else
    fail "$2"
  fi
}

check_line_count_lt() {
  local file="$1"
  local max="$2"
  local label="$3"
  if [ ! -f "$file" ]; then
    fail "$label (file not found)"
    return
  fi
  local count
  count=$(wc -l < "$file" | tr -d ' ')
  if [ "$count" -lt "$max" ]; then
    pass "$label ($count lines < $max)"
  else
    fail "$label ($count lines >= $max)"
  fi
}

check_line_count_gte() {
  local file="$1"
  local min="$2"
  local label="$3"
  if [ ! -f "$file" ]; then
    fail "$label (file not found)"
    return
  fi
  local count
  count=$(wc -l < "$file" | tr -d ' ')
  if [ "$count" -ge "$min" ]; then
    pass "$label ($count lines >= $min)"
  else
    fail "$label ($count lines < $min)"
  fi
}

check_contains() {
  local file="$1"
  local keyword="$2"
  local label="$3"
  if [ ! -f "$file" ]; then
    fail "$label (file not found)"
    return
  fi
  if grep -qi "$keyword" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_contains_exact() {
  local file="$1"
  local keyword="$2"
  local label="$3"
  if [ ! -f "$file" ]; then
    fail "$label (file not found)"
    return
  fi
  if grep -q "$keyword" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "========================================"
echo "npm-toolkit v2.0.0 Acceptance Tests"
echo "========================================"
echo ""

NPM_PUBLISH="$PLUGIN_ROOT/skills/npm-publish"
GH_ACTIONS="$PLUGIN_ROOT/skills/github-actions-setup"

# ---- Structure ----
echo "--- Structure ---"
check_file_exists "$NPM_PUBLISH/references/troubleshooting.md" \
  "npm-publish/references/troubleshooting.md exists"
check_file_exists "$NPM_PUBLISH/references/release-automation.md" \
  "npm-publish/references/release-automation.md exists"
check_file_exists "$GH_ACTIONS/references/advanced-patterns.md" \
  "github-actions-setup/references/advanced-patterns.md exists"
check_line_count_lt "$NPM_PUBLISH/SKILL.md" 200 \
  "npm-publish/SKILL.md < 200 lines"
check_line_count_lt "$GH_ACTIONS/SKILL.md" 200 \
  "github-actions-setup/SKILL.md < 200 lines"

echo ""

# ---- Reference paths ----
echo "--- Reference Paths ---"
check_contains "$NPM_PUBLISH/SKILL.md" "references/troubleshooting.md" \
  "npm-publish/SKILL.md references troubleshooting.md"
check_contains "$NPM_PUBLISH/SKILL.md" "references/release-automation.md" \
  "npm-publish/SKILL.md references release-automation.md"
check_contains "$GH_ACTIONS/SKILL.md" "references/advanced-patterns.md" \
  "github-actions-setup/SKILL.md references advanced-patterns.md"

echo ""

# ---- Content coverage: troubleshooting.md ----
echo "--- Content: troubleshooting.md ---"
TS="$NPM_PUBLISH/references/troubleshooting.md"
check_contains "$TS" "E404" "troubleshooting.md contains E404"
check_contains "$TS" "E422" "troubleshooting.md contains E422"
check_contains "$TS" "2FA" "troubleshooting.md contains 2FA"
check_contains "$TS" "provenance" "troubleshooting.md contains provenance"

echo ""

# ---- Content coverage: release-automation.md ----
echo "--- Content: release-automation.md ---"
RA="$NPM_PUBLISH/references/release-automation.md"
check_contains_exact "$RA" "Changesets" "release-automation.md contains Changesets"
check_contains "$RA" "semantic-release" "release-automation.md contains semantic-release"
check_contains "$RA" "release-please" "release-automation.md contains release-please"
check_contains "$RA" "monorepo" "release-automation.md contains monorepo"

echo ""

# ---- Content coverage: advanced-patterns.md ----
echo "--- Content: advanced-patterns.md ---"
AP="$GH_ACTIONS/references/advanced-patterns.md"
check_contains "$AP" "composite" "advanced-patterns.md contains composite"
check_contains "$AP" "workflow_call" "advanced-patterns.md contains workflow_call"
check_contains "$AP" "cache" "advanced-patterns.md contains cache"

echo ""

# ---- Metadata ----
echo "--- Metadata ---"
PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
if [ ! -f "$PLUGIN_JSON" ]; then
  fail "plugin.json exists"
else
  # Check version is exactly "2.0.0"
  if grep -q '"version"' "$PLUGIN_JSON" && grep -q '"2.0.0"' "$PLUGIN_JSON"; then
    pass "plugin.json version is 2.0.0"
  else
    fail "plugin.json version is 2.0.0"
  fi
fi

check_line_count_gte "$PLUGIN_ROOT/README.md" 50 \
  "README.md >= 50 lines"

echo ""

# ---- CLAUDE.md ----
echo "--- CLAUDE.md ---"
check_contains "$PROJECT_ROOT/CLAUDE.md" "npm-toolkit" \
  "CLAUDE.md contains npm-toolkit"

echo ""

# ---- SKILL.md frontmatter ----
echo "--- SKILL.md Frontmatter ---"
check_frontmatter() {
  local file="$1"
  local label="$2"
  if [ ! -f "$file" ]; then
    fail "$label (file not found)"
    return
  fi
  local first_line
  first_line=$(head -n 1 "$file")
  if [ "$first_line" != "---" ]; then
    fail "$label (first line is not ---)"
    return
  fi
  # Find second --- (closing frontmatter) on line 2+
  local closing_line
  closing_line=$(tail -n +2 "$file" | grep -n "^---$" | head -n 1 | cut -d: -f1)
  if [ -z "$closing_line" ] || [ "$closing_line" -lt 2 ]; then
    fail "$label (no closing --- or frontmatter too short)"
    return
  fi
  pass "$label"
}

check_frontmatter "$NPM_PUBLISH/SKILL.md" \
  "npm-publish/SKILL.md has valid YAML frontmatter"
check_frontmatter "$GH_ACTIONS/SKILL.md" \
  "github-actions-setup/SKILL.md has valid YAML frontmatter"

echo ""

# ---- Summary ----
echo "========================================"
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT failed"
echo "========================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
