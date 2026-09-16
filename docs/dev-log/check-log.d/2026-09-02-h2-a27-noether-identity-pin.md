# 2026-09-02 — A27 follow-up: pin the derived-estimand identities on the Julia REML fit path

**Arc:** A27-noether (follow-up to the A27 canon mirror, Julia `7a2361b9`).
**Lens:** Noether (math/notation consistency).
**Lane:** Julia engine (`HSquared.jl`).
**Worktree:** `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Branch:** `claude/lane-h2-twin-20260901`. **Not pushed.**

## Problem

The A27 mirror recorded — honestly, but as an open boundary — that the Julia
suite pinned no assertion of the form
`heritability(fit) ≈ diag(G0) ./ (diag(G0) .+ diag(R0))`, and pinned the
`cov2cor` identity only on the **supplied-covariance** `multivariate_mme` path
(`test/runtests.jl:7110-7114`), never on the **estimated** REML path. Both
quantities are built by construction inside `fit_multivariate_reml`
(`src/multivariate.jl`: `hsq = [G0hat[k,k] / (G0hat[k,k] + R0hat[k,k]) …]`;
`genetic_correlation = genetic_correlation(G0hat)`), so they could not disagree
with their definitions — but construction is not a test: a refactor that
recomputed `h²` from a different source, or that swapped in a different
correlation map, would not have turned the suite red. The suite pinned only
ranges (`0 ≤ h²_k ≤ 1`, `-1 ≤ r_g ≤ 1`) and copy-returning extractors.

## Change

### `test/runtests.jl` — new testset (test-only, +83 lines)

`@testset "Phase 4 derived-estimand identities on the REML fit path"`, inserted
between the existing *Phase 4 multivariate REML (estimate G0/R0)* and *Phase 4
shared multi-trait parity fixture* testsets. **69 assertions, 69 pass.**

Reference maps are written out locally in canon notation — `h2_ref(G0, R0)` and
`corr_ref(C) = D⁻¹ C D⁻¹` with `D = Diagonal(sqrt.(diag(C)))` — deliberately
**not** obtained by calling `genetic_correlation`, which is the very map under
test and would make the assertion circular.

Covered fits (all from the 8-animal pedigree already used by the neighbouring
REML testsets, so no new fixture and no RNG):

| Fit | `genetic_structure` |
|---|---|
| `unstructured` | `:unstructured`, t = 2 |
| `diagonal` | `:diagonal`, t = 2 (`G0[1,2] == 0`) |
| `lowrank` | `:lowrank`, rank 1, t = 2 (`r_g = ±1` exactly) |
| `trait_reduction` | `:unstructured`, t = 1 |
| `missing_records` | `:unstructured`, t = 2, two `NaN` records (near-boundary `diag(G0) ≈ [0.0067, 0.0835]`) |

Per fit (13 assertions at t = 2, 12 at t = 1):

- `fit.converged`; `all(>(0), diag(G0))`, `all(>(0), diag(R0))` — the identities
  need a positive diagonal to be defined, so that precondition is asserted, not
  assumed;
- `heritability(fit) ≈ h2_ref(G0, R0)` **and**
  `collect(fit.heritability) ≈ h2_ref(G0, R0)` (extractor *and* stored field),
  plus a per-trait `heritability(fit)[k] ≈ G0[k,k] / (G0[k,k] + R0[k,k])` loop;
- `fit.genetic_correlation ≈ corr_ref(G0)`,
  `genetic_correlation(fit) ≈ corr_ref(G0)`,
  `fit.residual_correlation ≈ corr_ref(R0)`;
- `diag(fit.genetic_correlation) == ones(t)`,
  `diag(fit.residual_correlation) == ones(t)`, and symmetry of `r_g`.

All numeric comparisons at `rtol = 1e-12` (measured discrepancy is ulp-level:
max abs error `1.1e-16` for `r_g`, exactly `0.0` for `h²` on every fit), so a
wrong-source recompute cannot hide inside the tolerance.

Anti-vacuity block (5 assertions), so the identities are shown to be
discriminating rather than trivially satisfiable:

- `G0[1,2] != 0` on the unstructured fit (measured `0.552`), so the correlation
  identity is not being checked on a diagonal matrix;
- the two per-trait `h²` are clearly distinct (`0.851` vs `0.558`), and the
  **reversed** reference vector is rejected at `rtol = 1e-6` — trait order is
  pinned, not incidental;
- `h²` is invariant to zeroing `G0`'s off-diagonal (it reads only trait `k`'s
  diagonals — it is not a pooled/total-additive ratio) while `r_g` is **not**
  invariant to the same drop, so the two estimands are pinned as different
  functions of the same `G0`.

### `docs/design/04-validation-canon.md` — stale claim corrected

§ *Locked Derived-Estimand Identities* asserted, as of `7a2361b9`, that "There
is **no** Julia assertion of the form `heritability(fit) ≈ …`". That sentence is
now false, so it is replaced by what the suite actually pins (testset name,
both identities, tolerance, the five fits, and the non-circular reference maps),
with the weaker pre-existing pins retained in the list. Two boundaries added
rather than glossed: these are **self-consistency** assertions on this engine's
own estimates (they pin what the symbols denote, not whether `G0`/`R0` are
right), and they are **not** external-comparator evidence. The R-lane MV-3
gating framing, both locked citations, and the closing fence paragraph are
unchanged. `docs/design/` is not in `docs/make.jl`, so no Documenter build
claim is made.

The A27 check-log entry's "absent" table row is left as written — it was true of
that slice — and is closed by this entry rather than edited.

## Commands and outcomes

| Command | Result |
|---|---|
| `julia --project=. ~/local-scratch/h2-noether-identity-probe.jl` | pre-implementation probe: identity holds on all five fits (`h²` err `0.0`, `r_g` err ≤ `1.1e-16`); all five anti-vacuity conditions true |
| `julia --project=. -e 'using Pkg; Pkg.test()'` | **PASSED** — 144 testsets, 4322 assertions, 0 fail / 0 error (run twice; second run logged to `/tmp/h2_a29_suite.log`). Baseline was 143 / 4252 (2026-09-01 `matfree-fence-pin`); the new testset reports **69 / 69** |
| `julia --project=. -e 'using HSquared; …'` | `validation_status()` loads; rows **56**, covered **13**, `V4-MV-REML.status == "covered"` — all unchanged |
| `bash tools/preamble_cap.sh` | **CAP OK** (12 186 B / 14 000 B; 1 snapshot entry) |
| `git diff --stat` | `test/runtests.jl` +83, `docs/design/04-validation-canon.md` +26/−14 — no `src/`, no fixture, no generated page |
| ref scan for `derived-estimand identities` across 60 local/remote refs | no match — this is not a re-implementation of work already on another branch |

Julia 1.10.0. No Documenter build run (no page touched). No comparator, no
Totoro/DRAC, no RNG introduced — the new testset reuses the deterministic
8-animal pedigree already in the file.

## Fence

- **No covered flip.** Julia `V4-MV-REML` stays `covered` (experimental,
  validation-scale, opt-in); the R multivariate surface stays `partial`;
  `public_covered_count` stays **5**. No file that carries that count was
  touched.
- These assertions are within-package identity evidence for the two *derived*
  estimands only. Component `G0`/`R0` remain external-same-estimand-comparator
  gated (`sommer` 4.4.5, `blupf90+` 2.60, DRAC `47925486`).
- The R-lane covered flip remains twin-gated plus Darwin MV-6 biology sign-off
  plus Rose. **Darwin's MV-6 signature line stays blank**
  (`~/local-scratch/h2-a27-darwin-mv-sign-sheet.md`).
- No push; no version bump; no Registrator; no G10 sign-off implied.
