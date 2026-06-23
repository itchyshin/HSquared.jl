# After-task — Wave-F kickoff (S0/F0) + F1 Meuwissen–Luo O(n) inbreeding — 2026-06-23

## Task goal

Open **Wave F** (production sparse foundation, Track A) on DRAC compute and land its
first hardening slice. Two-track plan recorded in
`docs/design/17-wave-F-foundation-and-genomic-gpu.md` (Foundation-first → build → prove
→ bank; no `covered` promotion this wave). **S0/F0** = a reproducible DRAC scale-benchmark
harness + a measure-first baseline that LOCATES the bottleneck. **F1 (B3)** = replace the
dense O(n²) inbreeding step (the located bottleneck) with the Meuwissen & Luo (1992)
O(n·ancestors) method so `pedigree_inverse` scales. `[JL]` engine-only; stays within the
already-`covered` V1-AINV tiny-pedigree claim (no large-scale *correctness* promotion).

## Active lenses / spawned agents

Henderson + Gauss + Mendel (the `A = T·D·Tᵀ` derivation, the sentinel `F_0=−1`, selfing);
Karpinski (the inline max-heap, O(n) scaling); Curie (the deterministic oracle + scaling
tests). A real `rose-systems-auditor` subagent audited the branch before merge (see Checks).
Measure-first runs executed live on **fir** (DRAC, `def-snakagaw_cpu`).

## What I derived (and what the measure-first found)

- **F0 found the bottleneck by running, not guessing.** `pedigree_inverse → inbreeding_
  coefficients → _numerator_relationship` materializes the **entire dense n×n** numerator
  relationship just to read its diagonal (`A[i,i]−1`), guarded by `max_relationship_cache
  = 10_000`. So Ainv refused to build past q=10⁴ (~80 GB dense at 10⁵). fit/PCG/selinv were
  all fast and far from their walls. → F1 is the critical path. (`2026-06-23-f0-scale-baseline.md`.)
- **M–L derivation.** `A = T·D·Tᵀ` ⇒ `A_ii = Σ_j L_ij² d_j`, `F_i = A_ii − 1`, with `d_j =
  0.5 − 0.25(F_sire(j)+F_dam(j))` (Mendelian sampling variance; unknown-parent sentinel
  `F_0 = −1`). Accumulate animal `i`'s T-row over its ancestors processed **strictly
  youngest-first** (a max-heap guarantees descending index order, the correctness
  condition). Never forms `A`; ~O(n·ancestors). Hand-verified on founder (F=0),
  unrelated-parents (F=0), and selfing (F=0.5) before coding.

## Files changed

- `src/pedigree.jl` — new `_meuwissen_luo_inbreeding(pedigree)` + inline binary max-heap
  `_ml_heappush!`/`_ml_heappop_max!`; `inbreeding_coefficients` now delegates to M–L
  (`max_relationship_cache` kept for signature compat, no longer bounds inbreeding; dense
  `_numerator_relationship` retained as the oracle + for `additive_relationship`/A₂₂).
- `test/runtests.jl` — new `@testset "F1 Meuwissen-Luo inbreeding (O(n), no dense cap)"`
  (10 assertions); replaced the obsolete `@test_throws ArgumentError inbreeding_
  coefficients(…; max_relationship_cache = 2)` (tested behaviour F1 deliberately removes)
  with an oracle-match assertion.
- `sim/drac/f0_scale_benchmark.jl` (+ `f0_fir.sbatch`, `f0_fir_scale.sbatch`) — the opt-in
  DRAC scale harness (gene-dropping O(q) DGP; per-step timing + peak RSS).
- `docs/dev-log/recovery-checkpoints/2026-06-23-f0-scale-baseline.md` — F0 baseline + F1
  after-curve.
- `docs/design/capability-status.md` (Sparse `Ainv`) + `docs/design/validation-debt-register.md`
  (V1-AINV) — M–L rows.
- `docs/design/17-wave-F-foundation-and-genomic-gpu.md` — the wave spec.
- `docs/dev-log/check-log.d/2026-06-23-f1-meuwissen-luo.md` — evidence chain.

## Checks run and exact outcomes

- **Oracle (exact):** M–L `F` == dense `_numerator_relationship` diagonal to `maxdiff =
  0.0` (bit-identical) on calf/sire/dam (F=0), inbred half-sibs (F=0.25), a 3-gen selfing
  chain (F=0.875), and a random 300-animal inbred pedigree (local probe); `≈` on a
  deterministic q=2000 inbred pedigree (in-suite). Selfing canonical series
  `[0, 0.5, 0.75, 0.875]` pinned.
