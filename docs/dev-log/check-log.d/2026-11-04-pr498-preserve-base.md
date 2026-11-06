# 2026-11-04 PR 498 preserve base records

Source commit: `62ab7c8d1527d98210934d862f2cb7fd003afcb2`.

- `LOOP/GOAL.md`: source and restored Git blob `f93a22c9d0ae92ae07c8e7eba07bc96c5c82efbf`.
- `LOOP/arcs.md`: source and restored Git blob `fdf8dcc788fe92c9d6089702dd4694c338e5968d`.
- `LOOP/checkpoint.md`: source and restored Git blob `df929851b490c9bcbbf47f803ac0ddc3cd3bd9a4`.
- `LOOP/ultra-plan.md`: source and restored Git blob `264d653a87535630f0763a6d774586107cd1c594`.
- Prior `GATES.md`: source and separate archive blob `7d2c6170831d58bcd7b66cb474faa0cfaac4c212`.
- Python JSON and project-relative hook path assertions: pass; `node --check .cursor/hooks/graft-hooks.cjs`: pass. Native Cursor execution is not tested.
- `bash tools/preamble_cap.sh` and the edited-index/hook/receipt whitespace check: pass. The full staged whitespace check reports two original whitespace issues in `LOOP/arcs.md`; the source bytes are retained unchanged.
- `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --status`: exit 2, root index contains zero live gates; no acceptance claim.

The ignored Arc 1 and automatic FA active ledgers remain unavailable. These
checks do not award scientific gate credit or establish release readiness.
