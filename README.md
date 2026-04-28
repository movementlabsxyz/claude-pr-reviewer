# claude-pr-reviewer

Reusable assets for the **audit-pr** subagent that reviews pull requests in
[`movementlabsxyz/aptos-core`](https://github.com/movementlabsxyz/aptos-core).

This repo holds only the *contents* the audit consumes:

| Path | Purpose |
|---|---|
| `agents/audit-pr.md` | Subagent definition (frontmatter + system prompt) |
| `agents/audit-pr/` | Analyzer references, taxonomy, risk scoring, scripts |
| `prompts/audit-pr.md` | Top-level prompt fed to `claude-code-action` |
| `settings.json` | CI-time Claude Code permissions allow/deny list |

The GitHub Actions workflow that *triggers* the audit lives in `aptos-core`
itself (events only fire from a workflow committed to the same repo).

## Consumer contract

A consuming workflow must:

1. Check out this repo to `.claude-reviewer/` (or any path of its choice).
2. Stage the assets into the workspace where Claude Code discovers them:
   ```bash
   mkdir -p .claude/agents
   cp -r .claude-reviewer/agents/audit-pr  .claude/agents/
   cp    .claude-reviewer/agents/audit-pr.md .claude/agents/
   cp    .claude-reviewer/settings.json    .claude/settings.json
   chmod +x .claude/agents/audit-pr/scripts/*.sh
   ```
3. Pass `.claude-reviewer/prompts/audit-pr.md` as the `prompt:` input to
   `anthropics/claude-code-action@v1`.
4. Export the env vars the subagent reads (see `agents/audit-pr.md` for the
   full list — at minimum: `PR_NUMBER`, `BASE_SHA`, `HEAD_SHA`, `REPO_PATH`,
   `AGENT_DIR`, `GITHUB_REPOSITORY`, `AUDIT_MODE`).

`AGENT_DIR` is conventionally `${GITHUB_WORKSPACE}/.claude/agents/audit-pr` —
the location the staging step above produces.

A reference caller workflow is committed in `aptos-core` at
`.github/workflows/claude-audit-pr.yml`.

## Versioning

| Tag | Meaning |
|---|---|
| `vX.Y.Z` | Immutable release — recommended pin for production callers |
| `vX` | Rolling pointer to latest `vX.*.*` — convenient but mutable |

Layout changes (moving/renaming `agents/`, `prompts/`, `settings.json`) are
**breaking** and require a major bump. Any change to file *contents* (prompts,
analyzers, scripts) is non-breaking and ships in the next minor or patch.

## Local iteration

This repo is content-only — there is nothing to install or build. Edit, commit,
tag, push. The next aptos-core PR audit will pick up the new tag (or rolling
ref) on its next run.
