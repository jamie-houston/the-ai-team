#!/usr/bin/env python3
"""Analyze Claude Code transcripts for token-waste patterns.

Reads ~/.claude/projects/**/*.jsonl plus the local skill/agent/command
inventory, and emits findings with dollar estimates.

Usage:
    python3 analyze.py [--days N] [--json] [--projects-dir PATH]

Cost model constants (structural, stable across models):
    uncached input = 1.00x base input price
    5m cache write = 1.25x
    1h cache write = 2.00x
    cache read     = 0.10x
"""

from __future__ import annotations

import argparse
import collections
import datetime as dt
import glob
import json
import os
import re
import sys

W5M, W1H, READ = 1.25, 2.00, 0.10

# $ per 1M tokens (input, output). Verified 2026-07-26.
PRICING = {
    "claude-fable-5": (10.0, 50.0),
    "claude-mythos-5": (10.0, 50.0),
    "claude-opus-5": (5.0, 25.0),
    "claude-opus-4-8": (5.0, 25.0),
    "claude-opus-4-7": (5.0, 25.0),
    "claude-opus-4-6": (5.0, 25.0),
    "claude-opus-4-5": (5.0, 25.0),
    "claude-sonnet-5": (3.0, 15.0),
    "claude-sonnet-4-6": (3.0, 15.0),
    "claude-sonnet-4-5": (3.0, 15.0),
    "claude-haiku-4-5": (1.0, 5.0),
}
DEFAULT_PRICE = (5.0, 25.0)


def price_for(model: str) -> tuple[float, float]:
    if not model:
        return DEFAULT_PRICE
    if model in PRICING:
        return PRICING[model]
    base = re.sub(r"-\d{8}$", "", model)  # strip date suffix
    return PRICING.get(base, DEFAULT_PRICE)


def parse_ts(value):
    if not value:
        return None
    try:
        return dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def tokens(usage: dict) -> dict:
    cc = usage.get("cache_creation") or {}
    return {
        "in": usage.get("input_tokens", 0) or 0,
        "out": usage.get("output_tokens", 0) or 0,
        "read": usage.get("cache_read_input_tokens", 0) or 0,
        "w1h": cc.get("ephemeral_1h_input_tokens", 0) or 0,
        "w5m": cc.get("ephemeral_5m_input_tokens", 0) or 0,
    }


