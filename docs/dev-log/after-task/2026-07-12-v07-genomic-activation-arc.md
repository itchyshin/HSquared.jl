# After-task report — v0.7 genomic GREML cross-twin activation arc

## 1. Goal

Expose a narrowly specified raw-marker genomic GREML candidate through the R twin, verify that it
constructs and reaches the intended Julia supplied-precision estimator, and retain default routing only
if the frozen cross-twin recovery and public-claim gates passed. The achieved endpoint is negative:
reusable explicit-route and evidence hardening remains, but default/public activation is removed and
held.

Branch: `codex/2026-07-12-v07-genomic-activation`. The final implementation checkpoints are R
`d4cefe10c155f87625bd5304d77e388a657c4eca` and Julia
`fade1d02cb2a9b404ec5d2d97da73fa291ac1237`; later commits contain only audited closeout records.

## 2. Implemented

- Froze the cross-twin scientific, grammar, alignment, payload, result, recovery, comparator, and claim
  contract in `docs/design/44-v07-genomic-public-activation.md`.
- Hardened `genomic()` validation for numeric finite dosages in `[0,2]`, monomorphic-panel rejection,
  one-to-one ID/kernel alignment, exactly one of markers or `Ginv`, and finite symmetric positive-
  definite named supplied precision.
- Added the narrow **explicit experimental** route for Gaussian REML with exactly one genomic random
  intercept through `engine = "julia", target = "genomic"`; unsupported forms are rejected before
  marshalling. The ordinary `engine = "fit"` default route again rejects genomic models after the
  recovery stop.
- Added strict engine-owned provenance normalization. Marker input records VanRaden1/sample-frequency/
  ridge/scale and fingerprints; supplied `Ginv` records unknown construction metadata and never
  inherits marker provenance.
- Returned `component = "genomic_variance_ratio"` with an explicit declared relationship scale and
  fenced ratio intervals/SEs. The coefficient is not presented as ordinary pedigree or population
  heritability or as a general average marginal phenotypic-variance fraction.
- Added engine-free validation/provenance/mutation tests, an independent base-R construction oracle,
  a frozen cross-twin live fixture, and a commit-pinned zero-skip local R-Julia gate.
- Added independent base-R recovery-summary recomputation, manifest/raw-key binding, separate
  create-once pilot/confirmation seals, failed-seed denominators, upper-SD sizing, Julia-summary parity,
  and deliberate mutation failures.
- Documented the fresh exact-candidate-Q `blupf90+` point-estimate comparison and the diagnostic pilot
  stop inherited from the Julia engine lane.
- Removed default activation after the 432-row diagnostic. Three cells had observed convergence below
  95% (`n120_m600_r020`, `n120_m600_r080`, `n300_m1000_r020`) and two more required more than 2,000
  confirmation replicates (`n120_m600_r050`, `n300_m1000_r080`). Confirmation did not run.
- Kept genomic GREML `partial`/experimental and `public_covered_count = 5`. No capability row moved,
  no release occurred, and no G10 decision exists.

## 3a. Decisions and Rejected Alternatives

- Kept the R package as owner of public grammar and Julia as owner of construction/fit provenance;
  rejected an R-fabricated provenance fallback because missing engine metadata must fail closed.
- Allowed optional marker column names with deterministic positional identities when absent; rejected
  silently reordered IDs or marker rows.
- Restricted the candidate to Gaussian REML, one genomic random intercept, and no extra random effect;
  rejected ML, non-Gaussian families, slopes, multiple genomic terms, and public method/ridge/frequency
  controls.
- Used the label “genomic variance-component ratio on the declared relationship scale”; rejected
  ordinary `h2` language and unavailable SE/interval claims.
- Used numerical `1e-10` identity for independently built base-R Q rather than demanding cross-language
  byte-identical hashes; exact hashes remain required for exact engine objects.
- Retained the explicit route and reusable hardening but removed default dispatch after the pilot stop.
  Rejected the alternative of leaving executable activation in place behind “held” prose.
- Rejected confirmation, failed-seed replacement, cell deletion, threshold relaxation, and partial-cell
  promotion. The pre-repair 432 rows are diagnostic only and cannot be upgraded retrospectively.

