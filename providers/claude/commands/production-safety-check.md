---
name: production-safety-check
description: Audit a PR for production regression risks before merge. Use this skill whenever the user says "is this safe to merge", "check for regressions", "production safety", "will this break production", "audit this PR", "safety check", or any time a PR is about to be merged and you want to verify it won't affect live customers. Also use proactively after completing significant code changes, before creating PVC entries, or when reviewing PRs in thanx-* repositories. This skill works for both Ruby/Rails and React/TypeScript codebases.
---

# Production Safety Check

Audit a PR for behaviour changes that could regress production. The core insight: **diffs don't tell you what's safe — production data does.** Every behaviour change needs verification against real data, not just logic review.

## Arguments

Accept one of:
- A PR URL (e.g., `https://github.com/thanx/thanx-offer/pull/1094`)
- A PR number + repo (e.g., `1094` in current repo)
- Empty — find the open PR for the current branch

## Step 1: Gather PR Context

```bash
# Get PR metadata
gh pr view {PR} --json title,body,headRefName,baseRefName,files,additions,deletions

# Check if branch is behind master
gh api repos/{owner}/{repo}/compare/{branch}...master --jq '.ahead_by'
```

**If the branch is behind master by more than 5 commits, WARN immediately.** Stale branches cause phantom deletions in the diff — code added to master after the branch diverged appears as deleted. This is how a RecoveryAI permission mapping was nearly deleted from a merchant-ui PR.

## Step 2: Get the Diff

```bash
gh pr diff {PR}
```

Split the diff into two categories:
- **Ruby files** (`*.rb`)
- **TypeScript/React files** (`*.ts`, `*.tsx`)

## Step 3: Scan for Behaviour-Changing Patterns

For every changed file under `app/` or `src/` (skip spec/test files for now — those are reviewed separately), scan for these patterns:

### Ruby Patterns

| Pattern | What to look for in the diff | Why it matters |
|---|---|---|
| **Guard clause removal** | Lines starting with `-` that contain `return if`, `return unless`, `.blank?`, `.nil?`, `optional: true` | Existing code relied on these guards. Removal may expose nil errors on production data. |
| **New error/rejection paths** | Lines starting with `+` that contain `error!`, `context.fail!`, `raise`, `reject_missing` | New rejection paths can block transactions that previously succeeded. |
| **Association changes** | `belongs_to` with `optional:` added or removed | Changes what records can be created/loaded without errors. |
| **Validation tightening** | New `validates`, modified `configured_correctly?`, new conditional checks | May reject data that previously passed. |
| **Feature flag removal** | `-` lines containing `ThanxFeatureFlag`, `variation(`, `feature_flag` | Behaviour that was gated is now always-on (or always-off). |
| **Discount/calculation changes** | Modified methods in `calculate_discount/`, `prepare/check_items`, price/amount logic | Directly affects money. |
| **Interactor rewrite** | File with >50% of lines changed, or `organize` replaced with manual `self.call` | Control flow changed — steps may run in different order or be skipped. |

### TypeScript/React Patterns

| Pattern | What to look for in the diff | Why it matters |
|---|---|---|
| **Permission map changes** | Changes to `permissionMap.ts` or CASL subjects — check both `+` AND `-` lines | Additions are usually safe. Deletions break RBAC access for merchants. |
| **Route changes** | Modified `Routes.tsx`, path strings, route guards | May expose or hide pages. |
| **Feature flag removal** | `-` lines containing `useFlags()`, `LaunchDarkly`, flag variable removal | Gated UI is now always visible (or never visible). |
| **API endpoint changes** | Modified files in `api/`, changed fetch/axios URLs, new/removed endpoints | May break client-server contract. |
| **Redux state shape** | Changed reducer initial state, removed action types, renamed selectors | Components depending on old shape will break. |
| **Prop interface changes** | Removed props from interfaces/types, changed required→optional or vice versa | Parent components passing old props get type errors (caught by TS) but runtime behaviour may change. |
| **Date/timezone handling** | Changes involving `new Date()`, `moment`, `toISOString`, timezone conversion | Silent data corruption — dates may shift by hours. |

## Step 4: Classify Each Finding

For every behaviour change found, classify it:

### GATED
The change only executes when a feature flag is enabled. Trace the code path:
- Is the method/component only called from a flag-gated parent?
- Does the method itself check a flag early and return?
- Is `context.promo_code_flow` (or similar) required to be true, and is that only set when a flag is on?

GATED changes are **safe** — they won't affect production until the flag is enabled.

### UNGATED
The change runs for all users/merchants regardless of flags. These are the dangerous ones.

For each UNGATED change, suggest a specific verification step:
- **For data changes:** A production replica query to count affected records
- **For API changes:** Which endpoints/responses change and for whom
- **For UI changes:** Which pages/components are affected and for which merchants
- **For calculation changes:** Which reward/discount configurations are affected

### ADDITIVE
New code that creates a new path without modifying existing paths:
- New files that are only reached from new (gated) code
- New error codes in a case/when that no existing flow produces
- New `store_accessor` fields on a JSON column
- New optional method parameters with defaults

ADDITIVE changes are **safe** — existing flows never reach them.

## Step 5: Check for Stale Branch Risks

If the branch is behind master:
1. Look at the diff for `-` (deletion) lines in files the PR didn't intentionally modify
2. Cross-reference: was the "deleted" code actually added to master after the branch diverged?
3. If yes, **flag prominently** — merging will revert that master change

## Step 6: Output the Report

Present findings as a summary table:

```
## Production Safety Audit: {PR title}

**Branch:** {branch} | **Behind master by:** {N} commits {⚠️ if > 5}

### Findings

| File | Change | Classification | Risk |
|---|---|---|---|
| app/models/provider/ticket.rb | `belongs_to :user` optional removed | UNGATED | **HIGH** — query: `SELECT COUNT(*) FROM provider_tickets WHERE user_id IS NULL` |
| app/interactors/qu/loyalty/prepare/promo_code.rb | New promo detection interactor | GATED (qu-promo-codes flag) | None |
| src/utilities/permissionMap.ts | `recovery_ai` entry deleted | UNGATED (stale branch) | **CRITICAL** — rebase onto master |

### Summary
- **UNGATED changes requiring verification:** {count}
- **GATED changes (safe):** {count}
- **ADDITIVE changes (safe):** {count}

### Recommended actions
{For each UNGATED HIGH/CRITICAL finding, list the specific verification step}
```

## Step 7: Production Queries (if Keystone available)

If `mcp__keystone__replica_query` is available and the user approves, run verification queries for UNGATED findings:

- **offer** database (Postgres): Provider tickets, transactions
- **nucleus** database (MySQL): Redeems, programs, promotions, templates
- **pos** database (MySQL): POS transactions

Include query results in the report. **Zero affected records is the only safe number.** Non-zero requires explanation of why those records won't be hit by the changed code path.

## Important Reminders

- A test that passes does not mean the change is safe. The `validate_redeem` spec passed while the code would have broken 101 active reward programs.
- "Identical across branches" does not mean "safe." Shared code extracted from feature branches still needs production verification.
- Guard clauses exist for a reason. Before removing one, check why it was added (`git log -p --all -S 'the line'`).
- Feature flag `default_value` matters. `default_value: false` on a new flag that gates existing behaviour means that behaviour stops until the flag is created in LaunchDarkly.
