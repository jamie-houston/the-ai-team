# Migrating a repo into this layout

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
