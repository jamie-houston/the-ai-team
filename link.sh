#!/bin/bash

# Script to link awesome-claude-agents to ~/.claude for global usage
# This makes all agents and commands in this repository available globally in Claude Code

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the absolute path to the repository
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_AGENTS_DIR="$REPO_DIR/agents"
REPO_COMMANDS_DIR="$REPO_DIR/commands"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_AGENTS_DIR="$CLAUDE_DIR/agents"
CLAUDE_COMMANDS_DIR="$CLAUDE_DIR/commands"

echo "=================================================="
echo "Awesome Claude Agents - Global Linking Script"
echo "=================================================="
echo ""

# Verify the repository directories exist
if [ ! -d "$REPO_AGENTS_DIR" ]; then
    echo -e "${RED}Error: Repository agents directory not found at: $REPO_AGENTS_DIR${NC}"
    exit 1
fi

echo -e "Repository location: ${GREEN}$REPO_DIR${NC}"
echo -e "  - agents:   ${GREEN}$REPO_AGENTS_DIR${NC}"
echo -e "  - commands: ${GREEN}$REPO_COMMANDS_DIR${NC}"
echo ""
echo -e "Claude directory:   ${GREEN}$CLAUDE_DIR${NC}"
echo ""

# Create ~/.claude if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}Creating $CLAUDE_DIR...${NC}"
    mkdir -p "$CLAUDE_DIR"
fi

# Create ~/.claude/agents if it doesn't exist
if [ ! -d "$CLAUDE_AGENTS_DIR" ]; then
    echo -e "${YELLOW}Creating $CLAUDE_AGENTS_DIR...${NC}"
    mkdir -p "$CLAUDE_AGENTS_DIR"
fi

# Create ~/.claude/commands if it doesn't exist
if [ ! -d "$CLAUDE_COMMANDS_DIR" ]; then
    echo -e "${YELLOW}Creating $CLAUDE_COMMANDS_DIR...${NC}"
    mkdir -p "$CLAUDE_COMMANDS_DIR"
fi

# Agent directories to link
AGENT_DIRS=("core" "orchestrators" "specialized" "universal")

# ========================================
# AGENTS LINKING
# ========================================
echo "--- Linking Agents ---"
echo ""

# Remove any existing incorrect links first
echo "Checking for existing agent links..."
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
echo "Creating agent symlinks..."
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
    echo -e "${GREEN}✓${NC} Linked: agents/$dir"
done
echo ""

# ========================================
# COMMANDS LINKING
# ========================================
echo "--- Linking Commands ---"
echo ""

if [ -d "$REPO_COMMANDS_DIR" ]; then
    # Remove any existing command links from this repo
    echo "Checking for existing command links..."
    for item in "$CLAUDE_COMMANDS_DIR"/*; do
        if [ -L "$item" ]; then
            target=$(readlink "$item")
            if [[ "$target" == *"awesome-claude-agents"* ]]; then
                echo -e "${YELLOW}Removing existing link: $(basename "$item") -> $target${NC}"
                rm "$item"
            fi
        fi
    done
    echo ""

    # Link individual command files (not the whole directory to allow users to have their own commands)
    echo "Creating command symlinks..."
    command_count=0
    for cmd_file in "$REPO_COMMANDS_DIR"/*.md; do
        if [ -f "$cmd_file" ]; then
            filename=$(basename "$cmd_file")
            TARGET="$CLAUDE_COMMANDS_DIR/$filename"

            # Remove existing symlink if it exists
            if [ -L "$TARGET" ]; then
                rm "$TARGET"
            elif [ -e "$TARGET" ]; then
                echo -e "${YELLOW}Warning: $TARGET exists and is not a symlink, skipping...${NC}"
                continue
            fi

            ln -s "$cmd_file" "$TARGET"
            ((command_count++))
        fi
    done
    echo -e "${GREEN}✓${NC} Linked: $command_count command files"
else
    echo -e "${YELLOW}No commands directory found, skipping...${NC}"
fi
echo ""

# ========================================
# SUMMARY
# ========================================
echo "=================================================="
echo -e "${GREEN}Success!${NC} All directories and files linked."
echo "=================================================="
echo ""
echo "Linked agents:"
for dir in "${AGENT_DIRS[@]}"; do
    if [ -L "$CLAUDE_AGENTS_DIR/$dir" ]; then
        echo -e "  ${GREEN}✓${NC} ~/.claude/agents/$dir"
        # Count agents in directory
        count=$(find "$REPO_AGENTS_DIR/$dir" -name "*.md" -type f | wc -l | tr -d ' ')
        echo -e "    ($count agents available)"
    fi
done
echo ""
echo "Linked commands:"
if [ -d "$REPO_COMMANDS_DIR" ]; then
    cmd_count=$(find "$REPO_COMMANDS_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} ~/.claude/commands/ ($cmd_count slash commands)"
fi
echo ""
echo "These agents and commands are now available globally in Claude Code!"
echo ""
echo "Usage:"
echo "  - Agents: claude \"use @agent-name ...\""
echo "  - Commands: /command-name (e.g., /scaffold, /debug, /review)"
echo ""
echo "To unlink, run: ./unlink.sh"
echo ""
