#!/bin/bash

# Script to link awesome-claude-agents to ~/.claude/agents for global usage
# This makes all agents in this repository available globally in Claude Code

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the absolute path to the repository's agents directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_AGENTS_DIR="$REPO_DIR/agents"
CLAUDE_AGENTS_DIR="$HOME/.claude/agents"

echo "=================================================="
echo "Awesome Claude Agents - Global Linking Script"
echo "=================================================="
echo ""

# Verify the repository agents directory exists
if [ ! -d "$REPO_AGENTS_DIR" ]; then
    echo -e "${RED}Error: Repository agents directory not found at: $REPO_AGENTS_DIR${NC}"
    exit 1
fi

echo -e "Repository agents: ${GREEN}$REPO_AGENTS_DIR${NC}"
echo -e "Claude agents dir: ${GREEN}$CLAUDE_AGENTS_DIR${NC}"
echo ""

# Create ~/.claude/agents if it doesn't exist
if [ ! -d "$CLAUDE_AGENTS_DIR" ]; then
    echo -e "${YELLOW}Creating $CLAUDE_AGENTS_DIR...${NC}"
    mkdir -p "$CLAUDE_AGENTS_DIR"
fi

# Agent directories to link
AGENT_DIRS=("core" "orchestrators" "specialized" "universal")

# Remove any existing incorrect links first
echo "Checking for existing links..."
for item in "$CLAUDE_AGENTS_DIR"/*; do
    if [ -L "$item" ]; then
        target=$(readlink "$item")
        # Check if it's linking to this repo (correctly or incorrectly)
        if [[ "$target" == *"awesome-claude-agents"* ]]; then
            echo -e "${YELLOW}Removing existing link: $(basename "$item") -> $target${NC}"
            rm "$item"
        fi
    fi
done
echo ""

# Create symlinks for each agent directory
echo "Creating symlinks..."
for dir in "${AGENT_DIRS[@]}"; do
    SOURCE="$REPO_AGENTS_DIR/$dir"
    TARGET="$CLAUDE_AGENTS_DIR/$dir"

    if [ ! -d "$SOURCE" ]; then
        echo -e "${YELLOW}Warning: $dir not found in repository, skipping...${NC}"
        continue
    fi

    # Remove existing symlink or directory if it exists
    if [ -L "$TARGET" ]; then
        echo -e "${YELLOW}Removing existing symlink: $TARGET${NC}"
        rm "$TARGET"
    elif [ -e "$TARGET" ]; then
        echo -e "${RED}Error: $TARGET exists and is not a symlink.${NC}"
        echo -e "${RED}Please manually remove or backup this directory first.${NC}"
        exit 1
    fi

    # Create the symlink
    ln -s "$SOURCE" "$TARGET"
    echo -e "${GREEN}✓${NC} Linked: $dir"
done

echo ""
echo "=================================================="
echo -e "${GREEN}Success!${NC} All agent directories linked."
echo "=================================================="
echo ""
echo "Linked directories:"
for dir in "${AGENT_DIRS[@]}"; do
    if [ -L "$CLAUDE_AGENTS_DIR/$dir" ]; then
        echo -e "  ${GREEN}✓${NC} ~/.claude/agents/$dir -> $REPO_AGENTS_DIR/$dir"
        # Count agents in directory
        count=$(find "$REPO_AGENTS_DIR/$dir" -name "*.md" -type f | wc -l | tr -d ' ')
        echo -e "    ($count agents available)"
    fi
done
echo ""
echo "These agents are now available globally in Claude Code!"
echo ""
echo "To unlink, run: ./unlink_agents.sh"
echo ""
