# HSquared.jl Agent Instructions

`HSquared.jl` is the Julia computational twin of the R package `hsquared`.
The R package owns the public user language; this Julia package owns the
engine reality.

## Live Phase Snapshot

> Refresh this block in every after-task report (GLLVM.jl pattern). Repo state
> is truth; this is the at-a-glance pointer.

- **As of 2026-06-30 (autonomous overnight segment — TWO staged PRs; Claude solo; `main` @ `c2b5babc`/#210
  UNCHANGED).** Delivered two complete, CI-green, real-Rose-audited slices, both staged for the maintainer
  (not merged): **[#211](https://github.com/itchyshin/HSquared.jl/pull/211) v0.4 MV broader-DGP recovery** —
  full-sib + 3-trait recovery **DISCHARGED** on the covered `V4-MV-REML` row (pre-declared 48-seed Totoro
  gates both PASS; Curie/Fisher/Mendel pre-run panel; additive, covered UNCHANGED, count 48); and
  **[#212](https://github.com/itchyshin/HSquared.jl/pull/212) v0.6 ordered-categorical (ordinal) probit family
  kernel (T1)** — new internal `OrderedProbitResponse` (exact K=2→probit reduction, log-concave observed-info
  weight), experimental/`partial`, count 48→49 on-branch. **Honesty pins on `main` UNCHANGED:**
  `validation_status()` = 48, covered 8, **public-covered FITTING = 1**. Comparator finding: v0.6 same-estimand
  tool is **`ordinal::clmm`** (Laplace-ML) — **glmmTMB does NOT fit cumulative-link ordinal models**. Stale PRs
  #193/#191 worth closing. **NEXT: maintainer review/merge #211 (G10) + #212; then finish v0.6 T1 (cutpoint
  estimation + `ordinal::clmm` comparator + recovery gate) or V5 GCTA.** START HERE:
  `docs/dev-log/handover/2026-06-30-claude-handover-v04-v06.md`.

- **As of 2026-06-30 (v0.5 QTL genome-wide significance → COVERED, scoped; Claude solo; `HSquared.jl` `main` @
  `261b52c7`/#209; `hsquared` `main` @ `c4e73ef`/#114; maintainer G10 GIVEN + merged).** Resumed a frozen
  session and finished v0.5 to covered across both twins, every slice pre-registered + real-Rose-audited.
  **V5-MARKER-THRESHOLD `partial → covered` (SCOPED, validation-scale, opt-in)** via the doc-16 substitutable
  gate (the **type-I-control adaptation of G11** — the first NON-point-estimator covered row): the EXACT
  per-dataset add-one permutation rule (`genome_wide_marker_scan` / R `gwas(genome_wide=TRUE)`), **type-I
  CONTROL only, fixed-effect/intercept-only**, on the tested LD designs. Legs: validation type-I gates #203/#204
  + **production REBUILD gate #207** PASS (mean type-I 0.0542/0.0504 at α; the REUSE shortcut FAILED → banked
  negative + diagnosed; the `(1-α)` quantile rule #202 FAILED → banked) + **PLINK max(T) comparator #205** +
  R activation **hsquared #113** (live-verified) + engine entry point #208. Real Rose on the flip →
  PROMOTE-WITH-CHANGES (two DoD docs added: check-log entry + doc-16 exemplar). `validation_status()` = **48
  rows / covered 7→8 / partial 37→36**; **public-covered FITTING = 1 UNCHANGED** (V5 is opt-in significance,
  NOT a fitting capability, NOT the public default). The R public `gwas(genome_wide=TRUE)` surface STAYS
  **experimental** (engine-covered ≠ R-public-covered; V4-MV-REML / Rose-risk-5 pattern). FENCED OUT:
  mixed-model/LOCO null, power/coverage, broader-LD/covariate-adjusted, the quantile rule + reuse shortcut, the
  map-annotated formula API — STANDING DEBT retained (2nd external comparator GCTA/statgenGWAS, mixed-model
  calibration, #45). Infra: **Totoro** (384-core server) set up + persisted to memory; **JuliaCall** installed
  (live R↔Julia bridge verified). **NEXT: v0.4 broader-DGP MV recovery · V5 standing debt (GCTA 2nd comparator)
  · v0.6 non-Gaussian (T1 ordinal/threshold, glmmTMB comparator).** The maintainer's `/goal` "finish all of
  v0.5" is ACHIEVED — `/goal clear` if it lingers. START HERE: `docs/dev-log/handover/2026-06-30-claude-handover.md`.

- **As of 2026-06-30 (V2-GREML genomic REML → covered, validation-scale; branch `feat/2026-06-30-v2-genomic-recovery-gate`, PR pending for G10; `main` @ `6acd451c`/#200).**
  The 24-hour goal's headline. Genomic REML (`fit_gblup_reml`) cleared the doc-16 **G11** covered bar on
  BOTH owed legs: (1) a **PRE-DECLARED bias/MCSE recovery gate** (`sim/phase2_genomic_reml_recovery.jl`;
  predeclaration committed `cb22e679` BEFORE the run, harness byte-identical pre/post → no relaxation) —
  48 cold-start seeds (N=300/M=1000, fresh VanRaden `G` per seed, exact-model `u ~ N(0, K·σ²g)`, `K =
  inv(Ginv)`), **48/48 converged, `|bias| ≤ 2·MCSE` for σ²g/σ²e/h²** (no detectable across-seed bias,
  never "unbiased"); (2) the executed **`blupf90+` 2.60 same-estimand comparator** (PR #200, neutral start →
  optimum ~1e-5, same-`Ginv` isolation). **Real Rose audit → PROMOTE** (both legs verified independently
  incl. the predeclaration-before-result commit ordering + a harness re-run). **Atomic flip** across all 3
  surfaces (`validation_status()` covered **6→7**, capability-status, debt-register); `validation_status()`
  = **48 rows UNCHANGED**; **public-covered FITTING = 1** (v0.1 Gaussian). SCOPE: supplied-`Ginv` REML
  ESTIMATOR / exact-model / N=300 single design — G-construction (`V2-GRM`) stays experimental, no
  production sparse-`G`, no R surface, NOT the public default. The flip + merge is the maintainer's atomic
  **G10** (PR staged, not self-merged). **NEXT: v0.5 (QTL null-DGP thresholds) or v0.4 (broader-DGP MV).**
  START HERE: `docs/dev-log/after-task/2026-06-30-v2-genomic-covered-close.md`.

- **As of 2026-06-30 (session resume: #198 merge + h² scale contract + genomic BLUPF90 comparator — Claude solo; branch `docs/2026-06-30-h2-contract-genomic-comparator`, PR pending; `main` @ `948527cd`/#198).**
  Resumed a frozen session; three maintainer asks. (a) **#198 MERGED** (`948527cd`, CI green; RR k=2 covered
  aim + non-Gaussian family plan); local `main` ff'd; the mission-control board (`:8791`) had died with the
  frozen session → **restored + regenerated** (`public_covered=1` pin intact). (b) The paused **v0.2 genomic
  comparator is RUN + PASSES**: `blupf90+` 2.60 AI-REML on the same-`Ginv` isolation packet
  (`comparator/prepare_blupf90_genomic.jl`, N=300/M=1000) converges from a NEUTRAL start (6 rounds) to
  `fit_gblup_reml`'s optimum — σ²g/σ²e/h² agree to ~1e-5 (BLUPF90 5-sig-fig floor) — the same-estimand REML
  leg doc-18 §priority-3 flagged owed; banked as a recovery-checkpoint + a `V2-GREML` clause (point-estimate /
  single fixture / same-`Ginv`; **stays `partial`** — committed recovery study + `sommer`/`rrBLUP` 2nd leg +
  `V2-GRM` G-construction still owed). (c) The **h² scale contract is pinned** (`docs/design/19-h2-scale-contract.md`)
  and **literature-verified** against a new trusted-PDF NotebookLM page (de Villemereuil 2016 / NS 2017 /
  Dempster–Lerner): π²/3-placement, QGglmm-integration vs NS-delta `1/[p(1−p)]`, `h²_obs=h²_liab·z²/[p(1−p)]`,
  probit-latent=liability, cloglog π²/6 — all confirmed. `Pkg.test()` green (count-guard 48 intact); **real
  Rose audit → PROMOTE (clean, all pins verified independently)**; nothing promoted; `validation_status()`=48;
  public-covered FITTING=1. **NEXT (maintainer-directed): code v0.2 (committed recovery study) → v0.4
  (broader-DGP MV recovery + in-suite `sommer`) → v0.5 (QTL null-DGP thresholds + `marker_scan()`).**
  START HERE: `docs/dev-log/after-task/2026-06-30-h2-contract-genomic-comparator-resume.md`.

- **As of 2026-06-30 (BLUPF90 multitrait `renumf90.par` emitter fix — Claude solo; `main` @ `c43e37c9`/#197; hsquared R twin untouched).**
  Closed the 2026-06-29 v0.4 next-action #3. `comparator/prepare_blupf90_multitrait.jl` emitted a
  `renumf90.par` that real `renumf90` 1.166 rejects (datafile name INLINE → renumf90 read `TRAITS` as the
  datafile; `EFFECT … cross numer` should be `cross alpha`; `FILE_POS` missing). Rewrote `renum_lines` to the
  verified format (separate-line `DATAFILE`; blank `FIELDS_PASSED`/`WEIGHT(S)` value-lines; `cross alpha`;
  `FILE_POS 1 2 3 0 0`) — byte-for-byte vs `renumf90_fixed.par`, same format as the sibling
  `prepare_blupf90_two_effect.jl`; relaxed the validator's incorrect no-blank rule; updated the `#49`
  preflight (42/42). **Gap closed END-TO-END:** re-downloaded `renumf90` 1.166 + `blupf90+` 2.60 (UGA,
  MKL-free, Rosetta) and RAN the regenerated packet — renumf90 accepts the emitted par DIRECTLY (no manual
  `renumf90_fixed.par`) and `blupf90+` AI-REML converges from a NEUTRAL start (7 rounds) to the fixture
  optimum (~1e-5). `Pkg.test()` green; CI green (Julia 1/1.10/docs/documenter); a real `rose-systems-auditor`
  audit (**PROMOTE-WITH-CHANGES**) required three evidence-hygiene sweeps (a stale `renumf90_fixed.par`
  reference in the `validation_status()` runtime string, the stale "follow-up" framing in the 2026-06-29
  entry below, and the self-claimed close-out) — all applied. **Tooling-only:** `validation_status()` = 48
  UNCHANGED (one row's evidence string swept; no status/count change), public-covered FITTING = 1, nothing
  promoted, no API/default/R-wording change; the other lane's v0.3 work (#195/#196) landed concurrently and
  #197 stacked clean. **START HERE:** `docs/dev-log/after-task/2026-06-30-blupf90-multitrait-emitter-fix.md`.

- **As of 2026-06-29 (v0.4 multivariate-unstructured SCOPED COVERED CLOSE — Claude solo; branch `w1/2026-06-29-evidence-week-setup` @ `406f3100` + this slice, PR #194 open; hsquared R twin clean `main` `8c5c886`/#112).**
  Finished v0.4 following doc-18. `V4-MV-REML` was ALREADY `covered` at validation scale; this slice is the
  scoped RATIFICATION, not a flip. Green foundation re-established (`Pkg.test()` PASS + `docs/make.jl` exit 0 —
  the W1-owed local checks). A **real Rose audit** (PROMOTE-WITH-CHANGES) required two mechanical edits, both
  applied verbatim: (A) an explicit **SCOPE OF VALIDITY** sentence on the covered clause (in
  `validation-debt-register.md` + the `validation_status()` function string), and (B) reconciling a **stale
  `experimental`** on `capability-status.md` (it predated the #161 covered promotion) → `covered`, so all three
  VALIDATION-scale surfaces now agree; `06-public-claims-register.md` stays `partial` (correct public-vs-
  validation layering). Honesty pins INTACT: `validation_status()` = 48 (5/3/39/1) UNCHANGED, **public-covered
  FITTING = 1** (v0.1 Gaussian), no API/default/R-wording change. BLUPF90 (the owed 2nd same-estimand
  comparator) was then **RUN** (user-authorized): `blupf90+` 2.60 AI-REML (Mac x86_64, MKL-free, Rosetta) from
  an independent NEUTRAL start converges (7 rounds) to the fixture optimum — G0/R0 ~1e-5, β ~1e-7, EBV corr
  1.000; a 2nd real Rose audit (PROMOTE-WITH-CHANGES → scope tag applied) → the 2nd-comparator owed item is
  **DISCHARGED (point-estimate, single fixture)** across all three validation-scale surfaces (a packet
  `renumf90.par` emitter bug was found + worked around; prepare-script fix is a follow-up). PENDING
  (human-only): maintainer **G10** to ratify the scoped claim + the BLUPF90 discharge; push + merge PR #194;
  D2 interval-default (profile-LRT, needs Codex + G10). **START HERE:** `docs/dev-log/after-task/2026-06-29-v04-mv-scoped-finish.md`.

- **As of 2026-06-29 (Codex small-sample interval calibration branch + Claude handover; HSquared.jl branch `codex/small-sample-interval-calibration`, commits `d7effc79` + `6581828f`, hsquared R twin clean `main` `8c5c886`/#112, PR pending/opened from branch).**
  Banked `V1-HERIT-TCAL` as a **planned** validation-debt row for Gaussian small-sample interval calibration and added the opt-in ADEMP/freqTLS/NotebookLM evidence chain plus a resumable harness (`sim/phase1_small_sample_interval_calibration.jl`). The harness now writes replicate-level detail TSVs with deterministic per-replicate seeds, `--detail-out`, `--resume`, `n_boot`, SW `df_eff`, failure reasons, boundary flags, and bootstrap convergence counts. Evidence remains TRIAGE ONLY: smoke output, a 200-rep no-bootstrap grid, and a 10-rep/9-bootstrap subset prove wiring/resumability and record negative/unstable SW behavior; they do **not** calibrate coverage. Decision checkpoint: do NOT expose t/Satterthwaite calibration, do NOT change interval defaults/API/R wording, do NOT move `validation_status()` (still 48 rows, planned=1, covered=5). DRAC aliases responded for Vulcan/Trillium/Rorqual/Nibi/Narval/Fir, but no cluster checkout was found and no login-node compute was run; next credible run needs a staged `/project` checkout + SLURM arrays. Two foreign untracked files remain never-stage. **START HERE:** `docs/dev-log/handover/2026-06-29-claude-handover.md`.

- **As of 2026-06-24 (R CI greened + handover to Codex; hsquared `main` `8c5c886`/#112; HSquared.jl `main` `06c7e71b`/#189).**
  The pre-existing `R/validation-status.R` non-ASCII WARNING that kept hsquared CI red is **FIXED** — it was a single
  em-dash → `—` (runtime output identical, verified); **hsquared #112 merged on the FIRST green hsquared CI** (clean,
  no admin). Also banked an evidence-based finding: **HSquared.jl intervals are ALL asymptotic** — normal-z Wald/delta
  (`_standard_normal_quantile`; the default `heritability_interval(:delta)`) + χ²₁ profile-LRT (`q = z*z`,
  `src/likelihood.jl:1491`); **no small-sample t-calibration (`qt`/df) anywhere** (`interval_method="asymptotic_reml"`);
  the parametric **bootstrap** (`bootstrap_variance_component_interval`, C6) is the only finite-sample-aware path (opt-in,
  uncalibrated). A small-sample t-calibration (design-based df, validated by coverage sim) is a cross-repo candidate, NOT
  yet a debt row. **Codex now active in the same repo** — wrote a Codex-addressed handover. NOTHING promoted to covered
  (still v0.1 Gaussian; `validation_status()` = 48). **START HERE:** `docs/dev-log/handover/2026-06-24-codex-handover.md`.

- **As of 2026-06-24 (the A→D "stop-today" list CLOSED + R-twin parity; HSquared.jl `main` `95c82b1a`/#188; hsquared `main` `4fa4b16`/#111).**
  Landed the full NotebookLM-scout improvement sequence and its R-twin parity. **A** (#186) — opt-in
  EM-REML warm-start in `fit_ai_reml` (`em_warmup`, default 0 = byte-identical; **optimum-INVARIANT** on
  identified fits + **rescues bad-start convergence**; NOT a #182 fix). **B** (log-variance reparam)
  **TRIED → REVERTED** — naive log-reparam of the AI step is numerically unstable AND #182 is already
  correct (non-identified → `converged=false` is right, not a bug); honest negative banked. **C** (#187) —
  Wave F G1 GPU VanRaden `G`/`Ginv` **RAN on tamia** (4× H100, job 352612): CPU↔GPU agreement ~1e-14 across
  all variants; benchmark GEMM 1.3×→~5× (m 2k→40k) / ridge Ginv ~2.7–2.9×; `V2-GRM-GPU` rows flipped to
  "GPU-agreed + benchmarked". **D** (#188) — `preconditioner=:ichol` for `solve_animal_model_pcg` (right-
  looking IC(0) + Manteuffel shift): CORRECTNESS primitive (matches direct solve ~1e-15; ≤ plain-CG iters,
  21→19 Jacobi→16 IC(0)); no performance claim. **R-twin parity for A** merged (hsquared **#111**):
  `em_warmup` exposed via `hs_control(engine_control=…)` → bridge → `fit_ai_reml`; live-verified well-formed
  call + optimum-invariant (VC diff 5.3e-9). B/C/D need no R parity (reverted / experimental-engine-GPU-not-
  covered / internal-no-surface). **Five real Rose audits this session, all CLEAN.** **NOTHING promoted to
  covered** (public default still v0.1 univariate Gaussian; `validation_status()` = 48 rows). KNOWN: hsquared
  R CI is red ONLY on a PRE-EXISTING `R/validation-status.R` non-ASCII WARNING (`0 errors | 1 warning |
  0 notes`; NOT this work — a background-task chip captures the `\uxxxx`-escape fix). START HERE:
  `docs/dev-log/handover/2026-06-24-session-handover.md`.

- **As of 2026-06-23 (EM-REML warm-start authored; main at `f3635d66`/#185; this slice = next PR).**
  Merged **#184** (Wave F G1 GPU genomic `G`/`Ginv`; now RUN on tamia — CPU↔GPU agreed to ~1e-14 +
  benchmarked, GEMM 1.3×→~5×, job 352612) and
  **#185** (the two stale #182 boundary comments); combined `main` re-verified green. A NotebookLM
  methods scout (cross-project KB; leads banked in `shinichi-brain/memory/LEARNINGS.md`) surfaced
  **PX-AI** as the top fastest-REML lead → implemented its base: an **opt-in EM-REML warm-start** in
  `fit_ai_reml` (`em_warmup`, default 0 = byte-identical; the EM update is the closed form that zeroes
  the REML score, monotone + in-bounds). HONEST result: **optimum-INVARIANT** on identified fits +
  **rescues convergence from extreme starts** (a (1e4,1e-2) start non-converged at em=0 → converges at
  em≥3; `sim/em_warmstart_benchmark.jl`), but it does **NOT** fix the σ²→0 / non-identified #182
  boundary (still `converged=false` — that's **B = log-Cholesky reparam**, next). `Pkg.test()` 23/23
  new + full suite green; `docs/make.jl` green; real Rose **CLEAN** (no overclaim). NEXT: PR this → B
  (log-Cholesky reparam, the actual #182 fix) → C (G1 tamia run) → D. START HERE:
  `docs/dev-log/after-task/2026-06-23-px-em-warmstart.md`.

- **As of 2026-06-23 (Wave F Track B G1 authored; main at `627ab754`/#183).** Closed the #182
  loose thread (real Rose audit on the merged boundary fix → **CLEAN**, fully banked) and merged
  **#183** (docs-only handover correction). Then authored **Track B G1** — GPU VanRaden `G`/`Ginv`
  as a `CUDA` weak-dep extension (`HSquaredCUDAExt`, the same OUT-of-CI posture as the Makie
  extension): EXPORTED stubs `gpu_genomic_relationship_matrix` / `gpu_genomic_relationship_inverse`,
  the device `W·Wᵀ/k` GEMM + ridge Cholesky inverse reusing the validated CPU `centered_markers`
  (SAME estimand by construction), an opt-in CPU↔GPU agreement + benchmark script
  (`sim/drac/g1_gpu_genomic.jl`) + a tamia sbatch (`g1_tamia.sbatch`), a 7-assertion CI stub test,
  and three honest status rows (`V2-GRM-GPU` partial; `validation_status()` 47→48). **Full
  `Pkg.test()` + `docs/make.jl` green; real Rose audit CLEAN.** HONESTY FENCE: the CUDA code is
  **authored but NOT yet run on a GPU** (no NVIDIA GPU on the dev Mac) — the CPU↔GPU agreement +
  benchmark are OWED, pending a committed tamia run + ingested `.tsv`; NO agreement/performance
  claim; nothing `covered`. NEXT: push/PR + the tamia run handoff (then flip the rows to
  "GPU-agreed + benchmarked"), then G2/G3/G4 (independent) + G5. START HERE:
  `docs/dev-log/after-task/2026-06-23-g1-gpu-genomic.md`.

- **As of 2026-06-23 (Wave F kickoff on DRAC; main at `d5d2b9b1`/#180).** Stood up DRAC HPC
  (Fir CPU `def-snakagaw_cpu`; tamia GPU `aip-snakagaw`, 4× H100 verified) and opened **Wave F**
  (production sparse foundation + genomic GPU, two co-equal tracks,
  `docs/design/17-wave-F-foundation-and-genomic-gpu.md`) by **measure-first** on real q=10⁵–10⁶
  pedigrees. **Two engine slices landed:** **F1** (#179) Meuwissen–Luo O(n) inbreeding —
  `_meuwissen_luo_inbreeding` replaces the dense O(n²) inbreeding that capped `pedigree_inverse`
  at q=10⁴; exact vs the dense oracle; Ainv build at q=300k = 0.337 s (was impossible past 10⁴).
  **F3** (#180) scale-invariant AI-REML convergence — the q=300k wall was NOT factorization
  (measured 0.15 s; METIS gives ~1% fill, **not implemented**) but `fit_ai_reml` running to its
  100-iter cap on a non-scale-invariant `hypot(score)<tol` check (the score scales with n);
  fixed by also stopping on the relative VC change → **q=300k 35.6 s/non-converged → 2.3 s/
  converged (15.5×)**. **Track B G0 verified** (tamia 4× H100 `functional=true`, matmul OK);
  genomic-GPU slices unblocked. **Real Rose audits on both** (F1 PROMOTE-WITH-CHANGES → fixed a
  vacuous test fixture; F3 CLEAN on the core fix — but its "green suite" claim was wrong for a
  guarded variant, caught by CI + verify). Two F3 mis-steps (a boundary guard, an `iterations<50`
  assertion) broke CI and were removed; the core convergence fix was correct throughout.
  **Nothing promoted to `covered`** (public default still v0.1 Gaussian). Banked: the Wave F
  spec, the citation-backed algorithm scout doc (`docs/dev-log/scout/2026-06-23-production-sparse-algorithms.md`;
  **METIS overturned by measurement**), the DRAC harness (`sim/drac/`), and the cross-project
  DRAC runbook (`shinichi-brain/tools/drac-setup.md`, incl. the verified CUDA-binding fix).
  **START HERE:** `docs/dev-log/handover/2026-06-23-wave-f-session-handover.md`.

- **As of 2026-06-23 (backlog grind, session 3; main at `a33e50f3`/#176).** Finished the
  six planned backlog slices + resolved the J1 landmine, each full-DoD, one PR per slice,
  self-merged on green CI under pre-authorization. **Six engine slices merged:** **H2**
  (#170) beta-binomial overdispersed-logit Laplace family (added `_lbeta`/`_digamma`,
  `BetaBinomialResponse`, Fisher-information weight `Σ_k score(k)²P(k|η,ρ)`, `dispersion`
  field on `NonGaussianFit`); **H3** (#171) Bernoulli probit / liability-threshold family
  (`BernoulliProbitResponse`, tail-stable `_norm_logcdf`/Mills-ratio weight); **H6** (#172)
  non-Gaussian interval coverage characterization (generalized `laplace_reml_interval`
  cross-family contract test + opt-in uniform-family coverage sim); **H7** (#173) NEW EXPORT
  `nongaussian_heritability` (latent vs observation-scale h², integrating over `N(μ, V_A+
  V_fixed)` — corrected TWO spec errors: the integration variance must NOT include π²/3, and
  Poisson h²_obs is NOT monotone in σ²a); **C2** (#174) NEW EXPORT
  `genetic_correlation_interval` (`:delta` Fisher-z, reuses the MV SE path; extends
  V4-MV-REML, stays `covered`); **C6** (#175) NEW EXPORT `bootstrap_variance_component_interval`
  (parametric-bootstrap percentile CI for σ²a/σ²e/h², `n_converged` honesty hinge; promoted
  `Random` to `[deps]`; extends V1-HERIT-CI). **`validation_status()` 44→47** (3 NEW `partial`
  rows: V6-BETABINOMIAL, V6-PROBIT, V6-NS-H2; C2/C6/H6 APPENDED clauses to existing rows).
  **J1** (#176, LANDMINE) resolved as **docs-only "derived + dual-lens ratified, kernel
  awaiting maintainer ratification"** — the design spec's haplodiploid anchor set is provably
  IMPOSSIBLE (√2 positive-diagonal-congruence contradiction; non-PSD); Mendel + Falconer
  ratified `A = 2θ` with haploid-drone self = 2 (`docs/dev-log/decisions/2026-06-22-
  haplodiploid-relationship-convention.md`); NO kernel shipped, NO capability row.
  **SEVEN real Rose audits** (one per slice; H6/C6/J1 PROMOTE-WITH-CHANGES → addressed;
  J1's one factual Rose flag was itself wrong — a 46-vs-47 count — and was rejected after
  verification). `Pkg.test()` + `docs/make.jl` green locally per slice; CI green on every
  merge. **Public-default covered count UNCHANGED (1 = Gaussian); nothing promoted to
  covered this session** — all new non-Gaussian/interval rows are `partial`
  (coverage/recovery NOT calibrated to a gate). **MAINTAINER DECISION PENDING:** ratify (or
  revise) the J1 `A = 2θ`/drone-diagonal-2 scale + construction-only fence before the
  haplodiploid kernel can land. START HERE: the per-slice after-task reports
  `docs/dev-log/after-task/2026-06-22-{h2,h3,h6,h7,c2,c6,j1}-*.md` and check-log entries
  (H2–C6 in `check-log.md`; J1 in `check-log.d/`).
- **As of 2026-06-22 (backlog grind, session 2; main at `4d4c0f4a`).** Continued the
  100-slice program. Merged the two green PRs the prior handover flagged — **#164**
  (I1 fitted sire-model fixture; honest self-consistency target, not external parity)
  and **#165** (H1 negative-binomial NB2 Laplace family; NB2 loglik/score/weight
  independently re-derived). Then **#166** closed the prior session's DEFERRED
  ledger/evidence follow-ups (C5/C10/I1/H1): +3 `partial` `validation_status()` rows
  (`C10-LRT`, `V1-SIRE-FIT`, `V6-NBINOM`; count 41→44), the C5 genomic-σ²a `.md`
  mirrors + V2-GBLUP cross-ref, the sire comparator-manifest entry, a NEW opt-in NB
  recovery sim (σ²a magnitude honestly REPORTED-NOT-GATED — the Bernoulli information
  effect, NO gate relaxation), and doc-14 ✅ marks. Then **#167** landed **L1**
  (HSquaredMakieExt drawing-only): 5 new Makie `kind`s (`:manhattan`, `:qq`,
  `:rr_variance`, `:rr_surface`, `:rr_eigenfunctions`) consuming existing `*_plot_data`
  preparers; Makie stays OUT of CI, the stub testset is 11 assertions, the LOAD-BEARING
  local CairoMakie draw passed ALL 30 checks (Florence figure-honesty CLEAN). **Two
  real Rose audits CLEAN.** `Pkg.test()` + `docs/make.jl` green on each; CI green on
  each merged PR. **Nothing promoted to covered; public-default covered count UNCHANGED
  (1 = Gaussian); Julia `validation_status()` 41→44 (all new rows `partial`).** START
  HERE: `docs/dev-log/handover/2026-06-22-backlog-grind-session2-handover.md` — the
  complete session-2 handover with the H2 (beta-binomial) spec digested (incl. its two
  correctness traps: the Fisher-vs-observed information weight, and the `NonGaussianFit`
  field blast radius) and the remaining 7 slices (H2 → H3 → H6 → H7 → C2 → C6 → J1-last).
- **As of 2026-06-22 (one-owner consolidation; main at `964448a5`).** The R lane
  CLOSED; one owner now develops BOTH repos (`hsquared` + `HSquared.jl`) from a single
  lane (one cross-repo DoD; review lenses kept, Rose mandatory). Landed: the R stack
  `hsquared#98→#108` merged + live-verified (1445 pure-R + 116 live-bridge); the engine
  PRs `#155→#159` merged (`Pkg.test` green); the 100-slice cross-repo program backlog
  (`docs/design/14-program-backlog.md`, #160); and — the first NEW covered model beyond
  v0.1 Gaussian — **`V4-MV-REML` promoted `partial→covered`** (experimental,
  validation-scale, OPT-IN; NOT the public default) on the doc-33 substitutable gate: a
  PRE-REGISTERED bias/MCSE recovery gate (`a7b1f9ad`) + a fresh 48-seed cold-start run
  that PASSED (`24ee2d9c`) + a real Rose audit (PROMOTE-WITH-CHANGES) + B1/B2 honesty
  fixes + maintainer sign-off (`#161`, merge-commit `964448a5`). Public-default covered
  count UNCHANGED (1 = Gaussian); `validation_status()` covered 7→8; nothing else
  promoted. Retained debts: a 2nd same-estimand REML comparator, the in-suite
  unstructured-`sommer` test, broader-DGP recovery, the deep-inbreeding boundary. START
  HERE: `docs/dev-log/handover/2026-06-22-backlog-grind-handover.md` (the complete
  next-session handover: consolidation, the V4-MV-REML covered close-out, and the
  100-slice backlog grind — 6 of the first 14 done/PR'd, 8 remaining + deferred
  ledger follow-ups + correctness caveats).
- **As of 2026-06-20 (autonomous segment — ULTRACODE; 4 substantive PRs, main at `11e9909`/#121).**
  On top of the committed plotting-layer runway (`*_plot_data` preparers #91/#92/#94/#95/#116,
  CPU benchmark #115, threshold calibration #112, GLLVM consumability #113), this segment
  landed **3 full-DoD PRs**, each adversarially verified before merge:
  **(1) `HSquaredMakieExt`** (PR #117) — the Julia **drawing** half of the plotting layer:
  a `Makie` weak-dep package extension (`/src` stays dependency-free; stub `hsquared_figure`
  throws `MethodError` until a backend loads) that draws sets B/C (`variance_components` forest,
  EBV caterpillar, G-scree) with the #93 honest-status behaviors rendered ON the figure
  (raw whiskers no-clamp, `[0,1]` on the h² panel only, scree-not-biplot guard, non-PD-G
  %-suppression). Makie is deliberately OUT of CI (cost discipline) — CI gates the stub, the
  full draw is local-verified (CairoMakie, PNG). Rose: CLEAN.
  **(2) Binomial per-record `n_trials`** (PR #118) — generalized the Binomial family from a
  common scalar to a per-record `n_trials[i]` (the general `cbind(successes, failures)` GLMM
  the R lane flagged on **#61**), via `BinomialVectorResponse` + a `_fam_record` resolver
  threaded through all 10 kernel sites; constant-vector==scalar to ~1e-12, an independent
  per-record Gauss–Hermite oracle gate, mixed-regime recovery (n∈1..30, q=345: 5/5, rel≤0.062).
  5-agent Gauss/Noether/Curie+Rose Workflow: code clean, fixed a stale-negative register claim.
  **(3) Binomial/Bernoulli profile-LRT σ²a interval** (PR #119) — extended `laplace_reml_interval`
  to all single-component families with self-describing `lower_clamped`/`upper_clamped`/`converged`
  flags; `:variational` rejected (ELBO≠LRT). Fisher+Rose review corrected an over-generalized
  "two-sided" claim and caught two stale "Poisson-only" doc claims — all fixed before landing.
  **(4) HSquaredMakieExt genetic-correlation heatmap** (PR #121, after the v13 closeout) —
  the set-C `D⁻¹GD⁻¹` heatmap kind (rotation-invariant gated, low-/NaN-h² flagged); a
  Florence figure-honesty review caught a silent NaN-h² flag gap (fixed). Drawing-only.
  `Pkg.test()` + Documenter green on each; all 4 CI-green on clean checkout (**CI on a clean
  checkout is the authoritative gate**); `validation_status()` has **41 rows** (4 covered);
  **nothing promoted to covered**. Cross-lane **#61 engine side is now resolved** (per-record
  `n_trials` built) — draft answers for #38/#61/#93 are prepared but **NOT posted** (outward
  posting is the user's call; the auto-mode classifier blocks issue comments without explicit
  per-issue authorization). **Next:** the metafounder R-bridge (gated on #61 Q1–Q4), the
  eigenbasis bridge for `:lowrank`/`:factor_analytic` (#42, after R ratifies the FA convention),
  HSquaredMakieExt follow-on figure kinds (genetic-correlation heatmap, Manhattan/QQ, RR
  reaction-norm/surface), the Gaussian two-component interval (nuisance profiling), or —
  highest-leverage but cross-lane — the R-lane external comparator runs.
  Read `docs/dev-log/after-task/2026-06-21-session-handover-v14.md` (START HERE).
- **Covered (public):** v0.1 univariate Gaussian animal model only. Everything
  else is `experimental`/`partial` — nothing was promoted to covered this session.
- **Active programme (next-phase plan):** BT1 clean base = **done**. BT2 engine
  bridge-readiness (#42 diagonal done; #43/#44/#45 **done**; #42 lowrank/fa eigenbasis
  exposure gated on R ratification of the FA convention) and BT3 Julia-native
  validation (#46 fitted target + #49 JWAS scaffold **done** as a serialized target +
  opt-in scaffold; #47 SEs/LRTs done; #48 threshold machinery **done**, calibration
  evidence opt-in) are **landed**. **#54 random regression is now slices 1+2+3
  complete** (descriptors → supplied-covariance MME → REML estimation); the
  multivariate REML recovery is now characterised (no detectable bias + accurate EBVs,
  robust to cold vs warm start — the "6/10" was G sampling variance, not bias), still
  `partial` pending an external comparator. **Innovation backlog: #53 metafounders
  (supplied-Γ construction) DONE; PCG MME solver (production-path primitive) DONE.**
  Remaining: external-comparator EVIDENCE + fitted-Mrode confrontation (R-lane + opt-in
  JWAS run), multivariate recovery calibration (#4, gate not re-declared); innovation
  backlog #50 genetic GLLVM + CRN + APY genomic scaling + a matrix-free PCG operator
  (the actual large-scale enabler — edges into performance-claim territory needing
  benchmarks); RR slice 4 (eigen-function / PE term / R `rr()` spec); the metafounder
  R-bridge + single-step H^Γ (gated on #61 Q1–Q4); scout cadence #56; Phase 7/8
  hardware-gated.

## Core Scope

- Sparse pedigree, genomic, and custom relationship precision matrices.
- REML/ML/AI-REML mixed-model fitting for quantitative-genetic models.
- EBVs/BLUPs, heritability, variance components, G matrices, and diagnostics.
- Later: factor-analytic G matrices, GLLVM-style high-dimensional responses,
  non-standard inheritance systems, and accelerator-aware computation.

Phase 0 is complete. Phase 1 has started with pedigree normalization, sparse
`Ainv` construction, and an experimental dense validation path. Production
model fitting is not implemented.

## Twin Boundary

- `hsquared` speaks to applied R users.
- `HSquared.jl` computes.
- R syntax must not promise Julia capabilities that are not implemented,
  tested, documented, and recorded in `docs/design/capability-status.md`.

## Standing Review Lenses

These are review perspectives, not always-running agents. Say explicitly when
actual subagents are running.

| Name | Role |
| --- | --- |
| Ada | Orchestrator, phase planner, final integrator |
| Shannon | Coordination manager, lane checks, handoffs |
| Boole | Formula grammar and user-facing syntax |
| Hopper | R-to-Julia bridge and model-spec parity |
| Emmy | Package architecture and fitted-object design |
| Gauss | Numerical estimation, REML, sparse linear algebra |
| Karpinski | Julia performance, dispatch, allocations, type stability |
| Noether | Equation/syntax/implementation consistency |
| Fisher | Inference, identifiability, intervals, comparators |
| Curie | Simulation, recovery tests, edge cases |
| Jason | Literature and package scout |
| Darwin | Ecology/evolution audience and biological framing |
| Pat | Applied user tester and error-message reader |
| Florence | Figures and visual diagnostics |
| Grace | CI, Documenter, release, reproducibility |
| Rose | Systems auditor and claim-vs-evidence gate |
| Henderson | Mixed-model equations, BLUPs, sparse Ainv |
| Mendel | Non-standard inheritance systems |
| Falconer | Quantitative-genetic interpretation |
| Kirkpatrick | G matrices and factor-analytic genetic covariance |
| Mrode | Textbook animal-model validation canon |

## Current Member Routing

- **Ada + Shannon**: keep the programme aligned across `HSquared.jl`,
  `hsquared`, `DRM.jl`, `GLLVM.jl`, `drmTMB`, and `gllvmTMB`.
- **Henderson + Mrode + Gauss**: own the Phase 1 pedigree/Ainv and later
  animal-model equation checks.
- **Karpinski + Grace**: own Julia package hygiene, CI, Documenter, dispatch,
  and sparse performance review.
- **Hopper + Boole + Emmy**: keep Julia engine utilities compatible with the
  future R formula and bridge contract.
- **Jason + Rose**: scout sister packages and comparator tools, then prevent
  unsupported public claims.
- **Pat + Darwin + Florence**: keep docs readable for applied quantitative
  geneticists and ecological/evolutionary users.

These names remain review lenses unless an actual subagent is spawned and named
separately.

### Lane routing (which lens reviews which change)

Adopted 2026-06-19 (DRM.jl lane-boundary pattern). Charters live in
`.claude/agents/*.md` and `.codex/agents/*.toml`.

| Change class | Required lens(es) |
| --- | --- |
| `src/` numerics, REML, sparse linear algebra | Gauss + Karpinski + Noether |
| Formula / bridge / result-payload contract | Hopper + Boole + Emmy |
| Validation evidence, fixtures, recovery, comparators | Curie + Fisher + Mrode |
| Non-standard inheritance, quant-gen interpretation | Mendel + Falconer |
| G matrices / factor-analytic covariance | Kirkpatrick |
| **Any public claim / pre-publish / repo-visibility** | **Rose (mandatory)** |
| CI / Documenter / release / reproducibility | Grace |
| Cross-repo / cross-lane coordination | Ada + Shannon |

Scripted Workflow macros (run only on explicit opt-in / ultracode): an
engine-quality pass (Gauss/Karpinski/Noether over `src/`), an R-bridge-parity pass
(Hopper over payload + fixtures), and a validation-gate pass (Curie/Fisher/Mrode +
Rose) before any `experimental→covered` move.

## Sister Project Boundaries

Use the local sister projects as references:

- `DRM.jl`: Julia twin operating model, DocumenterVitepress setup, quality
  gates, and R-bridge discipline.
- `GLLVM.jl`: Julia engine structure, status-page discipline, performance claim
  gates, and high-dimensional design patterns.
- `drmTMB`: R package process, formula grammar discipline, validation debt,
  after-task reporting, and fitted/planned/missing separation.
- `gllvmTMB`: long/wide documentation discipline, covariance grammar, and
  reader-first public docs.

Code reuse rule: adapt architecture and process patterns freely, but do not copy
statistical code or public claims from sister projects without checking license,
provenance, tests, and fit for `HSquared.jl`.

## Memory Rules

Private memory may suggest where to look. Repository state, tests, docs,
issues, PRs, and check logs decide what is true.

Maintain repo-visible memory in:

- `ROADMAP.md`
- `docs/design/`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/`
- `docs/dev-log/recovery-checkpoints/`
- `docs/dev-log/decisions/`
- `docs/dev-log/scout/`

## Development Rules

1. Keep status language honest: no model-fitting claims without code and
   validation.
2. Do not change the public R-Julia contract without updating both twins.
3. Do not add a fitted capability without tests, documentation, capability
   status, validation-debt rows, and a Rose audit.
4. Do not copy statistical claims or code from sibling projects; adapt
   process patterns and record provenance.
5. Keep changes narrow and reviewable.

## Standard Commands

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
git status --short --branch
gh run list --limit 3
```

## Definition Of Done

A slice is done only when the relevant items are present:

- implementation;
- tests;
- documentation;
- example or explicit not-public-yet note;
- check-log evidence;
- after-task report;
- capability-status row;
- validation-debt row;
- Rose claim-vs-evidence audit;
- clean local checks;
- clean CI if pushed.
