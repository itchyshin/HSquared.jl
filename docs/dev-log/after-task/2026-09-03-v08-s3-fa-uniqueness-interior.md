# After-task — 0.8 S3 FA uniqueness-interior bound (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-fa-20260903`. Type: engine change (not a campaign).

```
PLATFORM: cursor | LANE: cursor/08-fa-s3-20260903
OTHER LANES: G5 #157/#291 cite-only · Codex DRAFT #137/#274 cite-only · cursor/08-ss AGHmatrix
Active lenses: Ada · Shannon · Rose fence · Gauss/Kirkpatrick · Curie
Spawned subagents: none
Current lane: Julia 0.8 WT S3 uniqueness bound on #292
```

## Goal

Implement the S3 uniqueness-interior bound (and Ledermann covered-flip
refuse) without reopening the frozen S2 DGP. No covered flip.

## What landed

- Fitted FA uniqueness: `ψ = 1e-4 + exp(θ)` (`FA_UNIQUENESS_FLOOR`).
- `ledermann_slack`, `fa_covered_flip_cell`, `require_fa_covered_flip_cell`.
- Tests in `test/test_fa_uniqueness_interior.jl` (wired from `runtests.jl`).
- S2 driver / DGP / pass text **not** edited.
- Count stays **7**. `V4-FA` stays partial. No Rose CLEAN.

## Public claim audit

Allowed: "S3 bound is in; fitted min(ψ) ≥ 1e-4; slack≤0 is refused as a
covered-flip cell; S4 is unblocked but not run."
Blocked: FA / single-step covered; `cov=fa`; loadings+SE; WOMBAT parity;
0.8.0 / count 8; 1.0 / CRAN; Rose CLEAN (not requested, not written, not forged).

## Checks this slice

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. -e 'using Test; include("test/test_fa_uniqueness_interior.jl")'
# exit 0; 27 / 27 pass in 3.9 s (julia 1.10)

# existing Phase 4B FA path still reconstructs; min(ψ̂) sits on the floor
# (t=2 K=1 is Ledermann-saturated; bound is doing the work)
```

No S4 `--mode=fit`. Did not touch G5, `comparator/`,
`docs/design/capability-status.md` (other-lane lease), or the S2 driver.

## Tests of the tests

Unit tests pin slack arithmetic (t=4 K=1 → 4; t=3 K=1 → 0), the refuse
message, unconstrained θ → −∞ mapping onto the floor, and a near-Heywood
start (`ψ0 = 2e-4`) that cannot drop below `1e-4`.

## What did not go smoothly

`src/HSquared.jl` / `test/runtests.jl` have other-lane work on other
branches; those diffs are matrix-free / non-Gaussian, not FA uniqueness.
Built on this FA WT only.

## Known limitations

WOMBAT still absent. S4 8/10 bar is predeclared only. The 8-animal t=2
unit fixture sits on the floor (expected at slack −2). Whether the frozen
t=4 K=1 cell recovers interior uniqueness is an S4 question.

## Next

Totoro S4 on the frozen S2 driver (`--cell=d4-k1 --mode=fit`, seeds
`20260914:20260923`). No flip until design-41 §3 + Rose CLEAN.
