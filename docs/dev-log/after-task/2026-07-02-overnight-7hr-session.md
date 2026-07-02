# Overnight 7-hour autonomous session — generality-gap ultraplan (2026-07-01 → 2026-07-02)

**Window:** ~2026-07-01 22:00 → 2026-07-02 05:00 (Claude solo, autonomous; G10 flip
authority delegated with genuine-evidence requirement).
**Repos:** `HSquared.jl` (Julia engine) + `hsquared` (R public surface).
**Reconstructed from durable repo state** (git log, merged PRs, `tools/status_cache.json`,
live `validation_status()`, CI runs) — not chat memory.

## Headline

`public_covered_count` **1 → 5**. The entire public-facing goal of the cross-twin
*"Closing the mixed-model generality gap"* ultraplan is delivered: an R quantitative
geneticist can now fit — and get validated, honestly-fenced output from — **five**
covered models, up from the single v0.1 Gaussian animal model at session start.

| # | Public-covered model (opt-in `engine="julia"`) | Phase |
| --- | --- | --- |
| 1 | v0.1 univariate Gaussian animal model (unchanged default) | baseline |
| 2 | common-environment two-effect / c² (repeatability, maternal-env) | Phase 1 |
| 3 | arbitrary-N independent random effects `(1\|g)` | Phase 2-R |
| 4 | random regression k=2 (linear reaction norm) | Phase 3 |
| 5 | direct–maternal correlated 2×2 `G_dm` (first correlated structure) | Phase 4 |

Plus **Phase 5 P5.1**: a sparse K-component AI-REML estimator (engine scale foundation,
experimental/partial — no public-count move, no performance claim).

## Verified end state (repo = truth)

- `HSquared.jl` `main` @ `90bdf435`; `hsquared` `main` @ `7e848ee`.
- Live `validation_status()`: **rows=53, covered=13, covered_external=3, partial=36,
  planned=1** — matches `tools/status_cache.json` exactly.
- `public_covered_count` = **5** (pinned across `status_cache.json` + `gen_status_json.jl`;
  honesty-assert enumerates all 5).
- Both working trees clean of session work. (`hsquared` shows only pre-existing
  `AGENTS.md`/`CLAUDE.md` shinichi-hub appends — NOT session work, intentionally unstaged.)
- CI green in BOTH repos, including the `hsquared` **pkgdown** workflow (see below).

## What landed, phase by phase (evidence-based)

Every covered flip cleared the same doc-16 bar: a **pre-declared 48-seed bias/MCSE
recovery gate** (predeclaration committed BEFORE the run; harness byte-identical pre/post;
48/48 converged; |bias|≤2·MCSE per component) **+ a same-estimand external REML comparator**
(`sommer`; Bayesian never counts) **+ a real `rose-systems-auditor` audit + paired CI-green
merge**.

### Engine prerequisite — `V3-NEFFECT-REML` engine covered (HSquared.jl #230)
Arbitrary-N independent random-effect REML estimator promoted `partial→covered` at the
engine/validation scale (48-seed gate + `sommer` 4.4.5 comparator). **Engine-covered ≠
R-public-covered** — `public_covered_count` stayed **1** here (the public count only moves
when the whole R vertical lands).

### Phase 0 (S0) — payload-v2 multi-block bridge, contract-only
- HSquared.jl **#231** (Julia `parse_payload_v2`/`fit_payload_v2`/`result_payload_v2` +
  cross-lane parity) + `hsquared` **#115** (R emitter). Byte-identical cross-lane parity;
  v0.1 fast-path bit-identical. `public_covered_count` unchanged (**1**).

### Phase 1 — common-environment two-effect / c² → public 1→2
- HSquared.jl **#232** (public flip; `two_effect_ratio_interval` asymptotic delta-method
  CI for h²/c², J1) + `hsquared` **#116**; consolidation **#233**.
- Scope: common-env / c² leg; asymptotic uncalibrated intervals; opt-in.

### Phase 2-R — arbitrary-N independent `(1|g)` → public 2→3
- HSquared.jl **#234** (`multi_effect_ratio_interval`, generalizes J1 to K; public flip) +
  `hsquared` **#117**; consolidation **#235**.
- CI caught a Julia-1.11/1.12 version-fragile boundary test → fixed to a contract-based
  assertion (`3d216ab7`), verified on 1.10 AND 1.12.

