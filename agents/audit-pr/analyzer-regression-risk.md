# Regression Risk Analyzer — Prompt Template

> Read by: orchestrator for high/critical risk packets.
> Runs AFTER the security-impact analyzer. Receives its findings as additional context.
> Placeholders: {PACKET_SUMMARY}, {DIFF_HUNKS}, {CONTEXT}, {CALLERS}, {TESTS}, {PRIOR_FINDINGS}, {SECURITY_FINDINGS}

---

You are analyzing a change to Movement's aptos-core fork (m1 branch) for regression risk — the likelihood that this change breaks existing correct behavior.

## Change Summary

{PACKET_SUMMARY}

## Diff

{DIFF_HUNKS}

## Callers of Changed Code

{CALLERS}

## Existing Tests Covering This Code

{TESTS}

## Prior Findings in These Files

{PRIOR_FINDINGS}

## Security Findings (from security-impact analyzer)

{SECURITY_FINDINGS}

## Your Task

### 1. Behavioral Regressions

For each changed function or module:
- What behavior did callers depend on before this change?
- Does the change preserve that behavior for all callers, or only some?
- Are there callers that were not considered by the change author?
- Does the change alter error/abort behavior that callers may catch or propagate?

### 2. State Transition Regressions

- Does the change alter what state is written for any operation?
- Could existing on-chain state become inconsistent with new code expectations?
- Are there migration or upgrade considerations?

### 3. Cross-Subsystem Impact

- Do the callers span multiple subsystems?
- Could a change in one subsystem's behavior cascade into another?
- Are there implicit contracts (undocumented assumptions) between subsystems?

### 4. Test Coverage Gaps

- Which changed code paths have existing test coverage?
- Which changed code paths have NO test coverage?
- Do existing tests still pass with the semantic change, even though behavior changed? (tests that pass but are now wrong)

### 5. Interaction with Prior Findings

- Does this change fix, worsen, or reintroduce any prior finding?
- Does it create new interactions with previously-identified risky code?

## Output Format

For each regression risk:

```
## Regression: {title}

**Risk Level**: critical / high / medium / low
**Confidence**: {0.0 - 1.0} — {why}
**Location**: {file}:{line}
**Affected Callers**: {list of functions/modules that depend on changed behavior}
**Description**: {what behavioral contract is broken or at risk}
**Scenario**: {specific sequence of operations that would trigger the regression}
**Test Gap**: {is there a test for this? if not, what test should exist?}

**Fix Options**:
| Option | Effort | Tradeoff | Code Change? |
|--------|--------|----------|-------------|
| {option A} | none/low/medium/high | {what you accept} | yes/no |
| {option B} | ... | ... | ... |

**Recommended Fix**: {which option and why}
**Fix Details**: {specific implementation guidance — where to change, what to change}
```

ALL fields above are mandatory for every finding. If a finding has only one fix path, still list it as a single-row table.

If no regression risks found, state that explicitly with reasoning.
