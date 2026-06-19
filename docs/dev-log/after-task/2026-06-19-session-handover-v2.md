# Session handover — 2026-06-19 (v2) · START HERE

A complete inheritance note for a fresh session. Repository state is truth; this
is the at-a-glance pointer.

## Rehydrate path

Run the `hsquared-rehydrate` skill, then read in order: **this note** →
`docs/design/11-completion-plan.md` (the plan) → `AGENTS.md` (Live Phase Snapshot
+ lane-routing table) → `docs/design/capability-status.md` +
`docs/design/validation-debt-register.md` → `docs/dev-log/coordination-board.md`
→ newest `docs/dev-log/check-log.d/*`.

- **Live widget (mission control):** http://127.0.0.1:8791/ — served by screen
  session `96354.hsquared-dashboard-8791` from `~/.claude/hsquared-control-centre/`;
  polls `status.json` every 8s. `status.json` is refreshed to this handover
  (`live_agents = 0`). Only bump `version.txt` if you edit `index.html`.
- **Dev docs site:** https://itchyshin.github.io/HSquared.jl/dev/ — rebuilt by the
  Documenter CI on merge to `main`. The API/reference page now documents the full
  exported surface (this session added the 22 previously-missing Phase-3/4/5/6 +
  SE/LRT + `NonGaussianFit` entries).

## The goal (standing)

A session-scoped goal is active: **“finish the next-phase programme plan.”** The
plan lives in `docs/design/11-completion-plan.md` — three “Big Things” (BT) plus
process scaffolding and an innovation-scout cadence. Not yet finished (BT2/BT3
remain).

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** The R twin (`../hsquared`) code is READ-ONLY;
  GitHub issues/comments on **both** repos are the sanctioned coordination channel.
- **No direct push to `main`** (auto-classifier gates it) — land via PR. No
  publish/merge without explicit go-ahead (the standing goal counts as go-ahead to
  proceed via the reviewed PR mechanism).
- TDD + full Definition of Done per slice. No fitting/genomics/GPU/GLLVM claim
  without the evidence chain. **Julia is at `~/.juliaup/bin/julia` (NOT on PATH).**
- Local checks before any push: `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`
  and `~/.juliaup/bin/julia --project=docs docs/make.jl`.

## Current state (repo = truth)

- Branch **`main` @ `2a3eed5`** (Merge PR #59). Working tree clean. **0 open PRs.**
  Remote heads: `main` + `gh-pages` only.
- Suite **1822 green**; `main` CI + Documenter green.
- Local branches: just `main` (all slice branches merged + deleted). Worktrees: 1.

## DONE this session

- **BT0 — Phase-5 stack → `main`:** PR #36 (`c4fb442`). The 19-PR draft stack
  (#16–#35) closed as superseded; all merged branches + stray worktrees pruned.
- **BT1 — clean base:** repo clean; issue ledger rebuilt — Julia **#42–#45**
  (bridge activation), **#46–#49** (validation gates), **#50–#55** (innovation),
  **#56** (scout cadence); coordinated with the **active** R twin (comments on R
  #7/#10/#11–#15/#18). Process scaffolding via PR #57: per-file `check-log.d/`,
  `AGENTS.md` lane-routing + live snapshot, `docs/design/12-bridge-compatibility.md`,
  scout log + cadence.
- **BT3 #47 — multivariate covariance SEs + LRTs:** PR #59.
  `multivariate_covariance_standard_errors` (asymptotic observed-information +
  delta-method, unstructured-only, validated vs an independent t=1 FD-Hessian) and
  `covariance_structure_lrt` (boundary-aware nested LRT) + a dependency-free
  `_chisq_sf` (validated vs textbook χ² critical values). V4-MV-REML/V4-FA rows
  advanced.
- **Docs site refresh:** API page now lists every exported fn + `NonGaussianFit`
  (fixed an unresolved `@ref` that would have broken the VitePress build).
- **First innovation scout (Jason):** `docs/dev-log/scout/2026-06-19-*.md` → seeded
  #50–#55.

## IN-FLIGHT — NEEDS RELAUNCH (important)

An ultracode **Workflow** (BT2 parity fixtures + #55 evolvability + #48 calibrated
thresholds) **and** a worktree-isolated **JWAS.jl comparator agent** (#49) were
**killed by a process exit and committed NOTHING** — their dead worktrees were
pruned. **Re-run them from clean `main`.** No partial work to salvage.

## Decisions locked (2026-06-19)

- **Bridge = coordinate LIVE with the R twin.** Julia lane owns the engine half +
  parity fixtures + specs + hand-off issues; the R-twin session executes the R half.
- **#46 fitted Mrode = DEFERRED to R-twin** (nadiv/pedigreemm cross-check); Julia
  serializes a target fixture. Do NOT type published textbook EBVs from memory.
- **#49 comparator parity = add JWAS.jl** as a Julia-native comparator (opt-in
  `comparator/` env; MCMC-vs-REML; report agreement honestly, don’t overclaim).
- **Process = full adoption** of the DRM.jl/GLLVM.jl patterns.

## The plan — three Big Things (status)

| BT | Scope | Status |
| --- | --- | --- |
| BT1 | Clean base (merge, hygiene, ledger, scaffolding) | **DONE** |
| BT2 | Bridge activation for already-built engine work | engine ready; R-half coordinated. Targets: #42 structured covariance · #43 PEV/reliability · #44 non-Gaussian + `MarginalMethod` dispatch · #45 post-fit marker scans. Julia-lane DoD/target = parity fixture + `03-engine-contract.md` spec + R-activation issue. |
| BT3 | Validation → covered | #46 fitted Mrode (→R-twin) · **#47 SEs/LRTs DONE** · #48 calibrated thresholds (solo sim) · #49 comparator parity (JWAS.jl). |

Hardware-gated, structurally **not** this lane: Phase 7 (CPU/GPU) and Phase 8
(HPC) — need GPU/HPC hardware + benchmarks; surface as blocked, don’t fabricate.
Innovation backlog #50–#55; scout cadence #56 ↔ R #20.

## Smallest safe next actions

1. **Relaunch** the BT2/BT3 ultracode workflow + the JWAS comparator (clean `main`
   is ready). Or:
2. Take one solo engine slice via TDD: **#48 calibrated genome-wide thresholds**
   (sim-validated), the **`MarginalMethod` dispatch refactor** (#44, enables the
   non-Gaussian bridge), or the **BT2 parity fixtures** (low-risk, unblock the R
   twin’s parity tests).
3. Keep BT2 coordinated with the R twin via the issue ledger (R #15 gap audit).

## Verification snapshot

- `gh pr list` (both repos) → 0 open. Open issues: Julia 23, R 20.
- `Pkg.test()` → 1822 green; `docs/make.jl` → exit 0; `main` CI green on `2a3eed5`.
