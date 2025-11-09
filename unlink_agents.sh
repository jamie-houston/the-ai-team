#!/bin/bash

# Script to unlink awesome-claude-agents from ~/.claude/agents
# This removes the global agent links created by link_agents.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CLAUDE_AGENTS_DIR="$HOME/.claude/agents"

echo "=================================================="
echo "Awesome Claude Agents - Unlink Script"
echo "=================================================="
echo ""

if [ ! -d "$CLAUDE_AGENTS_DIR" ]; then
    echo -e "${YELLOW}~/.claude/agents directory does not exist.${NC}"
    echo "Nothing to unlink."
    exit 0
fi

# Agent directories that might be linked
AGENT_DIRS=("core" "orchestrators" "specialized" "universal")

echo "Removing symlinks from ~/.claude/agents..."
echo ""

removed_count=0
for dir in "${AGENT_DIRS[@]}"; do
    TARGET="$CLAUDE_AGENTS_DIR/$dir"

    if [ -L "$TARGET" ]; then
        link_target=$(readlink "$TARGET")
        # Only remove if it's linking to awesome-claude-agents
        if [[ "$link_target" == *"awesome-claude-agents"* ]]; then
            rm "$TARGET"
            echo -e "${GREEN}✓${NC} Removed: $dir"
            ((removed_count++))
        else
            echo -e "${YELLOW}⊘${NC} Skipped: $dir (not linked to awesome-claude-agents)"
        fi
    else
        echo -e "${YELLOW}⊘${NC} Skipped: $dir (not a symlink)"
    fi
done

echo ""
if [ $removed_count -eq 0 ]; then
    echo -e "${YELLOW}No awesome-claude-agents symlinks found.${NC}"
else
    echo "=================================================="
    echo -e "${GREEN}Success!${NC} Removed $removed_count symlink(s)."
    echo "=================================================="
fi
echo ""
echo "To re-link, run: ./link_agents.sh"
echo ""
