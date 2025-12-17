#!/bin/bash

# Script to unlink awesome-claude-agents from ~/.claude
# This removes the global agent and command links created by link.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CLAUDE_DIR="$HOME/.claude"
CLAUDE_AGENTS_DIR="$CLAUDE_DIR/agents"
CLAUDE_COMMANDS_DIR="$CLAUDE_DIR/commands"

echo "=================================================="
echo "Awesome Claude Agents - Unlink Script"
echo "=================================================="
echo ""

# Agent directories that might be linked
AGENT_DIRS=("core" "orchestrators" "specialized" "universal")

# ========================================
# UNLINK AGENTS
# ========================================
echo "--- Unlinking Agents ---"
echo ""

agents_removed=0
if [ -d "$CLAUDE_AGENTS_DIR" ]; then
    for dir in "${AGENT_DIRS[@]}"; do
        TARGET="$CLAUDE_AGENTS_DIR/$dir"

        if [ -L "$TARGET" ]; then
            link_target=$(readlink "$TARGET")
            # Only remove if it's linking to awesome-claude-agents
            if [[ "$link_target" == *"awesome-claude-agents"* ]]; then
                rm "$TARGET"
                echo -e "${GREEN}✓${NC} Removed: agents/$dir"
                ((agents_removed++))
            else
                echo -e "${YELLOW}⊘${NC} Skipped: agents/$dir (not linked to awesome-claude-agents)"
            fi
        else
            echo -e "${YELLOW}⊘${NC} Skipped: agents/$dir (not a symlink)"
        fi
    done
else
    echo -e "${YELLOW}~/.claude/agents directory does not exist.${NC}"
fi
echo ""

# ========================================
# UNLINK COMMANDS
# ========================================
echo "--- Unlinking Commands ---"
echo ""

commands_removed=0
if [ -d "$CLAUDE_COMMANDS_DIR" ]; then
    for item in "$CLAUDE_COMMANDS_DIR"/*; do
        if [ -L "$item" ]; then
            link_target=$(readlink "$item")
            # Only remove if it's linking to awesome-claude-agents
            if [[ "$link_target" == *"awesome-claude-agents"* ]]; then
                rm "$item"
                echo -e "${GREEN}✓${NC} Removed: commands/$(basename "$item")"
                ((commands_removed++))
            fi
        fi
    done
    if [ $commands_removed -eq 0 ]; then
        echo -e "${YELLOW}No awesome-claude-agents command symlinks found.${NC}"
    fi
else
    echo -e "${YELLOW}~/.claude/commands directory does not exist.${NC}"
fi
echo ""

# ========================================
# SUMMARY
# ========================================
total_removed=$((agents_removed + commands_removed))

if [ $total_removed -eq 0 ]; then
    echo -e "${YELLOW}No awesome-claude-agents symlinks found.${NC}"
else
    echo "=================================================="
    echo -e "${GREEN}Success!${NC} Removed $agents_removed agent directory link(s) and $commands_removed command link(s)."
    echo "=================================================="
fi
echo ""
echo "To re-link, run: ./link.sh"
echo ""