class Analysis:
    def __init__(self, projects_dir: str, since: dt.datetime | None):
        self.projects_dir = projects_dir
        self.since = since
        self.sessions = 0
        self.requests = 0
        self.model_tok = collections.defaultdict(
            lambda: dict(w1h=0, w5m=0, read=0, **{"in": 0, "out": 0})
        )
        # TTL counterfactual accumulators, in dollars
        self.ttl_1h_premium = 0.0       # what the 1h TTL cost above 5m
        self.ttl_1h_rescued = 0.0       # re-creation the 1h TTL avoided
        self.gap_buckets = collections.Counter()
        self.context_p = []             # per-request cached prefix size
        self.tool_calls = collections.Counter()
        self.skill_invocations = collections.Counter()
        self.agent_spawns = collections.Counter()
        self.result_bytes = collections.defaultdict(int)
        self.result_counts = collections.Counter()
        self.big_bash = []
        self.big_reads = []
        self.reread = collections.Counter()   # (session, path) -> extra reads
        self.reread_examples = collections.Counter()
        self.write_after_read = collections.Counter()
        self.compactions = 0

    # ---------------- ingest ----------------

    def run(self):
        files = sorted(glob.glob(os.path.join(self.projects_dir, "**", "*.jsonl"),
                                 recursive=True))
        for path in files:
            self.session(path)
        return self

    def session(self, path: str):
        recs = []
        for line in open(path, errors="ignore"):
            line = line.strip()
            if not line:
                continue
            try:
                recs.append(json.loads(line))
            except json.JSONDecodeError:
                continue
        if not recs:
            return

        assistants = [r for r in recs if r.get("type") == "assistant"
                      and isinstance(r.get("message"), dict)]
        if self.since:
            keep = [r for r in assistants
                    if (t := parse_ts(r.get("timestamp"))) and t >= self.since]
            if not keep:
                return
            assistants = keep
        if not assistants:
            return

        self.sessions += 1
        sid = os.path.basename(path)

        # One entry per API request (dedupe retries sharing a requestId).
        seen_req = set()
        timeline = []
        for r in assistants:
            rid = r.get("requestId")
            if rid and rid in seen_req:
                continue
            if rid:
                seen_req.add(rid)
            timeline.append(r)

        prev_ts = None
        for r in timeline:
            self.requests += 1
            msg = r["message"]
            model = msg.get("model") or ""
            tk = tokens(msg.get("usage") or {})
            bucket = self.model_tok[model]
            for k, v in tk.items():
                bucket[k] += v

            prefix = tk["read"] + tk["w1h"] + tk["w5m"] + tk["in"]
            if prefix:
                self.context_p.append(prefix)

            ts = parse_ts(r.get("timestamp"))
            gap = (ts - prev_ts).total_seconds() if (ts and prev_ts) else None
            if prev_ts is not None and gap is not None:
                if gap < 300:
                    self.gap_buckets["<5m"] += 1
                elif gap < 3600:
                    self.gap_buckets["5m-1h"] += 1
                else:
                    self.gap_buckets[">1h"] += 1
            if ts:
                prev_ts = ts

            in_price = price_for(model)[0] / 1_000_000
            # Premium paid for choosing 1h over 5m on this request's writes.
            self.ttl_1h_premium += tk["w1h"] * (W1H - W5M) * in_price
            # Where a 5m cache would already be dead, the 1h TTL saved us
            # re-creating the whole prefix we instead read cheaply.
            if gap is not None and 300 <= gap < 3600:
                self.ttl_1h_rescued += tk["read"] * (W5M - READ) * in_price

        self.tools(recs, sid)

    def tools(self, recs, sid: str):
        idmap = {}
        read_paths = set()
        for r in recs:
            typ = r.get("type")
            if typ == "assistant" and isinstance(r.get("message"), dict):
                for c in r["message"].get("content") or []:
                    if not isinstance(c, dict):
                        continue
                    if c.get("type") == "tool_use":
                        name = c.get("name", "?")
                        inp = c.get("input") or {}
                        idmap[c.get("id")] = (name, inp)
                        self.tool_calls[name] += 1
                        if name == "Skill":
                            self.skill_invocations[str(inp.get("skill"))] += 1
                        elif name == "Agent":
                            self.agent_spawns[
                                str(inp.get("subagent_type") or "general-purpose")] += 1
                        elif name == "Read":
                            p = inp.get("file_path")
                            if p:
                                key = (sid, p)
                                if key in read_paths:
                                    self.reread[key] += 1
                                    self.reread_examples[p] += 1
                                read_paths.add(key)
                        elif name == "Write":
                            p = inp.get("file_path")
                            if p and (sid, p) in read_paths:
                                self.write_after_read[p] += 1
            elif typ == "user":
                msg = r.get("message") or {}
                content = msg.get("content")
                if isinstance(content, str) and "compact" in content[:200].lower():
                    self.compactions += 1
                if not isinstance(content, list):
                    continue
                for c in content:
                    if not isinstance(c, dict) or c.get("type") != "tool_result":
                        continue
                    name, inp = idmap.get(c.get("tool_use_id"), ("?", {}))
                    size = len(json.dumps(c.get("content", ""), default=str))
                    self.result_bytes[name] += size
                    self.result_counts[name] += 1
                    if name == "Bash" and size > 20000:
                        self.big_bash.append(
                            (size, str(inp.get("command", ""))[:100]))
                    elif name == "Read" and size > 40000:
                        self.big_reads.append(
                            (size, str(inp.get("file_path", ""))[:100]))

    # ---------------- derived ----------------

    def spend(self):
        out = {}
        for model, t in self.model_tok.items():
            pin, pout = price_for(model)
            cost = (
                t["in"] * 1.0 * pin
                + t["w5m"] * W5M * pin
                + t["w1h"] * W1H * pin
                + t["read"] * READ * pin
                + t["out"] * pout
            ) / 1_000_000
            out[model] = {"tokens": dict(t), "cost": cost}
        return out

    def totals(self):
        agg = collections.Counter()
        for t in self.model_tok.values():
            agg.update(t)
        return dict(agg)


# ---------------- inventory (always-on system-prompt tax) ----------------

def frontmatter_description(text: str) -> str:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return ""
    fm = m.group(1)
    d = re.search(r"^description:\s*(.*?)(?=\n[a-zA-Z_-]+:\s|\Z)", fm, re.S | re.M)
    return (d.group(1) if d else "").strip()


