---
name: production-checklist
description: >
  Auto-generate a Production Change Validation Log entry for one or more PRs.
  Researches blast radius, test coverage, deployment risk, and cross-repo impact,
  then drafts the full 8-section checklist for engineer review.
  Trigger on: "validate change", "change validation", "production checklist", "deploy checklist".
allowed-tools: Read, Grep, Glob, Bash, Agent, WebFetch, mcp__claude_ai_Notion__notion-search, mcp__claude_ai_Notion__notion-fetch, mcp__claude_ai_Notion__notion-create-pages, mcp__claude_ai_Notion__notion-update-page, mcp__claude_ai_Notion__notion-query-database-view, ReadMcpResourceTool, AskUserQuestion, mcp__plugin_cortex_keystone__replica_query, mcp__plugin_cortex_keystone__launchdarkly_feature_flag, mcp__plugin_cortex_keystone__circleci_pipeline_status, mcp__plugin_cortex_keystone__datadog_monitors, mcp__plugin_cortex_keystone__sentry_issues
---

# Production Change Validation

Auto-generate a Production Change Validation Log entry. Research the change, draft all 8 sections, get engineer approval, save to Notion, and link to the PR.

## Arguments

- `$ARGUMENTS` — One or more of:
  - PR URL(s), space-separated
  - Branch name (auto-detects repo from CWD)
  - Notion URL (resume a previous validation)
  - Empty (uses current branch, looks for open PR)

Multiple PRs are treated as a **single logical change** — one checklist entry.

## Notion Details

| Item | Value |
|---|---|
| Validation Log data source ID | `bdb67447-737b-48c4-acef-97449310640b` |
| Validation Log database ID | `9d1b46aa-f9a3-4806-bf45-28f1d14ccfe1` |
| Pending Changes database ID | `32da84ed-4024-80ab-abfd-000b0395b097` |
| Checklist process page | `32da84ed402480d096caf355647afc3a` |

### Database Properties

| Property | Type | Values |
|---|---|---|
| Change | title | Terse summary |
| Checklist Complete | checkbox | `__YES__` / `__NO__` |
| Status | select | Pending Review, Peer Approved, EM Approved, Shipped, Held, Rolled Back |
| Risk Level | select | Low, Medium, High, Critical |
| Type | select | PR, Feature Flag, Rake Task, Rollout Change, Config Change, Hotfix |
| Financial Liability | select | None, Possible, Confirmed |
| Merchants Affected | text | Free text |
| PR / Ticket | url | GitHub PR URL |
| Engineer | person | JSON array of user IDs |
| Date | date | ISO-8601 date |
| Peer Reviewer | person | Leave empty |
| EM Sign-off | person | Leave empty |
| Notes | text | Free text |

## Before You Start

### Smoke-test Notion Write Access

Use ToolSearch to find `mcp__claude_ai_Notion__notion-create-pages`. If unavailable, tell the user: "Can't write to Notion. I'll save as `~/Documents/validate-change-{date}.md` instead."

### Check for Resume

If `$ARGUMENTS` contains a Notion URL:
1. Fetch the page content
2. If it has checklist structure, this is a **resume** — show current state and ask which sections need updating

## Phase 0: Context Gathering

### Step 1: Check Existing Entries

Query the Validation Log database for entries matching the PR. If found and complete, ask whether to re-validate or skip. If found but incomplete, ask whether to update or create new.

### Step 2: Parse Arguments and Fetch PR Metadata

```bash
# If PR URL provided
gh pr view {PR_URL} --json title,body,author,headRefName,baseRefName,files,additions,deletions,number,url
gh pr diff {PR_URL}

# If branch name or empty
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
BRANCH=$(git branch --show-current)
gh pr list --head "$BRANCH" --json number,url,title --limit 1
```

Also get the full diff:
```bash
git diff origin/master...HEAD -- ':(exclude)Gemfile.lock' ':(exclude)db/' ':(exclude)*.lock'
```

### Step 3: Detect Change Type

| Pattern | Type |
|---|---|
| Standard code change | PR |
| Only flag config changes | Feature Flag |
| Contains rake tasks / data scripts | Rake Task |
| Rollout percentage changes | Rollout Change |
| Config/env/terraform only | Config Change |
| Emergency fix | Hotfix |

### Step 4: Resolve Engineer

1. Extract PR author from metadata
2. Search Notion users matching the author name/login
3. If exactly 1 match, use it silently
4. If ambiguous or no match, ask via AskUserQuestion

### Step 5: Ask for Engineer Concerns

Show a brief summary of the change, then ask:

```
(Validate · Setup) Before I research, is there anything about this change that worries you? Any specific risk?
```

Provide 2-3 context-aware concern options from the diff plus "No concerns". Store as `$ENGINEER_CONCERNS` — these become priority investigation targets but do NOT replace standard analysis.

## Phase 1: Automated Research

Launch **3 agents in parallel**:

### Agent 1: Change Analysis

Provide the full diff. Agent should:
- Identify all modified models, endpoints, workers, migrations
- Trace cross-repo dependencies (check `~/.thanx/` sibling repos if available)
- Map code changes to business impact chains
- Assess test coverage of changed code paths
- Investigate `$ENGINEER_CONCERNS` as priority targets

### Agent 2: Blast Radius + Production Data

Provide affected tables, models, endpoints. Agent should:
- Query production replicas for merchant/user counts affected
- Check LaunchDarkly for relevant feature flags
- Check Sentry for existing errors on affected endpoints
- Calculate worst-case financial exposure
- Investigate `$ENGINEER_CONCERNS` risk chains with production data

