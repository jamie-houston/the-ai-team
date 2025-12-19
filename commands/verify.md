---
description: Verify implementation meets all PRD requirements
argument-hint: [requirement-focus]
---

# Verify PRD Requirements

Validate that the implementation fulfills all requirements from the PRD.

Use the Requirements Verifier agent defined in `.claude/agents/core/requirements-verifier.md` to:

1. Read and parse PRD.md
2. Scan the codebase for implemented features
3. Cross-reference user stories with code
4. Check acceptance criteria are met
5. Identify gaps, partial implementations, and scope creep
6. Generate a compliance report

## Output

A detailed verification report showing:
- Which requirements are fully implemented
- Which are partially implemented (with gaps identified)
- Which are missing entirely
- Any features implemented that weren't in the PRD

## Focus (optional)

$ARGUMENTS

If no focus specified, verify all requirements from PRD.md.

## When to Use

- After completing implementation before final review
- Before submitting a PR or demo
- When unsure if all requirements have been met
- As part of `/review` command (runs automatically)
