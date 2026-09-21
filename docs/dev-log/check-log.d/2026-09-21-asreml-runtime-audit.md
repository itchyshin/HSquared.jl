## 2026-09-21 — measured runtime audit against ASReml on the great tit data `[JL]`

Owner asked for "a clear picture of where we stand with runtime efficiency before we move
further", against a reported ASReml figure of ~2 s. The 2026-09-21 post-fit arc had closed
with "no ASReml run of our own — the ~2 s figure remains the owner's report". This slice runs
it. **Measurement only: no engine code changed.**

Harness committed at `docs/dev-log/scripts/2026-09-21-asreml-runtime-audit/` (the post-fit
arc's scripts were not, so its numbers could not be re-run).

Machine: Mac Studio M1 Ultra, Julia 1.13.0 (1 Julia thread, 8 BLAS threads), ASReml 4.2.0.482
under R 4.6 (OpenBLAS 0.3.33), live licence. Problem: great tit clutch size, n = 11,856,
7,340 females, q = 10,937, p = 63, `C` 21,937². Warm, best of 3–5.

### The reported baseline was not like-for-like

`dev-test/great_tit_animal_model.qmd` gives ASReml the **full 111,645-row** pedigree and
`hsquared` the **pruned 10,937-row** one. Both ASReml runs return identical estimates and
identical `loglik = -10779.54` in 7 iterations:

| ASReml, same model | time |
| --- | --- |
| full pedigree (111,645) | 1.82 s |
| pruned pedigree (10,937) | **0.57 s** |

The ~2 s is the full-pedigree run. **The like-for-like baseline is 0.57 s.** Correcting this
makes the standing comparison roughly 3x less flattering to this engine.

### Stage split (JuliaCall, bridge's own calls)

| stage | ASReml | HSquared.jl shipped |
| --- | --- | --- |
| A⁻¹ build | 0.019 | **0.012** |
| REML fit | 0.554 (7 it × 71 ms) | 0.632 (10 it × 63 ms) |
| SEs + interval | **0.000** | 0.552 |
| R↔Julia marshalling | — | 0.020 |
| **engine total** | **0.573** | **1.216** |

End to end in R: `hsquared()` **1.43–1.50 s** warm against ASReml **0.57 s**; ~0.25 s of the
difference is R-side work above the Julia total. Estimates agree exactly
(0.5954004 / 0.5252307 / 1.3727602).

Three candidate explanations are ruled out by measurement: marshalling is 0.020 s both
directions; A⁻¹ construction BEATS ASReml (0.012 vs 0.019); and per iteration we are already
faster (63 ms vs 71 ms). ASReml's SEs cost **0.0000 s** — they come from the AI matrix the fit
already built.

### Inside one AI-REML iteration

| component | ms |
| --- | --- |
| `_assemble_lhs_rhs!` | 0.1 |
| `_factorize!` (`cholesky!`) | 4.6 |
| one MME solve | 1.2 |
| **`selinv_block_traces`** | **45.8** |
| iteration total | ~61 |

75% of every iteration, ~0.46 s of the 0.61 s fit, ~38% of shipped runtime. This CONFIRMS
rather than discovers: the post-fit arc's report already named it a known residual at
~48.9 ms. It is now the dominant lever with a measured target to beat (`#375`).

### Iteration count is mostly a tolerance artifact

Julia's default `tol = 1e-8` is far tighter than ASReml's default. Estimates agree to 7
significant figures across the sweep:

| | `initial = nothing` | `initial = :auto` |
| --- | --- | --- |
| tol 1e-8 (default) | 10 it, 0.604 s | 8 it, 0.497 s |
| tol 1e-6 | 8 it, 0.494 s | **6 it, 0.369 s** |

At `tol = 1e-6` with `:auto` the optimizer takes **6 iterations — fewer than ASReml's 7**.

### Distance to parity

| configuration | engine total | vs 0.573 s |
| --- | --- | --- |
| shipped today | 1.216 s | 2.1x |
| + `hsquared#238` (open) | 0.829 s | 1.45x |
| + `initial = :auto` | 0.695 s | 1.21x |
| + `tol = 1e-6` | 0.566 s | 1.0x |

Only the first is free of an evidence decision.

### Independent cross-check of the AI-vs-FD estimand gap

ASReml's σ²a SE is **0.066322**; the engine's finite-difference SE is **0.069573** (~4.9%).
The post-fit arc recorded 6.1% between HSquared's OWN AI matrix and its FD Hessian and
refused to substitute the cheaper AI route. An independent implementation lands on the AI
side of that gap, which supports the refusal being a real estimand difference rather than a
local artefact. Not a validation claim — ASReml cannot serve as a covered leg.

### Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed earlier this session on the same
  tree content (176 summaries, 0 failures). **No engine code changed in this slice**;
  the only files added are dev-log records and the harness.
- `bash tools/build_check_log.sh --check` — well-formed.
- `bash tools/preamble_cap.sh` — CAP OK.
- `python3 tools/check_capability_citations.py` — OK, 82 verified.

### Claim boundary

One machine, one dataset, one trait, single-run cells (best-of-N within a run, not replicated
across sessions). No seeds, no pre-declaration, no MCSE, no second architecture, no thread
sweep (`#364` remains open and this was 1 Julia thread / 8 BLAS). ASReml is licence-gated and
**development evidence only** — not a comparator gate, not covered-flip evidence, no
`validation_status()` row. `public_covered_count` stays **7**. Nothing here says anything
about genomic, non-Gaussian, multivariate, or large-pedigree runtime; `#359` stays open.