def inventory(home: str):
    """Size the content injected into every session's system prompt."""
    inv = {"agents": [], "skills": [], "commands": []}

    for f in glob.glob(os.path.join(home, "agents", "**", "*.md"), recursive=True):
        try:
            desc = frontmatter_description(open(f, errors="ignore").read())
        except OSError:
            continue
        if desc:
            inv["agents"].append({"name": os.path.basename(f)[:-3],
                                  "desc_chars": len(desc)})

    # User skills, plugin skills, and bundled skills all cost tokens when loaded.
    # Bundled skills ship with the CLI, extract to ephemeral temp dirs, and
    # can't be removed — only user and plugin skills are actionable.
    skill_globs = [
        os.path.join(home, "skills", "**", "SKILL.md"),
        os.path.join(home, "plugins", "**", "SKILL.md"),
    ]
    seen_skills = set()
    for pattern in skill_globs:
        for f in glob.glob(pattern, recursive=True):
            name = os.path.basename(os.path.dirname(f))
            if name in seen_skills:
                continue
            seen_skills.add(name)
            _add_skill(inv, f)

    for f in glob.glob(os.path.join(home, "commands", "*.md")):
        try:
            inv["commands"].append({"name": os.path.basename(f)[:-3],
                                    "chars": os.path.getsize(f)})
        except OSError:
            continue
    return inv


def _add_skill(inv: dict, f: str):
    try:
        text = open(f, errors="ignore").read()
    except OSError:
        return
    d = os.path.dirname(f)
    body = sum(os.path.getsize(x) for x in
               glob.glob(os.path.join(d, "**", "*"), recursive=True)
               if os.path.isfile(x))
    inv["skills"].append({
        "name": os.path.basename(d),
        "desc_chars": len(frontmatter_description(text)),
        "skill_md_chars": len(text),
        "bundle_bytes": body,
        "user_installed": "/.claude/skills/" in f,
    })


# ---------------- report ----------------

