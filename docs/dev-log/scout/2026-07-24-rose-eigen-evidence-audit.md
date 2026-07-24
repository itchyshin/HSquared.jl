# Rose audit — `V1-EIGEN-REML` staged experimental→covered evidence package (G8)

**Auditor:** Rose (spawned subagent, real G8 claim-vs-evidence audit — not a lens) ·
**Date:** 2026-07-24 · **Lane:** Julia engine (`HSquared.jl`) ·
**Branch:** `codex/2026-07-13-v07-performance-localization` ·
**Session commits audited:** `1d9ec57d`, `d61f79e0`, `f27c6131`, `e9c3a811`, `a9d8c01e`
plus uncommitted working edits to `docs/design/capability-status.md`,
`docs/design/validation-debt-register.md`, and the untracked
`docs/dev-log/native-engine-arc/2026-07-24-szymek-closeout-draft.md`.

**Scope reminder:** this package is **STAGED, not promoted.** No capability-status row is
flipped. `public_covered_count` must stay **5**. The audit verifies (i) the package does not
overclaim, (ii) "still partial / experimental" is stated everywhere, (iii) every factual claim
is backed by repo evidence, and (iv) the fences hold.

---

## VERDICT: **CLEAR-WITH-CHANGES** — 3 required changes

The G11 evidence is genuine and independently reproduced (recovery gate pre-declared and
un-relaxed; comparator engine target reproduced byte-identically). The fences all hold
(count stays 5, no capability flip, no D1/TMB/hsquared touch, foreign files untouched). **But
one load-bearing descriptive claim is contradicted by same-session measurement:** the
high-fill (HF) arm is sold as `nnz(L)/n ≥ 76` and as the regime `:auto` routes to eigen, when
the gate's own `n=1000` HF seeds measure `nnz(L)/n ≈ 48–51`, all **below** the 60 threshold —
so `:auto` would route **both** gate arms to sparse AI-REML, and the gate never exercises
`:auto`'s eigen-selected regime. The recovery evidence itself is unaffected (eigen is fit
**directly**), so this is a correction, not a retraction → **CLEAR-WITH-CHANGES**, not HOLD.

---

## Fences (all hold)

| Fence | Status | Evidence |
|---|---|---|
| `public_covered_count` stays 5 | ✅ | Asserted in every doc + both status rows; `src/validation_status.jl` NOT in session diff (engine count untouched). |
| No capability move (row stays `experimental`) | ✅ | `git diff docs/design/capability-status.md`: the `Eigen-once …` row's status column reads `experimental` before and after. |
| D1 genomic PAUSED (D-68) untouched | ✅ | Session commits `8b3809c6..HEAD` touch 10 files, none a `phase2_v07_genomic_*`/D1 file. |
| TMB native engine deferred | ✅ | No `target = :native`/TMB token in session diff. |
| R twin (`hsquared`) not edited from this lane | ✅ | Session diff is entirely `HSquared.jl` paths; no `hsquared/` path. |
| 4 pre-existing foreign dirty files untouched | ✅ | The two `M` retry5 files + the two `??` (`2026-07-18-two-lever…`, `phase2_v07_genomic_recovery_v3_downstream_replay.jl`) remain dirty, appear in no session commit, unchanged by the session. |

---

## Per-item findings

### A. Pre-declaration integrity — **CLEAN**

- `git show --stat 1d9ec57d`: the predeclaration doc **and** the gate script
  `sim/phase_eigen_reml_recovery_gate.jl` land in the **same** commit, dated 11:52 — **before**
  the result commit `d61f79e0` (11:58). Freeze precedes run.
- `git log --oneline -- sim/phase_eigen_reml_recovery_gate.jl` → **one** commit (`1d9ec57d`);
  `git diff 1d9ec57d HEAD -- sim/phase_eigen_reml_recovery_gate.jl` → **empty**; working tree
  clean. The script is byte-identical to its frozen state.
- The coded acceptance rule matches the predeclaration exactly: `_bias_row` uses
  `ok = abs(bias) <= 2*mcse`; `_report_arm` requires `econv==n && aconv==n && ba.ok && be.ok &&
  agree_ok` with `AGREE_TOL = 1e-6` (gate script lines 100, 112–115). Constants `MU=2.0, SA=1.0,
  SE=1.5, N=1000`, seeds `20267000:047` / `20267100:147` match the predeclaration.
- Result doc (`…-result.md` lines 4–6) records the run at **checkout `1d9ec57d`** (the frozen
  commit), Totoro Julia 1.12.6.
