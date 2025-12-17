# Installation Guide

## Quick Installation (Recommended)

The easiest way to install Awesome Claude Agents is using the provided linking scripts.

### macOS/Linux

```bash
# Clone the repository
git clone https://github.com/vijaythecoder/awesome-claude-agents.git
cd awesome-claude-agents

# Run the linking script
./link.sh
```

This will:
- Create `~/.claude/agents/` and `~/.claude/commands/` directories if they don't exist
- Remove any incorrect existing symlinks
- Create symlinks for all agent categories:
  - `~/.claude/agents/core` → 17 core agents
  - `~/.claude/agents/orchestrators` → 3 orchestrator agents
  - `~/.claude/agents/specialized` → 32 framework-specific agents (Python, Laravel, Django, Rails, React, Vue, .NET, Android)
  - `~/.claude/agents/universal` → 7 universal agents
- Create symlinks for all slash commands:
  - `~/.claude/commands/` → 14 slash commands for quick workflows

### Benefits of Symlinking

✅ **Auto-updates**: When you `git pull` updates, agents and commands are automatically updated
✅ **No duplication**: Saves disk space
✅ **Easy management**: All agents in one central location
✅ **Clean uninstall**: Just run `./unlink.sh`

## Verify Installation

```bash
claude /agents
```

You should see all 59 agents listed across the four categories.

## Uninstalling

To remove the symlinks:

```bash
cd awesome-claude-agents
./unlink.sh
```

This will safely remove only the symlinks to this repository, preserving any other agents and commands you have installed.

## Manual Installation (Alternative)

If you prefer not to use symlinks:

```bash
# Create directories
mkdir -p ~/.claude/agents ~/.claude/commands

# Copy all agents and commands
cp -r agents/* ~/.claude/agents/
cp -r commands/* ~/.claude/commands/
```

**Note**: With this method, you'll need to manually copy files again to get updates.

## Windows Installation

Windows support for the linking scripts is coming soon. For now, use the manual copy method:

```powershell
# Create directories
New-Item -Path "$env:USERPROFILE\.claude\agents" -ItemType Directory -Force
New-Item -Path "$env:USERPROFILE\.claude\commands" -ItemType Directory -Force

# Copy agents and commands
Copy-Item -Recurse -Force "agents\*" "$env:USERPROFILE\.claude\agents\"
Copy-Item -Recurse -Force "commands\*" "$env:USERPROFILE\.claude\commands\"
```

## Troubleshooting

### "Permission denied" when running scripts

Make the scripts executable:
```bash
chmod +x link.sh unlink.sh
```

### Agents not showing in Claude Code

1. Verify the symlinks were created:
   ```bash
   ls -la ~/.claude/agents/
   ```

2. Restart Claude Code

3. Check that Claude Code is looking in the right directory:
   ```bash
   claude /agents
   ```

### Already have agents in ~/.claude/agents

The linking script preserves existing agents and commands, only managing the categories from this repository. Your existing agents and commands won't be affected.

## Next Steps

After installation:

1. **Navigate to your project**:
   ```bash
   cd your-project
   ```

2. **Configure your AI team**:
   ```bash
   claude "use @agent-team-configurator and optimize my project to best use the available subagents."
   ```

3. **Start building**:
   ```bash
   claude "use @agent-tech-lead-orchestrator and build a user authentication system"
   ```

4. **Use slash commands** (for .NET workflows):
   ```bash
   # In Claude Code, type:
   /analyze-prd Build a REST API for managing inventory
   /scaffold InventoryApi
   /efcore
   /webapi
   /test
   ```

See [README.md](README.md) for full documentation.
