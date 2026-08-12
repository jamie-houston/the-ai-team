# Running headless under the work loop

Read when the lane argument is `auto` — the session was started by
`work-loop.sh` (or a hand-run `claude -p "/project-context auto"`), there is no
human at the other end, and the final message must end with a machine-readable
handoff.

## What `auto` is

`auto` is not a sixth lane. The session routes to a real lane from CURRENT
POSITION exactly as the no-argument flow does — read `stories/README.md`, read
`## Lanes in flight`, verify against the repo — but instead of offering the
viable lanes to Jamie, it takes the single best one itself and says which in
the routing line. Everything the lane table says that lane may and may not
write still applies.

**One step per iteration, no exceptions.** The driver's whole cost model is
that every session is a fresh minimal context — base prefix plus one story —
that does one step, writes status back, and exits. A session that chains a
second step drags the first step's diffs and tool output into it and recreates
exactly the accumulating-prefix shape the loop exists to avoid. Finish the
step, write the handoff, end.

## Gates relaxed under `auto` — and only under `auto`

- **`needs-planning`**: write the story, set its ledger row to `planned`, end
  the iteration — do **not** stop for Jamie's review. The next iteration
  implements it, so the story always exists on disk as an audit trail before
  any code is written. (Interactive sessions still stop for review; this is
  the one place the routing table's "stop and let Jamie review" is overridden.)
- **`planned`**: read the story and implement without the interactive scope
  confirmation.
- **Model mismatch is advisory, not a stop.** The driver sets `--model` from
  the previous iteration's handoff, so the session runs on whatever it was
  given. Don't stop and wait for `/model` — just put the recommendation for
  the *next* step in the handoff's `next_model` field.
- **Never call `AskUserQuestion`** — nothing answers it in `-p` mode; the call
  hangs or dies and the iteration is wasted either way. Anything that would
  have been a question is written to `## FOR JAMIE` instead. If the answer
  blocks the routed step, halt (below); if it can wait a session or two, file
  it and continue.

## Gates that still halt

Halt means: write the reason to its owner (`## FOR JAMIE` for anything needing
Jamie), finish the step's owner-writes as far as they validly go, and emit a
`halt` handoff. Never guess through one of these:

- **`needs-decision`** — write the candidates with sizes and tradeoffs to
  `## FOR JAMIE`, then halt. Choosing silently is exactly what this step
  exists to prevent, headless or not.
- **A blocking unanswered `## FOR JAMIE` item** on the routed work.
- **A permission denial** on a command the step needs. Name the exact command
  in the handoff's `reason` so Jamie can allowlist it once and re-run.
- **An index/repo contradiction** the session can't safely resolve. The repo
  wins as usual, but if fixing the index requires a judgment call about work
  another session may have done, that's Jamie's call.

## Lanes in flight

Claim the row as normal — first write, deleted on close. The loop is serial,
so a stale row matching the loop's own shape (same lane the position routes
to, started recently, no session running) can only be a crashed prior
iteration of this same loop: take it over silently, no need to report it.
A row that doesn't fit that shape is another session's — stop and halt, as the
parallel-sessions rules require.

## The handoff

The session-status line rule still applies. After it, the final message ends
with a fenced ```json block — the driver parses this, so it must be the last
thing in the message and must be valid JSON:

```json
{"status": "continue|halt|empty",
 "completed": "story 61: planned → committed",
 "next_step": "committed", "next_lane": "deploy", "next_model": "sonnet",
 "reason": null}
```

- `status`: `continue` — a step completed and more work is available;
  `halt` — a halting gate fired, `reason` says which and what unblocks it;
  `empty` — no lane has available work (check every lane against its own
  steps first — a gate on one lane is not a gate on all of them).
- `completed`: one clause, what this iteration did (`null` on an early halt).
- `next_step` / `next_lane` / `next_model`: where the next iteration should
  pick up and which model fits it, per the model table. `null` when halting
  or empty.
- `reason`: `null` on `continue`; on `halt`, what stopped the loop and where
  the detail lives (the FOR JAMIE slug, the denied command); on `empty`, one
  clause on why nothing is available.
