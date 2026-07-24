# After-task — `fit_eigen_reml` experimental→covered EVIDENCE PACKAGE (staged, not flipped)

**Date:** 2026-07-24 · **Lane:** Julia engine (`HSquared.jl`) · **Branch:**
`codex/2026-07-13-v07-performance-localization` · **Commits:** `1d9ec57d`, `d61f79e0`, `f27c6131`,
`e9c3a811`, `a9d8c01e` (+ this consolidation) · **Plan:** ultra-plan, owner-approved (full-auto, two-arm DGP).

## Task goal

Assemble the complete experimental→covered evidence package for the eigen-once single-effect REML fitter
`fit_eigen_reml` (`V1-EIGEN-REML`) to the doc-16 G11 bar, **staged for the owner's promotion call** — folding
in the owner's three follow-ons: (a) close the loop with Szymek, (b) the promotion gate, (c) refine the
`:auto` fill threshold. Hard fences: `public_covered_count` stays **5**, **no capability-status row flips**,
D1 genomic PAUSED (D-68) untouched, TMB deferred, R twin not edited, 4 foreign dirty files untouched.

## Outcome (met)

The two G11 legs are DISCHARGED and the package is staged:

- **G11 recovery leg — PASS.** A PRE-DECLARED (frozen at `1d9ec57d` BEFORE the run) 48-seed × 2-arm
  known-truth recovery gate ran on Totoro (julia 1.12.6): both arms 48/48 converged (eigen + AI-REML), all
  `|bias| ≤ 2·MCSE` (max 1.01·MCSE, WS σ²a), eigen ≡ AI-REML ≤ 2.62e-7 (all-96 max). The two arms are a fill
  gradient (WS `nnz(L)/n≈17` → HF `≈49` at n=1000), both fit eigen DIRECTLY.
- **G11 comparator leg — AGREE.** `sommer` 4.4.5 (independent REML) recovers the identical `(σ²a, σ²e)` on
  gate seed 20267000 to **7.77e-9**; high-fill established transitively.
- **(c) `:auto` threshold — measured + validated.** The fill×n crossover surface was benchmarked; threshold
  60 is confirmed well-placed and safely conservative; **kept** (n-adaptive refinement scoped + deferred).
- **(a) Szymek close-out — drafted** (owner sends), honoring the ASReml honesty fence.
- **Rose audit (G8): CLEAR-WITH-CHANGES** — evidence genuine + independently reproduced (Rose reran the gate
  seeds + comparator engine target), all fences hold; 3 wording corrections applied
  (`docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md`).
- **Fences held:** no capability row flipped; `public_covered_count` stays **5**; the row stays `partial` /
  `experimental`; D1/TMB/R-twin/foreign-files untouched.

The **flip itself is deferred to the owner (G10)** and the R `method="eigen"` bridge (R lane) — both OWED.

## Active lenses and spawned agents

- **Spawned subagents (real):** 3× recon (Haiku) for the prior-work sweep; 1× Szymek draft (Sonnet);
  1× **Rose** (Opus) for the G8 claim-vs-evidence audit.
- **Review lenses (perspectives, not spawned):** Gauss/Karpinski/Noether (gate DGP + routing numerics),
  Curie/Fisher/Mrode (recovery + comparator evidence), Melissa (plan-vs-actual reconcile).

## Files changed

New (committed):
- `sim/phase_eigen_reml_recovery_gate.jl` — the frozen 48-seed × 2-arm recovery gate.
- `docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-recovery-gate-predeclaration.md` + `-result.md`.
- `comparator/prepare_sommer_eigen.jl` + `comparator/run_sommer_eigen.R` + `.../2026-07-24-eigen-reml-comparator.md`.
- `sim/bench_eigen_crossover.jl` + `docs/dev-log/native-engine-arc/2026-07-24-eigen-auto-threshold-crossover.md`.
- `docs/dev-log/native-engine-arc/2026-07-24-szymek-closeout-draft.md`.

