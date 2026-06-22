# After-task report — structured_genetic_payload: rotation-invariant lowrank/FA bridge (#42 / V4-BRIDGE)

Date: 2026-06-22

Branch: `claude/structured-genetic-payload` (HSquared.jl, isolated worktree from
`main` `38286b1`). **Not committed at time of writing.**

Active lenses: Kirkpatrick (G-matrix / FA), Noether (estimand/notation), Hopper
(bridge payload), Rose (claim-vs-evidence)

Spawned subagents: none

Current lane: Julia engine (`HSquared.jl`)

## 1. Goal

Bridge the rotation-gated `:lowrank` / `:factor_analytic` multivariate fits (which
`multivariate_result_payload` currently rejects) via the agreed FA convention:
expose only rotation-INVARIANT functionals of `G`, never the rotation-nonidentified
loadings. Stays `partial`; no promotion.

## 2. Implemented

- `structured_genetic_payload(result)` (exported) in `src/multivariate.jl` — the
  rotation-gated companion of `multivariate_result_payload`. Returns the
  reconstructed `genetic_covariance`, per-trait variances/correlations, the genetic
  eigenstructure (`genetic_pca`: descending eigenvalues + sign-canonicalized
  principal axes), `mean_evolvability`, FA `genetic_uniqueness` Ψ, heritabilities,
  fixed effects, breeding values, `loglik`, `converged`, and self-describing
  `rotation_invariant` / `loadings_excluded` flags. Reuses `genetic_pca`,
  `mean_evolvability`, `_require_structured_genetic_metadata`.
- Test added to the structured-covariance testset in `test/runtests.jl`.
- `validation_status()` (`src/validation_status.jl`) and
  `docs/design/validation-debt-register.md` V4-BRIDGE rows updated; the V4-BRIDGE
  status-row assertion in the suite updated to the new state.

## 3a. Decisions and Rejected Alternatives

- **Rotation-invariant functionals only, NEVER loadings** — the FA rotation
  convention (`docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`). The
  payload reads `G` (rotation-invariant by construction), so it is rotation-invariant
  without ever touching `Λ`.
- **A separate function (`structured_genetic_payload`)** rather than widening
  `multivariate_result_payload` — keeps the latter's strict rotation-free
  (`:unstructured`/`:diagonal`) contract intact and makes the rotation-gated path
  explicit. Each rejects the other's structures with a directing `ArgumentError`.
- **Guard order**: `hasproperty` → structure check → `_require_structured_genetic_metadata`,
  so a malformed input, a rotation-free fit, and a structured fit each get the
  right `ArgumentError` (tested).

## 4. Files Touched

- `src/multivariate.jl` (`structured_genetic_payload`)
- `src/HSquared.jl` (export)
- `src/validation_status.jl` (V4-BRIDGE evidence/needs/caveat)
- `docs/design/validation-debt-register.md` (V4-BRIDGE row)
- `test/runtests.jl` (structured payload testset + V4-BRIDGE status assertion)
- `docs/dev-log/after-task/2026-06-22-structured-genetic-payload.md` (this file)

## 5. Checks Run

- `Pkg.instantiate()` → instantiated cleanly.
- Full core suite **thread-capped** (`OPENBLAS_NUM_THREADS=2`): first run surfaced
  1 expected failure (the V4-BRIDGE status test still asserted "rotation convention
  pending", the OLD state); after updating that assertion, **exit 0, zero
  failures**.

## 6. Tests of the Tests

- Hard contract pinned: the payload **omits `genetic_loadings`** (`!(:genetic_loadings in keys(sp))`),
  and its eigenstructure equals `genetic_pca(G)` (so it is the rotation-invariant
  functional, not the loadings).
- Lowrank → `genetic_uniqueness === nothing`; FA → positive Ψ.
- Rotation-free `:diagonal`/`:unstructured` and a malformed input are each rejected
  with `ArgumentError`.

## 7a. Issue Ledger

- #42 / V4-BRIDGE extended: lowrank/FA are now bridge-exposed via rotation-invariant
  functionals. Stays `partial`. Still needs external comparator parity + R-side
  activation. No promotion; raw loadings deliberately remain unexposed.

## 8. Consistency Audit

- The FA convention is honored end-to-end (G/eigenstructure/Ψ only). `validation_status()`
  code + validation-debt register kept in sync; `capability-status.md` deferred to merge.

## 9. What Did Not Go Smoothly

- A status-row assertion (`bridge_row.missing` ⊃ "rotation convention pending")
  encoded the OLD state and failed once I updated the row; updated the assertion to
  the new state (the convention is applied, not pending). The validation-debt edit
  also needed the worktree file read first (different path from the prior worktree).

## 10. Known Residuals

- **Not committed/pushed** at time of writing.
- `capability-status.md` V4-BRIDGE mirror edit deferred to merge.
- R-side activation of the structured payload + external comparator parity remain
  (cross-lane #42/#47).

## 11. Team Learning

When a status-row's text changes, the suite's status-row assertions must move with
it — treat the validation_status() rows and their tests as one unit.
