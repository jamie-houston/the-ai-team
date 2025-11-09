# Installation Guide

## Quick Installation (Recommended)

The easiest way to install Awesome Claude Agents is using the provided linking scripts.

### macOS/Linux

```bash
# Clone the repository
git clone https://github.com/vijaythecoder/awesome-claude-agents.git
cd awesome-claude-agents

# Run the linking script
./link_agents.sh
```

This will:
- Create `~/.claude/agents/` directory if it doesn't exist
- Remove any incorrect existing symlinks
- Create symlinks for all agent categories:
  - `~/.claude/agents/core` → 16 core agents
  - `~/.claude/agents/orchestrators` → 3 orchestrator agents
  - `~/.claude/agents/specialized` → 22 framework-specific agents
  - `~/.claude/agents/universal` → 4 universal agents

### Benefits of Symlinking

✅ **Auto-updates**: When you `git pull` updates, agents are automatically updated
✅ **No duplication**: Saves disk space
✅ **Easy management**: All agents in one central location
✅ **Clean uninstall**: Just run `./unlink_agents.sh`

## Verify Installation

```bash
claude /agents
```

You should see all 45 agents listed across the four categories.

## Uninstalling

To remove the symlinks:

```bash
cd awesome-claude-agents
./unlink_agents.sh
```

This will safely remove only the symlinks to this repository, preserving any other agents you have installed.

## Manual Installation (Alternative)

If you prefer not to use symlinks:

```bash
# Create agents directory
mkdir -p ~/.claude/agents

# Copy all agents
cp -r agents/* ~/.claude/agents/
```

**Note**: With this method, you'll need to manually copy files again to get updates.

## Windows Installation

Windows support for the linking scripts is coming soon. For now, use the manual copy method:

```powershell
# Create agents directory
New-Item -Path "$env:USERPROFILE\.claude\agents" -ItemType Directory -Force

# Copy agents
Copy-Item -Recurse -Force "agents\*" "$env:USERPROFILE\.claude\agents\"
```

## Troubleshooting

### "Permission denied" when running scripts

Make the scripts executable:
```bash
chmod +x link_agents.sh unlink_agents.sh
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

The linking script preserves existing agents and only manages the four categories from this repository. Your existing agents won't be affected.

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

See [README.md](README.md) for full documentation.
