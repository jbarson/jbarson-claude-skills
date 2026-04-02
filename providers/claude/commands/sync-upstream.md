---
name: sync-upstream
description: Check the thanx-agent-starter upstream for improvements to core skills and help incorporate them into your personal fork
---

# Sync Upstream

Check the thanx-agent-starter upstream repo for improvements to core skills and help you decide what to adopt.

## Context

- Current branch: !`git branch --show-current 2>/dev/null | head -1`
- Upstream remote: !`git remote get-url upstream 2>/dev/null | head -1`
- Last upstream fetch: !`stat -f "%Sm" .git/FETCH_HEAD 2>/dev/null | head -1`
- Local skill files: !`find agents/skills -maxdepth 2 -name SKILL.md 2>/dev/null | head -30`

## Instructions

### Step 1: Verify Upstream Remote

Check if an `upstream` remote exists. If not, set it up:

```
git remote add upstream git@github.com:thanx/thanx-agent-starter.git
```

Then fetch:
```
git fetch upstream
```

### Step 2: Identify What Changed

Compare the local branch against upstream/master for changes to core files:

1. Run `git diff HEAD..upstream/master --name-only` to see all changed files
2. For each changed core skill (agents/skills/*/SKILL.md), run `git diff HEAD..upstream/master -- <path>` to see the actual diff
3. Also check for changes to: setup.sh, CLAUDE.md, global/CLAUDE.md, context/voice-profile.md, context/knowledge/index.md, README.md
4. Check for new files that do not exist locally (new skills, new context templates)

### Step 3: Summarize Changes

For each changed file, present a concise summary:

```
## Upstream Changes Available

### Core Skills

#### /improve (agents/skills/improve/SKILL.md)
- **[change type]**: [1-2 sentence description of what changed and why it matters]
- **[change type]**: [description]
- **Recommendation:** Adopt / Skip / Review manually

#### /handoff (agents/skills/handoff/SKILL.md)
- No changes

### New Files
- **[path]** -- [what it is and whether it is worth adopting]

### Other Changes
- **[file]** -- [description]
```

For each change, provide a recommendation:
- **Adopt** -- clearly beneficial, no conflict with local customizations
- **Skip** -- not relevant to this user or conflicts with local workflow
- **Review manually** -- significant change that the user should read before deciding

### Step 4: Apply Selected Changes

After the user selects which changes to adopt:

1. For straightforward adoptions, cherry-pick or apply the diff directly
2. For changes that conflict with local customizations, show both versions and help merge
3. For new files, copy them from upstream

**Important:** Never overwrite personal content in global/CLAUDE.md, context/voice-profile.md, or context/knowledge/ files. Only adopt structural changes (new sections, updated templates) from those files.

### Step 5: Report

Summarize what was adopted, what was skipped, and whether the local fork is now up to date with upstream.

## When There Are No Changes

If `git diff HEAD..upstream/master` shows nothing, report that the fork is current and stop.
