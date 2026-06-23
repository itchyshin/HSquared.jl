# After-task — H6 non-Gaussian interval coverage characterization — 2026-06-22

## Task goal

Backlog slice **H6**: the σ²a profile-LRT interval (`laplace_reml_interval`) over
single-component non-Gaussian families. **Scope correction (verified against the
code):** the "extend the interval to all families" headline was ALREADY DONE — the
interval covers `:poisson`/`:bernoulli`/`:binomial` (and now `:bernoulli_probit` from
H3) uniformly through one shared `_resolve_single_family` + `target`/`_profile_root`
path. The honest H6 residual is the ONE thing every V6 row + the interval docstring
still disclaimed: "NO coverage calibration." So this slice = a CI-safe uniformity
contract test + an empirical COVERAGE CHARACTERIZATION (not a code-API change).
`[JL]` engine-only; stays `partial` (no promotion, no new validation_status row).

## Active lenses / spawned agents

Lenses: Fisher (the coverage estimand + the non-degenerate-vs-clamped reporting),
Curie (the sweep design + honest small-rep framing), Gauss (the BLAS-cost discipline).
A real `rose-systems-auditor` audit of the branch is the next step before merge.

## What I did (and the scope I did NOT inflate)

- **Did NOT** re-implement the interval (it exists with ~20 passing assertions);
  landing that as "new" would be the spec's flagged double-count overclaim.
- **Added a CI-safe cross-family contract test** (`test/runtests.jl`): all four
  single-component families (`:poisson`/`:bernoulli`/`:binomial`/`:bernoulli_probit`)
  return the IDENTICAL `laplace_reml_interval` field tuple incl. both clamp flags —
  locks the "uniform interval" claim deterministically.
- **Generalized the coverage harness** `sim/phase6_nongaussian_interval_coverage.jl`:
  added the missing **Bernoulli leg**, a **level∈{0.90,0.95} × truth σ²a∈{0.25,1.0}**
  sweep, a TSV emit, coverage over NON-DEGENERATE reps with endpoint-clamp rates
  reported SEPARATELY, a smaller design (q=165) + small reps + capped BLAS (the prior
  50-rep multithreaded run was killed for pegging cores — now resolved).
- Softened the interval docstring "NO coverage calibration" → "preliminary coverage
  CHARACTERIZATION only … NOT a calibrated coverage guarantee."

## Files changed

- `src/nongaussian.jl` — interval docstring softening (1 clause; behavior unchanged).
- `test/runtests.jl` — new "Phase 6 non-Gaussian interval cross-family contract (H6)"
  testset (field-tuple uniformity across 4 families + `occursin("coverage", V6-LAPLACE)`).
- `sim/phase6_nongaussian_interval_coverage.jl` — Bernoulli leg + multi-cell sweep + TSV.
- `src/validation_status.jl` — V6-LAPLACE interval clause updated in place (uniform +
  coverage characterization). NO new row; count UNCHANGED at 46.
- `docs/design/validation-debt-register.md` — V6-FIT updated in place.
- `docs/dev-log/recovery-checkpoints/2026-06-22-nongaussian-interval-coverage.md` —
  updated (supersedes the #157 10-rep smoke with the H6 multi-cell run).
- `docs/design/14-program-backlog.md` — H6 ✅.

## Checks run and exact outcomes

- Coverage run (`sim/...`, capped BLAS, 15 reps/cell): coverage ~0.71–1.00 across
  cells, read as CONSERVATIVE/over-covering. Binomial m=20 clean (0.93–1.00, no clamps);
  Bernoulli predominantly LOWER-clamped one-sided (coverage inflated by the clamped
  bound — the documented flat-profile degeneracy, reported via the clamp-rate column);
  Poisson mostly two-sided, 0.71–0.93 (small-rep noise). Full table in the checkpoint.
- Full `Pkg.test()` (thread-capped): **"Testing HSquared tests passed"** (exit 0) —
  incl. the new cross-family contract testset + the `occursin("coverage", V6-LAPLACE)`.
- `julia --project=docs docs/make.jl` (thread-capped): **exit 0** (no dead links).
- Real `rose-systems-auditor` over the branch: **PROMOTE-WITH-CHANGES → addressed**.
  Confirmed: no new validation_status row (count 46→46), covered count unchanged, the
  interval code was NOT re-implemented (docstring-only `src/` change), every coverage
  claim is descriptive/negated-"calibrated", the inflated-Bernoulli case is honestly
  attributed to one-sided lower-clamping with the clamp rate reported separately, and
  the checkpoint preserves the superseded #157 smoke. Required changes APPLIED: the 3
  stale "no coverage calibration" sibling disclaimers (capability-status ×2,
  validation-debt-register V6-BINOMIAL) now cross-reference the characterization;
  `src/likelihood.jl` Gaussian interval correctly left untouched (out of H6 scope).

## Public claim audit (Rose)

- No new `validation_status` row; covered/covered_external counts UNCHANGED; V6-FIT /
  V6-LAPLACE stay `partial`. No promotion.
- The coverage result is framed as a DESCRIPTIVE characterization ("conservative /
  over-covering"), never "calibrated coverage" — at 15 reps a cell cannot distinguish
  0.90 from 1.00, stated explicitly. Bernoulli's inflated 1.000 coverage is honestly
  attributed to one-sided lower-clamping (the clamp rate is reported separately).
- No code-API/behavior change (docstring-only in `src/`); the contract test is the only
  new assertion surface. `[JL]` engine-only; no R repo edit.

## What did not go smoothly

- Scope discipline: the spec's "extend the interval" headline was already implemented;
  I verified against the code and narrowed H6 to the genuine residual (coverage
  evidence + the uniformity contract test), avoiding a double-count overclaim.
- A self-inflicted false alarm earlier in the session: a verification command ending
  in `grep -c "dead link"` exited 1 (zero matches) and masked a successful `docs/make.jl`
  exit 0 — noted; ended the H6 docs check on the Julia exit code, not the grep.

## Known limitations

- Coverage is small-rep (15/cell), single design (q=165), validation-scale — a
  characterization, NOT calibrated. Still needs a larger-rep estimate at multiple
  designs, a parametric-bootstrap interval alternative, the Gaussian/multi-component
  case (nuisance profiling), and external comparators.

## Next actions

1. Confirm full `Pkg.test()` + `docs/make.jl` green; fill the two pending outcomes.
2. Real `rose-systems-auditor` over the branch.
3. Commit, PR, merge on green CI (pre-authorized).
4. Then **H7** (latent/observation-scale h², `V6-NS-H2`, new export).
