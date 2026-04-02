# Permissions Config (settings.json)

Default sandboxing permissions for Claude Code. Installed to `~/.claude/settings.json` by `setup.sh`.

## How It Works

Claude Code uses an allow/deny model for tool permissions:

- **allow**: Tools and commands that run without prompting. These are read-only operations safe to auto-approve.
- **deny**: Tools and commands that are always blocked. These are destructive operations that should never run without deliberate override.
- **Everything else**: Prompts for approval each time. This is the safe default for commands like `git push`, `git commit`, `npm install`, etc.

## What Ships by Default

### Allowed (auto-approve)

Read-only git commands: `status`, `diff`, `log`, `branch`, `show`, `rev-parse`, `remote -v`

File reading commands: `ls`, `cat`, `head`, `tail`, `rg`, `find`, `wc`

Built-in read tools: `Read`, `Glob`, `Grep`

### Denied (always blocked)

Destructive git operations: `push --force`, `reset --hard`, `clean -f`, `checkout -- .`, `branch -D`

Destructive file operations: `rm -rf`

### Prompt-required (everything else)

Commands like `git push`, `git commit`, `npm install`, `docker run`, and any write operations will prompt for approval. This gives you a checkpoint before anything changes shared state.

## Customising

Add entries to match your workflow:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm test*)",
      "Bash(bundle exec rspec*)"
    ]
  }
}
```

For MCP tools, use the tool name pattern:

```json
{
  "permissions": {
    "allow": [
      "mcp__slack__slack_read_channel*",
      "mcp__notion__notion-search*"
    ],
    "deny": [
      "mcp__slack__slack_send_message*"
    ]
  }
}
```

## Principle

The default is conservative: allow reads, block destructive operations, prompt for everything in between. Widen permissions as you build trust with specific workflows, not upfront.
