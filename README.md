# jbarson-claude-skills

Personal AI skill marketplace for Claude Code. Fork of [thanx-agent-starter](https://github.com/thanx/thanx-agent-starter) with marketplace plugin structure.

## Quick Start

```bash
# Clone and set up
git clone git@github.com:jbarson/jbarson-claude-skills.git
cd jbarson-claude-skills
./setup.sh
```

## Skills

| Skill | Purpose |
|-------|---------|
| `/browse-skills` | Discover and adopt skills from the central skill ecosystem |
| `/disk-cleanup` | Scan local disk for large storage consumers and identify cleanup opportunities |
| `/handoff` | Generate structured context prompts for transferring work between agent sessions |
| `/improve` | End-of-session learning loop — extract friction, improve skills, capture knowledge |
| `/knowledge` | Initialize or update a project knowledge base for cross-session knowledge capture |
| `/register-repo` | Register your skill repository in the central ecosystem repo-list |
| `/sync-upstream` | Check upstream for improvements and incorporate them into your fork |
| `/write-skill` | Create or improve Claude Code skills with best practices and validation |

## How It Works

The setup script creates three symlinks:

- `~/.claude/CLAUDE.md` -> `global/CLAUDE.md`
- `~/.claude/skills/` -> `agents/skills/`
- `~/.claude/settings.json` -> `global/settings.json`

Skills are version-controlled here and available in every Claude Code session via the symlinks.

## Marketplace

This repo includes a `.claude-plugin/marketplace.json` manifest, making it discoverable as a plugin marketplace in the skill ecosystem. Other engineers can browse and adopt skills from this repo using `/browse-skills`.

## Staying Current

Run `/sync-upstream` to check for improvements from the upstream starter scaffold.

## Based On

[thanx/thanx-agent-starter](https://github.com/thanx/thanx-agent-starter) — the self-improving AI workflow infrastructure originated by [Darren Cheng](https://github.com/drn).
