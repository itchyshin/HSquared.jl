# Live Phase Snapshot — archive

- **As of 2026-07-24 (H2 engine-PERFORMANCE thread live — collaborator report; REML fit is the wall; handed to next lane).**
  Triggered by **szymekdr** (Discord): `hsquared` slow + crashes at genomic G n≈1000. **MEASURED on Totoro:**
  the A-inverse is FAST (`pedigree_inverse` 800=3 ms, 100k=2.2 s — **not** the bug); the default
  `fit_sparse_reml` (derivative-free) scales ≈ **n^2.6** (Szymek: 10k=1708 s vs ASReml 12.9 s, 100k=2 s); and
  the supposed fast path **`fit_ai_reml` runs to its 100-iteration cap / `not_converged`** at every size and
  tolerance (reaches the right loglik) — the concrete meaning of Shinichi's *"something is not really
  working."* **CONFOUND:** that was measured on no-signal data (σ²a→0, AI-REML's documented hard boundary);
  the real-signal confirming run (`bench_signal.jl`) **DIED unresolved** and is the **decision hinge** — re-run
  it first. Two-workflow ultra-plan (adversarial, beat-the-plan): **do NOT build the TMB native engine yet** —
  cheaper Option-A ladder first (dense-`Ginv` crash guard + flip pedigree default to a *working* `fit_ai_reml`
  + warm bridge), gated on the measurement. Native engine would PIVOT founding decision D-2026-06-12 (owner
  decision pending). **D1 genomic-recovery stays PAUSED (D-68; owner leans GO) — a SEPARATE thread, do not
  conflate.** `public_covered_count=5`; nothing moved. START HERE:
  `docs/dev-log/handover/2026-07-24-claude-handover.md` → first action: re-run `~/hsq_work/bench_signal.jl` on
  Totoro (real h²=0.4 signal). Ultra-plan detail: `docs/dev-log/native-engine-arc/native-engine-plan-hardened.md`.

- **As of 2026-07-20 (v0.7 D1 smoke-gate contract remediation DESIGNED + mirrored + Gauss RSS risk measured; H2 lane PAUSED by owner to focus on DRM/GLLVM).**
  The `SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH` that killed D1 now has an owner-authorized,
  three-lens-reviewed **planning-only** remediation: a declared arity contract as data
  (`docs/design/50-recovery-v3-arity-contract.{tsv,md}`), the C1–C6 implementation gate incl. the composed
  seed-free regression test (`docs/dev-log/recovery-checkpoints/2026-07-20-smoke-arity-contract-predeclaration.md`),
  brain `D-71`. **Mirrored** to the R twin (`hsquared@f5c0d46`, byte-identical bodies). **Gauss's RSS
  order-statistic risk MEASURED on Totoro (48 fits) → SAFE-AS-IS**, `attempts_per_rung=4` retained
  (`docs/dev-log/recovery-checkpoints/2026-07-21-smoke-rss-order-statistic-characterization-predeclaration.md`).
  Design satisfies **ONE of six** successor preconditions; **five remain open** (new root, disjoint
  allocation, fresh preregistration, mutation controls/reviews/preseal, explicit authorization). D0F reseal4
  stays PASS/COMPLETE; the retired `d1-reseal4` root and `2028000000/101:148` space stay immutable negative
  evidence. `public_covered_count=5`; `ordinary_auto_genomic` held; V2-GRM/V2-GINV partial.
  **NEXT ARC (owner decision, made fresh — not on momentum): go/no-go on whether to CONTINUE the genomic-recovery
  campaign at all.** If GO → implement the C1–C6 gate in the R launcher+tests (fresh scoped arc), then assemble
  a fresh D1 successor across all six preconditions. If NO-GO → freeze the D1/genomic-recovery line and pivot
  H2 elsewhere. **OWNER LEANS GO (Shinichi, 2026-07-20):** on pausing to focus on DRM/GLLVM, his stated
  inclination is to continue — implement C1–C6, then build the successor. **Resume TOWARD GO by default**, but
  re-confirm it fresh before committing compute: this is a leaning recorded at his request, NOT a standing
  authorization to run (the campaign has died at eight-plus distinct stages; the retirement fence and D-71
  planning-only boundary stand). START HERE: `docs/dev-log/after-task/2026-07-20-v07-smoke-gate-contract-remediation.md`.

- **As of 2026-07-20 (v0.7 D1 recovery-v3 — terminal root retired; static cause named; lane remains paused).**
  D0F reseal4 remains PASS/COMPLETE at R `5325e95` / Julia `418be984`, receipt `e88207e5…`. D1
  `d1-reseal4` passed seed-free admission and a unanimous read-only GREEN panel, drew four official smoke
  seeds, and then stopped `RC=21` (`fewer than 16 completed smoke attempts`); no D1 corpus or final receipt
  exists. The root and entire `2028000000/101:148` space are immutable retired negative evidence. The
  source-level cause is `SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH`: the controller passed
  `16` as workers to a mode that emitted four unique-`n` rows, then invoked a consumer requiring 16 files.
  This is **not** repair authority: D1 remains paused pending a separately authorized/pre-registered successor
  plan. `public_covered_count=5`; `ordinary_auto_genomic` held; V2-GRM/V2-GINV partial. START HERE:
  `docs/dev-log/handover/2026-07-20-claude-handover.md`.

- **As of 2026-07-17 (v0.7 genomic public-activation arc — RETRY-8 admission PASS; draw blocked by Totoro JuliaCall env; HANDOVER to next Claude).**
  Retry-8 fixed the two defects Retry-7's draw surfaced — the run-one
  `expected_route` arity bug (`hsquared` `96529fd`, Rose PROMOTE) + a stale driver
  checksum sidecar (`a23b15b`) — rebuilt a fresh sealed root under the repaired
  head, and **PASSED the admission gate** (write-review×5 → prepare → preseal →
  materialize-bootstrap → zero-seed preflight PASS; manifest 576, bootstrap 720000;
  seed bases 2042/2043 reused since `-c` was pristine; pre-reg `6d82b7ac`). The
  draw is blocked ONLY by Totoro's fresh Julia 1.10.10 **JuliaCall/RCall
  embedded-precompile being broken** — and the KEY new evidence is that **the same
  JuliaCall path WORKS on the Mac (1.10.0)**, so it is a **fixable Totoro env
  problem, not a code/version defect** (~17 tweaks failed; the untried fix is
  `Pkg.build("RCall")`). **NO seed spent — both roots PRISTINE.**
  `public_covered_count` stays **5**; route not activated. NEXT Claude: fix the
  Totoro JuliaCall env → fresh pre-draw GO → `run-official` smoke-first through
  `adjudicate`+`validate-final` on the `retry8-prep` root → spawned-Rose close-out.
  START HERE: `docs/dev-log/handover/2026-07-17-retry8-claude-handover.md`.

- **As of 2026-07-17 (v0.7 genomic public-activation arc — RETRY-8 admission PASS; draw BLOCKED by a JuliaCall precompile env issue).**
  Retry-8 repaired the two defects Retry-7's draw surfaced — the run-one
  `expected_route` arity bug (`hsquared` `96529fd`, Rose PROMOTE + RED→GREEN test)
  and a stale driver checksum sidecar (`a23b15b`) — and rebuilt a fresh sealed
  root under the repaired head: write-review×5 → prepare → preseal →
  materialize-bootstrap → **zero-seed preflight PASS** (manifest 576, bootstrap
  720000 byte-identical to `-c`; seed bases 2042/2043 reused since `-c` was
  pristine). Pre-registration `6d82b7ac`. The user authorized the draw; it is
  **BLOCKED (infrastructure, not science):** `run-one` builds K/Q via **JuliaCall**,
  whose lazy `using HSquared` fails to precompile on the fresh copied `HSquared.jl`
  deployment (`compilecache`/`mkpidlock`; worker error swallowed). A stable
  `TMPDIR` is necessary but not sufficient; `-c` only worked because its cache was
  pre-built by the original deployment. **NO seed spent — both roots PRISTINE.**
  `public_covered_count` stays **5**; route not activated. Recovery = clean-slate
  the Julia depot cache + one clean JuliaCall `Pkg.precompile`, or reconcile the
  original deployment's Julia/JuliaCall build. START HERE:
  `docs/dev-log/check-log.d/2026-07-17-retry8-draw-blocked-juliacall-precompile.md`.

- **As of 2026-07-17 (v0.7 genomic public-activation arc — RETRY-7 D0F CAMPAIGN BLOCKED at run-one; banked negative).**
  Admission gate + full pre-seed de-risk PASSED (PRE-0 pre-registration; PRE-1
  route-repair `b8096e5` in bound head; PRE-2/3 tail regression tests 209/0 with
  Rose PROMOTE + Hopper SOUND; PRE-4 real 720000-row bootstrap consumable; PRE-5
  preflight re-PASS). User authorized the draw; the smoke caught two issues
  BEFORE any seed was persistently drawn: (1) a JuliaCall precompile failure
  under R's ephemeral `TMPDIR` — FIXED by exporting a stable `TMPDIR` (env only);
  (2) **a CONFIRMED BOUND-TOOL DEFECT — `v3d_validate_attempt`
  (`v07_genomic_recovery_v3.R:1162`) calls `v3p_validate_results` without the
  now-required `expected_route` arg (route-repair `b8096e5` missed this run-one
  call site; synthetic lifecycle + preflight + tail-tests all bypass run-one, so
  none caught it).** Every official fit fails-closed. The sealed `-c` root is
  **PRISTINE** (preflight re-PASS; hashes unchanged; no attempts/packets) — no
  seed spent, NOT forfeit. Fixing the bound driver invalidates the sealed
  preseal, so recovery is a **repaired-head rebuild** (fix `v3d_validate_attempt`
  + add a run-one entry regression test + rebuild preseal + re-admit), not a draw
  on `-c`. `public_covered_count` stays **5**; route not activated. START HERE:
  `docs/dev-log/check-log.d/2026-07-17-retry7-d0f-campaign-run-one-blocker.md`.

