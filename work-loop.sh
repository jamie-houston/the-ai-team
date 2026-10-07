#!/bin/bash

# work-loop.sh — dumb headless dispatcher for /project auto
#
# Runs `claude -p "/project auto"` in a loop against a project repo.
# Each iteration is a fresh minimal session that does exactly one step, writes
# status to the Obsidian vault, emits a JSON handoff, and exits. All inter-task
# state lives in the vault, so nothing idles between iterations and nothing
# goes stale past the prompt-cache TTL.
#
# Usage: work-loop.sh <project-repo-dir> [--max N] [--budget USD] [--vault DIR]
#
# Every event also lands in a per-loop NDJSON file that `dashboard/server.py`
# serves as a local page — the live stream plus the vault state the loop is
# working against. The terminal keeps only a one-line-per-event trace.
#
# Stop a running loop without killing mid-step: touch <repo>/.work-loop-stop
# (or press Stop on the dashboard, which touches the same file).

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Where this script lives, following symlinks, so it can find dashboard/.
SELF="${BASH_SOURCE[0]}"
while [ -L "$SELF" ]; do
    LINK_DIR="$(cd -P "$(dirname "$SELF")" && pwd)"
    SELF="$(readlink "$SELF")"
    case "$SELF" in /*) ;; *) SELF="$LINK_DIR/$SELF" ;; esac
done
SCRIPT_DIR="$(cd -P "$(dirname "$SELF")" && pwd)"

# Condenses the stream-json feed into one dashboard event per assistant text
# block and tool call. These land in $EVENTS, the only channel between this
# loop and the dashboard; the terminal renders the same events through
# TEXT_FILTER below. The init event carries the model the CLI actually resolved
# for the session, which is the only place it is knowable when we did not pass
# --model.
EVENT_FILTER='
def clean: gsub("\\s+"; " ") | ltrimstr(" ");
if .type == "system" and .subtype == "init" then
  {t: now, iter: $iter, kind: "model",
   model: (.model // "unknown" | sub("^claude-"; ""))}
elif .type == "assistant" then
  .message.content[]? |
  if .type == "text" then
    ((.text | clean) as $t | select($t != "")
     | {t: now, iter: $iter, kind: "text", text: $t})
  elif .type == "tool_use" then
    {t: now, iter: $iter, kind: "tool", name: .name,
     arg: (((.input.file_path // .input.path // "") | sub(".*/"; "")) as $f
           | (.input.command // .input.pattern // .input.skill // .input.description // "")
               as $c
           | (if $f != "" then $f else ($c | tostring) end | clean))}
  else empty end
else empty end
'

# The same events, one dim line each, for the terminal. The dashboard is the
# full view; this is only enough to see that the iteration is alive.
TEXT_FILTER='
def trunc($n): if length > $n then .[0:$n] + "…" else . end;
def dim: "[2m" + . + "[0m";
def stamp: ((.t - $start) | floor) as $s
  | "\($s / 60 | floor):\("0" + ($s % 60 | tostring) | .[-2:])";
if .kind == "model" then "  model \(.model)" | dim
elif .kind == "text" then "  \(stamp)  \(.text | trunc(88))" | dim
elif .kind == "tool" then "  \(stamp)  → \(.name) \(.arg | trunc(66))" | dim
else empty end
'

# 12345 -> 12.3k, 1234567 -> 1.2M
human() {
    awk -v n="$1" 'BEGIN {
        if (n >= 1000000) printf "%.1fM", n / 1000000
        else if (n >= 1000) printf "%.1fk", n / 1000
        else printf "%d", n
    }'
}

DEFAULT_VAULT="$HOME/Documents/mybrain/areas/work/coding/side-projects"

DEFAULT_SRC="$HOME/src/jamie-houston"

