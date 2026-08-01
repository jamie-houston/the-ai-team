---
name: project-context
description: Load and update project context from Jamie's Obsidian vault instead of from markdown in the repo, so sessions stay short and repos stay lean. Use when Jamie says "work on the next phase", "what's next", "pick up where we left off", "what was I working on", or names a story file; when finishing a step that needs its status written back; or when a repo is carrying planning markdown that should be migrated out to the vault.
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
  stories/README.md        # index + status table + ground rules
  stories/NN-<slug>.md     # one unit of work, self-contained
  roadmap-phases.md        # the plan
  prd.md, progress.md      # requirements, history
  archive/                 # design handoffs, dead ends
```

In the repo: `CLAUDE.md`, `README.md`, `ARCHITECTURE.md` (binding constraints
only), and operational runbooks like `docs/DEPLOY.md`. Nothing else.

## Starting work — "work on the next phase"

**Always read `stories/README.md` first.** It is small on purpose and its
**CURRENT POSITION** block states the phase, the step, and any blocker. Never
scan `roadmap-phases.md` to work out what's next; that is a 63 KB read the index
exists to prevent.

Then verify rather than trust — the index records intent at last write, and the
tree may have moved. `git log --oneline -5` and `git status` is enough. **If the
index contradicts the repo, the repo wins**: say so, fix the index, then proceed.

Route on the **step**, and do exactly one step per session unless Jamie says
otherwise:

| Step | Do this |
|---|---|
| `needs-decision` | Two or more candidates and no obvious winner. **Present them with sizes and tradeoffs and ask Jamie to pick** — do not choose silently. Then update the position to the chosen work's real step and re-route. |
| `needs-planning` | Read **only** the source the index points at — a `## Phase N` section if the project has a phase roadmap (grep the heading, read to the next `## `), otherwise the relevant row of the index's "open work not yet storied" table. Write it up as the next numbered story, at the depth of the project's existing shipped stories. Then **stop and let Jamie review** — do not plan and implement in one session. |
| `planned` | Read the story. Confirm scope with Jamie, then implement. |
| `in-progress` | Read the story's session log for where it stopped. Resume there. |
| `verified` | Commit. |
| `committed` | Deploy / promote per the project's own runbook. |
| `deployed` | Smoke-check, then mark `done` and report what the next work is. |

Projects differ in shape. `scheduling` has a phase roadmap (`roadmap-phases.md`,
`## Phase N` sections) so its unstoried work comes from there. `mycreditcard.guru`
has no roadmap — its lettered phases are all done and remaining work is listed in
the index's own table. **Read the index and follow what it points at**; don't
assume a file exists because another project has one.

Confirm the routing in one line before acting — *"Phase 0 is `needs-planning`;
I'll write story 08 from the roadmap section and stop for your review"* — so
Jamie can redirect before any tokens go into the wrong step.

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
  questions are waiting on you."* Then give the one-line gist of each and let
  Jamie choose whether to answer now or defer. Do not re-explain them at length.
- **Anything you would have put in a closing message that needs an answer goes
  in that section instead** — appended at the bottom of it, with what it blocks.
  A question that blocks nothing stays in the closing message and dies there.
