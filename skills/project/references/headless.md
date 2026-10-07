# Running headless under the work loop

Read when the lane argument is `auto` or `auto <lane>` — the session was
started by `work-loop.sh` (or a hand-run `claude -p "/project auto"`),
there is no human at the other end, and the final message must end with a
machine-readable handoff.

## What `auto` is

`auto` is not a sixth lane. The session routes to a real lane from CURRENT
POSITION exactly as the no-argument flow does — read `stories/README.md`, read
`## Lanes in flight`, verify against the repo — but instead of offering the
viable lanes to Jamie, it takes the single best one itself and says which in
the routing line. Everything the lane table says that lane may and may not
write still applies.

**A live peer row is not a halt.** An unpinned `auto` that finds its best lane
already claimed routes to the best *unclaimed* one instead and says so. Only
when no lane is both free and fed does it report `empty`.

**One step per iteration, no exceptions.** The driver's whole cost model is
that every session is a fresh minimal context — base prefix plus one story —
that does one step, writes status back, and exits. A session that chains a
second step drags the first step's diffs and tool output into it and recreates
exactly the accumulating-prefix shape the loop exists to avoid. Finish the
step, write the handoff, end.

## Pinned lanes — `auto <lane>`

`work-loop.sh --lane plan` sends `/project auto plan`. The session may
then take **only** that lane's steps. It does not route elsewhere when the pin
has no work — it reports `empty` and the loop ends. That is correct, not a
failure: a pinned loop exists so a second loop can run beside it, and silently
wandering into the other loop's lane is the one thing the pin prevents.

Pinning is what makes two loops on one project safe. The intended pair is a
pinned `plan` loop plus an unpinned loop that takes `impl` and falls through to
`deploy` on the promote threshold. **Never run two loops with the same pin, and
never two unpinned** — both resolve to the same lane and race.

### The `plan` pin needs explicit fuel

A pinned `plan` loop may story **only** rows whose **first cell** is `ready` in
"Open work not yet storied". Everything else in that table is gated — most rows
carry a note saying so in as many words (*"deliberately not planned yet"*,
*"don't plan unless Dave's hours change"*, *"needs a decision before it's a
story"*), and those notes are prior sessions' reasoning, frequently waiting on
an answer from Jamie or a customer. Headless, there is no one to weigh them
against, so the marker is the whole signal: **no `ready` rows means `empty`**,
even when the table is long. Storying a gated row is the expensive failure this
pin exists to prevent — it burns the reasoning and produces work nobody asked
for yet.

**A `ready` row that turns out to need a decision doesn't have to end the
loop.** File the candidates to `## FOR JAMIE` as `needs-decision` always
requires, clear the row's `ready` marker so the next iteration doesn't pick it
up again, and end the iteration there — that is the step. Emit `continue` if
other `ready` rows remain, `empty` if none do. Reserve `halt` for a decision
that blocks the *whole* pin, not one row of it.

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

Claim the row as normal — first write, deleted on close.

**A row in another lane is a peer, not a conflict.** Two loops on one project
is the supported shape, so a `plan` row while you are taking `impl` means the
plan loop is doing its job. Leave it, honour what the lane table says it owns,
and carry on. Unpinned, a row in the lane you *wanted* means route to the best
unclaimed lane instead — don't halt.

**A row in the lane you are taking is either your own crash or a second loop
with your pin.** Loops never share a lane — one pin per lane, at most one
unpinned — so if its `Started` stamp is old enough that no live iteration
could still be in it, it is a prior iteration of this same loop that died
before deleting the row: take it over silently, no need to report it. If the
stamp is recent, assume a live session (another loop with your pin, or Jamie in
a terminal), halt, and name the row in `reason`. Never delete a row you might
be sharing.

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
  `empty` — no available work. Unpinned, that means checking every lane
  against its own steps first — a gate on one lane is not a gate on all of
  them. Pinned, it means only the pinned lane, and it is a normal ending:
  say what the pin was waiting on (*"no `ready` rows in open-work"*) so Jamie
  knows what to mark before restarting it.
- `completed`: one clause, what this iteration did (`null` on an early halt).
- `next_step` / `next_lane` / `next_model`: where the next iteration should
  pick up and which model fits it, per the model table. `null` when halting
  or empty. Under a pin, `next_lane` is always the pin — the driver ignores
  it for routing either way, but a different value there means the session
  routed somewhere it was not allowed to.
- `reason`: `null` on `continue`; on `halt`, what stopped the loop and where
  the detail lives (the FOR JAMIE slug, the denied command); on `empty`, one
  clause on why nothing is available.