### pkgdown CI fix — `hsquared` #118 (the user-flagged failure)
- `_pkgdown.yml` was missing the newly-exported Phase 1/2 topics + comparator articles
  (`check_missing_topics` errored; R-CMD-check does not build the pkgdown site, so it slipped
  the PR gate). **#118** added them; `pkgdown::check_pkgdown()` clean. Post-merge pkgdown
  workflow on `main` is **green** (runs 28566598947 / 28576612103). `pkgdown::check_pkgdown()`
  added to the R-lane DoD.

### Phase 3 — random regression k=2 (reaction norm) → public 3→4
- HSquared.jl **#236** (`V3-RR-REML` `partial→covered`; public flip) + `hsquared` **#119**;
  consolidation **#237**.
- Gate PASS 48/48 (|bias|/MCSE: K11 1.16, K22 1.67, K12 0.17, σe² 0.15). `sommer` `leg()`
  same-estimand comparator AGREE ≤1.9e-5 — with the **Legendre-normalization check**
  (diagonal D=I₂; compared absolute variance entries, not correlation-only, which would be a
  false pass). h² is a covariate-indexed **curve**, never a scalar.

### Phase 4 — direct–maternal correlated 2×2 `G_dm` → public 4→5 (the hardest)
- HSquared.jl **#238** (`V4-DIRECT-MATERNAL` `partial→covered`; public flip) + `hsquared`
  **#120** (correlated surface + Willham corrections); consolidation **#239**.
- **Gate PASS 48/48** on a *confound-breaking* DGP (4 overlapping generations, dams with
  own records + 8 offspring, 90 identifying dams, n=960) + a negative-control cell proving
  the gate detects the direct–maternal confound. |bias|/MCSE: σ²_ad 0.13, σ²_am 1.65,
  σ_dm 0.72, σ²e 0.24; EBV acc direct 0.667/maternal 0.759; cond ≤157; |r_am| interior.
  (The Fable gate-design agent flagged σ²_am at ~3·MCSE risk from a 12-seed projection; the
  full 48-seed run resolved it at **1.65·MCSE** — a genuine pass, nothing weakened.)
- `sommer` 4.4.5 **`covm(vsm(ism(animal),Gu=A), vsm(ism(dam_id),Gu=A))`** same-estimand
  comparator AGREE ≤1.1e-2 including the negative σ_dm. Correctly diagnosed that the RR
  `usm(leg())` idiom does NOT transfer (maternal loads on the dam's id, not the record's own).
- **Honesty catch (pre-ship):** a Falconer/Fisher check found the R surface's phenotypic-
  variance denominator was wrong (`σ_P` excluded σ_dm) and misattributed to "Falconer 1965".
  Corrected to Willham `σ_P = σ²_ad + σ²_am + σ_dm + σ²e`, added `total_heritability()`
  (Willham h²_T with the 1, 1.5, 0.5 coefficients — can fall below direct h² when r_am<0),
  and made `heritability()` return the **labelled triple** (direct h², m², total h²_T), never
  a bare scalar (`441cab9`).

### Phase 5 P5.1 — sparse K-component AI-REML (engine scale foundation)
- HSquared.jl **#240** (`fit_sparse_multi_effect_aireml` + `selinv_block_traces` Takahashi
  selected-inverse per-block score); check-log **#241**.
- **Correctness gate = exact reduction to the dense optimum** (not a recovery gate): N=1 →
  `fit_ai_reml` ~1e-14; K=2/K=3 → dense `fit_multi_effect_reml` (loglik ~1e-8, VC rtol ~2e-4,
  where the ~2e-4 is the dense NelderMead oracle stopping short — dense gradient ~6e-9 at the
  sparse optimum); objective identity ~1e-13; analytic score == central-FD gradient ~2e-8.
- **No public move** (`public_covered_count` stays 5); new `partial` engine row
  `V3-NEFFECT-SPARSE` (rows 52→53). **No performance/scale claim** — measure-first; the
  benchmark scaffold `sim/phase5_sparse_aireml_benchmark.jl` is opt-in, OUT of CI, evidence
  OWED.

## Honesty pins — all held

- **`public_covered_count` 5**, moved only when each whole R vertical landed (engine estimator
  alone never flipped it — the #230 engine-covered / public-stayed-1 case is the explicit
  precedent).