- **No post-hoc threshold relaxation:** results clear the frozen bars with margin (worst
  `|bias|/MCSE = 1.01` vs bound 2; worst reldiff 2.62e-7 vs tol 1e-6). The frozen bars are the
  standard 48-seed gate used by every prior covered close (V4-MV-REML, V6-ORDINAL), not tuned
  to any observed result.

### B. Recovery-gate claim — **CLEAN** (one minor number nit → RC3)

- The result tables reproduce the `GATE_JSON` exactly. WS: σ²a mean 0.9700, bias −0.029972,
  MCSE 0.029689 → ratio **1.01**; σ²e ratio 0.02. HF: σ²a ratio 0.00, σ²e ratio 0.26. Both arms
  48/48 converged (eigen + AI-REML). Max reldiff WS 2.62e-7 / HF 2.18e-7. All match the JSON
  blob at line 68.
- **WS σ²a at 1.01·MCSE is honestly disclosed, not hidden** (result doc "Honest reading" lines
  41–43: "mean 0.970 vs truth 1.00 … within the bound, not a boundary ride").
- **"No detectable bias, never unbiased" framing present** (result lines 39–40; predeclaration
  lines 56–57; gate script line 39).
- **Independently reproduced (my run, Julia 1.10.0):** all spot-checked gate seeds converge on
  both fitters; eigen≡AI-REML reldiff ≤1.3e-7 (e.g. HF seed 20267100 σ²a=0.886614 both paths,
  reldiff 7.71e-8). Convergence and substitutability corroboration hold.
- **RC3 (minor):** the all-96-seed eigen≡AI-REML bound is **2.62e-7** (WS arm), which the result
  doc states correctly ("≤ 2.6e-7 across all 96 fits", line 44). See E/RC3 — the comparator doc
  and both status rows quote the **HF-only** 2.18e-7 as if it were the all-96 bound.

### C. Comparator claim (G11 kind requirement) — **CLEAN** (engine side independently reproduced)

- **Kind requirement honored:** `sommer` 4.4.5 is an independent **REML** optimizer
  (`run_sommer_eigen.R` line 18 `mmer(...)`), not Bayesian.
- **Byte-identical data reconstruction verified by reading:** `prepare_sommer_eigen.jl` uses the
  identical RNG draw order to the gate's `_make_spec` (SEED 20267000, N 1000, WINDOW 50,
  MU/SA/SE 2.0/1.0/1.5).
- **Engine target reproduced byte-identically (my run):** seed 20267000/window=50 →
  eigen σ²a=**1.266229**, σ²e=**1.442756**, matching the comparator table (lines 19–20) to all
  printed digits. The number `sommer` was compared against is genuine.
- **Single-seed + transitive scope honestly stated:** the doc flags this is one WS seed and
  that high-fill is covered *transitively* (sommer≡eigen on WS + eigen≡AI on HF), with "a direct
  high-fill `sommer` run is a cheap optional add" (lines 28–38). Not oversold as a full
  multi-seed external validation.
- **Limitation of this audit:** I did **not** re-execute `sommer` (R/`sommer` is the live-toolchain
  lane); the **7.77e-9** agreement rests on the recorded run. The engine half is reproduced; the
  `sommer` half is documentary. The script is correct and would produce the reported comparison.
- Minor wording: the section header "covered transitively (**rigorous**)" is an
  estimand-identity *inference*, not a direct high-fill measurement; the body is transparent
  about exactly that, so this is a note, not a required change. (See RC1 — "high-fill" here is
  ~49 fill, meaningfully above WS ~17 but below the `:auto` boundary.)

### D. Threshold claim — **CLEAN**

- Single-rep noise caveated (`…threshold-crossover.md` line 13, 68–73). The 21.65 s
  n=4000/window=15 cell is flagged as a GC/first-touch **outlier**, excluded (lines 30, 37–38,
  72). n-adaptive refinement **scoped + DEFERRED** (lines 63–66, 79).
- **No overclaim of optimality:** line 52 states "a single scalar cannot be optimal at every n";
  the decision is "safely conservative", "biased toward the validated sparse default", "never …
  a catastrophic misroute in the grid" (lines 54–66).
- **No ASReml-beat claim** in this doc. "Validated" is adequately fenced as
  "empirically validated (not a guess)" on a single-rep grid with the finer rule deferred.
- This doc is the one artifact that **correctly** characterizes the fill n-dependence
  (49→75.6→124.5 for window=0 at n=1000/2000/4000, lines 17/23/29; line 49–52). The test-comment
  update in `a9d8c01e` likewise n-qualifies ("random ≥76 **at n≥2000**"), as does
  `src/likelihood.jl:409` ("`≥ 76` (n=2000..10000)"). The error in RC1/RC2 is that other
  artifacts dropped this qualifier.

### E. No-overclaim / count / gate bookkeeping — **CLEAN on count + status; TWO required wording fixes (RC2, RC3)**

