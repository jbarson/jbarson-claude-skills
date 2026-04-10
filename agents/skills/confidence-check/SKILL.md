---
name: confidence-check
description: Assess production safety confidence for a PR with a numeric score and gap-closing actions. Use this skill whenever the user asks "how confident are you", "confidence check", "production confidence", "will this break prod", "what's your confidence on this", "is this safe to ship", or when you've just finished preparing a PR and want to proactively assess its production risk. Unlike production-safety-check (which scans for regression patterns), this skill produces a single confidence percentage representing "probability this will NOT cause a production incident" and offers concrete actions to raise the score. Use this after code is written, before or after creating PVCs, or when reviewing any PR headed for production.
---

# Confidence Check

Produce a confidence score (0-100%) that a PR will **not** cause a production incident, backed by evidence. The number represents your honest assessment of "probability of no production incident if this merges and deploys."

## Arguments

- `$ARGUMENTS` — One of:
  - PR URL
  - PR number (uses current repo)
  - Empty (uses current branch's open PR)
  - A file path or diff to assess

## Phase 1: Understand the Change

Get the full picture before scoring.

### Gather

```bash
gh pr view {PR} --json title,body,files,additions,deletions,headRefName,baseRefName
gh pr diff {PR}
```

Read every changed file. Understand not just *what* changed but *what it touches at runtime* — downstream callers, database tables, API consumers, background jobs.

### Categorise each change

For each modified file, note:
- **What it does**: model change, API param, migration, interactor logic, UI component, config
- **Who calls it**: trace callers — is this in a hot path? A background job? A rarely-hit edge case?
- **What could go wrong**: the specific failure mode if this change has a bug or unexpected interaction

## Phase 2: Verify Assumptions Against Production

This is the step that distinguishes a confidence check from a code review. Code looks correct in the diff — production data reveals whether it's safe.

### Check with Keystone replica queries

For each assumption the change relies on, verify it:

| Assumption type | Verification query |
|---|---|
| "No existing data has X" | `SELECT COUNT(*) FROM table WHERE condition` |
| "This column is always populated" | `SELECT COUNT(*) FROM table WHERE column IS NULL` |
| "This resource/row exists" | `SELECT * FROM table WHERE name = 'expected'` |
| "No merchants use this feature yet" | `SELECT COUNT(DISTINCT merchant_id) FROM table WHERE feature_condition` |
| "This code path is never hit" | Check Datadog logs/traces or Sentry for the endpoint |

**Zero affected records is the only safe answer.** Non-zero requires an explanation of why those records won't trigger the failure mode.

### Check for implicit dependencies

Look for things the code assumes exist but doesn't create:
- Database rows (seed data, permission resources, feature flags in LaunchDarkly)
- Configuration (env vars, feature flag defaults)
- Other PRs that must merge/deploy first
- Gem/package bumps needed in downstream repos
- Migrations that must run before the code is called

This is where the hardest bugs hide. The code is correct, but it references something that doesn't exist in production yet.

## Phase 3: Score and Explain

### Calculate the confidence score

Start at 100% and subtract for each risk factor:

| Risk factor | Deduction |
|---|---|
| Untested code path | -5% to -15% depending on blast radius |
| Implicit dependency not verified | -10% to -20% |
| Production data assumption not checked | -5% to -10% |
| Missing specs for new behaviour | -5% |
| Deploy ordering dependency | -3% to -5% |
| Touches financial calculations | -5% to -10% unless thoroughly verified |
| Modifies shared code used by multiple integrations | -5% to -10% |
| No feature flag gating | -3% (only if change is behavioural) |
| CI hasn't run yet | -3% to -5% |

These are guidelines, not rigid rules. Use judgment — a missing spec on a dormant no-op method is different from a missing spec on a discount calculator.

### Present the result

```
## Confidence Check: {PR title}

**Score: {N}%** — {one-line verdict}

### Why it's at {N}%
- {Positive factor}: {evidence}
- {Positive factor}: {evidence}

### The {100-N}% gap
1. {Risk factor} (-X%): {specific concern}
2. {Risk factor} (-X%): {specific concern}

### To close the gap
- [ ] {Concrete action that would raise the score — e.g., "Add spec asserting X"}
- [ ] {Concrete action — e.g., "Run replica query: SELECT COUNT(*)..."}
- [ ] {Concrete action — e.g., "Verify feature flag exists in LaunchDarkly"}
```

### Confidence tiers

| Score | Meaning | Recommendation |
|---|---|---|
| 95-100% | Ship it. Risks are theoretical or fully mitigated. | Merge when CI is green. |
| 85-94% | High confidence. Small gaps remain but they're identified. | Close the gaps or accept the known risk. |
| 70-84% | Moderate confidence. Real questions unanswered. | Do not merge until gaps are closed. |
| Below 70% | Significant concerns. | Stop and investigate before proceeding. |

## Phase 4: Close the Gap (if asked)

When the user says "close the gap" or "let's fix that":

1. Work through each gap item in order
2. After completing each action, re-score
3. Present the updated confidence with the resolved items struck through

The goal is to get to 95%+. Perfection (100%) is rare — there's almost always residual risk from things like "CI hasn't run" or "deploy ordering." That's fine. The point is to identify and resolve the risks that are within your control.