- **Scaling unblock:** q=12000 runs in `test/runtests.jl` (was capped). On fir: q=30000
  ran (previously threw); the scale curve q=30k/100k/300k shows Ainv build O(n) (0.021 →
  0.054 → 0.337 s), peak RSS ≤1.4 GB. The **next** wall is `fit_ai_reml` (0.51 → 2.82 →
  35.6 s, super-linear; **non-converged at q=300k**) → F2/F3, untouched by F1.
- **Local `Pkg.test()`** (thread-capped, julia 1.10.10): green — `JULIA_EXIT=0`, F1 testset
  **10/10**, "Testing HSquared tests passed". (The first run caught the obsolete
  `@test_throws`; fixed and re-ran green.)
- **`julia --project=docs docs/make.jl`:** green (exit 0) after fixing two dead `@ref`
  links — docstring cross-refs to the *internal* `_meuwissen_luo_inbreeding` /
  `_numerator_relationship` (not in the manual) → plain code spans (the H2 precedent).
- **Real `rose-systems-auditor` subagent over the branch:** **PROMOTE-WITH-CHANGES →
  addressed.** Rose independently re-verified the kernel correct on genuinely-inbred
  pedigrees (random q=1500 with real loops; full-sib F=0.25; half-sib F=0.125; a
  5000-trial max-heap descending-pop property check) and the honesty framing CLEAN. It
  caught a REAL test defect (below), now fixed. Also a provenance nit (commit the raw
  scale TSV) — addressed (`sim/drac/results/f0_scale2_45510086.{tsv,out}` committed).

## Public claim audit (Rose)

- V1-AINV was already `covered` for tiny-pedigree Ainv correctness; F1 makes the inbreeding
  path O(n) and adds large-scale *evidence* (exact-vs-oracle to q=2000, runs to q≥3×10⁴)
  but does **not** promote a large-scale correctness claim. Nothing promoted to `covered`;
  `validation_status()` row count unchanged.
- NOT claimed: production fitting, competitive performance, or that the whole `pedigree_
  inverse` is "production-scale". Timings are opt-in single-machine DRAC measurements.
- The `fit_ai_reml` non-convergence at q=300k is disclosed (next-wall finding), not hidden.

## What did not go smoothly

- Two cheap bugs caught by small-q validation before any scaled job: the benchmark's
  original deterministic `y` had no genetic signal (AI-REML hit the σ²a boundary) → switched
  to O(q) gene-dropping; and a fit-object field misread (`fit.sigma_a2` → `fit.variance_
  components`).
- The first full `Pkg.test()` "exit 0" was a `| tail` pipe masking julia's real exit (the
  documented trap) — re-ran capturing the real exit, which surfaced the obsolete
  `@test_throws`. Fixed.
- **Rose caught a vacuous test fixture (the kernel was fine).** My `det_inbred` used
  `s[i]=(7i)%(i-1)+1`, `d[i]=(13i+3)%(i-1)+1` — but `7i mod (i-1) = 7` and
  `(13i+3) mod (i-1) = 16` for all large `i`, so the rule **collapses to constant parents
  (8, 17)** and every offspring is a non-inbred full sib (**0 inbreeding**). The q=200/2000
  "inbred" oracle assertions were therefore `0.0 ≈ 0.0` (vacuous), and the word "inbred" in
  the rows was unsupported. Verified Rose's claim (it was right), then replaced the rule
  with multiplicative-hash mating → genuine bounded inbreeding (q=2000: 1869/2000 inbred,
  meanF 0.08, maxF 0.56; maxdiff vs oracle 0.0; pedigree_inverse stable at q=12000) plus a
  `count(F > 1e-9) > q÷2` anti-vacuous guard so it cannot silently regress. The M–L kernel
  needed no change.

## Known limitations

- M–L uses a max-heap (O(n·ancestors·log)); the Quaas linked-list variant (no log factor)
  is a possible later micro-opt — not needed at current scale.
- F1 changes ONLY inbreeding. `fit_ai_reml` (factorization fill-in + convergence) is the
  next bottleneck → **F2** (fill-reducing ordering) + **F3** (AI-REML hardening), surfaced
  by this run.
- No external nadiv/pedigreemm inbreeding comparator run in-suite (the dense oracle is the
  in-suite check; the R-side `nadiv::makeAinv` comparator remains the cross-lane option).

## Next actions

1. Fill the two `__PENDING__` outcomes (docs build, Rose verdict); address Rose findings.
2. Push branch, open PR, self-merge on green CI + Rose clean (pre-authorized, in-scope).
3. Then **F2** (fill-reducing ordering) — re-run F0 to measure the factorization wall the
   q=300k run exposed; and/or **F3** (AI-REML convergence hardening for the q=300k case).