usage() {
    echo "Usage: $0 [project-repo-dir] [--lane LANE] [--max N] [--budget USD] [--vault DIR]"
    echo "       with no repo, prompts for one (vault projects that have stories/)"
    echo ""
    echo "  --lane  pin the loop to plan|impl|deploy|review|docs. Pinned, it takes"
    echo "          only that lane's steps and ends when the lane runs dry, instead"
    echo "          of routing itself. Two loops on one project need distinct pins;"
    echo "          the usual pair is '--lane plan' beside one unpinned loop."
    exit 1
}

# A project is loop-ready when the vault has a stories/ dir for it and a repo of
# the same name exists. Prints "name<TAB>repo" per project.
loop_ready_projects() {
    for d in "$VAULT"/*/; do
        name=$(basename "$d")
        [ -d "$d/stories" ] || continue
        [ -d "$DEFAULT_SRC/$name" ] || continue
        printf '%s\t%s\n' "$name" "$DEFAULT_SRC/$name"
    done
}

# If the current directory is inside one of the loop-ready project repos,
# print its path. Otherwise print nothing.
detect_repo_from_cwd() {
    local cwd name repo
    cwd="$(pwd)"
    while IFS=$'\t' read -r name repo; do
        [ -z "$repo" ] && continue
        case "$cwd" in
            "$repo"|"$repo"/*) echo "$repo"; return ;;
        esac
    done <<< "$(loop_ready_projects)"
}

# Asks for project and iteration count when the repo was not given on the CLI.
prompt_for_repo() {
    local projects names repos choice n
    projects=$(loop_ready_projects)
    [ -z "$projects" ] && { echo -e "${RED}No loop-ready projects in $VAULT${NC}"; exit 1; }
    names=(); repos=()
    while IFS=$'\t' read -r name repo; do
        names+=("$name"); repos+=("$repo")
    done <<< "$projects"

    echo "Which project?"
    for i in "${!names[@]}"; do
        printf "  %d) %-22s ${GREEN}%s${NC}\n" "$((i + 1))" "${names[$i]}" "${repos[$i]}"
    done
    read -r -p "Project [1]: " choice
    choice=${choice:-1}
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#names[@]}" ]; then
        echo -e "${RED}Not a listed project: $choice${NC}"; exit 1
    fi
    REPO="${repos[$((choice - 1))]}"

    read -r -p "Iterations [$MAX_ITER]: " n
    if [ -n "$n" ]; then
        [[ "$n" =~ ^[0-9]+$ ]] || { echo -e "${RED}Not a number: $n${NC}"; exit 1; }
        MAX_ITER="$n"
    fi
}

REPO=""
MAX_ITER=12
BUDGET=""
VAULT="$DEFAULT_VAULT"
LANE=""
PORT=8787

while [ $# -gt 0 ]; do
    case "$1" in
        --lane)   LANE="$2"; shift 2 ;;
        --max)    MAX_ITER="$2"; shift 2 ;;
        --budget) BUDGET="$2"; shift 2 ;;
        --vault)  VAULT="$2"; shift 2 ;;
        --port)   PORT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *)
            if [ -z "$REPO" ]; then REPO="$1"; shift; else usage; fi ;;
    esac
done

[ -d "$VAULT" ] || { echo -e "${RED}Vault not found: $VAULT${NC}"; exit 1; }
if [ -z "$REPO" ]; then
    REPO="$(detect_repo_from_cwd)"
    if [ -n "$REPO" ]; then
        echo -e "Detected current-directory project: ${GREEN}$(basename "$REPO")${NC}"
    else
        prompt_for_repo
    fi
fi
REPO="$(cd "$REPO" && pwd)" || { echo -e "${RED}Not a directory: $REPO${NC}"; exit 1; }
command -v jq >/dev/null || { echo -e "${RED}jq is required${NC}"; exit 1; }

case "$LANE" in
    ""|plan|impl|deploy|review|docs) ;;
    *) echo -e "${RED}Not a lane: $LANE${NC} (plan|impl|deploy|review|docs)"; exit 1 ;;
esac

# Pinned, the session may take only this lane's steps and ends when it runs
# dry; unpinned, it routes itself. Skill-side rules are in the project
# skill's references/headless.md.
PROMPT="/project auto${LANE:+ $LANE}"

# Per-lane, so two loops on one repo can be stopped independently.
STOP_FILE="$REPO/.work-loop-stop${LANE:+-$LANE}"
# Outside the repo on purpose: every session is told to check `git status`, and
# a loop's own scratch file showing up there is noise the loop created.
EVENTS="${XDG_CACHE_HOME:-$HOME/.cache}/work-loop/$(basename "$REPO")${LANE:+-$LANE}.ndjson"
TOTAL_COST=0
TOTAL_IN=0
TOTAL_OUT=0
TOTAL_CACHE=0
NEXT_MODEL=""
NEXT_LANE=""
NEXT_STEP=""
ITER=0
CUR_LANE=""
CUR_STEP=""

mkdir -p "$(dirname "$EVENTS")"
: > "$EVENTS"

# One NDJSON line per call. jq builds it so anything quoted survives.
event() { jq -nc "$@" >> "$EVENTS"; }

DASH_PID=""
DASH_URL=""
start_dashboard() {
    local script out i
    script="$SCRIPT_DIR/dashboard/server.py"
    [ -f "$script" ] || return 0
    command -v python3 >/dev/null || {
        echo -e "${YELLOW}python3 not found; dashboard disabled${NC}"; return 0; }
    out=$(mktemp -t work-loop-dash)
    python3 "$script" --events "$EVENTS" --repo "$REPO" --vault "$VAULT" \
        --stop-file "$STOP_FILE" --port "$PORT" > "$out" 2>&1 &
    DASH_PID=$!
    for i in 1 2 3 4 5 6 7 8 9 10; do
        DASH_URL=$(head -1 "$out" 2>/dev/null)
        case "$DASH_URL" in http://*) break ;; *) DASH_URL=""; sleep 0.2 ;; esac
    done
    [ -n "$DASH_URL" ] || echo -e "${YELLOW}dashboard did not start:${NC} $(cat "$out")"
    rm -f "$out"
}

STREAM_FILE=$(mktemp -t work-loop)
cleanup() {
    rm -f "$STREAM_FILE"
    [ -n "$DASH_PID" ] && kill "$DASH_PID" 2>/dev/null
    return 0
}
trap cleanup EXIT

finish() {
    # $1 = headline, $2 = detail
    event --arg h "$1" --arg d "$2" --argjson iter "$ITER" --argjson cost "$TOTAL_COST" \
        '{t: now, kind: "finish", headline: $h, detail: $d, iter: $iter, cost: $cost}'
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}$1${NC}"
    [ -n "$2" ] && echo "$2"
    printf "Iterations: %d   Cumulative cost: \$%.2f\n" "$ITER" "$TOTAL_COST"
    printf "Tokens: %s in / %s out / %s cached\n" \
        "$(human "$TOTAL_IN")" "$(human "$TOTAL_OUT")" "$(human "$TOTAL_CACHE")"
    echo "=================================================="
    osascript -e "display notification \"$1 after $ITER iteration(s), \$$(printf '%.2f' "$TOTAL_COST")\" with title \"work-loop: $(basename "$REPO")${LANE:+ [$LANE]}\"" 2>/dev/null || true
    exit 0
}

start_dashboard
event --arg project "$(basename "$REPO")" --arg repo "$REPO" --arg vault "$VAULT" \
    --arg lane "$LANE" --argjson max "$MAX_ITER" --arg budget "$BUDGET" \
    '{t: now, kind: "start", project: $project, repo: $repo, vault: $vault,
      lane: $lane, max: $max, budget: $budget}'

echo "=================================================="
echo "work-loop: $(basename "$REPO")"
echo -e "  repo:   ${GREEN}$REPO${NC}"
echo -e "  vault:  ${GREEN}$VAULT${NC}"
echo -e "  lane:   ${GREEN}${LANE:-unpinned (routes itself)}${NC}"
echo -e "  max:    ${GREEN}$MAX_ITER${NC}   budget: ${GREEN}${BUDGET:-none}${NC}"
[ -n "$DASH_URL" ] && echo -e "  view:   ${GREEN}$DASH_URL${NC}"
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
    STARTED=$(date +%s)
    CUR_LANE="${LANE:-${NEXT_LANE:-routing}}"
    CUR_STEP="$NEXT_STEP"
    echo ""
    echo -e "--- Iteration $ITER: ${GREEN}${CUR_LANE}${NC}${CUR_STEP:+ / $CUR_STEP} ---"
    event --argjson iter "$ITER" --arg lane "$CUR_LANE" --arg step "$CUR_STEP" \
        '{t: now, kind: "iteration", iter: $iter, lane: $lane, step: $step}'

    # stream-json so the iteration reports what it is doing while it runs; the
    # final `result` event carries the same payload --output-format json gave us.
    set +e
    (cd "$REPO" && claude -p "$PROMPT" \
        --permission-mode acceptEdits \
        --add-dir "$VAULT" \
        --output-format stream-json --verbose \
        "${MODEL_ARGS[@]}") \
        | tee "$STREAM_FILE" \
        | jq -rc --unbuffered --argjson iter "$ITER" "$EVENT_FILTER" \
        | tee -a "$EVENTS" \
        | jq -r --unbuffered --argjson start "$STARTED" "$TEXT_FILTER"
    EXIT_CODE=${PIPESTATUS[0]}
    set -e

    if [ $EXIT_CODE -ne 0 ]; then
        finish "claude exited non-zero ($EXIT_CODE)" "$(tail -3 "$STREAM_FILE")"
    fi

    OUTPUT=$(jq -c 'select(.type == "result")' "$STREAM_FILE" | tail -1)
    COST=$(echo "$OUTPUT" | jq -r '.total_cost_usd // 0')
    TOTAL_COST=$(awk -v t="$TOTAL_COST" -v c="$COST" 'BEGIN { printf "%f", t + c }')
    RESULT=$(echo "$OUTPUT" | jq -r '.result // empty')

    IN=$(echo "$OUTPUT" | jq -r '.usage.input_tokens // 0')
    OUT=$(echo "$OUTPUT" | jq -r '.usage.output_tokens // 0')
    CACHE=$(echo "$OUTPUT" | jq -r '(.usage.cache_read_input_tokens // 0) + (.usage.cache_creation_input_tokens // 0)')
    TOTAL_IN=$((TOTAL_IN + IN))
    TOTAL_OUT=$((TOTAL_OUT + OUT))
    TOTAL_CACHE=$((TOTAL_CACHE + CACHE))

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

    DURATION=$(( $(date +%s) - STARTED ))
    event --argjson iter "$ITER" --arg completed "$COMPLETED" --arg status "$STATUS" \
        --arg reason "$REASON" --argjson cost "$COST" --argjson in "$IN" \
        --argjson out "$OUT" --argjson cache "$CACHE" --argjson duration "$DURATION" \
        '{t: now, kind: "result", iter: $iter, completed: $completed, status: $status,
          reason: $reason, cost: $cost, in: $in, out: $out, cache: $cache,
          duration: $duration}'

    printf "completed: %s\n" "$COMPLETED"
    printf "usage: %ds  ·  %s in / %s out / %s cached  ·  \$%.2f (total \$%.2f)\n" \
        "$DURATION" \
        "$(human "$IN")" "$(human "$OUT")" "$(human "$CACHE")" "$COST" "$TOTAL_COST"

    case "$STATUS" in
        continue)
            : ;;  # next lane/step is printed in the next iteration header
        halt)
            finish "Loop halted" "Reason: ${REASON:-not given}" ;;
        empty)
            finish "Queue empty" "${REASON:-No lane has available work.}" ;;
        *)
            finish "Unknown handoff status: $STATUS" "$HANDOFF" ;;
    esac
done
