---
name: now
description: Give Jamie a short task list that fits the time and device he has, drawn from his vault project backlogs and live Todoist, and mark items done. Use when Jamie types /now, or asks "what now", "what can I do in 20 minutes", "I have an hour on my laptop", "give me something to do from my phone"; and when, after such a list, he says "done 1 3" or "finished 2".
---

# /now — what fits the time I have

A thin wrapper over `what-now.py` on the Hermes container. The script owns
collecting, filtering, ranking and completing. This skill only translates what
Jamie says into arguments and prints the result. Don't re-rank, re-filter or add
items, and never edit the vault notes or Todoist yourself: `done` goes through
the script so the strike and the Activity-log line come out exactly once.

## Asking

Parse the request into two flags. Leave out any flag he didn't give:

- **Time** → `--minutes N`. "20m"/"20 minutes" → 20, "an hour" → 60,
  "afternoon" → 240.
- **Device** → `--device laptop|phone|out`. Laptop/computer/Mac → `laptop`,
  phone → `phone`, out/errands/driving → `out`. If he gives no device, use
  `laptop`, because he is in a Claude Code session.

```bash
ssh hermes@10.0.1.49 "python3 /home/hermes/.hermes/scripts/what-now.py --minutes 20 --device laptop --json"
```

The output is JSON: `{minutes, device, untagged, items: [{n, id, title, context,
minutes, priority, due, note, area, source}]}`. Print it as a numbered list in
`n` order, one line per item:

```
1. Pay HELOC — 10m · @computer · p2 · due 2026-10-20 · Todoist/financial
2. Ohio 529 rollover — 30m · @computer · p1 · Financial Picture 2026
```

Where an item lives: `note` if it has one, otherwise `Todoist/<area>`. Below the
list, give the total minutes. If `untagged` > 0, add one line saying that many
backlog items have no tags yet, so they weren't considered. If a Todoist read
failure comes back on stderr, say the list is backlog-only. An empty list is a
valid answer. Say so in one line.

Keep the `n` → `id` mapping from this output. "done 1 3" refers to it.

## Completing

"done 1 3" → look up the ids from the most recent list in this conversation and
run:

```bash
ssh hermes@10.0.1.49 "python3 /home/hermes/.hermes/scripts/what-now.py done <id1> <id2>"
```

Relay each output line as is. A `t…` id closes the Todoist task (the 06:00
sweep logs it). A `b…` id strikes the backlog line and logs it. If there is no
list in this conversation yet, or a number isn't on it, ask. Don't guess an id.
"no open backlog item" means the line was already done or edited since the list
was printed. Say so and offer to re-run the list.
