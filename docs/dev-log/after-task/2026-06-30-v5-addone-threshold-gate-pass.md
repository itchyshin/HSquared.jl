# After-task — V5 add-one genome-wide threshold calibration gate: PASS, leg discharged (2026-06-30)

Resumed a frozen session (the maintainer asked to "resume — it is frozen somehow"). The frozen session had
two parallel threads agreed; both background agents died with the freeze and were restarted. This report
covers the **v0.5 finish** thread: the pre-declared **add-one** threshold calibration gate — the constructive
follow-up the #202 banked NEGATIVE named. **GATE PASS; the type-I-control calibration LEG of V5 is discharged
for the add-one rule at one design; NOTHING promoted to covered.** Claude solo, branch
`feat/2026-06-30-v5-addone-threshold-gate`.

## Live phase snapshot

- **As of 2026-06-30 (V5 add-one threshold calibration gate PASS — leg discharged, nothing promoted; branch
  `feat/2026-06-30-v5-addone-threshold-gate` @ `f98651e0`, PR pending; `main` @ `218f635d`/#202).**
  Followed the #202 banked NEGATIVE (the `(1−α)` quantile threshold failed anti-conservative, 0.069/2.42·MCSE).
  A PRE-DECLARED type-I-control gate on the CONSERVATIVE add-one decision rule
  (`sim/phase5_qtl_addone_gate.jl`; predeclaration committed `d26896c9` BEFORE the run; SAME NULL DGP/design as
  the failed gate — n=300, m=200, nperm=2000, α=0.05; only the accept/reject rule swapped to
  `genome_wide_pvalue ≤ α`; 20 cold seeds 20260920..20260939) **PASSED** the one-sided-upper
  (not-anti-conservative) criterion `mean type-I − α ≤ 2·MCSE`: mean empirical type-I **0.0543** (excess
  +0.0043 ≤ 2·MCSE 0.0170; MCSE 0.0085). The conservative add-one permutation rule controls family-wise type-I
  at α as its exact-permutation-test construction predicts — exactly where the quantile rule failed on
  byte-identical RNG streams. This DISCHARGES the type-I-control calibration leg of V5 for the add-one rule at
  this design. STAYS `partial`/`experimental`; `validation_status()` = 48 rows / covered 7 / partial 37
  UNCHANGED; public-covered FITTING = 1; R `gwas()` significance wording stays HELD. V5 covered STILL owes an
  external comparator (PLINK `max(T)` / GenABEL), broader n/m/LD designs, and the R `gwas()`/`marker_scan()`
  activation. **NEXT: the external comparator + broader designs (V5), and the GLLVM-adoption course-correction
  (see below).** START HERE: this report.

## What changed

- NEW `sim/phase5_qtl_addone_gate.jl` (`run_addone_calibration` mirrors `run_threshold_calibration`'s RNG order
  exactly; only the type-I decision differs — add-one `genome_wide_pvalue ≤ α` instead of the `(1−α)` quantile
  threshold). Predeclaration `docs/dev-log/recovery-checkpoints/2026-06-30-v5-qtl-addone-gate-predeclaration.md`
  (committed `d26896c9` with RESULT: PENDING → filled with the PASS in `f98651e0`).
- Evidence APPENDED (status UNCHANGED) to V5-MARKER-THRESHOLD across `src/validation_status.jl`,
  `docs/design/validation-debt-register.md`, `docs/design/capability-status.md`.

## Checks run and exact outcomes

- Gate: `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_qtl_addone_gate.jl` → 20/20
  runs, GATE PASS (mean type-I 0.0543, excess +0.0043 ≤ 2·MCSE 0.0170, per-seed range [0.014, 0.179]), exit 0.
- `Pkg.test()` → **"Testing HSquared tests passed"** (exit 0).
- `validation_status()` independently = 48 rows / covered 7 / partial 37 — UNCHANGED (evidence-string append,
  no status flip).
- Documenter: unaffected (no `docs/src/` change).

## Public claim audit (Rose)

Real `rose-systems-auditor` audit on the committed slice → **PROMOTE** (clean, no changes required). Verified
INDEPENDENTLY: (1) the pre-registration is genuine — `git diff d26896c9 f98651e0 -- sim/phase5_qtl_addone_gate.jl`
is EMPTY (criterion/seeds/nperm/one-sided rule byte-identical pre/post; only the predeclaration RESULT flip +
status appends differ), no post-hoc relaxation; (2) the one-sided criterion is construction-justified
(Phipson–Smyth exact permutation test → upper-bound estimand) and declared before the run; (3) Rose **re-ran
the gate** and reproduced GATE PASS to the digit (mean 0.0543, excess +0.0043, 2·MCSE 0.0170); (4) NO status
flip — `validation_status()` independently 48 rows / covered 7 / partial 37, V5 stays `partial`/`experimental`,
evidence strings carry no "calibrated/covered/production/validated" overclaim, `gwas()` held; (5) no stale
FAIL framing misapplied to the PASS; the "byte-identical nulls" claim is correctly scoped per-RNG-stream
(disjoint seed ranges). Rose's one observation (the 0.179 outlier seed *widens* 2·MCSE, making the test more
conservative against the package, so it does not manufacture the PASS) is already reflected in the
predeclaration's honest-reading paragraph.

