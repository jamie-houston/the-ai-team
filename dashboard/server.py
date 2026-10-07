#!/usr/bin/env python3
"""work-loop dashboard — a local view of one running work-loop.

Serves a page showing the loop's live event stream (an NDJSON file the loop
appends to) alongside the vault state it is working against: CURRENT POSITION,
lanes in flight, the FOR JAMIE queue, open work not yet storied, open items and
the story ledger.

Two things on the page write back: filling in a FOR JAMIE item's `**Answer:**`
line, and ticking a `ready` marker on an open-work row. Both are surgical edits
to the markdown — the answer body between its marker and the next item, or the
first cell of one table row — and both refuse if what is on disk no longer
matches what the page was showing, since other lanes edit the same files.

Started by work-loop.sh for one repo and killed with it. Binds localhost only.
"""

import argparse
import json
import os
import re
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
LOCK = threading.Lock()


# ---------------------------------------------------------------- markdown

HEADING = re.compile(r"^(#{2,6})\s+(.*)$")
ITEM = re.compile(r"^(?:#{3,4}\s*\[([^\]]+)\]|\*\*\[([^\]]+)\]\*\*)")
FIELD = re.compile(r"^\*\*[A-Z][A-Za-z ]+:\*\*")


def read_text(path):
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return ""


def section_range(lines, want):
    """(start, end) line indices of the body under the first heading whose text
    starts with `want`, ending at the next heading of the same level or higher.
    (None, None) when there is no such heading."""
    start = level = None
    for i, ln in enumerate(lines):
        m = HEADING.match(ln)
        if not m:
            continue
        if start is None:
            if m.group(2).lower().startswith(want.lower()):
                start, level = i + 1, len(m.group(1))
        elif len(m.group(1)) <= level:
            return start, i
    return (start, len(lines)) if start is not None else (None, None)


def find_section(text, want):
    lines = text.splitlines()
    start, end = section_range(lines, want)
    return lines[start:end] if start is not None else []


def parse_table(lines):
    """First markdown table in `lines`. Cells are stripped; the raw line is
    kept because it is how a row is identified when writing back."""
    headers, rows = None, []
    for ln in lines:
        s = ln.strip()
        if not s.startswith("|"):
            if headers is not None:
                break
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if headers is None:
            headers = cells
        elif set("".join(cells)) <= set("-: "):
            continue
        else:
            rows.append({"cells": cells, "line": ln})
    return {"headers": headers or [], "rows": rows}


def section_block(text, want):
    """A section that may be either a table or prose — "Open items" is a table
    in one project and bullets under sub-headings in another."""
    lines = find_section(text, want)
    table = parse_table(lines)
    return {"table": table, "text": "\n".join(lines).strip() if not table["rows"] else ""}


def parse_position(text):
    """The CURRENT POSITION blockquote, from its first `**Field:**` line on —
    the lines above that are the block's own usage instructions."""
    out, on = [], False
    for ln in text.splitlines():
        if not on:
            if ln.startswith(">") and "CURRENT POSITION" in ln:
                on = True
            continue
        if not ln.startswith(">"):
            break
        out.append(ln.lstrip(">").strip())
    for i, ln in enumerate(out):
        if FIELD.match(ln):
            return [l for l in out[i:] if l]
    return [l for l in out if l]


def parse_for_jamie(text):
    """Items in `## FOR JAMIE`, each `[slug]` plus whatever follows its
    `**Answer:**` marker. Both item styles in use are accepted: `### [slug]`
    and `**[slug]**`."""
    lines = find_section(text, "FOR JAMIE")
    starts = [i for i, ln in enumerate(lines) if ITEM.match(ln)]
    items = []
    for n, i in enumerate(starts):
        end = starts[n + 1] if n + 1 < len(starts) else len(lines)
        m = ITEM.match(lines[i])
        # `**[slug]** Blocks: …` puts the first sentence on the marker line, so
        # keep whatever follows the marker rather than dropping the line.
        head = lines[i][m.end():].strip()
        body, answer, in_answer = ([head] if head else []), [], False
        for ln in lines[i + 1:end]:
            if not in_answer and ln.strip().startswith("**Answer:**"):
                in_answer = True
                answer.append(ln.strip()[len("**Answer:**"):].strip())
            elif in_answer:
                answer.append(ln)
            else:
                body.append(ln)
        items.append({
            "slug": m.group(1) or m.group(2),
            "body": "\n".join(body).strip(),
            "answer": "\n".join(answer).strip(),
        })
    return items


