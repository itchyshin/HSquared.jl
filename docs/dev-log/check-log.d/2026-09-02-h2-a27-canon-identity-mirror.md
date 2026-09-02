# 2026-09-02 — A27: mirror the R-lane locked derived-estimand identities

**Arc:** A27 (Darwin MV-6 sign pack; criterion-3 citation scout). Docs-only
mirror; the Darwin signature is **still pending**.
**Lens:** Noether (math/notation consistency).
**Lane:** Julia engine (`HSquared.jl`).
**Worktree:** `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Branch:** `claude/lane-h2-twin-20260901`. **Not pushed.**

## Problem

The R twin's `docs/design/04-validation-canon.md` carries a
§ *Locked Derived-Estimand Identities* section pinning `r_g` and per-trait `h²_k`
to their defining functions of `G0`/`R0` plus locked Falconer/Lynch citations
(the Standard-Tier Covered-Flip Gate's criterion-3 requirement). The Julia
canon had **no such section**, so the two lanes had no shared written statement
of what `genetic_correlation` and `heritability` mean on a multivariate fit.

## Change

`docs/design/04-validation-canon.md` — new section
*Locked Derived-Estimand Identities (R-lane gate, mirrored here)*, inserted
before § Status Words. Mirrors both identities in engine notation
(`r_g = D⁻¹ G0 D⁻¹`; `h²_k = diag(G0) ./ (diag(G0) .+ diag(R0))`, with
`σ²_a,k = G0[k,k]`, `σ²_e,k = R0[k,k]`), names R's `cov2cor` ↔ Julia
`genetic_correlation` as the same map, and mirrors both locked citations
verbatim from the R lane. No DOI invented; no new citation introduced.

## Noether finding recorded in the mirror (not a new claim)

The gating identity tests are R-lane (`tests/testthat/test-multivariate.R`,
MV-3). On the Julia side both quantities are computed **by construction** from
the same fitted `G0hat`/`R0hat` inside `fit_multivariate_reml`
(`src/multivariate.jl`: `genetic_correlation = genetic_correlation(G0hat)`;
`hsq = [G0hat[k,k] / (G0hat[k,k] + R0hat[k,k]) for k in 1:t]`), so they cannot
numerically disagree with their definitions — but construction is not a test.
What the Julia suite pins is weaker, and the mirror says so:

| Pinned in Julia | Where |
|---|---|
| `0 ≤ h²_k ≤ 1`, `-1 ≤ r_g[i,j] ≤ 1` | `test/runtests.jl:7272-7273` |
| copy-returning `heritability` / `genetic_correlation` extractors | `test/runtests.jl:7278`, `7284-7286` |
| `result.genetic_correlation ≈ genetic_correlation(G0)` (supplied-covariance `multivariate_mme` only) | `test/runtests.jl:7110-7114` |
| **absent:** `heritability(fit) ≈ diag(G0) ./ (diag(G0) .+ diag(R0))` | — |

A refactor that recomputed `h²` from a different source would therefore not turn
the suite red. Recorded as an honest boundary in the canon; **not** proposed as
a blocker for the R-lane flip, whose identity gate is R-side by design.

## Commands and outcomes

| Command | Result |
|---|---|
| `rg -n "Locked Derived-Estimand" docs/design/04-validation-canon.md` (before) | no match — section genuinely missing, not reworded |
| `rg -n "genetic_correlation\|heritability" src/multivariate.jl` | construction sites confirmed (`hsq` 869; result fields 874, 876) |
| `rg -n "genetic_correlation" test/runtests.jl` | assertion inventory above; no `diag(G0)`-form h² identity |
| `git diff --stat` | docs-only (`docs/design/` + `docs/dev-log/check-log.d/`); no `src/`, no `test/` |

No Julia test run required or claimed: this commit touches no code, no test,
and no generated Documenter page (`docs/design/` is not in `docs/make.jl`).

## Fence

- No covered flip; `public_covered_count` stays **5**; Julia `V4-MV-REML`
  `covered`, R multivariate `partial` — all unchanged.
- No push; no Totoro/DRAC; no G10; no Registrator; no version bump.
- Darwin MV-6 signature line stays **blank**
  (`~/local-scratch/h2-a27-darwin-mv-sign-sheet.md`).
