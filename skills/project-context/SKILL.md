---
name: project-context
description: Load and update project context from Jamie's Obsidian vault instead of from markdown in the repo, so sessions stay short and repos stay lean. Use when Jamie says "work on the next phase", "what's next", "pick up where we left off", "what was I working on", or names a story file; when finishing a step that needs its status written back; or when a repo is carrying planning markdown that should be migrated out to the vault. Takes an optional lane argument — `plan`, `impl`, `deploy`, `review`, `docs` — declaring what this session is for; with no argument it reads the lanes already in flight and offers the ones that can run alongside them. `auto` runs one step headless under the work-loop dispatcher.
---

# Project context

Planning docs live in **Obsidian**, not in the repo. The repo carries only what
binds the code. Sessions load one story file, do one unit of work, write status
back, and end.

Vault root: `~/Documents/<vault>/areas/work/coding/side-projects/`

The cost reason: `CLAUDE.md` files that say "read PROGRESS.md and ROADMAP.md
first" turn every one-off task into a directed 15K-token read. Moving those out
made the `scheduling` repo drop from 204KB of markdown to 22KB. An idle session
holding a large prefix is also the expensive case — with a 5-minute cache TTL, a
20-minute pause mid-task re-creates the whole prefix at 1.25x. Ending the session
costs one cold write next time and nothing in between.

## Layout

```
side-projects/<project>/
  <project-name>.md        # hub: status, where things live, next steps, decisions
  <project> inbox.md       # two-way queue: `## FOR JAMIE` on top, Jamie's dumps below
  stories/README.md        # ENTRY POINT: position, lanes, step machine, phases, ground rules
  stories/ledger.md        # story status table         ┐ split out of README once it
  stories/open-work.md     # open work + open items     │ passes ~30 KB — README is
  stories/operations.md    # runbook facts, release     ┘ loaded whole every session
  stories/NN-<slug>.md     # one unit of work, self-contained
  prd.md, progress.md      # requirements, history
  archive/                 # design handoffs, dead ends, spent roadmaps
```

**The inbox is named `<project> inbox.md`, not `inbox.md`** — every project's
tabs and quick-switcher entries would otherwise read "inbox" and be
indistinguishable in Obsidian. Everywhere below that says `inbox.md` or
`[[inbox]]` means that file; the index's "Where the rest lives" table names it
exactly, so link it from there rather than guessing. **Never create a plain
`inbox.md` alongside one** — `scheduling` carried both for two days and the
item dumped in the unused copy went undrained.

In the repo: `CLAUDE.md`, `README.md`, `ARCHITECTURE.md` (binding constraints
only), and operational runbooks like `docs/DEPLOY.md`. Nothing else.

## One fact, one owner

**This is the rule the rest of the file is built on.** Every fact has exactly
one home. Everywhere else references it — by story link, by inbox item slug,
by section name — and does not restate it.

| Fact | Sole owner |
|---|---|
| What happened in a session | that story's session log |
| Real work with no story yet | "Open work not yet storied" — in `open-work.md` if the index is split, else the index |
| A deliberate non-fix, or a decision with no work attached | "Open items" — same file as above |
| A story's status | the Stories table — `ledger.md` if the index is split, else the index |
| How to run, deploy or bootstrap the thing | `operations.md` |
| Something Jamie must do or answer | `inbox.md` → `## FOR JAMIE` |
| Raw unshaped input from Jamie | `inbox.md` → bottom half |
| Anything that binds the code | the repo — `ARCHITECTURE.md` / `docs/arch/` |
| Where the next session starts | index → CURRENT POSITION |
| How this workflow works | **this file** — not the vault files |

Two consequences worth stating outright, because sessions get both wrong:

- **A session that finishes work writes the durable fact once, then links to
  it.** Recording the same finding in the position block *and* the open-work
  table *and* the story log is the failure mode, not thoroughness. It has now
  forced three cleanups of `stories/README.md` and one of `inbox.md`.
- **Discharging an item means deleting it.** Not striking it through, not
  replacing it with a summary of what it used to say. If the trace has value it
  already lives with its owner above; if it doesn't, it's noise. The vault is
  git-tracked — history is the archive, and `git log -S` finds anything.