### Agent 3: Deployment Risk + Rollback

Provide diffs and PR metadata. Agent should:
- Assess migration reversibility
- Check rollback feasibility (feature flags, deploy rollback, data state)
- Check deployment ordering across repos
- Check recent CI health
- Identify feature flag dependencies

Wait for all 3 agents, consolidate into `$RESEARCH`.

## Phase 2: Draft the Checklist

### Writing Style

**Assertive, evidence-first, no hedging.** Follow the CTO example style:

| Do This | Not This |
|---|---|
| "Risk is zero. Draft promotions cannot be redeemed — `.redeemable` scope filters to active only." | "No financial liability risk." |
| "0 merchants affected at launch. No existing callers send this param." | "The change has low blast radius." |
| "$0. Even if a draft were somehow created, `.redeemable` prevents redemption." | "Worst-case financial exposure is minimal." |

**Rules:**
- Full sentences but terse — quick to scan
- Lead with verdict, then evidence
- **Identify → Investigate → Resolve** each risk. Never just flag — deliver a verdict (SAFE / MITIGATED / AT RISK)
- Include specific numbers from production queries
- Reference specific code, scopes, models, dashboards

### Section Templates

#### 1. What are you shipping?
- ELIF one-liner
- Domain context: who was consulted, or why it's self-evident

#### 2. Potential negative business impact
For each sub-bullet (Direct Revenue, Direct Liability, Operational Friction, Indirect Impact):
- State the causal chain from code to business outcome
- "I investigated: [what was queried]. Verdict: [SAFE/MITIGATED/AT RISK] — [evidence]."

If `$ENGINEER_CONCERNS` exist, add a callout at the top:
> **Engineer concern: {concern}** — Investigated: {evidence}. Verdict: {SAFE/MITIGATED/AT RISK}.

#### 3. Blast radius
- Merchant count (from production query, not guessed)
- User/record count day after launch
- Merchant approval needed?
- Worst-case financial exposure with calculation

#### 4. Production scale
- Production-scale data methodology
- Rate limits, timeouts, resource constraints

#### 5. Testing
**Code coverage:** scenarios, edge cases, side effects checked
**Risk validation:** for each risk from Section 2, what test or verification proves it won't materialize
**Declared gaps:** what was NOT tested and why

#### 6. How will you know it's working/broken?
- Working: specific metrics, dashboards, signals
- Broken: what signal, will you see it before the merchant?
- Monitoring plan: first 24-48 hours

#### 7. Root cause (bug fix only)
N/A for features. For bug fixes: root cause, related bugs, symptom vs root cause.

#### 8. Rollback plan
- Deploy rollback or feature flag?
- Data migration reversibility?
- Flag-off behaviour?
- Clean return to previous state?
- Time to rollback?

### Determine Risk Level

- **Low** — no merchant impact, no financial exposure, clean rollback, well-tested
- **Medium** — limited merchant impact, low financial exposure, rollback available
- **High** — significant merchant impact, material financial exposure, rollback has caveats
- **Critical** — all merchants affected, high financial exposure, complex rollback

### Determine Financial Liability

- **None** — doesn't touch revenue, payments, rewards, discounts, or financial data
- **Possible** — touches financial flows but risk is mitigated
- **Confirmed** — directly modifies financial calculations or creates new liability

## Phase 3: Review and Save

### Present the Checklist

Display all 8 sections. Ask:

```
(Validate: {PR title} · Review) Here's the complete validation checklist. Please review — you're signing off on these answers.

Ready to save to Notion, or corrections needed?
```

### Save to Notion

**Only after explicit approval.**

Fetch the enhanced markdown spec first:
```
ReadMcpResourceTool(server="claude.ai Notion", uri="notion://docs/enhanced-markdown-spec")
```

Use `mcp__claude_ai_Notion__notion-create-pages` with:
- **parent:** `{"type": "data_source_id", "data_source_id": "bdb67447-737b-48c4-acef-97449310640b"}`
- Set all properties from the database schema
- Content: the 8 sections in Notion-flavoured Markdown

If updating an existing entry, use `mcp__claude_ai_Notion__notion-update-page`. If status is already Peer Approved or EM Approved, warn that re-validating resets to Pending Review.

### Fallback

If Notion write fails, save to `~/Documents/validate-change-{repo}-{date}.md`.

## Phase 4: Link PRs

After creating the Notion page:

```bash
BODY_FILE=$(mktemp)
gh pr view {PR_URL} --json body -q '.body' > "$BODY_FILE"
printf "\n\n---\n**Production Change Validation**: [{title}]({notion_url})\n" >> "$BODY_FILE"
gh pr edit {PR_NUMBER} -R {REPO} --body-file "$BODY_FILE"
rm -f "$BODY_FILE"
```

Tell the engineer:
```
Validation log saved and linked:
- Notion: {URL}
- PR(s) updated: {list}

Next steps:
1. Peer reviewer validates the checklist
2. EM gives final sign-off
3. No EM approval = does not proceed to production
```

## Error Handling

| Error | Action |
|---|---|
| Keystone unavailable | Proceed without production data. Flag sections as "needs manual verification" |
| No PR found | Ask: "No open PR found. Describe the change manually?" |
| Notion write fails | Save as local markdown file |
| PR edit fails | Show Notion link, tell engineer to add manually |
| Agent timeout | Use partial results, note incomplete analysis |
