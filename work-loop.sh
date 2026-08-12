#!/bin/bash

# work-loop.sh — dumb headless dispatcher for /project-context auto
#
# Runs `claude -p "/project-context auto"` in a loop against a project repo.
# Each iteration is a fresh minimal session that does exactly one step, writes
# status to the Obsidian vault, emits a JSON handoff, and exits. All inter-task
# state lives in the vault, so nothing idles between iterations and nothing
# goes stale past the prompt-cache TTL.
#
# Usage: work-loop.sh <project-repo-dir> [--max N] [--budget USD] [--vault DIR]
#
# Stop a running loop without killing mid-step: touch <repo>/.work-loop-stop

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DEFAULT_VAULT="$HOME/Documents/mybrain/areas/work/coding/side-projects"

usage() {
    echo "Usage: $0 <project-repo-dir> [--max N] [--budget USD] [--vault DIR]"
    exit 1
}

REPO=""
MAX_ITER=12
BUDGET=""
VAULT="$DEFAULT_VAULT"

while [ $# -gt 0 ]; do
    case "$1" in
        --max)    MAX_ITER="$2"; shift 2 ;;
        --budget) BUDGET="$2"; shift 2 ;;
        --vault)  VAULT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *)
            if [ -z "$REPO" ]; then REPO="$1"; shift; else usage; fi ;;
    esac
done

[ -z "$REPO" ] && usage
REPO="$(cd "$REPO" && pwd)" || { echo -e "${RED}Not a directory: $REPO${NC}"; exit 1; }
[ -d "$VAULT" ] || { echo -e "${RED}Vault not found: $VAULT${NC}"; exit 1; }
command -v jq >/dev/null || { echo -e "${RED}jq is required${NC}"; exit 1; }

STOP_FILE="$REPO/.work-loop-stop"
TOTAL_COST=0
NEXT_MODEL=""
ITER=0

finish() {
    # $1 = headline, $2 = detail
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}$1${NC}"
    [ -n "$2" ] && echo "$2"
    printf "Iterations: %d   Cumulative cost: \$%.2f\n" "$ITER" "$TOTAL_COST"
    echo "=================================================="
    osascript -e "display notification \"$1 after $ITER iteration(s), \$$(printf '%.2f' "$TOTAL_COST")\" with title \"work-loop: $(basename "$REPO")\"" 2>/dev/null || true
    exit 0
}

echo "=================================================="
echo "work-loop: $(basename "$REPO")"
echo -e "  repo:   ${GREEN}$REPO${NC}"
echo -e "  vault:  ${GREEN}$VAULT${NC}"
echo -e "  max:    ${GREEN}$MAX_ITER${NC}   budget: ${GREEN}${BUDGET:-none}${NC}"
echo "  stop:   touch $STOP_FILE"
echo "=================================================="

while true; do
    if [ -f "$STOP_FILE" ]; then
        rm -f "$STOP_FILE"
        finish "Stopped by kill switch" "$STOP_FILE existed; removed it and exited before the next iteration."
    fi
    if [ "$ITER" -ge "$MAX_ITER" ]; then
        finish "Max iterations reached ($MAX_ITER)"
    fi
    if [ -n "$BUDGET" ] && awk -v c="$TOTAL_COST" -v b="$BUDGET" 'BEGIN { exit !(c >= b) }'; then
        finish "Budget exceeded" "$(printf 'Spent $%.2f of the $%s budget.' "$TOTAL_COST" "$BUDGET")"
    fi

    ITER=$((ITER + 1))
    MODEL_ARGS=()
    [ -n "$NEXT_MODEL" ] && MODEL_ARGS=(--model "$NEXT_MODEL")
    echo ""
    echo -e "--- Iteration $ITER $([ -n "$NEXT_MODEL" ] && echo "(model: $NEXT_MODEL)") ---"

    set +e
    OUTPUT=$(cd "$REPO" && claude -p "/project-context auto" \
        --permission-mode acceptEdits \
        --add-dir "$VAULT" \
        --output-format json \
        "${MODEL_ARGS[@]}")
    EXIT_CODE=$?
    set -e

    if [ $EXIT_CODE -ne 0 ]; then
        finish "claude exited non-zero ($EXIT_CODE)" "$(echo "$OUTPUT" | tail -5)"
    fi

    COST=$(echo "$OUTPUT" | jq -r '.total_cost_usd // 0')
    TOTAL_COST=$(awk -v t="$TOTAL_COST" -v c="$COST" 'BEGIN { printf "%f", t + c }')
    RESULT=$(echo "$OUTPUT" | jq -r '.result // empty')

    # Handoff = the last fenced ```json block in the final message.
    HANDOFF=$(echo "$RESULT" | awk '/^```json$/ { buf = ""; on = 1; next } /^```$/ { if (on) { last = buf; on = 0 }; next } on { buf = buf $0 "\n" } END { printf "%s", last }')
    if [ -z "$HANDOFF" ] || ! echo "$HANDOFF" | jq -e . >/dev/null 2>&1; then
        finish "No parseable handoff" "Final message was:
$(echo "$RESULT" | tail -15)"
    fi

    STATUS=$(echo "$HANDOFF" | jq -r '.status // "halt"')
    COMPLETED=$(echo "$HANDOFF" | jq -r '.completed // "(nothing)"')
    REASON=$(echo "$HANDOFF" | jq -r '.reason // empty')
    NEXT_MODEL=$(echo "$HANDOFF" | jq -r '.next_model // empty')
    NEXT_STEP=$(echo "$HANDOFF" | jq -r '.next_step // empty')
    NEXT_LANE=$(echo "$HANDOFF" | jq -r '.next_lane // empty')

    printf "completed: %s   cost: \$%.2f\n" "$COMPLETED" "$COST"

    case "$STATUS" in
        continue)
            echo "next: $NEXT_LANE / $NEXT_STEP (model: ${NEXT_MODEL:-default})" ;;
        halt)
            finish "Loop halted" "Reason: ${REASON:-not given}" ;;
        empty)
            finish "Queue empty" "${REASON:-No lane has available work.}" ;;
        *)
            finish "Unknown handoff status: $STATUS" "$HANDOFF" ;;
    esac
done
