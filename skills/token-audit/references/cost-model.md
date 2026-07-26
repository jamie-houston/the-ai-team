# Cost model

Verified 2026-07-26 against the `claude-api` skill. Re-verify before quoting
figures in a report — pricing changes, and this file is a cache.

## Multipliers (structural — stable across models)

Relative to the model's base **input** price:

| Operation | Multiplier |
|---|---|
| Uncached input | 1.00x |
| Cache write, 5-minute TTL | 1.25x |
| Cache write, 1-hour TTL | 2.00x |
| Cache read | 0.10x |

Output tokens are priced separately (see table below).

## Per-model pricing, $ per 1M tokens

| Model | Input | Output |
|---|---|---|
| `claude-fable-5` | $10.00 | $50.00 |
| `claude-mythos-5` | $10.00 | $50.00 |
| `claude-opus-5` | $5.00 | $25.00 |
| `claude-opus-4-8` | $5.00 | $25.00 |
| `claude-opus-4-7` | $5.00 | $25.00 |
| `claude-opus-4-6` | $5.00 | $25.00 |
| `claude-sonnet-5` | $3.00 | $15.00 |
| `claude-sonnet-4-6` | $3.00 | $15.00 |
| `claude-haiku-4-5` | $1.00 | $5.00 |

`claude-sonnet-5` has introductory pricing of $2.00 / $10.00 through
2026-08-31. The analyzer uses list price, so it slightly over-estimates
Sonnet 5 spend during the intro window.

Fast mode on `claude-opus-5` is billed at $10 / $50 per MTok — the analyzer
does not detect it separately, so heavy fast-mode use is under-counted.

## Break-even arithmetic

Cache writes only pay off if enough reads follow.

- **5m TTL**: write 1.25x + one read 0.1x = 1.35x, versus 2.0x for two uncached
  passes. Breaks even at **2 requests**.
- **1h TTL**: write 2.0x + two reads 0.2x = 2.2x, versus 3.0x uncached. Breaks
  even at **3 requests**.

## TTL counterfactual, as implemented

For each API request, with `gap` = seconds since the previous request in that
session, and `p` = the model's input price per token:

```
premium_1h  += w1h_tokens * (2.00 - 1.25) * p          # every request
rescued_1h  += read_tokens * (1.25 - 0.10) * p         # only when 300 <= gap < 3600
net_waste    = premium_1h - rescued_1h
```

The rescue term is an **upper bound**: it assumes the entire cache-read prefix
at that request would have required full re-creation under a 5m TTL. In
practice partial-prefix reuse can reduce it. So a small net-waste figure should
not be treated as conclusive — say so in the report.

Requests with `gap >= 3600` are credited to neither side: both TTLs would have
expired, so the write happens regardless and the 1h premium on it is genuinely
wasted (captured in `premium_1h` with no offsetting rescue).

## Prompt-cache minimums

A prefix shorter than the model's minimum silently won't cache —
`cache_creation_input_tokens` comes back 0 with no error.

| Model | Minimum |
|---|---|
| Opus 5, Fable 5, Mythos 5 | 512 tokens |
| Opus 4.8, Sonnet 5, Sonnet 4.6 | 1024 tokens |
| Opus 4.7 | 2048 tokens |
| Opus 4.6, Haiku 4.5 | 4096 tokens |

Not monotonic across generations — worth checking before telling someone a
short prompt "should" be caching.

## Token estimation from bytes

Tool-payload sizes are measured in bytes and divided by 4 to estimate tokens.
This is a rough heuristic: accurate within ~15% for English prose, worse for
code, JSON, and non-English text (all of which tokenize denser). For an exact
count use `client.messages.count_tokens` — never `tiktoken`, which is OpenAI's
tokenizer and undercounts Claude tokens by 15-20%.
