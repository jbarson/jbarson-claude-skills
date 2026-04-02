---
name: browse-skills
description: Discover and adopt skills from the central skill ecosystem. Reads the repo-list, scans repos via GitHub API, and lets you adopt skills into your local repo.
---

# Browse Skills

Discover skills from the decentralized skill ecosystem. Reads the central `community/repo-list.yaml`, scans each listed repo via the GitHub API (no cloning needed), and presents available skills for adoption.

## Arguments

- `$ARGUMENTS` — optional: a repo name to scan, `--all` to scan everything, or `--central` to fetch/refresh the repo-list

## Context

- Repo list: !`cat community/repo-list.yaml 2>/dev/null | head -80`
- Local skills: !`find agents/skills -maxdepth 2 -name SKILL.md 2>/dev/null | head -20`
- Project root: !`git rev-parse --show-toplevel 2>/dev/null | head -1`

## Instructions

### Step 1: Load the Repo List

Read `community/repo-list.yaml` from the current repo (or fetch it from `thanx/thanx-agent-starter` if running outside that repo).

If `--central` was passed, fetch the latest version from GitHub:

```bash
gh api "repos/thanx/thanx-agent-starter/contents/community/repo-list.yaml" --jq '.content' | base64 -d
```

### Step 2: Select Repos to Scan

- No args: show the list of repos and ask which to scan
- `<repo-name>`: scan only that repo
- `--all`: scan all repos in the list

### Step 3: Scan Each Repo via GitHub API

For each selected repo, discover skills without cloning:

```bash
# Get the file tree
gh api "repos/{owner}/{repo}/git/trees/{default_branch}?recursive=1" --jq '.tree[] | select(.type == "blob") | .path'

# For each SKILL.md found in the skill_paths:
gh api "repos/{owner}/{repo}/contents/{path}" --jq '.content' | base64 -d | head -30
```

Extract from each SKILL.md:
- **name** (from frontmatter)
- **description** (from frontmatter)
- **covers** (from frontmatter, if present)

### Step 4: Present Results

Show a table of discovered skills:

```markdown
## Skills in {repo-name}

| Skill | Description | Already Have? |
|-------|-------------|:---:|
| bugbash | Interactive QA with parallel worktree fixing | No |
| improve | End-of-session skill improvement loop | Yes (local version) |
| handoff | Context transfer between sessions | Yes (identical) |
```

For `--all`, also check for **centralization candidates**:

```markdown
## Centralization Candidates

These skills appear in 3+ repos and may be worth promoting to thanx-cortex:

| Skill | Found In | Notes |
|-------|----------|-------|
| improve | anutron, drn/dots, kosmin, agent-starter | 4 versions — review for best-of-breed |
| handoff | anutron, drn/dots, agent-starter | 3 identical copies |
```

### Step 5: Adopt Skills

Ask: **"Which skills would you like to adopt?"**

For each selected skill:
1. Fetch the full SKILL.md content from the source repo
2. Copy it to `agents/skills/<skill-name>/SKILL.md` in the local repo
3. Report what was added

If the skill already exists locally, show a diff and ask whether to replace, skip, or merge.

## Error Handling

- **Repo not accessible**: skip and note "403/404 — repo may be private"
- **No SKILL.md files found**: note "no skills found at configured paths"
- **Rate limiting**: pause and retry after the reset window