## 4. Files Touched

Committed arc files plus current negative-endpoint hardening:

- `DESCRIPTION`
- `NEWS.md`
- `R/bridge-payload.R`
- `R/extractors.R`
- `R/formula-status.R`
- `R/genomic-markers.R`
- `R/hs_control.R`
- `R/hsquared.R`
- `R/julia-bridge.R`
- `R/model-spec.R`
- `man/genomic_markers.Rd`
- `man/hs_control.Rd`
- `man/hsquared.Rd`
- `tests/testthat/test-genomic.R`
- `tests/testthat/test-v07-genomic-recovery-recompute.R`
- `tools/run-v07-genomic-live-gate.sh`
- `tools/v07_genomic_recovery_recompute.R`
- `docs/design/02-formula-grammar.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/43-genomic-greml-g0.md`
- `docs/design/44-v07-genomic-public-activation.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- `vignettes/articles/genomic-prediction.Rmd`
- `vignettes/articles/model-status.Rmd`
- `vignettes/hsquared.Rmd`
- `docs/dev-log/after-task/2026-07-12-v07-genomic-activation-arc.md`

Raw simulation and comparator outputs remain local in the Julia lane and are not R-package files.

## 5. Checks Run

- Engine-free full `devtools::test()` checkpoint: **1760 pass, 0 fail, 0 warn, 70 skip**.
- Focused live genomic suite with `HSQUARED_JULIA_PROJECT`, `NOT_CRAN=true`, Julia on `PATH`, and
  `OPENBLAS_NUM_THREADS=1`: passed with no required genomic skips after correcting independent-Q hash
  expectations.
- Recovery recomputation suite: initially 31/31, then **38/38** after adding separate create-once seals,
  exact sealed-file-set comparison, overwrite refusal, and tier isolation.
- `bash tools/run-v07-genomic-live-gate.sh --selftest`: passed; the self-test accepts `SKIP 0` and
  rejects `SKIP 1`. `bash -n` passed.
- Independent base-R construction agreed with Julia p, W, k, G, K, and Q to `1e-10`; marker and
  exact-supplied-Q fitted quantities agreed at the frozen `1e-8` tolerances.
- Fresh exact-Q `blupf90+` comparison agreed at its five-significant-figure output floor; this is one
  point-estimate comparison only.
- Independent base-R recomputation of the 432 diagnostic rows retained every attempt and confirmed
  the three convergence and two precision blockers. Confirmation was not launched.
- Final R checks passed: `devtools::document()`, the full engine-free suite, `pkgdown::check_pkgdown()`,
  and `rcmdcheck(args = "--no-manual")` with **0 errors, 0 warnings, and 0 notes**. The only check
  information item was the unavailable suggested package `pedigreemm`.
- Final Julia checks passed: full `Pkg.test()`, the Documenter build, and
  `bash tools/preamble_cap.sh`. Documenter retained 38 pre-existing undocumented-docstring warnings;
  npm reported four pre-existing dependency vulnerabilities.
- A broad all-live package invocation encountered an unrelated existing JuliaCall multivariate
  segfault after other live setup. It is not claimed as green; the dedicated zero-skip genomic gate is
  the live evidence for this arc.
- The exact commit-pinned live gate passed at the implementation checkpoints above with fixture tree
  `33bff946724b2ad7cf43e90e6a244079b917a747`, no required failures or skips, `Julia exit.`, and
  `V07_GENOMIC_LIVE_GATE_PASS`.
- Reviews: Fisher/Noether classified the repaired engine harness clean only for a future Julia
  diagnostic; Darwin's closing re-audit was `CLEAN`; Grace's post-false-green recheck was `CLEAN`;
  Rose's final verdict was `CLEAN-WITH-LIMITATIONS` for the negative opt-in endpoint.

## 6. Tests of the Tests

- Pure-R gates fail for both `markers` and `Ginv`, malformed dosage, monomorphic panels, duplicate or
  mismatched IDs, unsupported family/ML/slopes/additional effects, and both/neither relationship source.
- Provenance mutations fail when source/method/ridge/fingerprints are missing or false, a supplied
  precision inherits marker metadata, IDs or rows are reordered, or the ratio is relabelled ordinary
  heritability.
- The live fixture fails if a marker, ID order, scale, or ridge changes; exact engine Q hash identity is
  distinguished from tolerance-based independent base-R Q agreement.
- Recovery recomputation deliberately rejects one changed estimate, changed truth, duplicate seed,
  removed failed seed, changed cell label, ridge, marker hash, ID order, pilot/confirmation overlap,
  seal overwrite, unexpected file, and cross-tier contamination.
- The local live-gate self-test proves a skipped required live test turns the gate red (`SKIP 1`) while
  a true zero-skip result (`SKIP 0`) passes.
- The repaired live-gate self-test also proves a positive failure count turns the gate red (`FAIL 1`)
  while `FAIL 0` passes. This mutation was added after a real failed test demonstrated that
  `devtools::test()` can print a failure yet return shell status zero.
- The default-route rejection test fails if ordinary `engine = "fit"` silently dispatches genomic
  fitting again.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| R provenance fallback could fabricate missing Julia metadata | Fixed; engine provenance is required and validated fail-closed. |
| Supplied `Ginv` could inherit marker construction/ridge | Fixed; construction fields remain unknown unless a future contract supplies them. |
| Default route remained active after recovery stop | Fixed; ordinary default path rejects, explicit experimental target retained. |
| Live tests could skip and still look green | Fixed with commit/fixture-pinned zero-skip local gate and bidirectional self-test. |
| Independent base-R Q was numerically equal but not byte-hash equal | Corrected contract/test: tolerance for independent language implementation, exact hash for exact Julia Q. |
| Recovery seals could be overwritten or mixed across tiers | Fixed for future fresh campaigns; 38/38 recomputation tests. |
| Three convergence and two precision cell blockers | Retained; confirmation and activation stopped. |
| Original simulation bypassed public R formula | Retained as explicit evidence boundary; old rows cannot support end-to-end activation. |
| Darwin interpretation wording | Repairs applied; closing re-audit `CLEAN`. |
| Testthat failure printed while shell status remained zero | Fixed with semantic failure parsing and `FAIL 0`/`FAIL 1` mutation controls; exact pinned gate rechecked green. |

## 8. Consistency Audit

The source/generated neighbourhood sweep covered DESCRIPTION, NEWS, roxygen and Rd files, runtime
`formula_status()`, formula grammar, claims/capability/debt registers, public genomic and model-status
articles, and the top-level vignette. Current wording puts the hold before behavior: genomic GREML is
explicit/experimental; default activation is unimplemented. The coefficient formula and declared-scale
warning are present, and the diagnostic DGP is fenced as exact-model HWE/no-LD with no evidence for LD,
structure, imputation, base-frequency misspecification, or real production panels. Supplied `Ginv`
provenance remains unknown. No surface claims a released default, production scale, calibrated ratio
interval, pedigree heritability, broad recovery, or G10. Julia and R capability counts remain unchanged;
`public_covered_count` is **5**.

Memory receipt: the repo `route.py` LOAD-FIRST material, ultra-plan, rehydrate/team-dispatch,
formula/engine/bridge contract reviews, validation harness, R-package engineering, Rose public audit,
and after-task guards were loaded. They shaped state reconciliation, symbolic scale alignment,
pre-marshalling errors, source/generated synchronization, deliberate mutations, local-only live/compute
gates, and the executable negative endpoint. Prior decisions were recalled before scouting; existing
NotebookLM research was treated as triage and not authority. No new expensive cross-project synthesis
needed filing. **Golden Set:** not run as a hub-memory regression because retrieval code did not
change; the in-scope recurring failure classes were tested directly through provenance, skip, seal,
count, and default-dispatch negative controls. No hub guard was added, so `hub_budget.sh` was not
applicable.

## 9. What Did Not Go Smoothly

- The real gap emerged only after the initial repository/PR sweep; another solver implementation would
  have duplicated already-covered Julia work.
- R and Julia can agree at `1e-10` while serialized floating-point hashes differ at the last bit. The
  test initially over-required cross-language hash identity and was corrected.
- Strict provenance review found that an apparently convenient R fallback would launder missing engine
  metadata into a public claim.
- The initial recovery pipeline had upper-SD, immutability, resume, and seal defects. Independent R
  recomputation and Grace review caught them before confirmation.
- The pilot stopped on five of nine cells; four eligible cells cannot be promoted in isolation under the
  frozen broad gate.
- Rose found an implementation/prose contradiction: default auto-dispatch still activated the feature
  while status prose called it held. The dispatch was removed.
- A broad all-live run hit an unrelated multivariate JuliaCall segfault, so this report deliberately
  cites only the dedicated zero-skip genomic live gate.
- The first exact live-gate attempt exposed a false green: a stale assertion failed, but
  `devtools::test()` returned zero and the shell gate printed PASS. The stale assertion and the gate
  were repaired, mutation-tested, and independently rerun before closeout.

## 10. Known Residuals

- Default/public genomic activation remains unimplemented. The explicit route is partial,
  validation-scale, dense, Gaussian REML-only, and experimental.
- No confirmation campaign or authoritative end-to-end R-formula recovery exists. The 432 old rows
  cannot be reclassified after harness repair.
- The next discriminating experiment is optimizer localization on the failed cells using the frozen
  default, predeclared extra AI-REML iterations and EM warm start, the same failed seeds, and a fresh
  holdout block. Convergence definitions and failed-seed denominators must remain frozen.
- Any later activation needs a committed clean repaired harness, fresh external output directory, fresh
  end-to-end public-route pilot/confirmation, independent R/Julia recomputation, full interpretive and
  Rose re-audit, and maintainer G10.
- GitHub CI remains a package/docs check only. Simulation and recovery output stayed local and was
  never uploaded as an Actions artifact.

## 11. Team Learning

The R public contract must fail closed when engine provenance is absent; a convenient fallback can turn
missing evidence into authoritative-looking metadata. A local live gate must prove that required tests
ran, not merely that testthat exited zero. Most importantly, a negative scientific endpoint must change
dispatch behavior: documentation cannot hold a feature that code still activates. Cross-language
fingerprints should distinguish exact-object identity from independently reproduced numerical identity.

## 12. Cross-Product Coverage

- Formula/validation: covers ✓ Gaussian REML with exactly one genomic random intercept and exactly one
  of raw markers or supplied `Ginv`, on the explicit Julia genomic target. It **does NOT cover** ✗ ML,
  non-Gaussian families, slopes, extra random effects, multiple genomic terms, or ordinary default
  routing.
- Marker construction: covers ✓ numeric finite hard-call dosages, sample-frequency unweighted
  VanRaden1, ridge `0.01`, positional or unique named markers, and strict ID alignment. It **does NOT
  cover** ✗ missing dosage, dosage probabilities, weights, supplied population frequencies, method/ridge
  controls, LD/structure robustness, imputation, or production panels.
- Supplied precision: covers ✓ validation and explicit fitting conditional on the user-supplied inverse.
  It **does NOT cover** ✗ inferred marker method, allele-frequency source, ridge, denominator, or a
  universal biological scale.
- Result/extractors: covers ✓ a labelled coefficient-scale `genomic_variance_ratio` and provenance. It
  **does NOT cover** ✗ pedigree/population heritability, average marginal phenotypic-variance fraction,
  ratio SEs/intervals, or a release-ready default fit.
- Cross-twin identity/comparator: covers ✓ independent base-R construction at `1e-10`, marker/supplied-Q
  live fitted identity, and one hash-pinned BLUPF90 point-estimate comparison. It **does NOT cover** ✗
  multi-DGP comparator recovery, interval/performance parity, or an external marker-construction oracle
  inside BLUPF90.
- Recovery: covers ✓ independent recomputation of a conservative STOP from all 432 diagnostic attempts.
  It **does NOT cover** ✗ a passing pilot, confirmation, end-to-end formula-route recovery, broad
  activation, a capability/count move, or G10.
- Execution surfaces: covers ✓ ordinary engine-free package checks and a separate local commit-pinned
  zero-skip Julia live gate. It **does NOT cover** ✗ simulation on GitHub Actions, campaign artifacts,
  retroactive reuse of pre-repair rows, automatic merge, or release.