- **Engine-covered ≠ R-public-covered** maintained throughout (V4-MV-REML / V5-GWAS pattern).
- **v0.1 default untouched** — every new model is opt-in `engine="julia", target=…`; the
  default `engine="fit"` path is unchanged.
- **All intervals asymptotic/uncalibrated** (delta-method); RR and direct–maternal are
  point-estimate (no interval). Stated in every covered scope.
- **Gates:** pre-declared, byte-identical harness, 48/48, |bias|≤2·MCSE — **all PASSED this
  session; no banked negatives.**
- **Real Rose audits** on every flip (Phase 4's on Fable, the highest-overclaim-risk claim);
  every PROMOTE-WITH-CHANGES item applied.
- **Scope fences** carried on the correlated claim: validation-scale dense n≤~1000, single-A,
  direct h² ≠ total h², negative r_am real, `|r_am|→1` rides on `converged`.

## CI status (both repos green)

- **HSquared.jl:** CI (Julia 1 + 1.10) + Documenter green on #240/#241 and all merges; pages
  deployed.
- **hsquared:** #120 R-CMD-check green (after the em-dash fix, below); #119 green; **pkgdown
  workflow on `main` green**.

## Two process catches (recorded for the DoD)

1. **R-CMD-check non-ASCII in R string literals** (SECOND occurrence; Phase 1 was the first).
   Em-dashes inside 4 R strings failed `hsquared` #120's first R-CMD-check (`error_on=warning`)
   — invisible to `devtools::test()`. Fixed (`ef65844`); re-run green. **Recommendation
   (now standing):** run `R CMD check` locally for R branches, not just `devtools::test()`.
2. **pkgdown not built by R-CMD-check** — a missing `_pkgdown.yml` topic passes R-CMD-check but
   fails the pkgdown workflow. `pkgdown::check_pkgdown()` is now part of the R-lane DoD.

## What remains + concrete next steps

**Phase 5 continuation (the estimator exists + is reduction-verified; the scale/perf claim is
OWED):**
- P5.2/P5.6 — a **pre-declared** sparse-vs-dense timing/scaling **benchmark** (DRAC/Totoro,
  committed before the run) → the only basis for any performance claim.
- P5.5 — a same-estimand comparator run *through the sparse path* at production scale.
- P5.4 — robustness rows (cold/warm start, boundary, large-q identifiability).
- P5.8 — Rose audit → G10 for any perf-claim promotion.

**Standing debt on the shipped covered models (harden, don't expand):**
- Direct–maternal: a BLUPF90 `OPTIONAL mat` **second independent comparator lineage** (needs
  `renumf90` re-download + a verified `OPTIONAL mat` emitter); broader-DGP / larger-than-dense
  recovery; the maternal-A2 / metafounder generalization (stays experimental).
- Calibrated (not asymptotic) intervals for the RR and direct–maternal covered models.
- Small-sample interval calibration (`V1-HERIT-TCAL`, still planned).

**Deferred (🔴 post-v1.0, unchanged):** reduced-rank / factor-analytic `K_g` (k>2);
non-Gaussian × multi-RE; full glmmTMB/brms parity; `genomic()`/`dominance()`/nested `/`.

## Mid-flight / caveats (flagged honestly)

- **No uncommitted session work, no red CI, no failed gates.** All 12 session PRs across both
  repos merged on green CI.
- `hsquared` working tree carries pre-existing `AGENTS.md`/`CLAUDE.md` shinichi-hub appends
  (unrelated to this session) — left unstaged, as prior sessions did.
- `tools/status_cache.json` `refreshed_from_head` reads `e34a1ef8` (Phase 4 merge) while
  `rows` correctly reads 53 (post-P5.1) — a cosmetic staleness in one metadata field; the
  count itself is correct (verified live) and the count-guard test (`== 53`) is green.

## Session PR ledger

- **HSquared.jl (merged):** #230 (engine N-effect covered), #231 (S0), #232 (Phase 1 flip),
  #233 (P1 consolidation), #234 (Phase 2 flip), #235 (P2 consolidation), #236 (Phase 3 flip),
  #237 (P3 consolidation), #238 (Phase 4 flip), #239 (P4 consolidation), #240 (Phase 5 P5.1),
  #241 (P5.1 check-log).
- **hsquared (merged):** #115 (S0 emitter), #116 (Phase 1 flip), #117 (Phase 2 flip),
  #118 (pkgdown fix), #119 (Phase 3 flip), #120 (Phase 4 flip).
