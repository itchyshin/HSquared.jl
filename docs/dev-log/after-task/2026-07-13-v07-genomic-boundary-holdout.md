# After-task report — v0.7 genomic closed-boundary holdout

## 1. Goal

Adjudicate the preregistered closed-boundary genomic GREML candidate on an
untouched cross-twin holdout, activate only if every scientific and runtime
gate passes, and otherwise bank an honest negative endpoint.

The achieved endpoint is negative: boundary correctness passed, but one frozen
per-cell runtime gate failed. Default/public activation remains held.

## 2. Implemented

- Implemented a fail-closed closed-domain genomic REML wrapper that distinguishes
  scientific endpoints `0`/`1` from the epsilon MME representation, preserves
  construction provenance, and suppresses boundary uncertainty/predictions.
- Canonicalized marker and supplied-precision routes through the same `Q -> K`
  profile path and pinned dense-versus-eigen profile agreement.
- Added adversarial guards for non-REML, malformed/nonfinite/asymmetric/non-PD
  inputs, identity-Z, fixed-effect rank, ID/precision/kernel fingerprints,
  refinement failure, endpoint ties, and unresolved outcomes.
- Added the independent base-R boundary oracle and exact R bridge binding. The
  public default remains rejected; only the explicit experimental route uses
  this result surface.
- Added a create-once Totoro holdout harness with exact Julia/R/oracle/doc/discovery
  bindings, a fixed non-holdout compile warm-up, seed-parity timing order, 240
  immutable packets, sidecars, independent oracles, and a conjunctive gate.
- Ran the sealed holdout. Scientific resolution passed (30 wins, 0 losses), but
  the preregistered runtime gate failed in one cell (5.99x versus 3x).
- Fixed a post-seal shell launcher argument bug and added a synthetic wiring
  test. This orchestration fix did not alter the sealed candidate or outputs.
- Banked the full negative evidence and updated roadmap, capability/debt warning,
  coordination, check-log, and recovery-checkpoint surfaces.

Active lenses: Ada/Shannon, Hopper/Boole/Emmy, Gauss/Karpinski/Noether,
Curie/Fisher, Grace, and Rose. One actual independent subagent ran the final
adversarial core review; it first returned `BLOCKED`, then `CLEAN` after both
fail-closed defects were repaired.

## 3a. Decisions and Rejected Alternatives

- Kept exact endpoint likelihood separate from the positive epsilon MME solve;
  rejected presenting the numerical rail as the scientific estimate.
- Required closed-domain likelihood plus KKT agreement and fail-closed ties;
  rejected treating AI iteration-limit/step-halving status as proof of failure.
- Required optimizer refinement convergence and input-contract failures to
  return `boundary_unresolved`; rejected consuming finite-looking non-converged
  optimizer output or throwing through the bridge.
- Balanced timed order and compiled both methods on a fixed non-holdout fixture;
  rejected measuring JIT latency as method runtime.
- Enforced the frozen 3x p95 gate conjunctively. Rejected relaxing the threshold,
  averaging across cells, deleting the fast-default cell, or calling 30/0 a pass.
- Did not revise or rerun the candidate on the opened seeds. A future candidate
  must use discovery data for performance work and a new holdout block.
- Retained reusable explicit-route hardening, but rejected default routing,
  nine-cell recovery, capability promotion, G10, or release.

## 4. Files Touched

Julia repository:

