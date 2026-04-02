---
name: disk-cleanup
description: Scan local disk for large storage consumers and identify cleanup opportunities. Read-only by default, never deletes without explicit approval.
---

# Disk Cleanup

Scan this Mac for hidden storage hogs: caches, build artifacts, old toolchain versions, logs, Claude/Conductor data, and more.

## When to Use

Run `/disk-cleanup` when:
- Running low on disk space
- Claude or Conductor instances are consuming too much storage
- After a period of heavy development with multiple projects
- Before a large build or deployment that needs space

## Context

- Current disk usage: !`df -H / 2>/dev/null | tail -1 | head -1`

## Instructions

**User input**: $ARGUMENTS

### Step 1: Show Disk Overview

Run `df -H /` to get current disk state. Also run `diskutil apfs list 2>/dev/null | grep -E "Capacity|Free Space"` for true APFS container-level free space (this is what actually matters, not per-volume numbers).

Present a quick summary: total, used, free, percent used.

### Step 2: Scan Known Storage Consumers

For each directory below, run `du -sm <path> 2>/dev/null` to get size in MB. Skip any that do not exist. Only report items over 100 MB (or the threshold the user specifies).

**Development caches:**
- `~/Library/Caches/Homebrew`
- `~/.npm`
- `~/Library/Caches/Yarn`
- `~/Library/Caches/pip`
- `~/Library/Caches/CocoaPods`
- `~/.gradle/caches`
- `~/.m2`
- `~/go`
- `~/.cargo`
- `~/.gem`
- `~/.cache/devbox`

**Version managers (accumulate old versions):**
- `~/.rbenv/versions`
- `~/.nodenv/versions`
- `~/.nvm/versions`
- `~/.pyenv/versions`
- `~/.asdf`

**Xcode (often the biggest offender):**
- `~/Library/Developer/Xcode/DerivedData`
- `~/Library/Developer/Xcode/Archives`
- `~/Library/Developer/Xcode/iOS DeviceSupport`
- `~/Library/Developer/CoreSimulator/Devices`

**Docker and containers:**
- `~/Library/Containers/com.docker.docker`
- `~/Library/Group Containers/HUAQ24HBR6.dev.orbstack`

**Claude and Conductor:**
- `~/Library/Application Support/Claude`
- `~/.claude`
- `~/conductor`

**Nix:**
- `/nix`

**App caches:**
- `~/Library/Application Support/Spotify/PersistentCache`
- `~/Library/Application Support/Slack`
- `~/Library/Application Support/Google/Chrome`
- `~/Library/Application Support/Granola`

**General:**
- `~/.Trash`
- `~/Library/Logs`
- `~/Downloads`
- `~/Movies`
- `~/Pictures/Photos Library.photoslibrary`
- `/Library/Updates`

Also scan top-level home directories (`du -sm ~/* 2>/dev/null`) for anything over 500 MB not already covered above.

### Step 3: Present Results

Show a sorted table (largest first) with columns: Category, Size, Path.

For each item, add a one-line note about what it is and whether it is safe to clean.

### Step 4: Recommend Cleanup Actions

Group recommendations by safety level:

**Safe to clean (caches that regenerate):**
| Category | Command |
|---|---|
| Homebrew cache | `brew cleanup --prune=all` |
| npm cache | `npm cache clean --force` |
| pip cache | `pip cache purge` |
| yarn cache | `yarn cache clean` |
| CocoaPods cache | `pod cache clean --all` |
| Go modules | `go clean -modcache` |
| Xcode DerivedData | `rm -rf ~/Library/Developer/Xcode/DerivedData/*` |
| Xcode Archives | `rm -rf ~/Library/Developer/Xcode/Archives/*` |
| iOS DeviceSupport | `rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*` |
| CoreSimulator | `xcrun simctl delete unavailable` |
| Trash | `rm -rf ~/.Trash/*` |
| Nix garbage | `nix-collect-garbage -d` (if not on PATH: `/nix/var/nix/profiles/default/bin/nix-collect-garbage -d`) |

**Review before cleaning (may contain wanted data):**
| Category | Command |
|---|---|
| Docker (active runtime only) | `docker system prune -a` |
| Old version manager installs | `asdf uninstall <plugin> <version>` for non-active versions |
| Conductor workspaces | Review `~/conductor/workspaces/` for stale workspace directories |
| Claude worktrees | Review `~/.claude/worktrees/` for abandoned worktrees |
| Downloads | Review and delete old files in `~/Downloads` |

**Ask first (potentially significant data loss):**
| Category | Notes |
|---|---|
| Docker Desktop data (if using OrbStack) | `rm -rf ~/Library/Containers/com.docker.docker` - only if OrbStack is the active runtime |
| Photos Library | `rm -rf ~/Pictures/Photos\ Library.photoslibrary` - only if user does not use Photos.app |
| Movies | May contain personal media |

### Step 5: Execute Cleanup (only with approval)

**NEVER delete anything without explicit user approval.** Present the plan, wait for the user to say which categories to clean, then execute only those commands.

After cleanup, re-run `df -H /` and show the before/after comparison.

## Gotchas

- **Docker Desktop vs OrbStack**: `~/Library/Containers/com.docker.docker` is Docker Desktop data. If the user runs OrbStack instead, this entire directory is dead weight (often 50+ GB). OrbStack stores data in `~/Library/Group Containers/HUAQ24HBR6.dev.orbstack`. Check which runtime is active before suggesting docker prune. Prune only works on the active runtime.
- **Photos Library**: Can be 20-30 GB even if unused. Always ask if the user uses Photos.app before suggesting deletion.
- **asdf versions**: Run `asdf list` to show installed versions. Starred ones are active, the rest can be removed with `asdf uninstall <plugin> <version>`.
- **Nix store**: `nix-collect-garbage -d` may not be on PATH. Fall back to the full path. This removes stale Conductor workspace profiles and can free tens of GB.
- **APFS reporting**: `df -H` shows per-volume usage. Use `diskutil apfs list` for true container-level free space.
- **Claude worktrees**: `~/.claude/worktrees/` accumulates abandoned worktrees from past sessions. These can be large if they contain full repo copies.
- **Conductor workspaces**: `~/conductor/workspaces/` creates copies of repos for each workspace. Stale workspaces from completed tasks can be removed.
