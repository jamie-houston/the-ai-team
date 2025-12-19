---
description: Full code review + requirements compliance check
argument-hint: [focus-area]
---

# Full Project Review

Comprehensive review covering both code quality AND requirements compliance.

## This command runs TWO agents:

### 1. Requirements Verifier (`.claude/agents/core/requirements-verifier.md`)
- Reads PRD.md and extracts all user stories/acceptance criteria
- Scans codebase to verify each requirement is implemented
- Identifies gaps, partial implementations, and scope creep
- Generates a compliance report

### 2. Code Review (`.claude/agents/specialized/dotnet/review.md`)
- Verifies build and tests pass
- Checks code quality and naming conventions
- Identifies security issues
- Finds common mistakes (N+1, missing async, thread safety)
- Suggests fixes

## Output

A combined report with:
1. **Requirements Compliance** - What's implemented, what's missing
2. **Code Quality** - Issues found and suggested fixes
3. **Action Items** - Prioritized list of things to address

## Focus (optional)

$ARGUMENTS

If no focus specified, review the entire project.

## When to Use

- Before submitting a PR
- Before a demo or presentation
- After completing a feature to ensure nothing was missed
- As a final quality gate before deployment