- `src/likelihood.jl`
- `test/runtests.jl`
- `sim/phase2_v07_genomic_boundary_holdout.jl`
- `sim/totoro/v07_genomic_boundary_holdout.sh`
- `docs/design/45-v07-genomic-optimizer-localization.md`
- `docs/design/45a-v07-genomic-oracle-refinement.md`
- `docs/design/45b-v07-genomic-oracle-endpoint-tolerance.md`
- `docs/design/46-v07-genomic-boundary-resolution.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `ROADMAP.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-07-12-v07-optimizer-localization-discovery.md`
- `docs/dev-log/check-log.d/2026-07-13-v07-genomic-boundary-holdout.md`
- `docs/dev-log/recovery-checkpoints/2026-07-13-v07-genomic-boundary-holdout.md`
- `docs/dev-log/after-task/2026-07-13-v07-genomic-boundary-holdout.md`

R twin (separate pushed branch):

- `R/julia-bridge.R`
- `R/extractors.R`
- `R/hsquared.R`
- `tests/testthat/test-genomic.R`
- `tests/testthat/test-v07-genomic-boundary-oracle.R`
- `tools/v07_genomic_boundary_oracle.R`

Raw packets/oracles remain local on Totoro and were not committed or uploaded.

## 5. Checks Run

- Mandatory git/branch/worktree/stash sweep in both repositories: clean scoped
  branches; no overlapping uncommitted implementation.
- Julia boundary testset: 72/72 pass after adversarial repairs.
- Full Julia `Pkg.test()`: pass.
- R full engine-free `devtools::test()`: 1,896 pass, 0 fail, 0 warn, 68
  ordinary dependency/toolchain skips.
- Commit-pinned live genomic R-Julia suite: 265 pass, 0 fail, 0 warn, 0 skip.
- Boundary harness self-test and launcher `bash -n`: pass.
- Non-holdout `n=300,m=1000` timing smoke: candidate/default 1.35x.
- Independent adversarial review: initial `BLOCKED` for unchecked profile
  refinement and throwing out-of-contract inputs; repaired and rechecked
  `CLEAN` at core `ecc058f3`.
- Totoro sealed run: 240 packets in 66.2 elapsed seconds at 96 single-threaded
  workers; 240 checksum locks; 240 independent R oracles and sidecars.
- Julia summary: `BOUNDARY_HOLDOUT_FAIL` only because `runtime_ok=false`.
- Independent base-R aggregation reproduced all counts, classifications, and
  five per-cell p95 ratios.
- Final Julia Documenter/Vitepress build passed; preamble cap, `git diff
  --check`, and close-out compiler passed. The synchronized R twin regenerated
  roxygen, completed its full suite without failure/warning, passed pkgdown,
  and passed repaired `R CMD check --no-manual` with 0 errors, 0 warnings, and
  0 notes.

Exact hashes, commands, versions, and local paths are in the recovery checkpoint.

## 6. Tests of the Tests

- Dense direct REML evaluation and the eigen evaluator agree at endpoints and
  an interior ratio; marker and supplied-Q routes agree exactly.
- Deliberate ID, precision, kernel, ridge, method, numeric-type, symmetry,
  positive-definiteness, Z, and rank mutations turn the boundary contract red.
- Pure classifier tests make endpoint-pair ties, endpoint-interior ties, and
  reversed KKT evidence unresolved; an AI-converged result is overridden.
- The refinement acceptance kernel rejects a finite result when its optimizer
  convergence flag is false, an out-of-bracket minimizer, or nonfinite values.
- The holdout validates exact file sets, checksums, commit/hash bindings,
  denominators, route order, finite resolved fields, and unresolved status.
- The original oracle launcher command actually failed with literal `{}` and
  produced zero files. The new synthetic xargs wiring test reproduces that
  argument geometry and fails under the old command.
- The frozen runtime gate demonstrably turned the aggregate result red despite
  a 30-to-0 scientific win, proving the conjunctive gate was not ceremonial.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| AI non-convergence conflated with boundary truth | Localized; 18 lower and 11 upper discovery endpoints. |
| Endpoint estimate confused with epsilon representation | Fixed and tested separately. |
| Profile refinement consumed without checking convergence | Fixed fail-closed; adversarial test added. |
| ML/malformed kernel could throw through wrapper | Fixed fail-closed; sibling numeric conversions hardened. |
| Marker and supplied-Q flat profiles differed by inversion roundoff | Canonicalized through exact same `Q -> K` path. |
| Fresh-process timing measured JIT and fixed method order | Fixed non-holdout warm-up plus seed-parity order. |
| Oracle xargs passed literal `{}` | Fixed post-seal at `75279136`; negative control added. |
| One cell exceeded runtime cap | Retained blocker; no activation or rerun. |
| Broad all-live R suite hit unrelated JuliaCall setup/segfault defects | Not claimed green; dedicated zero-skip genomic live gate is the evidence. |

## 8. Consistency Audit

The neighbourhood sweep covered the Julia core and tests, R bridge/result
wording, independent oracle, both harnesses, doc-46 contracts, roadmap,
capability/debt registers, coordination board, check log, recovery evidence,
and public-count language. Boundary results never expose PEV/reliability/
accuracy or ordinary heritability wording. Supplied `Ginv` does not inherit
marker construction provenance. The marker route remains validation-scale,
Gaussian REML-only, one effect, sample-frequency VanRaden1, ridge 0.01.

No surface claims broad recovery, production scale, calibrated uncertainty,
exact ridge SNP-BLUP equivalence, default activation, release, or G10.
`public_covered_count` remains 5 and no capability row moved.

Memory receipt: the repo LOAD-FIRST manifest, ultra-plan, ask-brain history,
rehydration/team-dispatch, validation-harness, R-package-engineer,
validation-canon, Rose pre-public, and after-task contracts were loaded and
applied. They caused the git-first sweep, exact twin binding, tests-of-tests,
Totoro-only compute, independent review, and negative endpoint. Existing
NotebookLM research was reused as triage; executable repo evidence decided the
claims. No new external corpus was needed.

## 9. What Did Not Go Smoothly

- The first optimizer-localization result showed that the apparent failures
  were boundary optima, forcing a new preregistered scientific policy rather
  than a larger iteration cap.
- Independent review blocked an apparently green 64-test implementation on two
  genuine fail-closed gaps. The expanded testset reached 72 only after repair.
- A broad all-live R invocation exposed an existing direct-maternal setup call
  and later segfaulted inside JuliaCall; the intended two-tier full-R plus
  isolated-live genomic checks were run separately.
- The first oracle fan-out had a shell argument-wiring bug that `bash -n` could
  not detect. It generated no oracle files; the same sealed packets were
  independently processed after a mechanical correction.
- The candidate was scientifically superior on the sealed holdout but still
  failed the predeclared performance contract. This is a legitimate negative
  endpoint, not a near-pass.
- The after-task compiler initially resolved a relative report path against the
  brain repository. The empty generated template was removed immediately and
  the report was written in the project repo.

## 10. Known Residuals

- Default/public genomic activation remains held; nine-cell recovery and G10
  did not run.
- One `n=120,m=600,r=0.5` cell had a 5.99x p95 candidate/default runtime ratio.
  The likely fixed profile-evaluation overhead is an inference, not yet a
  measured mechanism.
- The 240 boundary holdout seeds are spent and cannot adjudicate a revised
  implementation.
- A new candidate owes allocation/component profiling on discovery data,
  output-equivalent optimization, dense-oracle/classification preservation,
  a new preregistration, and a fresh holdout block.
- R and Julia branches are pushed but not merged; reusable explicit-route and
  validation hardening still require PR/CI review.
- Production sparse genomic fitting, APY public routing, calibrated intervals,
  real-panel robustness, and a second REML comparator remain outside this arc.

## 11. Team Learning

A scientific win is not an activation win when the contract is conjunctive.
Freeze operational gates with the scientific ones, warm compilation outside the
timed region, balance execution order, and make shell argument geometry
mutation-testable. Most importantly, a fresh independent reviewer must be
allowed to block a large green suite; that review found the two defects that
would otherwise have entered a sealed campaign.

Golden Set: not run because memory retrieval/routing code did not change. The
in-scope recurring failures were exercised directly through fail-closed input,
tie, refinement, provenance, seal, denominator, timing, and shell-wiring
negative controls.

## 12. Cross-Product Coverage

- Boundary estimator covers ✓ Gaussian REML, identity Z, one record per
  genotyped ID, one genomic random intercept, `n <= 2000`, and marker/supplied-Q
  provenance. It **does NOT cover** ✗ ML, non-Gaussian families, repeated-record
  Z, multiple effects, slopes, or production scale.
- Scientific result covers ✓ exact profile endpoint `0`/`1`, separately labelled
  epsilon MME representation, and independent oracle classification. It **does
  NOT cover** ✗ boundary SE/CI, PEV, reliability, accuracy, pedigree/population
  heritability, or an average marginal phenotypic-variance claim.
- Construction covers ✓ sample-frequency unweighted VanRaden1 plus ridge 0.01
  and exact ID/kernel/precision fingerprints. It **does NOT cover** ✗ weights,
  population frequencies, alternate methods/ridges, imputation, LD/structure
  robustness, or real production panels.
- Validation covers ✓ 240 sealed boundary datasets, 30-to-0 paired scientific
  improvement, no invalid/unresolved fits, and independent R aggregation. The
  five cell counts (attempted/wins/losses) were 48/11/0, 48/2/0, 48/11/0,
  48/6/0, and 48/0/0 in the documented cell order; net gain was
  `(30 - 0) / 240 = 0.125`. It
  **does NOT cover** ✗ a passing activation gate, the nine-cell recovery
  campaign, broad bias recovery, calibrated uncertainty, or a revised faster
  candidate.
- Execution covers ✓ Totoro local-only compute, immutable packets, sidecars,
  exact commit/hash binding, and a tested resume/oracle path. It **does NOT
  cover** ✗ GitHub Actions simulations/artifacts, seed replacement, threshold
  relaxation, automatic merge, release, capability/count promotion, or G10.