- **On an answer, delete the item** and write the answer where it binds (the
  story, the index, or the repo's `ARCHITECTURE.md`). An answer that exists only
  in a transcript is lost.
- **Cap is 7.** At the cap, resolve or downgrade one before adding. Items that
  will sit for weeks are backlog, not questions — move them to the index's
  "Needs Jamie, not code" / "Needs a decision, not a test" sections.
- Genuinely *blocking* questions still use `AskUserQuestion` mid-session. The
  list is for what can wait a session or two.
- **When the item is an action Jamie can just run, give the exact command(s),
  not a paragraph explaining the situation.** A sentence of *why* is fine
  above them, but the thing Jamie reads last must be copy-pasteable — not a
  decision he has to turn back into a command himself. Wrong: explaining that
  `db:reset-demo` needs a password and describing what it does. Right:

  ```bash
  export $(grep -v '^#' .env.staging | xargs)
  export SEED_DEMO_PASSWORD='<pick one, write it down>'
  npm run db:reset-demo
  ```

  If the action only makes sense with a value only Jamie has (a password, a
  yes/no on scope), say so in one clause and leave a placeholder in the
  command — don't hold the whole command back pending an answer. This applies
  in both places: the `inbox.md` item text and the session's closing message.

### Which model for this step

Recommend a model alongside the routing line — the step already tells you the
kind of work, so the model follows for free:

| Step | Model | Why |
|---|---|---|
| `needs-decision`, `needs-planning` | Opus (or Fable for open-ended exploration) | Judgment-heavy: weighing tradeoffs, writing a story from scratch. |
| `planned`, `in-progress` (real implementation) | Opus | Multi-file changes benefit from stronger reasoning. |
| `verified` → commit, `committed` → deploy/watch CI, `deployed` → smoke-check | Sonnet | Mechanical or supervisory — running commands and reading output, not deciding anything. |

Say it as part of the one-line routing confirmation, e.g. *"`committed` — I'll
push and watch CI; Sonnet is enough for this one."*

If the recommended model differs from the model currently active, **stop and
wait** for Jamie to switch (`/model`) or explicitly say to proceed anyway —
don't just note the mismatch and continue on the wrong model.

### Don't read what you don't need

- One-off task in the repo, no phase work: `CLAUDE.md` + `ARCHITECTURE.md` only.
  Do not open the vault at all.
- Implementing a story: that story + `CLAUDE.md` + `ARCHITECTURE.md`.
- `progress.md` and `prd.md` are history and requirements — read them only when
  the story points at a specific section, and never whole.

## Finishing a step

Do this **every time a step completes**, including when Jamie stops mid-step —
in that case record where it stopped, which is the part that makes resuming cheap.

1. **Update the CURRENT POSITION block** in `stories/README.md`: phase, step,
   blocker, date. *This edit must never be skipped* — it is the only thing the
   next session reads to orient, so skipping it silently breaks the workflow.
2. Update the phase table's Step column to match.
3. Tick the story's checklist; append to its session log — what shipped, what was
   deliberately left, and where it stops if unfinished.
4. **Does any decision bind the code?** It also belongs in the repo's
   `ARCHITECTURE.md`. A constraint that lives only in the vault is invisible
   during a one-off task, which is the exact failure this layout prevents.
5. Update the hub's Status line if the project's overall state changed.
6. **Anything you are about to raise in the closing message that needs an
   answer or an action from Jamie goes in `inbox.md`'s `## FOR JAMIE` section**,
   with what it blocks. Say it in the closing message *as well* — but the file
   is what survives. A decision that has been "reported and still nobody's" for
   three sessions running is the proof that a closing message is not a record.
7. Commit the vault and the repo separately.

Then say the step is done, name what the next step is, and suggest ending the
session. Record only what the next session cannot cheaply rediscover — **not**
file structure, what the code does, commit history, or test names.

## Keep stories small

A story is loaded whole, so its size is a recurring cost. Target **under 2,000
tokens** (~8KB). When one grows past that it is usually two stories. If Jamie's
file is already well over, say so with the number and offer to split it rather
than silently appending.

## Ending cleanly

When the story is updated, say so and suggest ending the session. Do not hold a
session open "in case" — that is the pattern this whole approach exists to avoid.
If Jamie steps away mid-task, write the half-finished state and where it stops
*before* going idle.

## Migrating a repo into this layout

For a repo still carrying planning markdown. `scheduling` is done;
`mycreditcard.guru` is not (its `docs/PROJECT_STATUS.md` is ~21.5KB).

1. **Inventory.** `find . -name '*.md' -not -path './node_modules/*' -exec wc -c {} \; | sort -rn`
2. **Find what binds code**, and separate it from planning. Business rules,
   invariants, non-obvious behavior, and locked architecture decisions stay — in
   a new `ARCHITECTURE.md`. Phase plans, status, and history move.
3. **Check whether the decisions are actually built.** Locked-but-unimplemented
   decisions must be labelled as such, or a future session hunts for models that
   do not exist. Read the schema and migration list, don't assume.
4. **Mine the history log for spec.** A "decisions log" usually holds real
   constraints mixed with narrative. The constraints are binding; extract them.
5. **`mv` to the vault** — `git mv` fails across repository boundaries. Then
   `git add -A` in the repo and commit the deletions.
6. **Rewrite `CLAUDE.md`**: drop the moved pointers, add "planning docs live in
   Obsidian; Jamie names the story file", point at `ARCHITECTURE.md`. Skipping
   this leaves dangling pointers and is the whole reason the move works.
7. **Grep wider than markdown.** Source comments, README links, and CI configs
   reference doc paths too:
   `grep -rn 'docs/PROGRESS\|docs/PRD\|docs/ROADMAP\|docs/backlog' --include='*.md' --include='*.ts' --include='*.tsx' --include='*.json' --include='*.yml' .`
8. **Verify byte-for-byte** that nothing was lost:
   `diff <(git show HEAD~1:docs/OLD.md) vault/new.md` — expect only the link
   edits you made deliberately.
9. Run the repo's verification bar before committing, even if the changes look
   like comments only.
