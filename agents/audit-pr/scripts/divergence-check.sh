#!/usr/bin/env bash
# divergence-check.sh — Compare m1 files against upstream aptos-core
#
# Usage:
#   ./divergence-check.sh <m1_repo_path> <upstream_repo_path> <file1> [file2 ...]
#
# For each file, outputs:
#   - Whether the file exists in both repos
#   - Line count difference
#   - Diff stat (how many lines differ)
#   - Divergence score (0.0 = identical, 1.0 = completely different)
#
# NOTE (v1 CI integration): this script is shipped but NOT invoked by the
# default workflow. Divergence scoring is v1-disabled — the workflow runs
# on a single local checkout and does not clone aptos-labs/aptos-core as a
# sibling. A follow-up PR can wire this up by adding an `actions/checkout`
# step for the upstream repo and passing its path into the subagent.

set -euo pipefail

M1_REPO="$1"
UPSTREAM_REPO="$2"
shift 2

for FILE in "$@"; do
    echo "=== $FILE ==="

    M1_FILE="$M1_REPO/$FILE"
    UP_FILE="$UPSTREAM_REPO/$FILE"

    if [[ ! -f "$M1_FILE" ]]; then
        echo "  m1: NOT FOUND (Movement-only or deleted)"
        echo "  divergence: 1.0"
        echo ""
        continue
    fi

    if [[ ! -f "$UP_FILE" ]]; then
        echo "  upstream: NOT FOUND (Movement-specific file)"
        echo "  divergence: 1.0"
        echo ""
        continue
    fi

    M1_LINES=$(wc -l < "$M1_FILE")
    UP_LINES=$(wc -l < "$UP_FILE")
    DIFF_LINES=$(diff "$M1_FILE" "$UP_FILE" | grep -c '^[<>]' || true)
    TOTAL_LINES=$(( M1_LINES > UP_LINES ? M1_LINES : UP_LINES ))

    if [[ "$TOTAL_LINES" -eq 0 ]]; then
        SCORE="0.0"
    else
        SCORE=$(awk "BEGIN {printf \"%.2f\", $DIFF_LINES / $TOTAL_LINES}")
    fi

    echo "  m1: $M1_LINES lines"
    echo "  upstream: $UP_LINES lines"
    echo "  differing lines: $DIFF_LINES"
    echo "  divergence: $SCORE"

    if [[ "$DIFF_LINES" -gt 0 ]]; then
        echo "  summary:"
        diff "$M1_FILE" "$UP_FILE" --stat 2>/dev/null || true
    fi
    echo ""
done