# ------------------------------------------------------------------ vault

class Vault:
    """The five files a project's state lives in. The index splits into
    ledger/open-work/operations once it outgrows ~30 KB, so each lookup falls
    back to the index when its split file does not exist."""

    def __init__(self, vault_root, project):
        self.root = Path(vault_root)
        self.project = project
        self.dir = self.root / project
        self.index = self.dir / "stories" / "README.md"
        self.inbox = self.dir / f"{project} inbox.md"
        self.obsidian = self._obsidian_root()

    def _obsidian_root(self):
        """The enclosing Obsidian vault, so the page can link a [[story]] to
        the file Obsidian will open. Absent, links render as plain text."""
        for d in [self.root, *self.root.parents]:
            if (d / ".obsidian").is_dir():
                return d
        return None

    def _or_index(self, name):
        split = self.dir / "stories" / name
        return split if split.exists() else self.index

    @property
    def ledger(self):
        return self._or_index("ledger.md")

    @property
    def open_work(self):
        return self._or_index("open-work.md")

    def state(self):
        index = read_text(self.index)
        open_work_text = read_text(self.open_work)
        ledger_text = read_text(self.ledger)
        table = parse_table(find_section(open_work_text, "Open work not yet storied"))
        for row in table["rows"]:
            row["ready"] = bool(row["cells"]) and row["cells"][0].lower() == "ready"
        return {
            "position": parse_position(index),
            "lanes": parse_table(find_section(index, "Lanes in flight")),
            "for_jamie": parse_for_jamie(read_text(self.inbox)),
            "open_work": table,
            "open_items": section_block(open_work_text, "Open items"),
            "stories": parse_table(find_section(ledger_text, "Stories")),
            "vault_name": self.obsidian.name if self.obsidian else "",
            "story_dir": (str((self.dir / "stories").relative_to(self.obsidian))
                          if self.obsidian else ""),
        }


def rewrite(path, old_text, new_lines):
    """Write `new_lines` to `path`, but only while the file still holds exactly
    what the edit was computed from. Other lanes edit these files; a
    whole-file write over a stale read is the failure this guards."""
    if read_text(path) != old_text:
        return False
    tmp = path.with_suffix(path.suffix + ".dashtmp")
    tmp.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
    os.replace(tmp, path)
    return True


def set_answer(path, slug, text, expected):
    """Replace one FOR JAMIE item's answer body."""
    original = read_text(path)
    lines = original.splitlines()
    # Bounded by the section: the bottom half of the inbox is Jamie's own dump,
    # and an item there must never be mistaken for the end of one up here.
    lo, hi = section_range(lines, "FOR JAMIE")
    if lo is None:
        return "not-found"
    starts = [i for i in range(lo, hi) if ITEM.match(lines[i])]
    for n, i in enumerate(starts):
        m = ITEM.match(lines[i])
        if (m.group(1) or m.group(2)) != slug:
            continue
        end = starts[n + 1] if n + 1 < len(starts) else hi
        for j in range(i, end):
            if lines[j].strip().startswith("**Answer:**"):
                current = "\n".join(
                    [lines[j].strip()[len("**Answer:**"):].strip()] + lines[j + 1:end]
                ).strip()
                if expected is not None and current != expected:
                    return "stale"
                body = ["**Answer:**"]
                if text.strip():
                    body += text.strip().splitlines()
                body.append("")
                return "ok" if rewrite(path, original, lines[:j] + body + lines[end:]) else "stale"
        return "no-answer-line"
    return "not-found"


def set_ready(path, row_line, ready):
    """Set or clear `ready` in the first cell of one open-work row. Only the
    cell is touched — the row's other cells run to 1,700 characters."""
    original = read_text(path)
    lines = original.splitlines()
    hits = [i for i, ln in enumerate(lines) if ln == row_line]
    if len(hits) != 1:
        return "stale"
    i = hits[0]
    a = lines[i].index("|")
    b = lines[i].index("|", a + 1)
    lines[i] = lines[i][:a + 1] + (" ready " if ready else " ") + lines[i][b:]
    return "ok" if rewrite(path, original, lines) else "stale"


# ------------------------------------------------------------------- loop

