# Handover — one-owner consolidation + 100-slice backlog grind (2026-06-22)

**START HERE** for the next session. Repo state is the source of truth; this note
is the at-a-glance pointer. Everything below is committed/pushed.

## TL;DR

One owner now develops BOTH repos (`hsquared` R + `HSquared.jl` engine) from a
single lane. This session: (1) closed the R-lane consolidation, (2) promoted the
**first new covered model** (V4-MV-REML), (3) stood up a vetted **100-slice
program** and ground **6 of its first 14 slices** (all `partial`, oracle/test-
verified). Two PRs are open and green-pending. The remaining 8 slices are
**correctness-critical** (GLMM families / inference) and must be done one careful
oracle-validated pass each — do NOT mechanically land them.

## Exact state

- **`HSquared.jl` main:** `2e21a01e` (C10 merged, #163).
- **`hsquared` main:** `ce61016` (R consistency #110).
- **Open PRs (review/merge in order):** `HSquared.jl#164` (I1 sire fixture),
  `HSquared.jl#165` (H1 negative-binomial). hsquared: none.
- **Pushed branches:** `claude/i1-sire-fixture` (#164), `claude/h1-nbinom` (#165);
  `claude/wave1-light` + `claude/wave2-light` are merged (deletable).

## Earlier this session (context, all landed)

- **Consolidation:** merged the R stack `hsquared#98→#108` (live-verified 1445
  pure-R + 116 live-bridge) and engine PRs `HSquared.jl#155→#159` (`Pkg.test` green).
- **V4-MV-REML `partial→covered`** (#161, merge `964448a5`) — first new covered
  model beyond v0.1 Gaussian: **experimental, validation-scale, opt-in — NOT the
  public default.** Substitutable gate (doc-33) via a PRE-REGISTERED 48-seed
  recovery gate that passed + a real Rose audit (PROMOTE-WITH-CHANGES) + sign-off.
  **Public-default covered count is still 1 (Gaussian).** Julia `validation_status()`
  covered 7→8.
- **Unified mission control** at `http://127.0.0.1:8791/` (served from
  `~/.claude/hsquared-control-centre/`, static `http.server`). Relaunch:
  `python3 -m http.server 8791 --bind 127.0.0.1 --directory ~/.claude/hsquared-control-centre`.
  (The 8781 board, `hsquared/.mission-control/`, is a stale duplicate.)

## The 100-slice program

- **Backlog of record:** `docs/design/14-program-backlog.md` (12 threads A–L).
- **Vetted wave plan:** `docs/design/15-backlog-wave-execution-plan.md` (the
  first 14 slices, 7 serial-landing waves).
- **Full per-slice specs** (exact API + RED-GREEN plans, from the design-sweep
  ultracode workflow): the workflow transcript under
  `subagents/workflows/wf_30d421bf-254`, also dumped to `/tmp/backlog_specs.md`
  (regenerate from the workflow output if gone).
- **Promotion-gate predicates:** `docs/design/16-promotion-gate-predicates.md`.

### First-14 status (6 done / 8 remaining)

| slice | what | status |
| --- | --- | --- |
| C5 | genomic-σ²a interval (contract-widen) | ✅ merged #162 |
| I9 | validation-debt burn-down tracker | ✅ merged #162 |
| I10 | promotion-gate predicate doc | ✅ merged #162 |
| C10 | reusable `nested_lrt` + chi-bar boundary | ✅ merged #163 |
| I1 | fitted sire-model fixture | 🔵 PR #164 |
| H1 | negative-binomial (NB2) Laplace family | 🔵 PR #165 |
| C2 | genetic-correlation interval (delta+profile) | ⏳ remaining (heavy) |
| C6 | parametric-bootstrap VC CIs | ⏳ remaining (heavy) |
| H2 | beta-binomial family | ⏳ remaining (heavy) |
| H3 | ordinal/probit threshold model | ⏳ remaining (heavy) |
| H6 | non-Gaussian interval coverage | ⏳ remaining (heavy; mostly the Bernoulli coverage leg) |
| H7 | latent-scale (NS) non-Gaussian h² | ⏳ remaining (heavy) |
| J1 | haplodiploid relationship kernel | ⛔ spec is self-contradictory — see below |
| L1 | Makie figure kinds (Manhattan/QQ, RR surface) | ⏳ remaining (drawing-only, out-of-CI) |

## DEFERRED ledger/evidence follow-ups (to bound context, the CODE+TESTS landed but
the honest-tracking rows are incomplete — close these next session)

- **C5:** `validation_status.jl` V1-HERIT-CI updated; the `.md` mirrors
  (`validation-debt-register.md`, `capability-status.md`) + V2-GBLUP cross-ref + the
  doc-14 ✅ mark are NOT done.
- **C10:** NO `validation_status.jl` row added (avoided the count-assertion churn) —
  add a `C10-LRT` row (+ bump `test/runtests.jl` length assertion), `.md` rows, doc-14.
- **I1:** NO `validation_status.jl` `V1-SIRE-FIT` row, NO `comparator_targets.toml`
  registration/manifest test — add them; `.md` rows; after-task; doc-14. (The fixture
  + self-consistency test ARE landed.)
- **H1:** NO `V6-NBINOM` `validation_status.jl` row (+count bump); the opt-in
  `sim/phase6_nbinom_recovery.jl` recovery sim is NOT written/run; `.md` rows;
  after-task; doc-14. (Kernels + fitter + oracle test ARE landed.)

## Correctness caveats + learnings (read before grinding more)

1. **J1 is a landmine — do NOT mechanically land.** Its design spec's haplodiploid
   convention is self-contradictory: the stated female rule `½(A_sire+A_dam)` gives
   father→daughter = 0.5, but the canonical anchor (and the row text) require 1.0
   (a haploid drone transmits his whole genome). Resolve by DERIVING the diploidized
   haplodiploid recursion from a reference + Mendel/Falconer sign-off, then implement.
2. **The GLMM/inference half (H2/H3/H6/H7/C2/C6) needs derive → oracle → Rose.** The
   design specs accelerate but do NOT guarantee correctness (J1 proved it). The
   working pattern (H1 used it): implement the kernels, then an **independent oracle**
   — score/weight vs central finite differences of `_fam_loglik`, plus a **limiting-
   case** check (H1: Poisson limit θ→∞, geometric at θ=1). These catch a wrong
   normalizer an η-only FD cannot. Only commit once the oracle passes.
3. **`_loggamma` already exists** in `src/multivariate.jl` (Lanczos g=7) — REUSE it;
   a duplicate definition breaks precompilation ("method overwriting not permitted").
   No `SpecialFunctions` dependency.
4. **Funnel files serialize landing:** `src/validation_status.jl` + `test/runtests.jl`
   (+ the `.md` ledgers) are edited by nearly every slice → land slices one at a time
   (per-slice or small-wave branches). Adding a `validation_status` row changes the
   count → bump the `@test length(validation) == N` assertion AND insert the row
   NOT-first/NOT-last (the suite pins `validation[begin].id`/`[end].id`). The I9
   burn-down testset is live-derived, so it adapts automatically.
5. **CPU discipline (user-enforced):** julia is at `~/.juliaup/bin` (OFF the
   non-interactive PATH). Run everything thread-capped:
   `PATH="$HOME/.juliaup/bin:$PATH" OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2
   JULIA_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test()'`. Do NOT fan out
   many concurrent julia/worktree jobs (precompile × N pegs the machine). One capped
   run at a time; recovery/coverage sims are heavy — pace them (background + capped).
6. **R live bridge:** `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT=../HSquared.jl`
   makes `hs_julia_bridge_available()` TRUE so the skip-guarded R↔Julia tests run.
7. **GH vs Laplace (the methods crux):** the non-Gaussian marginal integrates out a
   high-dim, A-correlated `u`. Laplace (mode + curvature; = adaptive GHQ with 1 node;
   exact for Gaussian) is the engine path; adaptive GHQ (Q nodes → exact, but cost
   `Qᵈ` → low-`d` only) is the **oracle** on a reduced tractable case; VA maximizes
   the ELBO (a different estimand — can't go in an LRT vs a Laplace loglik).

## Disciplines (carry over unchanged)

Covered/partial/planned honesty; **Rose claim-vs-evidence audit mandatory before any
covered move**; no rushing correctness-critical genetics/likelihood code; comparator
evidence distinguishes same-estimand parity from agreement; frequent commits;
local-checks-over-CI; repo-visible memory over chat. Definition of Done = impl +
tests + docs + capability-status row + validation-debt row + check-log + after-task +
Rose audit + clean local checks (+ clean CI if pushed) + maintainer sign-off for any
covered promotion.

## How to resume

1. Merge `#164` (I1) and `#165` (H1) once CI is green (`gh pr checks <n> --watch`).
2. Close the DEFERRED ledger/evidence follow-ups above (fast, mechanical).
3. Continue the grind: **L1** (lowest risk, drawing-only) → then the GLMM/inference
   slices **one careful oracle-validated pass each** (H2 beta-binomial reuses H1's
   2-parameter pattern; H6 is mostly the Bernoulli coverage leg). **J1** needs a
   derivation + sign-off first.
4. Specs are in the wave plan (`docs/design/15`) + `/tmp/backlog_specs.md`. Nothing
   reaches `covered` without the full evidence chain + a real Rose audit + sign-off.