- **As of 2026-07-17 (v0.7 genomic public-activation arc — RETRY-7 ADMISSION GATE PASSED; HARD STOP).**
  Claude ran the gate live on Totoro (execution reassigned to Claude). Chronology
  audit L1–L5 PASS (hashes byte-identical; preseal precedes bootstrap;
  create-once; no live worker; sole canonical root `-c`, with sibling `-b`
  recorded as the retired zero-fit SYNTHETIC lifecycle). Env unblocked (Julia
  1.10.10 installed + `-c` checkout instantiated; tree stayed clean). **Zero-seed
  Julia preflight `--stage=d0f` against the canonical root: PASS ("sealed inputs
  only; no official RNG or seed consumed"), exit 0, no mutation.** No phenotype
  drawn; no campaign run. Default R routing remains held and
  `public_covered_count` remains **5**; only the supplied-`Ginv` estimator is
  covered. NEXT (separately authorized, own ultra-plan): phenotype generation +
  576-fit campaign. START HERE:
  `docs/dev-log/check-log.d/2026-07-17-retry7-admission-gate-preflight.md`.

- **As of 2026-07-17 (v0.7 genomic public-activation arc — RETRY-7 ADMISSION GATE AUTHORIZED + PLANNED; HARD STOP).**
  Rose read-only pre-admission audit PASSED (sole ownership, canonical root,
  exact preseal/manifest/sidecar hashes byte-identical, no forbidden output;
  live no-worker leg delegated to Codex). The phenotype-admission gate is
  authorized and planned as a **zero-seed Julia preflight** (eight contract
  checks, each targeting a documented prior-retry failure) **+ post-bootstrap
  chronology audit**, both handed to Codex for live Totoro execution. No
  phenotype drawn; no campaign run. Default R routing remains held and
  `public_covered_count` remains **5**; only the supplied-`Ginv` estimator is
  covered. Hard stop after preflight+audit review; phenotype generation and the
  576-fit campaign need separate authorization. START HERE:
  `docs/dev-log/handover/2026-07-17-codex-handover.md`.

- **As of 2026-07-17 (v0.7 genomic public-activation arc — RETRY-7 BOOTSTRAP RECEIPT; HARD STOP).**
  The repaired exact head passed R/Julia checks, R CI, clean Totoro deployment,
  and zero-fit synthetic lifecycle. A fresh D0F preseal then materialized only
  the bound bootstrap index manifest at the canonical Totoro root; exact bytes
  reproduced and all phenotype/attempt/fit/adjudication namespaces remain
  absent. Default R routing remains held and `public_covered_count` remains
  **5**; only the supplied-`Ginv` estimator is covered. Next is a separately
  authorized phenotype-admission gate (Julia zero-seed preflight + post-bootstrap
  chronology audit), not phenotype generation. START HERE:
  `docs/dev-log/handover/2026-07-17-claude-handover.md`.

Thirty entries evicted verbatim from `AGENTS.md` on 2026-07-08, newest first (2026-07-03 back to
2026-06-20). **Nothing is summarised; nothing is deleted.**

Why they moved: the `## Live Phase Snapshot` block had grown to **92% of `AGENTS.md`** (720 of 880
lines, ~19,200 tokens) and `AGENTS.md` is `@import`ed by `CLAUDE.md`, so every line was re-read at the
front of **every session in this repo**. The cost was never money — the preamble is the most cacheable
object in a session. The cost was **salience**: the durable rules sat below 720 lines of history, and
one of them (`## Core Scope`) had gone four phases stale without anyone noticing.

The block's own instruction said *"Refresh this block in every after-task report (GLLVM.jl pattern)."*
Two things were wrong with that. "Refresh" was read as "prepend", 31 times. And GLLVM.jl has **no such
block** — nor does DRM.jl, nor the R twin `hsquared`, whose `AGENTS.md` carries the same doctrine in
6,000 B. The pattern was attributed, not copied.

---

- **As of 2026-07-15 (v0.7 genomic public-activation arc — RETRY-5 RETIRED; NOT ACTIVATED).**
  Retry 5 stopped after one valid official D0F fit at the post-preseal runtime-
  tree validator and is permanently
  `UNADJUDICATED — POST-PRESEAL TREE-VALIDATION BLOCKER`. A post-run admission
  audit also found that deployed Julia head `06941997` lacked the required
  typed infrastructure-error mutation gate, while durable proof of the fixed
  16-packet run and two review batches is absent. The root is frozen unchanged
  at 38 files / nine directories; all Retry-5 phenotype/bootstrap spaces are
  retired; no corpus lock, summary, Julia replay, adjudication receipt, D1, or
  D2 exists. Default R routing remains held and `public_covered_count` remains
  **5**; only the supplied-`Ginv` estimator remains covered. Prospective Retry-6
  work is carried over and cannot cure Retry 5 retroactively. START HERE:
  `docs/dev-log/recovery-checkpoints/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`.

- **As of 2026-07-14 (v0.7 genomic public-activation arc — RETRY-4 PRESEED REVIEW; NOT ACTIVATED).**
  Three separate 576-fit D0F corpora are permanently unadjudicated after exact
  Julia replay stopped before row 1 for fixed-panel cardinality, concrete-`Cmd`
  typing, and missing successful-gradient contract failures. All observed
  phenotype/bootstrap seeds are retired. Retry-4 bases `2036000000` /
  `2037000000`, finite-gradient admission, and batch-safe R/Julia replay are
  committed with local and CI gates green. NEXT: obtain five fresh exact CLEAN
  reviews bound to the final deployed heads and corrected doc-49 hash, then
  create a new preseal and run the zero-seed preflight. No retry-4 phenotype or
  D1/D2 seed exists, default R routing remains held, and
  `public_covered_count` remains **5**. The untracked downstream Julia replay
  remains an incomplete non-evidence scaffold. START HERE: the hash-bound
  execution contract in the R twin,
  `docs/design/49-v07-genomic-recovery-v3-sample-size-ladder.md`.


- **As of 2026-07-03 (doc-25 V7 GPU stream COMPLETE + V8 stream COMPLETE — ALL numbered slices done;
  Claude solo (Opus), autonomous; `/goal` "finish everything left in doc-25"; rows **55** / covered
  **13** / `public_covered_count` **5** UNCHANGED throughout).** The doc-25 numbered map is CLEARED.
  This continuation delivered + MERGED, each pre-declared + Rose-audited: **V8.5** APY genomic inverse
  (#253), **V8.4** external blupf90 comparator for the matrix-free fit — estimand leg (#254), and the
  ENTIRE **v0.7 GPU stream**: **V7.1** G-B Float32 (#255, tamia H100 — Float64 gate 7.3e-15, Float32
  GEBV ~1e-6, speedup MODEST ~1.2×, TF32 not engaged), **V7.2** G-7.2 cross-device (#256, Narval A100 —
  agreement PORTABLE ~1e-15, Float64 gate 3.0e-15; GBLUP bench 5.9×→46.7×), **V7.4** G-D backend
  dispatcher (#257, opt-in `backend=:cuda` on the two construction ops; `:cpu` byte-identical), **V7.3**
  G-C large-panel benchmark (#258, tamia H100 — handles n=20k×m=300k on one H100, 29% of 80GB; Float32
  modest, transfer-bound), and **V7.5** G-E close-out (this slice — `status_cache` pointer refreshed,
  stream consolidated). HONEST GPU summary: numerically exact + architecture-portable + handles realistic
  panels, but Float32 only a minor win + no R-public surface → `V2-GRM-GPU` stays `partial`, NO covered
  move. **doc-25 FULLY CLOSED** — both owed hardening legs now DISCHARGED (each Rose-audited + merged):
  **V8.4 at-scale** (blupf90 vs exact-sparse vs matrix-free at q=4060, PR #260 — exact==blupf90 4.7e-6,
  matrix-free ≤1%; the exact-infeasible regime q≫50k has NO external oracle by construction) and
  **coverage-calibrated intervals** (DRAC fir job 46853279 — empirical coverage of the shipped
  `:delta`/`:profile` h²/σ²a intervals: CONSERVATIVE over-coverage at small n, converging to nominal,
  `:profile` > `:delta`; a characterization, no covered flip). `public_covered_count` **5** held across
  the ENTIRE arc. START HERE: `docs/dev-log/after-task/2026-07-03-interval-coverage.md`.

- **As of 2026-07-03 (doc-25 V7 GPU stream STARTED — V7.1 G-B Float32 RUN on tamia H100; Claude solo
  (Opus), autonomous; user steer "V7 GPU stream (finish doc-25)"; rows **55** / covered **13** /
  `public_covered_count` **5** UNCHANGED).** After the engine-local matrix-free arc (V8.3/V8.4/V8.5,
  all merged), the user chose the V7 GPU stream. **V7.1 (G-B, branch `feat/2026-07-03-v07-gb-float32`):**
  `gpu_genomic_relationship_matrix(...; precision = Float32)` — opt-in mixed-precision `G` GEMM (return
  always Float64; centering unchanged → SAME estimand). Pre-declared + RUN LIVE on tamia H100 (job
  360780): Float64 gate HELD (`precision=Float64` GPU G ≡ CPU 7.3e-15); Float32 G differs ~1–5e-6
  absolute with NEGLIGIBLE GEBV impact (~1e-6) — numerically safe for prediction; but the speedup is
  **MODEST (~1.1–1.4×)** and TF32 tensor cores were NOT engaged (default==pedantic, FP32-level) — an
  HONEST, underwhelming measurement that CORRECTED the prior owed-note's "larger speedups" optimism.
  Float64 stays default. `V2-GRM-GPU` stays `partial`, NO covered flip. **V7.2 (cross-device, Narval
  A100 job 64637092) DONE:** the SAME committed G-A + G-B harnesses re-run on A100 — device-resident
  GBLUP CPU↔GPU agreement HELD (β/GEBV ~1e-15) + Float64 gate HELD (3.0e-15) → the GPU numerical
  AGREEMENT is architecture-portable (H100 → A100); Float32 same story (FP32-level, TF32 not engaged);
  A100 GBLUP benchmark 5.9×→46.7× (machine-specific, NOT a competitive A100-vs-H100 claim). Narval
  gpu_env set up under `/project/def-snakagaw`. REMAINING V7: V7.3 real panel, V7.4 dispatcher (local),
  V7.5 close-out. START HERE: `docs/dev-log/after-task/2026-07-03-v07-g72-crossdevice.md`.

- **As of 2026-07-03 (v0.8 doc-25 progress: V8.3 matrix-free intervals MERGED (PR #252) + V8.5 APY
  genomic inverse; Claude solo (Opus), autonomous; rows 54→**55** / covered **13** / `public_covered_count`
  **5** UNCHANGED).** Two more doc-25 slices, NO covered flip. **V8.3 (merged `afc446c4`):**
  `matrix_free_reml_information` — the average-information (AI) matrix built matrix-free and EXACTLY
  (working-variate `P`-projections, no stochastic trace — only the *score* needs the trace),
  reproducing the exact Cholesky-factor AI; `matrix_free_ratio_intervals` gives the same
  delta-method ratio/`h²` intervals as the exact path (asymptotic, NOT coverage-calibrated). **V8.5
  (this slice, branch `feat/2026-07-03-v85-apy`):** `apy_genomic_relationship_inverse(G, core; ridge)`
  — the Algorithm for Proven & Young (Misztal 2014) sparse-structured genomic inverse (factorizes
  only the core×core block + a diagonal conditional-variance correction for non-core, `O(ncore³)` not
  `O(n³)`) — the genomic analogue of the matrix-free "avoid the full dense object" move. EXACT-REDUCTION
  gate: core=all == full `inv(G+ridge·I)` to ~1e-15; the approximation converges to the full-inverse
  GEBV as the core grows (near-full core relerr 0.029 / corr ~0.9996). NEW `partial` row `V2-APY`
  (count 54→55; covered + `public_covered_count` UNCHANGED — engine scale primitive, caller-supplied
  core, dense return, no core-selection/scale-benchmark/comparator yet). `Pkg.test()` GREEN (55);
  `docs/make.jl` GREEN. **V8.4 (this session, ESTIMAND LEG DONE — no covered flip, no count change):**
  `comparator/matfree_blupf90_neffect.jl` runs `blupf90+` 2.60 AIREMLF90 LIVE on the shared K=3
  fixture (q=860); the matrix-free `fit_multi_effect_mc_reml` across-seed mean reaches blupf90's
  optimum to **≤0.15%** within MC error (nprobe 128→0.05%, 512→0.15%; blupf90 within ≤0.5 across-seed
  SD/component; exact-vs-blupf90 3.8e-5) — the external SAME-ESTIMAND leg for the matrix-free path at
  validation scale; `V3-NEFFECT-MATFREE-FIT` owed-notes swept (V8.3+V8.4 delivered) across all 3
  surfaces. REMAINING doc-25 (all COMPUTE-gated): V8.4 AT-SCALE leg (large-fixture, DRAC) +
  coverage-calibrated intervals + the v0.7 GPU stream (G-B/C/D/E, DRAC GPU). START HERE:
  `docs/dev-log/after-task/2026-07-03-v84-matfree-blupf90-comparator.md`.

- **As of 2026-07-03 (v0.8 doc-25 progress: V8.1 loglik + V8.2 varreduction MERGED, V8.6 R
  CONNECTION in paired PRs; R twin REOPENED; Claude solo (Opus), autonomous; rows 54 / covered 13
  / `public_covered_count` 5 UNCHANGED).** Working down the completion ultra-plan (`docs/design/25-completion-ultraplan.md`).
  DONE + MERGED (PR #250): **V8.1** matrix-free REML `loglik` (`matrix_free_reml_loglik`, `log|C|`
  by stochastic Lanczos quadrature, matches exact within the SLQ MC band); **V8.2** trace variance
  reduction (`shared_probes=true`, one full-random probe → all K traces, K× fewer solves, unbiased).
  IN PAIRED PRs (engine #251 / hsquared #122, Rose PROMOTE-WITH-CHANGES, auto-merge on CI green):
  **V8.6** R connection — `fit_payload_v2(...; scale_method=:auto)` + R `engine_control
  scale_method="auto"` route the EXISTING `target="multi_effect"` `(1|g)` surface through
  `fit_multi_effect(:auto)`; validation-scale = sparse-exact (reduces to the covered dense result,
  live-bridge verified dense-vs-auto 2.7e-5), large-scale = experimental matrix-free (its result now
  carries a stochastic `loglik` (V8.1) + `boundary` so `result_payload_v2` marshals it). **Default
  `scale_method=:dense` is BYTE-IDENTICAL** (frozen payload-v2 contract; parity `max_abs=0.0`). NO
  covered-count change (opt-in). Rose-principle fix: the pre-existing `random_effects(fit)` latent
  bug (masked in CI) → `ranef`. REMAINING doc-25: V8.3 (matrix-free intervals — AI matrix is
  matrix-free-EXACT, next), V8.4 (external comparator), V8.5 (APY), and the v0.7 GPU stream
  (G-B/C/D/E). START HERE: `docs/dev-log/after-task/2026-07-03-v86-r-connection.md`.

- **As of 2026-07-02 (v0.8 MATRIX-FREE Monte-Carlo REML FIT — lifts the multi-effect scale path from
  SOLVE to FIT, recovery+scale gate PASS to q=200k; Claude solo (Opus), autonomous; `main` @
  `b2ec7707` (PR #249); R twin frozen; rows 53→**54**, covered **13**, `public_covered_count` **5**).**
  Built the production large-`q` FITTING engine on top of the S2 matrix-free solve. FOUR slices, NO
  covered flip: (A) **`mc_reml_block_traces`** — Hutchinson stochastic trace estimating the REML
  score-trace `tr(Aᵢ⁻¹C⁻¹[uᵢ,uᵢ])` matrix-free (the term the exact path reads from a Cholesky
  selected inverse), unbiased vs the exact `selinv_block_traces`. (B) **`fit_multi_effect_mc_reml`**
  — matrix-free Monte-Carlo EM-REML fit; each EM step = a matrix-free PCG solve + the Hutchinson
  trace, `C` NEVER formed/factorized → not limited by the K≥2 fill-in; recovers the exact AI-REML
  optimum to ~0.7% (q=300). (usability) **`fit_multi_effect(...; method=:auto)`** — routes exact
  (`fit_sparse_multi_effect_aireml`) vs matrix-free by feasibility (K==1 || N≤direct_max_n; a
  documented heuristic, overridable) with a switch `@info` + `trace_mcse`; + the "Fitting at scale"
  doc page. (C) **PRE-DECLARED recovery+scale gate** (PREDECL `66ac9521` BEFORE the run; DRAC fir
  job 46725575): RECOVERY 48 seeds K=3 q=960 **PASS** — all converged, MC reproduces the covered
  exact estimator (`V3-NEFFECT-REML`) to **2.6%** (≤5% primary), secondary |bias|≤2·MCSE (max 1.20)
  with the exact fit sharing the means; SCALE the **FIT converges to q=200,000** (11.5s→586s) where
  the direct multi-effect AI-REML is fill-limited past ~50k — extending the S2 SOLVE feasibility
  (q=10⁶) to the FIT. The science risk (is the MC gradient noise benign?) is RESOLVED: benign,
  controllable by nprobe. NEW `partial` row `V3-NEFFECT-MATFREE-FIT` (count 53→54; covered +
  `public_covered_count` UNCHANGED — engine capability, APPROXIMATES the exact fit, NO
  loglik/intervals/comparator yet). Real `rose-systems-auditor` (Opus) → **PROMOTE-WITH-CHANGES**
  (every number independently reproduced, pins verified live, predeclaration-before-run confirmed,
  Pkg.test GREEN; 3 fixes applied). Cross-project methodology issues filed (gllvmTMB #705, drmTMB
  #714, GLLVM.jl #167, DRM.jl #327). **Completion ultra-plan: `docs/design/25-completion-ultraplan.md`**
  (V8.1 matrix-free loglik + V8.2 trace variance reduction = recommended next; v0.7 G-B/C/D + v0.8
  S3/S4 remain; V8.6 R bridge BLOCKED by the R freeze). `Pkg.test()` GREEN (count 54); `docs/make.jl`
  GREEN. START HERE: `docs/dev-log/after-task/2026-07-02-matrix-free-fit-arc.md`.

- **As of 2026-07-02 (v0.7 G-A + v0.8 S1/S2 DRAC FLEET CAMPAIGN — matrix-free multi-effect PCG to
  q=10⁶ + METIS banked-negative + device-resident GBLUP agreement PASSED; Claude solo (Opus), R
  twin frozen; branch `feat/2026-07-02-v07-v08-fleet`, PREDECL `cad28efb` pushed BEFORE any run;
  counts UNCHANGED — rows 53 / covered 13 / `public_covered_count` 5).** Executed the doc-23 v0.7/v0.8
  programme via a DRAC fleet campaign (doc-24; all 8 DRAC clusters reachable, Totoro socket down →
  DRAC-only; headline nodes **fir** CPU + **tamia** H100), full measure-first + pre-declaration
  discipline, user-approved pre-compute checkpoint. THREE outcomes, NO covered flip:
  (1) **v0.8-S1 METIS BANKED NEGATIVE** — measured (before writing ordering code) that METIS nested
  dissection is NOT a robust fill-reducing enabler for the multi-effect MME: **~3.2× SLOWER / 2.5×
  more fill than CHOLMOD AMD at q=50k K=3** (DRAC fir, reproduces local Mac); per the pre-declared
  ≥1.2×-at-every-cell rule → FAIL → **AMD retained, no Metis dependency**. This falsified doc-23's
  headline hypothesis. (2) **v0.8-S2 matrix-free multi-effect PCG — the real scale enabler** (NEW
  `solve_multi_effect_pcg`; never forms/factors `C`, bypasses the K≥2 fill wall): correctness-gated
  in-suite (matrix-free==direct ~1e-8; operator `C·eᵢ==C[:,i]` ≤1e-12; K=1 reduces to
  `solve_animal_model_pcg`), and BENCHMARKED (DRAC fir job 46705208, pre-declared) **feasible to
  q=1,000,000** (converged, PCG iters DECREASING 42→36 across 500× q, near-linear OLS slope ≈1.08,
  19× faster than direct at q=50k where direct is nnz(L)-cap-excluded). Machine-specific
  SUPPLIED-VARIANCE-SOLVE measurement — NOT a full REML fit (the AI-REML Takahashi score needs a
  factor → a stochastic-trace/EM matrix-free FIT is owed), NOT a GPU/portable claim. `V1-PCG`
  extended (count unchanged). (3) **v0.7-G-A device-resident GBLUP** (NEW `gpu_fit_gblup`; keeps
  `G`/`Ginv`/`C` on-device across `G→Ginv→MME solve`): **CPU↔GPU agreement gate PASSED on tamia H100
  to ~1e-15** (β+GEBV, vanraden1/2/weighted; device assembly also CPU-mirror-validated to ~1e-15
  pre-run) → device-resident GBLUP numerically identical to `fit_gblup`; CI stub-tested. The
  end-to-end speedup benchmark (job 360589, H100, q≤16000) shows device-resident GBLUP **5.2×→23×
  faster than CPU** (q=2k→16k; dense O(q³)), agreement holding through the benchmark (maxΔ ≤ 2e-13);
  first-run OOM'd on the q=32000 CPU reference (agreement had already passed) → rerun capped at the
  feasible q≤16000, harness byte-identical.
  Real `rose-systems-auditor` (Opus) on S1+S2 → **PROMOTE-WITH-CHANGES** (every load-bearing number
  independently reproduced; pins 53/13/5 verified live; pre-declaration-before-run ordering
  verified; 4 post-run status-string refreshes applied). `Pkg.test()` GREEN (count 53); `docs/make.jl`
  GREEN. OWED: v0.8 matrix-free FIT (stochastic-trace/EM) + sparse recovery gate + external
  comparator; v0.7 G-B Float32 + G-C real-panel + G-A cross-device agreement replicate (fleet set
  up); Totoro reconnect. START HERE:
  `docs/dev-log/after-task/2026-07-02-v07-v08-fleet.md`.

- **As of 2026-07-02 (Phase 5 sparse-vs-dense benchmark BANKED + direct–maternal 2nd comparator
  DISCHARGED + DM asymptotic intervals; Claude solo (Fable), R twin frozen; branch
  `feat/2026-07-02-phase5-sparse-benchmark`, PREDECL `662663ed`, PR pending; counts UNCHANGED —
  rows 53 / covered 13 / `public_covered_count` 5).** Closed the **one remaining compute-gated
  owed item** — the sparse K-component AI-REML timing/scaling benchmark — under full doc-16
  pre-declaration discipline (predeclaration `662663ed` committed BEFORE the run; harness
  byte-identical; run on Totoro 1-core; user-approved at the pre-compute checkpoint). **GO**
  decision, banked as MEASUREMENT on the `partial` `V3-NEFFECT-SPARSE` row (NO covered flip):
  sparse ≤ dense at ALL overlap sizes (**122×–692×** min-time q=200→1000, monotone, sign-stable,
  dense `converged=true`, same-optimum ≤3.3e-5); K=1 sparse **near-linear** (log-log slope 1.01,
  feasible to q=50k), K=3 **~quadratic** (slope 2.25; q≥20k infeasible in-budget). **Headline
  finding:** the K=1-vs-K=3 contrast pinpoints the multi-effect environmental-group columns'
  Cholesky fill-in as the K≥2 scale bottleneck → a fill-reducing ordering (METIS) is the concrete
  next enabler. Estimator-vs-estimator machine-specific measurement (confound disclosed via
  iters vs f_calls); NO isolated-LA / GPU / production / accuracy / portable claim. Plus two
  additive hardening slices on the COVERED `V4-DIRECT-MATERNAL` (no flip): (2) an INDEPENDENT
  `blupf90+` 2.60 AIREMLF90 2×2-G 2nd same-estimand comparator via `OPTIONAL mat` — converged to
  the engine optimum ~3e-5 on all four entries (dam-identification verified; verified against the
  raw `blupf90.log`) → the owed 2nd-comparator leg DISCHARGED (point-estimate, single fixture);
  (3) NEW exported `direct_maternal_interval` — asymptotic delta-method SEs/CIs (VCs + r_am
  Fisher-z + Willham triple; observed-info FD-Hessian; UNCALIBRATED; 32/32 tests; corroborated by
  BLUPF90's AI SEs to ~4–12%). Hygiene: Falconer→Willham fence, doc-33→doc-16 canonicalization
  (4 files), `.gitignore` + `docs/api.md` (direct-maternal family) + `docs/package.json` gitignore.
  Pre-freeze reviews (Karpinski/Gauss on the harness; Fisher/Rose on the pre-declaration) + a real
  Fable `rose-systems-auditor` close-out audit → **PROMOTE-WITH-CHANGES** (all numbers
  independently reproduced; 3 doc-hygiene fixes applied). `Pkg.test()` GREEN (count 53);
  `docs/make.jl` GREEN. Owed on V3-NEFFECT-SPARSE: METIS fill-reducing ordering for near-linear
  K≥2 scaling, a sparse-path recovery gate + comparator, the R multi-term `(1|g)` bridge. START
  HERE: `docs/dev-log/after-task/2026-07-02-phase5-benchmark-dm-comparator-intervals.md`.

- **As of 2026-07-02 (ULTRAPLAN COMPLETE + CERTIFIED airtight — generality-gap doc-consistency sweep
  closed; Claude solo; `HSquared.jl` `main` @ `2b2078cc`, `hsquared` `main` @ `f01ff61`; counts UNCHANGED
  rows 53 / covered 13 / `public_covered_count` 5).** An ultracode 20-agent adversarial verification sweep
  confirmed the 1→5 public-covered win is EVIDENCE-airtight (every gate/comparator/parity clean; zero
  numerics/overclaim findings) but found **11 stale status-surface contradictions** (covered models still
  labelled partial/experimental from uneven Phase 1–3 flip propagation; SAFE-direction under-claiming). This
  CORRECTS the overnight report's "no stale contradictions" — the sweep run to check caught the debt. All 11
  now RESOLVED + re-verified clean: hsquared named surfaces (R-lane peer `5389f23`), hsquared vignettes/README
  (#121), HSquared.jl v0.6 orphans V6-ORDINAL/V6-GAMMA (#245, after integrity-confirming the #229 G10 flip).
  No coverage decision moved (pure propagation); both repos CI green. Banked cosmetic nits: doc-16/doc-33
  citation style, a Falconer-vs-Willham fence tag (`likelihood.jl:1661`), `sommer_rr` R-stdout not committed,
  `status_cache.json refreshed_from_head` pointer. The generality-gap ultraplan is DONE. The one remaining
  compute-gated item is Phase 5's sparse-AI-REML PERFORMANCE benchmark (P5.1 estimator landed + reduction-
  verified; a pre-declared DRAC/Totoro run is OWED — engine scale, NOT a generality claim). START HERE:
  `docs/dev-log/check-log.d/2026-07-02-doc-consistency-certification.md`.
- **As of 2026-07-02 (OVERNIGHT 7-hour autonomous session CLOSE — generality-gap ultraplan public goal
  DELIVERED, `public_covered_count` 1→**5**; Claude solo; `HSquared.jl` `main` @ `90bdf435`, `hsquared`
  `main` @ `7e848ee`; live `validation_status()` rows **53** / covered 13 / covered_external 3 / partial 36
  / planned 1).** One session moved the R public surface from a single covered model to **five**: v0.1
  Gaussian → (Phase 1) common-env two-effect/c² → (Phase 2-R) arbitrary-N `(1|g)` → (Phase 3) RR k=2
  reaction norm → (Phase 4) direct–maternal correlated 2×2 `G_dm` — each on the Phase 0 payload-v2
  bridge, each with a pre-declared 48-seed gate (all PASSED, no banked negatives) + a `sommer`
  same-estimand comparator + a real Rose audit + paired CI-green merge. Plus **Phase 5 P5.1**: a sparse
  K-component AI-REML estimator (`fit_sparse_multi_effect_aireml`; `V3-NEFFECT-SPARSE` partial; exact
  dense-match oracle; NO perf claim — benchmark OWED; no public move). HONESTY PINS HELD: engine-covered
  ≠ R-public-covered; v0.1 default untouched; all intervals asymptotic/uncalibrated (RR + direct–maternal
  point-estimate); direct h² ≠ Willham total h². Both repos green incl. `hsquared` pkgdown (the
  user-flagged pkgdown CI failure was fixed in `hsquared` #118). NEXT: Phase 5 perf close (pre-declared
  DRAC/Totoro sparse-vs-dense benchmark + scale comparator); standing debt (BLUPF90 `OPTIONAL mat` 2nd
  direct–maternal comparator lineage, broader-DGP recovery, calibrated intervals). START HERE:
  `docs/dev-log/after-task/2026-07-02-overnight-7hr-session.md`.
- **As of 2026-07-02 (generality-gap ultraplan Phase 4: direct–maternal correlated 2×2 G_dm → covered
  + R public; `public_covered_count` 4→**5**; Claude solo autonomous; `HSquared.jl` `main` @ `e34a1ef8`
  (#238); `hsquared` `main` @ `7e848ee` (#120)).** The FIRST correlated random-effect structure promoted
  to covered: `fit_direct_maternal_reml` — the 2×2 `G_dm` over `[a_d; a_m]` with shared pedigree `A`
  and one residual variance — satisfies BOTH doc-16 covered legs. Evidence: **(1) PRE-DECLARED 48-seed
  bias/MCSE recovery gate PASS** (predeclaration `76f6c67e` committed BEFORE the run; harness
  `sim/phase4_direct_maternal_recovery_gate.jl` byte-identical pre/post; confound-breaking DGP — 4
  overlapping generations, dams with own records + 8 offspring, 90 identifying dams, n=960 — plus a
  negative-control cell; 48/48 converged; all four |bias|≤2·MCSE: σ²_ad 0.13·MCSE, σ²_am 1.65·MCSE,
  σ_dm 0.72·MCSE, σ²e 0.24·MCSE; EBV acc direct 0.667/maternal 0.759; max cond 157; max |r_am| 0.80,
  no seed rode the ±1 boundary). **(2) `sommer` 4.4.5 `covm()` same-estimand REML comparator AGREE**
  (≤1.1e-2 on all entries including σ_dm; `covm(vsm(ism(animal),Gu=A), vsm(ism(dam_id),Gu=A))`
  pattern; **the RR `usm(leg())` idiom does NOT transfer** — maternal coefficient loads on a different
  incidence matrix `Z_m` = record→dam; column-identification verified: absolute variance-entry
  agreement, NOT correlation-only). **(3) Engine G1/G2**: σ_dm=0 reduction byte-identical to the
  two-independent-effect model; negative-off-diagonal marginal-GLS oracle matched ~1e-9.
  **R vertical** (paired PR #120): opt-in `target="direct_maternal"` surface (`maternal_genetic()`
  stub wired to `fit_direct_maternal_reml`); labelled-triple `heritability()` returning direct h²,
  m², and Willham total h²_T (`σ_P = σ²_ad + σ²_am + σ_dm + σ²e`); corrected phenotypic variance
  denominator (includes σ_dm); `total_heritability()` extractor. Live R↔engine parity verified.
  **SCOPE (Rose-adjudicated):** validation-scale dense n≤~1000, OPT-IN NOT the public default; direct
  h² ≠ total h² (Willham — labelled triple, never a bare scalar); negative r_am is real and expected;
  |r_am|→1 rides on `converged=false` (covered claim is on well-conditioned identified designs);
  single relationship matrix A (not the maternal-A2/metafounder generalization). Covered = engine
  correctly implements direct–maternal 2×2-G REML on the tested confound-broken design, NOT
  small-sample accuracy of any single component. **Honesty pins HOLD:**
  `validation_status()` count **52 UNCHANGED** (covered 12→**13**, partial 36→35), v0.1 default
  untouched, `public_covered_count` 4→**5** at ALL 5 pin sites (`status_cache.json` +
  `gen_status_json.jl`). Real Fable `rose-systems-auditor` → **PROMOTE-WITH-CHANGES** (3
  stale-status contradictions + sibling field fixes; all applied). **R-CMD-check non-ASCII lesson
  (SECOND occurrence):** non-ASCII em-dashes in R string literals caused R-CMD-check WARNING (invisible
  to `devtools::test`); fixed by ASCII-izing 4 strings before merge. **Recommend adding "run R CMD
  check locally for R branches, not just devtools::test" to the R-lane DoD** — this has now recurred
  twice (Phase 1 + Phase 4). Merged only after BOTH lanes CI green (paired-PR discipline). **SESSION
  ARC (generality-gap ultraplan full run): `public_covered_count` 1→5** across the programme:
  Phase 1 common-env two-effect/c², Phase 2-R arbitrary-N `(1|g)`, Phase 3 RR k=2, Phase 4
  direct–maternal 2×2 G_dm. **NEXT: Phase 5 sparse AI-REML N-effect scale (measure-first, no perf
  claim without a pre-declared benchmark). Standing debt: BLUPF90 AIREMLF90 2×2-G optional 2nd-
  lineage comparator (OPTIONAL — not a covered blocker), broader-DGP/larger-scale direct–maternal
  recovery, maternal-A2 generalization (separate pedigree per leg).** START HERE:
  `docs/dev-log/after-task/2026-07-02-phase4-direct-maternal.md`.

- **As of 2026-07-01 (generality-gap ultraplan Phase 3: random regression k=2 / random slopes `rr()` →
  covered + R public; `public_covered_count` 3→**4**; Claude solo autonomous; `HSquared.jl` `main` @
  `13f9662f` (#236); `hsquared` `main` @ `e57a4e8` (#119)).** The 4th public-covered model: opt-in
  `hsquared(y ~ animal(rr(t, k=2)|id, pedigree=ped), engine="julia", target="random_regression")` now
  fits a linear reaction norm + returns the 2×2 K_g (intercept×slope genetic covariance matrix), σ²e,
  EBVs, and h²(t) trajectory. ENGINE: `V3-RR-REML` `partial→covered` (commit `2e777f74`) via two
  doc-16 legs: **(1)** a **pre-declared 48-seed bias/MCSE recovery gate PASS** (predeclared `b3e97835`
  BEFORE the run; 48/48 converged, |bias|≤2·MCSE for all K_g entries + σ²e; slope variance K_g[2,2]
  at 1.67·MCSE — within gate, no detectable bias); **(2)** a **`sommer` 4.4.5 `leg()` same-estimand
  REML comparator AGREE** ≤1.9e-5 on all K_g entries + σ²e (Legendre-normalization D=I₂ verified:
  basis diff 7.4e-13 — absolute variance-entry agreement, not correlation-only; evidence banked in
  `docs/dev-log/recovery-checkpoints/2026-07-01-rr-k2-covered-evidence.md`). R: **live R↔engine parity
  EXACT ≤1.03e-5 (VC) / h²(t) ≤4.24e-6** (two independent checks); `public_covered_count` 3→4 pinned
  at ALL 5 sites (`status_cache.json` + `gen_status_json.jl`). Real `rose-systems-auditor` →
  PROMOTE-WITH-CHANGES (stale field-6/field-7 self-contradictions fixed). Paired PRs #236
  (`HSquared.jl`) + #119 (`hsquared`); both-lane CI green; Maintainer G10 delegated. **SCOPE
  (Rose-adjudicated):** k=2 ONLY (k≥3 experimental, deferred to reduced-rank/FA post-v1.0); homogeneous
  residual; no PE term; h²(t) is a CURVE (point-estimate, NOT interval — unlike two-effect/N-effect;
  `heritability()` errors on curve gracefully); narrow-sense on animal block with PE-overstatement
  caveat; `(x|g)` raw slopes rejected; NOT non-Gaussian; NOT k≥3 / correlated-residual. **Honesty
  pins HOLD:** `validation_status()` count **52 UNCHANGED** (covered 11→12, partial 37→36), v0.1
  default untouched, `public_covered_count` 3→**4** (1 Gaussian → 2 two-effect → 3 multi-effect →
  4 RR k=2). **SESSION ARC:** `public_covered_count` **1→4** across this session (Phase 1 common-env
  two-effect, Phase 2-R arbitrary `(1|g)`, Phase 3 RR k=2), on the Phase 0 payload-v2 bridge. **NEXT:
  Phase 4 direct–maternal 2×2 G (Fable-tier gate + BLUPF90 AIREMLF90 2×2-G comparator → covered);
  Phase 5 sparse AI-REML (scale, measure-first).** START HERE:
  `docs/dev-log/recovery-checkpoints/2026-07-01-rr-k2-covered-evidence.md`.

- **As of 2026-07-01 (generality-gap ultraplan Phase 2-R: arbitrary `(1|g)` from R → `public_covered_count`
  2→**3**; Claude solo autonomous; `HSquared.jl` `main` @ `74b9dcbb`, `hsquared` `main` @ `c86b355`).**
  Delivered the HEADLINE: `hsquared(y ~ animal(1|id, pedigree=ped) + (1|nest) + (1|year), engine="julia",
  target="multi_effect")` now fits + returns per-component variances + animal-block h² + intervals. The
  opt-in **arbitrary-N INDEPENDENT random-effect model** is the 3rd public-covered model (PRs #234/#117,
  atomic pair; preceded by engine interval + R core + parity slices). Engine: NEW `multi_effect_ratio_interval`
  (generalizes `two_effect_ratio_interval` to K; delta-method, boundary-flagged, NOT calibrated; reduces to
  two-effect at K=2, heritability_interval at K=1). R: `(1|g)` grammar (accepts intercepts, **rejects** `(x|g)`
  slopes + `(x||g)`), N-block emitter, `multi_effect` dispatch, `hs_normalize_n_effect_result` +
  `hs_attach_n_effect_intervals` (heritability_interval resolves for K≥3 = animal ratio; per-block
  `variance_ratio_intervals`). **Live R↔engine parity EXACT (max diff 0, two independent checks incl. a native-
  Julia rebuild → verifies JuliaCall N-block marshalling); `sommer` cross-check ~1.5e-2.** SCOPE (Rose-adjudicated):
  INDEPENDENT iid + animal-A only — NOT correlated (direct–maternal), NOT random-regression, NOT random slopes,
  NOT non-Gaussian; maternal leg (A2=pedigree) stays experimental; animal ratio = narrow-sense h², other blocks =
  variance proportions; intervals asymptotic/uncalibrated. **Honesty pins HOLD:** `validation_status()` count
  **52 UNCHANGED**, engine covered-count unchanged (public-SURFACE flip), v0.1 default untouched,
  `public_covered_count` pinned at all 5 sites. Real `rose-systems-auditor` PROMOTE-WITH-CHANGES (all applied
  incl. stale-string fixes). CI caught a Julia-1.11/1.12 version-fragile boundary test (fixed to a contract-based
  assertion, verified on 1.10 AND 1.12) — merged only after BOTH lanes green (paired-PR discipline). SESSION ARC:
  `public_covered_count` **1→3** (v0.1 Gaussian → Phase 1 common-env two-effect/c² → Phase 2-R arbitrary-N
  `(1|g)`), on the Phase 0 (S0) payload-v2 bridge + engine `V3-NEFFECT-REML`. **NEXT: Phase 3 RR k=2 (after the
  P3.0 `(x|g)`-vs-`rr()` convention lock; random slopes), Phase 4 direct–maternal 2×2 G (Fable-tier gate + BLUPF90
  2×2-G comparator), Phase 5 sparse AI-REML (scale).** START HERE:
  `docs/dev-log/after-task/2026-07-01-phase2-r-arbitrary-1g.md`.
- **As of 2026-07-01 (generality-gap ultraplan: N-effect covered + Phase 0 (S0) done + FIRST public flip;
  Claude solo autonomous; `HSquared.jl` `main` @ `0d1518bf`, `hsquared` `main` @ `8ef81ac`; `public_covered_count`
  1→**2**).** Executed the cross-twin "Closing the mixed-model generality gap" ultraplan under the `ultra-plan`
  house method (~15 sub-agents, real Rose audits, both-lane CI). THREE landings: (1) **`V3-NEFFECT-REML` engine
  `partial→covered`** (PR #230 — pre-declared 48-seed bias/MCSE gate PASS + `sommer` 4.4.5 same-estimand
  comparator 8.09e-5; engine-only, `public_covered_count` stayed 1). (2) **Phase 0 / S0 — payload-v2 multi-block
  bridge contract FROZEN** (PRs #231/#115 — `parse_payload_v2`/`fit_payload_v2`/`result_payload_v2` + R
  `hs_build_bridge_payload` emitter; **byte-identical** cross-lane parity, v0.1 fast-path `===` bit-identical;
  contract-only; `maternal_genetic` stays INDEPENDENT, the correlated 2×2-G + `coefcov` are frozen slots).
  (3) **Phase 1 — FIRST public-covered model beyond v0.1: `public_covered_count` 1→2** (PRs #232/#116 — the
  opt-in **common-environment two-effect** animal model, NOT the default `engine="fit"` path). New engine
  `two_effect_ratio_interval` (asymptotic delta-method logit CI for h²/c²; boundary-flagged; NOT
  coverage-calibrated; reduces to `heritability_interval` at σ2²=0) + R `common_env_proportion()`/`maternal_proportion()`
  + `_interval()` accessors + `heritability_interval()` for two-effect + Falconer fences + `sommer` comparator
  vignette. Live R↔engine parity **EXACT** (max diff 0 on VC/h²/c²/intervals). SCOPE (Rose-adjudicated):
  common-env / c² leg ONLY — the **maternal leg (A2=pedigree) STAYS EXPERIMENTAL** (same estimator, exact
  parity, but a harder direct-maternal-correlated identifiability problem; its recovery gate + comparator owed).
  **Honesty pins HOLD:** `validation_status()` count **52 UNCHANGED**, engine covered-count unchanged by the
  Phase 1 (public-SURFACE) flip, v0.1 default untouched, all intervals asymptotic/uncalibrated,
  `public_covered_count` pinned consistently at all 5 sites (`status_cache.json` + `gen_status_json.jl`). Real
  `rose-systems-auditor` PROMOTE(-WITH-CHANGES) on every flip; R CMD check caught a non-ASCII WARNING (fixed
  `532d51d`) → merged only after BOTH lanes green (paired-PR discipline). **MAINTAINER-GATED items are delegated
  (G10 "flip autonomously once evidence passes"); nothing faked.** **NEXT (parallel streams, now unblocked by
  S0): Phase 4 direct-maternal 2×2 G → covered (engine exists `partial`; Fable-tier gate design + BLUPF90
  AIREMLF90 2×2-G comparator), Phase 3 RR k=2 → covered (after the P3.0 `(x|g)`-vs-`rr()` convention lock;
  `sommer leg()` comparator), Phase 5 sparse AI-REML N-component (scale, measure-first).** START HERE:
  `docs/dev-log/after-task/2026-07-01-phase0-phase1-public-flip.md`.
- **As of 2026-07-01 (v0.6 9-PR integration VERIFIED green + merge recipe + 3 lanes spawned; Claude solo
  autonomous; `main` @ `94d20319`/count 50 UNCHANGED; the six family PRs #215–#220 + three h² PRs #221–#223
  all still open).** De-risked the maintainer's merge: ran the FULL 4-tip trial-merge of all 9 v0.6 PRs onto
  `origin/main` in a throwaway branch (`trial/v06-full-integration`, discarded), resolved every conflict
  (three trivial keep-both + one genuine COMBINE — the `V6-NS-H2` row across 3 surfaces + `_nongaussian_h2_core`'s
  two h² branches + the two h² testsets), and `Pkg.test()` PASSED with count **50** / split unchanged /
  **nothing flipped to covered** / `public_covered_count` **1**. A real `rose-systems-auditor` on the integrated
  tree → **PROMOTE-WITH-CHANGES**: exactly one required fix (the `V6-NS-H2` `claim_boundary` field-7 was a STALE
  self-contradiction — "no QGglmm evidence" vs the same row's "QGglmm RUN + AGREES"; NOT a git conflict, so a
  mechanical merge silently carries it forward — the real #221/#223 PR must apply the exact one-line fix, banked
  + verified in the recipe). Exact recipe: `docs/dev-log/recovery-checkpoints/2026-07-01-full-v06-merge-recipe.md`.
  Also spawned THREE launch-ready work-lanes (merge-verify [maintainer started it], MCMCglmm h² comparator, v0.4
  broader-DGP MV recovery) — all experimental-only, G10-fenced, no covered flip. HONESTY PINS HOLD: count 50,
  public-covered fitting 1, nothing merged to `main`. MAINTAINER-GATED: merge the 9 PRs (mechanical, recipe
  provided) + the G10 covered flip (public-covered 1→3). START HERE:
  `docs/dev-log/handover/2026-07-01-claude-handover-v06-integration.md`.
- **As of 2026-07-01 (v0.6 non-Gaussian ordinal + Gamma → COVERED-READY, staged for maintainer; Claude solo
  autonomous; `main` @ `94d20319`/count 50 UNCHANGED; six stacked PRs #215–#220 open).** Executed the 7-hour
  plan: BOTH new non-Gaussian families now have all doc-16 covered PREREQUISITES — (1) a JOINT estimator
  (`fit_laplace_reml(family=:ordered_probit)` estimates σ²a + the K−1 cutpoints; `family=:gamma)` estimates
  σ²a + the shape ν), (2) an agreeing SAME-ESTIMAND comparator on an A=I/repeated-records iid reduction
  (**`ordinal::clmm`** for ordinal — glmmTMB does NOT fit cumulative-link; **`glmmTMB Gamma(link="log")`** for
  Gamma; both AGREE), and (3) a PASSING PRE-DECLARED 48-seed recovery gate (both 48/48, `|bias|≤2·MCSE`).
  Chains: ordinal **#215→#218→#220**, Gamma **#216→#217→#219**. This session also HARDENED the Gamma joint
  fit — a runaway shape (`ν≈4e5`) on uninformative data → a σ²a+ν **safety rail** (`log(init)±8`, mirroring the
  ordinal σ²a guard) + informative A=I test fixture; the 48-seed gate re-runs **byte-identical** post-rail
  (rail proven INERT on identified data). A real `rose-systems-auditor` on the rail slice → PROMOTE-WITH-CHANGES
  (3 documentation-lockstep fixes applied; Rose independently re-ran the gate + suite). A throwaway trial-merge
  `main→#220→#219` **verified** the integration: **3 trivial keep-both conflicts** (`nongaussian.jl` allow-list
  + both `elseif` cases; the two design-doc rows), `validation_status.jl`/`test/runtests.jl` auto-merge,
  integrated `Pkg.test()` GREEN, count **50**, both families symbol-reachable. **Honesty pins HOLD: public-covered
  FITTING = 1 UNCHANGED, `validation_status()` = 50, NOTHING flipped** (V6-ORDINAL + V6-GAMMA stay `partial`;
  engine-covered ≠ R-public-covered). **MAINTAINER-GATED (non-autonomous): merge the 6 PRs (recipe verified) +
  the G10 covered flip (would move public-covered 1→3 + wants a final full-chain Rose).** Deferred (not covered
  blockers): doc-20 Step-4 scale-labelled h² (ordinal liability clean; Gamma observation needs NS-2017 trigamma
  lit-check — do NOT guess); broader-DGP + pedigree-A recovery; 2nd comparators. NOTE: this AGENTS.md snapshot
  bullet is a 4th trivial keep-both conflict at merge (prepend, like #213↔#211). START HERE:
  `docs/dev-log/handover/2026-07-01-claude-handover.md`.

- **As of 2026-06-30 (overnight 4-PR batch MERGED to `main`; Claude solo + maintainer merge authorization;
  `validation_status()` 48→50).** Landed: **#211** v0.4 MV broader-DGP recovery (full-sib + 3-trait recovery
  **DISCHARGED** on the covered `V4-MV-REML` row — pre-declared 48-seed Totoro gates both PASS all four criteria,
  Curie/Fisher/Mendel pre-run panel, Rose PROMOTE-with-changes; ADDITIVE, covered status UNCHANGED); **#212**
  v0.6 ordered-categorical (ordinal) probit family kernel + **#214** v0.6 Gamma (log-link) family kernel — both
  internal, experimental/`partial`, with exact reduction oracles (ordinal K=2→`BernoulliProbit`; Gamma
  ν=1→Exponential) and log-concave OBSERVED-info weights, each real-Rose-audited (PROMOTE); **#213** handover +
  doc-20 v0.6 covered-path spec. `validation_status()` = **50** (`V6-ORDINAL` + `V6-GAMMA` added, both `partial`);
  **public-covered FITTING = 1 UNCHANGED** — no covered flip (the kernels are engine-internal, not exported, not
  the public default). Comparator note: ordinal same-estimand = **`ordinal::clmm`** (glmmTMB does NOT fit
  cumulative-link ordinal); Gamma = **`glmmTMB Gamma(link="log")`** (valid, installed locally). **NEXT (7-hour
  autonomous plan): v0.6 toward covered** — ordinal cutpoint + Gamma shape JOINT estimation → fitted-`:symbol`
  wiring → same-estimand comparators (glmmTMB local) → pre-declared recovery gates (Totoro); covered flips stay
  maintainer-G10. START HERE: `docs/dev-log/handover/2026-06-30-claude-handover-v04-v06.md`.

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

## Archived 2026-07-14 — prior live snapshot (verbatim)

- **As of 2026-07-08 (plotting-layer AlgebraOfGraphics migration — RECOVERED + FIXED + VERIFIED
  LIVE + TWICE ROSE-AUDITED + **MERGED** (PR #264 → `main` @ `50131e69`); Claude (Opus), two sessions,
  R-lane session on maintainer instruction; rows **55** / covered **13** / `public_covered_count` **5**
  UNCHANGED).** Five plotting files had sat
  uncommitted for two days (mtime 07-06) as an unfinished mid-conversion of `HSquaredMakieExt` to
  AlgebraOfGraphics (`:variance_components` + `:breeding_values`); AoG had never existed on any ref.
  **Five defect classes fixed** (three found by reading, two — (4) and (5) — only by rendering the PNG
  and looking at it)**:** (1) every marker drawn TWICE — the manual `scatter!` was restoring
  z-order after the whiskers overpainted, so AoG now owns the single marker layer and whiskers go behind
  via `translate!`; (2) `_axes_by_panel` pattern-matched `Label`s out of `fig.content` and index-zipped
  them to axes (two undocumented internals) — replaced with AoG's supported `FigureGrid.grid` accessor +
  a shape guard; (3) the full term list was forced onto EVERY facet's yticks — now per-facet; (4) *found
  only by rendering the PNG and looking at it* — title/subtitle drawn once PER FACET, `ylabel` leaking
  the mapped variable `"rank"`, x/y scales LINKED across facets (h² on `[0,1]` crushed against a `0–40`
  variance scale), and the `[0,1] boundary` annotation clipped at the data limit; (5) *found only by
  rendering the PNG, and it had PASSED an object assertion* — the `[0,1] boundary` flag was anchored at
  `hi` for EVERY crossing, so a `lo <= 0` interval flagged the one end it respects, with the headroom
  bump on the wrong side; the flag is now anchored at the crossed end (both ends when both cross) and the
  driver asserts anchor position, row, and alignment rather than merely counting the annotation.
  **VERIFIED:** compat
  pin resolves (`AlgebraOfGraphics 0.13.0` + `Makie 0.24.13` + `CairoMakie 0.15.13`, Julia 1.10.0), the
  extension precompiles, **9/9 kinds draw a `Makie.Figure`** (explicit + inferred); on the *forest payload
  specifically*: `Scatter=1` per axis, `NaN` whisker draws nothing, whisker/zero-line `z=-1.0`, boundary
  `Text` on the h² axis ONLY (control payload draws none); both AoG figures rasterize, `Pkg.test()` GREEN
  dependency-free. **One machine, one version set** (Julia 1.10.0, macOS/arm64) — not a cross-version or
  cross-platform claim. The facet-order assumption HOLDS on AoG 0.13.0. Re-runnable, **mutation-tested**
  driver: `docs/dev-log/scripts/2026-07-08-plotting-aog-livedraw.jl` (it rasterizes BEFORE asserting, so
  the PNGs exist on a failing run). The driver also runs as the **opt-in `plotting` CI job** — off by
  default; dispatch CI with `run_plotting = true` — which uploads the figures as an artifact.
  **Standing trap:** the default-CI stub test
  asserts `isempty(methods(hsquared_figure))` with Makie/AoG out of that environment, so it passes
  *precisely when the extension fails to load* — a green `Pkg.test()` is NEVER evidence about the
  drawing layer. Also:
  **`julia` is not on `PATH` in a Claude Code shell** (`~/.juliaup/bin`) — do not conclude the toolchain
  is absent. **PR #264 MERGED** → `main` @ `50131e69`; branch `feat/2026-07-08-plotting-aog` retained.
  **Two** real `rose-systems-auditor` audits, both PROMOTE-WITH-CHANGES, all changes applied:
  the first on the branch (false 2026-06-22 AoG evidence pointer in `test/runtests.jl`, unreproducible
  evidence, under-covering SUPERSEDED banner); the second on the defect-5 delta (a dangling "(see below)"
  evidence pointer, a defect count left inconsistent across **five** surfaces — Rose named four, the
  sweep found the fifth — three absolutes falsified by the new opt-in CI job, and an `if: always()`
  artifact upload defeated by rasterizing *after* asserting).
  Coordination board **UPDATED** — the R-lane-session lane exception is recorded and closed
  (`docs/dev-log/coordination-board.md`, 2026-07-08 entry). No action owed from the R lane.
  **SIX GATES THAT COULD NOT FAIL** were found closing this slice, each by the reflex the previous
  one taught: (1) the CI stub test above; (2) `shinichi-brain/tools/check-after-task.R` defined a
  main and never called it, so the documented CLI exited 0 for ANY input — including nonexistent
  files — for its entire life, while `protocols/after-task.md` cited it as *the* DoD gate; (3) the
  sibling sweep found `rose-pattern-scan.R` with the identical defect (both R honesty gates dead;
  every shell/Python tool fine); (4) `handoff_gate.sh` audited only the checked-out branch;
  (5) **restoring (3)'s missing `main()` did NOT restore the gate** — a later negative control showed
  `rose-pattern-scan.R <nonexistent-root>` still exiting 0, because `list.files()` globs a missing
  directory into zero files with no error and no warning, so a typo'd path "passed"; (6) this repo's
  own live-draw driver asserted `nplots(ax, Text) == 1` — it *counted* the `[0,1]` flag and never
  asked where it sat, which is exactly how defect (5) of the plotting layer survived a Rose audit.
  (2) fixed + pushed (`shinichi-brain` @ `3468312`, guarded by `sys.nframe() == 0L` — NOT
  `!interactive()`, which is FALSE under `Rscript -e 'source(...)'` too and would break the
  workaround); (4) fixed independently by a parallel session (`1f1df6f`); (3)+(5) genuinely fixed at
  `shinichi-brain` @ `d85299f` (root guard) and `@bbc1c34` (locale-independent matching), lesson banked
  at `@58a2936`; (6) fixed here — the driver now asserts anchor position, row, and alignment.
  **Before trusting a green, make it go red on purpose — including the gate you just repaired.**
  Nothing promoted. Evidence: `docs/dev-log/check-log.d/2026-07-08-plotting-aog.md`.
  START HERE: `docs/dev-log/handover/2026-07-08-claude-handover.md`.

- **As of 2026-07-14 (v0.7 genomic public-activation arc — PAUSED FOR CLAUDE HANDOVER; NOT ACTIVATED).**
  Both twins are on `codex/2026-07-13-v07-performance-localization`: Julia
  `9d1527e9` (draft PR #274) and R `120d04d` (draft PR #137). The latest
  pushed checks are green. Totoro's D0F recomputation remains live with 16
  workers; the last durable checkpoint was 432/576 recomputations after all
  576/576 official fits completed successfully. No D1 or D2 seed has been
  consumed, D0F is not adjudicated, default R routing remains held, and
  `public_covered_count` remains **5**. CARRIED-OVER: a four-file prospective R
  downstream-contract amendment awaiting fresh Noether/Hopper/Fisher review,
  plus an untracked Julia downstream-replay scaffold that is not evidence.
  Preserve both dirty working trees and the live Totoro process. START HERE:
  `docs/dev-log/handover/2026-07-14-claude-handover.md`.

- **As of 2026-07-14 (v0.7 genomic public-activation arc — RETRY-3 REPAIR READY TO LAND; NOT ACTIVATED).**
  D0F retry 2 completed 576 official R fits and 576 base-R recomputations but
  the exact Julia replay failed before row 1 with
  `Cmd(::Vector{AbstractString})`. Both D0F roots are permanently
  unadjudicated; both 576-seed phenotype spaces and bootstrap spaces are
  retired. The prospective concrete-string repair and disjoint retry-3 bases
  `2034000000` / `2035000000` pass focused twin checks, full Julia `Pkg.test()`,
  and Fisher/Grace/Noether review. No D1/D2 seed has been consumed, default R
  routing remains held, and `public_covered_count` remains **5**. The untracked
  downstream Julia replay is still an incomplete non-evidence scaffold. START
  HERE: `docs/dev-log/recovery-checkpoints/2026-07-14-v07-d0f-retry2-infrastructure-blocker.md`.

- **As of 2026-07-14 (v0.7 genomic public-activation arc — RETRY-3 PRESEAL ADMISSION; NOT ACTIVATED).**
  Both blocked D0F roots and their phenotype/bootstrap seed spaces remain
  permanently retired. The prospective concrete-string repair and disjoint
  retry-3 bases `2034000000` / `2035000000` are committed and pushed; focused
  twin checks and package checks are green. A zero-seed Julia 1.10 preflight
  now opens the exact sealed tree and exercises commit/blob/sidecar/ancestry/
  clean-tree checks before any phenotype can be generated. NEXT: obtain five
  fresh exact CLEAN receipts, deploy the bound commits to Totoro, mint a new
  D0F root/preseal, and run that preflight. No D1/D2 seed has been consumed,
  default R routing remains held, and `public_covered_count` remains **5**. The
  untracked downstream Julia replay remains an incomplete non-evidence
  scaffold. START HERE: `docs/dev-log/recovery-checkpoints/2026-07-14-v07-d0f-retry2-infrastructure-blocker.md`.

- **As of 2026-07-14 (v0.7 genomic public-activation arc — RETRY-3 RETIRED; RETRY-4 REPAIR IN PROGRESS; NOT ACTIVATED).**
  Retry 3 completed 576 official fits and 576 base-R recomputations but wrote
  zero Julia replay rows: the R bridge discarded the boundary solver's finite
  AI score norm and official attempts stored `gradient_norm=NA`, which the
  exact Julia replay correctly rejected. The sealed root and its
  `2034000000` / `2035000000` phenotype/bootstrap spaces are permanently
  retired and non-evidence. The prospective bridge/admission repair passes
  focused pure-R tests and a live R-to-Julia boundary test. NEXT: freeze
  disjoint retry-4 seeds, batch-safe replay/recomputation, five fresh exact
  reviews, a new preseal, and a zero-seed preflight. No D1/D2 seed has been
  consumed, default R routing remains held, and `public_covered_count` remains
  **5**. The untracked downstream Julia replay remains an incomplete
  non-evidence scaffold. START HERE:
  `docs/dev-log/recovery-checkpoints/2026-07-14-v07-d0f-retry3-gradient-contract-blocker.md`.

- **As of 2026-07-14 (v0.7 genomic public-activation arc — RETRY-4 NEGATIVE ENDPOINT; NOT ACTIVATED).**
  Retry 4 completed 576 official fits and 576 independent base-R
  recomputations, but exact Julia replay stopped after 455 admitted rows on a
  one-ULP endpoint-representation contract defect. Four batches stopped
  fail-closed and 121 later rows have no replay output. No Julia summary or
  adjudication receipt exists. The root and `2036000000` / `2037000000` seed
  spaces are permanently retired and unadjudicated; D1/D2 never opened.
  Classification: `UNADJUDICATED — REPLAY_ENDPOINT_REPRESENTATION_BLOCKER`,
  not solver, KKT, gradient, convergence, or recovery failure. Default R
  routing remains held and `public_covered_count` remains **5**; only the
  supplied-`Ginv` estimator remains covered. START HERE:
  `docs/dev-log/recovery-checkpoints/2026-07-14-v07-d0f-retry4-boundary-parity-blocker.md`.

- **As of 2026-07-15 (v0.7 genomic public-activation arc — CODEX HANDOFF; NOT ACTIVATED).**
  Retry 4 is a permanently retired diagnostic root classified
  `UNADJUDICATED — REPLAY_ENDPOINT_REPRESENTATION_BLOCKER`: 576 official fits
  and 576 base-R recomputations completed, while exact Julia replay stopped
  after 455 admitted rows on a one-ULP endpoint representation defect. No
  compute is live, no Julia summary or adjudication receipt exists, and D1/D2
  never opened. Both twins are pushed on
  `codex/2026-07-13-v07-performance-localization` at Julia `41219ce1` (draft
  PR #274) and R `31befc0` (draft PR #137), with green CI. Default R routing
  remains held and `public_covered_count` remains **5**; only the
  supplied-`Ginv` estimator remains covered. START HERE:
  `docs/dev-log/handover/2026-07-15-codex-handover.md`.

- **As of 2026-07-15 (v0.7 genomic public-activation arc — RETRY-6 RETIRED; NOT ACTIVATED).**
  Retry 6 passed every pre-RNG gate and completed 576 official fits, 576
  independent base-R recomputations, and 576 exact Julia replays. All three
  create-once summaries are complete and mutually agree, but the first
  post-run receipt writer stopped before writing a receipt because summary
  reconstruction rebound Julia rows to the ordinary-R route. Classification:
  `UNADJUDICATED_POSTRUN_ADJUDICATOR_ROUTE_BLOCKER`. The 9,248-file root and
  complete `2040000000` / `2041000000` seed spaces are permanently retired;
  no post-run review receipt, adjudication receipt, D1, or D2 exists. A
  seed-free prospective R repair at `562b93e` threads the declared route
  through D0F and D1 summary reconstruction and retires the seed spaces; it
  does not repair or adjudicate Retry 6. Default R routing remains held and
  `public_covered_count` remains **5**; only the supplied-`Ginv` estimator
  remains covered. START HERE:
  `docs/dev-log/handover/2026-07-15-retry6-terminal-route-repair.md`.

- **As of 2026-07-16 (v0.7 genomic public-activation arc — RETRY-7 ARCHITECTURE + SEED CONTRACT COMPLETE; NO RNG).**
  Research-informed route-safe R admission, weighted D0F/D1 route-lineage
  conservation, adjudication schema v2, exact idempotent receipt recognition,
  and Julia replay route typing are implemented. A full-cardinality synthetic
  D0F-to-D1 lifecycle and mutation campaign passed, and Hopper/Noether,
  Gauss/Karpinski, and Grace/Rose architecture reviews are CLEAN. Disjoint
  Retry-7 phenotype/bootstrap bases `2042000000` / `2043000000` are reserved
  but unspent. Exact-head `R CMD check`, CI, clean Totoro deployment rehearsal,
  preseal, chronology audit, official compute, and adjudication remain pending.
  Default R routing remains held and `public_covered_count` remains **5**; only
  the supplied-`Ginv` estimator is covered. Platform ownership is sequential:
  one fresh Terra/high Codex task continues implementation; use Sol only for
  explicit seed-contract, adjudication, and final adversarial-gate jobs. START
  HERE: `docs/dev-log/handover/2026-07-16-codex-handover.md`.

- **As of 2026-07-18 (v0.7 genomic public-activation arc — RETRY-8 D0F ADJUDICATION RECEIPT: PASS / COMPLETE, byte-reproducible).**
  The **first COMPLETE D0F adjudicated receipt** across the whole recovery arc
  (retries 4–7 all died in this tail). `retry8-prep/d0f/stage_adjudication_receipt.tsv`:
  `v07-genomic-recovery-v3-adjudication-2`, **`verdict=PASS`, `stage_decision=COMPLETE`**,
  receipt sha `04cc0740…`; `validate-final` re-derived it **byte-identical** (RC=0).
  576 official fits (all converged; 556 interior / 10 lower / 10 upper) + 576 base-R
  recomputations + 576 exact Julia replays in triple parity (attempt max-diff 3.18e-12,
  summary 7.11e-15, ≤1e-10); 5 bound post-run reviews (all CLEAN). The 8-retry Totoro
  JuliaCall blocker was root-caused to a **global-vs-project OrderedCollections version
  split** (1.8.2 vs 2.0.1) — NOT TMPDIR — and fixed with **no seal/tracked-file change**
  (deployed `Project.toml` byte-identical to sealed `976814`; fix in the non-sealed global
  bridge env + gitignored Manifest). Both lanes git-clean. Per the pre-registration this
  COMPLETE receipt **only opens D1/D2**: `public_covered_count` stays **5**,
  `ordinary_auto_genomic` route NOT activated, V2-GRM/V2-GINV stay partial. **Spawned-Rose
  close-out CONFIRMED** (claim-vs-evidence, bounds respected, nothing overstated). NEXT lane
  = **D1** (open): ultra-plan → pre-register (fresh seeds; 2042/2043 are spent) → adversarial
  pre-draw panel → draw → same validated pipeline → adjudicate/validate-final → Rose. The
  Totoro JuliaCall env fix (global-env OrderedCollections 2.0.1 + gitignored RCall-free
  Manifest) is persistent — VERIFY `ok=TRUE` before D1. START HERE:
  `docs/dev-log/handover/2026-07-18-claude-handover.md`.

- **As of 2026-07-19 (v0.7 genomic public-activation arc — D0F RE-SEALED at C_fix `5325e95`: PASS / COMPLETE, identical fits, new receipt identity).**
  The D0F stage was re-sealed to fold in the hsquared `recompute.R:278` fix (`r_recomputer_path`
  derived by name, not `= script`; two unconditional git-identity gates bind the sealed R head, so
  the fix forced a full 576-fit re-run). New receipt `reseal-d0f/stage_adjudication_receipt.tsv`:
  `v07-genomic-recovery-v3-adjudication-2`, **`verdict=PASS`, `stage_decision=COMPLETE`**, sha
  `0f5fbb54…` (supersedes retry8 `04cc0740…`); `validate-final` re-derived the **new** receipt
  byte-identical (RC=0). **Identical fits, new receipt identity** — NOT byte-identical to `04cc0740`:
  attempt max-diff `3.18e-12` bit-identical to retry8, tally 556 interior / 10 lower / 10 upper
  identical, 5 bound post-run reviews CLEAN. summary max-diff moved `7.11e-15 → 2.27e-13` — a benign
  1-ULP reshuffle on re-measured runtime/RSS medians (Gauss: no scientific quantity moved;
  `recompute.R:278` is identity-only), both ≪1e-10. Receipt identity fields advanced by design
  (`r_driver`/`r_recomputer_commit` `5325e95`, `r_recomputer_sha` `eb29c8f4`, `preseal` `b209ec0c`,
  `adjudication_key` `88d4cf2f`); driver bytes (`d1a7d930`) and Julia replay (`976814`) unchanged.
  **Spawned-Rose close-out CONFIRMED-WITH-CAVEATS** (PASS holds; summary figure + Gauss caveat
  folded in; 12-doc supersede ledger sound). Per the pre-registration this COMPLETE receipt **only
  opens D1/D2**: `public_covered_count` stays **5**, `ordinary_auto_genomic` route NOT activated,
  V2-GRM/V2-GINV stay partial. **D1 STATUS (2026-07-19): three latent D1-ONLY blockers found + fixed, all
  fail-closed pre-draw — ZERO seed drawn.** (1) `recompute.R:278` → the `0f5fbb54` re-seal above.
  (2) `marker_ratio` float-precision drift in Julia `_validate_manifest` (R serializes `10/3` at 14 digits in
  `cell_table.tsv` vs full Float64 in the manifest; the exact `==` drifted) → **fixed** (local `8f214eb3`,
  now tolerant `≤1e-12` like `_read_cell_table`; membership/order/seed stay exact).
  (3) stale `.sha256` **integrity-pin sidecar** on `stage_replay.jl` — the incomplete tail of fix (2): the
  edit changed the file but not its git-tracked pin, so `preseal` refused → **fixed** (local `512d7ca7`,
  deployed `8092fcb6`; sidecar regenerated to `36a264b2`; Rose-swept all sidecars, only this one stale).
  Each fix moves a head, and the admission hard-binds deployed julia == the D0F predecessor's
  `julia_replay_commit`, so a **3rd D0F re-seal (`reseal3` @ Julia `8092fcb6`) is DONE — PASS/COMPLETE**
  (2026-07-19 23:33 UTC), receipt `2903dd16…` (supersedes `0f5fbb54`), `attempt_max_diff` bit-identical
  (`3.183e-12`) → identical fits / new receipt identity, tally 576/556/10/10, byte-reproduced by
  `validate-final`, 5 reviews CLEAN. **NEXT = supersede, then D1 admission** (bind the NEW `reseal3-d0f`) →
  PRE-gate → panel → conditional draw. `public_covered_count` stays **5**. START HERE:
  `docs/dev-log/handover/2026-07-19-codex-handover.md` (full recipe:
  `docs/dev-log/handover/2026-07-19-claude-handover-d1-blocker2-reseal.md`).

- **As of 2026-07-20 (v0.7 D1 reseal4 post-draw terminal failure — root and seed space retired).**
  Canonical D0F reseal4 remains PASS/COMPLETE at R `5325e95` / Julia `418be984`, receipt `e88207e5…`.
  D1 `d1-reseal4` passed its seed-free admission and unanimous read-only GREEN panel, then its sole Totoro
  controller drew four official smoke seeds and terminated at `RC=21`: **`fewer than 16 completed smoke
  attempts`**. The controller wrote `POSTDRAW_TERMINAL_FAILURE`; no full corpus, lock, recomputation,
  Julia replay, summary, review, adjudication, or final D1 receipt exists. `/home/snakagaw/hsq_work/d1-reseal4`
  and **the entire** `2028000000/101:148` D1 seed space are immutable retired negative evidence: never
  repair/restart/resume/subset/pool them. `public_covered_count` remains **5**;
  `ordinary_auto_genomic` remains held; V2-GRM/V2-GINV remain partial. The D1 marker-ratio manifest
  regression suite landed in `21fd2425` and passed its synthetic selftest. **The D1 lane is PAUSED by
  owner directive (Shinichi, 2026-07-20; brain D-68): the next slice DIAGNOSES why smoke attempts fail
  at all — do not design attempt five until the failure mode is named.** START HERE:
  `docs/dev-log/after-task/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md`.