class Loop:
    """Loop state, derived from the NDJSON event file by consuming it
    incrementally. The file is the only channel between loop and dashboard."""

    def __init__(self, path):
        self.path = Path(path)
        self.reset()

    def reset(self):
        self.offset = 0
        self.buf = ""
        self.events = []
        self.start = None
        self.finish = None
        self.iterations = []

    def pump(self):
        try:
            size = self.path.stat().st_size
        except OSError:
            return
        if size < self.offset:
            self.reset()
        if size == self.offset:
            return
        with self.path.open("r", encoding="utf-8", errors="replace") as fh:
            fh.seek(self.offset)
            chunk = fh.read()
            self.offset = fh.tell()
        self.buf += chunk
        *complete, self.buf = self.buf.split("\n")
        for line in complete:
            if line.strip():
                self._consume(line)

    def _consume(self, line):
        try:
            ev = json.loads(line)
        except ValueError:
            return
        kind = ev.get("kind")
        if kind == "start":
            self.reset_run(ev)
        elif kind == "iteration":
            self.iterations.append({**ev, "model": None, "result": None})
        elif kind == "result" and self.iterations:
            self.iterations[-1]["result"] = ev
        elif kind == "model" and self.iterations:
            self.iterations[-1]["model"] = ev.get("model")
        elif kind == "finish":
            self.finish = ev
        self.events.append(ev)

    def reset_run(self, ev):
        self.start = ev
        self.events = []
        self.iterations = []
        self.finish = None

    def summary(self):
        totals = {"cost": 0.0, "in": 0, "out": 0, "cache": 0}
        for it in self.iterations:
            r = it.get("result") or {}
            totals["cost"] += r.get("cost", 0) or 0
            for k in ("in", "out", "cache"):
                totals[k] += r.get(k, 0) or 0
        cur = self.iterations[-1] if self.iterations else None
        return {
            "start": self.start,
            "finish": self.finish,
            "totals": totals,
            "iterations": self.iterations,
            "current": cur,
            "running": self.start is not None and self.finish is None,
            "next_seq": len(self.events),
        }


# ----------------------------------------------------------------- server

class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        pass

    def _send(self, code, body, ctype):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj, code=200):
        self._send(code, json.dumps(obj), "application/json; charset=utf-8")

    def do_GET(self):
        url = urllib.parse.urlparse(self.path)
        if url.path == "/":
            return self._send(200, read_text(HERE / "index.html"), "text/html; charset=utf-8")
        if url.path == "/api/events":
            frm = int(urllib.parse.parse_qs(url.query).get("from", ["0"])[0])
            with LOCK:
                LOOP.pump()
                if frm > len(LOOP.events):
                    frm = 0
                return self._json({"from": frm, "next": len(LOOP.events),
                                   "events": LOOP.events[frm:]})
        if url.path == "/api/state":
            with LOCK:
                LOOP.pump()
                state = LOOP.summary()
            state.update(VAULT.state())
            state["project"] = ARGS.project
            state["repo"] = ARGS.repo
            state["stopping"] = Path(ARGS.stop_file).exists()
            return self._json(state)
        return self._send(404, "not found", "text/plain")

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        try:
            body = json.loads(self.rfile.read(length) or "{}")
        except ValueError:
            return self._json({"error": "bad json"}, 400)
        path = urllib.parse.urlparse(self.path).path
        with LOCK:
            if path == "/api/answer":
                result = set_answer(VAULT.inbox, body.get("slug", ""),
                                    body.get("text", ""), body.get("expected"))
            elif path == "/api/ready":
                result = set_ready(VAULT.open_work, body.get("line", ""),
                                   bool(body.get("ready")))
            elif path == "/api/stop":
                Path(ARGS.stop_file).touch()
                result = "ok"
            else:
                return self._send(404, "not found", "text/plain")
        code = 200 if result == "ok" else 409
        return self._json({"result": result}, code)


def serve(port):
    for candidate in [port + i for i in range(10)] + [0]:
        try:
            return ThreadingHTTPServer(("127.0.0.1", candidate), Handler)
        except OSError:
            continue
    raise SystemExit("no free port")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--events", required=True)
    ap.add_argument("--repo", required=True)
    ap.add_argument("--vault", required=True)
    ap.add_argument("--stop-file", required=True)
    ap.add_argument("--port", type=int, default=8787)
    ARGS = ap.parse_args()
    ARGS.project = Path(ARGS.repo).name
    LOOP = Loop(ARGS.events)
    VAULT = Vault(ARGS.vault, ARGS.project)
    httpd = serve(ARGS.port)
    print(f"http://127.0.0.1:{httpd.server_address[1]}/", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