**CURRENT POSITION is a form, not a narrative, and it is capped at 15 lines.**
Fixed fields only: phase, active story + step, blocked-on, next, last-touched.
A session replaces it wholesale; it never appends. If something won't fit a
field, that is the signal it belongs to a different owner above — relocate it,
don't grow the block. Prose is what makes a position block unmergeable: every
session restates the last one's context to make its own paragraph read, and the
block is what every session loads whole.

The vault's `.git/hooks/pre-commit` enforces the cap on every
`side-projects/*/stories/README.md`. Git does not version hooks, so **if the
vault is ever re-cloned the hook is gone** — recover it with
`git show <sha>:...` from the 2026-08-02 commit, or rewrite it: count the
contiguous `>` lines after `CURRENT POSITION` and fail over 15.

## Running sessions in parallel

Several sessions may be open on the same project at once. **At most one of them
implements.** The lane table below is the authority on what each may write.

**Claim before you write.** The index carries a `## Lanes in flight` table. Add
your row as your *first* write and delete it when you close:

| Lane | Story | Step | Started |
|---|---|---|---|
| impl | [[60-plan-change-next-period]] | deployed | 2026-08-02 09:14 |
| plan | [[62-recurring-availability]] | needs-planning | 2026-08-02 10:02 |

A one-line append and a one-line delete have no conflict window — the same trick
`inbox.md` uses. **If a row already covers the work you routed to, stop and tell
Jamie**; another lane has it. A stale row from a session that crashed is
normal — say so and take it over, don't silently work around it.

### The lanes

| Lane | Steps it takes | May write | Must not touch |
|---|---|---|---|
| `plan` | `needs-decision`, `needs-planning` | its story file, that story's ledger row, `inbox.md` | the repo, CURRENT POSITION |
| `impl` | `planned`, `in-progress`, `verified` | everything — working tree, repo git, CURRENT POSITION | — |
| `deploy` | `committed`, `deployed` | `operations.md`, the deployed story's log, `inbox.md`, `open-work.md` (draining rows this promote discharges — see *Finishing a step*) | the working tree: no commits, no branch switches, no `build` / `db:generate` / dev server / integration tests. It promotes refs that already exist; the push belongs to `impl` (see *Deploying in batches*). |
| `review` | any — reads a diff or a PR | `open-work.md`, `inbox.md`, the reviewed story's log | the working tree — read-only in the repo |
| `docs` | any | vault files; repo docs **only when no `impl` row is in flight** | the working tree while `impl` holds it |

**What coexists.** `impl` + `plan` on a *different* story, `impl` + `review`, and
`impl` + `deploy` of an already-committed story all run fine — that last pair is
the common case: promote story N while N+1 is being built. Never two `impl`
lanes, never two `plan` lanes on the same story, never `docs` editing repo files
while `impl` holds the tree.

**Only ever `Edit` a shared vault file — never `Write` it.** `stories/README.md`
and `inbox.md` are written by every lane. A whole-file `Write` lands your
session-start read on top of another lane's edit from twenty minutes ago and
looks like a clean success. Before editing a section, re-read *that section*
(`grep -n` the heading, then `Read` with `offset`/`limit`); the read you did at
routing time is stale by the time you finish a step.

**Only the impl lane touches the repo** — not just its files, but its dev server,
its database, its generated client, and its git. The project's own `CLAUDE.md`
lists which commands that rules out. A non-implementation lane that wants a check
run names the command and leaves it to the impl lane.

**Name your lane** in the routing line and in every session-status line, so Jamie
can tell parallel terminals apart.

### Deploying in batches

**The `impl` lane pushes; the `deploy` lane promotes** — pushing is what runs
CI, so it belongs to the session that made the commit. Promoting is what
batches, and the queue is a fact git already holds:

```bash
git log origin/main..origin/staging --oneline
```

**Run that before offering `deploy` at routing time.** Under the threshold with
impl work available, `deploy` is not the lane — say what's pending and route to
the work.

> **Taking the `deploy` lane, or deciding whether to offer it? Read
> `~/.claude/skills/project-context/references/deploying.md`** — the four
> promote triggers, why pushes don't batch, and the cost of letting staging run
> ahead of prod.

## Starting work — "work on the next phase"

