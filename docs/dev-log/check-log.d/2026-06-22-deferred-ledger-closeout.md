# 2026-06-22 Deferred ledger/evidence close-out (C5/C10/I1/H1)

- Goal: close the DEFERRED honest-tracking follow-ups the backlog-grind handover
  left open for four already-merged slices (C5 genomic σ²a interval, C10
  `nested_lrt`, I1 sire fixture, H1 negative-binomial). No new `src/` numerics.
- Starting point:
  - HSquared.jl `main` clean at `6a0f3cf8` after merging `#164` (I1) and `#165`
    (H1), both CLEAN/MERGEABLE with all four CI checks green; NB2 loglik/score/
    weight re-derived independently before merge.
  - Branch `claude/deferred-ledger-closeout`.
- Files changed:
  - `src/validation_status.jl` (+3 partial rows: `C10-LRT`, `V1-SIRE-FIT`,
    `V6-NBINOM`; count 41 → 44; first/last pins unchanged)
  - `test/runtests.jl` (count bump; presence/status assertions; nbinom payload
    assertion; comparator-manifest id-set + sire block)
  - `test/fixtures/comparator_targets.toml` (sire target, `evidence_type =
    "julia_target"`)
  - `sim/phase6_nbinom_recovery.jl` (NEW opt-in NB2 σ²a recovery harness)
  - `docs/dev-log/recovery-checkpoints/2026-06-22-h1-nbinom-recovery.md` (NEW)
  - `docs/design/validation-debt-register.md`, `docs/design/capability-status.md`
    (C5 mirror + V2-GBLUP cross-ref + nbinom/sire/nested_lrt rows)
  - `docs/design/14-program-backlog.md` (✅/🟡 marks for C5/C10/H1/I1/I9/I10)
  - `docs/dev-log/after-task/2026-06-22-deferred-ledger-closeout.md` (NEW)
- Checks run:
  - Smoke: `validation_status()` → 44 rows, the 3 new ids present, first/last
    pins intact, statuses `{covered, covered_external, partial, planned}`.
  - NB recovery (`sim/phase6_nbinom_recovery.jl`, thread-capped): hard gate
    (converged ∧ interior σ̂²a ∧ EBV cor ≥ 0.5) **5/5**; σ²a magnitude
    REPORTED-NOT-GATED (3/5 at rel ≤ 0.45, mean σ̂²a 0.395 vs 0.50, ~21% down;
    θ̂ 1.8–6.5). No post-hoc gate relaxation — magnitude failure recorded.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` (thread-capped):
    **"Testing HSquared tests passed"** (exit 0).
  - `julia --project=docs docs/make.jl` (thread-capped): **exit 0** (benign
    pre-existing warnings only).
  - Real `rose-systems-auditor` subagent audit: **CLEAN (merge-ready)** — no
    overclaim, no covered-drift, no hidden gate relaxation; one wording nit fixed.
- Status: nothing promoted to covered; public-default covered count unchanged
  (1 = Gaussian); Julia `validation_status()` covered count unchanged (3 new
  rows all `partial`).
