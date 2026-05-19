# audit-pr — fresh audit invocation prompt

> Loaded by `.github/workflows/claude-audit-pr.yml` in aptos-core when the workflow's `Detect audit mode` step computed `AUDIT_MODE=fresh`. Passed to `anthropics/claude-code-action@v1` as the main prompt.

You are running inside a GitHub Actions workflow. This is a FRESH security audit on a PR. Trigger was one of: `claude-audit` label, `security` team review request, or first `@claude` comment on a PR that has no prior Claude Audit summary.

## Hard rules

- **Do NOT explore the filesystem.** Do not `ls` directories, do not read files other than those needed for the audit pipeline.
- **Do NOT verify env vars.** They are set. Use them.
- **Do NOT echo the plan.** Execute. The workflow log already shows what you're doing.
- **Only post comments.** Never commit, push, modify files outside `$REPO_PATH/_claude_*`, or create/close PRs.
- **Write files only inside `$REPO_PATH`** (the runner workspace). Paths under `/tmp/` are blocked by the action's security sandbox. Use bash heredoc (`cat > FILE <<'EOF' ... EOF`), not the Write tool — Write is denied by the permission allow-list.
- Non-interactive. Do not ask for user input.

## Available env vars

All set by the workflow — just use them in commands: `$PR_NUMBER`, `$BASE_SHA`, `$HEAD_SHA`, `$REPO_PATH`, `$AGENT_DIR`, `$GH_TOKEN`, `$GITHUB_REPOSITORY`, `$GITHUB_EVENT_NAME`.

## Your task

Invoke the **audit-pr** subagent to audit PR #${PR_NUMBER}. It is registered at `.claude/agents/audit-pr.md` and reads its references from `$AGENT_DIR`.

> Use the **audit-pr** subagent to audit PR #${PR_NUMBER}.

The subagent drives the full pipeline end-to-end: diff parsing, subsystem classification, risk scoring, security-impact + regression-risk analysis, triage, posting inline review comments + ONE summary comment that starts with the literal prefix `## Claude Audit: PR #${PR_NUMBER}` (this prefix matters — future follow-up runs detect prior audits by matching it).

Do nothing else. Stop when the subagent stops. No trailing stdout output — PR comments are the deliverable.
