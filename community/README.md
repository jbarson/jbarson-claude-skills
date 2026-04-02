# Skill Ecosystem — Decentralized Discovery

This directory holds the **central repo-list** — a discovery aid that helps agents and people find
skill repositories across the Thanx org and beyond.

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  Layer 3: Hub (thanx-cortex)                            │
│  Org-wide skills that benefit everyone.                 │
│  Skills get here after proving themselves in personal   │
│  repos. Centralization is organic, not forced.          │
├─────────────────────────────────────────────────────────┤
│  This file: community/repo-list.yaml                    │
│  Discovery aid. Lists known repos. NOT authoritative.   │
│  Each person's local snoop-sources.yaml is their truth. │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Personal repos                                │
│  kosmin-claude-skills, anutron/claude-skills, drn/dots  │
│  Each person curates their own skills.                  │
└─────────────────────────────────────────────────────────┘
```

### The Flow

1. **Fork or create** a personal skill repo (use this starter as a template)
2. **Register** your repo by opening a PR to `community/repo-list.yaml`
3. **Discover** others' skills via `/snoop --fetch-central` (reads this list)
4. **Adopt** skills you like into your personal repo
5. **Centralize** when 3+ people share similar skills → promote to thanx-cortex

## Adding Your Repo

Open a PR that adds your repo to `community/repo-list.yaml`:

```yaml
  - name: "your-name-claude-skills"
    type: personal              # or marketplace, claude-dir, agents-dir
    remote: "git@github.com:your-org/your-repo.git"
    owner: "your-github-username"
    description: "Brief description of what skills your repo contains"
    skill_paths:
      - "skills/"               # Where to look for SKILL.md files
    added_at: "2026-04-01"      # Today's date
    added_by: "your-username"
```

### Repo Types

| Type | Structure | Example |
|------|-----------|---------|
| `hub` | Claude Code marketplace with centralized, org-wide skills | thanx-cortex |
| `marketplace` | Claude Code marketplace with `.claude-plugin/` manifest | kosmin-claude-skills |
| `personal` | Flat `skills/` directory with SKILL.md files | anutron/claude-skills |
| `claude-dir` | Skills inside a `.claude/skills/` directory of a larger repo | drn/dots |
| `agents-dir` | Skills inside an `.agents/skills/` directory following the Agent Skills standard | (any repo) |

## Using This List

### For agents (automated)

Agents with `/snoop --fetch-central` can:
1. Fetch this file from GitHub
2. Compare against their local `snoop-sources.yaml`
3. Offer to register any new repos the user hasn't seen yet

### For humans (manual)

Browse the repos listed in `repo-list.yaml`. Clone any that interest you and explore their skills.

## Centralization Candidates

When `/snoop all` detects that 3+ repos have similar skills (same name or overlapping
`covers` keywords), it flags them as **centralization candidates**. This means the skill
has proven useful across multiple individuals and is a good candidate for promotion to
the hub (thanx-cortex).

The centralization process:
1. Agent flags the skill as a candidate
2. One person creates a PR to thanx-cortex with the best version
3. Once merged, personal repos can either delete their copy or keep a customized version
4. The hub version becomes the reference implementation

## Design Principles

- **Decentralized by default**: each person's local config is authoritative
- **No forced structure**: works with marketplaces, flat skill dirs, `.claude/` dirs
- **Organic centralization**: skills prove themselves before being promoted
- **Low overhead**: adding a repo is one YAML entry in a PR
- **Discovery, not dependency**: this list helps you find repos, it doesn't control them
