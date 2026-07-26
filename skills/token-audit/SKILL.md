---
name: token-audit
description: Audit Claude Code token usage and produce concrete cost-reduction recommendations. Combines ccusage billing totals with a deep analysis of ~/.claude/projects transcripts — cache TTL efficiency (5m vs 1h counterfactual), context bloat, always-on system-prompt tax from installed skills/agents/commands, skill and subagent ROI, oversized tool payloads, redundant file re-reads, and model mix. Use when the user asks why their token usage or Claude bill is high, wants to reduce token spend, asks about prompt-cache efficiency or TTL settings, wants to know which skills/agents/plugins are worth their cost, or asks for a usage/cost report.
---

# Token Audit

Find where tokens are actually going and recommend specific, evidence-backed cuts.

Two data sources, deliberately: **ccusage** for billing-authoritative totals, and
`scripts/analyze.py` for the diagnostic breakdown ccusage doesn't do (TTL
counterfactuals, per-skill ROI, tool payload attribution, re-read detection).

## Run it

```bash
# 1. Billing-authoritative totals (no install needed)
cd /tmp && npx -y ccusage@latest daily --json
cd /tmp && npx -y ccusage@latest session --json   # per-session, finds the expensive ones

# 2. Diagnostic analysis
python3 ~/.claude/skills/token-audit/scripts/analyze.py
python3 ~/.claude/skills/token-audit/scripts/analyze.py --days 30    # recent only
python3 ~/.claude/skills/token-audit/scripts/analyze.py --json       # machine-readable
```

Run both. If the user named a time window, pass `--days N` and `--since` to
ccusage so the two agree on scope.

**The two cost figures will differ, typically by 5-10%.** ccusage is the number
to quote for "what did I spend." The analyzer's figure applies the documented
1-hour cache-write premium (2.0x vs 1.25x) explicitly, which is precisely what
makes its TTL section possible. Report ccusage's total; use the analyzer for
*where* it went. If they diverge by more than ~15%, say so rather than
silently picking one.

## What each section means, and what to do about it

### 1. Cache TTL (5m vs 1h)
The analyzer computes both sides of the trade rather than assuming:

- **premium paid** — extra cost of 1h writes over 5m writes (0.75x per token)
- **re-creation avoided** — prefix re-writes the 1h TTL prevented, counted only
  on requests whose gap since the previous request fell in the 5m–1h band,
  where a 5m entry would already be dead

Net positive means the 1h TTL is losing money; net negative means it's earning
its keep. **Do not recommend switching TTL based on the gap histogram alone** —
a 96%-under-5m distribution still favours 1h if the few long gaps land on large
prefixes, which is the common case for long sessions.

Be honest about the lever: TTL is chosen by the harness, not a documented user
setting. What the user controls is session shape — tight bursts, and ending
sessions rather than parking them idle mid-task. Don't invent a config flag.

### 2. Context size per request
Median and p95 cached-prefix size, plus compaction count. This contextualizes
everything else: if the median prefix is 100K+, the system-prompt inventory is
a rounding error and tool output is the real story. Point the user at whichever
section actually dominates *their* numbers.

### 3. Always-on system prompt tax
Every agent and skill **description** is injected into every session, whether or
not it's ever used. Agent definitions with long `description:` blocks full of
`<example>` tags are the usual culprit — a few dozen of those is thousands of
tokens per session, charged as a cache write then re-read on every subsequent
request.

Recommend: trim verbose agent descriptions (the examples belong in the body, not
the frontmatter description), and remove agents for stacks the user doesn't work
in.

### 4. Skill & agent ROI
Invocation counts against footprint. Three findings:

- **Never-invoked user/plugin skills** — description tax with zero return.
  Actionable: uninstall the plugin, or move the skill out of `~/.claude/skills`.
- **Heavy skill bodies** — large `SKILL.md` files, cost paid per invocation.
  A 10K-token skill invoked twice is fine; invoked 200 times it deserves a diet.
- **Subagent spawns** — each starts cold and re-derives context. High counts of
  exploratory agents where a `Grep` would do is real waste.

Bundled skills ship with the CLI, extract to ephemeral temp dirs, and can't be
removed — the script marks them and doesn't recommend action on them. Don't
tell the user to delete something they can't delete.

### 5. Tool payload waste
Per-tool result bytes (→ tokens at 4 chars/token), plus three specific patterns:

- **Files re-read in one session** — usually re-reading a file just edited.
  Unnecessary: `Edit` errors if it fails, and the harness tracks file state.
  This is the single most common avoidable pattern; a CLAUDE.md line fixes it.
- **Full `Write` after a `Read`** — a targeted `Edit` would have cost a fraction.
- **Oversized `Bash` / `Read` payloads** — recommend `head`/`wc`/`jq` pipes and
  `offset`/`limit` or `Grep` respectively.

### 6. Model mix
Cost share per model. Only recommend a cheaper model where the work genuinely
doesn't need the stronger one — this is the user's call, so present the split
and the tradeoff rather than prescribing a downgrade.

## Writing the recommendations

Rank by **dollars, not by how easy the finding was to compute.** A 400-token
description trim is not worth mentioning next to 369 redundant file reads.

For each recommendation give: the finding, the estimated saving, and the exact
change. Prefer changes the user makes once — a CLAUDE.md line, an uninstalled
plugin, a trimmed frontmatter block — over behavioural intentions.

State assumptions plainly: token estimates from byte counts are ~4 chars/token
and approximate; the TTL counterfactual assumes cache-read tokens at a given
request would have needed full re-creation under a 5m TTL, which is an upper
bound on the rescue value.

If a section shows nothing worth acting on, say so and move on. A short report
naming two real problems beats a long one padded with non-findings.

See `references/cost-model.md` for the pricing table and multiplier arithmetic.
