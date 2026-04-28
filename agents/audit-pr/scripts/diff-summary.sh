#!/usr/bin/env bash
# diff-summary.sh — Extract structured diff summary for a PR or commit range
#
# Usage:
#   ./diff-summary.sh <repo_path> <base_sha> <head_sha>
#   ./diff-summary.sh <repo_path> --pr <pr_number>   (requires gh CLI)
#
# Outputs structured sections the orchestrator can parse:
#   1. PR metadata (title, author, description, commit messages)
#   2. Changed files with line counts
#   3. Changed function/struct signatures (Rust + Move)
#   4. Filtered diff hunks (only .rs, .move, .toml — skips tests and generated files)

set -euo pipefail

REPO="$1"
shift

cd "$REPO"

if [[ "${1:-}" == "--pr" ]]; then
    PR_NUM="$2"
    BASE_SHA=$(gh pr view "$PR_NUM" --json baseRefOid -q '.baseRefOid')
    HEAD_SHA=$(gh pr view "$PR_NUM" --json headRefOid -q '.headRefOid')

    echo "=== PR METADATA ==="
    gh pr view "$PR_NUM" --json title,author,body,commits --template \
      'Title: {{.title}}
Author: {{.author.login}}

Description:
{{.body}}

Commits:
{{range .commits}}  - {{.oid | truncate 8}}: {{.messageHeadline}}
{{end}}'
    echo ""
else
    BASE_SHA="$1"
    HEAD_SHA="$2"

    echo "=== COMMIT MESSAGES ==="
    git log --oneline "$BASE_SHA".."$HEAD_SHA"
    echo ""
fi

echo "=== CHANGED FILES ==="
git diff --numstat "$BASE_SHA".."$HEAD_SHA" | while read added removed file; do
    echo "  $file  (+$added -$removed)"
done
echo ""

echo "=== CHANGED SIGNATURES (Rust) ==="
git diff "$BASE_SHA".."$HEAD_SHA" -- '*.rs' \
  | grep -E '^[\+\-].*(pub |pub\(crate\) )?(fn |struct |enum |trait |impl |mod )' \
  | grep -v '^\+\+\+' | grep -v '^\-\-\-' \
  | sed 's/^\+/  + /' | sed 's/^\-/  - /' || true
echo ""

echo "=== CHANGED SIGNATURES (Move) ==="
git diff "$BASE_SHA".."$HEAD_SHA" -- '*.move' \
  | grep -E '^[\+\-].*(public |public\(friend\) |entry |fun |struct |module )' \
  | grep -v '^\+\+\+' | grep -v '^\-\-\-' \
  | sed 's/^\+/  + /' | sed 's/^\-/  - /' || true
echo ""

echo "=== DIFF (source only, excluding tests) ==="
git diff "$BASE_SHA".."$HEAD_SHA" \
  -- '*.rs' '*.move' '*.toml' \
  ':!**/tests/**' ':!**/test_*' ':!**/*_test.rs' ':!**/*_tests.move' \
  ':!**/testsuite/**' ':!**/e2e-move-tests/**'