def fmt_tok(n: float) -> str:
    for unit, div in (("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if abs(n) >= div:
            return f"{n / div:.2f}{unit}"
    return str(int(n))


def report(a: Analysis, inv: dict, window: str) -> str:
    L = []
    p = L.append
    spend = a.spend()
    total_cost = sum(v["cost"] for v in spend.values())
    t = a.totals()

    p("=" * 72)
    p(f"CLAUDE CODE TOKEN AUDIT  ({window})")
    p("=" * 72)
    p(f"sessions={a.sessions}  api_requests={a.requests}  "
      f"est_spend=${total_cost:,.2f}")
    p(f"tokens: cache_read={fmt_tok(t.get('read', 0))} "
      f"write_1h={fmt_tok(t.get('w1h', 0))} write_5m={fmt_tok(t.get('w5m', 0))} "
      f"uncached_in={fmt_tok(t.get('in', 0))} out={fmt_tok(t.get('out', 0))}")

    written = t.get("w1h", 0) + t.get("w5m", 0)
    if written:
        p(f"cache read:write ratio = {t.get('read', 0) / written:.1f}:1 "
          f"({'healthy' if t.get('read', 0) / written > 5 else 'LOW — prefix churn'})")

    # --- 1. TTL ---
    p("")
    p("-" * 72)
    p("1. CACHE TTL (5m vs 1h)")
    p("-" * 72)
    gb = a.gap_buckets
    tot_gaps = sum(gb.values()) or 1
    p(f"  turn gaps: <5m={gb['<5m']} ({gb['<5m']/tot_gaps:.1%})  "
      f"5m-1h={gb['5m-1h']} ({gb['5m-1h']/tot_gaps:.1%})  "
      f">1h={gb['>1h']} ({gb['>1h']/tot_gaps:.1%})")
    p(f"  premium paid for 1h TTL over 5m : ${a.ttl_1h_premium:,.2f}")
    p(f"  re-creation the 1h TTL avoided  : ${a.ttl_1h_rescued:,.2f}")
    net = a.ttl_1h_premium - a.ttl_1h_rescued
    if net > 0:
        share = f" ({net / total_cost:.1%} of spend)" if total_cost else ""
        p(f"  >> NET WASTE from 1h TTL: ${net:,.2f}{share}")
        p("     Gaps are mostly under 5 minutes, so the 1h TTL's 2.0x write")
        p("     premium rarely buys anything. Levers: keep bursts tight, and")
        p("     end sessions rather than parking them idle mid-task.")
    else:
        p(f"  >> 1h TTL is PAYING OFF: net ${-net:,.2f} saved. Leave it alone.")
        p(f"     The {gb['5m-1h']} gaps in the 5m-1h band are where it earns its")
        p("     keep — each one would otherwise re-create the whole prefix.")

    # --- 2. context size ---
    p("")
    p("-" * 72)
    p("2. CONTEXT SIZE PER REQUEST")
    p("-" * 72)
    if a.context_p:
        s = sorted(a.context_p)
        med = s[len(s) // 2]
        p95 = s[int(len(s) * 0.95)]
        p(f"  median={fmt_tok(med)}  p95={fmt_tok(p95)}  max={fmt_tok(s[-1])}")
        p(f"  compaction events observed: {a.compactions}")
        self_fixed = (sum(x["desc_chars"] for x in inv["agents"])
                      + sum(x["desc_chars"] for x in inv["skills"])) // 4
        if med:
            p(f"  fixed inventory tax is ~{self_fixed / med:.1%} of the median prefix "
              f"— the rest is conversation + tool output.")
        if med > 100000:
            p("  >> Median prefix exceeds 100K. At this size the dominant cost is")
            p("     accumulated tool output, not the system prompt. Section 5 is")
            p("     where the money is; trimming inventory is secondary.")
    else:
        p("  no usage data")

    # --- 3. always-on tax ---
    p("")
    p("-" * 72)
    p("3. ALWAYS-ON SYSTEM PROMPT TAX (paid every session)")
    p("-" * 72)
    agent_chars = sum(x["desc_chars"] for x in inv["agents"])
    skill_chars = sum(x["desc_chars"] for x in inv["skills"])
    p(f"  {len(inv['agents'])} agent descriptions : {agent_chars:,} chars "
      f"(~{agent_chars // 4:,} tokens)")
    p(f"  {len(inv['skills'])} skill descriptions : {skill_chars:,} chars "
      f"(~{skill_chars // 4:,} tokens)")
    p(f"  {len(inv['commands'])} commands installed")
    fixed = (agent_chars + skill_chars) // 4
    if a.sessions and fixed:
        # Charged once as a cache write, then re-read on each later request.
        rate = 5.0 / 1_000_000
        cost = a.sessions * fixed * W1H * rate
        reread = max(a.requests - a.sessions, 0) * fixed * READ * rate
        p(f"  >> ~{fixed:,} tokens injected into every session")
        p(f"     ≈ ${cost + reread:,.2f} over this window "
          f"(writes ${cost:,.2f} + re-reads ${reread:,.2f}, at Opus rates)")
    top = sorted(inv["agents"], key=lambda x: -x["desc_chars"])[:8]
    if top:
        p("  fattest agent descriptions:")
        for x in top:
            p(f"     {x['desc_chars']:6,} chars (~{x['desc_chars']//4:5,} tok)  "
              f"{x['name']}")

    # --- 4. skill/agent ROI ---
    p("")
    p("-" * 72)
    p("4. SKILL & AGENT ROI  (footprint vs. actual use)")
    p("-" * 72)
    used = a.skill_invocations
    by_name = {s["name"]: s for s in inv["skills"]}
    cmd_by_name = {c["name"]: c for c in inv["commands"]}
    p(f"  skills invoked in window: {sum(used.values())} calls "
      f"across {len(used)} distinct skills")
    for name, n in used.most_common(12):
        if name in by_name:
            load = f"{by_name[name]['skill_md_chars']//4:,} tok/load"
        elif name in cmd_by_name:
            load = f"{cmd_by_name[name]['chars']//4:,} tok/load (command)"
        else:
            load = "(bundled — size not on disk)"
        p(f"     {n:4}x  {name:30} {load}")

    never = [s for s in inv["skills"] if s["name"] not in used]
    if never:
        waste = sum(s["desc_chars"] for s in never) // 4
        p("")
        p(f"  {len(never)} user/plugin skills never invoked "
          f"— ~{waste:,} tokens/session of description tax you could reclaim:")
        for s in sorted(never, key=lambda x: -x["desc_chars"])[:10]:
            origin = "user" if s["user_installed"] else "plugin"
            p(f"     {s['desc_chars']:5,} chars  {s['name']:34} ({origin})")
        p("     Uninstall unused plugins; move rarely-used personal skills out")
        p("     of ~/.claude/skills. Descriptions load every session even when")
        p("     the skill body never does.")

    # Skills whose bundle is heavy relative to how often they earn their keep.
    heavy = [(s, used.get(s["name"], 0)) for s in inv["skills"]
             if s["skill_md_chars"] > 8000]
    if heavy:
        p("")
        p("  Heavy skill bodies (cost paid on each invocation):")
        for s, n in sorted(heavy, key=lambda kv: -kv[0]["skill_md_chars"])[:8]:
            p(f"     {s['skill_md_chars']//4:6,} tok  {s['name']:30} "
              f"invoked {n}x")
    if a.agent_spawns:
        p("")
        p(f"  subagent spawns: {sum(a.agent_spawns.values())}")
        for name, n in a.agent_spawns.most_common(6):
            p(f"     {n:4}x  {name}")
        p("     Each spawn starts cold and re-derives context. If any of these")
        p("     answered a question you could have grepped, that's pure overhead.")

    # --- 5. tool payload waste ---
    p("")
    p("-" * 72)
    p("5. TOOL PAYLOAD WASTE (tokens pulled into context)")
    p("-" * 72)
    p(f"  {'tool':<18}{'calls':>7}{'total':>12}{'avg':>10}")
    for name, b in sorted(a.result_bytes.items(), key=lambda kv: -kv[1])[:10]:
        n = a.result_counts[name] or 1
        p(f"  {name:<18}{n:>7}{fmt_tok(b/4):>12}{fmt_tok(b/4/n):>10}")
    p("  (tokens estimated at 4 chars/token)")

    rr = [(v, k) for k, v in a.reread_examples.items() if v >= 2]
    if rr:
        p("")
        p(f"  Files re-read within one session ({len(a.reread)} occurrences):")
        for n, path in sorted(rr, reverse=True)[:8]:
            p(f"     {n:3} extra reads  {path}")
        p("     Re-reading a file you just edited is never necessary — Edit")
        p("     errors if it fails, and the harness tracks file state.")
    if a.write_after_read:
        p("")
        p("  Full Write after a Read (Edit would have been cheaper):")
        for path, n in a.write_after_read.most_common(6):
            p(f"     {n:3}x  {path}")
    if a.big_bash:
        p("")
        p("  Largest Bash outputs (pipe through head/wc/jq):")
        for size, cmd in sorted(a.big_bash, reverse=True)[:6]:
            p(f"     ~{fmt_tok(size/4):>7} tok  {cmd}")
    if a.big_reads:
        p("")
        p("  Largest single Read calls (use offset/limit or Grep):")
        for size, path in sorted(a.big_reads, reverse=True)[:6]:
            p(f"     ~{fmt_tok(size/4):>7} tok  {path}")

    # --- 6. model mix ---
    p("")
    p("-" * 72)
    p("6. MODEL MIX")
    p("-" * 72)
    p(f"  {'model':<28}{'cost':>11}{'share':>8}{'out tok':>11}")
    for model, v in sorted(spend.items(), key=lambda kv: -kv[1]["cost"]):
        share = v["cost"] / total_cost if total_cost else 0
        p(f"  {(model or '(unknown)'):<28}${v['cost']:>10,.2f}{share:>8.1%}"
          f"{fmt_tok(v['tokens']['out']):>11}")

    p("")
    p("=" * 72)
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=0,
                    help="only analyze the last N days (0 = all)")
    ap.add_argument("--json", action="store_true", help="emit raw JSON")
    ap.add_argument("--projects-dir",
                    default=os.path.expanduser("~/.claude/projects"))
    ap.add_argument("--home", default=os.path.expanduser("~/.claude"))
    args = ap.parse_args()

    if not os.path.isdir(args.projects_dir):
        print(f"no transcripts at {args.projects_dir}", file=sys.stderr)
        return 1

    since = None
    window = "all history"
    if args.days > 0:
        since = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=args.days)
        window = f"last {args.days} days"

    a = Analysis(args.projects_dir, since).run()
    inv = inventory(args.home)

    if args.json:
        print(json.dumps({
            "window": window,
            "sessions": a.sessions,
            "requests": a.requests,
            "spend_by_model": a.spend(),
            "totals": a.totals(),
            "ttl": {
                "premium_1h": a.ttl_1h_premium,
                "rescued_1h": a.ttl_1h_rescued,
                "net_waste": a.ttl_1h_premium - a.ttl_1h_rescued,
                "gap_buckets": dict(a.gap_buckets),
            },
            "tool_calls": dict(a.tool_calls),
            "skill_invocations": dict(a.skill_invocations),
            "agent_spawns": dict(a.agent_spawns),
            "result_bytes": dict(a.result_bytes),
            "rereads": a.reread_examples.most_common(20),
            "write_after_read": a.write_after_read.most_common(20),
            "inventory": inv,
        }, indent=2, default=str))
    else:
        print(report(a, inv, window))
    return 0


if __name__ == "__main__":
    sys.exit(main())