## Tests of the tests

- The gate is a genuine pre-registration: the criterion (one-sided upper, α, seeds, nperm) was fixed in
  `d26896c9` before any seed ran; `git diff d26896c9 f98651e0 -- sim/phase5_qtl_addone_gate.jl` shows no logic
  change. No post-hoc relaxation.
- The one-sided criterion is construction-justified, not a convenient softening of #202: the add-one rule
  `(1 + #{null ≥ obs})/(nperm+1) ≤ α` is a valid exact permutation test that targets an UPPER bound on type-I
  (Phipson–Smyth), so the honest estimand is "does it violate α", which is one-sided. #202's estimator targeted
  exact calibration at α, so two-sided was right there. The change of sidedness tracks the change of estimator,
  declared in advance.
- A PASS here is a LOW-POWER non-rejection of "type-I ≤ α", read as "consistent with valid level control,"
  not "exactly calibrated." A FAIL would have been a genuine surprise (non-exchangeable nulls), not a
  foregone conclusion — so the PASS carries information.

## What did not go smoothly

- The local `julia` shim was absent from PATH; used `~/.juliaup/bin/julia` directly. No effect on results.
- The per-seed type-I range is wide (one seed at 0.179). This is single-seed sampling of a 1000-rep type-I and
  does not bear on the pre-declared mean-level verdict (the gate is on the 20-seed mean with its MCSE); the
  report states this explicitly rather than hiding the spread.

## Known limitations

- One design point (n=300, m=200, one LD scheme), intercept-only null. The PASS establishes level CONTROL for
  the add-one rule on THIS design — not power, not broader architectures, not covariate-adjusted GWAS
  (Freedman–Lane / ter Braak are the exact forms there).
- V5 covered remains owed: an external comparator (PLINK `max(T)` / GenABEL), broader n/m/LD designs, and the
  R `gwas()`/`marker_scan()` activation. This slice discharges ONE leg.

## Next actions

1. The V5 external comparator (PLINK `max(T)` / GenABEL) on the same design — the next owed leg toward covered.
2. **GLLVM-adoption thread — PAUSED by maintainer (2026-06-30).** A real `jason-landscape-scout` of GLLVM.jl
   found the frozen session's adoption premise is WRONG: GLLVM.jl has NO link-scale residual variance `V_link`
   and NO dispersion-to-variance partition for non-Gaussian families — only GLM Fisher working weights
   (information, not residual variance) and a Gaussian-only variance partition. What is reusable is narrower
   (the link functions + per-family `V(μ)`); HSquared.jl must author the `V_link` step itself (it already holds
   the correct π²/3-style constants in `docs/design/19-h2-scale-contract.md`). Beta (trigamma weight ≠ de
   Villemereuil's `μ(1−μ)/(1+φ)`) and Ordinal (no scalar `V_link` hook) are flagged traps. **Decision: the
   maintainer paused this thread to focus v0.5** — the premise dissolved, so revisit later with the corrected,
   narrower scope (borrow only the `V(μ)`+link dispatch PATTERN; author `V_link` from doc-19). No code, no spec
   change this session; the scout finding is banked here for the future revisit.
