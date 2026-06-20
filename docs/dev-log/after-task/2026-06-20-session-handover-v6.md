# Session handover — 2026-06-20 (v6) · START HERE

Inheritance note for a fresh session. Repository state is truth; this is the
at-a-glance pointer. Supersedes v5 (`2026-06-20-session-handover-v5.md`).

## Rehydrate path

Run the `hsquared-rehydrate` skill, then read in order: **this note** → `AGENTS.md`
(Live Phase Snapshot + lane routing) → `docs/design/capability-status.md` +
`docs/design/validation-debt-register.md` → `docs/dev-log/coordination-board.md` →
the newest `docs/dev-log/check-log.d/*` and `after-task/*`. **The live cross-lane
thread is GitHub issue #61** — read all comments (the most recent are this session's
Julia-lane notes, incl. the metafounder Q1–Q4 bridge gate).

- **Dev docs:** https://itchyshin.github.io/HSquared.jl/dev/
- **Control centre widget** (`~/.claude/hsquared-control-centre`, `:8791`): refreshed
  this session (preserve `live_agents`).

## Goal (standing)

Finish the next-phase programme. The committed BT2/BT3 runway is DONE; the clean,
well-bounded SOLO engine items are now **also** largely done (this session). **The
honest bottom line: most remaining `partial`/`planned` work is blocked on EXTERNAL
comparators (R-lane / sommer / ASReml / JWAS / BLUPF90), the R bridge contract, or
hardware (Phase 7/8) — not on more engine code. The solo work that remains is either
big multi-slice capabilities (genetic GLLVM) or edges into performance-claim territory
(matrix-free PCG) that needs benchmarks.**

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** R twin (`../hsquared`) is READ-ONLY; GitHub issues are
  the coordination channel.
- **Land via PR**; merge CI-green slice PRs. TDD + full Definition of Done per slice.
  No fitting/genomics/GPU/GLLVM/performance claim without the evidence chain. **Julia
  at `~/.juliaup/bin/julia` (NOT on PATH).**
- Local checks before push: `Pkg.test()` + `docs/make.jl`. **CAVEATS:** (1) Dropbox can
  transiently rewrite working-tree files mid-edit (you'll see "file modified by
  user/linter" reminders + occasional `.git/index.lock` staleness — `rm -f
  .git/index.lock` then `git fetch && git reset --hard origin/main` is safe, all work
  lands via PR). (2) A rapid push to a PR branch can fail to trigger GitHub Actions
  (0 check-runs) — push an empty no-op commit to re-trigger. **CI on a clean checkout is
  the AUTHORITATIVE gate.**

## Current state (repo = truth)

- Branch **`main` @ `86033fc`** (before this handover merges). Working tree clean;
  CI + Documenter green; **0 open PRs**.
- `Pkg.test()` green; `validation_status()` has **38 rows**.
- One public-covered capability: the v0.1 univariate Gaussian animal model. Everything
  else `experimental`/`partial` — nothing promoted to covered.

## DONE this session (ultracode pass, Ada — 7 PRs merged)

Each = full-DoD PR with adversarial review (actual subagents).
- **#77 — #54 slice 3, RR REML.** `fit_random_regression_reml` estimates the
  reaction-norm coefficient covariance `K_g` + residual by dense log-Cholesky REML;
  degree-0 → `fit_sparse_reml`. 4-lens review (Henderson/Gauss/Karpinski/Rose).
- **#78 — V4-MV-REML recovery evidence.** Harness now reports bias±2·MCSE + EBV
  accuracy + Wilson CI; 12-seed run → no detectable bias, EBV accuracy ≈0.90. The
  "6/10 failed" was G sampling variance at q=80/n=240, not bias. Checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-06-20-multivariate-reml-recovery-mcse.md`.
- **#79 — cold-start replication.** Optimizer reaches the same optimum unaided (max
  |Δrel_G| 2.7e-5) → warm-start caveat closed.
- **#80 — handover v5.**
- **#81 — V1-SELINV-PEV larger pedigree.** `:selinv` PEV == dense on a 110-animal
  4-gen pedigree (machine precision).
- **#82 — #53 metafounders.** Supplied-Γ `A^Γ` (`metafounder_relationship`), combined
  MME inverse (`metafounder_inverse`), descriptive animal-only inverse
  (`metafounder_relationship_inverse`), `metafounder_inbreeding` (Legarra 2015). The
  existing tabular/Henderson machinery with Γ seeded; reduction to `A`/`pedigree_inverse`
  at Γ=0; independent dense oracle + round-trip. Henderson (math verified) + Rose
  (honesty) reviewed. Γ SUPPLIED, not estimated. Scout note in `docs/dev-log/scout/`.
- **#83 — PCG MME solver.** `solve_animal_model_pcg` — preconditioned CG on the same
  sparse SPD MME `henderson_mme` factorizes; validated iterative == direct (Gauss
  confirmed at n up to 1500). CORRECTNESS primitive only — NO performance claim (`C`
  still assembled). The production-sparse-path foundation.

Two ultracode **Workflows** drove design/review; cross-lane notes on **#61**.

## R-lane action items (live on #61)

1. **#43/#21** bridge merge-guard; **#45/#23** post-fit scan unpack; **#48** keep
   `gwas()` wording uncalibrated; **#44/#18** hold non-Gaussian parser until the method
   note; **#2/#6** fitted-Mrode confrontation (`test/fixtures/animal_model_fitted_target/`).
2. **THE multivariate handoff (#10/#49):** run sommer/ASReml/BLUPF90 against
   `test/fixtures/phase4_multitrait_parity/`; record tolerance + versions. Engine half
   done.
3. **Metafounder bridge (#53): answer Q1–Q4 on #61** (Γ marker / UPG-vs-MF grammar /
   Γ shape + group round-trip / combined-vs-descriptive inverse row count). R already
   reserves `metafounder()`/`unknown_parent_group()`/`group()`. Bridge PR strictly
   after ratification.
4. **FA convention (#42 ↔ R#7):** ratify before bridging structured-fit fields.

## What remains (next-session candidates, prioritized)

1. **Genetic GLLVM (#50)** — the most ambitious SOLO build (high-dimensional latent
   genetic factors; multi-slice). The biggest remaining engine capability.
2. **Matrix-free PCG operator** — apply `C·v` without assembling `C` (the actual
   large-scale enabler on top of #83); then a genuine large-pedigree benchmark — but
   that is a PERFORMANCE claim, gated by the evidence rule.
3. **Cross-lane (highest leverage, not solo):** the R-lane external-comparator runs
   (multivariate #10/#49, fitted-Mrode #2/#6) and the metafounder bridge (after Q1–Q4).
4. Opt-in BLUPF90 metafounder comparator scaffold (JWAS-style); RR slice 4
   (eigen-function / PE term / R `rr()` spec); CRN + APY; scout cadence #56.
5. Hardware-gated, NOT this lane: Phase 7 (CPU/GPU), Phase 8 (HPC).

## Smallest safe next actions

1. Scope + start genetic GLLVM (#50) as a multi-slice build (descriptors/supplied
   first, mirroring how RR + multivariate started) — or
2. After R answers #61 Q1–Q4: the metafounder bridge payload — or
3. Record any further opt-in recovery/comparator evidence.

## Verification snapshot

- `gh pr list --state merged` → #77–#83 merged this session; 0 open after this handover.
- CI + Documenter green on `main`. `Pkg.test()` green; `validation_status()` → 38 rows.
- #61 carries the live cross-lane thread (RR/MV/selinv notes + metafounder Q1–Q4).
