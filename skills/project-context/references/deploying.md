# Deploying in batches

Read when the lane is `deploy`, or when deciding whether to offer it at routing time.

**The `impl` lane pushes; the `deploy` lane promotes.** A push to
`origin/staging` is what runs CI, so it belongs to the session that made the
commit — one story per CI run, and a red is attributable to the story whose
context is still warm. Batch the pushes instead and N stories hit CI as one
blob, which turns every red into a bisect across all of them. Push and **don't
wait on CI**: the next session's first act is checking whether `origin/staging`
is green, and if it isn't, that is the lane.

**Promoting is what batches.** The queue is a fact git already holds — no
counter, no vault field to keep in sync:

```bash
git log origin/main..origin/staging --oneline
```

Promote when any one of these is true, not after every impl:

- **3+ stories pending**, or
- **nothing in the index is ready to plan or implement** — drain the queue rather
  than idle, or
- **the batch fixes something broken in prod** — go now, ignore the count, or
- **the batch carries a schema migration** — promote it earlier and smaller than
  the count rule suggests. Several migrations landing together is the riskiest
  shape there is, and one smoke check then has to cover all of them at once.

**Read the range before offering `deploy` at routing time.** Under the threshold
with impl work available, `deploy` is not the lane — say what's pending, and
route to the work. Staging sitting ahead of prod carries its own cost: an
environment-difference bug (`scheduling`'s staging/prod timezone mismatch) hides
longer, and lands with more changes in flight to confuse attribution.
