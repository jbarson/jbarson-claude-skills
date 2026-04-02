# jbarson-claude-skills

Personal AI workflow repo. Contains global Claude Code configuration, personal skills, knowledge base, and voice profile.

## Repository Structure

```
jbarson-claude-skills/
├── CLAUDE.md                          # This file (repo-level instructions)
├── .claude-plugin/
│   └── marketplace.json               # Plugin marketplace manifest
├── global/
│   ├── CLAUDE.md                      # Global instructions -> symlinked to ~/.claude/CLAUDE.md
│   ├── settings.json                  # Permission defaults -> symlinked to ~/.claude/settings.json
│   └── PERMISSIONS.md                 # Explains the allow/deny model
├── agents/
│   └── skills/                        # Personal skills -> symlinked to ~/.claude/skills/
│       ├── browse-skills/SKILL.md
│       ├── disk-cleanup/SKILL.md
│       ├── handoff/SKILL.md
│       ├── improve/SKILL.md
│       ├── knowledge/SKILL.md
│       ├── register-repo/SKILL.md
│       ├── sync-upstream/SKILL.md
│       └── write-skill/SKILL.md
├── context/
│   ├── voice-profile.md              # Generated voice/writing profile
│   └── knowledge/                    # Personal knowledge base
│       └── index.md
├── community/
│   ├── repo-list.yaml                # Central registry of known skill repos
│   └── README.md                     # Ecosystem docs
└── .gitignore
```

## Symlink Setup

Run `./setup.sh` or manually create:

- `~/.claude/CLAUDE.md` symlinked to `global/CLAUDE.md`
- `~/.claude/skills/` symlinked to `agents/skills/`
- `~/.claude/settings.json` symlinked to `global/settings.json`

## Sandboxing Defaults

This repo ships with conservative permission defaults in `global/settings.json` (symlinked to `~/.claude/settings.json` by `setup.sh`). The model: allow reads, block destructive operations, prompt for everything in between. See `global/PERMISSIONS.md` for the full explanation and customisation guide.

## Working With Skills

Skills follow the Claude Code SKILL.md format. See `/write-skill` for the authoring guide.

### Least-Privilege Tool Access

Skills should declare only the tools they need in `allowed-tools`. A read-only research skill should not have write access. A reporting skill should not have message-send access. Narrow tool access limits the blast radius when a skill misbehaves.

### Dynamic Context Rules (Critical)

- No `$()` in dynamic context (blocked by Claude Code security)
- No `||` or `&&` in dynamic context (permission system blocks these)
- Always use `2>/dev/null | head -N` to suppress errors and neutralise exit codes
- Use `origin/HEAD` instead of hardcoding branch names
- Keep output bounded with `| head -N`

### Testing Skills

After editing a skill, test it by running the `/skill-name` command in any project. Skills are loaded from the symlinked directory so changes are immediately available.

## Conventions

- Keep skills concise and imperative
- Use numbered steps for predictable execution
- Include abort conditions and loop limits
- No backticks in prose (shell evaluation breaks them)
- No contractions (single-quote interpretation issues)
- Use Canadian spelling
