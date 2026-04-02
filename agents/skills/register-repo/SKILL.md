---
name: register-repo
description: Register your skill repository in the central ecosystem repo-list via an automated PR to thanx-agent-starter.
---

# Register Repo

Register your skill repository in the central `community/repo-list.yaml` by creating an automated PR to `thanx/thanx-agent-starter`.

## Arguments

- `$ARGUMENTS` — optional: the GitHub remote URL of the repo to register (defaults to the current repo's origin)

## Context

- Current repo remote: !`git remote get-url origin 2>/dev/null | head -1`
- Current repo root: !`git rev-parse --show-toplevel 2>/dev/null | head -1`
- Existing repo-list: !`gh api "repos/thanx/thanx-agent-starter/contents/community/repo-list.yaml" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | head -40`

## Instructions

### Step 1: Determine Repo Details

If no argument was passed, use the current repo's `origin` remote.

Gather:
- **name**: derive from the repo name (e.g., `kosmin-claude-skills`)
- **type**: detect by checking for:
  - `.claude-plugin/marketplace.json` → `marketplace`
  - `.agents/skills/` → `agents-dir`
  - `.claude/skills/` → `claude-dir`
  - `skills/` → `personal`
- **remote**: the git SSH URL
- **owner**: the GitHub username or org
- **skill_paths**: where skills live (detected above)
- **description**: from the repo's GitHub description, or ask the user

### Step 2: Check for Duplicates

Fetch the current `community/repo-list.yaml` from GitHub:

```bash
gh api "repos/thanx/thanx-agent-starter/contents/community/repo-list.yaml" --jq '.content' | base64 -d
```

Check if the repo's remote URL already appears. If it does:
- Show the existing entry
- Ask if the user wants to update it (description, skill_paths, etc.)
- If no changes needed, stop here

### Step 3: Generate the Entry

Format the new YAML entry:

```yaml
  - name: "{name}"
    type: {type}
    remote: "{remote}"
    owner: "{owner}"
    description: "{description}"
    skill_paths:
      - "{path1}"
    added_at: "{today}"
    added_by: "{owner}"
```

Show the entry to the user and confirm.

### Step 4: Create the PR

Clone thanx-agent-starter (or use an existing local copy), create a branch, append the entry, and open a PR:

```bash
# Clone to temp directory
TMPDIR=$(mktemp -d)
git clone git@github.com:thanx/thanx-agent-starter.git "$TMPDIR/thanx-agent-starter"
cd "$TMPDIR/thanx-agent-starter"

# Create branch
git checkout -b community/register-{name}

# Append entry to repo-list.yaml
cat >> community/repo-list.yaml << 'EOF'

  - name: "{name}"
    type: {type}
    ...
EOF

# Commit and push
git add community/repo-list.yaml
git commit -m "Register {name} in skill ecosystem repo-list"
git push -u origin community/register-{name}

# Create PR
gh pr create \
  --repo thanx/thanx-agent-starter \
  --title "Register {name} in skill ecosystem" \
  --body "Adds {name} ({remote}) to the central repo-list for skill discovery.

## Repo Details
- **Type**: {type}
- **Owner**: {owner}
- **Skill paths**: {paths}
- **Description**: {description}

This repo contains {N} skills: {skill names}.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

### Step 5: Report

```markdown
## Registered!

PR created: {pr_url}

Your repo will be discoverable via `/browse-skills --central` once the PR is merged.
Others can then find and adopt your skills.
```

## Error Handling

- **No write access to thanx-agent-starter**: the PR workflow handles this — GitHub forks automatically when needed for PRs
- **Repo already registered**: show existing entry, offer to update
- **Can't detect repo type**: ask the user to specify