**Always read `stories/README.md` first, and by default read nothing else.** It
is small on purpose — when it grows past ~30 KB the bulk gets split into
`ledger.md` / `open-work.md` / `operations.md` and the README keeps only the
entry-point sections. Its **CURRENT POSITION** block states the phase, the step,
and any blocker. Never scan a plan or history file to work out what's next —
`archive/roadmap-phases.md` is 63 KB, and that read is what the index exists to
prevent.

Then verify rather than trust — the index records intent at last write, and the
tree may have moved. `git log --oneline -5` and `git status` is enough. **If the
index contradicts the repo, the repo wins**: say so, fix the index, then proceed.

### Declaring the lane

**`/project-context <lane>`** — `plan`, `impl`, `deploy`, `review`, `docs` —
says what this session is for. Jamie may also just say it in words ("this one's
a planning session"); same thing. The lane fixes what the session is allowed to
write, per the table above; the step still decides *which* work it picks up.
`auto` is headless dispatcher mode, not a lane: the session routes itself to
the single best lane, runs one step with relaxed review gates, and ends with a
machine-readable handoff.

> **Running headless under the work loop (`/project-context auto`)? Read
> `~/.claude/skills/project-context/references/headless.md`** — which gates
> relax, which still halt, and the handoff the driver parses.

Reconcile the two before acting:

- **Lane and step agree** → confirm in the routing line and go.
- **The lane has no work under the current position** — `deploy` when nothing is
  `committed`, `plan` when everything is already planned — → say so, name what
  that lane *could* do (an older promotable story, an unstoried row in
  `open-work.md`), and let Jamie choose. Never quietly do a different lane's work
  because the declared one had nothing.
- **The lane is already claimed** in `## Lanes in flight` → stop and tell Jamie,
  as above. For `impl` that is absolute; the other lanes are only a clash when
  the row covers the same story.

**No lane given?** Read `## Lanes in flight` *before* proposing anything, then:

- **One viable lane** → don't ask. State it in the routing line and go.
- **Several** → `AskUserQuestion`, one option per lane, best first. The
  description says the story and step it would pick up and why it's safe
  alongside what's running — *"deploy — promote [[60-plan-change-next-period]],
  already committed; doesn't touch the tree impl is holding."*
- **A lane that is free but has no available work is not an option.** Don't pad
  the list to fill it out.
- **None viable** — one `impl` lane already holds the only live story and there
  is nothing to plan, promote, or review → say that, and suggest not opening a
  second session rather than inventing work for it.

**A gate on one lane is not a gate on all of them.** Check each lane against its
own steps before reporting that nothing is available. A promote-to-main gate — a
manual sweep owed, a sign-off pending — blocks `deploy` and nothing else; `plan`
and `impl` are still open, and staging still accepts pushes. This has twice been
reported as "no lane has available work" when there was plenty.

Route on the **step**, and do exactly one step per session unless Jamie says
otherwise:

| Step | Do this |
|---|---|
| `needs-decision` | Two or more candidates and no obvious winner. **Present them with sizes and tradeoffs and ask Jamie to pick** — do not choose silently. Then update the position to the chosen work's real step and re-route. |
| `needs-planning` | Read **only** the source the index points at — usually a row of "open work not yet storied", or an [[inbox]] item. If it points into a larger file, grep the heading and read to the next `## `; never read that file whole. Write it up as the next numbered story, at the depth of the project's existing shipped stories. Then **stop and let Jamie review** — do not plan and implement in one session. |
| `planned` | Read the story. Confirm scope with Jamie, then implement. |
| `in-progress` | Read the story's session log for where it stopped. Resume there. |
| `verified` | Commit, then push to `origin/staging` — don't wait on CI. |
| `committed` | Promote per the project's own runbook, **only once the batch is ready** — see *Deploying in batches*. Otherwise leave it queued and say so. |
| `deployed` | Smoke-check, then mark `done`, drain any `open-work.md` row this discharges (see *Finishing a step*), and report what the next work is. |

**Read the index and follow what it points at.** Don't assume a file exists
because another project has one — and don't assume a file that *used* to be the
source still is. Both projects have now outlived their roadmaps: `scheduling`'s
phases all shipped and `roadmap-phases.md` moved to `archive/`,
`mycreditcard.guru`'s lettered phases are done. Unstoried work comes from
[[inbox]] and the index's own open-work table in both. A roadmap is a shape a
project may pass through, not one it keeps.

Confirm the routing in one line before acting — *"`needs-planning`; I'll write
story 95 from the open-work row on tour screenshots and stop for your review"* — so
Jamie can redirect before any tokens go into the wrong step. Name the lane in
that line too.

**Then claim it before your first write** — the `## Lanes in flight` row, *and*
the story's ledger row set to `in-progress` *now*, not at the end of the
session. Status written only on finish is what lets two lanes plan the same
story twice.

If a phase turns out bigger than one story, split it and say so. A story that
would exceed ~8 KB is two stories.

**Ask outstanding questions at the start of the session, not the end.** Any
`needs-decision` step, ambiguous scope, or blocker noted in CURRENT POSITION
should be raised right after routing, before implementation work starts. Jamie
is fine deferring a question if it's asked early, but if it's raised as a
wrap-up note he's about to close the session and misses it.

**This is backed by a durable list, not by memory: the `## FOR JAMIE` section at
the top of `inbox.md`.** Read it on **every** session, not just
`needs-planning` ones — it is cheap and it is the only thing that survives a
closing message Jamie scrolled past.

- **Name the open count in the routing line**, e.g. *"Phase 0 is `planned`; 2
  questions are waiting on you."* Then **put them to him with `AskUserQuestion`
  — one question per item, and always a "Defer — answer later" option alongside
  the real answers.** Answering has to be one keystroke and so does skipping.
  The question text is the one-line gist, not a re-explanation. Jamie has asked
  for the tool form twice ("actually ask me with the ask user skill", "include
  defer answer if I can as an option"); prose inviting him to reply is what he
  scrolls past, which is the whole reason this list exists.
- **Anything you would have put in a closing message that needs an answer goes
  in that section instead** — appended at the bottom of it, with what it blocks.
  A question that blocks nothing stays in the closing message and dies there.
- **Identify items by a short slug, not an ordinal** — `[stripe-test-mode]`, not
  `#3`. Two lanes appending both produce "#6", and deleting an item renumbers
  everything below it, so a reference written elsewhere silently retargets.
- **End every item with a bolded `**Answer:**` line — that is the one place
  Jamie edits an existing item.** Appending a new item is still bottom-only;
  replying to one is filling in its own `Answer:` line, not a paragraph tacked
  on after it. A non-empty `Answer:` is what tells the next session the item is
  ready to process.
- **On an answer, delete the item** and write the answer with its owner above.
  An answer that exists only in a transcript is lost; an answer left here *as
  well* is the duplication this file exists to prevent.
- **Cap is 7.** At the cap, resolve or downgrade one before adding. Items that
  will sit for weeks are backlog, not questions — move them to the index's
  "Needs Jamie, not code" / "Needs a decision, not a test" sections.
- Genuinely *blocking* questions use `AskUserQuestion` mid-session as well —
  those get **no** Defer option, because deferring is the thing that blocks.
  The list is for what can wait a session or two.
- **When the item is an action Jamie can just run, give the exact command(s),
  not a paragraph explaining the situation.** A sentence of *why* is fine
  above them, but the thing Jamie reads last must be copy-pasteable — not a
  decision he has to turn back into a command himself. Wrong: explaining that
  `db:reset-demo` needs a password and describing what it does. Right:

  ```bash
  set -a; . ./.env.staging; set +a
  export SEED_DEMO_PASSWORD='<pick one, write it down>'
  npm run db:reset-demo
  ```

  **Load a `.env` by sourcing it, never by `grep`/`cat`/`export $(...)`.**
  Sourcing keeps the value inside the shell; piping the file through a command
  routes the secret into the transcript — that is exactly how this project
  leaked a prod password, while *verifying* it. The repo's
  `.claude/settings.json` denies `grep`/`cat`/`sed` on `.env*`, so the piped
  form is also a command that simply won't run.

  If the action only makes sense with a value only Jamie has (a password, a
  yes/no on scope), say so in one clause and leave a placeholder in the
  command — don't hold the whole command back pending an answer. This applies
  in both places: the `inbox.md` item text and the session's closing message.

### Verification checklists (e.g. `operations.md`'s manual sweep)

The same clunky-answer problem shows up wherever Jamie is asked to browser-check
a list and report back. Same fix: a real Markdown checkbox per item, plus a
bolded `**Notes:**` line reserved for what he found.

> **Writing or draining such a list? Read
> `~/.claude/skills/project-context/references/checklists.md`** — what to do
> with a filled `Notes:` line, and when a section is done.

### Which model for this step

Recommend a model alongside the routing line — the step already tells you the
kind of work, so the model follows for free:

| Step / lane | Model | Why |
|---|---|---|
| `needs-decision`, `needs-planning` | Opus (or Fable for open-ended exploration) | Judgment-heavy: weighing tradeoffs, writing a story from scratch. |
| `planned`, `in-progress` (real implementation) | Opus | Multi-file changes benefit from stronger reasoning. |
| `verified` → commit + push, `committed` → promote, `deployed` → smoke-check | Sonnet | Mechanical or supervisory — running commands and reading output, not deciding anything. |
| the `review` lane | Opus | Finding a real defect in a diff is judgment, not pattern-matching. |

Say it as part of the one-line routing confirmation, e.g. *"`committed` — three
stories pending, I'll promote and smoke-check; Sonnet is enough for this one."*

If the recommended model differs from the model currently active, **stop and
wait** for Jamie to switch (`/model`) or explicitly say to proceed anyway —
don't just note the mismatch and continue on the wrong model.

### Don't read what you don't need

- One-off task in the repo, no phase work: `CLAUDE.md` + `ARCHITECTURE.md` only.
  Do not open the vault at all.
- Implementing a story: that story + `CLAUDE.md` + `ARCHITECTURE.md`.
- `progress.md` and `prd.md` are history and requirements — read them only when
  the story points at a specific section, and never whole.
- **The index's split files are read by step, never by default.** `ledger.md`
  only to check a story's status, `open-work.md` only when planning or draining
  the inbox, `operations.md` only when deploying or debugging an environment.
  Reading all three costs what the unsplit index did — which is the thing the
  split undid. **Never merge them back into `README.md`.**
- **Never pad a markdown table to align its columns.** Write `| a | b |` and
  leave it ragged. Padding cells to the widest cell in the column was **half of
  `open-work.md` and two thirds of `ledger.md`** — 68 KB of whitespace across
  the two, in tables whose cells run 1,700 characters, where alignment is
  unreadable anyway. Nothing in the vault re-pads automatically; it only comes
  back if an agent does it while adding a row.

## Finishing a step

Do this **every time a step completes**, including when Jamie stops mid-step —
in that case record where it stopped, which is the part that makes resuming cheap.

**Write each fact to its owner first and the position block last.** The order
matters: a session that starts with the position block writes the narrative
there and then copies it outward, which is how the block grew to 494 lines
twice. Written in this order, the block has nothing left to say but pointers.

1. **Tick the story's checklist; append to its session log** — what shipped,
   what was deliberately left, and where it stops if unfinished. This is the
   only account of the session, so ship and promote detail goes *here*.
2. **Does any decision bind the code?** Then it belongs in the repo's
   `ARCHITECTURE.md` / `docs/arch/`, not the vault. A constraint that lives only
   in the vault is invisible during a one-off task, which is the exact failure
   this layout prevents.
2a. **Did the session add, move, or rename an environment variable?** Update the
   env-var table in `operations.md` in the same session — name, which hosted
   environments it is set in, whether a local `.env.*` also needs it, and what
   consumes it. Jamie asked where a var goes 15 times in three days because the
   answer was re-derived from the code each time instead of being written down
   once.
3. **Did the session turn up work nobody has storied?** One row in "Open work
   not yet storied" (`open-work.md` when the index is split). A deliberate
   non-fix goes in "Open items", same file.
3a. **Going the other way — did this session's promote discharge an existing
   row?** A row that reads "stays until story N ships / lands on `main`" does
   not delete itself the moment that becomes true; something has to notice.
   Whenever a story reaches `done` (promoted to `main`), `grep -n` that story's
   number in `open-work.md` and delete every row whose stay-clause is now
   satisfied. This is a `deploy`-lane duty at the `deployed`→`done` step, since
   that lane is the one confirming the promote. Skipping it is exactly how 17
   rows in `scheduling`'s `open-work.md` sat stale for days after their stories
   landed on `main` — each one still correctly *worded* as conditional, just
   never re-checked once the condition flipped.
4. Update the story's row in the **Stories** table (`ledger.md` when split), and
   the **Phases** table in the index if the project has one. These rows are the status ledger — when one
   disagrees with the position block, this is the one that was left stale.
   **A row is a status, not a session log — cap the Status cell at ~200
   characters**: step, promote SHA, version, one clause of why. CI run IDs,
   build timestamps, per-route smoke results and what deviated go in the story's
   session log, which step 1 already gave them. `scheduling`'s `ledger.md` grew
   to 104 KB this way — larger than the `README.md` whose size forced the split
   — with 23 rows over 2,000 characters and one at 4,604.
5. **Anything needing an answer or action from Jamie → `inbox.md`'s
   `## FOR JAMIE`**, with what it blocks and the exact command if there is one.
   Say it in the closing message *as well* — but the file is what survives. A
   decision "reported and still nobody's" for three sessions running is the
   proof that a closing message is not a record.
6. Update the hub's Status line if the project's overall state changed.
7. **Now replace the CURRENT POSITION block.** Fill the fields from the work
   above and reference it — story link, inbox item slug, section name. Never
   append to the old block; replace it. If a fact has no owner yet, give it one
   in step 1–5 rather than parking the prose here. *This edit must never be
   skipped* — it is the only thing the next session reads to orient.
8. **Commit the vault and the repo separately, and stage an explicit pathspec —
   never `-A`, never `-a`.** `git add stories/README.md stories/61-foo.md
   inbox.md && git commit -m …`. Other lanes have edits in flight in the same
   vault; `git add -A` commits their half-written files under your message, and
   there is no signal that it happened. If `.git/index.lock` exists another lane
   is mid-commit — wait and retry; never delete the lock.

Then name what the next step is and suggest ending the session, and close with
the session-status line below. Record only what the next session cannot
cheaply rediscover — **not** file structure, what the code does, commit
history, or test names.

## Keep stories small

A story is loaded whole, so its size is a recurring cost. Target **under ~12 KB**
(~3,000 tokens). Past that it is usually two stories: say so with the number and
offer to split rather than silently appending.

The cap was 8 KB and 73 of `scheduling`'s 96 stories broke it — most shipped
fine at 10–14 KB, so the number was wrong, not the stories. 12 KB is set to
what a working story actually costs, which is the point: a cap nothing respects
buys nothing. The genuine outliers it still catches run 16–18 KB.

## Ending cleanly

When the story is updated, say so and suggest ending the session. Do not hold a
session open "in case" — that is the pattern this whole approach exists to avoid.
If Jamie steps away mid-task, write the half-finished state and where it stops
*before* going idle.

**Every response given under this skill ends with an explicit session-status
line** — not just the final one. Jamie should never have to infer it from
prose:

> **Session: done** — \<one clause: what's finished and why nothing is left
> to do\>
> **Session: not done** — \<one clause: what's still open — a step in
> progress, a question in [[inbox]] blocking the next action, verification
> not yet run\>

"Done" means: the current step's owner-writes are all committed (story log,
index, `ARCHITECTURE.md`/`docs/arch` if code-binding, `inbox.md`, position
block) and nothing is left mid-air — not that the whole project is finished.
A `needs-planning` session that stopped for Jamie's review, per the routing
table, is **done** with reason "stopped for review, as the step requires" —
that is the correct exit, not an open loop. Likewise, an `impl` session that
carried a story from `planned` through `verified` to `committed` — commit
pushed, CI left running — is **done** even though promote/smoke-check remain.
Those are the `committed` and `deployed` steps, routed to the `deploy` lane in
a separate session by design, and a queued story waiting on its batch is the
expected resting state, not an open loop (see "Deploying in batches"). Judge "done" against **this
session's lane and step**, never against the story's full lifecycle: don't
downgrade to "not done" just because a later step, owned by a different
lane, hasn't happened yet. Reserve **not done** for a session that is
mid-step with no owner written yet, or is waiting on an answer it hasn't
gotten.

## Migrating a repo into this layout

For a repo still carrying planning markdown — `mycreditcard.guru` is the one
left (`docs/PROJECT_STATUS.md`, ~21.5 KB); `scheduling` is done. Nine steps,
including what counts as code-binding and how to verify nothing was lost:

> **Read `~/.claude/skills/project-context/references/migrating.md`.**

Don't attempt a migration from memory — step 3 (are the locked decisions
actually built?) and step 8 (byte-for-byte verify) are the ones that get
skipped, and both are how content silently disappears.