- **Both status rows say STAYS partial/experimental, no covered flip, count 5:**
  capability row — "**STAYS EXPERIMENTAL this session, NOT covered** … `public_covered_count`
  unchanged (5)"; validation-debt row — "STILL PARTIAL … **no covered flip this session**;
  `public_covered_count` unchanged (**5**)". ✅
- **G11 correctly described as discharged (both legs), G8/G10/R-bridge OWED:** capability row —
  "G11 evidence now assembled … a covered flip additionally OWES a spawned Rose audit (G8), the
  R `method=eigen` bridge, and maintainer sign-off (G10)"; validation-debt row — "G11 DISCHARGED
  … OWES: a real spawned **Rose** audit (G8), the R … bridge (R lane), and maintainer sign-off
  (G10)". ✅ Nothing reads as if eigen is now covered/public.
- **RC2 (required):** both rows carry "random/high-fill `≥76` → eigen" **without** the
  n-qualifier that `src/likelihood.jl:409` and the `a9d8c01e` test comment already have. At the
  regime the rows describe (and at the gate's n=1000) random fill is ≈49 → **sparse**. Fix to
  match the source ("`≥76` at n≥2000; ≈49 at n=1000").
- **RC3 (required, minor):** both rows and the comparator doc (line 34–35, "across ALL 96 gate
  seeds … ≤ 2.18e-7") understate the all-96 max, which is the WS arm's **2.62e-7**. Use ≤2.6e-7
  to match the result doc.

### F. Szymek close-out draft — **CLEAN**

- **Not sent, drafted for the owner** (lines 5–6 "DRAFT for the owner (Shinichi) to review and
  send; not sent by the engine lane").
- **ASReml honesty fence respected:** "we haven't run ASReml ourselves … none of this is a
  verified win over ASReml — the fast numbers we have are on synthetic pedigrees, not yours"
  (lines 33–35); "both numbers are from our synthetic proxies, not a head-to-head against ASReml
  or your data" (line 44). Szymek's ~12.9 s and the fit being "stuck" are attributed to *his*
  report, not claimed as engine measurements (lines 13–14).
- **Numbers grounded, not invented:** the 6.95× (25.4 s vs 176.9 s, random n=10000) and 0.64 s
  (realistic n=10000) figures trace to
  `…/2026-07-24-ai-reml-convergence-findings.md` lines 143 and 93/140; that doc carries its own
  "This is NOT a head-to-head comparison" fence (lines 97–101). The draft's Sources block (lines
  46–56) cites them. "~7×" is honest rounding of 6.95×.

### G. Fences — **CLEAN** (see the Fences table above)

- `git diff 8b3809c6..HEAD --stat`: 10 files, all eigen/comparator/bench/gate/status.
- The `test/runtests.jl` change in `a9d8c01e` is **comment-only** (routing-testset docstring now
  cites the crossover surface and n-qualifies "≥76 at n≥2000") — no test/capability logic change.
- No `public_covered_count` increment, no `hsquared/`, D1, or TMB edit in the session diff.

---

## Required changes (3)

**RC1 — substantive (root cause). Correct the "HF arm = `:auto`'s eigen regime / `nnz(L)/n ≥ 76`
at n=1000" mischaracterization.**
- **Contradiction, measured (my run, Julia 1.10.0, the gate's OWN builder + the exact
  `_sparse_mme_system` fill proxy):**
  gate HF seeds at n=1000/window=0 → `nnz(L)/n` = 51.3 (20267100), 50.8 (20267101),
  51.3 (20267102), 47.8 (20267147) — **all < 60 → `:auto` routes to SPARSE.** WS seeds → 17.2 /
  16.7 (matches the claimed 17–19). Bench cross-check reproduced 49.3 @ n=1000 and 75.5 @ n=2000
  for window=0 (matches the crossover table 49.0 / 75.6). The repo's own
  `src/likelihood.jl:409` and the `a9d8c01e` test comment already scope "≥76" to **n≥2000**.
- **Where it is wrong:**
  - `…-recovery-gate-result.md` line 44–47: *"Recovery therefore holds where eigen is actually
    used (high-fill), not only where `:auto` would pick sparse."* — contradicted; at n=1000
    `:auto` picks **sparse** for **both** arms. The recovery is real but was obtained by fitting
    eigen **directly**, not in `:auto`'s eigen-selected regime.
  - Frozen (cannot edit — freeze integrity) but wrong: predeclaration line 38 and gate-script
    comment line 21 ("`nnz(L)/n ≥ 76`; `:auto` → eigen-once") and the gate's stated purpose
    (script lines 16–17). Add an **erratum** in the result doc noting the "≥76 / `:auto`→eigen"
    descriptor is an **n≥2000** figure and does not hold at the gate's n=1000 (HF ≈ 48–51 →
    sparse); state plainly that eigen was validated by **direct** fits across a WS(~17)→HF(~49)
    fill gradient, and that recovery in the regime where `:auto` actually selects eigen
    (`nnz(L)/n > 60`, i.e. n≥2000 random or n=1000 window≈250) is **not** exercised by this gate.
- **Impact:** does **not** invalidate the recovery PASS or the comparator; the G11 predicate
  (known-truth recovery under a pre-declared un-relaxed gate) is met. It corrects an overstated
  claim about *which regime* was validated.

**RC2 — substantive. n-qualify "≥76 → eigen" in both status rows.**
- `docs/design/capability-status.md` (Eigen-once row) and
  `docs/design/validation-debt-register.md` (V1-EIGEN-REML row) both say "random/high-fill
  `≥76` → eigen". Restate to match `src/likelihood.jl:409` / the test comment: random fill
  reaches `≥76` only at **n≥2000**; at n=1000 random ≈49 → sparse. (Same root cause as RC1.)

**RC3 — minor. Fix the eigen≡AI-REML all-seeds bound.**
- `…-eigen-reml-comparator.md` line 34–35 ("across ALL 96 gate seeds … ≤ 2.18e-7") and both
  status rows quote **2.18e-7** (the HF-arm max) as the all-96 bound. The WS arm max is
  **2.62e-7**; use ≤2.6e-7, consistent with the result doc line 44.

---

## What is honestly NOT covered (state plainly; do not let the package imply otherwise)

- **Not covered / not public.** `V1-EIGEN-REML` stays `partial` / `experimental`;
  `public_covered_count` stays **5**. No R `method="eigen"` surface exists (R lane, not built).
- **G8/G10/R-bridge still OWED.** This audit (G8) is the claim-vs-evidence leg only; maintainer
  sign-off (G10) and the R bridge remain. Even with G11 discharged, the covered flip is the
  owner's call and is **not** part of this session.
- **`:auto`'s eigen-selected regime is not exercised by the recovery gate.** The whole gate runs
  at n=1000 where both arms sit below the 60 fill threshold (WS ≈17, HF ≈49). Recovery *in the
  regime `:auto` actually picks eigen* (`nnz(L)/n > 60`) rests on the direct-fit substitutability
  argument (eigen≡AI-REML on the HF seeds), not on a gate run inside that routing regime.
- **The external comparator is single-seed, single-`sommer`, engine-half-reproduced only.** One
  WS seed; high-fill agreement is transitive inference, not measured; the `sommer` run itself was
  not re-executed in this audit. A 2nd same-estimand lineage (ASReml/BLUPF90) and a direct
  high-fill `sommer` run remain open.
- **Recovery scope is narrow:** `Z=I`, interior h²=0.4, n=1000 only. Larger-n / broader-h²
  recovery, `Z≠I`, and the dense wall (`n > max_dense_n`) are not covered (the last two are
  guarded `ArgumentError`s, documented scope edges).
- **No ASReml head-to-head** anywhere; the Szymek numbers are synthetic-proxy, correctly fenced.
- **Threshold 60 is validated on single-rep timings**, safely-conservative, not provably optimal
  (a scalar cannot be optimal at every n); the n-adaptive refinement is deferred.

---

### Reproductions run for this audit (Julia 1.10.0, `--project=.`, `OPENBLAS_NUM_THREADS=1`)

- Fill proxy (`_sparse_mme_system` → `cholesky` → `nnz(L)/n`) for gate HF seeds n=1000/window=0:
  **47.8–51.3** (all < 60); WS seeds: 17.2 / 16.7. Bench cross-check: 49.3 @ n=1000, 75.5 @
  n=2000 (window=0) — reproduces the crossover table.
- `fit_eigen_reml` vs `fit_ai_reml` on 4 gate seeds: both converge; eigen≡AI-REML reldiff
  ≤1.3e-7; comparator engine target seed 20267000/window=50 reproduced exactly
  (σ²a=1.266229, σ²e=1.442756).

> Related: `docs/design/16-promotion-gate-predicates.md` (G1–G11) ·
> `sim/phase_eigen_reml_recovery_gate.jl` (frozen `1d9ec57d`) ·
> `docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-recovery-gate-{predeclaration,result}.md` ·
> `docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-comparator.md` ·
> `docs/dev-log/native-engine-arc/2026-07-24-eigen-auto-threshold-crossover.md` ·
> `src/likelihood.jl:405-417` (`_auto_reml_route`, `_AUTO_EIGEN_FILL_THRESHOLD`).
