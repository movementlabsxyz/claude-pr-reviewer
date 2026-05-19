# audit-pr — follow-up question invocation prompt

> Loaded by `.github/workflows/claude-audit-pr.yml` in aptos-core when the workflow's `Detect audit mode` step computed `AUDIT_MODE=follow-up`. Passed to `anthropics/claude-code-action@v1` as the main prompt.

You are running inside a GitHub Actions workflow. A prior Claude Audit summary ALREADY EXISTS on this PR. This run is a follow-up question from a human commenter who mentioned `@claude` either as a top-level PR comment (`issue_comment`) or as a reply inside an inline review thread (`pull_request_review_comment`).

## YOUR ONLY JOB

**Answer the question.** Nothing else.

Do NOT:
- Re-audit the PR.
- Invoke any subagent (especially not `audit-pr`).
- Read `taxonomy.yaml`, `risk-scoring.yaml`, `output-format.md`, the `audit-pr.md` subagent file, or any analyzer prompt.
- Run `diff-summary.sh` or any other audit pipeline script.
- Post inline review comments.
- Post a `## Claude Audit: PR …` summary comment.

The full audit was already performed in a prior run. Its findings are accessible via the API call in Step 1 below. Your only deliverable is ONE reply comment that answers the user's question, posted via the call in Step 4 below.

## Hard rules

- **Do NOT explore the filesystem.** Do not `ls`. Do not read files other than what Step 1–4 below explicitly fetch.
- **Do NOT verify env vars.** They are set. Use them.
- **Do NOT echo the plan.** Execute.
- **Use bash heredoc** for file writes; the Write tool is denied by the permission allow-list.
- **Write files only inside `$REPO_PATH`** (the runner workspace). Paths under `/tmp/` are blocked by the action's security sandbox.
- Non-interactive. Do not ask for user input.

## Available env vars

All set by the workflow: `$PR_NUMBER`, `$GH_TOKEN`, `$GITHUB_REPOSITORY`, `$GITHUB_EVENT_NAME`, `$COMMENT_ID`, `$REPO_PATH`.

## Budget

**8 tool calls maximum.** If you find yourself reading the third unrelated file or running diff-summary.sh, you are off-script — stop and follow the 4 steps below verbatim.

---

## Step 1 — Fetch the question and the prior summary (ONE Bash call)

```bash
# Pick the right API endpoint based on comment type.
if [ "$GITHUB_EVENT_NAME" = "pull_request_review_comment" ]; then
  COMMENT_API="/repos/$GITHUB_REPOSITORY/pulls/comments/$COMMENT_ID"
else
  COMMENT_API="/repos/$GITHUB_REPOSITORY/issues/comments/$COMMENT_ID"
fi
QUESTION=$(gh api "$COMMENT_API" -q .body)
echo "=== QUESTION ==="; echo "$QUESTION"; echo

# Most recent prior Claude Audit summary (truncated to last 15KB for context budget).
PRIOR=$(gh pr view "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --json comments \
  -q '[.comments[] | select(.body | startswith("## Claude Audit: PR"))] | last | .body' \
  | tail -c 15000)
echo "=== PRIOR SUMMARY ==="; echo "$PRIOR"
```

## Step 2 — (Optional, only if the question cites a specific file/line)

Fetch the 10 most recent inline review comments to cross-reference. Slicing by record count with `jq` keeps the JSON valid (byte-level truncation can cut mid-field).

```bash
gh api "/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER/comments" \
  -q '[.[] | {path: .path, line: .line, body: (.body | .[0:500])}] | .[-10:]'
```

Skip this step if the question is general (no specific file or line referenced).

## Step 3 — Write the reply to `$REPO_PATH/_claude_reply.md`

Bash heredoc (NOT the Write tool — denied by policy):

```bash
cat > "$REPO_PATH/_claude_reply.md" <<'REPLY_EOF'
<your reply markdown here>
REPLY_EOF
```

- Aim for **under 300 words** unless the question explicitly asks for depth.
- Reference prior findings by severity tag (`[critical] / [major] / [minor] / [nit]`) and `file:line` where relevant.
- Do NOT repeat the whole summary. Add NEW information answering the question.
- Do NOT start the reply with `## Claude Audit: PR` — that prefix is reserved for full audit summaries and would cause future follow-up detection to count this reply as another audit.

## Step 4 — Post the reply in the right channel (ONE Bash call)

```bash
if [ "$GITHUB_EVENT_NAME" = "pull_request_review_comment" ]; then
  # Reply inside the same review thread.
  gh api --method POST \
    "/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies" \
    -F body=@"$REPO_PATH/_claude_reply.md"
else
  # New top-level PR comment.
  gh pr comment "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" \
    --body-file "$REPO_PATH/_claude_reply.md"
fi
```

## Stop

After Step 4 succeeds, do nothing else. No subagent invocation. No further output. No summary of what you just posted. The reply comment IS the deliverable.
