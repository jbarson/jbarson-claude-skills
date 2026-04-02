#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "jbarson-claude-skills setup"
echo "==========================="
echo ""
echo "This will create symlinks from ~/.claude/ to this repo."
echo "Repo location: $REPO_DIR"
echo ""

# Check Claude Code directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating ~/.claude/ directory..."
    mkdir -p "$CLAUDE_DIR"
fi

# --- CLAUDE.md symlink ---
CLAUDE_MD_TARGET="$REPO_DIR/global/CLAUDE.md"
CLAUDE_MD_LINK="$CLAUDE_DIR/CLAUDE.md"

if [ -L "$CLAUDE_MD_LINK" ]; then
    CURRENT_TARGET="$(readlink "$CLAUDE_MD_LINK")"
    if [ "$CURRENT_TARGET" = "$CLAUDE_MD_TARGET" ]; then
        echo "CLAUDE.md symlink already correct."
    else
        echo "CLAUDE.md symlink exists but points to: $CURRENT_TARGET"
        read -p "Replace with link to this repo? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$CLAUDE_MD_LINK"
            ln -s "$CLAUDE_MD_TARGET" "$CLAUDE_MD_LINK"
            echo "  Updated CLAUDE.md symlink."
        else
            echo "  Skipped CLAUDE.md symlink."
        fi
    fi
elif [ -f "$CLAUDE_MD_LINK" ]; then
    BACKUP="$CLAUDE_MD_LINK.backup.$(date +%Y%m%d%H%M%S)"
    echo "Existing CLAUDE.md found (not a symlink). Backing up to: $BACKUP"
    mv "$CLAUDE_MD_LINK" "$BACKUP"
    ln -s "$CLAUDE_MD_TARGET" "$CLAUDE_MD_LINK"
    echo "  Created CLAUDE.md symlink. Original backed up."
else
    ln -s "$CLAUDE_MD_TARGET" "$CLAUDE_MD_LINK"
    echo "Created CLAUDE.md symlink."
fi

# --- Skills symlink ---
SKILLS_TARGET="$REPO_DIR/agents/skills"
SKILLS_LINK="$CLAUDE_DIR/skills"

if [ -L "$SKILLS_LINK" ]; then
    CURRENT_TARGET="$(readlink "$SKILLS_LINK")"
    if [ "$CURRENT_TARGET" = "$SKILLS_TARGET" ]; then
        echo "Skills symlink already correct."
    else
        echo "Skills symlink exists but points to: $CURRENT_TARGET"
        read -p "Replace with link to this repo? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$SKILLS_LINK"
            ln -s "$SKILLS_TARGET" "$SKILLS_LINK"
            echo "  Updated skills symlink."
        else
            echo "  Skipped skills symlink."
        fi
    fi
elif [ -d "$SKILLS_LINK" ]; then
    BACKUP="$SKILLS_LINK.backup.$(date +%Y%m%d%H%M%S)"
    echo "Existing skills/ directory found (not a symlink). Backing up to: $BACKUP"
    mv "$SKILLS_LINK" "$BACKUP"
    ln -s "$SKILLS_TARGET" "$SKILLS_LINK"
    echo "  Created skills symlink. Original backed up."
else
    ln -s "$SKILLS_TARGET" "$SKILLS_LINK"
    echo "Created skills symlink."
fi

# --- settings.json symlink ---
SETTINGS_TARGET="$REPO_DIR/global/settings.json"
SETTINGS_LINK="$CLAUDE_DIR/settings.json"

if [ -L "$SETTINGS_LINK" ]; then
    CURRENT_TARGET="$(readlink "$SETTINGS_LINK")"
    if [ "$CURRENT_TARGET" = "$SETTINGS_TARGET" ]; then
        echo "settings.json symlink already correct."
    else
        echo "settings.json symlink exists but points to: $CURRENT_TARGET"
        read -p "Replace with link to this repo? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$SETTINGS_LINK"
            ln -s "$SETTINGS_TARGET" "$SETTINGS_LINK"
            echo "  Updated settings.json symlink."
        else
            echo "  Skipped settings.json symlink."
        fi
    fi
elif [ -f "$SETTINGS_LINK" ]; then
    BACKUP="$SETTINGS_LINK.backup.$(date +%Y%m%d%H%M%S)"
    echo "Existing settings.json found (not a symlink). Backing up to: $BACKUP"
    mv "$SETTINGS_LINK" "$BACKUP"
    ln -s "$SETTINGS_TARGET" "$SETTINGS_LINK"
    echo "  Created settings.json symlink. Original backed up."
else
    ln -s "$SETTINGS_TARGET" "$SETTINGS_LINK"
    echo "Created settings.json symlink."
fi

echo ""
echo "Setup complete. Your skills are now available in every Claude Code session:"
echo ""
echo "  /improve        - End-of-session learning loop"
echo "  /handoff        - Context transfer between sessions"
echo "  /knowledge      - Knowledge base management"
echo "  /write-skill    - Skill authoring guide"
echo "  /disk-cleanup   - Disk space analysis"
echo "  /browse-skills  - Discover skills from the ecosystem"
echo "  /register-repo  - Register your repo in the ecosystem"
echo "  /sync-upstream  - Check for upstream improvements"
echo ""
echo "Next steps:"
echo "  1. Edit global/CLAUDE.md with your personal context"
echo "  2. Generate a voice profile (see context/voice-profile.md)"
echo "  3. Start using /improve at the end of your sessions"
echo ""