Edited:
- `docs/design/validation-debt-register.md` (V1-EIGEN-REML row — G11 discharged, stays partial).
- `docs/design/capability-status.md` (Eigen-once row — G11 evidence assembled, stays experimental).
- `test/runtests.jl` (routing testset COMMENT only — cites the measured crossover; no assertion change).
- `.gitignore` (ignore generated `comparator/sommer_eigen/`).

NOT touched: `hsquared` (R twin); any D1/genomic file; TMB; the 4 foreign dirty files.

## Checks run and exact outcomes

- **Local smoke** (n=250, 2 seeds/arm, julia 1.10.0): harness runs, both fitters converge, eigen≡AI-REML
  1e-7–1e-9. GREEN (recorded in the predeclaration).
- **Recovery gate** (Totoro, julia 1.12.6, frozen `1d9ec57d`): `GATE: PASS (WS=true HF=true)`, exit 0.
- **Comparator** (local R 4.6.0 + sommer 4.4.5): `COMPARATOR: AGREE (max rel.diff 7.77e-09)`, exit 0.
- **Crossover benchmark** (Totoro, BLAS=8): full n×window grid produced; brackets robust (2–3× margins).
- **`Pkg.test()`** (local, julia 1.10.0): **PASSED** — "Testing HSquared tests passed", 0 failures/errors
  (incl. the `fit_eigen_reml`-matches-AI-REML and `:auto`-routing testsets). No src assertions or src logic
  changed this session (only a test COMMENT), so the suite outcome is unchanged from the pre-session tree.
- **`docs/make.jl` (Documenter):** NOT re-run — no `docs/src/`/Documenter-source file changed this session
  (edits are under `docs/design/` + `docs/dev-log/`; `src/` untouched), so the rendered site is unaffected;
  the Documenter CI job on the pushed commits covers it. (Recorded per Melissa #5.)
- **G3 (docs + example / not-public-yet note):** satisfied by the experimental capability-status row's
  explicit "NOT the public default / not wired into the R bridge / no covered flip" language (that IS the
  not-public-yet note); a dedicated runnable example is DEFERRED to promotion (eigen is engine-internal, not
  a public surface). Flagged here rather than left silently absent (Melissa #4).
- **Melissa plan-vs-actual reconcile:** `docs/dev-log/plan-actual/2026-07-24-eigen-promotion-evidence.md` —
  2 drift, 2 unclear, 1 adaptive; all five addressed in this consolidation.
- **`git status`**: only session files staged/committed; the 4 foreign dirty files remain untouched.

## Public claim audit

- **No public/covered claim is made.** No capability-status row flipped; `public_covered_count` stays **5**;
  both status rows explicitly say "stays partial / experimental, no covered flip this session".
- **G11 is described as "discharged" (both legs), NOT as "covered"** — G8 (Rose), the R bridge, and G10
  (owner sign-off) remain OWED, and are stated as such in every doc.
- **Rose G8 verdict: CLEAR-WITH-CHANGES** (3 required changes, ALL APPLIED). RC1 — the HF arm at n=1000 is
  `nnz(L)/n≈49` (< threshold 60), so `:auto` routes BOTH arms to sparse; the gate validates eigen by DIRECT
  fits across a WS≈17→HF≈49 fill gradient, NOT inside `:auto`'s eigen-selected regime (result-doc erratum
  added). RC2 — n-qualified "≥76 → eigen" (only at n≥2000) in both status rows. RC3 — the all-96
  eigen≡AI-REML bound is 2.62e-7 (WS arm), not 2.18e-7. Rose independently reran the gate seeds + the
  comparator engine target (reproduced exactly); the evidence and all fences hold.
- **Szymek draft:** respects the ASReml honesty fence (no head-to-head; synthetic-proxy numbers flagged; not sent).

## Tests of the tests

- The gate's acceptance rule was **pre-declared and frozen before results** (commit `1d9ec57d` predates the
  run) — no post-hoc relaxation possible.
- The gate is self-checking two ways: (1) bias/MCSE vs known truth, (2) per-seed eigen≡AI-REML (a second
  independent estimator) — a disagreement would surface a bug even if both drifted from truth together.
- The comparator uses an INDEPENDENT optimizer (`sommer`) on the SAME data — agreement can't be a shared-code
  artifact.
