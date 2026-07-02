# 2026-07-02 — Retire stale "row count stays 52" comments (live count 53) `[JL]`

## Goal

`validation_status()` returns **53** rows (`tools/status_cache.json`:
`"rows": 53`). Remove hardcoded stale `52` from assertive comments.
Comment/doc-only; no logic, no numerics, no status change.

## Changes

- `test/test_payload_v2_parity.jl` — header `count stays 52` → count-agnostic
  (matches `test/runtests.jl:8864`, already fixed in `6aa17ccf`).
- `docs/dev-log/recovery-checkpoints/2026-07-01-neffect-covered-evidence.md` —
  `row count stays 52` annotated as point-in-time (52 at the 2026-07-01 gate;
  53 as of 2026-07-02); dated checkpoint, so historical annotation not rewrite.

**Not changed:** `test/runtests.jl:8864` (already count-agnostic);
`check-log.d/2026-07-02-phase5-p51-sparse-aireml.md:42` (accurate quote of the
prior fix — editing it would corrupt the audit trail).

## Commands run and results

- `julia --project=. -e 'using Pkg; Pkg.test()'` (Julia 1.10.0) →
  `Testing HSquared tests passed`, exit **0**. Touched testsets:
  `payload-v2 parser (P0.3) 54/54`; `P0.5 payload-v2 parity` fixtures
  19/19, 23/23, 19/19.
- CI (PR #243): Julia 1 + Julia 1.10 + docs — recorded green at merge.
- Real `rose-systems-auditor` audit → **PROMOTE** (clean, no changes). Rose
  independently triangulated the live count = 53 three ways
  (`tools/status_cache.json`, 53 row-id literals in `src/validation_status.jl`,
  and the count-guard `test/runtests.jl:175 @test length(validation) == 53`),
  confirmed both edits are comment-only, ratified both "not changed" decisions,
  and swept siblings (all other "52" hits are dated historical records). Full
  verdict in `docs/dev-log/after-task/2026-07-02-stale-rowcount-comments.md`.

## Claim boundary

Cosmetic hygiene only. `validation_status()` count 53 UNCHANGED, covered
count UNCHANGED, `public_covered_count` 5 UNCHANGED, v0.1 default untouched.
No capability-status row and no validation-debt row apply (no capability, no
debt) — intentional, not an omission.
