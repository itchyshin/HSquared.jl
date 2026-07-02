# 2026-07-02 — Phase 5 sparse benchmark + direct–maternal 2nd comparator + DM intervals `[JL]`

Three additive deliverables from one session (Claude solo, Fable). **No covered flip; no R
edits; honesty pins held** — `validation_status()` rows **53** / covered **13** UNCHANGED,
`public_covered_count` **5** UNCHANGED. Branch `feat/2026-07-02-phase5-sparse-benchmark`
(PREDECL `662663ed`).

## 1. Phase 5 sparse-vs-dense AI-REML performance benchmark (V3-NEFFECT-SPARSE, stays `partial`)

The one owed compute-gated item — the sparse estimator's timing/scaling — is now MEASURED under
the doc-16 pre-declaration discipline (predeclaration `662663ed` committed BEFORE the run; harness
`sim/phase5_sparse_aireml_benchmark.jl` byte-identical to that commit). Run on `totoro`
(1-core, `OPENBLAS_NUM_THREADS=1`, julia 1.10.10). **GO** decision per the pre-declared rules.

- **Crossover (C2):** sparse ≤ dense at ALL overlap sizes — K=3 min-time **122×→692×** (q=200→1000),
  monotone, sign-stable across seeds, dense `converged=true` (fair comparison). Same-optimum
  verified: max |σ_sparse−σ_dense| = **3.3e-5** (K=3) / 1.8e-5 (K=1), ≤ 0.01 gate.
- **Scaling (C1, descriptive):** K=1 sparse log-log slope **1.01** (R²=0.986, near-linear to
  q=50000); K=3 slope **2.25** (R²=0.975; 2.67 tail) — both below dense's O(n³).
- **Headline finding:** the K=1-vs-K=3 contrast pinpoints the multi-effect environmental-group
  columns' Cholesky fill-in as the K≥2 scale bottleneck (K=1 additive scales linearly; adding iid
  env blocks makes it quadratic). Identifies a fill-reducing ordering (METIS) as the next enabler.
- **Confound (C3):** sparse ~8–11 AI/Newton iters vs dense ~250–276 NelderMead f_calls — both
  fewer iters AND cheaper per iter (disclosed, descriptive).
- **Transparent declared-grid deviation:** the initial declared-grid run reached q=10000 (K=3) but
  did NOT complete a q=20000 fit in ~26 min (super-quadratic fill-in) → K=3 capped at the feasible
  range, K=1 ran the full grid; the RUN not completing the top cells (harness unchanged) is the
  honest feasibility-ceiling result, not a claim relaxation. Declared-attempt log preserved
  (`r3_bench_declared_attempt.log`).
- Evidence: `docs/dev-log/recovery-checkpoints/2026-07-02-phase5-sparse-benchmark{,-predeclaration}.md`;
  raw `sim/phase5_sparse_benchmark_{K3,K1}.tsv`.
- Harness pre-freeze review: Karpinski (timing) + Gauss (same-optimum) SOUND-WITH-FIXES → all
  applied; pre-declaration pre-freeze review: Fisher (decision rule) + Rose (freeze baseline)
  → all applied.
- Additive payload-safe source edit: `fit_multi_effect_reml` now returns `iterations`/`f_calls`
  (`result_payload_v2` field-selects → frozen payload shape unchanged).

## 2. Direct–maternal BLUPF90 2nd comparator (V4-DIRECT-MATERNAL, stays `covered`)

Discharges the explicitly-named owed 2nd same-estimand comparator on a covered model. `blupf90+`
2.60 AIREMLF90 2×2-G via `OPTIONAL mat` (RANDOM_GROUP add_an_upginb) converged from a NEUTRAL start
(12 rounds) to the engine optimum on the SAME `comparator/sommer_dm/` fixture: σ²_ad 1.13280,
σ²_am 0.46851, σ_dm −0.22499, σ²e 0.95484 — **~3e-5** rel.diff on all four vs
`engine_target.csv` (tighter than the sommer leg's 1.1e-2). Dam-identification verified (dm.csv
`dam_id` == pedigree dam for all 960 records → same Z_m estimand). Independently verified against
the raw `comparator/blupf90_direct_maternal/blupf90.log` "Final Estimates". Emitter
`comparator/prepare_blupf90_direct_maternal.jl`; packet + binaries gitignored. Checkpoint
`docs/dev-log/recovery-checkpoints/2026-07-02-direct-maternal-blupf90-comparator.md`. Point-estimate,
single fixture; no status flip.