- Smoke-first discipline: a tiny-n smoke gated the local API before any commit/Totoro scale-up.

## Coordination notes

- **R twin handoff (OWED, not this lane):** the R `method="eigen"` opt-in route per the bridge contract
  (`docs/dev-log/native-engine-arc/2026-07-24-eigen-fitter-r-bridge-contract.md`). Ledger: Julia #5/#6 ↔ R #2/#5.
  A coordination-board note is added this session.
- **PR #274 (draft)** mixes H2 + D1 on this shared branch — owner may split before merge (flagged prior).

## What did not go smoothly

- A stale Dropbox `.git/index.lock` blocked the first freeze commit; verified no live git process, the lock
  self-cleared, retried — committed clean. (Repo lives under Dropbox; lock contention recurs.)
- The Totoro clone's fetch refspec only tracks `main`; an explicit `git fetch origin <branch>` was needed to
  land the freeze commit for the run.
- The crossover benchmark is single-rep and shows GC noise (one t_eigen=21.65 s outlier at n=4000; sub-0.25 s
  n=1000 cells noise-dominated). The load-bearing crossover brackets have 2–3× margins and survive it; the
  threshold decision does not rest on the noisy cells. A multi-rep study is deferred.
- **Routing deviation (recorded per Melissa #routing).** The plan's slice table dispatched S1 (gate
  authoring), S4's design half, and S5 (comparator authoring) to Sonnet agents, but the orchestrator authored
  them INLINE. Reason: each is correctness-critical AND tightly coupled to the in-session compute the
  orchestrator was driving (Totoro gate/benchmark runs, local R comparator) — a script→smoke→freeze→run→
  certify chain awkward to split across agent context boundaries, and the orchestrator must certify the
  DGP/acceptance-rule correctness regardless. Real spawns: 3× recon (Haiku), Szymek (Sonnet), Rose (Opus),
  Melissa (Sonnet). Owner **Ada**: ratify orchestrator-inline for tightly-coupled build chains, or tighten
  the plan template so a `Dispatch=Agent` cell is honored or re-negotiated with a recorded reason.

## Known limitations

- **Comparator is single-seed** (WS 20267000); high-fill regime established transitively (rigorous but indirect).
  A direct high-fill `sommer` run is a cheap optional add.
- **Gate is n=1000, h²=0.4, Z=I, two fill regimes (WS `nnz(L)/n≈17` → HF `≈49`, both fit eigen DIRECTLY).**
  At n=1000 BOTH arms are below the `:auto` threshold 60, so **the gate does NOT exercise `:auto`'s
  eigen-selected regime** (`nnz(L)/n>60`, i.e. n≥2000 for a random pedigree) — recovery there rests on the
  direct-fit eigen≡AI-REML substitutability (see the result-doc erratum), not a gate run inside that regime.
  Larger-n / broader-h² recovery not gated (dense wall at `max_dense_n=20000` is a documented scope edge).
- **`:auto` threshold kept at 60** — a scalar cannot be optimal at every n (crossover is n-dependent); an
  n-adaptive rule is deferred pending a multi-rep study.
- **Engine-covered ≠ R-public-covered.** Even after promotion, the R public surface would stay experimental
  until the R bridge lands; `public_covered_count` is an R-public count.

## Next actions

1. **Owner (G10):** decide whether to flip `V1-EIGEN-REML` engine experimental→covered given G11 discharged +
   Rose verdict, or keep staged. `public_covered_count` stays 5 regardless (R-public, not engine).
2. **R lane:** implement the R `method="eigen"` opt-in route from the bridge contract; confirm count stays 5.
3. **Owner:** send the Szymek close-out (`2026-07-24-szymek-closeout-draft.md`) + request his real pedigree.
4. **Optional (deferred):** multi-rep `:auto` benchmark → possibly raise threshold to ~70 / n-adaptive;
   direct high-fill `sommer` comparator seed.
5. **Owner:** consider splitting PR #274 into H2 vs D1 before merge.

> Related: the recovery-checkpoint + native-engine-arc docs listed under Files changed ·
> `docs/design/16-promotion-gate-predicates.md` · `docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md`.