## 3. Direct–maternal asymptotic delta intervals (V4-DIRECT-MATERNAL, additive engine code)

`fit_direct_maternal_reml` returned point estimates only; NEW exported `direct_maternal_interval`
adds observed-information (central FD-Hessian of the REML loglik in the natural VCs) → delta-method
SEs/CIs for σ²_ad/σ²_am/σ_dm/σ²e, r_am (Fisher-z, stays in (−1,1)), and the Willham labelled triple
(direct h², m², total h²_T). Labelled ASYMPTOTIC/UNCALIBRATED (house convention); throws on non-PD
information (boundary/flat surface). NEW internal export only — no R-consumed signature change.
Reuses the `repeatability_interval` FD-Hessian + delta idiom. Independently corroborated: the delta
SEs agree with BLUPF90's AI-matrix SEs (§2's run) to ~4–12% (max 11.5%; both asymptotic). Testset
"direct_maternal_interval (asymptotic delta-method SEs/CIs)" — 32/32.

## Hygiene (Block 7)

- `src/likelihood.jl:1661` INTERPRETATION FENCE (Falconer)→(Willham) — lone-outlier tag fixed (the
  other 3 surfaces already said Willham; the statement is the Willham total-h² decomposition).
- doc-33→doc-16 "substitutable gate" shorthand canonicalized in `validation_status.jl` (6),
  `capability-status.md`, `validation-debt-register.md`, and the `test/runtests.jl:440` comment
  (doc-16 is the in-repo canonical which already credits the R-twin doc-33 as origin; no literal
  R-repo file-path doc-33 refs in these files).
- `.gitignore`: added the regenerable comparator packets (`sommer_neffect`, `sommer_rr`,
  `blupf90_neffect`, `blupf90_direct_maternal`, `bin`) + `sim/*.log.txt`.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'` — GREEN (interval testset 32/32; count guard
  `test/runtests.jl` pins 53; no failures; 2026-07-02).
- `julia --project=docs docs/make.jl` — GREEN (exit 0, zero dead links). The new
  `direct_maternal_interval` docstring's `[`fit_direct_maternal_reml`](@ref)` cross-ref exposed a
  pre-existing manual gap (the covered fitter was never in `docs/src/api.md`); added BOTH the
  fitter + the interval to `api.md` (resolves the `@ref`, documents the direct-maternal family).
- Real `rose-systems-auditor` (Fable) audit over all three deliverables → **PROMOTE-WITH-CHANGES**
  (benchmark PROMOTE, BLUPF90 comparator PROMOTE, DM intervals PROMOTE-WITH-CHANGES). Rose
  independently reproduced every load-bearing number (byte-identity vs `662663ed`; K=3 speedups
  122×–692×; sparse slopes 2.253/1.009; same-optimum 3.3e-5/1.8e-5; BLUPF90 ~3e-5; honesty pins).
  3 doc-hygiene fixes REQUIRED + APPLIED: (1) the delta-vs-AI SE cross-check softened "~10%" →
  "~4–12% (max 11.5%)" across all 4 surfaces + the 4 numbers banked in the DM comparator
  checkpoint §7b; (2) this Checks section completed (dangling scratch-log ref dropped); (3)
  `/docs/package.json` gitignored (transient Documenter/npm artifact).
- Honesty pins: rows 53 / covered 13 / `public_covered_count` 5 UNCHANGED (verified live at all
  pin sites; `tools/` + `control-centre/` untouched). V3-NEFFECT-SPARSE stays `partial`;
  V4-DIRECT-MATERNAL stays `covered`. Nothing promoted.
